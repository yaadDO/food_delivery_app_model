const { onCall, HttpsError } = require('firebase-functions/v2/https');
const { onDocumentCreated } = require('firebase-functions/v2/firestore');
const { onRequest } = require('firebase-functions/v2/https');
const { initializeApp } = require('firebase-admin/app');
const { getFirestore, FieldValue } = require('firebase-admin/firestore');
const { getMessaging } = require('firebase-admin/messaging');
const Stripe = require('stripe');
const logger = require('firebase-functions/logger');
const functions = require('firebase-functions');

// Initialize Firebase
initializeApp();

// Stripe Payment Intent Function
exports.createPaymentIntent = onCall(async (data, context) => {
  try {
    // Get Stripe secret from Firebase config - FIXED KEY NAME
    const stripeSecret = functions.config().stripe?.secret_key;
    if (!stripeSecret) {
      throw new Error('Stripe secret key not configured');
    }

    const stripe = new Stripe(stripeSecret);

    // Validate user authentication
    if (!context.auth) {
      throw new HttpsError(
        'unauthenticated',
        'Authentication required'
      );
    }

    // Validate input
    if (!data.amount || !data.currency) {
      throw new HttpsError(
        'invalid-argument',
        'Missing required fields'
      );
    }

    // Create payment intent
    const paymentIntent = await stripe.paymentIntents.create({
      amount: data.amount,
      currency: data.currency,
      automatic_payment_methods: { enabled: true }
    });

    return { clientSecret: paymentIntent.client_secret };

  } catch (error) {
    logger.error('Stripe Error:', error);
    throw new HttpsError('internal', error.message);
  }
});

exports.sendChatNotification = onDocumentCreated(
  'chats/{userId}/messages/{messageId}',
  async (event) => {
    try {
      const message = event.data.data();
      const userId = event.params.userId;

      if (!message.sender || !message.text) {
        logger.error('Missing required message fields');
        return null;
      }

      const isAdminMessage = message.sender === 'admin';
      const notificationPromises = [];
      const firestore = getFirestore();

      if (isAdminMessage) {
        const userDoc = await firestore.collection('users').doc(userId).get();
        const userToken = userDoc.data()?.fcmToken;

        if (userToken) {
          notificationPromises.push(sendNotification(
            userToken,
            'New Support Message',
            message.text,
            { type: 'chat', userId }
          ));
        }
      } else {
        const adminsSnapshot = await firestore.collection('users')
          .where('isAdmin', '==', true)
          .get();

        adminsSnapshot.forEach((adminDoc) => {
          const adminToken = adminDoc.data().fcmToken;
          if (adminToken) {
            notificationPromises.push(sendNotification(
              adminToken,
              'New Customer Message',
              message.text,
              { type: 'chat', userId }
            ));
          }
        });
      }

      await Promise.all(notificationPromises);
      return null;

    } catch (error) {
      logger.error('Full error:', error);
      return null;
    }
  }
);

async function sendNotification(token, title, body, data) {
  const messaging = getMessaging();
  const firestore = getFirestore();
  const payload = {
    notification: { title, body },
    data: {
      ...data,
      click_action: 'FLUTTER_NOTIFICATION_CLICK'
    },
    token
  };

  try {
    await firestore.collection('notifications').add({
      userId: data.userId,
      title: title,
      body: body,
      type: 'chat',
      chatUserId: data.userId,
      timestamp: FieldValue.serverTimestamp()
    });

    const response = await messaging.send(payload);
    logger.log('Successfully sent notification:', response);
    return response;
  } catch (error) {
    logger.error('Error sending notification:', error);
    return null;
  }
}

// Use the onRequest imported at the top
exports.healthCheck = onRequest((req, res) => {
  res.status(200).send('OK');
});
