from django.shortcuts import render
from django.core.cache import cache
from rest_framework import generics, permissions, status, views
from rest_framework.response import Response
from rest_framework.views import APIView
from django.db.models import Q
from django.core.cache import cache
from django.conf import settings
import jwt

from .models import VendorProfile, Restaurant, Category, FoodItem
from .serializers import VendorProfileSerializer, VendorRegistrationSerializer, RestaurantSerializer, CategorySerializer, FoodItemSerializer
from core.utils import generate_access_token, generate_refresh_token
from core.permissions import IsAuthenticatedVendor
from rest_framework.exceptions import PermissionDenied, NotFound
from django.http import Http404

# Create your views here.

class VendorRegistrationView(APIView):
    """
    Handles the final step of vendor registration after OTP verification.
    Requires a valid signup_token and vendor profile data.
    Creates the vendor profile and returns auth tokens.
    """
    permission_classes = [permissions.AllowAny] # Allow access with signup_token

    def post(self, request, *args, **kwargs):
        print("[VendorRegistrationView] Received registration request")
        serializer = VendorRegistrationSerializer(data=request.data)
        signup_token = request.data.get('signup_token')

        if not signup_token:
            print("[VendorRegistrationView] Error: signup_token missing")
            return Response({'error': 'Signup token is required.'}, status=status.HTTP_400_BAD_REQUEST)

        # 1. Verify signup_token and get phone number from cache
        signup_token_cache_key = f'signup_token_{signup_token}'
        cached_data = cache.get(signup_token_cache_key)

        if not cached_data:
            print(f"[VendorRegistrationView] Error: Invalid or expired signup token: {signup_token}")
            return Response({'error': 'Invalid or expired signup token.'}, status=status.HTTP_400_BAD_REQUEST)
        
        phone_number = cached_data.get('phone_number')
        if not phone_number:
             print(f"[VendorRegistrationView] Error: Phone number not found in cache for token: {signup_token}")
             return Response({'error': 'Could not retrieve phone number for registration.'}, status=status.HTTP_500_INTERNAL_SERVER_ERROR) # Should not happen

        print(f"[VendorRegistrationView] Valid signup token found for phone: {phone_number}")

        # 2. Validate incoming profile data
        if serializer.is_valid():
            print("[VendorRegistrationView] Profile data is valid.")
            # 3. Check if vendor with this phone number already exists (safety check)
            if VendorProfile.objects.filter(phone_number=phone_number).exists():
                print(f"[VendorRegistrationView] Error: Vendor profile already exists for {phone_number}")
                # Consider deleting the signup token cache entry here? 
                # cache.delete(signup_token_cache_key)
                return Response({'error': 'A vendor profile with this phone number already exists.'}, status=status.HTTP_409_CONFLICT)
            
            # 4. Create the vendor profile
            try:
                print(f"[VendorRegistrationView] Creating vendor profile for {phone_number}...")
                vendor = serializer.save(phone_number=phone_number, is_active=True)
                vendor.is_approved = True
                vendor.save()
                print(f"[VendorRegistrationView] Vendor profile created: {vendor.pk}")

                # --- Create and link a default Restaurant ---
                try:
                    restaurant_name = serializer.validated_data.get('company_name', f"Restaurant for {vendor.email}")
                    print(f"[VendorRegistrationView] Creating default restaurant '{restaurant_name}' for vendor {vendor.pk}...")
                    Restaurant.objects.create(
                        vendor=vendor,
                        name=restaurant_name,
                        # Add default values for other required fields if any, e.g.:
                        # description="Default description", 
                        # address_line1="Default address",
                        # city="Default City",
                        # postal_code="00000",
                        # is_active=True 
                    )
                    print(f"[VendorRegistrationView] Default restaurant created and linked for vendor {vendor.pk}.")
                except Exception as restaurant_exc:
                    # Log the error, but don't fail the registration if restaurant creation fails for now
                    print(f"[VendorRegistrationView] WARNING: Failed to create default restaurant for vendor {vendor.pk}: {restaurant_exc}")
                # ---------------------------------------------

            except Exception as e:
                print(f"[VendorRegistrationView] Error saving vendor profile: {e}")
                return Response({'error': 'Failed to create vendor profile.'}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)

            # 5. Generate tokens
            print("[VendorRegistrationView] Generating tokens...")
            access_token = generate_access_token(vendor)
            refresh_token = generate_refresh_token(vendor)
            print("[VendorRegistrationView] Tokens generated.")

            # 6. Clear the signup token from cache
            cache.delete(signup_token_cache_key)
            print(f"[VendorRegistrationView] Deleted signup token from cache: {signup_token_cache_key}")

            # 7. Return tokens
            return Response({
                'message': 'Vendor registered successfully.',
                'access': access_token,
                'refresh': refresh_token
            }, status=status.HTTP_201_CREATED)
        else:
            print(f"[VendorRegistrationView] Error: Invalid profile data: {serializer.errors}")
            return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

