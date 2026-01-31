import 'package:flutter/material.dart';
import '../styles/app_colors.dart';

class InboxCard extends StatelessWidget {
  final String name;
  final String message;
  final String category;
  final String sentiment;
  final String time;
  final bool isUrgent;
  final VoidCallback onTap;

  const InboxCard({
    super.key,
    required this.name,
    required this.message,
    required this.category,
    required this.sentiment,
    required this.time,
    required this.isUrgent,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    Color sentimentColor = sentiment == 'Angry'
        ? AppColors.googleRed
        : (sentiment == 'Happy' ? AppColors.googleGreen : AppColors.googleYellow);

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade200),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(5),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Text(
                        name,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      if (isUrgent) ...[
                        const SizedBox(width: 8),
                        _buildBadge(
                          'URGENT!',
                          Colors.orange.shade50,
                          Colors.orange,
                        ),
                      ],
                    ],
                  ),
                  Text(time, style: Theme.of(context).textTheme.bodySmall),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                message,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: Colors.grey.shade600, height: 1.4),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  _buildBadge(
                    category,
                    AppColors.googleBlue.withAlpha(25),
                    Colors.blue.shade700,
                  ),
                  const SizedBox(width: 8),
                  _buildBadge(
                    sentiment,
                    sentimentColor.withAlpha(25),
                    sentimentColor,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBadge(String label, Color bgColor, Color textColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label.toUpperCase(),
        style: TextStyle(
          color: textColor,
          fontSize: 10,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}
