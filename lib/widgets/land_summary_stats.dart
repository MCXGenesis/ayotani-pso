import 'package:flutter/material.dart';
import '../models/land_model.dart';

class LandSummaryStats extends StatefulWidget {
  final Land? selectedLand;

  const LandSummaryStats({super.key, this.selectedLand});

  @override
  State<LandSummaryStats> createState() => _LandSummaryStatsState();
}

class _LandSummaryStatsState extends State<LandSummaryStats> {
  @override
  Widget build(BuildContext context) {
    if (widget.selectedLand == null) return const SizedBox();

    return _buildStatsGrid(widget.selectedLand!);
  }

  Widget _buildStatsGrid(Land land) {
    // 1. Modal Calculations
    final modal = land.modalPerKg;
    final targetKg = land.targetHarvestKg;
    final totalModal = modal * targetKg;
    
    // 2. Profit Calculations
    final profitPct = land.targetProfitPercentage;
    final expectedProfit = totalModal * (profitPct / 100);
    final totalRevenue = totalModal + expectedProfit;
    
    // 3. Selling Price Calculation (Harga Jual per Kg)
    // Fixed: Changed 0 to 0.0 to ensure type is double, not num
    final pricePerKg = targetKg > 0 ? totalRevenue / targetKg : 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: Text('Ringkasan Finansial', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
        ),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 1.4,
            children: [
              _buildStatCard(
                title: 'Modal Awal',
                value: 'Rp ${_formatCurrency(totalModal)}',
                subtitle: 'Rp ${modal.toStringAsFixed(0)} / kg',
                icon: Icons.account_balance_wallet,
                color: Colors.orange,
              ),
              
              _buildStatCard(
                title: 'Target Panen',
                value: '${targetKg.toStringAsFixed(0)} Kg',
                subtitle: 'Estimasi Hasil',
                icon: Icons.scale,
                color: Colors.blue,
              ),
              
              _buildStatCard(
                title: 'Target Profit',
                value: '${profitPct.toStringAsFixed(0)}%',
                subtitle: 'Rp ${_formatCurrency(expectedProfit)}',
                icon: Icons.trending_up,
                color: Colors.green,
              ),
              
              _buildStatCard(
                title: 'Target Jual',
                value: 'Rp ${_formatCurrency(pricePerKg)}',
                subtitle: 'Harga per kg',
                icon: Icons.monetization_on,
                color: Colors.purple,
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _formatCurrency(double val) {
    if (val >= 1000000) return '${(val/1000000).toStringAsFixed(1)}Jt';
    if (val >= 1000) return '${(val/1000).toStringAsFixed(1)}rb';
    return val.toStringAsFixed(0);
  }

  Widget _buildStatCard({required String title, required String value, required IconData icon, required Color color, String? subtitle}) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 4, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: TextStyle(fontSize: 12, color: Colors.grey[600], fontWeight: FontWeight.w500)),
              Icon(icon, size: 20, color: color),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: color)),
              if (subtitle != null) Text(subtitle, style: TextStyle(fontSize: 10, color: Colors.grey[500])),
            ],
          )
        ],
      ),
    );
  }
}