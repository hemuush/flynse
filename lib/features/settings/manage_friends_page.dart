import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flynse/core/data/repositories/debt_repository.dart';
import 'package:flynse/core/data/repositories/friend_repository.dart';
import 'package:flynse/core/providers/app_provider.dart';
import 'package:flynse/features/settings/friend_history_page.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

class ManageFriendsPage extends StatefulWidget {
  const ManageFriendsPage({super.key});

  @override
  State<ManageFriendsPage> createState() => _ManageFriendsPageState();
}

class _ManageFriendsPageState extends State<ManageFriendsPage> {
  final FriendRepository _friendRepo = FriendRepository();
  final DebtRepository _debtRepo = DebtRepository(); // Use DebtRepository for debt checks
  late Future<List<Map<String, dynamic>>> _friendsFuture;

  @override
  void initState() {
    super.initState();
    _refreshFriendsList();
  }

  void _refreshFriendsList() {
    setState(() {
      _friendsFuture = _friendRepo.getFriends();
    });
  }
  
  /// Handles picking an image from the gallery and saving it as a base64 avatar.
  Future<void> _pickAndSetAvatar(int friendId) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 200, // Constrain image size to save space
      maxHeight: 200,
      imageQuality: 75, // Compress image
    );

    if (pickedFile != null) {
      await _friendRepo.updateFriendAvatar(friendId, base64Encode(await File(pickedFile.path).readAsBytes()));
      _refreshFriendsList(); // Refresh the list to show the new avatar
    }
  }

  Future<void> _showAddFriendDialog() async {
    final nameController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    final newFriendName = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add New Friend'),
        content: Form(
          key: formKey,
          child: TextFormField(
            controller: nameController,
            decoration: const InputDecoration(labelText: 'Friend Name'),
            autofocus: true,
            validator: (v) =>
                v == null || v.trim().isEmpty ? 'Name cannot be empty' : null,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                Navigator.of(context).pop(nameController.text.trim());
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );

    if (newFriendName != null && newFriendName.isNotEmpty) {
      await _friendRepo.addFriend(newFriendName);
      _refreshFriendsList();
    }
  }

  Future<void> _deleteFriend(int id, String name) async {
    // Check for pending debts before allowing deletion
    final hasPending = await _debtRepo.hasPendingDebtsForFriend(id);
    if (!mounted) return;

    final dialogContext = context;

    if (hasPending) {
      showDialog(
        context: dialogContext,
        builder: (context) => AlertDialog(
          title: Text('Cannot Delete $name'),
          content: const Text(
              'This friend has pending debts. Please settle all debts before removing them.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        ),
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: dialogContext,
      builder: (context) => AlertDialog(
        title: Text('Delete $name?'),
        content: const Text(
            'Are you sure you want to delete this friend? Their transaction history will be preserved but will no longer be associated with them.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(
                foregroundColor: Theme.of(context).colorScheme.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _friendRepo.deleteFriend(id);
      // FIX: Refresh all provider data to ensure consistency across the app.
      if (mounted) {
        await context.read<AppProvider>().refreshAllData();
      }
      _refreshFriendsList();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Friends'),
         actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline),
            tooltip: 'Add Friend',
            onPressed: _showAddFriendDialog,
          ),
        ],
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _friendsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
              child: Text('No friends found. Tap + to add one.'),
            );
          }

          final friends = snapshot.data!;
          return GridView.builder(
            padding: const EdgeInsets.all(16.0),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 1.5,
            ),
            itemCount: friends.length,
            itemBuilder: (context, index) {
              final friend = friends[index];
              return _buildFriendCard(friend);
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddFriendDialog,
        tooltip: 'Add Friend',
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildFriendCard(Map<String, dynamic> friend) {
    final theme = Theme.of(context);
    final friendName = friend['name'] as String;
    final friendAvatarBase64 = friend['avatar'] as String?;
    
    ImageProvider? avatarImage;
    if (friendAvatarBase64 != null) {
      avatarImage = MemoryImage(base64Decode(friendAvatarBase64));
    }

    return Card(
      elevation: 0,
      color: theme.colorScheme.surfaceContainerHighest,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          Navigator.of(context).push(MaterialPageRoute(
            builder: (context) => FriendHistoryPage(
              friendId: friend['id'],
              friendName: friend['name'],
            ),
          ));
        },
        child: Stack(
          children: [
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                   GestureDetector(
                      onTap: () => _pickAndSetAvatar(friend['id']),
                      child: CircleAvatar(
                        radius: 28,
                        backgroundColor: theme.colorScheme.primaryContainer,
                        foregroundColor: theme.colorScheme.onPrimaryContainer,
                        backgroundImage: avatarImage,
                        child: avatarImage == null && friendName.isNotEmpty
                            ? Text(
                                friendName[0].toUpperCase(),
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 22),
                              )
                            : null,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      friendName,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                ],
              ),
            ),
             Positioned(
                top: 4,
                right: 4,
                child: PopupMenuButton<String>(
                  icon: Icon(Icons.more_vert, size: 20, color: theme.colorScheme.onSurfaceVariant),
                  onSelected: (_) async {
                     _deleteFriend(friend['id'], friend['name']);
                  },
                  itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                    const PopupMenuItem<String>(
                      value: 'delete',
                      child: Text('Delete'),
                    ),
                  ],
                  padding: EdgeInsets.zero,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
