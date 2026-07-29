import 'package:flutter/material.dart';
import 'package:pharmacy/features/representatives/data/model/representative_model.dart';

class RepresentativeFormResult {
  const RepresentativeFormResult({
    required this.name,
    required this.phone,
  });

  final String name;
  final String phone;
}

Future<RepresentativeFormResult?> showRepresentativeDialog(
  BuildContext context, {
  RepresentativeModel? representative,
}) {
  return showDialog<RepresentativeFormResult>(
    context: context,
    builder: (_) => RepresentativeDialog(representative: representative),
  );
}

class RepresentativeDialog extends StatefulWidget {
  const RepresentativeDialog({this.representative, super.key});

  final RepresentativeModel? representative;

  @override
  State<RepresentativeDialog> createState() => _RepresentativeDialogState();
}

class _RepresentativeDialogState extends State<RepresentativeDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _phoneController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(
      text: widget.representative?.name ?? '',
    );
    _phoneController = TextEditingController(
      text: widget.representative?.phone ?? '',
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        widget.representative == null
            ? 'Add representative'
            : 'Edit representative',
      ),
      content: SizedBox(
        width: 420,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Name'),
                validator: _required,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _phoneController,
                decoration: const InputDecoration(labelText: 'Phone'),
                keyboardType: TextInputType.phone,
                validator: _required,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _submit,
          child: const Text('Save'),
        ),
      ],
    );
  }

  String? _required(String? value) {
    return value == null || value.trim().isEmpty ? 'Required' : null;
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    Navigator.pop(
      context,
      RepresentativeFormResult(
        name: _nameController.text,
        phone: _phoneController.text,
      ),
    );
  }
}
