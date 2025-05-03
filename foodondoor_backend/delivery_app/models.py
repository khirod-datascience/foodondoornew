from django.db import models
from django.contrib.auth.hashers import make_password, check_password
import uuid
from django.utils import timezone

# Re-define choices here or import from a common location if needed elsewhere
class VehicleType(models.TextChoices):
    BICYCLE = 'bicycle', 'Bicycle'
    MOTORCYCLE = 'motorcycle', 'Motorcycle'
    SCOOTER = 'scooter', 'Scooter'
    CAR = 'car', 'Car'

# Create your models here.
class DeliveryAgentProfile(models.Model):
    """Independent model for delivery agent data and authentication."""
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    email = models.EmailField(unique=True, blank=True, null=True)
    phone_number = models.CharField(max_length=15, unique=True, blank=False, help_text="Primary phone number, used for login.")
    first_name = models.CharField(max_length=150, blank=True)
    last_name = models.CharField(max_length=150, blank=True)
    fcm_token = models.TextField(blank=True, null=True, help_text="Firebase Cloud Messaging device token")

    # Delivery agent specific fields (moved from core)
    vehicle_type = models.CharField(max_length=15, choices=VehicleType.choices, null=True, blank=True)
    vehicle_details = models.CharField(max_length=100, blank=True, null=True, help_text="License plate, model, etc.")
    current_latitude = models.DecimalField(max_digits=9, decimal_places=6, null=True, blank=True)
    current_longitude = models.DecimalField(max_digits=9, decimal_places=6, null=True, blank=True)
    is_available = models.BooleanField(default=False, help_text="Is the agent currently available for deliveries?")
    profile_picture = models.ImageField(upload_to='delivery_agent_profiles/', null=True, blank=True)

    # Status fields
    is_active = models.BooleanField(default=True, help_text="Designates whether this agent should be treated as active.")
    is_approved = models.BooleanField(default=False, help_text="Designates whether the admin has approved this agent.")
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    # OTP Fields
    otp_code = models.CharField(max_length=6, blank=True, null=True)
    otp_expiry = models.DateTimeField(blank=True, null=True)

    def get_full_name(self):
        return f"{self.first_name} {self.last_name}".strip()

    def __str__(self):
        full_name = self.get_full_name()
        return full_name if full_name else (self.phone_number or self.email or str(self.id))

    USERNAME_FIELD = 'phone_number'
    REQUIRED_FIELDS = ['first_name', 'last_name'] # For createsuperuser

    class Meta:
        verbose_name = 'Delivery Agent Profile'
        verbose_name_plural = 'Delivery Agent Profiles'
