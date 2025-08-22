import 'dart:async';
import 'dart:ui' as ui;
import 'dart:math' as math; // moved from bottom
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../api/auth_api.dart';

/// A richer multi-step Forgot / Reset Password flow.
/// Steps:
/// 1. Collect email
/// 2. Email sent confirmation + token entry (if user already has token) OR "I have a token" button
/// 3. Token + new password form with strength + requirements
/// 4. Success screen with CTA back to Sign in
class ForgotPasswordPage extends StatefulWidget {
  static const routeName = '/forgot-password';
  const ForgotPasswordPage({super.key});
  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

enum _FPStage { request, sent, reset, success }

class _ForgotPasswordPageState extends State<ForgotPasswordPage> with TickerProviderStateMixin {
  _FPStage _stage = _FPStage.request;
  final _emailCtl = TextEditingController();
  final _tokenCtl = TextEditingController();
  final _passCtl = TextEditingController();
  final _emailFormKey = GlobalKey<FormState>();
  final _resetFormKey = GlobalKey<FormState>();
  bool _submitting = false;
  String? _error;
  double _strength = 0;
  late final AnimationController _bgCtl;
  // New animation / interaction controllers
  late final AnimationController _planeCtl; // send animation
  late final AnimationController _shakeCtl; // shake on error
  final FocusNode _emailFocus = FocusNode();
  bool _emailValid = true;

  @override
  void initState() {
    super.initState();
    _bgCtl = AnimationController(vsync: this, duration: const Duration(seconds: 18))..repeat();
    _planeCtl = AnimationController(vsync: this, duration: const Duration(milliseconds: 700));
    _shakeCtl = AnimationController(vsync: this, duration: const Duration(milliseconds: 500));
    _emailCtl.addListener(_onEmailChanged);
    _emailFocus.addListener(()=> setState((){}));
    // Web deep-link token prefill (supports /forgot-password?token=...)
    if (kIsWeb) {
      final uri = Uri.base;
      final tk = uri.queryParameters['token'];
      if (tk != null && tk.isNotEmpty) {
        _tokenCtl.text = tk;
        _stage = _FPStage.reset;
      }
      final email = uri.queryParameters['email'];
      if (email != null) _emailCtl.text = email;
    }
  }

  @override
  void dispose() {
    _bgCtl.dispose();
    _planeCtl.dispose();
    _shakeCtl.dispose();
    _emailCtl.removeListener(_onEmailChanged);
    _emailCtl.dispose();
    _tokenCtl.dispose();
    _passCtl.dispose();
    _emailFocus.dispose();
    super.dispose();
  }

  // ---------------- Password Strength Utilities ----------------
  double _calcStrength(String p) {
    if (p.isEmpty) return 0;
    int score = 0;
    if (p.length >= 8) score++;
    if (RegExp(r'[a-z]').hasMatch(p)) score++;
    if (RegExp(r'[A-Z]').hasMatch(p)) score++;
    if (RegExp(r'[0-9]').hasMatch(p)) score++;
    if (RegExp(r'[^A-Za-z0-9]').hasMatch(p)) score++;
    return score / 5.0;
  }
  String _strengthLabel(double s){
    if (s >= .9) return 'Very strong';
    if (s >= .75) return 'Strong';
    if (s >= .5) return 'Medium';
    if (s >= .3) return 'Weak';
    return 'Very weak';
  }
  Color _strengthColor(double s, ColorScheme cs){
    if (s >= .75) return Colors.green;
    if (s >= .5) return Colors.amber;
    if (s >= .3) return cs.tertiary;
    return Colors.redAccent;
  }

  // ---------------- New Helpers ----------------
  bool _isValidEmail(String v){
    return RegExp(r'^.+@.+\..+').hasMatch(v.trim());
  }
  void _onEmailChanged(){
    final nowValid = _isValidEmail(_emailCtl.text);
    if(nowValid != _emailValid){
      setState(()=> _emailValid = nowValid);
    }
    if(_error!=null){
      setState(()=> _error = null); // clear error as user edits
    }
  }
  void _triggerShake(){
    _shakeCtl.forward(from:0);
  }

