import 'dart:async';
import 'dart:ui' as ui;
import 'dart:math' as math; // moved from bottom
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../api/auth_api.dart';

// Brand palette & typography colors
const _kTeal = Color(0xFF00C2A8);
const _kIndigo = Color(0xFF3B82F6);
const _kViolet = Color(0xFF7C3AED);
const _kHeading = Color(0xFF111827);
const _kBody = Color(0xFF374151);
const _kMuted = Color(0xFF6B7280);

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
    setState(() { _submitting=true; _error=null; });
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
    setState(() { _submitting=true; _error=null; });
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
          Text('Forgot your password?', style: Theme.of(context).textTheme.headlineSmall?.copyWith(color: _kHeading, fontWeight: FontWeight.w700, fontSize: 26)),
          const SizedBox(height:8),
          Text('Enter the email associated with your account and we\'ll send a reset link / token.', style: const TextStyle(color: _kBody)),
          const SizedBox(height:24),
          TextFormField(
            controller: _emailCtl,
            focusNode: _emailFocus,
            decoration: InputDecoration(
              labelText:'Email',
              labelStyle: const TextStyle(color: _kMuted),
              prefixIcon: _AnimatedEmailIcon(focus: _emailFocus, valid: _emailValid),
              errorText: _emailValid? null : 'Invalid email',
              filled: true,
              fillColor: Colors.white.withValues(alpha: 0.85),
              // updated API
              // ignore: deprecated_member_use
              // replaced by withValues below line for precision
              // fillColor kept above for backward compatibility if needed
              // new fill color using withValues
              // (leave original removed to avoid double property)
            ),
            style: const TextStyle(color: _kBody),
            autofillHints: const [AutofillHints.email,AutofillHints.username],
            validator: (v)=> v==null || v.isEmpty? 'Enter email' : (!_isValidEmail(v)? 'Invalid email' : null),
            textInputAction: TextInputAction.done,
            onFieldSubmitted: (_)=> _submitEmail(),
          ),
          if(_error!=null) Padding(padding: const EdgeInsets.only(top:12), child: Text(_error!, style: const TextStyle(color: Colors.redAccent)) ),
          const SizedBox(height:28),
          SizedBox(
            height: 56,
            child: _BrandedGradientButton(
              onPressed: _submitting? null : _submitEmail,
              loading: _submitting,
              loadingLabel: 'Sending...',
              label: 'Send reset email',
              animation: _planeCtl,
            ),
          ),
          const SizedBox(height:12),
          TextButton(onPressed: ()=> Navigator.pop(context), child: const Text('Back to sign in', style: TextStyle(color: _kIndigo, fontWeight: FontWeight.w600))),
        ]),
      ),
    );
  }

  Widget _buildSentStage(ColorScheme cs){
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children:[
      const _SuccessCheck(),
      const SizedBox(height:16),
      Text('Check your email', style: Theme.of(context).textTheme.headlineSmall?.copyWith(color: _kHeading, fontWeight: FontWeight.w600)),
      const SizedBox(height:8),
      Text('If an account exists for ${_emailCtl.text.trim()}, we\'ve sent password reset instructions.', style: const TextStyle(color: _kBody)),
      const SizedBox(height:24),
      Wrap(spacing:12, runSpacing:12, children:[
        _SmallGradientButton(icon: Icons.vpn_key_outlined, label: 'I have a token', onTap: ()=> setState(()=> _stage = _FPStage.reset)),
        _SmallOutlineButton(icon: Icons.refresh, label: _submitting? 'Resending...' : 'Resend', onTap: _submitting? null : _submitEmail),
        TextButton(onPressed: ()=> Navigator.pop(context), child: const Text('Back', style: TextStyle(color: _kIndigo))),
      ])
    ]);
  }

  Widget _buildResetStage(ColorScheme cs){
    return Form(
      key: _resetFormKey,
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children:[
        Text('Enter token & new password', style: Theme.of(context).textTheme.headlineSmall?.copyWith(color: _kHeading, fontWeight: FontWeight.w600)),
        const SizedBox(height:8),
        Text('Paste the token from the email and choose a strong password.', style: const TextStyle(color: _kMuted)),
        const SizedBox(height:20),
        TextFormField(
          controller: _tokenCtl,
          decoration: const InputDecoration(labelText:'Token', prefixIcon: Icon(Icons.confirmation_number_outlined), filled: true, fillColor: Colors.white70),
          validator:(v)=> v==null||v.isEmpty? 'Token required': null,
          textInputAction: TextInputAction.next,
        ),
        const SizedBox(height:16),
        StatefulBuilder(builder:(ctx, localSet){
          return Column(crossAxisAlignment: CrossAxisAlignment.start, children:[
            TextFormField(
              controller: _passCtl,
              decoration: const InputDecoration(labelText:'New Password', prefixIcon: Icon(Icons.lock_outline), filled: true, fillColor: Colors.white70),
              obscureText: true,
              onChanged: (_){
                final val = _calcStrength(_passCtl.text);
                _strength = val; localSet((){});
              },
              validator:(v)=> v==null|| v.length<6? 'Min 6 chars': null,
            ),
            const SizedBox(height:10),
            LinearProgressIndicator(value: _strength, minHeight: 6, backgroundColor: const Color(0xFFE5E7EB), valueColor: AlwaysStoppedAnimation(_strengthColor(_strength, cs))),
            const SizedBox(height:6),
            Text('${_strengthLabel(_strength)} password', style: TextStyle(fontSize:12,color: _strengthColor(_strength, cs))),
            const SizedBox(height:10),
            _RequirementChecklist(strength: _strength, password: _passCtl.text, colorScheme: cs),
          ]);
        }),
        if(_error!=null) Padding(padding: const EdgeInsets.only(top:12), child: Text(_error!, style: const TextStyle(color: Colors.redAccent)) ),
        const SizedBox(height:28),
        SizedBox(
          height: 52,
          child: _BrandedGradientButton(
            onPressed: _submitting? null : _submitReset,
            loading: _submitting,
            loadingLabel: 'Updating...',
            label: 'Reset password',
            animation: _planeCtl,
            iconOverride: Icons.check_circle_outline,
          ),
        ),
        const SizedBox(height:12),
        TextButton(onPressed: ()=> setState(()=> _stage = _FPStage.request), child: const Text('Start over', style: TextStyle(color: _kIndigo))),
      ]),
    );
  }

  Widget _buildSuccessStage(ColorScheme cs){
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children:[
      const Icon(Icons.celebration_outlined, color: _kTeal, size:72),
      const SizedBox(height:18),
      Text('Password updated', style: Theme.of(context).textTheme.headlineSmall?.copyWith(color: _kHeading, fontWeight: FontWeight.w600)),
      const SizedBox(height:8),
      const Text('You can now sign in with your new password.', style: TextStyle(color: _kBody)),
      const SizedBox(height:30),
      SizedBox(height:52, child: _SmallGradientButton(icon: Icons.login, label: 'Back to Sign in', onTap: ()=> Navigator.pop(context))),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Recover Account', style: TextStyle(color: _kHeading)), backgroundColor: Colors.transparent, foregroundColor: _kHeading, elevation:0),
      extendBodyBehindAppBar: true,
      body: AnimatedBuilder(
        animation: _bgCtl,
        builder: (context, _) {
          return Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFFEEF2FF), Color(0xFFF0FDFA)],
              ),
            ),
            child: Center(
              child: LayoutBuilder(builder:(ctx, constraints){
                final wide = constraints.maxWidth > 900;
                final cardChild = ClipRRect(
                  borderRadius: BorderRadius.circular(28),
                  child: BackdropFilter(
                    filter: ui.ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                    child: Container(
                      padding: const EdgeInsets.all(32),
                      decoration: BoxDecoration(
                        color: const Color(0xD9FFFFFF),
                        borderRadius: BorderRadius.circular(28),
                        border: Border.all(color: Colors.white.withValues(alpha: .30), width: 1),
                        // ignore: deprecated_member_use
                        // replaced by withValues below line for precision
                        // border kept above for backward compatibility if needed
                        // new border color using withValues
                        // (leave original removed to avoid double property)
                      ),
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 400),
                        transitionBuilder: (child, anim)=> FadeTransition(opacity: anim, child: child),
                        child: SingleChildScrollView(
                          key: ValueKey(_stage),
                          child: DefaultTextStyle.merge(
                            style: const TextStyle(color: _kBody),
                            child: _buildCurrentStage(cs),
                          ),
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
        color: (ok? Colors.greenAccent : Colors.white).withValues(alpha: .15),
        // ignore: deprecated_member_use
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
// Added success check animation (was missing)
class _SuccessCheck extends StatefulWidget { const _SuccessCheck(); @override State<_SuccessCheck> createState()=>_SuccessCheckState(); }
class _SuccessCheckState extends State<_SuccessCheck> with SingleTickerProviderStateMixin { late final AnimationController _ctl; @override void initState(){ super.initState(); _ctl=AnimationController(vsync:this,duration: const Duration(milliseconds:800))..forward(); } @override void dispose(){ _ctl.dispose(); super.dispose(); } @override Widget build(BuildContext context){ return AnimatedBuilder(animation:_ctl, builder:(ctx,_) { final v=Curves.easeOutBack.transform(_ctl.value); return Transform.scale(scale:v, child: Icon(Icons.mark_email_read_outlined, color: _kTeal.withValues(alpha: v.clamp(0,1)), size:64)); }); }}

// Removed deprecated unused _GradientActionButton class entirely
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
        child: Icon(widget.valid? Icons.alternate_email_rounded : Icons.error_outline, color: widget.valid? _kTeal : Colors.redAccent),
      ),
    );
  }
}

// Simple math helper for animations
class _Maths { static double lerp(double a,double b,double t)=> a + (b-a)*t; }

// New branded gradient button (large)
class _BrandedGradientButton extends StatelessWidget {
  final VoidCallback? onPressed; final bool loading; final String label; final String loadingLabel; final AnimationController animation; final IconData? iconOverride;
  const _BrandedGradientButton({required this.onPressed, required this.loading, required this.label, required this.loadingLabel, required this.animation, this.iconOverride});
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
            gradient: const LinearGradient(colors:[_kTeal, _kIndigo]),
            borderRadius: BorderRadius.circular(20),
            boxShadow: const [BoxShadow(color: Color(0x3300C2A8), blurRadius: 20, offset: Offset(0,10))],
          ),
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal:24, vertical:14),
              child: Row(mainAxisSize: MainAxisSize.min, children:[
                if(loading)
                  const SizedBox(width:22,height:22, child: CircularProgressIndicator(strokeWidth:2.4, valueColor: AlwaysStoppedAnimation(Colors.white)))
                else
                  AnimatedBuilder(
                    animation: animation,
                    builder:(ctx,_) {
                      if(iconOverride!=null){ return Icon(iconOverride, color: Colors.white); }
                      final v = animation.value;
                      final dx = _Maths.lerp(0, 36, Curves.easeIn.transform(v));
                      final opacity = (1 - v*1.1).clamp(0.0,1.0);
                      return SizedBox(width: 28, height:28, child: Stack(children:[
                        Opacity(opacity: opacity, child: Transform.translate(offset: Offset(dx, -v*14), child: const Icon(Icons.send_rounded, color: Colors.white)) ),
                        if(v> .65) Center(child: Icon(Icons.check_circle_outline, color: Colors.white.withValues(alpha: ((v-.65)/.35).clamp(0,1))))
                        // ignore: deprecated_member_use
                        // replaced by withValues above for precision
                        // opacity kept above for backward compatibility if needed
                        // new opacity using withValues
                        // (leave original removed to avoid double property)
                      ]));
                    },
                  ),
                const SizedBox(width:14),
                Text(loading? loadingLabel : label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize:16)),
              ]),
            ),
          ),
        ),
      ),
    );
  }
}

