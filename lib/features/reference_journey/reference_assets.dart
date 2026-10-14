/// Runtime visual contract for the 48-screen driver reference journey.
///
/// `refrinces/assets_primary/ASSET_INDEX.csv` and its original PNG files remain
/// the design source of truth. The APK uses 768px WebP derivatives generated
/// from those exact canonical pixels so reference art stays faithful without
/// shipping dozens of 1920px multi-megabyte PNGs to every driver.
abstract final class ReferenceAssets {
  static const brandLeaf =
      'assets/reference_runtime/asset_brand_leaf_mark.webp';
  static const driverAvatar =
      'assets/reference_runtime/asset_driver_avatar.webp';
  static const onboardingFarm =
      'assets/reference_runtime/asset_onboarding_farm_sun.webp';
  static const routeArrow =
      'assets/reference_runtime/asset_route_arrow.webp';
  static const deliveryTote =
      'assets/reference_runtime/asset_delivery_tote.webp';
  static const loginPhoneOtp =
      'assets/reference_runtime/asset_login_phone_otp.webp';
  static const identityScan =
      'assets/reference_runtime/asset_identity_scan.webp';
  static const supportHeadset =
      'assets/reference_runtime/asset_support_headset.webp';
  static const routeMap =
      'assets/reference_runtime/asset_route_map_pin_cluster.webp';
  static const homePin =
      'assets/reference_runtime/asset_home_pin.webp';
  static const deliveryScooter =
      'assets/reference_runtime/asset_delivery_scooter.webp';
  static const farmCrate =
      'assets/reference_runtime/asset_farm_crate.webp';
  static const deliveryParcel =
      'assets/reference_runtime/asset_delivery_parcel.webp';
  static const freshProduce =
      'assets/reference_runtime/asset_fresh_produce_basket.webp';
  static const navigationSign =
      'assets/reference_runtime/asset_navigation_road_sign.webp';
  static const successBadge =
      'assets/reference_runtime/asset_success_badge.webp';
  static const documentShield =
      'assets/reference_runtime/asset_document_shield.webp';
  static const earningsArrow =
      'assets/reference_runtime/asset_earnings_chart_arrow.webp';
  static const bankCard =
      'assets/reference_runtime/asset_bank_transfer_card.webp';
  static const cashReceipt =
      'assets/reference_runtime/asset_cash_and_receipt.webp';
  static const ratingStars =
      'assets/reference_runtime/asset_rating_stars.webp';
  static const carMaintenance =
      'assets/reference_runtime/asset_car_maintenance.webp';
  static const emergencyTriangle =
      'assets/reference_runtime/asset_emergency_triangle.webp';
  static const qrFrame =
      'assets/reference_runtime/asset_qr_scanner_frame.webp';

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
