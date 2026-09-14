/// Single source of truth for the backend base URL.
///
/// Change [baseUrl] to match your setup:
///   - Emulator talking to a backend on the same PC: the backend's LAN IP.
///   - Physical device on the same Wi-Fi: the backend's LAN IP.
///   - Both machines must be on the same network.
///
/// Never use `localhost` from a mobile device — it refers to the device itself.
const String baseUrl = 'http://192.168.1.177:5223/api';
