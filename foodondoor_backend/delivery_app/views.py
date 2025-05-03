from django.shortcuts import render
from rest_framework import generics, status, permissions
from rest_framework.response import Response
from rest_framework.views import APIView
# Note: Delivery agents primarily use phone number, so no Q import needed unless adding email login later

from .models import DeliveryAgentProfile
from .serializers import DeliveryAgentProfileSerializer, DeliveryAgentRegistrationSerializer
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
    permission_classes = [permissions.IsAuthenticated] 

    def get_object(self):
        if isinstance(self.request.user, DeliveryAgentProfile):
            return self.request.user
        raise permissions.PermissionDenied("You do not have permission to access this profile.")

# --- Placeholder Views (Need Implementation) ---

class DeliveryAgentProfileUpdateView(APIView):
    permission_classes = [permissions.IsAuthenticated] # TODO: Use IsAuthenticatedDeliveryAgent
    def put(self, request, *args, **kwargs):
        # TODO: Implement profile update logic
        return Response({'message': 'Delivery agent profile update placeholder'}, status=status.HTTP_200_OK)

class AvailableOrdersView(APIView):
    permission_classes = [permissions.IsAuthenticated] # TODO: Use IsAuthenticatedDeliveryAgent
    def get(self, request, *args, **kwargs):
        # TODO: Implement available orders logic
        return Response({'message': 'Available orders placeholder'}, status=status.HTTP_200_OK)

class AssignOrderView(APIView):
    permission_classes = [permissions.IsAuthenticated] # TODO: Use IsAuthenticatedDeliveryAgent
    def post(self, request, pk, *args, **kwargs):
        # TODO: Implement order assignment logic using pk
        return Response({'message': f'Assign order placeholder for pk={pk}'}, status=status.HTTP_200_OK)

class ConfirmPickupView(APIView):
    permission_classes = [permissions.IsAuthenticated] # TODO: Use IsAuthenticatedDeliveryAgent
    def post(self, request, pk, *args, **kwargs):
        # TODO: Implement confirm pickup logic using pk
        return Response({'message': f'Confirm pickup placeholder for pk={pk}'}, status=status.HTTP_200_OK)

class ConfirmDeliveryView(APIView):
    permission_classes = [permissions.IsAuthenticated] # TODO: Use IsAuthenticatedDeliveryAgent
    def post(self, request, pk, *args, **kwargs):
        # TODO: Implement confirm delivery logic using pk
        return Response({'message': f'Confirm delivery placeholder for pk={pk}'}, status=status.HTTP_200_OK)

class DeliveryAgentEarningsView(APIView):
    permission_classes = [permissions.IsAuthenticated] # TODO: Use IsAuthenticatedDeliveryAgent
    def get(self, request, *args, **kwargs):
        # TODO: Implement earnings view logic
        return Response({'message': 'Delivery agent earnings placeholder'}, status=status.HTTP_200_OK)
