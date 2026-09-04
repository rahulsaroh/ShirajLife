import json
from http.server import ThreadingHTTPServer, BaseHTTPRequestHandler
import os
import threading
import time

DB_FILE = os.path.join(os.path.dirname(__file__), "gym_db.json")

# Default gym data
DEFAULT_DATA = {
    "branches": [
        {"id": "downtown", "name": "Downtown Fitness Center", "location": "New York, USA"},
        {"id": "west-end", "name": "West End Strength Gym", "location": "London, UK"},
        {"id": "east-side", "name": "East Side HIIT Club", "location": "Tokyo, Japan"}
    ],
    "trainers": [
        {"id": "none", "name": "No Trainer", "clientsCount": 0, "yearsExperience": 0, "tags": ["N/A"], "branchId": "all"},
        {"id": "king", "name": "King Zarips", "clientsCount": 3, "yearsExperience": 2, "tags": ["Motivation", "Mentality"], "branchId": "downtown"},
        {"id": "lerry", "name": "Lerry Rops", "clientsCount": 2, "yearsExperience": 1, "tags": ["Weight", "Power"], "branchId": "west-end"},
        {"id": "sarah", "name": "Sarah Connor", "clientsCount": 0, "yearsExperience": 4, "tags": ["Kettlebell", "HIIT"], "branchId": "east-side"}
    ],
    "students": [
        {
            "id": "bessie", "name": "Bessie Cooper", "email": "bessiecop@hotmail.com", "expiredDate": "08/05/2026", "age": 24, "status": "Active", "tel": "277-555-0119", "lastVisited": "Yesterday", "trainerId": "king", "isCheckedIn": False, "branchId": "downtown",
            "weeklyCheckins": [5, 4, 3],
            "subscription": {"autoDebit": True, "billingFailed": False, "gracePeriodDays": 3, "paymentMethod": "Stripe"},
            "workoutCredits": 12, "totalWorkouts": 99, "referralsCount": 2, "staffNotes": "Prefers barbell squats; slight shoulder stiffness."
        },
        {
            "id": "eleanor", "name": "Eleanor Pena", "email": "eleanor.pena@icloud.com", "expiredDate": "12/07/2026", "age": 24, "status": "In Active", "tel": "290-902-4829", "lastVisited": "Today", "trainerId": "none", "isCheckedIn": True, "branchId": "west-end",
            "weeklyCheckins": [4, 5, 5],
            "subscription": {"autoDebit": True, "billingFailed": True, "gracePeriodDays": 0, "paymentMethod": "Razorpay"},
            "workoutCredits": 5, "totalWorkouts": 45, "referralsCount": 0, "staffNotes": "Recovering from ankle strain. Avoid heavy dynamic jumping."
        },
        {
            "id": "albert", "name": "Albert Flores", "email": "albert.flores@yahoo.com", "expiredDate": "12/09/2026", "age": 28, "status": "Active", "tel": "505-555-0125", "lastVisited": "Today", "trainerId": "king", "isCheckedIn": False, "branchId": "downtown",
            "weeklyCheckins": [3, 0, 0],
            "subscription": {"autoDebit": True, "billingFailed": False, "gracePeriodDays": 3, "paymentMethod": "Stripe"},
            "workoutCredits": 8, "totalWorkouts": 78, "referralsCount": 1, "staffNotes": "Focus on progressive loading. Absent warning triggered."
        },
        {
            "id": "jane", "name": "Jane Cooper", "email": "jane.cooper@gmail.com", "expiredDate": "15/07/2026", "age": 22, "status": "Active", "tel": "302-555-0199", "lastVisited": "Yesterday", "trainerId": "king", "isCheckedIn": True, "branchId": "downtown",
            "weeklyCheckins": [5, 5, 5],
            "subscription": {"autoDebit": True, "billingFailed": False, "gracePeriodDays": 3, "paymentMethod": "Stripe"},
            "workoutCredits": 10, "totalWorkouts": 120, "referralsCount": 4, "staffNotes": "Prep for half-marathon; emphasize hamstring and calf foam roll."
        },
        {
            "id": "robert", "name": "Robert Fox", "email": "robert.fox@gmail.com", "expiredDate": "30/08/2026", "age": 29, "status": "Active", "tel": "704-555-0182", "lastVisited": "Yesterday", "trainerId": "none", "isCheckedIn": False, "branchId": "west-end",
            "weeklyCheckins": [2, 1, 0],
            "subscription": {"autoDebit": False, "billingFailed": True, "gracePeriodDays": 0, "paymentMethod": "Cash"},
            "workoutCredits": 0, "totalWorkouts": 12, "referralsCount": 0, "staffNotes": "General fitness, target fat loss. Failed auto-debit block."
        }
    ],
    "advice": [
        {"studentId": "bessie", "coachId": "king", "coachName": "King Zarips", "text": "Ensure your knees trace outward on the barbell descent. Keep chest high to preserve pelvic alignment.", "category": "Form Correction", "time": "09:30 AM", "branchId": "downtown"},
        {"studentId": "eleanor", "coachId": "lerry", "coachName": "Lerry Rops", "text": "Scale back carbs on non-training recovery days. Add 20g whey isolate post-workout.", "category": "Dietary Recommendation", "time": "11:20 AM", "branchId": "west-end"},
        {"studentId": "bessie", "coachId": "king", "coachName": "King Zarips", "text": "Take 48 hours recovery before heavy pulling. Focus on hip flexor foam rolling.", "category": "Recovery Advice", "time": "Yesterday", "branchId": "downtown"}
    ],
    "equipment": [
        {"id": "treadmill-1", "name": "NordicTrack Treadmill T8", "category": "Cardio", "status": "Operational", "lastMaintenance": "2026-05-15", "branchId": "downtown", "downtimeDays": 2, "serviceHistory": ["2026-05-15: Belt tension calibrated", "2026-06-02: Safety switch check"]},
        {"id": "squat-rack-1", "name": "Power Squat Rack A", "category": "Strength", "status": "Operational", "lastMaintenance": "2026-06-01", "branchId": "downtown", "downtimeDays": 0, "serviceHistory": ["2026-06-01: Bolt tightening & structural audit"]},
        {"id": "leg-press-1", "name": "Linear Leg Press Machine", "category": "Strength", "status": "Under Maintenance", "lastMaintenance": "2026-06-12", "branchId": "west-end", "downtimeDays": 6, "serviceHistory": ["2026-06-12: Carriage bearings replaced"]},
        {"id": "spin-bike-1", "name": "Peloton Spin Bike Pro", "category": "Cardio", "status": "Broken", "lastMaintenance": "2026-04-20", "branchId": "east-side", "downtimeDays": 59, "serviceHistory": ["2026-04-20: Drive belt snapped", "2026-06-18: Tech webhook dispatched"]}
    ],
    "leads": [
        {"id": "lead-1", "name": "David Beckham", "email": "david.beck@gmail.com", "tel": "415-555-2671", "stage": "new"},
        {"id": "lead-2", "name": "Maria Sharapova", "email": "maria.shara@yahoo.com", "tel": "310-555-8921", "stage": "trial"},
        {"id": "lead-3", "name": "Priya Sharma", "email": "priya.sharma@hotmail.com", "tel": "98765-43210", "stage": "completed"},
        {"id": "lead-4", "name": "John Doe", "email": "john.doe@gmail.com", "tel": "212-555-0988", "stage": "won"}
    ],
    "proShopInventory": [
        {"id": "whey-1", "name": "Whey Protein Isolate 1kg", "price": 45.00, "stock": 10, "reorderThreshold": 3, "branchId": "downtown"},
        {"id": "pre-1", "name": "Pre-Workout C4 30srv", "price": 35.00, "stock": 2, "reorderThreshold": 4, "branchId": "downtown"},
        {"id": "water-1", "name": "Energy Hydration Drink 500ml", "price": 3.00, "stock": 25, "reorderThreshold": 5, "branchId": "west-end"},
        {"id": "shaker-1", "name": "goJim Steel Shaker", "price": 15.00, "stock": 8, "reorderThreshold": 2, "branchId": "east-side"}
    ],
    "checklists": [
        {
            "id": "chk-1",
            "date": "2026-06-18",
            "shift": "Morning",
            "completedBy": "King Zarips",
            "items": [
                {"task": "Sanitize dumbbells and weight plates", "done": True, "time": "08:15 AM", "photo": "sanitized_weights.png"},
                {"task": "Check locker rooms hygiene standards", "done": True, "time": "08:30 AM", "photo": "locker_hygiene.png"},
                {"task": "Verify water stations filters and refill cups", "done": True, "time": "08:45 AM", "photo": "water_station.png"},
                {"task": "Inspect cardio machinery emergency stop clips", "done": False, "time": "", "photo": ""}
            ],
            "branchId": "downtown"
        }
    ],
    "trainerAvailability": [
        {"trainerId": "king", "slots": ["08:00 AM", "10:00 AM", "04:00 PM"], "bookings": [{"slot": "08:00 AM", "studentId": "bessie", "bookedAt": "2026-06-18"}]},
        {"trainerId": "lerry", "slots": ["09:00 AM", "11:00 AM", "05:00 PM"], "bookings": []},
        {"trainerId": "sarah", "slots": ["08:00 AM", "10:00 AM", "06:00 PM"], "bookings": [{"slot": "06:00 PM", "studentId": "eleanor", "bookedAt": "2026-06-18"}]}
    ],
    "zones": [
        {"id": "rack-1", "name": "Olympic Squat Rack A", "capacity": 1, "status": "Reserved", "activeBooking": {"studentId": "jane", "until": "12:30 PM"}, "waitlist": [{"studentId": "bessie", "timestamp": "11:45 AM"}, {"studentId": "albert", "timestamp": "11:50 AM"}], "branchId": "downtown"},
        {"id": "cable-1", "name": "Dual Cable Column 1", "capacity": 1, "status": "Available", "activeBooking": None, "waitlist": [], "branchId": "downtown"},
        {"id": "platform-1", "name": "Deadlift Lifting Platform", "capacity": 1, "status": "Available", "activeBooking": None, "waitlist": [], "branchId": "west-end"}
    ],
    "workoutLogs": [
        {
            "studentId": "bessie",
            "date": "2026-06-18",
            "exercises": [
                {"name": "Barbell Squat", "sets": [{"reps": 8, "weight": 80}, {"reps": 6, "weight": 90}, {"reps": 4, "weight": 100}]},
                {"name": "Bench Press", "sets": [{"reps": 10, "weight": 60}, {"reps": 8, "weight": 70}, {"reps": 6, "weight": 80}]}
            ],
            "bodyComposition": {"weight": 72.5, "fatPct": 14.5}
        }
    ],
    "announcements": [
        {"id": "ann-1", "author": "Owner", "text": "New dumbbells arriving on Downtown branch this Friday!", "date": "2026-06-18"},
        {"id": "ann-2", "author": "Owner", "text": "Cleanliness drive: hourly logs must be uploaded with photo checks.", "date": "2026-06-18"}
    ],
    "socialSchedule": [
        {"id": "post-1", "platform": "Instagram", "caption": "Transform your routine with goJim strength programs! 💪", "date": "2026-06-20", "status": "Scheduled"},
        {"id": "post-2", "platform": "Facebook", "caption": "Unlock your PRs today at goJim branches. ⚡", "date": "2026-06-22", "status": "Draft"}
    ]
}

