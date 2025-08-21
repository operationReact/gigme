import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/auth_service.dart';
import 'freelancer_profile_screen.dart';
import 'client_profile_screen.dart';
import '../main.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  static const route = '/login';

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _pwd = TextEditingController();
  bool _loading = false;
  bool _obscure = true;

  UserType _typeFromArgs(BuildContext context) {
    final arg = ModalRoute.of(context)!.settings.arguments;
    if (arg is UserType) return arg;
    return UserType.freelancer;
  }

  Future<void> _submit(UserType type) async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    await Future.delayed(const Duration(milliseconds: 600)); // simulate call
    final auth = AuthService.instance;
    auth.login(type, name: _email.text.split('@').first);
    setState(() => _loading = false);
    // If profile missing, go create
    if (type == UserType.freelancer && !auth.freelancerProfileCreated) {
      if (mounted) Navigator.of(context).pushReplacementNamed(FreelancerProfileScreen.route);
      return;
    }
    if (type == UserType.client && !auth.clientProfileCreated) {
      if (mounted) Navigator.of(context).pushReplacementNamed(ClientProfileScreen.route);
      return;
    }
    if (mounted) {
      Navigator.of(context).pushNamedAndRemoveUntil(JobsPage.route, (_) => false);
    }
  }

  @override
  void dispose() { _email.dispose(); _pwd.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final type = _typeFromArgs(context);
    final isFreelancer = type == UserType.freelancer;
    final heroTag = isFreelancer ? 'freelancerRole' : 'clientRole';
    final gradient = isFreelancer
      ? const LinearGradient(colors: [Color(0xFF6D83F2), Color(0xFF5146E1)])
      : const LinearGradient(colors: [Color(0xFFEE7752), Color(0xFFE73C7E)]);

    return Scaffold(
      backgroundColor: Colors.black.withOpacity(.25),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        automaticallyImplyLeading: true,
        title: Text(isFreelancer ? 'Freelancer Sign In' : 'Client Sign In'),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: Card(
            elevation: 0,
            color: Colors.white.withOpacity(.06),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32), side: BorderSide(color: Colors.white.withOpacity(.1)) ),
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Hero(
                      tag: heroTag,
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: gradient,
                          boxShadow: [BoxShadow(color: Colors.black.withOpacity(.35), blurRadius: 20, offset: const Offset(0,14))],
                        ),
                        child: Icon(isFreelancer ? Icons.bolt_rounded : Icons.work_outline_rounded, size: 40, color: Colors.white),
                      ),
                    ),
                    const SizedBox(height: 28),
                    Text(isFreelancer ? 'Welcome back, creator!' : 'Welcome back, hirer!', style: GoogleFonts.poppins(fontSize: 26, fontWeight: FontWeight.w700, color: Colors.white)),
                    const SizedBox(height: 8),
                    Text('Sign in to continue.', style: GoogleFonts.poppins(fontSize: 14, color: Colors.white70)),
                    const SizedBox(height: 32),
                    TextFormField(
                      controller: _email,
                      style: const TextStyle(color: Colors.white),
                      decoration: _fieldDecoration('Email'),
                      validator: (v){
                        if (v == null || v.trim().isEmpty) return 'Email required';
                        if (!v.contains('@')) return 'Invalid email';
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),
                    TextFormField(
                      controller: _pwd,
                      style: const TextStyle(color: Colors.white),
                      obscureText: _obscure,
                      decoration: _fieldDecoration('Password').copyWith(
                        suffixIcon: IconButton(
                          onPressed: () => setState(()=> _obscure = !_obscure),
                          icon: Icon(_obscure ? Icons.visibility : Icons.visibility_off, color: Colors.white70),
                        ),
                      ),
                      validator: (v){
                        if (v == null || v.length < 4) return 'Min 4 chars';
                        return null;
                      },
                    ),
                    const SizedBox(height: 28),
                    SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          padding: EdgeInsets.zero,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                        ).merge(ButtonStyle(
                          elevation: const MaterialStatePropertyAll(0),
                          shadowColor: const MaterialStatePropertyAll(Colors.transparent),
                        )),
                        onPressed: _loading ? null : () => _submit(type),
                        child: Ink(
                          decoration: BoxDecoration(
                            gradient: gradient,
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: Center(
                            child: _loading
                              ? const SizedBox(height: 22, width: 22, child: CircularProgressIndicator(strokeWidth: 3, valueColor: AlwaysStoppedAnimation<Color>(Colors.white)))
                              : Text('Continue', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white)),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    TextButton(
                      onPressed: _loading ? null : () {},
                      child: Text('Forgot password?', style: GoogleFonts.poppins(color: Colors.white70)),
                    )
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  InputDecoration _fieldDecoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Colors.white70),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Colors.white38),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Colors.white),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Colors.redAccent),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Colors.redAccent),
      ),
      fillColor: Colors.white.withOpacity(.05),
      filled: true,
    );
  }
}

