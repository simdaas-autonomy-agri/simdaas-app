import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../auth/presentation/providers/users_providers.dart';
import 'package:simdaas/core/widgets/api_error_widget.dart';

class OperatorListScreen extends ConsumerWidget {
  final bool showFab;
  const OperatorListScreen({Key? key, this.showFab = true}) : super(key: key);

  Future<void> _showAddOperatorDialog(
      BuildContext context, WidgetRef ref) async {
    final _nameController = TextEditingController();
    final _phoneController = TextEditingController();
    final _emailController = TextEditingController();
    final _addressController = TextEditingController();
    final _experienceController = TextEditingController();
    final _assignedMachineController = TextEditingController();
    final _shiftTimingController = TextEditingController();
    bool _isActive = true;

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Operator'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Name'),
              ),
              TextField(
                controller: _phoneController,
                decoration: const InputDecoration(labelText: 'Phone Number'),
                keyboardType: TextInputType.phone,
              ),
              TextField(
                controller: _emailController,
                decoration: const InputDecoration(labelText: 'Email'),
                keyboardType: TextInputType.emailAddress,
              ),
              TextField(
                controller: _addressController,
                decoration: const InputDecoration(labelText: 'Address'),
              ),
              TextField(
                controller: _experienceController,
                decoration:
                    const InputDecoration(labelText: 'Experience years'),
                keyboardType: TextInputType.number,
              ),
              TextField(
                controller: _assignedMachineController,
                decoration:
                    const InputDecoration(labelText: 'Assigned machine'),
              ),
              TextField(
                controller: _shiftTimingController,
                decoration: const InputDecoration(labelText: 'Shift timing'),
              ),
              Row(
                children: [
                  const Text('Active'),
                  const Spacer(),
                  StatefulBuilder(builder: (ctx, setState) {
                    return Switch(
                      value: _isActive,
                      onChanged: (v) => setState(() => _isActive = v),
                    );
                  })
                ],
              )
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final name = _nameController.text.trim();
              if (name.isEmpty) return;
              final phone = _phoneController.text.trim();
              final email = _emailController.text.trim();
              final address = _addressController.text.trim();
              final experience =
                  int.tryParse(_experienceController.text.trim());
              final assigned = _assignedMachineController.text.trim();
              final shift = _shiftTimingController.text.trim();
              await ref.read(operatorsControllerProvider).createOperator(
                    name: name,
                    contactNumber: phone,
                    email: email,
                    address: address,
                    experienceYears: experience,
                    assignedMachine: assigned,
                    shiftTiming: shift,
                    isActive: _isActive,
                  );
              Navigator.of(context).pop(true);
            },
            child: const Text('Add'),
          )
        ],
      ),
    );

    if (result == true) {
      // refresh list
      ref.invalidate(operatorsListProvider);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final opsAsync = ref.watch(operatorsListProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Operators')),
      body: opsAsync.when(
        data: (list) {
          if (list.isEmpty) {
            return const Center(child: Text('No operators yet'));
          }
          return ListView.separated(
            itemCount: list.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, idx) {
              final op = list[idx];
              return ListTile(
                title: Text(op['name'] ?? 'Unnamed'),
                subtitle: Text(op['phone'] ?? ''),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => ApiErrorWidget(
            error: e, onRetry: () => ref.invalidate(operatorsListProvider)),
      ),
      floatingActionButton: showFab
          ? FloatingActionButton(
              onPressed: () => _showAddOperatorDialog(context, ref),
              child: const Icon(Icons.add),
            )
          : null,
    );
  }
}
