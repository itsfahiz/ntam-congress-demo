import 'package:flutter/material.dart';

import '../../../app/theme/app_colors.dart';
import '../../auth/domain/attendee.dart';
import '../../auth/state/auth_controller.dart';

Future<void> showEditProfileSheet(
  BuildContext context, {
  required Attendee attendee,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    backgroundColor: AppColors.card,
    builder: (context) => _EditProfileSheet(attendee: attendee),
  );
}

class _EditProfileSheet extends StatefulWidget {
  const _EditProfileSheet({required this.attendee});
  final Attendee attendee;

  @override
  State<_EditProfileSheet> createState() => _EditProfileSheetState();
}

class _EditProfileSheetState extends State<_EditProfileSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _organization;
  late final TextEditingController _phone;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: widget.attendee.fullName);
    _organization = TextEditingController(text: widget.attendee.organization);
    _phone = TextEditingController(
      text: widget.attendee.phone == 'Not provided'
          ? ''
          : widget.attendee.phone,
    );
  }

  @override
  void dispose() {
    _name.dispose();
    _organization.dispose();
    _phone.dispose();
    super.dispose();
  }

  String? _phoneValidator(String? value) {
    final text = (value ?? '').trim();
    if (text.isEmpty) return null;
    if (text.length > 32 || !RegExp(r'^[+0-9() -]+$').hasMatch(text)) {
      return 'Use digits, spaces or + (maximum 32 characters).';
    }
    final digits = text.replaceAll(RegExp(r'\D'), '').length;
    if (digits < 7 || digits > 15) {
      return 'Phone number must contain 7–15 digits.';
    }
    return null;
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate() || _saving) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await AuthScope.of(context).updateProfile(
        fullName: _name.text.trim(),
        organization: _organization.text.trim(),
        phone: _phone.text.trim(),
      );
      if (!mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile updated successfully.')),
      );
    } catch (error) {
      if (!mounted) return;
      setState(() => _error = error.toString());
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          24, 8, 24, MediaQuery.viewInsetsOf(context).bottom + 24,
        ),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Edit Profile',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 18),
                TextFormField(
                  controller: _name,
                  enabled: !_saving,
                  maxLength: 80,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(labelText: 'Full name'),
                  validator: (value) {
                    final text = (value ?? '').trim();
                    return text.length < 2 || text.length > 80
                        ? 'Name must contain 2–80 characters.'
                        : null;
                  },
                ),
                TextFormField(
                  controller: _organization,
                  enabled: !_saving,
                  maxLength: 80,
                  decoration: const InputDecoration(
                    labelText: 'Hospital / Organization',
                  ),
                ),
                TextFormField(
                  controller: _phone,
                  enabled: !_saving,
                  maxLength: 32,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    labelText: 'Phone number (optional)',
                    hintText: '+971 50 123 4567',
                  ),
                  validator: _phoneValidator,
                ),
                const Text(
                  'Email and badge ID cannot be changed here.',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
                if (_error != null) ...[
                  const SizedBox(height: 10),
                  Text(_error!, style: const TextStyle(color: Colors.red)),
                ],
                const SizedBox(height: 18),
                FilledButton(
                  onPressed: _saving ? null : _save,
                  child: _saving
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Save Changes'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
