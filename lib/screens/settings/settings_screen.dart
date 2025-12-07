import 'package:flutter/material.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('سیٹنگز'),
        backgroundColor: Colors.teal[700],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: const [
            Tab(icon: Icon(Icons.store), text: 'شاپ پروفائل'),
            Tab(icon: Icon(Icons.backup), text: 'بیک اپ'),
            Tab(icon: Icon(Icons.receipt), text: 'رسید فارمیٹ'),
            Tab(icon: Icon(Icons.settings), text: 'ترجیحات'),
            Tab(icon: Icon(Icons.info), text: 'اينڈرول'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          ShopProfileTab(),
          BackupTab(),
          ReceiptTab(),
          PreferencesTab(),
          AboutTab(),
        ],
      ),
    );
  }
}

// ==================== Shop Profile Tab ====================
class ShopProfileTab extends StatelessWidget {
  const ShopProfileTab({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // Shop Logo
                  const CircleAvatar(
                    radius: 50,
                    backgroundColor: Colors.teal,
                    child: Icon(Icons.store, size: 50, color: Colors.white),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ElevatedButton.icon(
                        icon: const Icon(Icons.image),
                        label: const Text('لوگو تبدیل کریں'),
                        onPressed: () {},
                      ),
                      const SizedBox(width: 10),
                      OutlinedButton(
                        onPressed: () {},
                        child: const Text('ہٹائیں'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 20),

          // Shop Details Form
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'دکان کی تفصیلات',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    decoration: const InputDecoration(
                      labelText: 'دکان کا نام (اردو)',
                      border: OutlineInputBorder(),
                      hintText: 'لياقت کريانہ اسٹور',
                    ),
                    initialValue: 'لياقت کريانہ اسٹور',
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    decoration: const InputDecoration(
                      labelText: 'Shop Name (English)',
                      border: OutlineInputBorder(),
                      hintText: 'Liaqat Kiryana Store',
                    ),
                    initialValue: 'Liaqat Kiryana Store',
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    decoration: const InputDecoration(
                      labelText: 'پتہ',
                      border: OutlineInputBorder(),
                      hintText: 'شاپ نمبر 12، مین بازار، لاہور',
                    ),
                    maxLines: 2,
                    initialValue: 'شاپ نمبر 12، مین بازار، لاہور',
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    decoration: const InputDecoration(
                      labelText: 'پرائمری فون *',
                      border: OutlineInputBorder(),
                      hintText: '0300-1234567',
                    ),
                    initialValue: '0300-1234567',
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    decoration: const InputDecoration(
                      labelText: 'سیکنڈری فون',
                      border: OutlineInputBorder(),
                      hintText: '042-1234567',
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {},
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: Colors.teal[700],
                      ),
                      child: const Text('تبدیلیاں محفوظ کریں'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ==================== Backup Tab ====================
class BackupTab extends StatelessWidget {
  const BackupTab({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Current Database Info
          const Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'موجوده ڈیٹا بیس',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 10),
                  ListTile(
                    leading: Icon(Icons.storage, color: Colors.teal),
                    title: Text('liaqat_store.db'),
                    subtitle: Text('سائز: 45.2 MB'),
                  ),
                  ListTile(
                    leading: Icon(Icons.history, color: Colors.teal),
                    title: Text('آخری بیک اپ'),
                    subtitle: Text('29 نومبر 2025, 10:30 PM'),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 20),

          // Backup Actions
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'بیک اپ کے اختیارات',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.backup),
                      label: const Text('ابھی بیک اپ بنائیں'),
                      onPressed: () {},
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: Colors.teal[700],
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.usb),
                      label: const Text('USB پر ایکسپورٹ کریں'),
                      onPressed: () {},
                    ),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.download),
                      label: const Text('USB سے امپورٹ کریں'),
                      onPressed: () {},
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 20),

          // Recent Backups
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'حالیہ بیک اپس',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  const BackupItem(
                    fileName: 'liaqat_store_20251129_2230.db',
                    date: '29 نومبر 2025',
                    size: '45 MB',
                  ),
                  const BackupItem(
                    fileName: 'liaqat_store_20251128_2200.db',
                    date: '28 نومبر 2025',
                    size: '44 MB',
                  ),
                  const BackupItem(
                    fileName: 'liaqat_store_20251127_2200.db',
                    date: '27 نومبر 2025',
                    size: '43 MB',
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      OutlinedButton(
                        onPressed: () {},
                        child: const Text('فولڈر کھولیں'),
                      ),
                      const Spacer(),
                      ElevatedButton(
                        onPressed: () {},
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                        child: const Text('بحال کریں'),
                      ),
                      const SizedBox(width: 10),
                      ElevatedButton(
                        onPressed: () {},
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                        child: const Text('حذف کریں'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ==================== Receipt Format Tab ====================
class ReceiptTab extends StatelessWidget {
  const ReceiptTab({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Receipt Options
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'رسید کے اختیارات',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  const OptionSwitch(title: 'لوگو دکھائیں'),
                  const OptionSwitch(title: 'دکان کا پتہ دکھائیں'),
                  const OptionSwitch(title: 'فون نمبر دکھائیں'),
                  const OptionSwitch(title: 'تاریخ اور وقت دکھائیں'),
                  const OptionSwitch(title: 'کسٹمر کی تفصیل دکھائیں'),
                  const OptionSwitch(title: 'پیمنٹ کی تفصیل دکھائیں'),
                  const SizedBox(height: 10),
                  const Divider(),
                  const SizedBox(height: 10),
                  const Text('فونٹ سائز'),
                  DropdownButton(
                    value: 'درمیانہ',
                    items: const ['چھوٹا', 'درمیانہ', 'بڑا']
                        .map((size) => DropdownMenuItem(value: size, child: Text(size)))
                        .toList(),
                    onChanged: (value) {},
                  ),
                  const SizedBox(height: 10),
                  const Text('کاغذ کی چوڑائی'),
                  DropdownButton(
                    value: '58mm',
                    items: const ['58mm', '80mm', 'A4']
                        .map((width) => DropdownMenuItem(value: width, child: Text(width)))
                        .toList(),
                    onChanged: (value) {},
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 20),

          // Printer Configuration
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'پرنٹر سیٹنگز',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  const Text('پرنٹر کا انتخاب'),
                  DropdownButton(
                    value: 'USB تھرمل پرنٹر',
                    items: const [
                      'ڈیفالٹ پرنٹر',
                      'USB تھرمل پرنٹر',
                      'نیٹ ورک پرنٹر',
                      'PDF پرنٹر'
                    ].map((printer) => DropdownMenuItem(value: printer, child: Text(printer))).toList(),
                    onChanged: (value) {},
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.print),
                      label: const Text('ٹیسٹ رسید پرنٹ کریں'),
                      onPressed: () {},
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 20),

          // Receipt Preview
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'رسید کا پیش نظارہ',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Column(
                      children: [
                        Text('لياقت کريانہ اسٹور', style: TextStyle(fontWeight: FontWeight.bold)),
                        Text('LIAQAT KIRYANA STORE', style: TextStyle(fontSize: 12)),
                        SizedBox(height: 10),
                        Text('فون: 0300-1234567'),
                        Text('پتہ: مین بازار، لاہور'),
                        Divider(),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('بل نمبر: #2451'),
                            Text('تاریخ: 30 نومبر 2025'),
                          ],
                        ),
                        Divider(),
                        Text('آئٹم  مقدار  قیمت  کل'),
                        Divider(),
                        Text('چاول 2KG 180 360'),
                        Text('دال 1KG 200 200'),
                        Divider(),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('کل:'),
                            Text('Rs 560'),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ==================== Preferences Tab ====================
class PreferencesTab extends StatelessWidget {
  const PreferencesTab({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Language & Region
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'زبان اور علاقہ',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  const Text('ایپ کی زبان'),
                  DropdownButton(
                    value: 'اردو / English',
                    items: const ['اردو', 'English', 'اردو / English']
                        .map((lang) => DropdownMenuItem(value: lang, child: Text(lang)))
                        .toList(),
                    onChanged: (value) {},
                  ),
                  const SizedBox(height: 10),
                  const Text('تاریخ کا فارمیٹ'),
                  DropdownButton(
                    value: 'DD-MM-YYYY',
                    items: const ['DD-MM-YYYY', 'MM-DD-YYYY', 'YYYY-MM-DD']
                        .map((format) => DropdownMenuItem(value: format, child: Text(format)))
                        .toList(),
                    onChanged: (value) {},
                  ),
                  const SizedBox(height: 10),
                  const Text('کرنسی کا نشان'),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          decoration: const InputDecoration(hintText: 'Rs'),
                          initialValue: 'Rs',
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: DropdownButton(
                          value: 'پہلے',
                          items: const [
                            DropdownMenuItem(value: 'پہلے', child: Text('پہلے')),
                            DropdownMenuItem(value: 'بعد میں', child: Text('بعد میں')),
                          ],
                          onChanged: null,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 20),

          // Security
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'سیکورٹی',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  const OptionSwitch(title: 'شروع میں پاسورڈ ضروری ہے'),
                  const SizedBox(height: 10),
                  TextFormField(
                    decoration: const InputDecoration(
                      labelText: 'پاسورڈ',
                      suffixIcon: Icon(Icons.visibility_off),
                    ),
                    obscureText: true,
                  ),
                  const SizedBox(height: 10),
                  const OptionSwitch(title: '5 منٹ کی غیر فعالیت کے بعد لاک کریں'),
                ],
              ),
            ),
          ),

          const SizedBox(height: 20),

          // Auto Backup
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'آٹو بیک اپ',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  const OptionSwitch(title: 'آٹو بیک اپ فعال کریں'),
                  const SizedBox(height: 10),
                  const Text('فریکوئنسی'),
                  DropdownButton(
                    value: 'روزانہ',
                    items: const ['روزانہ', 'ہفتہ وار', 'ماہانہ']
                        .map((freq) => DropdownMenuItem(value: freq, child: Text(freq)))
                        .toList(),
                    onChanged: (value) {},
                  ),
                  const SizedBox(height: 10),
                  const Text('وقت'),
                  DropdownButton(
                    value: '10:00 PM',
                    items: const ['10:00 PM', '11:00 PM', '12:00 AM']
                        .map((time) => DropdownMenuItem(value: time, child: Text(time)))
                        .toList(),
                    onChanged: (value) {},
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 20),

          // Notifications
          const Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'اطلاعات',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 10),
                  OptionSwitch(title: 'کم اسٹاک الرٹ'),
                  OptionSwitch(title: 'دن بند کرنے کی یاددہانی'),
                  OptionSwitch(title: 'بیک اپ کامیابی کی اطلاع'),
                  OptionSwitch(title: 'اپ ڈیٹ دستیاب کی اطلاع'),
                  OptionSwitch(title: 'آواز کے اثرات'),
                  OptionSwitch(title: 'پاپ اپ اطلاعات'),
                ],
              ),
            ),
          ),

          const SizedBox(height: 20),

          // Save Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {},
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: Colors.teal[700],
              ),
              child: const Text('ترجیحات محفوظ کریں'),
            ),
          ),
        ],
      ),
    );
  }
}

