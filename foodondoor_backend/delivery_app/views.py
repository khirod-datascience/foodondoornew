from django.shortcuts import render
from django.core.cache import cache
from rest_framework import generics, status, permissions
from rest_framework.response import Response
from rest_framework.views import APIView
# Note: Delivery agents primarily use phone number, so no Q import needed unless adding email login later

from .models import DeliveryAgentProfile
from .serializers import DeliveryAgentProfileSerializer, DeliveryAgentRegistrationSerializer, OrderSerializer
from core.utils import generate_access_token, generate_refresh_token
from core.permissions import IsAuthenticatedDeliveryAgent

# Create your views here.

# We can add other views here later, e.g., for profile management, availability status, location updates etc.

class DeliveryAgentProfileView(APIView):
    """
    API view for retrieving the logged-in delivery agent's profile.
    Assumes JWTAuthentication populates request.user correctly.
    Requires authentication (handled by default settings).
    """
    serializer_class = DeliveryAgentProfileSerializer
    permission_classes = [IsAuthenticatedDeliveryAgent]

    def get(self, request, *args, **kwargs):
        agent = getattr(request, 'profile', None)
        if not isinstance(agent, DeliveryAgentProfile):
            return Response({'error': 'Not a delivery agent.'}, status=status.HTTP_403_FORBIDDEN)
        serializer = self.serializer_class(agent)
        return Response(serializer.data, status=status.HTTP_200_OK)

# --- Delivery Agent Registration View ---
class DeliveryAgentRegistrationView(APIView):
    """
    Handles the final step of delivery agent registration after OTP verification.
    Requires a valid signup_token and delivery agent profile data.
    Creates the delivery agent profile and returns auth tokens.
    """
    permission_classes = [permissions.AllowAny]

    def post(self, request, *args, **kwargs):
        serializer = DeliveryAgentRegistrationSerializer(data=request.data)
        signup_token = request.data.get('signup_token')

        if not signup_token:
            return Response({'error': 'Signup token is required.'}, status=status.HTTP_400_BAD_REQUEST)

        # 1. Verify signup_token and get phone number from cache
        signup_token_cache_key = f'signup_token_{signup_token}'
        cached_data = cache.get(signup_token_cache_key)

        if not cached_data:
            return Response({'error': 'Invalid or expired signup token.'}, status=status.HTTP_400_BAD_REQUEST)
        phone_number = cached_data.get('phone_number')
        if not phone_number:
            return Response({'error': 'Could not retrieve phone number for registration.'}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)

        # 2. Validate incoming profile data
        if serializer.is_valid():
            # 3. Check if delivery agent with this phone number already exists
            from .models import DeliveryAgentProfile
            if DeliveryAgentProfile.objects.filter(phone_number=phone_number).exists():
                return Response({'error': 'A delivery agent with this phone number already exists.'}, status=status.HTTP_409_CONFLICT)
            # 4. Create the delivery agent profile
            try:
                agent = serializer.save(phone_number=phone_number, is_active=True)
                agent.is_approved = True
                agent.save()
                # Registration successful, delete the signup token
                cache.delete(signup_token_cache_key)
                # Generate JWT tokens for the new user
                access_token = generate_access_token(agent)
                refresh_token = generate_refresh_token(agent)
                return Response({
                    'access_token': access_token,
                    'refresh_token': refresh_token,
                    'user_id': agent.id,
                    'user_type': 'delivery',
                    'is_new': False
                }, status=status.HTTP_201_CREATED)
            except Exception as e:
                return Response({'error': 'Failed to create profile.'}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)
        else:
            return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

# --- Placeholder Views (Need Implementation) ---

class DeliveryAgentProfileUpdateView(APIView):
    permission_classes = [IsAuthenticatedDeliveryAgent]
    def put(self, request, *args, **kwargs):
        agent = getattr(request, 'profile', None)
        if not isinstance(agent, DeliveryAgentProfile):
            return Response({'error': 'Not a delivery agent.'}, status=status.HTTP_403_FORBIDDEN)
        serializer = DeliveryAgentProfileSerializer(agent, data=request.data, partial=True)
        if serializer.is_valid():
            serializer.save()
            return Response(serializer.data, status=status.HTTP_200_OK)
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

