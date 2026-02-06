import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_ur.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('ur')
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'Liaqat Kiryana Store'**
  String get appTitle;

  /// No description provided for @posSystem.
  ///
  /// In en, this message translates to:
  /// **'POS System'**
  String get posSystem;

  /// No description provided for @posVersion.
  ///
  /// In en, this message translates to:
  /// **'POS System v1.0'**
  String get posVersion;

  /// No description provided for @login.
  ///
  /// In en, this message translates to:
  /// **'Login'**
  String get login;

  /// No description provided for @password.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get password;

  /// No description provided for @forgotPassword.
  ///
  /// In en, this message translates to:
  /// **'Forgot Password?'**
  String get forgotPassword;

  /// No description provided for @home.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get home;

  /// No description provided for @salesPos.
  ///
  /// In en, this message translates to:
  /// **'Sales / POS'**
  String get salesPos;

  /// No description provided for @stockManagement.
  ///
  /// In en, this message translates to:
  /// **'Stock Management'**
  String get stockManagement;

  /// No description provided for @masterData.
  ///
  /// In en, this message translates to:
  /// **'Master Data'**
  String get masterData;

  /// No description provided for @reports.
  ///
  /// In en, this message translates to:
  /// **'Reports'**
  String get reports;

  /// No description provided for @cashLedger.
  ///
  /// In en, this message translates to:
  /// **'Cash Ledger'**
  String get cashLedger;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @aboutApp.
  ///
  /// In en, this message translates to:
  /// **'About App'**
  String get aboutApp;

  /// No description provided for @logout.
  ///
  /// In en, this message translates to:
  /// **'Logout'**
  String get logout;

  /// No description provided for @generateBill.
  ///
  /// In en, this message translates to:
  /// **'Generate Bill'**
  String get generateBill;

  /// No description provided for @todaySales.
  ///
  /// In en, this message translates to:
  /// **'Today\'s Sales'**
  String get todaySales;

  /// No description provided for @todayCustomers.
  ///
  /// In en, this message translates to:
  /// **'Today\'s Customers'**
  String get todayCustomers;

  /// No description provided for @noCustomersToday.
  ///
  /// In en, this message translates to:
  /// **'No customers today'**
  String get noCustomersToday;

  /// No description provided for @lowStock.
  ///
  /// In en, this message translates to:
  /// **'Low Stock'**
  String get lowStock;

  /// No description provided for @allStockAvailable.
  ///
  /// In en, this message translates to:
  /// **'All items in stock'**
  String get allStockAvailable;

  /// No description provided for @recentSales.
  ///
  /// In en, this message translates to:
  /// **'Recent Sales'**
  String get recentSales;

  /// No description provided for @noSalesYet.
  ///
  /// In en, this message translates to:
  /// **'No sales yet'**
  String get noSalesYet;

  /// No description provided for @customer.
  ///
  /// In en, this message translates to:
  /// **'Customer'**
  String get customer;

  /// No description provided for @amount.
  ///
  /// In en, this message translates to:
  /// **'Amount'**
  String get amount;

  /// No description provided for @item.
  ///
  /// In en, this message translates to:
  /// **'Item'**
  String get item;

  /// No description provided for @current.
  ///
  /// In en, this message translates to:
  /// **'Current'**
  String get current;

  /// No description provided for @required.
  ///
  /// In en, this message translates to:
  /// **'Required'**
  String get required;

  /// No description provided for @items.
  ///
  /// In en, this message translates to:
  /// **'Items'**
  String get items;

  /// No description provided for @customers.
  ///
  /// In en, this message translates to:
  /// **'Customers'**
  String get customers;

  /// No description provided for @suppliers.
  ///
  /// In en, this message translates to:
  /// **'Suppliers'**
  String get suppliers;

  /// No description provided for @categories.
  ///
  /// In en, this message translates to:
  /// **'Categories'**
  String get categories;

  /// No description provided for @units.
  ///
  /// In en, this message translates to:
  /// **'Units'**
  String get units;

  /// No description provided for @itemsManagement.
  ///
  /// In en, this message translates to:
  /// **'Items Management'**
  String get itemsManagement;

  /// No description provided for @searchItem.
  ///
  /// In en, this message translates to:
  /// **'Search Item'**
  String get searchItem;

  /// No description provided for @noItemsFound.
  ///
  /// In en, this message translates to:
  /// **'No items found'**
  String get noItemsFound;

  /// No description provided for @addNewItem.
  ///
  /// In en, this message translates to:
  /// **'Add New Item'**
  String get addNewItem;

  /// No description provided for @englishName.
  ///
  /// In en, this message translates to:
  /// **'English Name'**
  String get englishName;

  /// No description provided for @urduName.
  ///
  /// In en, this message translates to:
  /// **'Urdu Name'**
  String get urduName;

  /// No description provided for @salePrice.
  ///
  /// In en, this message translates to:
  /// **'Sale Price'**
  String get salePrice;

  /// No description provided for @initialStock.
  ///
  /// In en, this message translates to:
  /// **'Initial Stock'**
  String get initialStock;

  /// No description provided for @stock.
  ///
  /// In en, this message translates to:
  /// **'Stock'**
  String get stock;

  /// No description provided for @price.
  ///
  /// In en, this message translates to:
  /// **'Price'**
  String get price;

  /// No description provided for @cost.
  ///
  /// In en, this message translates to:
  /// **'Cost'**
  String get cost;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @editItem.
  ///
  /// In en, this message translates to:
  /// **'Edit Item'**
  String get editItem;

  /// No description provided for @stockUpdate.
  ///
  /// In en, this message translates to:
  /// **'Stock Update'**
  String get stockUpdate;

  /// No description provided for @update.
  ///
  /// In en, this message translates to:
  /// **'Update'**
  String get update;

  /// No description provided for @confirmation.
  ///
  /// In en, this message translates to:
  /// **'Confirmation'**
  String get confirmation;

  /// No description provided for @deleteItemConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this item?'**
  String get deleteItemConfirm;

  /// No description provided for @yesDelete.
  ///
  /// In en, this message translates to:
  /// **'Yes, Delete'**
  String get yesDelete;

  /// No description provided for @no.
  ///
  /// In en, this message translates to:
  /// **'No'**
  String get no;

  /// No description provided for @itemDeleted.
  ///
  /// In en, this message translates to:
  /// **'Item deleted'**
  String get itemDeleted;

  /// No description provided for @error.
  ///
  /// In en, this message translates to:
  /// **'Error'**
  String get error;

  /// No description provided for @purchase.
  ///
  /// In en, this message translates to:
  /// **'Purchase'**
  String get purchase;

  /// No description provided for @sales.
  ///
  /// In en, this message translates to:
  /// **'Sales'**
  String get sales;

  /// No description provided for @stockView.
  ///
  /// In en, this message translates to:
  /// **'Stock View'**
  String get stockView;

  /// No description provided for @newPurchase.
  ///
  /// In en, this message translates to:
  /// **'New Purchase'**
  String get newPurchase;

  /// No description provided for @selectSupplier.
  ///
  /// In en, this message translates to:
  /// **'Select Supplier'**
  String get selectSupplier;

  /// No description provided for @chooseSupplier.
  ///
  /// In en, this message translates to:
  /// **'Choose Supplier'**
  String get chooseSupplier;

  /// No description provided for @addItem.
  ///
  /// In en, this message translates to:
  /// **'Add Item'**
  String get addItem;

  /// No description provided for @quantity.
  ///
  /// In en, this message translates to:
  /// **'Quantity'**
  String get quantity;

  /// No description provided for @total.
  ///
  /// In en, this message translates to:
  /// **'Total'**
  String get total;

  /// No description provided for @additionalCharges.
  ///
  /// In en, this message translates to:
  /// **'Additional Charges'**
  String get additionalCharges;

  /// No description provided for @transport.
  ///
  /// In en, this message translates to:
  /// **'Transport'**
  String get transport;

  /// No description provided for @labor.
  ///
  /// In en, this message translates to:
  /// **'Labor'**
  String get labor;

  /// No description provided for @savePurchase.
  ///
  /// In en, this message translates to:
  /// **'Save Purchase'**
  String get savePurchase;

  /// No description provided for @salesRecord.
  ///
  /// In en, this message translates to:
  /// **'Sales Record'**
  String get salesRecord;

  /// No description provided for @allSalesVisibleHere.
  ///
  /// In en, this message translates to:
  /// **'All sales will be visible here'**
  String get allSalesVisibleHere;

  /// No description provided for @makeNewSale.
  ///
  /// In en, this message translates to:
  /// **'Make New Sale'**
  String get makeNewSale;

  /// No description provided for @searchStock.
  ///
  /// In en, this message translates to:
  /// **'Search Stock'**
  String get searchStock;

  /// No description provided for @totalItems.
  ///
  /// In en, this message translates to:
  /// **'Total Items'**
  String get totalItems;

  /// No description provided for @stockValue.
  ///
  /// In en, this message translates to:
  /// **'Stock Value'**
  String get stockValue;

  /// No description provided for @stockDetails.
  ///
  /// In en, this message translates to:
  /// **'Stock Details'**
  String get stockDetails;

  /// No description provided for @unit.
  ///
  /// In en, this message translates to:
  /// **'Unit'**
  String get unit;

  /// No description provided for @action.
  ///
  /// In en, this message translates to:
  /// **'Action'**
  String get action;

  /// No description provided for @adjustStock.
  ///
  /// In en, this message translates to:
  /// **'Adjust Stock'**
  String get adjustStock;

  /// No description provided for @downloadReport.
  ///
  /// In en, this message translates to:
  /// **'Download Report'**
  String get downloadReport;

  /// No description provided for @profit.
  ///
  /// In en, this message translates to:
  /// **'Profit'**
  String get profit;

  /// No description provided for @customerBalance.
  ///
  /// In en, this message translates to:
  /// **'Customer Balance'**
  String get customerBalance;

  /// No description provided for @dateSelection.
  ///
  /// In en, this message translates to:
  /// **'Date Selection'**
  String get dateSelection;

  /// No description provided for @startDate.
  ///
  /// In en, this message translates to:
  /// **'Start Date'**
  String get startDate;

  /// No description provided for @endDate.
  ///
  /// In en, this message translates to:
  /// **'End Date'**
  String get endDate;

  /// No description provided for @to.
  ///
  /// In en, this message translates to:
  /// **'to'**
  String get to;

  /// No description provided for @comparison.
  ///
  /// In en, this message translates to:
  /// **'Comparison'**
  String get comparison;

  /// No description provided for @thisMonthVsLast.
  ///
  /// In en, this message translates to:
  /// **'This Month vs Last Month'**
  String get thisMonthVsLast;

  /// No description provided for @totalSales.
  ///
  /// In en, this message translates to:
  /// **'Total Sales'**
  String get totalSales;

  /// No description provided for @dailyAverage.
  ///
  /// In en, this message translates to:
  /// **'Daily Average'**
  String get dailyAverage;

  /// No description provided for @totalBills.
  ///
  /// In en, this message translates to:
  /// **'Total Bills'**
  String get totalBills;

  /// No description provided for @salesGraph.
  ///
  /// In en, this message translates to:
  /// **'Sales Graph'**
  String get salesGraph;

  /// No description provided for @detailedSales.
  ///
  /// In en, this message translates to:
  /// **'Detailed Sales'**
  String get detailedSales;

  /// No description provided for @billNumber.
  ///
  /// In en, this message translates to:
  /// **'Bill #'**
  String get billNumber;

  /// No description provided for @cash.
  ///
  /// In en, this message translates to:
  /// **'Cash'**
  String get cash;

  /// No description provided for @bank.
  ///
  /// In en, this message translates to:
  /// **'Bank'**
  String get bank;

  /// No description provided for @credit.
  ///
  /// In en, this message translates to:
  /// **'Credit'**
  String get credit;

  /// No description provided for @profitSummary.
  ///
  /// In en, this message translates to:
  /// **'Profit Summary'**
  String get profitSummary;

  /// No description provided for @totalCost.
  ///
  /// In en, this message translates to:
  /// **'Total Cost'**
  String get totalCost;

  /// No description provided for @netProfit.
  ///
  /// In en, this message translates to:
  /// **'Net Profit'**
  String get netProfit;

  /// No description provided for @profitPercentage.
  ///
  /// In en, this message translates to:
  /// **'Profit %'**
  String get profitPercentage;

  /// No description provided for @avgProfitPerBill.
  ///
  /// In en, this message translates to:
  /// **'Avg Profit/Bill'**
  String get avgProfitPerBill;

  /// No description provided for @expensesBreakdown.
  ///
  /// In en, this message translates to:
  /// **'Expenses Breakdown'**
  String get expensesBreakdown;

  /// No description provided for @purchaseCost.
  ///
  /// In en, this message translates to:
  /// **'Purchase Cost'**
  String get purchaseCost;

  /// No description provided for @otherExpenses.
  ///
  /// In en, this message translates to:
  /// **'Other Expenses'**
  String get otherExpenses;

  /// No description provided for @totalExpenses.
  ///
  /// In en, this message translates to:
  /// **'Total Expenses'**
  String get totalExpenses;

  /// No description provided for @monthlyProfit.
  ///
  /// In en, this message translates to:
  /// **'Monthly Profit'**
  String get monthlyProfit;

  /// No description provided for @purchaseReport.
  ///
  /// In en, this message translates to:
  /// **'Purchase Report'**
  String get purchaseReport;

  /// No description provided for @allPurchasesVisibleHere.
  ///
  /// In en, this message translates to:
  /// **'All purchases will be visible here'**
  String get allPurchasesVisibleHere;

  /// No description provided for @customerBalanceSummary.
  ///
  /// In en, this message translates to:
  /// **'Customer Balance Summary'**
  String get customerBalanceSummary;

  /// No description provided for @totalBalance.
  ///
  /// In en, this message translates to:
  /// **'Total Balance'**
  String get totalBalance;

  /// No description provided for @avgBalance.
  ///
  /// In en, this message translates to:
  /// **'Avg Balance'**
  String get avgBalance;

  /// No description provided for @balanceAging.
  ///
  /// In en, this message translates to:
  /// **'Balance Aging'**
  String get balanceAging;

  /// No description provided for @days.
  ///
  /// In en, this message translates to:
  /// **'Days'**
  String get days;

  /// No description provided for @old.
  ///
  /// In en, this message translates to:
  /// **'Old'**
  String get old;

  /// No description provided for @topBalanceCustomers.
  ///
  /// In en, this message translates to:
  /// **'Top Balance Customers'**
  String get topBalanceCustomers;

  /// No description provided for @stockValueSummary.
  ///
  /// In en, this message translates to:
  /// **'Stock Value Summary'**
  String get stockValueSummary;

  /// No description provided for @avgPrice.
  ///
  /// In en, this message translates to:
  /// **'Avg Price'**
  String get avgPrice;

  /// No description provided for @categoryStock.
  ///
  /// In en, this message translates to:
  /// **'Category-wise Stock'**
  String get categoryStock;

  /// No description provided for @lowStockItems.
  ///
  /// In en, this message translates to:
  /// **'Low Stock Items'**
  String get lowStockItems;

  /// No description provided for @fullReport.
  ///
  /// In en, this message translates to:
  /// **'Full Report'**
  String get fullReport;

  /// No description provided for @shopProfile.
  ///
  /// In en, this message translates to:
  /// **'Shop Profile'**
  String get shopProfile;

  /// No description provided for @backup.
  ///
  /// In en, this message translates to:
  /// **'Backup'**
  String get backup;

  /// No description provided for @receiptFormat.
  ///
  /// In en, this message translates to:
  /// **'Receipt Format'**
  String get receiptFormat;

  /// No description provided for @preferences.
  ///
  /// In en, this message translates to:
  /// **'Preferences'**
  String get preferences;

  /// No description provided for @about.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get about;

  /// No description provided for @appDescription.
  ///
  /// In en, this message translates to:
  /// **'A complete Point of Sale solution for retail businesses.'**
  String get appDescription;

  /// No description provided for @techInfo.
  ///
  /// In en, this message translates to:
  /// **'Technical Info'**
  String get techInfo;

  /// No description provided for @framework.
  ///
  /// In en, this message translates to:
  /// **'Framework'**
  String get framework;

  /// No description provided for @platform.
  ///
  /// In en, this message translates to:
  /// **'Platform'**
  String get platform;

  /// No description provided for @database.
  ///
  /// In en, this message translates to:
  /// **'Database'**
  String get database;

  /// No description provided for @stateManagement.
  ///
  /// In en, this message translates to:
  /// **'State Management'**
  String get stateManagement;

  /// No description provided for @uiFramework.
  ///
  /// In en, this message translates to:
  /// **'UI Framework'**
  String get uiFramework;

  /// No description provided for @lastUpdated.
  ///
  /// In en, this message translates to:
  /// **'Last Updated'**
  String get lastUpdated;

  /// No description provided for @features.
  ///
  /// In en, this message translates to:
  /// **'Key Features'**
  String get features;

  /// No description provided for @featurePos.
  ///
  /// In en, this message translates to:
  /// **'Fast Point of Sale'**
  String get featurePos;

  /// No description provided for @featureStockManagement.
  ///
  /// In en, this message translates to:
  /// **'Smart Stock Management'**
  String get featureStockManagement;

  /// No description provided for @featureCustomerManagement.
  ///
  /// In en, this message translates to:
  /// **'Customer Ledger & Tracking'**
  String get featureCustomerManagement;

  /// No description provided for @featureReporting.
  ///
  /// In en, this message translates to:
  /// **'Advanced Reporting'**
  String get featureReporting;

  /// No description provided for @featureBackup.
  ///
  /// In en, this message translates to:
  /// **'Automated Backups'**
  String get featureBackup;

  /// No description provided for @featureBilingual.
  ///
  /// In en, this message translates to:
  /// **'Bilingual Support (Urdu/English)'**
  String get featureBilingual;

  /// No description provided for @featurePrinter.
  ///
  /// In en, this message translates to:
  /// **'Thermal Printer Integration'**
  String get featurePrinter;

  /// No description provided for @changeLogo.
  ///
  /// In en, this message translates to:
  /// **'Change Logo'**
  String get changeLogo;

  /// No description provided for @remove.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get remove;

  /// No description provided for @shopDetails.
  ///
  /// In en, this message translates to:
  /// **'Shop Details'**
  String get shopDetails;

  /// No description provided for @shopNameUrdu.
  ///
  /// In en, this message translates to:
  /// **'Shop Name (Urdu)'**
  String get shopNameUrdu;

  /// No description provided for @shopNameEnglish.
  ///
  /// In en, this message translates to:
  /// **'Shop Name (English)'**
  String get shopNameEnglish;

  /// No description provided for @address.
  ///
  /// In en, this message translates to:
  /// **'Address'**
  String get address;

  /// No description provided for @primaryPhone.
  ///
  /// In en, this message translates to:
  /// **'Primary Phone'**
  String get primaryPhone;

  /// No description provided for @secondaryPhone.
  ///
  /// In en, this message translates to:
  /// **'Secondary Phone'**
  String get secondaryPhone;

  /// No description provided for @saveChanges.
  ///
  /// In en, this message translates to:
  /// **'Save Changes'**
  String get saveChanges;

  /// No description provided for @currentDatabase.
  ///
  /// In en, this message translates to:
  /// **'Current Database'**
  String get currentDatabase;

  /// No description provided for @size.
  ///
  /// In en, this message translates to:
  /// **'Size'**
  String get size;

  /// No description provided for @lastBackup.
  ///
  /// In en, this message translates to:
  /// **'Last Backup'**
  String get lastBackup;

  /// No description provided for @backupOptions.
  ///
  /// In en, this message translates to:
  /// **'Backup Options'**
  String get backupOptions;

  /// No description provided for @createBackupNow.
  ///
  /// In en, this message translates to:
  /// **'Create Backup Now'**
  String get createBackupNow;

  /// No description provided for @exportToUsb.
  ///
  /// In en, this message translates to:
  /// **'Export to USB'**
  String get exportToUsb;

  /// No description provided for @importFromUsb.
  ///
  /// In en, this message translates to:
  /// **'Import from USB'**
  String get importFromUsb;

  /// No description provided for @recentBackups.
  ///
  /// In en, this message translates to:
  /// **'Recent Backups'**
  String get recentBackups;

  /// No description provided for @openFolder.
  ///
  /// In en, this message translates to:
  /// **'Open Folder'**
  String get openFolder;

  /// No description provided for @restore.
  ///
  /// In en, this message translates to:
  /// **'Restore'**
  String get restore;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @receiptOptions.
  ///
  /// In en, this message translates to:
  /// **'Receipt Options'**
  String get receiptOptions;

  /// No description provided for @showLogo.
  ///
  /// In en, this message translates to:
  /// **'Show Logo'**
  String get showLogo;

  /// No description provided for @showShopAddress.
  ///
  /// In en, this message translates to:
  /// **'Show Shop Address'**
  String get showShopAddress;

  /// No description provided for @showPhone.
  ///
  /// In en, this message translates to:
  /// **'Show Phone Number'**
  String get showPhone;

  /// No description provided for @showDateTime.
  ///
  /// In en, this message translates to:
  /// **'Show Date & Time'**
  String get showDateTime;

  /// No description provided for @showCustomerDetails.
  ///
  /// In en, this message translates to:
  /// **'Show Customer Details'**
  String get showCustomerDetails;

  /// No description provided for @showPaymentDetails.
  ///
  /// In en, this message translates to:
  /// **'Show Payment Details'**
  String get showPaymentDetails;

  /// No description provided for @fontSize.
  ///
  /// In en, this message translates to:
  /// **'Font Size'**
  String get fontSize;

  /// No description provided for @paperWidth.
  ///
  /// In en, this message translates to:
  /// **'Paper Width'**
  String get paperWidth;

  /// No description provided for @printerSettings.
  ///
  /// In en, this message translates to:
  /// **'Printer Settings'**
  String get printerSettings;

  /// No description provided for @selectPrinter.
  ///
  /// In en, this message translates to:
  /// **'Select Printer'**
  String get selectPrinter;

  /// No description provided for @printTestReceipt.
  ///
  /// In en, this message translates to:
  /// **'Print Test Receipt'**
  String get printTestReceipt;

  /// No description provided for @receiptPreview.
  ///
  /// In en, this message translates to:
  /// **'Receipt Preview'**
  String get receiptPreview;

  /// No description provided for @languageAndRegion.
  ///
  /// In en, this message translates to:
  /// **'Language & Region'**
  String get languageAndRegion;

  /// No description provided for @appLanguage.
  ///
  /// In en, this message translates to:
  /// **'App Language'**
  String get appLanguage;

  /// No description provided for @dateFormat.
  ///
  /// In en, this message translates to:
  /// **'Date Format'**
  String get dateFormat;

  /// No description provided for @currencySymbol.
  ///
  /// In en, this message translates to:
  /// **'Currency Symbol'**
  String get currencySymbol;

  /// No description provided for @before.
  ///
  /// In en, this message translates to:
  /// **'Before'**
  String get before;

  /// No description provided for @after.
  ///
  /// In en, this message translates to:
  /// **'After'**
  String get after;

  /// No description provided for @security.
  ///
  /// In en, this message translates to:
  /// **'Security'**
  String get security;

  /// No description provided for @requirePasswordStartup.
  ///
  /// In en, this message translates to:
  /// **'Require Password on Startup'**
  String get requirePasswordStartup;

  /// No description provided for @lockAfter5Min.
  ///
  /// In en, this message translates to:
  /// **'Lock after 5 min inactivity'**
  String get lockAfter5Min;

  /// No description provided for @autoBackup.
  ///
  /// In en, this message translates to:
  /// **'Auto Backup'**
  String get autoBackup;

  /// No description provided for @enableAutoBackup.
  ///
  /// In en, this message translates to:
  /// **'Enable Auto Backup'**
  String get enableAutoBackup;

  /// No description provided for @frequency.
  ///
  /// In en, this message translates to:
  /// **'Frequency'**
  String get frequency;

  /// No description provided for @time.
  ///
  /// In en, this message translates to:
  /// **'Time'**
  String get time;

  /// No description provided for @notifications.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notifications;

  /// No description provided for @lowStockAlert.
  ///
  /// In en, this message translates to:
  /// **'Low Stock Alert'**
  String get lowStockAlert;

  /// No description provided for @dayCloseReminder.
  ///
  /// In en, this message translates to:
  /// **'Day Close Reminder'**
  String get dayCloseReminder;

  /// No description provided for @backupSuccessNotify.
  ///
  /// In en, this message translates to:
  /// **'Backup Success Notification'**
  String get backupSuccessNotify;

  /// No description provided for @updateAvailableNotify.
  ///
  /// In en, this message translates to:
  /// **'Update Available Notification'**
  String get updateAvailableNotify;

  /// No description provided for @soundEffects.
  ///
  /// In en, this message translates to:
  /// **'Sound Effects'**
  String get soundEffects;

  /// No description provided for @popupNotifications.
  ///
  /// In en, this message translates to:
  /// **'Popup Notifications'**
  String get popupNotifications;

  /// No description provided for @savePreferences.
  ///
  /// In en, this message translates to:
  /// **'Save Preferences'**
  String get savePreferences;

  /// No description provided for @version.
  ///
  /// In en, this message translates to:
  /// **'Version'**
  String get version;

  /// No description provided for @checkForUpdates.
  ///
  /// In en, this message translates to:
  /// **'Check for Updates'**
  String get checkForUpdates;

  /// No description provided for @developedBy.
  ///
  /// In en, this message translates to:
  /// **'Developed By'**
  String get developedBy;

  /// No description provided for @systemInfo.
  ///
  /// In en, this message translates to:
  /// **'System Information'**
  String get systemInfo;

  /// No description provided for @dbVersion.
  ///
  /// In en, this message translates to:
  /// **'Database Version'**
  String get dbVersion;

  /// No description provided for @totalSuppliers.
  ///
  /// In en, this message translates to:
  /// **'Total Suppliers'**
  String get totalSuppliers;

  /// No description provided for @appUptime.
  ///
  /// In en, this message translates to:
  /// **'App Uptime'**
  String get appUptime;

  /// No description provided for @lastLogin.
  ///
  /// In en, this message translates to:
  /// **'Last Login'**
  String get lastLogin;

  /// No description provided for @maintenance.
  ///
  /// In en, this message translates to:
  /// **'Maintenance'**
  String get maintenance;

  /// No description provided for @repairDb.
  ///
  /// In en, this message translates to:
  /// **'Repair Database'**
  String get repairDb;

  /// No description provided for @archiveOldData.
  ///
  /// In en, this message translates to:
  /// **'Archive Old Data'**
  String get archiveOldData;

  /// No description provided for @clearCache.
  ///
  /// In en, this message translates to:
  /// **'Clear Cache'**
  String get clearCache;

  /// No description provided for @viewLogs.
  ///
  /// In en, this message translates to:
  /// **'View Logs'**
  String get viewLogs;

  /// No description provided for @support.
  ///
  /// In en, this message translates to:
  /// **'Support'**
  String get support;

  /// No description provided for @email.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get email;

  /// No description provided for @phone.
  ///
  /// In en, this message translates to:
  /// **'Phone'**
  String get phone;

  /// No description provided for @viewOnlineGuide.
  ///
  /// In en, this message translates to:
  /// **'View Online Guide'**
  String get viewOnlineGuide;

  /// No description provided for @allRightsReserved.
  ///
  /// In en, this message translates to:
  /// **'All Rights Reserved'**
  String get allRightsReserved;

  /// No description provided for @posTitle.
  ///
  /// In en, this message translates to:
  /// **'POS Terminal'**
  String get posTitle;

  /// No description provided for @searchItemHint.
  ///
  /// In en, this message translates to:
  /// **'Search Item / Scan Barcode'**
  String get searchItemHint;

  /// No description provided for @searchCustomerHint.
  ///
  /// In en, this message translates to:
  /// **'Search Customer'**
  String get searchCustomerHint;

  /// No description provided for @walkInCustomer.
  ///
  /// In en, this message translates to:
  /// **'Walk-in'**
  String get walkInCustomer;

  /// No description provided for @cartEmpty.
  ///
  /// In en, this message translates to:
  /// **'Cart Empty'**
  String get cartEmpty;

  /// No description provided for @subtotal.
  ///
  /// In en, this message translates to:
  /// **'Subtotal'**
  String get subtotal;

  /// No description provided for @prevBalance.
  ///
  /// In en, this message translates to:
  /// **'Prev Balance'**
  String get prevBalance;

  /// No description provided for @grandTotal.
  ///
  /// In en, this message translates to:
  /// **'Grand Total'**
  String get grandTotal;

  /// No description provided for @checkoutButton.
  ///
  /// In en, this message translates to:
  /// **'CHECKOUT'**
  String get checkoutButton;

  /// No description provided for @billTotal.
  ///
  /// In en, this message translates to:
  /// **'Bill Total'**
  String get billTotal;

  /// No description provided for @paymentLabel.
  ///
  /// In en, this message translates to:
  /// **'Payment:'**
  String get paymentLabel;

  /// No description provided for @cashInput.
  ///
  /// In en, this message translates to:
  /// **'Cash'**
  String get cashInput;

  /// No description provided for @bankInput.
  ///
  /// In en, this message translates to:
  /// **'Bank Transfer'**
  String get bankInput;

  /// No description provided for @creditInput.
  ///
  /// In en, this message translates to:
  /// **'Credit (Udhar)'**
  String get creditInput;

  /// No description provided for @confirmSale.
  ///
  /// In en, this message translates to:
  /// **'CONFIRM SALE'**
  String get confirmSale;

  /// No description provided for @clearCartTitle.
  ///
  /// In en, this message translates to:
  /// **'Clear Cart?'**
  String get clearCartTitle;

  /// No description provided for @clearCartMsg.
  ///
  /// In en, this message translates to:
  /// **'This will remove all items from cart.'**
  String get clearCartMsg;

  /// No description provided for @clearAll.
  ///
  /// In en, this message translates to:
  /// **'Clear All'**
  String get clearAll;

  /// No description provided for @unsavedTitle.
  ///
  /// In en, this message translates to:
  /// **'Unsaved Items'**
  String get unsavedTitle;

  /// No description provided for @unsavedMsg.
  ///
  /// In en, this message translates to:
  /// **'There are items in cart. Are you sure you want to exit without checkout?'**
  String get unsavedMsg;

  /// No description provided for @exit.
  ///
  /// In en, this message translates to:
  /// **'Exit'**
  String get exit;

  /// No description provided for @addNewCustomer.
  ///
  /// In en, this message translates to:
  /// **'Add New Customer'**
  String get addNewCustomer;

  /// No description provided for @nameEnglish.
  ///
  /// In en, this message translates to:
  /// **'Name (English)*'**
  String get nameEnglish;

  /// No description provided for @nameUrdu.
  ///
  /// In en, this message translates to:
  /// **'Name (Urdu)'**
  String get nameUrdu;

  /// No description provided for @phoneNum.
  ///
  /// In en, this message translates to:
  /// **'Phone Number*'**
  String get phoneNum;

  /// No description provided for @creditLimit.
  ///
  /// In en, this message translates to:
  /// **'Credit Limit'**
  String get creditLimit;

  /// No description provided for @saveSelect.
  ///
  /// In en, this message translates to:
  /// **'Save & Select'**
  String get saveSelect;

  /// No description provided for @qty.
  ///
  /// In en, this message translates to:
  /// **'Qty'**
  String get qty;

  /// No description provided for @currBal.
  ///
  /// In en, this message translates to:
  /// **'Bal'**
  String get currBal;

  /// No description provided for @changeReturn.
  ///
  /// In en, this message translates to:
  /// **'Change Return'**
  String get changeReturn;

  /// No description provided for @insufficientPayment.
  ///
  /// In en, this message translates to:
  /// **'Insufficient payment'**
  String get insufficientPayment;

  /// No description provided for @paymentMatch.
  ///
  /// In en, this message translates to:
  /// **'Payment matches bill total'**
  String get paymentMatch;

  /// No description provided for @deleteBillTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete Bill?'**
  String get deleteBillTitle;

  /// No description provided for @deleteBillMsg.
  ///
  /// In en, this message translates to:
  /// **'This will restore stock and adjust customer balance.'**
  String get deleteBillMsg;

  /// No description provided for @saleCompleted.
  ///
  /// In en, this message translates to:
  /// **'Sale Completed! Bill:'**
  String get saleCompleted;

  /// No description provided for @totalCustomers.
  ///
  /// In en, this message translates to:
  /// **'Total Customers'**
  String get totalCustomers;

  /// No description provided for @nameRequired.
  ///
  /// In en, this message translates to:
  /// **'English Name is required'**
  String get nameRequired;

  /// No description provided for @phoneRequired.
  ///
  /// In en, this message translates to:
  /// **'Phone Number is required'**
  String get phoneRequired;

  /// No description provided for @phoneExists.
  ///
  /// In en, this message translates to:
  /// **'Phone number already exists'**
  String get phoneExists;

  /// No description provided for @customerAdded.
  ///
  /// In en, this message translates to:
  /// **'Customer added successfully'**
  String get customerAdded;

  /// No description provided for @customersManagement.
  ///
  /// In en, this message translates to:
  /// **'Customers Management'**
  String get customersManagement;

  /// No description provided for @receivableTotal.
  ///
  /// In en, this message translates to:
  /// **'Receivable (Total)'**
  String get receivableTotal;

  /// No description provided for @receivableActive.
  ///
  /// In en, this message translates to:
  /// **'Receivable (Active)'**
  String get receivableActive;

  /// No description provided for @receivableArchived.
  ///
  /// In en, this message translates to:
  /// **'Receivable (Archived)'**
  String get receivableArchived;

  /// No description provided for @archived.
  ///
  /// In en, this message translates to:
  /// **'Archived'**
  String get archived;

  /// No description provided for @active.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get active;

  /// No description provided for @history.
  ///
  /// In en, this message translates to:
  /// **'History'**
  String get history;

  /// No description provided for @editCustomer.
  ///
  /// In en, this message translates to:
  /// **'Edit Customer'**
  String get editCustomer;

  /// No description provided for @archiveCustomer.
  ///
  /// In en, this message translates to:
  /// **'Archive Customer'**
  String get archiveCustomer;

  /// No description provided for @restoreCustomer.
  ///
  /// In en, this message translates to:
  /// **'Restore Customer'**
  String get restoreCustomer;

  /// No description provided for @deleteConfirmMsg.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this customer?'**
  String get deleteConfirmMsg;

  /// No description provided for @archiveConfirmMsg.
  ///
  /// In en, this message translates to:
  /// **'This will hide the customer from active lists.'**
  String get archiveConfirmMsg;

  /// No description provided for @customerUpdated.
  ///
  /// In en, this message translates to:
  /// **'Customer updated successfully'**
  String get customerUpdated;

  /// No description provided for @customerDeleted.
  ///
  /// In en, this message translates to:
  /// **'Customer deleted'**
  String get customerDeleted;

  /// No description provided for @customerArchived.
  ///
  /// In en, this message translates to:
  /// **'Customer archived'**
  String get customerArchived;

  /// No description provided for @customerRestored.
  ///
  /// In en, this message translates to:
  /// **'Customer restored'**
  String get customerRestored;

  /// No description provided for @actions.
  ///
  /// In en, this message translates to:
  /// **'Actions'**
  String get actions;

  /// No description provided for @restoreConfirmMsg.
  ///
  /// In en, this message translates to:
  /// **'This will restore the customer to the active list.'**
  String get restoreConfirmMsg;

  /// No description provided for @restoreAction.
  ///
  /// In en, this message translates to:
  /// **'Restore'**
  String get restoreAction;

  /// No description provided for @archiveCustomerTitle.
  ///
  /// In en, this message translates to:
  /// **'Archive Customer?'**
  String get archiveCustomerTitle;

  /// No description provided for @restoreCustomerTitle.
  ///
  /// In en, this message translates to:
  /// **'Restore Customer?'**
  String get restoreCustomerTitle;

  /// No description provided for @customerNameRequired.
  ///
  /// In en, this message translates to:
  /// **'Name (English) is required'**
  String get customerNameRequired;

  /// No description provided for @customerAddedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Customer added successfully'**
  String get customerAddedSuccess;

  /// No description provided for @customerUpdatedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Customer updated successfully'**
  String get customerUpdatedSuccess;

  /// No description provided for @cannotDeleteTitle.
  ///
  /// In en, this message translates to:
  /// **'Cannot Delete Customer'**
  String get cannotDeleteTitle;

  /// No description provided for @deleteWarningSales.
  ///
  /// In en, this message translates to:
  /// **'Has {count} sales records.'**
  String deleteWarningSales(Object count);

  /// No description provided for @deleteWarningBalance.
  ///
  /// In en, this message translates to:
  /// **'Balance is not 0 (RS {balance}) .'**
  String deleteWarningBalance(Object balance);

  /// No description provided for @deleteWarningReason.
  ///
  /// In en, this message translates to:
  /// **'Deleting them would corrupt your financial reports.'**
  String get deleteWarningReason;

  /// No description provided for @deleteWarningArchive.
  ///
  /// In en, this message translates to:
  /// **'Please \'Archive\' them instead.'**
  String get deleteWarningArchive;

  /// No description provided for @deleteCustomerTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete Customer?'**
  String get deleteCustomerTitle;

  /// No description provided for @deleteCustomerWarning.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to permanently delete \'{name}\'?'**
  String deleteCustomerWarning(Object name);

  /// No description provided for @deleteAction.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get deleteAction;

  /// No description provided for @ok.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get ok;

  /// No description provided for @doYouWantTo.
  ///
  /// In en, this message translates to:
  /// **'Do you want to'**
  String get doYouWantTo;

  /// No description provided for @thisCustomer.
  ///
  /// In en, this message translates to:
  /// **'this customer'**
  String get thisCustomer;

  /// No description provided for @willBeArchived.
  ///
  /// In en, this message translates to:
  /// **'will be archived'**
  String get willBeArchived;

  /// No description provided for @archiveAction.
  ///
  /// In en, this message translates to:
  /// **'Archive'**
  String get archiveAction;

  /// No description provided for @customerCard.
  ///
  /// In en, this message translates to:
  /// **'Customer Card ID'**
  String get customerCard;

  /// No description provided for @generateCard.
  ///
  /// In en, this message translates to:
  /// **'Generate ID'**
  String get generateCard;

  /// No description provided for @viewBarcode.
  ///
  /// In en, this message translates to:
  /// **'View/Print Barcode'**
  String get viewBarcode;

  /// No description provided for @cannotDeleteReason.
  ///
  /// In en, this message translates to:
  /// **'Cannot delete customer with existing sales or non-zero balance.'**
  String get cannotDeleteReason;

  /// No description provided for @printReceipt.
  ///
  /// In en, this message translates to:
  /// **'Print Receipt'**
  String get printReceipt;

  /// No description provided for @receiptSentToPrinter.
  ///
  /// In en, this message translates to:
  /// **'Receipt sent to printer'**
  String get receiptSentToPrinter;

  /// No description provided for @printError.
  ///
  /// In en, this message translates to:
  /// **'Print Error'**
  String get printError;

  /// No description provided for @editFeatureComingSoon.
  ///
  /// In en, this message translates to:
  /// **'Edit feature coming soon!'**
  String get editFeatureComingSoon;

  /// No description provided for @cannotPrintCancelled.
  ///
  /// In en, this message translates to:
  /// **'Cannot print cancelled bill.'**
  String get cannotPrintCancelled;

  /// No description provided for @saveAsPdf.
  ///
  /// In en, this message translates to:
  /// **'Save as PDF'**
  String get saveAsPdf;

  /// No description provided for @startNewSale.
  ///
  /// In en, this message translates to:
  /// **'Start New Sale'**
  String get startNewSale;

  /// No description provided for @cancelBillAction.
  ///
  /// In en, this message translates to:
  /// **'Cancel Bill'**
  String get cancelBillAction;

  /// No description provided for @billCancelled.
  ///
  /// In en, this message translates to:
  /// **'Bill cancelled and stock restored.'**
  String get billCancelled;

  /// No description provided for @voided.
  ///
  /// In en, this message translates to:
  /// **'VOIDED'**
  String get voided;

  /// No description provided for @none.
  ///
  /// In en, this message translates to:
  /// **'None'**
  String get none;

  /// No description provided for @printCard.
  ///
  /// In en, this message translates to:
  /// **'Print Card'**
  String get printCard;

  /// No description provided for @customerPhoto.
  ///
  /// In en, this message translates to:
  /// **'Photo'**
  String get customerPhoto;

  /// No description provided for @saveAndPrint.
  ///
  /// In en, this message translates to:
  /// **'Save & Print'**
  String get saveAndPrint;

  /// No description provided for @tapToPick.
  ///
  /// In en, this message translates to:
  /// **'Tap to add photo'**
  String get tapToPick;

  /// No description provided for @camera.
  ///
  /// In en, this message translates to:
  /// **'Camera'**
  String get camera;

  /// No description provided for @gallery.
  ///
  /// In en, this message translates to:
  /// **'Gallery'**
  String get gallery;

  /// No description provided for @adminAccess.
  ///
  /// In en, this message translates to:
  /// **'Admin Access'**
  String get adminAccess;

  /// No description provided for @sale.
  ///
  /// In en, this message translates to:
  /// **'Sale'**
  String get sale;

  /// No description provided for @itemsNeedReordering.
  ///
  /// In en, this message translates to:
  /// **'{count} items need reordering.'**
  String itemsNeedReordering(Object count);

  /// No description provided for @quickActions.
  ///
  /// In en, this message translates to:
  /// **'Quick Actions'**
  String get quickActions;

  /// No description provided for @newSale.
  ///
  /// In en, this message translates to:
  /// **'New Sale'**
  String get newSale;

  /// No description provided for @viewReports.
  ///
  /// In en, this message translates to:
  /// **'View Reports'**
  String get viewReports;

  /// No description provided for @manageStock.
  ///
  /// In en, this message translates to:
  /// **'Manage Stock'**
  String get manageStock;

  /// No description provided for @viewAll.
  ///
  /// In en, this message translates to:
  /// **'View All'**
  String get viewAll;

  /// No description provided for @unknownBill.
  ///
  /// In en, this message translates to:
  /// **'Unknown Bill'**
  String get unknownBill;

  /// No description provided for @copyright.
  ///
  /// In en, this message translates to:
  /// **'© 2024 Liaqat Kiryana Store'**
  String get copyright;

  /// No description provided for @tapToSeeDetails.
  ///
  /// In en, this message translates to:
  /// **'Tap to see details'**
  String get tapToSeeDetails;

  /// No description provided for @loading.
  ///
  /// In en, this message translates to:
  /// **'Loading'**
  String get loading;

  /// No description provided for @mon.
  ///
  /// In en, this message translates to:
  /// **'Monday'**
  String get mon;

  /// No description provided for @tue.
  ///
  /// In en, this message translates to:
  /// **'Tuesday'**
  String get tue;

  /// No description provided for @wed.
  ///
  /// In en, this message translates to:
  /// **'Wednesday'**
  String get wed;

  /// No description provided for @thu.
  ///
  /// In en, this message translates to:
  /// **'Thursday'**
  String get thu;

  /// No description provided for @fri.
  ///
  /// In en, this message translates to:
  /// **'Friday'**
  String get fri;

  /// No description provided for @sat.
  ///
  /// In en, this message translates to:
  /// **'Saturday'**
  String get sat;

  /// No description provided for @sun.
  ///
  /// In en, this message translates to:
  /// **'Sunday'**
  String get sun;

  /// No description provided for @jan.
  ///
  /// In en, this message translates to:
  /// **'January'**
  String get jan;

  /// No description provided for @feb.
  ///
  /// In en, this message translates to:
  /// **'February'**
  String get feb;

  /// No description provided for @mar.
  ///
  /// In en, this message translates to:
  /// **'March'**
  String get mar;

  /// No description provided for @apr.
  ///
  /// In en, this message translates to:
  /// **'April'**
  String get apr;

  /// No description provided for @may.
  ///
  /// In en, this message translates to:
  /// **'May'**
  String get may;

  /// No description provided for @jun.
  ///
  /// In en, this message translates to:
  /// **'June'**
  String get jun;

  /// No description provided for @jul.
  ///
  /// In en, this message translates to:
  /// **'July'**
  String get jul;

  /// No description provided for @aug.
  ///
  /// In en, this message translates to:
  /// **'August'**
  String get aug;

  /// No description provided for @sep.
  ///
  /// In en, this message translates to:
  /// **'September'**
  String get sep;

  /// No description provided for @oct.
  ///
  /// In en, this message translates to:
  /// **'October'**
  String get oct;

  /// No description provided for @nov.
  ///
  /// In en, this message translates to:
  /// **'November'**
  String get nov;

  /// No description provided for @dec.
  ///
  /// In en, this message translates to:
  /// **'December'**
  String get dec;

  /// No description provided for @currentBill.
  ///
  /// In en, this message translates to:
  /// **'Current Bill'**
  String get currentBill;

  /// No description provided for @billSaved.
  ///
  /// In en, this message translates to:
  /// **'Bill Saved Successfully'**
  String get billSaved;

  /// No description provided for @checkout.
  ///
  /// In en, this message translates to:
  /// **'Checkout'**
  String get checkout;

  /// No description provided for @discount.
  ///
  /// In en, this message translates to:
  /// **'Discount'**
  String get discount;

  /// No description provided for @confirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get confirm;

  /// No description provided for @confirmDeleteItem.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this item?'**
  String get confirmDeleteItem;

  /// No description provided for @unknown.
  ///
  /// In en, this message translates to:
  /// **'Unknown'**
  String get unknown;

  /// No description provided for @salesHistoryNote.
  ///
  /// In en, this message translates to:
  /// **'Your sales history will appear here'**
  String get salesHistoryNote;

  /// No description provided for @suppliersManagement.
  ///
  /// In en, this message translates to:
  /// **'Suppliers Management'**
  String get suppliersManagement;

  /// No description provided for @addSupplier.
  ///
  /// In en, this message translates to:
  /// **'Add Supplier'**
  String get addSupplier;

  /// No description provided for @editSupplier.
  ///
  /// In en, this message translates to:
  /// **'Edit Supplier'**
  String get editSupplier;

  /// No description provided for @noSuppliersFound.
  ///
  /// In en, this message translates to:
  /// **'No suppliers found'**
  String get noSuppliersFound;

  /// No description provided for @supplierAdded.
  ///
  /// In en, this message translates to:
  /// **'Supplier added successfully'**
  String get supplierAdded;

  /// No description provided for @supplierUpdated.
  ///
  /// In en, this message translates to:
  /// **'Supplier updated successfully'**
  String get supplierUpdated;

  /// No description provided for @supplierDeleted.
  ///
  /// In en, this message translates to:
  /// **'Supplier deleted successfully'**
  String get supplierDeleted;

  /// No description provided for @confirmDeleteSupplier.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this supplier?'**
  String get confirmDeleteSupplier;

  /// No description provided for @balance.
  ///
  /// In en, this message translates to:
  /// **'Balance'**
  String get balance;

  /// No description provided for @selectDate.
  ///
  /// In en, this message translates to:
  /// **'Select Date'**
  String get selectDate;

  /// No description provided for @thisWeekVsLast.
  ///
  /// In en, this message translates to:
  /// **'This Week vs Last Week'**
  String get thisWeekVsLast;

  /// No description provided for @thisYearVsLast.
  ///
  /// In en, this message translates to:
  /// **'This Year vs Last Year'**
  String get thisYearVsLast;

  /// No description provided for @avgDaily.
  ///
  /// In en, this message translates to:
  /// **'Avg Daily'**
  String get avgDaily;

  /// No description provided for @graphPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'Sales Graph will appear here'**
  String get graphPlaceholder;

  /// No description provided for @printReport.
  ///
  /// In en, this message translates to:
  /// **'Print Report'**
  String get printReport;

  /// No description provided for @date.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get date;

  /// No description provided for @billNo.
  ///
  /// In en, this message translates to:
  /// **'Bill No'**
  String get billNo;

  /// No description provided for @expenseDetails.
  ///
  /// In en, this message translates to:
  /// **'Expenses Details'**
  String get expenseDetails;

  /// No description provided for @purchaseHistoryNote.
  ///
  /// In en, this message translates to:
  /// **'Your purchase history will appear here'**
  String get purchaseHistoryNote;

  /// No description provided for @topCustomersBalance.
  ///
  /// In en, this message translates to:
  /// **'Top Customers Balance'**
  String get topCustomersBalance;

  /// No description provided for @daysOld.
  ///
  /// In en, this message translates to:
  /// **'days old'**
  String get daysOld;

  /// No description provided for @totalStockValue.
  ///
  /// In en, this message translates to:
  /// **'Total Stock Value'**
  String get totalStockValue;

  /// No description provided for @stockByCategory.
  ///
  /// In en, this message translates to:
  /// **'Stock by Category'**
  String get stockByCategory;

  /// No description provided for @small.
  ///
  /// In en, this message translates to:
  /// **'Small'**
  String get small;

  /// No description provided for @medium.
  ///
  /// In en, this message translates to:
  /// **'Medium'**
  String get medium;

  /// No description provided for @large.
  ///
  /// In en, this message translates to:
  /// **'Large'**
  String get large;

  /// No description provided for @daily.
  ///
  /// In en, this message translates to:
  /// **'Daily'**
  String get daily;

  /// No description provided for @weekly.
  ///
  /// In en, this message translates to:
  /// **'Weekly'**
  String get weekly;

  /// No description provided for @monthly.
  ///
  /// In en, this message translates to:
  /// **'Monthly'**
  String get monthly;

  /// No description provided for @printerDefault.
  ///
  /// In en, this message translates to:
  /// **'Default'**
  String get printerDefault;

  /// No description provided for @printerUsb.
  ///
  /// In en, this message translates to:
  /// **'USB Thermal'**
  String get printerUsb;

  /// No description provided for @printerNetwork.
  ///
  /// In en, this message translates to:
  /// **'Network'**
  String get printerNetwork;

  /// No description provided for @printerPdf.
  ///
  /// In en, this message translates to:
  /// **'PDF'**
  String get printerPdf;

  /// No description provided for @paper58.
  ///
  /// In en, this message translates to:
  /// **'58mm'**
  String get paper58;

  /// No description provided for @paper80.
  ///
  /// In en, this message translates to:
  /// **'80mm'**
  String get paper80;

  /// No description provided for @paperA4.
  ///
  /// In en, this message translates to:
  /// **'A4'**
  String get paperA4;

  /// No description provided for @shopNamePlaceholder.
  ///
  /// In en, this message translates to:
  /// **'Liaqat Kiryana Store'**
  String get shopNamePlaceholder;

  /// No description provided for @addressPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'Lahore, Pakistan'**
  String get addressPlaceholder;

  /// No description provided for @bill.
  ///
  /// In en, this message translates to:
  /// **'Bill'**
  String get bill;

  /// No description provided for @deletedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Deleted Successfully'**
  String get deletedSuccessfully;

  /// No description provided for @endOfList.
  ///
  /// In en, this message translates to:
  /// **'End of List'**
  String get endOfList;

  /// No description provided for @noCustomersFound.
  ///
  /// In en, this message translates to:
  /// **'No customers found'**
  String get noCustomersFound;

  /// No description provided for @search.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get search;

  /// No description provided for @errorProcessingSale.
  ///
  /// In en, this message translates to:
  /// **'Error processing sale: {error}'**
  String errorProcessingSale(Object error);

  /// No description provided for @newCashIn.
  ///
  /// In en, this message translates to:
  /// **'New Cash In'**
  String get newCashIn;

  /// No description provided for @newCashOut.
  ///
  /// In en, this message translates to:
  /// **'New Cash Out'**
  String get newCashOut;

  /// No description provided for @description.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get description;

  /// No description provided for @remarks.
  ///
  /// In en, this message translates to:
  /// **'Remarks'**
  String get remarks;

  /// No description provided for @currentBalance.
  ///
  /// In en, this message translates to:
  /// **'Current Balance'**
  String get currentBalance;

  /// No description provided for @noData.
  ///
  /// In en, this message translates to:
  /// **'No Data'**
  String get noData;

  /// No description provided for @cashIn.
  ///
  /// In en, this message translates to:
  /// **'Cash In'**
  String get cashIn;

  /// No description provided for @cashOut.
  ///
  /// In en, this message translates to:
  /// **'Cash Out'**
  String get cashOut;

  /// No description provided for @errorNegativeValues.
  ///
  /// In en, this message translates to:
  /// **'Invalid input: Negative values are not allowed.'**
  String get errorNegativeValues;

  /// No description provided for @cancelSale.
  ///
  /// In en, this message translates to:
  /// **'Cancel Sale'**
  String get cancelSale;

  /// No description provided for @cancelSaleTitle.
  ///
  /// In en, this message translates to:
  /// **'Confirm Sale Cancellation'**
  String get cancelSaleTitle;

  /// No description provided for @cancelSaleMessage.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to cancel this sale?'**
  String get cancelSaleMessage;

  /// No description provided for @cancelSaleWarning.
  ///
  /// In en, this message translates to:
  /// **'This action cannot be undone.'**
  String get cancelSaleWarning;

  /// No description provided for @cancelReasonLabel.
  ///
  /// In en, this message translates to:
  /// **'Cancellation Reason'**
  String get cancelReasonLabel;

  /// No description provided for @saleCancelledSuccess.
  ///
  /// In en, this message translates to:
  /// **'Sale cancelled successfully.'**
  String get saleCancelledSuccess;

  /// No description provided for @saleAlreadyCancelled.
  ///
  /// In en, this message translates to:
  /// **'This sale has already been cancelled.'**
  String get saleAlreadyCancelled;

  /// No description provided for @cancelled.
  ///
  /// In en, this message translates to:
  /// **'Cancelled'**
  String get cancelled;

  /// No description provided for @completed.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get completed;

  /// No description provided for @invalidPrice.
  ///
  /// In en, this message translates to:
  /// **'Price must be greater than zero'**
  String get invalidPrice;

  /// No description provided for @invalidQuantity.
  ///
  /// In en, this message translates to:
  /// **'Quantity must be greater than zero'**
  String get invalidQuantity;

  /// No description provided for @insufficientStock.
  ///
  /// In en, this message translates to:
  /// **'Insufficient stock'**
  String get insufficientStock;

  /// No description provided for @outOfStock.
  ///
  /// In en, this message translates to:
  /// **'Out of stock'**
  String get outOfStock;

  /// No description provided for @productNotFound.
  ///
  /// In en, this message translates to:
  /// **'Product not found'**
  String get productNotFound;

  /// No description provided for @creditLimitExceeded.
  ///
  /// In en, this message translates to:
  /// **'Credit Limit Exceeded'**
  String get creditLimitExceeded;

  /// No description provided for @customerCreditLimit.
  ///
  /// In en, this message translates to:
  /// **'Customer credit limit'**
  String get customerCreditLimit;

  /// No description provided for @creditLimitWarning.
  ///
  /// In en, this message translates to:
  /// **'This sale will exceed the customer\'s credit limit. Please collect payment or increase credit limit.'**
  String get creditLimitWarning;

  /// No description provided for @processingSale.
  ///
  /// In en, this message translates to:
  /// **'Processing sale...'**
  String get processingSale;

  /// No description provided for @exceededBy.
  ///
  /// In en, this message translates to:
  /// **'Exceeded by'**
  String get exceededBy;

  /// No description provided for @increaseLimit.
  ///
  /// In en, this message translates to:
  /// **'Increase Limit'**
  String get increaseLimit;

  /// No description provided for @continueAnyway.
  ///
  /// In en, this message translates to:
  /// **'Continue Anyway'**
  String get continueAnyway;

  /// No description provided for @updateCreditLimit.
  ///
  /// In en, this message translates to:
  /// **'Update Credit Limit'**
  String get updateCreditLimit;

  /// No description provided for @newCreditLimit.
  ///
  /// In en, this message translates to:
  /// **'New Credit Limit'**
  String get newCreditLimit;

  /// No description provided for @suggestedLimit.
  ///
  /// In en, this message translates to:
  /// **'Suggested based on current sale'**
  String get suggestedLimit;

  /// No description provided for @invalidAmount.
  ///
  /// In en, this message translates to:
  /// **'Invalid amount'**
  String get invalidAmount;

  /// No description provided for @creditLimitUpdated.
  ///
  /// In en, this message translates to:
  /// **'Credit limit updated successfully'**
  String get creditLimitUpdated;

  /// No description provided for @creditLimitWarningMsg.
  ///
  /// In en, this message translates to:
  /// **'The current sale exceeds the customer\'s credit limit of {limit}. You can either collect payment now or increase the credit limit.'**
  String creditLimitWarningMsg(Object limit);

  /// No description provided for @excessAmount.
  ///
  /// In en, this message translates to:
  /// **'Excess Amount'**
  String get excessAmount;

  /// No description provided for @increaseCreditLimit.
  ///
  /// In en, this message translates to:
  /// **'Increase Credit Limit'**
  String get increaseCreditLimit;

  /// No description provided for @invalidLimit.
  ///
  /// In en, this message translates to:
  /// **'Invalid limit'**
  String get invalidLimit;

  /// No description provided for @updateLimit.
  ///
  /// In en, this message translates to:
  /// **'Update Limit'**
  String get updateLimit;

  /// No description provided for @savePrint.
  ///
  /// In en, this message translates to:
  /// **'Save & Print'**
  String get savePrint;

  /// No description provided for @changeDue.
  ///
  /// In en, this message translates to:
  /// **'Change Due'**
  String get changeDue;

  /// No description provided for @pendingAmount.
  ///
  /// In en, this message translates to:
  /// **'Pending Credits'**
  String get pendingAmount;

  /// No description provided for @itemsNeedRestock.
  ///
  /// In en, this message translates to:
  /// **'Items need restock'**
  String get itemsNeedRestock;

  /// No description provided for @activeToday.
  ///
  /// In en, this message translates to:
  /// **'Active today'**
  String get activeToday;

  /// No description provided for @cannotDeleteBal.
  ///
  /// In en, this message translates to:
  /// **'Cannot delete customer with outstanding balance'**
  String get cannotDeleteBal;

  /// No description provided for @archivedCustomers.
  ///
  /// In en, this message translates to:
  /// **'Archived Customers'**
  String get archivedCustomers;

  /// No description provided for @warning.
  ///
  /// In en, this message translates to:
  /// **'Warning'**
  String get warning;

  /// No description provided for @dashboardTotal.
  ///
  /// In en, this message translates to:
  /// **'Total'**
  String get dashboardTotal;

  /// No description provided for @dashboardActive.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get dashboardActive;

  /// No description provided for @dashboardArchived.
  ///
  /// In en, this message translates to:
  /// **'Archived'**
  String get dashboardArchived;

  /// No description provided for @balanceShort.
  ///
  /// In en, this message translates to:
  /// **'Bal'**
  String get balanceShort;

  /// No description provided for @searchPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'Search...'**
  String get searchPlaceholder;

  /// No description provided for @searchArchived.
  ///
  /// In en, this message translates to:
  /// **'Search Archived...'**
  String get searchArchived;

  /// No description provided for @addCustomer.
  ///
  /// In en, this message translates to:
  /// **'Add Customer'**
  String get addCustomer;

  /// No description provided for @phoneLabel.
  ///
  /// In en, this message translates to:
  /// **'Phone (Unique)'**
  String get phoneLabel;

  /// No description provided for @addressLabel.
  ///
  /// In en, this message translates to:
  /// **'Address'**
  String get addressLabel;

  /// No description provided for @phoneExistsError.
  ///
  /// In en, this message translates to:
  /// **'Phone number already exists in system'**
  String get phoneExistsError;

  /// No description provided for @archiveNow.
  ///
  /// In en, this message translates to:
  /// **'Archive Now'**
  String get archiveNow;

  /// No description provided for @requiredField.
  ///
  /// In en, this message translates to:
  /// **'is required'**
  String get requiredField;

  /// No description provided for @recentActivities.
  ///
  /// In en, this message translates to:
  /// **'Recent Activities'**
  String get recentActivities;

  /// No description provided for @dashboard.
  ///
  /// In en, this message translates to:
  /// **'Dashboard'**
  String get dashboard;

  /// No description provided for @noActivitiesYet.
  ///
  /// In en, this message translates to:
  /// **'No activities yet'**
  String get noActivitiesYet;

  /// No description provided for @paymentReceived.
  ///
  /// In en, this message translates to:
  /// **'Payment received'**
  String get paymentReceived;

  /// No description provided for @billCreated.
  ///
  /// In en, this message translates to:
  /// **'Bill created'**
  String get billCreated;

  /// No description provided for @newCustomerAdded.
  ///
  /// In en, this message translates to:
  /// **'New customer added'**
  String get newCustomerAdded;

  /// No description provided for @stockUpdated.
  ///
  /// In en, this message translates to:
  /// **'Stock updated'**
  String get stockUpdated;

  /// No description provided for @pendingCredits.
  ///
  /// In en, this message translates to:
  /// **'Pending Credits'**
  String get pendingCredits;

  /// No description provided for @systemOnline.
  ///
  /// In en, this message translates to:
  /// **'System Online'**
  String get systemOnline;

  /// No description provided for @databaseConnected.
  ///
  /// In en, this message translates to:
  /// **'Database: Connected'**
  String get databaseConnected;

  /// No description provided for @systemOk.
  ///
  /// In en, this message translates to:
  /// **'System OK'**
  String get systemOk;

  /// No description provided for @cashSale.
  ///
  /// In en, this message translates to:
  /// **'Cash Sale'**
  String get cashSale;

  /// No description provided for @urgent.
  ///
  /// In en, this message translates to:
  /// **'Urgent'**
  String get urgent;

  /// No description provided for @justNow.
  ///
  /// In en, this message translates to:
  /// **'Just now'**
  String get justNow;

  /// No description provided for @minAgo.
  ///
  /// In en, this message translates to:
  /// **'min ago'**
  String get minAgo;

  /// No description provided for @hrAgo.
  ///
  /// In en, this message translates to:
  /// **'hr ago'**
  String get hrAgo;

  /// No description provided for @daysAgo.
  ///
  /// In en, this message translates to:
  /// **'days ago'**
  String get daysAgo;

  /// No description provided for @onlyLeft.
  ///
  /// In en, this message translates to:
  /// **'Only {count} {unit} left'**
  String onlyLeft(Object count, Object unit);

  /// No description provided for @todaysCustomers.
  ///
  /// In en, this message translates to:
  /// **'Today\'s Customers'**
  String get todaysCustomers;

  /// No description provided for @activityType.
  ///
  /// In en, this message translates to:
  /// **'Activity'**
  String get activityType;

  /// No description provided for @status.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get status;

  /// No description provided for @pending.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get pending;

  /// No description provided for @name.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get name;

  /// No description provided for @noBackupsFound.
  ///
  /// In en, this message translates to:
  /// **'No backups found'**
  String get noBackupsFound;

  /// No description provided for @backupCreated.
  ///
  /// In en, this message translates to:
  /// **'Backup created successfully!'**
  String get backupCreated;

  /// No description provided for @backupFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to create backup'**
  String get backupFailed;

  /// No description provided for @backupDeleted.
  ///
  /// In en, this message translates to:
  /// **'Backup deleted'**
  String get backupDeleted;

  /// No description provided for @deleteFailed.
  ///
  /// In en, this message translates to:
  /// **'Delete failed'**
  String get deleteFailed;

  /// No description provided for @restoreBackup.
  ///
  /// In en, this message translates to:
  /// **'Restore Backup'**
  String get restoreBackup;

  /// No description provided for @deleteBackup.
  ///
  /// In en, this message translates to:
  /// **'Delete Backup'**
  String get deleteBackup;

  /// No description provided for @restoreConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to restore from'**
  String get restoreConfirm;

  /// No description provided for @deleteConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete'**
  String get deleteConfirm;

  /// No description provided for @restoreWarning.
  ///
  /// In en, this message translates to:
  /// **'This will replace your current database.'**
  String get restoreWarning;

  /// No description provided for @restoreSuccess.
  ///
  /// In en, this message translates to:
  /// **'Database restored successfully! App will restart.'**
  String get restoreSuccess;

  /// No description provided for @restoreFailed.
  ///
  /// In en, this message translates to:
  /// **'Restore failed'**
  String get restoreFailed;

  /// No description provided for @usbExportSetup.
  ///
  /// In en, this message translates to:
  /// **'USB export requires additional setup'**
  String get usbExportSetup;

  /// No description provided for @preferencesSaved.
  ///
  /// In en, this message translates to:
  /// **'Preferences saved successfully'**
  String get preferencesSaved;

  /// No description provided for @checkingForUpdates.
  ///
  /// In en, this message translates to:
  /// **'Checking for updates...'**
  String get checkingForUpdates;

  /// No description provided for @never.
  ///
  /// In en, this message translates to:
  /// **'Never'**
  String get never;

  /// No description provided for @refresh.
  ///
  /// In en, this message translates to:
  /// **'Refresh'**
  String get refresh;

  /// No description provided for @saveChangesSuccess.
  ///
  /// In en, this message translates to:
  /// **'Changes saved successfully'**
  String get saveChangesSuccess;

  /// No description provided for @fieldRequired.
  ///
  /// In en, this message translates to:
  /// **'Field is required'**
  String get fieldRequired;

  /// No description provided for @noDataAvailable.
  ///
  /// In en, this message translates to:
  /// **'No Data Available'**
  String get noDataAvailable;

  /// No description provided for @refreshingData.
  ///
  /// In en, this message translates to:
  /// **'Refreshing Data'**
  String get refreshingData;

  /// No description provided for @dbSize.
  ///
  /// In en, this message translates to:
  /// **'Database Size'**
  String get dbSize;

  /// No description provided for @selectPaymentMethod.
  ///
  /// In en, this message translates to:
  /// **'Select Payment Method'**
  String get selectPaymentMethod;

  /// No description provided for @confirmPayment.
  ///
  /// In en, this message translates to:
  /// **'Confirm Payment'**
  String get confirmPayment;

  /// No description provided for @paymentMustEqual.
  ///
  /// In en, this message translates to:
  /// **'Payment must equal'**
  String get paymentMustEqual;

  /// No description provided for @category.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get category;

  /// No description provided for @baseUnit.
  ///
  /// In en, this message translates to:
  /// **'Base Unit'**
  String get baseUnit;

  /// No description provided for @codeInputLabel.
  ///
  /// In en, this message translates to:
  /// **'Code (e.g. BOX)'**
  String get codeInputLabel;

  /// No description provided for @multiplier.
  ///
  /// In en, this message translates to:
  /// **'Multiplier'**
  String get multiplier;

  /// No description provided for @viewUnit.
  ///
  /// In en, this message translates to:
  /// **'View Unit'**
  String get viewUnit;

  /// No description provided for @systemUnitWarning.
  ///
  /// In en, this message translates to:
  /// **'System units cannot be modified.'**
  String get systemUnitWarning;

  /// No description provided for @codeUniqueError.
  ///
  /// In en, this message translates to:
  /// **'Code must be unique'**
  String get codeUniqueError;

  /// No description provided for @numericError.
  ///
  /// In en, this message translates to:
  /// **'Numeric only'**
  String get numericError;

  /// No description provided for @greaterThanOneError.
  ///
  /// In en, this message translates to:
  /// **'Must be > 1'**
  String get greaterThanOneError;

  /// No description provided for @close.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// No description provided for @systemUnit.
  ///
  /// In en, this message translates to:
  /// **'System Unit'**
  String get systemUnit;

  /// No description provided for @categoryLength.
  ///
  /// In en, this message translates to:
  /// **'Length'**
  String get categoryLength;

  /// No description provided for @categoryWeight.
  ///
  /// In en, this message translates to:
  /// **'Weight'**
  String get categoryWeight;

  /// No description provided for @categoryCount.
  ///
  /// In en, this message translates to:
  /// **'Count'**
  String get categoryCount;

  /// No description provided for @packingType.
  ///
  /// In en, this message translates to:
  /// **'Packing Type'**
  String get packingType;

  /// No description provided for @searchTags.
  ///
  /// In en, this message translates to:
  /// **'Search Tags'**
  String get searchTags;

  /// No description provided for @deleteItem.
  ///
  /// In en, this message translates to:
  /// **'Delete Item'**
  String get deleteItem;

  /// No description provided for @all.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get all;

  /// No description provided for @yes.
  ///
  /// In en, this message translates to:
  /// **'Yes'**
  String get yes;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'ur'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'ur':
      return AppLocalizationsUr();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
