import 'package:flutter/material.dart';

/// Reusable User Avatar Widget with Google profile photo support
/// Displays actual profile photo if available, falls back to initials
class UserAvatarWidget extends StatelessWidget {
  final String? photoUrl;
  final String userName;
  final double size;
  final VoidCallback? onTap;

  const UserAvatarWidget({
    super.key,
    this.photoUrl,
    required this.userName,
    this.size = 80,
    this.onTap,
  });

  /// Get initials from user name
  String _getInitials() {
    if (userName.isEmpty) return '?';
    final names = userName.split(' ');
    String initials = names[0][0].toUpperCase();
    if (names.length > 1) {
      initials += names[1][0].toUpperCase();
    }
    return initials;
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 4),
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha((0.1 * 255).round()),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: photoUrl != null && photoUrl!.isNotEmpty
            ? _buildPhotoAvatar()
            : _buildInitialsAvatar(),
      ),
    );
  }

  /// Build avatar with network image (Google profile photo)
  Widget _buildPhotoAvatar() {
    return ClipOval(
      child: Image.network(
        photoUrl!,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return _buildInitialsAvatar();
        },
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Center(
            child: CircularProgressIndicator(
              value: loadingProgress.expectedTotalBytes != null
                  ? loadingProgress.cumulativeBytesLoaded /
                        loadingProgress.expectedTotalBytes!
                  : null,
            ),
          );
        },
      ),
    );
  }

  /// Build avatar with user initials fallback
  Widget _buildInitialsAvatar() {
    return Center(
      child: Text(
        _getInitials(),
        style: TextStyle(
          fontSize: size * 0.5,
          color: Colors.blue.shade700,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
