from django.db import models
from django.utils import timezone
import uuid
from django.contrib.auth.hashers import make_password, check_password
from django.conf import settings # If needed for related user

# Create your models here.

class VendorProfile(models.Model):
    """Independent model for vendor data and authentication."""
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    email = models.EmailField(unique=True, blank=True, null=True)
    phone_number = models.CharField(max_length=15, unique=True, blank=False)
    company_name = models.CharField(max_length=200, blank=True)
    contact_person = models.CharField(max_length=150, blank=True)
    fcm_token = models.CharField(max_length=255, blank=True, null=True, help_text="Firebase Cloud Messaging device token")
    is_active = models.BooleanField(default=True, help_text="Designates whether this vendor should be treated as active.")
    is_approved = models.BooleanField(default=False, help_text="Designates whether the admin has approved this vendor.") # Example vendor-specific field
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    # OTP Fields
    otp_code = models.CharField(max_length=6, blank=True, null=True)
    otp_expiry = models.DateTimeField(blank=True, null=True)

    def __str__(self):
        return self.company_name or self.email or str(self.id)

    USERNAME_FIELD = 'phone_number'
    REQUIRED_FIELDS = ['email'] # Adjust as needed

    class Meta:
        verbose_name = 'Vendor Profile'
        verbose_name_plural = 'Vendor Profiles'

class Restaurant(models.Model):
    """Model representing a restaurant managed by a vendor."""
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    vendor = models.OneToOneField(VendorProfile, on_delete=models.CASCADE, related_name='restaurant')
    name = models.CharField(max_length=255)
    description = models.TextField(blank=True, null=True)
    address = models.CharField(max_length=255)
    city = models.CharField(max_length=100)
    state = models.CharField(max_length=100)
    postal_code = models.CharField(max_length=20)
    phone_number = models.CharField(max_length=20, blank=True, null=True)
    # logo = models.ImageField(upload_to='restaurant_logos/', blank=True, null=True)
    logo_url = models.URLField(max_length=500, blank=True, null=True) # Using URLField for simplicity
    cover_photo_url = models.URLField(max_length=500, blank=True, null=True) # Using URLField
    latitude = models.DecimalField(max_digits=9, decimal_places=6, blank=True, null=True)
    longitude = models.DecimalField(max_digits=9, decimal_places=6, blank=True, null=True)
    is_active = models.BooleanField(default=True, help_text="Whether the restaurant is currently accepting orders.")
    # Add fields like opening_hours, average_rating, etc. as needed
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    def __str__(self):
        return self.name

    class Meta:
        verbose_name = 'Restaurant'
        verbose_name_plural = 'Restaurants'

class Category(models.Model):
    """Represents a category of food items within a restaurant's menu."""
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    restaurant = models.ForeignKey(Restaurant, on_delete=models.CASCADE, related_name='categories')
    name = models.CharField(max_length=100)
    description = models.CharField(max_length=255, blank=True, null=True)
    # position = models.PositiveIntegerField(default=0, help_text="Order in which category appears")
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    def __str__(self):
        return f"{self.name} ({self.restaurant.name})"

    class Meta:
        verbose_name = 'Menu Category'
        verbose_name_plural = 'Menu Categories'
        # Optionally order by name or position
        # ordering = ['position', 'name']
        unique_together = ('restaurant', 'name') # Ensure category names are unique per restaurant

class FoodItem(models.Model):
    """Represents a single food item on the menu."""
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    category = models.ForeignKey(Category, on_delete=models.CASCADE, related_name='food_items')
    restaurant = models.ForeignKey(Restaurant, on_delete=models.CASCADE, related_name='food_items') # Direct link for easier querying
    name = models.CharField(max_length=255)
    description = models.TextField(blank=True, null=True)
    price = models.DecimalField(max_digits=10, decimal_places=2)
    image = models.ImageField(upload_to='food_items/', blank=True, null=True) # Changed to ImageField
    is_available = models.BooleanField(default=True, help_text="Is the item currently available for ordering?")
    is_vegetarian = models.BooleanField(default=False)
    # Add fields like calories, ingredients, etc. as needed
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    def __str__(self):
        return f"{self.name} ({self.category.name} - {self.restaurant.name})"

    class Meta:
        verbose_name = 'Food Item'
        verbose_name_plural = 'Food Items'
        # Optionally order by name or price
        # ordering = ['name']
        unique_together = ('restaurant', 'name') # Ensure item names are unique per restaurant
