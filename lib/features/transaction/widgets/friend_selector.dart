import 'package:flutter/material.dart';
import 'package:flynse/core/data/repositories/friend_repository.dart';
import 'package:flynse/features/transaction/widgets/transaction_form_models.dart';

class FriendSelector extends StatefulWidget {
  final TransactionFormState formState;
  final Function(String, String) showAddDialog;
  final VoidCallback onStateChanged;
  final bool isTryingToSubmit;

  const FriendSelector({
    super.key,
    required this.formState,
    required this.showAddDialog,
    required this.onStateChanged,
    required this.isTryingToSubmit,
  });

  @override
  State<FriendSelector> createState() => _FriendSelectorState();
}

class _FriendSelectorState extends State<FriendSelector> {
  final _friendRepo = FriendRepository();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (widget.formState.selectedFriend != null) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Friend',
            style: theme.textTheme.titleMedium,
          ),
          InputChip(
            label: Text(widget.formState.selectedFriend!['name']),
            onDeleted: () {
              widget.formState.selectedFriend = null;
              widget.onStateChanged();
            },
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              'Select Friend',
              style: theme.textTheme.titleMedium,
            ),
            TextButton.icon(
              icon: const Icon(Icons.add_circle_outline, size: 18),
              label: const Text('Add New'),
              style: TextButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              onPressed: () async {
                final newName = await widget.showAddDialog(
                    'Add New Friend', 'Friend Name');
                if (newName != null && newName.isNotEmpty) {
                  final id = await _friendRepo.addFriend(newName);
                  widget.formState.selectedFriend = {'id': id, 'name': newName};
                  widget.onStateChanged();
                }
              },
            ),
          ],
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 52,
          child: FutureBuilder<List<Map<String, dynamic>>>(
            future: _friendRepo.getFriends(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }
              final friends = snapshot.data!;
              if (friends.isEmpty) {
                return Center(
                  child: Text(
                    'No friends found. Please add one.',
                    style: theme.textTheme.bodySmall,
                  ),
                );
              }
              return ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: friends.length,
                itemBuilder: (context, index) {
                  final friend = friends[index];
                  return Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: ChoiceChip(
                      label: Text(friend['name']),
                      selected: false,
                      onSelected: (_) {
                        widget.formState.selectedFriend = friend;
                        widget.onStateChanged();
                      },
                    ),
                  );
                },
              );
            },
          ),
        ),
        if (widget.isTryingToSubmit && widget.formState.selectedFriend == null)
          Padding(
            padding: const EdgeInsets.only(top: 8.0, left: 12.0),
            child: Text(
              'Please select a friend',
              style: TextStyle(color: theme.colorScheme.error, fontSize: 12),
            ),
          ),
      ],
    );
  }
}
