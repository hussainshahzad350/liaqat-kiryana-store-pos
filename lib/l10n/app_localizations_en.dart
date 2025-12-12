// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get posTitle => 'POS Terminal';

  @override
  String get searchItemHint => 'Search Item / Scan Barcode';

  @override
  String get searchCustomerHint => 'Search Customer';

  @override
  String get walkInCustomer => 'Walk-in';

  @override
  String get cartEmpty => 'Cart Empty';

  @override
  String get totalItems => 'Total Items';

  @override
  String get subtotal => 'Subtotal';

  @override
  String get prevBalance => 'Prev Balance';

  @override
  String get grandTotal => 'Grand Total';

  @override
  String get checkoutButton => 'CHECKOUT';

  @override
  String get recentSales => 'Recent Sales';

  @override
  String get billTotal => 'Bill Total';

  @override
  String get paymentLabel => 'Payment:';

  @override
  String get cashInput => 'Cash';

  @override
  String get bankInput => 'Bank Transfer';

  @override
  String get creditInput => 'Credit (Udhar)';

  @override
  String get confirmSale => 'CONFIRM SALE';

  @override
  String get cancel => 'Cancel';

  @override
  String get clearCartTitle => 'Clear Cart?';

  @override
  String get clearCartMsg => 'This will remove all items from cart.';

  @override
  String get clearAll => 'Clear All';

  @override
  String get unsavedTitle => 'Unsaved Items';

  @override
  String get unsavedMsg =>
      'There are items in cart. Are you sure you want to exit without checkout?';

  @override
  String get exit => 'Exit';

  @override
  String get addNewCustomer => 'Add New Customer';

  @override
  String get nameEnglish => 'Name (English)*';

  @override
  String get nameUrdu => 'Name (Urdu)';

  @override
  String get phoneNum => 'Phone Number*';

  @override
  String get address => 'Address';

  @override
  String get creditLimit => 'Credit Limit';

  @override
  String get saveSelect => 'Save & Select';

  @override
  String get price => 'Price';

  @override
  String get qty => 'Qty';

  @override
  String get stock => 'Stock';

  @override
  String get currBal => 'Bal';

  @override
  String get changeReturn => 'Change Return';

  @override
  String get insufficientPayment => 'Insufficient payment';

  @override
  String get paymentMatch => 'Payment matches bill total';

  @override
  String get deleteBillTitle => 'Delete Bill?';

  @override
  String get deleteBillMsg =>
      'This will restore stock and adjust customer balance.';

  @override
  String get delete => 'Delete';

  @override
  String get saleCompleted => 'Sale Completed! Bill:';

  @override
  String get error => 'Error';
}
