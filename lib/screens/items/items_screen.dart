// lib/screens/master_data/items_screen.dart
// ignore_for_file: deprecated_member_use, use_build_context_synchronously

import 'package:flutter/material.dart';
import '../../core/repositories/items_repository.dart';
import '../../l10n/app_localizations.dart';

import '../../models/product_model.dart';
import '../../core/repositories/categories_repository.dart';
import '../../core/repositories/units_repository.dart';
import '../../models/category_models.dart';
import '../../models/unit_model.dart';

class ItemsScreen extends StatefulWidget {
  const ItemsScreen({super.key});

  @override
  State<ItemsScreen> createState() => _ItemsScreenState();
}

class _ItemsScreenState extends State<ItemsScreen> {
  final ItemsRepository _itemsRepository = ItemsRepository();
  final CategoriesRepository _categoriesRepository = CategoriesRepository();
  final UnitsRepository _unitsRepository = UnitsRepository();
  // Pagination & Data State
  List<Product> items = [];
  Map<int, String> _categoryNames = {};
  Map<int, String> _subCategoryNames = {};
  bool _isFirstLoadRunning = true;
  bool _hasNextPage = true;
  bool _isLoadMoreRunning = false;
  final int _limit = 20;

  late ScrollController _scrollController;
  final TextEditingController searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController()..addListener(_scrollListener);
    _loadCategories();
    _loadSubCategories();
    _firstLoad();
  }

  @override
  void dispose() {
    _scrollController.removeListener(_scrollListener);
    _scrollController.dispose();
    searchController.dispose();
    super.dispose();
  }

  void _scrollListener() {
    if (_scrollController.position.extentAfter < 200 && // Load when near bottom
        !_isFirstLoadRunning &&
        !_isLoadMoreRunning &&
        _hasNextPage) {
      _loadMoreItems();
    }
  }

  // --- Data Loading Logic ---

  Future<void> _loadCategories() async {
    try {
      final categories = await _categoriesRepository.getAllCategories();
      if (mounted) {
        setState(() {
          _categoryNames = {for (var c in categories) if (c.id != null) c.id!: c.nameEn};
        });
      }
    } catch (e) {
      // Ignore errors for category loading
    }
  }

  Future<void> _loadSubCategories() async {
    try {
      // Fetch all categories first to get subcategories for each
      final categories = await _categoriesRepository.getAllCategories();
      final List<SubCategory> allSubs = [];
      
      final futures = categories
          .where((c) => c.id != null)
          .map((c) => _categoriesRepository.getSubCategoriesByCategory(c.id!));
      
      final results = await Future.wait(futures);
      for (var list in results) {
        allSubs.addAll(list);
      }

      if (mounted) {
        setState(() {
          _subCategoryNames = {for (var s in allSubs) if (s.id != null) s.id!: s.nameEn};
        });
      }
    } catch (e) {
      // Ignore errors if method doesn't exist or fails
    }
  }

  Future<void> _firstLoad() async {
    setState(() {
      _isFirstLoadRunning = true;
      _hasNextPage = true;
      items = [];
    });

    try {
      final String searchQuery = searchController.text.trim();
      
      List<Product> result;
      
      if (searchQuery.isNotEmpty) {
        result = await _itemsRepository.searchProducts(searchQuery);
      } else {
        result = await _itemsRepository.getAllProducts();
      }

      if (!mounted) return;

      setState(() {
        items = result;
        _isFirstLoadRunning = false;
        // If we got fewer items than limit, no more pages exist
        if (result.length < _limit) {
          _hasNextPage = false;
        }
      });
    } catch (e) {
      if (mounted) setState(() => _isFirstLoadRunning = false);
    }
  }

  Future<void> _loadMoreItems() async {
    if (_isLoadMoreRunning || !_hasNextPage) return;

    setState(() => _isLoadMoreRunning = true);

    try {
      final String searchQuery = searchController.text.trim();

      List<Product> result;
      
      if (searchQuery.isNotEmpty) {
        result = await _itemsRepository.searchProducts(searchQuery);
      } else {
        result = await _itemsRepository.getAllProducts();
      }

      if (!mounted) return;

      setState(() {
        if (result.isNotEmpty) {
          items.addAll(result);
        } else {
          _hasNextPage = false;
        }
        
        _isLoadMoreRunning = false;
      });
    } catch (e) {
      if (mounted) setState(() => _isLoadMoreRunning = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    final isUrdu = Localizations.localeOf(context).languageCode == 'ur';

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: Text(localizations.itemsManagement, style: TextStyle(color: colorScheme.onPrimary)), // Ensure localizations and colorScheme are not null
        backgroundColor: colorScheme.primary,
        iconTheme: IconThemeData(color: colorScheme.onPrimary),
        actions: [
          IconButton(icon: const Icon(Icons.add), onPressed: _showAddItemDialog),
        ],
      ),
      body: Column(
          children: [
            // Top Toolbar
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  // Search Field (Left)
                  Expanded(
                    child: TextField(
                      controller: searchController,
                      style: TextStyle(color: colorScheme.onSurface),
                      textInputAction: TextInputAction.search,
                      onSubmitted: (_) => _firstLoad(),
                      decoration: InputDecoration(
                        labelText: localizations.searchItem,
                        labelStyle: TextStyle(color: colorScheme.onSurfaceVariant),
                        prefixIcon: IconButton(
                          icon: Icon(Icons.search, color: colorScheme.onSurfaceVariant),
                          onPressed: _firstLoad,
                        ),
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
                        filled: true,
                        fillColor: colorScheme.surfaceVariant,
                        suffixIcon: IconButton(
                          icon: Icon(Icons.clear, color: colorScheme.onSurfaceVariant),
                          onPressed: () {
                            searchController.clear();
                            _firstLoad();
                          },
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  // Add Item Button (Right)
                  ElevatedButton.icon(
                    onPressed: _showAddItemDialog,
                    icon: const Icon(Icons.add),
                    label: Text(localizations.addItem),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colorScheme.primary,
                      foregroundColor: colorScheme.onPrimary,
                    ),
                  ),
                ],
              ),
            ),
            // Data Table
            Expanded(
              child: _isFirstLoadRunning
                  ? const Center(child: CircularProgressIndicator())
                  : items.isEmpty
                      ? Center(child: Text(localizations.noItemsFound, style: TextStyle(color: colorScheme.onSurface)))
                      : LayoutBuilder(
                          builder: (context, constraints) {
                            return SingleChildScrollView(
                              controller: _scrollController,
                              scrollDirection: Axis.vertical,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  SingleChildScrollView(
                                    scrollDirection: Axis.horizontal,
                                    child: ConstrainedBox(
                                      constraints: BoxConstraints(minWidth: constraints.maxWidth),
                                      child: DataTable(
                                        headingRowHeight: 56,
                                        dataRowMinHeight: 64,
                                        dataRowMaxHeight: 64,
                                        columnSpacing: 32,
                                        horizontalMargin: 32,
                                        headingRowColor: MaterialStateProperty.all(colorScheme.surfaceVariant),
                                        dataRowColor: MaterialStateProperty.resolveWith<Color?>((Set<MaterialState> states) {
                                          if (states.contains(MaterialState.hovered)) return colorScheme.surfaceVariant.withOpacity(0.2);
                                          return null;
                                        }),
                                        columns: [
                                          DataColumn(label: Text(localizations.englishName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14))),
                                          DataColumn(label: Text(localizations.urduName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14))),
                                          const DataColumn(label: Text('Category', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14))),
                                          const DataColumn(label: Text('Sub Category', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14))),
                                          const DataColumn(label: Text('Brand', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14))),
                                          const DataColumn(label: Text('Unit', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14))),
                                          const DataColumn(label: Text('Packing', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14))),
                                          const DataColumn(label: Text('Actions', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14))),
                                        ],
                                        rows: items.map((item) {
                                          return DataRow(
                                            cells: [
                                              DataCell(Text(item.nameEnglish, style: TextStyle(color: colorScheme.onSurface, fontSize: 14))),
                                              DataCell(Text(item.nameUrdu ?? '-', style: TextStyle(fontFamily: 'NooriNastaleeq', color: colorScheme.onSurface, fontSize: 16))),
                                              DataCell(Text(_categoryNames[item.categoryId] ?? '-', style: TextStyle(color: colorScheme.onSurface, fontSize: 14))),
                                              DataCell(Text(_subCategoryNames[item.subCategoryId] ?? '-', style: TextStyle(color: colorScheme.onSurface, fontSize: 14))),
                                              DataCell(Text(item.brand ?? '-', style: TextStyle(color: colorScheme.onSurface, fontSize: 14))),
                                              DataCell(Text(item.unitType ?? '-', style: TextStyle(color: colorScheme.onSurface, fontSize: 14))),
                                              DataCell(Text(item.packingType ?? '-', style: TextStyle(color: colorScheme.onSurface, fontSize: 14))),
                                              DataCell(
                                                Row(
                                                  mainAxisSize: MainAxisSize.min,
                                                  children: [
                                                    IconButton(
                                                      icon: Icon(Icons.edit_outlined, color: colorScheme.secondary, size: 22),
                                                      onPressed: () => _showEditItemDialog(item),
                                                      tooltip: localizations.editItem,
                                                      padding: EdgeInsets.zero,
                                                      constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                                                    ),
                                                    const SizedBox(width: 8),
                                                    IconButton(
                                                      icon: Icon(Icons.delete_outline, color: colorScheme.error, size: 22),
                                                      onPressed: () => _deleteItem(item.id!),
                                                      tooltip: isUrdu ? 'آئٹم حذف کریں' : 'Delete Item',
                                                      padding: EdgeInsets.zero,
                                                      constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ],
                                          );
                                        }).toList(),
                                      ),
                                    ),
                                  ),
                                if (_isLoadMoreRunning)
                                  const Padding(
                                    padding: EdgeInsets.all(16.0),
                                    child: Center(child: CircularProgressIndicator()),
                                  ),
                                if (!_hasNextPage && items.isNotEmpty)
                                  Padding(
                                    padding: const EdgeInsets.all(16),
                                    child: Center(child: Text(localizations.endOfList, style: TextStyle(color: colorScheme.onSurfaceVariant))),
                                  ),
                              ],
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
  // ... [Dialog methods _showAddItemDialog, _showEditItemDialog, _deleteItem remain unchanged] ...
  
  // (Include previous helper methods here for complete file)
  Future<void> _showAddItemDialog() async {
    final Product? newProduct = await showDialog<Product>(
      context: context,
      builder: (context) => ItemFormDialog(
        categoriesRepository: _categoriesRepository,
        unitsRepository: _unitsRepository,
      ),
    );

    if (newProduct != null && mounted) {
      await _itemsRepository.addProduct(newProduct);
      _firstLoad();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.saveChangesSuccess), backgroundColor: Theme.of(context).colorScheme.primary)
      );
    }
  }

  Future<void> _showEditItemDialog(Product item) async {
    final Product? updatedProduct = await showDialog<Product>(
      context: context,
      builder: (context) => ItemFormDialog(
        product: item,
        categoriesRepository: _categoriesRepository,
        unitsRepository: _unitsRepository,
      ),
    );

    if (updatedProduct != null && mounted) {
      await _itemsRepository.updateProduct(item.id!, updatedProduct);
      _firstLoad();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.saveChangesSuccess), backgroundColor: Theme.of(context).colorScheme.primary)
      );
    }
  }

  Future<void> _deleteItem(int id) async {
    final localizations = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    
    final confirmed = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: colorScheme.surface,
        title: Text(localizations.confirm),
        content: Text(localizations.confirmDeleteItem),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text(localizations.no, style: TextStyle(color: colorScheme.onSurface))),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: colorScheme.error, foregroundColor: colorScheme.onError),
            child: Text(localizations.yesDelete),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _itemsRepository.deleteProduct(id);
        
        if (!mounted) return;

        _firstLoad();
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(localizations.itemDeleted), backgroundColor: colorScheme.primary));
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${localizations.error}: $e'), backgroundColor: colorScheme.error));
      }
    }
  }
}

