import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_constants.dart';
import '../../core/utils/auth_error_message.dart';
import '../../core/utils/validators.dart';
import '../../providers/auth_provider.dart';
import '../../routes/app_router.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _emailCtrl = TextEditingController();
  final TextEditingController _passwordCtrl = TextEditingController();
  bool _loading = false;

  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _loading = true);
    try {
      await context.read<AuthProvider>().login(
            email: _emailCtrl.text,
            password: _passwordCtrl.text,
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
    final TextTheme textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: const Text('CampusConnect Login')),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (BuildContext context, BoxConstraints constraints) {
            return SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 420),
                    child: Card(
                      clipBehavior: Clip.antiAlias,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: <Widget>[
                              Text('Welcome back', style: textTheme.headlineSmall),
                              const SizedBox(height: 4),
                              Text(
                                'Sign in with your college email to continue.',
                                style: textTheme.bodyMedium,
                              ),
                              const SizedBox(height: 16),
                              TextFormField(
                                controller: _emailCtrl,
                                keyboardType: TextInputType.emailAddress,
                                textInputAction: TextInputAction.next,
                                autofillHints: const <String>[AutofillHints.username, AutofillHints.email],
                                decoration: const InputDecoration(
                                  labelText: 'College Email',
                                  hintText: 'name@college.edu',
                                ),
                                validator: (String? value) {
                                  if (value == null || value.trim().isEmpty) {
                                    return 'Email required';
                                  }
                                  if (!Validators.isCollegeEmailInDomains(
                                    value,
                                    AppConstants.allowedCollegeEmailDomains,
                                  )) {
                                    return 'Use one of: ${AppConstants.allowedCollegeEmailDomains.map((String domain) => '@$domain').join(', ')}';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 12),
                              TextFormField(
                                controller: _passwordCtrl,
                                obscureText: _obscurePassword,
                                textInputAction: TextInputAction.done,
                                autofillHints: const <String>[AutofillHints.password],
                                onFieldSubmitted: (_) => _loading ? null : _login,
                                decoration: InputDecoration(
                                  labelText: 'Password',
                                  suffixIcon: IconButton(
                                    tooltip: _obscurePassword ? 'Show password' : 'Hide password',
                                    onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                                    icon: Icon(_obscurePassword ? Icons.visibility : Icons.visibility_off),
                                  ),
                                ),
                                validator: (String? value) =>
                                    (value == null || value.length < 6) ? 'Min 6 chars' : null,
                              ),
                              const SizedBox(height: 20),
                              SizedBox(
                                height: 48,
                                child: FilledButton(
                                  onPressed: _loading ? null : _login,
                                  child: Text(_loading ? 'Logging in...' : 'Login'),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: <Widget>[
                                  TextButton(
                                    onPressed: () => Navigator.pushNamed(context, AppRouter.signup),
                                    child: const Text('Create Account'),
                                  ),
                                  TextButton(
                                    onPressed: () => Navigator.pushNamed(context, AppRouter.forgot),
                                    child: const Text('Forgot Password?'),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