  // ---------------- Actions ----------------
  Future<void> _submitEmail() async {
    if(!_emailFormKey.currentState!.validate()) return;
    if(!_emailValid) return;
    setState(()=> {_submitting=true,_error=null});
    _planeCtl.forward(from:0); // animate plane
    try {
      await AuthApi().forgotPassword(_emailCtl.text.trim());
      // brief delay to let animation play
      await Future.delayed(const Duration(milliseconds: 400));
      if(mounted) setState(()=> _stage = _FPStage.sent);
    } catch(e) {
      if(mounted){
        setState(()=> _error = e.toString());
        _triggerShake();
      }
    }
    finally { if(mounted) setState(()=> _submitting=false); }
  }

  Future<void> _submitReset() async {
    if(!_resetFormKey.currentState!.validate()) return;
    if(_strength < 0.5) return; // require >= Medium
    setState(()=> {_submitting=true,_error=null});
    try {
      await AuthApi().resetPassword(token: _tokenCtl.text.trim(), newPassword: _passCtl.text);
      setState(()=> _stage = _FPStage.success);
    } catch(e){ setState(()=> _error = e.toString()); }
    finally { if(mounted) setState(()=> _submitting=false); }
  }

  // ---------------- UI Builders ----------------
  Widget _buildEmailStage(ColorScheme cs){
    // Animated shake offset
    final double shake = _shakeCtl.isAnimating ? (math.sin(_shakeCtl.value * 20) * (1 - _shakeCtl.value) * 12) : 0; // helper below
    return Transform.translate(
      offset: Offset(shake,0),
      child: Form(
        key: _emailFormKey,
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children:[
          // Heading with stronger hierarchy
            Text('Forgot your password?', style: Theme.of(context).textTheme.headlineSmall?.copyWith(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 24)),
            const SizedBox(height:8),
            Opacity(opacity: .8, child: Text('Enter the email associated with your account and we\'ll send a reset link / token.', style: const TextStyle(color: Colors.white))),
            const SizedBox(height:24),
            TextFormField(
              controller: _emailCtl,
              focusNode: _emailFocus,
              decoration: InputDecoration(
                labelText:'Email',
                prefixIcon: _AnimatedEmailIcon(focus: _emailFocus, valid: _emailValid),
                errorText: _emailValid? null : 'Invalid email',
                filled: true,
                fillColor: Colors.white.withOpacity(.06),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(18), borderSide: BorderSide(color: Colors.white24)),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(18), borderSide: BorderSide(color: Colors.tealAccent.shade200, width: 1.6)),
                errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(18), borderSide: const BorderSide(color: Colors.redAccent)),
                focusedErrorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(18), borderSide: const BorderSide(color: Colors.redAccent, width: 1.6)),
              ),
              autofillHints: const [AutofillHints.email,AutofillHints.username],
              validator: (v)=> v==null || v.isEmpty? 'Enter email' : (!_isValidEmail(v)? 'Invalid email' : null),
              textInputAction: TextInputAction.done,
              onFieldSubmitted: (_)=> _submitEmail(),
            ),
            if(_error!=null) Padding(padding: const EdgeInsets.only(top:12), child: Text(_error!, style: const TextStyle(color: Colors.redAccent))),
            const SizedBox(height:28),
            SizedBox(
              height: 56,
              child: _GradientActionButton(
                onPressed: _submitting? null : _submitEmail,
                loading: _submitting,
                loadingLabel: 'Sending...',
                label: 'Send reset email',
                animation: _planeCtl,
              ),
            ),
            const SizedBox(height:12),
            TextButton(onPressed: ()=> Navigator.pop(context), child: const Text('Back to sign in')),
          ]),
      ),
    );
  }

  Widget _buildSentStage(ColorScheme cs){
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children:[
      const _SuccessCheck(),
      const SizedBox(height:16),
      Text('Check your email', style: Theme.of(context).textTheme.headlineSmall?.copyWith(color: Colors.white, fontWeight: FontWeight.w600)),
      const SizedBox(height:8),
      Opacity(opacity:.8, child: Text('If an account exists for ${_emailCtl.text.trim()}, we\'ve sent password reset instructions.', style: const TextStyle(color: Colors.white))),
      const SizedBox(height:24),
      Wrap(spacing:12, runSpacing:12, children:[
        ElevatedButton.icon(onPressed: ()=> setState(()=> _stage = _FPStage.reset), icon: const Icon(Icons.vpn_key_outlined), label: const Text('I have a token')),
        OutlinedButton.icon(onPressed: _submitting? null : _submitEmail, icon: const Icon(Icons.refresh), label: Text(_submitting? 'Resending...' : 'Resend')),
        TextButton(onPressed: ()=> Navigator.pop(context), child: const Text('Back')),
      ])
    ]);
  }

  Widget _buildResetStage(ColorScheme cs){
    return Form(
      key: _resetFormKey,
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children:[
        Text('Enter token & new password', style: Theme.of(context).textTheme.headlineSmall?.copyWith(color: Colors.white, fontWeight: FontWeight.w600)),
        const SizedBox(height:8),
        Text('Paste the token from the email and choose a strong password.', style: const TextStyle(color: Colors.white70)),
        const SizedBox(height:20),
        TextFormField(
          controller: _tokenCtl,
          decoration: const InputDecoration(labelText:'Token', prefixIcon: Icon(Icons.confirmation_number_outlined)),
          validator:(v)=> v==null||v.isEmpty? 'Token required': null,
          textInputAction: TextInputAction.next,
        ),
        const SizedBox(height:16),
        StatefulBuilder(builder:(ctx, localSet){
          return Column(crossAxisAlignment: CrossAxisAlignment.start, children:[
            TextFormField(
              controller: _passCtl,
              decoration: const InputDecoration(labelText:'New Password', prefixIcon: Icon(Icons.lock_outline)),
              obscureText: true,
              onChanged: (_){
                final val = _calcStrength(_passCtl.text);
                _strength = val; localSet((){});
              },
              validator:(v)=> v==null|| v.length<6? 'Min 6 chars': null,
            ),
            const SizedBox(height:10),
            LinearProgressIndicator(value: _strength, minHeight: 6, backgroundColor: Colors.white12, valueColor: AlwaysStoppedAnimation(_strengthColor(_strength, cs))),
            const SizedBox(height:6),
            Text('${_strengthLabel(_strength)} password', style: TextStyle(fontSize:12,color: _strengthColor(_strength, cs))),
            const SizedBox(height:10),
            _RequirementChecklist(strength: _strength, password: _passCtl.text, colorScheme: cs),
          ]);
        }),
        if(_error!=null) Padding(padding: const EdgeInsets.only(top:12), child: Text(_error!, style: const TextStyle(color: Colors.redAccent))),
        const SizedBox(height:28),
        SizedBox(
          height: 52,
          child: ElevatedButton.icon(
            onPressed: _submitting? null : _submitReset,
            icon: _submitting? const SizedBox(width:20,height:20,child:CircularProgressIndicator(strokeWidth:2,color: Colors.white)) : const Icon(Icons.check_circle_outline),
            label: Text(_submitting? 'Updating...' : 'Reset password'),
          ),
        ),
        const SizedBox(height:12),
        TextButton(onPressed: ()=> setState(()=> _stage = _FPStage.request), child: const Text('Start over')),
      ]),
    );
  }

  Widget _buildSuccessStage(ColorScheme cs){
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children:[
      const Icon(Icons.celebration_outlined, color: Colors.lightGreenAccent, size:72),
      const SizedBox(height:18),
      Text('Password updated', style: Theme.of(context).textTheme.headlineSmall?.copyWith(color: Colors.white, fontWeight: FontWeight.w600)),
      const SizedBox(height:8),
      const Text('You can now sign in with your new password.', style: TextStyle(color: Colors.white70)),
      const SizedBox(height:30),
      SizedBox(height:52, child: ElevatedButton.icon(onPressed: ()=> Navigator.pop(context), icon: const Icon(Icons.login), label: const Text('Back to Sign in'))),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Recover Account'), backgroundColor: Colors.transparent, foregroundColor: Colors.white, elevation:0),
      extendBodyBehindAppBar: true,
      body: AnimatedBuilder(
        animation: _bgCtl,
        builder: (context, _) {
          // Multi-stop animated gradient
          final t = _bgCtl.value;
            final Alignment begin = Alignment(-0.8 + 0.6 * math.sin(t*2*3.1415), -1 + 0.4 * math.cos(t*2*3.1415));
            final Alignment end = Alignment(0.8 + 0.6 * math.cos(t*2*3.1415), 1 + 0.4 * math.sin(t*2*3.1415));
          return Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: begin,
                end: end,
                colors: [
                  Color.lerp(const Color(0xFF6D5DFB), const Color(0xFF4A8CFF), (math.sin(t*3.2)+1)/2)!,
                  const Color(0xFF24C6DC),
                  Color.lerp(const Color(0xFF24C6DC), const Color(0xFF514A9D), (math.cos(t*2.7)+1)/2)!,
                ],
              ),
            ),
            child: Center(
              child: LayoutBuilder(builder:(ctx, constraints){
                final wide = constraints.maxWidth > 900;
                final cardChild = ClipRRect(
                  borderRadius: BorderRadius.circular(28),
                  child: BackdropFilter(
                    filter: ui.ImageFilter.blur(sigmaX: 14, sigmaY: 14),
                    child: Container(
                      padding: const EdgeInsets.all(32),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(.07),
                        borderRadius: BorderRadius.circular(28),
                        border: Border.all(color: Colors.white.withOpacity(.15)),
                        boxShadow: [
                          BoxShadow(color: Colors.black.withOpacity(.35), blurRadius: 40, spreadRadius: -8, offset: const Offset(0,18)),
                          BoxShadow(color: Colors.white.withOpacity(.05), blurRadius: 6, spreadRadius: 2),
                        ],
                      ),
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 400),
                        transitionBuilder: (child, anim)=> FadeTransition(opacity: anim, child: child),
                        child: SingleChildScrollView(
                          key: ValueKey(_stage),
                          child: _buildCurrentStage(cs),
                        ),
                      ),
                    ),
                  ),
                );
                if(!wide){
                  return ConstrainedBox(constraints: const BoxConstraints(maxWidth: 640), child: cardChild);
                }
                return Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children:[
                    Flexible(
                      child: Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: _IllustrationPanel(animation: _bgCtl),
                      ),
                    ),
                    ConstrainedBox(constraints: const BoxConstraints(maxWidth: 560), child: cardChild),
                  ],
                );
              }),
            ),
          );
        },
      ),
    );
  }

  Widget _buildCurrentStage(ColorScheme cs){
    switch(_stage){
      case _FPStage.request: return _buildEmailStage(cs);
      case _FPStage.sent: return _buildSentStage(cs);
      case _FPStage.reset: return _buildResetStage(cs);
      case _FPStage.success: return _buildSuccessStage(cs);
    }
  }
}

