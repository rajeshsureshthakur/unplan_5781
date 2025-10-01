import 'package:emoji_picker_flutter/emoji_picker_flutter.dart' as emoji_picker;
import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

class CreateNoteModalWidget extends StatefulWidget {
  final Function(String) onCreateNote;
  final String? initialContent;
  final bool isEditing;

  const CreateNoteModalWidget({
    Key? key,
    required this.onCreateNote,
    this.initialContent,
    this.isEditing = false,
  }) : super(key: key);

  @override
  State<CreateNoteModalWidget> createState() => _CreateNoteModalWidgetState();
}

class _CreateNoteModalWidgetState extends State<CreateNoteModalWidget> {
  late TextEditingController _contentController;
  bool _isPosting = false;
  static const int _maxCharacters = 500;
  bool _showEmojiPicker = false;

  @override
  void initState() {
    super.initState();
    _contentController =
        TextEditingController(text: widget.initialContent ?? '');
  }

  @override
  void dispose() {
    _contentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.9,
      decoration: BoxDecoration(
        color: AppTheme.lightTheme.scaffoldBackgroundColor,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          Container(
            padding: EdgeInsets.all(4.w),
            decoration: BoxDecoration(
              color: AppTheme.lightTheme.colorScheme.surface,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 4,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    'Cancel',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: AppTheme.lightTheme.colorScheme.error,
                        ),
                  ),
                ),
                Expanded(
                  child: Text(
                    widget.isEditing ? 'Edit Note' : 'Add Note',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                    textAlign: TextAlign.center,
                  ),
                ),
                TextButton(
                  onPressed: _isPosting ? null : _handleCreateNote,
                  child: _isPosting
                      ? SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              AppTheme.lightTheme.colorScheme.primary,
                            ),
                          ),
                        )
                      : Text(
                          widget.isEditing ? 'Update' : 'Post',
                          style: Theme.of(context)
                              .textTheme
                              .bodyLarge
                              ?.copyWith(
                                color: _contentController.text.trim().isNotEmpty
                                    ? AppTheme.lightTheme.colorScheme.primary
                                    : AppTheme.lightTheme.colorScheme.outline,
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                ),
              ],
            ),
          ),
          Divider(height: 1),
          Expanded(
            child: Column(
              children: [
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.all(4.w),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _contentController,
                            maxLines: null,
                            maxLength: _maxCharacters,
                            decoration: InputDecoration(
                              hintText: 'What\'s on your mind?',
                              border: InputBorder.none,
                              enabledBorder: InputBorder.none,
                              focusedBorder: InputBorder.none,
                              counterText:
                                  '${_contentController.text.length}/$_maxCharacters',
                              counterStyle: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(
                                    color: AppTheme.lightTheme.colorScheme
                                        .onSurfaceVariant,
                                  ),
                            ),
                            style: Theme.of(context).textTheme.bodyLarge,
                            onChanged: (value) => setState(() {}),
                          ),
                        ),
                        Row(
                          children: [
                            IconButton(
                              onPressed: () {
                                setState(() {
                                  _showEmojiPicker = !_showEmojiPicker;
                                });
                              },
                              icon: CustomIconWidget(
                                iconName: 'emoji_emotions',
                                color: _showEmojiPicker
                                    ? AppTheme.lightTheme.colorScheme.primary
                                    : AppTheme.lightTheme.colorScheme
                                        .onSurfaceVariant,
                                size: 6.w,
                              ),
                            ),
                            IconButton(
                              onPressed: () {
                                // Mention functionality placeholder
                                _contentController.text += '@';
                                _contentController.selection =
                                    TextSelection.fromPosition(
                                  TextPosition(
                                      offset: _contentController.text.length),
                                );
                              },
                              icon: CustomIconWidget(
                                iconName: 'alternate_email',
                                color: AppTheme
                                    .lightTheme.colorScheme.onSurfaceVariant,
                                size: 6.w,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                if (_showEmojiPicker)
                  Container(
                    height: 35.h,
                    child: emoji_picker.EmojiPicker(
                      onEmojiSelected: (category, emoji) {
                        _contentController.text += emoji.emoji;
                        _contentController.selection =
                            TextSelection.fromPosition(
                          TextPosition(offset: _contentController.text.length),
                        );
                        setState(() {});
                      },
                      config: emoji_picker.Config(
                        height: 35.h,
                        checkPlatformCompatibility: true,
                        emojiViewConfig: emoji_picker.EmojiViewConfig(
                          emojiSizeMax: 28,
                          verticalSpacing: 0,
                          horizontalSpacing: 0,
                          gridPadding: EdgeInsets.zero,
                          backgroundColor:
                              AppTheme.lightTheme.colorScheme.surface,
                          recentsLimit: 28,
                        ),
                        categoryViewConfig: emoji_picker.CategoryViewConfig(
                          indicatorColor:
                              AppTheme.lightTheme.colorScheme.primary,
                          iconColor:
                              AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                          iconColorSelected:
                              AppTheme.lightTheme.colorScheme.primary,
                          backspaceColor:
                              AppTheme.lightTheme.colorScheme.primary,
                          recentTabBehavior:
                              emoji_picker.RecentTabBehavior.RECENT,
                        ),
                        skinToneConfig: emoji_picker.SkinToneConfig(
                          dialogBackgroundColor:
                              AppTheme.lightTheme.colorScheme.surface,
                          indicatorColor:
                              AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _handleCreateNote() {
    if (_isPosting) return;

    setState(() {
      _isPosting = true;
    });

    try {
      if (widget.isEditing) {
        widget.onCreateNote(_contentController.text.trim());
      } else {
        widget.onCreateNote(_contentController.text.trim());
      }
      Navigator.pop(context);
    } catch (e) {
      // Handle error
    } finally {
      setState(() {
        _isPosting = false;
      });
    }
  }
}