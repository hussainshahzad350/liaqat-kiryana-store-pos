// lib/screens/settings/settings_screen.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path/path.dart' show join, basename, dirname;
import 'package:intl/intl.dart';
import 'package:sqflite/sqflite.dart' as sql;
import '../../l10n/app_localizations.dart';
import '../../main.dart';
import '../../core/database/database_helper.dart' hide Database;
import '../../core/utils/logger.dart';

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
                    initialValue: 'Liaqat Kiryana Store',
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    decoration: InputDecoration(
                      labelText: loc.address,
                      border: const OutlineInputBorder(),
                      hintText: '123 Main Street, Lahore',
                    ),
                    maxLines: 2,
                    initialValue: '123 Main Street, Lahore',
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
class BackupTab extends StatefulWidget {
  const BackupTab({super.key});

  @override
  State<BackupTab> createState() => _BackupTabState();
}

class _BackupTabState extends State<BackupTab> {
  List<Map<String, dynamic>> backups = [];
  bool isLoading = false;
  double? currentDbSize;

  @override
  void initState() {
    super.initState();
    _loadBackups();
    _getCurrentDbSize();
  }

  Future<void> _loadBackups() async {
    setState(() => isLoading = true);
    backups = await DatabaseHelper.instance.getBackupFiles();
    setState(() => isLoading = false);
  }

  Future<bool> _createBackup() async {
    try {
      final backupPath = await DatabaseHelper.instance.createManualBackup(5);
      return backupPath != null;
    } catch (e) {
      AppLogger.error('Backup error: $e', tag: 'UI');
      return false;
    }
  }

