import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import '../../services/supabase_service.dart';
import './widgets/create_note_modal_widget.dart';
import './widgets/create_poll_modal_widget.dart';
import './widgets/note_card_widget.dart';
import './widgets/poll_card_widget.dart';
import './widgets/search_bar_widget.dart';

class NotesAndPollsScreen extends StatefulWidget {
  const NotesAndPollsScreen({Key? key}) : super(key: key);

  @override
  State<NotesAndPollsScreen> createState() => _NotesAndPollsScreenState();
}

class _NotesAndPollsScreenState extends State<NotesAndPollsScreen>
    with TickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  late TabController _tabController;
  late AnimationController _fabAnimationController;
  late Animation<double> _fabAnimation;
  bool _isFabExpanded = false;
  String _searchQuery = '';
  bool _isRefreshing = false;

  // ENHANCED: Replace mock data with database integration
  List<Map<String, dynamic>> _notes = [];
  List<Map<String, dynamic>> _polls = [];
  String? _currentGroupId;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _fabAnimationController = AnimationController(
      duration: Duration(milliseconds: 300),
      vsync: this,
    );
    _fabAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fabAnimationController, curve: Curves.easeInOut),
    );

    // CRITICAL FIX: Load real data from database
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeData();
    });
  }

  // ENHANCED: Initialize with real database data
  Future<void> _initializeData() async {
    try {
      // Get current group ID from route arguments or default to first group
      final args = ModalRoute.of(context)?.settings.arguments as String?;
      _currentGroupId = args;

      if (_currentGroupId == null) {
        // Get first available group for user
        final userGroups = await SupabaseService.instance.getUserGroups();
        if (userGroups.isNotEmpty) {
          _currentGroupId = userGroups.first['id'] as String;
        }
      }

      if (_currentGroupId != null) {
        await _loadNotesAndPolls();
      }
    } catch (e) {
      print('⚠️ Error initializing data: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // ENHANCED: Load real notes and polls from database
  Future<void> _loadNotesAndPolls() async {
    if (_currentGroupId == null) return;

    try {
      setState(() {
        _isRefreshing = true;
      });

      // Load notes and polls in parallel
      final results = await Future.wait([
        SupabaseService.instance.getGroupNotes(_currentGroupId!),
        SupabaseService.instance.getGroupPolls(_currentGroupId!),
      ]);

      final notes = results[0];
      final polls = results[1];

      // Load reactions for each note and poll
      for (final note in notes) {
        final reactions = await SupabaseService.instance.getReactionsForTarget(
          targetId: note['id'] as String,
          targetType: 'note',
        );
        note['reactions'] = reactions;
      }

      for (final poll in polls) {
        final reactions = await SupabaseService.instance.getReactionsForTarget(
          targetId: poll['id'] as String,
          targetType: 'poll',
        );
        poll['reactions'] = reactions;

        // Load poll results
        final results =
            await SupabaseService.instance.getPollResults(poll['id'] as String);
        poll['results'] = results;
      }

      if (mounted) {
        setState(() {
          _notes = notes;
          _polls = polls;
        });
      }

      print('✅ Loaded ${notes.length} notes and ${polls.length} polls');
    } catch (e) {
      print('❌ Error loading notes and polls: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load content. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isRefreshing = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _tabController.dispose();
    _fabAnimationController.dispose();
    super.dispose();
  }

  List<Map<String, dynamic>> get _filteredNotes {
    if (_searchQuery.isEmpty) {
      return _notes;
    }

    return _notes.where((note) {
      final content = note['content'] as String;
      final authorName = note['author']?['full_name'] as String? ?? '';

      return content.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          authorName.toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();
  }

  List<Map<String, dynamic>> get _filteredPolls {
    if (_searchQuery.isEmpty) {
      return _polls;
    }

    return _polls.where((poll) {
      final question = poll['question'] as String;
      final authorName = poll['author']?['full_name'] as String? ?? '';

      return question.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          authorName.toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();
  }

  Future<void> _handleRefresh() async {
    await _loadNotesAndPolls();
  }

  void _toggleFab() {
    setState(() {
      _isFabExpanded = !_isFabExpanded;
    });

    if (_isFabExpanded) {
      _fabAnimationController.forward();
    } else {
      _fabAnimationController.reverse();
    }
  }

  void _showCreateNoteModal() {
    if (_isFabExpanded) _toggleFab();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => CreateNoteModalWidget(
        onCreateNote: _createNote,
      ),
    );
  }

  void _showCreatePollModal() {
    if (_isFabExpanded) _toggleFab();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => CreatePollModalWidget(
        onCreatePoll: _createPoll,
      ),
    );
  }

  // ENHANCED: Create note with database integration
  Future<void> _createNote(String content) async {
    if (_currentGroupId == null) return;

    try {
      final newNote = await SupabaseService.instance.createNote(
        groupId: _currentGroupId!,
        content: content,
      );

      // Load reactions for the new note
      final reactions = await SupabaseService.instance.getReactionsForTarget(
        targetId: newNote['id'] as String,
        targetType: 'note',
      );
      newNote['reactions'] = reactions;

      setState(() {
        _notes.insert(0, newNote);
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Note created successfully'),
            backgroundColor: AppTheme.lightTheme.colorScheme.primary,
          ),
        );
      }
    } catch (e) {
      print('❌ Error creating note: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to create note. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // ENHANCED: Create poll with database integration
  Future<void> _createPoll(String question, List<String> options) async {
    if (_currentGroupId == null) return;

    try {
      final newPoll = await SupabaseService.instance.createPoll(
        groupId: _currentGroupId!,
        question: question,
        options: options,
      );

      // Load reactions and results for the new poll
      final reactions = await SupabaseService.instance.getReactionsForTarget(
        targetId: newPoll['id'] as String,
        targetType: 'poll',
      );
      newPoll['reactions'] = reactions;

      final results = await SupabaseService.instance
          .getPollResults(newPoll['id'] as String);
      newPoll['results'] = results;

      setState(() {
        _polls.insert(0, newPoll);
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Poll created successfully'),
            backgroundColor: AppTheme.lightTheme.colorScheme.secondary,
          ),
        );
      }
    } catch (e) {
      print('❌ Error creating poll: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to create poll. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // ENHANCED: Handle poll voting with database integration
  Future<void> _handlePollVote(String pollId, int optionIndex) async {
    try {
      final poll = _polls.firstWhere((p) => p['id'] == pollId);
      final options = poll['poll_options'] as List<dynamic>;

      if (optionIndex >= 0 && optionIndex < options.length) {
        final optionId = options[optionIndex]['id'] as String;

        await SupabaseService.instance.votePoll(
          pollId: pollId,
          optionId: optionId,
        );

        // Refresh poll results
        final results = await SupabaseService.instance.getPollResults(pollId);

        setState(() {
          final pollIndex = _polls.indexWhere((p) => p['id'] == pollId);
          if (pollIndex != -1) {
            _polls[pollIndex]['results'] = results;
          }
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Vote recorded successfully'),
              backgroundColor: AppTheme.lightTheme.colorScheme.primary,
            ),
          );
        }
      }
    } catch (e) {
      print('❌ Error voting on poll: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to record vote. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // ENHANCED: Handle emoji reactions with database integration
  Future<void> _handleEmojiReaction(String itemId, String emoji) async {
    try {
      // Determine if it's a note or poll
      final isNote = _notes.any((note) => note['id'] == itemId);
      final targetType = isNote ? 'note' : 'poll';

      final result = await SupabaseService.instance.toggleReaction(
        targetId: itemId,
        targetType: targetType,
        emoji: emoji,
      );

      // Refresh reactions for the item
      final reactions = await SupabaseService.instance.getReactionsForTarget(
        targetId: itemId,
        targetType: targetType,
      );

      setState(() {
        if (isNote) {
          final noteIndex = _notes.indexWhere((note) => note['id'] == itemId);
          if (noteIndex != -1) {
            _notes[noteIndex]['reactions'] = reactions;
          }
        } else {
          final pollIndex = _polls.indexWhere((poll) => poll['id'] == itemId);
          if (pollIndex != -1) {
            _polls[pollIndex]['reactions'] = reactions;
          }
        }
      });

      print('✅ Reaction ${result['action']}: ${result['emoji']}');
    } catch (e) {
      print('❌ Error handling emoji reaction: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update reaction. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // ENHANCED: Handle note editing with database integration
  Future<void> _handleNoteEdit(String noteId) async {
    final noteIndex = _notes.indexWhere((note) => note['id'] == noteId);
    if (noteIndex != -1) {
      final note = _notes[noteIndex];
      _showEditNoteModal(note);
    }
  }

  void _showEditNoteModal(Map<String, dynamic> note) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => CreateNoteModalWidget(
        onCreateNote: (content) => _updateNote(note['id'] as String, content),
        initialContent: note['content'] as String,
        isEditing: true,
      ),
    );
  }

  // ENHANCED: Update note with database integration
  Future<void> _updateNote(String noteId, String newContent) async {
    try {
      final updatedNote = await SupabaseService.instance.updateNote(
        noteId: noteId,
        content: newContent,
      );

      // Load reactions for updated note
      final reactions = await SupabaseService.instance.getReactionsForTarget(
        targetId: noteId,
        targetType: 'note',
      );
      updatedNote['reactions'] = reactions;

      setState(() {
        final noteIndex = _notes.indexWhere((note) => note['id'] == noteId);
        if (noteIndex != -1) {
          _notes[noteIndex] = updatedNote;
        }
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Note updated successfully'),
            backgroundColor: AppTheme.lightTheme.colorScheme.primary,
          ),
        );
      }
    } catch (e) {
      print('❌ Error updating note: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update note. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // ENHANCED: Handle note deletion with database integration
  Future<void> _handleNoteDelete(String noteId) async {
    try {
      await SupabaseService.instance.deleteNote(noteId);

      setState(() {
        _notes.removeWhere((note) => note['id'] == noteId);
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Note deleted successfully'),
            backgroundColor: AppTheme.lightTheme.colorScheme.primary,
          ),
        );
      }
    } catch (e) {
      print('❌ Error deleting note: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to delete note. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _handlePollDetails(String pollId) {
    // Navigate to detailed poll results screen
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Poll details functionality')),
    );
  }

  void _handleNoteDetails(String noteId) {
    // Handle note details view
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Note details functionality')),
    );
  }

  bool get _isNotesTab => _tabController.index == 0;

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: AppTheme.lightTheme.scaffoldBackgroundColor,
        appBar: AppBar(
          title: Text('Notes & Polls'),
          leading: IconButton(
            onPressed: () => Navigator.pop(context),
            icon: CustomIconWidget(
              iconName: 'arrow_back',
              color: AppTheme.lightTheme.colorScheme.onSurface,
              size: 6.w,
            ),
          ),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(
                color: AppTheme.lightTheme.colorScheme.primary,
              ),
              SizedBox(height: 2.h),
              Text(
                'Loading notes and polls...',
                style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                  color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      );
    }

    final filteredNotes = _filteredNotes;
    final filteredPolls = _filteredPolls;

    return Scaffold(
      backgroundColor: AppTheme.lightTheme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text('Notes & Polls'),
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: CustomIconWidget(
            iconName: 'arrow_back',
            color: AppTheme.lightTheme.colorScheme.onSurface,
            size: 6.w,
          ),
        ),
        actions: [
          IconButton(
            onPressed: () {
              // Navigate to notifications
              Navigator.pushNamed(context, '/notifications-screen');
            },
            icon: CustomIconWidget(
              iconName: 'notifications_outlined',
              color: AppTheme.lightTheme.colorScheme.onSurface,
              size: 6.w,
            ),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CustomIconWidget(
                    iconName: 'note_alt',
                    color: AppTheme.lightTheme.colorScheme.primary,
                    size: 5.w,
                  ),
                  SizedBox(width: 2.w),
                  Text('Notes (${filteredNotes.length})'),
                ],
              ),
            ),
            Tab(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CustomIconWidget(
                    iconName: 'poll',
                    color: AppTheme.lightTheme.colorScheme.secondary,
                    size: 5.w,
                  ),
                  SizedBox(width: 2.w),
                  Text('Polls (${filteredPolls.length})'),
                ],
              ),
            ),
          ],
          onTap: (index) {
            if (_isFabExpanded) {
              _toggleFab();
            }
          },
        ),
      ),
      body: Stack(
        children: [
          Column(
            children: [
              SearchBarWidget(
                controller: _searchController,
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value;
                  });
                },
                onClear: () {
                  _searchController.clear();
                  setState(() {
                    _searchQuery = '';
                  });
                },
              ),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    // Notes Tab
                    filteredNotes.isEmpty
                        ? _searchQuery.isNotEmpty
                            ? _buildNoSearchResults()
                            : _buildNotesEmptyState()
                        : RefreshIndicator(
                            onRefresh: _handleRefresh,
                            color: AppTheme.lightTheme.colorScheme.primary,
                            child: ListView.builder(
                              physics: AlwaysScrollableScrollPhysics(),
                              itemCount: filteredNotes.length,
                              itemBuilder: (context, index) {
                                final note = filteredNotes[index];
                                return NoteCardWidget(
                                  note: note,
                                  onLongPress: () =>
                                      _handleNoteEdit(note['id'] as String),
                                  onTap: () =>
                                      _handleNoteDetails(note['id'] as String),
                                  onEmojiReaction: (emoji) =>
                                      _handleEmojiReaction(
                                          note['id'] as String, emoji),
                                );
                              },
                            ),
                          ),
                    // Polls Tab
                    filteredPolls.isEmpty
                        ? _searchQuery.isNotEmpty
                            ? _buildNoSearchResults()
                            : _buildPollsEmptyState()
                        : RefreshIndicator(
                            onRefresh: _handleRefresh,
                            color: AppTheme.lightTheme.colorScheme.primary,
                            child: ListView.builder(
                              physics: AlwaysScrollableScrollPhysics(),
                              itemCount: filteredPolls.length,
                              itemBuilder: (context, index) {
                                final poll = filteredPolls[index];
                                return PollCardWidget(
                                  poll: poll,
                                  onVote: (optionIndex) => _handlePollVote(
                                      poll['id'] as String, optionIndex),
                                  onTap: () =>
                                      _handlePollDetails(poll['id'] as String),
                                  onEmojiReaction: (emoji) =>
                                      _handleEmojiReaction(
                                          poll['id'] as String, emoji),
                                );
                              },
                            ),
                          ),
                  ],
                ),
              ),
            ],
          ),
          if (_isFabExpanded)
            GestureDetector(
              onTap: _toggleFab,
              child: Container(
                color: Colors.black.withValues(alpha: 0.3),
                width: double.infinity,
                height: double.infinity,
              ),
            ),
        ],
      ),
      floatingActionButton: _currentGroupId == null
          ? null
          : _isNotesTab
              ? FloatingActionButton(
                  onPressed: _showCreateNoteModal,
                  backgroundColor: AppTheme.lightTheme.colorScheme.primary,
                  foregroundColor: AppTheme.lightTheme.colorScheme.onPrimary,
                  child: CustomIconWidget(
                    iconName: 'note_add',
                    color: AppTheme.lightTheme.colorScheme.onPrimary,
                    size: 6.w,
                  ),
                  heroTag: 'addNote',
                )
              : FloatingActionButton(
                  onPressed: _showCreatePollModal,
                  backgroundColor: AppTheme.lightTheme.colorScheme.secondary,
                  foregroundColor: AppTheme.lightTheme.colorScheme.onSecondary,
                  child: CustomIconWidget(
                    iconName: 'poll',
                    color: AppTheme.lightTheme.colorScheme.onSecondary,
                    size: 6.w,
                  ),
                  heroTag: 'createPoll',
                ),
    );
  }

// ... keep existing _buildNoSearchResults, _buildNotesEmptyState, and _buildPollsEmptyState methods ...

  Widget _buildNoSearchResults() {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(8.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 25.w,
              height: 25.w,
              decoration: BoxDecoration(
                color: AppTheme.lightTheme.colorScheme.outline
                    .withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: CustomIconWidget(
                iconName: 'search_off',
                color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                size: 12.w,
              ),
            ),
            SizedBox(height: 3.h),
            Text(
              'No results found',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppTheme.lightTheme.colorScheme.onSurface,
                  ),
            ),
            SizedBox(height: 1.h),
            Text(
              'Try searching with different keywords or create new content.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                  ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotesEmptyState() {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(8.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 25.w,
              height: 25.w,
              decoration: BoxDecoration(
                color: AppTheme.lightTheme.colorScheme.primary
                    .withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: CustomIconWidget(
                iconName: 'note_alt',
                color: AppTheme.lightTheme.colorScheme.primary,
                size: 12.w,
              ),
            ),
            SizedBox(height: 3.h),
            Text(
              'No notes yet',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppTheme.lightTheme.colorScheme.onSurface,
                  ),
            ),
            SizedBox(height: 1.h),
            Text(
              'Share updates, reminders, or thoughts with your group.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                  ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 4.h),
            ElevatedButton.icon(
              onPressed: _showCreateNoteModal,
              icon: CustomIconWidget(
                iconName: 'note_add',
                color: AppTheme.lightTheme.colorScheme.onPrimary,
                size: 5.w,
              ),
              label: Text('Add Note'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.lightTheme.colorScheme.primary,
                foregroundColor: AppTheme.lightTheme.colorScheme.onPrimary,
                padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPollsEmptyState() {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(8.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 25.w,
              height: 25.w,
              decoration: BoxDecoration(
                color: AppTheme.lightTheme.colorScheme.secondary
                    .withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: CustomIconWidget(
                iconName: 'poll',
                color: AppTheme.lightTheme.colorScheme.secondary,
                size: 12.w,
              ),
            ),
            SizedBox(height: 3.h),
            Text(
              'No polls yet',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppTheme.lightTheme.colorScheme.onSurface,
                  ),
            ),
            SizedBox(height: 1.h),
            Text(
              'Create polls to get group opinions on decisions.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                  ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 4.h),
            ElevatedButton.icon(
              onPressed: _showCreatePollModal,
              icon: CustomIconWidget(
                iconName: 'poll',
                color: AppTheme.lightTheme.colorScheme.onSecondary,
                size: 5.w,
              ),
              label: Text('Create Poll'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.lightTheme.colorScheme.secondary,
                foregroundColor: AppTheme.lightTheme.colorScheme.onSecondary,
                padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
