import 'package:flutter/material.dart';

class JobReportsScreen extends StatelessWidget {
  const JobReportsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Job Reports')),
      body: const Center(child: Text('Job reports will appear here')),
    );
  }
}
