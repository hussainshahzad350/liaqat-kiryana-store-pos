import 'package:flutter/material.dart';

class StockScreen extends StatefulWidget {
  const StockScreen({super.key});

  @override
  State<StockScreen> createState() => _StockScreenState();
}

class _StockScreenState extends State<StockScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
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
        title: const Text('اسٹاک مينيجمنٹ'),
        backgroundColor: Colors.green[700],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(
              icon: Icon(Icons.shopping_cart),
              text: 'خریداری',
            ),
            Tab(
              icon: Icon(Icons.remove_shopping_cart),
              text: 'فروخت',
            ),
            Tab(
              icon: Icon(Icons.inventory),
              text: 'اسٹاک ویو',
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          PurchaseTab(),
          SalesTab(),
          StockViewTab(),
        ],
      ),
    );
  }
}

// ==================== Purchase Tab ====================
class PurchaseTab extends StatelessWidget {
  const PurchaseTab({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'نئی خریداری',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          
          // Supplier Selection
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('سپلائر منتخب کریں'),
                  const SizedBox(height: 10),
                  DropdownButtonFormField(
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      hintText: 'سپلائر چنیں',
                    ),
                    items: [
                      'علی ٹریڈرز',
                      'سامی اسٹور',
                      'رحیم مارٹ',
                    ].map((supplier) {
                      return DropdownMenuItem(
                        value: supplier,
                        child: Text(supplier),
                      );
                    }).toList(),
                    onChanged: (value) {},
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 20),
          
          // Items List
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Text(
                        'آئٹمز',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const Spacer(),
                      ElevatedButton.icon(
                        icon: const Icon(Icons.add),
                        label: const Text('آئٹم شامل کریں'),
                        onPressed: () {},
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  const Divider(),
                  
                  // Items Table
                  Table(
                    children: const [
                      TableRow(
                        decoration: BoxDecoration(color: Colors.grey),
                        children: [
                          Padding(
                            padding: EdgeInsets.all(8),
                            child: Text('آئٹم', style: TextStyle(fontWeight: FontWeight.bold)),
                          ),
                          Padding(
                            padding: EdgeInsets.all(8),
                            child: Text('مقدار', style: TextStyle(fontWeight: FontWeight.bold)),
                          ),
                          Padding(
                            padding: EdgeInsets.all(8),
                            child: Text('قیمت', style: TextStyle(fontWeight: FontWeight.bold)),
                          ),
                          Padding(
                            padding: EdgeInsets.all(8),
                            child: Text('کل', style: TextStyle(fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 20),
          
          // Additional Charges
          const Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'اضافی اخراجات',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          decoration: InputDecoration(
                            labelText: 'ٹرانسپورٹ',
                            prefixText: 'Rs ',
                          ),
                          keyboardType: TextInputType.number,
                        ),
                      ),
                      SizedBox(width: 10),
                      Expanded(
                        child: TextField(
                          decoration: InputDecoration(
                            labelText: 'مزدوری',
                            prefixText: 'Rs ',
                          ),
                          keyboardType: TextInputType.number,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 30),
          
          // Save Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {},
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: Colors.green[700],
              ),
              child: const Text(
                'خریداری محفوظ کریں',
                style: TextStyle(fontSize: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ==================== Sales Tab ====================
class SalesTab extends StatelessWidget {
  const SalesTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.shopping_bag,
            size: 100,
            color: Colors.blue,
          ),
          const SizedBox(height: 20),
          const Text(
            'فروخت کا ریکارڈ',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          const Text(
            'یہاں آپ کی تمام فروخت نظر آئے گی',
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 30),
          ElevatedButton(
            onPressed: () {
              Navigator.pushNamed(context, '/sales');
            },
            child: const Text('نئی فروخت کریں'),
          ),
        ],
      ),
    );
  }
}

// ==================== Stock View Tab ====================
class StockViewTab extends StatelessWidget {
  const StockViewTab({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Search and Filter
          Row(
            children: [
              Expanded(
                child: TextField(
                  decoration: InputDecoration(
                    labelText: 'اسٹاک تلاش کریں',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              IconButton(
                icon: const Icon(Icons.filter_list),
                onPressed: () {},
              ),
              IconButton(
                icon: const Icon(Icons.print),
                onPressed: () {},
              ),
            ],
          ),
          
          const SizedBox(height: 20),
          
          // Stock Summary
          Row(
            children: [
              Expanded(
                child: Card(
                  color: Colors.green[50],
                  child: const Padding(
                    padding: EdgeInsets.all(16),
                    child: Column(
                      children: [
                        Text(
                          'کل آئٹمز',
                          style: TextStyle(color: Colors.green),
                        ),
                        SizedBox(height: 5),
                        Text(
                          '145',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Card(
                  color: Colors.blue[50],
                  child: const Padding(
                    padding: EdgeInsets.all(16),
                    child: Column(
                      children: [
                        Text(
                          'اسٹاک ویلیو',
                          style: TextStyle(color: Colors.blue),
                        ),
                        SizedBox(height: 5),
                        Text(
                          'Rs 450,000',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 20),
          
          // Stock Table
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'اسٹاک کی تفصیل',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: DataTable(
                      columns: const [
                        DataColumn(label: Text('آئٹم')),
                        DataColumn(label: Text('موجوده')),
                        DataColumn(label: Text('یونٹ')),
                        DataColumn(label: Text('قیمت')),
                        DataColumn(label: Text('کل')),
                        DataColumn(label: Text('عمل')),
                      ],
                      rows: [
                        DataRow(cells: [
                          const DataCell(Text('چاول')),
                          const DataCell(Text('50 KG')),
                          const DataCell(Text('KG')),
                          const DataCell(Text('Rs 180')),
                          const DataCell(Text('Rs 9,000')),
                          DataCell(IconButton(
                            icon: const Icon(Icons.edit, size: 18),
                            onPressed: () {},
                          )),
                        ]),
                        DataRow(cells: [
                          const DataCell(Text('چینی')),
                          const DataCell(Text('30 KG')),
                          const DataCell(Text('KG')),
                          const DataCell(Text('Rs 120')),
                          const DataCell(Text('Rs 3,600')),
                          DataCell(IconButton(
                            icon: const Icon(Icons.edit, size: 18),
                            onPressed: () {},
                          )),
                        ]),
                        DataRow(cells: [
                          const DataCell(Text('تیل')),
                          const DataCell(Text('20 لیٹر')),
                          const DataCell(Text('لیٹر')),
                          const DataCell(Text('Rs 320')),
                          const DataCell(Text('Rs 6,400')),
                          DataCell(IconButton(
                            icon: const Icon(Icons.edit, size: 18),
                            onPressed: () {},
                          )),
                        ]),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 20),
          
          // Action Buttons
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.add),
                  label: const Text('اسٹاک ایڈجسٹ کریں'),
                  onPressed: () {},
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.download),
                  label: const Text('رپورٹ ڈاؤنلوڈ کریں'),
                  onPressed: () {},
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}