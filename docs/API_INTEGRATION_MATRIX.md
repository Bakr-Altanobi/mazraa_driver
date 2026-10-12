# API Integration Matrix

Base URL verified from server code and production: `https://mzraa.runasp.net/`. All protected calls send `Authorization: Bearer <access token>`.

| Screen | Function | Method / endpoint | Permission | Request DTO | Response DTO | Main errors | Source | Implementation | Verification |
|---|---|---|---|---|---|---|---|---|---|
| Login | Sign in | `POST api/Auth/login` | Anonymous + auth rate limit | `{email,password,deviceName,ipAddress?}` | token, refreshToken, expiries, userId, email, role(s) | 400, 401, 429 | `AuthController.Login` | Complete | Production success for driver user 6; token values not logged |
| Splash/session | Refresh token | `POST api/Auth/refresh` | Anonymous + auth rate limit | `{refreshToken,deviceName,ipAddress?}` | Same auth response | 401, 429 | `AuthController.Refresh` | Complete; single-flight guard | Unit structure verified; no destructive production test |
| Profile | Logout | `POST api/Auth/logout` | Anonymous controller; valid refresh token required by use case | `{refreshToken}` | message | 400, 429 | `AuthController.Logout` | Complete, always clears local secure state | Not called against production to preserve test session |
| Profile | Driver identity | `GET api/Drivers/{userId}` | Auth token in client; controller currently lacks explicit `[Authorize]` | Path user ID | `DriverDto` | 404 | `DriversController.GetDriver` | Complete; used as driver-role gate | Production success: Omar Al-Qadhi, Van, Approved |
| Profile | Edit driver | `PUT api/Drivers/{id}` | `users.edit` | Full `UpdateDriverDto` | 204 | 400, 403, 404 | `DriversController.PutDriver` | Not exposed to driver UI | Backend lacks safe self-edit contract |
| Home | Online/offline | — | — | — | — | — | No self-service route found | Disabled with explanation | Backend gap |
| Shipments | Assigned list | `GET api/Shipments` | Authenticated; non-admin sees customer/driver-owned only | — | Shipment summary array | 401 | `ShipmentsController.GetShipments` | Complete | Production success, 4 rows |
| Offers | Available unassigned offers | — | — | — | — | — | Existing list filters out unassigned rows | Explicit empty/gap state | Backend gap |
| Shipment details | Details and coordinates | `GET api/Shipments/{id}` | Authenticated owner/driver/admin | Path ID | Shipment + store/customer/latest driver coordinates | 401, 403, 404 | `ShipmentsController.GetShipment` | Complete | Contract inspected; read-only client test pending a selected shipment |
| Shipment details | Tracking and estimate | `GET api/Shipments/{id}/tracking` | Authenticated owner/driver/admin | Path ID | shipment, latest location, Haversine distanceKm, etaMinutes, realtimeChannel | 401, 403, 404 | `ShipmentsController.Tracking` | Complete | Contract inspected |
| Active trip | Upload location | `POST api/Shipments/{id}/location` | Assigned driver/admin | latitude, longitude, heading?, speedKph?, accuracyMeters? | Saved location payload | 401, 403, 404, 409 | `ShipmentsController.UpdateLocation` | Complete; manual only, no background queue | Production write intentionally not executed |
| Offer | Accept | `POST api/Shipments/{id}/accept` | Assigned driver | — | Shipment entity | 401, 403, 404, 409 | `ShipmentsController.Accept` | Complete + confirm + reload | Production write intentionally not executed |
| Offer | Reject | `POST api/Shipments/{id}/reject` | Assigned driver | — | Shipment entity | 401, 403, 404, 409 | `ShipmentsController.Reject` | Complete + confirm + reload | Production write intentionally not executed |
| Pickup | Confirm pickup | `POST api/Shipments/{id}/pickup` | Assigned driver | — | Shipment entity | 401, 403, 404, 409 | `ShipmentsController.Pickup` | Complete + confirm + reload | Production write intentionally not executed |
| Trip | Start transit | — | — | — | — | — | State machine requires `PickedUp → InTransit`; no action route exists | Gap banner after pickup | Blocking backend gap |
| Delivery | Near customer | `POST api/Shipments/{id}/near-customer` | Assigned driver; only valid from InTransit | — | Shipment entity | 401, 403, 404, 409 | `ShipmentsController.NearCustomer` | Complete when state is InTransit | Production write intentionally not executed |
| Delivery | Deliver | `POST api/Shipments/{id}/deliver` | Assigned driver; only valid from NearCustomer | — | Shipment entity; server updates order/COD | 401, 403, 404, 409 | `ShipmentsController.Deliver` | Complete, guarded and confirmed | Production write intentionally not executed |
| Delivery | Fail | `POST api/Shipments/{id}/fail` | Assigned driver from PickedUp/InTransit/NearCustomer per state machine | `{reason}` | Shipment entity | 401, 403, 404, 409 | `ShipmentsController.Fail` | Complete with reason form | Production write intentionally not executed |
| Wallet | Balance/summary | `GET api/wallets/me` | Authenticated user | — | balance, currency, accountNumber, monthlyCredits/debits, capabilities | 401, 403 | `WalletController.Me` | Complete | Production success: SAR 500 at verification time |
| Wallet | Transactions | `GET api/wallets/transactions?page=&perPage=` | Authenticated wallet owner | filters + pagination | data + pagination | 401, 403 | `WalletController.Transactions` | Complete, first 50 rows | Read contract inspected |
| Wallet | Top up | `POST api/wallets/top-up` | Authenticated owner | `{amount}` | Stripe session URL and expiry | 400, 401, 409, 503 | `WalletController.TopUp` | Not exposed in driver earnings UI | Financial write intentionally excluded |
| Wallet | Driver earnings/withdrawal | — | — | — | — | — | No driver ledger or withdrawal endpoint found | Clearly marked unavailable | Backend gap |
| Notifications | Notification center | `GET api/notifications?page=&pageSize=&unreadOnly=` | Authenticated owner | Query | items + page + total | 401 | `NotificationsExtrasController.GetMyNotifications` | Complete | Read contract inspected |
| Notifications | Unread count | `GET api/notifications/unread-count` | Authenticated owner | — | `{count}` | 401 | `NotificationsExtrasController.GetUnreadCount` | Complete | Production success: 7 at verification time |
| Notifications | Mark selected read | `POST api/notifications/mark-read` | Authenticated owner | integer ID array | message + count | 401 | `NotificationsExtrasController.MarkRead` | Complete | Production write intentionally not executed |
| Notifications | Mark all read | `POST api/notifications/mark-all-read` | Authenticated owner | — | message + count | 401 | `NotificationsExtrasController.MarkAllRead` | Complete | Production write intentionally not executed |
| Push | Register/update device token | — | — | — | — | — | No verified mobile device-token contract | Not implemented | Backend/config gap |
| Support | Tickets/chat | — | — | — | — | — | No verified controller route | Informational screen only | Backend gap |

## Error handling

The client maps 400/401/403/404/409/422/429/500/503 to human-readable messages. Only a 401 read/write request is retried, once, after refresh. Mutating shipment or financial requests are never retried for generic connection failures.

