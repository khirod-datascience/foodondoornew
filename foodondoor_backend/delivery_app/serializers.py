from rest_framework import serializers
from .models import DeliveryAgentProfile
from core.models import Order, OrderItem

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
            'id', 'customer_id_temp', 'restaurant_id_temp', 'delivery_agent_id_temp', 'delivery_address_id_temp',
            'total_amount', 'status', 'notes', 'created_at', 'accepted_at', 'picked_up_at', 'delivered_at', 'updated_at',
            'vendor_pickup_otp', 'customer_delivery_otp', 'items'
        ]
        read_only_fields = fields

class DeliveryAgentRegistrationSerializer(serializers.ModelSerializer):
    password = serializers.CharField(write_only=True, required=False, allow_blank=True, style={'input_type': 'password'})

    class Meta:
        model = DeliveryAgentProfile
        # Include fields needed for registration, like phone number, email (optional), names, vehicle info
        fields = (
            'id', 'phone_number', 'email', 'password', 'first_name', 'last_name',
            'vehicle_type', 'vehicle_details', 'fcm_token'
        )
        read_only_fields = ('id',)
        extra_kwargs = {
            'phone_number': {'required': False, 'allow_blank': True},
        }

    def create(self, validated_data):
        # Use the set_password method to hash the password if provided
        agent = DeliveryAgentProfile.objects.create(
            phone_number=validated_data['phone_number'], # Assuming phone is required
            email=validated_data.get('email'),
            first_name=validated_data.get('first_name', ''),
            last_name=validated_data.get('last_name', ''),
            vehicle_type=validated_data.get('vehicle_type'),
            vehicle_details=validated_data.get('vehicle_details'),
            fcm_token=validated_data.get('fcm_token')
        )
        password = validated_data.get('password')
        if password:
            agent.set_password(password)
        agent.save()
        return agent

class DeliveryAgentProfileSerializer(serializers.ModelSerializer):
    """Serializer for viewing/updating delivery agent profile data (excluding password)."""
    class Meta:
        model = DeliveryAgentProfile
        # Include fields relevant for viewing/updating the profile by the agent or admin
        fields = (
            'id', 'phone_number', 'email', 'first_name', 'last_name',
            'vehicle_type', 'vehicle_details', 'current_latitude', 'current_longitude',
            'is_available', 'profile_picture', 'fcm_token',
            'is_active', 'is_approved', 'created_at', 'updated_at'
        )
        read_only_fields = (
            'id', 'phone_number', 'email', 'is_active', 'is_approved',
            'created_at', 'updated_at'
        ) # Assuming phone/email not changeable, status managed by admin
