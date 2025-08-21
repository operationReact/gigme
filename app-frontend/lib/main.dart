import 'package:flutter/material.dart';
import 'job_service.dart';

void main() {
  runApp(const GigmeworkApp());
}

class GigmeworkApp extends StatelessWidget {
  const GigmeworkApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Gigmework',
      theme: ThemeData(colorSchemeSeed: Colors.indigo, useMaterial3: true),
      home: const JobsPage(),
    );
  }
}

class JobsPage extends StatefulWidget {
  const JobsPage({super.key});
  @override
  State<JobsPage> createState() => _JobsPageState();
}

class _JobsPageState extends State<JobsPage> {
  final JobService _service = JobService();
  late Future<List<Job>> _future;
  final TextEditingController _titleCtrl = TextEditingController();
  final TextEditingController _descCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _future = _service.listJobs();
  }

  Future<void> _refresh() async {
    setState(() { _future = _service.listJobs(); });
  }

  Future<void> _create() async {
    final title = _titleCtrl.text.trim();
    if (title.isEmpty) return;
    await _service.createJob(title, description: _descCtrl.text.trim().isEmpty ? null : _descCtrl.text.trim());
    _titleCtrl.clear();
    _descCtrl.clear();
    _refresh();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Jobs')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                TextField(controller: _titleCtrl, decoration: const InputDecoration(labelText: 'Title')),
                TextField(controller: _descCtrl, decoration: const InputDecoration(labelText: 'Description')),
                const SizedBox(height: 8),
                Row(children:[
                  ElevatedButton(onPressed: _create, child: const Text('Add Job')),
                  const SizedBox(width: 12),
                  OutlinedButton(onPressed: _refresh, child: const Text('Refresh'))
                ])
              ],
            ),
          ),
          Expanded(
            child: FutureBuilder<List<Job>>(
              future: _future,
              builder: (context, snapshot) {
                if (snapshot.connectionState != ConnectionState.done) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }
                final jobs = snapshot.data ?? [];
                if (jobs.isEmpty) return const Center(child: Text('No jobs yet'));
                return ListView.builder(
                  itemCount: jobs.length,
                  itemBuilder: (context, i) {
                    final j = jobs[i];
                    return ListTile(
                      title: Text(j.title),
                      subtitle: j.description != null ? Text(j.description!) : null,
                    );
                  },
                );
              },
            ),
          )
        ],
      ),
    );
  }
}

