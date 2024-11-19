import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:flutter_tts/flutter_tts.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({Key? key}) : super(key: key);

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final List<Map<String, String>> messages = [];
  final TextEditingController _controller = TextEditingController();
  bool isLoading = false;

  // Speech-to-text and Text-to-speech instances
  late stt.SpeechToText _speech;
  late FlutterTts _flutterTts;
  bool isListening = false;

  @override
  void initState() {
    super.initState();
    _speech = stt.SpeechToText();
    _flutterTts = FlutterTts();

    // Cargar los mensajes guardados
    _loadMessages();

    // Configura el TTS
    _flutterTts.setLanguage("es-ES");
    _flutterTts.setSpeechRate(0.5);
    _flutterTts.setPitch(1.0);
  }

  // Cargar los mensajes desde SharedPreferences
  Future<void> _loadMessages() async {
    final prefs = await SharedPreferences.getInstance();
    final String? savedMessages = prefs.getString('messages');
    if (savedMessages != null) {
      final List<dynamic> decodedMessages = jsonDecode(savedMessages);
      setState(() {
        messages.addAll(decodedMessages.map((message) => Map<String, String>.from(message)));
      });
    }
  }

  // Guardar los mensajes en SharedPreferences
  Future<void> _saveMessages() async {
    final prefs = await SharedPreferences.getInstance();
    final String encodedMessages = jsonEncode(messages);
    prefs.setString('messages', encodedMessages);
  }

  @override
  void dispose() {
    _speech.stop();
    _flutterTts.stop();
    super.dispose();
  }

  Future<String> sendMessageToBot(String userMessage) async {
    const String apiUrl =
        'https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash-latest:generateContent?key=AIzaSyAQ8hJOCIOMrJJpl8fqzgMGvceVcswGke4';

    try {
      // Toma los últimos 5 mensajes del historial o menos
      final List<Map<String, String>> recentMessages =
          messages.length <= 5 ? messages : messages.sublist(messages.length - 5);

      // Mensaje inicial para indicar que todas las respuestas deben estar en inglés
      String instruction = "Always respond in English, regardless of the input language.";

      // Combina los mensajes recientes en el formato requerido
      String combinedMessages = recentMessages
          .map((message) =>
              message.containsKey('user') ? "You: ${message['user']}" : "Bot: ${message['bot']}")
          .join('\n');

      // Agrega el mensaje actual del usuario
      combinedMessages = "$instruction\n\n$combinedMessages\nYou: $userMessage";

      // Enviar solicitud a Gemini
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          "contents": [
            {
              "parts": [
                {"text": combinedMessages}
              ]
            }
          ]
        }),
      );

      print('Response Body: ${response.body}'); // Debugging

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        // Accede a la respuesta de la IA
        String reply = data['candidates'][0]['content']['parts'][0]['text'];
        return reply;
      } else {
        throw Exception('Error al conectar con Gemini: ${response.statusCode}');
      }
    } catch (e) {
      print('Error: $e');
      return 'Error: Unable to get a response from the bot.';
    }
  }

  void handleSendMessage(String input) async {
    if (input.isEmpty) return;

    setState(() {
      messages.add({'user': input});
      isLoading = true;
    });

    String botResponse;
    try {
      botResponse = await sendMessageToBot(input);
    } catch (e) {
      botResponse = 'Error al conectarse con el bot.';
    }

    setState(() {
      messages.add({'bot': botResponse});
      isLoading = false;
    });

    // Guardar los mensajes actualizados
    _saveMessages();

    // Leer la respuesta en voz alta
    await _flutterTts.speak(botResponse);

    _controller.clear();
  }

  void startListening() async {
    bool available = await _speech.initialize(
      onStatus: (status) => print('Status: $status'),
      onError: (error) => print('Error: $error'),
    );

    if (available) {
      setState(() => isListening = true);
      _speech.listen(
        onResult: (result) {
          setState(() {
            _controller.text = result.recognizedWords;
          });
        },
      );
    }
  }

  void stopListening() {
    _speech.stop();
    setState(() => isListening = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chat con el Bot'),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: messages.length,
              itemBuilder: (context, index) {
                final message = messages[index];
                final isUser = message.containsKey('user');
                return Align(
                  alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 5, horizontal: 10),
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: isUser ? Colors.blue[100] : Colors.grey[300],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(isUser ? message['user']! : message['bot']!),
                  ),
                );
              },
            ),
          ),
          if (isLoading) const CircularProgressIndicator(),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                IconButton(
                  icon: Icon(isListening ? Icons.mic_off : Icons.mic),
                  onPressed: isListening ? stopListening : startListening,
                ),
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: const InputDecoration(
                      hintText: 'Escribe o usa el micrófono...',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: () => handleSendMessage(_controller.text),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
