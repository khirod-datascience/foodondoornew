from django.urls import path
from .views import (
    DeliveryAgentProfileView,
    DeliveryAgentProfileUpdateView, 
    AvailableOrdersView,            
    AssignOrderView,                
    ConfirmPickupView,              
    ConfirmDeliveryView,            
    DeliveryAgentEarningsView       
)

urlpatterns = [
    path('profile/', DeliveryAgentProfileView.as_view(), name='delivery-agent-profile'),
    path('profile/update/', DeliveryAgentProfileUpdateView.as_view(), name='delivery-agent-profile-update'),
    path('orders/available/', AvailableOrdersView.as_view(), name='delivery-orders-available'),
    path('orders/<int:pk>/assign/', AssignOrderView.as_view(), name='delivery-order-assign'),
    path('orders/<int:pk>/confirm-pickup/', ConfirmPickupView.as_view(), name='delivery-order-confirm-pickup'),
    path('orders/<int:pk>/confirm-delivery/', ConfirmDeliveryView.as_view(), name='delivery-order-confirm-delivery'),
    path('earnings/', DeliveryAgentEarningsView.as_view(), name='delivery-agent-earnings'),
]
