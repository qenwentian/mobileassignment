import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme.dart';
import '../viewmodels/auth_viewmodel.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});
  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _form = GlobalKey<FormState>();
  final _studentId = TextEditingController();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _code = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(
        (_) => context.read<AuthViewModel>().resetRegistration());
  }

  @override
  void dispose() {
    for (final c in [_studentId, _name, _email, _password, _code]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _sendCode() async {
    if (!_form.currentState!.validate()) return;
    await context.read<AuthViewModel>().startRegistration(
          studentId: _studentId.text,
          name: _name.text,
          email: _email.text,
          password: _password.text,
        );
  }

  Future<void> _confirm() async {
    final ok = await context.read<AuthViewModel>().verifyCode(_code.text);
    // Authenticated: drop Sign Up so the root (now MainShell/Feed) shows.
    if (ok && mounted) Navigator.of(context).popUntil((r) => r.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthViewModel>();
    final verifying = auth.step == RegistrationStep.verify;
    return Scaffold(
      appBar: AppBar(
        title: Text('Register (Step ${verifying ? 2 : 1}/2)'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: verifying ? _verifyStep(auth) : _detailsStep(auth),
        ),
      ),
    );
  }

  Widget _detailsStep(AuthViewModel auth) {
    return Form(
      key: _form,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextFormField(
            controller: _studentId,
            decoration: const InputDecoration(hintText: 'Student ID Number'),
            validator: auth.validateStudentId,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _name,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(hintText: 'Full Name'),
            validator: (v) => auth.validateRequired(v, 'your full name'),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _email,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(hintText: 'Campus Email (@univ.edu)'),
            validator: auth.validateEmail,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _password,
            obscureText: true,
            decoration: const InputDecoration(hintText: 'Create Password'),
            validator: auth.validatePassword,
          ),
          if (auth.error != null) ...[
            const SizedBox(height: 12),
            Text(auth.error!, style: const TextStyle(color: AppColors.lost)),
          ],
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: auth.loading ? null : _sendCode,
            child: auth.loading
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(strokeWidth: 2))
                : const Text('Verify 2FA Email'),
          ),
        ],
      ),
    );
  }

  Widget _verifyStep(AuthViewModel auth) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text('Enter the 6-digit code we emailed you.',
            style: TextStyle(color: AppColors.muted)),
        const SizedBox(height: 4),
        Text('Demo code: ${auth.demoCode}',
            style: const TextStyle(color: AppColors.accent, fontSize: 12)),
        const SizedBox(height: 16),
        TextField(
          controller: _code,
          keyboardType: TextInputType.number,
          maxLength: 6,
          decoration: const InputDecoration(hintText: '6-digit code'),
        ),
        if (auth.error != null)
          Text(auth.error!, style: const TextStyle(color: AppColors.lost)),
        const SizedBox(height: 12),
        ElevatedButton(
          onPressed: auth.loading ? null : _confirm,
          child: auth.loading
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(strokeWidth: 2))
              : const Text('Confirm Code'),
        ),
      ],
    );
  }
}
