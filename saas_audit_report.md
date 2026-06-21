# goJim SaaS Ecosystem — Professional Audit Report
**Auditor:** Antigravity (Senior SaaS Engineering perspective)
**Scope:** Flutter Mobile App + shirajlife.com web console (`gym-dashboard.html`)
**Date:** June 2026

---

## Executive Summary

The goJim ecosystem has a strong foundation — real-time Firestore listeners, dual-platform auth, and a mirroring strategy to the ShirajLife B2B CRM. However, there are **7 critical issues** and **9 improvement opportunities** that, if unresolved, will cause data divergence, security vulnerabilities, and a degraded user experience in production.

---

## 🔴 Critical Issues (Must Fix)

### CRIT-1 — Dual Data Sources: Firestore vs. LocalStorage vs. localhost Server

**Severity:** 🔴 Critical — Data divergence between app and web guaranteed

**What's happening:**
The mobile app (`state.dart` L186, L364) syncs to `http://10.0.2.2:8000/data` — the Android emulator's loopback to a local Python server (`server.py`). The website (`gym-dashboard.html` L3758, L3773) also calls `http://localhost:8000/data`. In production (shirajlife.com), this server does not exist.

**Effect:**
- App creates a trainer → saved to `localhost:8000` (dev only) → website reads `localStorage` cache → **Firestore onSnapshot also fires but merges into the same localStorage** → inconsistent state
- A real gym owner on shirajlife.com will get **demo data** from DEFAULT_STUDENTS / DEFAULT_TRAINERS hardcoded in the JS (lines 3617–3636) instead of their Firestore data if localStorage has never been seeded from Firestore.

**Fix Required:**
- Remove the `fetchStateFromServer()` / `saveStateToServer()` HTTP calls from `state.dart` entirely. Firebase Firestore IS the server.
- Remove `fetch('http://localhost:8000/data')` from `gym-dashboard.html` lines 3758 and 3773.
- All writes must go to Firestore; reads must come from `onSnapshot` listeners.

---

### CRIT-2 — Missing `deleted` Event Handler in Firestore Listeners

**Severity:** 🔴 Critical — Deleted trainers/clients remain permanently on the dashboard

**Location:** `gym-dashboard.html` L4861–4927 (`startFirestoreListeners`)

**What's happening:**
```javascript
// Both listeners only handle "added" and "modified"
if (change.type === "added" || change.type === "modified") { ... }
// "removed" is NEVER handled
```
When a gym owner deletes a trainer or client from the mobile app (or from Firestore console), the website never removes them from `localStorage`. The ghost record persists indefinitely.

**Fix Required:**
Add a `removed` handler:
```javascript
} else if (change.type === "removed") {
    state.trainers = state.trainers.filter(t => t.id !== trainerId);
    hasChanges = true;
}
```

---

### CRIT-3 — Security: `applySessionRestrictions()` Can Be Bypassed via Browser Console

**Severity:** 🔴 Critical — Any user can see any gym's data

**Location:** `gym-dashboard.html` L4377–4486

**What's happening:**
The entire access control model is based on:
```javascript
const user = JSON.parse(localStorage.getItem('gojim_auth_user'));
```
Any visitor can open the browser DevTools console and type:
```javascript
localStorage.setItem('gojim_auth_user', JSON.stringify({role: 'owner', name: 'Hacker', linkedId: 'all'}));
location.reload();
```
They now have full owner access to all gym data. There is **no server-side token verification**.

**Fix Required:**
- `firebase.auth().onAuthStateChanged()` must be the gatekeeper. If `firebase.auth().currentUser` is null, redirect to login.
- The `linkedId` (gym restriction) must be fetched server-side from Firestore using `firebase.auth().currentUser.uid`, not from localStorage.
- Firestore Security Rules must enforce gym-scoped reads: `allow read: if request.auth.uid == resource.data.ownerUid`

---

### CRIT-4 — Firestore Security Rules: Open Read/Write on All Collections

**Severity:** 🔴 Critical — Anyone with the API key can read/write all gym data

**Location:** `firestore.rules`

**What's happening:**
```
allow read, write: if true; // for /gyms, /trainers, /clients
```
The Firebase API key is exposed in the HTML source (L3594). Since rules are wide open, any person who reads your HTML source can write arbitrary documents to your Firestore.

**Fix Required:**
```
match /gyms/{gymId} {
  allow read: if request.auth != null;
  allow write: if request.auth != null && request.auth.uid == resource.data.ownerUid;
}
match /trainers/{trainerId} {
  allow read: if request.auth != null;
  allow write: if request.auth != null;
}
match /users/{email} {
  allow read, write: if request.auth != null && request.auth.token.email == email;
}
```

