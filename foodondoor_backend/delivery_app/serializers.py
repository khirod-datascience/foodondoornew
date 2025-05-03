from rest_framework import serializers
from .models import DeliveryAgentProfile

class DeliveryAgentRegistrationSerializer(serializers.ModelSerializer):
    password = serializers.CharField(write_only=True, required=True, style={'input_type': 'password'})

    class Meta:
        model = DeliveryAgentProfile
        # Include fields needed for registration, like phone number, email (optional), names, vehicle info
        fields = (
            'id', 'phone_number', 'email', 'password', 'first_name', 'last_name',
            'vehicle_type', 'vehicle_details', 'fcm_token'
        )
        read_only_fields = ('id',)

    def create(self, validated_data):
        # Use the set_password method to hash the password
        agent = DeliveryAgentProfile.objects.create(
            phone_number=validated_data['phone_number'], # Assuming phone is required
            email=validated_data.get('email'),
            first_name=validated_data.get('first_name', ''),
            last_name=validated_data.get('last_name', ''),
            vehicle_type=validated_data.get('vehicle_type'),
            vehicle_details=validated_data.get('vehicle_details'),
            fcm_token=validated_data.get('fcm_token')
        )
        agent.set_password(validated_data['password'])
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
