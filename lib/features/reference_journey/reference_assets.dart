/// Canonical paths for the visual assets delivered with the 48-screen reference.
///
/// ASSET_INDEX.csv intentionally reuses identical visual sources between screens.
/// To keep the APK small we package one canonical copy of each visual source and
/// map the screen slots to that copy instead of bundling hundreds of duplicate
/// multi-megabyte PNG files.
abstract final class ReferenceAssets {
  static const brandLeaf =
      'refrinces/assets_primary/by_screen/01/01_asset_brand_leaf_mark.png';
  static const driverAvatar =
      'refrinces/assets_primary/by_screen/01/02_asset_driver_avatar.png';
  static const onboardingFarm =
      'refrinces/assets_primary/by_screen/asset_onboarding_farm_sun.png';
  static const routeArrow =
      'refrinces/assets_primary/by_screen/01/04_asset_route_arrow.png';
  static const deliveryTote =
      'refrinces/assets_primary/common/asset_delivery_tote.png';
  static const loginPhoneOtp =
      'refrinces/assets_primary/by_screen/asset_login_phone_otp.png';
  static const identityScan =
      'refrinces/assets_primary/common/asset_identity_scan.png';
  static const supportHeadset =
      'refrinces/assets_primary/by_screen/02/05_asset_support_headset.png';
  static const routeMap =
      'refrinces/assets_primary/common/asset_route_map_pin_cluster.png';
  static const homePin =
      'refrinces/assets_primary/by_screen/03/02_asset_home_pin.png';
  static const deliveryScooter =
      'refrinces/assets_primary/by_screen/03/05_asset_delivery_scooter.png';
  static const farmCrate =
      'refrinces/assets_primary/by_screen/04/02_asset_farm_crate.png';
  static const deliveryParcel =
      'refrinces/assets_primary/by_screen/04/03_asset_delivery_parcel.png';
  static const freshProduce =
      'refrinces/assets_primary/by_screen/05/03_asset_fresh_produce_basket.png';
  static const navigationSign =
      'refrinces/assets_primary/by_screen/asset_navigation_road_sign.png';
  static const successBadge =
      'refrinces/assets_primary/by_screen/07/04_asset_success_badge.png';
  static const documentShield =
      'refrinces/assets_primary/common/asset_document_shield.png';
  static const earningsArrow =
      'refrinces/assets_primary/by_screen/asset_earnings_chart_arrow.png';
  static const bankCard =
      'refrinces/assets_primary/common/asset_bank_transfer_card.png';
  static const cashReceipt =
      'refrinces/assets_primary/common/asset_cash_and_receipt.png';
  static const ratingStars =
      'refrinces/assets_primary/common/asset_rating_stars.png';
  static const carMaintenance =
      'refrinces/assets_primary/common/asset_car_maintenance.png';
  static const emergencyTriangle =
      'refrinces/assets_primary/common/asset_emergency_triangle.png';
  static const qrFrame =
      'refrinces/assets_primary/common/asset_qr_scanner_frame.png';

  // ASSET_INDEX aliases that deliberately point to identical source pixels.
  static const homeRouteDashboard = routeMap;
  static const ordersProduceThumbnail = deliveryTote;
  static const orderDetailParcelStack = deliveryParcel;
  static const pickupChecklist = documentShield;
  static const deliveryDoorstep = homePin;
  static const walletCoins = bankCard;

