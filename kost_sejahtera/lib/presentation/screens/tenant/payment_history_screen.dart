import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/colors.dart';
import '../../../core/constants/text_styles.dart';
import '../../../core/services/dashboard_service.dart';

class PaymentHistoryScreen extends StatefulWidget {
  const PaymentHistoryScreen({Key? key}) : super(key: key);

  @override
  State<PaymentHistoryScreen> createState() => _PaymentHistoryScreenState();
}

class _PaymentHistoryScreenState extends State<PaymentHistoryScreen> {
  final DashboardService _dashboardService = DashboardService();
  bool _isLoading = true;
  List<dynamic> _paymentHistory = [];

  @override
  void initState() {
    super.initState();
    _loadPaymentHistory();
  }

  Future<void> _loadPaymentHistory() async {
    setState(() => _isLoading = true);
    try {
      final data = await _dashboardService.getTenantDashboard();
      setState(() {
        _paymentHistory = data['paymentHistory'] as List? ?? [];
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceAll('Exception: ', ''))),
      );
      setState(() => _isLoading = false);
    }
  }

  String _formatCurrency(dynamic amount) {
    if (amount == null) return 'Rp 0';
    
    // Convert to double if it's a string
    double numAmount;
    if (amount is String) {
      numAmount = double.tryParse(amount) ?? 0;
    } else if (amount is int) {
      numAmount = amount.toDouble();
    } else {
      numAmount = amount as double;
    }
    
    final formatter = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
    return formatter.format(numAmount);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Riwayat Pembayaran'),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.white,
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadPaymentHistory,
              child: _paymentHistory.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.receipt_long_outlined,
                            size: 64,
                            color: Colors.grey,
                          ),
                          SizedBox(height: 16),
                          Text(
                            'Belum ada riwayat pembayaran',
                            style: AppTextStyles.bodyLarge.copyWith(color: Colors.grey),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: EdgeInsets.all(16),
                      itemCount: _paymentHistory.length,
                      itemBuilder: (context, index) {
                        final payment = _paymentHistory[index];
                        return _buildPaymentCard(payment);
                      },
                    ),
            ),
    );
  }

  Widget _buildPaymentCard(Map<String, dynamic> payment) {
    final paymentDate = payment['payment_date'] != null
        ? DateTime.parse(payment['payment_date'].toString())
        : null;
    final formattedDate = paymentDate != null
        ? DateFormat('d MMM yyyy').format(paymentDate)
        : '-';

    final status = payment['status']?.toString() ?? 'pending';
    final statusColor = status == 'success' ? AppColors.success : AppColors.warning;
    final statusText = status == 'success' ? 'Berhasil' : 'Pending';

    // Parse amount safely
    final amount = payment['payment_amount'] ?? payment['total'] ?? 0;

    return Card(
      margin: EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Pembayaran',
                  style: AppTextStyles.bodyMedium.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    statusText,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: statusColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 8),
            Text(
              formattedDate,
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Total',
                  style: AppTextStyles.bodyMedium,
                ),
                Text(
                  _formatCurrency(amount),
                  style: AppTextStyles.h4.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            if (payment['payment_method'] != null) ...[
              SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.payment, size: 16, color: AppColors.textSecondary),
                  SizedBox(width: 4),
                  Text(
                    payment['payment_method'].toString().toUpperCase(),
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
