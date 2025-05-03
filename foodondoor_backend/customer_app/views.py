from django.shortcuts import render
from django.core.cache import cache
from rest_framework import generics, status, permissions
from rest_framework.response import Response
from rest_framework.views import APIView
from django.db.models import Q # For OR queries

from .models import CustomerProfile, Address # Import Address model
from .serializers import CustomerProfileSerializer, CustomerRegistrationSerializer, AddressSerializer 
from vendor_app.models import Restaurant, Category, FoodItem
from vendor_app.serializers import RestaurantSerializer, FoodItemSerializer, CategorySerializer # Import CategorySerializer and Restaurant and FoodItem serializers
from core.utils import generate_access_token, generate_refresh_token # Import token generators
from core.permissions import IsAuthenticatedCustomer # Assuming custom permission class
import jwt
from django.conf import settings
from django.utils import timezone
from django.http import Http404

# Create your views here.

class CustomerHomeView(APIView):
    permission_classes = [permissions.IsAuthenticated]
    def get(self, request, *args, **kwargs):
        from vendor_app.models import Restaurant, Category, FoodItem
        from vendor_app.serializers import RestaurantSerializer, CategorySerializer, FoodItemSerializer
        # Example: banners can be static or fetched from a model
        banners = [
            {'image': '/static/banners/banner1.jpg', 'title': 'Welcome Offer'},
            {'image': '/static/banners/banner2.jpg', 'title': 'Free Delivery'},
        ]
        categories = CategorySerializer(Category.objects.all(), many=True).data
        # For demo, nearby = all restaurants (customize as needed)
        nearby_restaurants = RestaurantSerializer(Restaurant.objects.all()[:10], many=True).data
        top_rated_restaurants = RestaurantSerializer(Restaurant.objects.order_by('-rating')[:5], many=True).data
        popular_foods = FoodItemSerializer(FoodItem.objects.order_by('-popularity')[:10], many=True).data if hasattr(FoodItem, 'popularity') else FoodItemSerializer(FoodItem.objects.all()[:10], many=True).data
        return Response({
            'banners': banners,
            'categories': categories,
            'nearby_restaurants': nearby_restaurants,
            'top_rated_restaurants': top_rated_restaurants,
            'popular_foods': popular_foods
        }, status=status.HTTP_200_OK)

class CustomerCompleteSignupView(APIView):
    permission_classes = [permissions.AllowAny] # Anyone with a valid signup token can complete registration
    serializer_class = CustomerRegistrationSerializer

    def post(self, request, *args, **kwargs):
        signup_token = request.data.get('signup_token')
        if not signup_token:
            return Response({'error': 'Signup token is required.'}, status=status.HTTP_400_BAD_REQUEST)

        try:
            # Decode the signup token
            payload = jwt.decode(
                signup_token,
                settings.JWT_SECRET_KEY,
                algorithms=[settings.JWT_ALGORITHM]
            )

            # Validate token type and user type
            if payload.get('token_type') != 'signup' or payload.get('user_type') != 'CustomerProfile':
                raise jwt.exceptions.InvalidTokenError("Invalid token type or user type for signup.")

            # Check expiry (already handled by jwt.decode, but can double-check if needed)
            # exp_timestamp = payload.get('exp')
            # if exp_timestamp < timezone.now().timestamp():
            #    raise jwt.exceptions.ExpiredSignatureError("Signup token has expired.")

            phone_number = payload.get('phone_number')
            if not phone_number:
                 raise jwt.exceptions.InvalidTokenError("Signup token missing phone number.")

            # Check if user already exists with this phone number
            if CustomerProfile.objects.filter(phone_number=phone_number).exists():
                return Response({'error': 'User with this phone number already exists.'}, status=status.HTTP_409_CONFLICT)

            # Proceed with registration data validation
            serializer = self.serializer_class(data=request.data)
            if serializer.is_valid():
                # Inject the validated phone number from the token into the data to be saved
                validated_data = serializer.validated_data
                validated_data['phone_number'] = phone_number

                # Use the serializer's create method (which now expects phone_number)
                customer = serializer.save() # This calls serializer.create()

                # Generate JWT tokens for the new user
                access_token = generate_access_token(customer)
                refresh_token = generate_refresh_token(customer)

                # Return tokens and minimal user info
                return Response({
                    'access': access_token,
                    'refresh': refresh_token,
                    'user': {'id': customer.id, 'email': customer.email, 'phone_number': customer.phone_number}
                    # Consider using CustomerProfileSerializer here for full profile if needed
                }, status=status.HTTP_201_CREATED)
            else:
                return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

        except jwt.exceptions.ExpiredSignatureError:
            return Response({'error': 'Signup token has expired.'}, status=status.HTTP_400_BAD_REQUEST)
        except jwt.exceptions.InvalidTokenError as e:
            return Response({'error': f'Invalid signup token: {e}'}, status=status.HTTP_400_BAD_REQUEST)
        except Exception as e:
            # Catch unexpected errors
            return Response({'error': f'An unexpected error occurred: {str(e)}'}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)


