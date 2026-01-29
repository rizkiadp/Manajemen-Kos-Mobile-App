import 'package:flutter/material.dart';
import 'dart:async';
import '../../../core/constants/colors.dart';
import '../../../core/constants/text_styles.dart';
import '../../widgets/common/custom_button.dart';
import '../../widgets/common/custom_text_field.dart';
import '../../../core/services/room_service.dart';

class RoomManagementScreen extends StatefulWidget {
  const RoomManagementScreen({Key? key}) : super(key: key);

  @override
  State<RoomManagementScreen> createState() => _RoomManagementScreenState();
}

class _RoomManagementScreenState extends State<RoomManagementScreen> {
  final RoomService _roomService = RoomService();
  String _searchQuery = '';
  String _selectedFilter = 'Semua';
  bool _isLoading = true;
  List<Map<String, dynamic>> _rooms = [];
  Timer? _debounce;

  final List<String> filters = ['Semua', 'VIP', 'Standard', 'Reguler'];

  @override
  void initState() {
    super.initState();
    _loadRooms();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  Future<void> _loadRooms() async {
    setState(() => _isLoading = true);
    try {
      final rooms = await _roomService.getRooms(
        search: _searchQuery,
        filter: _selectedFilter,
      );
      setState(() {
        _rooms = rooms;
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
      _loadRooms();
    });
  }

  Future<void> _deleteRoom(int id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Konfirmasi Hapus'),
        content: Text('Apakah Anda yakin ingin menghapus kamar ini?'),
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
        await _roomService.deleteRoom(id);
        _loadRooms();
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Kamar berhasil dihapus')),
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
        title: Text('Kelola Kamar'),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _loadRooms,
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
                hintText: 'Cari kamar...',
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
                      _loadRooms();
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

          // Room List
          Expanded(
            child: _isLoading
                ? Center(child: CircularProgressIndicator())
                : _rooms.isEmpty
                    ? Center(child: Text('Tidak ada kamar ditemukan'))
                    : RefreshIndicator(
                        onRefresh: _loadRooms,
                        child: ListView.builder(
                          padding: EdgeInsets.symmetric(horizontal: 16),
                          itemCount: _rooms.length,
                          itemBuilder: (context, index) {
                            final room = _rooms[index];
                            return _buildRoomCard(room);
                          },
                        ),
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          _showAddRoomDialog();
        },
        backgroundColor: AppColors.primary,
        icon: Icon(Icons.add, color: AppColors.textPrimary),
        label: Text(
          'Tambah Kamar',
          style: TextStyle(color: AppColors.textPrimary),
        ),
      ),
    );
  }

  Widget _buildRoomCard(Map<String, dynamic> room) {
    final bool isAvailable = room['is_available'] ?? true;
    final String type = room['type'] ?? 'Standard';
    final int price = int.tryParse(room['price'].toString()) ?? 0;
    
    return Container(
      margin: EdgeInsets.only(bottom: 16),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Room Image with Status
          Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                child: Container(
                  height: 150,
                  width: double.infinity,
                  color: AppColors.greyLight,
                  child: Center(
                    child: Icon(Icons.image, size: 48, color: AppColors.grey),
                  ),
                ),
              ),
              Positioned(
                top: 12,
                right: 12,
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: isAvailable ? AppColors.success : AppColors.danger,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    isAvailable ? 'Kosong' : 'Terisi',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),

          Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Kamar ${room['room_number']}',
                      style: AppTextStyles.h4,
                    ),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: type == 'VIP'
                            ? AppColors.primary.withOpacity(0.1)
                            : AppColors.info.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        type,
                        style: AppTextStyles.bodySmall.copyWith(
                          color: type == 'VIP' ? AppColors.primary : AppColors.info,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),

                SizedBox(height: 12),

                Row(
                  children: [
                    Icon(Icons.location_on_outlined, size: 16, color: AppColors.textSecondary),
                    SizedBox(width: 4),
                    Text(
                      'Lantai ${room['floor']} - Sayap ${room['wing']}',
                      style: AppTextStyles.bodySmall,
                    ),
                  ],
                ),

                SizedBox(height: 8),

                Text(
                  'Rp ${price.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')}/bulan',
                  style: AppTextStyles.h4.copyWith(color: AppColors.primary),
                ),

                SizedBox(height: 12),

                if (room['facilities'] != null)
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: (room['facilities'] as List<dynamic>).map((facility) {
                      return Container(
                        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.backgroundLight,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          facility.toString(),
                          style: AppTextStyles.caption,
                        ),
                      );
                    }).toList(),
                  ),

                SizedBox(height: 16),

                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          // TODO: implement edit
                          _showEditRoomDialog(room);
                        },
                        icon: Icon(Icons.edit_outlined, size: 18),
                        label: Text('Edit'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.textPrimary,
                        ),
                      ),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _deleteRoom(room['id']),
                        icon: Icon(Icons.delete_outline, size: 18),
                        label: Text('Hapus'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.danger,
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

  void _showAddRoomDialog() {
    final roomNumberController = TextEditingController();
    final priceController = TextEditingController();
    final floorController = TextEditingController();
    final wingController = TextEditingController();
    String selectedType = 'Reguler';
    bool _isSubmitting = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: Text('Tambah Kamar Baru'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CustomTextField(
                    label: 'Nomor Kamar',
                    hint: 'Contoh: A-101',
                    controller: roomNumberController,
                  ),
                  SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: selectedType,
                    decoration: InputDecoration(
                      labelText: 'Tipe Kamar',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    items: ['VIP', 'Standard', 'Reguler'].map((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(value),
                      );
                    }).toList(),
                    onChanged: (newValue) {
                      setState(() => selectedType = newValue!);
                    },
                  ),
                   SizedBox(height: 12),
                  CustomTextField(
                    label: 'Harga Sewa',
                    hint: 'Contoh: 2500000',
                    controller: priceController,
                    keyboardType: TextInputType.number,
                  ),
                  SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: CustomTextField(
                          label: 'Lantai',
                          hint: '1',
                          controller: floorController,
                          keyboardType: TextInputType.number,
                        ),
                      ),
                      SizedBox(width: 12),
                      Expanded(
                         child: CustomTextField(
                          label: 'Sayap (Wing)',
                          hint: 'Kiri/Kanan',
                          controller: wingController,
                        ),
                      ),
                    ],
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
                        if (roomNumberController.text.isEmpty || 
                            priceController.text.isEmpty ||
                            floorController.text.isEmpty ||
                            wingController.text.isEmpty) {
                          return;
                        }

                        setState(() => _isSubmitting = true);
                        try {
                          await _roomService.createRoom({
                            'room_number': roomNumberController.text,
                            'type': selectedType,
                            'price': int.parse(priceController.text),
                            'floor': int.parse(floorController.text),
                            'wing': wingController.text,
                            'facilities': ["WiFi", "Full Furnished"], // Default facilities
                          });
                          Navigator.pop(context);
                          _loadRooms();
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Kamar berhasil ditambahkan')),
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

  void _showEditRoomDialog(Map<String, dynamic> room) {
    final roomNumberController = TextEditingController(text: room['room_number']);
    final priceController = TextEditingController(text: room['price'].toString());
    final floorController = TextEditingController(text: room['floor'].toString());
    final wingController = TextEditingController(text: room['wing']);
    String selectedType = room['type'] ?? 'Standard';
    bool _isSubmitting = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: Text('Edit Kamar ${room['room_number']}'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CustomTextField(
                    label: 'Nomor Kamar',
                    hint: 'Contoh: A-101',
                    controller: roomNumberController,
                  ),
                  SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: selectedType,
                    decoration: InputDecoration(
                      labelText: 'Tipe Kamar',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    items: ['VIP', 'Standard', 'Reguler'].map((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(value),
                      );
                    }).toList(),
                    onChanged: (newValue) {
                      setState(() => selectedType = newValue!);
                    },
                  ),
                   SizedBox(height: 12),
                  CustomTextField(
                    label: 'Harga Sewa',
                    hint: 'Contoh: 2500000',
                    controller: priceController,
                    keyboardType: TextInputType.number,
                  ),
                  SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: CustomTextField(
                          label: 'Lantai',
                          hint: '1',
                          controller: floorController,
                          keyboardType: TextInputType.number,
                        ),
                      ),
                      SizedBox(width: 12),
                      Expanded(
                         child: CustomTextField(
                          label: 'Sayap (Wing)',
                          hint: 'Kiri/Kanan',
                          controller: wingController,
                        ),
                      ),
                    ],
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
                        if (roomNumberController.text.isEmpty || 
                            priceController.text.isEmpty ||
                            floorController.text.isEmpty ||
                            wingController.text.isEmpty) {
                          return;
                        }

                        setState(() => _isSubmitting = true);
                        try {
                          await _roomService.updateRoom(room['id'], {
                            'room_number': roomNumberController.text, // Backend expects underscore
                            'type': selectedType,
                            'price': int.parse(priceController.text),
                            'floor': int.parse(floorController.text),
                            'wing': wingController.text,
                          });
                          Navigator.pop(context);
                          _loadRooms();
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Kamar berhasil diupdate')),
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
