import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/constants/colors.dart';
import '../../../core/constants/text_styles.dart';
import '../../widgets/common/custom_button.dart';
import '../../../core/services/payment_service.dart';

class PaymentScreen extends StatefulWidget {
  final Map<String, dynamic> invoice;

  const PaymentScreen({Key? key, required this.invoice}) : super(key: key);

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  final PaymentService _paymentService = PaymentService();
  String? _selectedMethod;
  String? _selectedProvider; // e.g., 'bca', 'gopay'
  bool _isLoading = false;

  final Map<String, List<Map<String, dynamic>>> paymentMethods = {
    'bank_transfer': [
      {'name': 'BCA Virtual Account', 'icon': Icons.account_balance, 'id': 'bca', 'fee': 0},
      {'name': 'Mandiri Virtual Account', 'icon': Icons.account_balance, 'id': 'mandiri', 'fee': 0},
      {'name': 'BNI Virtual Account', 'icon': Icons.account_balance, 'id': 'bni', 'fee': 0},
      {'name': 'BRI Virtual Account', 'icon': Icons.account_balance, 'id': 'bri', 'fee': 0},
    ],
    'ewallet': [
      {'name': 'GoPay', 'icon': Icons.wallet, 'id': 'gopay', 'fee': 0},
      {'name': 'ShopeePay', 'icon': Icons.wallet, 'id': 'shopeepay', 'fee': 0},
    ],
    'qris': [
      {'name': 'QRIS', 'icon': Icons.qr_code, 'id': 'qris', 'fee': 0},
    ],
  };

  @override
  Widget build(BuildContext context) {
    final total = double.parse(widget.invoice['total'].toString());
    final formattedTotal = NumberFormat.currency(locale: 'id', symbol: 'Rp ', decimalDigits: 0).format(total);

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
                      formattedTotal,
                      style: AppTextStyles.h3.copyWith(color: AppColors.primary),
                    ),
                  ],
                ),
                SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('No. Invoice', style: AppTextStyles.bodySmall),
                    Text(widget.invoice['invoice_number'], style: AppTextStyles.bodySmall),
                  ],
                ),
                Divider(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Total Bayar', style: AppTextStyles.h4),
                    Text(
                      formattedTotal,
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
              text: _isLoading ? 'Memproses...' : 'Bayar Sekarang',
              onPressed: (_selectedProvider != null && !_isLoading) ? _handlePayment : () {},
              icon: _isLoading ? null : Icons.payment,
              isLoading: _isLoading,
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
            provider['id'],
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
    String providerId,
  ) {
    final isSelected = _selectedMethod == method && _selectedProvider == providerId;
    
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedMethod = method;
          _selectedProvider = providerId;
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
    setState(() => _isLoading = true);
    
    try {
      final result = await _paymentService.createTransaction(
        invoiceId: widget.invoice['id'],
        paymentMethod: _selectedMethod ?? 'other', 
      );
      
      if (!mounted) return;

      final redirectUrl = result['redirect_url'];
      if (redirectUrl != null) {
          final Uri url = Uri.parse(redirectUrl);
          if (await canLaunchUrl(url)) {
            await launchUrl(url, mode: LaunchMode.externalApplication);
            // Show confirmation dialog after returning from browser
             if (!mounted) return;
             showDialog(
                context: context, 
                builder: (ctx) => AlertDialog(
                    title: Text('Menunggu Pembayaran'),
                    content: Text('Silakan selesaikan pembayaran di halaman yang terbuka. Jika sudah, tekan tombol "Sudah Bayar" untuk memuat ulang status.'),
                    actions: [
                        TextButton(
                            onPressed: () {
                                Navigator.pop(ctx); // Close dialog
                                Navigator.pop(context); // Close payment screen
                            }, 
                            child: Text('Sudah Bayar')
                        )
                    ],
                )
             );
          } else {
             throw Exception('Tidak dapat membuka halaman pembayaran');
          }
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal: ${e.toString().replaceAll('Exception: ', '')}')),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
}
