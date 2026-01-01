import 'package:flutter/material.dart';

enum MansisDrawerPage { documents, pic, typeDocument }

class MansisDrawer extends StatelessWidget {
  final String userName;
  final bool isAdmin;
  final MansisDrawerPage selectedPage;
  final VoidCallback onNavigateHome;
  final VoidCallback onNavigateDocuments;
  final VoidCallback? onNavigatePic;
  final VoidCallback? onNavigateTypeDocument;

  const MansisDrawer({
    super.key,
    required this.userName,
    required this.isAdmin,
    required this.selectedPage,
    required this.onNavigateHome,
    required this.onNavigateDocuments,
    this.onNavigatePic,
    this.onNavigateTypeDocument,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final surfaceColor = isDark ? colorScheme.surface : Colors.white;

    return Drawer(
      child: Container(
        color: surfaceColor,
        child: Column(
          children: [
            _buildDrawerHeader(theme, surfaceColor: surfaceColor, isDark: isDark),
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  _buildSectionTitle('Navigasi', theme),
                  _buildSidebarItem(
                    context,
                    assetPath: 'assets/images/home.png',
                    title: 'Beranda',
                    isSelected: false,
                    onTap: () {
                      Navigator.pop(context);
                      onNavigateHome();
                    },
                  ),
                  _buildSidebarItem(
                    context,
                    assetPath: 'assets/images/mansis/documents_logo.png',
                    title: 'Dokumen',
                    isSelected: selectedPage == MansisDrawerPage.documents,
                    onTap: () {
                      Navigator.pop(context);
                      onNavigateDocuments();
                    },
                  ),
                  if (isAdmin) ...[
                    const SizedBox(height: 12),
                    _buildSectionTitle('Data Master', theme),
                    _buildSidebarItem(
                      context,
                      assetPath: 'assets/images/mansis/pic_logo.png',
                      title: 'Daftar PIC',
                      isSelected: selectedPage == MansisDrawerPage.pic,
                      onTap: () {
                        Navigator.pop(context);
                        onNavigatePic?.call();
                      },
                    ),
                    _buildSidebarItem(
                      context,
                      assetPath: 'assets/images/mansis/list_documents.png',
                      title: 'Tipe Dokumen',
                      isSelected: selectedPage == MansisDrawerPage.typeDocument,
                      onTap: () {
                        Navigator.pop(context);
                        onNavigateTypeDocument?.call();
                      },
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawerHeader(
      ThemeData theme, {
        required Color surfaceColor,
        required bool isDark,
      }) {
    return SafeArea(
      bottom: false,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        decoration: BoxDecoration(
          color: surfaceColor,
          border: Border(
            bottom: BorderSide(
              color: isDark
                  ? theme.colorScheme.surface
                  : theme.colorScheme.surfaceVariant,
            ),
          ),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 28,
              backgroundColor:
              theme.colorScheme.primary.withOpacity(isDark ? 0.18 : 0.12),
              child: Padding(
                padding: const EdgeInsets.all(6.0),
                child: Image.asset(
                  'assets/images/logo.png',
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) => Icon(
                    Icons.account_circle,
                    size: 36,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    userName,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onSurface,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Manajemen Sistem MUJ',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.hintColor,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 6),
      child: Text(
        title,
        style: theme.textTheme.labelLarge?.copyWith(
          fontWeight: FontWeight.bold,
          color: theme.hintColor,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildSidebarItem(
      BuildContext context, {
        required String assetPath,
        required String title,
        required bool isSelected,
        required VoidCallback onTap,
      }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final color = isSelected ? theme.colorScheme.onSurface : theme.hintColor;
    final bgColor = isSelected
        ? theme.colorScheme.surfaceVariant.withOpacity(isDark ? 0.5 : 0.8)
        : Colors.transparent;

    return Material(
      color: bgColor,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Image.asset(
                assetPath,
                width: 22,
                height: 22,
                color: color,
                errorBuilder: (ctx, e, st) =>
                    Icon(Icons.image_not_supported, color: color, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  title,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
              ),
              if (isSelected) Icon(Icons.check_circle, size: 18, color: color),
            ],
          ),
        ),
      ),
    );
  }
}