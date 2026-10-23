const functions = require('firebase-functions');
const admin = require('firebase-admin');
const sgMail = require('@sendgrid/mail');

admin.initializeApp();

// Sends an email when an email_requests node is created
exports.sendEmailOnRequest = functions.database
  .ref('/email_requests/{id}')
  .onCreate(async (snapshot, context) => {
    const data = snapshot.val();
    if (!data) return null;

    const to = data.to;
    const subject = data.subject || 'Notification';
    const body = data.body || '';

    // Read SendGrid API key and optional from-address from functions config
    const sendgridKey = functions.config().sendgrid && functions.config().sendgrid.key;
    const fromAddress = functions.config().sendgrid && functions.config().sendgrid.from;

    if (!sendgridKey) {
      await snapshot.ref.update({ status: 'error', error: 'missing_sendgrid_key' });
      console.error('SendGrid key is missing (set with `firebase functions:config:set sendgrid.key="KEY"`)');
      return null;
    }

    sgMail.setApiKey(sendgridKey);

    const msg = {
      to,
      from: fromAddress || 'noreply@classlink.app',
      subject,
      text: body,
      html: body.replace(/\n/g, '<br/>'),
    };

    try {
      await sgMail.send(msg);
      await snapshot.ref.update({ status: 'sent', sentAt: new Date().toISOString() });
      console.log(`Email sent to ${to}`);
    } catch (err) {
      console.error('Error sending email', err);
      await snapshot.ref.update({ status: 'error', error: err && err.toString ? err.toString() : String(err) });
    }

    return null;
  });