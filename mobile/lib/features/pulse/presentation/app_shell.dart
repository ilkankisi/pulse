import 'package:flutter/material.dart';

import '../../auth/domain/auth_models.dart';
import 'composer_sheet.dart';
import 'feed_page.dart';
import 'profile_page.dart';

class AppShell extends StatefulWidget {
  const AppShell({
    required this.currentUser,
    required this.onLogout,
    required this.onUnauthorized,
    super.key,
  });

  final AuthUser currentUser;
  final Future<void> Function() onLogout;
  final Future<void> Function() onUnauthorized;

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _selectedIndex = 0;
  int _feedRevision = 0;

  Future<void> _openComposer() async {
    final created = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      elevation: 3,
      builder: (context) =>
          ComposerSheet(onUnauthorized: widget.onUnauthorized),
    );

    if (created == true && mounted) {
      setState(() => _feedRevision++);
    }
  }

  Future<void> _logout() async {
    Navigator.of(context).popUntil((route) => route.isFirst);
    await widget.onLogout();
  }

  void _selectDestination(int index) {
    if (_selectedIndex == index) {
      return;
    }

    setState(() => _selectedIndex = index);
  }

  Widget _activePage() {
    return IndexedStack(
      index: _selectedIndex,
      children: <Widget>[
        FeedPage(
          key: ValueKey<int>(_feedRevision),
          currentUser: widget.currentUser,
          onUnauthorized: widget.onUnauthorized,
        ),
        ProfilePage(
          username: widget.currentUser.username,
          isCurrentUser: true,
          showAppBar: false,
          onUnauthorized: widget.onUnauthorized,
        ),
      ],
    );
  }

  Widget _navigationPanel({required bool closeAfterSelection}) {
    final theme = Theme.of(context);

    return SizedBox(
      width: 300,
      child: Material(
        color: theme.colorScheme.surfaceContainerHighest,
        child: SafeArea(
          child: Column(
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: <Widget>[
                    CircleAvatar(
                      radius: 24,
                      backgroundImage: widget.currentUser.avatarUrl == null
                          ? null
                          : NetworkImage(widget.currentUser.avatarUrl!),
                      child: widget.currentUser.avatarUrl == null
                          ? Text(
                              widget.currentUser.displayName
                                  .substring(0, 1)
                                  .toUpperCase(),
                            )
                          : null,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            widget.currentUser.displayName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.titleMedium,
                          ),
                          Text(
                            '@${widget.currentUser.username}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: NavigationDrawer(
                  selectedIndex: _selectedIndex,
                  onDestinationSelected: (index) {
                    _selectDestination(index);

                    if (closeAfterSelection) {
                      Navigator.of(context).pop();
                    }
                  },
                  children: const <Widget>[
                    NavigationDrawerDestination(
                      icon: Icon(Icons.home_outlined),
                      selectedIcon: Icon(Icons.home),
                      label: Text('Ana Akış'),
                    ),
                    NavigationDrawerDestination(
                      icon: Icon(Icons.person_outline),
                      selectedIcon: Icon(Icons.person),
                      label: Text('Profil'),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.logout),
                title: const Text('Çıkış yap'),
                onTap: _logout,
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 600;
        final expanded = constraints.maxWidth >= 1024;

        final contentScaffold = Scaffold(
          appBar: expanded
              ? null
              : AppBar(
                  title: Text(_selectedIndex == 0 ? 'Ana Akış' : 'Profil'),
                ),
          drawer: compact
              ? Drawer(
                  width: 300,
                  child: _navigationPanel(closeAfterSelection: true),
                )
              : null,
          bottomNavigationBar: compact
              ? NavigationBar(
                  height: 64,
                  selectedIndex: _selectedIndex,
                  onDestinationSelected: _selectDestination,
                  destinations: const <NavigationDestination>[
                    NavigationDestination(
                      icon: Icon(Icons.home_outlined),
                      selectedIcon: Icon(Icons.home),
                      label: 'Ana Akış',
                    ),
                    NavigationDestination(
                      icon: Icon(Icons.person_outline),
                      selectedIcon: Icon(Icons.person),
                      label: 'Profil',
                    ),
                  ],
                )
              : null,
          floatingActionButton: _selectedIndex == 0
              ? FloatingActionButton.extended(
                  onPressed: _openComposer,
                  icon: const Icon(Icons.edit_outlined),
                  label: const Text('Gönder'),
                )
              : null,
          body: SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 720),
                child: _activePage(),
              ),
            ),
          ),
        );

        if (compact) {
          return contentScaffold;
        }

        if (expanded) {
          return Row(
            children: <Widget>[
              _navigationPanel(closeAfterSelection: false),
              Expanded(child: contentScaffold),
            ],
          );
        }

        return Row(
          children: <Widget>[
            NavigationRail(
              selectedIndex: _selectedIndex,
              onDestinationSelected: _selectDestination,
              labelType: NavigationRailLabelType.all,
              trailing: IconButton(
                tooltip: 'Çıkış yap',
                onPressed: _logout,
                icon: const Icon(Icons.logout),
              ),
              destinations: const <NavigationRailDestination>[
                NavigationRailDestination(
                  icon: Icon(Icons.home_outlined),
                  selectedIcon: Icon(Icons.home),
                  label: Text('Ana Akış'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.person_outline),
                  selectedIcon: Icon(Icons.person),
                  label: Text('Profil'),
                ),
              ],
            ),
            const VerticalDivider(width: 1),
            Expanded(child: contentScaffold),
          ],
        );
      },
    );
  }
}
