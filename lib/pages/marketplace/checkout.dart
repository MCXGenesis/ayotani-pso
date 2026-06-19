import 'package:flutter/material.dart';
import 'package:ayotani/theme/app_colors.dart';
import 'package:provider/provider.dart';
import '../../providers/cart_provider.dart';
import '../../routes/app_routes.dart';
import '../../theme/app_colors.dart';

class CheckoutScreen extends StatefulWidget {
  CheckoutScreen({Key? key}) : super(key: key);

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  // Static Address for demo (matches image)
  final String addressName = 'Leslie Lane';
  final String addressPhone = '+62 812 3456 7890';
  final String addressDetails = 'Jl Panjang 7-9 Kedoya Elok Plaza Bl DE/11, Kedoya Selatan, Jakarta, Kebon Jeruk, Indonesia 12345';

  // Shipping & Payment State
  String selectedPayment = 'Seabank'; // Default match image
  String deliveryDate = '6-8 Mar 2025';
  
  // Shipping cost logic matching image
  final double shippingCost = 9000;
  final double shippingDiscount = 9000; // Making it "Free" effectively as per image red text
  final double serviceFee = 1000;
  final double handlingFee = 1000;

  @override
  Widget build(BuildContext context) {
    return Consumer<CartProvider>(
      builder: (context, cart, child) {
        // Calculate totals dynamically from CartProvider
        double productSubtotal = cart.totalPrice;
        double finalTotal = productSubtotal + shippingCost - shippingDiscount + serviceFee + handlingFee;

        return Scaffold(
          backgroundColor: Color(0xFFF5F5F5),
          appBar: AppBar(
            backgroundColor: context.scaffoldBg,
            elevation: 0,
            leading: IconButton(
              icon: Icon(Icons.arrow_back, color: context.textPrimary),
              onPressed: () => Navigator.pop(context),
            ),
            title: Text(
              'Checkout',
              style: TextStyle(color: context.textPrimary, fontSize: 18, fontWeight: FontWeight.bold),
            ),
            centerTitle: true,
            actions: [
               IconButton(
                icon: Icon(Icons.headset_mic_outlined, color: context.primaryColor),
                onPressed: () {},
              ),
            ],
          ),
          body: Column(
            children: [
              _buildStepper(),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      _buildAddressSection(),
                      SizedBox(height: 8),
                      _buildItemsSection(cart), // Passing real cart data
                      SizedBox(height: 8),
                      _buildDeliveryDateSection(),
                      SizedBox(height: 8),
                      _buildShippingSection(),
                      SizedBox(height: 8),
                      _buildPaymentSection(),
                      SizedBox(height: 8),
                      _buildPaymentDetails(productSubtotal, finalTotal), // New detailed breakdown
                      SizedBox(height: 30),
                    ],
                  ),
                ),
              ),
            ],
          ),
          bottomNavigationBar: _buildBottomBar(finalTotal),
        );
      },
    );
  }

  Widget _buildStepper() {
    return Container(
      padding: EdgeInsets.fromLTRB(40, 20, 40, 20),
      color: Color(0xFFF9F9F9),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _stepIndicator('Review', true),
          _stepLine(),
          _stepIndicator('Payment', false),
          _stepLine(),
          _stepIndicator('Order', false),
        ],
      ),
    );
  }

  Widget _stepIndicator(String label, bool isActive) {
    return Column(
      children: [
        Container(
          width: 20,
          height: 20,
          decoration: BoxDecoration(
            color: context.cardBg,
            shape: BoxShape.circle,
            border: Border.all(
              color: isActive ? context.primaryColor : context.dividerColor,
              width: 5,
            ),
          ),
        ),
        SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: isActive ? context.textPrimary : context.textMuted,
          ),
        ),
      ],
    );
  }

  Widget _stepLine() {
    return Expanded(
      child: Container(
        height: 2,
        color: context.dividerColor,
        margin: EdgeInsets.only(bottom: 20, left: 4, right: 4),
      ),
    );
  }

  Widget _buildAddressSection() {
    return Container(
      color: context.cardBg,
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.location_on_outlined, color: Colors.orange, size: 20),
                  SizedBox(width: 8),
                  Text(addressName, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                ],
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(color: Colors.teal[100], borderRadius: BorderRadius.circular(4)),
                child: Text('Utama', style: TextStyle(color: Colors.teal, fontSize: 10, fontWeight: FontWeight.bold)),
              )
            ],
          ),
          Padding(
            padding: EdgeInsets.only(left: 28, top: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(addressPhone, style: TextStyle(fontSize: 13)),
                SizedBox(height: 4),
                Text(addressDetails, style: TextStyle(fontSize: 13, color: context.textSecondary, height: 1.4)),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildItemsSection(CartProvider cart) {
    return Container(
      color: context.cardBg,
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.storefront, size: 18, color: context.primaryColor),
              SizedBox(width: 8),
              Text('Eka farm shop', style: TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
          Divider(height: 24),
          // Dynamic List from Cart
          ...cart.items.map((item) => Container(
            margin: EdgeInsets.only(bottom: 16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 70,
                  height: 70,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    color: context.dividerColor,
                    image: item.imageUrl.isNotEmpty 
                      ? DecorationImage(image: NetworkImage(item.imageUrl), fit: BoxFit.cover)
                      : null,
                  ),
                  child: item.imageUrl.isEmpty ? Icon(Icons.image, color: context.bgGrey) : null,
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(item.productName, maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                      SizedBox(height: 4),
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(color: context.dividerColor, borderRadius: BorderRadius.circular(4)),
                        child: Text('Kategori', style: TextStyle(fontSize: 10, color: context.bgGrey)),
                      ),
                      SizedBox(height: 4),
                      Text('Rp${item.price.toStringAsFixed(0)}', style: TextStyle(fontWeight: FontWeight.bold, color: context.primaryColor)),
                    ],
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Color(0xFF0A3D2F),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text('Qty ${item.quantity}', style: TextStyle(color: context.cardBg, fontSize: 10, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          )).toList(),
          
          Divider(),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Total Pesanan (${cart.totalSelectedItems} produk)', style: TextStyle(fontSize: 13)),
              Text('Rp${cart.totalPrice.toStringAsFixed(0)}', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: context.primaryColor)),
            ],
          ),
          SizedBox(height: 16),
          TextField(
            decoration: InputDecoration(
              hintText: 'Pesan...',
              hintStyle: TextStyle(fontSize: 13, color: context.textMuted),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: context.dividerColor)),
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 0),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildDeliveryDateSection() {
    return Container(
      color: context.cardBg,
      padding: EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text('Delivery date', style: TextStyle(fontWeight: FontWeight.bold)),
          Text(deliveryDate, style: TextStyle(color: context.primaryColor, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildShippingSection() {
    return Container(
      color: context.cardBg,
      padding: EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Hemat', style: TextStyle(fontWeight: FontWeight.bold)),
                SizedBox(height: 4),
                Row(
                  children: [
                    Image.network('https://upload.wikimedia.org/wikipedia/commons/9/92/SICEPAT_EKSPRES_LOGO.png', width: 40, errorBuilder: (c,o,s)=>Icon(Icons.local_shipping, size: 16)),
                    SizedBox(width: 8),
                    Text('SiCepat Ekspress', style: TextStyle(fontSize: 12)),
                  ],
                ),
              ],
            ),
          ),
          Row(
            children: [
              Text('Rp${shippingCost.toStringAsFixed(0)}', style: TextStyle(fontWeight: FontWeight.bold)),
              SizedBox(width: 8),
              Icon(Icons.chevron_right, color: context.bgGrey),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildPaymentSection() {
    return GestureDetector(
      onTap: () async {
        final result = await Navigator.pushNamed(context, AppRoutes.paymentMethod);
        if (result != null && result is Map) {
          setState(() {
            selectedPayment = result['paymentName'];
          });
        }
      },
      child: Container(
        color: context.cardBg,
        padding: EdgeInsets.all(16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Payment', style: TextStyle(fontWeight: FontWeight.bold)),
            Row(
              children: [
                Text(selectedPayment, style: TextStyle(fontWeight: FontWeight.bold, color: context.primaryColor)),
                SizedBox(width: 8),
                Icon(Icons.chevron_right, color: context.bgGrey),
              ],
            )
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentDetails(double subtotal, double finalTotal) {
    return Container(
      color: context.cardBg,
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.receipt_long, color: Colors.orange, size: 20),
              SizedBox(width: 8),
              Text('Payment Details', style: TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
          SizedBox(height: 16),
          _detailRow('Subtotal untuk Produk:', 'Rp${subtotal.toStringAsFixed(0)}'),
          _detailRow('Subtotal Pengiriman:', 'Rp${shippingCost.toStringAsFixed(0)}'),
          _detailRow('Diskon Pengiriman', '-Rp${shippingDiscount.toStringAsFixed(0)}', color: Colors.red),
          _detailRow('Biaya Layanan', 'Rp${serviceFee.toStringAsFixed(0)}'),
          _detailRow('Biaya Penanganan', 'Rp${handlingFee.toStringAsFixed(0)}'),
        ],
      ),
    );
  }

  Widget _detailRow(String label, String value, {Color color = Colors.black}) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: 13, color: context.textMuted)),
          Text(value, style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: color)),
        ],
      ),
    );
  }

  Widget _buildBottomBar(double finalTotal) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.cardBg,
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: Offset(0, -5))],
      ),
      child: SafeArea(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Rp${finalTotal.toStringAsFixed(0)}', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: context.primaryColor)),
            ElevatedButton(
              onPressed: () {
                Navigator.pushNamed(
                  context, 
                  AppRoutes.payment,
                  arguments: {
                    'totalAmount': finalTotal,
                    'paymentMethod': selectedPayment
                  }
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFF0A3D2F),
                padding: EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: Text('Checkout', style: TextStyle(color: context.cardBg, fontWeight: FontWeight.bold, fontSize: 16)),
            ),
          ],
        ),
      ),
    );
  }
}