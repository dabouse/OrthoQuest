import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/session.dart';
import '../../providers/timer_provider.dart';
import '../../utils/app_theme.dart';
import '../../utils/session_utils.dart';
import 'edit_session_dialog.dart';

/// Affiche un bottom sheet avec les actions disponibles pour une session :
/// modifier ou supprimer. Retourne `true` si la session a été modifiée
/// ou supprimée (pour permettre au caller de rafraîchir son état).
Future<bool?> showSessionActionsSheet(
  BuildContext context,
  WidgetRef ref,
  Session session,
) {
  return showModalBottomSheet<bool>(
    context: context,
    backgroundColor: Colors.transparent,
    builder: (context) => _SessionActionsContent(session: session),
  );
}

class _SessionActionsContent extends ConsumerWidget {
  final Session session;
  const _SessionActionsContent({required this.session});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stickerId = session.stickerId;
    final stickerData = stickerId != null
        ? SessionUtils.stickers[stickerId]
        : null;
    final stickerLabel = stickerData != null
        ? stickerData['label'] as String
        : 'Sans sticker';

    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF0F0F23),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        border: Border(
          top: BorderSide(color: AppTheme.primaryColor, width: 1),
          left: BorderSide(color: AppTheme.primaryColor, width: 0.5),
          right: BorderSide(color: AppTheme.primaryColor, width: 0.5),
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  if (stickerData != null) ...[
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: (stickerData['color'] as Color)
                            .withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: stickerData['color'] as Color,
                          width: 2,
                        ),
                      ),
                      child: Icon(
                        stickerData['icon'] as IconData,
                        color: stickerData['color'] as Color,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                  ],
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          SessionUtils.formatDuration(session.duration),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '$stickerLabel — ${_formatSessionTime(session)}',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.6),
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              _buildAction(
                context: context,
                icon: Icons.edit_rounded,
                label: 'Modifier la session',
                color: AppTheme.primaryColor,
                onTap: () async {
                  Navigator.pop(context);
                  final edited = await showDialog<bool>(
                    context: context,
                    builder: (_) => EditSessionDialog(session: session),
                  );
                  if (edited == true && context.mounted) {
                    Navigator.maybePop(context);
                  }
                },
              ),
              const SizedBox(height: 12),
              _buildAction(
                context: context,
                icon: Icons.delete_rounded,
                label: 'Supprimer la session',
                color: AppTheme.errorColor,
                onTap: () => _confirmDelete(context, ref),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAction({
    required BuildContext context,
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(width: 16),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: AppTheme.errorColor),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                'Supprimer cette session ?',
                style: TextStyle(color: Colors.white, fontSize: 18),
              ),
            ),
          ],
        ),
        content: Text(
          'La session de ${SessionUtils.formatDuration(session.duration)} sera supprimée '
          'et l\'XP sera recalculée. Cette action est irréversible.',
          style: TextStyle(color: Colors.white.withValues(alpha: 0.8)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(dialogContext);
              if (session.id != null) {
                await ref
                    .read(timerProvider.notifier)
                    .deleteSession(session.id!);
              }
              if (context.mounted) {
                Navigator.pop(context, true);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.errorColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
  }

  String _formatSessionTime(Session s) {
    final start = s.startTime;
    final end = s.endTime;
    final datePart =
        '${start.day.toString().padLeft(2, '0')}/${start.month.toString().padLeft(2, '0')}';
    final startPart =
        '${start.hour.toString().padLeft(2, '0')}:${start.minute.toString().padLeft(2, '0')}';
    if (end != null) {
      final endPart =
          '${end.hour.toString().padLeft(2, '0')}:${end.minute.toString().padLeft(2, '0')}';
      return '$datePart  $startPart → $endPart';
    }
    return '$datePart  $startPart';
  }
}
