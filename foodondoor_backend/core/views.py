from django.shortcuts import render
import jwt
from django.conf import settings
from rest_framework import permissions, status
from rest_framework.response import Response
from rest_framework.views import APIView
from django.utils import timezone
# Import specific utils needed
from .utils import generate_otp, get_otp_expiry_time, generate_access_token, generate_refresh_token, generate_signup_token
# Import the constant needed from django.conf.settings
from django.conf import settings
# Import Profile models from their respective apps
from customer_app.models import CustomerProfile
from vendor_app.models import VendorProfile
from delivery_app.models import DeliveryAgentProfile

from django.core.cache import cache
import secrets

# --- Constants ---
OTP_CACHE_TIMEOUT = settings.OTP_EXPIRY_MINUTES * 60 # Cache timeout in seconds

USER_TYPE_MODEL_MAP = {
    'customer': CustomerProfile,
    'vendor': VendorProfile,
    'delivery': DeliveryAgentProfile
}

# --- Helper Function --- (Moved back here)
def get_profile_model(user_type):
    """Returns the appropriate profile model class based on user_type string."""
    return USER_TYPE_MODEL_MAP.get(user_type.lower()) # Use lower() for case-insensitivity


# --- OTP Authentication Views ---

class SendOTPView(APIView):
    permission_classes = [permissions.AllowAny]

    def post(self, request, *args, **kwargs):
        print("--- SendOTPView START ---") # Log start
        phone_number = request.data.get('phone_number')
        user_type = request.data.get('user_type')
        print(f"Received phone_number: {phone_number}, user_type: {user_type}")

        if not phone_number or not user_type:
            print("WARNING: Missing phone_number or user_type.")
            return Response({'error': 'Phone number and user type are required.'}, status=status.HTTP_400_BAD_REQUEST)

        ProfileModel = get_profile_model(user_type)
        if not ProfileModel:
            print(f"WARNING: Invalid user_type received: {user_type}")
            return Response({'error': 'Invalid user type.'}, status=status.HTTP_400_BAD_REQUEST)
        print(f"Using ProfileModel: {ProfileModel.__name__}")

        # Always generate OTP
        otp = generate_otp()
        otp_expiry = get_otp_expiry_time()
        cache_key = f"otp_{user_type}_{phone_number}"
        print(f"Generated OTP: {otp} for cache_key: {cache_key}, expiry: {otp_expiry}")

        try:
            # Check if user profile exists
            profile = ProfileModel.objects.get(phone_number=phone_number)
            # User exists: Update OTP and expiry on the profile model
            profile.otp_code = otp
            profile.otp_expiry = otp_expiry
            profile.save(update_fields=['otp_code', 'otp_expiry'])
            print(f"User exists. Updated OTP on profile: {profile.pk}")
            # Clear any potentially stale cache entry for this user
            cache.delete(cache_key)
            print(f"Cleared potentially stale cache entry for key: {cache_key}")

        except ProfileModel.DoesNotExist:
            # User does not exist: Save OTP to cache
            cache.set(cache_key, otp, timeout=OTP_CACHE_TIMEOUT)
            print(f"User does not exist. Saved OTP to cache with key: {cache_key}, timeout: {OTP_CACHE_TIMEOUT}s")

        # --- IMPORTANT --- 
        # In a real application, send the OTP via SMS here (using Twilio, etc.)
        # e.g., send_sms(phone_number, f\"Your OTP is: {otp}\")
        print(f"!!! SIMULATING SMS SENDING for {phone_number} with OTP {otp} !!!") # Log the simulated send

        # Always return generic success to prevent user enumeration
        print("--- SendOTPView END ---") # Log end
        return Response({'message': 'If an account exists, an OTP has been sent.'}, status=status.HTTP_200_OK)


