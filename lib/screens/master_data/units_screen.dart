import 'package:flutter/material.dart';

class UnitsScreen extends StatefulWidget {
  const UnitsScreen({super.key});

  @override
  State<UnitsScreen> createState() => _UnitsScreenState();
}

class _UnitsScreenState extends State<UnitsScreen> {
  List<Map<String, dynamic>> units = [
    {
      'id': 1,
      'name_english': 'Kilogram',
      'name_urdu': 'کلوگرام',
      'unit_type': 'Weight',
      'is_base_unit': true,
      'conversion_factor': 1.0,
      'base_unit': null,
    },
    {
      'id': 2,
      'name_english': 'Gram',
      'name_urdu': 'گرام',
      'unit_type': 'Weight',
      'is_base_unit': false,
      'conversion_factor': 0.001,
      'base_unit': 'Kilogram',
    },
    {
      'id': 3,
      'name_english': 'Piece',
      'name_urdu': 'ٹکڑا',
      'unit_type': 'Count',
      'is_base_unit': true,
      'conversion_factor': 1.0,
      'base_unit': null,
    },
    {
      'id': 4,
      'name_english': 'Dozen',
      'name_urdu': 'درجن',
      'unit_type': 'Count',
      'is_base_unit': false,
      'conversion_factor': 12.0,
      'base_unit': 'Piece',
    },
    {
      'id': 5,
      'name_english': 'Liter',
      'name_urdu': 'لیٹر',
      'unit_type': 'Volume',
      'is_base_unit': true,
      'conversion_factor': 1.0,
      'base_unit': null,
    },
    {
      'id': 6,
      'name_english': 'Milliliter',
      'name_urdu': 'ملی لیٹر',
      'unit_type': 'Volume',
      'is_base_unit': false,
      'conversion_factor': 0.001,
      'base_unit': 'Liter',
    },
    {
      'id': 7,
      'name_english': 'Bag',
      'name_urdu': 'بوری',
      'unit_type': 'Weight',
      'is_base_unit': false,
      'conversion_factor': 50.0,
      'base_unit': 'Kilogram',
    },
    {
      'id': 8,
      'name_english': 'Carton',
      'name_urdu': 'کارٹن',
      'unit_type': 'Count',
      'is_base_unit': false,
      'conversion_factor': 24.0,
      'base_unit': 'Piece',
    },
  ];

  String _selectedUnitType = 'All';
  final List<String> _unitTypes = ['All', 'Weight', 'Volume', 'Count'];

