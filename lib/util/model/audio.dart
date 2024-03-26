class Audio {

  final String url;
  final String startTime;
  final String endTime;

  Audio({required this.url, required this.startTime, required this.endTime});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Audio && runtimeType == other.runtimeType && url == other.url && startTime == other.startTime && endTime == other.endTime;


  @override
  int get hashCode => url.hashCode ^ startTime.hashCode ^ endTime.hashCode;
}