from django.urls import path
from .views import (
    VendorRegistrationView,
    VendorProfileView, 
    VendorRestaurantView,
    VendorCategoryListCreateView,
    VendorCategoryDetailView,
    VendorProfileUpdateView,  
    VendorOrderListView,      
    VendorOrderAcceptView,    
    VendorOrderRejectView,    
    VendorOrderReadyView,     
    VendorMenuItemListCreateView, 
    VendorMenuItemDetailView,     
)

app_name = 'vendor_app'

urlpatterns = [
    path('auth/register/', VendorRegistrationView.as_view(), name='vendor-register'),
    path('profile/', VendorProfileView.as_view(), name='vendor-profile'),
    path('profile/update/', VendorProfileUpdateView.as_view(), name='vendor-profile-update'),
    path('restaurant/', VendorRestaurantView.as_view(), name='vendor-restaurant-detail'),
    path('orders/', VendorOrderListView.as_view(), name='vendor-order-list'),
    path('orders/<int:pk>/accept/', VendorOrderAcceptView.as_view(), name='vendor-order-accept'),
    path('orders/<int:pk>/reject/', VendorOrderRejectView.as_view(), name='vendor-order-reject'),
    path('orders/<int:pk>/ready/', VendorOrderReadyView.as_view(), name='vendor-order-ready'),
    # Menu Item management endpoints
    path('menu-items/', VendorMenuItemListCreateView.as_view(), name='vendor-menu-item-list-create'),
    path('menu-items/<uuid:pk>/', VendorMenuItemDetailView.as_view(), name='vendor-menu-item-detail'),
    # Category management endpoints
    path('categories/', VendorCategoryListCreateView.as_view(), name='vendor-category-list-create'),
    path('categories/<uuid:pk>/', VendorCategoryDetailView.as_view(), name='vendor-category-detail'),
]
