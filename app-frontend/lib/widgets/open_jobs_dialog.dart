import 'package:flutter/material.dart';
import '../job_service.dart';

class OpenJobsDialog extends StatefulWidget {
  final String freelancerEmail;
  const OpenJobsDialog({super.key, required this.freelancerEmail});

  @override
  State<OpenJobsDialog> createState() => _OpenJobsDialogState();
}

class _OpenJobsDialogState extends State<OpenJobsDialog> {
  late Future<List<Job>> _futureJobs;
  String? _error;
  int? _appliedJobId;
  bool _isApplying = false;

  @override
  void initState() {
    super.initState();
    _futureJobs = JobService().listOpenJobs();
  }

  void _apply(int jobId) async {
    setState(() {
      _isApplying = true;
      _appliedJobId = jobId;
      _error = null;
    });
    try {
      await JobService().applyForJob(jobId, widget.freelancerEmail);
      setState(() {
        _isApplying = false;
      });
      if (mounted) {
        Navigator.of(context).pop('applied');
      }
    } catch (e) {
      setState(() {
        _isApplying = false;
        _error = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Open Jobs'),
      content: SizedBox(
        width: 350,
        child: FutureBuilder<List<Job>>(
          future: _futureJobs,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Text('Error: \\${snapshot.error}');
            }
            final jobs = snapshot.data ?? [];
            if (jobs.isEmpty) {
              return const Text('No open jobs available.');
            }
            return ListView.separated(
              shrinkWrap: true,
              itemCount: jobs.length,
              separatorBuilder: (_, __) => const Divider(),
              itemBuilder: (context, i) {
                final job = jobs[i];
                return ListTile(
                  title: Text(job.title),
                  subtitle: job.description != null ? Text(job.description!) : null,
                  trailing: _isApplying && _appliedJobId == job.id
                      ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2))
                      : ElevatedButton(
                          onPressed: _isApplying ? null : () => _apply(job.id),
                          child: const Text('Apply'),
                        ),
                );
              },
            );
          },
        ),
      ),
      actions: [
        if (_error != null) ...[
          Text(_error!, style: const TextStyle(color: Colors.red)),
        ],
        TextButton(
          onPressed: _isApplying ? null : () => Navigator.of(context).pop(),
          child: const Text('Close'),
        ),
      ],
    );
  }
}

