import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // For Clipboard
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

import '../../theme/theme_manager.dart';
import '../../controllers/task_controller.dart';
import '../../controllers/xp_controller.dart';

class ChatPage extends StatefulWidget {
  const ChatPage({super.key});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  // 📦 HIVE: Local Database for Chat History
  late Box _chatBox;
  List<Map<String, dynamic>> _messages = [];

  // 🎤 VOICE: Speech Recognition
  late stt.SpeechToText _speech;
  bool _isListening = false;
  bool _isTyping = false; // Controls the "Astra is typing..." animation

  // ⚠️ YOUR KEY GOES HERE. (This is the only part I cannot do for you)
  static const String _apiKey = 'AIzaSyDt10th9Hf2U3ocBoaMPKXBhsPHlPORY-o';

  late final GenerativeModel _model;
  late final ChatSession _chatSession;

  @override
  void initState() {
    super.initState();
    _initHive();
    _initVoice();
    _initModel();
  }

  // --- 1. SETUP DATABASE ---
  Future<void> _initHive() async {
    _chatBox = await Hive.openBox('chatHistory');
    if (_chatBox.isNotEmpty) {
      setState(() {
        _messages = List<Map<String, dynamic>>.from(
            _chatBox.values.map((e) => Map<String, dynamic>.from(e))
        );
      });
      // Scroll to bottom slightly after load
      Future.delayed(const Duration(milliseconds: 200), _scrollToBottom);
    } else {
      _saveMessage("astra", "Astra Systems Online. Syncing complete. How can I assist?");
    }
  }

  // --- 2. SETUP VOICE ---
  void _initVoice() {
    _speech = stt.SpeechToText();
  }

  void _listen() async {
    if (!_isListening) {
      bool available = await _speech.initialize(
        onError: (val) => debugPrint('Voice Error: $val'),
        onStatus: (val) => debugPrint('Voice Status: $val'),
      );
      if (available) {
        setState(() => _isListening = true);
        _speech.listen(onResult: (val) {
          setState(() {
            _controller.text = val.recognizedWords;
          });
        });
      }
    } else {
      setState(() => _isListening = false);
      _speech.stop();
    }
  }

  // --- 3. SETUP GEMINI (The Brain) ---
  void _initModel() {
    // 'gemini-1.5-flash' is the fastest, free-tier friendly model.
    _model = GenerativeModel(
      model: 'gemini-flash-latest',
      apiKey: _apiKey,
    );
    _chatSession = _model.startChat();
  }

  // --- HELPER: SAVE & SHOW MESSAGE ---
  void _saveMessage(String sender, String text) {
    final msg = {"sender": sender, "text": text, "time": DateTime.now().toIso8601String()};
    setState(() {
      _messages.add(msg);
    });
    // Save to local storage so it remembers next time
    if (_chatBox.isOpen) _chatBox.add(msg);
    _scrollToBottom();
  }

  void _handleSubmitted(String text) {
    if (text.trim().isEmpty) return;
    _controller.clear();
    _saveMessage("user", text);

    // Check if user wants to create a task, otherwise chat
    _checkForTaskIntent(text);
  }

  // --- 4. SMART TASK CREATION ---
  void _checkForTaskIntent(String text) {
    final lower = text.toLowerCase();

    // Detect commands like "Remind me to..."
    if (lower.startsWith("remind me to ") || lower.startsWith("add task ")) {
      String taskTitle = text.replaceAll(RegExp(r'(?i)(remind me to |add task )'), "");

      if (taskTitle.isNotEmpty) {
        final taskController = Provider.of<TaskController>(context, listen: false);
        taskController.addTask(taskTitle, category: "General");

        _saveMessage("astra", "✅ Directive confirmed. Created task: \"$taskTitle\"");
        return;
      }
    }
    // If not a command, generate AI response
    _generateStreamingResponse(text);
  }