// ==================== About Tab ====================
class AboutTab extends StatelessWidget {
  const AboutTab({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // App Info
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  const Icon(
                    Icons.store,
                    size: 80,
                    color: Colors.teal,
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'لياقت کريانہ اسٹور POS',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 5),
                  const Text(
                    'ورژن: 1.0.0 (بِلڈ 2025.11.30)',
                    style: TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () {},
                    child: const Text('اپ ڈیٹس چیک کریں'),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'توسیع کی گئی: آپ کی ڈیولپمنٹ ٹیم',
                    style: TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 20),

          // System Information
          const Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'سسٹم کی معلومات',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 10),
                  InfoItem(label: 'ڈیٹا بیس ورژن', value: '1.0'),
                  InfoItem(label: 'کل آئٹمز', value: '145'),
                  InfoItem(label: 'کل کسٹمرز', value: '45'),
                  InfoItem(label: 'کل سپلائرز', value: '12'),
                  InfoItem(label: 'کل فروخت', value: 'Rs 5,45,000'),
                  InfoItem(label: 'ایپ اپ ٹائم', value: '15 دن، 2 گھنٹے'),
                  InfoItem(label: 'آخری لاگ ان', value: 'آج، 08:00 AM'),
                ],
              ),
            ),
          ),

          const SizedBox(height: 20),

          // Maintenance
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'دیکھ بھال',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: () {},
                      child: const Text('ڈیٹا بیس مرمت کریں'),
                    ),
                  ),
                  const SizedBox(height: 5),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: () {},
                      child: const Text('پرانا ڈیٹا محفوظ کریں'),
                    ),
                  ),
                  const SizedBox(height: 5),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: () {},
                      child: const Text('کیش صاف کریں'),
                    ),
                  ),
                  const SizedBox(height: 5),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: () {},
                      child: const Text('لاگز دیکھیں'),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 20),

          // Support
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'سپورٹ',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  const ListTile(
                    leading: Icon(Icons.email),
                    title: Text('ای میل'),
                    subtitle: Text('support@liaqatkiryanastore.com'),
                  ),
                  const ListTile(
                    leading: Icon(Icons.phone),
                    title: Text('فون'),
                    subtitle: Text('0300-1234567 (ایکسٹنشن 2)'),
                  ),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: () {},
                      child: const Text('آن لائن گائیڈ دیکھیں'),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 20),

          // Copyright
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.grey[50],
            child: const Center(
              child: Text(
                '© 2025 لياقت کريانہ اسٹور۔ تمام حقوق محفوظ ہیں۔',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ==================== Helper Widgets ====================

class BackupItem extends StatelessWidget {
  final String fileName;
  final String date;
  final String size;

  const BackupItem({
    super.key,
    required this.fileName,
    required this.date,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            const Icon(Icons.insert_drive_file, color: Colors.teal),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    fileName,
                    style: const TextStyle(fontSize: 14),
                  ),
                  Text(
                    date,
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
            ),
            Text(size),
          ],
        ),
      ),
    );
  }
}

class OptionSwitch extends StatelessWidget {
  final String title;

  const OptionSwitch({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: Text(title)),
        Switch(value: true, onChanged: (value) {}),
      ],
    );
  }
}

class InfoItem extends StatelessWidget {
  final String label;
  final String value;

  const InfoItem({super.key, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(child: Text(label)),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}