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
  final ApiService _apiService = ApiService(); // 1. Panggil Service
  
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
    
    // Panggil fungsi untuk load summary (Opsional)
    _loadAISummary();
  }

  // --- LOGIC 1: Minta Summary ke Gemini ---
  void _loadAISummary() async {
    // Note: Pastikan di ApiService ada fungsi getSummary
    // Kalau belum ada, nanti akan return string default/error, tapi aman.
    try {
      // Kita pakai try-catch biar kalau endpoint belum siap, gak crash
      // final summary = await _apiService.getSummary(widget.id); 
      // setState(() => _aiSummary = summary);
      
      // SEMENTARA (Simulasi delay biar kelihatan mikir)
      await Future.delayed(const Duration(seconds: 2));
      if (mounted) {
        setState(() {
          _aiSummary = "Customer seems frustrated about the ${widget.category}. Priority: High.";
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
      setState(() => _isGenerating = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Gagal generate AI: $e")),
      );
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
      setState(() {
        _messages.add({
          "text": content,
          "isMe": true, // Ini pesan kita (CS)
        });
        _messageController.clear(); // Bersihkan kotak ketik
        _isSending = false;
      });
      
    } catch (e) {
      setState(() => _isSending = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Gagal kirim pesan: $e")),
      );
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
            "Complaint / Refund Request", // Bisa didinamisin nanti
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
                    children: [
                      Icon(Icons.auto_awesome, size: 18),
                      SizedBox(width: 8),
                      Text("Generate AI Draft",
                          style: TextStyle(
                              color: Colors.white, fontWeight: FontWeight.bold)),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _insightCard(String title, String content, {Color? color}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 11, color: Colors.grey)),
          const SizedBox(height: 4),
          Text(
            content,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: color ?? Colors.black87,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputArea() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _messageController,
              decoration: InputDecoration(
                hintText: "Type a message or use AI...",
                filled: true,
                fillColor: const Color(0xFFF0F2F5),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Tombol Kirim yang sekarang berfungsi
          InkWell(
            onTap: _isSending ? null : _handleSendMessage,
            child: CircleAvatar(
              backgroundColor: _isSending ? Colors.grey : AppColors.googleBlue,
              child: _isSending 
                  ? const Padding(padding: EdgeInsets.all(8), child: CircularProgressIndicator(color: Colors.white))
                  : const Icon(Icons.send, color: Colors.white, size: 18),
            ),
          ),
        ],
      ),
    );
  }

  Widget _bubble(String text, bool isMe) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        constraints: const BoxConstraints(maxWidth: 250),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isMe ? AppColors.googleBlue : const Color(0xFFF0F2F5),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: isMe ? const Radius.circular(16) : Radius.zero,
            bottomRight: isMe ? Radius.zero : const Radius.circular(16),
          ),
        ),
        child: Text(
          text,
          style: TextStyle(color: isMe ? Colors.white : Colors.black87),
        ),
      ),
    );
  }

  Widget _buildChatList() {
    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: _messages.length,
      itemBuilder: (context, index) {
        final msg = _messages[index];
        return _bubble(msg['text'], msg['isMe']);
      },
    );
  }
}

