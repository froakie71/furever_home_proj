class Dog {
  final String id;
  final String name;
  final String breed;
  final String description;
  final String gender;
  final String imageUrl;
  final String size;
  final Map<String, bool> medicalRecords;

  Dog({
    required this.id,
    required this.name,
    required this.breed,
    required this.description,
    required this.gender,
    required this.imageUrl,
    required this.size,
    required this.medicalRecords,
  });

  factory Dog.fromFirestore(Map<String, dynamic> data, String id) {
    return Dog(
      id: id,
      name: data['name'] ?? '',
      breed: data['breed'] ?? '',
      description: data['description'] ?? '',
      gender: data['gender'] ?? '',
      imageUrl: data['imageUrl'] ?? '',
      size: data['size'] ?? 'Medium',
      medicalRecords: Map<String, bool>.from(data['medicalRecords'] ?? {
        'Dewormed': false,
        'Spayed/Neutered': false,
        'Vaccinated': false,
      }),
    );
  }
}