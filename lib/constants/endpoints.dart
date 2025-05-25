
class AppApi {
  static const String apiBaseUrl = 'https://0291-2600-4040-b5e5-f300-a881-2bd0-6293-7d02.ngrok-free.app';

  // User profile
  static final Uri login = Uri.parse('$apiBaseUrl/api/user/login/');
  static final Uri register = Uri.parse('$apiBaseUrl/api/user/register/');
  static final Uri profile = Uri.parse('$apiBaseUrl/api/user/profile/');
  static final Uri profileUpdate = Uri.parse('$apiBaseUrl/api/user/profile/update/');
  static final Uri changePassword = Uri.parse('$apiBaseUrl/api/user/change-password/');

  // Reset Password
  static final Uri resetPasswordSendCode = Uri.parse('$apiBaseUrl/api/user/reset-password/send-code/');
  static final Uri resetPasswordVerifyCode = Uri.parse('$apiBaseUrl/api/user/reset-password/verify-code/');
  static final Uri resetPasswordConfirm = Uri.parse('$apiBaseUrl/api/user/reset-password/confirm/');

  // User WheelChair
  // This endpoint is used to update the wheelchair status of the user.
  // It is a POST request that requires the user to be authenticated.
  //'$apiBaseUrl/api/user/wheelchair/' - GET for list of Wheelchair
  //'$apiBaseUrl/api/user/wheelchair/' - POST for add of Wheelchair
  //'$apiBaseUrl/api/user/wheelchair/47' - PUT/PATCH for update Wheelchair
  //'$apiBaseUrl/api/user/wheelchair/47' - DELETE for delete Wheelchair
  static final Uri userWheelChair = Uri.parse('$apiBaseUrl/api/user/wheelchair/');

  // For Token
  static final Uri tokenRefresh = Uri.parse('$apiBaseUrl/api/user/tokenRefresh/');
  static final Uri refresh = Uri.parse('$apiBaseUrl/api/user/token/refresh/');


  // WheelChair API
  // Get list of Wheelchair types
  static final Uri wheelChairType = Uri.parse('$apiBaseUrl/api/wheelchair/types/');
  // Get list of Wheelchair Drive Type
  static final Uri wheelChairDriveType = Uri.parse('$apiBaseUrl/api/wheelchair/drive-types/');
  // Get list of Wheelchair Tire Materials
  static final Uri wheelChairTireMaterial = Uri.parse('$apiBaseUrl/api/wheelchair/tire-materials/');


  // Navigation (NEW)
  static final Uri routeSearch = Uri.parse('$apiBaseUrl/api/navigation/route/');

  // Transit Routes
  static final Uri transitCreate = Uri.parse('$apiBaseUrl/api/navigation/transits/create/');
  static final Uri transitCancel = Uri.parse('$apiBaseUrl/api/navigation/transits/cancel/');
  static final Uri transitComplete = Uri.parse('$apiBaseUrl/api/navigation/transits/complete/');

  // Marker Routes
  static final Uri markerCreate = Uri.parse('$apiBaseUrl/api/navigation/markers/create/');
  static final Uri markerSearch = Uri.parse('$apiBaseUrl/api/navigation/markers/search/');
  static final Uri markerUpdate = Uri.parse('$apiBaseUrl/api/navigation/markers/update/');

}
