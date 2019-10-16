class Secret {
  final String apiKey;
  final String spotifyClientId;
  final String spotifyClientSecret;
  Secret({
    this.apiKey = "",
    this.spotifyClientId = "",
    this.spotifyClientSecret = "",
  });
  factory Secret.fromJson(Map<String, dynamic> jsonMap) {
    return new Secret(
      apiKey: jsonMap["apiKey"],
      spotifyClientId: jsonMap["spotifyClientId"],
      spotifyClientSecret: jsonMap["spotifyClientSecret"],
    );
  }
}
