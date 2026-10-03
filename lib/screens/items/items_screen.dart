import 'package:flutter/material.dart';
import '../../core/repositories/categories_repository.dart';
import '../../core/repositories/items_repository.dart';
import '../../core/repositories/units_repository.dart';
import '../../l10n/app_localizations.dart';
import '../../models/category_models.dart';
import '../../models/product_model.dart';
import 'dialogs/item_form_dialog.dart';
import 'widgets/items_table.dart';
import 'widgets/items_toolbar.dart';

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
          _categoryNames = {
            for (var c in categories)
              if (c.id != null) c.id!: c.nameEn
          };
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
          _subCategoryNames = {
            for (var s in allSubs)
              if (s.id != null) s.id!: s.nameEn
          };
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

  void _clearSearch() {
    searchController.clear();
    _firstLoad();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return ColoredBox(
      color: colorScheme.surface,
      child: Column(
        children: [
          ItemsToolbar(
            searchController: searchController,
            onSearch: _firstLoad,
            onClearSearch: _clearSearch,
            onAddItem: _showAddItemDialog,
          ),
          Expanded(
            child: ItemsTable(
              items: items,
              categoryNames: _categoryNames,
              subCategoryNames: _subCategoryNames,
              scrollController: _scrollController,
              isInitialLoading: _isFirstLoadRunning,
              isLoadingMore: _isLoadMoreRunning,
              hasNextPage: _hasNextPage,
              onEditItem: _showEditItemDialog,
              onDeleteItem: _deleteItem,
            ),
          ),
        ],
      ),
    );
  }

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
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(AppLocalizations.of(context)!.saveChangesSuccess),
          backgroundColor: Theme.of(context).colorScheme.primary));
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
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(AppLocalizations.of(context)!.saveChangesSuccess),
          backgroundColor: Theme.of(context).colorScheme.primary));
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
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(localizations.no,
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.copyWith(color: colorScheme.onSurface))),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
                backgroundColor: colorScheme.error,
                foregroundColor: colorScheme.onError),
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
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(localizations.itemDeleted),
            backgroundColor: colorScheme.primary));
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('${localizations.error}: $e'),
            backgroundColor: colorScheme.error));
      }
    }
  }
}
