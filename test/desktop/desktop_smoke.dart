// A single entry point avoids rebuilding one Windows harness per feature.
// Each registered test still owns a disposable database and memory credentials.
import 'desktop_startup.dart' as startup;
import 'desktop_workflows.dart' as workflows;
import 'desktop_keyboard.dart' as keyboard;
import 'desktop_purchase.dart' as purchases;
import 'desktop_accounts_stock.dart' as accounts_stock;
import 'desktop_account_crud.dart' as account_crud;
import 'desktop_product_crud.dart' as products;
import 'desktop_receipt.dart' as receipts;
import 'desktop_sales_visual.dart' as sales_visuals;

import 'desktop_remaining_visual.dart' as remaining_visuals;
import 'desktop_taxonomy_units.dart' as taxonomy_units;

void main() {
  startup.main();
  workflows.main();
  keyboard.main();
  purchases.main();
  accounts_stock.main();
  account_crud.main();
  products.main();
  receipts.main();
  sales_visuals.main();
  remaining_visuals.main();
  taxonomy_units.main();
}
