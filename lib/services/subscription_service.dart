import 'package:flutter/foundation.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

import '../models/app_user.dart';

/// Controla si los puntos de entrada al paywall (botón "Ver planes
/// Premium" en Configuración, ítem en "Yo") están visibles en la app.
///
/// La API key de Android ya es la real (proyecto CicloPlus en RevenueCat,
/// app "CicloPlus (Play Store)"). Pendiente: la de iOS sigue siendo
/// placeholder hasta que se publique también en App Store.
const bool kPaywallEnabled = true;

/// Gestiona la conexión con RevenueCat para saber si la persona tiene una
/// suscripción de pago activa. La app ya no concede una prueba gratis
/// propia solo por registrarse (decisión del 2026-09: se dejó de lado esa
/// prueba automática porque duplicaba, sin coordinarse bien, la prueba
/// gratis real que puede ofrecer la propia suscripción de Google Play si
/// el plan tiene configurada una oferta de prueba); el único acceso
/// premium es el que concede una suscripción activa de verdad.
class SubscriptionService {
  // API key pública (Android) del proyecto CicloPlus en RevenueCat,
  // app "CicloPlus (Play Store)". No es secreta, se puede incluir en el
  // cliente.
  static const String _revenueCatApiKeyAndroid = 'goog_FygVCYConHLDNAeyOxomQPLbaHC';

  // TODO(RevenueCat): si también se publica en iOS, sustituir por la API
  // key pública de iOS (suele ser distinta de la de Android en RevenueCat).
  static const String _revenueCatApiKeyIOS = 'REVENUECAT_API_KEY_PLACEHOLDER';

  // Identificador del Entitlement en RevenueCat que agrupa los productos
  // de pago (semanal/mensual/anual).
  static const String entitlementId = 'CicloPlus Pro';

  // Product IDs reales en Play Console (producto `cicloplus_monthly` con
  // 3 base plans). Son solo referencia: la pantalla de paywall obtiene
  // los `Package` reales (con precio localizado) desde RevenueCat, no usa
  // estas constantes para mostrar precios.
  static const String weeklyProductId = 'cicloplus_monthly:weekly-autorenew';
  static const String monthlyProductId = 'cicloplus_monthly:monthly-autorenew';
  static const String annualProductId = 'cicloplus_monthly:annual-autorenew';

  bool _configured = false;

  /// Inicializa el SDK de RevenueCat y vincula el usuario actual de
  /// Firebase Auth (`firebaseUid`) como `appUserID`, para que la
  /// suscripción se reconozca de forma consistente entre dispositivos
  /// (si la persona inicia sesión en otro teléfono con la misma cuenta,
  /// RevenueCat sabe que es la misma persona).
  ///
  /// Debe llamarse una vez al iniciar sesión (o al arrancar la app si ya
  /// hay sesión activa), antes de consultar `hasActiveSubscription`.
  /// Mientras la API key siga siendo el placeholder, esta función no hace
  /// nada (evita que el SDK intente conectarse con una key inválida).
  Future<void> configure({required String firebaseUid}) async {
    if (_configured) return;
    if (!_hasRealApiKey) {
      debugPrint(
        'SubscriptionService: RevenueCat no configurado — falta sustituir '
        'REVENUECAT_API_KEY_PLACEHOLDER por la API key real (ver TODO en '
        'subscription_service.dart). Todas las funciones premium se '
        'evaluarán como no compradas.',
      );
      return;
    }

    try {
      await Purchases.setLogLevel(LogLevel.warn);
      final configuration = PurchasesConfiguration(_apiKeyForCurrentPlatform)
        ..appUserID = firebaseUid;
      await Purchases.configure(configuration);
      _configured = true;
    } catch (e) {
      debugPrint('SubscriptionService: error al configurar RevenueCat: $e');
    }
  }

  bool get _hasRealApiKey =>
      _apiKeyForCurrentPlatform.isNotEmpty && !_apiKeyForCurrentPlatform.contains('PLACEHOLDER');

  String get _apiKeyForCurrentPlatform =>
      defaultTargetPlatform == TargetPlatform.iOS ? _revenueCatApiKeyIOS : _revenueCatApiKeyAndroid;

