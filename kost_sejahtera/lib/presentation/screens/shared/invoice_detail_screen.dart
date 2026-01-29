import 'package:flutter/material.dart';
import '../../../core/constants/colors.dart';
import '../../../core/constants/text_styles.dart';

class InvoiceDetailScreen extends StatelessWidget {
  const InvoiceDetailScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Detail Tagihan'),
        actions: [
          IconButton(
            icon: Icon(Icons.download_outlined),
            onPressed: () {
              // TODO: Download PDF
            },
          ),
          IconButton(
            icon: Icon(Icons.share_outlined),
            onPressed: () {
              // TODO: Share invoice
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Invoice Header
            Container(
              padding: EdgeInsets.all(24),
              color: AppColors.white,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Invoice', style: AppTextStyles.h2),
                          SizedBox(height: 4),
                          Text(
                            '#INV-2024-001',
                            style: AppTextStyles.bodyMedium.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: AppColors.danger.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          'Belum Dibayar',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.danger,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  
                  SizedBox(height: 24),
                  Divider(),
                  SizedBox(height: 24),
                  
                  // Billing Info
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Tagihan Untuk', style: AppTextStyles.label),
                            SizedBox(height: 8),
                            Text('Budi Santoso', style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600)),
                            Text('Kamar A-101', style: AppTextStyles.bodySmall),
                            Text('08123456789', style: AppTextStyles.bodySmall),
                          ],
                        ),
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Periode', style: AppTextStyles.label),
                            SizedBox(height: 8),
                            Text('Januari 2024', style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600)),
                            SizedBox(height: 12),
                            Text('Tanggal Jatuh Tempo', style: AppTextStyles.label),
                            SizedBox(height: 8),
                            Text(
                              '5 Februari 2024',
                              style: AppTextStyles.bodyMedium.copyWith(
                                fontWeight: FontWeight.w600,
                                color: AppColors.danger,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            SizedBox(height: 16),
            
            // Invoice Items
            Container(
              padding: EdgeInsets.all(24),
              color: AppColors.white,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Rincian Tagihan', style: AppTextStyles.h4),
                  SizedBox(height: 20),
                  
                  _buildInvoiceItem('Sewa Kamar', 'Rp 2.000.000'),
                  _buildInvoiceItem('Listrik (150 kWh x Rp 1.500)', 'Rp 225.000'),
                  _buildInvoiceItem('Air', 'Rp 100.000'),
                  _buildInvoiceItem('Internet', 'Rp 100.000'),
                  _buildInvoiceItem('Service Charge', 'Rp 75.000'),
                  
                  SizedBox(height: 16),
                  Divider(),
                  SizedBox(height: 16),
                  
                  _buildInvoiceItem('Subtotal', 'Rp 2.500.000', isBold: true),
                  _buildInvoiceItem('Diskon', '- Rp 0', isDiscount: true),
                  
                  SizedBox(height: 16),
                  Divider(thickness: 2),
                  SizedBox(height: 16),
                  
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Total Bayar', style: AppTextStyles.h3),
                      Text(
                        'Rp 2.500.000',
                        style: AppTextStyles.h2.copyWith(color: AppColors.primary),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            SizedBox(height: 16),
            
            // Payment Instructions
            Container(
              padding: EdgeInsets.all(24),
              color: AppColors.white,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Cara Pembayaran', style: AppTextStyles.h4),
                  SizedBox(height: 16),
                  
                  _buildPaymentInstruction(
                    '1',
                    'Pilih metode pembayaran yang Anda inginkan',
                  ),
                  _buildPaymentInstruction(
                    '2',
                    'Lakukan pembayaran sesuai instruksi',
                  ),
                  _buildPaymentInstruction(
                    '3',
                    'Pembayaran akan dikonfirmasi otomatis',
                  ),
                  _buildPaymentInstruction(
                    '4',
                    'Invoice akan berubah status menjadi "Lunas"',
                  ),
                ],
              ),
            ),
            
            SizedBox(height: 80), // Space for button
          ],
        ),
      ),
      bottomNavigationBar: Container(
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
        child: ElevatedButton(
          onPressed: () {
            // Navigate to payment screen
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            padding: EdgeInsets.symmetric(vertical: 16),
          ),
          child: Text(
            'Bayar Sekarang',
            style: AppTextStyles.button,
          ),
        ),
      ),
    );
  }

  Widget _buildInvoiceItem(String label, String amount, {bool isBold = false, bool isDiscount = false}) {
    return Padding(
      padding: EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: AppTextStyles.bodyMedium.copyWith(
              fontWeight: isBold ? FontWeight.w600 : FontWeight.w400,
            ),
          ),
          Text(
            amount,
            style: AppTextStyles.bodyMedium.copyWith(
              fontWeight: isBold ? FontWeight.w600 : FontWeight.w400,
              color: isDiscount ? AppColors.success : AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentInstruction(String number, String text) {
    return Padding(
      padding: EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Center(
              child: Text(
                number,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: AppTextStyles.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }
}
