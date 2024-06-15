import 'dart:convert';
import 'package:http/http.dart' as http;

class PostServices {
  static Map<String, String> headers = {
    'Content-Type': 'application/json',
  };

  // static const baseUrl = "http://3.37.177.133:1883";
  static const baseUrl = "http://125.179.1.43:1883";
  // static const baseUrl = "http://10.0.2.2:1883";
  static const String insertHeartrateUrl = "/api/insertHeartrate";

  static Future<bool> insertHeartrate(Map<String, String> postData) async {
    print(
        "postUserContent : URL[${baseUrl + insertHeartrateUrl}]\npassed data : $postData");

    String jsonData = jsonEncode(postData);

    try {
      return await http
          .post(
        Uri.parse(baseUrl + insertHeartrateUrl),
        headers: headers,
        body: jsonData,
      )
          .then((response) {
        if (response.statusCode == 200) {
          print("A post successfully uploaded on DB.");
          return true;
        } else {
          print(
            "An error occurred while uploading a post on DB. (statusCode is not 200)",
          );
          throw Exception();
        }
      });
    } catch (error) {
      print("error $error");
      return false;
    }
  }
}
