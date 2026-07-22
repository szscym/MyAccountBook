import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  static const _releaseUrl = 'https://github.com/szscym/MyAccountBook/releases';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('关于'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            // App icon and name
            Center(
              child: Column(
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      gradient: LinearGradient(
                        colors: [Colors.teal.shade400, Colors.teal.shade600],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.teal.withValues(alpha: 0.3),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Icon(Icons.account_balance_wallet, color: Colors.white, size: 40),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Money Minder',
                    style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '简洁高效的收支管理',
                    style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'v1.0.1',
                    style: TextStyle(color: theme.colorScheme.outline, fontSize: 12),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // QR code card
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: theme.colorScheme.outlineVariant),
              ),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    Text(
                      '扫码下载 App',
                      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Image.asset(
                        'assets/qr_release.png',
                        width: 200,
                        height: 200,
                        fit: BoxFit.contain,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      '使用手机相机扫描二维码\n进入下载页面安装最新版本',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: theme.colorScheme.onSurfaceVariant,
                        fontSize: 13,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Copy link button
                    OutlinedButton.icon(
                      onPressed: () {
                        Clipboard.setData(const ClipboardData(text: _releaseUrl));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('下载链接已复制到剪贴板'),
                            duration: Duration(seconds: 2),
                          ),
                        );
                      },
                      icon: const Icon(Icons.copy, size: 16),
                      label: const Text('复制下载链接'),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(200, 40),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Instructions
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: theme.colorScheme.outlineVariant),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '安装说明',
                      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    _StepItem(
                      number: '1',
                      text: '扫描上方二维码，进入 GitHub Releases 页面',
                    ),
                    _StepItem(
                      number: '2',
                      text: '在最新的 Release 中找到 app-release.apk',
                    ),
                    _StepItem(
                      number: '3',
                      text: '下载 APK 文件到手机',
                    ),
                    _StepItem(
                      number: '4',
                      text: '在手机上打开 APK 文件，允许「未知来源」安装',
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Version info
            Center(
              child: Text(
                '© 2026 Money Minder',
                style: TextStyle(
                  color: theme.colorScheme.outline,
                  fontSize: 11,
                ),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

class _StepItem extends StatelessWidget {
  final String number;
  final String text;
  const _StepItem({required this.number, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: Colors.teal.shade100,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(number, style: TextStyle(color: Colors.teal.shade700, fontSize: 12, fontWeight: FontWeight.bold)),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(text, style: const TextStyle(fontSize: 14, height: 1.4)),
          ),
        ],
      ),
    );
  }
}
