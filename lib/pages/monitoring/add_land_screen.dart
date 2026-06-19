import 'package:flutter/material.dart';
import 'package:ayotani/theme/app_colors.dart';
import 'package:provider/provider.dart';
import 'package:flutter_map/flutter_map.dart'; 
import 'package:latlong2/latlong.dart';
import 'package:http/http.dart' as http; // Add HTTP
import 'dart:convert';                   // Add JSON
import '../../models/land_model.dart';
import '../../services/land_service.dart';
import '../../services/weather_service.dart';
import '../../providers/auth_provider.dart';

class AddLandScreen extends StatefulWidget {
  AddLandScreen({super.key});

  @override
  State<AddLandScreen> createState() => _AddLandScreenState();
}

class _AddLandScreenState extends State<AddLandScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  final _formKey = GlobalKey<FormState>();
  
  // Controllers
  final _nameController = TextEditingController(); 
  final _locationController = TextEditingController();
  final _modalController = TextEditingController();
  final _profitController = TextEditingController();
  final _harvestKgController = TextEditingController();

  // State
  String? _selectedPlantType;
  DateTime? _plantingDate;
  DateTime? _harvestDate;
  
  // Default Location (Surabaya)
  LatLng _selectedLocation = LatLng(-7.2575, 112.7521); 
  String _addressPreview = "Pilih lokasi di peta"; // Stores fetched address
  
  Map<String, dynamic>? _currentWeather;
  bool _isLoading = false;

  final List<String> _plantTypes = ['Tomat', 'Cabai', 'Padi', 'Jagung', 'Bawang Merah'];

  @override
  void initState() {
    super.initState();
    _updateWeather();
    _fetchAddress(_selectedLocation); // Fetch address for default location
  }

  Future<void> _updateWeather() async {
    final weather = await WeatherService().getCurrentWeather(_selectedLocation.latitude, _selectedLocation.longitude);
    if (mounted) {
      setState(() {
        _currentWeather = weather?['current'] ?? weather?['current_weather'];
      });
    }
  }

  // NEW: Fetch readable address
  Future<void> _fetchAddress(LatLng point) async {
    try {
      final url = Uri.parse('https://nominatim.openstreetmap.org/reverse?format=json&lat=${point.latitude}&lon=${point.longitude}&zoom=14');
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

        if (mounted) setState(() => _addressPreview = readable);
      }
    } catch (e) {
      if (mounted) setState(() => _addressPreview = "${point.latitude.toStringAsFixed(4)}, ${point.longitude.toStringAsFixed(4)}");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.scaffoldBg,
      appBar: AppBar(
        backgroundColor: context.scaffoldBg,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: context.textPrimary),
          onPressed: () {
            if (_currentPage > 0) {
              _pageController.previousPage(duration: Duration(milliseconds: 300), curve: Curves.easeInOut);
            } else {
              Navigator.pop(context);
            }
          },
        ),
        title: Text(_currentPage == 1 ? 'Pilih Lokasi Real-Time' : (_currentPage == 2 ? 'Detail Lahan' : ''), style: TextStyle(color: context.textPrimary, fontWeight: FontWeight.bold)),
      ),
      body: PageView(
        controller: _pageController,
        physics: NeverScrollableScrollPhysics(),
        onPageChanged: (index) => setState(() => _currentPage = index),
        children: [
          _buildIntroStep(),
          _buildMapStep(), 
          _buildFormStep(), 
        ],
      ),
    );
  }

  // STEP 1: Intro
  Widget _buildIntroStep() {
    return Padding(
      padding: EdgeInsets.all(24.0),
      child: Column(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                image: DecorationImage(
                  image: NetworkImage('https://placehold.co/800x600/0A3D2F/FFFFFF.png?text=Mulai+Bertani'),
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),
          SizedBox(height: 32),
          Text('Ayo Mulai Bertani', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
          SizedBox(height: 12),
          Text('Atur lahan pertanianmu dengan data real-time dan perencanaan finansial.', style: TextStyle(fontSize: 14, color: context.textMuted, height: 1.5), textAlign: TextAlign.center),
          SizedBox(height: 40),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: () => _pageController.nextPage(duration: Duration(milliseconds: 300), curve: Curves.easeInOut),
              style: ElevatedButton.styleFrom(backgroundColor: Color(0xFF0A3D2F), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25))),
              child: Text('Mulai', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
            ),
          ),
        ],
      ),
    );
  }

  // STEP 2: Real Map Picker
  Widget _buildMapStep() {
    return Stack(
      children: [
        FlutterMap(
          options: MapOptions(
            initialCenter: _selectedLocation,
            initialZoom: 13.0,
            onTap: (tapPosition, point) {
              setState(() {
                _selectedLocation = point;
                _addressPreview = "Memuat alamat..."; // Show loading
              });
              _updateWeather(); // Fetch weather
              _fetchAddress(point); // Fetch address
            },
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.example.ayotani',
            ),
            MarkerLayer(
              markers: [
                Marker(
                  point: _selectedLocation,
                  width: 50,
                  height: 50,
                  child: Icon(Icons.location_on, color: Colors.red, size: 50),
                ),
              ],
            ),
          ],
        ),
        
        // Weather Info Card (Real Data)
        if (_currentWeather != null)
          Positioned(
            top: 20, left: 20, right: 20,
            child: Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: context.cardBg.withOpacity(0.95),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10)],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Column(children: [
                    Icon(Icons.thermostat, color: Colors.orange),
                    SizedBox(height: 4),
                    Text('${_currentWeather!['temperature'] ?? _currentWeather!['temperature_2m'] ?? '-'}°C', style: TextStyle(fontWeight: FontWeight.bold)),
                    Text('Suhu', style: TextStyle(fontSize: 10, color: context.bgGrey)),
                  ]),
                  Column(children: [
                    Icon(Icons.location_city, color: Colors.green),
                    SizedBox(height: 4),
                    // Show fetched address in the card
                    SizedBox(width: 80, child: Text(_addressPreview, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 10), maxLines: 2, overflow: TextOverflow.ellipsis, textAlign: TextAlign.center)),
                    Text('Lokasi', style: TextStyle(fontSize: 10, color: context.bgGrey)),
                  ]),
                ],
              ),
            ),
          ),

        Positioned(
          bottom: 90, left: 20, right: 20,
          child: GestureDetector(
            onTap: () {
              Navigator.pushNamed(
                context,
                '/weather',
                arguments: {
                  'lat': _selectedLocation.latitude,
                  'lon': _selectedLocation.longitude,
                },
              );
            },
            child: Container(
              height: 42,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: context.cardBg.withOpacity(0.9),
                borderRadius: BorderRadius.circular(25),
                border: Border.all(color: Color(0xFF0A3D2F).withOpacity(0.3)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.cloud, color: Color(0xFF0A3D2F), size: 16),
                  SizedBox(width: 6),
                  Text('Lihat Cuaca Lokasi Ini',
                      style: TextStyle(color: Color(0xFF0A3D2F), fontWeight: FontWeight.w600, fontSize: 13)),
                ],
              ),
            ),
          ),
        ),

        Positioned(
          bottom: 30, left: 20, right: 20,
          child: SizedBox(
            height: 50,
            child: ElevatedButton(
              onPressed: () {
                // Set the address controller to the fetched address, NOT coordinates
                _locationController.text = _addressPreview;
                _pageController.nextPage(duration: Duration(milliseconds: 300), curve: Curves.easeInOut);
              },
              style: ElevatedButton.styleFrom(backgroundColor: Color(0xFF0A3D2F), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25))),
              child: Text('Pilih Lokasi Ini', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ),
        ),
      ],
    );
  }

  // STEP 3: Detailed Form
  Widget _buildFormStep() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(24),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildLabel('Nama Pertanian'),
            TextFormField(controller: _nameController, decoration: _inputDecoration('Contoh: Lahan Tomat A'), validator: (v) => v!.isEmpty ? 'Wajib diisi' : null),
            SizedBox(height: 16),
            
            _buildLabel('Lokasi'),
            // This will now show the Address instead of coords
            TextFormField(controller: _locationController, readOnly: true, decoration: _inputDecoration('Lokasi')),
            SizedBox(height: 16),
            
            _buildLabel('Tipe Tanaman'),
            _buildDropdown(hint: 'Pilih tanaman', value: _selectedPlantType, items: _plantTypes, onChanged: (val) => setState(() => _selectedPlantType = val)),
            SizedBox(height: 16),
            
            // Financials (Modal & Profit)
            Row(
              children: [
                Expanded(child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildLabel('Modal / kg (Rp)'),
                    TextFormField(controller: _modalController, keyboardType: TextInputType.number, decoration: _inputDecoration('5000')),
                  ],
                )),
                SizedBox(width: 12),
                Expanded(child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildLabel('Target Profit (%)'),
                    TextFormField(controller: _profitController, keyboardType: TextInputType.number, decoration: _inputDecoration('20')),
                  ],
                )),
              ],
            ),
            SizedBox(height: 16),

            // Harvest Target
            _buildLabel('Target Panen (Total Kg)'),
            TextFormField(
              controller: _harvestKgController, 
              keyboardType: TextInputType.number, 
              decoration: _inputDecoration('Contoh: 1000').copyWith(suffixText: 'Kg')
            ),
            SizedBox(height: 16),

            _buildLabel('Tanggal Tanam'),
            _buildDatePicker(_plantingDate, (d) => setState(() => _plantingDate = d)),
            SizedBox(height: 16),

            _buildLabel('Perkiraan Panen'),
            _buildDatePicker(_harvestDate, (d) => setState(() => _harvestDate = d)),
            
            SizedBox(height: 40),
            
            SizedBox(
              width: double.infinity, height: 50,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _submit,
                style: ElevatedButton.styleFrom(backgroundColor: Color(0xFF0A3D2F), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25))),
                child: _isLoading ? CircularProgressIndicator(color: Colors.white) : Text('Simpan Lahan', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDatePicker(DateTime? date, Function(DateTime) onSelect) {
    return InkWell(
      onTap: () async {
        final d = await showDatePicker(context: context, initialDate: DateTime.now(), firstDate: DateTime(2020), lastDate: DateTime(2030));
        if (d != null) onSelect(d);
      },
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(border: Border.all(color: context.dividerColor), borderRadius: BorderRadius.circular(8)),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(date == null ? 'Pilih Tanggal' : '${date.day}/${date.month}/${date.year}'),
            Icon(Icons.calendar_today, size: 20, color: context.bgGrey),
          ],
        ),
      ),
    );
  }

  Widget _buildLabel(String text) => Padding(padding: EdgeInsets.only(bottom: 8), child: Text(text, style: TextStyle(fontWeight: FontWeight.w600)));
  InputDecoration _inputDecoration(String hint) => InputDecoration(hintText: hint, border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)));
  Widget _buildDropdown({required String hint, required String? value, required List<String> items, required Function(String?) onChanged}) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(border: Border.all(color: context.dividerColor), borderRadius: BorderRadius.circular(8)),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          isExpanded: true, hint: Text(hint), value: value, items: items.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(), onChanged: onChanged
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    final auth = Provider.of<AuthProvider>(context, listen: false);
    
    final land = Land(
      id: 0,
      userId: auth.userProfile!.id,
      name: _nameController.text,
      location: _locationController.text, // Now stores the address string
      latitude: _selectedLocation.latitude,
      longitude: _selectedLocation.longitude,
      plantType: _selectedPlantType,
      plantingDate: _plantingDate ?? DateTime.now(),
      harvestDate: _harvestDate,
      modalPerKg: double.tryParse(_modalController.text) ?? 0,
      targetProfitPercentage: double.tryParse(_profitController.text) ?? 0,
      targetHarvestKg: double.tryParse(_harvestKgController.text) ?? 0,
    );

    await LandService().addLand(land);
    if(mounted) {
      setState(() => _isLoading = false);
      Navigator.pop(context, true);
    }
  }
}