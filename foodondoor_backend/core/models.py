from django.db import models


# --- Cart Models --- (Keeping these in core for now)

class Cart(models.Model):
    """Represents a customer's shopping cart (can be temporary or synced)."""
    # NOTE: This needs updating later to point to vendor_app.FoodItem instead of core.MenuItem
    # customer = models.OneToOneField('customer_app.CustomerProfile', on_delete=models.CASCADE, related_name='cart') # A cart belongs to one customer
    # TEMP: Placeholder until models are finalized/refactored
    # Using CharField temporarily to avoid FK issues during migration
    customer_id_temp = models.CharField(max_length=36, unique=True, null=True, blank=True) 
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    def __str__(self):
        # Adjust __str__ if customer FK changes
        return f"Cart for Customer ID {self.customer_id_temp}"

    class Meta:
        verbose_name_plural = 'Carts'


class CartItem(models.Model):
    """An item within a shopping cart."""
    cart = models.ForeignKey(Cart, on_delete=models.CASCADE, related_name='items')
    # NOTE: This needs updating later to point to vendor_app.FoodItem instead of core.MenuItem
    # menu_item = models.ForeignKey(MenuItem, on_delete=models.CASCADE)
    # TEMP: Placeholder until models are finalized/refactored
    menu_item_id_temp = models.CharField(max_length=36, null=True, blank=True)
    quantity = models.PositiveIntegerField(default=1)
    added_at = models.DateTimeField(auto_now_add=True)

    def __str__(self):
        # Adjust __str__ if menu_item FK changes
        return f"{self.quantity} x MenuItem ID {self.menu_item_id_temp} in {self.cart}"

    class Meta:
        # unique_together = ('cart', 'menu_item') # Re-enable when FKs are fixed
        pass # Temporarily removing constraint


# --- Order Models --- (Keeping these in core for now)

class Order(models.Model):
    """Represents a customer's order."""
    class OrderStatus(models.TextChoices):
        PENDING = 'pending', 'Pending Confirmation'
        ACCEPTED = 'accepted', 'Accepted by Vendor'
        REJECTED = 'rejected', 'Rejected by Vendor'
        PREPARING = 'preparing', 'Preparing'
        READY_FOR_PICKUP = 'ready_for_pickup', 'Ready for Pickup'
        PICKED_UP = 'picked_up', 'Picked Up by Delivery'
        ON_THE_WAY = 'on_the_way', 'On The Way'
        DELIVERED = 'delivered', 'Delivered'
        CANCELLED = 'cancelled', 'Cancelled by User'

    # NOTE: These need updating later
    # customer = models.ForeignKey('customer_app.CustomerProfile', on_delete=models.SET_NULL, null=True, related_name='orders')
    # restaurant = models.ForeignKey(Restaurant, on_delete=models.CASCADE, related_name='orders')
    # delivery_agent = models.ForeignKey('delivery_app.DeliveryAgentProfile', on_delete=models.SET_NULL, null=True, blank=True, related_name='assigned_orders')
    # delivery_address = models.ForeignKey(Address, on_delete=models.SET_NULL, null=True, related_name='order_deliveries')
    # TEMP: Placeholders
    customer_id_temp = models.CharField(max_length=36, null=True, blank=True)
    restaurant_id_temp = models.CharField(max_length=36, null=True, blank=True)
    delivery_agent_id_temp = models.CharField(max_length=36, null=True, blank=True)
    delivery_address_id_temp = models.CharField(max_length=36, null=True, blank=True)

    total_amount = models.DecimalField(max_digits=10, decimal_places=2)
    status = models.CharField(max_length=20, choices=OrderStatus.choices, default=OrderStatus.PENDING)
    notes = models.TextField(blank=True, help_text="Special instructions for the order")
    # Timestamps for tracking
    created_at = models.DateTimeField(auto_now_add=True)
    accepted_at = models.DateTimeField(null=True, blank=True)
    picked_up_at = models.DateTimeField(null=True, blank=True)
    delivered_at = models.DateTimeField(null=True, blank=True)
    updated_at = models.DateTimeField(auto_now=True)
    # Could add fields for payment status, delivery OTPs etc.
    vendor_pickup_otp = models.CharField(max_length=6, blank=True, null=True) # OTP for delivery agent to confirm pickup
    customer_delivery_otp = models.CharField(max_length=6, blank=True, null=True) # OTP for customer to confirm delivery

    def __str__(self):
        # Adjust __str__ if FKs change
        return f"Order {self.pk} by Customer ID {self.customer_id_temp} - Status: {self.get_status_display()}"

    class Meta:
        ordering = ['-created_at']


class OrderItem(models.Model):
    """Represents a single item within an order."""
    order = models.ForeignKey(Order, on_delete=models.CASCADE, related_name='items')
    # NOTE: Needs updating later to vendor_app.FoodItem
    # menu_item = models.ForeignKey(MenuItem, on_delete=models.SET_NULL, null=True)
    # TEMP: Placeholder
    menu_item_id_temp = models.CharField(max_length=36, null=True, blank=True)
    quantity = models.PositiveIntegerField()
    price = models.DecimalField(max_digits=8, decimal_places=2, help_text="Price at the time of order") # Store price to handle menu price changes
    # Store name/desc too if needed for history when MenuItem is deleted
    item_name_snapshot = models.CharField(max_length=150, blank=True)
    item_description_snapshot = models.TextField(blank=True)

    def __str__(self):
        # Adjust __str__ if FK changes
        return f"{self.quantity} x {self.item_name_snapshot or f'MenuItem ID {self.menu_item_id_temp}'}"
