import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:pdm_aula12_shared_preferences/main.dart';
import 'package:pdm_aula12_shared_preferences/services/preferences_service.dart';

void main() {
  testWidgets('carrega preferências salvas e exibe último acesso', (tester) async {
    SharedPreferences.setMockInitialValues({
      'key_nome_usuario': 'Maria',
      'key_modo_escuro': true,
      'key_ultimo_acesso': DateTime(2026, 10, 20, 9, 5).toString(),
      'key_tarefas': '[{"titulo":"Estudar Flutter","concluida":false}]',
    });

    await tester.pumpWidget(const MeuApp(modoEscuroInicial: true));
    await tester.pumpAndSettle();

    expect(find.text('Maria'), findsOneWidget);
    expect(find.text('Estudar Flutter'), findsOneWidget);
    expect(find.text('Último acesso: 20/10/2026 às 09:05'), findsOneWidget);
    expect(tester.widget<SwitchListTile>(find.byType(SwitchListTile)).value, isTrue);
  });

  testWidgets('adiciona tarefa e persiste como JSON', (tester) async {
    SharedPreferences.setMockInitialValues({});

    await tester.pumpWidget(const MeuApp(modoEscuroInicial: false));
    await tester.pumpAndSettle();

    expect(find.text('Primeiro acesso ao aplicativo'), findsOneWidget);

    await tester.enterText(find.widgetWithText(TextField, 'Nova tarefa'), 'Entregar atividade');
    await tester.tap(find.byIcon(Icons.add));
    await tester.pumpAndSettle();

    expect(find.text('Entregar atividade'), findsOneWidget);
    final tarefas = await PreferencesService().obterTarefas();
    expect(tarefas.single['titulo'], 'Entregar atividade');
  });

  testWidgets('redefinir padrões limpa preferências', (tester) async {
    SharedPreferences.setMockInitialValues({
      'key_nome_usuario': 'Maria',
      'key_modo_escuro': true,
    });

    await tester.pumpWidget(const MeuApp(modoEscuroInicial: true));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Redefinir Padrões'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Redefinir'));
    await tester.pumpAndSettle();

    expect(find.text(PreferencesService.nomePadrao), findsOneWidget);
    expect(await PreferencesService().obterModoEscuro(), isFalse);
  });
}
