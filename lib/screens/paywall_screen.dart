import 'package:flutter/material.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

import '../l10n/app_strings.dart';
import '../services/subscription_service.dart';
import '../theme/app_theme.dart';

/// Pantalla de suscripción (paywall): muestra los 3 planes de pago
/// (semanal, mensual, anual) con precios reales obtenidos de RevenueCat
/// (`package.storeProduct.priceString`), con el plan anual destacado como
/// "Más popular".
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
    final packages = await _subscriptionService.getAvailablePackages();
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
      appBar: AppBar(title: Text(s.paywallTitle)),
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
    };
    final sorted = [..._packages];
    sorted.sort((a, b) {
      final aKey = order[a.storeProduct.identifier] ?? (_isWeekly(a) ? 0 : (_isAnnual(a) ? 2 : 1));
      final bKey = order[b.storeProduct.identifier] ?? (_isWeekly(b) ? 0 : (_isAnnual(b) ? 2 : 1));
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
    final features = [s.paywallFeature1, s.paywallFeature2, s.paywallFeature3, s.paywallFeature4];
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

  Widget _buildPlanCard(AppStrings s, Package package) {
    final selected = _selectedPackage?.identifier == package.identifier;
    final isAnnual = _isAnnual(package);
    final isWeekly = _isWeekly(package);

    final String title = isAnnual
        ? s.paywallPlanAnnual
        : isWeekly
            ? s.paywallPlanWeekly
            : s.paywallPlanMonthly;
    final String desc = isAnnual
        ? s.paywallPlanAnnualDesc
        : isWeekly
            ? s.paywallPlanWeeklyDesc
            : s.paywallPlanMonthlyDesc;
    final String priceSuffix = isAnnual
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
              boxShadow: isAnnual
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
          if (isAnnual)
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
                  s.paywallRecommendedBadge,
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