class CustomerProfileView(APIView):
    """
    API view for retrieving the logged-in customer's profile.
    Assumes JWTAuthentication populates request.user correctly.
    Requires authentication (handled by specific permission).
    """
    serializer_class = CustomerProfileSerializer
    permission_classes = [IsAuthenticatedCustomer] # Use specific customer permission

    def get(self, request, *args, **kwargs):
        # request.user should be the CustomerProfile instance due to JWT Auth and permission check
        serializer = self.serializer_class(request.user)
        return Response(serializer.data, status=status.HTTP_200_OK)

# --- Placeholder Views (Need Implementation) ---

# Class to handle profile updates (PUT/PATCH)
class CustomerProfileUpdateView(APIView):
    permission_classes = [IsAuthenticatedCustomer] # Ensure only authenticated customers can update
    serializer_class = CustomerProfileSerializer

    def get_object(self):
        # Since IsAuthenticatedCustomer checks the user type, request.user is the profile
        return self.request.user

    def get(self, request, *args, **kwargs):
        """Handles GET requests to retrieve the current profile data before update."""
        profile = self.get_object()
        serializer = self.serializer_class(profile)
        return Response(serializer.data)

    def put(self, request, *args, **kwargs):
        """Handles PUT requests to update the entire profile (or fields provided)."""
        profile = self.get_object()
        # Pass instance=profile to update the existing object
        # partial=False by default for PUT, requiring all fields (unless serializer allows partial)
        # We allow partial updates implicitly by using ModelSerializer with optional fields
        serializer = self.serializer_class(profile, data=request.data, partial=True) # Allow partial updates
        if serializer.is_valid():
            serializer.save()
            return Response(serializer.data)
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

    def patch(self, request, *args, **kwargs):
        """Handles PATCH requests for partial profile updates."""
        profile = self.get_object()
        # partial=True explicitly for PATCH
        serializer = self.serializer_class(profile, data=request.data, partial=True) 
        if serializer.is_valid():
            serializer.save()
            return Response(serializer.data)
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

class CustomerBannersView(APIView):
    permission_classes = [permissions.IsAuthenticated] # TODO: Implement specific permission if needed
    def get(self, request, *args, **kwargs):
        # TODO: Implement banner fetching logic
        return Response({'message': 'Banners placeholder'}, status=status.HTTP_200_OK)

class CustomerCategoriesView(APIView):
    permission_classes = [permissions.IsAuthenticated] # TODO: Implement IsAuthenticatedCustomer
    def get(self, request, *args, **kwargs):
        # TODO: Implement category fetching logic
        return Response({'message': 'Categories placeholder'}, status=status.HTTP_200_OK)

