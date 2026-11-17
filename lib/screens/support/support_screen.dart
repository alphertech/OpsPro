import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../config/app_info.dart';
import '../../config/terms_and_conditions.dart';
import '../../widgets/app_drawer.dart';
import '../../widgets/custom_app_bar.dart';

class SupportScreen extends StatelessWidget {
  const SupportScreen({super.key});

  Future<void> _launchUrl(BuildContext context, String url) async {
    final uri = Uri.parse(url.startsWith('http') ? url : 'https://$url');
    try {
      if (Platform.isWindows) {
        await Process.run('rundll32', ['url.dll,FileProtocolHandler', uri.toString()]);
      } else if (Platform.isMacOS) {
        await Process.run('open', [uri.toString()]);
      } else if (Platform.isLinux) {
        await Process.run('xdg-open', [uri.toString()]);
      }
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not open link: $url')),
      );
    }
  }

  void _copyToClipboard(BuildContext context, String value, String label) {
    Clipboard.setData(ClipboardData(text: value));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$label copied to clipboard'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;

    return Scaffold(
      appBar: const CustomAppBar(title: 'Support & About'),
      drawer: const AppDrawer(currentRoute: '/support'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 800),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildHeader(primaryColor),
                const SizedBox(height: 20),
                _buildQuickContacts(context),
                const SizedBox(height: 16),
                _buildAboutCard(context),
                const SizedBox(height: 16),
                _buildCompanyInfo(context),
                const SizedBox(height: 16),
                _buildDeveloperSection(context),
                const SizedBox(height: 16),
                _buildTermsSection(context),
                const SizedBox(height: 16),
                _buildVersionInfo(context),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(Color primaryColor) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            primaryColor,
            primaryColor.withValues(alpha: 0.85),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(Icons.hub_outlined, size: 40, color: Colors.white),
          ),
          const SizedBox(height: 16),
          const Text(
            AppInfo.appName,
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Version ${AppInfo.appVersionDisplay}',
            style: TextStyle(
              fontSize: 14,
              color: Colors.white.withValues(alpha: 0.9),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'by ${AppInfo.company}',
            style: TextStyle(
              fontSize: 13,
              color: Colors.white.withValues(alpha: 0.8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickContacts(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.contact_support_outlined,
                    color: Theme.of(context).primaryColor, size: 22),
                const SizedBox(width: 10),
                const Text(
                  'Quick Contact',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: _ContactButton(
                    icon: Icons.phone_outlined,
                    label: 'Call Helpline',
                    value: AppInfo.helpdeskPhoneDisplay,
                    color: Colors.green,
                    onTap: () => _copyToClipboard(
                        context, AppInfo.helpdeskPhone, 'Phone number'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _ContactButton(
                    icon: Icons.email_outlined,
                    label: 'Email Support',
                    value: AppInfo.supportEmail,
                    color: Colors.blue,
                    onTap: () => _copyToClipboard(
                        context, AppInfo.supportEmail, 'Email'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _ContactButton(
              icon: Icons.language_outlined,
              label: 'Official Website',
              value: AppInfo.websiteDisplay,
              color: Colors.deepPurple,
              onTap: () => _launchUrl(context, AppInfo.website),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAboutCard(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.info_outline,
                    color: Theme.of(context).primaryColor, size: 22),
                const SizedBox(width: 10),
                const Text(
                  'About Plexus',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 14),
            const Text(
              AppInfo.appLongDescription,
              style: TextStyle(fontSize: 14, height: 1.6, color: Colors.black87),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCompanyInfo(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.business_outlined,
                    color: Theme.of(context).primaryColor, size: 22),
                const SizedBox(width: 10),
                const Text(
                  'Company Information',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildInfoRow(context, Icons.business, 'Company', AppInfo.company),
            const Divider(height: 20),
            _buildInfoRow(
              context,
              Icons.language,
              'Website',
              AppInfo.websiteDisplay,
              isUrl: true,
              url: AppInfo.website,
            ),
            const Divider(height: 20),
            _buildInfoRow(
              context,
              Icons.email,
              'Support Email',
              AppInfo.supportEmail,
              isCopyable: true,
              copyValue: AppInfo.supportEmail,
            ),
            const Divider(height: 20),
            _buildInfoRow(context, Icons.phone, 'Helpline', AppInfo.helpdeskPhoneDisplay,
                isCopyable: true, copyValue: AppInfo.helpdeskPhone),
            const Divider(height: 20),
            _buildInfoRow(context, Icons.verified_user, 'License', AppInfo.license),
          ],
        ),
      ),
    );
  }

  Widget _buildDeveloperSection(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.code_outlined,
                    color: Theme.of(context).primaryColor, size: 22),
                const SizedBox(width: 10),
                const Text(
                  'Development Team',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...AppInfo.developers.map(
              (dev) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 20,
                        backgroundColor: Theme.of(context)
                            .primaryColor
                            .withValues(alpha: 0.12),
                        child: Icon(Icons.person_outline,
                            color: Theme.of(context).primaryColor, size: 20),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              dev.name,
                              style: const TextStyle(
                                  fontWeight: FontWeight.w600, fontSize: 14),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              dev.role,
                              style: TextStyle(
                                  fontSize: 12, color: Colors.grey[600]),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.copy, size: 18),
                        onPressed: () =>
                            _copyToClipboard(context, dev.email, 'Email'),
                        tooltip: 'Copy email',
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTermsSection(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          leading: Icon(Icons.shield_outlined,
              color: Theme.of(context).primaryColor),
          title: const Text(
            'Terms and Conditions',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          subtitle: Text(
            TermsAndConditions.title,
            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
          ),
          children: [
            Container(
              constraints: const BoxConstraints(maxHeight: 350),
              margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: const SingleChildScrollView(
                child: Text(
                  TermsAndConditions.licenseText,
                  style: TextStyle(fontSize: 12, height: 1.6),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVersionInfo(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.verified_outlined,
                    color: Theme.of(context).primaryColor, size: 22),
                const SizedBox(width: 10),
                const Text(
                  'Version Information',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildInfoRow(context, Icons.tag, 'Version', AppInfo.appVersion),
            const Divider(height: 20),
            _buildInfoRow(context, Icons.build, 'Build', '${AppInfo.appBuildNumber}'),
            const Divider(height: 20),
            _buildInfoRow(context, Icons.verified, 'License', AppInfo.license),
            const Divider(height: 20),
            _buildInfoRow(
              context,
              Icons.devices,
              'Platform',
              'Desktop (Windows/macOS/Linux)',
            ),
            const SizedBox(height: 16),
            Center(
              child: Text(
                AppInfo.copyrightLine(),
                style: TextStyle(fontSize: 12, color: Colors.grey[500]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(
    BuildContext context,
    IconData icon,
    String label,
    String value, {
    bool isUrl = false,
    String? url,
    bool isCopyable = false,
    String? copyValue,
  }) {
    final color = Theme.of(context).colorScheme.primary;
    final copyText = copyValue ?? value;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(fontSize: 11, color: Colors.grey[500]),
              ),
              const SizedBox(height: 3),
              isUrl
                  ? InkWell(
                      onTap: () => _launchUrl(context, url ?? value),
                      child: Text(
                        value,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Colors.blue,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    )
                  : Text(
                      value,
                      style: const TextStyle(
                          fontSize: 14, fontWeight: FontWeight.w500),
                    ),
            ],
          ),
        ),
        if (isCopyable)
          IconButton(
            icon: const Icon(Icons.copy, size: 18),
            onPressed: () => _copyToClipboard(context, copyText, label),
            tooltip: 'Copy $label',
            visualDensity: VisualDensity.compact,
          ),
      ],
    );
  }
}

class _ContactButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  final VoidCallback onTap;

  const _ContactButton({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color.withValues(alpha: 0.08),
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 8),
              Flexible(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: TextStyle(
                          fontSize: 11, color: Colors.grey[600]),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      value,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: color,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