---

### CRIT-5 — Passwords Stored in Plain Text in Firestore

**Severity:** 🔴 Critical — GDPR violation and catastrophic data breach risk

**Location:** `auth_screen.dart` L338, L367; `gym-dashboard.html` L4143, L4191, L4240

**What's happening:**
```dart
await userDoc.set({
  'email': email,
  'password': password,  // ← PLAIN TEXT PASSWORD IN FIRESTORE
  'role': 'owner',
```
The `/users` collection stores raw, unhashed passwords in Firestore. Any Firestore admin or breach exposes all user credentials.

**Fix Required:**
- Use **Firebase Authentication** exclusively for auth. Passwords never touch Firestore.
- The `/users` collection should only store: `{ role, name, linkedId }` — no password field.
- The sign-in flow must use `firebase.auth().signInWithEmailAndPassword()` (web) and `FirebaseAuth.instance.signInWithEmailAndPassword()` (Flutter), not a manual password check from Firestore.

---

### CRIT-6 — Referral Link Hardcoded to `localhost:8000`

**Severity:** 🔴 High — Broken in production for all clients

**Location:** `gym-dashboard.html` L2515

**What's happening:**
```html
<span id="student-referral-link-text">http://localhost:8000/gym-dashboard...</span>
```
The referral link shown to members is hardcoded to the dev server address. When a member copies and shares it, the link is broken.

**Fix Required:** Line 7317–7320 already dynamically sets `currentOrigin`, but this is only applied when `loadStudentWorkspace()` runs. The static placeholder `http://localhost:8000/gym-dashboard...` must be removed from the HTML.

---

### CRIT-7 — App State Not Scoped to Authenticated Gym

**Severity:** 🔴 High — All gym owners see the same shared mock data

**Location:** `state.dart` — `_initializeData()` L137–179

**What's happening:**
The app boots with hardcoded demo data (Bessie Cooper, Eleanor Pena, etc.). When `fetchStateFromServer()` runs, it either gets localhost data (dev only) or silently fails. `syncActiveRoutinesFromFirestore()` is scoped to `clientId` — good — but all other entities (students, trainers, branches) are never fetched from Firestore by gym ID.

**Fix Required:**
- On login, the owner's `linkedGymId` from SharedPreferences must be used to query Firestore: `collection('clients').where('gymId', '==', gymId)`
- The `_initializeData()` hardcoded data should only serve as the default when no Firestore data is present (i.e., truly a demo/new account).

---

## 🟡 High Priority Improvements

### IMP-1 — App/Web Sync Architecture: Missing Firestore Gym-Scoped Listeners in the App

