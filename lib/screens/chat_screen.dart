import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class ChatPage extends StatefulWidget {
  @override
  _ChatPageState createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final TextEditingController _textController = TextEditingController();
  final List<Map<String, dynamic>> _messages = [];

  Future<void> _sendMessage() async {
    if (_textController.text.isNotEmpty) {
      // Add user message to the list
      setState(() {
        _messages.add({
          'sender': 'user',
          'text': _textController.text,
        });
      });

      // Send message to backend
      var response = await http.post(
        Uri.parse('https://capstonebackend-5am6.onrender.com/'), // Replace with your actual backend endpoint
        body: jsonEncode({'message': _textController.text}),
        headers: {"Content-Type": "application/json"},
      );

      if (response.statusCode == 200) {
        // Decode the response
        var decodedResponse = jsonDecode(response.body) as Map<String, dynamic>;

        // Add AI message to the list
        setState(() {
          _messages.add({
            'sender': 'ai',
            'text': decodedResponse['response'],
          });
        });
      } else {
        // Handle error
        print('Error sending message: ${response.statusCode}');
        // You can show a snackbar or alert here
      }

      // Clear the text field
      _textController.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Chat"),
      ),
      body: Column(
        children: <Widget>[
          Expanded(
            child: ListView.builder(
              reverse: true, // To display the latest messages at the bottom
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final message = _messages[index];
                return ListTile(
                  title: Text(message['text']),
                  subtitle: Text(message['sender']),
                  leading: message['sender'] == 'user'
                      ? Icon(Icons.person)
                      : Icon(Icons.computer),
                );
              },
            ),
          ),
          Divider(height: 1.0),
          Container(
            decoration: BoxDecoration(color: Theme.of(context).cardColor),
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                children: <Widget>[
                  Expanded(
                    child: TextField(
                      controller: _textController,
                      onSubmitted: (value) => _sendMessage(),
                      decoration: InputDecoration.collapsed(
                        hintText: "Enter your message",
                      ),
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.send),
                    onPressed: _sendMessage,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}