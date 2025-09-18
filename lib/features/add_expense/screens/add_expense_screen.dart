import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:hive/hive.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

import '../../../data/models/expense_model.dart';
import '../../../data/datasources/currency_remote_datasource.dart';
import '../../../data/repositories/currency_repository.dart';
import '../../dashboard/bloc/dashboard_bloc.dart';
import '../../dashboard/bloc/dashboard_event.dart';
import '../bloc/add_expense_bloc.dart';
import '../bloc/add_expense_event.dart';
import '../bloc/add_expense_state.dart';
import 'package:http/http.dart' as http;

class AddExpenseScreen extends StatefulWidget {
  const AddExpenseScreen({super.key});

  @override
  State<AddExpenseScreen> createState() => _AddExpenseScreenState();
}

class _AddExpenseScreenState extends State<AddExpenseScreen> {
  final _formKey = GlobalKey<FormState>();

  // controllers
  final _categoryCtrl = TextEditingController();
  final _amountCtrl = TextEditingController();
  final _dateCtrl = TextEditingController();

  // local ui state
  String _selectedCurrency = 'USD';
  String? _receiptPath;
  DateTime _selectedDate = DateTime.now();

  // category presets (icon + label)
  final _categories = <_Cat>[
    _Cat('Groceries', Icons.local_grocery_store_rounded, const Color(0xFFEFF5FF), const Color(0xFF4A78FF)),
    _Cat('Entertainment', Icons.emoji_emotions_rounded, const Color(0xFFEFF5FF), const Color(0xFF2E6CF6)),
    _Cat('Gas', Icons.local_gas_station_rounded, const Color(0xFFFFF3F2), const Color(0xFFE06157)),
    _Cat('Shopping', Icons.shopping_bag_rounded, const Color(0xFFFFF9EC), const Color(0xFFE7B039)),
    _Cat('News Paper', Icons.menu_book_rounded, const Color(0xFFFFF7ED), const Color(0xFFDFA14A)),
    _Cat('Transport', Icons.directions_bus_rounded, const Color(0xFFF2EFFF), const Color(0xFF7D56F3)),
    _Cat('Rent', Icons.home_rounded, const Color(0xFFFFF7EF), const Color(0xFFE7A568)),
  ];

  @override
  void initState() {
    super.initState();
    _dateCtrl.text = DateFormat('MM/dd/yy').format(_selectedDate);
  }