class ItemFormDialog extends StatefulWidget {
  final Product? product;
  final CategoriesRepository categoriesRepository;
  final UnitsRepository unitsRepository;

  const ItemFormDialog({
    super.key,
    this.product,
    required this.categoriesRepository,
    required this.unitsRepository,
  });

  @override
  State<ItemFormDialog> createState() => _ItemFormDialogState();
}

class _ItemFormDialogState extends State<ItemFormDialog> {
  late TextEditingController _nameEngCtrl;
  late TextEditingController _nameUrduCtrl;
  late TextEditingController _brandCtrl;
  late TextEditingController _packingCtrl;
  late TextEditingController _tagsCtrl;

  int? _selectedCategoryId;
  int? _selectedSubCategoryId;
  List<SubCategory> _subCategories = [];
  int? _selectedUnitId;
  String? _selectedUnitType;

  @override
  void initState() {
    super.initState();
    _nameEngCtrl = TextEditingController(text: widget.product?.nameEnglish);
    _nameUrduCtrl = TextEditingController(text: widget.product?.nameUrdu);
    _brandCtrl = TextEditingController(text: widget.product?.brand);
    _packingCtrl = TextEditingController(text: widget.product?.packingType);
    _tagsCtrl = TextEditingController(text: widget.product?.searchTags);

    _selectedCategoryId = widget.product?.categoryId;
    _selectedSubCategoryId = widget.product?.subCategoryId;
    if (_selectedCategoryId != null) {
      _fetchSubCategories(_selectedCategoryId!);
    }
    _selectedUnitId = widget.product?.unitId;
    _selectedUnitType = widget.product?.unitType;
  }

