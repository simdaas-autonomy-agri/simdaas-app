import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:simdaas/core/services/auth_service.dart';
import '../providers/users_providers.dart' as users_provs;

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authServiceProvider);
    final userId = auth.currentUserId ?? 'Unknown';
    final usersAsync = ref.watch(users_provs.usersListProvider);
    final singleUserAsync = (userId != 'Unknown')
        ? ref.watch(users_provs.userByIdProvider(userId))
        : null;

    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const CircleAvatar(radius: 28, child: Icon(Icons.person)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // If we have the user object stored from login, show it immediately
                      (auth.currentUserMap != null)
                          ? Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  auth.currentUserMap!['username']
                                          ?.toString() ??
                                      auth.currentUserMap!['name']
                                          ?.toString() ??
                                      'Unknown',
                                  style:
                                      Theme.of(context).textTheme.titleMedium,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  auth.currentUserMap!['email']?.toString() ??
                                      '—',
                                  style: Theme.of(context).textTheme.bodyMedium,
                                ),
                              ],
                            )
                          : usersAsync.when(
                              data: (users) {
                                // try to find the current user in the users list
                                final found = users
                                    .cast<Map<String, dynamic>?>()
                                    .firstWhere(
                                        (u) =>
                                            u != null &&
                                            (u['id']?.toString() ==
                                                userId.toString()),
                                        orElse: () => null);
                                if (found != null) {
                                  final displayName =
                                      found['name']?.toString() ??
                                          found['username']?.toString() ??
                                          'Unknown';
                                  final displayEmail =
                                      found['email']?.toString() ?? '—';
                                  return Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(displayName,
                                          style: Theme.of(context)
                                              .textTheme
                                              .titleMedium),
                                      const SizedBox(height: 4),
                                      Text(displayEmail,
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodyMedium),
                                    ],
                                  );
                                }

                                // Not found in list; try single-user lookup if available
                                if (singleUserAsync != null) {
                                  return singleUserAsync.when(
                                    data: (u) {
                                      if (u == null) {
                                        return Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(userId,
                                                style: Theme.of(context)
                                                    .textTheme
                                                    .titleMedium),
                                            const SizedBox(height: 4),
                                            Text('User details not available',
                                                style: Theme.of(context)
                                                    .textTheme
                                                    .bodySmall),
                                          ],
                                        );
                                      }
                                      final displayName =
                                          u['name']?.toString() ??
                                              u['username']?.toString() ??
                                              'Unknown';
                                      final displayEmail =
                                          u['email']?.toString() ?? '—';
                                      return Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(displayName,
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .titleMedium),
                                          const SizedBox(height: 4),
                                          Text(displayEmail,
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .bodyMedium),
                                        ],
                                      );
                                    },
                                    loading: () => Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(userId,
                                            style: Theme.of(context)
                                                .textTheme
                                                .titleMedium),
                                        const SizedBox(height: 4),
                                        const Text('Loading user info...'),
                                      ],
                                    ),
                                    error: (e, st) => Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(userId,
                                            style: Theme.of(context)
                                                .textTheme
                                                .titleMedium),
                                        const SizedBox(height: 4),
                                        Text('Failed to load user details',
                                            style: Theme.of(context)
                                                .textTheme
                                                .bodySmall),
                                      ],
                                    ),
                                  );
                                }

                                // No user data available at all
                                return Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Unknown',
                                        style: Theme.of(context)
                                            .textTheme
                                            .titleMedium),
                                    const SizedBox(height: 4),
                                    Text('No user information available',
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodySmall),
                                  ],
                                );
                              },
                              loading: () => Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(userId,
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleMedium),
                                  const SizedBox(height: 4),
                                  const SizedBox(height: 4),
                                  const Text('Loading user info...'),
                                ],
                              ),
                              error: (e, st) => Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(userId,
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleMedium),
                                  const SizedBox(height: 4),
                                  Text('Failed to load user details',
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall),
                                ],
                              ),
                            ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            // Additional profile fields from login response if available
            if (auth.currentUserMap != null) ...[
              Text('Profile', style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: 8),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Text('Type: ${auth.currentUserMap!['type'] ?? '—'}'),
                      // const SizedBox(height: 6),
                      Text(
                          'Joined: ${auth.currentUserMap!['date_joined'] ?? '—'}'),
                      const SizedBox(height: 6),
                      Text(
                          'Last login: ${auth.currentUserMap!['last_login'] ?? '—'}'),
                      // const SizedBox(height: 6),
                      // Text('Bio: ${auth.currentUserMap!['bio'] ?? ''}'),
                      // const SizedBox(height: 6),
                      // Text('Contact: ${auth.currentUserMap!['contact'] ?? ''}'),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text('Account', style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: 8),
            ] else ...[
              Text('Account', style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: 8),
            ],
            const SizedBox(height: 8),
            // ListTile(
            //   leading: const Icon(Icons.lock_outline),
            //   title: const Text('Change password'),
            //   onTap: () {
            //     // placeholder
            //     ScaffoldMessenger.of(context).showSnackBar(
            //         const SnackBar(content: Text('Not implemented')));
            //   },
            // ),
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('Sign out'),
              onTap: () async {
                await ref.read(authServiceProvider.notifier).signOut();
                if (context.mounted) {
                  Navigator.of(context).pushReplacementNamed('/login');
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}
