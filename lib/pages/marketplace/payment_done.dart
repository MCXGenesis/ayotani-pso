import 'package:flutter/material.dart';
import 'package:ayotani/theme/app_colors.dart';
import '../../theme/app_colors.dart';

class PaymentDoneScreen extends StatelessWidget {
  PaymentDoneScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF9F9F9),
      appBar: AppBar(
        backgroundColor: Color(0xFFF9F9F9),
        elevation: 0,
        leading: SizedBox(), // Hide back button
        title: Text('Checkout', style: TextStyle(color: context.textPrimary, fontWeight: FontWeight.bold)),
        centerTitle: true,
         actions: [
          IconButton(icon: Icon(Icons.headset_mic_outlined, color: context.primaryColor), onPressed: () {}),
        ],
      ),
      body: Column(
        children: [
          // Stepper
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 40, vertical: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _stepIcon(context, true), _stepLine(context, true), _stepIcon(context, true), _stepLine(context, true), _stepIcon(context, true)
              ],
            ),
          ),
          
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(color: Color(0xFF0A3D2F), shape: BoxShape.circle),
                  child: Icon(Icons.check, size: 60, color: context.scaffoldBg),
                ),
                SizedBox(height: 24),
                Text('Pembayaran Berhasil!', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: context.textPrimary)),
                SizedBox(height: 12),
                Text(
                  'Pesanan Anda telah berhasil dibuat!\nUntuk keterangan lebih lanjut, kunjungi\nkeranjang.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: context.bgGrey, height: 1.5),
                ),
              ],
            ),
          ),
          
          Padding(
            padding: EdgeInsets.all(24.0),
            child: Column(
              children: [
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFF0A3D2F),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: Text('Lanjut Belanja', style: TextStyle(color: context.scaffoldBg, fontWeight: FontWeight.bold)),
                  ),
                ),
                SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: OutlinedButton(
                    onPressed: () => Navigator.pushNamedAndRemoveUntil(context, '/cart', (route) => false),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: context.primaryColor),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: Text('Keranjang Saya', style: TextStyle(color: context.primaryColor, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _stepIcon(BuildContext context, bool active) {
    return Container(
      width: 20, height: 20,
      decoration: BoxDecoration(
        color: active ? context.primaryColor : context.dividerColor,
        shape: BoxShape.circle,
        border: active ? Border.all(color: context.cardBg, width: 2) : null,
      ),
      child: active ? Icon(Icons.check, size: 12, color: context.cardBg) : null,
    );
  }

  Widget _stepLine(BuildContext context, bool active) {
    return Expanded(child: Container(height: 3, color: active ? context.primaryColor : context.dividerColor));
  }
}