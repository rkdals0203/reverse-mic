import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/audio_provider.dart';

class AudioWaveformWidget extends StatefulWidget {
  final double height;
  final Color? waveformColor;
  final Color? backgroundColor;
  final Color? playheadColor;
  final bool showTimeLabels;
  final bool showPitchInfo;

  const AudioWaveformWidget({
    super.key,
    this.height = 120,
    this.waveformColor,
    this.backgroundColor,
    this.playheadColor,
    this.showTimeLabels = true,
    this.showPitchInfo = true,
  });

  @override
  State<AudioWaveformWidget> createState() => _AudioWaveformWidgetState();
}

class _AudioWaveformWidgetState extends State<AudioWaveformWidget>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;
  List<double> _waveformData = [];
  double _currentPosition = 0.0;
  bool _isPlaying = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 100),
      vsync: this,
    );
    _animation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _generateWaveformData();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  /// 더미 파형 데이터 생성 (실제로는 오디오 파일에서 추출)
  void _generateWaveformData() {
    final random = math.Random();
    _waveformData = List.generate(200, (index) {
      // 실제 오디오 파형을 시뮬레이션
      double baseValue = math.sin(index * 0.1) * 0.3;
      double noise = (random.nextDouble() - 0.5) * 0.2;
      double envelope = math.exp(-index / 100.0); // 감쇠 효과
      
      return (baseValue + noise) * envelope;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AudioProvider>(
      builder: (context, audioProvider, child) {
        _updatePlaybackState(audioProvider);
        
        return Container(
          height: widget.height,
          decoration: BoxDecoration(
            color: widget.backgroundColor ?? 
                   Theme.of(context).colorScheme.surfaceVariant.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.1),
            ),
          ),
          child: Column(
            children: [
              if (widget.showPitchInfo) _buildPitchInfo(context, audioProvider),
              Expanded(
                child: _buildWaveform(context, audioProvider),
              ),
              if (widget.showTimeLabels) _buildTimeLabels(context, audioProvider),
            ],
          ),
        );
      },
    );
  }

  /// 피치 정보 표시
  Widget _buildPitchInfo(BuildContext context, AudioProvider audioProvider) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildPitchIndicator(audioProvider.pitchShift),
          _buildCurrentFileInfo(audioProvider),
        ],
      ),
    );
  }

  /// 피치 인디케이터
  Widget _buildPitchIndicator(double pitchShift) {
    final isShifted = pitchShift != 0.0;
    final pitchText = pitchShift > 0 
        ? '+${pitchShift.toStringAsFixed(1)}' 
        : pitchShift.toStringAsFixed(1);
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isShifted 
            ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.1)
            : Theme.of(context).colorScheme.surfaceVariant,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isShifted 
              ? Theme.of(context).colorScheme.primary
              : Theme.of(context).colorScheme.outline.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.tune,
            size: 16,
            color: isShifted 
                ? Theme.of(context).colorScheme.primary
                : Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: 4),
          Text(
            '피치: $pitchText',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: isShifted 
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  /// 현재 파일 정보
  Widget _buildCurrentFileInfo(AudioProvider audioProvider) {
    final fileName = audioProvider.currentAudioFile?.name ?? '선택된 파일 없음';
    return Expanded(
      child: Text(
        fileName,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
        overflow: TextOverflow.ellipsis,
        textAlign: TextAlign.right,
      ),
    );
  }

  /// 파형 표시
  Widget _buildWaveform(BuildContext context, AudioProvider audioProvider) {
    return GestureDetector(
      onTapDown: (details) => _handleTap(details, audioProvider),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        child: CustomPaint(
          size: Size.infinite,
          painter: WaveformPainter(
            waveformData: _waveformData,
            currentPosition: _currentPosition,
            waveformColor: widget.waveformColor ?? 
                          Theme.of(context).colorScheme.primary,
            playheadColor: widget.playheadColor ?? 
                         Theme.of(context).colorScheme.onSurface,
            backgroundColor: Colors.transparent,
          ),
        ),
      ),
    );
  }

  /// 탭 처리 (시크 기능)
  void _handleTap(TapDownDetails details, AudioProvider audioProvider) {
    final RenderBox box = context.findRenderObject() as RenderBox;
    final localPosition = details.localPosition;
    final relativePosition = localPosition.dx / box.size.width;
    
    setState(() {
      _currentPosition = relativePosition.clamp(0.0, 1.0);
    });
    
    // TODO: 실제 오디오 시크 구현
    debugPrint('시크 위치: ${(_currentPosition * 100).toStringAsFixed(1)}%');
  }

  /// 시간 라벨
  Widget _buildTimeLabels(BuildContext context, AudioProvider audioProvider) {
    final currentTime = _formatTime(_currentPosition * 120); // 더미 총 시간
    final totalTime = _formatTime(120); // 더미 총 시간
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            currentTime,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(
            totalTime,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  /// 시간 포맷팅
  String _formatTime(double seconds) {
    final minutes = (seconds / 60).floor();
    final remainingSeconds = (seconds % 60).floor();
    final milliseconds = ((seconds % 1) * 10).floor();
    
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}.$milliseconds';
  }

  /// 재생 상태 업데이트
  void _updatePlaybackState(AudioProvider audioProvider) {
    final isPlaying = audioProvider.isPlaying;
    final position = audioProvider.currentPosition;
    final duration = audioProvider.duration;
    
    if (isPlaying != _isPlaying) {
      setState(() {
        _isPlaying = isPlaying;
      });
      
      if (isPlaying) {
        _animationController.repeat();
      } else {
        _animationController.stop();
      }
    }
    
    if (duration.inMilliseconds > 0) {
      setState(() {
        _currentPosition = position.inMilliseconds / duration.inMilliseconds;
      });
    }
  }
}

