import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../widgets/app_field.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});
  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _form = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _phone;
  late final TextEditingController _email;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final u = context.read<AuthProvider>().user!;
    _name = TextEditingController(text: u.name);
    _phone = TextEditingController(text: u.phone);
    _email = TextEditingController(text: u.email);
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    setState(() => _saving = true);
    final err = await context
        .read<AuthProvider>()
        .updateProfile(name: _name.text, phone: _phone.text);
    if (!mounted) return;
    setState(() => _saving = false);
    ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(err ?? 'Profile updated')));
  }

  Future<void> _logout() async {
    await context.read<AuthProvider>().logout();
    if (mounted) Navigator.of(context).popUntil((r) => r.isFirst);
  }

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _email.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final role = context.read<AuthProvider>().user!.role;
    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _form,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Align(
                    alignment: Alignment.centerLeft,
                    child: Chip(label: Text('Role: $role'))),
                const SizedBox(height: 16),
                AppField(
                  controller: _name,
                  label: 'Full name',
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Enter your name' : null,
                ),
                const SizedBox(height: 16),
                AppField(
                  controller: _phone,
                  label: 'Phone number',
                  type: TextInputType.phone,
                  validator: (v) => (v == null ||
                          !RegExp(r'^[0-9+\- ]{8,15}$').hasMatch(v.trim()))
                      ? 'Enter a valid phone number'
                      : null,
                ),
                const SizedBox(height: 16),
                AppField(controller: _email, label: 'Email', enabled: false),
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: _saving ? null : _save,
                  child: const Text('Save'),
                ),
                const SizedBox(height: 12),
                OutlinedButton(
                    onPressed: _logout, child: const Text('Log out')),
              ],
            ),
          ),
        ),
      ),
    );
  }
}