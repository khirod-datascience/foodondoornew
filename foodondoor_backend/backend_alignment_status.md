# Foodondoor Backend Alignment & Progress Log

_Last updated: 2025-05-03 21:07 IST_

## 📝 Alignment & Completion Table

| Planned Endpoint                           | Method | Status      | Actual Path/Notes                   | Fix Needed?           |
|---------------------------------------------|--------|-------------|-------------------------------------|-----------------------|
| /api/customer/home/                        | GET    | TODO        | /api/customer/banners/, ...         | Merge to single view  |
| /api/customer/restaurant/<id>/             | GET    | TODO        | /api/customer/restaurants/<int:pk>/ | Param type, naming    |
| /api/customer/cart/add/                    | POST   | DONE        | /api/customer/cart/add/             | Check params          |
| /api/customer/cart/                        | GET    | DONE        | /api/customer/cart/                 | -                     |
| /api/customer/cart/remove/                 | POST   | DONE        | /api/customer/cart/remove/          | -                     |
| /api/customer/order/place/                 | POST   | DONE        | /api/customer/order/place/          | Renamed endpoint      |
| /api/customer/orders/                      | GET    | DONE        | /api/customer/orders/               | -                     |
| /api/<user_type>/send_otp/                 | POST   | DONE        | /api/<user_type>/send_otp/          | Path refactored       |
| /api/<user_type>/verify_otp/               | POST   | DONE        | /api/<user_type>/verify_otp/        | Path refactored       |
| /api/<user_type>/signup/                   | POST   | DONE        | /api/customer/signup/, /api/vendor/signup/, /api/delivery/signup/ | All mapped to respective views |
| /api/vendor/profile/                       | GET    | DONE        | /api/vendor/profile/                | Confirmed and aligned |
| /api/vendor/menu/                          | GET    | DONE        | /api/vendor/menu/                   | Refactor complete     |
| /api/vendor/menu/add/                      | POST   | DONE        | /api/vendor/menu/add/               | Refactor complete     |
| /api/vendor/menu/<id>/update/              | PUT    | DONE        | /api/vendor/menu/<uuid:pk>/update/  | Refactor complete     |
| /api/vendor/menu/<id>/delete/              | DELETE | DONE        | /api/vendor/menu/<uuid:pk>/delete/  | Refactor complete     |
| /api/vendor/orders/                        | GET    | DONE        | /api/vendor/orders/                 | Implemented and aligned |
| /api/vendor/order/<id>/status/             | POST   | DONE        | /api/vendor/order/<id>/status/      | Refactor complete     |
| /api/delivery/orders/                      | GET    | DONE        | /api/delivery/orders/available/     | Implemented and aligned |
| /api/delivery/order/<id>/status/           | POST   | DONE        | /api/delivery/order/<id>/status/    | Implemented and aligned |
| /api/delivery/history/                     | GET    | DONE        | /api/delivery/history/              | Implemented and aligned |
| /api/common/register_fcm_token/            | POST   | DONE        | /api/common/register_fcm_token/     | Implemented and aligned |
| /api/common/test_notification/             | POST   | DONE        | /api/common/test_notification/      | Implemented and aligned |

## ✅ Completed Tasks
- FCM token registration and test notification endpoints implemented and aligned (urls.py, views.py, models.py)
- Delivery history endpoint implemented and aligned (urls.py, views.py)
- FCM token registration endpoint work started
- All delivery order endpoints implemented and aligned (urls.py, views.py)
- Delivery history endpoint work started
- Delivery order status endpoint implemented and aligned (urls.py, views.py)
- Delivery orders endpoint implemented and aligned (urls.py, views.py)
- Vendor app alignment complete (all endpoints)
- Delivery app alignment started
- Vendor orders endpoint implemented and aligned (urls.py, views.py)
- Vendor profile endpoint confirmed and aligned (urls.py, views.py)
- Vendor menu endpoints refactored and aligned with backend plan (urls.py, views.py)
- Vendor order status endpoint implemented and aligned (urls.py, views.py)
- Refactored OTP endpoints to `/api/<user_type>/send_otp/` and `/api/<user_type>/verify_otp/` (core app)
- Implemented `/api/customer/signup/` (customer_app)
- Implemented `/api/vendor/signup/` (vendor_app)
- Implemented `/api/delivery/signup/` (delivery_app)
- Deprecated old `/complete-signup/` endpoint
- Renamed `/place-order/` to `/order/place/` (customer_app)
- Started endpoint renaming and alignment for customer app

## 🔄 In Progress
- Implementing `/api/vendor/signup/` and `/api/delivery/signup/`
- Preparing to merge customer home/dashboard data into `/home/`

## 🗂️ Next Steps
- Complete signup endpoints for vendor and delivery
- Align all customer endpoints and response formats
- Refactor vendor and delivery endpoints to match backend plan
- Implement missing common/notification endpoints
- Update this log with each change

---

This file will be updated continuously as work progresses. Each endpoint will be marked as DONE, IN PROGRESS, or TODO, and all major changes will be logged here for transparency.
