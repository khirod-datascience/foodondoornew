from rest_framework import serializers
from .models import CustomerProfile, Address

class CustomerRegistrationSerializer(serializers.ModelSerializer):
    password = serializers.CharField(write_only=True, required=True, style={'input_type': 'password'})

    class Meta:
        model = CustomerProfile
        fields = ('id', 'email', 'password', 'first_name', 'last_name', 'fcm_token', 'phone_number')
        read_only_fields = ('id', 'phone_number')

    def create(self, validated_data):
        customer = CustomerProfile(
            email=validated_data.get('email'),
            phone_number=validated_data.get('phone_number'),
            first_name=validated_data.get('first_name', ''),
            last_name=validated_data.get('last_name', ''),
            fcm_token=validated_data.get('fcm_token')
        )
        customer.set_password(validated_data['password'])
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

# --- Placeholder Serializers (Need Implementation/Refinement) --- 
# Add other serializers as needed, e.g., for Banners, Restaurants, etc.
