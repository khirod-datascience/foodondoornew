# Backend Implementation Checklist

## ✅ Phase 1: OTP Auth System
- [x] /api/<user_type>/send_otp/ – **Missing**
- [x] /api/<user_type>/verify_otp/ – **Missing**
- [x] Customer Complete Signup – **Implemented**
- [x] Vendor Complete Signup – **Implemented**
- [x] Delivery Complete Signup – **Check/Implement**

## ✅ Phase 2: Customer APIs
- [x] /api/customer/home/ (combined banners, categories, restaurants, popular foods) – **Implemented**
- [x] /api/customer/restaurant/<id>/ – **Implemented**
- [x] /api/customer/cart/add/ – **Implemented**
- [x] /api/customer/cart/ – **Implemented**
- [x] /api/customer/cart/remove/ – **POST & DELETE supported**
- [x] /api/customer/order/place/ – **Implemented**
  - [x] Response includes message and order_id
- [x] /api/customer/orders/ – **Implemented**

## ✅ Phase 3: Vendor APIs
- [x] /api/vendor/profile/ – **Implemented**
- [x] /api/vendor/menu/ – List – **Implemented**
- [x] /api/vendor/menu/add/ – **Implemented**
- [x] /api/vendor/menu/<id>/update/ – **Implemented**
- [x] /api/vendor/menu/<id>/delete/ – **Implemented**
- [x] /api/vendor/orders/ – **Implemented**
- [x] /api/vendor/order/<id>/status/ – **Implemented**
  - [x] Ownership/permission checks – **Enforced**

## ✅ Phase 4: Delivery APIs
- [x] /api/delivery/orders/ – **Implemented** (as AvailableOrdersView)
- [x] Delivery order accept/mark picked/mark delivered – **Check/Implement**

## 🔁 General Tasks
- [x] Add POST support to cart/remove/ endpoint
- [x] Update order placement response to include "message" and "order_id"
- [x] Implement /api/customer/home/ combined endpoint
- [x] Implement/send reminders for OTP endpoints (send & verify) for all user types
- [x] Ensure vendor endpoints have proper authentication and ownership logic
- [x] Ensure delivery endpoints have proper authentication and ownership logic