  Future<void> _confirmRestore(String backupPath) async {
    final fileName = basename(backupPath);
  
    bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.restoreBackup),
        content: Text('${AppLocalizations.of(context)!.restoreConfirm}\n\n$fileName?\n\n${AppLocalizations.of(context)!.restoreWarning}'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(AppLocalizations.of(context)!.cancel),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text(AppLocalizations.of(context)!.restore, style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  
    if (confirm == true) {
      setState(() => isLoading = true);
      final success = await DatabaseHelper.instance.restoreBackup(backupPath);
      setState(() => isLoading = false);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(success 
              ? AppLocalizations.of(context)!.restoreSuccess
              : AppLocalizations.of(context)!.restoreFailed),
            backgroundColor: success ? Colors.green : Colors.red,
          )
        );
      }
    }
  }

  Future<void> _confirmDelete(String backupPath) async {
    final fileName = basename(backupPath);
  
    bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.deleteBackup),
        content: Text('${AppLocalizations.of(context)!.deleteConfirm}\n\n$fileName?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(AppLocalizations.of(context)!.cancel),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text(AppLocalizations.of(context)!.delete, style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  
    if (confirm == true) {
      try {
        await File(backupPath).delete();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(AppLocalizations.of(context)!.backupDeleted),
              backgroundColor: Colors.green,
            )
          );
        }
        await _loadBackups();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${AppLocalizations.of(context)!.deleteFailed}: $e'),
              backgroundColor: Colors.red,
            )
          );
        }
      }
    }
  }

  Future<void> _getCurrentDbSize() async {
    final db = await DatabaseHelper.instance.database;
    final file = File(db.path);
    if (await file.exists()) {
      final stat = await file.stat();
      setState(() {
        currentDbSize = stat.size / (1024 * 1024);
      });
    }
  }

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
                    loc.currentDatabase,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  FutureBuilder<sql.Database>(
                    future: DatabaseHelper.instance.database,
                    builder: (context, snapshot) {
                      if (snapshot.hasData) {
                        final db = snapshot.data!;
                        final dbPath = db.path;
                        final fileName = basename(dbPath);
                        final lastBackup = backups.isNotEmpty
                          ? DateFormat('dd-MM-yyyy HH:mm').format(backups.first['modified'] as DateTime)
                          : loc.never;
                        
                        return Column(
                          children: [
                            ListTile(
                              leading: const Icon(Icons.storage, color: Colors.teal),
                              title: Text(fileName),
                              subtitle: Text('${loc.size}: ${currentDbSize?.toStringAsFixed(2) ?? '?'} MB'),
                            ),
                            ListTile(
                              leading: const Icon(Icons.history, color: Colors.teal),
                              title: Text(loc.lastBackup),
                              subtitle: Text(lastBackup),
                            ),
                          ],
                        );
                      }
                      return const CircularProgressIndicator();
                    },
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
                        setState(() => isLoading = true);
                        final success = await _createBackup();
                        setState(() => isLoading = false);

                        if (!mounted) return;
                        
                        // ignore: use_build_context_synchronously
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(success
                              ? loc.backupCreated
                              : loc.backupFailed),
                            backgroundColor: success ? Colors.green : Colors.red,
                          )
                        );

                        if (success) {
                          await _loadBackups();
                        }
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
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(loc.usbExportSetup))
                        );
                      },
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
                  Row(
                    children: [
                      Text(
                        loc.recentBackups,
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      const Spacer(),
                      if (isLoading)
                        const Padding(
                          padding: EdgeInsets.all(8.0),
                          child: SizedBox(
                            height: 16,
                            width: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        ),
                      IconButton(
                        icon: const Icon(Icons.refresh),
                        onPressed: _loadBackups,
                        tooltip: loc.refresh,
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
        
                  if (backups.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      child: Center(
                        child: Text(
                          loc.noBackupsFound,
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      ),
                    )
                  else
                    ...backups.take(5).map((backup) {
                      final fileName = backup['name'] as String;
                      final size = (backup['size'] as int) / (1024 * 1024);
                      final modified = backup['modified'] as DateTime;
                      final dateStr = DateFormat('dd-MM-yyyy HH:mm').format(modified);
            
                      return Column(
                        children: [
                          ListTile(
                            leading: const Icon(Icons.insert_drive_file, color: Colors.teal),
                            title: Text(fileName),
                            subtitle: Text('$dateStr • ${size.toStringAsFixed(2)} MB'),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.restore, color: Colors.green),
                                  onPressed: () => _confirmRestore(backup['path'] as String),
                                  tooltip: loc.restore,
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete, color: Colors.red),
                                  onPressed: () => _confirmDelete(backup['path'] as String),
                                  tooltip: loc.delete,
                                ),
                              ],
                            ),
                          ),
                          const Divider(height: 1),
                        ],
                      );
                    }),
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
                  DropdownButton<String>(
                    value: loc.medium,
                    isExpanded: true,
                    items: [
                      DropdownMenuItem(value: loc.small, child: Text(loc.small)),
                      DropdownMenuItem(value: loc.medium, child: Text(loc.medium)),
                      DropdownMenuItem(value: loc.large, child: Text(loc.large)),
                    ],
                    onChanged: (value) {},
                  ),
                  const SizedBox(height: 10),
                  Text(loc.paperWidth),
                  DropdownButton<String>(
                    value: loc.paper58,
                    isExpanded: true,
                    items: [
                      DropdownMenuItem(value: loc.paper58, child: Text(loc.paper58)),
                      DropdownMenuItem(value: loc.paper80, child: Text(loc.paper80)),
                      DropdownMenuItem(value: loc.paperA4, child: Text(loc.paperA4)),
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
                    value: loc.printerUsb,
                    isExpanded: true,
                    items: [
                      DropdownMenuItem(value: loc.printerDefault, child: Text(loc.printerDefault)),
                      DropdownMenuItem(value: loc.printerUsb, child: Text(loc.printerUsb)),
                      DropdownMenuItem(value: loc.printerNetwork, child: Text(loc.printerNetwork)),
                      DropdownMenuItem(value: loc.printerPdf, child: Text(loc.printerPdf)),
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
class PreferencesTab extends StatefulWidget {
  const PreferencesTab({super.key});

  @override
  State<PreferencesTab> createState() => _PreferencesTabState();
}

class _PreferencesTabState extends State<PreferencesTab> {
  String? _selectedDateFormat;
  String? _selectedFrequency;
  String _currencyPosition = 'before';
  String _currencySymbol = 'Rs';

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
                  DropdownButton<String>(
                    value: _selectedDateFormat ?? 'DD-MM-YYYY',
                    isExpanded: true,
                    items: const ['DD-MM-YYYY', 'MM-DD-YYYY', 'YYYY-MM-DD']
                        .map((format) => DropdownMenuItem(value: format, child: Text(format)))
                        .toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedDateFormat = value;
                      });
                    },
                  ),
                  const SizedBox(height: 10),
                  Text(loc.currencySymbol),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          decoration: InputDecoration(hintText: loc.currencySymbol),
                          initialValue: _currencySymbol,
                          onChanged: (value) {
                            setState(() {
                              _currencySymbol = value;
                            });
                          },
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: DropdownButton<String>(
                          value: _currencyPosition,
                          isExpanded: true,
                          items: [
                            DropdownMenuItem(value: 'before', child: Text(loc.before)),
                            DropdownMenuItem(value: 'after', child: Text(loc.after)),
                          ],
                          onChanged: (value) {
                            setState(() {
                              _currencyPosition = value!;
                            });
                          },
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
                  DropdownButton<String>(
                    value: _selectedFrequency ?? loc.daily,
                    isExpanded: true,
                    items: [
                      DropdownMenuItem(value: loc.daily, child: Text(loc.daily)),
                      DropdownMenuItem(value: loc.weekly, child: Text(loc.weekly)),
                      DropdownMenuItem(value: loc.monthly, child: Text(loc.monthly)),
                    ],
                    onChanged: (value) {
                      setState(() {
                        _selectedFrequency = value;
                      });
                    },
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
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(loc.preferencesSaved),
                    backgroundColor: Colors.green,
                  )
                );
              },
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
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(loc.checkingForUpdates))
                      );
                    },
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

class OptionSwitch extends StatefulWidget {
  final String title;

  const OptionSwitch({super.key, required this.title});

  @override
  State<OptionSwitch> createState() => _OptionSwitchState();
}

class _OptionSwitchState extends State<OptionSwitch> {
  bool _isEnabled = true;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: Text(widget.title)),
        Switch(
          value: _isEnabled, 
          onChanged: (value) {
            setState(() {
              _isEnabled = value;
            });
          }
        ),
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