class _RequirementChecklist extends StatelessWidget {
  final double strength; final String password; final ColorScheme colorScheme;
  const _RequirementChecklist({required this.strength, required this.password, required this.colorScheme});
  bool get _len => password.length >= 8;
  bool get _lower => RegExp(r'[a-z]').hasMatch(password);
  bool get _upper => RegExp(r'[A-Z]').hasMatch(password);
  bool get _num => RegExp(r'[0-9]').hasMatch(password);
  bool get _sym => RegExp(r'[^A-Za-z0-9]').hasMatch(password);
  Color _c(bool ok) => ok? Colors.greenAccent : colorScheme.error;
  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children:[
      Wrap(spacing: 12, runSpacing: 6, children: [
        _chip('8+ chars', _len),
        _chip('lowercase', _lower),
        _chip('UPPERCASE', _upper),
        _chip('number', _num),
        _chip('symbol', _sym),
      ])
    ]);
  }
  Widget _chip(String label, bool ok){
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.symmetric(horizontal:10, vertical:6),
      decoration: BoxDecoration(
        color: (ok? Colors.greenAccent : Colors.white24).withOpacity(.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: ok? Colors.greenAccent : Colors.white30),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children:[
        Icon(ok? Icons.check_circle : Icons.radio_button_unchecked, size:14, color: ok? Colors.greenAccent : Colors.white54),
        const SizedBox(width:4),
        Text(label, style: TextStyle(fontSize:12, color: ok? Colors.greenAccent : Colors.white70)),
      ]),
    );
  }
}

