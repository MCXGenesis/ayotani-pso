import 'package:flutter/material.dart';
import 'package:ayotani/theme/app_colors.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../models/product_model.dart';
import '../../theme/app_colors.dart';
import '../../providers/cart_provider.dart';
import '../../routes/app_routes.dart';

class ProductDetailScreen extends StatefulWidget {
  final Product product;

  ProductDetailScreen({
    super.key,
    required this.product,
  });

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  late Future<List<Product>> _recommendationsFuture;

  @override
  void initState() {
    super.initState();
    _recommendationsFuture = _fetchRecommendations();
  }

  Future<List<Product>> _fetchRecommendations() async {
    try {
      final response = await Supabase.instance.client
          .from('products')
          .select()
          .neq('id', widget.product.id)
          .limit(5); 
      return (response as List).map((item) => Product.fromJson(item)).toList();
    } catch (e) {
      return [];
    }
  }

  void _addToCart({bool navigate = false}) {
    if (widget.product.stock <= 0) return;
    
    Provider.of<CartProvider>(context, listen: false).addToCart(widget.product);
    
    if (navigate) {
       Navigator.pushNamed(context, AppRoutes.checkout);
    } else {
       ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${widget.product.name} ditambahkan ke keranjang!'),
          backgroundColor: AppColors.green,
          duration: Duration(seconds: 1),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.scaffoldBg,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 350,
            pinned: true,
            backgroundColor: Colors.transparent,
            elevation: 0,
            leading: _buildCircleBtn(Icons.arrow_back, () => Navigator.pop(context)),
            actions: [
              _buildCircleBtn(Icons.shopping_cart_outlined, () => Navigator.pushNamed(context, AppRoutes.cart)),
              SizedBox(width: 16),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                children: [
                  Container(
                    color: context.dividerColor,
                    height: double.infinity,
                    width: double.infinity,
                    child: widget.product.imageUrl != null
                        ? CachedNetworkImage(
                            imageUrl: widget.product.imageUrl!,
                            fit: BoxFit.cover,
                            placeholder: (_,__) => Center(child: CircularProgressIndicator(color: context.primaryColor)),
                          )
                        : Center(child: Icon(Icons.image, size: 80, color: context.bgGrey)),
                  ),
                ],
              ),
            ),
          ),
          
