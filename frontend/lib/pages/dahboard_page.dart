import 'package:flutter/material.dart';
import '../styles/app_colors.dart';
import '../widgets/inbox_card.dart';
import 'conversation_detail_page.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  String _selectedCategory = "All Messages";
  final TextEditingController _searchController = TextEditingController();

  final List<Map<String, dynamic>> _allMessages = [
    {
      "name": "Budi Setiawan",
      "message": "Akun saya belum aktif padahal sudah bayar dari kemarin!",
      "category": "Billing",
      "sentiment": "Angry",
      "time": "2m ago",
      "isUrgent": true,
    },
    {
      "name": "Siti Aminah",
      "message": "Halo, saya tertarik dengan layanan AI ini untuk toko saya.",
      "category": "Inquiry",
      "sentiment": "Happy",
      "time": "15m ago",
      "isUrgent": false,
    },
    {
      "name": "Andi Wijaya",
      "message": "Apakah sudah support pembayaran via QRIS?",
      "category": "Technical",
      "sentiment": "Neutral",
      "time": "1h ago",
      "isUrgent": false,
    },
    {
      "name": "Rina Permata",
      "message": "Password saya tidak bisa di-reset, muncul error 404.",
      "category": "Technical",
      "sentiment": "Angry",
      "time": "3h ago",
      "isUrgent": true,
    },
  ];

  List<Map<String, dynamic>> _filteredMessages = [];

  @override
  void initState() {
    super.initState();
    _filteredMessages = _allMessages;
    _searchController.addListener(_runFilter);
  }

  void _runFilter() {
    List<Map<String, dynamic>> results = [];
    if (_searchController.text.isEmpty) {
      results = _allMessages;
    } else {
      results = _allMessages
          .where(
            (msg) =>
                msg["name"].toLowerCase().contains(
                  _searchController.text.toLowerCase(),
                ) ||
                msg["message"].toLowerCase().contains(
                  _searchController.text.toLowerCase(),
                ),
          )
          .toList();
    }

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
                _buildSidebarItem(Icons.check_circle_outline, "Resolved"),
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
        color: Colors.white,
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
          const CircleAvatar(
            backgroundColor: AppColors.googleBlue,
            radius: 18,
            child: Text('A', style: TextStyle(color: Colors.white)),
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
                    name: msg["name"],
                    message: msg["message"],
                    category: msg["category"],
                    sentiment: msg["sentiment"],
                    time: msg["time"],
                    isUrgent: msg["isUrgent"],
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ConversationDetailPage(
                          name: msg["name"],
                          category: msg["category"],
                          initialMessage: msg["message"],
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
        onTap: () => setState(() => _selectedCategory = title),
        selected: isSelected,
        selectedTileColor: Colors.white.withValues(alpha: 0.1),
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
        hoverColor: Colors.red.withValues(alpha: 0.1),
      ),
    );
  }
}
