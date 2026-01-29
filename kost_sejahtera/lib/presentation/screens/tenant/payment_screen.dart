import 'package:flutter/material.dart';
import '../../../core/constants/colors.dart';
import '../../../core/constants/text_styles.dart';
import '../../widgets/common/custom_button.dart';

class PaymentScreen extends StatefulWidget {
  const PaymentScreen({Key? key}) : super(key: key);

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  String? _selectedMethod;
  String? _selectedProvider;

  final Map<String, List<Map<String, dynamic>>> paymentMethods = {
    'bank_transfer': [
      {'name': 'BCA Virtual Account', 'icon': Icons.account_balance, 'fee': 0},
      {'name': 'Mandiri Virtual Account', 'icon': Icons.account_balance, 'fee': 0},
      {'name': 'BNI Virtual Account', 'icon': Icons.account_balance, 'fee': 0},
    ],
    'ewallet': [
      {'name': 'GoPay', 'icon': Icons.wallet, 'fee': 0},
      {'name': 'OVO', 'icon': Icons.wallet, 'fee': 0},
      {'name': 'ShopeePay', 'icon': Icons.wallet, 'fee': 0},
      {'name': 'DANA', 'icon': Icons.wallet, 'fee': 0},
    ],
    'qris': [
      {'name': 'QRIS', 'icon': Icons.qr_code, 'fee': 0},
    ],
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Pilih Metode Pembayaran'),
      ),
      body: Column(
        children: [
          // Bill Summary
          Container(
            padding: EdgeInsets.all(20),
            color: AppColors.white,
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Total Tagihan', style: AppTextStyles.bodyMedium),
                    Text(
                      'Rp 2.500.000',
                      style: AppTextStyles.h3.copyWith(color: AppColors.primary),
                    ),
                  ],
                ),
                SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Biaya Admin', style: AppTextStyles.bodySmall),
                    Text('Rp 0', style: AppTextStyles.bodySmall),
                  ],
                ),
                Divider(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Total Bayar', style: AppTextStyles.h4),
                    Text(
                      'Rp 2.500.000',
                      style: AppTextStyles.h3.copyWith(color: AppColors.textPrimary),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          SizedBox(height: 16),
          
          // Payment Methods
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildMethodSection('Transfer Bank', 'bank_transfer'),
                  SizedBox(height: 16),
                  _buildMethodSection('E-Wallet', 'ewallet'),
                  SizedBox(height: 16),
                  _buildMethodSection('QRIS', 'qris'),
                ],
              ),
            ),
          ),
          
          // Pay Button
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: Offset(0, -2),
                ),
              ],
            ),
            child: CustomButton(
              text: 'Bayar Sekarang',
              onPressed: _selectedProvider != null ? _handlePayment : () {},
              icon: Icons.payment,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMethodSection(String title, String methodType) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: AppTextStyles.h4),
        SizedBox(height: 12),
        ...paymentMethods[methodType]!.map((provider) {
          return _buildPaymentOption(
            provider['name'],
            provider['icon'],
            provider['fee'],
            methodType,
            provider['name'],
          );
        }).toList(),
      ],
    );
  }

  Widget _buildPaymentOption(
    String name,
    IconData icon,
    int fee,
    String method,
    String provider,
  ) {
    final isSelected = _selectedMethod == method && _selectedProvider == provider;
    
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedMethod = method;
          _selectedProvider = provider;
        });
      },
      child: Container(
        margin: EdgeInsets.only(bottom: 12),
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.greyLight,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.backgroundLight,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: AppColors.textPrimary),
            ),
            SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name, style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600)),
                  if (fee > 0) ...[
                    SizedBox(height: 4),
                    Text('Biaya admin: Rp ${fee.toString()}', style: AppTextStyles.bodySmall),
                  ],
                ],
              ),
            ),
            if (isSelected)
              Icon(Icons.check_circle, color: AppColors.primary),
          ],
        ),
      ),
    );
  }

  Future<void> _handlePayment() async {
    // TODO: Integrate with Midtrans
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Proses Pembayaran'),
        content: Text('Integrasi Midtrans akan ditambahkan di sini.\n\nMetode: $_selectedProvider'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('OK'),
          ),
        ],
      ),
    );
  }
}
