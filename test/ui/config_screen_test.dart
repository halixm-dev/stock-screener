import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stock_screener/ui/config/indicator_config_screen.dart';
import 'package:stock_screener/state/config_cubit.dart';
import 'package:stock_screener/data/config_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:stock_screener/ui/theme/app_theme.dart';

void main() {
  testWidgets('IndicatorConfigScreen rendering test', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final repo = ConfigRepository(prefs);
    final cubit = ConfigCubit(repo);
    await cubit.loadConfig();

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: BlocProvider.value(
          value: cubit,
          child: const IndicatorConfigScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();
    expect(find.byType(IndicatorConfigScreen), findsOneWidget);
  });
}
