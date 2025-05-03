from django.contrib import admin
from .models import VendorProfile, Restaurant, Category, FoodItem

admin.site.register(VendorProfile)
admin.site.register(Restaurant)
admin.site.register(Category)
admin.site.register(FoodItem)
