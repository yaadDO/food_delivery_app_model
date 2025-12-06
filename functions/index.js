const { onDocumentCreated } = require('firebase-functions/v2/firestore');
const { onRequest } = require('firebase-functions/v2/https');
const { initializeApp } = require('firebase-admin/app');
const { getFirestore, FieldValue } = require('firebase-admin/firestore');
const { getMessaging } = require('firebase-admin/messaging');
const logger = require('firebase-functions/logger');

initializeApp();

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
      const firestore = getFirestore();

      if (isAdminMessage) {
        // Admin sent message → notify USER
        const userDoc = await firestore.collection('users').doc(userId).get();
        const userToken = userDoc.data()?.fcmToken;

        if (userToken) {
          await sendNotification(
            userToken,
            'New Support Message',
            message.text,
            { type: 'chat', userId },
          );
        }
      } else {
        // User sent message → notify ADMINS (excluding the sender)
        const adminsSnapshot = await firestore.collection('users')
          .where('isAdmin', '==', true)
          .get();

        // Filter out current user if they're also an admin
        const notificationPromises = [];
        adminsSnapshot.forEach((adminDoc) => {
          const adminToken = adminDoc.data().fcmToken;
          // Only send if adminToken exists AND it's not the same user
          if (adminToken && adminDoc.id !== userId) {
            notificationPromises.push(sendNotification(
              adminToken,
              'New Customer Message',
              message.text,
              { type: 'chat', userId },
            ));
          }
        });

        await Promise.all(notificationPromises);
      }

      return null;
    } catch (error) {
      logger.error('Full error:', error);
      return null;
    }
  });

async function sendNotification(token, title, body, data) {
  const messaging = getMessaging();
  const firestore = getFirestore();

  const payload = {
    notification: { title, body },
    data: {
      ...data,
      click_action: 'FLUTTER_NOTIFICATION_CLICK',
    },
    token,
  };

  try {
    // Log notification in Firestore
    await firestore.collection('notifications').add({
      userId: data.userId,
      title: title,
      body: body,
      type: 'chat',
      chatUserId: data.userId,
      timestamp: FieldValue.serverTimestamp(),
    });

    const response = await messaging.send(payload);
    logger.log('Successfully sent notification:', response);
    return response;
  } catch (error) {
    logger.error('Error sending notification:', error);
    return null;
  }
}

exports.healthCheck = onRequest((req, res) => {
  res.status(200).send('OK');
});