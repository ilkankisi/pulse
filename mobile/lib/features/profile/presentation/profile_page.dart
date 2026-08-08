import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../pulse/data/pulse_repository.dart';
import '../../pulse/domain/pulse_models.dart';

class ProfilePage extends ConsumerStatefulWidget {
  const ProfilePage({
    super.key,
    this.username,
    this.initialProfile,
    this.loadProfile,
    this.updateProfile,
  });

  final String? username;
  final PulseProfile? initialProfile;
  final Future<PulseProfile?> Function()? loadProfile;
  final Future<PulseProfile> Function(UpdateProfileRequest request)?
  updateProfile;

  @override
  ConsumerState<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends ConsumerState<ProfilePage> {
  PulseProfile? _profile;
  Object? _error;
  bool _isLoading = true;

  bool get _isOwnProfile =>
      widget.username == null || (_profile?.isCurrentUser ?? false);

  @override
  void initState() {
    super.initState();
    _profile = widget.initialProfile;
    _isLoading = widget.initialProfile == null;

    if (_isLoading) {
      Future<void>.microtask(_loadProfile);
    }
  }

  Future<void> _loadProfile() async {
    if (mounted) {
      setState(() {
        _isLoading = true;
        _error = null;
      });
    }

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
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _error = error;
        _isLoading = false;
      });
    }
  }

  Future<void> _openEditDialog() async {
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
    if (_isLoading) {
      return const SafeArea(child: Center(child: CircularProgressIndicator()));
    }

    if (_error != null || _profile == null) {
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
                  ),
                  const SizedBox(height: 8),
                  FilledButton(
                    onPressed: _loadProfile,
                    child: const Text('Tekrar Dene'),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    final profile = _profile!;
    final avatarUrl = profile.avatarUrl?.trim();

    return SafeArea(
      child: RefreshIndicator(
        onRefresh: _loadProfile,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 40,
                  backgroundImage: avatarUrl == null || avatarUrl.isEmpty
                      ? null
                      : NetworkImage(avatarUrl),
                  child: avatarUrl == null || avatarUrl.isEmpty
                      ? Text(
                          profile.displayName.isEmpty
                              ? '?'
                              : profile.displayName[0].toUpperCase(),
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
                    ],
                  ),
                ),
              ],
            ),
            if (profile.bio?.trim().isNotEmpty ?? false) ...[
              const SizedBox(height: 16),
              Text(profile.bio!.trim()),
            ],
            const SizedBox(height: 16),
            Wrap(
              spacing: 16,
              runSpacing: 8,
              children: [
                _ProfileCount(value: profile.postCount, label: 'Gönderi'),
                _ProfileCount(value: profile.followerCount, label: 'Takipçi'),
                _ProfileCount(value: profile.followingCount, label: 'Takip'),
              ],
            ),
            if (_isOwnProfile) ...[
              const SizedBox(height: 24),
              OutlinedButton.icon(
                onPressed: _openEditDialog,
                icon: const Icon(Icons.edit_outlined),
                label: const Text('Profili Düzenle'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ProfileCount extends StatelessWidget {
  const _ProfileCount({required this.value, required this.label});

  final int value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '$label: $value',
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('$value', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(width: 4),
          Text(label, style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    );
  }
}

class _EditProfileDialog extends StatefulWidget {
  const _EditProfileDialog({required this.profile, required this.onSave});

  final PulseProfile profile;
  final Future<PulseProfile> Function(UpdateProfileRequest request) onSave;

  @override
  State<_EditProfileDialog> createState() => _EditProfileDialogState();
}

class _EditProfileDialogState extends State<_EditProfileDialog> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  late final TextEditingController _displayNameController;
  late final TextEditingController _bioController;
  late final TextEditingController _avatarUrlController;

  bool _isSaving = false;
  String? _saveError;

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
    if (_isSaving || !(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    setState(() {
      _isSaving = true;
      _saveError = null;
    });

    try {
      final updatedProfile = await widget.onSave(
        UpdateProfileRequest(
          displayName: _displayNameController.text.trim(),
          bio: _bioController.text.trim(),
          avatarUrl: _avatarUrlController.text.trim(),
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
        _saveError = 'Profil güncellenemedi. Tekrar deneyin.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Profili Düzenle'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                key: const ValueKey<String>('profile-display-name-field'),
                controller: _displayNameController,
                enabled: !_isSaving,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(labelText: 'Görünen ad'),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Görünen ad zorunludur.';
                  }

                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                key: const ValueKey<String>('profile-bio-field'),
                controller: _bioController,
                enabled: !_isSaving,
                textInputAction: TextInputAction.next,
                minLines: 2,
                maxLines: 4,
                decoration: const InputDecoration(labelText: 'Biyografi'),
              ),
              const SizedBox(height: 12),
              TextFormField(
                key: const ValueKey<String>('profile-avatar-url-field'),
                controller: _avatarUrlController,
                enabled: !_isSaving,
                keyboardType: TextInputType.url,
                textInputAction: TextInputAction.done,
                onFieldSubmitted: (_) {
                  _save();
                },
                decoration: const InputDecoration(labelText: 'Avatar URL'),
              ),
              if (_saveError != null) ...[
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    _saveError!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSaving
              ? null
              : () {
                  Navigator.of(context).pop();
                },
          child: const Text('İptal'),
        ),
        FilledButton(
          key: const ValueKey<String>('profile-save-button'),
          onPressed: _isSaving ? null : _save,
          child: _isSaving
              ? const SizedBox.square(
                  dimension: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Kaydet'),
        ),
      ],
    );
  }
}