class VerifyOTPView(APIView):
    permission_classes = [permissions.AllowAny]

    def post(self, request, *args, **kwargs):
        print(request.data)
        phone_number = request.data.get('phone_number')
        otp_entered = request.data.get('otp_code')
        user_type = request.data.get('user_type')
        print('before it..',phone_number,otp_entered,user_type)
        if not phone_number or not otp_entered or not user_type:
            print(phone_number,otp_entered,user_type)
            return Response({'error': 'Phone number, OTP, and user type are required.'}, status=status.HTTP_400_BAD_REQUEST)
        print('after it..',phone_number,otp_entered,user_type)
        ProfileModel = get_profile_model(user_type)
        if not ProfileModel:
            return Response({'error': 'Invalid user type.'}, status=status.HTTP_400_BAD_REQUEST)

        try:
            # --- Case 1: User Exists (Login Flow) ---
            user_profile = ProfileModel.objects.get(phone_number=phone_number)

            # Check OTP validity
            if user_profile.otp_code == otp_entered and user_profile.otp_expiry and user_profile.otp_expiry > timezone.now():
                # OTP is valid
                user_profile.otp_code = None # Clear OTP fields after successful verification
                user_profile.otp_expiry = None
                user_profile.is_active = True # Ensure user is active
                user_profile.save(update_fields=['otp_code', 'otp_expiry', 'is_active'])

                # Generate tokens
                access_token = generate_access_token(user_profile)
                refresh_token = generate_refresh_token(user_profile)

                return Response({
                    'access': access_token,
                    'refresh': refresh_token,
                    'signup_required': False # User exists, no signup needed
                }, status=status.HTTP_200_OK)
            else:
                # Invalid or expired OTP
                return Response({'error': 'Invalid or expired OTP.'}, status=status.HTTP_400_BAD_REQUEST)

        except ProfileModel.DoesNotExist:
            # --- Case 2: User Does Not Exist (Potential Registration Flow) ---
            cache_key = f"otp_{user_type}_{phone_number}"
            cached_otp = cache.get(cache_key)

            if cached_otp and cached_otp == otp_entered:
                # OTP from cache is valid
                cache.delete(cache_key) # Delete OTP from cache after use
                
                # Generate a temporary signup token (e.g., JWT or random string)
                # This token will be used to authorize the actual registration step
                signup_token = secrets.token_urlsafe(32) 
                signup_token_cache_key = f'signup_token_{signup_token}'
                
                # Store phone number with the token for registration view
                cache.set(signup_token_cache_key, {'phone_number': phone_number}, timeout=900) # 15 min expiry
                print(f"[VerifyOTPView] New user verified. Generated signup token: {signup_token}. Storing {phone_number} in cache.")

                return Response({
                    'message': 'OTP verified. Please complete registration.',
                    'signup_required': True,
                    'signup_token': signup_token,
                    'user_type': user_type # Include user_type if needed by frontend
                }, status=status.HTTP_200_OK)
            else:
                # Invalid OTP or not found in cache (possibly expired)
                return Response({'error': 'Invalid or expired OTP.'}, status=status.HTTP_400_BAD_REQUEST)


# --- Token Refresh View ---
class TokenRefreshView(APIView):
    """
    Accepts a refresh token and returns a new access token if valid.
    """
    permission_classes = [permissions.AllowAny] # Anyone can attempt to refresh

    def post(self, request, *args, **kwargs):
        refresh_token = request.data.get('refresh')

        if not refresh_token:
            return Response({'error': 'Refresh token is required.'}, status=status.HTTP_400_BAD_REQUEST)

        try:
            payload = jwt.decode(
                refresh_token, settings.JWT_SECRET_KEY, algorithms=[settings.JWT_ALGORITHM]
            )
        except jwt.ExpiredSignatureError:
            raise exceptions.AuthenticationFailed('Refresh token has expired. Please login again.')
        except jwt.PyJWTError as e:
            raise exceptions.AuthenticationFailed(f'Invalid refresh token: {e}. Please login again.')

        # Verify token type
        if payload.get('token_type') != 'refresh':
            raise exceptions.AuthenticationFailed('Invalid token type provided for refresh.')

        user_id = payload.get('user_id')
        user_type_str = payload.get('user_type')

        if not user_id or not user_type_str:
            raise exceptions.AuthenticationFailed('Token payload is missing required fields.')

        UserModel = USER_TYPE_MODEL_MAP.get(user_type_str)
        if not UserModel:
            raise exceptions.AuthenticationFailed(f'Invalid user type in token: {user_type_str}')

        try:
            user = UserModel.objects.get(pk=user_id)
        except UserModel.DoesNotExist:
            raise exceptions.AuthenticationFailed(f'{user_type_str} not found.')

        if not user.is_active:
            raise exceptions.AuthenticationFailed(f'{user_type_str} account is inactive.')

        # Re-check approval status for Vendor/Agent
        if hasattr(user, 'is_approved') and not user.is_approved:
             raise exceptions.AuthenticationFailed(f'{user_type_str} account is not approved.')

        # Generate a new access token
        new_access_token = generate_access_token(user)

        return Response({'access': new_access_token}, status=status.HTTP_200_OK)