// ---------------- Additional UI Components ----------------
class _AnimatedEmailIcon extends StatefulWidget {
  final FocusNode focus; final bool valid;
  const _AnimatedEmailIcon({required this.focus, required this.valid});
  @override
  State<_AnimatedEmailIcon> createState() => _AnimatedEmailIconState();
}
class _AnimatedEmailIconState extends State<_AnimatedEmailIcon> with SingleTickerProviderStateMixin {
  late final AnimationController _ctl;
  @override
  void initState(){
    super.initState();
    _ctl = AnimationController(vsync: this, duration: const Duration(milliseconds: 550), lowerBound: 0, upperBound: 1)..forward();
    widget.focus.addListener(()=> setState((){}));
  }
  @override
  void dispose(){ _ctl.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) {
    final focused = widget.focus.hasFocus;
    return AnimatedScale(
      scale: focused? 1.15 : 1,
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOutBack,
      child: AnimatedRotation(
        turns: focused? 0.02 : 0,
        duration: const Duration(milliseconds: 300),
        child: Icon(widget.valid? Icons.alternate_email_rounded : Icons.error_outline, color: widget.valid? Colors.tealAccent : Colors.redAccent),
      ),
    );
  }
}

class _GradientActionButton extends StatelessWidget {
  final VoidCallback? onPressed; final bool loading; final String label; final String loadingLabel; final AnimationController animation;
  const _GradientActionButton({required this.onPressed, required this.loading, required this.label, required this.loadingLabel, required this.animation});
  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null;
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 220),
      opacity: enabled? 1: .6,
      child: InkWell(
        onTap: enabled? onPressed: null,
        borderRadius: BorderRadius.circular(20),
        child: Ink(
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors:[Color(0xFF00C6A7), Color(0xFF1E9AFE)]),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(.3), blurRadius: 16, offset: const Offset(0,8))],
          ),
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal:20, vertical:12),
              child: Row(mainAxisSize: MainAxisSize.min, children:[
                if(loading)
                  const SizedBox(width:22,height:22, child: CircularProgressIndicator(strokeWidth:2.4, valueColor: AlwaysStoppedAnimation(Colors.white)))
                else
                  AnimatedBuilder(
                    animation: animation,
                    builder:(ctx,_) {
                      final v = animation.value;
                      final dx = Maths.lerp(0, 36, Curves.easeIn.transform(v));
                      final opacity = (1 - v*1.1).clamp(0.0,1.0);
                      return SizedBox(width: 28, height:28, child: Stack(children:[
                        Opacity(opacity: opacity, child: Transform.translate(offset: Offset(dx, -v*14), child: Icon(Icons.send_rounded, color: Colors.white)) ),
                        if(v> .65) Center(child: Icon(Icons.check_circle_outline, color: Colors.white.withOpacity((v-.65)/.35)))
                      ]));
                    },
                  ),
                const SizedBox(width:12),
                Text(loading? loadingLabel : label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize:16)),
              ]),
            ),
          ),
        ),
      ),
    );
  }
}

