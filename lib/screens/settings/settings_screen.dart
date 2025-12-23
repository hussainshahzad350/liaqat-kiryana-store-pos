// lib/screens/settings/settings_screen.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path/path.dart' show join, basename, dirname;
import 'package:intl/intl.dart';
import 'package:sqflite/sqflite.dart' as sql;
import '../../l10n/app_localizations.dart';
import '../../main.dart';
import '../../core/utils/logger.dart';
import '../../core/repositories/settings_repository.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final SettingsRepository _settingsRepository = SettingsRepository();

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
        children: [
          ShopProfileTab(repository: _settingsRepository),
          BackupTab(repository: _settingsRepository),
          ReceiptTab(repository: _settingsRepository),
          PreferencesTab(repository: _settingsRepository),
          AboutTab(repository: _settingsRepository),
        ],
      ),
    );
  }
}

// ==================== 1. Shop Profile Tab ====================
class ShopProfileTab extends StatefulWidget {
  final SettingsRepository repository;
  const ShopProfileTab({super.key, required this.repository});

  @override
  State<ShopProfileTab> createState() => _ShopProfileTabState();
}

class _ShopProfileTabState extends State<ShopProfileTab> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameUrduController;
  late final TextEditingController _nameEnglishController;
  late final TextEditingController _addressController;
  late final TextEditingController _primaryPhoneController;
  late final TextEditingController _secondaryPhoneController;

  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _nameUrduController = TextEditingController();
    _nameEnglishController = TextEditingController();
    _addressController = TextEditingController();
    _primaryPhoneController = TextEditingController();
    _secondaryPhoneController = TextEditingController();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    setState(() => _isLoading = true);
    final profile = await widget.repository.getShopProfile();
    if (mounted) {
      if (profile != null) {
        _nameUrduController.text = profile['name_urdu'] ?? '';
        _nameEnglishController.text = profile['name_english'] ?? '';
        _addressController.text = profile['address'] ?? '';
        _primaryPhoneController.text = profile['phone_primary'] ?? '';
        _secondaryPhoneController.text = profile['phone_secondary'] ?? '';
      }
      setState(() => _isLoading = false);
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    final data = {
      'name_urdu': _nameUrduController.text,
      'name_english': _nameEnglishController.text,
      'address': _addressController.text,
      'phone_primary': _primaryPhoneController.text,
      'phone_secondary': _secondaryPhoneController.text,
    };
    await widget.repository.updateShopProfile(data);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.saveChangesSuccess),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  @override
  void dispose() {
    _nameUrduController.dispose();
    _nameEnglishController.dispose();
    _addressController.dispose();
    _primaryPhoneController.dispose();
    _secondaryPhoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
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
                                onPressed: () {
                                   ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text("Functionality not implemented yet."))
                                  );
                                },
                              ),
                              const SizedBox(width: 10),
                              OutlinedButton(
                                onPressed: () {
                                   ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text("Functionality not implemented yet."))
                                  );
                                },
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
                            controller: _nameUrduController,
                            decoration: InputDecoration(
                              labelText: loc.shopNameUrdu,
                              border: const OutlineInputBorder(),
                              hintText: 'لياقت کريانہ اسٹور',
                            ),
                          ),
                          const SizedBox(height: 10),
                          TextFormField(
                            controller: _nameEnglishController,
                            decoration: InputDecoration(
                              labelText: loc.shopNameEnglish,
                              border: const OutlineInputBorder(),
                              hintText: 'Liaqat Kiryana Store',
                            ),
                          ),
                          const SizedBox(height: 10),
                          TextFormField(
                            controller: _addressController,
                            decoration: InputDecoration(
                              labelText: loc.address,
                              border: const OutlineInputBorder(),
                              hintText: '123 Main Street, Lahore',
                            ),
                            maxLines: 2,
                          ),
                          const SizedBox(height: 10),
                          TextFormField(
                            controller: _primaryPhoneController,
                             validator: (value) => value == null || value.isEmpty ? loc.fieldRequired : null,
                            decoration: InputDecoration(
                              labelText: '${loc.primaryPhone} *',
                              border: const OutlineInputBorder(),
                              hintText: '0300-1234567',
                            ),
                          ),
                          const SizedBox(height: 10),
                          TextFormField(
                            controller: _secondaryPhoneController,
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
                              onPressed: _saveProfile,
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
            ),
    );
  }
}

