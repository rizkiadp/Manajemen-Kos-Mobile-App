import 'package:flutter/material.dart';
import '../../../core/constants/colors.dart';
import '../../../core/constants/text_styles.dart';

class RulesScreen extends StatelessWidget {
  const RulesScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Tata Tertib Kost'),
        backgroundColor: AppColors.background,
        elevation: 0,
        foregroundColor: AppColors.textPrimary,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            // Welcome Card
            Container(
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.primary, Color(0xFF8B5CF6)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                   Icon(Icons.rule_folder, size: 48, color: Colors.white),
                   SizedBox(width: 16),
                   Expanded(
                     child: Column(
                       crossAxisAlignment: CrossAxisAlignment.start,
                       children: [
                         Text(
                           'Peraturan & Ketentuan',
                           style: AppTextStyles.h3.copyWith(color: Colors.white),
                         ),
                         SizedBox(height: 4),
                         Text(
                           'Harap dibaca dan dipatuhi demi kenyamanan bersama.',
                           style: AppTextStyles.bodySmall.copyWith(color: Colors.white.withOpacity(0.9)),
                         ),
                       ],
                     ),
                   )
                ],
              ),
            ),
            
            SizedBox(height: 24),
            
            // Rules List
            _buildRuleItem(
              icon: Icons.favorite,
              title: 'Tamu Menginap & Pasangan',
              description: 'Diperbolehkan membawa pasangan atau tamu menginap, namun harap menjaga ketertiban dan tidak mengganggu penghuni lain.',
              color: AppColors.primary,
            ),
             _buildRuleItem(
              icon: Icons.cleaning_services,
              title: 'Kebersihan',
              description: 'Wajib menjaga kebersihan kamar dan area umum (dapur, lorong, parkiran). Buang sampah pada tempatnya.',
              color: AppColors.success,
            ),
             _buildRuleItem(
              icon: Icons.volume_off,
              title: 'Ketenangan',
              description: 'Dilarang membuat kegaduhan yang mengganggu (musik keras, teriak-teriak) terutama di atas jam 22.00 WIB.',
              color: AppColors.warning,
            ),
             _buildRuleItem(
              icon: Icons.lock,
              title: 'Keamanan',
              description: 'Pastikan pintu gerbang selalu terkunci saat keluar atau masuk. Kehilangan barang pribadi menjadi tanggung jawab masing-masing.',
              color: AppColors.info,
            ),
             _buildRuleItem(
              icon: Icons.smoke_free,
              title: 'Rokok & Obat Terlarang',
              description: 'Dilarang menggunakan narkoba/obat terlarang jenis apapun. Merokok diperbolehkan di area terbuka/balkon.',
              color: AppColors.danger,
            ),
            _buildRuleItem(
              icon: Icons.payment,
              title: 'Pembayaran',
              description: 'Pembayaran sewa dilakukan paling lambat pada tanggal jatuh tempo yang telah ditentukan setiap bulannya.',
               color: AppColors.textPrimary,
            ),
            
             SizedBox(height: 16),
             
             Container(
               padding: EdgeInsets.all(16),
               decoration: BoxDecoration(
                 color: AppColors.info.withOpacity(0.1),
                 borderRadius: BorderRadius.circular(12),
                 border: Border.all(color: AppColors.info.withOpacity(0.3)),
               ),
               child: Text(
                 'Pelanggaran terhadap tata tertib dapat dikenakan sanksi berupa teguran hingga pemutusan kontrak sewa sepihak.',
                 style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary, fontStyle: FontStyle.italic),
                 textAlign: TextAlign.center,
               ),
             ),
          ],
        ),
      ),
    );
  }

  Widget _buildRuleItem({
    required IconData icon,
    required String title,
    required String description,
    required Color color,
  }) {
    return Container(
      margin: EdgeInsets.only(bottom: 16),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTextStyles.h4,
                ),
                SizedBox(height: 4),
                Text(
                  description,
                  style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
