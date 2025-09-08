import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../api/profile_api.dart';
import '../services/session_service.dart';
import '../main.dart';
import '../screens/freelancer_home.dart';
import '../widgets/profile_preview_card.dart';
import 'package:flutter/services.dart';
import '../screens/share_card_public.dart';


class FreelancerProfileScreen extends StatefulWidget {
  const FreelancerProfileScreen({super.key});
  static const route = '/freelancerProfile';

  @override
  State<FreelancerProfileScreen> createState() => _FreelancerProfileScreenState();
}

class _FreelancerProfileScreenState extends State<FreelancerProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _title = TextEditingController();
  final _bio = TextEditingController();
  final _skills = TextEditingController();
  bool _loading = false;
  bool _initialLoading = true;
  bool _existing = false;

  @override
  void initState(){
    super.initState();
    _prefill();
  }

  Future<void> _prefill() async {
    final user = SessionService.instance.user;
    if(user==null){ setState(()=> _initialLoading=false); return; }
    try {
      final dto = await ProfileApi().getFreelancer(user.id);
      if(dto!=null){
        _existing = true;
        _name.text = dto.displayName;
        if(dto.professionalTitle!=null) _title.text = dto.professionalTitle!;
        if(dto.bio!=null) _bio.text = dto.bio!;
        if(dto.skillsCsv!=null) _skills.text = dto.skillsCsv!;
      }
    } catch(_){ /* ignore */ }
    if(mounted) setState(()=> _initialLoading=false);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final session = SessionService.instance;
    final user = session.user;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Not authenticated')));
      return;
    }
    setState(()=> _loading = true);
    try {
      final api = ProfileApi();
      await api.upsertFreelancer(user.id,
          displayName: _name.text.trim(),
          professionalTitle: _title.text.trim().isEmpty ? null : _title.text.trim(),
          bio: _bio.text.trim().isEmpty ? null : _bio.text.trim(),
          skillsCsv: _skills.text.trim().isEmpty ? null : _skills.text.trim());
      session.updateProfiles(hasFreelancer: true);
      if (mounted) {
        Navigator.of(context).pushNamedAndRemoveUntil(FreelancerHomePage.routeName, (_) => false);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Save failed: $e')));
      }
    } finally {
      if (mounted) setState(()=> _loading = false);
    }
  }

  @override
  void dispose() { _name.dispose(); _title.dispose(); _bio.dispose(); _skills.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    if(_initialLoading){ return const Scaffold(body: Center(child: CircularProgressIndicator())); }
    return Scaffold(
      appBar: AppBar(title: const Text('Freelancer Profile')),
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
                      Text('Create your professional profile', style: GoogleFonts.poppins(fontSize: 24, fontWeight: FontWeight.w700, color: Colors.white)),
                      const SizedBox(height: 6),
                      Text('Show clients why you are the right fit.', style: GoogleFonts.poppins(fontSize: 14, color: Colors.white70)),
                      const SizedBox(height: 28),
                      // Profile Preview Card
                      ProfilePreviewCard(
                        name: _name.text.isEmpty ? 'Your Name' : _name.text,
                        title: _title.text.isEmpty ? 'Your Title' : _title.text,
                        bio: _bio.text.isEmpty ? 'Short bio about yourself...' : _bio.text,
                        skills: _skills.text.isEmpty ? ['Skill 1', 'Skill 2'] : _skills.text.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toList(),
                        imageUrl: null, // You can add image support later
                      ),
                      const SizedBox(height: 32),
                      _field(_name, 'Display Name', validator: (v)=> v==null||v.trim().isEmpty? 'Required': null),
                      const SizedBox(height: 18),
                      _field(_title, 'Professional Title', hint: 'e.g. Mobile App Developer'),
                      const SizedBox(height: 18),
                      _field(_skills, 'Key Skills (comma separated)', hint: 'Flutter, REST, UI/UX'),
                      const SizedBox(height: 18),
                      _field(_bio, 'Short Bio', maxLines: 4, hint: 'Tell clients about your experience'),
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
                              gradient: const LinearGradient(colors:[Color(0xFF6D83F2), Color(0xFF5146E1)]),
                              borderRadius: BorderRadius.circular(18),
                            ),
                            child: Center(
                              child: _loading ? const SizedBox(width:22,height:22,child:CircularProgressIndicator(strokeWidth:3,valueColor: AlwaysStoppedAnimation(Colors.white)))
                                : Text(_existing ? 'Save' : 'Finish & Continue', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white)),
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
