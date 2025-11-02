import 'package:flutter/material.dart';

class JobListItem extends StatelessWidget {
  final String title;
  const JobListItem({super.key, required this.title});

  @override
  Widget build(BuildContext context) => ListTile(title: Text(title));
}
