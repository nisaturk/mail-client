/// Single source of truth for the backend base URL.
///
/// Change [baseUrl] to match your setup:
///   - Emulator talking to a backend on the same PC: the backend's LAN IP.
///   - Physical device on the same Wi-Fi: the backend's LAN IP.
///   - Both machines must be on the same network.
///
/// Never use `localhost` from a mobile device — it refers to the device itself.
const String baseUrl = 'http://localhost:5223';

/// Global switch between the real backend API and bundled mock data.
/// Set to `false` and make sure the backend is reachable at [baseUrl].
const bool useMockApi = true;
