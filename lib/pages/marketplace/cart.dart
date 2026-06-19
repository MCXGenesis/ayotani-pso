import 'package:flutter/material.dart';
import 'package:ayotani/theme/app_colors.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../routes/app_routes.dart';
import '../../providers/cart_provider.dart';
import '../../theme/app_colors.dart';
import '../../models/product_model.dart';
import 'product_detail_screen.dart';

class ShoppingCartScreen extends StatefulWidget {
  ShoppingCartScreen({Key? key}) : super(key: key);

  @override
  State<ShoppingCartScreen> createState() => _ShoppingCartScreenState();
}

class _ShoppingCartScreenState extends State<ShoppingCartScreen> {
  late Future<List<Product>> _similarProductsFuture;

  @override
  void initState() {
    super.initState();
    _similarProductsFuture = _fetchSimilarProducts();
  }

  Future<List<Product>> _fetchSimilarProducts() async {
    try {
      // Fetch 4 random products for suggestions
      final response = await Supabase.instance.client
          .from('products')
          .select()
          .limit(4);
      
      return (response as List).map((item) => Product.fromJson(item)).toList();
    } catch (e) {
      return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<CartProvider>(
      builder: (context, cart, child) {
        return Scaffold(
          backgroundColor: Color(0xFFF5F5F5),
          appBar: AppBar(
            backgroundColor: Color(0xFFF5F5F5),
            elevation: 0,
            leading: IconButton(
              icon: Icon(Icons.arrow_back_ios_new, size: 20, color: context.textPrimary),
              // FIX: Handle navigation safely
              onPressed: () {
                if (Navigator.canPop(context)) {
                  Navigator.pop(context);
                } else {
                  // If no history (e.g. after purchase), go to Marketplace
                  Navigator.pushReplacementNamed(context, AppRoutes.marketplace);
                }
              },
            ),
            title: Text(
              'Keranjang',
              style: TextStyle(color: context.textPrimary, fontSize: 18, fontWeight: FontWeight.w700),
            ),
            centerTitle: true,
          ),
          body: cart.items.isEmpty 
              ? _buildEmptyState()
              : Column(
                  children: [
                    Expanded(
                      child: SingleChildScrollView(
                        padding: EdgeInsets.all(16),
                        child: Column(
                          children: [
                            // Wrap items in a white container to mimic the "Shop Group" card
                            Container(
                              decoration: BoxDecoration(
                                color: context.scaffoldBg,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Column(
                                children: [
                                  // Shop Header (Static due to schema limits)
                                  Padding(
                                    padding: EdgeInsets.all(12),
                                    child: Row(
                                      children: [
                                        _buildCheckbox(true), // Shop checkbox
                                        SizedBox(width: 12),
                                        Icon(Icons.storefront, size: 18, color: context.primaryColor),
                                        SizedBox(width: 8),
                                        Text('Eka farm shop', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                                        Icon(Icons.chevron_right, size: 18, color: context.bgGrey),
                                      ],
                                    ),
                                  ),
                                  Divider(height: 1),
                                  
                                  // Items List
                                  ListView.builder(
                                    shrinkWrap: true,
                                    physics: NeverScrollableScrollPhysics(),
                                    itemCount: cart.items.length,
                                    itemBuilder: (context, index) {
                                      return _buildCartItemCard(cart, index);
                                    },
                                  ),
                                ],
                              ),
                            ),
                            
                            // "Produk serupa" / Recommendations Section
                            SizedBox(height: 24),
                            Row(
                              children: [
                                Expanded(child: Divider()),
                                Padding(
                                  padding: EdgeInsets.symmetric(horizontal: 12),
                                  child: Text('Produk serupa', style: TextStyle(color: context.bgGrey, fontSize: 12)),
                                ),
                                Expanded(child: Divider()),
                              ],
                            ),
                            SizedBox(height: 16),
                            
                            // Grid for Recommendations (Connected to DB)
                            FutureBuilder<List<Product>>(
                              future: _similarProductsFuture,
                              builder: (context, snapshot) {
                                if (snapshot.connectionState == ConnectionState.waiting) {
                                  return Center(child: CircularProgressIndicator(color: context.primaryColor));
                                }
                                final similarProducts = snapshot.data ?? [];
                                
                                return GridView.builder(
                                  shrinkWrap: true,
                                  physics: NeverScrollableScrollPhysics(),
                                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: 2,
                                    childAspectRatio: 0.7,
                                    crossAxisSpacing: 12,
                                    mainAxisSpacing: 12,
                                  ),
                                  itemCount: similarProducts.length,
                                  itemBuilder: (context, index) => _buildRecommendationCard(context, similarProducts[index]),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                    _buildBottomBar(cart),
                  ],
                ),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.shopping_cart_outlined, size: 80, color: context.textMuted),
          SizedBox(height: 16),
          Text(
            'Keranjang Kosong',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: context.textSecondary),
          ),
          SizedBox(height: 8),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.green),
            child: Text('Mulai Belanja', style: TextStyle(color: Colors.white)),
          )
        ],
      ),
    );
  }

  Widget _buildCheckbox(bool isSelected) {
    return Container(
      width: 20,
      height: 20,
      decoration: BoxDecoration(
        border: Border.all(
          color: isSelected ? context.primaryColor : Color(0xFFE0E0E0),
          width: 2,
        ),
        borderRadius: BorderRadius.circular(4),
        color: isSelected ? context.primaryColor : Colors.transparent,
      ),
      child: isSelected ? Icon(Icons.check, size: 14, color: context.cardBg) : null,
    );
  }

  Widget _buildCartItemCard(CartProvider cart, int index) {
    final item = cart.items[index];
    
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFFF0F0F0))),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Checkbox
          Padding(
            padding: EdgeInsets.only(top: 24),
            child: GestureDetector(
              onTap: () => cart.toggleSelection(index),
              child: _buildCheckbox(item.isSelected),
            ),
          ),
          SizedBox(width: 12),
          
          // Image
          Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              color: Color(0xFFF5F5F5),
              borderRadius: BorderRadius.circular(8),
              image: item.imageUrl.isNotEmpty 
                  ? DecorationImage(image: NetworkImage(item.imageUrl), fit: BoxFit.cover)
                  : null,
            ),
            child: item.imageUrl.isEmpty 
                ? Icon(Icons.image, size: 40, color: context.bgGrey) 
                : null,
          ),
          SizedBox(width: 12),
          
          // Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        item.productName,
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    SizedBox(width: 8),
                    InkWell(
                      onTap: () => cart.removeItem(index),
                      child: Icon(Icons.delete_outline, size: 18, color: Colors.red),
                    ),
                  ],
                ),
                SizedBox(height: 4),
                // Category Chip (Hardcoded as not in CartItem model usually, or extract from product if added)
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: context.dividerColor,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text('Product', style: TextStyle(fontSize: 10, color: context.bgGrey)),
                ),
                SizedBox(height: 4),
                // Price Row
                Row(
                  children: [
                     Text(
                      'Rp${(item.price * 1.2).toStringAsFixed(0)}', // Fake original price
                      style: TextStyle(fontSize: 11, color: context.textMuted, decoration: TextDecoration.lineThrough),
                    ),
                    SizedBox(width: 6),
                    Text(
                      'Rp${item.price.toStringAsFixed(0)}',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: context.primaryColor),
                    ),
                  ],
                ),
                
                // Qty Row
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    SizedBox(width: 8),
                    Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: context.dividerColor),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Row(
                        children: [
                          _qtyButton(Icons.remove, () => cart.updateQuantity(index, false)),
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: 12),
                            child: Text('${item.quantity}', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                          ),
                          _qtyButton(Icons.add, () => cart.updateQuantity(index, true)),
                        ],
                      ),
                    )
                  ],
                )
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _qtyButton(IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: EdgeInsets.all(4.0),
        child: Icon(icon, size: 14, color: context.textSecondary),
      ),
    );
  }

  Widget _buildRecommendationCard(BuildContext context, Product product) {
    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ProductDetailScreen(product: product))),
      child: Container(
        decoration: BoxDecoration(
          color: context.cardBg,
          borderRadius: BorderRadius.circular(8),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4)],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: context.bgGrey,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(8)),
                ),
                width: double.infinity,
                child: product.imageUrl != null 
                    ? Image.network(product.imageUrl!, fit: BoxFit.cover)
                    : Center(child: Icon(Icons.image, color: context.cardBg)),
              ),
            ),
            Padding(
              padding: EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                    color: context.dividerColor,
                    child: Text(product.categoryDisplay, style: TextStyle(fontSize: 8)),
                  ),
                  SizedBox(height: 4),
                  Text(
                    product.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 4),
                   Row(
                    children: List.generate(5, (i) => Icon(
                      i < product.rating ? Icons.star : Icons.star_border, 
                      size: 10, 
                      color: context.primaryColor
                    )),
                   ),
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

  Widget _buildBottomBar(CartProvider cart) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.cardBg,
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: Offset(0, -5))],
      ),
      child: SafeArea(
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Icons.keyboard_arrow_up, size: 20),
                    SizedBox(width: 4),
                    Text('Total (${cart.totalSelectedItems})', style: TextStyle(fontWeight: FontWeight.bold)),
                  ],
                ),
                Text(
                  'Rp${cart.totalPrice.toStringAsFixed(0)}',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: context.textPrimary),
                ),
              ],
            ),
            SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: cart.totalSelectedItems > 0
                    ? () => Navigator.pushNamed(context, AppRoutes.checkout)
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: context.primaryColor,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  disabledBackgroundColor: context.bgGrey,
                ),
                child: Text('Checkout', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: context.cardBg)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}