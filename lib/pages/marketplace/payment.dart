import 'package:flutter/material.dart';
import 'package:ayotani/theme/app_colors.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../routes/app_routes.dart';
import '../../theme/app_colors.dart';
import '../../providers/cart_provider.dart';

class PaymentScreen extends StatefulWidget {
  final double totalAmount;
  final String paymentMethod;

  PaymentScreen({
    Key? key,
    required this.totalAmount,
    required this.paymentMethod,
  }) : super(key: key);

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  // Demo VA number
  final String vaNumber = '781 0123 4567 890';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: Color(0xFFF5F5F5),
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, size: 18, color: context.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Payment', style: TextStyle(color: context.textPrimary, fontWeight: FontWeight.bold)),
        centerTitle: true,
        actions: [
          IconButton(icon: Icon(Icons.headset_mic_outlined, color: context.primaryColor), onPressed: () {}),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildStepper(),
            
            // Total Payment Card
            Container(
              margin: EdgeInsets.symmetric(horizontal: 16),
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(color: context.scaffoldBg, borderRadius: BorderRadius.circular(12)),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Total Pembayaran:', style: TextStyle(fontWeight: FontWeight.bold)),
                  Text('Rp${widget.totalAmount.toStringAsFixed(0)}', style: TextStyle(fontWeight: FontWeight.bold, color: context.primaryColor, fontSize: 16)),
                ],
              ),
            ),
            
            SizedBox(height: 16),
            
            // Bank Info Card
            Container(
              margin: EdgeInsets.symmetric(horizontal: 16),
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(color: context.scaffoldBg, borderRadius: BorderRadius.circular(12)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.savings, color: Colors.orange), // Seabank Logo placeholder
                      SizedBox(width: 12),
                      Expanded(child: Text('${widget.paymentMethod} (dicek otomatis)', style: TextStyle(fontWeight: FontWeight.bold))),
                    ],
                  ),
                  Divider(height: 24),
                  Text('No. Rekening', style: TextStyle(fontSize: 12, color: context.bgGrey)),
                  SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(vaNumber, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: context.primaryColor)),
                      InkWell(
                        onTap: () {
                          Clipboard.setData(ClipboardData(text: vaNumber));
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Copied!'), duration: Duration(seconds: 1)));
                        },
                        child: Icon(Icons.copy, color: context.primaryColor, size: 20),
                      )
                    ],
                  )
                ],
              ),
            ),

            SizedBox(height: 16),

            // Instructions
            Container(
              margin: EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(color: context.scaffoldBg, borderRadius: BorderRadius.circular(12)),
              child: Theme(
                data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                child: ExpansionTile(
                  title: Text('Transfer Bank', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  initiallyExpanded: true,
                  childrenPadding: EdgeInsets.fromLTRB(16, 0, 16, 16),
                  children: const [
                    Text('1. Klik Buka Aplikasi Seabank dan log in ke akun Seabank\n2. Masuk ke halaman Transfer Virtual Account\n3. Pastikan jumlah benar\n4. Masukkan PIN anda.', style: TextStyle(height: 1.5, fontSize: 13)),
                  ],
                ),
              ),
            ),
             SizedBox(height: 8),
             Container(
              margin: EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(color: context.scaffoldBg, borderRadius: BorderRadius.circular(12)),
               child: ListTile(
                title: Text('Transfer Bank (manual)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                trailing: Icon(Icons.keyboard_arrow_down),
               ),
             ),

             SizedBox(height: 32),
             
             // Bottom Buttons
             Padding(
               padding: EdgeInsets.symmetric(horizontal: 16),
               child: Column(
                 children: [
                   SizedBox(
                     width: double.infinity,
                     height: 48,
                     child: ElevatedButton(
                       onPressed: () {
                         // Action logic here
                       },
                       style: ElevatedButton.styleFrom(
                         backgroundColor: Color(0xFF0A3D2F),
                         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                       ),
                       child: Text('Buka Aplikasi Seabank', style: TextStyle(color: context.scaffoldBg, fontWeight: FontWeight.bold)),
                     ),
                   ),
                   SizedBox(height: 12),
                   SizedBox(
                     width: double.infinity,
                     height: 48,
                     child: OutlinedButton(
                       onPressed: () {
                         // Actually complete payment flow
                         Provider.of<CartProvider>(context, listen: false).clearCart();
                         Navigator.pushNamed(context, AppRoutes.paymentDone);
                       },
                       style: OutlinedButton.styleFrom(
                         side: BorderSide(color: context.primaryColor),
                         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                       ),
                       child: Text('Saya Sudah Membayar', style: TextStyle(color: context.primaryColor, fontWeight: FontWeight.bold)),
                     ),
                   ),
                 ],
               ),
             ),
             SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildStepper() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 40, vertical: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _stepIcon(true), _stepLine(true), _stepIcon(true), _stepLine(false), _stepIcon(false)
        ],
      ),
    );
  }

  Widget _stepIcon(bool active) {
    return Container(
      width: 20, height: 20,
      decoration: BoxDecoration(
        color: active ? context.primaryColor : context.dividerColor,
        shape: BoxShape.circle,
        border: active ? Border.all(color: context.cardBg, width: 2) : null,
        boxShadow: active ? [BoxShadow(color: Colors.black12, blurRadius: 4)] : null,
      ),
      child: active ? Icon(Icons.check, size: 12, color: context.cardBg) : null,
    );
  }

  Widget _stepLine(bool active) {
    return Expanded(child: Container(height: 3, color: active ? context.primaryColor : context.dividerColor));
  }
}