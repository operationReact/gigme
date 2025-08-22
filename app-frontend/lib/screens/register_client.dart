import 'package:flutter/material.dart';
import '../api/auth_api.dart';
import '../services/session_service.dart';
import 'profile_client.dart';

class RegisterClientPage extends StatefulWidget {
  static const routeName = '/register/client';
  const RegisterClientPage({super.key});

  @override
  State<RegisterClientPage> createState() => _RegisterClientPageState();
}

class _RegisterClientPageState extends State<RegisterClientPage> {
  final _formKey = GlobalKey<FormState>();
  final _companyController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _obscure = true;
  bool _obscure2 = true;
  double _pwdStrength = 0;
  String _pwdStrengthLabel = '';
  Color _pwdStrengthColor = Colors.red;

  void _updateStrength(String v) {
    int score = 0;
    if (v.length >= 6) score++;
    if (v.length >= 10) score++;
    if (RegExp(r'[A-Z]').hasMatch(v)) score++;
    if (RegExp(r'[0-9]').hasMatch(v)) score++;
    if (RegExp(r'[!@#%^&*(),.?":{}|<>]').hasMatch(v)) score++;
    _pwdStrength = score / 5;
    if (score <= 1) {
      _pwdStrengthLabel = 'Weak';
      _pwdStrengthColor = Colors.redAccent;
    } else if (score == 2) {
      _pwdStrengthLabel = 'Fair';
      _pwdStrengthColor = Colors.orange;
    } else if (score == 3) {
      _pwdStrengthLabel = 'Good';
      _pwdStrengthColor = Colors.lightGreen;
    } else {
      _pwdStrengthLabel = 'Strong';
      _pwdStrengthColor = Colors.green;
    }
  }

  @override
  void dispose() {
    _companyController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  void _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final authApi = AuthApi();
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Creating client account...')));
    try {
      final user = await authApi.register(email: _emailController.text.trim(), password: _passwordController.text, role: 'CLIENT');
      SessionService.instance.setUser(user);
      if (!mounted) return;
      Navigator.of(context).pushReplacementNamed('/clientProfile');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Registration failed: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Client Registration')),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [cs.secondary.withOpacity(0.35), cs.tertiary.withOpacity(0.35)],
          ),
        ),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: Card(
              color: cs.surface,
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          Hero(
                            tag: 'hero-client',
                            child: CircleAvatar(
                              radius: 22,
                              backgroundColor: cs.tertiary.withOpacity(0.2),
                              child: Icon(Icons.apartment_outlined, color: cs.primary),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text('Create your client account', style: Theme.of(context).textTheme.titleMedium),
                        ],
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _companyController,
                        decoration: const InputDecoration(
                          labelText: 'Company name',
                          prefixIcon: Icon(Icons.business_outlined),
                        ),
                        validator: (v) => (v == null || v.trim().length < 2) ? 'Enter your company' : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _emailController,
                        decoration: const InputDecoration(
                          labelText: 'Business email',
                          prefixIcon: Icon(Icons.email_outlined),
                        ),
                        keyboardType: TextInputType.emailAddress,
                        validator: (v) => (v == null || !v.contains('@')) ? 'Enter a valid email' : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _passwordController,
                        decoration: InputDecoration(
                          labelText: 'Password',
                          prefixIcon: const Icon(Icons.lock_outline),
                          suffixIcon: GestureDetector(
                            onLongPressStart: (_) => setState(() => _obscure = false),
                            onLongPressEnd: (_) => setState(() => _obscure = true),
                            child: IconButton(
                              icon: Icon(_obscure ? Icons.visibility : Icons.visibility_off),
                              onPressed: () => setState(() => _obscure = !_obscure),
                              tooltip: _obscure ? 'Show password' : 'Hide password',
                            ),
                          ),
                        ),
                        obscureText: _obscure,
                        onChanged: (v) {
                          setState(() => _updateStrength(v));
                        },
                        validator: (v) => (v == null || v.length < 6) ? 'At least 6 characters' : null,
                      ),
                      const SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          minHeight: 6,
                          value: _pwdStrength.clamp(0, 1),
                          backgroundColor: cs.outlineVariant.withOpacity(.3),
                          valueColor: AlwaysStoppedAnimation(_pwdStrengthColor),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Align(alignment: Alignment.centerLeft, child: Text(_pwdStrengthLabel, style: TextStyle(color: _pwdStrengthColor, fontSize: 12))),
                      TextFormField(
                        controller: _confirmController,
                        decoration: InputDecoration(
                          labelText: 'Confirm password',
                          prefixIcon: const Icon(Icons.lock_outline),
                          suffixIcon: GestureDetector(
                            onLongPressStart: (_) => setState(() => _obscure2 = false),
                            onLongPressEnd: (_) => setState(() => _obscure2 = true),
                            child: IconButton(
                              icon: Icon(_obscure2 ? Icons.visibility : Icons.visibility_off),
                              onPressed: () => setState(() => _obscure2 = !_obscure2),
                              tooltip: _obscure2 ? 'Show password' : 'Hide password',
                            ),
                          ),
                        ),
                        obscureText: _obscure2,
                        validator: (v) => (v != _passwordController.text) ? 'Passwords do not match' : null,
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton.icon(
                        onPressed: _submit,
                        icon: const Icon(Icons.person_add_alt_1),
                        label: const Text('Create account'),
                      ),
                      const SizedBox(height: 8),
                      TextButton(
                        onPressed: () => Navigator.of(context).maybePop(),
                        child: const Text('Back to sign in'),
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
  }
}
