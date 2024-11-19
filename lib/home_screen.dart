import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart'; // Importar url_launcher
import 'chat_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({Key? key}) : super(key: key);

  // Función para abrir el enlace del repositorio en el navegador
  Future<void> _launchUrl(String url) async {
    final Uri uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      throw Exception('No se pudo abrir la URL: $url');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chatbot App'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Bienvenido a la App de la Universidad',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            const Text('Carrera: Ingenieria en software'),
            const Text('Materia: Mobiles 2'),
            const Text('Matrícula: 221225'),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const ChatScreen()),
                );
              },
              child: const Text('Ir al Chat'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                _launchUrl('https://github.com/Jesus-137/chat_voz.git');
              }, // Llama a la función para abrir el enlace
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueAccent,
              ),
              child: const Text('Visitar Repositorio GitHub'),
            ),
          ],
        ),
      ),
    );
  }
}
