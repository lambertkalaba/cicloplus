import 'package:flutter/material.dart';

import 'ui.dart';

/// Estilo de todos los diálogos de la app (tarjeta blanca muy redondeada,
/// título en negrita rosa). Se usa como tema global.
DialogThemeData cicloDialogTheme() => DialogThemeData(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      elevation: 10,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      titleTextStyle: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: C.pinkDark),
      contentTextStyle: const TextStyle(fontSize: 14.5, height: 1.45, color: Color(0xFF6B5A63)),
    );

/// Diálogo de confirmación con el diseño de CicloPlus (hecho con ChatGPT):
/// hibisco arriba en un círculo rosa, título centrado, texto en gris y dos
/// botones a lo ancho (el principal en pastilla rosa, el otro con borde).
/// Devuelve true (principal), false (secundario) o null (cerrado).
Future<bool?> showCicloConfirm(
  BuildContext context, {
  required String title,
  required String message,
  required String confirm,
  required String cancel,
  String icon = 'hibiscus',
}) {
  return showDialog<bool>(
    context: context,
    builder: (c) {
      final pink = C.pink;
      return Dialog(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(22, 22, 22, 18),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(
              width: 76,
              height: 76,
              decoration: BoxDecoration(color: C.pinkSoft, shape: BoxShape.circle),
              alignment: Alignment.center,
              child: Img(icon, size: 56, fallback: Icons.local_florist_rounded),
            ),
            const SizedBox(height: 14),
            Text(title, textAlign: TextAlign.center, style: TextStyle(fontSize: 21, fontWeight: FontWeight.w900, color: C.pinkDark)),
            const SizedBox(height: 8),
            Text(message, textAlign: TextAlign.center, style: const TextStyle(fontSize: 14.5, height: 1.45, color: Color(0xFF6B5A63))),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: FilledButton(
                onPressed: () => Navigator.pop(c, true),
                style: FilledButton.styleFrom(backgroundColor: pink, foregroundColor: Colors.white, shape: const StadiumBorder(), elevation: 2),
                child: Text(confirm, style: const TextStyle(fontSize: 15.5, fontWeight: FontWeight.w900)),
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: OutlinedButton(
                onPressed: () => Navigator.pop(c, false),
                style: OutlinedButton.styleFrom(foregroundColor: pink, side: BorderSide(color: pink, width: 1.5), shape: const StadiumBorder()),
                child: Text(cancel, style: const TextStyle(fontSize: 15.5, fontWeight: FontWeight.w800)),
              ),
            ),
          ]),
        ),
      );
    },
  );
}
