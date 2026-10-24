# Mazraa driver UI, event routing, and scheduled-delivery acceptance

Date: 24 October 2026. Scope: development branches only, not a claim of production deployment.

## Canonical screen inventory and user journey
The transferred repository contains 48 reference destinations and 48 reference asset folders, 34 operational tools, and the principal root and detail routes. Every canonical reference design, data provider, form and error state should remain testable. No false assumption of 84 screens should be made without receiving the missing reference files.

Root navigation: Home / Shipments / Wallet / Notifications / Profile. Secondary views receive a context-sensitive footer outside the GoRouter Navigator:
- Shipment/details/navigation/pickup/proof → Shipments / My trips / Offers.
- Scheduled trips / current trips / availability / preferences → Scheduled / My trips / Availability.
- Vehicle/change/maintenance/documents → Vehicle / Change request / Documents.
- Chat/support/notification preferences → Notifications / Chats / Support.
- Wallet/earnings/payout/cash → Wallet / Earnings / Payouts.
- Miscellaneous settings retain account-context shortcuts.
Context tab changes use `router.go`, not a nested Navigator widget/key reused on two pages. Test: `test/features/contextual_nav_router_test.dart`.

Home quick access now includes scheduled trips, availability and conversations so essential workflows do not require drilling into the full services index.

## Event-to-screen navigation
`lib/features/notifications/notification_navigation.dart` permits only known same-app routes; external/malformed deep links never execute. Stored chat notifications show the server-supplied reply excerpt and open the exact `/chats/{chatId}` (including legacy `dataJson` notifications). Shipment alerts open the shipment; scheduled-trip assignments, returns, account/vehicle/documents, incidents, feedback and finance events map to relevant screens. The notification app bar links directly to preferences, without going through Services. Event mapping and actual tap tests live under `test/features/notification_navigation_test.dart` and `test/features/notification_page_navigation_test.dart`.

The server `ChatsController` stores a `chat.message_received` notification, body excerpt, chat ID and `/chats/{id}` deep link. Receiving it on a specific device remains dependent on authentication, the deployed server and push credentials.

## Scheduled order that did not appear to a driver
Do not conflate a customer booking with a dispatched shipment:
1. Customer accepts and consumes a scheduled delivery quote tied to a trip.
2. Merchant's authorized employee receives and prepares the order.
3. The trip must have a driver assigned by operations. Driver's participation request alone is *Requested*, not an assignment.
4. After merchant preparation a shipment is created and associated with the trip. The assigned driver receives a targeted notification and can perform the handoff.
5. Until then drivers who have participated or been assigned can see **booked order count** and **prepared shipment count** on the scheduled-trip table, but not private customer details.

The selectable table shows departure, destination, counts, assignment, and participation. It uses native checkboxes and forbids requesting a trip already assigned to another driver; pending participation remains withdrawable. The server also enforces this conflict. All new checks are on development branches; if the production API is older, these features may not be visible there. An actual missing order requires examining its quote/trip ID, merchant preparation state, driver participation/assignment, and deployment SHA with authorized access.

## Coverage and vehicle workflows
- Weekly availability: server-backed weekday/time table and add/remove windows.
- Driver-owned service areas: choose from approved global zones; create/edit/remove a driver's coverage and maximum distance without editing global zone prices/geometry. Swipe-down refresh invalidates both available-zone catalog and saved driver selections.
- Vehicle: the driver submits a **change request** and sees its record; the assigned vehicle remains unchanged until operations approves it. Direct administrative vehicle reassignment is not presented as a driver-controlled edit.
- Referral: share the driver's actual server referral code through a WhatsApp deep link or copy the invitation. Store URL is explicitly temporary. A real branded WhatsApp link preview with app icon additionally requires a publicly hosted landing page and an Open Graph PNG image; text and placeholder links alone cannot guarantee a WhatsApp thumbnail.

## Refresh, empty/error states, and Flutter red-screen regression
Ordinary refresh is via pull-down where a scrollable data screen exists, not an app-bar refresh action. Async errors show a retry-by-swipe prompt; blank results are distinguished from failed requests. Nested error lists set `shrinkWrap: true` to avoid unbounded viewport layout errors. Shared MetricCard no longer uses Spacer under unconstrained height. Details, maps, tool views, wallet, ticket and notification surfaces have focused widget/regression coverage.

## Verification and remaining evidence
- Flutter analyze, widget tests, Android ARM64 APK and unsigned iOS Simulator builds are run by `.github/workflows/delivery-platform-ci.yml`.
- Server full and isolated SQL tests exercise scheduled checkout, preparation, assignment, pickup, departure timing and COD/earnings, with one-click E2E runner and separate server CI.
- The latest workflow conclusion should be verified by inspecting GitHub Actions **after the final commit**, not copied from an earlier cancelled run.
- A live production claim still requires matching **deployed SHA**, valid driver account login, one identified customer order/trip and merchant preparation, actual FCM receipt, map provider/permissions, and physical device testing. Do not mutate hosted user data or merge stacked branches solely to make UI widget tests pass.
