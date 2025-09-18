import 'package:flutter/material.dart';
import '../../../data/models/expense_model.dart';
import '../../../core/utils/currency_api.dart';

class ExpenseForm extends StatefulWidget {
  final void Function(ExpenseModel expense) onSubmit;

  const ExpenseForm({super.key, required this.onSubmit});

  @override
  State<ExpenseForm> createState() => _ExpenseFormState();
}

class _ExpenseFormState extends State<ExpenseForm> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _categoryController = TextEditingController();
  DateTime _selectedDate = DateTime.now();
  String _selectedCurrency = "EGP"; // default

  final _currencies = ["EGP", "USD", "EUR", "SAR"]; // Add more if needed

  bool _isConverting = false;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            TextFormField(
              controller: _categoryController,
              decoration: const InputDecoration(labelText: "Category"),
              validator: (value) => value!.isEmpty ? "Enter category" : null,
            ),
            TextFormField(
              controller: _amountController,
              decoration: const InputDecoration(labelText: "Amount"),
              keyboardType: TextInputType.number,
              validator: (value) => value!.isEmpty ? "Enter amount" : null,
            ),
            const SizedBox(height: 12),

            // 🔹 Currency Dropdown
            DropdownButtonFormField<String>(
              value: _selectedCurrency,
              items:
                  _currencies
                      .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                      .toList(),
              onChanged: (val) => setState(() => _selectedCurrency = val!),
              decoration: const InputDecoration(labelText: "Currency"),
            ),

            const SizedBox(height: 12),

            Row(
              children: [
                Expanded(
                  child: Text("Date: ${_selectedDate.toLocal()}".split(' ')[0]),
                ),
                TextButton(
                  child: const Text("Select Date"),
                  onPressed: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: _selectedDate,
                      firstDate: DateTime(2020),
                      lastDate: DateTime(2100),
                    );
                    if (picked != null) setState(() => _selectedDate = picked);
                  },
                ),
              ],
            ),
            const SizedBox(height: 20),

            ElevatedButton(
              child:
                  _isConverting
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text("Save Expense"),
              onPressed: () async {
                if (_formKey.currentState!.validate()) {
                  setState(() => _isConverting = true);

                  final amount = double.tryParse(_amountController.text) ?? 0.0;

                  try {
                    // 🔹 Convert to USD using API
                    final usdAmount = await CurrencyApi.convertToUSD(
                      amount,
                      _selectedCurrency,
                    );

                    final expense = ExpenseModel(
                      id: DateTime.now().millisecondsSinceEpoch.toString(),
                      category: _categoryController.text,
                      amount: amount,
                      date: _selectedDate,
                      currency: _selectedCurrency,
                      usdAmount: usdAmount,
                    );

                    widget.onSubmit(expense);
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text("Conversion failed: $e")),
                    );
                  } finally {
                    setState(() => _isConverting = false);
                  }
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}
