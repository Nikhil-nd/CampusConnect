import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_constants.dart';
import '../../core/utils/auth_error_message.dart';
import '../../core/utils/validators.dart';
import '../../providers/auth_provider.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _nameCtrl = TextEditingController();
  final TextEditingController _emailCtrl = TextEditingController();
  final TextEditingController _passwordCtrl = TextEditingController();
  final TextEditingController _branchCtrl = TextEditingController();
  final TextEditingController _yearCtrl = TextEditingController(text: '1');
  bool _loading = false;

  String get _allowedDomainsLabel =>
      AppConstants.allowedCollegeEmailDomains.map((String domain) => '@$domain').join(', ');

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _branchCtrl.dispose();
    _yearCtrl.dispose();
    super.dispose();
  }

  Future<void> _signup() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _loading = true);
    try {
      await context.read<AuthProvider>().signUp(
            name: _nameCtrl.text.trim(),
            email: _emailCtrl.text.trim().toLowerCase(),
            password: _passwordCtrl.text,
            branch: _branchCtrl.text.trim(),
            year: int.tryParse(_yearCtrl.text.trim()) ?? 1,
          );
      if (!mounted) {
        return;
      }
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Account created. Verify your email to continue.')),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(authErrorMessage(error))));
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create Account')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: <Widget>[
              TextFormField(
                controller: _nameCtrl,
                decoration: const InputDecoration(labelText: 'Name'),
                validator: (String? value) => Validators.requiredText(value, field: 'Name'),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _emailCtrl,
                decoration: InputDecoration(labelText: 'College Email ($_allowedDomainsLabel)'),
                validator: (String? value) {
                  if (value == null || value.isEmpty) {
                    return 'Email required';
                  }
                  if (!Validators.isCollegeEmailInDomains(value, AppConstants.allowedCollegeEmailDomains)) {
                    return 'Use one of: $_allowedDomainsLabel';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _passwordCtrl,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'Password'),
                validator: (String? value) => (value == null || value.length < 6) ? 'Min 6 chars' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _branchCtrl,
                decoration: const InputDecoration(labelText: 'Branch'),
                validator: (String? value) => Validators.requiredText(value, field: 'Branch'),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _yearCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Year'),
                validator: (String? value) {
                  final String trimmed = (value ?? '').trim();
                  final int? year = int.tryParse(trimmed);
                  if (year == null || year < 1 || year > 6) {
                    return 'Enter a year from 1 to 6';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              FilledButton(
                onPressed: _loading ? null : _signup,
                child: Text(_loading ? 'Creating...' : 'Sign Up'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
