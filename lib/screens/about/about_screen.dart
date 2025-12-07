import 'package:flutter/material.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ایپ کے بارے میں'),
        backgroundColor: Colors.deepPurple[700],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // App Logo and Info
            Card(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        color: Colors.deepPurple[100],
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Icon(
                        Icons.store,
                        size: 60,
                        color: Colors.deepPurple,
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'لیاقت کرایانہ اسٹور POS',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 5),
                    const Text(
                      'ورژن: 1.0.0',
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'ایک مکمل پوائنٹ آف سیل سسٹم چھوٹے اور درمیانے کاروباروں کے لیے',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Developer Info

            const SizedBox(height: 20),

            // Technical Details
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'تکنیکی معلومات',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 15),
                    _buildTechItem('فریم ورک', 'Flutter 3.0+'),
                    _buildTechItem('پلیٹ فارم', 'Windows Desktop'),
                    _buildTechItem('ڈیٹا بیس', 'SQLite with sqflite'),
                    _buildTechItem('اسٹیٹ مینجمنٹ', 'Provider'),
                    _buildTechItem('UI فریم ورک', 'Material Design 3'),
                    _buildTechItem('آخری اپ ڈیٹ', 'دسمبر 2024'),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Features List
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'ایپ کی خصوصیات',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),
                    _buildFeatureItem('مکمل POS سسٹم'),
                    _buildFeatureItem('اسٹاک مینجمنٹ'),
                    _buildFeatureItem('کسٹمر مینجمنٹ'),
                    _buildFeatureItem('5 قسم کی رپورٹس'),
                    _buildFeatureItem('ڈیٹا بیک اپ سسٹم'),
                    _buildFeatureItem('دونوں زبانیں (اردو/انگریزی)'),
                    _buildFeatureItem('پرنٹر سپورٹ'),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Links

            const SizedBox(height: 20),

            // Copyright
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                children: [
                  const Text(
                    '© 2024 لیاقت کرایانہ اسٹور',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 5),
                  const Text(
                    'تمام حقوق محفوظ ہیں۔',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'بنی: ${DateTime.now().year}-${DateTime.now().month.toString().padLeft(2, '0')}-${DateTime.now().day.toString().padLeft(2, '0')}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildTechItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          const Text(': '),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(color: Colors.grey),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureItem(String feature) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          const Icon(Icons.check_circle, color: Colors.green, size: 16),
          const SizedBox(width: 10),
          Expanded(child: Text(feature)),
        ],
      ),
    );
  }
}