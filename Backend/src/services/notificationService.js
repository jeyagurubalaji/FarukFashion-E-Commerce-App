const nodemailer = require('nodemailer');
const axios = require('axios');

const appName = 'Faruk Fashion';
const supportPhone = process.env.SUPPORT_PHONE || '6369456650';
const sellerPhone = process.env.SELLER_PHONE || '6369456650';
const sellerEmail = process.env.SELLER_EMAIL || 'jgbalajinfinity006@gmail.com';

let transporter;
function getTransporter() {
  if (!transporter) {
    transporter = nodemailer.createTransport({
      host: process.env.MAIL_HOST || 'smtp.gmail.com',
      port: Number(process.env.MAIL_PORT) || 587,
      secure: false,
      auth: {
        user: process.env.MAIL_USER,
        pass: process.env.MAIL_PASS,
      },
    });
  }
  return transporter;
}

function normalizePhone(phone) {
  if (!phone) return '';
  let p = String(phone).replace(/\D/g, '');
  if (p.length === 10) p = '91' + p;
  return p;
}

async function sendEmail(to, subject, text) {
  if (!to || !process.env.MAIL_USER) {
    console.log(`[Email SKIP] To: ${to} | ${subject}`);
    return;
  }
  try {
    await getTransporter().sendMail({
      from: process.env.MAIL_FROM || process.env.MAIL_USER,
      to,
      subject,
      text,
    });
    console.log(`[Email] To: ${to} | ${subject}`);
  } catch (e) {
    console.warn(`[Email failed] ${e.message}`);
  }
}

async function sendWhatsApp(phone, message) {
  if (process.env.WHATSAPP_ENABLED !== 'true' || !phone) return;
  const normalized = normalizePhone(phone);
  try {
    if (process.env.WHATSAPP_API_TOKEN && !process.env.WHATSAPP_API_TOKEN.includes('your_')) {
      await axios.post(
        process.env.WHATSAPP_API_URL,
        {
          messaging_product: 'whatsapp',
          to: normalized,
          type: 'text',
          text: { body: message },
        },
        { headers: { Authorization: `Bearer ${process.env.WHATSAPP_API_TOKEN}` } }
      );
    }
    console.log(`[WhatsApp] To: ${normalized} | ${message.slice(0, 60)}...`);
  } catch (e) {
    console.warn(`[WhatsApp failed] ${e.message}`);
  }
}

async function sendSms(phone, message) {
  if (process.env.SMS_ENABLED !== 'true' || !phone) return;
  const normalized = normalizePhone(phone);
  try {
    // MSG91 / generic – log in dev when no real key
    console.log(`[SMS] To: ${normalized} | ${message.slice(0, 60)}...`);
  } catch (e) {
    console.warn(`[SMS failed] ${e.message}`);
  }
}

function buildBuyerMessage(order) {
  let msg = `Thank you for shopping at ${appName}!\n\n`;
  msg += `Order Confirmed: ${order.orderNumber}\n`;
  msg += `Amount: ₹${order.totalAmount}\n`;
  msg += `Payment: ${order.paymentMethod} (${order.paymentStatus})\nItems:\n`;
  (order.items || []).forEach((i) => {
    msg += `• ${i.productName} x${i.quantity} – ₹${i.totalPrice}\n`;
  });
  msg += `\nSupport: ${supportPhone}\nStyle That Speaks – Faruk Fashion`;
  return msg;
}

function buildSellerMessage(order) {
  let msg = `NEW ORDER – ${appName}\n\n`;
  msg += `Order #: ${order.orderNumber}\n`;
  msg += `Customer: ${order.customerName}\nPhone: ${order.customerPhone}\n`;
  msg += `Amount: ₹${order.totalAmount}\nPayment: ${order.paymentMethod}/${order.paymentStatus}\n`;
  (order.items || []).forEach((i) => {
    msg += `• ${i.productName} x${i.quantity}\n`;
  });
  return msg;
}

exports.sendOrderConfirmation = async (order) => {
  const buyerMsg = buildBuyerMessage(order);
  const sellerMsg = buildSellerMessage(order);

  await Promise.all([
    sendWhatsApp(order.customerPhone, buyerMsg),
    sendSms(order.customerPhone, buyerMsg),
    sendEmail(order.customerEmail, `Order Confirmed – ${order.orderNumber}`, buyerMsg),
    sendWhatsApp(sellerPhone, sellerMsg),
    sendSms(sellerPhone, sellerMsg),
    sendEmail(sellerEmail, `New Order – ${order.orderNumber}`, sellerMsg),
  ]);
};

exports.sendOrderStatusUpdate = async (order) => {
  const msg = `Dear ${order.customerName}, your order ${order.orderNumber} is now ${String(order.status).replace(/_/g, ' ')}. Support: ${supportPhone}`;
  await Promise.all([
    sendWhatsApp(order.customerPhone, msg),
    sendSms(order.customerPhone, msg),
    sendEmail(order.customerEmail, `Order Update – ${order.orderNumber}`, msg),
  ]);
};

exports.sendReturnUpdate = async (phone, email, orderNumber, status) => {
  const msg = `Faruk Fashion: Return for order ${orderNumber} is now ${String(status).replace(/_/g, ' ')}. Support: ${supportPhone}`;
  await Promise.all([
    sendWhatsApp(phone, msg),
    sendSms(phone, msg),
    email ? sendEmail(email, `Return Update – ${orderNumber}`, msg) : Promise.resolve(),
  ]);
};
