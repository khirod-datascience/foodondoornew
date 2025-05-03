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
    # send_otp and verify_otp handled by core.urls
    path('orders/', VendorOrderListView.as_view(), name='vendor-orders'),
    path('order/<int:pk>/status/', VendorOrderReadyView.as_view(), name='vendor-order-status'),
    path('signup/', VendorRegistrationView.as_view(), name='vendor-signup'),
    path('profile/', VendorProfileView.as_view(), name='vendor-profile'),
    path('profile/update/', VendorProfileUpdateView.as_view(), name='vendor-profile-update'),
    path('restaurant/', VendorRestaurantView.as_view(), name='vendor-restaurant-detail'),
    path('orders/', VendorOrderListView.as_view(), name='vendor-order-list'),
    path('orders/<int:pk>/accept/', VendorOrderAcceptView.as_view(), name='vendor-order-accept'),
    path('orders/<int:pk>/reject/', VendorOrderRejectView.as_view(), name='vendor-order-reject'),
    path('orders/<int:pk>/ready/', VendorOrderReadyView.as_view(), name='vendor-order-ready'),
    path('order/<int:pk>/status/', VendorOrderReadyView.as_view(), name='vendor-order-status'),
    path('orders/', VendorOrderListView.as_view(), name='vendor-orders'),
    # Menu Item management endpoints (aligned with backend plan)
    path('menu/', VendorMenuItemListCreateView.as_view(), name='vendor-menu-list'),  # GET
    path('menu/add/', VendorMenuItemListCreateView.as_view(), name='vendor-menu-add'),  # POST
    path('menu/<uuid:pk>/update/', VendorMenuItemDetailView.as_view(), name='vendor-menu-update'),  # PUT
    path('menu/<uuid:pk>/delete/', VendorMenuItemDetailView.as_view(), name='vendor-menu-delete'),  # DELETE
    # Category management endpoints
    path('categories/', VendorCategoryListCreateView.as_view(), name='vendor-category-list-create'),
    path('categories/<uuid:pk>/', VendorCategoryDetailView.as_view(), name='vendor-category-detail'),
]
