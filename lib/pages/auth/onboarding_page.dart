import 'package:flutter/material.dart';
import 'package:ayotani/theme/app_colors.dart';
import '../../routes/app_routes.dart';

class OnboardingPage extends StatefulWidget {
  final String userId;

  OnboardingPage({
    super.key,
    required this.userId,
  });

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  int _currentStep = 0;
  late PageController _pageController;
  bool _isLoading = false;

  // Onboarding data
  final List<OnboardingStep> _steps = [
    OnboardingStep(
      title: 'Selamat Datang di Ayo Tani',
      description: 'Platform pertanian modern untuk petani muda. Mari mulai perjalanan Anda menuju pertanian yang lebih produktif!',
      icon: Icons.agriculture,
      backgroundColor: Color(0xFF0B6138),
    ),
    OnboardingStep(
      title: 'Izinkan Akses Lokasi',
      description: 'Kami membutuhkan akses lokasi Anda untuk memberikan data cuaca real-time dan rekomendasi pertanian yang sesuai dengan area Anda.',
      icon: Icons.location_on,
      backgroundColor: Color(0xFF0B5F61),
    ),
    OnboardingStep(
      title: 'Lengkapi Profil Anda',
      description: 'Tambahkan nama, foto profil, dan informasi lainnya untuk personalisasi pengalaman Anda.',
      icon: Icons.person,
      backgroundColor: Color(0xFF2D6A4F),
    ),
    OnboardingStep(
      title: 'Siap Memulai!',
      description: 'Anda sudah siap. Mulai jelajahi fitur-fitur Ayo Tani dan tingkatkan hasil pertanian Anda.',
      icon: Icons.check_circle,
      backgroundColor: Color(0xFF1B4332),
    ),
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  /// Handle moving to next step
  void _nextStep() {
    if (_currentStep < _steps.length - 1) {
      _pageController.nextPage(
        duration: Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _completeOnboarding();
    }
  }

  /// Handle moving to previous step
  void _previousStep() {
    if (_currentStep > 0) {
      _pageController.previousPage(
        duration: Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  /// Complete onboarding and navigate to home
  Future<void> _completeOnboarding() async {
    setState(() => _isLoading = true);

    try {
      // Mark onboarding as completed in user preferences
      // For now, we'll just navigate to home
      if (mounted) {
        Navigator.pushReplacementNamed(context, AppRoutes.home);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  /// Skip to end of onboarding
  void _skipOnboarding() {
    _pageController.jumpToPage(_steps.length - 1);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PageView.builder(
        controller: _pageController,
        onPageChanged: (index) {
          setState(() => _currentStep = index);
        },
        itemCount: _steps.length,
        itemBuilder: (context, index) {
          return _OnboardingStepWidget(
            step: _steps[index],
            stepNumber: index + 1,
            totalSteps: _steps.length,
            onNext: _nextStep,
            onPrevious: _previousStep,
            onSkip: _skipOnboarding,
            isLoading: _isLoading,
            isLastStep: index == _steps.length - 1,
          );
        },
      ),
    );
  }
}

/// Data class for onboarding step
class OnboardingStep {
  final String title;
  final String description;
  final IconData icon;
  final Color backgroundColor;

  OnboardingStep({
    required this.title,
    required this.description,
    required this.icon,
    required this.backgroundColor,
  });
}

/// Individual onboarding step widget
class _OnboardingStepWidget extends StatelessWidget {
  final OnboardingStep step;
  final int stepNumber;
  final int totalSteps;
  final VoidCallback onNext;
  final VoidCallback onPrevious;
  final VoidCallback onSkip;
  final bool isLoading;
  final bool isLastStep;

  const _OnboardingStepWidget({
    required this.step,
    required this.stepNumber,
    required this.totalSteps,
    required this.onNext,
    required this.onPrevious,
    required this.onSkip,
    required this.isLoading,
    required this.isLastStep,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: step.backgroundColor,
      child: SafeArea(
        child: Column(
          children: [
            // Skip button (top right)
            if (stepNumber < totalSteps)
              Align(
                alignment: Alignment.topRight,
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: GestureDetector(
                    onTap: !isLoading ? onSkip : null,
                    child: Text(
                      'Lewati',
                      style: TextStyle(
                        color: context.cardBg.withOpacity(0.8),
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              )
            else
              SizedBox(height: 16),

            // Main content
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Icon
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      color: context.cardBg.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      step.icon,
                      size: 60,
                      color: context.cardBg,
                    ),
                  ),
                  SizedBox(height: 40),

                  // Title
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 24),
                    child: Text(
                      step.title,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        color: context.cardBg,
                        height: 1.2,
                      ),
                    ),
                  ),
                  SizedBox(height: 16),

                  // Description
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 24),
                    child: Text(
                      step.description,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        color: context.cardBg.withOpacity(0.85),
                        height: 1.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Bottom controls
            Padding(
              padding: EdgeInsets.all(24),
              child: Column(
                children: [
                  // Progress indicator
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      totalSteps,
                      (index) => Container(
                        width: 10,
                        height: 10,
                        margin: EdgeInsets.symmetric(horizontal: 4),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: index <= stepNumber - 1
                              ? context.cardBg
                              : context.cardBg.withOpacity(0.3),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 24),

                  // Buttons
                  Row(
                    children: [
                      // Previous button
                      if (stepNumber > 1)
                        Expanded(
                          child: OutlinedButton(
                            onPressed: !isLoading ? onPrevious : null,
                            style: OutlinedButton.styleFrom(
                              padding: EdgeInsets.symmetric(vertical: 12),
                              side: BorderSide(
                                color: context.cardBg.withOpacity(0.5),
                                width: 1.5,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: Text(
                              'Kembali',
                              style: TextStyle(
                                color: context.cardBg.withOpacity(0.9),
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      if (stepNumber > 1) SizedBox(width: 12),

                      // Next/Finish button
                      Expanded(
                        child: FilledButton(
                          onPressed: !isLoading ? onNext : null,
                          style: FilledButton.styleFrom(
                            backgroundColor: context.cardBg,
                            foregroundColor: step.backgroundColor,
                            padding: EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: isLoading
                              ? SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : Text(
                                  isLastStep ? 'Mulai!' : 'Lanjut',
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
