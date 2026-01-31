import 'package:flutter/material.dart';
import '../styles/app_colors.dart';
import '../services/api_service.dart';

class ConversationDetailPage extends StatefulWidget {
  final int id; // ID pesan/percakapan
  final String name;
  final String category;
  final String initialMessage;

  const ConversationDetailPage({
    super.key,
    required this.id,
    required this.name,
    required this.category,
    required this.initialMessage,
  });

  @override
  State<ConversationDetailPage> createState() => _ConversationDetailPageState();
}

class _ConversationDetailPageState extends State<ConversationDetailPage> {
  final TextEditingController _messageController = TextEditingController();
  final ApiService _apiService = ApiService(); // Panggil Service
  
  // State untuk menampung chat
  List<Map<String, dynamic>> _messages = []; 
  bool _isGenerating = false;
  bool _isSending = false;
  String _aiSummary = "Analyzing content...";

  @override
  void initState() {
    super.initState();
    // Masukkan pesan awal dari customer ke list
    _messages.add({
      "text": widget.initialMessage,
      "isMe": false,
    });
    
    // Panggil fungsi untuk load summary
    _loadAISummary();
  }

  // --- LOGIC 1: Minta Summary ke Gemini ---
  void _loadAISummary() async {
    try {
      // Panggil API summary (pastikan method getSummary ada di api_service.dart)
      final summary = await _apiService.getSummary(widget.id); 
      if (mounted) {
        setState(() {
          _aiSummary = summary;
        });
      }
    } catch (e) {
      print("Error summary: $e");
    }
  }

  // --- LOGIC 2: Minta Saran Balasan (Draft) ke Gemini ---
  void _generateAIResponse() async {
    setState(() => _isGenerating = true);

    try {
      // Panggil API backend endpoint /suggest-reply
      final suggestion = await _apiService.suggestReply(widget.id);

      if (mounted) {
        setState(() {
          _isGenerating = false;
          // Masukkan saran AI langsung ke kotak ketik
          _messageController.text = suggestion; 
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isGenerating = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Gagal generate AI: $e")),
        );
      }
    }
  }

  // --- LOGIC 3: Kirim Pesan ---
  void _handleSendMessage() async {
    if (_messageController.text.isEmpty) return;

    final content = _messageController.text;
    setState(() => _isSending = true);

    try {
      // 1. Kirim ke Backend
      await _apiService.sendMessage(content, widget.name);

      // 2. Update UI (Tambah balon chat baru)
      if (mounted) {
        setState(() {
          _messages.add({
            "text": content,
            "isMe": true, // Ini pesan kita (CS)
          });
          _messageController.clear(); // Bersihkan kotak ketik
          _isSending = false;
        });
      }
      
    } catch (e) {
      if (mounted) {
        setState(() => _isSending = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Gagal kirim pesan: $e")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        title: Text(
          widget.name,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ),
      body: Row(
        children: [
          // BAGIAN TENGAH: Chat Area
          Expanded(
            flex: 2,
            child: Column(
              children: [
                Expanded(child: _buildChatList()),
                _buildInputArea(),
              ],
            ),
          ),
          // BAGIAN KANAN: AI Sidebar
          _buildAISidepanel(),
        ],
      ),
    );
  }

  // ... Widget Sidebar AI ...
  Widget _buildAISidepanel() {
    return Container(
      width: 300,
      color: const Color(0xFFF7F7F8),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "AI INSIGHTS",
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 20),
          _insightCard(
            "Quick Analysis",
            _aiSummary, // Variabel dinamis
          ),
          const SizedBox(height: 12),
          _insightCard(
            "Detected Intent",
            widget.category, // Ambil dari kategori yang dikirim
            color: AppColors.googleBlue,
          ),
          const Spacer(),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.googleBlue,
              minimumSize: const Size(double.infinity, 50),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: _isGenerating ? null : _generateAIResponse,
            child: _isGenerating
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children


