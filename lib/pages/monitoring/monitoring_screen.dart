import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:flutter_map/flutter_map.dart'; 
import 'package:latlong2/latlong.dart';
import 'package:http/http.dart' as http; 
import 'dart:convert';
import '../../models/land_model.dart';
import '../../models/land_task_model.dart';
import '../../providers/auth_provider.dart';
import '../../services/land_service.dart';
import '../../services/weather_service.dart';
import '../../theme/app_colors.dart';
import '../../widgets/land_summary_stats.dart';

class MonitoringScreen extends StatefulWidget {
  final int? initialLandId; // ADDED THIS

  const MonitoringScreen({super.key, this.initialLandId});

  @override
  State<MonitoringScreen> createState() => _MonitoringScreenState();
}

class _MonitoringScreenState extends State<MonitoringScreen> with SingleTickerProviderStateMixin {
  final _landService = LandService();
  final _weatherService = WeatherService();

  late TabController _tabController;
  
  Land? _selectedLand;
  List<Land> _userLands = [];
  Map<String, dynamic>? _weatherData;
  List<Map<String, dynamic>> _progressLogs = [];
  List<LandTask> _dailyTasks = [];
  
  bool _isLoading = true;
  DateTime _selectedTaskDate = DateTime.now();
  String _displayAddress = "Memuat alamat..."; 

  // Controllers for Edit Land
  final _editNameController = TextEditingController();
  final _editLocationController = TextEditingController();
  final _editModalController = TextEditingController();
  final _editProfitController = TextEditingController();
  final _editHarvestKgController = TextEditingController();
  String? _editPlantType;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(() {
        if (_tabController.indexIsChanging) setState(() {});
    });
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final userId = auth.userProfile?.id;

    if (userId != null) {
      _userLands = await _landService.getUserLands(userId);
      
      // LOGIC UPDATE: Pick specific land if passed, otherwise default
      if (_userLands.isNotEmpty) {
        if (_selectedLand == null) {
          if (widget.initialLandId != null) {
             _selectedLand = _userLands.firstWhere((l) => l.id == widget.initialLandId, orElse: () => _userLands.first);
          } else {
             _selectedLand = _userLands.first;
          }
        }
      }
      
      if (_selectedLand != null) {
        _progressLogs = await _landService.getProgressLogs(_selectedLand!.id);
        _dailyTasks = await _landService.getLandTasks(_selectedLand!.id, _selectedTaskDate);
        _populateEditControllers();
        
        if (_selectedLand!.latitude != null && _selectedLand!.longitude != null) {
          _fetchAddress(_selectedLand!.latitude!, _selectedLand!.longitude!);
        } else {
          setState(() => _displayAddress = _selectedLand!.location ?? "Lokasi tidak diketahui");
        }
      }
    } else {
      // Demo Mode
      _selectedLand = _landService.getDemoLand();
      _progressLogs = []; 
      _displayAddress = "Malang, Jawa Timur (Demo)";
    }

    if (_selectedLand != null) {
      _weatherData = await _weatherService.getCurrentWeather(
        _selectedLand!.latitude ?? -7.2504, 
        _selectedLand!.longitude ?? 112.7688
      );
    }

