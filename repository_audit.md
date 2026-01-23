# Repository Function Audit

## ItemsRepository Functions

#### ✅ Used in UI/BLoC
- `getAllProducts()` - `sales_bloc.dart`, `stock_bloc.dart`, `purchase_bloc.dart`, `items_screen.dart`, `purchase_screen.dart`
- `addProduct()` - `items_screen.dart`
- `updateProduct()` - `items_screen.dart`
- `deleteProduct()` - `items_screen.dart`
- `adjustStock()` - `stock_activity_bloc.dart`
- `searchProducts()` - `items_screen.dart`
- `getLowStockItems()` - `home_screen.dart`

#### 🔵 Internal Use
- `getTotalStockValue()` - Used by `getPotentialProfit`
- `getTotalStockValueAtSalePrice()` - Used by `getPotentialProfit`

#### ❌ Unused
- `getProductById()`
- `getProductByItemCode()`
- `getProductStock()`
- `updateProductStock()`
- `updateAverageCostPrice()`
- `getProductsByCategory()`
- `getOutOfStockItems()`
- `getProductsAboveStock()`
- `getTotalProductsCount()`
- `getPotentialProfit()`
- `getLowStockCount()`
- `getOutOfStockCount()`
- `getProductSalesStats()`
- `getTopSellingProducts()`
- `getSlowMovingProducts()`
- `getProductByBarcode()`
- `updateProductBarcode()`
- `barcodeExists()`
- `updateProductPrices()`
- `getStockAdjustmentsForProduct()`
- `bulkUpdateSalePrices()`

---

## CustomersRepository Functions

#### ✅ Used
- `getActiveCustomers()` - `customers_screen.dart`
- `getCustomerById()` - `sales_bloc.dart`, `customers_screen.dart`
- `addCustomer()` - `customers_screen.dart`, `sales_screen.dart`
- `updateCustomer()` - `customers_screen.dart`
- `deleteCustomer()` - `customers_screen.dart`
- `searchCustomers()` - `sales_bloc.dart`, `customers_screen.dart`, `sales_screen.dart`
- `getArchivedCustomers()` - `customers_screen.dart`
- `isPhoneUnique()` - `customers_screen.dart`
- `updateCustomerCreditLimit()` - `sales_screen.dart`
- `checkCreditLimit()` - `sales_screen.dart`
- `addPayment()` - `customers_screen.dart`
- `getCustomerLedger()` - `customers_screen.dart`
- `getTodayCustomers()` - `home_screen.dart`

#### ❌ Unused
- `getAllCustomers()`
- `getCustomerLedgerGrouped()`
- `updateCustomerBalance()`
- `getCustomerPayments()`
- `getPaymentsByDateRange()`
- `getCustomerSummary()`
- `getCustomersWithBalance()`
- `getCustomersNearLimit()`
- `getTotalCustomerCount()`
- `getActiveCustomerCount()`
- `getTotalOutstandingBalance()`
- `getCustomerStats()`

---

## InvoiceRepository Functions

#### ✅ Used
- `createInvoiceWithTransaction()` - `sales_bloc.dart`
- `cancelInvoice()` - `sales_bloc.dart`, `stock_activity_bloc.dart`, `customers_screen.dart`
- `getInvoiceWithItems()` - `sales_bloc.dart`, `customers_screen.dart`
- `getInvoicesByDateRange()` - `reports_bloc.dart`
- `getRecentInvoicesWithCustomer()` - `sales_bloc.dart`, `home_screen.dart`
- `getTodaySalesTotal()` - `home_screen.dart`
- `validateStock()` - `sales_bloc.dart`

#### ❌ Unused
- `getRecentInvoices()`
- `getInvoicesByCustomer()`
- `deleteInvoice()`
- `updateInvoice()`

---

## SuppliersRepository Functions