class VendorProfileView(generics.RetrieveUpdateAPIView):
    """
    Allows authenticated vendors to retrieve and update their profile.
    Handles GET (retrieve) and PUT/PATCH (update) requests.
    """
    serializer_class = VendorProfileSerializer
    permission_classes = [IsAuthenticatedVendor]  # Use custom permission for vendor

    def get_object(self):
        # Use request.profile provided by the authentication backend
        vendor_profile = getattr(self.request, 'profile', None)
        if not isinstance(vendor_profile, VendorProfile):
            raise PermissionDenied('Authenticated user is not a vendor.')
        return vendor_profile

    def perform_update(self, serializer):
        vendor_profile = self.get_object()
        serializer.save()

    def get_queryset(self):
        return VendorProfile.objects.none()  # Not used

class VendorRestaurantView(generics.RetrieveUpdateAPIView):
    """
    Allows vendors to retrieve and update their associated restaurant details.
    Assumes a one-to-one relationship between VendorProfile and Restaurant.
    GET: Retrieve the restaurant details.
    PUT/PATCH: Update the restaurant details.
    Requires the vendor to be authenticated and approved.
    """
    serializer_class = RestaurantSerializer
    permission_classes = [permissions.IsAuthenticated] # TODO: Refine with IsAuthenticatedVendor if needed

    def get(self, request, *args, **kwargs):
        vendor_profile = getattr(request, 'profile', None)
        print(f"[VendorRestaurantView GET] VendorProfile: {vendor_profile}, Is Approved: {getattr(vendor_profile, 'is_approved', 'N/A')}")
        if not getattr(vendor_profile, 'is_approved', False):
            return Response({'detail': 'VendorProfile account is not approved.'}, status=status.HTTP_403_FORBIDDEN)
        restaurant = self.get_object()
        serializer = RestaurantSerializer(restaurant)
        return Response(serializer.data)

    def get_object(self):
        """Fetch the restaurant associated with the authenticated vendor."""
        # self.request.profile should be the authenticated VendorProfile instance
        vendor_profile = getattr(self.request, 'profile', None)
        print(f"[VendorRestaurantView] Attempting to get restaurant for vendor: {vendor_profile.id} ({vendor_profile.phone_number})")
        try:
            # Attempt to retrieve the restaurant linked to this vendor
            restaurant = Restaurant.objects.get(vendor=vendor_profile)
            print(f"[VendorRestaurantView] Found restaurant: {restaurant.id} ({restaurant.name})")
            return restaurant
        except Restaurant.DoesNotExist:
            print(f"[VendorRestaurantView] Restaurant not found for vendor: {vendor_profile.id}")
            # Raise NotFound, which results in a 404 response
            raise Http404("Restaurant details not found for this vendor.")
        except Exception as e:
             print(f"[VendorRestaurantView] Error getting restaurant for vendor {vendor_profile.id}: {e}")
             raise Http404("An error occurred while fetching restaurant details.") # Generic error

    def get_queryset(self):
        """
        Define queryset for schema generation and permission checks.
        Filters based on the logged-in vendor.
        """
        if not self.request.user.is_authenticated:
            return Restaurant.objects.none()
        vendor_profile = getattr(self.request, 'profile', None)
        if not vendor_profile:
            return Restaurant.objects.none()
        if not getattr(vendor_profile, 'is_approved', False):
            return Restaurant.objects.none()
        return Restaurant.objects.filter(vendor=vendor_profile)

