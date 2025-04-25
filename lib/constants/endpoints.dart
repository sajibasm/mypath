import 'constants.dart';

class AppEndpoints {
  static const String apiBaseUrl = 'https://4e73-2600-4040-b5e5-f300-9538-888-c2dc-a32f.ngrok-free.app/api';

  // For user profile
  static final Uri login = Uri.parse('${apiBaseUrl}/user/login/');
  static final Uri register = Uri.parse('${apiBaseUrl}/user/register/');
  static final Uri refresh = Uri.parse('${apiBaseUrl}/user/refresh/');
  static final Uri profile = Uri.parse('${apiBaseUrl}/user/profile/');



}
