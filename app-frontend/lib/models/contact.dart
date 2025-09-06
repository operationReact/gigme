class ContactLinkDto {
  final int id;
  final int userId;
  final String label; // e.g. "Website", "LinkedIn"
  final String url;
  final String? kind; // optional semantic tag
  final int order;    // default 0

  ContactLinkDto({
    required this.id,
    required this.userId,
    required this.label,
    required this.url,
    this.kind,
    this.order = 0,
  });

  factory ContactLinkDto.fromJson(Map<String, dynamic> j) => ContactLinkDto(
    id: j['id'],
    userId: j['userId'],
    label: j['label'] ?? '',
    url: j['url'] ?? '',
    kind: j['kind'],
    order: (j['order'] ?? 0) as int,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'userId': userId,
    'label': label,
    'url': url,
    'kind': kind,
    'order': order,
  };
}
