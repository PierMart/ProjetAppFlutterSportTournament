class Student {
  final String lastName;
  final String firstName;
  final String birthDate;
  final String gender;
  final String grade;
  final String school;
  final String city;

  Student({
    required this.lastName,
    required this.firstName,
    required this.birthDate,
    required this.gender,
    required this.grade,
    required this.school,
    required this.city,
  });

  factory Student.fromJson(Map<String, dynamic> json) {
    return Student(
      lastName: json['lastName'],
      firstName: json['firstName'],
      birthDate: json['birthDate'],
      gender: json['gender'],
      grade: json['grade'],
      school: json['school'],
      city: json['city'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'lastName': lastName,
      'firstName': firstName,
      'birthDate': birthDate,
      'gender': gender,
      'grade': grade,
      'school': school,
      'city': city,
    };
  }
}