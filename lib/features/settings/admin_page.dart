import 'package:flutter/material.dart';
import 'package:flynse/core/data/repositories/category_repository.dart';
import 'package:flynse/core/providers/app_provider.dart';
import 'package:provider/provider.dart';

class AdminPage extends StatefulWidget {
  const AdminPage({super.key});

  @override
  State<AdminPage> createState() => _AdminPageState();
}

class _AdminPageState extends State<AdminPage> {
  final CategoryRepository _categoryRepo = CategoryRepository();
  String _selectedType = 'Expense';

  List<Map<String, dynamic>> _expenseCategories = [];
  List<Map<String, dynamic>> _incomeCategories = [];
  List<Map<String, dynamic>> _savingCategories = [];

  // Define a list of categories that cannot be deleted.
  static const _nonDeletableCategories = [
    'Debt Repayment',
    'Loan',
    'Savings Withdrawal',
    'Bank',
    'Shopping',
    'Others',
    'Friends',
    'Friend Repayment',
  ];

  // Define a list of system categories that should not have sub-categories.
  static const _nonTappableCategories = [
    'Debt Repayment',
    'Loan',
    'Savings Withdrawal',
    'Bank',
    'Friends',
    'Friend Repayment',
  ];

  @override
  void initState() {
    super.initState();
    _loadAllCategories();
  }

  Future<void> _loadAllCategories() async {
    final expense = await _categoryRepo.getCategories('Expense');
    final income = await _categoryRepo.getCategories('Income');
    final saving = await _categoryRepo.getCategories('Saving');
    if (mounted) {
      setState(() {
        _expenseCategories = expense;
        _incomeCategories = income;
        _savingCategories = saving;
      });
    }
  }

  void _showAddCategoryDialog(String type) async {
    final nameController = TextEditingController();
    final newCategoryName = await _showInputDialog(
      title: 'Add New $type Category',
      label: 'Category Name',
      controller: nameController,
    );

    if (newCategoryName != null && newCategoryName.isNotEmpty) {
      await _categoryRepo
          .insertCategory({'name': newCategoryName, 'type': type});
      _loadAllCategories();
    }
  }

