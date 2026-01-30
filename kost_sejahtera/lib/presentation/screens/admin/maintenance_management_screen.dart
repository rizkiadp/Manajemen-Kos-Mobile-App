import 'package:flutter/material.dart';
import '../../../core/services/maintenance_service.dart';
import '../../../core/constants/colors.dart';
import '../../../core/constants/text_styles.dart';
import '../tenant/maintenance_chat_screen.dart';

class MaintenanceManagementScreen extends StatefulWidget {
  const MaintenanceManagementScreen({Key? key}) : super(key: key);

  @override
  State<MaintenanceManagementScreen> createState() => _MaintenanceManagementScreenState();
}

class _MaintenanceManagementScreenState extends State<MaintenanceManagementScreen> {
  final MaintenanceService _maintenanceService = MaintenanceService();
  
  List<dynamic> _reports = [];
  bool _isLoading = false;
  String? _filterStatus;
  String? _filterCategory;

  final List<Map<String, String>> _statuses = [
    {'value': 'pending', 'label': 'Menunggu'},
    {'value': 'in_progress', 'label': 'Diproses'},
    {'value': 'resolved', 'label': 'Selesai'},
    {'value': 'closed', 'label': 'Ditutup'},
  ];

  final List<Map<String, dynamic>> _categories = [
    {'value': 'electrical', 'label': 'Listrik', 'icon': Icons.electrical_services},
    {'value': 'plumbing', 'label': 'Pipa/Air', 'icon': Icons.plumbing},
    {'value': 'furniture', 'label': 'Furniture', 'icon': Icons.chair},
    {'value': 'cleaning', 'label': 'Kebersihan', 'icon': Icons.cleaning_services},
    {'value': 'other', 'label': 'Lainnya', 'icon': Icons.more_horiz},
  ];

  @override
  void initState() {
    super.initState();
    _loadReports();
  }

  Future<void> _loadReports() async {
    setState(() => _isLoading = true);
    try {
      final reports = await _maintenanceService.getReports(
        status: _filterStatus,
        category: _filterCategory,
      );
      setState(() {
        _reports = reports;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal memuat laporan: $e')),
        );
      }
    }
  }

  Future<void> _updateStatus(int reportId, String newStatus) async {
    try {
      await _maintenanceService.updateReportStatus(reportId, newStatus);
      await _loadReports();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Status berhasil diupdate!'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal update status: $e')),
        );
      }
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'pending':
        return Colors.orange;
      case 'in_progress':
        return Colors.blue;
      case 'resolved':
        return Colors.green;
      case 'closed':
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }

  String _getStatusLabel(String status) {
    return _statuses.firstWhere((s) => s['value'] == status, orElse: () => {'label': status})['label']!;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Kelola Laporan Kerusakan'),
      ),
      body: Column(
        children: [
          // Filters
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.grey[100],
            child: Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _filterStatus,
                    decoration: const InputDecoration(
                      labelText: 'Status',
                      border: OutlineInputBorder(),
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    items: [
                      const DropdownMenuItem(value: null, child: Text('Semua')),
                      ..._statuses.map((s) => DropdownMenuItem(
                            value: s['value'],
                            child: Text(s['label']!),
                          )),
                    ],
                    onChanged: (value) {
                      setState(() => _filterStatus = value);
                      _loadReports();
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _filterCategory,
                    decoration: const InputDecoration(
                      labelText: 'Kategori',
                      border: OutlineInputBorder(),
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    items: [
                      const DropdownMenuItem(value: null, child: Text('Semua')),
                      ..._categories.map((c) => DropdownMenuItem(
                            value: c['value'],
                            child: Text(c['label']),
                          )),
                    ],
                    onChanged: (value) {
                      setState(() => _filterCategory = value);
                      _loadReports();
                    },
                  ),
                ),
              ],
            ),
          ),
          // Reports List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : RefreshIndicator(
                    onRefresh: _loadReports,
                    child: _reports.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.inbox, size: 64, color: Colors.grey[400]),
                                const SizedBox(height: 16),
                                Text('Tidak ada laporan', style: AppTextStyles.bodyLarge.copyWith(color: Colors.grey)),
                              ],
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: _reports.length,
                            itemBuilder: (context, index) {
                              final report = _reports[index];
                              return Card(
                                margin: const EdgeInsets.only(bottom: 12),
                                child: ExpansionTile(
                                  leading: CircleAvatar(
                                    backgroundColor: _getStatusColor(report['status']),
                                    child: Icon(
                                      _categories.firstWhere(
                                        (c) => c['value'] == report['category'],
                                        orElse: () => _categories.last,
                                      )['icon'],
                                      color: Colors.white,
                                    ),
                                  ),
                                  title: Text(report['title'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold)),
                                  subtitle: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const SizedBox(height: 4),
                                      Text('Penyewa: ${report['tenant_name'] ?? 'N/A'} - Kamar ${report['room_number'] ?? 'N/A'}'),
                                      const SizedBox(height: 4),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: _getStatusColor(report['status']),
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: Text(
                                          _getStatusLabel(report['status']),
                                          style: const TextStyle(color: Colors.white, fontSize: 12),
                                        ),
                                      ),
                                    ],
                                  ),
                                  children: [
                                    Padding(
                                      padding: const EdgeInsets.all(16),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          const Text('Deskripsi:', style: TextStyle(fontWeight: FontWeight.bold)),
                                          const SizedBox(height: 8),
                                          Text(report['description'] ?? ''),
                                          const SizedBox(height: 16),
                                          const Text('Update Status:', style: TextStyle(fontWeight: FontWeight.bold)),
                                          const SizedBox(height: 8),
                                          Wrap(
                                            spacing: 8,
                                            children: _statuses.map((status) {
                                              return ChoiceChip(
                                                label: Text(status['label']!),
                                                selected: report['status'] == status['value'],
                                                onSelected: (selected) {
                                                  if (selected) {
                                                    _updateStatus(report['id'], status['value']!);
                                                  }
                                                },
                                              );
                                            }).toList(),
                                          ),
                                          const SizedBox(height: 16),
                                          ElevatedButton.icon(
                                            onPressed: () {
                                              Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                  builder: (context) => MaintenanceChatScreen(reportId: report['id']),
                                                ),
                                              );
                                            },
                                            icon: const Icon(Icons.chat),
                                            label: const Text('Chat dengan Penyewa'),
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: AppColors.primary,
                                              foregroundColor: Colors.white,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                  ),
          ),
        ],
      ),
    );
  }
}
