import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/auth_service.dart';
import '../main.dart';

class ClientProfileScreen extends StatefulWidget {
  const ClientProfileScreen({super.key});
  static const route = '/clientProfile';

  @override
  State<ClientProfileScreen> createState() => _ClientProfileScreenState();
}

class _ClientProfileScreenState extends State<ClientProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _company = TextEditingController();
  final _website = TextEditingController();
  final _desc = TextEditingController();
  bool _loading = false;

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(()=> _loading = true);
    await Future.delayed(const Duration(milliseconds: 600));
    AuthService.instance.setClientProfile(displayName: _company.text.trim());
    if (mounted) {
      Navigator.of(context).pushNamedAndRemoveUntil(JobsPage.route, (_) => false);
    }
  }

  @override
  void dispose() { _company.dispose(); _website.dispose(); _desc.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Client Profile')),
      backgroundColor: Colors.black.withOpacity(.25),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 640),
          child: Card(
            color: Colors.white.withOpacity(.06),
            elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32), side: BorderSide(color: Colors.white.withOpacity(.08))),
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Form(
                key: _formKey,
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Set up your client profile', style: GoogleFonts.poppins(fontSize: 24, fontWeight: FontWeight.w700, color: Colors.white)),
                      const SizedBox(height: 6),
                      Text('Let freelancers learn about your brand.', style: GoogleFonts.poppins(fontSize: 14, color: Colors.white70)),
                      const SizedBox(height: 28),
                      _field(_company, 'Company / Display Name', validator: (v)=> v==null||v.trim().isEmpty? 'Required': null),
                      const SizedBox(height: 18),
                      _field(_website, 'Website (optional)', hint: 'https://'),
                      const SizedBox(height: 18),
                      _field(_desc, 'About / Description', maxLines: 4, hint: 'Describe your mission or hiring goals'),
                      const SizedBox(height: 30),
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton(
                          onPressed: _loading? null : _submit,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            padding: EdgeInsets.zero,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                          ),
                          child: Ink(
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(colors:[Color(0xFFEE7752), Color(0xFFE73C7E)]),
                              borderRadius: BorderRadius.circular(18),
                            ),
                            child: Center(
                              child: _loading ? const SizedBox(width:22,height:22,child:CircularProgressIndicator(strokeWidth:3,valueColor: AlwaysStoppedAnimation(Colors.white)))
                                : Text('Finish & Continue', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white)),
                            ),
                          ),
                        ),
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

  Widget _field(TextEditingController c, String label, {String? hint, String? Function(String?)? validator, int maxLines = 1}) {
    return TextFormField(
      controller: c,
      style: const TextStyle(color: Colors.white),
      maxLines: maxLines,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.white38),
        labelStyle: const TextStyle(color: Colors.white70),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Colors.white38)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Colors.white)),
        errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Colors.redAccent)),
        focusedErrorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Colors.redAccent)),
        fillColor: Colors.white.withOpacity(.05),
        filled: true,
      ),
    );
  }
}

