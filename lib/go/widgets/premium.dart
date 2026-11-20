import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../cicloplus_links.dart';
import '../go_root.dart' show GoSession;
import '../strings.dart';
import 'ui.dart';

/// Premium (RevenueCat, entitlement "CicloPlus Pro"). Lo básico es gratis:
/// regla, calendario, registro, recordatorios y Michi. Son Premium:
/// análisis y tendencias, el informe para el médico, los avisos avanzados
/// de fertilidad y el armario, retos y logros de Michi.
class Premium {
  Premium._();
  static bool get active => GoSession.premium.value;
}

/// Muestra [child] si tiene Premium; si no, una pantalla bonita que explica
/// qué incluye y lleva al pago. Se actualiza sola al comprar.
class PremiumGate extends StatelessWidget {
  const PremiumGate({super.key, required this.title, required this.child});
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) => ValueListenableBuilder<bool>(
        valueListenable: GoSession.premium,
        builder: (context, on, _) => on ? child : _PremiumLocked(title: title),
      );
}

class _PremiumLocked extends StatelessWidget {
  const _PremiumLocked({required this.title});
  final String title;

  @override
  Widget build(BuildContext context) {
    final perks = [
      ('📊', tr('Análisis del ciclo y tendencias', 'Cycle analysis and trends')),
      ('📄', tr('Informe completo para tu médico', 'Full report for your doctor')),
      ('🌱', tr('Avisos de fertilidad: temperatura y test de ovulación', 'Fertility alerts: temperature and ovulation test')),
      ('👗', tr('Armario, retos y logros de Michi', "Michi's wardrobe, challenges and badges")),
    ];
    return SubPage(
      title: title,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(18, 18, 18, 28),
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(20, 22, 20, 22),
            decoration: card(radius: 24),
            child: Column(children: [
              Container(
                width: 110,
                height: 110,
                decoration: BoxDecoration(color: const Color(0xFFFFF4D6), shape: BoxShape.circle),
                alignment: Alignment.center,
                child: const Img('michi_crown', size: 92, fallback: Icons.workspace_premium_rounded),
              ),
              const SizedBox(height: 14),
              Text(tr('Esto es Premium 👑', 'This is Premium 👑'),
                  textAlign: TextAlign.center, style: TextStyle(fontSize: 21, fontWeight: FontWeight.w900, color: C.pinkDark)),
              const SizedBox(height: 6),
              Text(tr('Lo básico de CicloPlus es gratis para siempre. Con Premium, además:', 'The basics of CicloPlus are free forever. With Premium you also get:'),
                  textAlign: TextAlign.center, style: const TextStyle(fontSize: 14, height: 1.4, color: C.muted)),
              const SizedBox(height: 14),
              for (final p in perks)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 5),
                  child: Row(children: [
                    Container(
                      width: 34,
                      height: 34,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(color: C.pinkSoft, shape: BoxShape.circle),
                      child: Text(p.$1, style: const TextStyle(fontSize: 16)),
                    ),
                    const SizedBox(width: 12),
                    Expanded(child: Text(p.$2, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: C.text))),
                  ]),
                ),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: FilledButton(
                  onPressed: () => CP.openPremium(context),
                  style: FilledButton.styleFrom(backgroundColor: C.pink, shape: const StadiumBorder(), elevation: 2),
                  child: Text(tr('Prueba 7 días gratis', 'Try 7 days free'),
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Colors.white)),
                ),
              ),
            ]),
          ),
        ],
      ),
    );
  }
}

/// Tarjeta pequeña dentro de una pantalla gratuita: "esto es Premium".
class PremiumTeaser extends StatelessWidget {
  const PremiumTeaser({super.key, required this.text});
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(top: 12),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: () => CP.openPremium(context),
          child: Container(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF8E6),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0xFFF5DE9E)),
            ),
            child: Row(children: [
              const Text('👑', style: TextStyle(fontSize: 22)),
              const SizedBox(width: 10),
              Expanded(child: Text(text, style: const TextStyle(fontSize: 13, height: 1.35, fontWeight: FontWeight.w700, color: Color(0xFF7A5A12)))),
              const Icon(Icons.chevron_right_rounded, color: Color(0xFFB98A1E)),
            ]),
          ),
        ),
      );
}


/// Pantalla para quien ya tiene Premium: confirma que está activo, muestra
/// lo que tiene desbloqueado y permite gestionar o cancelar la suscripción
/// en la tienda.
class PremiumActiveScreen extends StatelessWidget {
  const PremiumActiveScreen({super.key});

  Future<void> _manage() async {
    final ios = !kIsWeb && defaultTargetPlatform == TargetPlatform.iOS;
    final url = ios
        ? 'https://apps.apple.com/account/subscriptions'
        : 'https://play.google.com/store/account/subscriptions?package=com.cicloplus.cicloplus_app';
    await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    final perks = [
      ('📊', tr('Análisis del ciclo y tendencias', 'Cycle analysis and trends')),
      ('📄', tr('Informe completo para tu médico', 'Full report for your doctor')),
      ('🌱', tr('Avisos de fertilidad: temperatura y test de ovulación', 'Fertility alerts: temperature and ovulation test')),
      ('👗', tr('Armario, retos y logros de Michi', "Michi's wardrobe, challenges and badges")),
    ];
    return SubPage(
      title: tr('CicloPlus Premium', 'CicloPlus Premium'),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(18, 18, 18, 28),
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(20, 22, 20, 22),
            decoration: card(radius: 24),
            child: Column(children: [
              Container(
                width: 110,
                height: 110,
                decoration: const BoxDecoration(color: Color(0xFFFFF4D6), shape: BoxShape.circle),
                alignment: Alignment.center,
                child: const Img('michi_crown', size: 92, fallback: Icons.workspace_premium_rounded),
              ),
              const SizedBox(height: 14),
              Text(tr('¡Ya eres Premium! 👑', "You're Premium! 👑"),
                  textAlign: TextAlign.center, style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: C.pinkDark)),
              const SizedBox(height: 6),
              Text(tr('Gracias por apoyar CicloPlus 💗 Tienes todo desbloqueado:', 'Thank you for supporting CicloPlus 💗 Everything is unlocked:'),
                  textAlign: TextAlign.center, style: const TextStyle(fontSize: 14, height: 1.4, color: C.muted)),
              const SizedBox(height: 14),
              for (final p in perks)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 5),
                  child: Row(children: [
                    Container(
                      width: 34,
                      height: 34,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(color: C.pinkSoft, shape: BoxShape.circle),
                      child: Text(p.$1, style: const TextStyle(fontSize: 16)),
                    ),
                    const SizedBox(width: 12),
                    Expanded(child: Text(p.$2, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: C.text))),
                    const Icon(Icons.check_circle_rounded, color: Color(0xFF2FB45A), size: 22),
                  ]),
                ),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: OutlinedButton(
                  onPressed: _manage,
                  style: OutlinedButton.styleFrom(shape: const StadiumBorder(), side: BorderSide(color: C.pink, width: 1.5)),
                  child: Text(tr('Gestionar suscripción', 'Manage subscription'),
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: C.pinkDark)),
                ),
              ),
              const SizedBox(height: 8),
              Text(tr('Puedes cambiar de plan o cancelar cuando quieras desde la tienda.', 'You can change plan or cancel anytime from the store.'),
                  textAlign: TextAlign.center, style: const TextStyle(fontSize: 12, color: C.muted)),
            ]),
          ),
        ],
      ),
    );
  }
}