from rest_framework import generics

class AvailableOrdersView(generics.ListAPIView):
    """
    Returns a list of all available orders for delivery, newest first.
    """
    serializer_class = OrderSerializer
    permission_classes = [IsAuthenticatedDeliveryAgent]

    def get_queryset(self):
        # Only show orders that are available for delivery assignment
        return Order.objects.filter(status='ready').order_by('-created_at')

class AssignOrderView(APIView):
    permission_classes = [IsAuthenticatedDeliveryAgent]
    def post(self, request, pk, *args, **kwargs):
        agent = getattr(request, 'profile', None)
        try:
            order = Order.objects.get(pk=pk, status='ready')
        except Order.DoesNotExist:
            return Response({'error': 'Order not available for assignment.'}, status=status.HTTP_404_NOT_FOUND)
        # Assign order
        order.status = 'assigned'
        order.delivery_agent = agent
        order.save(update_fields=['status', 'delivery_agent'])
        return Response({'message': f'Order {pk} assigned to you.'}, status=status.HTTP_200_OK)

class ConfirmPickupView(APIView):
    """
    Handles POST /order/<int:pk>/status/ to update the delivery order status (picked_up, delivered, etc.).
    """
    permission_classes = [IsAuthenticatedDeliveryAgent]
    def post(self, request, pk, *args, **kwargs):
        agent = getattr(request, 'profile', None)
        status_value = request.data.get('status')
        if not status_value:
            return Response({'error': 'Missing status parameter.'}, status=status.HTTP_400_BAD_REQUEST)
        try:
            order = Order.objects.get(pk=pk, delivery_agent=agent)
        except Order.DoesNotExist:
            return Response({'error': 'Order not found or not assigned to you.'}, status=status.HTTP_404_NOT_FOUND)
        if status_value not in ['picked_up', 'delivered']:
            return Response({'error': 'Invalid status value.'}, status=status.HTTP_400_BAD_REQUEST)
        order.status = status_value
        order.save(update_fields=['status'])
        return Response({'message': f'Order {pk} status updated to {status_value}.'}, status=status.HTTP_200_OK)

class ConfirmDeliveryView(APIView):
    permission_classes = [IsAuthenticatedDeliveryAgent]
    def post(self, request, pk, *args, **kwargs):
        agent = getattr(request, 'profile', None)
        try:
            order = Order.objects.get(pk=pk, delivery_agent=agent, status='picked_up')
        except Order.DoesNotExist:
            return Response({'error': 'Order not found or not picked up.'}, status=status.HTTP_404_NOT_FOUND)
        order.status = 'delivered'
        order.save(update_fields=['status'])
        return Response({'message': f'Order {pk} marked as delivered.'}, status=status.HTTP_200_OK)

from rest_framework import generics

class DeliveryAgentHistoryView(generics.ListAPIView):
    """
    Returns a list of completed orders for the logged-in delivery agent, newest first.
    """
    serializer_class = OrderSerializer
    permission_classes = [IsAuthenticatedDeliveryAgent]

    def get_queryset(self):
        # Only show orders assigned to this delivery agent and completed
        agent_profile = getattr(self.request, 'profile', None)
        return Order.objects.filter(delivery_agent=agent_profile, status='delivered').order_by('-completed_at')

class DeliveryAgentEarningsView(APIView):
    permission_classes = [IsAuthenticatedDeliveryAgent]
    def get(self, request, *args, **kwargs):
        agent = getattr(request, 'profile', None)
        # Example: sum all completed orders' delivery_fee for this agent
        from .models import Order
        total_earnings = Order.objects.filter(delivery_agent=agent, status='delivered').aggregate(total=models.Sum('delivery_fee'))['total'] or 0
        return Response({'total_earnings': total_earnings}, status=status.HTTP_200_OK)