#### ✅ Used
- `getSuppliers()` - `stock_filter_bloc.dart`, `purchase_bloc.dart`, `purchase_screen.dart`
- `addSupplier()` - `suppliers_screen.dart`
- `updateSupplier()` - `suppliers_screen.dart`
- `deleteSupplier()` - `suppliers_screen.dart`
- `getSuppliersPaged()` - `suppliers_screen.dart`
- `getInactiveSuppliers()` - `suppliers_screen.dart`
- `addPayment()` - `suppliers_screen.dart`
- `toggleSupplierStatus()` - `suppliers_screen.dart`

#### 🔵 Internal Use
- `getSupplierById()`

#### ❌ Unused
- `searchSuppliers()`
- `getActiveSuppliers()`
- `updateSupplierBalance()`
- `adjustSupplierBalance()`
- `getSuppliersWithBalance()`
- `getTotalOutstandingBalance()`
- `activateSupplier()`
- `deactivateSupplier()`
- `getTotalSupplierCount()`
- `getActiveSupplierCount()`
- `getSupplierSummary()`
- `getSupplierStats()`
- `bulkActivateSuppliers()`
- `bulkDeactivateSuppliers()`
- `bulkDeleteSuppliers()`
- `supplierNameExists()`
- `supplierContactExists()`
- `getSupplierPurchaseHistory()`
- `getSupplierPaymentHistory()`
- `getSupplierLedger()`
- `getBillItems()`

---

## CashRepository Functions

#### ✅ Used
- `getCurrentCashBalance()` - `cash_ledger_screen.dart`
- `addCashEntry()` - `cash_ledger_screen.dart`
- `getCashLedger()` - `cash_ledger_screen.dart`

#### 🔵 Internal Use
- `_moneyFromDb()`
- `getCashLedgerByDateRange()`
- `getCashSummary()`

#### ❌ Unused
- `getCashBalanceAtDate()`
- `addCashIn()`
- `addCashOut()`
- `getTodayCashLedger()`
- `getCashLedgerByType()`
- `searchCashLedger()`
- `getTodayCashSummary()`
- `getThisMonthCashSummary()`
- `getCashFlowTrend()`
- `getTransactionById()`
- `updateCashEntry()`
- `deleteCashEntry()`
- `_recalculateBalancesFrom()`
- `getTotalCashIn()`
- `getTotalCashOut()`
- `getTransactionCount()`
- `getAverageTransactionAmount()`

---

## StockRepository Functions

#### ✅ Used
- `getStockItems()` - `stock_overview_bloc.dart`
- `getStockSummary()` - `stock_overview_bloc.dart`

#### 🔵 Internal Use
- `_mapToEntity()`

#### ❌ Unused
- `getStockItemById()`
- `adjustStockQuantity()`

---

## PurchaseRepository / SupplierPurchaseRepository

#### ✅ Used
- `cancelPurchase()` - `stock_activity_bloc.dart`

#### ❌ Unused
- `createPurchaseWithTransaction()`
- `getPurchaseWithItems()`
- `getRecentPurchases()`
- `getPurchasesBySupplier()`
- `getPurchasesByDateRange()`

---

## SettingsRepository Functions

#### ✅ Used
- `getBackupFiles()` - `settings_screen.dart`
- `createManualBackup()` - `settings_screen.dart`
- `restoreBackup()` - `settings_screen.dart`
- `deleteBackup()` - `settings_screen.dart`
- `getShopProfile()` - `sales_bloc.dart`, `settings_screen.dart`
- `updateShopProfile()` - `settings_screen.dart`
- `getDatabaseSize()` - `settings_screen.dart`
- `vacuumDatabase()` - `settings_screen.dart`
- `getDatabaseStats()` - `settings_screen.dart`

#### 🔵 Internal Use
- `_cleanOldBackups()`

#### ❌ Unused
- `getBackupSize()`
- `getTotalBackupStorage()`
- `exportToCSV()`
- `getCategories()`
- `addCategory()`
- `updateCategory()`
- `deleteCategory()`
- `getExpenseCategories()`
- `addExpenseCategory()`
- `getAppPreferences()`
- `updateAppPreferences()`
