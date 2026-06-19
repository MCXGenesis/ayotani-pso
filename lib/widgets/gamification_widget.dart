import 'package:flutter/material.dart';
import '../models/user_profile_model.dart';
import '../theme/app_colors.dart';

class GamificationWidget extends StatefulWidget {
  final UserProfile? userProfile;

  GamificationWidget({
    super.key,
    required this.userProfile,
  });

  @override
  State<GamificationWidget> createState() => _GamificationWidgetState();
}

class _GamificationWidgetState extends State<GamificationWidget> with SingleTickerProviderStateMixin {
  late AnimationController _gemAnimationController;
  late Animation<double> _gemScale;

  @override
  void initState() {
    super.initState();
    _gemAnimationController = AnimationController(
      duration: Duration(milliseconds: 600),
      vsync: this,
    );
    _gemScale = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(parent: _gemAnimationController, curve: Curves.elasticOut),
    );
  }

  @override
  void didUpdateWidget(GamificationWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Trigger animation when gems change
    if (oldWidget.userProfile?.gems != widget.userProfile?.gems) {
      _gemAnimationController.forward().then((_) {
        _gemAnimationController.reverse();
      });
    }
  }

  @override
  void dispose() {
    _gemAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final profile = widget.userProfile;

    if (profile == null) {
      return _buildLoadingCard();
    }

    final nextLevelExp = (profile.level * 100).toInt();
    final currentExp = 0; // This would come from user_tasks completed count
    final expPercentage = currentExp / nextLevelExp;

    return Column(
      children: [
        // Main gamification card
        Container(
          padding: EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [context.primaryColor, context.primaryColor.withOpacity(0.8)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: context.primaryColor.withOpacity(0.3),
                blurRadius: 12,
                offset: Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            children: [
              // Level and gems row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Level section
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Level',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        '${profile.level}',
                        style: TextStyle(
                          fontSize: 48,
                          fontWeight: FontWeight.w900,
                          color: context.cardBg,
                        ),
                      ),
                    ],
                  ),
                  // Gem section with animation
                  ScaleTransition(
                    scale: _gemScale,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          'Gems',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        SizedBox(height: 4),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Icon(Icons.star, color: Colors.amber, size: 32),
                            SizedBox(width: 8),
                            Text(
                              '${profile.gems}',
                              style: TextStyle(
                                fontSize: 40,
                                fontWeight: FontWeight.w900,
                                color: Colors.amber,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              SizedBox(height: 20),
              // Level progress bar
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Pengalaman',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                      ),
                      Text(
                        '$currentExp / $nextLevelExp XP',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      minHeight: 8,
                      value: expPercentage,
                      backgroundColor: context.cardBg.withOpacity(0.2),
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Colors.amber[300] ?? Colors.amber,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        SizedBox(height: 16),
        // Achievements/milestones section
        Container(
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: context.cardBg,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: context.dividerColor),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Pencapaian',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
              SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildAchievementBadge(
                    icon: Icons.local_fire_department,
                    label: 'Bersemangat',
                    isUnlocked: profile.gems > 50,
                  ),
                  _buildAchievementBadge(
                    icon: Icons.grass,
                    label: 'Petani Andal',
                    isUnlocked: profile.level >= 5,
                  ),
                  _buildAchievementBadge(
                    icon: Icons.workspace_premium,
                    label: 'Master',
                    isUnlocked: profile.level >= 10,
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Build achievement badge
  Widget _buildAchievementBadge({
    required IconData icon,
    required String label,
    required bool isUnlocked,
  }) {
    return Column(
      children: [
        Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isUnlocked ? context.primaryColor.withOpacity(0.2) : context.dividerColor,
            border: Border.all(
              color: isUnlocked ? context.primaryColor : context.dividerColor,
              width: 2,
            ),
          ),
          child: Icon(
            icon,
            color: isUnlocked ? context.primaryColor : context.textMuted,
            size: 28,
          ),
        ),
        SizedBox(height: 8),
        Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: isUnlocked ? context.textPrimary : context.textMuted,
          ),
        ),
      ],
    );
  }

  /// Build loading card
  Widget _buildLoadingCard() {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [context.primaryColor.withOpacity(0.3), context.primaryColor.withOpacity(0.1)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: SizedBox(
        height: 150,
        child: Center(
          child: CircularProgressIndicator(),
        ),
      ),
    );
  }
}
