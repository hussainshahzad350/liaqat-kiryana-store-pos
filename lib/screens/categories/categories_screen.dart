import 'package:flutter/material.dart';
import '../../l10n/app_localizations.dart';

class CategoriesScreen extends StatefulWidget {
  const CategoriesScreen({super.key});

  @override
  State<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends State<CategoriesScreen> {
  List<Map<String, dynamic>> categories = [
    {
      'id': 1,
      'name_english': 'Rice',
      'name_urdu': 'چاول',
      'parent_id': null,
      'has_subcategories': true,
      'subcategories': [
        {'id': 11, 'name_english': 'Basmati Rice', 'name_urdu': 'باسمتی چاول'},
        {'id': 12, 'name_english': 'IRRI Rice', 'name_urdu': 'ايری چاول'},
      ]
    },
    {
      'id': 2,
      'name_english': 'Pulses',
      'name_urdu': 'دالیں',
      'parent_id': null,
      'has_subcategories': true,
      'subcategories': [
        {'id': 21, 'name_english': 'Masoor Dal', 'name_urdu': 'مسور دال'},
        {'id': 22, 'name_english': 'Chana Dal', 'name_urdu': 'چنا دال'},
      ]
    },
    {
      'id': 3,
      'name_english': 'Oil & Ghee',
      'name_urdu': 'تیل اور گھی',
      'parent_id': null,
      'has_subcategories': false,
      'subcategories': []
    },
    {
      'id': 4,
      'name_english': 'Spices',
      'name_urdu': 'مصالحے',
      'parent_id': null,
      'has_subcategories': false,
      'subcategories': []
    },
    {
      'id': 5,
      'name_english': 'Beverages',
      'name_urdu': 'مشروبات',
      'parent_id': null,
      'has_subcategories': false,
      'subcategories': []
    },
  ];

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: Text(loc.categories, style: TextStyle(color: colorScheme.onPrimary)),
        backgroundColor: colorScheme.primary,
        iconTheme: IconThemeData(color: colorScheme.onPrimary),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _showAddCategoryDialog,
            tooltip: loc.addItem,
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              style: TextStyle(color: colorScheme.onSurface),
              decoration: InputDecoration(
                labelText: loc.search,
                labelStyle: TextStyle(color: colorScheme.onSurfaceVariant),
                prefixIcon: Icon(Icons.search, color: colorScheme.onSurfaceVariant),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: colorScheme.outline),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: colorScheme.outline),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: colorScheme.primary, width: 2),
                ),
              ),
              onChanged: (value) {
                // Search functionality
              },
            ),
          ),

          // Categories List
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: categories.length,
              itemBuilder: (context, index) {
                final category = categories[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  color: colorScheme.surface,
                  elevation: 2,
                  child: ExpansionTile(
                    collapsedIconColor: colorScheme.onSurfaceVariant,
                    iconColor: colorScheme.primary,
                    leading: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Center(
                        child: Icon(Icons.category, color: colorScheme.onPrimaryContainer),
                      ),
                    ),
                    title: Text(
                      category['name_urdu'],
                      style: TextStyle(fontWeight: FontWeight.bold, color: colorScheme.onSurface, fontFamily: 'NooriNastaleeq'),
                    ),
                    subtitle: Text(category['name_english'], style: TextStyle(color: colorScheme.onSurfaceVariant)),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: Icon(Icons.add, size: 20, color: colorScheme.primary),
                          onPressed: () {
                            _showAddSubcategoryDialog(category['id']);
                          },
                          tooltip: 'Add Subcategory',
                        ),
                        IconButton(
                          icon: Icon(Icons.edit, size: 18, color: colorScheme.secondary),
                          onPressed: () {
                            _showEditCategoryDialog(category);
                          },
                        ),
                        IconButton(
                          icon: Icon(Icons.delete, size: 18, color: colorScheme.error),
                          onPressed: () {
                            _deleteCategory(category['id']);
                          },
                        ),
                      ],
                    ),
                    children: category['has_subcategories'] && (category['subcategories'] as List).isNotEmpty
                        ? (category['subcategories'] as List).map<Widget>((subcategory) {
                            return Padding(
                              padding: const EdgeInsets.only(left: 40, right: 16, bottom: 8),
                              child: Card(
                                color: colorScheme.surfaceVariant.withOpacity(0.3),
                                elevation: 0,
                                child: ListTile(
                                  leading: Container(
                                    width: 30,
                                    height: 30,
                                    decoration: BoxDecoration(
                                      color: colorScheme.surfaceVariant,
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Center(
                                      child: Icon(Icons.subdirectory_arrow_right, size: 16, color: colorScheme.onSurfaceVariant),
                                    ),
                                  ),
                                  title: Text(
                                    subcategory['name_urdu'],
                                    style: TextStyle(fontSize: 14, color: colorScheme.onSurface, fontFamily: 'NooriNastaleeq'),
                                  ),
                                  subtitle: Text(
                                    subcategory['name_english'],
                                    style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant),
                                  ),
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                        icon: Icon(Icons.edit, size: 16, color: colorScheme.secondary),
                                        onPressed: () {
                                          _showEditSubcategoryDialog(subcategory);
                                        },
                                      ),
                                      IconButton(
                                        icon: Icon(Icons.delete, size: 16, color: colorScheme.error),
                                        onPressed: () {
                                          _deleteSubcategory(subcategory['id']);
                                        },
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          }).toList()
                        : [
                            Padding(
                              padding: const EdgeInsets.only(left: 40, bottom: 16),
                              child: Text(
                                'No subcategories',
                                style: TextStyle(color: colorScheme.onSurfaceVariant),
                              ),
                            ),
                          ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddCategoryDialog,
        backgroundColor: colorScheme.primary,
        child: Icon(Icons.add, color: colorScheme.onPrimary),
      ),
    );
  }

  void _showAddCategoryDialog() {
    final loc = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (context) => CategoryDialog(
        onSave: () {
          // Add category logic
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(loc.saveChangesSuccess)),
          );
        },
      ),
    );
  }

  void _showAddSubcategoryDialog(int parentId) {
    final loc = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (context) => CategoryDialog(
        isSubcategory: true,
        onSave: () {
          // Add subcategory logic
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(loc.saveChangesSuccess)),
          );
        },
      ),
    );
  }

  void _showEditCategoryDialog(Map<String, dynamic> category) {
    final loc = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (context) => CategoryDialog(
        category: category,
        onSave: () {
          // Edit category logic
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(loc.saveChangesSuccess)),
          );
        },
      ),
    );
  }

  void _showEditSubcategoryDialog(Map<String, dynamic> subcategory) {
    final loc = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (context) => CategoryDialog(
        category: subcategory,
        isSubcategory: true,
        onSave: () {
          // Edit subcategory logic
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(loc.saveChangesSuccess)),
          );
        },
      ),
    );
  }

  void _deleteCategory(int id) {
    final loc = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: colorScheme.surface,
        title: Text(loc.confirm, style: TextStyle(color: colorScheme.onSurface)),
        content: Text(loc.confirmDeleteItem, style: TextStyle(color: colorScheme.onSurface)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(loc.no, style: TextStyle(color: colorScheme.onSurface)),
          ),
          ElevatedButton(
            onPressed: () {
              // Delete logic
              setState(() {
                categories.removeWhere((cat) => cat['id'] == id);
              });
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(loc.itemDeleted), backgroundColor: colorScheme.primary),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: colorScheme.error, foregroundColor: colorScheme.onError),
            child: Text(loc.yesDelete),
          ),
        ],
      ),
    );
  }

  void _deleteSubcategory(int id) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تصدیق'),
        content: const Text('کیا آپ واقعی اس سب کیٹیگری کو حذف کرنا چاہتے ہیں؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('نہيں'),
          ),
          ElevatedButton(
            onPressed: () {
              // Delete subcategory logic
              for (var category in categories) {
                final subs = category['subcategories'] as List;
                subs.removeWhere((sub) => sub['id'] == id);
              }
              setState(() {});
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('سب کیٹیگری حذف ہو گئی')),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('ہاں، حذف کریں'),
          ),
        ],
      ),
    );
  }
}