  @override
  void dispose() {
    _categoryCtrl.dispose();
    _amountCtrl.dispose();
    _dateCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final expenseBox = Hive.box<ExpenseModel>('expenses');

    final currencyRepo = CurrencyRepository(CurrencyRemoteDataSource(http.Client()));

    return BlocConsumer<AddExpenseBloc, AddExpenseState>(
      listener: (context, state) {
        if (state is AddExpenseSuccess) {
          context.read<DashboardBloc>().add(LoadExpenses(page: 1, filter: DashboardFilter.all));
          Fluttertoast.showToast(
            msg: "Expense saved successfully!",
            toastLength: Toast.LENGTH_SHORT,
            gravity: ToastGravity.BOTTOM,
            backgroundColor: Colors.black87,
            textColor: Colors.white,
            fontSize: 14,
          );
          Navigator.pop(context);
        } else if (state is AddExpenseFailure) {
          Fluttertoast.showToast(
            msg: "Error: ${state.message}",
            toastLength: Toast.LENGTH_LONG,
            gravity: ToastGravity.BOTTOM,
            backgroundColor: Colors.red,
            textColor: Colors.white,
            fontSize: 14,
          );
        }
      },

      builder: (context, state) {
        final loading = state is AddExpenseLoading;

        return Scaffold(
          backgroundColor: const Color(0xFFF7F8FB),
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            foregroundColor: Colors.black87,
            title: const Text('Add Expense', style: TextStyle(fontWeight: FontWeight.w600)),
          ),
          body: Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
              children: [
                _label('Categories'),
                _categoryField(context),
                const SizedBox(height: 14),

                _label('Amount'),
                _filledField(
                  child: TextFormField(
                    controller: _amountCtrl,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
                    // Optional: restrict typing to digits, dot, comma, minus
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[0-9.,\-]')),
                    ],
                    decoration: const InputDecoration(
                      hintText: '5000 or 5,000.25',
                      border: InputBorder.none,
                    ),
                    validator: (v) {
                      final ok = _parseAmount(v) != null;
                      return ok ? null : 'Enter a valid amount';
                    },
                  ),
                ),
                const SizedBox(height: 14),

                _label('Date'),
                _filledField(
                  trailing: IconButton(
                    icon: const Icon(Icons.calendar_today_rounded),
                    onPressed: _pickDate,
                  ),
                  child: TextFormField(
                    controller: _dateCtrl,
                    readOnly: true,
                    decoration: const InputDecoration(
                      hintText: '02/01/24',
                      border: InputBorder.none,
                    ),
                    onTap: _pickDate,
                  ),
                ),
                const SizedBox(height: 14),

                _label('Attach Receipt'),
                _filledField(
                  trailing: IconButton(
                    icon: const Icon(Icons.camera_alt_outlined),
                    onPressed: _pickReceipt,
                  ),
                  child: InkWell(
                    onTap: _pickReceipt,
                    child: IgnorePointer(
                      ignoring: true,
                      child: TextFormField(
                        decoration: InputDecoration(
                          hintText: _receiptPath == null ? 'Upload image' : _receiptPath!.split('/').last,
                          border: InputBorder.none,
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 20),
                const Text('Categories',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                const SizedBox(height: 12),
                _categoryGrid(),
                const SizedBox(height: 12),

                // Currency (not shown in screenshot, but required by your flow)
                _currencyDropdown(),
              ],
            ),
          ),

          bottomNavigationBar: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: SizedBox(
                height: 52,
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF3A6FF7),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    elevation: 0,
                  ),
                  onPressed: loading ? null : _onSave,
                  child: loading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('Save', style: TextStyle(color: Colors.white, fontSize: 16)),
                ),
              ),
            ),
          ),
        );
      },
    );
  }



  Widget _label(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Text(text, style: const TextStyle(fontWeight: FontWeight.w600)),
  );

  Widget _filledField({required Widget child, Widget? trailing}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F2F6),
        borderRadius: BorderRadius.circular(12),
      ),
      height: 52,
      child: Row(
        children: [
          Expanded(child: child),
          if (trailing != null) trailing,
        ],
      ),
    );
  }

  Widget _categoryField(BuildContext context) {
    return _filledField(
      trailing: const Icon(Icons.keyboard_arrow_down_rounded),
      child: DropdownButtonFormField<String>(
        value: _categoryCtrl.text.isEmpty ? null : _categoryCtrl.text,
        isExpanded: true,
        icon: const SizedBox.shrink(),
        decoration: const InputDecoration(
          hintText: 'Entertainment',
          border: InputBorder.none,
        ),
        items: [
          ..._categories.map((c) => DropdownMenuItem(value: c.label, child: Text(c.label))),
        ],
        onChanged: (v) => setState(() => _categoryCtrl.text = v ?? ''),
        validator: (v) => (v == null || v.isEmpty) ? 'Select category' : null,
      ),
    );
  }


  Widget _categoryGrid() {
    final selected = _categoryCtrl.text;

    final items = [
      ..._categories.map((c) {
        final isSel = selected == c.label;
        return GestureDetector(
          onTap: () => setState(() => _categoryCtrl.text = c.label),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 58,
                height: 58,
                decoration: BoxDecoration(
                  color: c.bg,
                  shape: BoxShape.circle,
                  border: isSel ? Border.all(color: const Color(0xFF3A6FF7), width: 2) : null,
                ),
                child: Icon(c.icon, color: isSel ? const Color(0xFF3A6FF7) : c.fg),
              ),
              const SizedBox(height: 6),
              Text(
                c.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isSel ? FontWeight.w600 : FontWeight.w400,
                  color: isSel ? const Color(0xFF3A6FF7) : Colors.black87,
                ),
              ),
            ],
          ),
        );
      }),
      // Add Category
      Column(
        mainAxisSize: MainAxisSize.min,
        children: const [
          SizedBox(
            width: 58,
            height: 58,
            child: CircleAvatar(
              backgroundColor: Color(0xFFEFF5FF),
              child: Icon(Icons.add, color: Color(0xFF3A6FF7)),
            ),
          ),
          SizedBox(height: 6),
          Text('Add Category', maxLines: 1, overflow: TextOverflow.ellipsis, textAlign: TextAlign.center, style: TextStyle(fontSize: 12)),
        ],
      ),
    ].toList();

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        crossAxisSpacing: 14,
        mainAxisSpacing: 14,
        mainAxisExtent: 98,
      ),
      itemCount: items.length,
      itemBuilder: (_, i) => items[i],
    );
  }



  Widget _currencyDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _label('Currency'),
        _filledField(
          child: DropdownButtonFormField<String>(
            value: _selectedCurrency,
            isExpanded: true,
            decoration: const InputDecoration(border: InputBorder.none),
            items: const [
              DropdownMenuItem(value: 'USD', child: Text('USD')),
              DropdownMenuItem(value: 'EGP', child: Text('EGP')),
              DropdownMenuItem(value: 'EUR', child: Text('EUR')),
              DropdownMenuItem(value: 'SAR', child: Text('SAR')),
              DropdownMenuItem(value: 'AED', child: Text('AED')),
            ],
            onChanged: (v) => setState(() => _selectedCurrency = v ?? 'USD'),
          ),
        ),
      ],
    );
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
        _dateCtrl.text = DateFormat('MM/dd/yy').format(picked);
      });
    }
  }

  Future<void> _pickReceipt() async {
    final picker = ImagePicker();
    final img = await picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (img != null) {
      setState(() => _receiptPath = img.path);
    }
  }

  void _onSave() {
    final isValid = _formKey.currentState?.validate() ?? false;
    if (!isValid) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fix the form and try again')),
      );
      return;
    }
    final parsed = _parseAmount(_amountCtrl.text);
    if (parsed == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Amount is invalid')),
      );
      return;
    }
    print('[AddExpense] Dispatch SaveExpense: category="${_categoryCtrl.text}", amount=$parsed, currency=$_selectedCurrency');
    context.read<AddExpenseBloc>().add(SaveExpense(
      category: _categoryCtrl.text,
      amount: parsed,
      date: _selectedDate,
      currency: _selectedCurrency,
      receiptPath: _receiptPath,
    ));
  }



}

double? _parseAmount(String? raw) {
  if (raw == null) return null;
  final cleaned = raw.replaceAll(RegExp(r'[^0-9.,\-]'), '');
  if (cleaned.isEmpty) return null;

  final hasDot = cleaned.contains('.');
  final hasComma = cleaned.contains(',');

  String normalized;
  if (hasDot && hasComma) {
    normalized = cleaned.replaceAll(',', '');        // 5,000.25 -> 5000.25
  } else if (!hasDot && hasComma) {
    normalized = cleaned.replaceAll(',', '.');       // 5000,25 -> 5000.25
  } else {
    normalized = cleaned;
  }
  return double.tryParse(normalized);
}


class _Cat {
  final String label;
  final IconData icon;
  final Color bg;
  final Color fg;
  const _Cat(this.label, this.icon, this.bg, this.fg);
}
