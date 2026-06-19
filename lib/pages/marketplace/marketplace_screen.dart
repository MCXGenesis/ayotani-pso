import 'dart:async';
import 'package:flutter/material.dart';
import 'package:ayotani/theme/app_colors.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../models/product_model.dart';
import '../../theme/app_colors.dart';
import '../../routes/app_routes.dart';
import 'product_detail_screen.dart';

class MarketplaceScreen extends StatefulWidget {
  MarketplaceScreen({super.key});

  @override
  State<MarketplaceScreen> createState() => _MarketplaceScreenState();
}

class _MarketplaceScreenState extends State<MarketplaceScreen> {
  // State for logic
  late Future<List<Product>> _productsFuture;
  late Future<int> _gemsFuture;
  String _selectedCategory = 'All';
  
  // Banner State
  final PageController _bannerController = PageController();
  int _currentBannerIndex = 0;
  Timer? _bannerTimer;

  // Dummy Banners
  final List<String> _bannerImages = [
    'https://placehold.co/800x450/0A3D2F/FFFFFF.png?text=AyoTani+Shop',
    'https://images.unsplash.com/photo-1560493676-04071c5f467b?auto=format&fit=crop&w=800&q=80',
    'https://placehold.co/800x450/0A3D2F/FFFFFF.png?text=Smart+Farming',
  ];

  @override
  void initState() {
    super.initState();
    _productsFuture = _fetchProducts();
    _gemsFuture = _fetchUserGems();
    
    // Auto-scroll banner
    _bannerTimer = Timer.periodic(Duration(seconds: 5), (Timer timer) {
      if (_currentBannerIndex < _bannerImages.length - 1) {
        _currentBannerIndex++;
      } else {
        _currentBannerIndex = 0;
      }
      if (_bannerController.hasClients) {
        _bannerController.animateToPage(
          _currentBannerIndex,
          duration: Duration(milliseconds: 350),
          curve: Curves.easeIn,
        );
      }
    });
  }

  @override
  void dispose() {
    _bannerTimer?.cancel();
    _bannerController.dispose();
    super.dispose();
  }

  Future<List<Product>> _fetchProducts() async {
    try {
      var query = Supabase.instance.client
          .from('products')
          .select()
          .order('created_at', ascending: false);
      
      // Basic filtering if category is selected (and not 'All')
      // Note: This matches the 'category' text column in your DB.
      if (_selectedCategory != 'All') {
        // Mapping UI names to potential DB keys if needed, or using loose matching
        // For now, assuming exact match or partial match logic could be added here
      }

      final response = await query;
      return (response as List).map((item) => Product.fromJson(item)).toList();
    } catch (e) {
      return [];
    }
  }

  Future<int> _fetchUserGems() async {
    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) return 0;
      
