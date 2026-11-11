/// Stub implementasyonu (native platformlar için).
/// Web dışı platformlarda JS interop kullanılamaz,
/// bu yüzden her zaman false döner ve hiçbir şey yapmaz.

bool checkAndClearSwRefreshFlag() => false;

void addFcmTokenRefreshListener(Function callback, {Function? onExpired}) {
  // Native platformlarda service worker yok, bir şey yapma
}

void sendUserIdToSw(String userId) {
  // Native platformlarda service worker yok, bir şey yapma
}

void clearUserIdFromSw() {
  // Native platformlarda service worker yok, bir şey yapma
}
