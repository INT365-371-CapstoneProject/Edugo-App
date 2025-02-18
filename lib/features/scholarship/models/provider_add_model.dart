class Announce {
  final int? id;
  final String title;
  final String description;
  final String? url;
  final String? countryId;
  final String? categoryId;
  final DateTime? publishDate;
  final DateTime? closeDate;
  final String? image;
  final String? attachFile;
  final String? posts_type;

  Announce({
    this.id,
    required this.title,
    required this.description,
    this.url,
    this.countryId,
    this.categoryId,
    this.publishDate,
    this.closeDate,
    this.image,
    this.attachFile,
    this.posts_type,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'url': url,
      'country_id': countryId,
      'category_id': categoryId,
      'publish_date': '${publishDate?.toIso8601String().split('.')[0]}Z',
      'close_date': '${closeDate?.toIso8601String().split('.')[0]}Z',
      'image': image,
      'attach_file': attachFile,
      'posts_type': "Announce",
    };
  }
}
