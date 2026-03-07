import 'package:flutter/material.dart';
import '../../config/app_colors.dart';
import '../../config/app_constants.dart';
import '../../models/contact.dart';

/// 联系人列表项卡片
class ContactCard extends StatelessWidget {
  final Contact contact;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  const ContactCard({
    Key? key,
    required this.contact,
    this.onTap,
    this.onLongPress,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    print('🧩 构建联系人卡片: ${contact.name} (ID: ${contact.id})');
    return Card(
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.xs,
          ),
          child: SizedBox(
            height: 75,
            child: Row(
              children: [
                // 头像
                _buildAvatar(),
                const SizedBox(width: AppSpacing.md),
                // 联系人信息
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 名字
                      Text(
                        contact.name,
                        style: const TextStyle(
                          fontSize: AppFontSize.titleMedium,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      // 电话
                      if (contact.phone != null)
                        Text(
                          contact.phone!,
                          style: const TextStyle(
                            fontSize: AppFontSize.bodySmall,
                            color: AppColors.outline,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      const SizedBox(height: 2),
                      // 标签
                      if (contact.tags.isNotEmpty) _buildTags(),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                // 更多按钮
                IconButton(
                  icon: const Icon(Icons.more_vert),
                  onPressed: () {},
                  iconSize: 20,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// 构建头像
  Widget _buildAvatar() {
    return CircleAvatar(
      radius: 24,
      backgroundColor: AppColors.primary,
      child: contact.avatar != null
          ? Image.network(contact.avatar!)
          : Text(
              contact.name.isNotEmpty ? contact.name[0].toUpperCase() : '?',
              style: const TextStyle(
                color: Colors.white,
                fontSize: AppFontSize.titleMedium,
                fontWeight: FontWeight.bold,
              ),
            ),
    );
  }

  /// 构建标签
  Widget _buildTags() {
    // 最多显示2个标签
    final displayTags = contact.tags.take(2).toList();
    final remaining = contact.tags.length > 2 ? contact.tags.length - 2 : 0;

    return Wrap(
      spacing: AppSpacing.xs,
      runSpacing: AppSpacing.xs,
      children: [
        ...displayTags.map(
          (tag) => _buildTagChip(tag),
        ),
        if (remaining > 0)
          _buildTagChip('+$remaining'),
      ],
    );
  }

  /// 构建标签芯片
  Widget _buildTagChip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: AppColors.secondary.withOpacity(0.2),
        borderRadius: BorderRadius.circular(AppRadius.xs),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: AppFontSize.labelSmall,
          color: AppColors.secondary,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
