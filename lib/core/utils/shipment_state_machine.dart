import 'package:mazraa_driver/core/models/app_models.dart';

abstract final class ShipmentStateMachine {
  static bool canTransition(ShipmentStatus current, ShipmentStatus next) {
    return switch (current) {
      ShipmentStatus.pending =>
        next == ShipmentStatus.assigned || next == ShipmentStatus.cancelled,
      ShipmentStatus.assigned =>
        next == ShipmentStatus.accepted ||
            next == ShipmentStatus.pending ||
            next == ShipmentStatus.cancelled,
      ShipmentStatus.accepted =>
        next == ShipmentStatus.pickedUp ||
            next == ShipmentStatus.pending ||
            next == ShipmentStatus.cancelled,
      ShipmentStatus.pickedUp =>
        next == ShipmentStatus.inTransit || next == ShipmentStatus.failed,
      ShipmentStatus.inTransit =>
        next == ShipmentStatus.nearCustomer || next == ShipmentStatus.failed,
      ShipmentStatus.nearCustomer =>
        next == ShipmentStatus.delivered || next == ShipmentStatus.failed,
      ShipmentStatus.delivered ||
      ShipmentStatus.cancelled ||
      ShipmentStatus.failed ||
      ShipmentStatus.unknown => false,
    };
  }
}
