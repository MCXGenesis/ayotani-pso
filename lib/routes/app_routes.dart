import 'package:flutter/widgets.dart';
import '../pages/auth/login_page.dart';
import '../pages/auth/onboarding_page.dart';
import '../pages/auth/signup_page.dart';
import '../pages/auth/splash_screen.dart';
import '../pages/home/home_screen.dart';
import '../pages/marketplace/cart.dart';
import '../pages/marketplace/checkout.dart';
import '../pages/marketplace/marketplace_screen.dart';
import '../pages/marketplace/payment.dart';
import '../pages/marketplace/payment_done.dart';
import '../pages/marketplace/payment_method.dart';
import '../pages/education/educational_list_screen.dart';
import '../pages/education/educational_detail_screen.dart';
import '../pages/profile/profile_page.dart';
import '../pages/profile/edit_profile_screen.dart';
import '../pages/profile/change_password_screen.dart';
import '../pages/profile/notification_screen.dart';
import '../pages/profile/terms_screen.dart';
import '../pages/monitoring/monitoring_screen.dart';
import '../pages/monitoring/land_list_screen.dart';
import '../pages/monitoring/add_land_screen.dart';
import '../pages/news/news_article_detail_page.dart';
import '../pages/news/comments_page.dart';
import '../models/comment_model.dart';
import '../pages/news/article_list_screen.dart';
import '../pages/profile/customer_service_screen.dart';
import '../pages/weather/weather_screen.dart';

class AppRoutes {
  static const splash = '/splash';
  static const login = '/login';
  static const signup = '/signup';
  static const onboarding = '/onboarding';
  static const home = '/home';
  static const marketplace = '/marketplace';
  static const cart = '/cart';
  static const checkout = '/checkout';
  static const paymentMethod = '/payment-method';
  static const payment = '/payment';
  static const paymentDone = '/payment-done';
  static const educational = '/educational';
  static const educationalDetail = '/educational-detail';
  static const profile = '/profile';
  static const editProfile = '/edit-profile';
  static const changePassword = '/change-password';
  static const notifications = '/notifications';
  static const terms = '/terms';
  static const customerService = '/customer-service';
  
  static const newsArticle = '/news-article';
  static const articleList = '/article-list';
  static const comments = '/comments';
  
  static const monitoring = '/monitoring';
  static const landList = '/land-list';
  static const addLand = '/add-land';
  static const weather = '/weather';

  static Map<String, WidgetBuilder> get routes => {
        splash: (_) => SplashScreen(),
        login: (_) => LoginPage(),
        signup: (_) => SignupPage(),
        onboarding: (context) {
          final userId = ModalRoute.of(context)?.settings.arguments as String?;
          return OnboardingPage(userId: userId ?? '');
        },
        home: (_) => HomeScreen(),
        profile: (_) => ProfilePage(),
        marketplace: (_) => MarketplaceScreen(),
        cart: (_) => ShoppingCartScreen(),
        checkout: (_) => CheckoutScreen(),
        paymentMethod: (_) => PaymentMethodScreen(),
        payment: (context) {
          final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
          return PaymentScreen(
            totalAmount: args?['totalAmount'] as double? ?? 0.0,
            paymentMethod: args?['paymentMethod'] as String? ?? 'Unknown',
          );
        },
        paymentDone: (_) => PaymentDoneScreen(),
        educational: (_) => EducationalListScreen(),
        educationalDetail: (context) {
          final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
          final id = args?['id'] as int? ?? 0;
          return EducationalDetailScreen(contentId: id);
        },
        editProfile: (_) => EditProfileScreen(),
        changePassword: (_) => ChangePasswordScreen(),
        notifications: (_) => NotificationScreen(),
        terms: (_) => TermsScreen(),
        customerService: (_) => CustomerServiceScreen(),
        
        // Updated News Article Route to accept ID
        newsArticle: (context) {
          final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
          final articleId = args?['articleId'] as int?;
          return NewsArticleDetailPage(articleId: articleId);
        },
        
        // NEW Article List Route
        articleList: (_) => ArticleListScreen(),

        comments: (context) {
          final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
          return CommentsPage(
            comments: args?['comments'] as List<Comment>? ?? [],
            commentCount: args?['commentCount'] as int? ?? 0,
          );
        },
        
        landList: (_) => LandListScreen(),
        weather: (context) {
          final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
          return WeatherScreen(
            initialLat: args?['lat'] as double?,
            initialLon: args?['lon'] as double?,
          );
        },
        addLand: (_) => AddLandScreen(),
        monitoring: (context) {
          final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
          final initialLandId = args?['landId'] as int?;
          return MonitoringScreen(initialLandId: initialLandId);
        },
      };
}