import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/pulse_repository.dart';
import '../domain/pulse_models.dart';
import 'profile_page.dart';

enum SocialGraphKind { followers, following }

typedef SocialGraphUser = PulseSocialGraphUser;

class SocialGraphPage extends StatefulWidget {
  const SocialGraphPage({
    super.key,
    required this.username,
    required this.kind,
    required this.isCurrentUser,
    required this.loadUsers,
    this.removeFollower,
  });

  final String username;
  final SocialGraphKind kind;
  final bool isCurrentUser;
  final Future<List<SocialGraphUser>> Function() loadUsers;
  final Future<void> Function(String username)? removeFollower;

  @override
  State<SocialGraphPage> createState() => _SocialGraphPageState();
}

class _SocialGraphPageState extends State<SocialGraphPage> {
  List<SocialGraphUser> _users = const <SocialGraphUser>[];
  bool _isLoading = true;
  Object? _error;
  final Set<String> _removingUsers = <String>{};

  String get _title {
    switch (widget.kind) {
      case SocialGraphKind.followers:
        return 'Takipçiler';
      case SocialGraphKind.following:
        return 'Takip Edilenler';
    }
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (mounted) {
      setState(() {
        _isLoading = true;
        _error = null;
      });
    }

    try {
      final users = await widget.loadUsers();

      if (!mounted) {
        return;
      }

      setState(() {
        _users = List<SocialGraphUser>.unmodifiable(users);
        _isLoading = false;
        _error = null;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isLoading = false;
        _error = error;
      });
    }
  }

  Future<void> _removeFollower(SocialGraphUser user) async {
    final removeFollower = widget.removeFollower;

    if (removeFollower == null || _removingUsers.contains(user.username)) {
      return;
    }

    setState(() {
      _removingUsers.add(user.username);
    });

    try {
      await removeFollower(user.username);

      if (!mounted) {
        return;
      }

      setState(() {
        _users = List<SocialGraphUser>.unmodifiable(
          _users.where((item) => item.username != user.username),
        );
        _removingUsers.remove(user.username);
      });
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(() {
        _removingUsers.remove(user.username);
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Takipçi kaldırılamadı. Tekrar deneyin.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _openProfile(SocialGraphUser user) async {
    final profile = PulseProfile(
      id: user.id,
      username: user.username,
      displayName: user.displayName,
      avatarUrl: user.avatarUrl,
      followerCount: 0,
      followingCount: 0,
      postCount: 0,
      isFollowing: user.isFollowing,
      isCurrentUser: false,
    );

    var hasParentProviderScope = true;

    try {
      ProviderScope.containerOf(context, listen: false);
    } on StateError {
      hasParentProviderScope = false;
    }

    if (!mounted) {
      return;
    }

    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) {
          final profilePage = ProfilePage(
            username: user.username,
            initialProfile: profile,
            loadProfile: () async => profile,
            isCurrentUser: false,
          );

          if (hasParentProviderScope) {
            return profilePage;
          }

          return ProviderScope(
            overrides: [
              pulseRepositoryProvider.overrideWithValue(
                _FallbackSocialGraphProfileRepository(),
              ),
            ],
            child: profilePage,
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_title)),
      body: _buildBody(context),
    );
  }

  Widget _buildBody(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48),
            const SizedBox(height: 16),
            Text(
              'Liste yüklenemedi',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            FilledButton(onPressed: _load, child: const Text('Tekrar Dene')),
          ],
        ),
      );
    }

    if (_users.isEmpty) {
      return const Center(child: Text('Henüz kimse yok'));
    }

    return ListView.separated(
      itemCount: _users.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final user = _users[index];
        final avatarUrl = user.avatarUrl?.trim();
        final canRemove =
            widget.kind == SocialGraphKind.followers &&
            widget.isCurrentUser &&
            widget.removeFollower != null;
        final isRemoving = _removingUsers.contains(user.username);

        return ListTile(
          key: ValueKey<String>('social-user-${user.username}'),
          leading: CircleAvatar(
            backgroundImage: avatarUrl != null && avatarUrl.isNotEmpty
                ? NetworkImage(avatarUrl)
                : null,
            child: avatarUrl == null || avatarUrl.isEmpty
                ? Text(
                    user.displayName.isEmpty
                        ? '?'
                        : user.displayName.characters.first.toUpperCase(),
                  )
                : null,
          ),
          title: Text(user.displayName),
          subtitle: Text('@${user.username}'),
          onTap: () {
            _openProfile(user);
          },
          trailing: canRemove
              ? TextButton(
                  key: ValueKey<String>('remove-follower-${user.username}'),
                  onPressed: isRemoving
                      ? null
                      : () {
                          _removeFollower(user);
                        },
                  child: isRemoving
                      ? const SizedBox.square(
                          dimension: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Kaldır'),
                )
              : null,
        );
      },
    );
  }
}

class _FallbackSocialGraphProfileRepository extends PulseRepository {
  _FallbackSocialGraphProfileRepository() : super(dio: Dio());

  @override
  Future<List<PulsePost>> getProfilePosts(String username) async {
    return const <PulsePost>[];
  }
}