// ==================== Category Dialog ====================
class CategoryDialog extends StatefulWidget {
  final Map<String, dynamic>? category;
  final bool isSubcategory;
  final VoidCallback onSave;

  const CategoryDialog({
    super.key,
    this.category,
    this.isSubcategory = false,
    required this.onSave,
  });

  @override
  State<CategoryDialog> createState() => _CategoryDialogState();
}

class _CategoryDialogState extends State<CategoryDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameEnController = TextEditingController();
  final _nameUrController = TextEditingController();
  String? _selectedParentCategory;

  @override
  void initState() {
    super.initState();
    if (widget.category != null) {
      _nameEnController.text = widget.category!['name_english'] ?? '';
      _nameUrController.text = widget.category!['name_urdu'] ?? '';
    }
  }

  @override
  void dispose() {
    _nameEnController.dispose();
    _nameUrController.dispose();
    super.dispose();
  }

  void _saveCategory() {
    if (_formKey.currentState!.validate()) {
      widget.onSave();
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    return AlertDialog(
      backgroundColor: colorScheme.surface,
      title: Text(widget.isSubcategory ? 'New Subcategory' : loc.addItem, style: TextStyle(color: colorScheme.onSurface, fontWeight: FontWeight.bold)),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (widget.isSubcategory) ...[
                DropdownButtonFormField(
                  decoration: InputDecoration(
                    labelText: 'Parent Category',
                    labelStyle: TextStyle(color: colorScheme.onSurfaceVariant),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    filled: true,
                    fillColor: colorScheme.surfaceVariant,
                  ),
                  initialValue: _selectedParentCategory,
                  items: [
                    DropdownMenuItem(value: '1', child: Text('Rice', style: TextStyle(color: colorScheme.onSurface))),
                    DropdownMenuItem(value: '2', child: Text('Pulses', style: TextStyle(color: colorScheme.onSurface))),
                    DropdownMenuItem(value: '3', child: Text('Oil', style: TextStyle(color: colorScheme.onSurface))),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _selectedParentCategory = value;
                    });
                  },
                  validator: (value) {
                    if (widget.isSubcategory && (value == null || value.isEmpty)) {
                      return loc.fieldRequired;
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
              ],
              TextFormField(
                controller: _nameEnController,
                style: TextStyle(color: colorScheme.onSurface),
                decoration: InputDecoration(
                  labelText: loc.englishName,
                  labelStyle: TextStyle(color: colorScheme.onSurfaceVariant),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  filled: true,
                  fillColor: colorScheme.surfaceVariant,
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return loc.fieldRequired;
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _nameUrController,
                style: TextStyle(color: colorScheme.onSurface, fontFamily: 'NooriNastaleeq'),
                decoration: InputDecoration(
                  labelText: loc.urduName,
                  labelStyle: TextStyle(color: colorScheme.onSurfaceVariant),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  filled: true,
                  fillColor: colorScheme.surfaceVariant,
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return loc.fieldRequired;
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(loc.cancel, style: TextStyle(color: colorScheme.onSurface)),
        ),
        ElevatedButton(
          onPressed: _saveCategory,
          style: ElevatedButton.styleFrom(backgroundColor: colorScheme.primary, foregroundColor: colorScheme.onPrimary),
          child: Text(loc.save),
        ),
      ],
    );
  }
}