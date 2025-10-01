import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

class CreatePollModalWidget extends StatefulWidget {
  final Function(String, List<String>) onCreatePoll;

  const CreatePollModalWidget({
    Key? key,
    required this.onCreatePoll,
  }) : super(key: key);

  @override
  State<CreatePollModalWidget> createState() => _CreatePollModalWidgetState();
}

class _CreatePollModalWidgetState extends State<CreatePollModalWidget> {
  final TextEditingController _questionController = TextEditingController();
  final List<TextEditingController> _optionControllers = [
    TextEditingController(),
    TextEditingController(),
  ];
  final int _maxQuestionCharacters = 100;
  final int _maxOptions = 3;

  @override
  void dispose() {
    _questionController.dispose();
    for (var controller in _optionControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  bool get _canCreatePoll {
    return _questionController.text.trim().isNotEmpty &&
        _optionControllers.where((c) => c.text.trim().isNotEmpty).length >= 2;
  }

  void _addOption() {
    if (_optionControllers.length < _maxOptions) {
      setState(() {
        _optionControllers.add(TextEditingController());
      });
    }
  }

  void _removeOption(int index) {
    if (_optionControllers.length > 2) {
      setState(() {
        _optionControllers[index].dispose();
        _optionControllers.removeAt(index);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 70.h,
      decoration: BoxDecoration(
        color: AppTheme.lightTheme.colorScheme.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          Container(
            width: 12.w,
            height: 0.5.h,
            margin: EdgeInsets.only(top: 2.h),
            decoration: BoxDecoration(
              color: AppTheme.lightTheme.colorScheme.outline
                  .withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: EdgeInsets.all(4.w),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    'Cancel',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color:
                              AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                        ),
                  ),
                ),
                Text(
                  'Create Poll',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
                TextButton(
                  onPressed: _canCreatePoll
                      ? () {
                          final options = _optionControllers
                              .map((c) => c.text.trim())
                              .where((text) => text.isNotEmpty)
                              .toList();
                          widget.onCreatePoll(
                              _questionController.text.trim(), options);
                          Navigator.pop(context);
                        }
                      : null,
                  child: Text(
                    'Create',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: _canCreatePoll
                              ? AppTheme.lightTheme.colorScheme.primary
                              : AppTheme.lightTheme.colorScheme.onSurfaceVariant
                                  .withValues(alpha: 0.5),
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ),
              ],
            ),
          ),
          Divider(height: 1),
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(4.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Question',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  SizedBox(height: 1.h),
                  TextField(
                    controller: _questionController,
                    maxLength: _maxQuestionCharacters,
                    decoration: InputDecoration(
                      hintText: 'Ask a question...',
                      counterText:
                          '${_questionController.text.length}/$_maxQuestionCharacters',
                      counterStyle:
                          Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: AppTheme
                                    .lightTheme.colorScheme.onSurfaceVariant,
                              ),
                    ),
                    onChanged: (value) => setState(() {}),
                  ),
                  SizedBox(height: 3.h),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Options',
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                      ),
                      if (_optionControllers.length < _maxOptions)
                        TextButton.icon(
                          onPressed: _addOption,
                          icon: CustomIconWidget(
                            iconName: 'add',
                            color: AppTheme.lightTheme.colorScheme.primary,
                            size: 4.w,
                          ),
                          label: Text(
                            'Add Option',
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(
                                  color:
                                      AppTheme.lightTheme.colorScheme.primary,
                                ),
                          ),
                        ),
                    ],
                  ),
                  SizedBox(height: 1.h),
                  ..._optionControllers.asMap().entries.map((entry) {
                    final int index = entry.key;
                    final TextEditingController controller = entry.value;

                    return Container(
                      margin: EdgeInsets.only(bottom: 2.h),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: controller,
                              decoration: InputDecoration(
                                hintText: 'Option ${index + 1}',
                                prefixIcon: Padding(
                                  padding: EdgeInsets.all(3.w),
                                  child: CustomIconWidget(
                                    iconName: 'radio_button_unchecked',
                                    color: AppTheme.lightTheme.colorScheme
                                        .onSurfaceVariant,
                                    size: 5.w,
                                  ),
                                ),
                              ),
                              onChanged: (value) => setState(() {}),
                            ),
                          ),
                          if (_optionControllers.length > 2)
                            IconButton(
                              onPressed: () => _removeOption(index),
                              icon: CustomIconWidget(
                                iconName: 'remove_circle_outline',
                                color: AppTheme.lightTheme.colorScheme.error,
                                size: 6.w,
                              ),
                            ),
                        ],
                      ),
                    );
                  }).toList(),
                  SizedBox(height: 2.h),
                  Container(
                    padding: EdgeInsets.all(3.w),
                    decoration: BoxDecoration(
                      color: AppTheme.lightTheme.colorScheme.primary
                          .withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        CustomIconWidget(
                          iconName: 'info_outline',
                          color: AppTheme.lightTheme.colorScheme.primary,
                          size: 5.w,
                        ),
                        SizedBox(width: 2.w),
                        Expanded(
                          child: Text(
                            'Group members will be able to vote on this poll. You can add up to 3 options.',
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(
                                  color:
                                      AppTheme.lightTheme.colorScheme.primary,
                                ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
