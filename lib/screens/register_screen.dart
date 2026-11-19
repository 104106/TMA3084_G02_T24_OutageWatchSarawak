import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../widgets/app_field.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});
  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _loading = false;
  String? _error;

  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    final err = await context.read<AuthProvider>().register(
          name: _name.text,
          phone: _phone.text,
          email: _email.text,
          password: _password.text,
        );
    if (!mounted) return;
    if (err == null) {
      Navigator.of(context).popUntil((r) => r.isFirst); // show home
    } else {
      setState(() {
        _loading = false;
        _error = err;
      });
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create account')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _form,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
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
                AppField(
                  controller: _email,
                  label: 'Email',
                  type: TextInputType.emailAddress,
                  validator: (v) => (v == null || !v.contains('@'))
                      ? 'Enter a valid email'
                      : null,
                ),
                const SizedBox(height: 16),
                AppField(
                  controller: _password,
                  label: 'Password (at least 8 characters)',
                  obscure: true,
                  validator: (v) => (v == null || v.length < 8)
                      ? 'Password must be at least 8 characters'
                      : null,
                ),
                if (_error != null) ...[
                  const SizedBox(height: 12),
                  Text(_error!,
                      style: TextStyle(
                          color: Theme.of(context).colorScheme.error)),
                ],
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: _loading ? null : _submit,
                  child: _loading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2))
                      : const Text('Register'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}