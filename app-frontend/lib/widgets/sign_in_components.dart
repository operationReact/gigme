import 'package:flutter/material.dart';

/// ─────────────────────────────────────────────────────────────────────────────
/// GigMeWork brand palette + logo + shared sign-in widgets

const _kTeal = Color(0xFF00C2A8);
const _kIndigo = Color(0xFF3B82F6);
const _kViolet = Color(0xFF7C3AED);
const _kHeading = Color(0xFF111827);
const _kMuted  = Color(0xFF6B7280);

/// Compact mark + wordmark if you need it elsewhere.
class GmwLogoSmall extends StatelessWidget {
  final double markSize;
  final double fontSize;
  final bool onDark;
  const GmwLogoSmall({super.key, this.markSize = 24, this.fontSize = 18, this.onDark = false});

  @override
  Widget build(BuildContext context) {
    final head = onDark ? Colors.white : _kHeading;
    final word = Text.rich(
      TextSpan(children: [
        TextSpan(text: 'Gig', style: TextStyle(color: head, fontWeight: FontWeight.w700)),
        const TextSpan(text: 'Me', style: TextStyle(color: _kTeal, fontWeight: FontWeight.w700)),
        TextSpan(text: 'Work', style: TextStyle(color: head, fontWeight: FontWeight.w700)),
      ]),
      style: TextStyle(fontSize: fontSize, height: 1.0, letterSpacing: 0.2),
    );
    return Row(children: [
      _GmwMark(size: markSize),
      const SizedBox(width: 8),
      word,
    ]);
  }
}

/// Full wordmark with optional tagline (matches other pages).
class GmwLogo extends StatelessWidget {
  final double markSize;
  final double fontSize;
  final bool showTagline;
  final bool onDark;
  const GmwLogo({
    super.key,
    this.markSize = 32,
    this.fontSize = 24,
    this.showTagline = true,
    this.onDark = false,
  });

  @override
  Widget build(BuildContext context) {
    final head  = onDark ? Colors.white : _kHeading;
    final muted = onDark ? Colors.white70 : _kMuted;

    final wordmark = Text.rich(
      TextSpan(children: [
        TextSpan(text: 'Gig', style: TextStyle(color: head, fontWeight: FontWeight.w800)),
        const TextSpan(text: 'Me', style: TextStyle(color: _kTeal, fontWeight: FontWeight.w800)),
        TextSpan(text: 'Work', style: TextStyle(color: head, fontWeight: FontWeight.w800)),
      ]),
      style: TextStyle(fontSize: fontSize, height: 1.0, letterSpacing: 0.2),
    );

    final tagline = Padding(
      padding: const EdgeInsets.only(top: 2),
      child: Text(
        'People Need People',
        style: TextStyle(
          color: muted.withOpacity(0.92),
          fontSize: (fontSize * 0.46).clamp(10.0, 14.0).toDouble(),
          fontWeight: FontWeight.w600,
          letterSpacing: 0.35,
          height: 1.08,
        ),
      ),
    );

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _GmwMark(size: markSize),
        const SizedBox(width: 10),
        Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [wordmark, if (showTagline) tagline],
        ),
      ],
    );
  }
}

class _GmwMark extends StatelessWidget {
  final double size;
  const _GmwMark({required this.size});
  @override
  Widget build(BuildContext context) {
    final h = size; final w = size * 1.7;
    return SizedBox(
      width: w, height: h,
      child: Stack(alignment: Alignment.center, children: [
        Align(alignment: Alignment.centerLeft,  child: Container(width: h, height: h, decoration: const BoxDecoration(color: _kTeal,   shape: BoxShape.circle))),
        Align(alignment: Alignment.centerRight, child: Container(width: h, height: h, decoration: const BoxDecoration(color: _kViolet, shape: BoxShape.circle))),
        Container(
          width: w * 0.74, height: h * 0.34,
          decoration: BoxDecoration(
            color: _kIndigo,
            borderRadius: BorderRadius.circular(h),
            border: Border.all(color: Colors.white, width: h * 0.10),
          ),
        ),
      ]),
    );
  }
}

