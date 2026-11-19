import 'package:material_ui/material_ui.dart';

class AppField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final bool obscure;
  final bool enabled;
  final TextInputType? type;
  final String? Function(String?)? validator;

  const AppField({
    super.key,
    required this.controller,
    required this.label,
    this.obscure = false,
    this.enabled = true,
    this.type,
    this.validator,
  });

  @override
  Widget build(BuildContext context) => TextFormField(
        controller: controller,
        obscureText: obscure,
        enabled: enabled,
        keyboardType: type,
        validator: validator,
        decoration: InputDecoration(
            labelText: label, border: const OutlineInputBorder()),
      );
}