    setState(() => _isLoading = false);
  }

  Future<void> _fetchAddress(double lat, double lng) async {
    try {
      final url = Uri.parse('https://nominatim.openstreetmap.org/reverse?format=json&lat=$lat&lon=$lng&zoom=14');
      final response = await http.get(url, headers: {'User-Agent': 'com.example.ayotani'}); 

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final address = data['address'];
        String readable = '';
        if (address != null) {
          readable = [
            address['village'],
            address['suburb'],
            address['city_district'],
            address['city'],
            address['county']
          ].where((e) => e != null).take(2).join(', ');
        }
        
        if (readable.isEmpty) readable = data['display_name'] ?? 'Alamat tidak ditemukan';
        if (mounted) setState(() => _displayAddress = readable);
      }
    } catch (e) {
      if (mounted) setState(() => _displayAddress = "${lat.toStringAsFixed(4)}, ${lng.toStringAsFixed(4)}");
    }
  }

  void _populateEditControllers() {
    if (_selectedLand == null) return;
    _editNameController.text = _selectedLand!.name;
    _editLocationController.text = _selectedLand!.location ?? '';
    _editModalController.text = _selectedLand!.modalPerKg.toString();
    _editProfitController.text = _selectedLand!.targetProfitPercentage.toString();
    _editHarvestKgController.text = _selectedLand!.targetHarvestKg.toString();
    _editPlantType = _selectedLand!.plantType;
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Scaffold(body: Center(child: CircularProgressIndicator(color: AppColors.green)));

    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: Stack(
        children: [
          SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Stack(
                  clipBehavior: Clip.none,
                  alignment: Alignment.bottomCenter,
                  children: [
                    _buildMapHeader(),
                    Positioned(
                      bottom: -40,
                      left: 16,
                      right: 16,
                      child: _buildLandSelector(),
                    ),
                  ],
                ),
                const SizedBox(height: 60),
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  child: LandSummaryStats(selectedLand: _selectedLand), 
                ),
                const SizedBox(height: 24),
                Container(
                  height: 40,
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: [
                      _buildTabButton('Monitoring', 0),
                      _buildTabButton('Tugas', 1),
                      _buildTabButton('Integrasi', 2),
                      _buildTabButton('Setting', 3),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                _buildTabContent(),
                const SizedBox(height: 100),
              ],
            ),
          ),
          Positioned(
            top: 50,
            left: 16,
            child: CircleAvatar(
              backgroundColor: Colors.white,
              child: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.black), 
                onPressed: () {
                   Navigator.pop(context); // Simple pop is fine now as we navigate via pushNamed
                }
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: _getFloatingActionButton(),
    );
  }

  // ... (Rest of the file remains the same: _getFloatingActionButton, _buildMapHeader, _buildLandSelector, etc.)
  
  // NOTE: Just ensuring the previous methods are kept. For brevity in this response, I'm assuming the helper methods 
  // (_buildMapHeader, _buildLandSelector, _buildTabButton, _buildTabContent, _buildMonitoringTab, _buildWeatherCard, 
  // _buildChartContainer, _showManualLogDialog, _buildTasksTab, _showAddTaskDialog, _buildSettingsTab, 
  // _buildEditField, _saveLandSettings) are unchanged from the previous version.
  
  Widget? _getFloatingActionButton() {
    if (_tabController.index == 1) {
      return FloatingActionButton.extended(
        onPressed: _showAddTaskDialog,
        backgroundColor: AppColors.green,
        icon: const Icon(Icons.add_task, color: Colors.white),
        label: const Text('Buat Tugas', style: TextStyle(color: Colors.white)),
      );
    }
    // Removed the "Add Land" button here because we now add lands from the List View
    return null; 
  }

  Widget _buildMapHeader() {
    final lat = _selectedLand?.latitude ?? -7.2504;
    final lng = _selectedLand?.longitude ?? 112.7688;

    return SizedBox(
      height: 280,
      width: double.infinity,
      child: FlutterMap(
        options: MapOptions(
          initialCenter: LatLng(lat, lng),
          initialZoom: 14.0,
          interactionOptions: const InteractionOptions(flags: InteractiveFlag.none),
        ),
        children: [
          TileLayer(urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png', userAgentPackageName: 'com.example.ayotani'),
          MarkerLayer(markers: [Marker(point: LatLng(lat, lng), width: 40, height: 40, child: const Icon(Icons.location_on, color: Colors.red, size: 40))]),
          Container(color: Colors.black.withOpacity(0.1)),
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  decoration: BoxDecoration(color: const Color(0xFF0A3D2F), borderRadius: BorderRadius.circular(4)),
                  child: Column(
                    children: [
                      Text('${_selectedLand?.areaSize ?? 0} ha', style: const TextStyle(color: Colors.white, fontSize: 10)),
                      Text(_selectedLand?.name ?? 'Tanaman', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    ],
                  ),
                )
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLandSelector() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<Land>(
          value: _userLands.contains(_selectedLand) ? _selectedLand : null,
          isExpanded: true,
          hint: const Text("Pilih Lahan"),
          icon: const Icon(Icons.keyboard_arrow_down, color: Colors.grey),
          items: _userLands.map((Land land) {
            return DropdownMenuItem<Land>(
              value: land,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(land.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black)),
                  Text(land.location ?? 'Lokasi tidak diketahui', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                ],
              ),
            );
          }).toList(),
          onChanged: (Land? newValue) {
            if (newValue != null) {
              setState(() => _selectedLand = newValue);
              _loadData();
            }
          },
        ),
      ),
    );
  }

  Widget _buildTabButton(String text, int index) {
    bool isSelected = _tabController.index == index;
    return GestureDetector(
      onTap: () => _tabController.animateTo(index),
      child: Container(
        margin: const EdgeInsets.only(right: 12),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF0A3D2F) : const Color(0xFFE8F5E9),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Center(
          child: Text(text, style: TextStyle(color: isSelected ? Colors.white : Colors.black, fontWeight: FontWeight.bold, fontSize: 13)),
        ),
      ),
    );
  }

  Widget _buildTabContent() {
    switch (_tabController.index) {
      case 0: return _buildMonitoringTab();
      case 1: return _buildTasksTab();
      case 2: return const Center(child: Padding(padding: EdgeInsets.all(32), child: Text("Integrasi API coming soon")));
      case 3: return _buildSettingsTab();
      default: return _buildMonitoringTab();
    }
  }

  Widget _buildMonitoringTab() {
    final temp = _weatherData?['current']?['temperature_2m'] ?? _weatherData?['current_weather']?['temperature'] ?? 24;
    List<double> waterHistory = _progressLogs.map((e) => (e['water_amount_liters'] as num).toDouble()).toList();
    List<double> growthHistory = _progressLogs.map((e) => (e['plant_height_cm'] as num).toDouble()).toList();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildWeatherCard(temp),
          const SizedBox(height: 24),
          const Text('Grafik Lahan (Manual Input)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 12),
          _buildChartContainer(title: 'Air (Liter)', data: waterHistory, color: Colors.blue, onUpdate: () => _showManualLogDialog(isWater: true)),
          const SizedBox(height: 16),
          _buildChartContainer(title: 'Pertumbuhan (cm)', data: growthHistory, color: Colors.green, onUpdate: () => _showManualLogDialog(isWater: false)),
        ],
      ),
    );
  }

  Widget _buildWeatherCard(dynamic temp) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [Colors.white, Colors.green[50]!]),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.green[100]!),
      ),
      child: Row(
        children: [
          Column(
            children: [
              const Icon(Icons.wb_sunny_rounded, color: Colors.orange, size: 36),
              const SizedBox(height: 8),
              Text('$temp°C', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
              const Text('Hari ini', style: TextStyle(fontSize: 10, color: Colors.grey)),
            ],
          ),
          Container(width: 1, height: 50, color: Colors.grey[300], margin: const EdgeInsets.symmetric(horizontal: 20)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Lokasi Lahan', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                Text(_displayAddress, style: const TextStyle(fontSize: 11, color: Colors.black87), maxLines: 2, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 4),
                Text('${_selectedLand?.latitude?.toStringAsFixed(4)}, ${_selectedLand?.longitude?.toStringAsFixed(4)}', style: const TextStyle(fontSize: 9, color: Colors.grey)),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildChartContainer({required String title, required List<double> data, required Color color, required VoidCallback onUpdate}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey[200]!)),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
              SizedBox(
                height: 30,
                child: ElevatedButton(
                  onPressed: onUpdate,
                  style: ElevatedButton.styleFrom(backgroundColor: color, padding: const EdgeInsets.symmetric(horizontal: 12)),
                  child: const Text("Input Data", style: TextStyle(color: Colors.white, fontSize: 10)),
                ),
              )
            ],
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(7, (index) {
              double val = 0;
              if (index < data.length) val = data[index];
              return Column(
                children: [
                  Container(
                    width: 20,
                    height: (val * 3).clamp(5.0, 100.0), 
                    decoration: BoxDecoration(color: color.withOpacity(0.5), borderRadius: BorderRadius.circular(4)),
                  ),
                  const SizedBox(height: 4),
                  Text(index < data.length ? val.toStringAsFixed(0) : '-', style: const TextStyle(fontSize: 10)),
                ],
              );
            }),
          )
        ],
      ),
    );
  }

  Future<void> _showManualLogDialog({required bool isWater}) async {
    final controller = TextEditingController();
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isWater ? 'Catat Penyiraman' : 'Catat Pertumbuhan'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(controller: controller, keyboardType: TextInputType.number, decoration: InputDecoration(labelText: isWater ? 'Jumlah Air (Liter)' : 'Tinggi Tanaman (cm)', border: const OutlineInputBorder())),
            const SizedBox(height: 10),
            const Text('Data akan dicatat untuk hari ini.', style: TextStyle(fontSize: 12, color: Colors.grey)),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Batal')),
          ElevatedButton(
            onPressed: () async {
              if (controller.text.isEmpty) return;
              final val = double.tryParse(controller.text) ?? 0;
              await _landService.addProgressLog(_selectedLand!.id, isWater ? val : 0, isWater ? 0 : val, 'Manual Update');
              Navigator.pop(context);
              _loadData();
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.green),
            child: const Text('Simpan', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildTasksTab() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.grey[200]!)),
            child: CalendarDatePicker(
              initialDate: _selectedTaskDate,
              firstDate: DateTime(2020),
              lastDate: DateTime(2030),
              onDateChanged: (newDate) { setState(() => _selectedTaskDate = newDate); _loadData(); },
            ),
          ),
          const SizedBox(height: 24),
          Align(alignment: Alignment.centerLeft, child: Text('Tugas: ${DateFormat('dd MMM yyyy').format(_selectedTaskDate)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16))),
          const SizedBox(height: 12),
          if (_dailyTasks.isEmpty) const Padding(padding: EdgeInsets.all(20), child: Text("Tidak ada tugas hari ini.", style: TextStyle(color: Colors.grey))),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _dailyTasks.length,
            itemBuilder: (context, index) {
              final task = _dailyTasks[index];
              return Dismissible(
                key: Key(task.id.toString()),
                background: Container(color: Colors.red, alignment: Alignment.centerRight, padding: const EdgeInsets.only(right: 20), child: const Icon(Icons.delete, color: Colors.white)),
                onDismissed: (_) async { await _landService.deleteTask(task.id); _loadData(); },
                child: Card(
                  elevation: 0,
                  shape: RoundedRectangleBorder(side: BorderSide(color: Colors.grey[200]!), borderRadius: BorderRadius.circular(8)),
                  child: CheckboxListTile(
                    title: Text(task.title, style: TextStyle(decoration: task.isCompleted ? TextDecoration.lineThrough : null)),
                    subtitle: Text('${task.description ?? ''} • ${DateFormat('HH:mm').format(task.dueDate)}', style: const TextStyle(fontSize: 12)),
                    value: task.isCompleted,
                    activeColor: AppColors.green,
                    onChanged: (val) async { await _landService.toggleTaskComplete(task.id, task.isCompleted); _loadData(); },
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Future<void> _showAddTaskDialog() async {
    final titleCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    TimeOfDay selectedTime = TimeOfDay.now();
    String repeat = 'once';
    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Buat Tugas Baru'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: titleCtrl, decoration: const InputDecoration(labelText: 'Judul Tugas')),
                TextField(controller: descCtrl, decoration: const InputDecoration(labelText: 'Deskripsi')),
                const SizedBox(height: 16),
                Row(
                  children: [
                    const Icon(Icons.access_time, size: 20),
                    const SizedBox(width: 8),
                    TextButton(
                      onPressed: () async { final t = await showTimePicker(context: context, initialTime: selectedTime); if (t != null) setDialogState(() => selectedTime = t); },
                      child: Text(selectedTime.format(context)),
                    ),
                  ],
                ),
                DropdownButton<String>(
                  value: repeat,
                  isExpanded: true,
                  items: ['once', 'daily', 'weekly'].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                  onChanged: (v) => setDialogState(() => repeat = v!),
                )
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Batal')),
            ElevatedButton(
              onPressed: () async {
                if (titleCtrl.text.isEmpty) return;
                final taskDate = DateTime(_selectedTaskDate.year, _selectedTaskDate.month, _selectedTaskDate.day, selectedTime.hour, selectedTime.minute);
                final newTask = LandTask(id: 0, landId: _selectedLand!.id, title: titleCtrl.text, description: descCtrl.text, dueDate: taskDate, repeatType: repeat);
                await _landService.addLandTask(newTask);
                Navigator.pop(context);
                _loadData();
              },
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.green),
              child: const Text('Simpan'),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsTab() {
    if (_selectedLand == null) return const Center(child: Text("Pilih lahan terlebih dahulu"));
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Card(
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: Colors.grey[300]!)),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("Edit Informasi Lahan", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const Divider(),
              const SizedBox(height: 10),
              _buildEditField('Nama Lahan', _editNameController),
              _buildEditField('Lokasi', _editLocationController),
              _buildEditField('Tipe Tanaman', TextEditingController(text: _editPlantType), readOnly: true),
              const SizedBox(height: 10),
              const Text("Data Finansial", style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.green)),
              const SizedBox(height: 10),
              Row(children: [
                Expanded(child: _buildEditField('Modal/Kg', _editModalController, isNumber: true)),
                const SizedBox(width: 10),
                Expanded(child: _buildEditField('Target Profit %', _editProfitController, isNumber: true)),
              ]),
              _buildEditField('Target Panen (Kg)', _editHarvestKgController, isNumber: true),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _saveLandSettings,
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.green, padding: const EdgeInsets.symmetric(vertical: 12)),
                  child: const Text("Simpan Perubahan", style: TextStyle(color: Colors.white)),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEditField(String label, TextEditingController ctrl, {bool isNumber = false, bool readOnly = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: ctrl,
        readOnly: readOnly,
        keyboardType: isNumber ? TextInputType.number : TextInputType.text,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        ),
      ),
    );
  }

  Future<void> _saveLandSettings() async {
    if (_selectedLand == null) return;
    final updatedLand = Land(
      id: _selectedLand!.id,
      userId: _selectedLand!.userId,
      name: _editNameController.text,
      location: _editLocationController.text,
      latitude: _selectedLand!.latitude,
      longitude: _selectedLand!.longitude,
      plantType: _selectedLand!.plantType,
      plantingDate: _selectedLand!.plantingDate,
      harvestDate: _selectedLand!.harvestDate,
      areaSize: _selectedLand!.areaSize,
      imageUrl: _selectedLand!.imageUrl,
      modalPerKg: double.tryParse(_editModalController.text) ?? 0,
      targetProfitPercentage: double.tryParse(_editProfitController.text) ?? 0,
      targetHarvestKg: double.tryParse(_editHarvestKgController.text) ?? 0,
    );
    setState(() => _isLoading = true);
    bool success = await _landService.updateLand(updatedLand);
    if (success) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Berhasil menyimpan perubahan")));
      _loadData();
    } else {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Gagal menyimpan"), backgroundColor: Colors.red));
      setState(() => _isLoading = false);
    }
  }
}