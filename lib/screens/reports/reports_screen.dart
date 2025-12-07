import 'package:flutter/material.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> with SingleTickerProviderStateMixin {
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
        title: const Text('رپورٹس'),
        backgroundColor: Colors.purple[700],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: const [
            Tab(icon: Icon(Icons.shopping_bag), text: 'فروخت'),
            Tab(icon: Icon(Icons.trending_up), text: 'منافع'),
            Tab(icon: Icon(Icons.shopping_cart), text: 'خریداری'),
            Tab(icon: Icon(Icons.people), text: 'کسٹمر بیلنس'),
            Tab(icon: Icon(Icons.inventory), text: 'اسٹاک'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          SalesReportTab(),
          ProfitReportTab(),
          PurchaseReportTab(),
          CustomerReportTab(),
          StockReportTab(),
        ],
      ),
    );
  }
}

// ==================== Sales Report Tab ====================
class SalesReportTab extends StatelessWidget {
  const SalesReportTab({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Date Range Selector
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'تاریخ کا انتخاب',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          decoration: const InputDecoration(
                            labelText: 'شروع تاریخ',
                            suffixIcon: Icon(Icons.calendar_today),
                          ),
                          onTap: () {
                            // Date picker
                          },
                        ),
                      ),
                      const SizedBox(width: 10),
                      const Text('سے', style: TextStyle(fontSize: 18)),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextField(
                          decoration: const InputDecoration(
                            labelText: 'اختتام تاریخ',
                            suffixIcon: Icon(Icons.calendar_today),
                          ),
                          onTap: () {
                            // Date picker
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField(
                          decoration: const InputDecoration(
                            labelText: 'مقابلہ',
                          ),
                          items: [
                            'اس مہینہ بمقابلہ پچھلے مہینہ',
                            'اس ہفتہ بمقابلہ پچھلے ہفتہ',
                            'اس سال بمقابلہ پچھلے سال',
                          ].map((item) {
                            return DropdownMenuItem(
                              value: item,
                              child: Text(item),
                            );
                          }).toList(),
                          onChanged: (value) {},
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 20),

          // Summary Cards
          const Row(
            children: [
              Expanded(
                child: SummaryCard(
                  title: 'کل فروخت',
                  value: 'Rs 154,200',
                  color: Colors.green,
                  icon: Icons.currency_rupee,
                ),
              ),
              SizedBox(width: 10),
              Expanded(
                child: SummaryCard(
                  title: 'اوسط روزانہ',
                  value: 'Rs 5,140',
                  color: Colors.blue,
                  icon: Icons.trending_up,
                ),
              ),
              SizedBox(width: 10),
              Expanded(
                child: SummaryCard(
                  title: 'کل بل',
                  value: '245',
                  color: Colors.orange,
                  icon: Icons.receipt,
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Sales Chart
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'فروخت کا گراف',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    height: 200,
                    color: Colors.grey[100],
                    child: const Center(
                      child: Text(
                        'یہاں فروخت کا گراف آئے گا',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 20),

          // Sales Table
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Text(
                        'تفصیلی فروخت',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.download),
                        onPressed: () {},
                        tooltip: 'ڈاؤنلوڈ کریں',
                      ),
                      IconButton(
                        icon: const Icon(Icons.print),
                        onPressed: () {},
                        tooltip: 'پرنٹ کریں',
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: DataTable(
                      columns: const [
                        DataColumn(label: Text('تاریخ')),
                        DataColumn(label: Text('بل نمبر')),
                        DataColumn(label: Text('کسٹمر')),
                        DataColumn(label: Text('کل')),
                        DataColumn(label: Text('کیش')),
                        DataColumn(label: Text('بینک')),
                        DataColumn(label: Text('کریڈٹ')),
                      ],
                      rows: const [
                        DataRow(cells: [
                          DataCell(Text('01 Dec')),
                          DataCell(Text('#2451')),
                          DataCell(Text('علی خان')),
                          DataCell(Text('Rs 5,200')),
                          DataCell(Text('Rs 3,200')),
                          DataCell(Text('Rs 1,000')),
                          DataCell(Text('Rs 1,000')),
                        ]),
                        DataRow(cells: [
                          DataCell(Text('30 Nov')),
                          DataCell(Text('#2450')),
                          DataCell(Text('کیش')),
                          DataCell(Text('Rs 3,800')),
                          DataCell(Text('Rs 3,800')),
                          DataCell(Text('Rs 0')),
                          DataCell(Text('Rs 0')),
                        ]),
                        DataRow(cells: [
                          DataCell(Text('29 Nov')),
                          DataCell(Text('#2449')),
                          DataCell(Text('سامی')),
                          DataCell(Text('Rs 4,500')),
                          DataCell(Text('Rs 2,500')),
                          DataCell(Text('Rs 1,000')),
                          DataCell(Text('Rs 1,000')),
                        ]),
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

// ==================== Profit Report Tab ====================
class ProfitReportTab extends StatelessWidget {
  const ProfitReportTab({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Profit Summary
          const Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                children: [
                  Text(
                    'منافع کا خلاصہ',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: ProfitCard(
                          title: 'کل فروخت',
                          value: 'Rs 154,200',
                          color: Colors.green,
                        ),
                      ),
                      SizedBox(width: 10),
                      Expanded(
                        child: ProfitCard(
                          title: 'کل لاگت',
                          value: 'Rs 120,000',
                          color: Colors.red,
                        ),
                      ),
                      SizedBox(width: 10),
                      Expanded(
                        child: ProfitCard(
                          title: 'خالص منافع',
                          value: 'Rs 34,200',
                          color: Colors.blue,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: ProfitCard(
                          title: 'منافع فیصد',
                          value: '22.2%',
                          color: Colors.purple,
                        ),
                      ),
                      SizedBox(width: 10),
                      Expanded(
                        child: ProfitCard(
                          title: 'اوسط منافع فی بل',
                          value: 'Rs 140',
                          color: Colors.orange,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 20),

          // Expenses Breakdown
          const Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'اخراجات کی تفصیل',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  SizedBox(height: 10),
                  ExpenseItem(name: 'خریداری لاگت', amount: 'Rs 120,000', percentage: '78%'),
                  ExpenseItem(name: 'ٹرانسپورٹ', amount: 'Rs 5,000', percentage: '3.2%'),
                  ExpenseItem(name: 'مزدوری', amount: 'Rs 3,000', percentage: '1.9%'),
                  ExpenseItem(name: 'دیگر اخراجات', amount: 'Rs 2,000', percentage: '1.3%'),
                  SizedBox(height: 10),
                  Divider(),
                  ExpenseItem(name: 'کل اخراجات', amount: 'Rs 130,000', percentage: '84.4%'),
                ],
              ),
            ),
          ),

          const SizedBox(height: 20),

          // Monthly Profit Chart
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'ماہانہ منافع',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    height: 150,
                    color: Colors.grey[100],
                    child: const Center(
                      child: Text(
                        'ماہانہ منافع کا گراف',
                        style: TextStyle(color: Colors.grey),
                      ),
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

// ==================== Purchase Report Tab ====================
class PurchaseReportTab extends StatelessWidget {
  const PurchaseReportTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.shopping_cart,
            size: 100,
            color: Colors.blue,
          ),
          const SizedBox(height: 20),
          const Text(
            'خریداری رپورٹ',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          const Text(
            'یہاں آپ کی تمام خریداری نظر آئے گی',
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 30),
          ElevatedButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.download),
            label: const Text('رپورٹ ڈاؤنلوڈ کریں'),
          ),
        ],
      ),
    );
  }
}

// ==================== Customer Report Tab ====================
class CustomerReportTab extends StatelessWidget {
  const CustomerReportTab({super.key});

  @override
  Widget build(BuildContext context) {
    return const SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        children: [
          // Outstanding Summary
          Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                children: [
                  Text(
                    'کسٹمر بیلنس کا خلاصہ',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: SummaryCard(
                          title: 'کل بیلنس',
                          value: 'Rs 45,200',
                          color: Colors.red,
                          icon: Icons.money_off,
                        ),
                      ),
                      SizedBox(width: 10),
                      Expanded(
                        child: SummaryCard(
                          title: 'کسٹمرز',
                          value: '24',
                          color: Colors.blue,
                          icon: Icons.people,
                        ),
                      ),
                      SizedBox(width: 10),
                      Expanded(
                        child: SummaryCard(
                          title: 'اوسط بیلنس',
                          value: 'Rs 1,883',
                          color: Colors.orange,
                          icon: Icons.calculate,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          SizedBox(height: 20),

          // Aging Analysis
          Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'بیلنس ایجنگ',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  SizedBox(height: 10),
                  AgingItem(days: '0-30 دن', amount: 'Rs 25,000', color: Colors.green),
                  AgingItem(days: '31-60 دن', amount: 'Rs 12,000', color: Colors.yellow),
                  AgingItem(days: '61-90 دن', amount: 'Rs 5,200', color: Colors.orange),
                  AgingItem(days: '90+ دن', amount: 'Rs 3,000', color: Colors.red),
                  SizedBox(height: 10),
                  Divider(),
                  AgingItem(days: 'کل', amount: 'Rs 45,200', color: Colors.blue),
                ],
              ),
            ),
          ),

          SizedBox(height: 20),

          // Top Customers
          Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'سب سے زیادہ بیلنس والے کسٹمرز',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  SizedBox(height: 10),
                  CustomerBalanceItem(
                    name: 'علی خان',
                    balance: 'Rs 12,500',
                    phone: '0300-1111111',
                    days: '15 دن',
                  ),
                  CustomerBalanceItem(
                    name: 'سامی احمد',
                    balance: 'Rs 8,200',
                    phone: '0321-2222222',
                    days: '8 دن',
                  ),
                  CustomerBalanceItem(
                    name: 'رحیم ڈیپو',
                    balance: 'Rs 6,500',
                    phone: '0333-3333333',
                    days: '25 دن',
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

// ==================== Stock Report Tab ====================
class StockReportTab extends StatelessWidget {
  const StockReportTab({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Stock Value Summary
          const Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                children: [
                  Text(
                    'اسٹاک ویلیو کا خلاصہ',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: SummaryCard(
                          title: 'کل اسٹاک ویلیو',
                          value: 'Rs 450,000',
                          color: Colors.green,
                          icon: Icons.warehouse,
                        ),
                      ),
                      SizedBox(width: 10),
                      Expanded(
                        child: SummaryCard(
                          title: 'کل آئٹمز',
                          value: '145',
                          color: Colors.blue,
                          icon: Icons.inventory,
                        ),
                      ),
                      SizedBox(width: 10),
                      Expanded(
                        child: SummaryCard(
                          title: 'اوسط قیمت',
                          value: 'Rs 3,103',
                          color: Colors.orange,
                          icon: Icons.calculate,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 20),

          // Category-wise Stock
          const Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'کیٹیگری کے لحاظ سے اسٹاک',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  SizedBox(height: 10),
                  StockCategoryItem(
                    category: 'چاول',
                    value: 'Rs 150,000',
                    items: '12',
                    percentage: '33%',
                  ),
                  StockCategoryItem(
                    category: 'دالیں',
                    value: 'Rs 85,000',
                    items: '18',
                    percentage: '19%',
                  ),
                  StockCategoryItem(
                    category: 'تیل اور گھی',
                    value: 'Rs 75,000',
                    items: '8',
                    percentage: '17%',
                  ),
                  StockCategoryItem(
                    category: 'مصالحے',
                    value: 'Rs 65,000',
                    items: '25',
                    percentage: '14%',
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 20),

          // Low Stock Items
          Card(
            color: Colors.red[50],
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.warning, color: Colors.red),
                      const SizedBox(width: 8),
                      const Text(
                        'کم اسٹاک آئٹمز',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Colors.red,
                        ),
                      ),
                      const Spacer(),
                      ElevatedButton(
                        onPressed: () {},
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                        child: const Text('مکمل رپورٹ'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  const LowStockItem(
                    name: 'چاول',
                    current: '5 KG',
                    min: '50 KG',
                    difference: '-45 KG',
                  ),
                  const LowStockItem(
                    name: 'چینی',
                    current: '8 KG',
                    min: '30 KG',
                    difference: '-22 KG',
                  ),
                  const LowStockItem(
                    name: 'تیل',
                    current: '3 لیٹر',
                    min: '20 لیٹر',
                    difference: '-17 لیٹر',
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

// ==================== Helper Widgets ====================

class SummaryCard extends StatelessWidget {
  final String title;
  final String value;
  final Color color;
  final IconData icon;

  const SummaryCard({
    super.key,
    required this.title,
    required this.value,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}

class ProfitCard extends StatelessWidget {
  final String title;
  final String value;
  final Color color;

  const ProfitCard({
    super.key,
    required this.title,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: color.withOpacity(0.1),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Text(
              value,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: const TextStyle(fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}

class ExpenseItem extends StatelessWidget {
  final String name;
  final String amount;
  final String percentage;

  const ExpenseItem({
    super.key,
    required this.name,
    required this.amount,
    required this.percentage,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: Text(name),
          ),
          Text(amount),
          const SizedBox(width: 20),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(percentage),
          ),
        ],
      ),
    );
  }
}

class AgingItem extends StatelessWidget {
  final String days;
  final String amount;
  final Color color;

  const AgingItem({
    super.key,
    required this.days,
    required this.amount,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(days),
          ),
          Text(
            amount,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}

class CustomerBalanceItem extends StatelessWidget {
  final String name;
  final String balance;
  final String phone;
  final String days;

  const CustomerBalanceItem({
    super.key,
    required this.name,
    required this.balance,
    required this.phone,
    required this.days,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Center(
                child: Icon(Icons.person, color: Colors.red, size: 20),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    phone,
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  balance,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.red,
                  ),
                ),
                Text(
                  '$days پرانا',
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class StockCategoryItem extends StatelessWidget {
  final String category;
  final String value;
  final String items;
  final String percentage;

  const StockCategoryItem({
    super.key,
    required this.category,
    required this.value,
    required this.items,
    required this.percentage,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: Text(category),
          ),
          Text('$items آئٹمز'),
          const SizedBox(width: 20),
          Text(value),
          const SizedBox(width: 20),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(percentage),
          ),
        ],
      ),
    );
  }
}

class LowStockItem extends StatelessWidget {
  final String name;
  final String current;
  final String min;
  final String difference;

  const LowStockItem({
    super.key,
    required this.name,
    required this.current,
    required this.min,
    required this.difference,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            const Icon(Icons.warning, size: 16, color: Colors.red),
            const SizedBox(width: 8),
            Expanded(
              child: Text(name),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text('موجودہ: $current'),
                Text('ضرورت: $min'),
              ],
            ),
            const SizedBox(width: 12),
            Text(
              difference,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.red,
              ),
            ),
          ],
        ),
      ),
    );
  }
}