class VendorCategoryListCreateView(generics.ListCreateAPIView):
    """
    Allows authenticated vendors to list their restaurant's categories
    or create a new category for their restaurant.
    """
    serializer_class = CategorySerializer
    permission_classes = [permissions.IsAuthenticated] # Ensures only logged-in vendors

    def get_queryset(self):
        """Return categories only for the logged-in vendor's restaurant."""
        vendor_profile = getattr(self.request, 'profile', None)
        if not isinstance(vendor_profile, VendorProfile):
             raise PermissionDenied("Authentication credentials were not provided or are invalid.")
        if not getattr(vendor_profile, 'is_approved', False):
            return Category.objects.none()
        try:
            # Get the restaurant associated with the vendor
            restaurant = vendor_profile.restaurant
            return Category.objects.filter(restaurant=restaurant)
        except Restaurant.DoesNotExist:
            # Vendor has no restaurant setup, so they have no categories
            return Category.objects.none()
        except AttributeError:
            # Handle case where request.profile might not have a 'restaurant' attribute (shouldn't happen with VendorProfile)
             print(f"[VendorCategoryListCreateView] Error: VendorProfile {getattr(vendor_profile, 'id', None)} missing 'restaurant' attribute.")
             return Category.objects.none()

    def perform_create(self, serializer):
        """Associate the new category with the logged-in vendor's restaurant."""
        vendor_profile = getattr(self.request, 'profile', None)
        if not getattr(vendor_profile, 'is_approved', False):
            return Response({'detail': 'VendorProfile account is not approved.'}, status=status.HTTP_403_FORBIDDEN)
        try:
            restaurant = vendor_profile.restaurant
            # Check for uniqueness within the restaurant before saving
            category_name = serializer.validated_data.get('name')
            if Category.objects.filter(restaurant=restaurant, name=category_name).exists():
                 from rest_framework.exceptions import ValidationError
                 raise ValidationError({'name': f'Category with name "{category_name}" already exists for this restaurant.'})

            serializer.save(restaurant=restaurant)
        except Restaurant.DoesNotExist:
            from rest_framework.exceptions import ValidationError
            raise ValidationError("Vendor does not have an associated restaurant. Cannot create category.")
        except AttributeError:
            from rest_framework.exceptions import ValidationError
            raise ValidationError("Could not determine the vendor's restaurant.")

class VendorCategoryDetailView(generics.RetrieveUpdateDestroyAPIView):
    """
    Allows authenticated vendors to retrieve, update, or delete
    a specific category belonging to their restaurant.
    """
    serializer_class = CategorySerializer
    permission_classes = [permissions.IsAuthenticated]
    queryset = Category.objects.all() # Initial queryset, will be filtered by get_queryset
    lookup_field = 'pk' # Default, but explicit

    def get_queryset(self):
        """Ensure vendors can only access categories from their own restaurant."""
        vendor_profile = getattr(self.request, 'profile', None)
        if not isinstance(vendor_profile, VendorProfile):
            raise PermissionDenied("Authentication credentials were not provided or are invalid.")
        if not getattr(vendor_profile, 'is_approved', False):
            return Category.objects.none()
        try:
            restaurant = vendor_profile.restaurant
            return Category.objects.filter(restaurant=restaurant)
        except Restaurant.DoesNotExist:
            return Category.objects.none()
        except AttributeError:
             print(f"[VendorCategoryDetailView] Error: VendorProfile {getattr(vendor_profile, 'id', None)} missing 'restaurant' attribute.")
             return Category.objects.none()
        
    def perform_update(self, serializer):
        # Optional: Add validation before update if needed
        # Example: Check uniqueness of new name within the restaurant
        vendor_profile = getattr(self.request, 'profile', None)
        if not getattr(vendor_profile, 'is_approved', False):
            return Response({'detail': 'VendorProfile account is not approved.'}, status=status.HTTP_403_FORBIDDEN)
        instance = self.get_object() # The category being updated
        new_name = serializer.validated_data.get('name', instance.name)
        
        # Check if another category with the new name already exists in the same restaurant
        if Category.objects.filter(restaurant=instance.restaurant, name=new_name).exclude(pk=instance.pk).exists():
            from rest_framework.exceptions import ValidationError
            raise ValidationError({'name': f'Another category with name "{new_name}" already exists for this restaurant.'})
            
        serializer.save()