class NearbyRestaurantsView(APIView):
    permission_classes = [permissions.IsAuthenticated] # TODO: Implement IsAuthenticatedCustomer
    def get(self, request, *args, **kwargs):
        # TODO: Implement nearby restaurant logic (requires location)
        return Response({'message': 'Nearby restaurants placeholder'}, status=status.HTTP_200_OK)

class TopRatedFoodView(APIView):
    permission_classes = [permissions.IsAuthenticated] # TODO: Implement IsAuthenticatedCustomer
    def get(self, request, *args, **kwargs):
        # TODO: Implement top-rated food logic
        return Response({'message': 'Top rated food placeholder'}, status=status.HTTP_200_OK)

class RestaurantDetailView(APIView):
    permission_classes = [permissions.AllowAny] # Allow anyone to view details
    serializer_class = RestaurantSerializer

    def get_object(self, pk):
        try:
            # Fetch only active restaurants
            return Restaurant.objects.prefetch_related('categories__food_items').get(pk=pk, is_active=True)
        except Restaurant.DoesNotExist:
            raise Http404

    def get(self, request, pk, *args, **kwargs):
        """Retrieves details for a specific active restaurant, including menu."""
        restaurant = self.get_object(pk)
        serializer = self.serializer_class(restaurant, context={'request': request})
        return Response(serializer.data, status=status.HTTP_200_OK)

class RestaurantListView(APIView):
    permission_classes = [permissions.AllowAny] # Allow anyone to view restaurants
    serializer_class = RestaurantSerializer

    def get(self, request, *args, **kwargs):
        """Lists all active restaurants."""
        # TODO: Add filtering (cuisine, rating, distance), pagination
        restaurants = Restaurant.objects.filter(is_active=True)
        serializer = self.serializer_class(restaurants, many=True, context={'request': request})
        # Exclude categories/food_items from list view for performance? Optional.
        # Or use a different, simpler serializer for the list view.
        return Response(serializer.data, status=status.HTTP_200_OK)

class CategoryListView(APIView):
    permission_classes = [permissions.AllowAny] # Public view usually
    serializer_class = CategorySerializer

    def get_restaurant(self, restaurant_pk):
        try:
            return Restaurant.objects.get(pk=restaurant_pk, is_active=True)
        except Restaurant.DoesNotExist:
            raise Http404("Active restaurant not found.")

    def get(self, request, restaurant_pk, *args, **kwargs):
        """Lists all categories for a specific active restaurant."""
        restaurant = self.get_restaurant(restaurant_pk)
        categories = Category.objects.filter(restaurant=restaurant)
        # If using nested serializers, ensure CategorySerializer handles FoodItems
        # Or add prefetch_related('food_items') if needed here or in serializer
        serializer = self.serializer_class(categories, many=True, context={'request': request})
        return Response(serializer.data, status=status.HTTP_200_OK)

class FoodItemDetailView(APIView):
    permission_classes = [permissions.AllowAny] # Public view usually
    serializer_class = FoodItemSerializer # Use FoodItemSerializer

    def get_object(self, pk):
        try:
            # Fetch only available food items from active restaurants
            return FoodItem.objects.select_related('category', 'restaurant').get(pk=pk, is_available=True, restaurant__is_active=True)
        except FoodItem.DoesNotExist:
            raise Http404

    def get(self, request, pk, *args, **kwargs):
        """Retrieves details for a specific available food item."""
        food_item = self.get_object(pk)
        serializer = self.serializer_class(food_item, context={'request': request})
        return Response(serializer.data, status=status.HTTP_200_OK)

class CustomerCartView(APIView):
    permission_classes = [permissions.IsAuthenticated] # TODO: Implement IsAuthenticatedCustomer
    def get(self, request, *args, **kwargs):
        from core.models import Cart
        from .serializers import CartSerializer
        customer_id = str(request.user.id)
        cart, created = Cart.objects.get_or_create(customer_id_temp=customer_id)
        serializer = CartSerializer(cart)
        return Response(serializer.data, status=status.HTTP_200_OK)

