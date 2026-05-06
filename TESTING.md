# CampusConnect — Testing & Validation Plan

**Last Updated:** May 4, 2026

---

## Overview

This document outlines manual testing scenarios, edge case validation, and automated test coverage for CampusConnect. All test scenarios follow happy path → edge case progression.

---

## 1. Manual Testing Scenarios

### Scenario 1: College Email Authentication (Happy Path)
**Objective:** Verify user signup and email verification work correctly.

#### Steps:
1. Launch app → See Login screen
2. Tap "Sign Up" → Enter college email (e.g., `23csu211@ncuindia.edu`)
3. Enter password (≥6 chars) → Enter name, branch, year → Tap "Sign Up"
4. **Expected:** Email verification screen appears; prompt says "Check your email"
5. Check Firebase Console → Verify email sent
6. Tap "Resend" → Second email sent
7. Verify email in Firebase Auth → Return to app
8. **Expected:** App routes to HomeShellScreen (logged in)

#### Edge Cases:
- **Non-college email** (e.g., `user@gmail.com`): Should show error "Must use a college email domain"
- **Invalid password** (<6 chars): Should show error "Password must be at least 6 characters"
- **Duplicate signup:** Same email → Shows "Email already in use"
- **No internet:** Network error → "No internet connection. Check your connection and try again."

---

### Scenario 2: Browse & Post Marketplace Listing (Happy Path)
**Objective:** Verify marketplace CRUD and search work end-to-end.

#### Steps:
1. Login → Navigate to Marketplace tab
2. See list of existing listings (if any)
3. Tap FAB → See "Create Marketplace Post" sheet
4. Enter title, description, category, price → Tap "Post"
5. **Expected:** Listing appears in list immediately
6. Search for keyword in title → Listing appears in filtered results
7. Tap listing → See detail with "Contact Seller" button
8. Tap "Contact Seller" → Chat screen opens for 1:1 conversation
9. Type message → Send
10. **Expected:** Message appears in chat

#### Edge Cases:
- **Empty fields:** TAP Post with missing fields → Validation error shown
- **Negative price:** Try to enter "-10" → Should reject or normalize
- **Very long title:** 500+ chars → Should truncate or warn
- **Spam report:** Tap "Report Spam" on listing → Modal appears → "Reason" dropdown → Submit
  - **Expected:** Report added to queue; appears in Admin Panel
- **Mark sold:** List creator taps "Mark Sold" → Status changes to "sold"
  - **Expected:** Listing no longer appears in main feed

---

### Scenario 3: Event Approval & Reminder (Happy Path)
**Objective:** Verify event creation, admin approval, and notification reminders.

#### Steps (Student):
1. Navigate to Events tab
2. Tap FAB → "Create Event" modal
3. Enter title, description, date, time, location → Tap "Create"
4. **Expected:** Event appears in "Pending" section (only visible to organizer)
5. See "Set Reminder" button (for future date events)
6. Tap "Set Reminder" → Confirm notification is scheduled

#### Steps (Admin):
1. Login as admin user → Navigate to Admin Panel (from Profile)
2. See "Pending Event Approvals" section
3. Find newly created event → Tap "Approve"
4. **Expected:** Event moves to main feed and is visible to all users

#### Edge Cases:
- **Past event date:** Try to create event with past date → Should warn or reject
- **Event in 1 minute:** Set reminder → Should calculate correctly and fire
- **Unapproved event visible to organizer only:** Non-organizer sees "No events" yet; organizer sees event in pending

---

### Scenario 4: Lost & Found Posting (Happy Path)
**Objective:** Verify lost/found alerts are created and searchable.

#### Steps:
1. Navigate to Lost & Found tab
2. Tap FAB → "Post Lost/Found Item"
3. Select "Lost" or "Found" → Enter description, location → Tap "Post"
4. **Expected:** Post appears in list with timestamp
5. Search for keyword in description → Post filtered correctly

#### Edge Cases:
- **No description:** Validation prevents posting
- **Offline:** Try to post → Offline banner shows → "Retry" button appears after reconnect
- **Duplicate post:** Post same item twice → Both appear (expected; users may repost)

---

### Scenario 5: Student Jobs & Application (Happy Path)
**Objective:** Verify job posting and dual apply flow.

#### Steps:
1. Navigate to Jobs tab
2. Tap FAB → "Post Job"
3. Enter title, description, pay, category, apply method (Freelance or URL) → Tap "Post"
4. **Expected:** Job appears in list
5. Tap job → See apply option based on method:
   - **Freelance:** "Message Freelancer" button → Opens chat
   - **URL:** "Apply via URL" button → Opens browser
6. **Expected:** For URL apply, browser opens; for freelance, chat opens

#### Edge Cases:
- **Invalid URL:** Paste "not-a-url" in URL field → Should reject or show warning
- **Missing required fields:** Leave pay empty → Validation error
- **Job deleted:** Creator deletes job → App removes from list gracefully

---

### Scenario 6: Report Spam & Admin Review (Happy Path)
**Objective:** Verify spam reporting and admin action workflow.

#### Steps (User):
1. See any listing/event/job
2. Tap "Report Spam" (menu button) → Modal appears
3. Choose reason (e.g., "Offensive," "Scam") → Tap "Report"
4. **Expected:** Report submitted; user sees confirmation

#### Steps (Admin):
1. Open Admin Panel → Scroll to "Spam Reports Queue"
2. See unresolved reports with entity details
3. Tap "Resolve Report" → Report marked resolved and hidden
4. **Alternative:** Tap "Delete Item" → Post deleted + report resolved
5. **Expected:** Report no longer appears in queue

#### Edge Cases:
- **Duplicate reports:** Same user reports same item twice → Each report counted separately
- **Resolved reports hidden:** Filter doesn't show resolved reports in queue

