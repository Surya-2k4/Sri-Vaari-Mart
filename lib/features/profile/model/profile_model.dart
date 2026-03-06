class ProfileModel {
  final String id;
  final String email;
  final String? fullName;
  final String? address;
  final String? phone;
  final String theme;

  ProfileModel({
    required this.id,
    required this.email,
    this.fullName,
    this.address,
    this.phone,
    required this.theme,
  });

  factory ProfileModel.fromMap(Map<String, dynamic> data) {
    return ProfileModel(
      id: data['id'],
      email: data['email'],
      fullName: data['full_name'],
      address: data['address'],
      phone: data['phone']?.toString(),
      theme: data['theme'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'full_name': fullName,
      'address': address,
      'phone': phone,
      'theme': theme,
    };
  }
}
