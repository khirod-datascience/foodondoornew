from rest_framework import permissions
# Import profile models from their respective apps
from customer_app.models import CustomerProfile
from vendor_app.models import VendorProfile
from delivery_app.models import DeliveryAgentProfile

class IsAuthenticatedCustomer(permissions.BasePermission):
    """
    Allows access only to authenticated users who are CustomerProfile instances.
    Assumes request.user is populated by a custom JWT Authentication backend.
    """
    message = 'User is not a Customer.'

    def has_permission(self, request, view):
        # Check if the user is authenticated (handled by IsAuthenticated in DRF settings)
        # and if the user object is an instance of CustomerProfile.
        return bool(request.user and request.user.is_authenticated and isinstance(request.user, CustomerProfile))

class IsAuthenticatedVendor(permissions.BasePermission):
    """
    Allows access only to authenticated users who are VendorProfile instances.
    Assumes request.user is populated by a custom JWT Authentication backend.
    """
    message = 'User is not a Vendor.'

    def has_permission(self, request, view):
        # Check if the user is authenticated and if the user object is an instance of VendorProfile.
        # Also consider if the vendor needs to be approved.
        return bool(
            request.user and 
            request.user.is_authenticated and 
            isinstance(request.user, VendorProfile) 
            # Add approval check if necessary for most vendor endpoints
            # and request.user.is_approved 
        )

class IsAuthenticatedDeliveryAgent(permissions.BasePermission):
    """
    Allows access only to authenticated users who are DeliveryAgentProfile instances.
    Assumes request.user is populated by a custom JWT Authentication backend.
    """
    message = 'User is not a Delivery Agent.'

    def has_permission(self, request, view):
        # Check if the user is authenticated and if the user object is an instance of DeliveryAgentProfile.
        # Also consider if the agent needs to be approved.
        return bool(
            request.user and 
            request.user.is_authenticated and 
            isinstance(request.user, DeliveryAgentProfile)
            # Add approval check if necessary for most delivery endpoints
            # and request.user.is_approved 
        )
