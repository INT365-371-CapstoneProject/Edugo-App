class Endpoints {
  // static const String baseUrl = 'http://127.0.0.1:8080/api';
  static const String baseUrl = 'https://capstone24.sit.kmutt.ac.th/un2/api';

  // Login
  static const String login = '$baseUrl/login';

  // Forget Password
  static const String forgotPassword = '$baseUrl/auth/forgot-password';

  // Verify OTP
  static const String otpVerification = '$baseUrl/auth/verify-otp';

  // Firebase Cloud Messaging
  static const String fcm = '$baseUrl/fcm';

  // GetBookmark
  static const String bookmark = '$baseUrl/bookmark';

  // GetBookmarkByAccountID
  static const String getBookmarkByAccountID = '$baseUrl/bookmark/acc/';

  // GetProfile
  static const String profile = '$baseUrl/profile';

  // GetProfileAvatar
  static const String getProfileAvatar = '$baseUrl/profile/avatar';

  // GetNotificationWithAccountID
  static const String getNotificationWithAccountID =
      '$baseUrl/notification/acc';

  // Subject
  static const String subject = '$baseUrl/subject';

  // Comment
  static const String comment = '$baseUrl/comment';

  // Announce User
  static const String announceUser = '$baseUrl/announce-user';

  // Answer
  static const String answer = '$baseUrl/answer';

  // Get Scholar Image
  static const String getScholarshipImage = '$baseUrl/public/images/';

  // Scholarship
  static const String getScholarship = '$baseUrl/announce-user';

  // Announce
  static const String announce = '$baseUrl/announce';

  // Country
  static const String country = '$baseUrl/country';

  // Category
  static const String category = '$baseUrl/category';

  // Search
  static const String searchAnnounceUser = '$baseUrl/search/announce-user';
}
