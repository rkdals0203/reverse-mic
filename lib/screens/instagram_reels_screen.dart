import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/instagram_reels_provider.dart';
import '../providers/audio_provider.dart';
import '../models/instagram_reel_model.dart';
import '../widgets/reel_list_item.dart';

class InstagramReelsScreen extends StatefulWidget {
  const InstagramReelsScreen({super.key});

  @override
  State<InstagramReelsScreen> createState() => _InstagramReelsScreenState();
}

class _InstagramReelsScreenState extends State<InstagramReelsScreen> {
  final TextEditingController _searchController = TextEditingController();
  ReelSortType _currentSortType = ReelSortType.newest;
  List<String> _selectedReels = [];
  bool _isSelectionMode = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<InstagramReelsProvider>().loadReels();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isSelectionMode ? '${_selectedReels.length}개 선택됨' : 'Instagram 릴스'),
        actions: _buildAppBarActions(),
      ),
      body: Consumer<InstagramReelsProvider>(
        builder: (context, reelsProvider, child) {
          if (reelsProvider.isLoading) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (reelsProvider.error != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 64,
                    color: Theme.of(context).colorScheme.error,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    reelsProvider.error!,
                    style: Theme.of(context).textTheme.bodyLarge,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => reelsProvider.loadReels(),
                    child: const Text('다시 시도'),
                  ),
                ],
              ),
            );
          }

          if (reelsProvider.reels.isEmpty) {
            return _buildEmptyState();
          }

          return Column(
            children: [
              _buildSearchAndSortBar(),
              Expanded(
                child: _buildReelsList(reelsProvider),
              ),
            ],
          );
        },
      ),
      floatingActionButton: _isSelectionMode
          ? FloatingActionButton.extended(
              onPressed: _selectedReels.isNotEmpty ? _deleteSelectedReels : null,
              icon: const Icon(Icons.delete),
              label: Text('${_selectedReels.length}개 삭제'),
              backgroundColor: Theme.of(context).colorScheme.error,
            )
          : null,
    );
  }

  /// AppBar 액션 버튼들
  List<Widget> _buildAppBarActions() {
    if (_isSelectionMode) {
      return [
        IconButton(
          icon: const Icon(Icons.close),
          onPressed: _exitSelectionMode,
          tooltip: '선택 모드 종료',
        ),
      ];
    }

    return [
      IconButton(
        icon: const Icon(Icons.sort),
        onPressed: _showSortDialog,
        tooltip: '정렬',
      ),
      IconButton(
        icon: const Icon(Icons.select_all),
        onPressed: _enterSelectionMode,
        tooltip: '선택 모드',
      ),
    ];
  }

  /// 빈 상태 위젯
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.video_library_outlined,
            size: 80,
            color: Theme.of(context).colorScheme.outline,
          ),
          const SizedBox(height: 16),
          Text(
            '아직 저장된 릴스가 없습니다',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            '인스타그램에서 릴스를 공유하면\n여기에 표시됩니다',
            style: Theme.of(context).textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back),
            label: const Text('돌아가기'),
          ),
        ],
      ),
    );
  }

  /// 검색 및 정렬 바
  Widget _buildSearchAndSortBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: '릴스 검색...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                        setState(() {});
                      },
                    )
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onChanged: (value) => setState(() {}),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Text(
                '총 ${context.watch<InstagramReelsProvider>().totalCount}개',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const Spacer(),
              Text(
                '정렬: ${_getSortTypeText(_currentSortType)}',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// 릴스 목록
  Widget _buildReelsList(InstagramReelsProvider reelsProvider) {
    final searchQuery = _searchController.text;
    final filteredReels = searchQuery.isEmpty
        ? reelsProvider.reels
        : reelsProvider.searchReels(searchQuery);

    if (filteredReels.isEmpty && searchQuery.isNotEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off,
              size: 64,
              color: Theme.of(context).colorScheme.outline,
            ),
            const SizedBox(height: 16),
            Text(
              '"$searchQuery"에 대한 검색 결과가 없습니다',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: filteredReels.length,
      itemBuilder: (context, index) {
        final reel = filteredReels[index];
        return ReelListItem(
          reel: reel,
          isSelected: _selectedReels.contains(reel.id),
          isSelectionMode: _isSelectionMode,
          onTap: () => _handleReelTap(reel),
          onLongPress: () => _handleReelLongPress(reel),
          onPlay: () => _playReel(reel),
          onDelete: () => _deleteReel(reel),
        );
      },
    );
  }

  /// 릴스 탭 처리
  void _handleReelTap(InstagramReelModel reel) {
    if (_isSelectionMode) {
      _toggleReelSelection(reel.id);
    } else {
      _playReel(reel);
    }
  }

  /// 릴스 롱프레스 처리
  void _handleReelLongPress(InstagramReelModel reel) {
    if (!_isSelectionMode) {
      _enterSelectionMode();
    }
    _toggleReelSelection(reel.id);
  }

  /// 릴스 재생
  void _playReel(InstagramReelModel reel) {
    final audioProvider = context.read<AudioProvider>();
    // TODO: 릴스 오디오 재생 구현
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${reel.title} 재생 시작'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  /// 릴스 삭제
  void _deleteReel(InstagramReelModel reel) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('릴스 삭제'),
        content: Text('${reel.title}을(를) 삭제하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              context.read<InstagramReelsProvider>().deleteReel(reel.id);
            },
            child: const Text('삭제'),
          ),
        ],
      ),
    );
  }

  /// 선택된 릴스들 삭제
  void _deleteSelectedReels() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('릴스 삭제'),
        content: Text('선택된 ${_selectedReels.length}개의 릴스를 삭제하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              context.read<InstagramReelsProvider>().deleteMultipleReels(_selectedReels);
              _exitSelectionMode();
            },
            child: const Text('삭제'),
          ),
        ],
      ),
    );
  }

  /// 릴스 선택 토글
  void _toggleReelSelection(String reelId) {
    setState(() {
      if (_selectedReels.contains(reelId)) {
        _selectedReels.remove(reelId);
      } else {
        _selectedReels.add(reelId);
      }
    });
  }

  /// 선택 모드 진입
  void _enterSelectionMode() {
    setState(() {
      _isSelectionMode = true;
      _selectedReels.clear();
    });
  }

  /// 선택 모드 종료
  void _exitSelectionMode() {
    setState(() {
      _isSelectionMode = false;
      _selectedReels.clear();
    });
  }

  /// 정렬 다이얼로그 표시
  void _showSortDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('정렬 기준'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: ReelSortType.values.map((sortType) {
            return RadioListTile<ReelSortType>(
              title: Text(_getSortTypeText(sortType)),
              value: sortType,
              groupValue: _currentSortType,
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _currentSortType = value;
                  });
                  context.read<InstagramReelsProvider>().sortReels(value);
                  Navigator.pop(context);
                }
              },
            );
          }).toList(),
        ),
      ),
    );
  }

  /// 정렬 타입 텍스트
  String _getSortTypeText(ReelSortType sortType) {
    switch (sortType) {
      case ReelSortType.newest:
        return '최신순';
      case ReelSortType.oldest:
        return '오래된순';
      case ReelSortType.title:
        return '제목순';
      case ReelSortType.duration:
        return '재생시간순';
    }
  }
}