class VendorMenuItemListCreateView(generics.ListCreateAPIView):
    """
    Allows authenticated vendors to list their restaurant's food items
    or create a new food item for their restaurant.
    """
    serializer_class = FoodItemSerializer
    permission_classes = [permissions.IsAuthenticated]

    def get_queryset(self):
        """Return food items only for the logged-in vendor's restaurant."""
        vendor_profile = getattr(self.request, 'profile', None)
        print(f"[VendorMenuItemListCreateView GET Queryset] VendorProfile: {vendor_profile}, Is Approved: {getattr(vendor_profile, 'is_approved', 'N/A')}")

        if not isinstance(vendor_profile, VendorProfile):
            raise PermissionDenied("Authentication credentials were not provided or are invalid.")
        if not getattr(vendor_profile, 'is_approved', False):
            return FoodItem.objects.none()
        try:
            restaurant = vendor_profile.restaurant
            return FoodItem.objects.filter(restaurant=restaurant)
        except Restaurant.DoesNotExist:
            return FoodItem.objects.none()
        except AttributeError:
            print(f"[VendorMenuItemListCreateView] Error: VendorProfile {getattr(vendor_profile, 'id', None)} missing 'restaurant' attribute.")
            return FoodItem.objects.none()

    def perform_create(self, serializer):
        """Associate the new food item with the logged-in vendor's restaurant and category."""
        user = self.request.user
        if not getattr(user, 'is_approved', False):
            return Response({'detail': 'VendorProfile account is not approved.'}, status=status.HTTP_403_FORBIDDEN)
        try:
            restaurant = user.restaurant
            # Ensure the selected category belongs to this restaurant
            category_id = serializer.validated_data.get('category').id
            category = Category.objects.get(pk=category_id, restaurant=restaurant)
            
            # Check uniqueness of item name within the restaurant
            item_name = serializer.validated_data.get('name')
            if FoodItem.objects.filter(restaurant=restaurant, name=item_name).exists():
                 from rest_framework.exceptions import ValidationError
                 raise ValidationError({'name': f'Food item with name "{item_name}" already exists for this restaurant.'})

            serializer.save(restaurant=restaurant, category=category)
        except Restaurant.DoesNotExist:
            from rest_framework.exceptions import ValidationError
            raise ValidationError("Vendor does not have an associated restaurant.")
        except Category.DoesNotExist:
            from rest_framework.exceptions import ValidationError
            raise ValidationError("Invalid category selected or category does not belong to this restaurant.")
        except AttributeError:
             from rest_framework.exceptions import ValidationError
             raise ValidationError("Could not determine the vendor's restaurant or category.")

    def get_serializer_context(self):
        """Pass request context to the serializer."""
        context = super().get_serializer_context()
        context.update({'request': self.request})
        return context

