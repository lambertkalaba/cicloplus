import 'package:flutter/material.dart';
import '../widgets/ciclo_header.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

import '../l10n/app_strings.dart';
import '../services/subscription_service.dart';
import '../theme/app_theme.dart';
import '../go/strings.dart' show tr;

/// Pantalla de suscripción (paywall): muestra los planes de pago
/// (semanal, mensual, anual y de por vida) con precios reales obtenidos
/// de RevenueCat (`package.storeProduct.priceString`), con el plan anual
/// destacado como "Más popular" y el de por vida como "Mejor valor" (si
/// RevenueCat no lo ofrece todavía en alguna plataforma, simplemente no
/// aparece en la lista).
///
/// Si RevenueCat no devuelve ninguna oferta (sin conexión, offering no
/// publicado, etc.), `getAvailablePackages()` devuelve una lista vacía y
/// esta pantalla muestra un aviso en vez de precios — no hardcodea ningún
/// precio como texto fijo.
class PaywallScreen extends StatefulWidget {
  const PaywallScreen({super.key});

  @override
  State<PaywallScreen> createState() => _PaywallScreenState();
}

class _PaywallScreenState extends State<PaywallScreen> {
  final _subscriptionService = SubscriptionService();

  bool _loading = true;
  bool _purchasing = false;
  List<Package> _packages = [];
  Package? _selectedPackage;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadPackages();
  }

  Future<void> _loadPackages() async {
    // Solo plan mensual y anual (sin semanal ni de por vida).
    final packages = (await _subscriptionService.getAvailablePackages())
        .where((p) => !_isWeekly(p) && !_isLifetime(p))
        .toList();
    if (!mounted) return;
    setState(() {
      _packages = packages;
      _selectedPackage = _preselectAnnual(packages);
      _loading = false;
    });
  }

  /// El plan anual viene preseleccionado por defecto (es el recomendado).
  /// Si por lo que sea no está entre las ofertas, no preselecciona nada.
  Package? _preselectAnnual(List<Package> packages) {
    for (final p in packages) {
      if (p.packageType == PackageType.annual ||
          p.storeProduct.identifier == SubscriptionService.annualProductId) {
        return p;
      }
    }
    return packages.isNotEmpty ? packages.first : null;
  }

  bool _isAnnual(Package p) =>
      p.packageType == PackageType.annual || p.storeProduct.identifier == SubscriptionService.annualProductId;

  bool _isWeekly(Package p) =>
      p.packageType == PackageType.weekly || p.storeProduct.identifier == SubscriptionService.weeklyProductId;

  bool _isLifetime(Package p) =>
      p.packageType == PackageType.lifetime || p.storeProduct.identifier == SubscriptionService.lifetimeProductId;

  Future<void> _purchase() async {
    final package = _selectedPackage;
    if (package == null) return;

    setState(() {
      _purchasing = true;
      _errorMessage = null;
    });

    try {
      final success = await _subscriptionService.purchasePackage(package);
      if (!mounted) return;
      if (success) {
        final s = AppStrings.of(context);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(s.paywallPurchaseSuccess)));
        Navigator.of(context).pop(true);
      }
    } catch (_) {
      if (!mounted) return;
      final s = AppStrings.of(context);
      setState(() => _errorMessage = s.paywallPurchaseError);
    } finally {
      if (mounted) setState(() => _purchasing = false);
    }
  }

  Future<void> _restore() async {
    setState(() => _purchasing = true);
    final restored = await _subscriptionService.restorePurchases();
    if (!mounted) return;
    setState(() => _purchasing = false);
    final s = AppStrings.of(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(restored ? s.paywallRestoreSuccess : s.paywallRestoreNothingFound)),
    );
    if (restored) Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: CicloAppBar(title: Text(s.paywallTitle)),
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
            : ListView(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                children: [
                  _buildHeader(s),
                  const SizedBox(height: 20),
                  _buildFeatures(s),
                  const SizedBox(height: 24),
                  if (_packages.isEmpty)
                    _buildNoPlansNotice(s)
                  else ...[
                    ..._sortedPackages().map((p) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _buildPlanCard(s, p),
                        )),
                    const SizedBox(height: 8),
                    if (_errorMessage != null) ...[
                      Text(_errorMessage!, style: const TextStyle(color: Colors.red, fontSize: 12.5)),
                      const SizedBox(height: 10),
                    ],
                    _buildCtaButton(s),
                    const SizedBox(height: 14),
                    Center(
                      child: TextButton(
                        onPressed: _purchasing ? null : _restore,
                        child: Text(s.paywallRestorePurchases,
                            style: const TextStyle(color: AppColors.textMuted, fontSize: 12.5)),
                      ),
                    ),
                  ],
                  const SizedBox(height: 12),
                  Text(
                    s.paywallTerms,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 10.5, color: AppColors.textMuted, height: 1.4),
                  ),
                ],
              ),
      ),
    );
  }

  List<Package> _sortedPackages() {
    // Orden fijo semanal -> mensual -> anual, independientemente del
    // orden en que RevenueCat devuelva las ofertas.
    const order = {
      SubscriptionService.weeklyProductId: 0,
      SubscriptionService.monthlyProductId: 1,
      SubscriptionService.annualProductId: 2,
      SubscriptionService.lifetimeProductId: 3,
    };
    final sorted = [..._packages];
    sorted.sort((a, b) {
      final aKey = order[a.storeProduct.identifier] ?? (_isWeekly(a) ? 0 : (_isAnnual(a) ? 2 : (_isLifetime(a) ? 3 : 1)));
      final bKey = order[b.storeProduct.identifier] ?? (_isWeekly(b) ? 0 : (_isAnnual(b) ? 2 : (_isLifetime(b) ? 3 : 1)));
      return aKey.compareTo(bKey);
    });
    return sorted;
  }

  Widget _buildHeader(AppStrings s) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primary, AppColors.ovulation],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          const Text('🌸', style: TextStyle(fontSize: 34)),
          const SizedBox(height: 10),
          Text(
            s.paywallHeadline,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800, height: 1.3),
          ),
          const SizedBox(height: 8),
          Text(
            s.paywallSubheadline,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white70, fontSize: 12.5, height: 1.4),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatures(AppStrings s) {
    // Lo que de verdad incluye Premium (igual que la pantalla de candado).
    final features = [
      tr('Análisis del ciclo y tendencias', 'Cycle analysis and trends'),
      tr('Informe completo para tu médico', 'Full report for your doctor'),
      tr('Avisos de fertilidad: temperatura y test de ovulación', 'Fertility alerts: temperature and ovulation test'),
      tr('Armario, retos y logros de Michi', "Michi's wardrobe, challenges and badges"),
      tr('Modos «Intento concebir» y «Embarazo»', 'Trying to conceive and Pregnancy modes'),
      tr('Diario con Michi', 'Diary with Michi'),
    ];
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: features
            .map((f) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 5),
                  child: Row(
                    children: [
                      const Icon(Icons.check_circle, color: AppColors.ovulation, size: 18),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(f, style: const TextStyle(fontSize: 12.5, color: AppColors.textPrimary)),
                      ),
                    ],
                  ),
                ))
            .toList(),
      ),
    );
  }

  Widget _buildNoPlansNotice(AppStrings s) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primaryLight,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Text(
        s.paywallNoPlansAvailable,
        textAlign: TextAlign.center,
        style: const TextStyle(fontSize: 12.5, color: AppColors.textPrimary),
      ),
    );
  }

  /// % que se ahorra con el anual frente a 12 meses del mensual.
  int? _annualSaving() {
    Package? m, a;
    for (final p in _packages) {
      if (_isAnnual(p)) a = p;
      if (p.packageType == PackageType.monthly || p.storeProduct.identifier == SubscriptionService.monthlyProductId) m = p;
    }
    if (m == null || a == null) return null;
    final year = m.storeProduct.price * 12;
    if (year <= 0) return null;
    final pct = ((1 - a.storeProduct.price / year) * 100).round();
    return pct > 0 ? pct : null;
  }

  Widget _buildPlanCard(AppStrings s, Package package) {
    final selected = _selectedPackage?.identifier == package.identifier;
    final isAnnual = _isAnnual(package);
    final isWeekly = _isWeekly(package);
    final isLifetime = _isLifetime(package);

    final String title = isLifetime
        ? s.paywallPlanLifetime
        : isAnnual
            ? s.paywallPlanAnnual
            : isWeekly
                ? s.paywallPlanWeekly
                : s.paywallPlanMonthly;
    final String desc = isLifetime
        ? s.paywallPlanLifetimeDesc
        : isAnnual
            ? (_annualSaving() != null
                ? tr('Ahorra un {} % frente al mensual', 'Save {}% vs monthly').replaceFirst('{}', '${_annualSaving()}')
                : s.paywallPlanAnnualDesc)
            : isWeekly
                ? s.paywallPlanWeeklyDesc
                : s.paywallPlanMonthlyDesc;
    // El plan de por vida es un pago único: en vez de "/periodo" se
    // indica que es un pago único.
    final String priceSuffix = isLifetime
        ? s.paywallOneTimePayment
        : isAnnual
            ? s.paywallPerYear
            : isWeekly
                ? s.paywallPerWeek
                : s.paywallPerMonth;

    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () => setState(() => _selectedPackage = package),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: selected ? AppColors.ovulation : AppColors.border,
                width: selected ? 2 : 1.5,
              ),
              boxShadow: isAnnual || isLifetime
                  ? [BoxShadow(color: AppColors.ovulation.withOpacity(0.15), blurRadius: 12, offset: const Offset(0, 4))]
                  : null,
            ),
            child: Row(
              children: [
                Icon(
                  selected ? Icons.radio_button_checked : Icons.radio_button_off,
                  color: selected ? AppColors.ovulation : AppColors.textMuted,
                  size: 22,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w700)),
                      const SizedBox(height: 2),
                      Text(desc, style: const TextStyle(fontSize: 11.5, color: AppColors.textMuted)),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      package.storeProduct.priceString,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.primaryDark),
                    ),
                    Text(priceSuffix, style: const TextStyle(fontSize: 10.5, color: AppColors.textMuted)),
                  ],
                ),
              ],
            ),
          ),
          if (isAnnual || isLifetime)
            Positioned(
              top: -10,
              left: 16,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.ovulation,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  isLifetime ? s.paywallBestValueBadge : s.paywallRecommendedBadge,
                  style: const TextStyle(color: Colors.white, fontSize: 9.5, fontWeight: FontWeight.w800, letterSpacing: 0.4),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCtaButton(AppStrings s) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _selectedPackage == null || _purchasing ? null : _purchase,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 15),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
        child: _purchasing
            ? const SizedBox(
                width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
            : Text(
                s.paywallCtaButton,
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
              ),
      ),
    );
  }
}
