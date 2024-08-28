import 'package:bluetooth_low_energy/bluetooth_low_energy.dart';
import 'package:lucy_sez/services/bluetooth/config.dart';

final GATTCharacteristic headerCharacteristic = GATTCharacteristic.mutable(
  uuid: UUID.fromString(headerCharacteristicUUID),
  properties: [
    GATTCharacteristicProperty.read,
    GATTCharacteristicProperty.indicate,
  ],
  permissions: [
    GATTCharacteristicPermission.read,
  ],
  descriptors: [],
);

final GATTCharacteristic dataCharacteristic = GATTCharacteristic.mutable(
  uuid: UUID.fromString(dataCharacteristicUUID),
  properties: [
    GATTCharacteristicProperty.read,
    GATTCharacteristicProperty.indicate,
  ],
  permissions: [
    GATTCharacteristicPermission.read,
  ],
  descriptors: [],
);

final GATTCharacteristic requestCharacteristic = GATTCharacteristic.mutable(
  uuid: UUID.fromString(requestCharacteristicUUID),
  properties: [
    GATTCharacteristicProperty.read,
  ],
  permissions: [
    GATTCharacteristicPermission.read,
  ],
  descriptors: [],
);
