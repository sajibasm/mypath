import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
    _loadWifiSetting();
  }

  Future<void> _loadWifiSetting() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _wifiOnlyUpload = prefs.getBool('wifiOnlyUpload') ?? false;
    });
  }

  Future<void> _toggleWifiSetting(bool value) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool('wifiOnlyUpload', value);
    setState(() {
      _wifiOnlyUpload = value;
    });
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
            onChanged: _toggleWifiSetting,
            activeColor: Colors.green, // Thumb color when ON
            activeTrackColor: Colors.greenAccent, // Track color when ON
          ),
        ],
      ),
    );
  }
}
