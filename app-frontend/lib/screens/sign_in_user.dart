import 'package:flutter/material.dart';
import 'profile_freelancer.dart';
import 'register_freelancer.dart';
import 'dart:ui' as ui;
import 'freelancer_home.dart';
import '../api/auth_api.dart';
import '../services/session_service.dart';
import '../api/profile_api.dart';
import '../services/preferences_service.dart';
import 'forgot_password.dart';
import '../widgets/animated_background.dart';
import '../widgets/sign_in_components.dart';

class SignInUserPage extends StatefulWidget {
  static const routeName = '/signin/user';
  const SignInUserPage({super.key});

  @override
  State<SignInUserPage> createState() => _SignInUserPageState();
}

enum _BtnState { idle, loading, success }

class _SignInUserPageState extends State<SignInUserPage> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscure = true;
  bool _remember = true;
  String? _authError;
  late AnimationController _shakeCtl;
  late Animation<double> _shakeAnim;
  String? _emailAuthError; // highlight email as well
  _BtnState _btnState = _BtnState.idle;

  @override
  void initState() {
    super.initState();
    _shakeCtl = AnimationController(vsync: this, duration: const Duration(milliseconds: 450));
    _shakeAnim = CurvedAnimation(parent: _shakeCtl, curve: Curves.elasticIn);
    // load remembered email
    PreferencesService.instance.loadRemembered().then((data) {
      final (remember, email, role) = data;
      if (!mounted) return;
      setState(() {
        _remember = remember;
        if (remember && email != null) _emailController.text = email;
      });
    });
  }

  @override
  void dispose() {
    _shakeCtl.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _triggerShake() { _shakeCtl.forward(from: 0); }

  void _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_btnState == _BtnState.loading || _btnState == _BtnState.success) return;
    setState(() { _btnState = _BtnState.loading; _authError = null; _emailAuthError = null; });
    final authApi = AuthApi();
    try {
      final user = await authApi.login(email: _emailController.text.trim(), password: _passwordController.text);
      SessionService.instance.setUser(user);
      await PreferencesService.instance.saveUser(user);
      if (!mounted) return;
      // persist remember
      await PreferencesService.instance.saveRemembered(remember: _remember, email: _remember ? _emailController.text.trim() : null, role: _remember ? 'FREELANCER' : null);
      setState(()=> _btnState = _BtnState.success);
      await Future.delayed(const Duration(milliseconds: 480));
      if (!mounted) return;
      if (!user.hasFreelancerProfile) {
        Navigator.of(context).pushReplacementNamed('/freelancerProfile');
      } else {
        // Navigate to freelancer home instead of profile page for a fuller dashboard experience
        Navigator.of(context).pushReplacementNamed(FreelancerHomePage.routeName);
      }
    } catch (e) {
      if (!mounted) return;
      final msg = e.toString().toLowerCase();
      setState(() {
        if (msg.contains('invalid credentials') || msg.contains('unauthorized')) {
          _authError = 'Invalid email or password.';
          _emailAuthError = 'Invalid email or password.';
        } else {
          _authError = 'Login failed. Please try again.';
        }
        _btnState = _BtnState.idle;
      });
      _triggerShake();
    }
  }

  double _strengthFor(String p){
    if(p.isEmpty) return 0; int score=0; if(p.length>=8) score++; if(RegExp(r'[a-z]').hasMatch(p)) score++; if(RegExp(r'[A-Z]').hasMatch(p)) score++; if(RegExp(r'[0-9]').hasMatch(p)) score++; if(RegExp(r'[^A-Za-z0-9]').hasMatch(p)) score++; return score/5.0; }
  String _strengthLabel(double s){ if(s>=0.9) return 'Very strong'; if(s>=0.75) return 'Strong'; if(s>=0.5) return 'Medium'; if(s>=0.3) return 'Weak'; return 'Very weak'; }
  Color _strengthColor(double s, BuildContext ctx){ final cs=Theme.of(ctx).colorScheme; if(s>=0.75) return Colors.green; if(s>=0.5) return Colors.amber; if(s>=0.3) return cs.tertiary; return Colors.redAccent; }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final strength = _strengthFor(_passwordController.text);
    final strengthLabel = _strengthLabel(strength);
    return Scaffold(
      body: AnimatedSignInBackground(
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(begin: Alignment.topLeft,end: Alignment.bottomRight,colors:[cs.secondary.withOpacity(0.25), cs.tertiary.withOpacity(0.25)]),
          ),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 640),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 32),
                child: AnimatedBuilder(
                  animation: _shakeCtl,
                  builder: (context, child) {
                    final dx = _shakeCtl.isAnimating ? (1 - _shakeAnim.value) * 14 * (_shakeAnim.value % 0.2 > 0.1 ? -1 : 1) : 0;
                    return Transform.translate(offset: Offset(dx.toDouble(), 0), child: child);
                  },
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(28),
                    child: BackdropFilter(
                      filter: ui.ImageFilter.blur(sigmaX: 24, sigmaY: 24),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.82),
                          borderRadius: BorderRadius.circular(28),
                          border: Border.all(color: Colors.white.withOpacity(0.18)),
                          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.25), blurRadius: 38, spreadRadius: 4, offset: const Offset(0,18))],
                        ),
                        padding: const EdgeInsets.fromLTRB(32, 34, 32, 40),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              // header
                              Row(children:[
                                Container(height:52,width:52,decoration: BoxDecoration(gradient: LinearGradient(colors:[cs.secondary, cs.tertiary]), shape: BoxShape.circle, boxShadow:[BoxShadow(color: cs.secondary.withOpacity(0.4), blurRadius: 18, offset: const Offset(0,8))]), child: const Icon(Icons.workspaces_outline, color: Colors.white)),
                                const SizedBox(width:16),
                                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children:[
                                  Text('Gigmework', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700, color: Colors.black87)),
                                  const SizedBox(height:4),
                                  const Text('Find gigs, grow your career', style: TextStyle(color: Colors.black54, fontSize: 14, fontWeight: FontWeight.w600)),
                                ]))
                              ]),
                              const SizedBox(height: 32),
                              TextFormField(
                                controller: _emailController,
                                autofillHints: const [AutofillHints.username, AutofillHints.email],
                                decoration: signInInputDecoration(context, label: 'Email', hint: 'you@example.com', icon: Icons.email_outlined, errorText: _emailAuthError),
                                keyboardType: TextInputType.emailAddress,
                                textInputAction: TextInputAction.next,
                                validator: (v) => (v == null || v.isEmpty || !v.contains('@')) ? 'Enter a valid email' : null,
                                onChanged: (_) { if (_authError != null || _emailAuthError != null) setState(() { _authError = null; _emailAuthError = null; }); },
                              ),
                              const SizedBox(height: 18),
                              TextFormField(
                                controller: _passwordController,
                                autofillHints: const [AutofillHints.password],
                                obscureText: _obscure,
                                decoration: signInInputDecoration(context, label: 'Password', icon: Icons.lock_outline, errorText: _authError, suffix: Row(mainAxisSize: MainAxisSize.min, children:[
                                  TextButton(onPressed: () => Navigator.of(context).pushNamed(ForgotPasswordPage.routeName), child: const Text('Forgot?', style: TextStyle(fontSize:12))),
                                  AnimatedSwitcher(duration: const Duration(milliseconds: 260), transitionBuilder: (child, anim)=> RotationTransition(turns: anim, child: child), child: IconButton(key: ValueKey(_obscure), icon: Icon(_obscure? Icons.visibility: Icons.visibility_off), onPressed: ()=> setState((){ _obscure = !_obscure; }), tooltip: _obscure? 'Show password':'Hide password')),
                                ])),
                                textInputAction: TextInputAction.done,
                                onFieldSubmitted: (_) => _submit(),
                                onChanged: (_) { if (_authError != null) setState(() { _authError = null; }); setState((){}); },
                                validator: (v) => (v == null || v.length < 6) ? 'Password must be at least 6 characters' : null,
                              ),
                              if(_passwordController.text.isNotEmpty) ...[
                                const SizedBox(height:10),
                                PasswordStrengthMeter(strength: strength, label: strengthLabel),
                              ],
                              const SizedBox(height: 12),
                              CheckboxListTile(value: _remember, onChanged: (v)=> setState(()=> _remember = v??true), controlAffinity: ListTileControlAffinity.leading, title: const Text('Remember me', style: TextStyle(color: Colors.black87)), contentPadding: EdgeInsets.zero),
                              const SizedBox(height: 12),
                              SignInPrimaryButton(
                                state: _btnState==_BtnState.idle? SignInButtonState.idle: (_btnState==_BtnState.loading? SignInButtonState.loading: SignInButtonState.success),
                                onPressed: _submit,
                                label: 'Sign in',
                                icon: Icons.login,
                              ),
                              const SizedBox(height: 22),
                              Row(children:[
                                Expanded(child: Divider(color: Colors.black.withOpacity(0.15), thickness: 1)),
                                const SizedBox(width:12),
                                const Text('or continue with', style: TextStyle(fontSize:12, color: Colors.black54)),
                                const SizedBox(width:12),
                                Expanded(child: Divider(color: Colors.black.withOpacity(0.15), thickness: 1)),
                              ]),
                              const SizedBox(height: 18),
                              const SocialLoginButtons(),
                              const SizedBox(height: 20),
                              Row(mainAxisAlignment: MainAxisAlignment.end, children:[
                                HoverLink(text: 'Forgot password?', onTap: ()=> Navigator.of(context).pushNamed(ForgotPasswordPage.routeName), fontSize: 13),
                              ]),
                              const SizedBox(height: 12),
                              Wrap(alignment: WrapAlignment.center, spacing: 6, children: [
                                const Text('Need an account?', style: TextStyle(color: Colors.black54)),
                                HoverLink(text: 'Create account', onTap: () => Navigator.of(context).pushNamed(RegisterFreelancerPage.routeName), fontSize: 14, fontWeight: FontWeight.w600),
                              ]),
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
      ),
    );
  }
}
