class ApiConfig {
  static const String baseUrl = "https://capstone24.sit.kmutt.ac.th/un2";
  static const String apiUrl = "$baseUrl/api";

  // Auth endpoints
  static const String loginUrl = "$apiUrl/login";
  static const String logoutUrl = "$apiUrl/logout";
  static const String profileUrl = "$apiUrl/profile";
  static const String profileAvatarUrl = "$profileUrl/avatar";
  static const String forgotPasswordUrl = "$apiUrl/auth/forgot-password";
  static const String resetPasswordUrl = "$apiUrl/auth/reset-password";
  static const String verifyOtpUrl = "$apiUrl/auth/verify-otp";

  // Announce & Scholarship endpoints
  static const String announceUrl = "$apiUrl/announce";
  static const String announceUserUrl = "$apiUrl/announce-user";
  static String getAnnounceImageUrl(String id) => "$apiUrl/announce/$id/image";
  static String getAnnounceUserImageUrl(String id) =>
      "$apiUrl/announce-user/$id/image";
  static String getAnnounceAdminImageUrl(String id) =>
      "$apiUrl/announce-admin/$id/image";

  // Search endpoints
  static const String searchAnnounceUrl = "$apiUrl/search/announce-user";
  static const String searchAnnounceProviderUrl =
      "$apiUrl/search/announce-provider";

  // Filter endpoints
  static const String categoryUrl = "$apiUrl/category";
  static const String countryUrl = "$apiUrl/country";

  // Bookmark endpoints
  static const String bookmarkUrl = "$apiUrl/bookmark";
  static const String bookmarkUser = "$announceUserUrl/bookmark";

  // Subject endpoints
  static const String subjectUrl = "$apiUrl/subject";

  // Notification endpoints
  static const String notificationUrl = "$apiUrl/notification";

  // Profile endpoints
  static const String profileUpdateUrl = "$apiUrl/profile/update";
  static const String profileImageUrl = "$apiUrl/profile/image";
  static const String profileChangePasswordUrl =
      "$apiUrl/profile/change-password"; // This line exists

  // Question/Answer endpoints
  static const String answerUrl = "$apiUrl/answer";

  // FCM endpoints
  static const String fcmUrl = "$apiUrl/fcm";

  //comment endpoints
  static const String commentUrl = "$apiUrl/comment";

  static const String userUrl = "$apiUrl/user";

  static const String providerUrl = "$apiUrl/provider";

  static const String providerAvatarUrl = "$apiUrl/provider/avatar";
}
