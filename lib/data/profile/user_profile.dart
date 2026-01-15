class UserProfile {
  final String id;
  final String email;
  final String role;
  final String? pairId;

  UserProfile({
    required this.id,
    required this.email,
    required this.role,
    this.pairId,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'],
      email: json['email'],
      role: json['role'],
      pairId: json['pair_id'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'role': role,
      'pair_id': pairId,
    };
  }

  UserProfile copyWith({
    String? id,
    String? email,
    String? role,
    String? pairId,
  }) {
    return UserProfile(
      id: id ?? this.id,
      email: email ?? this.email,
      role: role ?? this.role,
      pairId: pairId ?? this.pairId,
    );
  }
}