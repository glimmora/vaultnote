import 'package:flutter/material.dart';
import '../../domain/entities/note.dart';

class NoteCard extends StatelessWidget {
  final Note note;
  final VoidCallback? onTap;
  final VoidCallback? onPin;
  final VoidCallback? onArchive;
  final VoidCallback? onLongPress;
  final bool isCompact;

  const NoteCard({
    super.key,
    required this.note,
    this.onTap,
    this.onPin,
    this.onArchive,
    this.onLongPress,
    this.isCompact = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = _hexToColor(note.color);
    
    return Card(
      color: color,
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header with title and pin
              Row(
                children: [
                  Expanded(
                    child: Text(
                      note.title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (note.pinned)
                    const Icon(Icons.push_pin, size: 16, color: Colors.grey),
                ],
              ),
              if (!isCompact) ...[
                const SizedBox(height: 8),
                // Note body preview
                Text(
                  note.body,
                  style: Theme.of(context).textTheme.bodyMedium,
                  maxLines: isCompact ? 2 : 6,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              const SizedBox(height: 8),
              // Labels
              if (note.labels.isNotEmpty)
                Wrap(
                  spacing: 4,
                  runSpacing: 4,
                  children: note.labels.take(3).map((label) {
                    return Chip(
                      label: Text(
                        label,
                        style: const TextStyle(fontSize: 10, color: Colors.white),
                      ),
                      backgroundColor: _getLabelColor(label).withOpacity(0.8),
                      padding: EdgeInsets.zero,
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      visualDensity: VisualDensity.compact,
                    );
                  }).toList(),
                ),
              if (isCompact && note.labels.length > 3)
                Text(
                  '+${note.labels.length - 3} more',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              // Modified date
              if (!isCompact) ...[
                const SizedBox(height: 8),
                Text(
                  _formatDate(note.modified),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey.shade600,
                      ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Color _hexToColor(String hex) {
    return Color(int.parse(hex.substring(1), radix: 16) + 0xFF000000);
  }

  Color _getLabelColor(String labelName) {
    // Default label colors based on name hash
    final colors = [
      const Color(0xFF4285F4),
      const Color(0xFFEA4335),
      const Color(0xFFFBBC05),
      const Color(0xFF34A853),
      const Color(0xFFFF6D01),
      const Color(0xFF46BDC6),
      const Color(0xFF9E69AF),
      const Color(0xFFFF8BCC),
    ];
    return colors[labelName.hashCode.abs() % colors.length];
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      if (difference.inHours == 0) {
        if (difference.inMinutes == 0) {
          return 'Just now';
        }
        return '${difference.inMinutes}m ago';
      }
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}
