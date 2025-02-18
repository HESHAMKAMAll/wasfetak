// services/recipe_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;

class RecipeService {
  static const String apiKey = '526f9a64272b4077b65476bea4856d95';
  static const String baseUrl = 'https://api.spoonacular.com/recipes';

  // إضافة client للإستخدام المتكرر
  final http.Client _client;

  // Singleton pattern للتحكم في عدد النسخ من الكلاس
  static final RecipeService _instance = RecipeService._internal();

  factory RecipeService() {
    return _instance;
  }

  RecipeService._internal() : _client = http.Client();

  // التخلص من الـ client عند الانتهاء
  void dispose() {
    _client.close();
  }

  Future<List<Recipe>> getRecipesByIngredients(List<String> ingredients) async {
    if (ingredients.isEmpty) {
      throw Exception('يجب إدخال مكون واحد على الأقل');
    }

    final queryParams = {
      'apiKey': apiKey,
      'ingredients': ingredients.join(','),
      'number': '10',
      'ranking': '2', // تحسين الترتيب حسب عدد المكونات المتطابقة
      'ignorePantry': 'true' // تجاهل المكونات الأساسية
    };

    try {
      final uri = Uri.parse('$baseUrl/findByIngredients').replace(queryParameters: queryParams);
      final response = await _client.get(uri).timeout(
        const Duration(seconds: 10),
        onTimeout: () => throw Exception('انتهت مهلة الاتصال'),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        final recipes = data
            .map((json) => Recipe.fromJson(json))
            .where((recipe) => recipe.isValid())
            .toList();

        if (recipes.isEmpty) {
          throw Exception('لم يتم العثور على وصفات متطابقة');
        }

        return recipes;
      } else if (response.statusCode == 402) {
        throw Exception('تم تجاوز حد API المجاني');
      } else {
        throw Exception('فشل في تحميل الوصفات (${response.statusCode})');
      }
    } on FormatException {
      throw Exception('تنسيق البيانات المستلمة غير صحيح');
    } catch (e) {
      throw Exception('خطأ في الاتصال: $e');
    }
  }

  Future<RecipeDetails> getRecipeDetails(int recipeId) async {
    if (recipeId <= 0) {
      throw Exception('معرف الوصفة غير صالح');
    }

    final queryParams = {
      'apiKey': apiKey,
      'includeNutrition': 'true',
    };

    try {
      final uri = Uri.parse('$baseUrl/$recipeId/information').replace(queryParameters: queryParams);
      final response = await _client.get(uri).timeout(
        const Duration(seconds: 10),
        onTimeout: () => throw Exception('انتهت مهلة الاتصال'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return RecipeDetails.fromJson(data);
      } else if (response.statusCode == 404) {
        throw Exception('الوصفة غير موجودة');
      } else {
        throw Exception('فشل في تحميل تفاصيل الوصفة (${response.statusCode})');
      }
    } on FormatException {
      throw Exception('تنسيق البيانات المستلمة غير صحيح');
    } catch (e) {
      throw Exception('خطأ في الاتصال: $e');
    }
  }
}


// models/recipe.dart
class Recipe {
  final int id;
  final String title;
  final String imageUrl;
  final List<String> ingredients;
  final int readyInMinutes;
  final int servings;
  bool isFavorite;

  Recipe({
    required this.id,
    required this.title,
    required this.imageUrl,
    required this.ingredients,
    required this.readyInMinutes,
    required this.servings,
    this.isFavorite = false,
  });

  factory Recipe.fromJson(Map<String, dynamic> json) {
    return Recipe(
      id: json['id'] ?? 0,
      title: json['title'] ?? '',
      imageUrl: json['image'] ?? 'https://placeholder.com/food',
      ingredients: List<String>.from(
          (json['usedIngredients'] ?? []).map((i) => i['name'] ?? '') ?? []
      ),
      readyInMinutes: json['readyInMinutes'] ?? 0,
      servings: json['servings'] ?? 1,
    );
  }

