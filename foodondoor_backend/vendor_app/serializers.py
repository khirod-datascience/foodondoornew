from rest_framework import serializers
from .models import VendorProfile, Restaurant, Category, FoodItem
from django.db.models import Q

class VendorRegistrationSerializer(serializers.ModelSerializer):
    class Meta:
        model = VendorProfile
        fields = ('id', 'email', 'phone_number', 'company_name', 'fcm_token') 
        read_only_fields = ('id', 'phone_number') 

    def create(self, validated_data):
        # Phone number is retrieved from cache in the view and passed via save()
        # It will be present in validated_data here.
        vendor = VendorProfile.objects.create(
            email=validated_data.get('email'),
            phone_number=validated_data.get('phone_number'),
            company_name=validated_data.get('company_name', ''),
            fcm_token=validated_data.get('fcm_token')
        )
        vendor.save()
        return vendor

class VendorProfileSerializer(serializers.ModelSerializer):
    """Serializer for viewing/updating vendor profile data (excluding password)."""
    class Meta:
        model = VendorProfile
        fields = ('id', 'email', 'phone_number', 'company_name', 'fcm_token', 'is_active', 'is_approved', 'created_at', 'updated_at') 
        read_only_fields = ('id', 'email', 'phone_number', 'is_active', 'is_approved', 'created_at', 'updated_at') 

# --- Restaurant/Menu Serializers ---

class FoodItemSerializer(serializers.ModelSerializer):
    """
    Serializer for the FoodItem model.
    Handles validation and conversion for food item data.
    """
    category_id = serializers.PrimaryKeyRelatedField(
        queryset=Category.objects.all(), source='category', write_only=True
    )
    category_name = serializers.CharField(source='category.name', read_only=True)
    image_url = serializers.SerializerMethodField() # Use SerializerMethodField for full URL

    class Meta:
        model = FoodItem
        fields = [
            'id', 
            'restaurant', # Should be read_only or set automatically in the view
            'category_id', # Use this for writing
            'category', # Keep this for reading nested category info if needed, mark read_only
            'category_name', # Read-only category name
            'name', 
            'description', 
            'price', 
            'image', # The actual ImageField for upload (write-only or handled separately)
            'image_url', # Read-only full URL for display
            'is_available', 
            'is_vegetarian', 
            'created_at',
            'updated_at'
        ]
        read_only_fields = ['id', 'restaurant', 'category', 'category_name', 'image_url', 'created_at', 'updated_at']
        extra_kwargs = {
            'image': {'write_only': True, 'required': False}, # Image field is for upload only, not required
            'category': {'read_only': True}, # Make the nested serializer read-only
        }

    def get_image_url(self, obj):
        request = self.context.get('request')
        if obj.image and hasattr(obj.image, 'url'):
            # If request is available, build the absolute URL
            if request is not None:
                return request.build_absolute_uri(obj.image.url)
            # Otherwise, return the relative URL (less ideal but better than nothing)
            return obj.image.url
        return None # Return None if no image

    def validate_category_id(self, value):
        """Ensure the selected category belongs to the vendor's restaurant."""

class CategorySerializer(serializers.ModelSerializer):
    """Serializer for Category model."""
    food_items = FoodItemSerializer(many=True, read_only=True) 

    class Meta:
        model = Category
        fields = ('id', 'restaurant', 'name', 'description', 'food_items', 'created_at', 'updated_at')
        read_only_fields = ('id', 'restaurant', 'created_at', 'updated_at') 

class RestaurantSerializer(serializers.ModelSerializer):
    """Serializer for Restaurant model."""
    categories = CategorySerializer(many=True, read_only=True)

    class Meta:
        model = Restaurant
        fields = (
            'id', 'vendor', 'name', 'description', 'address', 'city', 'state', 
            'postal_code', 'phone_number', 'logo_url', 'cover_photo_url', 
            'latitude', 'longitude', 'is_active', 'categories', 
            'created_at', 'updated_at'
        )
        read_only_fields = ('id', 'vendor', 'created_at', 'updated_at')
