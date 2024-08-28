import 'package:bluetooth_low_energy/bluetooth_low_energy.dart';
import 'package:lucy_sez/services/bluetooth/characteristics.dart';
import 'package:lucy_sez/services/bluetooth/config.dart';

final GATTService service = GATTService(
  uuid: UUID.fromString(serviceUUID),
  isPrimary: true,
  includedServices: [],
  characteristics: [
    headerCharacteristic,
    dataCharacteristic,
    requestCharacteristic,
  ],
);
