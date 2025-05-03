from django.urls import path
from .views import (
    DeliveryAgentRegistrationView,
    DeliveryAgentProfileView,
    DeliveryAgentProfileUpdateView, 
    AvailableOrdersView,            
    AssignOrderView,                
    ConfirmPickupView,              
    ConfirmDeliveryView,            
    DeliveryAgentEarningsView,      
    DeliveryAgentHistoryView        
)

urlpatterns = [
    # send_otp and verify_otp handled by core.urls
    path('orders/', AvailableOrdersView.as_view(), name='delivery-orders'),
    path('order/<int:pk>/status/', ConfirmPickupView.as_view(), name='delivery-order-status'),
    path('history/', DeliveryAgentHistoryView.as_view(), name='delivery-agent-history'),
    path('signup/', DeliveryAgentRegistrationView.as_view(), name='delivery-signup'),
    path('profile/', DeliveryAgentProfileView.as_view(), name='delivery-agent-profile'),
    path('profile/update/', DeliveryAgentProfileUpdateView.as_view(), name='delivery-agent-profile-update'),
    path('orders/', AvailableOrdersView.as_view(), name='delivery-orders'),
    path('orders/available/', AvailableOrdersView.as_view(), name='delivery-orders-available'),
    path('orders/<int:pk>/assign/', AssignOrderView.as_view(), name='delivery-order-assign'),
    path('orders/<int:pk>/confirm-pickup/', ConfirmPickupView.as_view(), name='delivery-order-confirm-pickup'),
    path('order/<int:pk>/status/', ConfirmPickupView.as_view(), name='delivery-order-status'),
    path('orders/<int:pk>/confirm-delivery/', ConfirmDeliveryView.as_view(), name='delivery-order-confirm-delivery'),
    path('earnings/', DeliveryAgentEarningsView.as_view(), name='delivery-agent-earnings'),
    path('history/', DeliveryAgentHistoryView.as_view(), name='delivery-agent-history'),
]
