import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:package_info_plus/package_info_plus.dart';

class MainMenuScreen extends StatelessWidget {
  const MainMenuScreen({super.key});

  /// Кошелёк поддержки проекта (v1 → v2, без изменений).
  static const _donationAddress =
      'UQApUe-U1E-u8tNQhupN2eP8o3NfXF_4X8J1nas4T_c7_J5N';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Герои — Помощник'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Stack(
          children: [
            Positioned.fill(
              child: Container(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                child: Opacity(
                  opacity: 0.2,
                  child: Image.asset(
                    'assets/faction_background/humans.PNG',
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) =>
                        const SizedBox.shrink(),
                  ),
                ),
              ),
            ),
            Center(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _MenuButton(
                      label: 'Начать игру',
                      onPressed: () => context.push('/faction_choose'),
                    ),
                    const SizedBox(height: 20),
                    _MenuButton(
                      label: 'Записи игр',
                      onPressed: () => context.push('/score_history'),
                    ),
                  ],
                ),
              ),
            ),
            Positioned(
              left: 16,
              bottom: 16,
              child: FloatingActionButton(
                onPressed: () {
                  showModalBottomSheet<void>(
                    context: context,
                    builder: (context) => const _DonationModal(
                      address: _donationAddress,
                    ),
                  );
                },
                tooltip: 'Поддержать проект',
                child: const Icon(Icons.volunteer_activism),
              ),
            ),
            const Positioned(
              right: 16,
              bottom: 16,
              child: _AppVersionText(),
            ),
          ],
        ),
      ),
    );
  }
}

class _MenuButton extends StatelessWidget {
  const _MenuButton({required this.label, required this.onPressed});

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 60,
      child: FilledButton(
        style: FilledButton.styleFrom(
          textStyle: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        onPressed: onPressed,
        child: Text(label),
      ),
    );
  }
}

class _AppVersionText extends StatefulWidget {
  const _AppVersionText();

  @override
  State<_AppVersionText> createState() => _AppVersionTextState();
}

class _AppVersionTextState extends State<_AppVersionText> {
  final Future<PackageInfo> _packageInfo = PackageInfo.fromPlatform();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<PackageInfo>(
      future: _packageInfo,
      builder: (context, snapshot) {
        final version = snapshot.data?.version;
        if (version == null) return const SizedBox.shrink();
        return Text(
          'v$version',
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
            fontSize: 12,
          ),
        );
      },
    );
  }
}

/// Модалка поддержки проекта: адрес кошелька и копирование в буфер (из v1).
class _DonationModal extends StatelessWidget {
  const _DonationModal({required this.address});

  final String address;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Поддержать проект',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            const Text(
              'Вы можете поддержать проект, сделав пожертвование '
              'на кошелёк в сети TON:',
            ),
            const SizedBox(height: 16),
            _WalletInfo(address: address),
            const SizedBox(height: 24),
            Center(
              child: FilledButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Закрыть'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WalletInfo extends StatelessWidget {
  const _WalletInfo({required this.address});

  final String address;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'TON:',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        SelectableText(
          address,
          style: const TextStyle(fontFamily: 'monospace'),
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          child: FilledButton(
            onPressed: () {
              Clipboard.setData(ClipboardData(text: address));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Адрес скопирован в буфер обмена'),
                  duration: Duration(seconds: 2),
                ),
              );
              Navigator.pop(context);
            },
            child: const Text('Скопировать адрес'),
          ),
        ),
      ],
    );
  }
}