class VendorMenuItemDetailView(generics.RetrieveUpdateDestroyAPIView):
    """
    Allows authenticated vendors to retrieve, update, or delete
    a specific food item belonging to their restaurant.
    """
    serializer_class = FoodItemSerializer
    permission_classes = [permissions.IsAuthenticated]
    queryset = FoodItem.objects.all() # Initial queryset
    lookup_field = 'pk' # Use the primary key (UUID) for lookup

    def get_queryset(self):
        vendor_profile = getattr(self.request, 'profile', None)
        if not getattr(vendor_profile, 'is_approved', False):
            return FoodItem.objects.none()
        try:
            restaurant = vendor_profile.restaurant
            return FoodItem.objects.filter(restaurant=restaurant)
        except Restaurant.DoesNotExist:
            return FoodItem.objects.none()
        except AttributeError:
            print(f"[VendorMenuItemDetailView] Error: VendorProfile {getattr(vendor_profile, 'id', None)} missing 'restaurant' attribute.")
            return FoodItem.objects.none()

    def get(self, request, *args, **kwargs):
        """GET /menu/<uuid:pk>/ - Retrieve menu item"""
        return super().get(request, *args, **kwargs)

    def put(self, request, *args, **kwargs):
        """PUT /menu/<uuid:pk>/update/ - Update menu item"""
        if request.path.endswith('/update/'):
            return super().put(request, *args, **kwargs)
        return Response({'detail': 'Method "PUT" not allowed on this endpoint.'}, status=405)

    def delete(self, request, *args, **kwargs):
        """DELETE /menu/<uuid:pk>/delete/ - Delete menu item"""
        if request.path.endswith('/delete/'):
            return super().delete(request, *args, **kwargs)
        return Response({'detail': 'Method "DELETE" not allowed on this endpoint.'}, status=405)

    def perform_update(self, serializer):
        vendor_profile = getattr(self.request, 'profile', None)
        if not getattr(vendor_profile, 'is_approved', False):
            raise PermissionDenied('VendorProfile account is not approved.')
        instance = self.get_object() # The item being updated
        new_name = serializer.validated_data.get('name', instance.name)
        
        # Check uniqueness of new name within the restaurant (excluding self)
        if FoodItem.objects.filter(restaurant=instance.restaurant, name=new_name).exclude(pk=instance.pk).exists():
            from rest_framework.exceptions import ValidationError
            raise ValidationError({'name': f'Another food item with name "{new_name}" already exists for this restaurant.'})
        
        # Ensure the category (if changed) belongs to the restaurant
        if 'category' in serializer.validated_data:
            try:
                category = serializer.validated_data['category']
                if category.restaurant != instance.restaurant:
                    raise ValidationError({'category': 'Selected category does not belong to this restaurant.'})
            except Category.DoesNotExist:
                 raise ValidationError({'category': 'Invalid category selected.'})
        
        serializer.save()

    def get_serializer_context(self):
        """Pass request context to the serializer."""
        context = super().get_serializer_context()
        context.update({'request': self.request})
        return context

class VendorProfileUpdateView(APIView):
    permission_classes = [permissions.IsAuthenticated] # TODO: Use IsAuthenticatedVendor
    def put(self, request, *args, **kwargs):
        # TODO: Implement profile update logic
        return Response({'message': 'Vendor profile update placeholder'}, status=status.HTTP_200_OK)

class VendorOrderListView(APIView):
    permission_classes = [permissions.IsAuthenticated] # TODO: Use IsAuthenticatedVendor
    def get(self, request, *args, **kwargs):
        # Block unapproved vendors
        vendor_profile = getattr(request, 'profile', None)
        if not getattr(vendor_profile, 'is_approved', False):
            return Response({'detail': 'VendorProfile account is not approved.'}, status=status.HTTP_403_FORBIDDEN)
        # TODO: Implement vendor order list logic
        return Response({'message': 'Vendor order list placeholder'}, status=status.HTTP_200_OK)

class VendorOrderAcceptView(APIView):
    permission_classes = [permissions.IsAuthenticated] # TODO: Use IsAuthenticatedVendor
    def post(self, request, pk, *args, **kwargs):
        # TODO: Implement order accept logic using pk
        return Response({'message': f'Vendor order accept placeholder for pk={pk}'}, status=status.HTTP_200_OK)

class VendorOrderRejectView(APIView):
    permission_classes = [permissions.IsAuthenticated] # TODO: Use IsAuthenticatedVendor
    def post(self, request, pk, *args, **kwargs):
        # TODO: Implement order reject logic using pk
        return Response({'message': f'Vendor order reject placeholder for pk={pk}'}, status=status.HTTP_200_OK)

class VendorOrderReadyView(APIView):
    permission_classes = [permissions.IsAuthenticated] # TODO: Use IsAuthenticatedVendor
    def post(self, request, pk, *args, **kwargs):
        # Accepts status param and updates order status accordingly
        status_value = request.data.get('status')
        if not status_value:
            return Response({'error': 'Missing status parameter.'}, status=status.HTTP_400_BAD_REQUEST)
        # TODO: Implement logic to update order status (accepted, preparing, ready, etc.)
        # Example:
        # order = get_object_or_404(Order, pk=pk, vendor=request.user)
        # order.status = status_value
        # order.save()
        return Response({'message': f'Order {pk} status updated to {status_value}.'}, status=status.HTTP_200_OK)
