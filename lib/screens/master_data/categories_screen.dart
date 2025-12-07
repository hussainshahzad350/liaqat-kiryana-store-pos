import 'package:flutter/material.dart';

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
    return Scaffold(
      appBar: AppBar(
        title: const Text('کیٹیگریز مينيجمنٹ'),
        backgroundColor: Colors.orange[700],
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _showAddCategoryDialog,
            tooltip: 'نیا کیٹیگری',
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              decoration: InputDecoration(
                labelText: 'کیٹیگری تلاش کریں',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
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
                  child: ExpansionTile(
                    leading: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.orange.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Center(
                        child: Icon(Icons.category, color: Colors.orange),
                      ),
                    ),
                    title: Text(
                      category['name_urdu'],
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(category['name_english']),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.add, size: 18),
                          onPressed: () {
                            _showAddSubcategoryDialog(category['id']);
                          },
                          tooltip: 'سب کیٹیگری شامل کریں',
                        ),
                        IconButton(
                          icon: const Icon(Icons.edit, size: 18, color: Colors.blue),
                          onPressed: () {
                            _showEditCategoryDialog(category);
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, size: 18, color: Colors.red),
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
                                color: Colors.grey[50],
                                child: ListTile(
                                  leading: Container(
                                    width: 30,
                                    height: 30,
                                    decoration: BoxDecoration(
                                      color: Colors.grey.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: const Center(
                                      child: Icon(Icons.subdirectory_arrow_right, size: 16, color: Colors.grey),
                                    ),
                                  ),
                                  title: Text(
                                    subcategory['name_urdu'],
                                    style: const TextStyle(fontSize: 14),
                                  ),
                                  subtitle: Text(
                                    subcategory['name_english'],
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                        icon: const Icon(Icons.edit, size: 16, color: Colors.blue),
                                        onPressed: () {
                                          _showEditSubcategoryDialog(subcategory);
                                        },
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.delete, size: 16, color: Colors.red),
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
                            const Padding(
                              padding: EdgeInsets.only(left: 40, bottom: 16),
                              child: Text(
                                'کوئی سب کیٹیگری نہيں',
                                style: TextStyle(color: Colors.grey),
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
        backgroundColor: Colors.orange[700],
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  void _showAddCategoryDialog() {
    showDialog(
      context: context,
      builder: (context) => CategoryDialog(
        onSave: () {
          // Add category logic
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('کیٹیگری شامل ہو گئی')),
          );
        },
      ),
    );
  }

  void _showAddSubcategoryDialog(int parentId) {
    showDialog(
      context: context,
      builder: (context) => CategoryDialog(
        isSubcategory: true,
        onSave: () {
          // Add subcategory logic
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('سب کیٹیگری شامل ہو گئی')),
          );
        },
      ),
    );
  }

  void _showEditCategoryDialog(Map<String, dynamic> category) {
    showDialog(
      context: context,
      builder: (context) => CategoryDialog(
        category: category,
        onSave: () {
          // Edit category logic
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('کیٹیگری اپ ڈیٹ ہو گئی')),
          );
        },
      ),
    );
  }

  void _showEditSubcategoryDialog(Map<String, dynamic> subcategory) {
    showDialog(
      context: context,
      builder: (context) => CategoryDialog(
        category: subcategory,
        isSubcategory: true,
        onSave: () {
          // Edit subcategory logic
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('سب کیٹیگری اپ ڈیٹ ہو گئی')),
          );
        },
      ),
    );
  }

  void _deleteCategory(int id) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تصدیق'),
        content: const Text('کیا آپ واقعی اس کیٹیگری کو حذف کرنا چاہتے ہیں؟ تمام سب کیٹیگریز بھی حذف ہو جائیں گی۔'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('نہيں'),
          ),
          ElevatedButton(
            onPressed: () {
              // Delete logic
              setState(() {
                categories.removeWhere((cat) => cat['id'] == id);
              });
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('کیٹیگری حذف ہو گئی')),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('ہاں، حذف کریں'),
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
    return AlertDialog(
      title: Text(widget.isSubcategory ? 'نیا سب کیٹیگری' : 'نیا کیٹیگری'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (widget.isSubcategory) ...[
                DropdownButtonFormField(
                  decoration: const InputDecoration(
                    labelText: 'مین کیٹیگری',
                    border: OutlineInputBorder(),
                  ),
                  value: _selectedParentCategory,
                  items: const [
                    DropdownMenuItem(value: '1', child: Text('چاول')),
                    DropdownMenuItem(value: '2', child: Text('دالیں')),
                    DropdownMenuItem(value: '3', child: Text('تیل اور گھی')),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _selectedParentCategory = value;
                    });
                  },
                  validator: (value) {
                    if (widget.isSubcategory && (value == null || value.isEmpty)) {
                      return 'براہ کرم مین کیٹیگری منتخب کریں';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
              ],
              TextFormField(
                controller: _nameEnController,
                decoration: const InputDecoration(
                  labelText: 'انگریزی نام *',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'براہ کرم نام درج کریں';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _nameUrController,
                decoration: const InputDecoration(
                  labelText: 'اردو نام *',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'براہ کرم اردو نام درج کریں';
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
          child: const Text('منسوخ'),
        ),
        ElevatedButton(
          onPressed: _saveCategory,
          child: const Text('محفوظ کریں'),
        ),
      ],
    );
  }
}