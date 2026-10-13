class ContactMessage {
  final String name;
  final String email;
  final String subject;
  final String message;
  final String phone;
  final DateTime? sentAt;

  const ContactMessage({
    required this.name,
    required this.email,
    required this.subject,
    required this.message,
    this.phone = '',
    this.sentAt,
  });

  static final RegExp emailRegex = RegExp(r'^[\w.+-]+@[\w-]+\.[\w.]{2,}$');

  static const int maxNameLength = 100;
  static const int maxSubjectLength = 150;
  static const int maxMessageLength = 2000;

  bool get isValid =>
      name.trim().isNotEmpty &&
      name.trim().length <= maxNameLength &&
      email.trim().isNotEmpty &&
      emailRegex.hasMatch(email.trim()) &&
      subject.trim().isNotEmpty &&
      subject.trim().length <= maxSubjectLength &&
      message.trim().isNotEmpty &&
      message.trim().length <= maxMessageLength;

  Map<String, dynamic> toMap() => {
        'name': name.trim(),
        'email': email.trim(),
        'subject': subject.trim(),
        'message': message.trim(),
        'phone': phone.trim(),
        if (sentAt != null) 'created_at': sentAt!.toIso8601String(),
      };

  factory ContactMessage.fromMap(Map<String, dynamic> d) => ContactMessage(
        name: d['name'] as String? ?? '',
        email: d['email'] as String? ?? '',
        subject: d['subject'] as String? ?? '',
        message: d['message'] as String? ?? '',
        phone: d['phone'] as String? ?? '',
        sentAt: d['created_at'] != null
            ? DateTime.tryParse(d['created_at'] as String)
            : (d['sent_at'] != null
                ? DateTime.tryParse(d['sent_at'] as String)
                : null),
      );
}