class GymDbHandler(BaseHTTPRequestHandler):
    def end_headers(self):
        self.send_header('Access-Control-Allow-Origin', '*')
        self.send_header('Access-Control-Allow-Methods', 'GET, POST, OPTIONS')
        self.send_header('Access-Control-Allow-Headers', 'Content-Type')
        super().end_headers()

    def do_OPTIONS(self):
        self.send_response(200)
        self.end_headers()

    def do_GET(self):
        if self.path == "/data":
            self.send_response(200)
            self.send_header('Content-Type', 'application/json')
            self.end_headers()
            
            # Ensure the file exists and is populated
            if not os.path.exists(DB_FILE):
                with open(DB_FILE, "w") as f:
                    json.dump(DEFAULT_DATA, f, indent=4)
                    
            with open(DB_FILE, "r") as f:
                self.wfile.write(f.read().encode('utf-8'))
        else:
            clean_path = self.path.split('?')[0]
            if clean_path == '/' or clean_path == '':
                clean_path = '/index.html'
            local_path = os.path.join(os.path.dirname(__file__), clean_path.lstrip('/'))
            
            if os.path.exists(local_path) and os.path.isfile(local_path):
                self.send_response(200)
                
                # Determine content type
                if local_path.endswith('.html'):
                    self.send_header('Content-Type', 'text/html; charset=utf-8')
                elif local_path.endswith('.css'):
                    self.send_header('Content-Type', 'text/css; charset=utf-8')
                elif local_path.endswith('.js'):
                    self.send_header('Content-Type', 'application/javascript; charset=utf-8')
                elif local_path.endswith('.png'):
                    self.send_header('Content-Type', 'image/png')
                elif local_path.endswith('.ico'):
                    self.send_header('Content-Type', 'image/x-icon')
                elif local_path.endswith('.svg'):
                    self.send_header('Content-Type', 'image/svg+xml')
                elif local_path.endswith('.json') or local_path.endswith('.webmanifest'):
                    self.send_header('Content-Type', 'application/json; charset=utf-8')
                elif local_path.endswith('.jpg') or local_path.endswith('.jpeg'):
                    self.send_header('Content-Type', 'image/jpeg')
                else:
                    self.send_header('Content-Type', 'application/octet-stream')
                self.end_headers()
                
                with open(local_path, "rb") as f:
                    self.wfile.write(f.read())
            else:
                self.send_response(404)
                self.end_headers()

    def do_POST(self):
        if self.path == "/data":
            content_length = int(self.headers['Content-Length'])
            post_data = self.rfile.read(content_length)
            
            try:
                data = json.loads(post_data.decode('utf-8'))
                
                # Load existing DB state to merge omitted keys (like proShopInventory) from client updates
                existing_data = {}
                if os.path.exists(DB_FILE):
                    try:
                        with open(DB_FILE, "r") as f:
                            existing_data = json.load(f)
                    except Exception:
                        existing_data = {}

                required_keys = ["trainers", "students", "advice", "equipment", "branches", "leads", "proShopInventory", "checklists", "trainerAvailability", "zones", "workoutLogs", "announcements", "socialSchedule"]
                for key in required_keys:
                    if key not in data:
                        if key in existing_data:
                            data[key] = existing_data[key]
                        else:
                            data[key] = DEFAULT_DATA.get(key, [])

                with open(DB_FILE, "w") as f:
                    json.dump(data, f, indent=4)
                
                self.send_response(200)
                self.send_header('Content-Type', 'application/json')
                self.end_headers()
                self.wfile.write(json.dumps({"status": "success"}).encode('utf-8'))
            except Exception as e:
                self.send_response(500)
                self.end_headers()
                self.wfile.write(json.dumps({"error": str(e)}).encode('utf-8'))
        else:
            self.send_response(404)
            self.end_headers()

