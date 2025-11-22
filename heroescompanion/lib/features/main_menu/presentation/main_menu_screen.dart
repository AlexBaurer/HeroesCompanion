import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:package_info_plus/package_info_plus.dart';

class MainMenuScreen extends StatefulWidget {
  const MainMenuScreen({super.key});

  @override
  State<MainMenuScreen> createState() => _MainMenuScreenState();
}

class _MainMenuScreenState extends State<MainMenuScreen> {
  String _version = '';

  @override
  void initState() {
    super.initState();
    _getAppVersion();
  }

  Future<void> _getAppVersion() async {
    final packageInfo = await PackageInfo.fromPlatform();
    setState(() {
      _version = 'v${packageInfo.version}';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Heroes Companion'),
        centerTitle: true,
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: Stack(
          children: [
            // Background image with semi-transparency
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: const Color.fromARGB(255, 109, 109, 109),
                ),
                child: Opacity(
                  opacity: 0.2,
                  child: Image.asset(
                    'assets/faction_background/humans.PNG',
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),
            // Main content
            Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: double.infinity,
                      height: 60,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: () {
                          // Navigate to faction choose menu
                          Navigator.pushNamed(context, '/faction_choose_menu');
                        },
                        child: const Text(
                          'Начать игру',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      height: 60,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: () {
                          // Navigate to score history screen
                          Navigator.pushNamed(context, '/score_history');
                        },
                        child: const Text(
                          'Записи игр',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Settings button at bottom right
            Positioned(
              bottom: 16,
              left: 16,
              child: FloatingActionButton(
                onPressed: () {
                  showModalBottomSheet(
                    context: context,
                    builder: (BuildContext context) {
                      return const DonationModal();
                    },
                  );
                },
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                child: const Icon(Icons.volunteer_activism),
              ),
            ),
            // Version text at bottom right
            Positioned(
              bottom: 16,
              right: 16,
              child: Text(
                _version,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                ),
              ),
            ),
            // Positioned(
            //   bottom: 16,
            //   right: 16,
            //   child: FloatingActionButton(
            //     onPressed: () {
            //       // TODO: Implement settings functionality
            //     },
            //     backgroundColor: Colors.blue,
            //     foregroundColor: Colors.white,
            //     child: const Icon(Icons.settings),
            //   ),
            // ),
          ],
        ),
      ),
    );
  }
}

class DonationModal extends StatelessWidget {
  const DonationModal({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.all(16),
        height: 400,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Поддержать проект',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Вы можете поддержать проект, сделав пожертвование на кошелёк в сети TON:',
            ),
            const SizedBox(height: 16),
            const WalletInfo(
              currency: 'TON',
              address: 'UQApUe-U1E-u8tNQhupN2eP8o3NfXF_4X8J1nas4T_c7_J5N',
            ),
            const Spacer(),
            Center(
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: const Text('Закрыть'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class WalletInfo extends StatelessWidget {
  final String currency;
  final String address;

  const WalletInfo({
    super.key,
    required this.currency,
    required this.address,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$currency:',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        SelectableText(
          address,
          style: const TextStyle(fontFamily: 'monospace'),
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
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
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
            ),
            child: const Text('Скопировать адрес'),
          ),
        ),
      ],
    );
  }
}