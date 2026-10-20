# Mazraa Driver · Integration and reference contract (2026-10-19)

This is a **code/source audit** against the checked-out driver catalog, not a production feature certification.

## Canonical runtime
- `/home`, `/shipments`, `/wallet`, `/notifications`, `/profile` are actual Flutter app routes.
- `/services` exposes 48 canonical screens via `/journey/01`–`/journey/48` with Flutter widgets and assets taken from `refrinces/assets_primary/ASSET_INDEX.csv`. Reference screenshots are never rendered as screen implementations.
- The catalog below labels operations deliberately as **partial**. A rendered reference screen with a read source is not proof its entire design functionality works.
- `/upload-document` and `/shipments/:id/evidence` use real camera/gallery, authenticated multipart, and new scoped driver-media API; secure private storage must be configured on the backend.

## All 48 reference screens — source-derived mapping

| # | Screen | Current capability | Sources | Mutating actions | Catalog gap |
|---:|---|---|---|---|---|
| 01 | البداية والترحيب | تنقل/عرض | — | — | — |
| 02 | تسجيل الدخول والتحقق | قراءة API | driver | — | معلن قيد الاستكمال |
| 03 | لوحة السائق | أحداث API جزئية | journeyMe, shipments, wallet, shifts | goOnline, goOffline | — |
| 04 | قائمة الطلبات | أحداث API جزئية | shipments, offers | acceptOffer, rejectOffer | — |
| 05 | تفاصيل الطلب | أحداث API جزئية | shipmentDetail | acceptShipment | معلن قيد الاستكمال |
| 06 | الملاحة إلى نقطة الاستلام | قراءة API | tracking | — | معلن قيد الاستكمال |
| 07 | التحقق من الاستلام | أحداث API جزئية | shipmentDetail, shipmentProofs | addPickupProof, pickupShipment, startTransit | معلن قيد الاستكمال |
| 08 | تسليم الطلب للعميل | أحداث API جزئية | shipmentDetail, tracking, shipmentProofs | nearCustomer, deliverShipment, failShipment | — |
| 09 | الأرباح | قراءة API | wallet, walletTransactions | — | — |
| 10 | المحفظة والتحويل | أحداث API جزئية | wallet, walletTransactions, bankAccounts, payouts | requestPayout | — |
| 11 | مركز الإشعارات | أحداث API جزئية | notifications | markAllNotificationsRead | — |
| 12 | الملف الشخصي والإعدادات | أحداث API جزئية | journeyMe, preferences | goOnline, goOffline, toggleOffersPreference, toggleScheduledTripsPreference | — |
| 13 | تسجيل سائق جديد | قراءة API | driver | — | معلن قيد الاستكمال |
| 14 | وثائق المركبة والسائق | قراءة API | journeyMe, vehicle, documents | — | — |
| 15 | ملف المركبة | قراءة API | vehicle, vehicleMaintenance | — | — |
| 16 | جدول التوفر | أحداث API جزئية | journeyMe, availability, preferences, shifts | startShift, endShift, joinScheduledTrip, withdrawScheduledTrip, addAvailabilityWindow, removeAvailabilityWindow | — |
| 17 | الحوافز والمكافآت | قراءة API | incentives, performance, wallet | — | — |
| 18 | مشكلة في الطلب | أحداث API جزئية | shipmentDetail, incidents | createIncident, failShipment | — |
| 19 | محادثة العميل | أحداث API جزئية | chats | sendChatMessage | — |
| 20 | المساعدة الطارئة | أحداث API جزئية | incidents, supportFaqs | createIncident | معلن قيد الاستكمال |
| 21 | مركز الدعم | أحداث API جزئية | supportFaqs, supportTickets | createSupportTicket, replySupportTicket, startSupportChat | — |
| 22 | التقييم والملاحظات | قراءة API | performance | — | معلن قيد الاستكمال |
| 23 | لا توجد طلبات | قراءة API | shipments, offers | — | — |
| 24 | إحالة صديق | قراءة API | referral | — | — |
| 25 | سجل الرحلات | قراءة API | shipments, currentTrips | — | — |
| 26 | مسح رمز QR | قراءة API | shipmentDetail, shipmentProofs | — | معلن قيد الاستكمال |
| 27 | الطلبات المجمّعة | أحداث API جزئية | currentTrips, shipments, preferences, scheduledTrips | joinScheduledTrip, withdrawScheduledTrip | — |
| 28 | فحص محتويات الاستلام | قراءة API | shipmentDetail, shipmentProofs | — | معلن قيد الاستكمال |
| 29 | إثبات التسليم | أحداث API جزئية | shipmentDetail, tracking, shipmentProofs | addDeliveryProof | — |
| 30 | تعديل الحساب البنكي | أحداث API جزئية | bankAccounts, wallet | saveBankAccount | — |
| 31 | اللغة والخصوصية | قراءة API | journeyMe | — | معلن قيد الاستكمال |
| 32 | لوحة الأداء | قراءة API | performance, wallet | — | — |
| 33 | تفصيل تقييم السائق | قراءة API | performance | — | معلن قيد الاستكمال |
| 34 | تفضيلات الإشعارات | قراءة API | notifications | — | معلن قيد الاستكمال |
| 35 | منطقة الخدمة | أحداث API جزئية | deliveryZones, preferences | toggleOffersPreference | معلن قيد الاستكمال |
| 36 | حالة النظام | قراءة API | journeyMe | — | معلن قيد الاستكمال |
| 37 | التحصيل النقدي | قراءة API | shipments, walletTransactions | — | معلن قيد الاستكمال |
| 38 | نجاح التحويل | قراءة API | payouts, bankAccounts, wallet | — | — |
| 39 | إرجاع الطلب | أحداث API جزئية | returns, shipmentDetail | acceptReturn, pickupReturn, completeReturn | — |
| 40 | تعذر الوصول للعميل | أحداث API جزئية | shipmentDetail, tracking | failShipment | معلن قيد الاستكمال |
| 41 | ملخص الوردية | أحداث API جزئية | shifts, performance, wallet, walletTransactions | startShift, endShift | — |
| 42 | صيانة المركبة | قراءة API | vehicle, vehicleMaintenance | — | — |
| 43 | انتهاء الوثائق | قراءة API | documents, vehicle, journeyMe | — | — |
| 44 | الحساب موقوف | قراءة API | journeyMe | — | — |
| 45 | رفع بلاغ | أحداث API جزئية | incidents | createIncident | — |
| 46 | تفاصيل الرسوم | قراءة API | shipmentDetail, walletTransactions, incentives | — | معلن قيد الاستكمال |
| 47 | التحقق من الهوية | قراءة API | journeyMe, documents | — | معلن قيد الاستكمال |
| 48 | ملاحظات العميل | قراءة API | performance | — | معلن قيد الاستكمال |

