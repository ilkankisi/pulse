import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/pulse_repository.dart';
import '../data/safety_moderation_api.dart';
import '../domain/moderation_models.dart';
import '../domain/pulse_models.dart';
import 'blocked_users_page.dart';
import 'report_sheet.dart';

class ProfilePage extends ConsumerStatefulWidget {
  const ProfilePage({
    super.key,
    this.username,
    this.initialProfile,
    this.loadProfile,
    this.updateProfile,
    this.isCurrentUser,
    this.showAppBar = true,
    this.onUnauthorized,
  });

  final String? username;
  final PulseProfile? initialProfile;
  final Future<PulseProfile?> Function()? loadProfile;
  final Future<PulseProfile> Function(UpdateProfileRequest request)?
  updateProfile;
  final bool? isCurrentUser;
  final bool showAppBar;
  final VoidCallback? onUnauthorized;

  @override
  ConsumerState<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends ConsumerState<ProfilePage> {
  PulseProfile? _profile;
  List<PulsePost> _posts = const <PulsePost>[];

  Object? _profileError;
  Object? _postsError;

  bool _isLoadingProfile = true;
  bool _isLoadingPosts = true;
  bool _isBlocked = false;

  bool get _isOwnProfile =>
      widget.isCurrentUser ??
      (widget.username == null || (_profile?.isCurrentUser ?? false));

  String? get _profileUsername {
    final loadedUsername = _profile?.username.trim();

    if (loadedUsername != null && loadedUsername.isNotEmpty) {
      return loadedUsername;
    }

    final requestedUsername = widget.username?.trim();

    if (requestedUsername != null && requestedUsername.isNotEmpty) {
      return requestedUsername;
    }

    return null;
  }

  @override
  void initState() {
    super.initState();

    _profile = widget.initialProfile;
    _isLoadingProfile = widget.initialProfile == null;

    Future<void>.microtask(_refreshProfileAndPosts);
  }

  Future<void> _refreshProfileAndPosts() async {
    await _loadProfile(showLoading: _profile == null);

    if (!mounted || _profileError != null || _profile == null) {
      return;
    }

    await _loadPosts();
  }

  Future<void> _loadProfile({bool showLoading = true}) async {
    if (!mounted) {
      return;
    }

    setState(() {
      if (showLoading) {
        _isLoadingProfile = true;
      }

      _profileError = null;
    });

    try {
      final profile = widget.loadProfile != null
          ? await widget.loadProfile!()
          : widget.username == null
          ? await ref.read(pulseRepositoryProvider).getMyProfile()
          : await ref
                .read(pulseRepositoryProvider)
                .getProfile(widget.username!);

      if (!mounted) {
        return;
      }

      setState(() {
        _profile = profile;
        _isLoadingProfile = false;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _profileError = error;
        _isLoadingProfile = false;
      });
    }
  }

  Future<void> _loadPosts() async {
    final username = _profileUsername;

    if (username == null) {
      if (!mounted) {
        return;
      }

      setState(() {
        _posts = const <PulsePost>[];
        _postsError = null;
        _isLoadingPosts = false;
      });
      return;
    }

    if (!mounted) {
      return;
    }

    final request = ref.read(pulseRepositoryProvider).getProfilePosts(username);

    setState(() {
      _isLoadingPosts = true;
      _postsError = null;
    });

    try {
      final result = await request;

      if (!mounted) {
        return;
      }

      setState(() {
        _posts = List<PulsePost>.unmodifiable(result);
        _postsError = null;
        _isLoadingPosts = false;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _postsError = error;
        _isLoadingPosts = false;
      });
    }
  }

  Future<void> _retryPosts() async {
    await _loadPosts();
  }

  Future<void> _toggleBlock() async {
    final username = _profileUsername;

    if (username == null || _isOwnProfile) {
      return;
    }

    try {
      if (_isBlocked) {
        await ref.read(safetyModerationApiProvider).unblockUser(username);
      } else {
        await ref.read(safetyModerationApiProvider).blockUser(username);
      }

      if (!mounted) {
        return;
      }

      setState(() {
        _isBlocked = !_isBlocked;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _isBlocked
                ? '@$username engellendi.'
                : '@$username engeli kaldırıldı.',
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } on DioException catch (error) {
      if (!mounted) {
        return;
      }

      if (error.response?.statusCode == 401) {
        widget.onUnauthorized?.call();
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('İşlem tamamlanamadı. Tekrar deneyin.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _reportUser() async {
    final profile = _profile;

    if (profile == null || _isOwnProfile) {
      return;
    }

    final sent = await ReportSheet.show(
      context,
      targetType: ReportTargetType.user,
      targetId: profile.id,
      onUnauthorized: widget.onUnauthorized,
    );

    if (!mounted || !sent) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Şikâyet gönderildi.'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _reportPost(PulsePost post) async {
    final sent = await ReportSheet.show(
      context,
      targetType: ReportTargetType.post,
      targetId: post.id,
      onUnauthorized: widget.onUnauthorized,
    );

    if (!mounted || !sent) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Şikâyet gönderildi.'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _openBlockedUsers() async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) {
          return BlockedUsersPage(onUnauthorized: widget.onUnauthorized);
        },
      ),
    );
  }

  Future<void> _editProfile() async {
    final profile = _profile;

    if (profile == null) {
      return;
    }

    final updatedProfile = await showDialog<PulseProfile>(
      context: context,
      builder: (_) {
        return _EditProfileDialog(
          profile: profile,
          onSave: (request) async {
            final updateProfile = widget.updateProfile;

            if (updateProfile != null) {
              return updateProfile(request);
            }

            return ref.read(pulseRepositoryProvider).updateMyProfile(request);
          },
        );
      },
    );

    if (!mounted || updatedProfile == null) {
      return;
    }

    setState(() {
      _profile = updatedProfile;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Profil güncellendi.'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final body = _buildBody(context);

    if (!widget.showAppBar) {
      return body;
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Profil')),
      body: body,
    );
  }

  Widget _buildBody(BuildContext context) {
    if (_isLoadingProfile && _profile == null) {
      return const SafeArea(child: Center(child: CircularProgressIndicator()));
    }

    if (_profileError != null || _profile == null) {
      return SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 360),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.error_outline, size: 48),
                  const SizedBox(height: 16),
                  Text(
                    'Profil yüklenemedi',
                    style: Theme.of(context).textTheme.titleLarge,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  FilledButton(
                    onPressed: _refreshProfileAndPosts,
                    child: const Text('Tekrar Dene'),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return _buildProfile(context, _profile!);
  }

  Widget _buildProfile(BuildContext context, PulseProfile profile) {
    final avatarUrl = profile.avatarUrl?.trim();

    return SafeArea(
      child: RefreshIndicator(
        onRefresh: _refreshProfileAndPosts,
        triggerMode: RefreshIndicatorTriggerMode.anywhere,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              sliver: SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CircleAvatar(
                          radius: 40,
                          backgroundImage:
                              avatarUrl != null && avatarUrl.isNotEmpty
                              ? NetworkImage(avatarUrl)
                              : null,
                          child: avatarUrl == null || avatarUrl.isEmpty
                              ? Text(
                                  profile.displayName.isEmpty
                                      ? '?'
                                      : profile.displayName.characters.first
                                            .toUpperCase(),
                                )
                              : null,
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                profile.displayName,
                                style: Theme.of(context).textTheme.titleLarge,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '@${profile.username}',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                              if (profile.bio?.trim().isNotEmpty ?? false) ...[
                                const SizedBox(height: 12),
                                Text(profile.bio!.trim()),
                              ],
                            ],
                          ),
                        ),
                        if (!_isOwnProfile)
                          PopupMenuButton<_ProfileSafetyAction>(
                            tooltip: 'Güvenlik seçenekleri',
                            onSelected: (action) {
                              switch (action) {
                                case _ProfileSafetyAction.block:
                                  _toggleBlock();
                                  break;
                                case _ProfileSafetyAction.report:
                                  _reportUser();
                                  break;
                              }
                            },
                            itemBuilder: (_) {
                              return [
                                PopupMenuItem<_ProfileSafetyAction>(
                                  value: _ProfileSafetyAction.block,
                                  child: Text(
                                    _isBlocked
                                        ? 'Engeli Kaldır'
                                        : 'Kullanıcıyı Engelle',
                                  ),
                                ),
                                const PopupMenuItem<_ProfileSafetyAction>(
                                  value: _ProfileSafetyAction.report,
                                  child: Text('Kullanıcıyı Şikâyet Et'),
                                ),
                              ];
                            },
                          ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        _ProfileStat(
                          value: profile.postCount,
                          label: 'Gönderi',
                        ),
                        const SizedBox(width: 24),
                        _ProfileStat(
                          value: profile.followerCount,
                          label: 'Takipçi',
                        ),
                        const SizedBox(width: 24),
                        _ProfileStat(
                          value: profile.followingCount,
                          label: 'Takip',
                        ),
                      ],
                    ),
                    if (_isOwnProfile) ...[
                      const SizedBox(height: 20),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          OutlinedButton.icon(
                            onPressed: _editProfile,
                            icon: const Icon(Icons.edit_outlined),
                            label: const Text('Profili Düzenle'),
                          ),
                          OutlinedButton.icon(
                            onPressed: _openBlockedUsers,
                            icon: const Icon(Icons.block_outlined),
                            label: const Text('Engellenen Hesaplar'),
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 24),
                    Text(
                      'Gönderiler',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 12),
                  ],
                ),
              ),
            ),
            if (_isLoadingPosts)
              const SliverFillRemaining(
                hasScrollBody: false,
                child: Center(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: CircularProgressIndicator(),
                  ),
                ),
              )
            else if (_postsError != null)
              SliverFillRemaining(
                hasScrollBody: false,
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 360),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.error_outline, size: 48),
                          const SizedBox(height: 16),
                          Text(
                            'Gönderiler yüklenemedi',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const SizedBox(height: 8),
                          FilledButton(
                            onPressed: _retryPosts,
                            child: const Text('Tekrar Dene'),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              )
            else if (_posts.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 360),
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.forum_outlined, size: 48),
                          const SizedBox(height: 16),
                          Text(
                            'Henüz gönderi yok',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate((context, index) {
                    final post = _posts[index];

                    return Padding(
                      padding: EdgeInsets.only(
                        bottom: index == _posts.length - 1 ? 0 : 12,
                      ),
                      child: _ProfilePostCard(
                        post: post,
                        onReport: _isOwnProfile
                            ? null
                            : () => _reportPost(post),
                      ),
                    );
                  }, childCount: _posts.length),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _ProfileStat extends StatelessWidget {
  const _ProfileStat({required this.value, required this.label});

  final int value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('$value', style: Theme.of(context).textTheme.titleMedium),
        Text(label, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}

class _ProfilePostCard extends StatelessWidget {
  const _ProfilePostCard({required this.post, this.onReport});

  final PulsePost post;
  final VoidCallback? onReport;

  @override
  Widget build(BuildContext context) {
    final avatarUrl = post.author.avatarUrl?.trim();

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              radius: 20,
              backgroundImage: avatarUrl != null && avatarUrl.isNotEmpty
                  ? NetworkImage(avatarUrl)
                  : null,
              child: avatarUrl == null || avatarUrl.isEmpty
                  ? Text(
                      post.author.displayName.isEmpty
                          ? '?'
                          : post.author.displayName.characters.first
                                .toUpperCase(),
                    )
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Wrap(
                          spacing: 6,
                          runSpacing: 2,
                          children: [
                            Text(
                              post.author.displayName,
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            Text(
                              '@${post.author.username}',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                      if (onReport != null)
                        IconButton(
                          tooltip: 'Gönderiyi şikâyet et',
                          onPressed: onReport,
                          icon: const Icon(Icons.flag_outlined),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(post.content),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Icon(
                        post.isLiked
                            ? Icons.favorite
                            : Icons.favorite_border_outlined,
                        size: 18,
                      ),
                      const SizedBox(width: 4),
                      Text('${post.likeCount}'),
                      const SizedBox(width: 20),
                      const Icon(Icons.chat_bubble_outline, size: 18),
                      const SizedBox(width: 4),
                      Text('${post.replyCount}'),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

enum _ProfileSafetyAction { block, report }

class _EditProfileDialog extends StatefulWidget {
  const _EditProfileDialog({required this.profile, required this.onSave});

  final PulseProfile profile;
  final Future<PulseProfile> Function(UpdateProfileRequest request) onSave;

  @override
  State<_EditProfileDialog> createState() => _EditProfileDialogState();
}

class _EditProfileDialogState extends State<_EditProfileDialog> {
  late final TextEditingController _displayNameController;
  late final TextEditingController _bioController;
  late final TextEditingController _avatarUrlController;

  bool _isSaving = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();

    _displayNameController = TextEditingController(
      text: widget.profile.displayName,
    );
    _bioController = TextEditingController(text: widget.profile.bio ?? '');
    _avatarUrlController = TextEditingController(
      text: widget.profile.avatarUrl ?? '',
    );
  }

  @override
  void dispose() {
    _displayNameController.dispose();
    _bioController.dispose();
    _avatarUrlController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_isSaving) {
      return;
    }

    final displayName = _displayNameController.text.trim();
    final bio = _bioController.text.trim();
    final avatarUrl = _avatarUrlController.text.trim();

    if (displayName.isEmpty) {
      setState(() {
        _errorMessage = 'Görünen ad boş bırakılamaz.';
      });
      return;
    }

    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    try {
      final updatedProfile = await widget.onSave(
        UpdateProfileRequest(
          displayName: displayName,
          bio: bio,
          avatarUrl: avatarUrl,
        ),
      );

      if (!mounted) {
        return;
      }

      Navigator.of(context).pop(updatedProfile);
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isSaving = false;
        _errorMessage = 'Profil güncellenemedi.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Profili Düzenle'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              key: const ValueKey<String>('profile-display-name-field'),
              controller: _displayNameController,
              enabled: !_isSaving,
              decoration: const InputDecoration(labelText: 'Görünen ad'),
            ),
            const SizedBox(height: 12),
            TextField(
              key: const ValueKey<String>('profile-bio-field'),
              controller: _bioController,
              enabled: !_isSaving,
              minLines: 2,
              maxLines: 4,
              decoration: const InputDecoration(labelText: 'Biyografi'),
            ),
            const SizedBox(height: 12),
            TextField(
              key: const ValueKey<String>('profile-avatar-url-field'),
              controller: _avatarUrlController,
              enabled: !_isSaving,
              decoration: const InputDecoration(labelText: 'Avatar URL'),
            ),
            if (_errorMessage != null) ...[
              const SizedBox(height: 12),
              Text(
                _errorMessage!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSaving ? null : () => Navigator.of(context).pop(),
          child: const Text('İptal'),
        ),
        FilledButton(
          onPressed: _isSaving ? null : _save,
          child: _isSaving
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Kaydet'),
        ),
      ],
    );
  }
}
