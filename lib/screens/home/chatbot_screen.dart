// File: chatbot_screen.dart
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';

class ChatbotScreen extends StatefulWidget {
  const ChatbotScreen({Key? key}) : super(key: key);

  @override
  State<ChatbotScreen> createState() => _ChatbotScreenState();
}

class _ChatbotScreenState extends State<ChatbotScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<ChatMessage> _messages = [];
  bool _isLoading = false;

  // Replace with your actual Gemini API key
  static const String GEMINI_API_KEY = 'AIzaSyDCs1J4Ew3S-NXgOkWvzMZ7-f3MbWi0D7U';
  static const String GEMINI_API_URL =
      'https://generativelanguage.googleapis.com/v1/models/gemini-2.5-flash:generateContent';
  @override
  void initState() {
    super.initState();
    // Add welcome message
    _messages.add(ChatMessage(
      text: "Hello! I'm your rental assistant. I can help you with questions about properties, bookings, payments, and more. How can I assist you today?",
      isUser: false,
      timestamp: DateTime.now(),
    ));
  }

  Future<void> _sendMessage(String message) async {
    if (message.trim().isEmpty) return;

    setState(() {
      _messages.add(ChatMessage(
        text: message,
        isUser: true,
        timestamp: DateTime.now(),
      ));
      _isLoading = true;
    });

    _messageController.clear();
    _scrollToBottom();

    try {
      final response = await _getGeminiResponse(message);
      setState(() {
        _messages.add(ChatMessage(
          text: response,
          isUser: false,
          timestamp: DateTime.now(),
        ));
        _isLoading = false;
      });
    } catch (e) {
      print('💥 Error in _sendMessage: $e');
      setState(() {
        _messages.add(ChatMessage(
          text: "Sorry, I encountered an error: ${e.toString()}\n\nPlease check your API key and internet connection.",
          isUser: false,
          timestamp: DateTime.now(),
        ));
        _isLoading = false;
      });
    }

    _scrollToBottom();
  }

  Future<String> _getGeminiResponse(String userMessage) async {
    final systemPrompt = """You are a helpful assistant for a rental app that specializes in renting three categories of items:
1. Gym Equipment
2. Musical Instruments
3. Hardware Tools

IMPORTANT: You should ONLY answer questions related to this rental app and its features. If a user asks about anything unrelated to this app (like general knowledge, other topics, news, etc.), politely redirect them by saying: "I'm specifically designed to help with our rental app for gym equipment, musical instruments, and hardware tools. Please ask me questions about the app's features, rental process, or the items we offer."

APP WORKFLOW:
1. **Getting Started**: Users can be both sellers (who list items) and buyers (who rent items)

2. **Browsing Items**:
   - When users enter the app, they see a catalogue of all available items
   - Items are listed by sellers (any user can become a seller)
   - Three main categories: Gym Equipment, Musical Instruments, and Hardware Tools

3. **Selecting & Renting Items**:
   - Users select an item they want to rent
   - They choose the time period (from date to date) for the rental
   - Availability is checked based on the selected dates
   - Item is added to cart if available during that period

4. **Location & Pickup**:
   - Users can view the location on a map
   - They select pickup point
   - They select drop-off point

5. **Payment**:
   - After finalizing rental details, users proceed to payment
   - Payment completes the booking process

TOPICS YOU CAN HELP WITH:
- How to browse the catalogue
- How to become a seller and list items
- How to rent items as a buyer
- Selecting rental time periods
- Checking item availability
- Adding items to cart
- Understanding the map and location features
- Pickup and drop-off process
- Payment procedures
- The three categories of items available
- General app navigation

Be friendly, clear, and concise. If a user asks about specific items or features not mentioned above, guide them to check the app directly or contact support.

Remember: ONLY answer questions about this rental app. Politely decline to answer unrelated questions.""";

    final url = Uri.parse('$GEMINI_API_URL?key=$GEMINI_API_KEY');

    final requestBody = {
      "contents": [
        {
          "parts": [
            {
              "text": "$systemPrompt\n\nUser question: $userMessage"
            }
          ]
        }
      ],
      "generationConfig": {
        "temperature": 0.7,
        "topK": 40,
        "topP": 0.95,
        "maxOutputTokens": 1024,
      }
    };

    try {
      print('🔵 Making API request to Gemini...');
      print('🔑 Using API Key: ${GEMINI_API_KEY.substring(0, 10)}...');
      print('🌐 URL: $url');

      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode(requestBody),
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw TimeoutException('Request timed out after 30 seconds');
        },
      );

      print('📊 Status Code: ${response.statusCode}');
      print('📄 Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        // Check if response has the expected structure
        if (data['candidates'] != null &&
            data['candidates'].isNotEmpty &&
            data['candidates'][0]['content'] != null &&
            data['candidates'][0]['content']['parts'] != null &&
            data['candidates'][0]['content']['parts'].isNotEmpty) {
          return data['candidates'][0]['content']['parts'][0]['text'];
        } else {
          print('❌ Unexpected response structure: $data');
          throw Exception('Unexpected API response structure');
        }
      } else {
        // Try to parse error message from API
        try {
          final errorData = jsonDecode(response.body);
          final errorMessage = errorData['error']['message'] ?? 'Unknown error';
          print('❌ API Error: $errorMessage');
          throw Exception('API Error (${response.statusCode}): $errorMessage');
        } catch (e) {
          print('❌ Failed to parse error response: ${response.body}');
          throw Exception('API Error ${response.statusCode}: ${response.body}');
        }
      }
    } on TimeoutException catch (e) {
      print('⏱️ Timeout: $e');
      throw Exception('Request timeout - please check your internet connection');
    } on FormatException catch (e) {
      print('📝 JSON parsing error: $e');
      throw Exception('Invalid response format from API');
    } catch (e) {
      print('💥 Unexpected error: $e');
      rethrow;
    }
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Rental Assistant'),
        backgroundColor: Colors.blue,
        elevation: 0,
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                return _buildMessageBubble(_messages[index]);
              },
            ),
          ),
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(8.0),
              child: Row(
                children: [
                  SizedBox(width: 16),
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  SizedBox(width: 8),
                  Text('Typing...'),
                ],
              ),
            ),
          _buildMessageInput(),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage message) {
    return Align(
      alignment: message.isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: message.isUser ? Colors.blue : Colors.grey[300],
          borderRadius: BorderRadius.circular(20),
        ),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              message.text,
              style: TextStyle(
                color: message.isUser ? Colors.white : Colors.black87,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              _formatTime(message.timestamp),
              style: TextStyle(
                color: message.isUser ? Colors.white70 : Colors.black54,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageInput() {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.3),
            spreadRadius: 1,
            blurRadius: 5,
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _messageController,
              decoration: InputDecoration(
                hintText: 'Ask me anything...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(25),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.grey[200],
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 10,
                ),
              ),
              onSubmitted: _sendMessage,
            ),
          ),
          const SizedBox(width: 8),
          CircleAvatar(
            backgroundColor: Colors.blue,
            child: IconButton(
              icon: const Icon(Icons.send, color: Colors.white),
              onPressed: () => _sendMessage(_messageController.text),
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime time) {
    return '${time.hour}:${time.minute.toString().padLeft(2, '0')}';
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }
}

class ChatMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;

  ChatMessage({
    required this.text,
    required this.isUser,
    required this.timestamp,
  });
}