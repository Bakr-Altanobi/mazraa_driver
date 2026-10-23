import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mazraa_driver/features/operations/driver_live_providers.dart';
import 'package:mazraa_driver/features/shipments/shipment_providers.dart';
import 'package:mazraa_driver/features/notifications/notification_providers.dart';
import 'package:mazraa_driver/features/wallet/wallet_providers.dart';
import 'package:mazraa_driver/features/wallet/cash_custody_screen.dart';
import 'package:mazraa_driver/features/support/driver_support_screen.dart';
import 'package:mazraa_driver/features/workspace/driver_workspace_repository.dart';
import 'package:mazraa_driver/features/workspace/driver_delivery_screens.dart';
import 'package:mazraa_driver/features/workspace/driver_ticket_screen.dart';
import 'package:mazraa_driver/features/reference_journey/reference_repository.dart';

/// Clears account data on both logout and login. Unwatched providers are also
/// invalidated, so a later page cannot reuse the previous driver's bank/wallet.
final resetDriverAccountCacheProvider = Provider<VoidCallback>(
  (ref) => () {
    ref.invalidate(driverOffersProvider);
    ref.invalidate(driverJourneyProvider);
    ref.invalidate(driverShiftsProvider);
    ref.invalidate(driverBankAccountsProvider);
    ref.invalidate(driverPayoutsProvider);
    ref.invalidate(shipmentsProvider);
    ref.invalidate(shipmentDetailsProvider);
    ref.invalidate(shipmentTrackingProvider);
    ref.invalidate(notificationsProvider);
    ref.invalidate(unreadNotificationsProvider);
    ref.invalidate(walletSummaryProvider);
    ref.invalidate(walletTransactionsProvider);
    ref.invalidate(cashCustodyProvider);
    ref.invalidate(supportTicketsProvider);
    ref.invalidate(driverChatMessagesProvider);
    ref.invalidate(driverTicketProvider);
    ref.invalidate(toolDataProvider);
    ref.invalidate(shipmentProofsProvider);
    ref.invalidate(shipmentContactsProvider);
    ref.invalidate(shipmentRoadProvider);
    ref.invalidate(shipmentWaitingProvider);
    ref.invalidate(phoneVerificationTargetProvider);
    ref.invalidate(referenceScreenPayloadProvider);
  },
);