def predictive_engagement_worker():
    while True:
        try:
            time.sleep(10)
            if not os.path.exists(DB_FILE):
                continue
                
            with open(DB_FILE, "r") as f:
                data = json.load(f)
            
            updated = False
            if "students" in data:
                for student in data["students"]:
                    # check WoW drop or 14+ days absent
                    if "weeklyCheckins" in student and len(student["weeklyCheckins"]) >= 2:
                        prev = student["weeklyCheckins"][-2]
                        curr = student["weeklyCheckins"][-1]
                        
                        # Case 1: 14+ days absent (last 2 weeks check-ins are both 0)
                        if len(student["weeklyCheckins"]) >= 2 and student["weeklyCheckins"][-1] == 0 and student["weeklyCheckins"][-2] == 0:
                            if student.get("status") != "At-Risk (14+ Days Absent)":
                                student["status"] = "At-Risk (14+ Days Absent)"
                                updated = True
                                print(f"[PREDICTIVE CHURN] Flagged {student['name']} as At-Risk (14+ Days Absent). Firing re-engagement SMS.")
                        # Case 2: WoW drop >= 40%
                        elif prev > 0:
                            drop = (prev - curr) / prev
                            if drop >= 0.40:
                                if student.get("status") != "At-Risk":
                                    student["status"] = "At-Risk"
                                    updated = True
                                    print(f"[PREDICTIVE CHURN] Flagged {student['name']} as At-Risk due to WoW drop of {int(drop*100)}%. Firing complimentary assessment SMS.")
            
            if updated:
                with open(DB_FILE, "w") as f:
                    json.dump(data, f, indent=4)
        except Exception as e:
            print(f"[BACKGROUND WORKER ERROR] {e}")

if __name__ == "__main__":
    t = threading.Thread(target=predictive_engagement_worker, daemon=True)
    t.start()
    server = ThreadingHTTPServer(('0.0.0.0', 8000), GymDbHandler)
    print("Gym DB Server running on http://localhost:8000...")
    server.serve_forever()