  @override
  void dispose() {
    _nameEngCtrl.dispose();
    _nameUrduCtrl.dispose();
    _brandCtrl.dispose();
    _packingCtrl.dispose();
    _tagsCtrl.dispose();
    super.dispose();
  }

  Future<void> _fetchSubCategories(int categoryId) async {
    try {
      final subs = await widget.categoriesRepository.getSubCategoriesByCategory(categoryId);
      if (mounted) {
        setState(() {
          _subCategories = subs;
          // Ensure the selected subcategory exists in the fetched list
          if (subs.isNotEmpty && _selectedSubCategoryId != null && !subs.any((s) => s.id == _selectedSubCategoryId)) {
            _selectedSubCategoryId = null;
          }
        });
      }
    } catch (e) {
      // Handle error
    }
  }

  InputDecoration _buildInputDecoration(String label, IconData icon) {
    final colorScheme = Theme.of(context).colorScheme;
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(color: colorScheme.onSurfaceVariant),
      prefixIcon: Icon(icon, color: colorScheme.onSurfaceVariant),
      filled: true,
      fillColor: colorScheme.surfaceVariant.withOpacity(0.3),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: colorScheme.outline)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: colorScheme.outline)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: colorScheme.primary, width: 2)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    );
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    final isEdit = widget.product != null;

    return AlertDialog(
      backgroundColor: colorScheme.surface,
      title: Text(isEdit ? localizations.editItem : localizations.addItem, style: TextStyle(fontWeight: FontWeight.bold, color: colorScheme.onSurface)),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 700),
        child: FutureBuilder(
          future: Future.wait([
            widget.categoriesRepository.getAllCategories(),
            widget.unitsRepository.getUnits(),
          ]),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const SizedBox(height: 200, child: Center(child: CircularProgressIndicator()));
            }
            if (snapshot.hasError) {
              return SizedBox(height: 200, child: Center(child: Text('Error: ${snapshot.error}')));
            }

            final categories = snapshot.data?[0] as List<Category>? ?? [];
            final units = snapshot.data?[1] as List<Unit>? ?? [];

            return SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(height: 10),
                  Row(children: [
                    Expanded(child: TextField(controller: _nameEngCtrl, decoration: _buildInputDecoration(localizations.englishName, Icons.inventory_2_outlined))),
                    const SizedBox(width: 16),
                    Expanded(child: TextField(controller: _nameUrduCtrl, decoration: _buildInputDecoration(localizations.urduName, Icons.translate), style: const TextStyle(fontFamily: 'NooriNastaleeq', fontSize: 16))),
                  ]),
                  const SizedBox(height: 16),
                  Row(children: [
                    Expanded(child: DropdownButtonFormField<int>(
                      value: _selectedCategoryId,
                      decoration: _buildInputDecoration(localizations.category, Icons.category_outlined),
                      items: categories.map((c) => DropdownMenuItem(value: c.id, child: Text(c.nameEn))).toList(),
                      onChanged: (val) {
                        setState(() {
                          _selectedCategoryId = val;
                          _selectedSubCategoryId = null;
                          _subCategories = [];
                        });
                        if (val != null) _fetchSubCategories(val);
                      },
                    )),
                    const SizedBox(width: 16),
                    Expanded(child: DropdownButtonFormField<int>(
                      value: _subCategories.any((s) => s.id == _selectedSubCategoryId) ? _selectedSubCategoryId : null,
                      decoration: _buildInputDecoration('Sub Category', Icons.subdirectory_arrow_right),
                      items: _subCategories
                          .where((s) => s.id != null)
                          .map((s) => DropdownMenuItem(value: s.id, child: Text(s.nameEn)))
                          .toList(),
                      onChanged: (val) => setState(() => _selectedSubCategoryId = val),
                    )),
                  ]),
                  const SizedBox(height: 16),
                  Row(children: [
                    Expanded(child: TextField(
                      controller: _brandCtrl,
                      decoration: _buildInputDecoration('Brand', Icons.branding_watermark_outlined),
                    )),
                    const SizedBox(width: 16),
                    Expanded(child: TextField(controller: _packingCtrl, decoration: _buildInputDecoration(localizations.packingType, Icons.archive_outlined))),
                  ]),
                  const SizedBox(height: 16),
                  Row(children: [
                    Expanded(child: DropdownButtonFormField<int>(
                      value: _selectedUnitId,
                      decoration: _buildInputDecoration(localizations.unit, Icons.straighten),
                      items: units.map((u) => DropdownMenuItem(value: u.id, child: Text('${u.name} (${u.code})'))).toList(),
                      onChanged: (val) => setState(() {
                        _selectedUnitId = val;
                        _selectedUnitType = units.firstWhere((u) => u.id == val).code;
                      }),
                    )),
                    const SizedBox(width: 16),
                    Expanded(child: TextField(controller: _tagsCtrl, decoration: _buildInputDecoration(localizations.searchTags, Icons.tag))),
                  ]),
                ],
              ),
            );
          },
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: Text(localizations.cancel)),
        ElevatedButton(
          onPressed: () {
            if (_nameEngCtrl.text.isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("${localizations.englishName} ${localizations.fieldRequired}")));
              return;
            }
            final product = (widget.product ?? Product(nameEnglish: '')).copyWith(
              nameEnglish: _nameEngCtrl.text,
              nameUrdu: _nameUrduCtrl.text,
              categoryId: _selectedCategoryId,
              subCategoryId: _selectedSubCategoryId,
              brand: _brandCtrl.text.trim().isEmpty ? null : _brandCtrl.text.trim(),
              unitId: _selectedUnitId,
              unitType: _selectedUnitType,
              packingType: _packingCtrl.text,
              searchTags: _tagsCtrl.text,
            );
            Navigator.pop(context, product);
          },
          child: Text(isEdit ? localizations.update : localizations.save),
        ),
      ],
    );
  }
}