class _SmallGradientButton extends StatelessWidget { final IconData icon; final String label; final VoidCallback? onTap; const _SmallGradientButton({required this.icon, required this.label, this.onTap}); @override Widget build(BuildContext context){ return GestureDetector(onTap: onTap, child: DecoratedBox(decoration: BoxDecoration(gradient: const LinearGradient(colors: [_kViolet, _kIndigo]), borderRadius: BorderRadius.circular(14), boxShadow: const [BoxShadow(color: Color(0x337C3AED), blurRadius: 16, offset: Offset(0,6))]), child: Padding(padding: const EdgeInsets.symmetric(horizontal:16, vertical:12), child: Row(mainAxisSize: MainAxisSize.min, children:[Icon(icon, color: Colors.white, size:18), const SizedBox(width:8), Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600))])))); }}
class _SmallOutlineButton extends StatelessWidget { final IconData icon; final String label; final VoidCallback? onTap; const _SmallOutlineButton({required this.icon, required this.label, this.onTap}); @override Widget build(BuildContext context){ return GestureDetector(onTap: onTap, child: DecoratedBox(decoration: BoxDecoration(border: Border.all(color: _kIndigo.withValues(alpha:.55)), color: Colors.white.withValues(alpha:.6), borderRadius: BorderRadius.circular(14)), child: Padding(padding: const EdgeInsets.symmetric(horizontal:16, vertical:12), child: Row(mainAxisSize: MainAxisSize.min, children:[Icon(icon, color: _kIndigo, size:18), const SizedBox(width:8), Text(label, style: const TextStyle(color: _kIndigo, fontWeight: FontWeight.w600))])))); }}

// Illustration panel (restored)
class _IllustrationPanel extends StatelessWidget { final Animation<double> animation; const _IllustrationPanel({required this.animation}); @override Widget build(BuildContext context){ final t=animation.value; return Column(mainAxisAlignment: MainAxisAlignment.center, children:[ Container(height:180,width:180, decoration: BoxDecoration(shape: BoxShape.circle, gradient: SweepGradient(colors:[ _kTeal.withValues(alpha:.7), _kIndigo.withValues(alpha:.7), _kViolet.withValues(alpha:.7), _kTeal.withValues(alpha:.7)], stops: const [0,.33,.66,1], transform: GradientRotation(t*6.28318)), boxShadow: const [BoxShadow(color: Color(0x33000000), blurRadius:32, spreadRadius:-6)]), child: const Center(child: Icon(Icons.lock_reset_rounded, color: Colors.white, size:96)), ), const SizedBox(height:28), Text('Secure Reset', style: Theme.of(context).textTheme.titleLarge?.copyWith(color: _kHeading, fontWeight: FontWeight.w600)), const SizedBox(height:8), const Text("We'll guide you through recovering access safely.", textAlign: TextAlign.center, style: TextStyle(color: _kMuted)) ]); }}