          SliverToBoxAdapter(
            child: Container(
              color: context.scaffoldBg,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. Title and Price
                  Padding(
                    padding: EdgeInsets.fromLTRB(16, 16, 16, 0),
                    child: Text(
                      widget.product.name,
                      style: GoogleFonts.inter(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: context.textPrimary,
                      ),
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Text(
                      'Rp${widget.product.price.toStringAsFixed(0)}',
                      style: GoogleFonts.inter(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: context.primaryColor,
                      ),
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: [
                        Icon(Icons.inventory_2_outlined, size: 14, color: context.textSecondary),
                        SizedBox(width: 4),
                        Text(
                          widget.product.stock > 0 ? 'Stok tersedia: ${widget.product.stock}' : 'Stok habis',
                          style: TextStyle(fontSize: 12, color: widget.product.stock > 0 ? context.textSecondary : Colors.red),
                        )
                      ],
                    ),
                  ),
                  SizedBox(height: 16),
                  Divider(thickness: 4, color: Color(0xFFF5F5F5)),

                  // 2. Description
                  Padding(
                    padding: EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Deskripsi Produk',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                        ),
                        SizedBox(height: 8),
                        Text(
                          widget.product.description ?? 
                          'Tidak ada deskripsi tersedia for produk ini. Hubungi admin untuk informasi lebih lanjut.',
                          style: GoogleFonts.inter(fontSize: 14, color: context.textPrimary, height: 1.5),
                        ),
                      ],
                    ),
                  ),
                  Divider(thickness: 4, color: Color(0xFFF5F5F5)),

                  // 3. Shop Info (Static)
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 20,
                          backgroundColor: Color(0xFFE0E0E0),
                          child: Icon(Icons.store, color: context.bgGrey),
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text('Eka Farm Shop', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                                  SizedBox(width: 4),
                                  Icon(Icons.verified, size: 14, color: context.primaryColor),
                                ],
                              ),
                              SizedBox(height: 2),
                              Text('Online 10 menit lalu', style: TextStyle(fontSize: 11, color: context.textMuted)),
                            ],
                          ),
                        ),
                        OutlinedButton(
                          onPressed: () {},
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(color: context.primaryColor),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 0),
                            minimumSize: Size(0, 32),
                          ),
                          child: Text('Kunjungi', style: TextStyle(color: context.primaryColor, fontSize: 12)),
                        )
                      ],
                    ),
                  ),
                  Divider(thickness: 4, color: Color(0xFFF5F5F5)),
                  
                  // Recommendations
                  Container(
                    color: Color(0xFFF5F5F5),
                    padding: EdgeInsets.symmetric(vertical: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 16),
                          child: Text('Rekomendasi Lainnya', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                        ),
                        SizedBox(height: 12),
                        SizedBox(
                          height: 220,
                          child: FutureBuilder<List<Product>>(
                            future: _recommendationsFuture,
                            builder: (context, snapshot) {
                              if (!snapshot.hasData) return SizedBox();
                              final recommendations = snapshot.data!;
                              return ListView.builder(
                                scrollDirection: Axis.horizontal,
                                padding: EdgeInsets.symmetric(horizontal: 16),
                                itemCount: recommendations.length,
                                itemBuilder: (context, index) => _buildRecommendationCard(context, recommendations[index]),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 100), 
                ],
              ),
            ),
          ),
        ],
      ),
      bottomSheet: Container(
        decoration: BoxDecoration(
          color: context.scaffoldBg,
          boxShadow: [
            BoxShadow(
              blurRadius: 10,
              offset: Offset(0, -4),
              color: Colors.black.withOpacity(0.05),
            ),
          ],
        ),
        padding: EdgeInsets.fromLTRB(16, 12, 16, 12 + MediaQuery.of(context).padding.bottom),
        child: Row(
          children: [
            // Chat Icon
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: context.dividerColor),
                borderRadius: BorderRadius.circular(8),
              ),
              child: IconButton(
                icon: Icon(Icons.chat_bubble_outline, color: context.bgGrey),
                onPressed: () {}, // Chat functionality to be implemented
              ),
            ),
            SizedBox(width: 12),
            
            // Add to Cart Button (Outlined)
            Expanded(
              child: SizedBox(
                height: 48,
                child: OutlinedButton(
                  onPressed: widget.product.stock > 0 ? () => _addToCart(navigate: false) : null,
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: context.primaryColor, width: 1.5),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: Text('Keranjang', style: TextStyle(color: context.primaryColor, fontWeight: FontWeight.bold)),
                ),
              ),
            ),
            
            SizedBox(width: 12),
            
            // Buy Now / Checkout Button (Filled)
            Expanded(
              child: SizedBox(
                height: 48,
                child: ElevatedButton(
                  onPressed: widget.product.stock > 0 ? () => _addToCart(navigate: true) : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: context.primaryColor,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    elevation: 0,
                  ),
                  child: Text('Beli Langsung', style: TextStyle(fontWeight: FontWeight.bold, color: context.scaffoldBg)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCircleBtn(IconData icon, VoidCallback onPressed) {
    return Container(
      margin: EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: context.cardBg,
        shape: BoxShape.circle,
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 8)],
      ),
      child: IconButton(
        icon: Icon(icon, color: context.textPrimary, size: 20),
        onPressed: onPressed,
      ),
    );
  }

  Widget _buildRecommendationCard(BuildContext context, Product product) {
    return GestureDetector(
      onTap: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => ProductDetailScreen(product: product))),
      child: Container(
        width: 140,
        margin: EdgeInsets.only(right: 12),
        decoration: BoxDecoration(
          color: context.cardBg,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: context.dividerColor),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.vertical(top: Radius.circular(8)),
                child: CachedNetworkImage(
                  imageUrl: product.imageUrl ?? '',
                  fit: BoxFit.cover,
                  width: double.infinity,
                  placeholder: (_,__) => Container(color: context.dividerColor),
                  errorWidget: (_,__,___) => Container(color: context.dividerColor, child: Icon(Icons.image)),
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(product.name, maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  SizedBox(height: 4),
                  Text('Rp${product.price.toStringAsFixed(0)}', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: context.primaryColor)),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}