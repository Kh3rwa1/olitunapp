import 'package:flutter/material.dart';
import '../admin_media_state.dart';
import '../../widgets/admin_form_widgets.dart';

class MediaFilterBar extends StatelessWidget {
  final MediaType selectedType;
  final ValueChanged<MediaType> onTypeSelected;

  const MediaFilterBar({
    super.key,
    required this.selectedType,
    required this.onTypeSelected,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          AdminFilterChip(
            label: 'All',
            icon: Icons.grid_view_rounded,
            selected: selectedType == MediaType.all,
            onTap: () => onTypeSelected(MediaType.all),
          ),
          const SizedBox(width: 8),
          AdminFilterChip(
            label: 'Images',
            icon: Icons.image_rounded,
            selected: selectedType == MediaType.image,
            onTap: () => onTypeSelected(MediaType.image),
          ),
          const SizedBox(width: 8),
          AdminFilterChip(
            label: 'Audio',
            icon: Icons.audiotrack_rounded,
            selected: selectedType == MediaType.audio,
            onTap: () => onTypeSelected(MediaType.audio),
          ),
          const SizedBox(width: 8),
          AdminFilterChip(
            label: 'Video',
            icon: Icons.videocam_rounded,
            selected: selectedType == MediaType.video,
            onTap: () => onTypeSelected(MediaType.video),
          ),
        ],
      ),
    );
  }
}
