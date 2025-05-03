import jwt
import datetime
from django.conf import settings
from django.utils import timezone
import random
import string

def generate_access_token(user_profile):
    """
    Generates an Access JWT token for a given user profile instance.
    Includes user's UUID, email/phone (if available), and user type in the payload.
    Uses settings.JWT_EXPIRATION_DELTA for expiry.
    """
    access_token_payload = {
        'token_type': 'access',
        'user_id': str(user_profile.id), # Use UUID as the primary identifier
        'user_type': user_profile.__class__.__name__, # e.g., 'CustomerProfile', 'VendorProfile'
        'exp': datetime.datetime.utcnow() + settings.JWT_EXPIRATION_DELTA,
        'iat': datetime.datetime.utcnow(),
    }

    # Optionally add email or phone for easier debugging/identification, if present
    if hasattr(user_profile, 'email') and user_profile.email:
        access_token_payload['email'] = user_profile.email
    elif hasattr(user_profile, 'phone_number') and user_profile.phone_number:
        access_token_payload['phone'] = user_profile.phone_number

    token = jwt.encode(access_token_payload, settings.JWT_SECRET_KEY, algorithm=settings.JWT_ALGORITHM)
    return token

def generate_refresh_token(user_profile):
    """
    Generates a Refresh JWT token for a given user profile instance.
    Includes user's UUID and user type.
    Uses settings.JWT_REFRESH_EXPIRATION_DELTA for expiry.
    """
    refresh_token_payload = {
        'token_type': 'refresh',
        'user_id': str(user_profile.id),
        'user_type': user_profile.__class__.__name__,
        'exp': datetime.datetime.utcnow() + settings.JWT_REFRESH_EXPIRATION_DELTA,
        'iat': datetime.datetime.utcnow()
    }
    token = jwt.encode(refresh_token_payload, settings.JWT_SECRET_KEY, algorithm=settings.JWT_ALGORITHM)
    return token

# --- OTP Utilities ---

OTP_LENGTH = 6
OTP_EXPIRY_MINUTES = 5 # Set OTP expiry duration

def generate_otp(length=6):
    """Generates a random N-digit OTP."""
    return ''.join(random.choices(string.digits, k=length))

def get_otp_expiry_time():
    """Calculates the OTP expiry time from now."""
    return timezone.now() + timezone.timedelta(minutes=OTP_EXPIRY_MINUTES)

def generate_signup_token(phone_number, user_type):
    """
    Generates a short-lived JWT token containing verified phone number and user type
    to authorize the completion of the signup process.
    Uses a short expiration time (e.g., 10 minutes).
    """
    signup_token_payload = {
        'token_type': 'signup',
        'phone_number': phone_number,
        'user_type': user_type,
        'exp': datetime.datetime.utcnow() + datetime.timedelta(minutes=10), # Short expiry
        'iat': datetime.datetime.utcnow(),
    }
    token = jwt.encode(signup_token_payload, settings.JWT_SECRET_KEY, algorithm=settings.JWT_ALGORITHM)
    return token
