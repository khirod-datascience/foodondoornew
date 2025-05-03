from django.urls import path
from .views import RegisterFCMTokenView, TestNotificationView
# Import the specific views needed
from .views import (
    SendOTPView,
    VerifyOTPView,
    TokenRefreshView
)

app_name = 'core_api'

urlpatterns = [
    path('common/register_fcm_token/', RegisterFCMTokenView.as_view(), name='register-fcm-token'),
    path('common/test_notification/', TestNotificationView.as_view(), name='test-notification'),
    path('auth/token/refresh/', TokenRefreshView.as_view(), name='token_refresh'),
    path('customer/send_otp/', SendOTPView.as_view(), {'user_type': 'customer'}, name='customer-send-otp'),
    path('customer/verify_otp/', VerifyOTPView.as_view(), {'user_type': 'customer'}, name='customer-verify-otp'),
    path('vendor/send_otp/', SendOTPView.as_view(), {'user_type': 'vendor'}, name='vendor-send-otp'),
    path('vendor/verify_otp/', VerifyOTPView.as_view(), {'user_type': 'vendor'}, name='vendor-verify-otp'),
    path('delivery/send_otp/', SendOTPView.as_view(), {'user_type': 'delivery'}, name='delivery-send-otp'),
    path('delivery/verify_otp/', VerifyOTPView.as_view(), {'user_type': 'delivery'}, name='delivery-verify-otp'),
]
