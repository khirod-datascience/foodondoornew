# FOODONDOOR DEVELOPMENT PLAN

## GLOBAL DEVELOPMENT STANDARDS

- **Authentication**: Custom OTP-initiated authentication using JWT for session management (no Django defaults)
- **Theming**: Unified Material 3 theme with Poppins font and `Colors.deepOrange`
- **Naming Conventions**:
  - **Files**: `snake_case.dart`
  - **Classes**: `PascalCase`
  - **Variables/Functions**: `camelCase`
- **API Design**: Custom endpoints as per `api_endpoints.md`
- **State Management**: `provider` package (clean, modular)
- **Code Tracking**: All work and updates logged in `work_summary.md`
- **Notifications**: To be implemented in a future phase

---

## 1 CUSTOMER APP (`foodondoor_customer_app`)

### 1. Splash Screen
- **Logic**:  
  - Check stored JWT token  
  - Fetch location  
- **Libs**: `geolocator`, `shared_preferences`  
- **Next**: Redirect to login or home

### 2. Login / OTP
- **Fields**: Phone Number  
- **APIs**:
  - `POST /api/core/auth/send-otp/`
  - `POST /api/core/auth/verify-otp/`
- **Token**: JWT (access/refresh) stored securely

### 3. Home Screen
- **Features**:
  - Current location (reverse-geocoded)
  - Search bar (future feature)
- **Sections**:
  - **Banners** → `GET /api/customer/banners/`
  - **Food Categories** → `GET /api/customer/categories/`
  - **Nearby Restaurants** → `GET /api/customer/restaurants/nearby/?lat=xx&lon=yy`
  - **Top-rated Dishes** → `GET /api/customer/food/top-rated/`

### 4. Restaurant Details
- **Display**:
  - Restaurant info, ratings
  - Menu grouped by category (`GET /api/customer/restaurants/<id>/categories/`)
  - Menu items (`GET /api/customer/restaurants/<id>/` already includes items)
- **Cart Integration**:
  - Add/Remove item
  - **API**:
    - `POST /api/customer/cart/add/`
    - `PUT /api/customer/cart/update/`
    - `DELETE /api/customer/cart/remove/`
  - Show item modifiers (if any)

### 5. Cart Screen
- Show all selected items
- Modify quantity, delete items
- Show pricing breakdown
- **API**: `GET /api/customer/cart/`
- **Button**: Proceed to Checkout

### 6. Address Screen
- **Features**:
  - List, Add, Edit, Delete addresses
  - Auto-locate option (via GPS)
- **API**:
  - `GET /api/customer/addresses/`
  - `POST /api/customer/addresses/add/`
  - `PUT /api/customer/addresses/<id>/update/`
  - `DELETE /api/customer/addresses/<id>/delete/`

### 7. Checkout Screen
- **Show**:
  - Cart Summary
  - Selected Address
  - Expected Delivery Time
- **Place Order**: `POST /api/customer/place-order/`

### 8. Order Tracking
- **Tracking**: Real-time  
- **Method**: Polling/Future WebSocket → `GET /api/customer/orders/<id>/status/`
- **Info**: Rider info (after assigned)

### 9. Order History
- **List**: `GET /api/customer/orders/`
- **Actions**:
  - View Details
  - Rate & Review (`POST /api/customer/orders/<id>/rate/`)
  - Reorder

### 10. Profile Screen
- **View/Update**: (`GET /api/customer/profile/`, `PUT /api/customer/profile/update/`)
  - Name
  - Phone (non-editable)
- **Actions**:
  - Logout
  - View Addresses

---

## 2 VENDOR APP (`foodondoor_vendor_app`)

### 1. Login / OTP
- **Flow**: Uses Core OTP endpoints
  - `POST /api/core/auth/send-otp/`
  - `POST /api/core/auth/verify-otp/`
- **Role**: `vendor`
- **Signup Completion**: `POST /api/vendor/auth/register/` (after OTP verification returns signup_token)

### 2. Order Management
- **Tabs/Filtering**:
  - New Orders
  - Preparing Orders
  - Completed Orders
- **API**: `GET /api/vendor/orders/` (Use query parameters for filtering e.g., `?status=new`)
- **Actions**:
  - Accept → `POST /api/vendor/orders/<id>/accept/`
  - Mark as Ready → `POST /api/vendor/orders/<id>/ready/`
  - Reject → `POST /api/vendor/orders/<id>/reject/`

### 3. Menu Management
- **Features**:
  - Add/Edit/Delete Item
  - Toggle availability
- **Fields**:
  - Name, Description, Price, Category, Image, IsAvailable
- **API**:
  - `GET /api/vendor/menu-items/`
  - `POST /api/vendor/menu-items/add/`
  - `PUT /api/vendor/menu-items/<id>/update/`
  - `DELETE /api/vendor/menu-items/<id>/delete/`

### 4. Profile & Restaurant Management
- **Vendor Account Info**:
  - View/Update Name, Email, Phone (Non-editable)
  - **API**: `GET /api/vendor/profile/`, `PUT /api/vendor/profile/update/`
- **Restaurant Details**:
  - View/Update Restaurant Name, Logo, Contact, Address, Operating Hours, etc.
  - **API**: `GET /api/vendor/restaurant/`, `PUT /api/vendor/restaurant/`

---

## 3 DELIVERY APP (`foodondoor_delivery_app`)

### 1. Login / OTP
- **Flow**: Uses Core OTP endpoints
  - `POST /api/core/auth/send-otp/`
  - `POST /api/core/auth/verify-otp/`
- **Role**: `delivery`
- **Signup Completion**: `POST /api/delivery/auth/register/` (TODO - after OTP verification returns signup_token)
- **Token**: Save JWT locally

### 2. Assigned Orders
- **Show**:
  - Unassigned/Assigned orders
  - Customer & restaurant details
- **Accept**: `POST /api/delivery/orders/<id>/assign/`

### 3. Pickup Screen
- **Details**:
  - Restaurant Address
  - Items to pick
- **Confirm Pickup**: `POST /api/delivery/orders/<id>/confirm-pickup/`

### 4. Delivery Screen
- **Map**: Showing customer location
- **Confirm Delivery**: `POST /api/delivery/orders/<id>/confirm-delivery/`

### 5. Earnings
- **List**: Completed deliveries
- **Show**: Amount earned (today/week)
- **API**: `GET /api/delivery/earnings/`

---

## PHASE-WISE DEVELOPMENT PLAN

| Phase | Tasks                                                | Apps     |
|-------|------------------------------------------------------|----------|
| 1   | Django backend setup, DB schema, Custom Auth API     | All      |
| 2   | OTP Login flow (vendor, customer, delivery)          | All      |
| 3   | Vendor App → Menu & Restaurant Management            | Vendor   |
| 4   | Customer App → Home, Restaurant, Cart, Checkout      | Customer |
| 5   | Vendor App → Order Management (Accept/Ready/Reject)  | Vendor   |
| 6   | Customer App → Order Tracking & History              | Customer |
| 7   | Delivery App → Assigned Orders → Pickup → Deliver    | Delivery |
| 8   | Notifications (FCM)                                  | All      |
| 9   | Admin Panel (optional)                               | Backend  |
| 10  | MongoDB refactor (optional)                          | Backend  |

---

## FOLDER STRUCTURE

### `foodondoor_backend/`

```bash
foodondoor_backend/
├── auth_app/
├── customer_app/
├── vendor_app/
├── delivery_app/
├── plan.md
├── api_endpoints.md
├── work_summary.md