class CustomerCartAddView(APIView):
    permission_classes = [permissions.IsAuthenticated] # TODO: Implement IsAuthenticatedCustomer
    def post(self, request, *args, **kwargs):
        from core.models import Cart, CartItem
        from .serializers import CartSerializer
        customer_id = str(request.user.id)
        menu_item_id = request.data.get('menu_item_id')
        quantity = int(request.data.get('quantity', 1))
        if not menu_item_id or quantity < 1:
            return Response({'error': 'menu_item_id and positive quantity required.'}, status=status.HTTP_400_BAD_REQUEST)
        cart, _ = Cart.objects.get_or_create(customer_id_temp=customer_id)
        cart_item, created = CartItem.objects.get_or_create(cart=cart, menu_item_id_temp=menu_item_id)
        if not created:
            cart_item.quantity += quantity
        else:
            cart_item.quantity = quantity
        cart_item.save()
        serializer = CartSerializer(cart)
        return Response(serializer.data, status=status.HTTP_201_CREATED)

class CustomerCartUpdateView(APIView):
    permission_classes = [permissions.IsAuthenticated] # TODO: Implement IsAuthenticatedCustomer
    def put(self, request, *args, **kwargs):
        from core.models import Cart, CartItem
        from .serializers import CartSerializer
        customer_id = str(request.user.id)
        menu_item_id = request.data.get('menu_item_id')
        quantity = int(request.data.get('quantity', 1))
        if not menu_item_id or quantity < 1:
            return Response({'error': 'menu_item_id and positive quantity required.'}, status=status.HTTP_400_BAD_REQUEST)
        try:
            cart = Cart.objects.get(customer_id_temp=customer_id)
            cart_item = CartItem.objects.get(cart=cart, menu_item_id_temp=menu_item_id)
            cart_item.quantity = quantity
            cart_item.save()
            serializer = CartSerializer(cart)
            return Response(serializer.data, status=status.HTTP_200_OK)
        except (Cart.DoesNotExist, CartItem.DoesNotExist):
            return Response({'error': 'Cart or CartItem not found.'}, status=status.HTTP_404_NOT_FOUND)

class CustomerCartRemoveView(APIView):
    permission_classes = [permissions.IsAuthenticated] # TODO: Implement IsAuthenticatedCustomer
    def delete(self, request, *args, **kwargs):
        from core.models import Cart, CartItem
        customer_id = str(request.user.id)
        menu_item_id = request.data.get('menu_item_id')
        if not menu_item_id:
            return Response({'error': 'menu_item_id required.'}, status=status.HTTP_400_BAD_REQUEST)
        try:
            cart = Cart.objects.get(customer_id_temp=customer_id)
            cart_item = CartItem.objects.get(cart=cart, menu_item_id_temp=menu_item_id)
            cart_item.delete()
            return Response({'message': 'Item removed from cart.'}, status=status.HTTP_200_OK)
        except (Cart.DoesNotExist, CartItem.DoesNotExist):
            return Response({'error': 'Cart or CartItem not found.'}, status=status.HTTP_404_NOT_FOUND)

    def post(self, request, *args, **kwargs):
        # POST support for removing cart item
        return self.delete(request, *args, **kwargs)

# --- Address Management Views ---

class AddressListView(APIView):
    permission_classes = [IsAuthenticatedCustomer]
    serializer_class = AddressSerializer

    def get(self, request, *args, **kwargs):
        """Lists addresses for the logged-in customer."""
        addresses = Address.objects.filter(customer=request.user)
        serializer = self.serializer_class(addresses, many=True)
        return Response(serializer.data, status=status.HTTP_200_OK)

class AddressCreateView(APIView):
    permission_classes = [IsAuthenticatedCustomer]
    serializer_class = AddressSerializer

    def post(self, request, *args, **kwargs):
        """Creates a new address for the logged-in customer."""
        serializer = self.serializer_class(data=request.data)
        if serializer.is_valid():
            # Set the customer automatically based on the authenticated user
            serializer.save(customer=request.user)
            return Response(serializer.data, status=status.HTTP_201_CREATED)
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

