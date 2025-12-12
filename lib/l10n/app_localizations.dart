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

  /// No description provided for @totalItems.
  ///
  /// In en, this message translates to:
  /// **'Total Items'**
  String get totalItems;

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

  /// No description provided for @recentSales.
  ///
  /// In en, this message translates to:
  /// **'Recent Sales'**
  String get recentSales;

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

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

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

  /// No description provided for @address.
  ///
  /// In en, this message translates to:
  /// **'Address'**
  String get address;

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

  /// No description provided for @price.
  ///
  /// In en, this message translates to:
  /// **'Price'**
  String get price;

  /// No description provided for @qty.
  ///
  /// In en, this message translates to:
  /// **'Qty'**
  String get qty;

  /// No description provided for @stock.
  ///
  /// In en, this message translates to:
  /// **'Stock'**
  String get stock;

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

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @saleCompleted.
  ///
  /// In en, this message translates to:
  /// **'Sale Completed! Bill:'**
  String get saleCompleted;

  /// No description provided for @error.
  ///
  /// In en, this message translates to:
  /// **'Error'**
  String get error;
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
