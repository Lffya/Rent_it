import 'package:flutter/material.dart';
import '../screens/auth/login_page.dart';
import '../screens/auth/signup_page.dart';
import '../screens/auth/auth_wrapper.dart';
import '../navigation/main_navigation.dart';
import '../screens/home/home_page.dart';
import '../screens/categories/categories_page.dart';
import '../screens/categories/catalogue_page.dart';
import '../screens/listings/my_listings_page.dart';
import '../screens/listings/add_item_page.dart';
import '../screens/cart/cart_page.dart';
import '../screens/profile/profile_page.dart';
import '../screens/search/search_page.dart';

class AppRoutes {
  // Route names as constants
  static const String authWrapper = '/';
  static const String login = '/login';
  static const String signup = '/signup';
  static const String mainNavigation = '/main';
  static const String home = '/home';
  static const String categories = '/categories';
  static const String catalogue = '/catalogue';
  static const String myListings = '/my-listings';
  static const String addItem = '/add-item';
  static const String cart = '/cart';
  static const String profile = '/profile';
  static const String search = '/search';

  // Named routes map
  static Map<String, WidgetBuilder> routes = {
    authWrapper: (context) => const AuthWrapper(),
    login: (context) => const LoginPage(),
    signup: (context) => const SignupPage(),
    mainNavigation: (context) => const MainNavigationPage(),
    home: (context) => const HomePage(),
    categories: (context) => const CategoriesPage(),
    myListings: (context) => const MyListingsPage(),
    addItem: (context) => const AddItemPage(),
    cart: (context) => const CartPage(),
    profile: (context) => const ProfilePage(),
    search: (context) => const SearchPage(),
  };

  // Handle routes with arguments
  static Route<dynamic>? onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case catalogue:
        final args = settings.arguments as Map<String, dynamic>?;
        return MaterialPageRoute(
          builder: (context) => CataloguePage(
            category: args?['category'] ?? 'All',
          ),
        );
      default:
        return null;
    }
  }

  // Helper methods for navigation
  static void navigateToLogin(BuildContext context) {
    Navigator.pushReplacementNamed(context, login);
  }

  static void navigateToSignup(BuildContext context) {
    Navigator.pushNamed(context, signup);
  }

  static void navigateToMain(BuildContext context) {
    Navigator.pushReplacementNamed(context, mainNavigation);
  }

  static void navigateToAddItem(BuildContext context) {
    Navigator.pushNamed(context, addItem);
  }

  static void navigateToSearch(BuildContext context) {
    Navigator.pushNamed(context, search);
  }

  static void navigateToCatalogue(BuildContext context, String category) {
    Navigator.pushNamed(
      context,
      catalogue,
      arguments: {'category': category},
    );
  }

  static void navigateToMyListings(BuildContext context) {
    Navigator.pushNamed(context, myListings);
  }
}