class AddressUpdateView(APIView):
    permission_classes = [IsAuthenticatedCustomer]
    serializer_class = AddressSerializer

    def get_object(self, pk):
        try:
            # Ensure the address belongs to the requesting customer
            return Address.objects.get(pk=pk, customer=self.request.user)
        except Address.DoesNotExist:
            raise Http404

    def get(self, request, pk, *args, **kwargs):
        address = self.get_object(pk)
        serializer = self.serializer_class(address)
        return Response(serializer.data)

    def put(self, request, pk, *args, **kwargs):
        address = self.get_object(pk)
        # Allow partial updates with PUT as well for convenience
        serializer = self.serializer_class(address, data=request.data, partial=True) 
        if serializer.is_valid():
            # Customer is implicitly validated by get_object
            serializer.save()
            return Response(serializer.data)
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

    def patch(self, request, pk, *args, **kwargs):
        address = self.get_object(pk)
        serializer = self.serializer_class(address, data=request.data, partial=True)
        if serializer.is_valid():
            # Customer is implicitly validated by get_object
            serializer.save()
            return Response(serializer.data)
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

class AddressDeleteView(APIView):
    permission_classes = [IsAuthenticatedCustomer]

    def get_object(self, pk):
        try:
            # Ensure the address belongs to the requesting customer
            return Address.objects.get(pk=pk, customer=self.request.user)
        except Address.DoesNotExist:
            raise Http404

    def delete(self, request, pk, *args, **kwargs):
        address = self.get_object(pk)
        address.delete()
        return Response(status=status.HTTP_204_NO_CONTENT)

# --- Order Management Views --- 

class CustomerAddressListView(APIView):
    permission_classes = [permissions.IsAuthenticated] # TODO: Implement IsAuthenticatedCustomer
    def get(self, request, *args, **kwargs):
        # TODO: Implement list addresses logic
        return Response({'message': 'List addresses placeholder'}, status=status.HTTP_200_OK)

class CustomerAddressAddView(APIView):
    permission_classes = [permissions.IsAuthenticated] # TODO: Implement IsAuthenticatedCustomer
    def post(self, request, *args, **kwargs):
        # TODO: Implement add address logic
        return Response({'message': 'Add address placeholder'}, status=status.HTTP_201_CREATED)

class CustomerAddressUpdateView(APIView):
    permission_classes = [permissions.IsAuthenticated] # TODO: Implement IsAuthenticatedCustomer
    def put(self, request, pk, *args, **kwargs):
        # TODO: Implement update address logic using pk
        return Response({'message': f'Update address placeholder for pk={pk}'}, status=status.HTTP_200_OK)

class CustomerAddressDeleteView(APIView):
    permission_classes = [permissions.IsAuthenticated] # TODO: Implement IsAuthenticatedCustomer
    def delete(self, request, pk, *args, **kwargs):
        # TODO: Implement delete address logic using pk
        return Response(status=status.HTTP_204_NO_CONTENT)

