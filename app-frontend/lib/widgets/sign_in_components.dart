import 'package:flutter/material.dart';
import 'dart:math' as math;

/// Shared sign-in related UI components to reduce duplication.
/// Includes: primary gradient button, social login buttons, input decoration helper.

enum SignInButtonState { idle, loading, success }

class SignInPrimaryButton extends StatelessWidget {
  final SignInButtonState state;
  final VoidCallback? onPressed;
  final String label;
  final IconData icon;
  final double height;
  const SignInPrimaryButton({super.key, required this.state, required this.onPressed, this.label='Sign in', this.icon=Icons.login, this.height=54});

  @override
  Widget build(BuildContext context) {
    final success = state == SignInButtonState.success;
    final loading = state == SignInButtonState.loading;
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
                : const LinearGradient(begin: Alignment(-0.9,-1), end: Alignment(1,1), colors: [Color(0xFF0F766E), Color(0xFF0C5EAC), Color(0xFF0A4EB0)]),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                if(hover && !loading && !success) BoxShadow(color: const Color(0xFF0C5EAC).withOpacity(.45), blurRadius: 34, spreadRadius: 2, offset: const Offset(0,10)),
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
          // inner shadow (edge darkening) overlay
          Positioned.fill(
            child: IgnorePointer(
              child: AnimatedOpacity(
                duration: const Duration(milliseconds:260),
                opacity: hover && !success ? 1 : 0.6,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    gradient: RadialGradient(
                      center: Alignment.topLeft,
                      radius: 1.4,
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
      side: BorderSide(color: Colors.white.withOpacity(0.25)),
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 18),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      minimumSize: const Size.fromHeight(54),
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

/// Helper for consistent decoration; floating labels + focus brand color.
InputDecoration signInInputDecoration(BuildContext context, {required String label, String? hint, IconData? icon, String? errorText, Widget? suffix}){
  final cs = Theme.of(context).colorScheme;
  final bool darkBg = Theme.of(context).brightness == Brightness.dark;
  return InputDecoration(
    labelText: label,
    hintText: hint,
    labelStyle: TextStyle(color: Colors.grey.shade700, fontWeight: FontWeight.w500),
    prefixIcon: icon!=null? Icon(icon, color: Colors.grey.shade700): null,
    filled: true,
    fillColor: Colors.white.withOpacity(0.55),
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

/// Internal hover + scale wrapper used by the primary button.
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
                        decoration: BoxDecoration(
                          gradient: LinearGradient(colors:[color.withOpacity(.1), color])
                        ),
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