/// ─────────────────────────────────────────────────────────────────────────────
/// Brand background + glass card wrappers

class SignInBackground extends StatelessWidget {
  final Widget child;
  const SignInBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Stack(fit: StackFit.expand, children: [
      const DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft, end: Alignment.bottomRight,
            colors: [_kTeal, _kIndigo, _kViolet],
          ),
        ),
      ),
      Positioned(top: -60, left: -40, child: _softCircle(220, Colors.white.withOpacity(0.10))),
      Positioned(bottom: -40, right: -50, child: _softCircle(200, Colors.white.withOpacity(0.08))),
      Positioned(top: 120, right: -30, child: _softCircle(120, Colors.white.withOpacity(0.06))),
      child,
    ]);
  }

  Widget _softCircle(double s, Color c) => Container(
    width: s, height: s,
    decoration: BoxDecoration(color: c, shape: BoxShape.circle, boxShadow: const [
      BoxShadow(color: Colors.black26, blurRadius: 40, spreadRadius: -10)
    ]),
  );
}

/// Centered glass card for auth forms. Uses the real brand logo.
class SignInCard extends StatelessWidget {
  final Widget child;
  final String title;     // kept for semantics/consistency if needed
  final String subtitle;  // shows as a small helper line below tagline (optional)
  final double maxWidth;
  const SignInCard({
    super.key,
    required this.child,
    required this.title,
    required this.subtitle,
    this.maxWidth = 520,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.82),
            borderRadius: BorderRadius.circular(28),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.25), blurRadius: 38, spreadRadius: 4, offset: const Offset(0, 18))],
            border: Border.all(color: Colors.white.withOpacity(0.18)),
          ),
          padding: const EdgeInsets.fromLTRB(32, 30, 32, 40),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ★ Brand header (logo + tagline)
              const GmwLogo(markSize: 28, fontSize: 22, showTagline: true),
              if (subtitle.isNotEmpty)
                const SizedBox(height: 6),
              if (subtitle.isNotEmpty)
                Text(subtitle, style: const TextStyle(color: Colors.black54, fontSize: 12, fontWeight: FontWeight.w500)),
              const SizedBox(height: 18),
              child,
            ],
          ),
        ),
      ),
    );
  }
}

/// Convenience shell: background + card.
class SignInShell extends StatelessWidget {
  final String title;
  final String subtitle;
  final double maxWidth;
  final Widget child;
  const SignInShell({super.key, required this.title, required this.subtitle, required this.child, this.maxWidth = 520});

  @override
  Widget build(BuildContext context) {
    return SignInBackground(
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: SignInCard(title: title, subtitle: subtitle, maxWidth: maxWidth, child: child),
        ),
      ),
    );
  }
}

/// ─────────────────────────────────────────────────────────────────────────────
/// Buttons + fields (brandified)

enum SignInButtonState { idle, loading, success }

class SignInPrimaryButton extends StatelessWidget {
  final SignInButtonState state;
  final VoidCallback? onPressed;
  final String label;
  final IconData icon;
  final double height;
  const SignInPrimaryButton({super.key, required this.state, required this.onPressed, this.label='Sign in', this.icon=Icons.login_rounded, this.height=54});

