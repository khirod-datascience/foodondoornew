import jwt
from django.conf import settings
from rest_framework import authentication
from rest_framework import exceptions

# Import profile models dynamically to avoid circular imports if needed,
# or directly if structure allows (assuming core doesn't import from them heavily)
from customer_app.models import CustomerProfile
from vendor_app.models import VendorProfile
from delivery_app.models import DeliveryAgentProfile

# Map user type string (from token) to the actual model class
USER_TYPE_MODEL_MAP = {
    'CustomerProfile': CustomerProfile,
    'VendorProfile': VendorProfile,
    'DeliveryAgentProfile': DeliveryAgentProfile,
}

class JWTAuthentication(authentication.BaseAuthentication):
    """
    Custom JWT Authentication backend.

    Authenticates requests containing a JWT in the 'Authorization: Bearer <token>' header.
    Validates the token and retrieves the corresponding user profile based on type.
    """
    def authenticate(self, request):
        auth_header = authentication.get_authorization_header(request).split()

        if not auth_header or auth_header[0].lower() != settings.JWT_AUTH_HEADER_PREFIX.lower().encode():
            return None # No token provided or incorrect prefix

        if len(auth_header) == 1:
            raise exceptions.AuthenticationFailed('Invalid token header. No credentials provided.')
        elif len(auth_header) > 2:
            raise exceptions.AuthenticationFailed('Invalid token header. Token string should not contain spaces.')

        try:
            token = auth_header[1].decode('utf-8')
            payload = jwt.decode(
                token, settings.JWT_SECRET_KEY, algorithms=[settings.JWT_ALGORITHM]
            )
        except jwt.ExpiredSignatureError:
            raise exceptions.AuthenticationFailed('Token has expired.')
        except jwt.PyJWTError as e:
            raise exceptions.AuthenticationFailed(f'Invalid token: {e}')
        except UnicodeDecodeError:
             raise exceptions.AuthenticationFailed('Invalid token header. Contains invalid characters.')

        user_id = payload.get('user_id')
        user_type_str = payload.get('user_type')

        if not user_id or not user_type_str:
            raise exceptions.AuthenticationFailed('Token payload is missing required fields (user_id, user_type).')

        UserModel = USER_TYPE_MODEL_MAP.get(user_type_str)
        if not UserModel:
            raise exceptions.AuthenticationFailed(f'Invalid user type specified in token: {user_type_str}')

        try:
            profile = UserModel.objects.get(pk=user_id)
        except UserModel.DoesNotExist:
            raise exceptions.AuthenticationFailed(f'{user_type_str} not found for the given token.')

        # All profiles must have a related Django user
        user = getattr(profile, 'user', None)
        if user is None:
            raise exceptions.AuthenticationFailed(f'{user_type_str} does not have a related user account.')
        if not user.is_active:
            raise exceptions.AuthenticationFailed(f'{user_type_str} account is inactive.')

        # For Vendor and DeliveryAgent, also check if approved (adjust if approval logic changes)
        if hasattr(profile, 'is_approved') and not profile.is_approved:
            raise exceptions.AuthenticationFailed(f'{user_type_str} account is not approved.')

        # Attach the profile to the request for easy access in views
        # DRF sets request.user to the returned user
        # We'll attach the profile as request.vendor_profile, request.customer_profile, etc.
        # This requires a middleware or monkeypatch, but for now, views can access request.auth for the payload
        request.profile = profile

        return (user, payload)