## Delivery state contract
`Pending → Assigned → Accepted → PickedUp → InTransit → NearCustomer → Delivered`; terminal failed/cancelled and return states require separate rules. Dispatcher owns assignment, driver owns driver state transitions, customer owns their order views, and administrator reviews documents, banks, return custody and payouts. API must validate ownership and concurrency on every step. Actual multi-account mutating E2E tests have **not** been performed on the live database.

## Implemented in proposed integration PRs
- Ecommerce API PR #29: safer weekly schedule POST/DELETE and validation, trip eligibility, bank verification, admin operations queues, soft driver deactivation, ownership-aware evidence endpoints.
- Driver PR #22: services hub, code-built access to all canonical reference screens, photo evidence and document picker/hosted upload, periodic offer refresh, scoped availability UI.
- Customer PR #8: real order tracking refresh in foreground and on resume, last server-confirmed position preserved during loading/errors; active routing already used ConnectedTrackOrderScreen and ConnectedOrderDetailsScreen, not inactive pixel/mock samples.
- Dashboard PR #16: authenticated API proxy for document preview and queues for bank verification, financial payout processing and document reviews; route permissions + antiforgery.

## Required production capabilities not yet completed
1. Full synchronized customer checkout → payment/COD → shipment creation → dispatch offer → accept/reject/expiry/reassign → pickup checklist → departure → near customer → signed/delivery-code confirmation → rating → returns/refunds → financial reconciliation, exercised against isolated test data with rollback/cleanup.
2. Background location tracking with platform-specific Android foreground service and iOS policy; currently in-app tracking is foreground-only. Add device permission & power-management behaviour, offline queue and retry.
3. Push notifications via configured Firebase project (driver and customer) and SignalR websocket or polling fallback for assignments, status and chat events.
4. Production-grade Google Maps and server-side Routes/ETA keys with Android/iOS signing restrictions and route polyline from actual route service (never fabricate straight-line road geometry).
5. Secure, persistent storage `DriverFiles:PrivateRoot`, outside `wwwroot` and protected by storage and backup policies. If missing, driver-media returns 503 intentionally. Private documents require authenticated API retrieval; never place identity photos at a public URL.
6. Document approval and rejected/reupload workflows; QR code scan and cryptographic verification, handwritten signature capture and proof metadata consistency.
7. COD cash ledger, audit/idempotency/outbox for payout and external bank transfer, bank verification evidence, fraud/dispute workflows; do not mark Paid without a real provider reference.
8. Compliance/operations: staff dispatch + role permission auditing, evidence retention, cancellation/refunds, emergency/SOS routing, shipment incident resolution, ETA notifications and accessibility/RTL/English.
9. Device and emulator testing for each button/field, media plugin dependency lockfile update (`flutter pub get`), `flutter analyze`, `flutter test` and a signed APK tested on Android ARM64. **No driver GitHub Actions workflows are retained**, by explicit request, and no new driver APK is claimed from this branch.

## Data-preservation boundaries
- Existing SQL migrations were inspected and the previous FullDriverJourney additive migration was already applied; this integration PR makes **no new schema migration or seeder run**.
- Never run `--maintenance-reset-seed`, turn on `Maintenance__EnableResetAndSeed`, clear the application tables, or hard-delete historical drivers/orders.
- PRs are staged and not merged/deployed; backend CI is an automated code check and not a signed-off E2E test.

## External/configuration prerequisites
- Host-provided `DriverFiles:PrivateRoot` absolute, backed-up, non-public persistent path and secured access.
- Restricted Android Maps key & matching release signing SHA fingerprint; separate server Routes key; Firebase credentials and OS push entitlement.
- Isolated test accounts, test transactions and sandbox gateway credentials where full mutation can be safely validated.
- Flutter SDK/tooling and signed Android testing once the user authorizes manual build workflow; **do not recreate GitHub Actions** for the driver.
