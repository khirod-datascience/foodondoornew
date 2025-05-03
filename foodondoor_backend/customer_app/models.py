from django.db import models
from django.utils import timezone
import uuid

# Create your models here.

class CustomerProfile(models.Model):
    """Independent model for customer data and authentication."""
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    email = models.EmailField(unique=True, blank=True, null=True)
    phone_number = models.CharField(max_length=15, unique=True, blank=False, help_text="Primary phone number, used for login.")
    first_name = models.CharField(max_length=150, blank=True)
    last_name = models.CharField(max_length=100, blank=True)
    fcm_token = models.CharField(max_length=255, blank=True, null=True, help_text="Firebase Cloud Messaging device token")
    is_active = models.BooleanField(default=True, help_text="Designates whether this user should be treated as active. Unselect this instead of deleting accounts.")
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    # OTP Fields
    otp_code = models.CharField(max_length=6, blank=True, null=True)
    otp_expiry = models.DateTimeField(blank=True, null=True)

    # Add related name for reverse relationship from Address/Cart/Order if needed
    # cart = models.OneToOneField('core.Cart', ...)
    # orders = models.ForeignKey('core.Order', ...)

    def get_full_name(self):
        return f"{self.first_name} {self.last_name}".strip()

    def __str__(self):
        return self.phone_number or self.email or str(self.id)

    USERNAME_FIELD = 'phone_number' # Use phone number for login identification primarily
    REQUIRED_FIELDS = ['first_name', 'last_name', 'email'] # Required for createsuperuser, less relevant here

    class Meta:
        verbose_name = 'Customer Profile'
        verbose_name_plural = 'Customer Profiles'

class Address(models.Model):
    """Model to store customer addresses."""
    ADDRESS_TYPE_CHOICES = [
        ('HOME', 'Home'),
        ('WORK', 'Work'),
        ('OTHER', 'Other'),
    ]

    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    customer = models.ForeignKey(CustomerProfile, on_delete=models.CASCADE, related_name='addresses')
    address_line1 = models.CharField(max_length=255)
    address_line2 = models.CharField(max_length=255, blank=True, null=True)
    city = models.CharField(max_length=100)
    state = models.CharField(max_length=100)
    postal_code = models.CharField(max_length=20)
    country = models.CharField(max_length=100, default='India') # Assuming default country
    address_type = models.CharField(max_length=10, choices=ADDRESS_TYPE_CHOICES, default='HOME')
    is_default = models.BooleanField(default=False)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        verbose_name = 'Address'
        verbose_name_plural = 'Addresses'
        # Ensure only one default address per customer
        unique_together = ('customer', 'is_default') 
        constraints = [
            models.UniqueConstraint(
                fields=['customer'],
                condition=models.Q(is_default=True),
                name='unique_default_address_per_customer'
            )
        ]

    def __str__(self):
        return f"{self.address_line1}, {self.city} ({self.customer.get_full_name()})"

    def save(self, *args, **kwargs):
        # Ensure only one default address per customer
        if self.is_default:
            # Set all other addresses for this customer to non-default
            Address.objects.filter(customer=self.customer, is_default=True).exclude(pk=self.pk).update(is_default=False)
        super().save(*args, **kwargs)
