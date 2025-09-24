import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/audio_provider.dart';
import '../providers/file_manager_provider.dart';
import '../providers/instagram_reels_provider.dart';
import '../widgets/recording_button.dart';
import '../widgets/audio_player_widget.dart';
import '../widgets/audio_controls_widget.dart';
import '../widgets/audio_waveform_widget.dart';
import '../widgets/playback_control_buttons.dart';
import '../services/share_service.dart';
import '../services/app_share_handler.dart';
import '../services/instagram_service.dart';
import 'file_list_screen.dart';
import 'instagram_reels_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    // 앱 시작 시 저장된 파일들 로드 및 공유받은 데이터 처리
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<FileManagerProvider>().loadSavedFiles();
      _handleInitialSharedData();
    });
  }

  /// 앱 시작 시 공유받은 데이터 처리
  Future<void> _handleInitialSharedData() async {
    try {
      final shareHandler = AppShareHandler();
      String? savedPath = await shareHandler.handleInitialSharedData();
      
      if (savedPath != null) {
        // 릴스 정보를 InstagramReelsProvider에 추가
        await _addReelToProvider(savedPath);
        
        // 성공 메시지 표시
        _showSuccessDialog('인스타그램 릴스가 성공적으로 가져와졌습니다!');
        
        // 파일 목록 새로고침
        context.read<FileManagerProvider>().loadSavedFiles();
      }
    } catch (e) {
      debugPrint('초기 공유 데이터 처리 오류: $e');
    }
  }

  /// 릴스를 Provider에 추가
  Future<void> _addReelToProvider(String audioFilePath) async {
    try {
      final reelsProvider = context.read<InstagramReelsProvider>();
      final instagramService = InstagramService();
      
      // 임시로 더미 데이터 사용 (실제로는 공유받은 URL에서 추출)
      final dummyUrl = 'https://instagram.com/reel/dummy_${DateTime.now().millisecondsSinceEpoch}';
      final metadata = await instagramService.extractReelMetadata(dummyUrl);
      
      await reelsProvider.addReel(
        originalUrl: dummyUrl,
        audioFilePath: audioFilePath,
        title: metadata['title'],
        thumbnailUrl: metadata['thumbnailUrl'],
        duration: metadata['duration'],
        description: metadata['description'],
      );
    } catch (e) {
      debugPrint('릴스 Provider 추가 오류: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Reverse Mic',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 24,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.video_library_outlined),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const InstagramReelsScreen(),
                ),
              );
            },
            tooltip: 'Instagram 릴스',
          ),
          IconButton(
            icon: const Icon(Icons.folder_outlined),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const FileListScreen(),
                ),
              );
            },
            tooltip: '저장된 파일',
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () {
              // TODO: 설정 화면으로 이동
            },
            tooltip: '설정',
          ),
        ],
      ),
      body: Consumer<AudioProvider>(
        builder: (context, audioProvider, child) {
          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  // 메인 녹음 영역
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // 오디오 파형 시각화 (마이크 버튼 위)
                        AudioWaveformWidget(
                          height: 140,
                          showPitchInfo: true,
                          showTimeLabels: true,
                        ),
                        
                        const SizedBox(height: 20),
                        
                        // 재생 컨트롤 버튼들
                        PlaybackControlButtons(
                          buttonSize: 120,
                          spacing: 40,
                        ),
                        
                        const SizedBox(height: 24),
                        
                        // 녹음 버튼
                        RecordingButton(),
                        
                        const SizedBox(height: 32),
                        
                        // 오디오 플레이어 (녹음 후 표시)
                        if (audioProvider.currentAudioFile != null)
                          AudioPlayerWidget(),
                        
                        const SizedBox(height: 24),
                        
                        // 오디오 컨트롤 (재생 중일 때 표시)
                        if (audioProvider.currentAudioFile != null)
                          AudioControlsWidget(),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }





  void _showSaveDialog(AudioProvider audioProvider) {
    final TextEditingController nameController = TextEditingController(
      text: audioProvider.currentAudioFile?.name ?? '새 녹음',
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('파일 저장'),
        content: TextField(
          controller: nameController,
          decoration: const InputDecoration(
            labelText: '파일 이름',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소'),
          ),
          ElevatedButton(
            onPressed: () async {
              final name = nameController.text.trim();
              if (name.isNotEmpty) {
                final success = await audioProvider.saveCurrentAudio(name);
                if (success && mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('파일이 저장되었습니다.')),
                  );
                  // 파일 목록 새로고침
                  context.read<FileManagerProvider>().loadSavedFiles();
                }
              }
            },
            child: const Text('저장'),
          ),
        ],
      ),
    );
  }

  void _shareCurrentFile(AudioProvider audioProvider) {
    final fileManager = context.read<FileManagerProvider>();
    if (audioProvider.currentAudioFile != null) {
      fileManager.shareFile(audioProvider.currentAudioFile!);
    }
  }

  /// 인스타그램 릴스 가져오기 처리
  Future<void> _handleInstagramReelsImport() async {
    try {
      // 로딩 다이얼로그 표시
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const AlertDialog(
          content: Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 16),
              Text('인스타그램 릴스 처리 중...'),
            ],
          ),
        ),
      );

      final shareService = ShareService();
      
      // 클립보드에서 텍스트 가져오기
      String? clipboardText = await shareService.getClipboardText();
      
      if (clipboardText == null || clipboardText.isEmpty) {
        Navigator.pop(context); // 로딩 다이얼로그 닫기
        _showErrorDialog('클립보드가 비어있습니다.\n인스타그램에서 릴스를 공유한 후 다시 시도해주세요.');
        return;
      }

      // 인스타그램 URL 확인
      String? instagramUrl = shareService.extractInstagramUrl(clipboardText);
      
      if (instagramUrl == null) {
        Navigator.pop(context); // 로딩 다이얼로그 닫기
        _showErrorDialog('인스타그램 릴스 URL을 찾을 수 없습니다.\n올바른 릴스 링크를 공유해주세요.');
        return;
      }

      if (!shareService.isValidInstagramReelsUrl(instagramUrl)) {
        Navigator.pop(context); // 로딩 다이얼로그 닫기
        _showErrorDialog('릴스 URL이 아닙니다.\n인스타그램 릴스를 공유해주세요.');
        return;
      }

      // 오디오 추출 및 저장
      String? savedPath = await shareService.handleSharedContent(clipboardText);
      
      Navigator.pop(context); // 로딩 다이얼로그 닫기
      
      if (savedPath != null) {
        // 성공 메시지 표시
        _showSuccessDialog('인스타그램 릴스 오디오가 성공적으로 저장되었습니다!');
        
        // 파일 목록 새로고침
        context.read<FileManagerProvider>().loadSavedFiles();
      } else {
        _showErrorDialog('오디오 추출에 실패했습니다.\n다시 시도해주세요.');
      }
      
    } catch (e) {
      Navigator.pop(context); // 로딩 다이얼로그 닫기
      _showErrorDialog('오류가 발생했습니다: ${e.toString()}');
    }
  }

  /// 성공 다이얼로그 표시
  void _showSuccessDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green),
            SizedBox(width: 8),
            Text('성공'),
          ],
        ),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('확인'),
          ),
        ],
      ),
    );
  }

  /// 오류 다이얼로그 표시
  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.error, color: Colors.red),
            SizedBox(width: 8),
            Text('오류'),
          ],
        ),
        content: Text(message),
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
