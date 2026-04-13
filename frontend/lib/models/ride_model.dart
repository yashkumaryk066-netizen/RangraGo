class RideRequest {
  final String id;
  final String pickup;
  final String drop;
  final String userId;
  final double? fare;

  RideRequest({
    required this.id, 
    required this.pickup, 
    required this.drop, 
    required this.userId, 
    this.fare
  });

  factory RideRequest.fromJson(Map<String, dynamic> json) {
    return RideRequest(
      id: json['_id'],
      pickup: json['pickup'],
      drop: json['drop'],
      userId: json['userId'],
      fare: json['fare']?.toDouble(),
    );
  }
}
