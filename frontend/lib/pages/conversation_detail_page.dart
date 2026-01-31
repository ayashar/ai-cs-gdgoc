import 'package:flutter/material.dart';
import '../styles/app_colors.dart';
import '../services/api_service.dart';

class ConversationDetailPage extends StatefulWidget {
  final int id;
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
  bool _isGenerating = false;

  String _aiSummary = "Analyzing...";

  void _loadAISummary() async {
    final summary = await ApiService.getSummary(widget.id);
    setState(() {
      _aiSummary = summary;
    });
  }

  void _generateAIResponse() async {
    setState(() => _isGenerating = true);
    final suggestion = await ApiService.getSuggestReply(widget.id);

    setState(() {
      _isGenerating = false;
      _messageController.text = suggestion;
    });
  }

  @override
  void initState() {
    super.initState();
    _loadAISummary();
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
          Expanded(
            flex: 2,
            child: Column(
              children: [
                Expanded(child: _buildChatList()),
                _buildInputArea(),
              ],
            ),
          ),
          _buildAISidepanel(),
        ],
      ),
    );
  }

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
            "Summary",
            "Issues with ${widget.category.toLowerCase()} identified.",
          ),
          const SizedBox(height: 12),
          _insightCard(
            "Sentiment",
            "Analyzing...",
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
                : const Text(
                    "Generate AI Draft",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
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
          Text(
            content,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: color ?? Colors.black87,
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
                hintText: "Type a message...",
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
          const CircleAvatar(
            backgroundColor: AppColors.googleBlue,
            child: Icon(Icons.send, color: Colors.white, size: 18),
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
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isMe ? AppColors.googleBlue : const Color(0xFFF0F2F5),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          text,
          style: TextStyle(color: isMe ? Colors.white : Colors.black87),
        ),
      ),
    );
  }

  Widget _buildChatList() {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        _bubble(widget.initialMessage, false),

        if (_isGenerating) _bubble("Alex.ai is analyzing the context...", true),

        if (!_isGenerating && _messageController.text.isNotEmpty)
          _bubble("Draft suggestion: ${_messageController.text}", true),
      ],
    );
  }
}
