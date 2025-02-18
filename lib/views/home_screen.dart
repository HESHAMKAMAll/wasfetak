
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:google_ml_kit/google_ml_kit.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:image_picker/image_picker.dart';

import 'suggested_recipes_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  File? _image;
  final picker = ImagePicker();
  String recognizedText = '';
  bool isProcessing = false;
  BannerAd? _bannerAd;

  // إضافة متغيرات جديدة للمكونات النصية
  final List<String> _ingredients = [];
  final TextEditingController _ingredientController = TextEditingController();
  bool _isTextMode = false; // للتبديل بين وضع الصورة والنص

  // تعريف الألوان الأساسية
  final primaryColor = const Color(0xFF6750A4);
  final secondaryColor = const Color(0xFF625B71);
  final surfaceColor = const Color(0xFFFFFBFE);
  final backgroundColor = const Color(0xFFF6F5F7);
  @override
  void initState() {
    _loadAd();
    super.initState();
  }


  @override
  void dispose() {
    _ingredientController.dispose();
    super.dispose();
  }

  Future<void> _getImage(ImageSource source) async {
    try {
      final pickedFile = await picker.pickImage(source: source);

      if (pickedFile != null) {
        setState(() {
          _image = File(pickedFile.path);
          isProcessing = true;
        });

        await _processImage();
      }
    } catch (e) {
      _showError('خطأ في التقاط الصورة: $e');
    }
  }

  Future<void> _processImage() async {
    if (_image == null) return;

    final inputImage = InputImage.fromFile(_image!);
    final textDetector = GoogleMlKit.vision.textDetector();

    try {
      final recognizedText = await textDetector.processImage(inputImage);
      setState(() {
        this.recognizedText = recognizedText.text;
        isProcessing = false;
      });

      List<String> ingredients = recognizedText.text.split('\n');
      _navigateToRecipes(ingredients);
    } catch (e) {
      _showError('خطأ في معالجة الصورة: $e');
      setState(() {
        isProcessing = false;
      });
    }
  }

  void _addIngredient() {
    if (_ingredientController.text.isNotEmpty) {
      setState(() {
        _ingredients.add(_ingredientController.text);
        _ingredientController.clear();
      });
    }
  }

  void _removeIngredient(int index) {
    setState(() {
      _ingredients.removeAt(index);
    });
  }

  void _navigateToRecipes(List<String> ingredients) {
    if (ingredients.isNotEmpty) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => SuggestedRecipesPage(ingredients: ingredients),
        ),
      );
    } else {
      _showError('الرجاء إضافة مكون واحد على الأقل');
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  void _loadAd() {
    final bannerAd = BannerAd(
      size: AdSize.largeBanner,
      // adUnitId: "ca-app-pub-3940256099942544/9214589741", // test
      adUnitId: "ca-app-pub-",
      request: const AdRequest(),
      listener: BannerAdListener(
        // Called when an ad is successfully received.
        onAdLoaded: (ad) {
          if (!mounted) {
            ad.dispose();
            return;
          }
          setState(() {
            _bannerAd = ad as BannerAd;
          });
        },
        // Called when an ad request failed.
        onAdFailedToLoad: (ad, error) {
          debugPrint('BannerAd failed to load: $error');
          ad.dispose();
        },
      ),
    );

    // Start loading.
    bannerAd.load();
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
                _isTextMode ? Icons.camera_alt : Icons.edit,
                color: primaryColor,
              ),
              onPressed: () {
                setState(() {
                  _isTextMode = !_isTextMode;
                  _image = null;
                  recognizedText = '';
                  _ingredients.clear();
                  _ingredientController.clear();
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
                  _isTextMode ? 'إدخال المكونات يدوياً' : 'التقاط صورة للمكونات',
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

                  if (!_isTextMode) ...[
                    if(_image == null)
                      Center(child: _bannerAd == null
                      // Nothing to render yet.
                          ? const SizedBox()
                      // The actual ad.
                          : SizedBox(height: 90,child: AdWidget(ad: _bannerAd!))),
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
                                controller: _ingredientController,
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
                              onPressed: _addIngredient,
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
                    if (_ingredients.isNotEmpty) ...[
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
                        itemCount: _ingredients.length,
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
                                  _ingredients[index],
                                  style: const TextStyle(fontSize: 16),
                                  textDirection: TextDirection.rtl,
                                ),
                                trailing: IconButton(
                                  icon: const Icon(Icons.delete),
                                  color: Colors.red[400],
                                  onPressed: () => _removeIngredient(index),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton.icon(
                        onPressed: () => _navigateToRecipes(_ingredients),
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
      bottomNavigationBar: !_isTextMode
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
                  onPressed: () => _getImage(ImageSource.camera),
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
                  onPressed: () => _getImage(ImageSource.gallery),
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