  static const Map<int, List<ReferenceAssetSlot>> byScreen = {
    1: [
      ReferenceAssetSlot('asset_brand_leaf_mark', brandLeaf),
      ReferenceAssetSlot('asset_driver_avatar', driverAvatar),
      ReferenceAssetSlot('asset_onboarding_farm_sun', onboardingFarm),
      ReferenceAssetSlot('asset_route_arrow', routeArrow),
      ReferenceAssetSlot('asset_delivery_tote', deliveryTote),
    ],
    2: [
      ReferenceAssetSlot('asset_brand_leaf_mark', brandLeaf),
      ReferenceAssetSlot('asset_driver_avatar', driverAvatar),
      ReferenceAssetSlot('asset_login_phone_otp', loginPhoneOtp),
      ReferenceAssetSlot('asset_identity_scan', identityScan),
      ReferenceAssetSlot('asset_support_headset', supportHeadset),
    ],
    3: [
      ReferenceAssetSlot('asset_home_route_dashboard', homeRouteDashboard),
      ReferenceAssetSlot('asset_home_pin', homePin),
      ReferenceAssetSlot('asset_driver_avatar', driverAvatar),
      ReferenceAssetSlot('asset_route_map_pin_cluster', routeMap),
      ReferenceAssetSlot('asset_delivery_scooter', deliveryScooter),
    ],
    4: [
      ReferenceAssetSlot('asset_orders_produce_thumbnail', ordersProduceThumbnail),
      ReferenceAssetSlot('asset_farm_crate', farmCrate),
      ReferenceAssetSlot('asset_delivery_parcel', deliveryParcel),
      ReferenceAssetSlot('asset_home_pin', homePin),
      ReferenceAssetSlot('asset_route_arrow', routeArrow),
    ],
    5: [
      ReferenceAssetSlot('asset_order_detail_parcel_stack', orderDetailParcelStack),
      ReferenceAssetSlot('asset_farm_crate', farmCrate),
      ReferenceAssetSlot('asset_fresh_produce_basket', freshProduce),
      ReferenceAssetSlot('asset_route_map_pin_cluster', routeMap),
      ReferenceAssetSlot('asset_home_pin', homePin),
    ],
    6: [
      ReferenceAssetSlot('asset_navigation_road_sign', navigationSign),
      ReferenceAssetSlot('asset_route_arrow', routeArrow),
      ReferenceAssetSlot('asset_home_pin', homePin),
      ReferenceAssetSlot('asset_route_map_pin_cluster', routeMap),
      ReferenceAssetSlot('asset_delivery_scooter', deliveryScooter),
    ],
    7: [
      ReferenceAssetSlot('asset_pickup_checklist_clipboard', pickupChecklist),
      ReferenceAssetSlot('asset_delivery_tote', deliveryTote),
      ReferenceAssetSlot('asset_farm_crate', farmCrate),
      ReferenceAssetSlot('asset_success_badge', successBadge),
      ReferenceAssetSlot('asset_document_shield', documentShield),
    ],
    8: [
      ReferenceAssetSlot('asset_delivery_doorstep', deliveryDoorstep),
      ReferenceAssetSlot('asset_delivery_parcel', deliveryParcel),
      ReferenceAssetSlot('asset_home_pin', homePin),
      ReferenceAssetSlot('asset_driver_avatar', driverAvatar),
      ReferenceAssetSlot('asset_success_badge', successBadge),
    ],
    9: [
      ReferenceAssetSlot('asset_earnings_chart_arrow', earningsArrow),
      ReferenceAssetSlot('asset_wallet_coins', walletCoins),
      ReferenceAssetSlot('asset_success_badge', successBadge),
      ReferenceAssetSlot('asset_rating_stars', ratingStars),
      ReferenceAssetSlot('asset_bank_transfer_card', bankCard),
    ],
    10: [
      ReferenceAssetSlot('asset_wallet_coins', walletCoins),
      ReferenceAssetSlot('asset_bank_transfer_card', bankCard),
      ReferenceAssetSlot('asset_cash_and_receipt', cashReceipt),
      ReferenceAssetSlot('asset_success_badge', successBadge),
      ReferenceAssetSlot('asset_support_headset', supportHeadset),
    ],
    11: [
      ReferenceAssetSlot('asset_brand_leaf_mark', brandLeaf),
      ReferenceAssetSlot('asset_support_headset', supportHeadset),
      ReferenceAssetSlot('asset_success_badge', successBadge),
      ReferenceAssetSlot('asset_rating_stars', ratingStars),
      ReferenceAssetSlot('asset_route_arrow', routeArrow),
    ],
    12: [
      ReferenceAssetSlot('asset_driver_avatar', driverAvatar),
      ReferenceAssetSlot('asset_brand_leaf_mark', brandLeaf),
      ReferenceAssetSlot('asset_document_shield', documentShield),
      ReferenceAssetSlot('asset_support_headset', supportHeadset),
      ReferenceAssetSlot('asset_success_badge', successBadge),
    ],
    13: [
      ReferenceAssetSlot('asset_driver_avatar', driverAvatar),
      ReferenceAssetSlot('asset_identity_scan', identityScan),
      ReferenceAssetSlot('asset_document_shield', documentShield),
      ReferenceAssetSlot('asset_brand_leaf_mark', brandLeaf),
      ReferenceAssetSlot('asset_route_arrow', routeArrow),
    ],
    14: [
      ReferenceAssetSlot('asset_document_shield', documentShield),
      ReferenceAssetSlot('asset_identity_scan', identityScan),
      ReferenceAssetSlot('asset_car_maintenance', carMaintenance),
      ReferenceAssetSlot('asset_success_badge', successBadge),
      ReferenceAssetSlot('asset_support_headset', supportHeadset),
    ],
    15: [
      ReferenceAssetSlot('asset_car_maintenance', carMaintenance),
      ReferenceAssetSlot('asset_delivery_scooter', deliveryScooter),
      ReferenceAssetSlot('asset_document_shield', documentShield),
      ReferenceAssetSlot('asset_route_arrow', routeArrow),
      ReferenceAssetSlot('asset_success_badge', successBadge),
    ],
    16: [
      ReferenceAssetSlot('asset_route_map_pin_cluster', routeMap),
      ReferenceAssetSlot('asset_brand_leaf_mark', brandLeaf),
      ReferenceAssetSlot('asset_success_badge', successBadge),
      ReferenceAssetSlot('asset_driver_avatar', driverAvatar),
      ReferenceAssetSlot('asset_route_arrow', routeArrow),
    ],
    17: [
      ReferenceAssetSlot('asset_success_badge', successBadge),
      ReferenceAssetSlot('asset_rating_stars', ratingStars),
      ReferenceAssetSlot('asset_brand_leaf_mark', brandLeaf),
      ReferenceAssetSlot('asset_delivery_tote', deliveryTote),
      ReferenceAssetSlot('asset_route_arrow', routeArrow),
    ],
    18: [
      ReferenceAssetSlot('asset_emergency_triangle', emergencyTriangle),
      ReferenceAssetSlot('asset_support_headset', supportHeadset),
      ReferenceAssetSlot('asset_delivery_parcel', deliveryParcel),
      ReferenceAssetSlot('asset_document_shield', documentShield),
      ReferenceAssetSlot('asset_success_badge', successBadge),
    ],
    19: [
      ReferenceAssetSlot('asset_driver_avatar', driverAvatar),
      ReferenceAssetSlot('asset_support_headset', supportHeadset),
      ReferenceAssetSlot('asset_home_pin', homePin),
      ReferenceAssetSlot('asset_delivery_tote', deliveryTote),
      ReferenceAssetSlot('asset_route_arrow', routeArrow),
    ],
    20: [
      ReferenceAssetSlot('asset_emergency_triangle', emergencyTriangle),
      ReferenceAssetSlot('asset_support_headset', supportHeadset),
      ReferenceAssetSlot('asset_home_pin', homePin),
      ReferenceAssetSlot('asset_identity_scan', identityScan),
      ReferenceAssetSlot('asset_route_arrow', routeArrow),
    ],
    21: [
      ReferenceAssetSlot('asset_support_headset', supportHeadset),
      ReferenceAssetSlot('asset_brand_leaf_mark', brandLeaf),
      ReferenceAssetSlot('asset_document_shield', documentShield),
      ReferenceAssetSlot('asset_qr_scanner_frame', qrFrame),
      ReferenceAssetSlot('asset_success_badge', successBadge),
    ],
    22: [
      ReferenceAssetSlot('asset_rating_stars', ratingStars),
      ReferenceAssetSlot('asset_success_badge', successBadge),
      ReferenceAssetSlot('asset_driver_avatar', driverAvatar),
      ReferenceAssetSlot('asset_brand_leaf_mark', brandLeaf),
      ReferenceAssetSlot('asset_support_headset', supportHeadset),
    ],
    23: [
      ReferenceAssetSlot('asset_route_arrow', routeArrow),
      ReferenceAssetSlot('asset_delivery_scooter', deliveryScooter),
      ReferenceAssetSlot('asset_brand_leaf_mark', brandLeaf),
      ReferenceAssetSlot('asset_home_pin', homePin),
      ReferenceAssetSlot('asset_support_headset', supportHeadset),
    ],
    24: [
      ReferenceAssetSlot('asset_driver_avatar', driverAvatar),
      ReferenceAssetSlot('asset_brand_leaf_mark', brandLeaf),
      ReferenceAssetSlot('asset_route_map_pin_cluster', routeMap),
      ReferenceAssetSlot('asset_success_badge', successBadge),
      ReferenceAssetSlot('asset_route_arrow', routeArrow),
    ],
    25: [
      ReferenceAssetSlot('asset_route_map_pin_cluster', routeMap),
      ReferenceAssetSlot('asset_route_arrow', routeArrow),
      ReferenceAssetSlot('asset_delivery_parcel', deliveryParcel),
      ReferenceAssetSlot('asset_success_badge', successBadge),
      ReferenceAssetSlot('asset_wallet_coins', walletCoins),
    ],
    26: [
      ReferenceAssetSlot('asset_qr_scanner_frame', qrFrame),
      ReferenceAssetSlot('asset_delivery_tote', deliveryTote),
      ReferenceAssetSlot('asset_brand_leaf_mark', brandLeaf),
      ReferenceAssetSlot('asset_success_badge', successBadge),
      ReferenceAssetSlot('asset_route_arrow', routeArrow),
    ],
    27: [
      ReferenceAssetSlot('asset_route_map_pin_cluster', routeMap),
      ReferenceAssetSlot('asset_route_arrow', routeArrow),
      ReferenceAssetSlot('asset_delivery_scooter', deliveryScooter),
      ReferenceAssetSlot('asset_delivery_parcel', deliveryParcel),
      ReferenceAssetSlot('asset_home_pin', homePin),
    ],
    28: [
      ReferenceAssetSlot('asset_pickup_checklist_clipboard', pickupChecklist),
      ReferenceAssetSlot('asset_farm_crate', farmCrate),
      ReferenceAssetSlot('asset_fresh_produce_basket', freshProduce),
      ReferenceAssetSlot('asset_document_shield', documentShield),
      ReferenceAssetSlot('asset_success_badge', successBadge),
    ],
    29: [
      ReferenceAssetSlot('asset_delivery_doorstep', deliveryDoorstep),
      ReferenceAssetSlot('asset_qr_scanner_frame', qrFrame),
      ReferenceAssetSlot('asset_delivery_parcel', deliveryParcel),
      ReferenceAssetSlot('asset_home_pin', homePin),
      ReferenceAssetSlot('asset_success_badge', successBadge),
    ],
    30: [
      ReferenceAssetSlot('asset_bank_transfer_card', bankCard),
      ReferenceAssetSlot('asset_document_shield', documentShield),
      ReferenceAssetSlot('asset_identity_scan', identityScan),
      ReferenceAssetSlot('asset_success_badge', successBadge),
      ReferenceAssetSlot('asset_support_headset', supportHeadset),
    ],
    31: [
      ReferenceAssetSlot('asset_document_shield', documentShield),
      ReferenceAssetSlot('asset_brand_leaf_mark', brandLeaf),
      ReferenceAssetSlot('asset_identity_scan', identityScan),
      ReferenceAssetSlot('asset_support_headset', supportHeadset),
      ReferenceAssetSlot('asset_success_badge', successBadge),
    ],
    32: [
      ReferenceAssetSlot('asset_earnings_chart_arrow', earningsArrow),
      ReferenceAssetSlot('asset_rating_stars', ratingStars),
      ReferenceAssetSlot('asset_success_badge', successBadge),
      ReferenceAssetSlot('asset_driver_avatar', driverAvatar),
      ReferenceAssetSlot('asset_route_arrow', routeArrow),
    ],
    33: [
      ReferenceAssetSlot('asset_rating_stars', ratingStars),
      ReferenceAssetSlot('asset_driver_avatar', driverAvatar),
      ReferenceAssetSlot('asset_success_badge', successBadge),
      ReferenceAssetSlot('asset_brand_leaf_mark', brandLeaf),
      ReferenceAssetSlot('asset_support_headset', supportHeadset),
    ],
    34: [
      ReferenceAssetSlot('asset_support_headset', supportHeadset),
      ReferenceAssetSlot('asset_brand_leaf_mark', brandLeaf),
      ReferenceAssetSlot('asset_success_badge', successBadge),
      ReferenceAssetSlot('asset_route_arrow', routeArrow),
      ReferenceAssetSlot('asset_document_shield', documentShield),
    ],
    35: [
      ReferenceAssetSlot('asset_route_map_pin_cluster', routeMap),
      ReferenceAssetSlot('asset_home_pin', homePin),
      ReferenceAssetSlot('asset_route_arrow', routeArrow),
      ReferenceAssetSlot('asset_delivery_scooter', deliveryScooter),
      ReferenceAssetSlot('asset_brand_leaf_mark', brandLeaf),
    ],
    36: [
      ReferenceAssetSlot('asset_route_arrow', routeArrow),
      ReferenceAssetSlot('asset_brand_leaf_mark', brandLeaf),
      ReferenceAssetSlot('asset_support_headset', supportHeadset),
      ReferenceAssetSlot('asset_success_badge', successBadge),
      ReferenceAssetSlot('asset_document_shield', documentShield),
    ],
    37: [
      ReferenceAssetSlot('asset_cash_and_receipt', cashReceipt),
      ReferenceAssetSlot('asset_wallet_coins', walletCoins),
      ReferenceAssetSlot('asset_delivery_tote', deliveryTote),
      ReferenceAssetSlot('asset_success_badge', successBadge),
      ReferenceAssetSlot('asset_bank_transfer_card', bankCard),
    ],
    38: [
      ReferenceAssetSlot('asset_bank_transfer_card', bankCard),
      ReferenceAssetSlot('asset_success_badge', successBadge),
      ReferenceAssetSlot('asset_wallet_coins', walletCoins),
      ReferenceAssetSlot('asset_cash_and_receipt', cashReceipt),
      ReferenceAssetSlot('asset_brand_leaf_mark', brandLeaf),
    ],
    39: [
      ReferenceAssetSlot('asset_route_map_pin_cluster', routeMap),
      ReferenceAssetSlot('asset_delivery_parcel', deliveryParcel),
      ReferenceAssetSlot('asset_route_arrow', routeArrow),
      ReferenceAssetSlot('asset_home_pin', homePin),
      ReferenceAssetSlot('asset_support_headset', supportHeadset),
    ],
    40: [
      ReferenceAssetSlot('asset_driver_avatar', driverAvatar),
      ReferenceAssetSlot('asset_support_headset', supportHeadset),
      ReferenceAssetSlot('asset_home_pin', homePin),
      ReferenceAssetSlot('asset_delivery_parcel', deliveryParcel),
      ReferenceAssetSlot('asset_route_arrow', routeArrow),
    ],
    41: [
      ReferenceAssetSlot('asset_success_badge', successBadge),
      ReferenceAssetSlot('asset_earnings_chart_arrow', earningsArrow),
      ReferenceAssetSlot('asset_rating_stars', ratingStars),
      ReferenceAssetSlot('asset_wallet_coins', walletCoins),
      ReferenceAssetSlot('asset_driver_avatar', driverAvatar),
    ],
    42: [
      ReferenceAssetSlot('asset_car_maintenance', carMaintenance),
      ReferenceAssetSlot('asset_delivery_scooter', deliveryScooter),
      ReferenceAssetSlot('asset_document_shield', documentShield),
      ReferenceAssetSlot('asset_success_badge', successBadge),
      ReferenceAssetSlot('asset_route_arrow', routeArrow),
    ],
    43: [
      ReferenceAssetSlot('asset_document_shield', documentShield),
      ReferenceAssetSlot('asset_identity_scan', identityScan),
      ReferenceAssetSlot('asset_success_badge', successBadge),
      ReferenceAssetSlot('asset_support_headset', supportHeadset),
      ReferenceAssetSlot('asset_brand_leaf_mark', brandLeaf),
    ],
    44: [
      ReferenceAssetSlot('asset_document_shield', documentShield),
      ReferenceAssetSlot('asset_identity_scan', identityScan),
      ReferenceAssetSlot('asset_support_headset', supportHeadset),
      ReferenceAssetSlot('asset_emergency_triangle', emergencyTriangle),
      ReferenceAssetSlot('asset_success_badge', successBadge),
    ],
    45: [
      ReferenceAssetSlot('asset_emergency_triangle', emergencyTriangle),
      ReferenceAssetSlot('asset_route_map_pin_cluster', routeMap),
      ReferenceAssetSlot('asset_support_headset', supportHeadset),
      ReferenceAssetSlot('asset_identity_scan', identityScan),
      ReferenceAssetSlot('asset_success_badge', successBadge),
    ],
    46: [
      ReferenceAssetSlot('asset_cash_and_receipt', cashReceipt),
      ReferenceAssetSlot('asset_earnings_chart_arrow', earningsArrow),
      ReferenceAssetSlot('asset_bank_transfer_card', bankCard),
      ReferenceAssetSlot('asset_wallet_coins', walletCoins),
      ReferenceAssetSlot('asset_success_badge', successBadge),
    ],
    47: [
      ReferenceAssetSlot('asset_identity_scan', identityScan),
      ReferenceAssetSlot('asset_document_shield', documentShield),
      ReferenceAssetSlot('asset_driver_avatar', driverAvatar),
      ReferenceAssetSlot('asset_success_badge', successBadge),
      ReferenceAssetSlot('asset_brand_leaf_mark', brandLeaf),
    ],
    48: [
      ReferenceAssetSlot('asset_rating_stars', ratingStars),
      ReferenceAssetSlot('asset_driver_avatar', driverAvatar),
      ReferenceAssetSlot('asset_success_badge', successBadge),
      ReferenceAssetSlot('asset_support_headset', supportHeadset),
      ReferenceAssetSlot('asset_brand_leaf_mark', brandLeaf),
    ],
  };
}

class ReferenceAssetSlot {
  const ReferenceAssetSlot(this.name, this.path);

  final String name;
  final String path;
}
