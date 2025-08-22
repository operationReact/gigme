import 'package:flutter/material.dart';
import 'profile_client.dart';
import 'register_client.dart';
import 'dart:ui' as ui;
import '../api/auth_api.dart';
import '../services/session_service.dart';
import '../services/preferences_service.dart';

class SignInClientPage extends StatefulWidget {
  static const routeName = '/signin/client';
  const SignInClientPage({super.key});

  @override
  State<SignInClientPage> createState() => _SignInClientPageState();
}

class _SignInClientPageState extends State<SignInClientPage> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscure = true;
  bool _remember = true;
  bool _loading = false;
  String? _authError;
  String? _emailAuthError;
  late AnimationController _shakeCtl;
  late Animation<double> _shakeAnim;

  @override
  void initState() {
    super.initState();
    _shakeCtl = AnimationController(vsync: this, duration: const Duration(milliseconds: 450));
    _shakeAnim = CurvedAnimation(parent: _shakeCtl, curve: Curves.elasticIn);
    PreferencesService.instance.loadRemembered().then((data){
      if(!mounted) return; final (remember,email,role)=data; setState((){ _remember=remember; if(remember && email!=null) _emailController.text=email; });
    });
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _shakeCtl.dispose();
    super.dispose();
  }

  void _triggerShake(){ _shakeCtl.forward(from:0); }

  void _submit() async {
    if(!_formKey.currentState!.validate()) return; if(_loading) return;
    setState((){ _loading=true; _authError=null; _emailAuthError=null; });
    final authApi=AuthApi();
    try {
      final user = await authApi.login(email: _emailController.text.trim(), password: _passwordController.text);
      SessionService.instance.setUser(user);
      if(!mounted) return;
      await PreferencesService.instance.saveRemembered(remember: _remember, email: _remember? _emailController.text.trim():null, role: _remember? 'CLIENT': null);
      if(!user.hasClientProfile){
        Navigator.of(context).pushReplacementNamed(ProfileClientPage.routeName);
      } else {
        Navigator.of(context).pushReplacementNamed(ProfileClientPage.routeName);
      }
    } catch(e){
      if(!mounted) return; final msg=e.toString();
      setState((){
        if(msg.toLowerCase().contains('invalid credentials')|| msg.toLowerCase().contains('unauthorized')) { _authError='Invalid email or password.'; _emailAuthError='Invalid email or password.'; } else { _authError='Login failed. Please try again.'; }
      });
      _triggerShake();
    } finally { if(mounted) setState(()=> _loading=false); }
  }

  @override
  Widget build(BuildContext context){
    final cs=Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Client Sign in')),
      body: Container(
        decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topLeft,end: Alignment.bottomRight,colors:[cs.secondary.withOpacity(0.35), cs.tertiary.withOpacity(0.35)])),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth:560),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: BackdropFilter(
                filter: ui.ImageFilter.blur(sigmaX:10,sigmaY:10),
                child: Container(
                  decoration: BoxDecoration(color: Colors.white.withOpacity(0.06),borderRadius: BorderRadius.circular(20),border: Border.all(color: Colors.white.withOpacity(0.12))),
                  padding: const EdgeInsets.all(24),
                  child: Semantics(
                    label: 'Client sign in form',
                    child: AnimatedBuilder(
                      animation: _shakeCtl,
                      builder:(c,child){final dx=_shakeCtl.isAnimating? (1-_shakeAnim.value)*12*(_shakeAnim.value%0.2>0.1?-1:1):0; return Transform.translate(offset: Offset(dx.toDouble(),0),child: child);},
                      child: Form(
                        key:_formKey,
                        child: Column(mainAxisSize: MainAxisSize.min,crossAxisAlignment: CrossAxisAlignment.stretch,children:[
                          // header row
                          Row(children:[Hero(tag:'hero-client',child: CircleAvatar(radius:22,backgroundColor: cs.tertiary.withOpacity(0.2),child: Icon(Icons.apartment_outlined,color: cs.primary))), const SizedBox(width:12), Text('Welcome back, client', style: Theme.of(context).textTheme.titleMedium)]),
                          const SizedBox(height:16),
                          TextFormField(
                            controller:_emailController,
                            autofillHints: const [AutofillHints.username,AutofillHints.email],
                            decoration: InputDecoration(labelText: 'Business Email', hintText:'you@company.com',filled:true,fillColor: Colors.white.withOpacity(0.06),prefixIcon: const Icon(Icons.email_outlined),border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)), errorText: _emailAuthError),
                            textInputAction: TextInputAction.next, keyboardType: TextInputType.emailAddress,
                            onChanged: (_){ if(_authError!=null || _emailAuthError!=null) setState((){ _authError=null; _emailAuthError=null; }); },
                            validator:(v)=> (v==null||v.isEmpty|| !v.contains('@'))? 'Enter a valid email' : null,
                          ),
                          const SizedBox(height:12),
                          TextFormField(
                            controller:_passwordController,
                            autofillHints: const [AutofillHints.password],
                            decoration: InputDecoration(labelText: 'Password',filled:true,fillColor: Colors.white.withOpacity(0.06),prefixIcon: const Icon(Icons.lock_outline),border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)), suffixIcon: GestureDetector(onLongPressStart: (_)=> setState(()=> _obscure=false), onLongPressEnd: (_)=> setState(()=> _obscure=true), child: IconButton(icon: Icon(_obscure? Icons.visibility: Icons.visibility_off), onPressed: ()=> setState(()=> _obscure=!_obscure), tooltip: _obscure? 'Show password':'Hide password')), errorText: _authError),
                            obscureText: _obscure, textInputAction: TextInputAction.done, onFieldSubmitted: (_)=> _submit(), onChanged: (_){ if(_authError!=null) setState(()=> _authError=null); }, validator:(v)=> (v==null|| v.length<6)? 'Password must be at least 6 characters': null,
                          ),
                          const SizedBox(height:8),
                          CheckboxListTile(value:_remember,onChanged:(v)=> setState(()=> _remember=v??true),controlAffinity: ListTileControlAffinity.leading,dense:true,title: const Text('Remember me'),contentPadding: EdgeInsets.zero),
                          const SizedBox(height:8),
                          SizedBox(height:48, child: ElevatedButton.icon(onPressed: _loading? null: _submit, icon: _loading? const SizedBox(width:18,height:18,child: CircularProgressIndicator(strokeWidth:2,color: Colors.white)): const Icon(Icons.login), label: Text(_loading? '...': 'Sign in'))),
                          const SizedBox(height:8),
                          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children:[
                            TextButton(onPressed: (){}, child: const Text('Need help?')),
                            TextButton(onPressed: ()=> Navigator.of(context).pushNamed(RegisterClientPage.routeName), child: const Text('Create account'))
                          ])
                        ]),
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
