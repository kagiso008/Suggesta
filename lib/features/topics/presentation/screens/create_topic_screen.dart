import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../providers/topics_provider.dart';
import '../providers/user_topics_provider.dart';

class CreateTopicScreen extends ConsumerStatefulWidget {
  const CreateTopicScreen({super.key});

  @override
  ConsumerState<CreateTopicScreen> createState() => _CreateTopicScreenState();
}

class _CreateTopicScreenState extends ConsumerState<CreateTopicScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _tagsController = TextEditingController();

  String? _selectedCategory;
  final List<String> _tags = [];

  bool _isSubmitting = false;

  final List<String> _categories = [
    'Tech',
    'Lifestyle',
    'Design',
    'Food',
    'Sports',
    'Entertainment',
    'Other',
  ];

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _tagsController.dispose();
    super.dispose();
  }

  void _addTag() {
    final tag = _tagsController.text.trim();
    if (tag.isNotEmpty && _tags.length < 5) {
      setState(() {
        _tags.add(tag);
        _tagsController.clear();
      });
    }
  }

  void _removeTag(String tag) {
    setState(() {
      _tags.remove(tag);
    });
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCategory == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please select a category')));
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    // Store context locally to avoid async gap issues
    final localContext = context;

    try {
      final newTopic = await ref
          .read(topicsProvider.notifier)
          .createTopic(
            title: _titleController.text.trim(),
            description: _descriptionController.text.trim().isNotEmpty
                ? _descriptionController.text.trim()
                : null,
            category: _selectedCategory,
            tags: _tags,
          );

      // Show success message
      if (localContext.mounted) {
        ScaffoldMessenger.of(localContext).showSnackBar(
          const SnackBar(
            content: Text('Topic created successfully!'),
            backgroundColor: Colors.green,
          ),
        );

        // Invalidate user topics provider to refresh "My Topics" page
        final user = Supabase.instance.client.auth.currentUser;
        if (user != null) {
          ref.invalidate(userTopicsProvider(user.id));
        }

        // Navigate back to homepage
        localContext.pop();
      }
    } catch (e) {
      if (localContext.mounted) {
        ScaffoldMessenger.of(localContext).showSnackBar(
          SnackBar(
            content: Text('Failed to create topic: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create a Topic'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => context.pop(),
        ),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Title field
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Title *',
                  hintText: 'What would you like to discuss?',
                  border: OutlineInputBorder(),
                ),
                maxLength: 120,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Title is required';
                  }
                  if (value.trim().length > 120) {
                    return 'Title must be 120 characters or less';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Description field
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description (optional)',
                  hintText: 'Add more details about your topic...',
                  border: OutlineInputBorder(),
                  alignLabelWithHint: true,
                ),
                maxLines: 4,
                maxLength: 500,
                validator: (value) {
                  if (value != null && value.trim().length > 500) {
                    return 'Description must be 500 characters or less';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Category dropdown
              DropdownButtonFormField<String>(
                initialValue: _selectedCategory,
                decoration: const InputDecoration(
                  labelText: 'Category *',
                  border: OutlineInputBorder(),
                ),
                items: _categories.map((category) {
                  return DropdownMenuItem(
                    value: category,
                    child: Text(category),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedCategory = value;
                  });
                },
                validator: (value) {
                  if (value == null) {
                    return 'Please select a category';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Tags input
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextFormField(
                    controller: _tagsController,
                    decoration: InputDecoration(
                      labelText: 'Tags (optional, max 5)',
                      hintText: 'Press Enter or comma to add tag',
                      border: const OutlineInputBorder(),
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.add),
                        onPressed: _addTag,
                      ),
                    ),
                    onFieldSubmitted: (_) => _addTag(),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Add relevant tags to help others find your topic',
                    style: Theme.of(
                      context,
                    ).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 8),

                  // Tags chips
                  if (_tags.isNotEmpty)
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      children: _tags.map((tag) {
                        return Chip(
                          label: Text(tag),
                          deleteIcon: const Icon(Icons.close, size: 16),
                          onDeleted: () => _removeTag(tag),
                        );
                      }).toList(),
                    ),
                ],
              ),
              const SizedBox(height: 32),

              // Submit button
              ElevatedButton(
                onPressed: _isSubmitting ? null : _submitForm,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: _isSubmitting
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation(Colors.white),
                        ),
                      )
                    : const Text('Post Topic', style: TextStyle(fontSize: 16)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
