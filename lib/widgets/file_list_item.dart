import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:provider/provider.dart';
import '../models/audio_file_model.dart';
import '../providers/file_manager_provider.dart';

class FileListItem extends StatelessWidget {
  final AudioFileModel audioFile;
  final bool isSelected;
  final bool isSelectionMode;
  final VoidCallback onTap;
  final VoidCallback onLongPress;
  final ValueChanged<bool> onSelectionChanged;

  const FileListItem({
    super.key,
    required this.audioFile,
    required this.isSelected,
    required this.isSelectionMode,
    required this.onTap,
    required this.onLongPress,
    required this.onSelectionChanged,
  });

  @override
  Widget build(BuildContext context) {
    if (isSelectionMode) {
      return _buildSelectionModeItem(context);
    } else {
      return _buildNormalModeItem(context);
    }
  }

  Widget _buildSelectionModeItem(BuildContext context) {
    return ListTile(
      leading: Checkbox(
        value: isSelected,
        onChanged: (value) => onSelectionChanged(value ?? false),
      ),
      title: Text(
        audioFile.name,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(
        '${audioFile.formattedDuration} • ${audioFile.formattedDate}',
        style: TextStyle(
          fontSize: 12,
          color: Colors.grey[600],
        ),
      ),
      trailing: Text(
        audioFile.formattedSize,
        style: TextStyle(
          fontSize: 12,
          color: Colors.grey[600],
        ),
      ),
      onTap: onTap,
      selected: isSelected,
    );
  }

  Widget _buildNormalModeItem(BuildContext context) {
    return Slidable(
      key: ValueKey(audioFile.path),
      endActionPane: ActionPane(
        motion: const ScrollMotion(),
        children: [
          SlidableAction(
            onPressed: (_) => _shareFile(context),
            backgroundColor: Theme.of(context).colorScheme.primary,
            foregroundColor: Colors.white,
            icon: Icons.share,
            label: '공유',
          ),
          SlidableAction(
            onPressed: (_) => _renameFile(context),
            backgroundColor: Colors.orange,
            foregroundColor: Colors.white,
            icon: Icons.edit,
            label: '이름변경',
          ),
          SlidableAction(
            onPressed: (_) => _deleteFile(context),
            backgroundColor: Theme.of(context).colorScheme.error,
            foregroundColor: Colors.white,
            icon: Icons.delete,
            label: '삭제',
          ),
        ],
      ),
      child: ListTile(
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            Icons.audiotrack,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
        title: Text(
          audioFile.name,
          style: const TextStyle(
            fontWeight: FontWeight.w500,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              audioFile.formattedDuration,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
            Text(
              audioFile.formattedDate,
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              audioFile.formattedSize,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 4),
            Icon(
              Icons.more_horiz,
              size: 16,
              color: Colors.grey[400],
            ),
          ],
        ),
        onTap: onTap,
        onLongPress: onLongPress,
      ),
    );
  }

  void _shareFile(BuildContext context) {
    final fileManager = context.read<FileManagerProvider>();
    fileManager.shareFile(audioFile);
  }

  void _renameFile(BuildContext context) {
    final TextEditingController nameController = TextEditingController(
      text: audioFile.name,
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('파일 이름 변경'),
        content: TextField(
          controller: nameController,
          decoration: const InputDecoration(
            labelText: '새 파일 이름',
            border: OutlineInputBorder(),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소'),
          ),
          ElevatedButton(
            onPressed: () async {
              final newName = nameController.text.trim();
              if (newName.isNotEmpty && newName != audioFile.name) {
                final fileManager = context.read<FileManagerProvider>();
                final success = await fileManager.renameFile(audioFile, newName);
                
                if (context.mounted) {
                  Navigator.pop(context);
                  if (success) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('파일 이름이 변경되었습니다.')),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('파일 이름 변경에 실패했습니다.'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              } else {
                Navigator.pop(context);
              }
            },
            child: const Text('변경'),
          ),
        ],
      ),
    );
  }

  void _deleteFile(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('파일 삭제'),
        content: Text('\"${audioFile.name}\" 파일을 삭제하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              final fileManager = context.read<FileManagerProvider>();
              final success = await fileManager.deleteFile(audioFile);
              
              if (context.mounted) {
                if (success) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('파일이 삭제되었습니다.')),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('파일 삭제에 실패했습니다.'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
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
}