  /// Consulta a RevenueCat si la persona tiene activo el entitlement
  /// "premium" (cualquiera de los 3 planes de pago lo concede). Si
  /// RevenueCat todavía no está configurado (API key placeholder) o la
  /// consulta falla (sin conexión, etc.), devuelve false — nunca bloquea
  /// la app, simplemente no concede acceso premium pagado (el acceso por
  /// prueba gratis se calcula aparte, sin depender de RevenueCat).
  Future<bool> hasActiveSubscriptionAsync() async {
    if (!_configured) return false;
    try {
      final customerInfo = await Purchases.getCustomerInfo();
      return customerInfo.entitlements.active.containsKey(entitlementId);
    } catch (e) {
      debugPrint('SubscriptionService: error al consultar customerInfo: $e');
      return false;
    }
  }

  /// Variante síncrona usada por widgets que hoy leen `hasActiveSubscription`
  /// como propiedad simple (p. ej. `hasAccess`). Usa el último `CustomerInfo`
  /// cacheado en memoria por el SDK de RevenueCat si ya se resolvió una vez
  /// en esta sesión; si no hay nada cacheado todavía, devuelve false (no
  /// puede haber suscripción pagada sin que RevenueCat esté configurado).
  ///
  /// Para lógica que decide si mostrar contenido premium de forma crítica,
  /// prefiere `hasActiveSubscriptionAsync()` (más fiable, consulta a
  /// RevenueCat en el momento).
  bool hasActiveSubscription(AppUser user) => _cachedHasActiveSubscription;

  bool _cachedHasActiveSubscription = false;

  /// Refresca el valor cacheado que usa `hasActiveSubscription`. Conviene
  /// llamarlo tras `configure()` y tras volver de la pantalla de paywall
  /// (por si la persona acaba de comprar).
  Future<void> refreshCachedStatus() async {
    _cachedHasActiveSubscription = await hasActiveSubscriptionAsync();
  }

  /// True si el usuario puede seguir usando la app con todas sus funciones
  /// (según el último estado conocido de RevenueCat).
  bool hasAccess(AppUser user) => hasActiveSubscription(user);

  /// Obtiene las ofertas actuales (los 3 `Package`: semanal, mensual,
  /// anual) configuradas en RevenueCat, para que la pantalla de paywall
  /// pinte precios reales y localizados. Devuelve una lista vacía si
  /// RevenueCat no está configurado o no hay ninguna oferta publicada
  /// todavía.
  Future<List<Package>> getAvailablePackages() async {
    if (!_configured) return [];
    try {
      final offerings = await Purchases.getOfferings();
      final current = offerings.current;
      if (current == null) return [];
      return current.availablePackages;
    } catch (e) {
      debugPrint('SubscriptionService: error al obtener offerings: $e');
      return [];
    }
  }

  /// Lanza el flujo de compra nativo para el `Package` elegido. Devuelve
  /// true si la compra se completó con éxito (entitlement activo tras la
  /// compra). Lanza `PlatformException` en caso de error o cancelación,
  /// que la pantalla de paywall captura para mostrar un mensaje.
  Future<bool> purchasePackage(Package package) async {
    // Desde purchases_flutter 10.x, purchasePackage() devuelve un
    // PurchaseResult (antes devolvía el CustomerInfo directamente) —
    // el CustomerInfo ahora está en `result.customerInfo`.
    final result = await Purchases.purchasePackage(package);
    final active = result.customerInfo.entitlements.active.containsKey(entitlementId);
    _cachedHasActiveSubscription = active;
    return active;
  }

  /// Restaura compras previas (necesario en iOS por requisito de Apple, y
  /// útil en Android si la persona reinstaló la app o cambió de teléfono).
  Future<bool> restorePurchases() async {
    if (!_configured) return false;
    try {
      final customerInfo = await Purchases.restorePurchases();
      final active = customerInfo.entitlements.active.containsKey(entitlementId);
      _cachedHasActiveSubscription = active;
      return active;
    } catch (e) {
      debugPrint('SubscriptionService: error al restaurar compras: $e');
      return false;
    }
  }
}
