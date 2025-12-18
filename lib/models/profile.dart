/// Model profil pengguna.
/// Mapping ke tabel `profiles` di Supabase.
class ProfileModel {
  final String id; // uuid, foreign key to auth.users
  final String email;
  final String? fullName;
  final String? phone;
  final String? address;
  final String? avatarUrl;
  final String role; // 'user' | 'admin'
  final DateTime createdAt;

  const ProfileModel({
    required this.id,
    required this.email,
    required this.role,
    required this.createdAt,
    this.fullName,
    this.phone,
    this.address,
    this.avatarUrl,
  });

  factory ProfileModel.fromMap(Map<String, dynamic> map) {
    return ProfileModel(
      id: map['id'] as String,
      email: map['email'] as String,
      fullName: map['full_name'] as String?,
      phone: map['phone'] as String?,
      address: map['address'] as String?,
      avatarUrl: map['avatar_url'] as String?,
      role: map['role'] as String? ?? 'user',
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'email': email,
      'full_name': fullName,
      'phone': phone,
      'address': address,
      'avatar_url': avatarUrl,
      'role': role,
      'created_at': createdAt.toIso8601String(),
    };
  }

  ProfileModel copyWith({
    String? fullName,
    String? phone,
    String? address,
    String? avatarUrl,
  }) {
    return ProfileModel(
      id: id,
      email: email,
      role: role,
      createdAt: createdAt,
      fullName: fullName ?? this.fullName,
      phone: phone ?? this.phone,
      address: address ?? this.address,
      avatarUrl: avatarUrl ?? this.avatarUrl,
    );
  }
}
