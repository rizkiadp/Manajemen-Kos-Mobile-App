import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../core/constants/colors.dart';
import '../../../core/constants/text_styles.dart';
import '../../widgets/common/custom_button.dart';
import '../../widgets/common/custom_text_field.dart';
import '../../../core/services/transaction_service.dart';
import '../../../core/services/tenant_service.dart';
import '../../../core/services/dashboard_service.dart';

class FinancialScreen extends StatefulWidget {
  const FinancialScreen({Key? key}) : super(key: key);

  @override
  State<FinancialScreen> createState() => _FinancialScreenState();
}

class _FinancialScreenState extends State<FinancialScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TransactionService _transactionService = TransactionService();
  bool _isLoading = true;
  List<Map<String, dynamic>> _transactions = [];
  Map<String, dynamic> _summary = {
    'income': {'total': 0},
    'expense': {'total': 0},
    'net': 0,
  };
  List<dynamic> _trendData = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final transactions = await _transactionService.getTransactions();
      final summary = await _transactionService.getTransactionSummary();
      final trend = await DashboardService().getFinancialTrend();
      
      setState(() {
        _transactions = transactions;
        _summary = summary;
        _trendData = trend;
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
        title: Text('Keuangan'),
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textSecondary,
          indicatorColor: AppColors.primary,
          tabs: [
            Tab(text: 'Ringkasan'),
            Tab(text: 'Riwayat Transaksi'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildSummaryTab(),
          _buildHistoryTab(),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showCreateInvoiceDialog,
        backgroundColor: AppColors.primary,
        icon: Icon(Icons.add, color: AppColors.white),
        label: Text('Buat Tagihan', style: TextStyle(color: AppColors.white, fontWeight: FontWeight.w600)),
      ),
    );
  }

  Widget _buildSummaryTab() {
    return RefreshIndicator(
      onRefresh: _loadData,
      child: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        physics: AlwaysScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildFinancialSummaryCard(),
            SizedBox(height: 24),
            Text('Pemasukan vs Pengeluaran', style: AppTextStyles.h3),
            SizedBox(height: 16),
            _buildFinancialChart(),
          ],
        ),
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
          Text(
            'Total Saldo (Net)',
            style: AppTextStyles.bodyMedium.copyWith(color: AppColors.white),
          ),
          SizedBox(height: 8),
          Text(
            _formatCurrency(_summary['net']),
            style: AppTextStyles.h1.copyWith(color: AppColors.white, fontSize: 32),
          ),
          SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.arrow_downward, color: AppColors.success, size: 16),
                        SizedBox(width: 4),
                        Text('Pemasukan', style: AppTextStyles.bodySmall.copyWith(color: AppColors.white.withOpacity(0.8))),
                      ],
                    ),
                    SizedBox(height: 4),
                    Text(
                      _formatCurrency(_summary['income']?['total']),
                      style: AppTextStyles.h4.copyWith(color: AppColors.white),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.arrow_upward, color: AppColors.danger, size: 16),
                        SizedBox(width: 4),
                        Text('Pengeluaran', style: AppTextStyles.bodySmall.copyWith(color: AppColors.white.withOpacity(0.8))),
                      ],
                    ),
                    SizedBox(height: 4),
                    Text(
                      _formatCurrency(_summary['expense']?['total']),
                      style: AppTextStyles.h4.copyWith(color: AppColors.white),
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

  Widget _buildFinancialChart() {
    if (_trendData.isEmpty) {
      return Container(
        height: 300,
        decoration: BoxDecoration(color: AppColors.white, borderRadius: BorderRadius.circular(16)),
        child: Center(child: Text("Belum ada data tren")),
      );
    }

    return Container(
      height: 300,
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: _TrendMaxY(),
          barTouchData: BarTouchData(
            touchTooltipData: BarTouchTooltipData(
              tooltipBgColor: Colors.blueGrey,
              getTooltipItem: (group, groupIndex, rod, rodIndex) {
                 return BarTooltipItem(
                   _formatCurrency(rod.toY),
                   const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 10),
                 );
              }
            ),
          ),
          titlesData: FlTitlesData(
            show: true,
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (double value, TitleMeta meta) {
                  if (value.toInt() >= 0 && value.toInt() < _trendData.length) {
                     return SideTitleWidget(
                       axisSide: meta.axisSide, 
                       child: Text(_trendData[value.toInt()]['month'].toString().substring(5), style: TextStyle(fontSize: 10))
                     );
                  }
                  return Container();
                },
              ),
            ),
            leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          gridData: FlGridData(show: false),
          borderData: FlBorderData(show: false),
          barGroups: _trendData.asMap().entries.map((entry) {
            final index = entry.key;
            final data = entry.value;
            return BarChartGroupData(
              x: index,
              barRods: [
                BarChartRodData(toY: double.tryParse(data['income'].toString()) ?? 0, color: AppColors.success, width: 12),
                BarChartRodData(toY: double.tryParse(data['expense'].toString()) ?? 0, color: AppColors.danger, width: 12),
              ]
            );
          }).toList(),
        ),
      ),
    );
  }
  
  double _TrendMaxY() {
      double max = 0;
      for (var item in _trendData) {
          double inc = double.tryParse(item['income'].toString()) ?? 0;
          double exp = double.tryParse(item['expense'].toString()) ?? 0;
          if (inc > max) max = inc;
          if (exp > max) max = exp;
      }
      return max * 1.2; // Add 20% buffer
  }

  Widget _buildHistoryTab() {
    if (_isLoading) {
      return Center(child: CircularProgressIndicator());
    }

    if (_transactions.isEmpty) {
      return RefreshIndicator(
        onRefresh: _loadData,
        child: Center(child: Text('Belum ada transaksi')),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView.builder(
      padding: EdgeInsets.all(16),
      itemCount: _transactions.length,
      itemBuilder: (context, index) {
        final transaction = _transactions[index];
        final isIncome = transaction['type'] == 'income';
        final amount = (double.tryParse(transaction['amount'].toString()) ?? 0).toInt();
        final date = DateTime.tryParse(transaction['date'] ?? '') ?? DateTime.now();
        
        return Container(
          margin: EdgeInsets.only(bottom: 12),
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.greyLight),
          ),
          child: Row(
            children: [
              Container(
                padding: EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: isIncome ? AppColors.success.withOpacity(0.1) : AppColors.danger.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isIncome ? Icons.arrow_downward : Icons.arrow_upward,
                  color: isIncome ? AppColors.success : AppColors.danger,
                ),
              ),
              SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      transaction['description'] ?? 'Transaksi',
                      style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600),
                    ),
                    SizedBox(height: 4),
                    Text(
                      DateFormat('dd MMM yyyy, HH:mm').format(date),
                      style: AppTextStyles.caption,
                    ),
                  ],
                ),
              ),
              Text(
                (isIncome ? '+ ' : '- ') + _formatCurrency(amount),
                style: AppTextStyles.bodyMedium.copyWith(
                  fontWeight: FontWeight.bold,
                  color: isIncome ? AppColors.success : AppColors.danger,
                ),
              ),
            ],
          ),
        );
      },
      ),
    );
  }

  void _showCreateInvoiceDialog() {
    final _tenantService = TenantService();
    // Assuming InvoiceService is merged into TransactionService or separate? 
    // Based on implementation plan, we put invoice creation in TransactionService.
    
    int? selectedTenantId;
    List<Map<String, dynamic>> activeTenants = [];
    bool isLoadingTenants = true;
    bool isSubmitting = false;
    
    // Default invoice items
    List<Map<String, dynamic>> items = [
      {'description': 'Sewa Kamar', 'amount': 0},
      {'description': 'Listrik', 'amount': 0},
      {'description': 'Air', 'amount': 0},
    ];

    final dueDateController = TextEditingController(
      text: DateFormat('yyyy-MM-dd').format(DateTime.now().add(Duration(days: 7)))
    );

    void loadTenants(StateSetter setDialogState) async {
      try {
        final tenants = await _tenantService.getActiveTenants();
        setDialogState(() {
          activeTenants = tenants;
          isLoadingTenants = false;
        });
      } catch (e) {
        setDialogState(() => isLoadingTenants = false);
      }
    }

    void updateTenantDefaultAmount(int tenantId, StateSetter setDialogState) {
        // Find tenant room price to auto-fill 'Sewa Kamar'
        final tenant = activeTenants.firstWhere((t) => t['id'] == tenantId, orElse: () => {});
        if (tenant.isNotEmpty && tenant['room_price'] != null) {
            setDialogState(() {
               // Parse room_price safely (handle String or int from JSON)
               int price = 0;
               if (tenant['room_price'] is int) {
                 price = tenant['room_price'];
               } else if (tenant['room_price'] is String) {
                 price = double.tryParse(tenant['room_price'])?.toInt() ?? 0;
               } else if (tenant['room_price'] is double) {
                 price = (tenant['room_price'] as double).toInt();
               }
               items[0]['amount'] = price;
            });
        }
    }

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          if (isLoadingTenants && activeTenants.isEmpty) {
            loadTenants(setDialogState);
          }

          return AlertDialog(
            title: Text('Buat Tagihan Baru'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Pilih Penghuni', style: AppTextStyles.bodySmall),
                  if (isLoadingTenants)
                    LinearProgressIndicator()
                  else if (activeTenants.isEmpty)
                    Text('Tidak ada penghuni aktif', style: TextStyle(color: AppColors.danger))
                  else
                    DropdownButtonFormField<int>(
                      value: selectedTenantId,
                       decoration: InputDecoration(
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                      hint: Text('Pilih Penghuni'),
                      items: activeTenants.map((t) {
                        return DropdownMenuItem<int>(
                          value: t['id'],
                          child: Text('${t['name']} (Kamar ${t['room_number']})'),
                        );
                      }).toList(),
                      onChanged: (val) {
                          setDialogState(() => selectedTenantId = val);
                          if (val != null) updateTenantDefaultAmount(val, setDialogState);
                      },
                    ),
                  SizedBox(height: 12),
                  CustomTextField(
                    label: 'Jatuh Tempo',
                    controller: dueDateController,
                    hint: 'YYYY-MM-DD',
                  ),
                  SizedBox(height: 16),
                  Text('Rincian Tagihan', style: AppTextStyles.h4),
                  SizedBox(height: 8),
                  ...items.asMap().entries.map((entry) {
                    final index = entry.key;
                    final item = entry.value;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8.0),
                      child: Row(
                        key: ValueKey('item_$index'), // Key to maintain state
                        children: [
                          Expanded(
                            flex: 2,
                            child: TextFormField(
                              initialValue: item['description'],
                              decoration: InputDecoration(hintText: 'Item'),
                              onChanged: (val) => item['description'] = val,
                            ),
                          ),
                          SizedBox(width: 8),
                          Expanded(
                            child: TextFormField(
                              key: ValueKey(item['amount']), // Key forces rebuild when amount changes
                              initialValue: item['amount'].toString(),
                              decoration: InputDecoration(prefixText: 'Rp '),
                              keyboardType: TextInputType.number,
                              onChanged: (val) => item['amount'] = int.tryParse(val) ?? 0,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                  TextButton.icon(
                      onPressed: () {
                          setDialogState(() {
                              items.add({'description': '', 'amount': 0});
                          });
                      }, 
                      icon: Icon(Icons.add), 
                      label: Text('Tambah Item')
                  ),
                  SizedBox(height: 12),
                  Text(
                      'Total: ${_formatCurrency(items.fold(0, (sum, item) => sum + (int.tryParse(item['amount'].toString()) ?? 0)))}',
                      style: AppTextStyles.h3.copyWith(color: AppColors.primary),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('Batal'),
              ),
              ElevatedButton(
                onPressed: (isSubmitting || selectedTenantId == null)
                    ? null
                    : () async {
                        setDialogState(() => isSubmitting = true);
                        try {
                          await _transactionService.createInvoice({
                            'tenant_id': selectedTenantId,
                            'due_date': dueDateController.text,
                            'items': items,
                          });
                          Navigator.pop(context); // Close dialog
                          // TODO: Switch to invoice tab if we had one, or Refresh summary
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Tagihan berhasil dibuat')),
                          );
                        } catch (e) {
                          setDialogState(() => isSubmitting = false);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Gagal: ${e.toString().replaceAll('Exception: ', '')}')),
                          );
                        }
                      },
                child: isSubmitting ? SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white)) : Text('Buat Tagihan'),
              ),
            ],
          );
        },
      ),
    );
  }
}
