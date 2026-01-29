import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/constants/colors.dart';
import '../../../core/constants/text_styles.dart';
import '../../../core/services/dashboard_service.dart';
import '../../../core/services/auth_service.dart';
import 'payment_screen.dart';
import 'maintenance_report_screen.dart';
import 'invoices_screen.dart';
import 'payment_history_screen.dart';
import 'profile_screen.dart';
import 'general_chat_screen.dart';

class TenantDashboardScreen extends StatefulWidget {
  const TenantDashboardScreen({Key? key}) : super(key: key);

  @override
  State<TenantDashboardScreen> createState() => _TenantDashboardScreenState();
}

class _TenantDashboardScreenState extends State<TenantDashboardScreen> {
  final DashboardService _dashboardService = DashboardService();
  final AuthService _authService = AuthService();
  int _selectedIndex = 0;
  bool _isLoading = true;
  Map<String, dynamic>? _dashboardData;
  Map<String, dynamic>? _currentUser;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final user = await _authService.getCurrentUser();
      final dashboard = await _dashboardService.getTenantDashboard();
      
      setState(() {
        _currentUser = user;
        _dashboardData = dashboard;
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

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_dashboardData == null) {
      return Scaffold(
        body: Center(child: Text('Gagal memuat data')),
      );
    }

    // Show different screens based on selected tab
    Widget currentScreen;
    switch (_selectedIndex) {
      case 0:
        currentScreen = _buildDashboardContent();
        break;
      case 1:
        currentScreen = InvoicesScreen();
        break;
      case 2:
        currentScreen = PaymentHistoryScreen();
        break;
      case 3:
        currentScreen = ProfileScreen();
        break;
      default:
        currentScreen = _buildDashboardContent();
    }

    return Scaffold(
      appBar: _selectedIndex == 0 ? AppBar(
        title: Text('Dashboard'),
        actions: [
          IconButton(
            icon: Icon(Icons.notifications_outlined),
            onPressed: () {},
          ),
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: () async {
              await _authService.signOut();
              if (!mounted) return;
              Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
            },
          ),
        ],
      ) : null,
      body: currentScreen,
      bottomNavigationBar: _buildBottomNavBar(),
    );
  }

  Widget _buildDashboardContent() {
    return RefreshIndicator(
      onRefresh: _loadData,
      child: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Greeting
            Text(
              'Halo, ${_currentUser?['name'] ?? 'Penyewa'} 👋',
              style: AppTextStyles.h2,
            ),
            SizedBox(height: 4),
            Text(
              'Selamat datang kembali!',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            
            SizedBox(height: 24),
            
            // Payment Reminder (if unpaid)
            if (_dashboardData!['latestInvoice'] != null)
              _buildPaymentReminderCard(_dashboardData!['latestInvoice']),
            
            if (_dashboardData!['latestInvoice'] != null)
              SizedBox(height: 16),
            
            // Bill Breakdown
            if (_dashboardData!['latestInvoice'] != null)
             _buildBillBreakdown(_dashboardData!['latestInvoice']),
            
            SizedBox(height: 24),
            
            // Room Information
            Text(
              'Informasi Kamar',
              style: AppTextStyles.h3,
            ),
            SizedBox(height: 16),
            _buildRoomInfoCard(_dashboardData!['tenant']),
            
            SizedBox(height: 24),
            
            // Quick Actions
            Text(
              'Aksi Cepat',
              style: AppTextStyles.h3,
            ),
            SizedBox(height: 16),
            _buildQuickActions(),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentReminderCard(Map<String, dynamic> invoice) {
    if (invoice['due_date'] == null) return SizedBox.shrink();
    final dueDate = DateTime.parse(invoice['due_date'].toString());
    final formattedDate = DateFormat('d MMMM yyyy').format(dueDate);
    
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.danger, Color(0xFFDC2626)],
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
              Icon(Icons.warning_amber_rounded, color: AppColors.white),
              SizedBox(width: 8),
              Text(
                'Tagihan Belum Dibayar',
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
          ElevatedButton(
            onPressed: () {
              Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => PaymentScreen(invoice: invoice)
                  )
              ).then((_) => _loadData()); // Reload after payment return
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
    final total = double.tryParse(invoice['total']?.toString() ?? '0') ?? 0;
    final items = invoice['items'] as List<dynamic>? ?? [
      {'description': 'Tagihan Bulan Ini', 'amount': total}
    ];

    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.greyLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Rincian Tagihan', style: AppTextStyles.h4),
          SizedBox(height: 16),
          ...items.map((item) => _buildBillItem(
            item['description']?.toString() ?? 'Item Tagihan', 
            NumberFormat.currency(locale: 'id', symbol: 'Rp ', decimalDigits: 0).format(item['amount'] ?? 0)
          )).toList(),
          Divider(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Total', style: AppTextStyles.h4),
              Text(
                NumberFormat.currency(locale: 'id', symbol: 'Rp ', decimalDigits: 0).format(total),
                style: AppTextStyles.h3.copyWith(color: AppColors.primary),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBillItem(String label, String amount) {
    return Padding(
      padding: EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: AppTextStyles.bodyMedium),
          Text(amount, style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _buildRoomInfoCard(Map<String, dynamic> tenant) {
    if (tenant['move_in_date'] == null) return SizedBox.shrink();
    final moveInDate = DateTime.parse(tenant['move_in_date'].toString());
    final formattedDate = DateFormat('d MMMM yyyy').format(moveInDate);
    
    List<String> facilities = ['Standar'];
    if (tenant['facilities'] != null) {
      if (tenant['facilities'] is List) {
        facilities = (tenant['facilities'] as List).map((e) => e.toString()).toList();
      } else if (tenant['facilities'] is String) {
        facilities = (tenant['facilities'] as String).split(',');
      }
    }

    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.greyLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Room Image with attractive gradient
          ClipRRect(
            borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
            child: Container(
              height: 200,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFF6366F1), // Indigo-500
                    Color(0xFF8B5CF6), // Violet-500
                    Color(0xFFA855F7), // Purple-500
                  ],
                ),
              ),
              child: Stack(
                children: [
                  // Decorative circles
                  Positioned(
                    right: -50,
                    top: -50,
                    child: Container(
                      width: 200,
                      height: 200,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.white.withOpacity(0.1),
                      ),
                    ),
                  ),
                  Positioned(
                    left: -30,
                    bottom: -30,
                    child: Container(
                      width: 150,
                      height: 150,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.white.withOpacity(0.08),
                      ),
                    ),
                  ),
                  // Decorative icons
                  Positioned(
                    right: 20,
                    top: 20,
                    child: Icon(
                      Icons.bed_outlined,
                      size: 40,
                      color: AppColors.white.withOpacity(0.3),
                    ),
                  ),
                  Positioned(
                    left: 20,
                    bottom: 20,
                    child: Icon(
                      Icons.chair_outlined,
                      size: 35,
                      color: AppColors.white.withOpacity(0.3),
                    ),
                  ),
                  // Center content
                  Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: AppColors.white.withOpacity(0.2),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: AppColors.white.withOpacity(0.3),
                              width: 2,
                            ),
                          ),
                          child: Icon(
                            Icons.meeting_room_rounded,
                            size: 50,
                            color: AppColors.white,
                          ),
                        ),
                        SizedBox(height: 16),
                        Text(
                          'Kamar ${tenant['room_number'] ?? '-'}',
                          style: AppTextStyles.h2.copyWith(
                            color: AppColors.white,
                            fontWeight: FontWeight.bold,
                            shadows: [
                              Shadow(
                                color: Colors.black.withOpacity(0.2),
                                offset: Offset(0, 2),
                                blurRadius: 4,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          Padding(
            padding: EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Kamar ${tenant['room_number'] ?? '-'}', style: AppTextStyles.h3),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        (tenant['type'] ?? 'Standard').toString().toUpperCase(),
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                
                SizedBox(height: 16),
                
                Text('Fasilitas', style: AppTextStyles.label),
                SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: facilities.map((f) => _buildFacilityChip(f.trim())).toList(),
                ),
                
                SizedBox(height: 16),
                
                Row(
                  children: [
                    Icon(Icons.calendar_today, size: 16, color: AppColors.textSecondary),
                    SizedBox(width: 8),
                    Text(
                      'Masuk: $formattedDate',
                      style: AppTextStyles.bodySmall,
                    ),
                  ],
                ),
                
                SizedBox(height: 16),
                
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const MaintenanceReportScreen(),
                            ),
                          );
                        },
                        icon: Icon(Icons.report_problem_outlined),
                        label: Text('Lapor Kerusakan'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.textPrimary,
                          side: BorderSide(color: AppColors.greyLight),
                        ),
                      ),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {},
                        icon: Icon(Icons.description_outlined),
                        label: Text('Tata Tertib'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.textPrimary,
                          side: BorderSide(color: AppColors.greyLight),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFacilityChip(String label) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.backgroundLight,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: AppTextStyles.bodySmall.copyWith(
          color: AppColors.textPrimary,
        ),
      ),
    );
  }

  Widget _buildQuickActions() {
    return Row(
      children: [
        Expanded(
          child: _buildActionCard(
            'Riwayat Pembayaran',
            Icons.history,
            AppColors.info,
            () {
              // Navigate to payment history tab
              setState(() {
                _selectedIndex = 2; // Index for Riwayat tab
              });
            },
          ),
        ),
        SizedBox(width: 12),
        Expanded(
          child: _buildActionCard(
            'Hubungi Admin',
            Icons.chat_bubble_outline,
            AppColors.success,
            () {
              // Navigate to general chat screen
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const GeneralChatScreen(),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
  
  Widget _buildPaymentHistoryList(List<dynamic> history) {
    return Column(
      children: history.map((payment) {
          final createdAt = payment['paid_at'] != null 
              ? DateTime.parse(payment['paid_at']) 
              : DateTime.now(); // Fallback if pending
              
          final status = payment['payment_status'] ?? 'success';
          final isPending = status == 'pending';
          final isFailed = status == 'failed';

          Color statusColor = AppColors.success;
          String statusText = 'Berhasil';
          
          if (isPending) {
              statusColor = AppColors.warning;
              statusText = 'Menunggu';
          } else if (isFailed) {
              statusColor = AppColors.danger;
              statusText = 'Gagal';
          }

          return Container(
            margin: EdgeInsets.only(bottom: 12),
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.greyLight),
            ),
            child: Column(
              children: [
                Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                        Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                                Text(payment['description']?.toString() ?? 'Pembayaran', style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.bold)),
                                Text(DateFormat('d MMM yyy').format(createdAt), style: AppTextStyles.caption),
                            ],
                        ),
                        Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                                Text(
                                    NumberFormat.currency(locale: 'id', symbol: 'Rp ', decimalDigits: 0).format(
                                      double.tryParse((payment['payment_amount'] ?? payment['total'])?.toString() ?? '0') ?? 0
                                    ),
                                    style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textPrimary, fontWeight: FontWeight.bold),
                                ),
                                SizedBox(height: 4),
                                Container(
                                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                        color: statusColor.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(4)
                                    ),
                                    child: Text(statusText, style: TextStyle(color: statusColor, fontSize: 10, fontWeight: FontWeight.bold))
                                )
                            ],
                        ),
                    ],
                ),
                if (isPending) ...[
                    SizedBox(height: 12),
                    SizedBox(
                        width: double.infinity,
                        child: OutlinedButton(
                            onPressed: () async {
                                final token = payment['midtrans_transaction_id'];
                                if (token != null && token.toString().isNotEmpty) {
                                    final urlString = 'https://app.sandbox.midtrans.com/snap/v2/vtweb/$token';
                                    final url = Uri.parse(urlString);
                                    
                                    try {
                                        // Try launching directly without checking canLaunchUrl first
                                        // as it can sometimes be unreliable on certain platforms/configurations
                                        if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
                                           throw 'Could not launch $urlString';
                                        }
                                    } catch (e) {
                                        if (context.mounted) {
                                            ScaffoldMessenger.of(context).showSnackBar(
                                                SnackBar(content: Text('Gagal membuka pembayaran: $e'))
                                            );
                                        }
                                        debugPrint('Payment Launch Error: $e');
                                    }
                                } else {
                                    if (context.mounted) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(content: Text('Token pembayaran belum tersedia. Coba refresh.'))
                                        );
                                    }
                                }
                            },
                             style: OutlinedButton.styleFrom(
                                foregroundColor: AppColors.warning,
                                side: BorderSide(color: AppColors.warning),
                                visualDensity: VisualDensity.compact
                            ),
                            child: Text('Lanjutkan Pembayaran')
                        ),
                    )
                ]
              ],
            ),
          );
      }).toList(),
    );
  }

  Widget _buildActionCard(String title, IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.greyLight),
        ),
        child: Column(
          children: [
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            SizedBox(height: 12),
            Text(
              title,
              textAlign: TextAlign.center,
              style: AppTextStyles.bodySmall,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomNavBar() {
    return BottomNavigationBar(
      currentIndex: _selectedIndex,
      onTap: (index) {
        setState(() {
          _selectedIndex = index;
        });
      },
      type: BottomNavigationBarType.fixed,
      selectedItemColor: AppColors.primary,
      unselectedItemColor: AppColors.textSecondary,
      items: [
        BottomNavigationBarItem(icon: Icon(Icons.home_outlined), label: 'Beranda'),
        BottomNavigationBarItem(icon: Icon(Icons.receipt_long_outlined), label: 'Tagihan'),
        BottomNavigationBarItem(icon: Icon(Icons.history), label: 'Riwayat'),
        BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: 'Profil'),
      ],
    );
  }
}