  Future<String?> _showInputDialog({
    required String title,
    required String label,
    required TextEditingController controller,
  }) {
    return showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(title),
          content: TextField(
            controller: controller,
            decoration: InputDecoration(labelText: label),
            autofocus: true,
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () {
                if (controller.text.isNotEmpty) {
                  Navigator.of(context).pop(controller.text);
                }
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Categories'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline),
            tooltip: 'Add Category',
            onPressed: () {
              _showAddCategoryDialog(_selectedType);
            },
          ),
        ],
      ),
      body: Column(
        children: [
          _buildTypeSelector(),
          Expanded(
            child: _buildCategoryGrid(),
          ),
        ],
      ),
    );
  }

  Widget _buildTypeSelector() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16.0, 8.0, 16.0, 16.0),
      child: SizedBox(
        width: double.infinity,
        child: SegmentedButton<String>(
          segments: const <ButtonSegment<String>>[
            ButtonSegment<String>(value: 'Expense', label: Text('Expense')),
            ButtonSegment<String>(value: 'Income', label: Text('Income')),
            ButtonSegment<String>(value: 'Saving', label: Text('Saving')),
          ],
          selected: {_selectedType},
          onSelectionChanged: (Set<String> newSelection) {
            setState(() {
              _selectedType = newSelection.first;
            });
          },
          style: SegmentedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
            textStyle: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryGrid() {
    final List<Map<String, dynamic>> categories;
    switch (_selectedType) {
      case 'Income':
        categories = _incomeCategories;
        break;
      case 'Saving':
        categories = _savingCategories;
        break;
      case 'Expense':
      default:
        categories = _expenseCategories;
        break;
    }

    if (categories.isEmpty) {
      return Center(
          child: Text(
        'No $_selectedType categories found.\nTap + to add one!',
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.bodyLarge,
      ));
    }

    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 2.0,
      ),
      itemCount: categories.length,
      itemBuilder: (context, index) {
        final category = categories[index];
        return _buildCategoryCard(category);
      },
    );
  }

  Widget _buildCategoryCard(Map<String, dynamic> category) {
    final categoryName = category['name'] as String;
    final isDeletable = !_nonDeletableCategories.contains(categoryName);
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    // A category is tappable if it's not in the non-tappable list.
    final bool isTappable = !_nonTappableCategories.contains(categoryName);

    return Card(
      elevation: 0,
      color: theme.colorScheme.surfaceContainer,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16.0),
        side: BorderSide(
          color: isDarkMode ? Colors.grey.shade800 : Colors.grey.shade200,
          width: 1,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: isTappable
            ? () {
                Navigator.of(context).push(MaterialPageRoute(
                  builder: (_) => SubCategoryPage(
                    categoryId: category['id'],
                    categoryName: categoryName,
                  ),
                ));
              }
            : null,
        child: Stack(
          children: [
            Center(
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(
                  categoryName,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            if (isDeletable)
              Positioned(
                top: 4,
                right: 4,
                child: PopupMenuButton<String>(
                  icon: Icon(Icons.more_vert,
                      size: 20, color: theme.colorScheme.onSurfaceVariant),
                  onSelected: (_) async {
                    final confirmed = await showDialog<bool>(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Confirm Deletion'),
                        content: Text(
                            'Are you sure you want to delete the category "$categoryName"? This cannot be undone.'),
                        actions: [
                          TextButton(
                              onPressed: () => Navigator.of(context).pop(false),
                              child: const Text('Cancel')),
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(true),
                            style: TextButton.styleFrom(
                                foregroundColor:
                                    Theme.of(context).colorScheme.error),
                            child: const Text('Delete'),
                          ),
                        ],
                      ),
                    );
                    if (confirmed == true) {
                      await _categoryRepo.deleteCategory(category['id']);
                      _loadAllCategories();
                    }
                  },
                  itemBuilder: (BuildContext context) =>
                      <PopupMenuEntry<String>>[
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

class SubCategoryPage extends StatefulWidget {
  final int categoryId;
  final String categoryName;

  const SubCategoryPage({
    super.key,
    required this.categoryId,
    required this.categoryName,
  });

  @override
  State<SubCategoryPage> createState() => _SubCategoryPageState();
}

class _SubCategoryPageState extends State<SubCategoryPage> {
  final CategoryRepository _categoryRepo = CategoryRepository();

  Future<String?> _showInputDialog({
    required String title,
    required String label,
    required TextEditingController controller,
  }) {
    return showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(title),
          content: TextField(
            controller: controller,
            decoration: InputDecoration(labelText: label),
            autofocus: true,
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () {
                if (controller.text.isNotEmpty) {
                  Navigator.of(context).pop(controller.text);
                }
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  void _showAddSubCategoryDialog() async {
    final nameController = TextEditingController();
    final newSubCategoryName = await _showInputDialog(
        title: 'Add Sub-Category',
        label: 'Sub-Category Name',
        controller: nameController);

    if (newSubCategoryName != null && newSubCategoryName.isNotEmpty) {
      await _categoryRepo.insertSubCategory(
          {'name': newSubCategoryName, 'category_id': widget.categoryId});
      setState(() {});
    }
  }

  // --- NEW METHOD: Shows a dialog to move the sub-category ---
  Future<void> _showMoveSubCategoryDialog(Map<String, dynamic> subCategory) async {
    final List<Map<String, dynamic>> allExpenseCategories =
        await _categoryRepo.getCategories('Expense');
    
    final List<Map<String, dynamic>> availableCategories =
        allExpenseCategories.where((cat) {
            final isTappable = !_AdminPageState._nonTappableCategories.contains(cat['name']);
            final isNotCurrent = cat['id'] != widget.categoryId;
            return isTappable && isNotCurrent;
        }).toList();

    if (availableCategories.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('No other available categories to move to.'),
        ));
      }
      return;
    }

    final selectedCategory = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Move "${subCategory['name']}" to:'),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: availableCategories.length,
              itemBuilder: (context, index) {
                final category = availableCategories[index];
                return ListTile(
                  title: Text(category['name']),
                  onTap: () {
                    Navigator.of(context).pop(category);
                  },
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
          ],
        );
      },
    );

    if (selectedCategory != null) {
      try {
        await _categoryRepo.moveSubCategory(
          subCategoryId: subCategory['id'],
          subCategoryName: subCategory['name'],
          oldParentCategoryName: widget.categoryName,
          newParentCategoryId: selectedCategory['id'],
          newParentCategoryName: selectedCategory['name'],
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text(
                    'Moved "${subCategory['name']}" to "${selectedCategory['name']}".')),
          );
          await context.read<AppProvider>().refreshAllData();
          setState(() {});
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text('Error moving sub-category: $e'),
                backgroundColor: Colors.red),
          );
        }
      }
    }
  }

  // --- NEW METHOD: Confirms and deletes a sub-category ---
  Future<void> _confirmAndDelete(Map<String, dynamic> sub) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Deletion'),
        content: Text(
            'Are you sure you want to delete the sub-category "${sub['name']}"? This cannot be undone.'),
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
      await _categoryRepo.deleteSubCategory(sub['id']);
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.categoryName} Sub-Categories'),
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _categoryRepo.getSubCategories(widget.categoryId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
                child: Text('No sub-categories yet. Tap + to add one.'));
          }
          final subCategories = snapshot.data!;
          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(16.0, 8.0, 16.0, 100.0),
            itemCount: subCategories.length,
            itemBuilder: (context, index) {
              final sub = subCategories[index];
              return Card(
                  elevation: 0,
                  color: theme.colorScheme.surfaceContainer,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16.0),
                    side: BorderSide(
                      color: isDarkMode
                          ? Colors.grey.shade800
                          : Colors.grey.shade200,
                      width: 1,
                    ),
                  ),
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  child: ListTile(
                    title: Text(sub['name']),
                    // --- MODIFIED: Use a PopupMenuButton for multiple actions ---
                    trailing: PopupMenuButton<String>(
                      icon: const Icon(Icons.more_vert),
                      onSelected: (value) {
                        if (value == 'move') {
                          _showMoveSubCategoryDialog(sub);
                        } else if (value == 'delete') {
                          _confirmAndDelete(sub);
                        }
                      },
                      itemBuilder: (BuildContext context) =>
                          <PopupMenuEntry<String>>[
                        const PopupMenuItem<String>(
                          value: 'move',
                          child: Text('Move to...'),
                        ),
                        const PopupMenuItem<String>(
                          value: 'delete',
                          child: Text('Delete'),
                        ),
                      ],
                    ),
                  ));
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddSubCategoryDialog,
        tooltip: 'Add Sub-Category',
        child: const Icon(Icons.add),
      ),
    );
  }
}