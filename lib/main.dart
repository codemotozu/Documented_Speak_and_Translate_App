// lib/main.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'features/translation/presentation/screens/prompt_screen.dart';
import 'features/translation/presentation/screens/settings_screen.dart';
import 'features/translation/presentation/screens/conversation_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    const ProviderScope(
      child: MyApp(),
    ),
  );
}
 
class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'AI Chat Assistant ',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const PromptScreen(),
        '/settings': (context) => const SettingsScreen(),
      },
      onGenerateRoute: (settings) {
        if (settings.name == '/conversation') {
          final prompt = settings.arguments as String;
          return MaterialPageRoute(
            builder: (context) => ConversationScreen(prompt: prompt),
          );
        }
        return null;
      },
    );
  }
}


// ? IF I SAY "OPEN" THEN IT WILL NAVIGATE TO SECOND PAGE

// import 'dart:io';

// import 'package:flutter/material.dart';
// import 'package:permission_handler/permission_handler.dart';
// import 'package:porcupine_flutter/porcupine.dart';
// import 'package:speech_to_text/speech_to_text.dart' as stt;
// import 'package:porcupine_flutter/porcupine_error.dart';
// import 'package:porcupine_flutter/porcupine_manager.dart';

// void main() => runApp(MyApp());

// class MyApp extends StatelessWidget {
//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp(
//       home: VoiceControlPage(),
//     );
//   }
// }



// ? IF I SAY "OPEN" THEN IT WILL NAVIGATE TO SECOND PAGE




// class VoiceControlPage extends StatefulWidget {
//   @override
//   _VoiceControlPageState createState() => _VoiceControlPageState();
// }

// class _VoiceControlPageState extends State<VoiceControlPage> {
//   late PorcupineManager _porcupineManager;
//   late stt.SpeechToText _speech;
//   bool _isListening = false;
  
//   @override
//   void initState() {
//     super.initState();
//     _speech = stt.SpeechToText();
//     _initPorcupine();
//   }

// void _initPorcupine() async {
//   try {
//     _porcupineManager = await PorcupineManager.fromBuiltInKeywords(
//       '5Mri+YIkPqfYUP7wiE7/ernliOHgScC4HY6/yXNczTqPX9+/CeivIQ==',
//       [BuiltInKeyword.JARVIS], // Using built-in keywords
//       _wakeWordCallback,
//     );
//     await _porcupineManager.start();
//   } on PorcupineException catch (err) {
//     print("Failed to initialize Porcupine: $err");
//   }
// }

//   void _wakeWordCallback(int keywordIndex) {
//     // This is called when "open mic" is detected
//     _startListening();
//   }

//   void _startListening() async {
//     if (!_isListening) {
//       bool available = await _speech.initialize(
//         onStatus: (status) => print('status: $status'),
//         onError: (error) => print('error: $error'),
//       );

//       if (available) {
//         setState(() => _isListening = true);
//         _speech.listen(
//           onResult: (result) {
//             // Handle speech recognition results
//             if (result.recognizedWords.toLowerCase() == 'open') {
//               Navigator.push(
//                 context,
//                 MaterialPageRoute(builder: (context) => SecondPage()),
//               );
//             }
//           },
//         );
//       }
//     }
//   }

//   @override
//   void dispose() {
//     _porcupineManager?.delete();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       body: Center(
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             Icon(
//               _isListening ? Icons.mic : Icons.mic_none,
//               size: 50,
//             ),
//             SizedBox(height: 20),
//             Text(
//               _isListening 
//                 ? 'Listening...' 
//                 : 'Say "Jarvis" to start listening',
//               style: TextStyle(fontSize: 18),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }


// class SecondPage extends StatelessWidget {
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: Text('Second Page')),
//       body: Center(
//         child: Text('You navigated here using voice command!'),
//       ),
//     );
//   }
// }

