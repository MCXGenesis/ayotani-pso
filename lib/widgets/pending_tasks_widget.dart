import 'package:flutter/material.dart';
import '../services/task_service.dart';
import '../services/supabase_service.dart';
import '../theme/app_colors.dart';

class PendingTasksWidget extends StatefulWidget {
  final VoidCallback? onTaskCompleted;

  PendingTasksWidget({
    super.key,
    this.onTaskCompleted,
  });

  @override
  State<PendingTasksWidget> createState() => _PendingTasksWidgetState();
}

class _PendingTasksWidgetState extends State<PendingTasksWidget> {
  final _taskService = TaskService();

  @override
  Widget build(BuildContext context) {
    final supabase = SupabaseService();
    return FutureBuilder<Map<String, dynamic>?>(
      future: _taskService.getTopPendingTask(supabase.userId ?? ''),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildLoadingCard();
        }

        if (snapshot.hasError) {
          return _buildErrorCard();
        }

        final taskData = snapshot.data;

        if (taskData == null) {
          return _buildNoTaskCard();
        }

        return _buildTaskCard(taskData);
      },
    );
  }

  /// Build task card
  Widget _buildTaskCard(Map<String, dynamic> taskData) {
    final taskTitle = taskData['title'] as String?;
    final taskDesc = taskData['description'] as String?;
    final rewardGems = taskData['reward_gems'] as int? ?? 10;

    return GestureDetector(
      onTap: () {
        // Navigate to monitoring screen or show task details
      },
      child: Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [context.secondaryColor.withOpacity(0.9), context.secondaryColor.withOpacity(0.7)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: context.secondaryColor.withOpacity(0.2),
              blurRadius: 8,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Tugas Selanjutnya',
                        style: TextStyle(color: Colors.white70, fontSize: 11),
                      ),
                      SizedBox(height: 6),
                      Text(
                        taskTitle ?? 'Tugas',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: context.cardBg,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      if (taskDesc != null) ...[
                        SizedBox(height: 6),
                        Text(
                          taskDesc,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                SizedBox(width: 12),
                Column(
                  children: [
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.amber[400],
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.star, color: context.cardBg, size: 14),
                          SizedBox(width: 4),
                          Text(
                            '+$rewardGems',
                            style: TextStyle(
                              color: context.cardBg,
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 8),
                    Icon(Icons.arrow_forward, color: context.cardBg, size: 20),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Build loading card
  Widget _buildLoadingCard() {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.dividerColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: SizedBox(
        height: 100,
        child: Center(
          child: CircularProgressIndicator(),
        ),
      ),
    );
  }

  /// Build error card
  Widget _buildErrorCard() {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red[50],
        border: Border.all(color: Colors.red[200]!),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        'Gagal memuat tugas',
        style: TextStyle(color: Colors.red[700]),
      ),
    );
  }

  /// Build no task card
  Widget _buildNoTaskCard() {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.green[50]!, Colors.green[100]!],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: context.primaryColor.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.check_circle, color: context.primaryColor, size: 32),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  'Semua Tugas Selesai!',
                  style: TextStyle(
                    color: Color(0xFF2D6A4F),
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Kembali besok untuk tugas baru',
                  style: TextStyle(
                    color: Color(0xFF555555),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