  // --- 5. STREAMING RESPONSE (THE "QUICK FEELING") ---
  Future<void> _generateStreamingResponse(String userQuery) async {
    try {
      setState(() => _isTyping = true);

      final taskController = Provider.of<TaskController>(context, listen: false);
      final xpController = Provider.of<XpController>(context, listen: false);
      final user = FirebaseAuth.instance.currentUser;
      final String name = user?.displayName ?? "Hunter";

      // Gather live data
      String allTasks = taskController.tasks.isEmpty
          ? "No active missions."
          : taskController.tasks.map((t) => "- ${t.title} (${t.category})").join("\n");
      String analysis = "Level ${xpController.level}, ${xpController.embers} Embers.";

      // 🔥 PERSONALITY PROTOCOL
      String systemContext = """
      You are Astra, a tactical AI companion.
      USER: $name. STATS: $analysis.
      MISSIONS: $allTasks
      
      PROTOCOL:
      1. Be helpful, witty, and concise. 
      2. If chatting ("hi", "how are you"), be friendly and human-like.
      3. If asked about data, be precise.
      
      QUERY: $userQuery
      """;

      // ⚡ STREAMING: Types word-by-word instead of waiting
      final stream = _chatSession.sendMessageStream(Content.text(systemContext));

      String accumulatedText = "";
      bool isFirstChunk = true;

      await for (final chunk in stream) {
        if (chunk.text != null) {
          accumulatedText += chunk.text!;

          if (isFirstChunk) {
            // Remove "Thinking..." and start the message
            setState(() {
              _isTyping = false;
              _saveMessage("astra", accumulatedText);
            });
            isFirstChunk = false;
          } else {
            // Update the existing message bubble
            setState(() {
              _messages.last['text'] = accumulatedText;
              // Update storage
              if (_chatBox.isNotEmpty) {
                _chatBox.putAt(_chatBox.length - 1, _messages.last);
              }
            });
          }
          // Auto-scroll
          if (_scrollController.hasClients && _scrollController.position.atEdge) {
            _scrollToBottom();
          }
        }
      }

    } catch (e) {
      if (mounted) {
        setState(() => _isTyping = false);
        _saveMessage("astra", "System Failure: $e");
      }
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  // --- 6. LONG PRESS MENU (Copy, Edit, Delete) ---
  void _showOptions(int index, String text, bool isUser) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: ThemeManager().cardColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.copy_rounded),
              title: const Text("Copy Text"),
              onTap: () {
                Clipboard.setData(ClipboardData(text: text));
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Copied.")));
              },
            ),
            if (isUser) ListTile(
              leading: const Icon(Icons.edit_rounded),
              title: const Text("Edit Message"),
              onTap: () {
                Navigator.pop(context);
                _controller.text = text;
                // Delete old message so user can "resend" the corrected version
                setState(() {
                  _messages.removeAt(index);
                  _chatBox.deleteAt(index);
                });
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent),
              title: const Text("Delete Message", style: TextStyle(color: Colors.redAccent)),
              onTap: () {
                Navigator.pop(context);
                setState(() {
                  _messages.removeAt(index);
                  _chatBox.deleteAt(index);
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: ThemeManager(),
      builder: (context, child) {
        final theme = ThemeManager();
        return Scaffold(
          backgroundColor: theme.bgColor,
          appBar: AppBar(
            backgroundColor: theme.cardColor,
            elevation: 0,
            leading: IconButton(
              icon: Icon(Icons.arrow_back_ios_new_rounded, color: theme.textColor),
              onPressed: () => Navigator.pop(context),
            ),
            title: Row(
              children: [
                CircleAvatar(backgroundImage: const AssetImage('assets/profile/astra_happy.png'), radius: 14),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("ASTRA ONLINE", style: TextStyle(color: theme.textColor, fontSize: 14, fontWeight: FontWeight.bold)),
                    Row(children: [
                      Container(width: 6, height: 6, decoration: const BoxDecoration(color: Colors.greenAccent, shape: BoxShape.circle)),
                      const SizedBox(width: 4),
                      Text("Systems Synced", style: TextStyle(color: theme.subText, fontSize: 10)),
                    ]),
                  ],
                ),
              ],
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.delete_outline_rounded),
                tooltip: "Clear History",
                onPressed: () {
                  _chatBox.clear();
                  setState(() => _messages.clear());
                },
              )
            ],
          ),
          body: Column(
            children: [
              Expanded(
                child: ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(20),
                  itemCount: _messages.length + (_isTyping ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (index == _messages.length) return _buildTypingIndicator(theme);
                    final msg = _messages[index];
                    final isUser = msg['sender'] == 'user';
                    return GestureDetector(
                      onLongPress: () => _showOptions(index, msg['text'], isUser),
                      child: _buildMessageBubble(theme, msg['text'], isUser),
                    );
                  },
                ),
              ),
              _buildInputArea(theme),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMessageBubble(ThemeManager theme, String text, bool isUser) {
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.8),
        decoration: BoxDecoration(
          color: isUser ? theme.accentColor : theme.cardColor,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(12),
            topRight: const Radius.circular(12),
            bottomLeft: isUser ? const Radius.circular(12) : Radius.zero,
            bottomRight: isUser ? Radius.zero : const Radius.circular(12),
          ),
        ),
        child: Text(text, style: TextStyle(color: isUser ? Colors.white : theme.textColor, fontSize: 14)),
      ),
    );
  }

  Widget _buildTypingIndicator(ThemeManager theme) {
    return Align(alignment: Alignment.centerLeft, child: Padding(
      padding: const EdgeInsets.only(bottom: 10, left: 10),
      child: Text("Astra is typing...", style: TextStyle(color: theme.subText, fontSize: 10)),
    ));
  }

  Widget _buildInputArea(ThemeManager theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      color: theme.cardColor,
      child: Row(
        children: [
          // 🎤 MIC BUTTON
          GestureDetector(
            onTap: _listen,
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                  color: _isListening ? Colors.redAccent : theme.bgColor,
                  shape: BoxShape.circle
              ),
              child: Icon(_isListening ? Icons.mic : Icons.mic_none, color: theme.textColor, size: 20),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: _controller,
              style: TextStyle(color: theme.textColor),
              decoration: InputDecoration(
                  hintText: _isListening ? "Listening..." : "Enter directive...",
                  filled: true,
                  fillColor: theme.bgColor,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(30), borderSide: BorderSide.none),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12)
              ),
              onSubmitted: _handleSubmitted,
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () => _handleSubmitted(_controller.text),
            child: Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: theme.accentColor, shape: BoxShape.circle), child: const Icon(Icons.send_rounded, color: Colors.white, size: 18)),
          ),
        ],
      ),
    );
  }
}