/// 파형 그리기 페인터
class WaveformPainter extends CustomPainter {
  final List<double> waveformData;
  final double currentPosition;
  final Color waveformColor;
  final Color playheadColor;
  final Color backgroundColor;

  WaveformPainter({
    required this.waveformData,
    required this.currentPosition,
    required this.waveformColor,
    required this.playheadColor,
    required this.backgroundColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = waveformColor
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round;

    final playheadPaint = Paint()
      ..color = playheadColor
      ..strokeWidth = 2.0;

    // 파형 그리기
    final barWidth = size.width / waveformData.length;
    final centerY = size.height / 2;
    final maxHeight = size.height * 0.8;

    for (int i = 0; i < waveformData.length; i++) {
      final x = i * barWidth + barWidth / 2;
      final amplitude = waveformData[i].abs();
      final barHeight = amplitude * maxHeight;
      
      // 현재 재생 위치에 따른 색상 변화
      final isBeforePlayhead = i < currentPosition * waveformData.length;
      final alpha = isBeforePlayhead ? 1.0 : 0.6;
      
      paint.color = waveformColor.withValues(alpha: alpha);
      
      canvas.drawLine(
        Offset(x, centerY - barHeight / 2),
        Offset(x, centerY + barHeight / 2),
        paint,
      );
    }

    // 플레이헤드 그리기
    final playheadX = currentPosition * size.width;
    canvas.drawLine(
      Offset(playheadX, 0),
      Offset(playheadX, size.height),
      playheadPaint,
    );

    // 플레이헤드 위에 시간 표시 말풍선
    if (currentPosition > 0 && currentPosition < 1) {
      _drawTimeTooltip(canvas, playheadX, size.height);
    }
  }

  /// 시간 툴팁 그리기
  void _drawTimeTooltip(Canvas canvas, double x, double height) {
    final tooltipPaint = Paint()
      ..color = playheadColor.withValues(alpha: 0.9)
      ..style = PaintingStyle.fill;

    final textPainter = TextPainter(
      text: TextSpan(
        text: _formatTime(currentPosition * 120), // 더미 시간
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
      textDirection: TextDirection.ltr,
    );

    textPainter.layout();

    final tooltipWidth = textPainter.width + 16;
    final tooltipHeight = textPainter.height + 8;
    final tooltipX = (x - tooltipWidth / 2).clamp(0, height - tooltipWidth);
    final tooltipY = 8;

    // 말풍선 모양 그리기
    final path = Path();
    path.moveTo(tooltipX.toDouble(), (tooltipY + tooltipHeight).toDouble());
    path.lineTo((tooltipX + tooltipWidth / 2 - 4).toDouble(), (tooltipY + tooltipHeight).toDouble());
    path.lineTo((tooltipX + tooltipWidth / 2).toDouble(), (tooltipY + tooltipHeight + 4).toDouble());
    path.lineTo((tooltipX + tooltipWidth / 2 + 4).toDouble(), (tooltipY + tooltipHeight).toDouble());
    path.lineTo((tooltipX + tooltipWidth).toDouble(), (tooltipY + tooltipHeight).toDouble());
    path.lineTo((tooltipX + tooltipWidth).toDouble(), tooltipY.toDouble());
    path.lineTo(tooltipX.toDouble(), tooltipY.toDouble());
    path.close();

    canvas.drawPath(path, tooltipPaint);

    // 텍스트 그리기
    textPainter.paint(
      canvas,
      Offset(tooltipX + 8, tooltipY + 4),
    );
  }

  /// 시간 포맷팅
  String _formatTime(double seconds) {
    final minutes = (seconds / 60).floor();
    final remainingSeconds = (seconds % 60).floor();
    final milliseconds = ((seconds % 1) * 10).floor();
    
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}.$milliseconds';
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return oldDelegate is! WaveformPainter ||
           oldDelegate.currentPosition != currentPosition ||
           oldDelegate.waveformData != waveformData;
  }
}
