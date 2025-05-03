from django.urls import path
# Import the specific views needed
from .views import (
    SendOTPView,
    VerifyOTPView,
    TokenRefreshView
)

app_name = 'core_api'

urlpatterns = [
    # Add core utility URLs here later if needed
    path('auth/token/refresh/', TokenRefreshView.as_view(), name='token_refresh'),
    path('auth/send-otp/', SendOTPView.as_view(), name='send_otp'),
    path('auth/verify-otp/', VerifyOTPView.as_view(), name='verify_otp'),
]
