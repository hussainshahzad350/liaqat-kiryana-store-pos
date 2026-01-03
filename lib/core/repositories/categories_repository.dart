import '../database/database_helper.dart';
import '../../models/category_models.dart';

class CategoriesRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  // --- Departments ---
  Future<List<Department>> getAllDepartments() async {
    final db = await _dbHelper.database;
    final result = await db.query('departments', orderBy: 'name_english');
    return result.map((e) => Department.fromMap(e)).toList();
  }

  Future<int> addDepartment(Department dept) async {
    final db = await _dbHelper.database;
    return await db.insert('departments', dept.toMap());
  }

  Future<int> updateDepartment(Department dept) async {
    final db = await _dbHelper.database;
    return await db.update('departments', dept.toMap(), where: 'id = ?', whereArgs: [dept.id]);
  }

  Future<int> deleteDepartment(int id) async {
    final db = await _dbHelper.database;
    return await db.delete('departments', where: 'id = ?', whereArgs: [id]);
  }

  // --- Categories ---
  Future<List<Category>> getCategoriesByDepartment(int departmentId) async {
    final db = await _dbHelper.database;
    final result = await db.query('categories', where: 'department_id = ?', whereArgs: [departmentId], orderBy: 'name_english');
    return result.map((e) => Category.fromMap(e)).toList();
  }
  
  Future<List<Category>> getAllCategories() async {
    final db = await _dbHelper.database;
    final result = await db.query('categories', orderBy: 'name_english');
    return result.map((e) => Category.fromMap(e)).toList();
  }

  Future<int> addCategory(Category cat) async {
    final db = await _dbHelper.database;
    return await db.insert('categories', cat.toMap());
  }

  Future<int> updateCategory(Category cat) async {
    final db = await _dbHelper.database;
    return await db.update('categories', cat.toMap(), where: 'id = ?', whereArgs: [cat.id]);
  }

  Future<int> deleteCategory(int id) async {
    final db = await _dbHelper.database;
    return await db.delete('categories', where: 'id = ?', whereArgs: [id]);
  }

  // --- SubCategories ---
  Future<List<SubCategory>> getAllSubCategories() async {
    final db = await _dbHelper.database;
    final result = await db.query('subcategories', orderBy: 'name_english');
    return result.map((e) => SubCategory.fromMap(e)).toList();
  }

  Future<List<SubCategory>> getSubCategoriesByCategory(int categoryId) async {
    final db = await _dbHelper.database;
    final result = await db.query('subcategories', where: 'category_id = ?', whereArgs: [categoryId], orderBy: 'name_english');
    return result.map((e) => SubCategory.fromMap(e)).toList();
  }

  Future<int> addSubCategory(SubCategory sub) async {
    final db = await _dbHelper.database;
    return await db.insert('subcategories', sub.toMap());
  }

  Future<int> updateSubCategory(SubCategory sub) async {
    final db = await _dbHelper.database;
    return await db.update('subcategories', sub.toMap(), where: 'id = ?', whereArgs: [sub.id]);
  }

  Future<int> deleteSubCategory(int id) async {
    final db = await _dbHelper.database;
    return await db.delete('subcategories', where: 'id = ?', whereArgs: [id]);
  }

  // --- Search ---
  Future<Map<String, Set<int>>> searchHierarchy(String query) async {
    final db = await _dbHelper.database;
    final q = '%${query.toLowerCase()}%';

    // 1. Search Subcategories
    final subResults = await db.rawQuery('''
      SELECT id, category_id FROM subcategories 
      WHERE LOWER(name_english) LIKE ? OR LOWER(name_urdu) LIKE ?
    ''', [q, q]);
    
    final matchingSubIds = subResults.map((e) => e['id'] as int).toSet();
    final parentCatIdsFromSubs = subResults.map((e) => e['category_id'] as int).toSet();

    // 2. Search Categories
    final catResults = await db.rawQuery('''
      SELECT id, department_id FROM categories 
      WHERE LOWER(name_english) LIKE ? OR LOWER(name_urdu) LIKE ?
    ''', [q, q]);

    final matchingCatIds = catResults.map((e) => e['id'] as int).toSet();
    final parentDeptIdsFromCats = catResults.map((e) => e['department_id'] as int).toSet();

    // 3. Search Departments
    final deptResults = await db.rawQuery('''
      SELECT id FROM departments 
      WHERE LOWER(name_english) LIKE ? OR LOWER(name_urdu) LIKE ?
    ''', [q, q]);

    final matchingDeptIds = deptResults.map((e) => e['id'] as int).toSet();

    // 4. Resolve indirect parents (Departments of categories found via subcategories)
    Set<int> parentDeptIdsFromSubParents = {};
    if (parentCatIdsFromSubs.isNotEmpty) {
       final placeholders = List.filled(parentCatIdsFromSubs.length, '?').join(',');
       final extraCats = await db.rawQuery(
         'SELECT department_id FROM categories WHERE id IN ($placeholders)',
         parentCatIdsFromSubs.toList()
       );
       parentDeptIdsFromSubParents = extraCats
           .where((e) => e['department_id'] != null)
           .map((e) => e['department_id'] as int)
           .toSet();
    }

    return {
      'departments': matchingDeptIds..addAll(parentDeptIdsFromCats)..addAll(parentDeptIdsFromSubParents),
      'categories': matchingCatIds..addAll(parentCatIdsFromSubs),
      'subcategories': matchingSubIds,
    };
  }

  // --- Counts & Validation ---
  Future<int> getCategoryCount(int deptId) async {
    final db = await _dbHelper.database;
    final result = await db.rawQuery('SELECT COUNT(*) as count FROM categories WHERE department_id = ?', [deptId]);
    return (result.first['count'] as num?)?.toInt() ?? 0;
  }

  Future<int> getSubCategoryCount(int catId) async {
    final db = await _dbHelper.database;
    final result = await db.rawQuery('SELECT COUNT(*) as count FROM subcategories WHERE category_id = ?', [catId]);
    return (result.first['count'] as num?)?.toInt() ?? 0;
  }

  Future<int> getProductCountByCategory(int catId) async {
    final db = await _dbHelper.database;
    final result = await db.rawQuery('SELECT COUNT(*) as count FROM products WHERE category_id = ?', [catId]);
    return (result.first['count'] as num?)?.toInt() ?? 0;
  }

  Future<int> getProductCountByDepartment(int deptId) async {
    final db = await _dbHelper.database;
    final result = await db.rawQuery('''
      SELECT COUNT(*) as count FROM products p 
      JOIN categories c ON p.category_id = c.id 
      WHERE c.department_id = ?
    ''', [deptId]);
    return (result.first['count'] as num?)?.toInt() ?? 0;
  }
}
