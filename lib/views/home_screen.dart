
import 'dart:io';
import 'package:flutter/material.dart';
// import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:image_picker/image_picker.dart';

import 'suggested_recipes_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {




  // متغيرات الحالة
  File? _image;
  String recognizedText = '';
  bool isProcessing = false;
  bool isTextMode = false;
  BannerAd? bannerAd;

  // متغيرات المكونات
  final List<String> ingredients = [];
  final TextEditingController ingredientController = TextEditingController();

  // الأدوات المساعدة
  final picker = ImagePicker();
  final textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);

  // الألوان
  final primaryColor = const Color(0xFF6750A4);
  final secondaryColor = const Color(0xFF625B71);
  final surfaceColor = const Color(0xFFFFFBFE);
  final backgroundColor = const Color(0xFFF6F5F7);

  @override
  void initState() {
    super.initState();
    _loadAd();
  }

  @override
  void dispose() {
    ingredientController.dispose();
    textRecognizer.close();
    bannerAd?.dispose();
    super.dispose();
  }

  // تحميل الإعلان
  void _loadAd() {
    bannerAd = BannerAd(
      size: AdSize.banner,
      adUnitId: 'YOUR_AD_UNIT_ID', // استبدل بمعرف الإعلان الخاص بك
      listener: BannerAdListener(
        onAdLoaded: (ad) => setState(() {}),
        onAdFailedToLoad: (ad, error) {
          ad.dispose();
          print('Ad load failed: $error');
        },
      ),
      request: AdRequest(),
    )..load();
  }

  // التقاط الصورة
  Future<void> getImage(ImageSource source) async {
    try {
      final XFile? pickedFile = await picker.pickImage(
        source: source,
        maxWidth: 1800,
        maxHeight: 1800,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        setState(() {
          _image = File(pickedFile.path);
          isProcessing = true;
        });

        await processImage();
      }
    } catch (e) {
      showError('خطأ في التقاط الصورة: $e');
    }
  }

  // معالجة الصورة
  Future<void> processImage() async {
    if (_image == null) return;

    try {
      final inputImage = InputImage.fromFile(_image!);
      final RecognizedText recognizedText = await textRecognizer.processImage(inputImage);

      setState(() {
        this.recognizedText = recognizedText.text;
        isProcessing = false;
      });

      // تحويل النص المتعرف عليه إلى مكونات
      final List<String> newIngredients = recognizedText.text
          .split('\n')
          .where((line) => line.trim().isNotEmpty)
          .toList();

      if (newIngredients.isNotEmpty) {
        setState(() {
          ingredients.addAll(newIngredients);
        });
      }

    } catch (e) {
      showError('خطأ في معالجة الصورة: $e');
    } finally {
      setState(() {
        isProcessing = false;
      });
    }
  }

  // إضافة مكون يدوياً
  void addIngredient() {
    final ingredient = ingredientController.text.trim();
    if (ingredient.isNotEmpty) {
      setState(() {
        ingredients.add(ingredient);
        ingredientController.clear();
      });
    }
  }

  // إزالة مكون
  void removeIngredient(int index) {
    if (index >= 0 && index < ingredients.length) {
      setState(() {
        ingredients.removeAt(index);
      });
    }
  }

  // الانتقال إلى صفحة الوصفات
  void navigateToRecipes(List<String> ingredients) {
    if (ingredients.isNotEmpty) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => SuggestedRecipesPage(ingredients: ingredients),
        ),
      );
    } else {
      showError('الرجاء إضافة مكون واحد على الأقل');
    }
  }

  // عرض رسالة خطأ
  void showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        margin: EdgeInsets.all(16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  // عرض مربع حوار اختيار مصدر الصورة
  void showImageSourceDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('اختر مصدر الصورة'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(Icons.camera_alt),
              title: Text('الكاميرا'),
              onTap: () {
                Navigator.pop(context);
                getImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: Icon(Icons.photo_library),
              title: Text('معرض الصور'),
              onTap: () {
                Navigator.pop(context);
                getImage(ImageSource.gallery);
              },
            ),
          ],
        ),
      ),
    );
  }

  // تبديل وضع الإدخال
  void toggleInputMode() {
    setState(() {
      isTextMode = !isTextMode;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: surfaceColor,
        title: Text(
          'Scan & Cook',
          style: TextStyle(
            color: primaryColor,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: IconButton(
              icon: Icon(
                isTextMode ? Icons.camera_alt : Icons.edit,
                color: primaryColor,
              ),
              onPressed: () {
                setState(() {
                  isTextMode = !isTextMode;
                  _image = null;
                  recognizedText = '';
                  ingredients.clear();
                  ingredientController.clear();
                });
              },
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // // شريط علوي منحني
            // _bannerAd == null
            // // Nothing to render yet.
            //     ? const SizedBox()
            // // The actual ad.
            //     : SizedBox(height: 55,child: AdWidget(ad: _bannerAd!)),
            Container(
              height: 100,
              decoration: BoxDecoration(
                color: surfaceColor,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(32),
                  bottomRight: Radius.circular(32),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  isTextMode ? 'إدخال المكونات يدوياً' : 'التقاط صورة للمكونات',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: primaryColor,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [

                  if (!isTextMode) ...[
                    if(_image == null)
                      Center(child: bannerAd == null
                      // Nothing to render yet.
                          ? const SizedBox()
                      // The actual ad.
                          : SizedBox(height: 90,child: AdWidget(ad: bannerAd!))),
                    if (_image != null) ...[
                      Card(
                        elevation: 4,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: Image.file(
                            _image!,
                            height: 300,
                            width: double.infinity,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],
                    if (isProcessing)
                      Center(
                        child: CircularProgressIndicator(
                          color: primaryColor,
                        ),
                      )
                    else if (recognizedText.isNotEmpty)
                      Card(
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'المكونات المكتشفة:',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: primaryColor,
                                ),
                                textAlign: TextAlign.right,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                recognizedText,
                                style: const TextStyle(
                                  fontSize: 16,
                                  height: 1.5,
                                ),
                                textAlign: TextAlign.right,
                                textDirection: TextDirection.rtl,
                              ),
                            ],
                          ),
                        ),
                      ),
                  ] else ...[
                    Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: ingredientController,
                                decoration: InputDecoration(
                                  hintText: 'أدخل المكون',
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(color: primaryColor),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(color: primaryColor, width: 2),
                                  ),
                                  filled: true,
                                  fillColor: surfaceColor,
                                ),
                                textDirection: TextDirection.rtl,
                              ),
                            ),
                            const SizedBox(width: 12),
                            ElevatedButton(
                              onPressed: addIngredient,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: primaryColor,
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: const Text(
                                'إضافة',
                                style: TextStyle(fontSize: 16,color: Colors.white),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (ingredients.isNotEmpty) ...[
                      const SizedBox(height: 24),
                      Text(
                        'المكونات المضافة:',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: primaryColor,
                        ),
                        textAlign: TextAlign.right,
                      ),
                      const SizedBox(height: 12),
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: ingredients.length,
                        itemBuilder: (context, index) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 8.0),
                            child: Card(
                              elevation: 2,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: ListTile(
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 8,
                                ),
                                title: Text(
                                  ingredients[index],
                                  style: const TextStyle(fontSize: 16),
                                  textDirection: TextDirection.rtl,
                                ),
                                trailing: IconButton(
                                  icon: const Icon(Icons.delete),
                                  color: Colors.red[400],
                                  onPressed: () => removeIngredient(index),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton.icon(
                        onPressed: () => navigateToRecipes(ingredients),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryColor,
                          padding: const EdgeInsets.symmetric(
                            vertical: 16,
                            horizontal: 24,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        icon: const Icon(Icons.search, size: 24,color: Colors.white),
                        label: const Text(
                          'البحث عن الوصفات',
                          style: TextStyle(fontSize: 18,color: Colors.white),
                        ),
                      ),
                    ],
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: !isTextMode
          ? Container(
        decoration: BoxDecoration(
          color: surfaceColor,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => getImage(ImageSource.camera),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: const Icon(Icons.camera_alt,color: Colors.white),
                  label: const Text(
                    'التقاط صورة',
                    style: TextStyle(fontSize: 16,color: Colors.white),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => getImage(ImageSource.gallery),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: secondaryColor,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: const Icon(Icons.photo_library,color: Colors.white),
                  label: const Text(
                    'اختيار من المعرض',
                    style: TextStyle(fontSize: 16,color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        ),
      )
          : null,
    );
  }
}