import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/colors.dart';
import '../../../core/constants/text_styles.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../core/services/dashboard_service.dart';
import '../../../core/services/maintenance_service.dart';
import 'maintenance_management_screen.dart';
import 'admin_chat_screen.dart';
import 'admin_profile_screen.dart';

class DashboardAdminScreen extends StatefulWidget {
  const DashboardAdminScreen({Key? key}) : super(key: key);

  @override
  State<DashboardAdminScreen> createState() => _DashboardAdminScreenState();
}

class _DashboardAdminScreenState extends State<DashboardAdminScreen> {
  int _selectedIndex = 0;
  final DashboardService _dashboardService = DashboardService();
  final MaintenanceService _maintenanceService = MaintenanceService();
  bool _isLoading = true;
  int _pendingReportsCount = 0;
  Map<String, dynamic> _stats = {
    'totalRooms': 0,
    'occupiedRooms': 0,
    'emptyRooms': 0,
    'activeTenants': 0,
    'occupancyRate': 0,
    'totalIncome': 0,
    'totalExpense': 0,
    'netIncome': 0,
    'pendingInvoices': 0,
  };

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final data = await _dashboardService.getDashboardStats();
      final pendingCount = await _maintenanceService.getPendingCount();
      setState(() {
        // Flatten the nested API response to match UI expectations
        _stats = {
          'totalRooms': data['rooms']?['total'] ?? 0,
          'occupiedRooms': data['rooms']?['occupied'] ?? 0,
          'emptyRooms': data['rooms']?['available'] ?? 0,
          'activeTenants': data['tenants']?['active'] ?? 0,
          'occupancyRate': data['rooms']?['occupancyRate'] ?? 0,
          'totalIncome': data['financial']?['monthlyIncome'] ?? 0,
          'totalExpense': data['financial']?['monthlyExpense'] ?? 0,
          'netIncome': data['financial']?['netIncome'] ?? 0,
          'pendingInvoices': data['invoices']?['pending'] ?? 0,
        };
        _pendingReportsCount = pendingCount;
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
        title: Text('Dashboard Admin'),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _loadData,
          ),
          IconButton(
            icon: Badge(
              label: Text(_pendingReportsCount.toString()),
              isLabelVisible: _pendingReportsCount > 0,
              child: Icon(Icons.notifications_outlined),
            ),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const MaintenanceManagementScreen(),
                ),
              ).then((_) => _loadData()); // Refresh after returning
            },
          ),
           SizedBox(width: 8),
          IconButton(
            icon: Icon(Icons.account_circle),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const AdminProfileScreen(),
                ),
              );
            },
          ),
          SizedBox(width: 8),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              child: SingleChildScrollView(
                physics: AlwaysScrollableScrollPhysics(),
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Greeting
                    Text(
                      'Selamat Datang, Admin 👋',
                      style: AppTextStyles.h2,
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Berikut ringkasan properti Anda hari ini',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    
                    SizedBox(height: 24),
                    
                    // Financial Summary Card
                    _buildFinancialSummaryCard(),
                    
                    SizedBox(height: 16),
                    
                    // Stats Grid
                    Row(
                      children: [
                        Expanded(
                          child: _buildStatCard(
                            'Kamar Terisi',
                            _stats['occupiedRooms'].toString(),
                            '${_stats['occupancyRate']}%',
                            AppColors.success,
                            Icons.meeting_room,
                          ),
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: _buildStatCard(
                            'Kamar Kosong',
                            _stats['emptyRooms'].toString(),
                            'Available',
                            AppColors.warning,
                            Icons.door_back_door_outlined,
                          ),
                        ),
                      ],
                    ),
                    
                    SizedBox(height: 12),
                    
                    Row(
                      children: [
                        Expanded(
                          child: _buildStatCard(
                            'Penghuni Aktif',
                            _stats['activeTenants'].toString(),
                            'Total',
                            AppColors.info,
                            Icons.people_outline,
                          ),
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: _buildStatCard(
                            'Tagihan Pending',
                            _stats['pendingInvoices'].toString(),
                            'Perlu tindakan',
                            AppColors.danger,
                            Icons.receipt_long_outlined,
                          ),
                        ),
                      ],
                    ),
                    
                    SizedBox(height: 24),
                    
                    // Occupancy Chart
                    Text(
                      'Tingkat Hunian',
                      style: AppTextStyles.h3,
                    ),
                    SizedBox(height: 16),
                    _buildOccupancyChart(),
                    
                    SizedBox(height: 24),
                    
                    // Financial Trend
                    Text(
                      'Tren Keuangan',
                      style: AppTextStyles.h3,
                    ),
                    SizedBox(height: 16),
                    _buildFinancialTrendChart(),
                    
                    SizedBox(height: 24),
                    
                  ],
                ),
              ),
            ),
      bottomNavigationBar: _buildBottomNavBar(),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _showQuickActions();
        },
        backgroundColor: AppColors.primary,
        child: Icon(Icons.add, color: AppColors.textPrimary),
      ),
    );
  }

  Widget _buildFinancialSummaryCard() {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary, AppColors.primaryDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.3),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Keuntungan Bersih',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textPrimary,
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.success.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    Icon(Icons.trending_up, size: 16, color: AppColors.success),
                    SizedBox(width: 4),
                    Text(
                      '+12.5%', // Placeholder for trend
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.success,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
          Text(
            _formatCurrency(_stats['netIncome']),
            style: AppTextStyles.h1.copyWith(
              color: AppColors.textPrimary,
              fontSize: 32,
            ),
          ),
          SizedBox(height: 16),
          Divider(color: AppColors.textPrimary.withOpacity(0.2)),
          SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Pemasukan',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.textPrimary.withOpacity(0.7),
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      _formatCurrency(_stats['totalIncome']),
                      style: AppTextStyles.h4.copyWith(
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Pengeluaran',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.textPrimary.withOpacity(0.7),
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      _formatCurrency(_stats['totalExpense']),
                      style: AppTextStyles.h4.copyWith(
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    String subtitle,
    Color color,
    IconData icon,
  ) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
            ],
          ),
          SizedBox(height: 12),
          Text(
            value,
            style: AppTextStyles.h2,
          ),
          SizedBox(height: 4),
          Text(
            title,
            style: AppTextStyles.bodySmall,
          ),
          SizedBox(height: 4),
          Text(
            subtitle,
            style: AppTextStyles.caption.copyWith(
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOccupancyChart() {
    final double occupied = (_stats['occupiedRooms'] as num).toDouble();
    final double empty = (_stats['emptyRooms'] as num).toDouble();
    final double total = occupied + empty;
    
    // Prevent division by zero
    if (total == 0) {
      return Container(
        height: 200,
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(child: Text("Belum ada data kamar")),
      );
    }

    final occupiedPercentage = (occupied / total * 100).toStringAsFixed(1);
    final emptyPercentage = (empty / total * 100).toStringAsFixed(1);

    return Container(
      height: 200,
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: PieChart(
        PieChartData(
          sectionsSpace: 2,
          centerSpaceRadius: 50,
          sections: [
            PieChartSectionData(
              value: occupied,
              title: '$occupiedPercentage%',
              color: AppColors.success,
              radius: 50,
              titleStyle: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            PieChartSectionData(
              value: empty,
              title: '$emptyPercentage%',
              color: AppColors.greyLight,
              radius: 50,
              titleStyle: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFinancialTrendChart() {
    return Container(
      height: 200,
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: LineChart(
        LineChartData(
          gridData: FlGridData(show: false),
          titlesData: FlTitlesData(show: false),
          borderData: FlBorderData(show: false),
          lineBarsData: [
            LineChartBarData(
              spots: [
                FlSpot(0, 3),
                FlSpot(1, 4),
                FlSpot(2, 3.5),
                FlSpot(3, 5),
                FlSpot(4, 4.5),
                FlSpot(5, 6),
              ],
              isCurved: true,
              color: AppColors.primary,
              barWidth: 3,
              dotData: FlDotData(show: true),
              belowBarData: BarAreaData(
                show: true,
                color: AppColors.primary.withOpacity(0.1),
              ),
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
        
        switch (index) {
          case 0:
            // Do nothing, already here
            break;
          case 1:
            // Navigate to Financial Screen
            Navigator.pushNamed(context, '/financial');
            break;
          case 2:
            // Navigate to Room Management (Push instead of Replacement to keep back stack)
            Navigator.pushNamed(context, '/rooms');
            break;
          case 3:
             // Navigate to Tenant Management
             Navigator.pushNamed(context, '/tenants');
            break;
        }
      },
      type: BottomNavigationBarType.fixed,
      selectedItemColor: AppColors.primary,
      unselectedItemColor: AppColors.textSecondary,
      items: [
        BottomNavigationBarItem(icon: Icon(Icons.dashboard_outlined), label: 'Dashboard'),
        BottomNavigationBarItem(icon: Icon(Icons.account_balance_wallet_outlined), label: 'Keuangan'),
        BottomNavigationBarItem(icon: Icon(Icons.meeting_room_outlined), label: 'Kamar'),
        BottomNavigationBarItem(icon: Icon(Icons.people_outline), label: 'Penghuni'),
      ],
    );
  }

  void _showQuickActions() {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Aksi Cepat', style: AppTextStyles.h3),
              SizedBox(height: 24),
              ListTile(
                leading: Icon(Icons.person_add, color: AppColors.primary),
                title: Text('Tambah Penghuni Baru'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.pushNamed(context, '/tenants');
                },
              ),
              ListTile(
                leading: Icon(Icons.receipt, color: AppColors.primary),
                title: Text('Buat Tagihan'),
                onTap: () {
                   Navigator.pop(context);
                   Navigator.pushNamed(context, '/financial');
                },
              ),
              ListTile(
                leading: Icon(Icons.add_home, color: AppColors.primary),
                title: Text('Tambah Kamar'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.pushNamed(context, '/rooms');
                },
              ),
              ListTile(
                leading: Icon(Icons.build_outlined, color: AppColors.primary),
                title: Text('Kelola Laporan Kerusakan'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const MaintenanceManagementScreen(),
                    ),
                  );
                },
              ),
              ListTile(
                leading: Icon(Icons.chat_bubble_outline, color: AppColors.primary),
                title: Text('Pesan Tenant'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const AdminTenantChatListScreen(),
                    ),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }
}
