const { onDocumentCreated } = require('firebase-functions/v2/firestore');
const { logger } = require('firebase-functions/v2');
const { initializeApp } = require('firebase-admin/app');
const { getMessaging } = require('firebase-admin/messaging');
const { getFirestore, FieldValue } = require('firebase-admin/firestore');

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

