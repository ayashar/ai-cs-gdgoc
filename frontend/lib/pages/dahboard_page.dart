import 'package:flutter/material.dart';
import '../styles/app_colors.dart';
import '../widgets/inbox_card.dart';
import 'conversation_detail_page.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  String _selectedCategory = "All Messages";
  final TextEditingController _searchController = TextEditingController();

  List<Map<String, dynamic>> _allMessages = [];
  List<Map<String, dynamic>> _filteredMessages = [];

  Future<void> fetchMessages() async {
    try {
      final response = await http.get(
        Uri.parse('http://localhost:3000/api/messages'),
      );
      if (response.statusCode == 200) {
        setState(() {
          _allMessages = List<Map<String, dynamic>>.from(
            json.decode(response.body)['data'],
          );
          _filteredMessages = _allMessages;
        });
      }
    } catch (e) {
      debugPrint("Error fetching data: $e");
    }
  }

  String _userName = "User";

  String get _initial {
    if (_userName.isEmpty) return "A";
    return _userName[0].toUpperCase();
  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _userName = prefs.getString('user_name') ?? "Admin";
    });
  }

  @override
  void initState() {
    super.initState();
    _loadUserData();
    fetchMessages();
    _searchController.addListener(_runFilter);
  }

  void _runFilter() {
    final query = _searchController.text.toLowerCase();
    List<Map<String, dynamic>> results = _allMessages.where((msg) {
      final matchesQuery =
          query.isEmpty ||
          (msg["customer_name"] ?? "").toLowerCase().contains(query) ||
          (msg["content"] ?? "").toLowerCase().contains(query);

      bool matchesCategory = true;
      if (_selectedCategory == "Urgent") {
        matchesCategory =
            msg["priority"] == "Tinggi" ||
            msg["priority"] == "High" ||
            (msg["isUrgent"] ?? false);
      }

      return matchesQuery && matchesCategory;
    }).toList();

    setState(() {
      _filteredMessages = results;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          Container(
            width: 260,
            color: const Color.fromARGB(255, 20, 45, 80),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 40, 24, 20),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.bolt,
                        color: AppColors.googleBlue,
                        size: 28,
                      ),
                      const SizedBox(width: 10),
                      Text(
                        'Alex.ai',
                        style: Theme.of(context).textTheme.headlineMedium
                            ?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 22,
                            ),
                      ),
                    ],
                  ),
                ),
                _buildSidebarItem(Icons.all_inbox, "All Messages"),
                _buildSidebarItem(Icons.warning_amber_rounded, "Urgent"),
                const Spacer(),
                const Divider(color: Colors.white10),
                _buildLogoutItem(context),
                const SizedBox(height: 20),
              ],
            ),
          ),

          Expanded(
            child: Column(
              children: [
                _buildTopNavbar(),
                Expanded(child: _buildInboxContent()),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopNavbar() {
    return Container(
      height: 70,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(
        color: const Color.fromARGB(255, 197, 197, 197),
        border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Row(
        children: [
          Expanded(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: "Search customer or message...",
                  prefixIcon: const Icon(Icons.search, size: 20),
                  filled: true,
                  fillColor: const Color(0xFFF5F5F5),
                  contentPadding: const EdgeInsets.symmetric(vertical: 0),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
          ),
          const Spacer(),
          CircleAvatar(
            backgroundColor: AppColors.googleBlue,
            radius: 18,
            child: Text(
              _initial,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInboxContent() {
    return _filteredMessages.isEmpty
        ? const Center(child: Text("No messages found."))
        : ListView.builder(
            padding: const EdgeInsets.all(24),
            itemCount: _filteredMessages.length,
            itemBuilder: (context, index) {
              final msg = _filteredMessages[index];
              return Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 800),
                  child: InboxCard(
                    name: msg["customer_name"] ?? "Unknown Customer",
                    message: msg["content"] ?? "No message content",
                    category: msg["category"] ?? "General",
                    sentiment: msg["sentiment"] ?? "Neutral",
                    time: msg["time"] ?? "Just now",
                    isUrgent:
                        msg["priority"] == "Tinggi" ||
                        (msg["isUrgent"] ?? false),
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ConversationDetailPage(
                          id: msg["id"] ?? 0,
                          name: msg["customer_name"] ?? "Customer",
                          category: msg["category"] ?? "General",
                          initialMessage: msg["content"] ?? "",
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          );
  }

  Widget _buildSidebarItem(IconData icon, String title) {
    bool isSelected = _selectedCategory == title;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: ListTile(
        onTap: () {
          setState(() => _selectedCategory = title);
          _runFilter();
        },
        selected: isSelected,
        selectedTileColor: Colors.white.withValues(alpha: 10),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        leading: Icon(
          icon,
          color: isSelected ? Colors.white : Colors.white60,
          size: 20,
        ),
        title: Text(
          title,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.white60,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  Widget _buildLogoutItem(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: ListTile(
        onTap: () {
          Navigator.pushReplacementNamed(context, '/');
        },
        leading: const Icon(Icons.logout, color: Colors.redAccent, size: 20),
        title: const Text(
          'Logout',
          style: TextStyle(
            color: Colors.redAccent,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        hoverColor: Colors.red.withValues(alpha: 10),
      ),
    );
  }
}
