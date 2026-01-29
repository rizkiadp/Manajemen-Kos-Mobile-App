import 'package:flutter/material.dart';
import 'dart:async';
import 'package:intl/intl.dart';
import '../../../core/constants/colors.dart';
import '../../../core/constants/text_styles.dart';
import '../../widgets/common/custom_text_field.dart';
import '../../../core/services/tenant_service.dart';
import '../../../core/services/room_service.dart';

class TenantManagementScreen extends StatefulWidget {
  const TenantManagementScreen({Key? key}) : super(key: key);

  @override
  State<TenantManagementScreen> createState() => _TenantManagementScreenState();
}

class _TenantManagementScreenState extends State<TenantManagementScreen> {
  final TenantService _tenantService = TenantService();
  final RoomService _roomService = RoomService();
  String _searchQuery = '';
  String _selectedFilter = 'Semua';
  bool _isLoading = true;
  List<Map<String, dynamic>> _tenants = [];
  Timer? _debounce;

  final List<String> filters = ['Semua', 'Aktif', 'Tidak Aktif'];

  @override
  void initState() {
    super.initState();
    _loadTenants();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  Future<void> _loadTenants() async {
    setState(() => _isLoading = true);
    try {
      final tenants = await _tenantService.getTenants(
        search: _searchQuery,
        status: _selectedFilter == 'Semua' ? null : (_selectedFilter == 'Aktif' ? 'active' : 'inactive'),
      );
      setState(() {
        _tenants = tenants;
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

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      setState(() {
        _searchQuery = query;
      });
      _loadTenants();
    });
  }

  Future<void> _deleteTenant(int id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Konfirmasi Hapus'),
        content: Text('Apakah Anda yakin ingin menghapus data penghuni ini?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger),
            child: Text('Hapus', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _tenantService.deleteTenant(id);
        _loadTenants();
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Penghuni berhasil dihapus')),
        );
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceAll('Exception: ', ''))),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Data Penghuni'),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _loadTenants,
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: EdgeInsets.all(16),
            child: TextField(
              onChanged: _onSearchChanged,
              decoration: InputDecoration(
                hintText: 'Cari nama, kamar, atau NIK...',
                prefixIcon: Icon(Icons.search),
                filled: true,
                fillColor: AppColors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: AppColors.greyLight),
                ),
              ),
            ),
          ),

          // Filter Chips
          SizedBox(
            height: 50,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: EdgeInsets.symmetric(horizontal: 16),
              itemCount: filters.length,
              itemBuilder: (context, index) {
                final filter = filters[index];
                final isSelected = _selectedFilter == filter;
                return Padding(
                  padding: EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(filter),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() {
                        _selectedFilter = filter;
                      });
                      _loadTenants();
                    },
                    backgroundColor: AppColors.white,
                    selectedColor: AppColors.primary,
                    labelStyle: TextStyle(
                      color: isSelected ? AppColors.textPrimary : AppColors.textSecondary,
                    ),
                  ),
                );
              },
            ),
          ),

          SizedBox(height: 16),

          // Tenant List
          Expanded(
            child: _isLoading
                ? Center(child: CircularProgressIndicator())
                : _tenants.isEmpty
                    ? Center(child: Text('Tidak ada data penghuni'))
                    : RefreshIndicator(
                        onRefresh: _loadTenants,
                        child: ListView.builder(
                          padding: EdgeInsets.symmetric(horizontal: 16),
                          itemCount: _tenants.length,
                          itemBuilder: (context, index) {
                            final tenant = _tenants[index];
                            return _buildTenantCard(tenant);
                          },
                        ),
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          _showAddTenantDialog();
        },
        backgroundColor: AppColors.primary,
        icon: Icon(Icons.person_add, color: AppColors.textPrimary),
        label: Text(
          'Tambah Penghuni',
          style: TextStyle(color: AppColors.textPrimary),
        ),
      ),
    );
  }

  Widget _buildTenantCard(Map<String, dynamic> tenant) {
    final status = tenant['status'] ?? 'active';
    final isActive = status == 'active';
    final moveInDate = DateTime.parse(tenant['move_in_date']);
    final formattedDate = DateFormat('dd MMM yyyy').format(moveInDate);

    return Container(
      margin: EdgeInsets.only(bottom: 16),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: AppColors.primary.withOpacity(0.1),
                child: Text(
                  (tenant['name']?[0] ?? 'U').toUpperCase(),
                  style: TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ),
              SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      tenant['name'] ?? 'Unknown',
                      style: AppTextStyles.h4,
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Kamar ${tenant['room_number'] ?? '-'}',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: 8),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: isActive ? AppColors.success.withOpacity(0.1) : AppColors.grey.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        isActive ? 'Aktif' : 'Tidak Aktif',
                        style: AppTextStyles.caption.copyWith(
                          color: isActive ? AppColors.success : AppColors.grey,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  IconButton(
                    icon: Icon(Icons.more_vert),
                    onPressed: () {
                      // TODO: Show contextual menu
                    },
                  ),
                ],
              ),
            ],
          ),
          Divider(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('No. HP', style: AppTextStyles.caption),
                  SizedBox(height: 2),
                  Text(tenant['phone'] ?? '-', style: AppTextStyles.bodySmall),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('Masuk Sejak', style: AppTextStyles.caption),
                  SizedBox(height: 2),
                  Text(formattedDate, style: AppTextStyles.bodySmall),
                ],
              ),
            ],
          ),
          SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                     _showEditTenantDialog(tenant);
                  },
                  icon: Icon(Icons.edit_outlined, size: 18),
                  label: Text('Edit'),
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _deleteTenant(tenant['id']),
                  icon: Icon(Icons.delete_outline, size: 18),
                  label: Text('Hapus'),
                  style: OutlinedButton.styleFrom(foregroundColor: AppColors.danger),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showAddTenantDialog() {
    final nameController = TextEditingController();
    final emailController = TextEditingController();
    final phoneController = TextEditingController();
    final passwordController = TextEditingController(); // Added password controller
    final nikController = TextEditingController();
    DateTime selectedDate = DateTime.now();
    int? selectedRoomId;
    List<Map<String, dynamic>> availableRooms = [];
    bool isLoadingRooms = true;
    bool isSubmitting = false;

    // Load available rooms
    void loadRooms(StateSetter setDialogState) async {
      try {
        final rooms = await _roomService.getAvailableRooms();
        setDialogState(() {
          availableRooms = rooms;
          isLoadingRooms = false;
        });
      } catch (e) {
        setDialogState(() => isLoadingRooms = false);
      }
    }

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          // Trigger load on first build
          if (isLoadingRooms && availableRooms.isEmpty) {
            loadRooms(setDialogState);
          }

          return AlertDialog(
            title: Text('Tambah Penghuni Baru'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CustomTextField(
                    label: 'Nama Lengkap',
                    hint: 'Contoh: Budi Santoso',
                    controller: nameController,
                  ),
                  SizedBox(height: 12),
                  CustomTextField(
                    label: 'Email',
                    hint: 'Contoh: budi@gmail.com',
                    controller: emailController,
                    keyboardType: TextInputType.emailAddress,
                  ),
                  SizedBox(height: 12),
                  CustomTextField(
                    label: 'No. HP',
                    hint: 'Contoh: 08123456789',
                    controller: phoneController,
                    keyboardType: TextInputType.phone,
                  ),
                  SizedBox(height: 12),
                  CustomTextField(
                    label: 'Password',
                    hint: '********',
                    controller: passwordController,
                    isPassword: true,
                  ),
                  SizedBox(height: 12),
                  CustomTextField(
                    label: 'NIK (KTP)',
                    hint: '16 digit NIK',
                    controller: nikController,
                    keyboardType: TextInputType.number,
                  ),
                  SizedBox(height: 12),
                  Text('Pilih Kamar', style: AppTextStyles.bodySmall),
                  SizedBox(height: 4),
                  if (isLoadingRooms)
                    LinearProgressIndicator()
                  else if (availableRooms.isEmpty)
                    Text('Tidak ada kamar kosong', style: TextStyle(color: AppColors.danger))
                  else
                    DropdownButtonFormField<int>(
                      value: selectedRoomId,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                      hint: Text('Pilih Kamar Kosong'),
                      items: availableRooms.map((room) {
                        return DropdownMenuItem<int>(
                          value: room['id'],
                          child: Text('${room['room_number']} (${room['type']}) - Rp ${room['price']}'),
                        );
                      }).toList(),
                      onChanged: (val) => setDialogState(() => selectedRoomId = val),
                    ),
                  SizedBox(height: 12),
                  Text('Tanggal Masuk', style: AppTextStyles.bodySmall),
                  SizedBox(height: 4),
                  InkWell(
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: selectedDate,
                        firstDate: DateTime(2020),
                        lastDate: DateTime(2030),
                      );
                      if (picked != null) {
                        setDialogState(() => selectedDate = picked);
                      }
                    },
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                      decoration: BoxDecoration(
                        border: Border.all(color: AppColors.grey),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(DateFormat('dd MMM yyyy').format(selectedDate)),
                          Icon(Icons.calendar_today, size: 18, color: AppColors.primary),
                        ],
                      ),
                    ),
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
                onPressed: (isSubmitting || selectedRoomId == null)
                    ? null
                    : () async {
                        if (nameController.text.isEmpty ||
                            emailController.text.isEmpty ||
                            selectedRoomId == null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Mohon lengkapi semua data')),
                          );
                          return;
                        }

                        setDialogState(() => isSubmitting = true);
                        try {
                          await _tenantService.createTenant({
                            'name': nameController.text,
                            'email': emailController.text,
                            'phone': phoneController.text,
                            'role': 'tenant', // Auto create user
                            'room_id': selectedRoomId,
                            'nik': nikController.text,
                            'move_in_date': selectedDate.toIso8601String(),
                            'password': passwordController.text, // Pass password
                          });
                          Navigator.pop(context);
                          _loadTenants(); // Refresh list
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Penghuni berhasil ditambahkan')),
                          );
                        } catch (e) {
                          setDialogState(() => isSubmitting = false);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Gagal: ${e.toString().replaceAll('Exception: ', '')}')),
                          );
                        }
                      },
                child: isSubmitting
                    ? SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white))
                    : Text('Simpan'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showEditTenantDialog(Map<String, dynamic> tenant) {
    final nameController = TextEditingController(text: tenant['name']);
    final emailController = TextEditingController(text: tenant['email']); // Added email
    final phoneController = TextEditingController(text: tenant['phone']);
    final nikController = TextEditingController(text: tenant['nik']);
    final passwordController = TextEditingController(); // Added password
    bool _isSubmitting = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: Text('Edit Penghuni'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                   Container(
                     padding: EdgeInsets.all(12),
                     margin: EdgeInsets.only(bottom: 12),
                     decoration: BoxDecoration(
                         color: AppColors.backgroundLight,
                         borderRadius: BorderRadius.circular(8)
                     ),
                     child: Row(
                         children: [
                             Icon(Icons.info_outline, size: 20, color: AppColors.textSecondary),
                             SizedBox(width: 8),
                             Expanded(child: Text('Anda dapat mengubah data profil dan password penyewa di sini.', style: AppTextStyles.caption)),
                         ],
                     ),
                  ),
                  CustomTextField(
                    label: 'Nama Lengkap',
                    hint: 'Contoh: Budi Santoso',
                    controller: nameController,
                  ),
                  SizedBox(height: 12),
                  CustomTextField(
                    label: 'Email',
                    hint: 'Contoh: budi@gmail.com',
                    controller: emailController,
                    keyboardType: TextInputType.emailAddress,
                  ),
                  SizedBox(height: 12),
                  CustomTextField(
                    label: 'No. HP',
                    hint: 'Contoh: 08123456789',
                    controller: phoneController,
                    keyboardType: TextInputType.phone,
                  ),
                  SizedBox(height: 12),
                  CustomTextField(
                    label: 'NIK (KTP)',
                    hint: '16 digit NIK',
                    controller: nikController,
                    keyboardType: TextInputType.number,
                  ),
                  SizedBox(height: 12),
                  CustomTextField(
                    label: 'Password Baru (Opsional)',
                    hint: 'Kosongkan jika tidak ingin mengubah',
                    controller: passwordController,
                    isPassword: true,
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
                onPressed: _isSubmitting
                    ? null
                    : () async {
                        if (nameController.text.isEmpty || emailController.text.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Nama dan Email tidak boleh kosong')),
                            );
                            return;
                        }

                        setState(() => _isSubmitting = true);
                        try {
                          final Map<String, dynamic> updates = {
                            'nik': nikController.text,
                            'name': nameController.text,
                            'email': emailController.text,
                            'phone': phoneController.text,
                          };
                          
                          if (passwordController.text.isNotEmpty) {
                            updates['password'] = passwordController.text;
                          }

                          await _tenantService.updateTenant(tenant['id'], updates);
                          
                          Navigator.pop(context);
                          _loadTenants();
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Data penghuni berhasil diupdate')),
                          );
                        } catch (e) {
                          setState(() => _isSubmitting = false);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Gagal: ${e.toString().replaceAll('Exception: ', '')}')),
                          );
                        }
                      },
                child: _isSubmitting ? SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white)) : Text('Simpan'),
              ),
            ],
          );
        }
      ),
    );
  }
}