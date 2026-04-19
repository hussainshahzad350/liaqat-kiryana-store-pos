import 'package:equatable/equatable.dart';
import '../../models/category_models.dart';

abstract class CategoriesEvent extends Equatable {
  const CategoriesEvent();

  @override
  List<Object?> get props => [];
}

class LoadCategories extends CategoriesEvent {}

class SearchCategories extends CategoriesEvent {
  final String query;
  const SearchCategories(this.query);
  @override
  List<Object?> get props => [query];
}

class SelectDepartment extends CategoriesEvent {
  final Department? department;
  const SelectDepartment(this.department);
  @override
  List<Object?> get props => [department];
}

class SelectCategory extends CategoriesEvent {
  final Category? category;
  const SelectCategory(this.category);
  @override
  List<Object?> get props => [category];
}

class SelectSubCategory extends CategoriesEvent {
  final SubCategory? subCategory;
  const SelectSubCategory(this.subCategory);
  @override
  List<Object?> get props => [subCategory];
}

class PreloadCategorySubCategories extends CategoriesEvent {
  final int categoryId;
  const PreloadCategorySubCategories(this.categoryId);
  @override
  List<Object?> get props => [categoryId];
}

// CRUD Events
class AddDepartment extends CategoriesEvent {
  final Department department;
  const AddDepartment(this.department);
  @override
  List<Object?> get props => [department];
}

class UpdateDepartment extends CategoriesEvent {
  final Department department;
  const UpdateDepartment(this.department);
  @override
  List<Object?> get props => [department];
}

class DeleteDepartment extends CategoriesEvent {
  final int id;
  const DeleteDepartment(this.id);
  @override
  List<Object?> get props => [id];
}

class AddCategory extends CategoriesEvent {
  final Category category;
  const AddCategory(this.category);
  @override
  List<Object?> get props => [category];
}

class UpdateCategory extends CategoriesEvent {
  final Category category;
  const UpdateCategory(this.category);
  @override
  List<Object?> get props => [category];
}

class DeleteCategory extends CategoriesEvent {
  final int id;
  const DeleteCategory(this.id);
  @override
  List<Object?> get props => [id];
}

class AddSubCategory extends CategoriesEvent {
  final SubCategory subCategory;
  const AddSubCategory(this.subCategory);
  @override
  List<Object?> get props => [subCategory];
}

class UpdateSubCategory extends CategoriesEvent {
  final SubCategory subCategory;
  const UpdateSubCategory(this.subCategory);
  @override
  List<Object?> get props => [subCategory];
}

class DeleteSubCategory extends CategoriesEvent {
  final int id;
  const DeleteSubCategory(this.id);
  @override
  List<Object?> get props => [id];
}
