import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:outagewatch_sarawak/models/app_user.dart';
import 'package:outagewatch_sarawak/providers/auth_provider.dart';
import 'package:outagewatch_sarawak/screens/auth_gate.dart';
import 'package:outagewatch_sarawak/screens/login_screen.dart';
import 'package:outagewatch_sarawak/screens/register_screen.dart';

/// Fake provider so tests never touch Firebase.
class FakeAuth extends ChangeNotifier implements AuthProvider {
  @override
  AppUser? user;
  @override
  bool loading = false;

  String? loginResult;
  String? registerResult;
  String? lastEmail;
  String? lastPassword;
  int loginCalls = 0;
  int registerCalls = 0;

  @override
  Future<String?> login(String email, String password) async {
    loginCalls++;
    lastEmail = email;
    lastPassword = password;
    return loginResult;
  }

  @override
  Future<String?> register({
    required String name,
    required String phone,
    required String email,
    required String password,
  }) async {
    registerCalls++;
    return registerResult;
  }

  @override
  Future<String?> updateProfile(
          {required String name, required String phone}) async =>
      null;

  @override
  Future<void> logout() async {}

  // Covers any other AuthProvider members (e.g. sendPasswordReset).
  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

Widget wrap(Widget child, FakeAuth auth) =>
    ChangeNotifierProvider<AuthProvider>.value(
      value: auth,
      child: MaterialApp(home: child),
    );

AppUser userWithRole(String role) => AppUser(
      uid: 'u1',
      name: 'Test User',
      email: 'test@example.com',
      phone: '0123456789',
      role: role,
      isActive: true,
    );

Finder field(String label) => find.widgetWithText(TextFormField, label);

void main() {
  group('AppUser model', () {
    test('fromMap reads all fields', () {
      final u = AppUser.fromMap('abc', {
        'name': 'Ali',
        'email': 'ali@example.com',
        'phone': '0123456789',
        'role': 'technician',
        'isActive': false,
      });
      expect(u.uid, 'abc');
      expect(u.name, 'Ali');
      expect(u.role, 'technician');
      expect(u.isActive, false);
    });

    test('fromMap defaults to an active customer', () {
      final u = AppUser.fromMap('abc', {});
      expect(u.role, 'customer');
      expect(u.isActive, true);
    });
  });

  group('FR-02 LoginScreen', () {
    testWidgets('shows email, password and Log in button', (tester) async {
      await tester.pumpWidget(wrap(const LoginScreen(), FakeAuth()));
      expect(field('Email'), findsOneWidget);
      expect(field('Password'), findsOneWidget);
      expect(find.text('Log in'), findsOneWidget);
    });

    testWidgets('empty form shows errors and does not log in',
        (tester) async {
      final auth = FakeAuth();
      await tester.pumpWidget(wrap(const LoginScreen(), auth));
      await tester.tap(find.text('Log in'));
      await tester.pumpAndSettle();
      expect(find.text('Enter a valid email'), findsOneWidget);
      expect(find.text('Enter your password'), findsOneWidget);
      expect(auth.loginCalls, 0);
    });

    testWidgets('valid form calls login with the typed values',
        (tester) async {
      final auth = FakeAuth();
      await tester.pumpWidget(wrap(const LoginScreen(), auth));
      await tester.enterText(field('Email'), 'a@b.com');
      await tester.enterText(field('Password'), 'secret123');
      await tester.tap(find.text('Log in'));
      await tester.pump();
      await tester.pump();
      expect(auth.loginCalls, 1);
      expect(auth.lastEmail, 'a@b.com');
      expect(auth.lastPassword, 'secret123');
    });

    testWidgets('shows the error message when login fails', (tester) async {
      final auth = FakeAuth()..loginResult = 'Invalid email or password.';
      await tester.pumpWidget(wrap(const LoginScreen(), auth));
      await tester.enterText(field('Email'), 'a@b.com');
      await tester.enterText(field('Password'), 'wrongpass');
      await tester.tap(find.text('Log in'));
      await tester.pump();
      await tester.pump();
      expect(find.text('Invalid email or password.'), findsOneWidget);
    });

    testWidgets('can open the register screen', (tester) async {
      await tester.pumpWidget(wrap(const LoginScreen(), FakeAuth()));
      await tester.tap(find.text('Create a customer account'));
      await tester.pumpAndSettle();
      expect(find.byType(RegisterScreen), findsOneWidget);
    });
  });

  group('FR-01 RegisterScreen', () {
    Future<void> fill(WidgetTester t,
        {String name = 'Ali',
        String phone = '0123456789',
        String email = 'a@b.com',
        String password = 'password123'}) async {
      await t.enterText(field('Full name'), name);
      await t.enterText(field('Phone number'), phone);
      await t.enterText(field('Email'), email);
      await t.enterText(field('Password (at least 8 characters)'), password);
    }

    testWidgets('password under 8 characters is rejected', (tester) async {
      final auth = FakeAuth();
      await tester.pumpWidget(wrap(const RegisterScreen(), auth));
      await fill(tester, password: '123');
      await tester.tap(find.text('Register'));
      await tester.pumpAndSettle();
      expect(find.text('Password must be at least 8 characters'),
          findsOneWidget);
      expect(auth.registerCalls, 0);
    });

    testWidgets('invalid phone number is rejected', (tester) async {
      final auth = FakeAuth();
      await tester.pumpWidget(wrap(const RegisterScreen(), auth));
      await fill(tester, phone: 'abc');
      await tester.tap(find.text('Register'));
      await tester.pumpAndSettle();
      expect(find.text('Enter a valid phone number'), findsOneWidget);
      expect(auth.registerCalls, 0);
    });

    testWidgets('valid form calls register once', (tester) async {
      final auth = FakeAuth();
      await tester.pumpWidget(wrap(const RegisterScreen(), auth));
      await fill(tester);
      await tester.tap(find.text('Register'));
      await tester.pump();
      await tester.pump();
      expect(auth.registerCalls, 1);
    });

    testWidgets('shows the error when the email is already used',
        (tester) async {
      final auth = FakeAuth()..registerResult = 'Email already registered.';
      await tester.pumpWidget(wrap(const RegisterScreen(), auth));
      await fill(tester);
      await tester.tap(find.text('Register'));
      await tester.pump();
      await tester.pump();
      expect(find.text('Email already registered.'), findsOneWidget);
    });
  });

  group('FR-02 AuthGate role-based home', () {
    testWidgets('shows a spinner while loading', (tester) async {
      final auth = FakeAuth()..loading = true;
      await tester.pumpWidget(wrap(const AuthGate(), auth));
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('logged out user sees the login screen', (tester) async {
      await tester.pumpWidget(wrap(const AuthGate(), FakeAuth()));
      expect(find.byType(LoginScreen), findsOneWidget);
    });

    testWidgets('customer sees the customer home', (tester) async {
      final auth = FakeAuth()..user = userWithRole('customer');
      await tester.pumpWidget(wrap(const AuthGate(), auth));
      expect(find.text('Customer home (UI-02)'), findsWidgets);
    });

    testWidgets('technician sees the assigned jobs screen', (tester) async {
      final auth = FakeAuth()..user = userWithRole('technician');
      await tester.pumpWidget(wrap(const AuthGate(), auth));
      expect(find.text('Assigned jobs (UI-08)'), findsWidgets);
    });

    testWidgets('admin sees the admin dashboard', (tester) async {
      final auth = FakeAuth()..user = userWithRole('admin');
      await tester.pumpWidget(wrap(const AuthGate(), auth));
      expect(find.text('Admin dashboard (UI-06)'), findsWidgets);
    });
  });
}