      final response = await Supabase.instance.client
          .from('profiles')
          .select('gems')
          .eq('id', userId)
          .single();
      return response['gems'] as int? ?? 0;
    } catch (e) {
      return 0;
    }
  }

  void _onCategorySelected(String category) {
    setState(() {
      _selectedCategory = category;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.scaffoldBg,
      appBar: AppBar(
        backgroundColor: context.primaryColor,
        elevation: 0,
        titleSpacing: 16,
        title: Container(
          height: 40,
          decoration: BoxDecoration(
            color: context.scaffoldBg,
            borderRadius: BorderRadius.circular(8),
          ),
          child: TextField(
            readOnly: true, // Making it read-only for now unless you build search logic
            onTap: () {
               // Navigation to search screen could go here
            },
            decoration: InputDecoration(
              hintText: 'Cari Bibit Cabai Merah...',
              hintStyle: TextStyle(color: context.textMuted, fontSize: 13),
              prefixIcon: Icon(Icons.search, color: context.textMuted, size: 20),
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(vertical: 8),
            ),
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.notifications_outlined, color: context.scaffoldBg),
            onPressed: () {},
          ),
          IconButton(
            icon: Icon(Icons.shopping_cart_outlined, color: context.scaffoldBg),
            onPressed: () => Navigator.pushNamed(context, AppRoutes.cart),
          ),
          SizedBox(width: 8),
        ],
      ),
      body: FutureBuilder<List<Product>>(
        future: _productsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator(color: context.primaryColor));
          }
          
          // Local filtering for immediate UI response
          List<Product> products = snapshot.data ?? [];
          if (_selectedCategory != 'All') {
             products = products.where((p) => p.category.toLowerCase().contains(_selectedCategory.toLowerCase()) || 
                                              _selectedCategory.toLowerCase().contains(p.category.toLowerCase())).toList();
          }

          return LayoutBuilder(
            builder: (context, constraints) {
              // Responsive grid
              int crossAxisCount = 2;
              if (constraints.maxWidth > 600) crossAxisCount = 3;
              if (constraints.maxWidth > 900) crossAxisCount = 4;

              return CustomScrollView(
                slivers: [
                  // 1. Banner & Overlapping Wallet Card
                  SliverToBoxAdapter(
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        // Green Background Extension
                        Container(height: 140, color: context.primaryColor),
                        
                        // Scrolling Banner
                        Container(
                          margin: EdgeInsets.fromLTRB(16, 10, 16, 0),
                          height: 150,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0,2))],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: PageView.builder(
                              controller: _bannerController,
                              itemCount: _bannerImages.length,
                              onPageChanged: (index) {
                                setState(() => _currentBannerIndex = index);
                              },
                              itemBuilder: (context, index) {
                                return Stack(
                                  fit: StackFit.expand,
                                  children: [
                                    CachedNetworkImage(
                                      imageUrl: _bannerImages[index],
                                      fit: BoxFit.cover,
                                      placeholder: (context, url) => Container(color: context.dividerColor),
                                    ),
                                    Container(
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          begin: Alignment.centerLeft,
                                          end: Alignment.centerRight,
                                          colors: [Colors.black.withOpacity(0.6), Colors.transparent],
                                        ),
                                      ),
                                      padding: EdgeInsets.all(20),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Text(
                                            'Gunakan pupuk Organik\nuntuk tanaman yang\nlebih sehat!',
                                            style: TextStyle(
                                                color: context.scaffoldBg,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 14,
                                                height: 1.3),
                                          ),
                                          SizedBox(height: 10),
                                          Container(
                                            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                            decoration: BoxDecoration(
                                                color: context.scaffoldBg, borderRadius: BorderRadius.circular(20)),
                                            child: Text('Beli Sekarang',
                                                style: TextStyle(
                                                    color: context.primaryColor,
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.bold)),
                                          )
                                        ],
                                      ),
                                    ),
                                  ],
                                );
                              },
                            ),
                          ),
                        ),

                        // Indicators
                        Positioned(
                          top: 145, 
                          left: 0,
                          right: 0,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: _bannerImages.asMap().entries.map((entry) {
                              return Container(
                                width: 8.0,
                                height: 8.0,
                                margin: EdgeInsets.symmetric(horizontal: 4.0),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: _currentBannerIndex == entry.key
                                      ? context.scaffoldBg
                                      : context.scaffoldBg.withOpacity(0.4),
                                ),
                              );
                            }).toList(),
                          ),
                        ),

                        // Overlapping Wallet Card
                        Positioned(
                          top: 170, 
                          left: 16,
                          right: 16,
                          child: Container(
                            padding: EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                            decoration: BoxDecoration(
                              color: context.scaffoldBg,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.08),
                                  blurRadius: 10,
                                  offset: Offset(0, 4),
                                ),
                              ],
                            ),
                            child: FutureBuilder<int>(
                              future: _gemsFuture,
                              builder: (context, gemSnapshot) {
                                final gems = gemSnapshot.data ?? 0;
                                return Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    _buildWalletAction(Icons.qr_code_scanner, 'Scan'),
                                    _buildVerticalDivider(),
                                    _buildWalletInfo(Icons.account_balance_wallet_outlined, 'Rp0', 'Isi Saldo'),
                                    _buildVerticalDivider(),
                                    _buildWalletInfo(Icons.monetization_on_outlined, gems.toString(), 'Gems'),
                                  ],
                                );
                              }
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Spacer for the overlapping card
                  SliverToBoxAdapter(child: SizedBox(height: 60)),

                  // 2. Categories
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Category',
                              style: TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 16)),
                          SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildCategoryItem('All', Icons.grid_view, context.dividerColor),
                              _buildCategoryItem('Seeds', Icons.grass, Colors.yellow[100]!),
                              _buildCategoryItem('Growth', Icons.eco, Colors.green[100]!), // Maps to 'Growth Promoters'
                              _buildCategoryItem('Tools', Icons.build, Colors.blue[100]!),
                              _buildCategoryItem('Fertilizer', Icons.science, Colors.brown[100]!),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                  SliverToBoxAdapter(child: SizedBox(height: 24)),

                  // 3. Special Chip
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Container(
                          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.teal[50],
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: Colors.teal.withOpacity(0.3)),
                          ),
                          child: Text(
                            'Spesial hari Pohon Sedunia',
                            style: TextStyle(color: Colors.teal[800], fontSize: 12, fontWeight: FontWeight.w600),
                          ),
                        ),
                      ),
                    ),
                  ),
                  
                  SliverToBoxAdapter(child: SizedBox(height: 16)),

                  // 4. Flash Sale
                  SliverToBoxAdapter(
                    child: Column(
                      children: [
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 16),
                          child: Row(
                            children: [
                              Text('FLASHSALE',
                                  style: TextStyle(
                                      fontWeight: FontWeight.w900,
                                      fontSize: 18,
                                      color: Color(0xFF0A3D2F))),
                              Spacer(),
                              Row(
                                children: [
                                  _buildTimerBox('02'),
                                  Text(' : ', style: TextStyle(fontWeight: FontWeight.bold)),
                                  _buildTimerBox('12'),
                                  Text(' : ', style: TextStyle(fontWeight: FontWeight.bold)),
                                  _buildTimerBox('45'),
                                ],
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: 12),
                        SizedBox(
                          height: 240,
                          child: ListView.builder(
                            padding: EdgeInsets.symmetric(horizontal: 16),
                            scrollDirection: Axis.horizontal,
                            // Use raw snapshot data here so flash sale always shows something regardless of filter
                            itemCount: (snapshot.data ?? []).length > 5 ? 5 : (snapshot.data ?? []).length,
                            itemBuilder: (context, index) {
                               if (snapshot.data == null) return SizedBox();
                               return _buildFlashSaleCard(context, snapshot.data![index]);
                            },
                          ),
                        ),
                      ],
                    ),
                  ),

                  SliverToBoxAdapter(child: SizedBox(height: 24)),

                  // 5. Recommendations Header
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Rekomendasi Produk', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          if (_selectedCategory != 'All')
                            GestureDetector(
                              onTap: () => setState(() => _selectedCategory = 'All'),
                              child: Text('Clear Filter', style: TextStyle(fontSize: 12, color: Colors.red[400])),
                            )
                        ],
                      ),
                    ),
                  ),

                  // 6. Product Grid (Filtered)
                  products.isEmpty 
                  ? SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.all(32.0),
                        child: Center(child: Text('Tidak ada produk kategori $_selectedCategory', style: TextStyle(color: context.bgGrey))),
                      ),
                    )
                  : SliverPadding(
                      padding: EdgeInsets.symmetric(horizontal: 16),
                      sliver: SliverGrid(
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: crossAxisCount,
                          childAspectRatio: 0.62, 
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                        ),
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            return _buildProductCard(context, products[index]);
                          },
                          childCount: products.length,
                        ),
                      ),
                    ),

                  SliverToBoxAdapter(child: SizedBox(height: 40)),
                ],
              );
            }
          );
        },
      ),
    );
  }

  Widget _buildVerticalDivider() {
    return Container(width: 1, height: 24, color: context.dividerColor);
  }

  Widget _buildWalletAction(IconData icon, String label) {
    return InkWell(
      onTap: () {}, // Action for Scan
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: context.textSecondary, size: 24),
          SizedBox(height: 4),
          Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _buildWalletInfo(IconData icon, String value, String label) {
    return InkWell(
      onTap: () {}, // Action for Wallet buttons
      child: Row(
        children: [
          Icon(icon, size: 20, color: context.primaryColor),
          SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(value, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              Text(label, style: TextStyle(fontSize: 11, color: context.textMuted)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryItem(String label, IconData icon, Color bgColor) {
    final isSelected = _selectedCategory == label || 
        (_selectedCategory == 'Growth' && label == 'Growth') ||
        (_selectedCategory == 'Tools' && label == 'Tools');
        
    return GestureDetector(
      onTap: () => _onCategorySelected(label),
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: isSelected ? context.primaryColor : context.cardBg,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: isSelected ? context.primaryColor : context.dividerColor),
              boxShadow: [
                BoxShadow(
                  color: context.bgGrey.withOpacity(0.05),
                  blurRadius: 4,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Icon(icon, color: isSelected ? context.cardBg : context.primaryColor, size: 26),
          ),
          SizedBox(height: 8),
          Text(
            label, 
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 11, 
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500, 
              color: isSelected ? context.primaryColor : context.textPrimary,
              height: 1.2
            )
          ),
        ],
      ),
    );
  }

  Widget _buildTimerBox(String text) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      decoration: BoxDecoration(
        color: Color(0xFF0A3D2F),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        text, 
        style: TextStyle(color: context.cardBg, fontWeight: FontWeight.bold, fontSize: 12)
      ),
    );
  }

  Widget _buildFlashSaleCard(BuildContext context, Product product) {
    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ProductDetailScreen(product: product))),
      child: Container(
        width: 140,
        margin: EdgeInsets.only(right: 12),
        decoration: BoxDecoration(
          color: context.cardBg,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: context.dividerColor),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.vertical(top: Radius.circular(10)),
                  child: CachedNetworkImage(
                    imageUrl: product.imageUrl ?? '',
                    height: 120,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    placeholder: (_,__) => Container(color: context.dividerColor),
                    errorWidget: (_,__,___) => Container(color: context.dividerColor, child: Icon(Icons.image)),
                  ),
                ),
                Positioned(
                  top: 8,
                  left: 8,
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text('42%', style: TextStyle(color: context.cardBg, fontSize: 10, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
            Padding(
              padding: EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                    decoration: BoxDecoration(color: context.dividerColor, borderRadius: BorderRadius.circular(2)),
                    child: Text(product.categoryDisplay, style: TextStyle(fontSize: 9, color: context.bgGrey)),
                  ),
                  SizedBox(height: 4),
                  Text(
                    product.name, 
                    maxLines: 2, 
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, height: 1.2),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Rp${product.price.toStringAsFixed(0)}', 
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: context.primaryColor)
                  ),
                  Text(
                    'Rp${(product.price * 1.4).toStringAsFixed(0)}',
                    style: TextStyle(fontSize: 10, color: context.textMuted, decoration: TextDecoration.lineThrough)
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductCard(BuildContext context, Product product) {
    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ProductDetailScreen(product: product))),
      child: Container(
        decoration: BoxDecoration(
          color: context.cardBg,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: context.dividerColor),
          boxShadow: [
            BoxShadow(
              color: context.bgGrey.withOpacity(0.05),
              blurRadius: 4,
              offset: Offset(0, 2),
            )
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.vertical(top: Radius.circular(10)),
                    child: CachedNetworkImage(
                      imageUrl: product.imageUrl ?? '',
                      width: double.infinity,
                      fit: BoxFit.cover,
                      placeholder: (_,__) => Container(color: context.dividerColor),
                      errorWidget: (_,__,___) => Container(color: context.dividerColor, child: Icon(Icons.image)),
                    ),
                  ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Icon(Icons.favorite_border, color: context.bgGrey, size: 20),
                  ),
                ],
              ),
            ),
            Padding(
              padding: EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: context.dividerColor,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(product.categoryDisplay, style: TextStyle(fontSize: 10, color: context.bgGrey)),
                  ),
                  SizedBox(height: 4),
                  Text(
                    product.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, height: 1.2),
                  ),
                  SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.star, size: 12, color: Colors.amber),
                      SizedBox(width: 2),
                      Text(product.rating.toString(), style: TextStyle(fontSize: 10, color: context.bgGrey)),
                    ],
                  ),
                  SizedBox(height: 6),
                  Text(
                    'Rp${product.price.toStringAsFixed(0)}',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: context.primaryColor),
                  ),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}