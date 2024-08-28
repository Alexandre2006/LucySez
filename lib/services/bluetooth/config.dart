// Services
String serviceUUID =
    "4C756379-5365-7A00-9B00-63F9A0808BAA"; // Lucy-Se-z, followed by a random UUID

// Characteristics
String headerCharacteristicUUID =
    "4C756379-5365-7A01-9B00-63F9A0808BAA"; // Stores data about the data, including length
String dataCharacteristicUUID =
    "4C756379-5365-7A02-9B00-63F9A0808BAA"; // Used to transmit data in chunks via notifications
String requestCharacteristicUUID =
    "4C756379-5365-7A03-9B00-63F9A0808BAA"; // Used to request COMPLETE data from the host (i.e. full whiteboard, not changes)

// Buffer Size
int maxBufferSize = 2 * 1024 * 1024; // 2 MB