  @override
  Widget build(BuildContext context) {
    final filteredUnits = _selectedUnitType == 'All'
        ? units
        : units.where((unit) => unit['unit_type'] == _selectedUnitType).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('یونٹس مينيجمنٹ'),
        backgroundColor: Colors.indigo[700],
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _showAddUnitDialog,
            tooltip: 'نیا یونٹ',
          ),
        ],
      ),
      body: Column(
        children: [
          // Filter and Stats Row
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Unit Type Filter
                Expanded(
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      child: DropdownButton<String>(
                        value: _selectedUnitType,
                        isExpanded: true,
                        items: _unitTypes.map((type) {
                          return DropdownMenuItem(
                            value: type,
                            child: Text(type == 'All' ? 'تمام یونٹس' : type),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedUnitType = value!;
                          });
                        },
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                // Stats Card
                Card(
                  color: Colors.indigo[50],
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      children: [
                        const Text(
                          'کل یونٹس',
                          style: TextStyle(fontSize: 12, color: Colors.indigo),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          filteredUnits.length.toString(),
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.indigo,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Units Table
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Card(
                child: Column(
                  children: [
                    // Table Header
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.indigo[50],
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(8),
                          topRight: Radius.circular(8),
                        ),
                      ),
                      child: const Row(
                        children: [
                          Expanded(
                            flex: 2,
                            child: Text(
                              'یونٹ',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                          Expanded(
                            child: Text(
                              'قسم',
                              style: TextStyle(fontWeight: FontWeight.bold),
                              textAlign: TextAlign.center,
                            ),
                          ),
                          Expanded(
                            child: Text(
                              'بنیادی یونٹ',
                              style: TextStyle(fontWeight: FontWeight.bold),
                              textAlign: TextAlign.center,
                            ),
                          ),
                          Expanded(
                            child: Text(
                              'تبدیلی',
                              style: TextStyle(fontWeight: FontWeight.bold),
                              textAlign: TextAlign.center,
                            ),
                          ),
                          SizedBox(width: 60), // For action buttons
                        ],
                      ),
                    ),

                    // Units List
                    Expanded(
                      child: filteredUnits.isEmpty
                          ? const Center(
                              child: Text(
                                'کوئی یونٹ نہيں ملا',
                                style: TextStyle(color: Colors.grey),
                              ),
                            )
                          : ListView.builder(
                              itemCount: filteredUnits.length,
                              itemBuilder: (context, index) {
                                final unit = filteredUnits[index];
                                return Container(
                                  decoration: BoxDecoration(
                                    border: Border(
                                      bottom: BorderSide(
                                        color: Colors.grey[200]!,
                                        width: 1,
                                      ),
                                    ),
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                    child: Row(
                                      children: [
                                        // Unit Name
                                        Expanded(
                                          flex: 2,
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                unit['name_urdu'],
                                                style: const TextStyle(fontWeight: FontWeight.w500),
                                              ),
                                              Text(
                                                unit['name_english'],
                                                style: const TextStyle(fontSize: 12, color: Colors.grey),
                                              ),
                                            ],
                                          ),
                                        ),

                                        // Unit Type
                                        Expanded(
                                          child: Center(
                                            child: Chip(
                                              label: Text(unit['unit_type']),
                                              backgroundColor: _getTypeColor(unit['unit_type']),
                                              labelStyle: const TextStyle(fontSize: 11, color: Colors.white),
                                            ),
                                          ),
                                        ),

                                        // Base Unit
                                        Expanded(
                                          child: Center(
                                            child: unit['is_base_unit']
                                                ? const Chip(
                                                    label: Text('بنیادی'),
                                                    backgroundColor: Colors.green,
                                                    labelStyle: TextStyle(fontSize: 11, color: Colors.white),
                                                  )
                                                : Text(
                                                    unit['base_unit'] ?? 'N/A',
                                                    style: const TextStyle(fontSize: 12),
                                                    textAlign: TextAlign.center,
                                                  ),
                                          ),
                                        ),

                                        // Conversion Factor
                                        Expanded(
                                          child: Center(
                                            child: Text(
                                              unit['is_base_unit'] ? '1' : '${unit['conversion_factor']}',
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                color: unit['is_base_unit'] ? Colors.green : Colors.blue,
                                              ),
                                            ),
                                          ),
                                        ),

                                        // Action Buttons
                                        SizedBox(
                                          width: 60,
                                          child: Row(
                                            children: [
                                              IconButton(
                                                icon: const Icon(Icons.edit, size: 18, color: Colors.blue),
                                                onPressed: () {
                                                  _showEditUnitDialog(unit);
                                                },
                                              ),
                                              IconButton(
                                                icon: const Icon(Icons.delete, size: 18, color: Colors.red),
                                                onPressed: () {
                                                  _deleteUnit(unit['id']);
                                                },
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Info Panel
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.grey[50],
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'رہنمائی:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 5),
                Text(
                  '• بنیادی یونٹ: وہ یونٹ جس میں اسٹاک محفوظ ہوتا ہے\n'
                  '• تبدیلی: ایک یونٹ = کتنے بنیادی یونٹ\n'
                  '• مثال: 1 بوری = 50 کلوگرام (تبدیلی 50)',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddUnitDialog,
        backgroundColor: Colors.indigo[700],
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Color _getTypeColor(String type) {
    switch (type) {
      case 'Weight':
        return Colors.red;
      case 'Volume':
        return Colors.blue;
      case 'Count':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  void _showAddUnitDialog() {
    showDialog(
      context: context,
      builder: (context) => UnitDialog(
        onSave: () {
          // Add unit logic
          setState(() {
            units.add({
              'id': units.length + 1,
              'name_english': 'New Unit',
              'name_urdu': 'نیا یونٹ',
              'unit_type': 'Weight',
              'is_base_unit': false,
              'conversion_factor': 1.0,
              'base_unit': 'Kilogram',
            });
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('نیا یونٹ شامل ہو گیا')),
          );
        },
      ),
    );
  }

  void _showEditUnitDialog(Map<String, dynamic> unit) {
    showDialog(
      context: context,
      builder: (context) => UnitDialog(
        unit: unit,
        onSave: () {
          // Edit unit logic
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('یونٹ اپ ڈیٹ ہو گیا')),
          );
        },
      ),
    );
  }

  void _deleteUnit(int id) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تصدیق'),
        content: const Text('کیا آپ واقعی اس یونٹ کو حذف کرنا چاہتے ہیں؟ اس سے متاثرہ آئٹمز پر اثر پڑ سکتا ہے۔'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('نہيں'),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                units.removeWhere((unit) => unit['id'] == id);
              });
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('یونٹ حذف ہو گیا')),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('ہاں، حذف کریں'),
          ),
        ],
      ),
    );
  }
}

// ==================== Unit Dialog ====================
class UnitDialog extends StatefulWidget {
  final Map<String, dynamic>? unit;
  final VoidCallback onSave;

  const UnitDialog({
    super.key,
    this.unit,
    required this.onSave,
  });

  @override
  State<UnitDialog> createState() => _UnitDialogState();
}

class _UnitDialogState extends State<UnitDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameEnController = TextEditingController();
  final _nameUrController = TextEditingController();
  final _conversionController = TextEditingController();
  
  String _selectedUnitType = 'Weight';
  bool _isBaseUnit = true;
  String? _selectedBaseUnit;

  @override
  void initState() {
    super.initState();
    if (widget.unit != null) {
      _nameEnController.text = widget.unit!['name_english'] ?? '';
      _nameUrController.text = widget.unit!['name_urdu'] ?? '';
      _selectedUnitType = widget.unit!['unit_type'] ?? 'Weight';
      _isBaseUnit = widget.unit!['is_base_unit'] ?? true;
      _conversionController.text = widget.unit!['conversion_factor']?.toString() ?? '1.0';
      _selectedBaseUnit = widget.unit!['base_unit'];
    } else {
      _conversionController.text = '1.0';
    }
  }

  @override
  void dispose() {
    _nameEnController.dispose();
    _nameUrController.dispose();
    _conversionController.dispose();
    super.dispose();
  }

  void _saveUnit() {
    if (_formKey.currentState!.validate()) {
      widget.onSave();
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.unit == null ? 'نیا یونٹ' : 'یونٹ ایڈٹ کریں'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Unit Type
              DropdownButtonFormField(
                decoration: const InputDecoration(
                  labelText: 'یونٹ کی قسم *',
                  border: OutlineInputBorder(),
                ),
                value: _selectedUnitType,
                items: const [
                  DropdownMenuItem(value: 'Weight', child: Text('وزن')),
                  DropdownMenuItem(value: 'Volume', child: Text('حجم')),
                  DropdownMenuItem(value: 'Count', child: Text('شمار')),
                ],
                onChanged: (value) {
                  setState(() {
                    _selectedUnitType = value!;
                  });
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'براہ کرم قسم منتخب کریں';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // English Name
              TextFormField(
                controller: _nameEnController,
                decoration: const InputDecoration(
                  labelText: 'انگریزی نام *',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'براہ کرم انگریزی نام درج کریں';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Urdu Name
              TextFormField(
                controller: _nameUrController,
                decoration: const InputDecoration(
                  labelText: 'اردو نام *',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'براہ کرم اردو نام درج کریں';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Base Unit Toggle
              Row(
                children: [
                  Checkbox(
                    value: _isBaseUnit,
                    onChanged: (value) {
                      setState(() {
                        _isBaseUnit = value!;
                        if (_isBaseUnit) {
                          _conversionController.text = '1.0';
                          _selectedBaseUnit = null;
                        }
                      });
                    },
                  ),
                  const Text('بنیادی یونٹ ہے'),
                ],
              ),

              // Base Unit Selection (if not base unit)
              if (!_isBaseUnit) ...[
                const SizedBox(height: 16),
                DropdownButtonFormField(
                  decoration: const InputDecoration(
                    labelText: 'بنیادی یونٹ *',
                    border: OutlineInputBorder(),
                  ),
                  value: _selectedBaseUnit,
                  items: const [
                    DropdownMenuItem(value: 'Kilogram', child: Text('کلوگرام')),
                    DropdownMenuItem(value: 'Liter', child: Text('لیٹر')),
                    DropdownMenuItem(value: 'Piece', child: Text('ٹکڑا')),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _selectedBaseUnit = value;
                    });
                  },
                  validator: (value) {
                    if (!_isBaseUnit && (value == null || value.isEmpty)) {
                      return 'براہ کرم بنیادی یونٹ منتخب کریں';
                    }
                    return null;
                  },
                ),
              ],

              // Conversion Factor
              const SizedBox(height: 16),
              TextFormField(
                controller: _conversionController,
                decoration: InputDecoration(
                  labelText: _isBaseUnit ? 'تبدیلی (ہمیشہ 1)' : 'تبدیلی *',
                  border: const OutlineInputBorder(),
                  hintText: 'مثال: 50 (ایک بوری = 50 کلوگرام)',
                ),
                keyboardType: TextInputType.number,
                enabled: !_isBaseUnit,
                validator: (value) {
                  if (!_isBaseUnit && (value == null || value.isEmpty)) {
                    return 'براہ کرم تبدیلی درج کریں';
                  }
                  final numValue = double.tryParse(value ?? '0');
                  if (!_isBaseUnit && (numValue == null || numValue <= 0)) {
                    return 'تبدیلی 0 سے زیادہ ہونی چاہیے';
                  }
                  return null;
                },
              ),

              // Info Text
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _isBaseUnit
                      ? 'یہ بنیادی یونٹ ہے۔ اس میں اسٹاک محفوظ ہوگا۔'
                      : 'ایک ${_nameUrController.text} = ${_conversionController.text} ${_selectedBaseUnit ?? ''}',
                  style: const TextStyle(fontSize: 12, color: Colors.blue),
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('منسوخ'),
        ),
        ElevatedButton(
          onPressed: _saveUnit,
          child: const Text('محفوظ کریں'),
        ),
      ],
    );
  }
}