import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:social_issues_tracker/data/local_data.dart';
import 'package:social_issues_tracker/data/models/file_attachment.dart';
import 'package:social_issues_tracker/pages/group_view_page.dart';

enum GroupEditMode { create, edit }

class GroupEditPage extends StatefulWidget {
  const GroupEditPage({super.key, required this.mode, this.groupId});

  final GroupEditMode mode;
  final String? groupId;

  @override
  State<GroupEditPage> createState() => _GroupEditPageState();
}

class _GroupEditPageState extends State<GroupEditPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();

  Uint8List? _pickedImageBytes;
  String? _pickedImageExtension;

  final List<FileAttachment> _attachments = [];

  bool _saving = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final local = Provider.of<LocalData>(context, listen: false);
      if (widget.mode == GroupEditMode.edit && widget.groupId != null) {
        final existing = local.getGroupById(widget.groupId!);
        _titleController.text = existing.title ?? '';
        _descriptionController.text = existing.description ?? '';
        if (existing.imageData != null && existing.imageData!.isNotEmpty) {
          _pickedImageBytes = existing.imageData;
          _pickedImageExtension = 'jpg';
        }
        if (existing.fileIds?.isNotEmpty ?? false) {
          for (final fid in existing.fileIds!) {
            _attachments.add(local.getFileById(fid));
          }
        }
      }
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      withData: true,
    );

    if (result == null || result.files.isEmpty) return;
    final file = result.files.first;
    if (file.bytes == null) return;

    setState(() {
      _pickedImageBytes = file.bytes;
      final name = (file.name).toLowerCase();
      if (name.endsWith('.png')) {
        _pickedImageExtension = 'png';
      } else if (name.endsWith('.gif')) {
        _pickedImageExtension = 'gif';
      } else if (name.endsWith('.webp')) {
        _pickedImageExtension = 'webp';
      } else {
        _pickedImageExtension = 'jpg';
      }
    });
  }

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      allowMultiple: true,
      withData: false,
      type: FileType.any,
    );

    if (result == null || result.files.isEmpty) return;

    setState(() {
      for (final file in result.files) {
        final name = file.name;
        final dotIndex = name.lastIndexOf('.');
        final base = dotIndex == -1 ? name : name.substring(0, dotIndex);
        final ext = dotIndex == -1 ? 'dat' : name.substring(dotIndex + 1);

        _attachments.add(
          FileAttachment(
            id: 'temp_${DateTime.now().millisecondsSinceEpoch}_${_attachments.length}',
            name: base,
            extension: ext,
            uploadLink:
                'https://example.com/dummy/${DateTime.now().millisecondsSinceEpoch}/$name',
          ),
        );
      }
    });
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _saving = true;
    });

    final local = Provider.of<LocalData>(context, listen: false);

    String? groupId;
    if (widget.mode == GroupEditMode.edit && widget.groupId != null) {
      // Edit mode - update existing group via API
      final success = await local.updateGroup(
        groupId: widget.groupId!,
        name: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        displayPictureBytes: _pickedImageBytes,
        displayPictureExtension: _pickedImageExtension,
      );

      if (!success) {
        if (mounted) {
          setState(() {
            _saving = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to update group. Please try again.'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      groupId = widget.groupId;
    } else {
      // Create mode - call backend API
      groupId = await local.createGroup(
        name: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        displayPictureBytes: _pickedImageBytes,
        displayPictureExtension: _pickedImageExtension,
      );

      if (groupId == null) {
        if (mounted) {
          setState(() {
            _saving = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to create group')),
          );
        }
        return;
      }
    }

    if (mounted) {
      setState(() {
        _saving = false;
      });
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => GroupViewPage(groupId: groupId!)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isEdit = widget.mode == GroupEditMode.edit;
    final local = Provider.of<LocalData>(context, listen: false);

    if (isEdit && widget.groupId != null) {
      final group = local.getGroupById(widget.groupId!);
      final canEdit =
          group.postedBy != null && group.postedBy == local.loggedInUserId;
      if (!canEdit) {
        return Scaffold(
          appBar: AppBar(title: const Text('Edit Group')),
          body: Center(
            child: Text(
              'You can only edit your own groups.',
              style: theme.textTheme.bodyMedium,
            ),
          ),
        );
      }
    }

    return Scaffold(
      appBar: AppBar(title: Text(isEdit ? 'Edit Group' : 'New Group')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextFormField(
                  controller: _titleController,
                  decoration: const InputDecoration(labelText: 'Title'),
                  textInputAction: TextInputAction.next,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Title is required';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _descriptionController,
                  decoration: const InputDecoration(labelText: 'Description'),
                  maxLines: 4,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Description is required';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24),
                Text('Cover Image', style: theme.textTheme.titleMedium),
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: _pickImage,
                  child: Container(
                    height: 180,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: theme.colorScheme.primary.withOpacity(0.4),
                      ),
                      color: theme.colorScheme.surfaceVariant,
                    ),
                    child: _pickedImageBytes == null
                        ? Center(
                            child: Text(
                              'Tap to pick image',
                              style: theme.textTheme.bodyMedium,
                            ),
                          )
                        : ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.memory(
                              _pickedImageBytes!,
                              fit: BoxFit.cover,
                              width: double.infinity,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 24),
                Text('Attachments', style: theme.textTheme.titleMedium),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    ..._attachments.asMap().entries.map((entry) {
                      final index = entry.key;
                      final f = entry.value;
                      return Chip(
                        label: Text('${f.name}.${f.extension}'),
                        deleteIcon: const Icon(Icons.close, size: 18),
                        onDeleted: () {
                          setState(() {
                            _attachments.removeAt(index);
                          });
                        },
                      );
                    }),
                    ActionChip(
                      avatar: const Icon(Icons.attach_file, size: 18),
                      label: const Text('Add attachment'),
                      onPressed: _pickFile,
                    ),
                  ],
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _saving ? null : _save,
                    child: _saving
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(isEdit ? 'Save Changes' : 'Create Group'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
