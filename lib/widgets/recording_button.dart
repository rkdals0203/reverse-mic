import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/audio_provider.dart';

class RecordingButton extends StatefulWidget {
  const RecordingButton({super.key});

  @override
  State<RecordingButton> createState() => _RecordingButtonState();
}

class _RecordingButtonState extends State<RecordingButton>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _scaleController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    
    // 펄스 애니메이션 (녹음 중일 때)
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));

    // 스케일 애니메이션 (터치 피드백)
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 100),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(
      parent: _scaleController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _scaleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AudioProvider>(
      builder: (context, audioProvider, child) {
        // 녹음 상태에 따라 펄스 애니메이션 제어
        if (audioProvider.recordingState == RecordingState.recording) {
          _pulseController.repeat(reverse: true);
        } else {
          _pulseController.stop();
          _pulseController.reset();
        }

        return Center(
          child: GestureDetector(
            onTapDown: (_) {
              _scaleController.forward();
            },
            onTapUp: (_) {
              _scaleController.reverse();
            },
            onTapCancel: () {
              _scaleController.reverse();
            },
            onTap: () => _handleRecordingButtonTap(audioProvider),
            child: AnimatedBuilder(
              animation: Listenable.merge([_pulseAnimation, _scaleAnimation]),
              builder: (context, child) {
                return Transform.scale(
                  scale: _scaleAnimation.value,
                  child: Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: _getButtonGradient(audioProvider.recordingState),
                      boxShadow: [
                        BoxShadow(
                          color: _getButtonColor(audioProvider.recordingState)
                              .withValues(alpha: 0.4),
                          blurRadius: 25,
                          spreadRadius: audioProvider.recordingState == RecordingState.recording
                              ? _pulseAnimation.value * 12
                              : 8,
                        ),
                        BoxShadow(
                          color: Theme.of(context).colorScheme.background
                              .withValues(alpha: 0.1),
                          blurRadius: 15,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: Icon(
                      _getButtonIcon(audioProvider.recordingState),
                      size: 48,
                      color: Colors.white,
                    ),
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }

  void _handleRecordingButtonTap(AudioProvider audioProvider) async {
    switch (audioProvider.recordingState) {
      case RecordingState.idle:
        final success = await audioProvider.startRecording();
        if (!success && mounted) {
          _showPermissionDialog();
        }
        break;
      case RecordingState.recording:
        await audioProvider.stopRecording();
        break;
      case RecordingState.paused:
        // 일시정지 상태에서는 녹음 재개 (향후 구현 가능)
        break;
    }
  }

  IconData _getButtonIcon(RecordingState state) {
    switch (state) {
      case RecordingState.idle:
        return Icons.mic;
      case RecordingState.recording:
        return Icons.stop;
      case RecordingState.paused:
        return Icons.play_arrow;
    }
  }

  Color _getButtonColor(RecordingState state) {
    switch (state) {
      case RecordingState.idle:
        return Theme.of(context).colorScheme.primary;
      case RecordingState.recording:
        return const Color(0xFFEF4444); // Red
      case RecordingState.paused:
        return const Color(0xFFF59E0B); // Orange
    }
  }

  Gradient _getButtonGradient(RecordingState state) {
    final color = _getButtonColor(state);
    return LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        color,
        color.withOpacity(0.8),
      ],
    );
  }

  void _showPermissionDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('권한 필요'),
        content: const Text(
          '음성을 녹음하려면 마이크 권한이 필요합니다.\n'
          '설정에서 권한을 허용해주세요.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('확인'),
          ),
        ],
      ),
    );
  }
}
