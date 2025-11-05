const nodemailer = require('nodemailer');

// Create a reusable transporter object using SMTP transport
// We use environment variables to keep credentials secure.
const transporter = nodemailer.createTransport({
  host: process.env.EMAIL_HOST,   // e.g., 'smtp.gmail.com'
  port: process.env.EMAIL_PORT,   // e.g., 465 (SSL) or 587 (TLS)
  secure: process.env.EMAIL_PORT == 465, // true for 465, false for other ports
  auth: {
    user: process.env.EMAIL_USER, // Your email address
    pass: process.env.EMAIL_PASS, // Your email password (or App Password for Gmail)
  },
});

/**
 * Sends an email using the pre-configured transporter.
 * @param {object} options - Email options.
 * @param {string} options.to - Recipient's email address.
 * @param {string} options.subject - Subject line.
 * @param {string} options.text - Plain text body.
 * @param {string} options.html - HTML body.
 */
const sendEmail = async ({ to, subject, text, html }) => {
  if (!process.env.EMAIL_USER) {
    console.error('EMAIL_USER is not set. Email not sent.');
    console.log('Email Body (for debugging):', text);
    // In development, you might want to just log the email instead of failing
    // For production, this should ideally throw an error.
    return Promise.resolve(); // Pretend it sent successfully for dev
  }

  try {
    const info = await transporter.sendMail({
      from: `"Yoga App" <${process.env.EMAIL_USER}>`, // Sender address
      to: to,         // List of receivers
      subject: subject, // Subject line
      text: text,     // Plain text body
      html: html,     // HTML body
    });

    console.log('Message sent: %s', info.messageId);
    return info;
  } catch (error) {
    console.error('Error sending email:', error);
    throw new Error('Failed to send email.');
  }
};

module.exports = { sendEmail };