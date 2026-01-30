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
  List<Map<String, dynamic>> _trendData = [];
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
      final trend = await _dashboardService.getFinancialTrend();
      setState(() {
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
        _trendData = List<Map<String, dynamic>>.from(trend);
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
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        title: Text('Dashboard', style: AppTextStyles.h3),
        backgroundColor: AppColors.white,
        elevation: 0,
        scrolledUnderElevation: 2,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _loadData,
          ),
          IconButton(
            icon: Badge(
              label: Text(_pendingReportsCount.toString()),
              isLabelVisible: _pendingReportsCount > 0,
              backgroundColor: AppColors.danger,
              child: const Icon(Icons.notifications_outlined),
            ),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const MaintenanceManagementScreen(),
                ),
              ).then((_) => _loadData());
            },
          ),
          const SizedBox(width: 8),
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: CircleAvatar(
              backgroundColor: AppColors.backgroundLight,
              child: IconButton(
                icon: const Icon(Icons.person_outline, color: AppColors.textPrimary),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const AdminProfileScreen(),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Ringkasan Properti',
                      style: AppTextStyles.h4,
                    ),
                    const SizedBox(height: 16),
                    
                    // Financial Summary Card
                    _buildFinancialSummaryCard(),
                    
                    const SizedBox(height: 24),
                    
                    // Stats Grid
                    Row(
                      children: [
                        Expanded(
                          child: _buildStatCard(
                            'Kamar Terisi',
                            _stats['occupiedRooms'].toString(),
                            '${_stats['occupancyRate']}% Full',
                            AppColors.success,
                            Icons.meeting_room_rounded,
                          ),
                        ),
                        const SizedBox(width: 16),
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
                    
                    const SizedBox(height: 16),
                    
                    Row(
                      children: [
                        Expanded(
                          child: _buildStatCard(
                            'Penghuni Aktif',
                            _stats['activeTenants'].toString(),
                            'Total Tenant',
                            AppColors.info,
                            Icons.people_alt_outlined,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildStatCard(
                            'Tagihan Pending',
                            _stats['pendingInvoices'].toString(),
                            'Perlu Tindakan',
                            AppColors.danger,
                            Icons.receipt_long_rounded,
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 32),
                    
                    // Charts Section
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Analisis', style: AppTextStyles.h4),
                      ],
                    ),
                    const SizedBox(height: 16),
                    
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: AppColors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppColors.divider),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Tingkat Hunian', style: AppTextStyles.h4),
                          const SizedBox(height: 24),
                          _buildOccupancyChart(),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: AppColors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppColors.divider),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Tren Keuangan', style: AppTextStyles.h4),
                          const SizedBox(height: 24),
                          _buildFinancialTrendChart(),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
      bottomNavigationBar: _buildBottomNavBar(),
      floatingActionButton: FloatingActionButton(
        onPressed: _showQuickActions,
        backgroundColor: AppColors.accent,
        elevation: 4,
        child: const Icon(Icons.add_rounded, color: AppColors.white, size: 28),
      ),
    );
  }

  Widget _buildFinancialSummaryCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primary, AppColors.primaryDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.25),
            blurRadius: 20,
            offset: const Offset(0, 10),
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
                'Profit Bersih (Bulan Ini)',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.white.withOpacity(0.8),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.success.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.success.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.trending_up, size: 14, color: AppColors.success),
                    const SizedBox(width: 4),
                    Text(
                      'Stabil',
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.success,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            _formatCurrency(_stats['netIncome']),
            style: AppTextStyles.h1.copyWith(
              color: AppColors.white,
              fontSize: 36,
              letterSpacing: -1,
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Pemasukan',
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.white.withOpacity(0.6),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _formatCurrency(_stats['totalIncome']),
                      style: AppTextStyles.h4.copyWith(
                        color: AppColors.white,
                        fontSize: 18,
                      ),
                    ),
                  ],
                ),
              ),
              Container(width: 1, height: 40, color: AppColors.white.withOpacity(0.1)),
              const SizedBox(width: 24),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Pengeluaran',
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.white.withOpacity(0.6),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _formatCurrency(_stats['totalExpense']),
                      style: AppTextStyles.h4.copyWith(
                        color: AppColors.white,
                        fontSize: 18,
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
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.divider),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF64748B).withOpacity(0.04), // Soft slate shadow
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(height: 16),
          Text(
            value,
            style: AppTextStyles.h2.copyWith(fontSize: 28),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: AppTextStyles.caption.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
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
    
    if (total == 0) {
      return SizedBox(
        height: 200,
        child: Center(
          child: Text(
            "Belum ada data kamar",
            style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
          ),
        ),
      );
    }

    return SizedBox(
      height: 220,
      child: PieChart(
        PieChartData(
          sectionsSpace: 4,
          centerSpaceRadius: 40,
          sections: [
            PieChartSectionData(
              value: occupied,
              title: '${(occupied/total*100).toStringAsFixed(0)}%',
              color: AppColors.accent,
              radius: 60,
              titleStyle: AppTextStyles.bodyLarge.copyWith(
                color: AppColors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            PieChartSectionData(
              value: empty,
              title: '${(empty/total*100).toStringAsFixed(0)}%',
              color: AppColors.divider, // Use divider color for empty
              showTitle: true,
              radius: 50,
              titleStyle: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFinancialTrendChart() {
    if (_trendData.isEmpty) {
      return SizedBox(
        height: 200,
        child: Center(
          child: Text(
            'Belum ada data transaksi',
            style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
          ),
        ),
      );
    }

    // Convert trend data to chart spots
    final spots = _trendData.asMap().entries.map((entry) {
      final index = entry.key;
      final data = entry.value;
      final income = double.tryParse(data['income'].toString()) ?? 0;
      final expense = double.tryParse(data['expense'].toString()) ?? 0;
      final net = income - expense;
      return FlSpot(index.toDouble(), net / 1000000); // Convert to millions for better display
    }).toList();

    return SizedBox(
      height: 200,
      child: LineChart(
        LineChartData(
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: 1,
            getDrawingHorizontalLine: (value) {
              return FlLine(
                color: AppColors.divider.withOpacity(0.5),
                strokeWidth: 1,
              );
            },
          ),
          titlesData: FlTitlesData(
            show: true,
            rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          borderData: FlBorderData(show: false),
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              color: AppColors.accent,
              barWidth: 4,
              isStrokeCapRound: true,
              dotData: FlDotData(
                show: true,
                getDotPainter: (spot, percent, barData, index) {
                  return FlDotCirclePainter(
                    radius: 4,
                    color: AppColors.white,
                    strokeWidth: 2,
                    strokeColor: AppColors.accent,
                  );
                },
              ),
              belowBarData: BarAreaData(
                show: true,
                color: AppColors.accent.withOpacity(0.1),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomNavBar() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        border: Border(top: BorderSide(color: AppColors.divider, width: 1)),
      ),
      child: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) {
          setState(() {
            _selectedIndex = index;
          });
          switch (index) {
            case 1:
              Navigator.pushNamed(context, '/financial');
              break;
            case 2:
              Navigator.pushNamed(context, '/rooms');
              break;
            case 3:
               Navigator.pushNamed(context, '/tenants');
              break;
          }
        },
        backgroundColor: AppColors.white,
        elevation: 0,
        indicatorColor: AppColors.primary.withOpacity(0.1),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard, color: AppColors.primary),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.account_balance_wallet_outlined),
            selectedIcon: Icon(Icons.account_balance_wallet, color: AppColors.primary),
            label: 'Keuangan',
          ),
          NavigationDestination(
            icon: Icon(Icons.meeting_room_outlined),
            selectedIcon: Icon(Icons.meeting_room, color: AppColors.primary),
            label: 'Kamar',
          ),
          NavigationDestination(
            icon: Icon(Icons.people_outlined),
            selectedIcon: Icon(Icons.people, color: AppColors.primary),
            label: 'Penghuni',
          ),
        ],
      ),
    );
  }

  void _showQuickActions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      backgroundColor: AppColors.white,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(24),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.divider,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Text('Aksi Cepat', style: AppTextStyles.h3),
                const SizedBox(height: 24),
                _buildQuickActionItem(
                  Icons.person_add_rounded, 'Tambah Penghuni', () {
                  Navigator.pop(context);
                  Navigator.pushNamed(context, '/tenants');
                }),
                _buildQuickActionItem(
                  Icons.receipt_long_rounded, 'Buat Tagihan', () {
                   Navigator.pop(context);
                   Navigator.pushNamed(context, '/financial');
                }),
                _buildQuickActionItem(
                  Icons.add_home_rounded, 'Tambah Kamar', () {
                  Navigator.pop(context);
                  Navigator.pushNamed(context, '/rooms');
                }),
                _buildQuickActionItem(
                  Icons.build_rounded, 'Laporan & Maintenance', () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const MaintenanceManagementScreen(),
                    ),
                  );
                }),
                _buildQuickActionItem(
                  Icons.chat_bubble_rounded, 'Pesan Tenant', () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const AdminTenantChatListScreen(),
                    ),
                  );
                }),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildQuickActionItem(IconData icon, String title, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.backgroundLight,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: AppColors.primary, size: 24),
              ),
              const SizedBox(width: 16),
              Text(
                title,
                style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600),
              ),
              const Spacer(),
              Icon(Icons.chevron_right, color: AppColors.textSecondary),
            ],
          ),
        ),
      ),
    );
  }
}
