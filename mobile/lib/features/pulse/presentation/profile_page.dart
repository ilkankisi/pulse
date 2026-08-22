import 'dart:async';

class _ProfilePostTile extends StatelessWidget {
  const _ProfilePostTile({required this.post});

  final PulsePost post;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Text(
            post.content,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
        ),
        const Divider(height: 1),
      ],
    );
  }
}

class _ProfileStateMessage extends StatelessWidget {
  const _ProfileStateMessage({
    required this.title,
    this.actionLabel,
    this.onAction,
  });

  final String title;
  final String? actionLabel;
  final Future<void> Function()? onAction;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
            ),
            if (actionLabel != null && onAction != null) ...<Widget>[
              const SizedBox(height: 12),
              FilledButton.tonal(
                onPressed: onAction,
                child: Text(actionLabel!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

final pulseRepositoryProvider = Provider<ProfilePage>((ref) {
  final dio = ref.watch(dioProvider);
  return ProfilePage(dio);
});

final pulseRepositoryProvider = Provider<ProfilePage>((ref) {
  final dio = ref.watch(dioProvider);
  return ProfilePage(dio);
});

final pulseRepositoryProvider = Provider<ProfilePage>((ref) {
  final dio = ref.watch(dioProvider);
  return ProfilePage(dio);
});

final pulseRepositoryProvider = Provider<ProfilePage>((ref) {
  final dio = ref.watch(dioProvider);
  return ProfilePage(dio);
});

final pulseRepositoryProvider = Provider<ProfilePage>((ref) {
  final dio = ref.watch(dioProvider);
  return ProfilePage(dio);
});

final pulseRepositoryProvider = Provider<ProfilePage>((ref) {
  final dio = ref.watch(dioProvider);
  return ProfilePage(dio);
});

final pulseRepositoryProvider = Provider<ProfilePage>((ref) {
  final dio = ref.watch(dioProvider);
  return ProfilePage(dio);
});

final pulseRepositoryProvider = Provider<ProfilePage>((ref) {
  final dio = ref.watch(dioProvider);
  return ProfilePage(dio);
});
