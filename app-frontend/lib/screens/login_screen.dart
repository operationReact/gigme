import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/auth_service.dart';
import 'freelancer_profile_screen.dart';
import 'client_profile_screen.dart';
import '../main.dart';
import '../widgets/animated_background.dart';
import '../widgets/sign_in_components.dart';
import 'dart:ui' as ui;
import 'register_freelancer.dart';
import 'register_client.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  static const route = '/login';

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _pwd = TextEditingController();
  bool _loading = false;
  bool _obscure = true;

  late AnimationController _shakeCtl; late Animation<double> _shakeAnim;
  enum _BtnState { idle, loading, success }
  _BtnState _btn = _BtnState.idle; bool _hoverPrimary=false;
  String? _error;

  UserType _typeFromArgs(BuildContext context) {
    final arg = ModalRoute.of(context)!.settings.arguments;
    if (arg is UserType) return arg;
    return UserType.freelancer;
  }

  @override
  void initState(){
    super.initState();
    _shakeCtl = AnimationController(vsync:this, duration: const Duration(milliseconds:460));
    _shakeAnim = CurvedAnimation(parent: _shakeCtl, curve: Curves.elasticIn);
  }
  void _triggerShake(){ _shakeCtl.forward(from:0); }

  Future<void> _submit(UserType type) async {
    if (!_formKey.currentState!.validate()) { setState(()=> _error='Please fix the errors'); _triggerShake(); return; }
    if(_btn==_BtnState.loading || _btn==_BtnState.success) return;
    setState(()=> {_btn=_BtnState.loading, _error=null});
    await Future.delayed(const Duration(milliseconds: 650)); // simulate call
    final auth = AuthService.instance;
    auth.login(type, name: _email.text.split('@').first);
    if(!mounted) return;
    setState(()=> _btn=_BtnState.success);
    await Future.delayed(const Duration(milliseconds: 520));
    if(!mounted) return;
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
  void dispose() { _email.dispose(); _pwd.dispose(); _shakeCtl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final type = _typeFromArgs(context);
    final isFreelancer = type == UserType.freelancer;
    final gradient = const LinearGradient(colors: [Color(0xFF0D9488), Color(0xFF2563EB)]);
    final cs = Theme.of(context).colorScheme;

    final pwdStrength = _strengthFor(_pwd.text); final pwdStrengthLabel=_strengthLabel(pwdStrength);

    return Scaffold(
      body: AnimatedSignInBackground(
        child: Container(
          decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topLeft,end: Alignment.bottomRight, colors:[cs.secondary.withOpacity(.25), cs.tertiary.withOpacity(.25)])),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 600),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 34),
                child: AnimatedBuilder(
                  animation: _shakeCtl,
                  builder:(c,child){ final dx=_shakeCtl.isAnimating? (1-_shakeAnim.value)*14*(_shakeAnim.value%0.2>0.1?-1:1):0; return Transform.translate(offset: Offset(dx.toDouble(),0), child: child); },
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(30),
                    child: BackdropFilter(
                      filter: ui.ImageFilter.blur(sigmaX: 24, sigmaY: 24),
                      child: Container(
                        decoration: BoxDecoration(color: Colors.white.withOpacity(0.08), borderRadius: BorderRadius.circular(30), border: Border.all(color: Colors.white.withOpacity(0.16))),
                        padding: const EdgeInsets.fromLTRB(36,40,36,44),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Row(children:[
                                Container(height:54,width:54, decoration: BoxDecoration(gradient: LinearGradient(colors:[cs.secondary, cs.tertiary]), shape: BoxShape.circle, boxShadow:[BoxShadow(color: cs.secondary.withOpacity(.45), blurRadius:20, offset: const Offset(0,10))]), child: Icon(isFreelancer? Icons.bolt_rounded: Icons.work_outline_rounded, color: Colors.white, size:30)),
                                const SizedBox(width:18),
                                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children:[
                                  Text('Gigmework', style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Colors.white, fontWeight: FontWeight.w700)),
                                  const SizedBox(height:4),
                                  Text(isFreelancer? 'Find gigs, grow your career' : 'Find talent, scale your team', style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.w500)),
                                ]))
                              ]),
                              const SizedBox(height: 34),
                              TextFormField(
                                controller: _email,
                                style: const TextStyle(color: Colors.black87),
                                decoration: signInInputDecoration(context, label: 'Email', hint: 'you@example.com', icon: Icons.email_outlined, errorText: _error),
                                validator: (v){ if (v==null || v.trim().isEmpty) return 'Email required'; if(!v.contains('@')) return 'Invalid email'; return null; },
                                onChanged: (_){ if(_error!=null) setState(()=> _error=null); },
                              ),
                              const SizedBox(height: 20),
                              TextFormField(
                                controller: _pwd,
                                style: const TextStyle(color: Colors.black87),
                                obscureText: _obscure,
                                decoration: signInInputDecoration(context, label: 'Password', icon: Icons.lock_outline, suffix: Row(mainAxisSize: MainAxisSize.min, children:[
                                  HoverLink(text: 'Forgot?', onTap: ()=> Navigator.of(context).pushNamed('/forgot-password'), fontSize: 12),
                                  AnimatedSwitcher(duration: const Duration(milliseconds:260), transitionBuilder: (child,anim)=> RotationTransition(turns: anim, child: child), child: IconButton(key: ValueKey(_obscure), onPressed: ()=> setState(()=> _obscure=!_obscure), icon: Icon(_obscure? Icons.visibility: Icons.visibility_off)))
                                ])),
                                validator: (v){ if (v==null || v.length<4) return 'Min 4 chars'; return null; },
                                onChanged: (_){ if(_error!=null) setState(()=> _error=null); setState((){}); },
                              ),
                              if(_pwd.text.isNotEmpty) ...[
                                const SizedBox(height:12),
                                PasswordStrengthMeter(strength: pwdStrength, label: pwdStrengthLabel),
                              ],
                              const SizedBox(height: 28),
                              SignInPrimaryButton(
                                state: _btn==_BtnState.idle? SignInButtonState.idle: (_btn==_BtnState.loading? SignInButtonState.loading: SignInButtonState.success),
                                onPressed: _btn==_BtnState.idle? ()=> _submit(type): null,
                                label: 'Continue',
                                icon: Icons.login,
                                height: 56,
                              ),
                              const SizedBox(height: 26),
                              Row(children:[
                                Expanded(child: Divider(color: Colors.black.withOpacity(0.15), thickness:1)),
                                const SizedBox(width:12),
                                const Text('or continue with', style: TextStyle(fontSize:12, color: Colors.black54)),
                                const SizedBox(width:12),
                                Expanded(child: Divider(color: Colors.black.withOpacity(0.15), thickness:1)),
                              ]),
                              const SizedBox(height: 20),
                              const SocialLoginButtons(),
                              const SizedBox(height: 24),
                              Wrap(alignment: WrapAlignment.center, spacing:6, children:[
                                const Text('Need an account?', style: TextStyle(color: Colors.black54)),
                                if(isFreelancer) HoverLink(text: 'Create freelancer account', onTap: ()=> Navigator.of(context).pushNamed(RegisterFreelancerPage.routeName), fontSize: 14, fontWeight: FontWeight.w600) else HoverLink(text: 'Create client account', onTap: ()=> Navigator.of(context).pushNamed(RegisterClientPage.routeName), fontSize: 14, fontWeight: FontWeight.w600)
                              ])
                            ],
                          ),
                        ),
                      ),
                    ),
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

  // add password strength helpers
  double _strengthFor(String p){ if(p.isEmpty) return 0; int score=0; if(p.length>=8) score++; if(RegExp(r'[a-z]').hasMatch(p)) score++; if(RegExp(r'[A-Z]').hasMatch(p)) score++; if(RegExp(r'[0-9]').hasMatch(p)) score++; if(RegExp(r'[^A-Za-z0-9]').hasMatch(p)) score++; return score/5.0; }
  String _strengthLabel(double s){ if(s>=0.9) return 'Very strong'; if(s>=0.75) return 'Strong'; if(s>=0.5) return 'Medium'; if(s>=0.3) return 'Weak'; return 'Very weak'; }
}
