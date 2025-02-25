import 'package:flutter/material.dart';
import 'conversation_screen.dart';

enum VoiceMode {
  pushToTalk,
  handsFree,
}

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  VoiceMode _selectedMode = VoiceMode.handsFree;
  double _textSize = 0.8;
  bool _autoPlayback = true;
  bool _autoTrigger = true;
  int _triggerSeconds = 5;

  void _handleSave() {
    if (_selectedMode == VoiceMode.pushToTalk) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => const ConversationScreen(
            prompt: '', // Add your initial prompt here
          ),
        ),
      );
    } else {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
          iconTheme: IconThemeData(
    color: Colors.white, //change your color here
  ),
        backgroundColor: Colors.black,
        title: const Text('Settings', style: TextStyle(
          color: Colors.cyan,
        ),
        ),
        centerTitle: true,
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: constraints.maxHeight,
              ),
              child: IntrinsicHeight(
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Voice Mode',
                            style: TextStyle(
                              color: Colors.cyan,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Column(
                            children: [
                              ListTile(
                                title: const Text(
                                  'Push to talk',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                  ),
                                ),
                                subtitle: const Text(
                                  'Press the botton to ask questions',
                                  style: TextStyle(
                                    color: Colors.grey,
                                    fontSize: 14,
                                  ),
                                ),
                                trailing: Radio<VoiceMode>(
                                  value: VoiceMode.pushToTalk,
                                  groupValue: _selectedMode,
                                  onChanged: (VoiceMode? value) {
                                    if (value != null) {
                                      setState(() => _selectedMode = value);
                                    }
                                  },
                                  fillColor: MaterialStateProperty.resolveWith(
                                    (states) => states.contains(MaterialState.selected)
                                        ? Colors.cyan
                                        : Colors.grey,
                                  ),
                                ),
                              ),
                              ListTile(
                                title: const Text(
                                  'Hands free',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                  ),
                                ),
                                subtitle: const Text(
                                  'Automatic speech detection',
                                  style: TextStyle(
                                    color: Colors.grey,
                                    fontSize: 14,
                                  ),
                                ),
                                trailing: Radio<VoiceMode>(
                                  value: VoiceMode.handsFree,
                                  groupValue: _selectedMode,
                                  onChanged: (VoiceMode? value) {
                                    if (value != null) {
                                      setState(() => _selectedMode = value);
                                    }
                                  },
                                  fillColor: MaterialStateProperty.resolveWith(
                                    (states) => states.contains(MaterialState.selected)
                                        ? Colors.cyan
                                        : Colors.grey,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Checkbox(
                                  value: _autoTrigger,
                                  onChanged: (value) {
                                    if (value != null) {
                                      setState(() => _autoTrigger = value);
                                    }
                                  },
                                  activeColor: Colors.cyan,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Wrap(
                                    crossAxisAlignment: WrapCrossAlignment.center,
                                    children: [
                                      const Text(
                                        'After I finish speaking, automatically trigger enter after ',
                                        style: TextStyle(color: Colors.white, fontSize: 14),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 8, vertical: 4),
                                        margin: const EdgeInsets.symmetric(horizontal: 4),
                                        decoration: BoxDecoration(
                                          border: Border.all(color: Colors.cyan, width: 2),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: SizedBox(
                                          width: 50,
                                          child: TextFormField(
                                            initialValue: '$_triggerSeconds',
                                            keyboardType: TextInputType.number,
                                            style: const TextStyle(
                                                color: Colors.white, fontSize: 14),
                                            textAlign: TextAlign.center,
                                            decoration: const InputDecoration(
                                              border: InputBorder.none,
                                              contentPadding:
                                                  EdgeInsets.symmetric(vertical: 8),
                                              isDense: true,
                                            ),
                                            onChanged: (value) {
                                              final seconds = int.tryParse(value);
                                              if (seconds != null && seconds > 0) {
                                                setState(() => _triggerSeconds = seconds);
                                              }
                                            },
                                          ),
                                        ),
                                      ),
                                      const Text(
                                        ' second(s)',
                                        style: TextStyle(color: Colors.white, fontSize: 14),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),
                          const Text(
                            'Text size',
                            style: TextStyle(color: Colors.white, fontSize: 16),
                          ),
                          Row(
                            children: [
                              const Text('A', style: TextStyle(color: Colors.white)),
                              Expanded(
                                child: Slider(
                                  value: _textSize,
                                  onChanged: (value) {
                                    setState(() => _textSize = value);
                                  },
                                  activeColor: Colors.blue,
                                ),
                              ),
                              const Text(
                                'A',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 24,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: const [
                                  Text(
                                    'Auto playback',
                                    style: TextStyle(color: Colors.white, fontSize: 16),
                                  ),
                                  Text(
                                    'Automatically read the response aloud\nafter you finish speaking',
                                    style: TextStyle(color: Colors.grey, fontSize: 14),
                                  ),
                                ],
                              ),
                              Switch(
                                value: _autoPlayback,
                                onChanged: (value) {
                                  setState(() => _autoPlayback = value);
                                },
                                activeColor: Colors.blue,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const Expanded(child: SizedBox()),  // This replaces the Spacer
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _handleSave,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                          child: const Text(
                            'SAVE',
                            style: TextStyle(
                              color: Colors.black,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