  @override
  Widget build(BuildContext context) {
    final success = state == SignInButtonState.success;
    final loading = state == SignInButtonState.loading;

    const brandGradient = LinearGradient(
      begin: Alignment(-0.9, -1),
      end: Alignment(1, 1),
      colors: [_kTeal, _kIndigo, _kViolet],
    );

    return _HoverScale(
      childBuilder: (hover){
        return Stack(children:[
          AnimatedContainer(
              duration: const Duration(milliseconds: 260),
              curve: Curves.easeOutCubic,
              height: height,
              decoration: BoxDecoration(
                gradient: success
                    ? LinearGradient(colors: [Colors.green.shade400, Colors.green.shade600])
                    : brandGradient,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  if(hover && !loading && !success) BoxShadow(color: _kIndigo.withOpacity(.45), blurRadius: 34, spreadRadius: 2, offset: const Offset(0,10)),
                  if(success) BoxShadow(color: Colors.green.withOpacity(0.55), blurRadius: 32, spreadRadius: 2),
                ],
              ),
              child: Material(
                type: MaterialType.transparency,
                child: InkWell(
                  borderRadius: BorderRadius.circular(20),
                  splashColor: Colors.white.withOpacity(0.18),
                  highlightColor: Colors.white.withOpacity(0.06),
                  onTap: (loading || success)? null : onPressed,
                  child: Center(
                    child: Semantics(
                      button: true,
                      label: success? 'Sign in success' : label,
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 360),
                        transitionBuilder: (child, anim)=> ScaleTransition(scale: anim, child: child),
                        child: success
                            ? const Icon(Icons.check_circle_outline, key: ValueKey('ok'), color: Colors.white, size: 30)
                            : loading
                            ? const SizedBox(key: ValueKey('load'), height: 28, width: 28, child: CircularProgressIndicator(strokeWidth: 3, valueColor: AlwaysStoppedAnimation<Color>(Colors.white)))
                            : Row(key: const ValueKey('label'), mainAxisSize: MainAxisSize.min, children:[
                          Icon(icon, color: Colors.white), const SizedBox(width: 10), Text(label, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white))
                        ]),
                      ),
                    ),
                  ),
                ),
              )
          ),
          // inner shadow overlay
          Positioned.fill(
            child: IgnorePointer(
              child: AnimatedOpacity(
                duration: const Duration(milliseconds:260),
                opacity: hover && !success ? 1 : 0.6,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    gradient: RadialGradient(
                      center: Alignment.topLeft, radius: 1.4,
                      colors: [Colors.white.withOpacity(0.15), Colors.black.withOpacity(0.20)],
                      stops: const [0.15, 1],
                    ),
                  ),
                ),
              ),
            ),
          )
        ]);
      },
    );
  }
}

class SocialLoginButtons extends StatelessWidget {
  final VoidCallback? onGoogle;
  final VoidCallback? onGitHub;
  const SocialLoginButtons({super.key, this.onGoogle, this.onGitHub});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final base = OutlinedButton.styleFrom(
      foregroundColor: cs.onSurface,
      side: BorderSide(color: cs.secondary.withOpacity(0.35)),
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 18),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      minimumSize: const Size.fromHeight(54),
      backgroundColor: Colors.white.withOpacity(0.55),
    );
    return Row(children:[
      Expanded(
        child: Semantics(
          button: true,
          label: 'Sign in with Google',
          child: OutlinedButton.icon(
            onPressed: onGoogle,
            icon: Image.network('https://www.gstatic.com/firebasejs/ui/2.0.0/images/auth/google.svg', height:20, errorBuilder: (_,__,___)=> const Icon(Icons.g_mobiledata)),
            style: base,
            label: const Text('Google'),
          ),
        ),
      ),
      const SizedBox(width:12),
      Expanded(
        child: Semantics(
          button: true,
          label: 'Sign in with GitHub',
          child: OutlinedButton.icon(
            onPressed: onGitHub,
            icon: const Icon(Icons.code),
            style: base,
            label: const Text('GitHub'),
          ),
        ),
      ),
    ]);
  }
}

/// Floating-label field decoration with brand focus color.
InputDecoration signInInputDecoration(BuildContext context, {required String label, String? hint, IconData? icon, String? errorText, Widget? suffix}){
  final cs = Theme.of(context).colorScheme;
  final isDark = Theme.of(context).brightness == Brightness.dark;
  final fill = isDark ? Colors.white.withOpacity(0.08) : Colors.white.withOpacity(0.60);
  return InputDecoration(
    labelText: label,
    hintText: hint,
    labelStyle: TextStyle(color: Colors.grey.shade700, fontWeight: FontWeight.w500),
    prefixIcon: icon!=null? Icon(icon, color: Colors.grey.shade700): null,
    filled: true,
    fillColor: fill,
    errorText: errorText,
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(18), borderSide: BorderSide(color: Colors.grey.shade300)),
    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(18), borderSide: BorderSide(color: Colors.grey.shade300)),
    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(18), borderSide: BorderSide(color: cs.secondary, width: 2)),
    errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(18), borderSide: const BorderSide(color: Colors.redAccent)),
    focusedErrorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(18), borderSide: const BorderSide(color: Colors.redAccent, width: 2)),
    suffixIcon: suffix,
    contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
  );
}

