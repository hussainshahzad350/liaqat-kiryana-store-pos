// lib/screens/settings/settings_screen.dart

import 'package:flutter/material.dart';
import '../../l10n/app_localizations.dart';
import '../../main.dart';
import '../../core/database/database_helper.dart';

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
    final loc = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(loc.settings), 
        backgroundColor: Colors.teal[700],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: [
            Tab(icon: const Icon(Icons.store), text: loc.shopProfile),
            Tab(icon: const Icon(Icons.backup), text: loc.backup),
            Tab(icon: const Icon(Icons.receipt), text: loc.receiptFormat),
            Tab(icon: const Icon(Icons.settings), text: loc.preferences),
            Tab(icon: const Icon(Icons.info), text: loc.about),
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

// ==================== 1. Shop Profile Tab ====================
class ShopProfileTab extends StatelessWidget {
  const ShopProfileTab({super.key});

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
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
                        label: Text(loc.changeLogo),
                        onPressed: () {},
                      ),
                      const SizedBox(width: 10),
                      OutlinedButton(
                        onPressed: () {},
                        child: Text(loc.remove),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    loc.shopDetails,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    decoration: InputDecoration(
                      labelText: loc.shopNameUrdu,
                      border: const OutlineInputBorder(),
                      hintText: 'لياقت کريانہ اسٹور',
                    ),
                    initialValue: 'لياقت کريانہ اسٹور',
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    decoration: InputDecoration(
                      labelText: loc.shopNameEnglish,
                      border: const OutlineInputBorder(),
                      hintText: 'Liaqat Kiryana Store',
                    ),
                    initialValue: loc.shopNamePlaceholder, // Localized
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    decoration: InputDecoration(
                      labelText: loc.address,
                      border: const OutlineInputBorder(),
                      hintText: loc.addressPlaceholder, // Localized
                    ),
                    maxLines: 2,
                    initialValue: loc.addressPlaceholder,
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    decoration: InputDecoration(
                      labelText: '${loc.primaryPhone} *',
                      border: const OutlineInputBorder(),
                      hintText: '0300-1234567',
                    ),
                    initialValue: '0300-1234567',
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    decoration: InputDecoration(
                      labelText: loc.secondaryPhone,
                      border: const OutlineInputBorder(),
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
                      child: Text(loc.saveChanges, style: const TextStyle(color: Colors.white)),
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

// ==================== 2. Backup Tab ====================
class BackupTab extends StatelessWidget {
  const BackupTab({super.key});

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final now = DateTime.now();
    final dateStr = "${now.day}-${now.month}-${now.year}";

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    loc.currentDatabase,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  ListTile(
                    leading: const Icon(Icons.storage, color: Colors.teal),
                    title: const Text('liaqat_store.db'),
                    subtitle: Text('${loc.size}: 45.2 MB'),
                  ),
                  ListTile(
                    leading: const Icon(Icons.history, color: Colors.teal),
                    title: Text(loc.lastBackup),
                    subtitle: Text('$dateStr, 10:30 PM'),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    loc.backupOptions,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.backup),
                      label: Text(loc.createBackupNow, style: const TextStyle(color: Colors.white)),
                      onPressed: () async {
                        // FIX: Connect to DatabaseHelper backup
                        final db = await DatabaseHelper.instance.database;
                        // We can pass version 1 or current version
                        // Note: You might need to move _backupDatabase to public in DatabaseHelper 
                        // Change '_backupDatabase' to 'backupDatabase' in database_helper.dart first!
  
                        // Assuming you made it public:
                        await DatabaseHelper.instance.backupDatabase(db, 3);
                        if (!context.mounted) return; 
  
                        // OR for now, just trigger a simple file copy if you didn't expose the method:
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Backup created successfully!'))
                        );
                      },
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
                      label: Text(loc.exportToUsb),
                      onPressed: () {},
                    ),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.download),
                      label: Text(loc.importFromUsb),
                      onPressed: () {},
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    loc.recentBackups,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  BackupItem(fileName: 'store_$dateStr.db', date: dateStr, size: '45 MB'),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      OutlinedButton(onPressed: () {}, child: Text(loc.openFolder)),
                      const Spacer(),
                      ElevatedButton(
                        onPressed: () {},
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                        child: Text(loc.restore, style: const TextStyle(color: Colors.white)),
                      ),
                      const SizedBox(width: 10),
                      ElevatedButton(
                        onPressed: () {},
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                        child: Text(loc.delete, style: const TextStyle(color: Colors.white)),
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

// ==================== 3. Receipt Tab ====================
class ReceiptTab extends StatelessWidget {
  const ReceiptTab({super.key});

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    loc.receiptOptions,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  OptionSwitch(title: loc.showLogo),
                  OptionSwitch(title: loc.showShopAddress),
                  OptionSwitch(title: loc.showPhone),
                  OptionSwitch(title: loc.showDateTime),
                  OptionSwitch(title: loc.showCustomerDetails),
                  OptionSwitch(title: loc.showPaymentDetails),
                  const SizedBox(height: 10),
                  const Divider(),
                  const SizedBox(height: 10),
                  Text(loc.fontSize),
                  // Fix: Localized Dropdown Display
                  DropdownButton<String>(
                    value: 'Medium',
                    isExpanded: true,
                    items: [
                      DropdownMenuItem(value: 'Small', child: Text(loc.small)),
                      DropdownMenuItem(value: 'Medium', child: Text(loc.medium)),
                      DropdownMenuItem(value: 'Large', child: Text(loc.large)),
                    ],
                    onChanged: (value) {},
                  ),
                  const SizedBox(height: 10),
                  Text(loc.paperWidth),
                  DropdownButton<String>(
                    value: '58mm',
                    isExpanded: true,
                    items: [
                      DropdownMenuItem(value: '58mm', child: Text(loc.paper58)),
                      DropdownMenuItem(value: '80mm', child: Text(loc.paper80)),
                      DropdownMenuItem(value: 'A4', child: Text(loc.paperA4)),
                    ],
                    onChanged: (value) {},
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    loc.printerSettings,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  Text(loc.selectPrinter),
                  DropdownButton<String>(
                    value: 'USB Thermal',
                    isExpanded: true,
                    items: [
                      DropdownMenuItem(value: 'Default', child: Text(loc.printerDefault)),
                      DropdownMenuItem(value: 'USB Thermal', child: Text(loc.printerUsb)),
                      DropdownMenuItem(value: 'Network', child: Text(loc.printerNetwork)),
                      DropdownMenuItem(value: 'PDF', child: Text(loc.printerPdf)),
                    ],
                    onChanged: (value) {},
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.print),
                      label: Text(loc.printTestReceipt),
                      onPressed: () {},
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

// ==================== 4. Preferences Tab ====================
class PreferencesTab extends StatelessWidget {
  const PreferencesTab({super.key});

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    
    final String currentLangCode = Localizations.localeOf(context).languageCode;
    String dropdownValue = currentLangCode == 'ur' ? 'اردو' : 'English';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Language
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    loc.languageAndRegion,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  Text(loc.appLanguage),
                  DropdownButton<String>(
                    value: dropdownValue,
                    isExpanded: true,
                    items: const ['اردو', 'English']
                        .map((lang) => DropdownMenuItem(value: lang, child: Text(lang)))
                        .toList(),
                    onChanged: (String? newValue) {
                      if (newValue == 'English') {
                        LiaqatStoreApp.setLocale(context, const Locale('en', ''));
                      } else {
                        LiaqatStoreApp.setLocale(context, const Locale('ur', ''));
                      }
                    },
                  ),
                  const SizedBox(height: 10),
                  Text(loc.dateFormat),
                  DropdownButton(
                    value: 'DD-MM-YYYY',
                    isExpanded: true,
                    items: const ['DD-MM-YYYY', 'MM-DD-YYYY', 'YYYY-MM-DD']
                        .map((format) => DropdownMenuItem(value: format, child: Text(format)))
                        .toList(),
                    onChanged: (value) {},
                  ),
                  const SizedBox(height: 10),
                  Text(loc.currencySymbol),
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
                          value: loc.before,
                          items: [
                             DropdownMenuItem(value: loc.before, child: Text(loc.before)),
                             DropdownMenuItem(value: loc.after, child: Text(loc.after)),
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
                  Text(
                    loc.security,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  OptionSwitch(title: loc.requirePasswordStartup),
                  const SizedBox(height: 10),
                  TextFormField(
                    decoration: InputDecoration(
                      labelText: loc.password,
                      suffixIcon: const Icon(Icons.visibility_off),
                    ),
                    obscureText: true,
                  ),
                  const SizedBox(height: 10),
                  OptionSwitch(title: loc.lockAfter5Min),
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
                  Text(
                    loc.autoBackup,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  OptionSwitch(title: loc.enableAutoBackup),
                  const SizedBox(height: 10),
                  Text(loc.frequency),
                  // Fix: Localized Dropdown
                  DropdownButton<String>(
                    value: 'Daily',
                    isExpanded: true,
                    items: [
                      DropdownMenuItem(value: 'Daily', child: Text(loc.daily)),
                      DropdownMenuItem(value: 'Weekly', child: Text(loc.weekly)),
                      DropdownMenuItem(value: 'Monthly', child: Text(loc.monthly)),
                    ],
                    onChanged: (value) {},
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          // Notifications
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    loc.notifications,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  OptionSwitch(title: loc.lowStockAlert),
                  OptionSwitch(title: loc.dayCloseReminder),
                  OptionSwitch(title: loc.backupSuccessNotify),
                  OptionSwitch(title: loc.updateAvailableNotify),
                  OptionSwitch(title: loc.soundEffects),
                ],
              ),
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
              child: Text(loc.savePreferences, style: const TextStyle(color: Colors.white)),
            ),
          ),
        ],
      ),
    );
  }
}