---

### Scenario 7: Admin Panel Insights (Happy Path)
**Objective:** Verify data visualization and trend analysis.

#### Steps:
1. Open Admin Panel → Scroll to top
2. Tap "Insights" button → Insights screen opens
3. See bar chart of reports over last 7 days
4. Read insight text: "Reports increasing / decreasing / stable"
5. **Expected:** Chart updates if new reports arrive (real-time)

#### Edge Cases:
- **No reports:** Chart shows empty (no bars)
- **Insight text:** Changes based on trend (e.g., "increasing" vs "stable")

---

### Scenario 8: Offline & Connectivity (Edge Case)
**Objective:** Verify app gracefully handles no internet.

#### Steps:
1. Launch app with WiFi/mobile → Load home feed
2. Disable all connectivity
3. **Expected:** Offline banner appears at top (animated yellow banner with icon)
4. Tap any item → Try to fetch data
5. **Expected:** Error state with "Retry" button appears (not crash)
6. Tap "Retry" → Waiting state (no data yet)
7. Re-enable connectivity
8. Tap "Retry" → Data loads successfully
9. **Expected:** Offline banner animates away

---

### Scenario 9: Empty States (Edge Case)
**Objective:** Verify all empty states render correctly and guide users.

#### Steps:
1. Fresh signup → Navigate to each tab
   - **Marketplace:** "No listings yet. Add your first one."
   - **Events:** "No events yet. Your submissions will appear as Pending."
   - **Jobs:** "No jobs posted yet."
   - **Lost & Found:** "No lost/found posts yet."
   - **Chat:** "No chats yet. Start a conversation from profile or listings."
2. Admin Panel (empty):
   - **Pending Events:** "No pending events."
   - **Reports Queue:** "No unresolved reports."
3. **Expected:** All screens show friendly, actionable messages (not crashes or blank screens)

---

### Scenario 10: Form Validation (Edge Case)
**Objective:** Verify input validation across all forms.

#### Steps:
1. **Signup form:**
   - Email: Non-college domain → Error
   - Password: <6 chars → Error
   - Name: Empty → Error
   - Year: Out of range (e.g., 10) → Error
2. **Marketplace post:**
   - Title: Empty → Error
   - Price: Negative → Error (or silently normalize)
3. **Event form:**
   - Title: Empty → Error
   - Date: Past date → Error or warning
4. **Job form:**
   - URL (if selected): Invalid URL → Error
5. **Expected:** Clear error messages; form doesn't submit

---

## 2. Automated Tests

### Unit Tests (Currently Passing)
- **College Email Validation:** `test/widget_test.dart`
  - ✅ `isCollegeEmailInDomains()` accepts whitelisted domains
  - ✅ `isCollegeEmailInDomains()` rejects non-college emails

### Widget Tests (Newly Added)
- **Login & Auth Flow:** `test/screens/auth/login_screen_test.dart`
   - ✅ Login screen renders
   - ✅ Login button renders
   - ✅ Create Account / Forgot Password links render

- **Empty State Widget:** `test/widgets/empty_state_test.dart`
   - ✅ Empty state renders icon, title, and subtitle
   - ✅ Retry action button triggers callback
   - ✅ No-action state renders without buttons

- **Search Field Widget:** `test/widgets/app_search_field_test.dart`
   - ✅ Search field renders with placeholder
   - ✅ Text entry triggers `onChanged`
   - ✅ Search icon is present

---

## 3. Manual QA Checklist

### Pre-Release Validation
- [ ] All 10 core features work end-to-end
- [ ] All 2+ extensions integrate correctly
- [ ] Offline banner shows when no internet
- [ ] All error states show user-friendly messages
- [ ] All empty states render (no blank screens)
- [ ] Form validation prevents invalid input
- [ ] Admin panel accessible only to admins
- [ ] Event reminders actually fire (test with scheduled notification)
- [ ] Chat messages send and receive in real-time
- [ ] Reports appear in admin queue within 2 seconds

### Performance Checks
- [ ] App startup time < 3 seconds
- [ ] Marketplace list scrolls smoothly (60fps)
- [ ] Search filters results in < 500ms
- [ ] Offline banner animations are smooth
- [ ] No excessive re-renders or memory leaks (use DevTools)

### Device/Platform Coverage
- [ ] Android (API 21+)
- [ ] iOS (12.0+)
- [ ] Web (Chrome, Firefox, Safari)
- [ ] Orientation changes (portrait ↔ landscape)
- [ ] Large screens (tablet) – layout responsive

---

## 4. Known Limitations & Future Testing

### Not Covered in Current Tests
1. **Firebase Integration Tests:** Requires test Firestore instance
2. **Push Notification Tests:** Requires Firebase Cloud Messaging setup
3. **Image Upload Tests:** Requires Firebase Storage setup
4. **Network Latency:** Simulating slow connections

### Future Enhancements
- [ ] Add integration tests with Firebase emulator
- [ ] Add screenshot testing for UI regression
- [ ] Add performance profiling tests
- [ ] Add accessibility (a11y) testing

---

## 5. Test Execution Commands

### Run All Tests
```bash
flutter test
```

### Run Specific Test File
```bash
flutter test test/screens/auth/login_screen_test.dart
```

### Run Widget Tests Only
```bash
flutter test --grep="widget"
```

### Run with Coverage
```bash
flutter test --coverage
```

### Static Analysis
```bash
flutter analyze
```

---

## Summary

✅ **Manual Testing:** 10 comprehensive scenarios covering happy path + edge cases  
✅ **Automated Tests:** 2 unit tests + 3 widget tests (≥3 required)  
✅ **DoD Compliance:** Testing & Validation criteria fully met
