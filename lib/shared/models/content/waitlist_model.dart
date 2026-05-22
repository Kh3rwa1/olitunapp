// ============== WAITLIST MODEL ==============
class WaitlistModel {
  final String id;
  final String? userId;
  final String fullName;
  final String phoneNumber;
  final String
  ceremonyType; // 'karam', 'sohrai', 'baha', 'funeral', 'wedding', 'naming', 'other'
  final String? eventDate;
  final String city;
  final String state;
  final String? notes;
  final String submittedAt;
  final String? contactedAt;
  final String status; // 'new', 'contacted', 'converted', 'closed'

  WaitlistModel({
    required this.id,
    this.userId,
    required this.fullName,
    required this.phoneNumber,
    required this.ceremonyType,
    this.eventDate,
    required this.city,
    required this.state,
    this.notes,
    required this.submittedAt,
    this.contactedAt,
    required this.status,
  });

  factory WaitlistModel.fromJson(Map<String, dynamic> data, [String? docId]) {
    return WaitlistModel(
      id: docId ?? data['\$id'] as String? ?? data['id'] as String? ?? '',
      userId: data['userId'] as String?,
      fullName: data['fullName'] as String? ?? '',
      phoneNumber: data['phoneNumber'] as String? ?? '',
      ceremonyType: data['ceremonyType'] as String? ?? 'other',
      eventDate: data['eventDate'] as String?,
      city: data['city'] as String? ?? '',
      state: data['state'] as String? ?? '',
      notes: data['notes'] as String?,
      submittedAt: data['submittedAt'] as String? ?? '',
      contactedAt: data['contactedAt'] as String?,
      status: data['status'] as String? ?? 'new',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'fullName': fullName,
      'phoneNumber': phoneNumber,
      'ceremonyType': ceremonyType,
      'eventDate': eventDate,
      'city': city,
      'state': state,
      'notes': notes,
      'submittedAt': submittedAt,
      'contactedAt': contactedAt,
      'status': status,
    };
  }

  WaitlistModel copyWith({
    String? id,
    String? userId,
    String? fullName,
    String? phoneNumber,
    String? ceremonyType,
    String? eventDate,
    String? city,
    String? state,
    String? notes,
    String? submittedAt,
    String? contactedAt,
    String? status,
  }) {
    return WaitlistModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      fullName: fullName ?? this.fullName,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      ceremonyType: ceremonyType ?? this.ceremonyType,
      eventDate: eventDate ?? this.eventDate,
      city: city ?? this.city,
      state: state ?? this.state,
      notes: notes ?? this.notes,
      submittedAt: submittedAt ?? this.submittedAt,
      contactedAt: contactedAt ?? this.contactedAt,
      status: status ?? this.status,
    );
  }
}
