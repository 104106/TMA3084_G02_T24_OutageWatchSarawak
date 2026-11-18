import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import 'login_screen.dart';
import 'profile_screen.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    if (auth.loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final u = auth.user;
    if (u == null) return const LoginScreen();

    switch (u.role) {
      case 'admin':
        return const _Stub('Admin dashboard (UI-06)'); // TODO Fabian
      case 'technician':
        return const _Stub('Assigned jobs (UI-08)'); // TODO Fabian
      default:
        return const _Stub('Customer home (UI-02)'); // TODO Maccoy
    }
  }
}

/// Placeholder until teammates' screens are merged. Replace with their widget.
class _Stub extends StatelessWidget {
  final String title;
  const _Stub(this.title);

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: Text(title), actions: [
          IconButton(
            icon: const Icon(Icons.person),
            tooltip: 'Profile',
            onPressed: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const ProfileScreen())),
          ),
        ]),
        body: Center(child: Text(title)),
      );
}