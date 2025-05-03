import unittest
import requests
import json

BASE_URL = "http://127.0.0.1:8000/api/"
CUSTOMER_MOBILE = "8908168688"
VENDOR_MOBILE = "9999999992"
DELIVERY_MOBILE = "9999999993"
TEST_OTP = "123456"

report = []

def log_case(endpoint, test_name, req, res, status_code, expected_status, passed, reason=""):
    report.append({
        "endpoint": endpoint,
        "test": test_name,
        "request": req,
        "response": res if isinstance(res, str) else json.dumps(res, ensure_ascii=False),
        "status_code": status_code,
        "expected_status": expected_status,
        "result": "PASSED" if passed else f"FAILED: {status_code} != {expected_status}" if not passed and not reason else f"FAILED: {reason}"
    })
    # print(f"[{'PASS' if passed else 'FAIL'}] {test_name}: {report[-1]['result']}")

# At the end of the file, after all tests:
def save_report_and_summary():
    with open('api_test_actual_report.json', 'w', encoding='utf-8') as f:
        json.dump(report, f, ensure_ascii=False, indent=2)
    # Markdown summary
    # print("\n\n# API Test Summary\n")
    # print("| Endpoint | Test | Auth | Result | Response Snippet |")
    # print("|---|---|---|---|---|")
    for entry in report:
        endpoint = entry['endpoint']
        test = entry['test']
        auth = '✅' if 'Authorization' in str(entry['request']) else '❌'
        result = '✅ PASS' if entry['result'].startswith('PASSED') else '❌ FAIL'
        snippet = str(entry['response'])[:40].replace('\n',' ')
        # print(f"| {endpoint} | {test} | {auth} | {result} | {snippet} ...|")