// ==================== 2. Backup Tab ====================
class BackupTab extends StatefulWidget {
  final SettingsRepository repository;
  const BackupTab({super.key, required this.repository});

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
    backups = await widget.repository.getBackupFiles();
    if (mounted) {
      setState(() => isLoading = false);
    }
  }

  Future<void> _getCurrentDbSize() async {
    try {
      final size = await widget.repository.getDatabaseSize();
      if (mounted) {
        setState(() {
          currentDbSize = size;
        });
      }
    } catch (e) {
      AppLogger.error('Error getting database size: $e', tag: 'UI');
    }
  }

  Future<bool> _createBackup() async {
    try {
      final backupPath = await widget.repository.createManualBackup(5);
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
      final success = await widget.repository.restoreBackup(backupPath);
      if(mounted) setState(() => isLoading = false);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(success 
              ? AppLocalizations.of(context)!.restoreSuccess
              : AppLocalizations.of(context)!.restoreFailed),
            backgroundColor: success ? Colors.green : Colors.red,
          )
        );
         if (success) {
            // You might want to restart the app or re-initialize services here
            AppLogger.info("Database restored. App restart recommended.", tag: 'UI');
          }
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
      final success = await widget.repository.deleteBackup(backupPath);
       if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(success ? AppLocalizations.of(context)!.backupDeleted : AppLocalizations.of(context)!.deleteFailed),
              backgroundColor: success ? Colors.green : Colors.red,
            )
          );
        }
        if (success) {
          await _loadBackups();
        }
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
                   ListTile(
                    leading: const Icon(Icons.storage, color: Colors.teal),
                    title: const Text("app_database.db"), // Assuming a static name
                    subtitle: Text('${loc.size}: ${currentDbSize?.toStringAsFixed(2) ?? '?'} MB'),
                  ),
                  ListTile(
                    leading: const Icon(Icons.history, color: Colors.teal),
                    title: Text(loc.lastBackup),
                    subtitle: Text(backups.isNotEmpty
                        ? DateFormat('dd-MM-yyyy HH:mm').format(backups.first['modified'] as DateTime)
                        : loc.never),
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
                        if (mounted) setState(() => isLoading = false);

                        if (!mounted) return;
                        
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
                          await _getCurrentDbSize();
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
                       onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(loc.usbExportSetup))
                        );
                      },
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
        
                  if (backups.isEmpty && !isLoading)
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
  final SettingsRepository repository;
  const ReceiptTab({super.key, required this.repository});

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;

    // TODO: Load receipt preferences from repository
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
                    onChanged: (value) {}, // TODO: Save preference
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
                    onChanged: (value) {}, // TODO: Save preference
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
                    onChanged: (value) {}, // TODO: Save preference
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.print),
                      label: Text(loc.printTestReceipt),
                      onPressed: () {
                         ScaffoldMessenger.of(context).showSnackBar(
                           const SnackBar(content: Text("Functionality not implemented yet."))
                         );
                      },
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
  final SettingsRepository repository;
  const PreferencesTab({super.key, required this.repository});

  @override
  State<PreferencesTab> createState() => _PreferencesTabState();
}

class _PreferencesTabState extends State<PreferencesTab> {
  // App Preferences
  String? _selectedDateFormat;
  String _currencyPosition = 'before';
  String _currencySymbol = 'Rs';
  
  // Security
  bool _requirePassword = false;
  final TextEditingController _passwordController = TextEditingController();

  // Auto Backup
  bool _autoBackupEnabled = false;
  String? _selectedFrequency;

