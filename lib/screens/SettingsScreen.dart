import 'package:flutter/material.dart';
import '../services/StorageService.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _wifiOnlyUpload = false;

  @override
  void initState() {
    super.initState();
    _loadSetting();
  }

  Future<void> _loadSetting() async {
    final wifiOnly = await StorageService.getWiFiOnlyUploadSetting();
    setState(() => _wifiOnlyUpload = wifiOnly);
  }

  Future<void> _onToggle(bool value) async {
    await StorageService.setWiFiOnlyUploadSetting(value);
    setState(() => _wifiOnlyUpload = value);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        children: [
          SwitchListTile(
            title: const Text('Wi-Fi Only Data Upload'),
            subtitle: const Text('Enable to upload data only over Wi-Fi'),
            value: _wifiOnlyUpload,
            onChanged: _onToggle,
            activeColor: Colors.green,
            activeTrackColor: Colors.greenAccent,
          ),
        ],
      ),
    );
  }
}
