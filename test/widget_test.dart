import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cicloplus_app/main.dart';

void main() {
  testWidgets('CicloPlus arranca sin errores', (WidgetTester tester) async {
    await tester.pumpWidget(const CicloPlusApp());
    // AuthGate revisa la sesión guardada (async) antes de mostrar la
    // pantalla de login, así que dejamos que ese frame se resuelva.
    await tester.pumpAndSettle();
    expect(find.text('CicloPlus'), findsWidgets);
  });
}
