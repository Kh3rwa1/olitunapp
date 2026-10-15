// This collection stores categories for the Learn home tab only
// (Alphabets, Numbers, Vocabulary, Sentences, Greetings).
//
// Bakhed (rhymes/stories) categories are NOT stored here — they live as
// string fields directly on rhyme rows in the `rhymes` collection.
// See `RhymeModel.category` and `rhymeCategoriesProvider`.
//
// DO NOT add Bakhed-only categories to this collection. They will leak
// onto the Learn tab. The historical "Sohrai" leak was caused by this.
import 'package:http/http.dart' as http;
import '../../../../core/api/admin_content_client.dart';
import '../../../../core/api/edge_json_client.dart';
import '../../../../core/config/cloudflare_config.dart';
import '../../../../core/error/exceptions.dart';
import '../models/category_model.dart';

abstract class CategoryRemoteDataSource {
  Future<List<CategoryModel>> getCategories();
  Future<CategoryModel> getCategoryById(String id);
  Future<void> createCategory(CategoryModel category);
  Future<void> updateCategory(CategoryModel category);
  Future<void> deleteCategory(String id);
}

class CategoryRemoteDataSourceImpl implements CategoryRemoteDataSource {
  static const Duration _readTimeout = Duration(seconds: 6);

  final http.Client _client;
  final AdminContentClient _admin;

  /// Learner reads use the public Worker routes; admin writes use the
  /// Worker admin routes (`/api/v1/admin/content/categories`).
  CategoryRemoteDataSourceImpl({
    http.Client? httpClient,
    AdminContentClient? adminClient,
  }) : _client = httpClient ?? http.Client(),
       _admin = adminClient ?? AdminContentClient(httpClient ?? http.Client());

  @override
  Future<List<CategoryModel>> getCategories() async {
    try {
      final items = await EdgeJsonClient.getList(
        _client,
        Uri.parse(CloudflareConfig.categoriesEndpoint),
        'categories',
        timeout: _readTimeout,
      );
      return items
          .map((data) => CategoryModel.fromJson(data, '${data['id'] ?? ''}'))
          .toList();
    } on EdgeApiException catch (e) {
      throw ServerException(message: e.message, code: e.statusCode);
    } catch (e) {
      throw ServerException(message: e.toString());
    }
  }

  @override
  Future<CategoryModel> getCategoryById(String id) async {
    try {
      final body = await EdgeJsonClient.getJson(
        _client,
        Uri.parse(
          '${CloudflareConfig.categoriesEndpoint}/${Uri.encodeComponent(id)}',
        ),
        timeout: _readTimeout,
      );
      final category = body['category'];
      if (category is! Map) {
        throw const EdgeApiException('Missing category in response');
      }
      return CategoryModel.fromJson(Map<String, dynamic>.from(category), id);
    } on EdgeApiException catch (e) {
      throw ServerException(message: e.message, code: e.statusCode);
    } catch (e) {
      throw ServerException(message: e.toString());
    }
  }

  static Map<String, dynamic> _categoryDocument(CategoryModel category) =>
      category.toJson()
        ..remove('id')
        ..removeWhere((key, value) => value == null);

  Future<void> _write(Future<void> Function() write) async {
    try {
      await write();
    } on EdgeApiException catch (e) {
      throw ServerException(message: e.message, code: e.statusCode);
    } catch (e) {
      throw ServerException(message: e.toString());
    }
  }

  @override
  Future<void> createCategory(CategoryModel category) => _write(
    () => _admin.upsert('categories', category.id, _categoryDocument(category)),
  );

  @override
  Future<void> updateCategory(CategoryModel category) => _write(
    () => _admin.upsert('categories', category.id, _categoryDocument(category)),
  );

  @override
  Future<void> deleteCategory(String id) =>
      _write(() => _admin.delete('categories', id));
}
