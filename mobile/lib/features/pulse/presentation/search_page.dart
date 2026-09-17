import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/domain/auth_models.dart';
import '../data/pulse_repository.dart';
import '../domain/pulse_models.dart';
import 'post_detail_page.dart';
import 'profile_page.dart';

class SearchPage extends ConsumerStatefulWidget {
  const SearchPage({
    required this.currentUser,
    required this.onUnauthorized,
    super.key,
  });

  final AuthUser currentUser;
  final Future<void> Function() onUnauthorized;

  @override
  ConsumerState<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends ConsumerState<SearchPage> {
  final TextEditingController _queryController = TextEditingController();

  List<PulseProfile> _users = const <PulseProfile>[];
  List<PulsePost> _posts = const <PulsePost>[];

  bool _isLoading = false;
  String? _errorMessage;
  int _requestGeneration = 0;

  @override
  void dispose() {
    _queryController.dispose();
    super.dispose();
  }

  Future<void> _search() async {
    final query = _queryController.text.trim();
    final requestGeneration = ++_requestGeneration;

    if (query.isEmpty) {
      if (!mounted) {
        return;
      }

      setState(() {
        _users = const <PulseProfile>[];
        _posts = const <PulsePost>[];
        _isLoading = false;
        _errorMessage = null;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final repository = ref.read(pulseRepositoryProvider);

    try {
      final usersFuture = repository.searchUsers(query);
      final postsFuture = repository.searchPosts(query);

      final users = await usersFuture;
      final posts = await postsFuture;

      if (!mounted || requestGeneration != _requestGeneration) {
        return;
      }

      setState(() {
        _users = users;
        _posts = posts;
        _isLoading = false;
      });
    } on DioException catch (error) {
      if (requestGeneration != _requestGeneration) {
        return;
      }

      if (error.response?.statusCode == 401) {
        await widget.onUnauthorized();
        return;
      }

      if (!mounted) {
        return;
      }

      setState(() {
        _isLoading = false;
        _errorMessage = _readError(error);
      });
    } on FormatException {
      if (!mounted || requestGeneration != _requestGeneration) {
        return;
      }

      setState(() {
        _isLoading = false;
        _errorMessage = 'Arama sonuçları okunamadı.';
      });
    }
  }

  void _clear() {
    _queryController.clear();
    _requestGeneration++;

    setState(() {
      _users = const <PulseProfile>[];
      _posts = const <PulsePost>[];
      _isLoading = false;
      _errorMessage = null;
    });
  }

  void _openProfile(PulseProfile profile) {
    Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (context) => ProfilePage(
          username: profile.username,
          isCurrentUser: profile.id == widget.currentUser.id,
          showAppBar: true,
          onUnauthorized: widget.onUnauthorized,
        ),
      ),
    );
  }

  Future<void> _openPost(PulsePost post) async {
    await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (context) =>
            PostDetailPage(post: post, onUnauthorized: widget.onUnauthorized),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasQuery = _queryController.text.trim().isNotEmpty;

    return Column(
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: TextField(
            key: const ValueKey<String>('pulse-search-field'),
            controller: _queryController,
            textInputAction: TextInputAction.search,
            onSubmitted: (_) => _search(),
            onChanged: (_) {
              _requestGeneration++;
              setState(() {
                _errorMessage = null;
              });
            },
            decoration: InputDecoration(
              hintText: 'Kullanıcı veya gönderi ara',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: hasQuery
                  ? IconButton(
                      tooltip: 'Temizle',
                      onPressed: _clear,
                      icon: const Icon(Icons.close),
                    )
                  : null,
              border: const OutlineInputBorder(),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              key: const ValueKey<String>('pulse-search-button'),
              onPressed: _isLoading || !hasQuery ? null : _search,
              icon: const Icon(Icons.search),
              label: const Text('Ara'),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Expanded(child: _buildResults()),
      ],
    );
  }

  Widget _buildResults() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return _SearchMessage(
        icon: Icons.error_outline,
        message: _errorMessage!,
        actionLabel: 'Tekrar Dene',
        onAction: _search,
      );
    }

    if (_queryController.text.trim().isEmpty) {
      return const _SearchMessage(
        icon: Icons.search,
        message: 'Kullanıcı adı veya gönderi metniyle arama yap.',
      );
    }

    if (_users.isEmpty && _posts.isEmpty) {
      return const _SearchMessage(
        icon: Icons.search_off_outlined,
        message: 'Arama sonucu bulunamadı.',
      );
    }

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: <Widget>[
        if (_users.isNotEmpty) ...<Widget>[
          Text('Kullanıcılar', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          ..._users.map(
            (profile) => ListTile(
              contentPadding: EdgeInsets.zero,
              leading: CircleAvatar(
                foregroundImage:
                    profile.avatarUrl == null ||
                        profile.avatarUrl!.trim().isEmpty
                    ? null
                    : NetworkImage(profile.avatarUrl!),
                child:
                    profile.avatarUrl == null ||
                        profile.avatarUrl!.trim().isEmpty
                    ? Text(_initial(profile.displayName, profile.username))
                    : null,
              ),
              title: Text(profile.displayName),
              subtitle: Text('@${profile.username}'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => _openProfile(profile),
            ),
          ),
        ],
        if (_users.isNotEmpty && _posts.isNotEmpty) const Divider(height: 32),
        if (_posts.isNotEmpty) ...<Widget>[
          Text('Gönderiler', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          ..._posts.map(
            (post) => Card(
              elevation: 0,
              child: ListTile(
                title: Text(
                  post.author.displayName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text('@${post.author.username}'),
                    const SizedBox(height: 4),
                    Text(
                      post.content,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _openPost(post),
              ),
            ),
          ),
        ],
      ],
    );
  }

  String _readError(DioException error) {
    final data = error.response?.data;

    if (data is Map<String, dynamic>) {
      final message = data['message'];

      if (message is String && message.trim().isNotEmpty) {
        return message;
      }
    }

    return 'Arama yapılamadı. Tekrar deneyin.';
  }

  String _initial(String displayName, String username) {
    final trimmedDisplayName = displayName.trim();

    if (trimmedDisplayName.isNotEmpty) {
      return trimmedDisplayName.characters.first.toUpperCase();
    }

    final trimmedUsername = username.trim();

    if (trimmedUsername.isNotEmpty) {
      return trimmedUsername.characters.first.toUpperCase();
    }

    return '?';
  }
}

class _SearchMessage extends StatelessWidget {
  const _SearchMessage({
    required this.icon,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(icon, size: 48),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            if (actionLabel != null && onAction != null) ...<Widget>[
              const SizedBox(height: 16),
              FilledButton(onPressed: onAction, child: Text(actionLabel!)),
            ],
          ],
        ),
      ),
    );
  }
}
