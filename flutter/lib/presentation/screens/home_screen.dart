import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import '../cubits/note_cubit.dart';
import '../cubits/crypto_cubit.dart';
import '../widgets/note_card.dart';
import '../../domain/entities/note.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  bool _isGridView = true;
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: _selectedIndex == 0
            ? const Text('VaultNote')
            : _selectedIndex == 1
                ? const Text('Archived')
                : const Text('Settings'),
        actions: [
          if (_selectedIndex == 0) ...[
            IconButton(
              icon: Icon(_isGridView ? Icons.view_list : Icons.grid_view),
              onPressed: () {
                setState(() {
                  _isGridView = !_isGridView;
                });
              },
            ),
            IconButton(
              icon: const Icon(Icons.search),
              onPressed: () {
                showSearch(context: context, delegate: NoteSearchDelegate());
              },
            ),
          ],
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.pushNamed(context, '/settings');
            },
          ),
        ],
      ),
      body: _selectedIndex == 2
          ? const SettingsPreview()
          : BlocBuilder<NoteCubit, NoteState>(
              builder: (context, state) {
                if (state.isLoading) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (state.error != null) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.error_outline,
                            size: 64,
                            color: Colors.red,
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'Something went wrong',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            state.error!,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.grey.shade600,
                            ),
                          ),
                          const SizedBox(height: 24),
                          ElevatedButton.icon(
                            onPressed: () {
                              context.read<NoteCubit>().loadNotes();
                            },
                            icon: const Icon(Icons.refresh),
                            label: const Text('Try Again'),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                final notes = _selectedIndex == 0
                    ? state.filteredNotes
                    : state.notes.where((n) => n.archived).toList();

                if (notes.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          _selectedIndex == 0
                              ? Icons.note_add_outlined
                              : Icons.archive_outlined,
                          size: 64,
                          color: Colors.grey,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _selectedIndex == 0
                              ? 'No notes yet'
                              : 'No archived notes',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _selectedIndex == 0
                              ? 'Tap + to create your first note'
                              : 'Archived notes will appear here',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: Colors.grey,
                              ),
                        ),
                      ],
                    ),
                  );
                }

                if (_isGridView) {
                  return MasonryGridView.count(
                    crossAxisCount: 2,
                    mainAxisSpacing: 8,
                    crossAxisSpacing: 8,
                    padding: const EdgeInsets.all(8),
                    itemCount: notes.length,
                    itemBuilder: (context, index) {
                      return NoteCard(
                        note: notes[index],
                        onTap: () => _openNote(notes[index]),
                        onPin: () => _togglePin(notes[index]),
                        onArchive: () => _archiveNote(notes[index]),
                        onLongPress: () => _showNoteOptions(notes[index]),
                      );
                    },
                  );
                } else {
                  return ListView.builder(
                    padding: const EdgeInsets.all(8),
                    itemCount: notes.length,
                    itemBuilder: (context, index) {
                      return NoteCard(
                        note: notes[index],
                        onTap: () => _openNote(notes[index]),
                        onPin: () => _togglePin(notes[index]),
                        onArchive: () => _archiveNote(notes[index]),
                        onLongPress: () => _showNoteOptions(notes[index]),
                        isCompact: true,
                      );
                    },
                  );
                }
              },
            ),
      floatingActionButton: _selectedIndex != 2
          ? FloatingActionButton.extended(
              onPressed: () {
                Navigator.pushNamed(context, '/note/new');
              },
              icon: const Icon(Icons.add),
              label: const Text('New Note'),
            )
          : null,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.archive_outlined),
            selectedIcon: Icon(Icons.archive),
            label: 'Archived',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
    );
  }

  void _openNote(Note note) {
    Navigator.pushNamed(
      context,
      '/note/edit',
      arguments: note,
    ).then((_) {
      context.read<NoteCubit>().loadNotes();
    });
  }

  void _togglePin(Note note) {
    context.read<NoteCubit>().togglePin(note.id);
  }

  void _archiveNote(Note note) {
    context.read<NoteCubit>().archiveNote(note.id, !note.archived);
  }

  void _showNoteOptions(Note note) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.share),
              title: const Text('Export as QR'),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/qr-export', arguments: note);
              },
            ),
            ListTile(
              leading: Icon(note.pinned ? Icons.push_pin : Icons.push_pin_outlined),
              title: Text(note.pinned ? 'Unpin' : 'Pin'),
              onTap: () {
                Navigator.pop(context);
                _togglePin(note);
              },
            ),
            ListTile(
              leading: Icon(note.archived ? Icons.unarchive : Icons.archive),
              title: Text(note.archived ? 'Unarchive' : 'Archive'),
              onTap: () {
                Navigator.pop(context);
                _archiveNote(note);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: const Text('Delete', style: TextStyle(color: Colors.red)),
              onTap: () {
                Navigator.pop(context);
                _confirmDelete(note);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(Note note) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Note'),
        content: const Text('Are you sure you want to delete this note? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              context.read<NoteCubit>().deleteNote(note.id);
            },
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

class NoteSearchDelegate extends SearchDelegate<String?> {
  @override
  List<Widget> buildActions(BuildContext context) {
    return [
      if (query.isNotEmpty)
        IconButton(
          icon: const Icon(Icons.clear),
          onPressed: () {
            query = '';
          },
        ),
    ];
  }

  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () {
        close(context, null);
      },
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    if (query.isEmpty) {
      return const Center(child: Text('Enter a search term'));
    }
    return BlocBuilder<NoteCubit, NoteState>(
      builder: (context, state) {
        final results = state.notes.where((note) {
          final q = query.toLowerCase();
          return note.title.toLowerCase().contains(q) ||
              note.body.toLowerCase().contains(q);
        }).toList();

        if (results.isEmpty) {
          return const Center(child: Text('No results found'));
        }

        return ListView.builder(
          itemCount: results.length,
          itemBuilder: (context, index) {
            final note = results[index];
            return ListTile(
              title: Text(note.title),
              subtitle: Text(
                note.body.length > 50
                    ? '${note.body.substring(0, 50)}...'
                    : note.body,
              ),
              onTap: () {
                close(context, note.id);
              },
            );
          },
        );
      },
    );
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    if (query.isEmpty) {
      return const Center(child: Text('Start typing to search notes'));
    }
    return BlocBuilder<NoteCubit, NoteState>(
      builder: (context, state) {
        final suggestions = state.notes.where((note) {
          final q = query.toLowerCase();
          return note.title.toLowerCase().contains(q) ||
              note.body.toLowerCase().contains(q);
        }).toList();

        if (suggestions.isEmpty) {
          return const Center(child: Text('No results found'));
        }

        return ListView.builder(
          itemCount: suggestions.length,
          itemBuilder: (context, index) {
            final note = suggestions[index];
            return ListTile(
              leading: const Icon(Icons.search),
              title: Text(note.title),
              subtitle: Text(
                note.body.length > 50
                    ? '${note.body.substring(0, 50)}...'
                    : note.body,
              ),
              onTap: () {
                query = note.title;
                showResults(context);
              },
            );
          },
        );
      },
    );
  }
}

class SettingsPreview extends StatelessWidget {
  const SettingsPreview({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        ListTile(
          leading: const Icon(Icons.label_outline),
          title: const Text('Manage Labels'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () {
            Navigator.pushNamed(context, '/labels');
          },
        ),
        ListTile(
          leading: const Icon(Icons.qr_code),
          title: const Text('Import via QR'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () {
            Navigator.pushNamed(context, '/qr-import');
          },
        ),
        ListTile(
          leading: const Icon(Icons.folder_open),
          title: const Text('Import from File'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () {
          },
        ),
        const Divider(height: 32),
        BlocBuilder<CryptoCubit, CryptoState>(
          builder: (context, state) {
            return SwitchListTile(
              secondary: const Icon(Icons.dark_mode),
              title: const Text('Dark Mode'),
              subtitle: const Text('Use dark theme'),
              value: Theme.of(context).brightness == Brightness.dark,
              onChanged: (value) {
              },
            );
          },
        ),
        ListTile(
          leading: const Icon(Icons.lock_outline),
          title: const Text('Lock App'),
          subtitle: const Text('Require password to access'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () {
            context.read<CryptoCubit>().lock();
          },
        ),
      ],
    );
  }
}