  // إضافة طريقة للتحقق من صحة البيانات
  bool isValid() {
    return id != 0 && title.isNotEmpty && imageUrl.isNotEmpty;
  }
}

// models/recipe_details.dart
class RecipeDetails extends Recipe {
  final List<String> instructions;
  final Map<String, String> nutrition;
  final List<String> equipments;

  RecipeDetails({
    required int id,
    required String title,
    required String imageUrl,
    required List<String> ingredients,
    required int readyInMinutes,
    required int servings,
    required this.instructions,
    required this.nutrition,
    required this.equipments,
    bool isFavorite = false,
  }) : super(
    id: id,
    title: title,
    imageUrl: imageUrl,
    ingredients: ingredients,
    readyInMinutes: readyInMinutes,
    servings: servings,
    isFavorite: isFavorite,
  );

  factory RecipeDetails.fromJson(Map<String, dynamic> json) {
    // التحقق من وجود البيانات الأساسية وتوفير قيم افتراضية
    return RecipeDetails(
      id: json['id'] ?? 0,
      title: json['title'] ?? '',
      imageUrl: json['image'] ?? '',
      ingredients: _parseIngredients(json['extendedIngredients']),
      readyInMinutes: json['readyInMinutes'] ?? 0,
      servings: json['servings'] ?? 1,
      instructions: _parseInstructions(json['analyzedInstructions']),
      nutrition: _parseNutrition(json['nutrition']),
      equipments: _parseEquipments(json['analyzedInstructions']),
    );
  }

  static List<String> _parseIngredients(dynamic ingredients) {
    if (ingredients == null || ingredients is! List) return [];
    return List<String>.from(
        ingredients.map((i) => i['original'] ?? '').where((i) => i.isNotEmpty)
    );
  }

  static List<String> _parseInstructions(dynamic instructions) {
    if (instructions == null || instructions is! List || instructions.isEmpty) {
      return [];
    }
    try {
      return List<String>.from(
          instructions[0]['steps']?.map((step) => step['step'] ?? '') ?? []
      ).where((step) => step.isNotEmpty).toList();
    } catch (e) {
      return [];
    }
  }

  static Map<String, String> _parseNutrition(dynamic nutrition) {
    if (nutrition == null || nutrition['nutrients'] == null) {
      return {
        'سعرات حرارية': '0 كالوري',
        'بروتين': '0 غرام',
        'دهون': '0 غرام',
        'كربوهيدرات': '0 غرام',
      };
    }

    Map<String, String> result = {
      'سعرات حرارية': '0 كالوري',
      'بروتين': '0 غرام',
      'دهون': '0 غرام',
      'كربوهيدرات': '0 غرام',
    };

    // البحث في مصفوفة nutrients عن القيم المطلوبة
    for (var nutrient in nutrition['nutrients']) {
      switch (nutrient['name']) {
        case 'Calories':
          result['سعرات حرارية'] = '${nutrient['amount'].round()} كالوري';
          break;
        case 'Protein':
          result['بروتين'] = '${nutrient['amount'].round()} غرام';
          break;
        case 'Fat':
          result['دهون'] = '${nutrient['amount'].round()} غرام';
          break;
        case 'Carbohydrates':
          result['كربوهيدرات'] = '${nutrient['amount'].round()} غرام';
          break;
      }
    }

    return result;
  }

  static List<String> _parseEquipments(dynamic instructions) {
    if (instructions == null || instructions is! List || instructions.isEmpty) {
      return [];
    }
    try {
      Set<String> equipments = {};
      final steps = instructions[0]['steps'] ?? [];
      for (var step in steps) {
        final equipment = step['equipment'] ?? [];
        for (var item in equipment) {
          if (item['name'] != null && item['name'].toString().isNotEmpty) {
            equipments.add(item['name']);
          }
        }
      }
      return equipments.toList();
    } catch (e) {
      return [];
    }
  }
}