import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/utils/auth_error_message.dart';
import '../../providers/auth_provider.dart';

class EmailVerificationScreen extends StatefulWidget {
  const EmailVerificationScreen({super.key});

  @override
  State<EmailVerificationScreen> createState() => _EmailVerificationScreenState();
}

class _EmailVerificationScreenState extends State<EmailVerificationScreen> {
  bool _loading = false;
  bool _resending = false;

  Future<void> _refreshStatus() async {
    final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
    setState(() => _loading = true);
    try {
      await context.read<AuthProvider>().reloadUser();
    } catch (error) {
      messenger.showSnackBar(SnackBar(content: Text(authErrorMessage(error))));
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              const Icon(Icons.mark_email_read_outlined, size: 64),
              const SizedBox(height: 12),
              const Text('Verify your college email to continue.'),
              const SizedBox(height: 18),
              FilledButton(
                onPressed: _loading ? null : _refreshStatus,
                child: Text(_loading ? 'Checking...' : 'I Verified My Email'),
              ),
              TextButton(
                onPressed: (_loading || _resending)
                    ? null
                    : () async {
                        final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
                        setState(() => _resending = true);
                        try {
                          await context.read<AuthProvider>().resendVerification();
                          if (!mounted) {
                            return;
                          }
                          messenger.showSnackBar(const SnackBar(content: Text('Verification email sent.')));
                        } catch (error) {
                          messenger.showSnackBar(SnackBar(content: Text(authErrorMessage(error))));
                        } finally {
                          if (mounted) {
                            setState(() => _resending = false);
                          }
                        }
                      },
                child: Text(_resending ? 'Sending...' : 'Resend Verification Email'),
              ),
              TextButton(
                onPressed: () async {
                  final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
                  try {
                    await context.read<AuthProvider>().logout();
                  } catch (error) {
                    messenger.showSnackBar(SnackBar(content: Text(authErrorMessage(error))));
                  }
                },
                child: const Text('Logout'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