class CustomerPlaceOrderView(APIView):
    permission_classes = [permissions.IsAuthenticated] # TODO: Implement IsAuthenticatedCustomer
    def post(self, request, *args, **kwargs):
        from core.models import Cart, CartItem, Order, OrderItem
        from .serializers import OrderSerializer
        customer_id = str(request.user.id)
        restaurant_id = request.data.get('restaurant_id')
        delivery_address_id = request.data.get('delivery_address_id')
        notes = request.data.get('notes', '')
        # Find cart
        try:
            cart = Cart.objects.get(customer_id_temp=customer_id)
            cart_items = CartItem.objects.filter(cart=cart)
            if not cart_items.exists():
                return Response({'error': 'Cart is empty.'}, status=status.HTTP_400_BAD_REQUEST)
        except Cart.DoesNotExist:
            return Response({'error': 'Cart not found.'}, status=status.HTTP_404_NOT_FOUND)
        # Calculate total
        total_amount = 0
        order_items = []
        for item in cart_items:
            # For now, price is not fetched from FoodItem; set as 0 or extend as needed
            price = 0
            order_items.append({'menu_item_id_temp': item.menu_item_id_temp, 'quantity': item.quantity, 'price': price})
        # Create Order
        order = Order.objects.create(
            customer_id_temp=customer_id,
            restaurant_id_temp=restaurant_id,
            delivery_address_id_temp=delivery_address_id,
            total_amount=total_amount,
            notes=notes
        )
        # Create OrderItems
        for item in cart_items:
            OrderItem.objects.create(
                order=order,
                menu_item_id_temp=item.menu_item_id_temp,
                quantity=item.quantity,
                price=0, # TODO: fetch actual price
                item_name_snapshot='',
                item_description_snapshot=''
            )
        # Clear cart
        cart_items.delete()
        serializer = OrderSerializer(order)
        return Response({
            'message': 'Order placed successfully',
            'order_id': order.id,
            'order': serializer.data
        }, status=status.HTTP_201_CREATED)

class CustomerOrderListView(APIView):
    permission_classes = [permissions.IsAuthenticated] # TODO: Implement IsAuthenticatedCustomer
    def get(self, request, *args, **kwargs):
        from core.models import Order
        from .serializers import OrderSerializer
        customer_id = str(request.user.id)
        orders = Order.objects.filter(customer_id_temp=customer_id).order_by('-created_at')
        serializer = OrderSerializer(orders, many=True)
        return Response(serializer.data, status=status.HTTP_200_OK)

class CustomerOrderDetailView(APIView):
    permission_classes = [permissions.IsAuthenticated] # TODO: Implement IsAuthenticatedCustomer
    def get(self, request, pk, *args, **kwargs):
        from core.models import Order
        from .serializers import OrderSerializer
        customer_id = str(request.user.id)
        try:
            order = Order.objects.get(pk=pk, customer_id_temp=customer_id)
            serializer = OrderSerializer(order)
            return Response(serializer.data, status=status.HTTP_200_OK)
        except Order.DoesNotExist:
            return Response({'error': 'Order not found.'}, status=status.HTTP_404_NOT_FOUND)

class CustomerOrderStatusView(APIView):
    permission_classes = [permissions.IsAuthenticated] # TODO: Implement IsAuthenticatedCustomer
    def get(self, request, pk, *args, **kwargs):
        from core.models import Order
        customer_id = str(request.user.id)
        try:
            order = Order.objects.get(pk=pk, customer_id_temp=customer_id)
            return Response({'status': order.status}, status=status.HTTP_200_OK)
        except Order.DoesNotExist:
            return Response({'error': 'Order not found.'}, status=status.HTTP_404_NOT_FOUND)

class CustomerOrderTrackView(APIView):
    permission_classes = [permissions.IsAuthenticated] # TODO: Implement IsAuthenticatedCustomer
    def get(self, request, pk, *args, **kwargs):
        from core.models import Order
        customer_id = str(request.user.id)
        try:
            order = Order.objects.get(pk=pk, customer_id_temp=customer_id)
            # For demo, just return status and timestamps
            data = {
                'status': order.status,
                'created_at': order.created_at,
                'accepted_at': order.accepted_at,
                'picked_up_at': order.picked_up_at,
                'delivered_at': order.delivered_at
            }
            return Response(data, status=status.HTTP_200_OK)
        except Order.DoesNotExist:
            return Response({'error': 'Order not found.'}, status=status.HTTP_404_NOT_FOUND)

