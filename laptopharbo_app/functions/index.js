// index.js
const functions = require("firebase-functions");
const admin = require("firebase-admin");
const nodemailer = require("nodemailer");

admin.initializeApp();

const GMAIL_EMAIL = "lorem.ipsum.sample.email@gmail.com";
const GMAIL_PASSWORD = "tetmxtzkfgkwgpsc";

const transporter = nodemailer.createTransport({
  service: "gmail",
  auth: {
    user: GMAIL_EMAIL,
    pass: GMAIL_PASSWORD,
  },
});

exports.sendOrderEmail = functions.https.onCall(async (data, context) => {
  const { email, name, orderId, status, location, total } = data;

  const mailOptions = {
    from: `Your Store <${GMAIL_EMAIL}>`,
    to: email,
    subject: `Order #${orderId} Update - ${status}`,
    html: `
      <p>Dear ${name},</p>
      <p>Your order <strong>#${orderId}</strong> has been updated to: <strong>${status}</strong>.</p>
      <p><strong>Total:</strong> ${total}</p>
      <p><strong>Location:</strong> ${location}</p>
      <p>Thank you for shopping with us!</p>
    `,
  };

  try {
    await transporter.sendMail(mailOptions);
    return { success: true };
  } catch (error) {
    console.error("Email error:", error);
    return { success: false, error: error.toString() };
  }
});
