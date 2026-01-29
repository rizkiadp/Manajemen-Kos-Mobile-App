import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/colors.dart';
import '../../../core/constants/text_styles.dart';
import '../../../core/services/dashboard_service.dart';
import 'payment_screen.dart';

class InvoicesScreen extends StatefulWidget {
  const InvoicesScreen({Key? key}) : super(key: key);

  @override
  State<InvoicesScreen> createState() => _InvoicesScreenState();
}

class _InvoicesScreenState extends State<InvoicesScreen> {
  final DashboardService _dashboardService = DashboardService();
  bool _isLoading = true;
  Map<String, dynamic>? _latestInvoice;

  @override
  void initState() {
    super.initState();
    _loadInvoice();
  }

  Future<void> _loadInvoice() async {
    setState(() => _isLoading = true);
    try {
      final data = await _dashboardService.getTenantDashboard();
      setState(() {
        _latestInvoice = data['latestInvoice'];
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
    final formatter = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
    return formatter.format(amount);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Tagihan'),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.white,
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadInvoice,
              child: _latestInvoice == null
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.check_circle_outline,
                            size: 64,
                            color: AppColors.success,
                          ),
                          SizedBox(height: 16),
                          Text(
                            'Tidak ada tagihan',
                            style: AppTextStyles.h3,
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Semua tagihan sudah lunas',
                            style: AppTextStyles.bodyMedium.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    )
                  : SingleChildScrollView(
                      physics: AlwaysScrollableScrollPhysics(),
                      padding: EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildInvoiceCard(_latestInvoice!),
                          SizedBox(height: 24),
                          _buildBillBreakdown(_latestInvoice!),
                        ],
                      ),
                    ),
            ),
    );
  }

  Widget _buildInvoiceCard(Map<String, dynamic> invoice) {
    final dueDate = DateTime.parse(invoice['due_date'].toString());
    final formattedDate = DateFormat('d MMMM yyyy').format(dueDate);
    final isPaid = invoice['status'] == 'paid';

    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isPaid
              ? [AppColors.success, Color(0xFF059669)]
              : [AppColors.danger, Color(0xFFDC2626)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isPaid ? Icons.check_circle : Icons.warning_amber_rounded,
                color: AppColors.white,
              ),
              SizedBox(width: 8),
              Text(
                isPaid ? 'Tagihan Lunas' : 'Tagihan Belum Dibayar',
                style: AppTextStyles.h4.copyWith(color: AppColors.white),
              ),
            ],
          ),
          SizedBox(height: 12),
          Text(
            'Jatuh tempo: $formattedDate',
            style: AppTextStyles.bodyMedium.copyWith(color: AppColors.white),
          ),
          SizedBox(height: 16),
          if (!isPaid)
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => PaymentScreen(invoice: invoice),
                  ),
                ).then((_) => _loadInvoice());
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.white,
                foregroundColor: AppColors.danger,
              ),
              child: Text('Bayar Sekarang'),
            ),
        ],
      ),
    );
  }

  Widget _buildBillBreakdown(Map<String, dynamic> invoice) {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Rincian Tagihan',
            style: AppTextStyles.h4,
          ),
          SizedBox(height: 16),
          _buildBillRow('Sewa Kamar', invoice['rent_amount']),
          if (invoice['electricity_amount'] != null && invoice['electricity_amount'] > 0)
            _buildBillRow('Listrik', invoice['electricity_amount']),
          if (invoice['water_amount'] != null && invoice['water_amount'] > 0)
            _buildBillRow('Air', invoice['water_amount']),
          if (invoice['other_amount'] != null && invoice['other_amount'] > 0)
            _buildBillRow('Lain-lain', invoice['other_amount']),
          Divider(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total',
                style: AppTextStyles.h4.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                _formatCurrency(invoice['total_amount']),
                style: AppTextStyles.h3.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBillRow(String label, dynamic amount) {
    return Padding(
      padding: EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: AppTextStyles.bodyMedium,
          ),
          Text(
            _formatCurrency(amount),
            style: AppTextStyles.bodyMedium.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
