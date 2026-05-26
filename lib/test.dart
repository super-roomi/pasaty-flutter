import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';

Future<http.Response> fetchAlbum() {
  return http.get(Uri.parse('http://127.0.0.1:3000/test'));
}


class Test extends StatelessWidget {
  const Test({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(child: ElevatedButton(onPressed: fetchAlbum, child: Text("Test")));
  }
}



