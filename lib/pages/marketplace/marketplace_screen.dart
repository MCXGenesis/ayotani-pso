import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../models/product_model.dart';
import '../../theme/app_colors.dart';
import '../../routes/app_routes.dart';
import 'product_detail_screen.dart';

class MarketplaceScreen extends StatefulWidget {
  const MarketplaceScreen({super.key});

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
    'https://images.unsplash.com/photo-1599520847774-4b47209f257a?auto=format&fit=crop&w=800&q=80',
    'https://images.unsplash.com/photo-1560493676-04071c5f467b?auto=format&fit=crop&w=800&q=80',
    'https://images.unsplash.com/photo-1625246333195-58197bd47d72?auto=format&fit=crop&w=800&q=80',
  ];

  @override
  void initState() {
    super.initState();
    _productsFuture = _fetchProducts();
    _gemsFuture = _fetchUserGems();
    
    // Auto-scroll banner
    _bannerTimer = Timer.periodic(const Duration(seconds: 5), (Timer timer) {
      if (_currentBannerIndex < _bannerImages.length - 1) {
        _currentBannerIndex++;
      } else {
        _currentBannerIndex = 0;
      }
      if (_bannerController.hasClients) {
        _bannerController.animateToPage(
          _currentBannerIndex,
          duration: const Duration(milliseconds: 350),
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
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: AppColors.green,
        elevation: 0,
        titleSpacing: 16,
        title: Container(
          height: 40,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
          ),
          child: TextField(
            readOnly: true, // Making it read-only for now unless you build search logic
            onTap: () {
               // Navigation to search screen could go here
            },
            decoration: InputDecoration(
              hintText: 'Cari Bibit Cabai Merah...',
              hintStyle: TextStyle(color: Colors.grey[400], fontSize: 13),
              prefixIcon: Icon(Icons.search, color: Colors.grey[400], size: 20),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(vertical: 8),
            ),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined, color: Colors.white),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.shopping_cart_outlined, color: Colors.white),
            onPressed: () => Navigator.pushNamed(context, AppRoutes.cart),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: FutureBuilder<List<Product>>(
        future: _productsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: AppColors.green));
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
                        Container(height: 140, color: AppColors.green),
                        
                        // Scrolling Banner
                        Container(
                          margin: const EdgeInsets.fromLTRB(16, 10, 16, 0),
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
                                      placeholder: (context, url) => Container(color: Colors.grey[300]),
                                    ),
                                    Container(
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          begin: Alignment.centerLeft,
                                          end: Alignment.centerRight,
                                          colors: [Colors.black.withOpacity(0.6), Colors.transparent],
                                        ),
                                      ),
                                      padding: const EdgeInsets.all(20),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          const Text(
                                            'Gunakan pupuk Organik\nuntuk tanaman yang\nlebih sehat!',
                                            style: TextStyle(
                                                color: Colors.white,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 14,
                                                height: 1.3),
                                          ),
                                          const SizedBox(height: 10),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                            decoration: BoxDecoration(
                                                color: Colors.white, borderRadius: BorderRadius.circular(20)),
                                            child: const Text('Beli Sekarang',
                                                style: TextStyle(
                                                    color: AppColors.green,
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
                                margin: const EdgeInsets.symmetric(horizontal: 4.0),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: _currentBannerIndex == entry.key
                                      ? Colors.white
                                      : Colors.white.withOpacity(0.4),
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
                            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.08),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
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
                  const SliverToBoxAdapter(child: SizedBox(height: 60)),

                  // 2. Categories
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Category',
                              style: TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 16)),
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildCategoryItem('All', Icons.grid_view, Colors.grey[100]!),
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

                  const SliverToBoxAdapter(child: SizedBox(height: 24)),

                  // 3. Special Chip
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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
                  
                  const SliverToBoxAdapter(child: SizedBox(height: 16)),

                  // 4. Flash Sale
                  SliverToBoxAdapter(
                    child: Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Row(
                            children: [
                              const Text('FLASHSALE',
                                  style: TextStyle(
                                      fontWeight: FontWeight.w900,
                                      fontSize: 18,
                                      color: Color(0xFF0A3D2F))),
                              const Spacer(),
                              Row(
                                children: [
                                  _buildTimerBox('02'),
                                  const Text(' : ', style: TextStyle(fontWeight: FontWeight.bold)),
                                  _buildTimerBox('12'),
                                  const Text(' : ', style: TextStyle(fontWeight: FontWeight.bold)),
                                  _buildTimerBox('45'),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          height: 240,
                          child: ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            scrollDirection: Axis.horizontal,
                            // Use raw snapshot data here so flash sale always shows something regardless of filter
                            itemCount: (snapshot.data ?? []).length > 5 ? 5 : (snapshot.data ?? []).length,
                            itemBuilder: (context, index) {
                               if (snapshot.data == null) return const SizedBox();
                               return _buildFlashSaleCard(context, snapshot.data![index]);
                            },
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SliverToBoxAdapter(child: SizedBox(height: 24)),

                  // 5. Recommendations Header
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Rekomendasi Produk', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
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
                        padding: const EdgeInsets.all(32.0),
                        child: Center(child: Text('Tidak ada produk kategori $_selectedCategory', style: const TextStyle(color: Colors.grey))),
                      ),
                    )
                  : SliverPadding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
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

                  const SliverToBoxAdapter(child: SizedBox(height: 40)),
                ],
              );
            }
          );
        },
      ),
    );
  }

  Widget _buildVerticalDivider() {
    return Container(width: 1, height: 24, color: Colors.grey[200]);
  }

  Widget _buildWalletAction(IconData icon, String label) {
    return InkWell(
      onTap: () {}, // Action for Scan
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.grey[700], size: 24),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _buildWalletInfo(IconData icon, String value, String label) {
    return InkWell(
      onTap: () {}, // Action for Wallet buttons
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppColors.green),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              Text(label, style: TextStyle(fontSize: 11, color: Colors.grey[500])),
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
              color: isSelected ? AppColors.green : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: isSelected ? AppColors.green : Colors.grey[200]!),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.05),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Icon(icon, color: isSelected ? Colors.white : AppColors.green, size: 26),
          ),
          const SizedBox(height: 8),
          Text(
            label, 
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 11, 
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500, 
              color: isSelected ? AppColors.green : Colors.black87,
              height: 1.2
            )
          ),
        ],
      ),
    );
  }

  Widget _buildTimerBox(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFF0A3D2F),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        text, 
        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)
      ),
    );
  }

  Widget _buildFlashSaleCard(BuildContext context, Product product) {
    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ProductDetailScreen(product: product))),
      child: Container(
        width: 140,
        margin: const EdgeInsets.only(right: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.grey[200]!),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(10)),
                  child: CachedNetworkImage(
                    imageUrl: product.imageUrl ?? '',
                    height: 120,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    placeholder: (_,__) => Container(color: Colors.grey[100]),
                    errorWidget: (_,__,___) => Container(color: Colors.grey[100], child: const Icon(Icons.image)),
                  ),
                ),
                Positioned(
                  top: 8,
                  left: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text('42%', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                    decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(2)),
                    child: Text(product.categoryDisplay, style: const TextStyle(fontSize: 9, color: Colors.grey)),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    product.name, 
                    maxLines: 2, 
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, height: 1.2),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Rp${product.price.toStringAsFixed(0)}', 
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.green)
                  ),
                  Text(
                    'Rp${(product.price * 1.4).toStringAsFixed(0)}',
                    style: TextStyle(fontSize: 10, color: Colors.grey[400], decoration: TextDecoration.lineThrough)
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
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.grey[200]!),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.05),
              blurRadius: 4,
              offset: const Offset(0, 2),
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
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(10)),
                    child: CachedNetworkImage(
                      imageUrl: product.imageUrl ?? '',
                      width: double.infinity,
                      fit: BoxFit.cover,
                      placeholder: (_,__) => Container(color: Colors.grey[100]),
                      errorWidget: (_,__,___) => Container(color: Colors.grey[100], child: const Icon(Icons.image)),
                    ),
                  ),
                  const Positioned(
                    top: 8,
                    right: 8,
                    child: Icon(Icons.favorite_border, color: Colors.grey, size: 20),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(product.categoryDisplay, style: const TextStyle(fontSize: 10, color: Colors.grey)),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    product.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, height: 1.2),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.star, size: 12, color: Colors.amber),
                      const SizedBox(width: 2),
                      Text(product.rating.toString(), style: const TextStyle(fontSize: 10, color: Colors.grey)),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Rp${product.price.toStringAsFixed(0)}',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.green),
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