The web dashboard has `startFirestoreListeners()` (even though it's incomplete). The Flutter app has zero real-time Firestore listeners — it only polls a local HTTP server every 5 seconds. The app needs `StreamBuilder` or `addSnapshotListener` calls on `collection('clients').where('gymId', '==', gymId)` to stay live with the web.

---

### IMP-2 — `addTrainerSubmit()` Does Not Write to Firestore

**Location:** `gym-dashboard.html` L4930–4964

When an owner adds a trainer via the web UI, it only writes to `localStorage` and does NOT create a Firestore document. This means the trainer is invisible to the mobile app.

**Fix:** Call `db.collection('trainers').doc(newId).set(newTrainer)` after pushing to local state.

---

### IMP-3 — `processSignOut()` Does Not Call `firebase.auth().signOut()`

**Location:** `gym-dashboard.html` L4488–4509

Sign-out only clears `localStorage`. The Firebase Auth session token remains active. If another person uses the same browser, they inherit the Firebase session.

**Fix:**
```javascript
firebase.auth().signOut().then(() => {
    localStorage.removeItem('gojim_auth_user');
    // ... rest of cleanup
});
```

---

### IMP-4 — Missing `gymId` Field on Trainer Registration (App)

**Location:** `auth_screen.dart` L377–399

When a trainer registers, their Firestore document does not include `gymId`. The `linkingCode` is stored but never validated against the `/gyms` collection. This means the Firestore `trainers` listener on the web (`startFirestoreListeners` L4894) can't filter trainers by gym — all trainers from all gyms appear on every dashboard.

**Fix:** Validate the linking code against `/gyms`, fetch the `gymId`, and store it in the trainer document.

---

### IMP-5 — `firebaseConfig` Missing `appId`

**Location:** `gym-dashboard.html` L3598

The `firebaseConfig` object is missing the `appId` field. This prevents Firebase Analytics from working and may cause subtle SDK issues.

---

### IMP-6 — `DEFAULT_STUDENTS` / `DEFAULT_TRAINERS` Are Always Seeded to First-Time Users

**Location:** `gym-dashboard.html` L3700–3703

```javascript
if (!localStorage.getItem('gojim_trainers')) {
    localStorage.setItem('gojim_trainers', JSON.stringify(DEFAULT_TRAINERS));
}
```
When a **new, real gym owner** signs in for the first time, they see Bessie Cooper, King Zarips, etc. as their members. This is confusing and unprofessional.

**Fix:** Only seed defaults if the authenticated user has role `demo` or if no `linkedId` is present.

---

### IMP-7 — Client Registration Sets `gymId: 'downtown'` (Hardcoded)

**Location:** `auth_screen.dart` L407

```dart
'gymId': 'downtown',  // ← Hardcoded fake gym ID
```
A client linking to a real gym gets `downtown` as their gymId. They will never appear in the correct gym owner's dashboard.

**Fix:** Validate the `linkingCode` against the `/gyms` collection, fetch the real `gymId`, and write it to the client document.

---

### IMP-8 — `login.html` is Orphaned / Legacy

**Location:** `g:\My Drive\Apps\Website\login.html`

The old login page still exists and points to a passcode-based system. Any link to `/login.html` bypasses the new unified auth system on `gym-dashboard.html`.

**Fix:** Either delete it or redirect to `gym-dashboard.html`.

---

### IMP-9 — Routine Sync is One-Way (App → Firestore only)

**Location:** `state.dart` L92–121

Routines published by the web dashboard's "Workout Routine Builder" are written to Firestore (`routines` collection). The app reads them via `syncActiveRoutinesFromFirestore()`. However, the app never writes workout completion events back to Firestore. Trainers on the web can never see if their assigned routine was completed.

---

## ✅ What's Working Well

| Feature | Status |
|---|---|
| Unified Firebase project (same `my-gym-mentor-ai`) across app & web | ✅ |
| Firestore `onSnapshot` listeners for real-time trainer/client sync | ✅ (partial — no delete handling) |
| Tabbed Sign In / Sign Up modal on web | ✅ |
| Google Sign-In on web | ✅ |
| Gym registration mirrors to ShirajLife CRM `/clients` | ✅ |
| `linkingCode` system for trainer/client-to-gym linking | ✅ |
| Routine published from web → readable by app | ✅ |
| Referral link dynamically set via `currentOrigin` | ✅ |
| Role-based selector restriction (trainer sees own clients only) | ✅ |

---

## Remediation Priority Order

| # | Issue | Priority | Effort |
|---|---|---|---|
| 1 | CRIT-5: Remove plain text passwords from Firestore | 🔴 Immediate | Medium |
| 2 | CRIT-4: Lock down Firestore Security Rules | 🔴 Immediate | Low |
| 3 | CRIT-3: Replace localStorage auth with Firebase Auth tokens | 🔴 Sprint 1 | High |
| 4 | CRIT-1: Remove localhost:8000 server calls entirely | 🔴 Sprint 1 | Medium |
| 5 | CRIT-2: Add `removed` handler to Firestore listeners | 🔴 Sprint 1 | Low |
| 6 | IMP-7: Fix hardcoded `gymId: 'downtown'` in client registration | 🟡 Sprint 1 | Low |
| 7 | IMP-4: Validate trainer linking code + store gymId | 🟡 Sprint 1 | Low |
| 8 | CRIT-7: Scope app state to authenticated gym (Firestore queries) | 🔴 Sprint 2 | High |
| 9 | IMP-2: Write trainer adds to Firestore (not just localStorage) | 🟡 Sprint 2 | Low |
| 10 | IMP-3: Call `firebase.auth().signOut()` on web sign-out | 🟡 Sprint 2 | Low |
| 11 | CRIT-6: Remove localhost referral link from HTML | 🟢 Quick Win | Low |
| 12 | IMP-1: Add Firestore listeners to Flutter app | 🟡 Sprint 3 | High |
| 13 | IMP-6: Don't seed demo data to real gym owners | 🟡 Sprint 3 | Low |
| 14 | IMP-8: Retire/redirect login.html | 🟢 Quick Win | Low |
| 15 | IMP-9: Write workout completion events to Firestore | 🟡 Sprint 3 | Medium |
| 16 | IMP-5: Add missing `appId` to firebaseConfig | 🟢 Quick Win | Low |

---

*This audit was performed via static analysis of source code. Live end-to-end testing on a production Firebase project is recommended to validate the remediation.*
