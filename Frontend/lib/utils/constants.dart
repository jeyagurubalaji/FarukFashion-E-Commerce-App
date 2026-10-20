class AppConstants {
  // Change this to my backend URL
  static const String baseUrl = 'https://farukfashion-express.vercel.app/api';
  // static const String baseUrl = 'http://10.0.2.2:8080/api';
  // static const String baseUrl = 'http://192.168.1.10:8080/api';

  static const String appName = 'Faruk Fashion';
  static const String tagline = 'Style That Speaks';
  static const String supportPhone = '6369456650';
  static const String supportEmail = 'jgbalajinfinity006@gmail.com';
  static const String address =
      '35, Kamarajar Street, Thenkarai, Periyakulam-625 601';

  static const String tokenKey = 'ff_access_token';
  static const String userIdKey = 'ff_user_id';
  static const String usernameKey = 'ff_username';
  static const String fullNameKey = 'ff_full_name';
  static const String googleClientId =
        '788219758793-92vdb8hopvdq38laal2agsoj9gudp0fm.apps.googleusercontent.com';
  /// Shop by Category (includes All)
  static const List<Map<String, String>> categories = [
    {'code': '', 'name': 'All', 'icon': '✨'},
    {'code': 'HANDBAGS', 'name': 'Handbags', 'icon': '👜'},
    {'code': 'TROLLEY_BAGS', 'name': 'Trolley Bags', 'icon': '🧳'},
    {'code': 'SCHOOL_BAGS', 'name': 'School Bags', 'icon': '🎒'},
    {'code': 'COLLEGE_BAGS', 'name': 'College Bags', 'icon': '🎒'},
    {'code': 'OFFICE_BAGS', 'name': 'Office Bags', 'icon': '💼'},
    {'code': 'SLING_BAGS', 'name': 'Sling Bags', 'icon': '👜'},
    {'code': 'KIDS_BAGS', 'name': 'Kids Bags', 'icon': '🦄'},
    {'code': 'TRAVELLING_BAGS', 'name': 'Travelling Kit', 'icon': '✈️'},
    {'code': 'LAPTOP_BAGS', 'name': 'Laptop Bags', 'icon': '💻'},
    {'code': 'OTHER', 'name': 'Other', 'icon': '📦'},
  ];

  static List<Map<String, String>> get productCategories =>
      categories.where((c) => (c['code'] ?? '').isNotEmpty).toList();
}