  // Notifications
  bool _lowStockAlert = true;
  bool _dayCloseReminder = true;

  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    setState(() => _isLoading = true);
    // In a real app, you'd load these from the repository
    // The repository currently returns placeholder data, but the UI is ready.
    final prefs = await widget.repository.getAppPreferences();
    if(mounted) {
      setState(() {
        _selectedDateFormat = prefs['dateFormat'] ?? 'DD-MM-YYYY';
        _currencySymbol = prefs['currencySymbol'] ?? 'Rs';
        _currencyPosition = prefs['currencyPosition'] ?? 'before';
        _requirePassword = prefs['requirePassword'] ?? false;
        _autoBackupEnabled = prefs['autoBackupEnabled'] ?? false;
        _lowStockAlert = prefs['lowStockAlert'] ?? true;
        _dayCloseReminder = prefs['dayCloseReminder'] ?? true;
        // The frequency might need localization if the keys are stored in english
        _selectedFrequency = prefs['backupFrequency'] ?? AppLocalizations.of(context)!.daily;
        _isLoading = false;
      });
    }
  }

  Future<void> _savePreferences() async {
    final loc = AppLocalizations.of(context)!;
    final prefs = {
      'dateFormat': _selectedDateFormat,
      'currencySymbol': _currencySymbol,
      'currencyPosition': _currencyPosition,
      'requirePassword': _requirePassword,
      'password': _passwordController.text, // Note: Password should be hashed in a real app
      'autoBackupEnabled': _autoBackupEnabled,
      'backupFrequency': _selectedFrequency,
      'lowStockAlert': _lowStockAlert,
      'dayCloseReminder': _dayCloseReminder,
    };
    await widget.repository.updateAppPreferences(prefs);
    if(mounted) {
       ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(loc.preferencesSaved),
          backgroundColor: Colors.green,
        )
      );
    }
  }

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    
    final String currentLangCode = Localizations.localeOf(context).languageCode;
    String dropdownValue = currentLangCode == 'ur' ? 'اردو' : 'English';

    return _isLoading 
      ? const Center(child: CircularProgressIndicator())
      : SingleChildScrollView(
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
                            // No need for setState since controller handles it, but for saving we need it
                            _currencySymbol = value;
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
                  OptionSwitch(
                    title: loc.requirePasswordStartup,
                    isEnabled: _requirePassword,
                    onChanged: (value) => setState(() => _requirePassword = value),
                  ),
                  if(_requirePassword) ...[
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: _passwordController,
                      decoration: InputDecoration(
                        labelText: loc.password,
                        suffixIcon: const Icon(Icons.visibility_off),
                      ),
                      obscureText: true,
                    ),
                  ],
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
                  OptionSwitch(
                    title: loc.enableAutoBackup,
                    isEnabled: _autoBackupEnabled,
                    onChanged: (value) => setState(() => _autoBackupEnabled = value),
                    ),
                  if(_autoBackupEnabled) ...[
                    const SizedBox(height: 10),
                    Text(loc.frequency),
                    DropdownButton<String>(
                      value: _selectedFrequency ?? loc.daily,
                      isExpanded: true,
                      items: [ loc.daily, loc.weekly, loc.monthly]
                          .map((freq) => DropdownMenuItem(value: freq, child: Text(freq)))
                          .toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedFrequency = value;
                        });
                      },
                    ),
                  ]
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
                  OptionSwitch(
                    title: loc.lowStockAlert,
                    isEnabled: _lowStockAlert,
                    onChanged: (value) => setState(() => _lowStockAlert = value),
                  ),
                  OptionSwitch(
                    title: loc.dayCloseReminder,
                    isEnabled: _dayCloseReminder,
                    onChanged: (value) => setState(() => _dayCloseReminder = value),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _savePreferences,
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
  final SettingsRepository repository;
  const AboutTab({super.key, required this.repository});

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
                    '${loc.version}: 1.0.0', // TODO: Make this dynamic from pubspec
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
              child: FutureBuilder<Map<String, dynamic>>(
                future: repository.getDatabaseStats(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return Center(child: Text("Error: ${snapshot.error}"));
                  }
                  if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return Center(child: Text(loc.noDataAvailable));
                  }
                  
                  final stats = snapshot.data!;
                  return Column(
                     crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        loc.systemInfo,
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 10),
                      InfoItem(label: loc.totalItems, value: (stats['products'] ?? 0).toString()),
                      InfoItem(label: loc.totalCustomers, value: (stats['customers'] ?? 0).toString()),
                      InfoItem(label: loc.totalSuppliers, value: (stats['suppliers'] ?? 0).toString()),
                      InfoItem(label: loc.totalSales, value: (stats['sales'] ?? 0).toString()),
                      InfoItem(label: loc.dbSize, value: "${(stats['databaseSize'] as double?)?.toStringAsFixed(2) ?? '0'} MB"),
                    ],
                  );
                }
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
                    child: OutlinedButton(onPressed: () async {
                      final success = await repository.vacuumDatabase();
                       if(context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(success ? "Database Optimized" : "Optimization failed"), backgroundColor: success ? Colors.green : Colors.red,)
                          );
                       }
                    }, child: Text(loc.repairDb)),
                  ),
                  const SizedBox(height: 5),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(onPressed: () {
                       ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Functionality not implemented yet."))
                      );
                    }, child: Text(loc.archiveOldData)),
                  ),
                  const SizedBox(height: 5),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(onPressed: () {
                       ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Functionality not implemented yet."))
                      );
                    }, child: Text(loc.clearCache)),
                  ),
                  const SizedBox(height: 5),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(onPressed: () {
                       ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Functionality not implemented yet."))
                      );
                    }, child: Text(loc.viewLogs)),
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
                    onTap: () {},
                  ),
                  ListTile(
                    leading: const Icon(Icons.phone),
                    title: Text(loc.phone),
                    subtitle: const Text('0310-4523235'),
                     onTap: () {},
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
  final VoidCallback onRestore;
  final VoidCallback onDelete;

  const BackupItem({
    super.key,
    required this.fileName,
    required this.date,
    required this.size,
    required this.onRestore,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    return Column(
      children: [
        ListTile(
          leading: const Icon(Icons.insert_drive_file, color: Colors.teal),
          title: Text(fileName),
          subtitle: Text('$date • $size'),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(Icons.restore, color: Colors.green),
                onPressed: onRestore,
                tooltip: loc.restore,
              ),
              IconButton(
                icon: const Icon(Icons.delete, color: Colors.red),
                onPressed: onDelete,
                tooltip: loc.delete,
              ),
            ],
          ),
        ),
        const Divider(height: 1),
      ],
    );
  }
}

class OptionSwitch extends StatelessWidget {
  final String title;
  final bool isEnabled;
  final Function(bool)? onChanged;

  const OptionSwitch({
    super.key, 
    required this.title,
    this.isEnabled = false,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: Text(title)),
        Switch(
          value: isEnabled, 
          onChanged: onChanged
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