class _SuccessCheck extends StatefulWidget {
  const _SuccessCheck();
  @override
  State<_SuccessCheck> createState() => _SuccessCheckState();
}
class _SuccessCheckState extends State<_SuccessCheck> with SingleTickerProviderStateMixin {
  late final AnimationController _ctl;
  @override
  void initState(){
    super.initState();
    _ctl = AnimationController(vsync: this, duration: const Duration(milliseconds: 800))..forward();
  }
  @override
  void dispose(){ _ctl.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctl,
      builder:(ctx,_) {
        final v = Curves.easeOutBack.transform(_ctl.value);
        return Transform.scale(scale: v, child: Icon(Icons.mark_email_read_outlined, color: Colors.greenAccent.withOpacity(v.clamp(0,1)), size: 64));
      },
    );
  }
}

class _IllustrationPanel extends StatelessWidget {
  final Animation<double> animation;
  const _IllustrationPanel({required this.animation});
  @override
  Widget build(BuildContext context) {
    final t = animation.value;
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children:[
        Container(
          height: 180, width: 180,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: SweepGradient(colors:[
              const Color(0xFF00C6A7).withOpacity(.7),
              const Color(0xFF1E9AFE).withOpacity(.7),
              const Color(0xFF6D5DFB).withOpacity(.7),
              const Color(0xFF00C6A7).withOpacity(.7),
            ], stops: const [0, .33, .66, 1], transform: GradientRotation(t*6.2831)),
            boxShadow:[BoxShadow(color: Colors.black.withOpacity(.3), blurRadius: 32, spreadRadius: -6)]
          ),
          child: const Center(child: Icon(Icons.lock_reset_rounded, color: Colors.white, size: 96)),
        ),
        const SizedBox(height: 28),
        Text('Secure Reset', style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Colors.white, fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        Opacity(opacity:.8, child: const Text('We\'ll guide you through recovering access safely.', textAlign: TextAlign.center, style: TextStyle(color: Colors.white))),
      ],
    );
  }
}

// ---------------- Math helper ----------------
class Maths {
  static double sin(double v) => math.sin(v);
  static double cos(double v) => math.cos(v);
  static double lerp(double a, double b, double t) => a + (b-a)*t;
}