// ==================== 5. About Tab ====================
class AboutTab extends StatelessWidget {
  const AboutTab({super.key});

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;

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
                  const Icon(Icons.store, size: 80, color: Colors.teal),
                  const SizedBox(height: 10),
                  Text(
                    loc.appTitle,
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    '${loc.version}: 1.0.0',
                    style: const TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () {},
                    child: Text(loc.checkForUpdates),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    '${loc.developedBy}: Smart Khata Technologies',
                    style: const TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          // System Info
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    loc.systemInfo,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  InfoItem(label: loc.dbVersion, value: '1.0'),
                  InfoItem(label: loc.totalItems, value: '145'),
                  InfoItem(label: loc.totalCustomers, value: '45'),
                  InfoItem(label: loc.totalSuppliers, value: '12'),
                  InfoItem(label: loc.appUptime, value: '15d 2h'),
                  InfoItem(label: loc.lastLogin, value: 'Today 08:00 AM'),
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
                  Text(
                    loc.maintenance,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(onPressed: () {}, child: Text(loc.repairDb)),
                  ),
                  const SizedBox(height: 5),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(onPressed: () {}, child: Text(loc.archiveOldData)),
                  ),
                  const SizedBox(height: 5),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(onPressed: () {}, child: Text(loc.clearCache)),
                  ),
                  const SizedBox(height: 5),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(onPressed: () {}, child: Text(loc.viewLogs)),
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
                  Text(
                    loc.support,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  ListTile(
                    leading: const Icon(Icons.email),
                    title: Text(loc.email),
                    subtitle: const Text('hussainshahzad350@gmail.com'),
                  ),
                  ListTile(
                    leading: const Icon(Icons.phone),
                    title: Text(loc.phone),
                    subtitle: const Text('0310-4523235'),
                  ),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(onPressed: () {}, child: Text(loc.viewOnlineGuide)),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.grey[50],
            child: Center(
              child: Text(
                '© ${DateTime.now().year} ${loc.appTitle}. ${loc.allRightsReserved}',
                style: const TextStyle(fontSize: 12, color: Colors.grey),
                textAlign: TextAlign.center,
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
                  Text(fileName, style: const TextStyle(fontSize: 14)),
                  Text(date, style: const TextStyle(fontSize: 12, color: Colors.grey)),
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
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}