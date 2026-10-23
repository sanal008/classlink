/// Email configuration settings
/// Update these values with your actual SMTP credentials

class EmailConfig {
  // Gmail SMTP settings (example)
  static const String smtpHost = 'smtp.gmail.com';
  static const int smtpPort = 587;
  // TODO: fill these in locally with your SMTP credentials before building.
  // Do NOT commit real credentials to version control.
  static const String smtpUsername = ''; // e.g. your Gmail address
  static const String smtpPassword = ''; // e.g. Gmail App Password
  static const String defaultSender = 'noreply@classlink+.app';
  
  // Alternative SMTP providers examples:
  // Outlook: smtp.office365.com:587
  // Yahoo: smtp.mail.yahoo.com:587
  // Custom SMTP: your-provider.com:587
  
  /// Call this method during app initialization to configure email service
  static void initialize() {
    // EmailService will use these values directly from EmailConfig
    // No need to call configureSmtp as EmailService already references EmailConfig
  }
}
