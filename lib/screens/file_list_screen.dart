import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/file_manager_provider.dart';
import '../models/audio_file_model.dart';
import '../widgets/file_list_item.dart';

class FileListScreen extends StatefulWidget {
  const FileListScreen({super.key});

  @override
  State<FileListScreen> createState() => _FileListScreenState();
}

class _FileListScreenState extends State<FileListScreen> {
  final TextEditingController _searchController = TextEditingController();
  bool _isSelectionMode = false;
  final Set<AudioFileModel> _selectedFiles = {};

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      context.read<FileManagerProvider>().setSearchQuery(_searchController.text);
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
        title: _isSelectionMode
            ? Text('${_selectedFiles.length}개 선택됨')
            : const Text('저장된 파일'),
        actions: [
          if (_isSelectionMode) ...[
            IconButton(
              icon: const Icon(Icons.share),
              onPressed: _selectedFiles.isNotEmpty ? _shareSelectedFiles : null,
              tooltip: '선택한 파일 공유',
            ),
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: _selectedFiles.isNotEmpty ? _deleteSelectedFiles : null,
              tooltip: '선택한 파일 삭제',
            ),
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: _exitSelectionMode,
              tooltip: '선택 모드 종료',
            ),
          ] else ...[
            IconButton(
              icon: const Icon(Icons.search),
              onPressed: _showSearchDialog,
              tooltip: '검색',
            ),
            PopupMenuButton<SortOrder>(
              icon: const Icon(Icons.sort),
              onSelected: (order) {
                context.read<FileManagerProvider>().setSortOrder(order);
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: SortOrder.dateNewest,
                  child: Text('최신 순'),
                ),
                const PopupMenuItem(
                  value: SortOrder.dateOldest,
                  child: Text('오래된 순'),
                ),
                const PopupMenuItem(
                  value: SortOrder.nameAZ,
                  child: Text('이름 순 (A-Z)'),
                ),
                const PopupMenuItem(
                  value: SortOrder.nameZA,
                  child: Text('이름 순 (Z-A)'),
                ),
                const PopupMenuItem(
                  value: SortOrder.duration,
                  child: Text('재생 시간 순'),
                ),
              ],
            ),
          ],
        ],
      ),
      body: Consumer<FileManagerProvider>(
        builder: (context, fileManager, child) {
          if (fileManager.isLoading) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          final files = fileManager.savedFiles;

          if (files.isEmpty) {
            return _buildEmptyState();
          }

          return Column(
            children: [
              // 검색 바 (검색어가 있을 때만 표시)
              if (fileManager.searchQuery.isNotEmpty)
                _buildSearchBar(fileManager),

              // 파일 통계
              _buildFileStats(fileManager),

              // 파일 목록
              Expanded(
                child: ListView.builder(
                  itemCount: files.length,
                  itemBuilder: (context, index) {
                    final file = files[index];
                    final isSelected = _selectedFiles.contains(file);

                    return FileListItem(
                      audioFile: file,
                      isSelected: isSelected,
                      isSelectionMode: _isSelectionMode,
                      onTap: () => _handleFileTap(file),
                      onLongPress: () => _handleFileLongPress(file),
                      onSelectionChanged: (selected) {
                        setState(() {
                          if (selected) {
                            _selectedFiles.add(file);
                          } else {
                            _selectedFiles.remove(file);
                          }
                        });
                      },
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: _isSelectionMode
          ? null
          : FloatingActionButton(
              onPressed: () {
                // TODO: 파일 가져오기 기능
              },
              child: const Icon(Icons.add),
              tooltip: '파일 가져오기',
            ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.folder_open,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            '저장된 파일이 없습니다',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '메인 화면에서 음성을 녹음하고 저장해보세요',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.mic),
            label: const Text('녹음하러 가기'),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar(FileManagerProvider fileManager) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: '파일 이름 검색...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                    fileManager.clearSearch();
                  },
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFileStats(FileManagerProvider fileManager) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Row(
        children: [
          Expanded(
            child: _buildStatItem(
              '파일 수',
              '${fileManager.fileCount}개',
              Icons.folder,
            ),
          ),
          Expanded(
            child: _buildStatItem(
              '총 용량',
              fileManager.formattedStorageUsed,
              Icons.storage,
            ),
          ),
          Expanded(
            child: _buildStatItem(
              '총 재생시간',
              fileManager.formattedTotalDuration,
              Icons.access_time,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, size: 20, color: Colors.grey[600]),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  void _handleFileTap(AudioFileModel file) {
    if (_isSelectionMode) {
      setState(() {
        if (_selectedFiles.contains(file)) {
          _selectedFiles.remove(file);
        } else {
          _selectedFiles.add(file);
        }
      });
    } else {
      // TODO: 파일 재생 화면으로 이동
    }
  }

  void _handleFileLongPress(AudioFileModel file) {
    if (!_isSelectionMode) {
      setState(() {
        _isSelectionMode = true;
        _selectedFiles.add(file);
      });
    }
  }

  void _exitSelectionMode() {
    setState(() {
      _isSelectionMode = false;
      _selectedFiles.clear();
    });
  }

  void _shareSelectedFiles() {
    final fileManager = context.read<FileManagerProvider>();
    fileManager.shareFiles(_selectedFiles.toList());
    _exitSelectionMode();
  }

  void _deleteSelectedFiles() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('파일 삭제'),
        content: Text('선택한 ${_selectedFiles.length}개의 파일을 삭제하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              final fileManager = context.read<FileManagerProvider>();
              final deletedCount = await fileManager.deleteFiles(_selectedFiles.toList());
              
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('${deletedCount}개 파일이 삭제되었습니다.')),
                );
                _exitSelectionMode();
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Colors.white,
            ),
            child: const Text('삭제'),
          ),
        ],
      ),
    );
  }

  void _showSearchDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('파일 검색'),
        content: TextField(
          controller: _searchController,
          decoration: const InputDecoration(
            hintText: '파일 이름을 입력하세요...',
            border: OutlineInputBorder(),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () {
              _searchController.clear();
              context.read<FileManagerProvider>().clearSearch();
              Navigator.pop(context);
            },
            child: const Text('초기화'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('검색'),
          ),
        ],
      ),
    );
  }
}
