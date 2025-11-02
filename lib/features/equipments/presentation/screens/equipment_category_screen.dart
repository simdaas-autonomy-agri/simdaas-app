import 'package:flutter/material.dart';
import 'equipment_list_screen.dart';

class EquipmentCategoryScreen extends StatelessWidget {
  const EquipmentCategoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Equipments')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: () => Navigator.of(context).push(MaterialPageRoute(
                  builder: (_) => const EquipmentListScreen(),
                  settings: const RouteSettings(
                      arguments: {'category': 'control_unit'}))),
              style: ElevatedButton.styleFrom(
                  minimumSize: const Size.fromHeight(56)),
              child:
                  const Text('Control Units', style: TextStyle(fontSize: 16)),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () => Navigator.of(context).push(MaterialPageRoute(
                  builder: (_) => const EquipmentListScreen(),
                  settings:
                      const RouteSettings(arguments: {'category': 'tractor'}))),
              style: ElevatedButton.styleFrom(
                  minimumSize: const Size.fromHeight(56)),
              child: const Text('Tractors', style: TextStyle(fontSize: 16)),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () => Navigator.of(context).push(MaterialPageRoute(
                  builder: (_) => const EquipmentListScreen(),
                  settings:
                      const RouteSettings(arguments: {'category': 'sprayer'}))),
              style: ElevatedButton.styleFrom(
                  minimumSize: const Size.fromHeight(56)),
              child: const Text('Sprayers', style: TextStyle(fontSize: 16)),
            ),
          ],
        ),
      ),
    );
  }
}
