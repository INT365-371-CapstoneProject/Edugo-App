class ApiEndpoints {
  // static const String baseUrl = "https://capstone24.sit.kmutt.ac.th/un2/api";
  static const String baseUrl = "http://192.168.1.35:8080/api";
  static const String fetchCountries = "$baseUrl/country";
  static const String fetchCategories = "$baseUrl/category";
  static const String addAnnounce = "$baseUrl/announce/add";
  static String updateAnnounce(String id) => "$baseUrl/announce/update/$id";
}