class CustomerOrderRateView(APIView):
    permission_classes = [permissions.IsAuthenticated] # TODO: Implement IsAuthenticatedCustomer
    def post(self, request, pk, *args, **kwargs):
        # Placeholder: Implement order rating logic here (e.g., save rating to Order or related model)
        rating = request.data.get('rating')
        if rating is None:
            return Response({'error': 'Rating is required.'}, status=status.HTTP_400_BAD_REQUEST)
        # For now, just acknowledge receipt
        return Response({'message': 'Order rated successfully.'}, status=status.HTTP_200_OK)

from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework import status
from django.core.cache import cache
from .models import CustomerProfile
from core.utils import generate_access_token, generate_refresh_token # Import token generators
# import logging
from rest_framework.permissions import AllowAny



class RegisterCustomerView(APIView):
    permission_classes = [AllowAny] # Allow anyone to access this view

    def post(self, request, *args, **kwargs):
        print("--- RegisterCustomerView START ---")
        print(f"Received registration request data: {request.data}")
        signup_token = request.data.get('signup_token')
        email = request.data.get('email', '').lower().strip()
        first_name = request.data.get('first_name', '').strip()
        last_name = request.data.get('last_name', '').strip() # Optional

        print(f"Extracted signup_token: {signup_token}")

        if not all([signup_token, email, first_name]):
            print("Missing required fields: signup_token, email, or first_name")
            print("[RegisterCustomerView] Missing required fields in registration request.")
            return Response({'error': 'Missing required fields (signup_token, email, first_name are required).'}, status=status.HTTP_400_BAD_REQUEST)

        signup_token_cache_key = f'signup_token_{signup_token}'
        cached_data = cache.get(signup_token_cache_key)

        if not cached_data:
            print(f"[RegisterCustomerView] Invalid or expired signup token received: {signup_token[:10]}...")
            return Response({'error': 'Invalid or expired signup token.'}, status=status.HTTP_400_BAD_REQUEST)

        phone_number = cached_data.get('phone_number')
        if not phone_number:
             print(f"[RegisterCustomerView] Phone number not found in cache for valid token: {signup_token[:10]}...")
             # This case indicates an internal issue during token storage
             return Response({'error': 'Internal server error during registration.'}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)
        
        # Check if phone number or email already exists (should ideally not happen if token logic is sound)
        if CustomerProfile.objects.filter(phone_number=phone_number).exists():
            print(f"[RegisterCustomerView] Attempt to register with already existing phone number: {phone_number}")
            # Decide how to handle: Maybe return login tokens? Or error? For now, error.
            cache.delete(signup_token_cache_key) # Clean up token
            return Response({'error': 'Phone number already registered.'}, status=status.HTTP_409_CONFLICT)
            
        if CustomerProfile.objects.filter(email__iexact=email).exists():
             print(f"[RegisterCustomerView] Attempt to register with already existing email: {email}")
             # No need to delete token here, let user try again or login
             return Response({'error': 'Email address already registered.'}, status=status.HTTP_409_CONFLICT)

        try:
            # Create the customer profile
            new_customer = CustomerProfile.objects.create(
                phone_number=phone_number,
                first_name=first_name,
                last_name=last_name or '', # Handle optional last name
                email=email,
                is_active=True # Activate user upon registration
            )
            print(f"[RegisterCustomerView] Successfully created CustomerProfile for phone: {phone_number}")

            # Registration successful, delete the signup token
            cache.delete(signup_token_cache_key)

            # Generate JWT tokens for the newly created user
            access_token = generate_access_token(new_customer)
            refresh_token = generate_refresh_token(new_customer)

            return Response({
                'message': 'Registration successful.',
                'access_token': access_token,
                'refresh_token': refresh_token
                # Optionally include basic user info if needed by frontend immediately
                # 'user': { 'id': customer.id, 'first_name': customer.first_name, ... }
            }, status=status.HTTP_201_CREATED)

        except Exception as e:
            print(f"[RegisterCustomerView] Error creating customer profile for phone {phone_number}: {e}")
            # Don't delete the token on creation failure, user might retry
            return Response({'error': 'Failed to create profile.'}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)
