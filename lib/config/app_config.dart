class AppConfig {
  static const String baseUrl = 'https://trivially-active-bream.ngrok-free.app/api';
  // static const String baseUrl = 'https://unifound-app.vercel.app/api';

  static const String apiTimeout = '30';

  // API Endpoints
  static const String loginEndpoint = '/auth/login';
  static const String registerEndpoint = '/auth/register';
  static const String itemsEndpoint = '/items';
  static const String categoriesEndpoint = '/categories';
  static const String uploadEndpoint = '/upload';
  static const String userProfileEndpoint = '/users/profile';
  static const String userItemsEndpoint = '/users/items';
}
