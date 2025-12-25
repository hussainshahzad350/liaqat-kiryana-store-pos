import 'package:flutter/material.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Access theme colors
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    final TextTheme textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('ایپ کے بارے میں'),
        // backgroundColor will be handled by AppBarTheme in AppThemes
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
                        color: colorScheme.primaryContainer, // Themed background
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Icon( // Changed to non-const to allow dynamic color
                        Icons.store,
                        size: 60,
                        color: colorScheme.onPrimaryContainer, // Themed icon color
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text( // Changed to non-const to allow dynamic text style
                      'لیاقت کرایانہ اسٹور POS',
                      style: textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onSurface, // Themed text color
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text( // Changed to non-const
                      'ورژن: 1.0.0',
                      style: textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant, // Themed text color
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text( // Changed to non-const
                      'ایک مکمل پوائنٹ آف سیل سسٹم چھوٹے اور درمیانے کاروباروں کے لیے',
                      textAlign: TextAlign.center,
                      style: textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant, // Themed text color
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
                    Text( // Changed to non-const
                      'تکنیکی معلومات',
                      style: textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 15),
                    _buildTechItem(context, 'فریم ورک', 'Flutter 3.0+'), // Pass context
                    _buildTechItem(context, 'پلیٹ فارم', 'Windows Desktop'), // Pass context
                    _buildTechItem(context, 'ڈیٹا بیس', 'SQLite with sqflite'), // Pass context
                    _buildTechItem(context, 'اسٹیٹ مینجمنٹ', 'Provider'), // Pass context
                    _buildTechItem(context, 'UI فریم ورک', 'Material Design 3'), // Pass context
                    _buildTechItem(context, 'آخری اپ ڈیٹ', 'دسمبر 2024'), // Pass context
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
                    Text( // Changed to non-const
                      'ایپ کی خصوصیات',
                      style: textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 10),
                    _buildFeatureItem(context, 'مکمل POS سسٹم'), // Pass context
                    _buildFeatureItem(context, 'اسٹاک مینجمنٹ'), // Pass context
                    _buildFeatureItem(context, 'کسٹمر مینجمنٹ'), // Pass context
                    _buildFeatureItem(context, '5 قسم کی رپورٹس'), // Pass context
                    _buildFeatureItem(context, 'ڈیٹا بیک اپ سسٹم'), // Pass context
                    _buildFeatureItem(context, 'دونوں زبانیں (اردو/انگریزی)'), // Pass context
                    _buildFeatureItem(context, 'پرنٹر سپورٹ'), // Pass context
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
                color: colorScheme.surfaceVariant, // Themed background
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                children: [
                  Text( // Changed to non-const
                    '© 2024 لیاقت کرایانہ اسٹور',
                    style: textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text( // Changed to non-const
                    'تمام حقوق محفوظ ہیں۔',
                    style: textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text( // Changed to non-const
                    'بنی: ${DateTime.now().year}-${DateTime.now().month.toString().padLeft(2, '0')}-${DateTime.now().day.toString().padLeft(2, '0')}',
                    style: textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
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

  Widget _buildTechItem(BuildContext context, String label, String value) { // Added context
    final TextTheme textTheme = Theme.of(context).textTheme;
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
                color: colorScheme.onSurface,
              ),
            ),
          ),
          Text(
            ': ',
            style: textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurface,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureItem(BuildContext context, String feature) { // Added context
    final TextTheme textTheme = Theme.of(context).textTheme;
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(Icons.check_circle, color: colorScheme.primary, size: 16), // Use theme primary color
          const SizedBox(width: 10),
          Expanded(
              child: Text(
                feature,
                style: textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurface,
                ),
              )),
        ],
      ),
    );
  }
}