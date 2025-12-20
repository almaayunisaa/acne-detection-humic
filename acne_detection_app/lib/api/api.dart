import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:path/path.dart';
import '../models/report.dart'; 

class AcneApi {
  final String _baseUrl = 'http://192.168.1.13:5000/predict'; 

  Future<Report?> detectAcne(File imageFile) async {
    try {
      var request = http.MultipartRequest('POST', Uri.parse(_baseUrl));
      
      var stream = http.ByteStream(imageFile.openRead());
      var length = await imageFile.length();
      
      var multipartFile = http.MultipartFile(
        'image',
        stream,
        length,
        filename: basename(imageFile.path)
      );

      request.files.add(multipartFile);

      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        var jsonResponse = json.decode(response.body);
        if (jsonResponse['status'] == 'success') {
          return Report.fromJson(jsonResponse);
        } else {
          print('API Error: ${jsonResponse['error']}');
          return null;
        }

      } else {
        print('API Error (Status Code ${response.statusCode}): ${response.body}');
        return null;
      }
    } catch (e) {
      print('Koneksi atau Pemrosesan Error: $e');
      return null;
    }
  }
}