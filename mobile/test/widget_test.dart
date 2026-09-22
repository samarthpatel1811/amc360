import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/widgets/metric_card.dart';
import 'package:mobile/core/widgets/status_badge.dart';
import 'package:mobile/features/auth/auth_provider.dart';
import 'package:mobile/features/auth/login_screen.dart';
import 'package:mobile/features/onboarding/onboarding_screen.dart';

class MockAuthNotifier extends AuthNotifier {
  @override
  AuthState build() => AuthState(isLoading: false, isAuthenticated: false);
}

void main() {
  testWidgets('LoginScreen renders brand badge, fields, and 1-tap demo pills', (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authProvider.overrideWith(() => MockAuthNotifier()),
        ],
        child: const MaterialApp(
          home: LoginScreen(),
        ),
      ),
    );
    await tester.pump();

    // Verify Brand title & greeting
    expect(find.text('AMC360'), findsOneWidget);
    expect(find.text('Manage your service business beautifully.'), findsOneWidget);

    // Verify Quick Demo Role pills
    expect(find.text('Admin'), findsOneWidget);
    expect(find.text('Technician'), findsOneWidget);
    expect(find.text('Customer'), findsOneWidget);

    // Verify Sign In CTA
    expect(find.text('Sign In as Admin'), findsOneWidget);
  });


  testWidgets('OnboardingScreen renders first step and control actions', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: OnboardingScreen(),
      ),
    );
    await tester.pump();

    expect(find.text('Manage Every Contract'), findsOneWidget);
    expect(find.text('CONTRACT ENGINE'), findsOneWidget);
    expect(find.text('Continue'), findsOneWidget);
    expect(find.text('Skip'), findsOneWidget);
  });

  testWidgets('MetricCard renders title, value, and trend', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: MetricCard(
            title: 'Active AMCs',
            value: '42',
            icon: Icons.shield_outlined,
            trend: '+12%',
            isTrendPositive: true,
          ),
        ),
      ),
    );

    expect(find.text('Active AMCs'), findsOneWidget);
    expect(find.text('42'), findsOneWidget);
    expect(find.text('+12%'), findsOneWidget);
    expect(find.byIcon(Icons.arrow_upward), findsOneWidget);
  });

  testWidgets('StatusBadge renders correct label and style', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Column(
            children: [
              StatusBadge(status: 'active'),
              StatusBadge(status: 'payment_requested'),
              StatusBadge(status: 'payment_declined'),
            ],
          ),
        ),
      ),
    );

    expect(find.text('Active'), findsOneWidget);
    expect(find.text('Payment Requested'), findsOneWidget);
    expect(find.text('Declined Payment'), findsOneWidget);
  });
}