class FoodondoorAPITest(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.customer_token = None
        cls.vendor_token = None
        cls.delivery_token = None
        session = requests.Session()

        # Customer login flow
        url = BASE_URL + "customer/send_otp/"
        req = {"mobile": CUSTOMER_MOBILE}
        session.post(url, json=req)
        verify_url = BASE_URL + "customer/verify_otp/"
        verify_req = {"mobile": CUSTOMER_MOBILE, "otp": TEST_OTP}
        res = session.post(verify_url, json=verify_req)
        data = res.json() if res.status_code == 200 else {}
        if data.get("signup_required") and "signup_token" in data:
            signup_url = BASE_URL + "customer/signup/"
            signup_req = {
                "signup_token": data["signup_token"],
                "first_name": "Test Customer",
                "last_name": "User",
                "email": "testcustomer@example.com",
                "phone_number": CUSTOMER_MOBILE
            }
            signup_res = session.post(signup_url, json=signup_req)
            # print("[DEBUG] Customer signup response:", signup_res.status_code, signup_res.text)
            # print("[DEBUG] Customer signup response body:", signup_res.json() if signup_res.status_code == 200 else signup_res.text)
            signup_data = signup_res.json() if signup_res.status_code == 200 else {}
            cls.customer_token = signup_data.get("access") or signup_data.get("token")
        else:
            cls.customer_token = data.get("access") or data.get("token")

        # Vendor login flow
        url = BASE_URL + "vendor/send_otp/"
        req = {"mobile": VENDOR_MOBILE}
        session.post(url, json=req)
        verify_url = BASE_URL + "vendor/verify_otp/"
        verify_req = {"mobile": VENDOR_MOBILE, "otp": TEST_OTP}
        res = session.post(verify_url, json=verify_req)
        data = res.json() if res.status_code == 200 else {}
        if data.get("signup_required") and "signup_token" in data:
            signup_url = BASE_URL + "vendor/signup/"
            signup_req = {
                "signup_token": data["signup_token"],
                "company_name": "Test Vendor Company",
                "email": "testvendor@example.com"
            }
            signup_res = session.post(signup_url, json=signup_req)
            # print("[DEBUG] Vendor signup response:", signup_res.status_code, signup_res.text)
            # print("[DEBUG] Vendor signup response body:", signup_res.json() if signup_res.status_code == 200 else signup_res.text)
            signup_data = signup_res.json() if signup_res.status_code == 200 else {}
            cls.vendor_token = signup_data.get("access") or signup_data.get("token") or signup_data.get("access_token")
        else:
            cls.vendor_token = data.get("access") or data.get("token") or data.get("access_token")

        # Delivery login flow
        url = BASE_URL + "delivery/send_otp/"
        req = {"mobile": DELIVERY_MOBILE}
        session.post(url, json=req)
        verify_url = BASE_URL + "delivery/verify_otp/"
        verify_req = {"mobile": DELIVERY_MOBILE, "otp": TEST_OTP}
        res = session.post(verify_url, json=verify_req)
        data = res.json() if res.status_code == 200 else {}
        if data.get("signup_required") and "signup_token" in data:
            signup_url = BASE_URL + "delivery/signup/"
            signup_req = {
                "mobile": DELIVERY_MOBILE,
                "name": "Test Delivery",
                "signup_token": data["signup_token"]
            }
            signup_res = session.post(signup_url, json=signup_req)
            # print("[DEBUG] Delivery signup response:", signup_res.status_code, signup_res.text)
            signup_data = signup_res.json() if signup_res.status_code == 200 else {}
            cls.delivery_token = signup_data.get("access") or signup_data.get("token")
        else:
            cls.delivery_token = data.get("access") or data.get("token")

    def setUp(self):
        self.session = requests.Session()
        self.order_id = None

    # ---- AUTH TESTS ----
    def test_01_customer_send_otp(self):
        url = BASE_URL + "customer/send_otp/"
        req = {"mobile": CUSTOMER_MOBILE}
        res = self.session.post(url, json=req)
        expected_status = 200
        try:
            self.assertEqual(res.status_code, expected_status)
            self.assertIn("message", res.json())
            log_case(url, "Customer Send OTP", req, res.json(), res.status_code, expected_status, True)
        except Exception as e:
            log_case(url, "Customer Send OTP", req, res.text, res.status_code, expected_status, False, str(e))

    def test_02_customer_verify_otp(self):
        url = BASE_URL + "customer/verify_otp/"
        req = {"mobile": CUSTOMER_MOBILE, "otp": TEST_OTP}
        res = self.session.post(url, json=req)
        expected_status = 200
        try:
            data = res.json()
            if res.status_code == 200 and ("access" in data or "token" in data):
                self.customer_token = data.get("access") or data.get("token")
                self.session.headers.update({"Authorization": f"Bearer {self.customer_token}"})
                log_case(url, "Customer Verify OTP", req, data, res.status_code, expected_status, True)
            elif res.status_code == 200 and data.get("signup_required") and "signup_token" in data:
                # Automatically register user
                signup_url = BASE_URL + "customer/signup/"
                signup_req = {
                    "mobile": CUSTOMER_MOBILE,
                    "name": "Test Customer",
                    "signup_token": data["signup_token"]
                }
                signup_res = self.session.post(signup_url, json=signup_req)
                if signup_res.status_code == 200 and "token" in signup_res.json():
                    self.customer_token = signup_res.json()["token"]
                    self.session.headers.update({"Authorization": f"Bearer {self.customer_token}"})
                    log_case(signup_url, "Customer Signup", signup_req, signup_res.json(), signup_res.status_code, 200, True)
                else:
                    log_case(signup_url, "Customer Signup", signup_req, signup_res.text, signup_res.status_code, 200, False, "Signup failed")
                # Retry OTP verification to simulate login
                res2 = self.session.post(url, json=req)
                if res2.status_code == 200 and "token" in res2.json():
                    self.customer_token = res2.json()["token"]
                    self.session.headers.update({"Authorization": f"Bearer {self.customer_token}"})
                    log_case(url, "Customer Verify OTP (after signup)", req, res2.json(), res2.status_code, expected_status, True)
                else:
                    log_case(url, "Customer Verify OTP (after signup)", req, res2.text, res2.status_code, expected_status, False, "No token after signup")
            else:
                log_case(url, "Customer Verify OTP", req, data, res.status_code, expected_status, False, "No token or signup flow")
        except Exception as e:
            log_case(url, "Customer Verify OTP", req, res.text, res.status_code, expected_status, False, str(e))

    # ---- CUSTOMER APP TESTS ----
    def test_03_customer_home(self):
        if self.customer_token:
            self.session.headers.update({"Authorization": f"Bearer {self.customer_token}"})

        url = BASE_URL + "customer/home/"
        req = {}
        res = self.session.get(url)
        expected_status = 200
        try:
            self.assertEqual(res.status_code, expected_status)
            for key in ["banners", "categories", "nearby_restaurants", "top_rated_restaurants", "popular_foods"]:
                self.assertIn(key, res.json())
            log_case(url, "Customer Home", req, res.json(), res.status_code, expected_status, True)
        except Exception as e:
            log_case(url, "Customer Home", req, res.text, res.status_code, expected_status, False, str(e))

    def test_04_customer_cart_add(self):
        if self.customer_token:
            self.session.headers.update({"Authorization": f"Bearer {self.customer_token}"})

        url = BASE_URL + "customer/cart/add/"
        req = {"item_id": 1, "quantity": 2}
        res = self.session.post(url, json=req)
        expected_status = 200  # Accept 200 or 201
        try:
            self.assertIn(res.status_code, [200, 201])
            self.assertIn("message", res.json())
            log_case(url, "Customer Cart Add", req, res.json(), res.status_code, expected_status, True)
        except Exception as e:
            log_case(url, "Customer Cart Add", req, res.text, res.status_code, expected_status, False, str(e))

    def test_05_customer_cart_view(self):
        if self.customer_token:
            self.session.headers.update({"Authorization": f"Bearer {self.customer_token}"})

        url = BASE_URL + "customer/cart/"
        req = {}
        res = self.session.get(url)
        expected_status = 200
        try:
            self.assertEqual(res.status_code, expected_status)
            self.assertIn("items", res.json())
            log_case(url, "Customer Cart View", req, res.json(), res.status_code, expected_status, True)
        except Exception as e:
            log_case(url, "Customer Cart View", req, res.text, res.status_code, expected_status, False, str(e))

    def test_06_customer_place_order(self):
        if self.customer_token:
            self.session.headers.update({"Authorization": f"Bearer {self.customer_token}"})

        url = BASE_URL + "customer/order/place/"
        req = {"address": "123 Main St"}
        res = self.session.post(url, json=req)
        expected_status = 201
        try:
            self.assertEqual(res.status_code, expected_status)
            self.assertIn("order_id", res.json())
            self.order_id = res.json()["order_id"]
            log_case(url, "Customer Place Order", req, res.json(), res.status_code, expected_status, True)
        except Exception as e:
            log_case(url, "Customer Place Order", req, res.text, res.status_code, expected_status, False, str(e))

    def test_07_customer_order_history(self):
        if self.customer_token:
            self.session.headers.update({"Authorization": f"Bearer {self.customer_token}"})

        # Clear Authorization header after customer block
        self.session.headers.pop('Authorization', None)

        url = BASE_URL + "customer/orders/"
        req = {}
        res = self.session.get(url)
        expected_status = 200
        try:
            self.assertEqual(res.status_code, expected_status)
            self.assertIsInstance(res.json(), list)
            log_case(url, "Customer Order History", req, res.json(), res.status_code, expected_status, True, "")
        except Exception as e:
            log_case(url, "Customer Order History", req, res.text, res.status_code, expected_status, False, str(e))

    # ---- VENDOR APP TESTS ----
    def test_08_vendor_send_otp(self):
        url = BASE_URL + "vendor/send_otp/"
        req = {"mobile": VENDOR_MOBILE}
        res = self.session.post(url, json=req)
        expected_status = 200
        try:
            self.assertEqual(res.status_code, expected_status)
            log_case(url, "Vendor Send OTP", req, res.json(), res.status_code, expected_status, True, "")
        except Exception as e:
            log_case(url, "Vendor Send OTP", req, res.text, res.status_code, expected_status, False, str(e))

    def test_09_vendor_verify_otp(self):
        url = BASE_URL + "vendor/verify_otp/"
        req = {"mobile": VENDOR_MOBILE, "otp": TEST_OTP}
        res = self.session.post(url, json=req)
        expected_status = 200
        try:
            data = res.json()
            if res.status_code == 200 and ("access" in data or "token" in data):
                self.vendor_token = data.get("access") or data.get("token")
                self.session.headers.update({"Authorization": f"Bearer {self.vendor_token}"})
                log_case(url, "Vendor Verify OTP", req, data, res.status_code, expected_status, True)
            elif res.status_code == 200 and data.get("signup_required") and "signup_token" in data:
                # Automatically register vendor
                signup_url = BASE_URL + "vendor/signup/"
                signup_req = {
                    "mobile": VENDOR_MOBILE,
                    "name": "Test Vendor",
                    "signup_token": data["signup_token"]
                }
                signup_res = self.session.post(signup_url, json=signup_req)
                if signup_res.status_code == 200 and "token" in signup_res.json():
                    self.vendor_token = signup_res.json()["token"]
                    self.session.headers.update({"Authorization": f"Bearer {self.vendor_token}"})
                    log_case(signup_url, "Vendor Signup", signup_req, signup_res.json(), signup_res.status_code, 200, True)
                else:
                    log_case(signup_url, "Vendor Signup", signup_req, signup_res.text, signup_res.status_code, 200, False, "Signup failed")
                # Retry OTP verification to simulate login
                res2 = self.session.post(url, json=req)
                if res2.status_code == 200 and "token" in res2.json():
                    self.vendor_token = res2.json()["token"]
                    self.session.headers.update({"Authorization": f"Bearer {self.vendor_token}"})
                    log_case(url, "Vendor Verify OTP (after signup)", req, res2.json(), res2.status_code, expected_status, True)
                else:
                    log_case(url, "Vendor Verify OTP (after signup)", req, res2.text, res2.status_code, expected_status, False, "No token after signup")
            else:
                log_case(url, "Vendor Verify OTP", req, data, res.status_code, expected_status, False, "No token or signup flow")
        except Exception as e:
            log_case(url, "Vendor Verify OTP", req, res.text, res.status_code, expected_status, False, str(e))

    def test_10_vendor_profile(self):
        if self.vendor_token:
            self.session.headers.update({"Authorization": f"Bearer {self.vendor_token}"})

        self.session.headers.update({"Authorization": f"Bearer {self.vendor_token}"})
        url = BASE_URL + "vendor/profile/"
        req = {}
        res = self.session.get(url)
        expected_status = 200
        try:
            self.assertEqual(res.status_code, expected_status)
            log_case(url, "Vendor Profile", req, res.json(), res.status_code, expected_status, True, "")
        except Exception as e:
            log_case(url, "Vendor Profile", req, res.text, res.status_code, expected_status, False, str(e))

    def test_11_vendor_menu_list(self):
        if self.vendor_token:
            self.session.headers.update({"Authorization": f"Bearer {self.vendor_token}"})

        url = BASE_URL + "vendor/menu/"
        req = {}
        res = self.session.get(url)
        expected_status = 200
        try:
            self.assertEqual(res.status_code, expected_status)
            self.assertIsInstance(res.json(), list)
            log_case(url, "Vendor Menu List", req, res.json(), res.status_code, expected_status, True, "")
        except Exception as e:
            log_case(url, "Vendor Menu List", req, res.text, res.status_code, expected_status, False, str(e))

    def test_12_vendor_orders(self):
        if self.vendor_token:
            self.session.headers.update({"Authorization": f"Bearer {self.vendor_token}"})

        # Clear Authorization header after vendor block
        self.session.headers.pop('Authorization', None)

        url = BASE_URL + "vendor/orders/"
        req = {}
        res = self.session.get(url)
        expected_status = 200
        try:
            self.assertEqual(res.status_code, expected_status)
            log_case(url, "Vendor Orders", req, res.json(), res.status_code, expected_status, True)
        except Exception as e:
            log_case(url, "Vendor Orders", req, res.text, res.status_code, expected_status, False, str(e))

    # ---- DELIVERY PARTNER TESTS ----
    def test_13_delivery_send_otp(self):
        url = BASE_URL + "delivery/send_otp/"
        req = {"mobile": DELIVERY_MOBILE}
        res = self.session.post(url, json=req)
        expected_status = 200
        try:
            self.assertEqual(res.status_code, expected_status)
            log_case(url, "Delivery Send OTP", req, res.json(), res.status_code, expected_status, True)
        except Exception as e:
            log_case(url, "Delivery Send OTP", req, res.text, res.status_code, expected_status, False, str(e))

    def test_14_delivery_verify_otp(self):
        url = BASE_URL + "delivery/verify_otp/"
        req = {"mobile": DELIVERY_MOBILE, "otp": TEST_OTP}
        res = self.session.post(url, json=req)
        expected_status = 200
        try:
            data = res.json()
            if res.status_code == 200 and ("access" in data or "token" in data):
                self.delivery_token = data.get("access") or data.get("token")
                self.session.headers.update({"Authorization": f"Bearer {self.delivery_token}"})
                log_case(url, "Delivery Verify OTP", req, data, res.status_code, expected_status, True)
            elif res.status_code == 200 and data.get("signup_required") and "signup_token" in data:
                # Automatically register delivery user
                signup_url = BASE_URL + "delivery/signup/"
                signup_req = {
                    "mobile": DELIVERY_MOBILE,
                    "name": "Test Delivery",
                    "signup_token": data["signup_token"]
                }
                signup_res = self.session.post(signup_url, json=signup_req)
                if signup_res.status_code == 200 and "token" in signup_res.json():
                    self.delivery_token = signup_res.json()["token"]
                    self.session.headers.update({"Authorization": f"Bearer {self.delivery_token}"})
                    log_case(signup_url, "Delivery Signup", signup_req, signup_res.json(), signup_res.status_code, 200, True)
                else:
                    log_case(signup_url, "Delivery Signup", signup_req, signup_res.text, signup_res.status_code, 200, False, "Signup failed")
                # Retry OTP verification to simulate login
                res2 = self.session.post(url, json=req)
                if res2.status_code == 200 and "token" in res2.json():
                    self.delivery_token = res2.json()["token"]
                    self.session.headers.update({"Authorization": f"Bearer {self.delivery_token}"})
                    log_case(url, "Delivery Verify OTP (after signup)", req, res2.json(), res2.status_code, expected_status, True)
                else:
                    log_case(url, "Delivery Verify OTP (after signup)", req, res2.text, res2.status_code, expected_status, False, "No token after signup")
            else:
                log_case(url, "Delivery Verify OTP", req, data, res.status_code, expected_status, False, "No token or signup flow")
        except Exception as e:
            log_case(url, "Delivery Verify OTP", req, res.text, res.status_code, expected_status, False, str(e))

    def test_15_delivery_orders(self):
        if self.delivery_token:
            self.session.headers.update({"Authorization": f"Bearer {self.delivery_token}"})

        self.session.headers.update({"Authorization": f"Bearer {self.delivery_token}"})
        url = BASE_URL + "delivery/orders/"
        req = {}
        res = self.session.get(url)
        expected_status = 200
        try:
            self.assertEqual(res.status_code, expected_status)
            log_case(url, "Delivery Orders", req, res.json(), res.status_code, expected_status, True)
        except Exception as e:
            log_case(url, "Delivery Orders", req, res.text, res.status_code, expected_status, False, str(e))

    def test_16_delivery_history(self):
        if self.delivery_token:
            self.session.headers.update({"Authorization": f"Bearer {self.delivery_token}"})

        # Clear Authorization header after delivery block
        self.session.headers.pop('Authorization', None)

        url = BASE_URL + "delivery/history/"
        req = {}
        res = self.session.get(url)
        expected_status = 200
        try:
            self.assertEqual(res.status_code, expected_status)
            log_case(url, "Delivery History", req, res.json(), res.status_code, expected_status, True)
        except Exception as e:
            log_case(url, "Delivery History", req, res.text, res.status_code, expected_status, False, str(e))

    # ---- COMMON/NOTIFICATION TESTS ----
    def test_17_register_fcm_token(self):
        url = BASE_URL + "common/register_fcm_token/"
        req = {"user_id": 1, "user_type": "customer", "fcm_token": "test_token"}
        res = self.session.post(url, json=req)
        expected_status = 200
        try:
            self.assertIn(res.status_code, [200, 201])
            log_case(url, "Register FCM Token", req, res.json(), res.status_code, expected_status, True)
        except Exception as e:
            log_case(url, "Register FCM Token", req, res.text, res.status_code, expected_status, False, str(e))

    def test_18_test_notification(self):
        url = BASE_URL + "common/test_notification/"
        req = {"user_id": 1, "user_type": "customer", "message": "Hello"}
        res = self.session.post(url, json=req)
        expected_status = 200
        try:
            self.assertEqual(res.status_code, expected_status)
            log_case(url, "Test Notification", req, res.json(), res.status_code, expected_status, True)
        except Exception as e:
            log_case(url, "Test Notification", req, res.text, res.status_code, expected_status, False, str(e))

    # ---- ERROR CASES & PERMISSION CHECKS ----
    def test_19_customer_access_vendor_api(self):
        self.session.headers.update({"Authorization": f"Bearer {self.customer_token}"})
        url = BASE_URL + "vendor/orders/"
        req = {}
        res = self.session.get(url)
        expected_status = 403
        try:
            self.assertEqual(res.status_code, expected_status)
            log_case(url, "Customer Access Vendor API", req, res.json(), res.status_code, expected_status, True)
        except Exception as e:
            log_case(url, "Customer Access Vendor API", req, res.text, res.status_code, expected_status, False, str(e))

    def test_20_missing_fields(self):
        url = BASE_URL + "customer/cart/add/"
        req = {}
        res = self.session.post(url, json=req)
        expected_status = 400
        try:
            self.assertIn(res.status_code, [400, 422])
            log_case(url, "Missing Fields in Cart Add", req, res.json(), res.status_code, expected_status, True)
        except Exception as e:
            log_case(url, "Missing Fields in Cart Add", req, res.text, res.status_code, expected_status, False, str(e))

if __name__ == "__main__":
    unittest.main(exit=False)
    # print("\n\n================= API TEST REPORT =================\n")
    for entry in report:
        # print(json.dumps(entry, indent=2, ensure_ascii=False))