/// Hover + scale wrapper for the primary CTA.
class _HoverScale extends StatefulWidget {
  final Widget Function(bool hover) childBuilder;
  const _HoverScale({required this.childBuilder});
  @override
  State<_HoverScale> createState() => _HoverScaleState();
}
class _HoverScaleState extends State<_HoverScale> {
  bool _hover=false;
  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_)=> setState(()=> _hover=true),
      onExit: (_)=> setState(()=> _hover=false),
      child: AnimatedScale(
        scale: _hover?1.03:1,
        duration: const Duration(milliseconds:160),
        child: widget.childBuilder(_hover),
      ),
    );
  }
}

/// Password strength bar widget (accessible) derived from a 0..1 strength value.
class PasswordStrengthMeter extends StatelessWidget {
  final double strength; // 0..1
  final String label;
  const PasswordStrengthMeter({super.key, required this.strength, required this.label});
  Color _color(BuildContext ctx){
    if(strength>=0.9) return Colors.green;
    if(strength>=0.75) return Colors.greenAccent.shade400;
    if(strength>=0.5) return Colors.amber;
    if(strength>=0.3) return Theme.of(ctx).colorScheme.tertiary;
    return Colors.redAccent;
  }
  @override
  Widget build(BuildContext context) {
    final color = _color(context);
    return Semantics(
      label: 'Password strength: $label',
      child: Row(children:[
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              minHeight: 8,
              value: strength==0? 0: strength.clamp(0,1),
              backgroundColor: Colors.white.withOpacity(0.12),
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: color))
      ]),
    );
  }
}

class HoverLink extends StatefulWidget {
  final String text; final VoidCallback onTap; final Color? color; final double fontSize; final FontWeight fontWeight; final EdgeInsets padding;
  const HoverLink({super.key, required this.text, required this.onTap, this.color, this.fontSize=14, this.fontWeight=FontWeight.w500, this.padding=EdgeInsets.zero});
  @override State<HoverLink> createState()=> _HoverLinkState(); }
class _HoverLinkState extends State<HoverLink> with SingleTickerProviderStateMixin {
  bool _hover=false; late AnimationController _ctl; late Animation<double> _anim;
  @override void initState(){ super.initState(); _ctl=AnimationController(vsync:this, duration: const Duration(milliseconds:220)); _anim=CurvedAnimation(parent:_ctl, curve: Curves.easeOut); }
  @override void dispose(){ _ctl.dispose(); super.dispose(); }
  void _set(bool h){ if(h){ _ctl.forward(); } else { _ctl.reverse(); } setState(()=> _hover=h); }
  @override Widget build(BuildContext context){
    final color = widget.color ?? Theme.of(context).colorScheme.secondary;
    return MouseRegion(
      onEnter: (_)=> _set(true),
      onExit: (_)=> _set(false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: Semantics(
          button: true,
          label: widget.text,
          child: Padding(
            padding: widget.padding,
            child: Stack(
              alignment: Alignment.centerLeft,
              children: [
                Text(widget.text, style: TextStyle(color: color, fontSize: widget.fontSize, fontWeight: widget.fontWeight, decoration: TextDecoration.none)),
                Positioned(
                  bottom: 0,
                  child: FadeTransition(
                    opacity: _anim,
                    child: SizeTransition(
                      sizeFactor: _anim,
                      axis: Axis.horizontal,
                      axisAlignment: -1,
                      child: Container(
                        height: 2,
                        width: _textWidth(widget.text, context),
                        decoration: BoxDecoration(gradient: LinearGradient(colors:[color.withOpacity(.1), color])),
                      ),
                    ),
                  ),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
  double _textWidth(String text, BuildContext context){ final tp=TextPainter(text: TextSpan(text:text, style: TextStyle(fontSize: widget.fontSize, fontWeight: widget.fontWeight)), textDirection: TextDirection.ltr)..layout(); return tp.width; }
}
