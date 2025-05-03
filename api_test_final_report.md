
## Recommendations
---

## 🟢 Core/OTP/Auth APIs

### /api/<user_type>/send_otp/  
**POST**  
**Input:** `{ "phone_number": "string" }` or `{ "mobile": "string" }`  
**Output:** `{ "message": "OTP sent successfully." }` or `{ "error": "..." }`

### /api/<user_type>/verify_otp/  
**POST**  
**Input:** `{ "phone_number": "string", "otp": "string" }` or `{ "mobile": "string", "otp": "string" }`  
**Output:** `{ "access": "jwt", "refresh": "jwt", ...}` or `{ "signup_required": true, "signup_token": "..." }`

### /api/auth/token/refresh/  
**POST**  
**Input:** `{ "refresh": "token" }`  
**Output:** `{ "access": "new_token" }`

### /api/common/register_fcm_token/  
**POST**  
**Input:** `{ "user_id": int, "user_type": "string", "fcm_token": "string" }`  
**Output:** `{ "message": "FCM token registered successfully." }`

### /api/common/test_notification/  
**POST**  
**Input:** `{ "user_id": int, "user_type": "string", "message": "string" }`  
**Output:** `{ "message": "Notification to ..." }`

---

## 🟢 Customer APIs

### /api/customer/home/  
**GET**  
**Output:** `{ "banners": [...], "categories": [...], "nearby_restaurants": [...], "top_rated_restaurants": [...], "popular_foods": [...] }`

### /api/customer/signup/  
**POST**  
**Input:** `{ "signup_token": "...", "first_name": "...", "last_name": "...", "email": "...", "phone_number": "..." }`  
**Output:** `{ "access": "jwt", "refresh": "jwt", ...}`

### /api/customer/profile/  
**GET**  
**Output:** Customer profile fields

### /api/customer/profile/update/  
**PUT/PATCH**  
**Input:** Partial or full profile fields  
**Output:** Updated profile

### /api/customer/cart/  
**GET**  
**Output:** Cart details

### /api/customer/cart/add/  
**POST**  
**Input:** `{ "food_item": id, "quantity": int }`  
**Output:** Cart item added

### /api/customer/cart/update/  
**PUT/PATCH**  
**Input:** `{ "food_item": id, "quantity": int }`  
**Output:** Cart item updated

### /api/customer/cart/remove/  
**POST/DELETE**  
**Input:** `{ "food_item": id }` or query param  
**Output:** Cart item removed

### /api/customer/order/place/  
**POST**  
**Input:** `{ "address_id": id, ... }`  
**Output:** `{ "message": "Order placed successfully", "order_id": id, ... }`

### /api/customer/orders/  
**GET**  
**Output:** List of orders

### /api/customer/orders/<int:pk>/  
**GET**  
**Output:** Order details

### /api/customer/orders/<int:pk>/status/  
**GET**  
**Output:** Order status

### /api/customer/orders/<int:pk>/track/  
**GET**  
**Output:** Tracking info

### /api/customer/orders/<int:pk>/rate/  
**POST**  
**Input:** `{ "rating": int, "review": "string" }`  
**Output:** Rating submitted

### /api/customer/addresses/  
**GET**  
**Output:** List of addresses

### /api/customer/addresses/add/  
**POST**  
**Input:** Address fields  
**Output:** Address created

### /api/customer/addresses/<int:pk>/update/  
**PUT/PATCH**  
**Input:** Address fields  
**Output:** Address updated

### /api/customer/addresses/<int:pk>/delete/  
**DELETE**  
**Output:** Address deleted

---

## 🟢 Vendor APIs

### /api/vendor/signup/  
**POST**  
**Input:** `{ "signup_token": "...", "company_name": "...", "email": "..." }`  
**Output:** `{ "access": "jwt", "refresh": "jwt", ...}`

### /api/vendor/profile/  
**GET**  
**Output:** Vendor profile fields

### /api/vendor/profile/update/  
**PUT/PATCH**  
**Input:** Partial or full profile fields  
**Output:** Updated profile

### /api/vendor/restaurant/  
**GET**  
**Output:** Restaurant details

### /api/vendor/menu/  
**GET**  
**Output:** List of menu items

### /api/vendor/menu/add/  
**POST**  
**Input:** Menu item fields  
**Output:** Menu item created

### /api/vendor/menu/<uuid:pk>/update/  
**PUT/PATCH**  
**Input:** Menu item fields  
**Output:** Menu item updated

### /api/vendor/menu/<uuid:pk>/delete/  
**DELETE**  
**Output:** Menu item deleted

### /api/vendor/categories/  
**GET**  
**Output:** List of categories

### /api/vendor/categories/  
**POST**  
**Input:** Category fields  
**Output:** Category created

### /api/vendor/categories/<uuid:pk>/  
**GET**  
**Output:** Category details

### /api/vendor/categories/<uuid:pk>/  
**PUT/PATCH**  
**Input:** Category fields  
**Output:** Category updated

### /api/vendor/categories/<uuid:pk>/  
**DELETE**  
**Output:** Category deleted

### /api/vendor/orders/  
**GET**  
**Output:** List of vendor orders

### /api/vendor/order/<int:pk>/status/  
**POST**  
**Input:** `{ "status": "accepted"|"preparing"|"ready" }`  
**Output:** Order status updated

### /api/vendor/orders/<int:pk>/accept/  
**POST**  
**Output:** Order accepted

### /api/vendor/orders/<int:pk>/reject/  
**POST**  
**Output:** Order rejected

### /api/vendor/orders/<int:pk>/ready/  
**POST**  
**Output:** Order marked ready

---

## 🟢 Delivery APIs

### /api/delivery/signup/  
**POST**  
**Input:** `{ "signup_token": "...", "first_name": "...", "last_name": "...", "email": "...", "phone_number": "..." }`  
**Output:** `{ "access": "jwt", "refresh": "jwt", ...}`

### /api/delivery/profile/  
**GET**  
**Output:** Delivery agent profile fields

### /api/delivery/profile/update/  
**PUT/PATCH**  
**Input:** Partial or full profile fields  
**Output:** Updated profile

### /api/delivery/orders/  
**GET**  
**Output:** List of available orders

### /api/delivery/orders/<int:pk>/assign/  
**POST**  
**Output:** Order assigned to agent

### /api/delivery/orders/<int:pk>/confirm-pickup/  
**POST**  
**Output:** Order marked as picked up

### /api/delivery/orders/<int:pk>/confirm-delivery/  
**POST**  
**Output:** Order marked as delivered

### /api/delivery/history/  
**GET**  
**Output:** List of completed orders

### /api/delivery/earnings/  
**GET**  
**Output:** `{ "total_earnings": float }`

---

**Note:** All endpoints require authentication (JWT) unless otherwise noted. Input/output may be further refined by inspecting the corresponding serializer in each view.
