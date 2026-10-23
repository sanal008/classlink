import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server.dart';
import 'firebase_service.dart';
import 'email_config.dart';

class EmailService {
  // SMTP configuration will use EmailConfig values
  static String _smtpHost = EmailConfig.smtpHost;
  static int _smtpPort = EmailConfig.smtpPort;
  static String _smtpUsername = EmailConfig.smtpUsername;
  static String _smtpPassword = EmailConfig.smtpPassword;
  static String _defaultSender = EmailConfig.defaultSender;

  /// Send email directly using SMTP
  static Future<bool> sendEmail({
    required String to,
    required String subject,
    required String body,
    String? from,
  }) async {
    try {
      // Create SMTP server configuration
      final smtpServer = SmtpServer(
        _smtpHost,
        port: _smtpPort,
        username: _smtpUsername,
        password: _smtpPassword,
        ssl: false,
        allowInsecure: false,
      );

      // Create email message
      final message = Message()
        ..from = Address(from ?? _defaultSender)
        ..recipients.add(to)
        ..subject = subject
        ..text = body
        ..html = body.replaceAll('\n', '<br/>');

      // Send email
      final sendReport = await send(message, smtpServer);
      
      print('Email sent successfully to $to: ${sendReport.toString()}');
      return true;
    } catch (e) {
      print('Failed to send email to $to: $e');
      return false;
    }
  }

  /// Send kickout notification email to user
  static Future<bool> sendKickoutNotification({
    required String userEmail,
    required String conferenceID,
    String? studentId,
  }) async {
    final subject = 'Removed from class $conferenceID';
    final body = 'You were removed from the meeting due to absence on ${DateTime.now().toLocal()}.';
    
    return await sendEmail(
      to: userEmail,
      subject: subject,
      body: body,
      from: _defaultSender,
    );
  }

  /// Fetch user email from Firebase and send kickout notification
  static Future<bool> fetchAndSendKickoutNotification({
    required String userId,
    required String conferenceID,
  }) async {
    try {
      // Fetch user email from Firebase
      final userSnapshot = await FirebaseService().getUserData(userId);
      
      if (userSnapshot == null) {
        print('User not found: $userId');
        return false;
      }

      final userEmail = userSnapshot['email'] as String?;
      if (userEmail == null || userEmail.isEmpty) {
        print('User email not found for: $userId');
        return false;
      }

      // Send kickout notification
      return await sendKickoutNotification(
        userEmail: userEmail,
        conferenceID: conferenceID,
        studentId: userId,
      );
    } catch (e) {
      print('Error in fetchAndSendKickoutNotification: $e');
      return false;
    }
  }

  /// Configure SMTP settings (call this during app initialization)
  static void configureSmtp({
    required String username,
    required String password,
    String host = 'smtp.gmail.com',
    int port = 587,
    String defaultSender = 'noreply@classlink+.app',
  }) {
    _smtpUsername = username;
    _smtpPassword = password;
    _smtpHost = host;
    _smtpPort = port;
    _defaultSender = defaultSender;
    
    print('SMTP configured with username: $username');
  }
}
