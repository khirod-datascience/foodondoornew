from rest_framework import serializers
from .models import CustomerProfile, Address

class CustomerRegistrationSerializer(serializers.ModelSerializer):
    password = serializers.CharField(write_only=True, required=False, allow_blank=True, style={'input_type': 'password'})

    class Meta:
        model = CustomerProfile
        fields = ('id', 'email', 'password', 'first_name', 'last_name', 'fcm_token', 'phone_number')
        read_only_fields = ('id', 'phone_number')
        extra_kwargs = {
            'phone_number': {'required': False, 'allow_blank': True},
        }

    def create(self, validated_data):
        customer = CustomerProfile(
            email=validated_data.get('email'),
            phone_number=validated_data.get('phone_number'),
            first_name=validated_data.get('first_name', ''),
            last_name=validated_data.get('last_name', ''),
            fcm_token=validated_data.get('fcm_token')
        )
        password = validated_data.get('password')
        if password:
            customer.set_password(password)
        customer.save()
        return customer

class CustomerProfileSerializer(serializers.ModelSerializer):
    """Serializer for viewing/updating customer profile data (excluding password)."""
    class Meta:
        model = CustomerProfile
        fields = ('id', 'email', 'phone_number', 'first_name', 'last_name', 'fcm_token', 'is_active', 'created_at', 'updated_at')
        read_only_fields = ('id', 'phone_number', 'is_active', 'created_at', 'updated_at')

class AddressSerializer(serializers.ModelSerializer):
    """Serializer for the Address model."""
    # Optionally make customer read-only if it's always set implicitly from the request user
    # customer = serializers.PrimaryKeyRelatedField(read_only=True)

    class Meta:
        model = Address
        fields = (
            'id', 
            'customer', # Keep customer field for potential admin use or explicit setting?
            'address_line1', 
            'address_line2', 
            'city', 
            'state', 
            'postal_code', 
            'country', 
            'address_type', 
            'is_default',
            'created_at',
            'updated_at'
        )
        read_only_fields = ('id', 'customer', 'created_at', 'updated_at') # Set customer read-only here

    def validate(self, data):
        # If creating/updating and setting is_default=True, handle the logic
        # The model's save method handles enforcing only one default, 
        # but you could add validation here if needed before hitting the DB.
        return data

# --- Cart and Order Serializers ---
from core.models import Cart, CartItem, Order, OrderItem

class CartItemSerializer(serializers.ModelSerializer):
    class Meta:
        model = CartItem
        fields = ['id', 'menu_item_id_temp', 'quantity', 'added_at']

class CartSerializer(serializers.ModelSerializer):
    items = CartItemSerializer(many=True, read_only=True)
    class Meta:
        model = Cart
        fields = ['id', 'customer_id_temp', 'created_at', 'updated_at', 'items']

class OrderItemSerializer(serializers.ModelSerializer):
    class Meta:
        model = OrderItem
        fields = [
            'id', 'menu_item_id_temp', 'quantity', 'price', 'item_name_snapshot', 'item_description_snapshot'
        ]

class OrderSerializer(serializers.ModelSerializer):
    items = OrderItemSerializer(many=True, read_only=True)
    class Meta:
        model = Order
        fields = [
            'id', 'customer_id_temp', 'restaurant_id_temp', 'delivery_agent_id_temp',
            'delivery_address_id_temp', 'total_amount', 'status', 'notes',
            'created_at', 'accepted_at', 'picked_up_at', 'delivered_at', 'updated_at',
            'vendor_pickup_otp', 'customer_delivery_otp', 'items'
        ]

# --- Placeholder Serializers (Need Implementation/Refinement) --- 
# Add other serializers as needed, e.g., for Banners, Restaurants, etc.
