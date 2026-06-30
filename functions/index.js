const functions = require('firebase-functions');
const admin = require('firebase-admin');

admin.initializeApp();

const db = admin.firestore();

exports.sendMessageNotification = functions.firestore
    .document('chats/{sessionId}/messages/{messageId}')
    .onCreate(async (snap, context) => {
      const message = snap.data();
      if (!message) {
        console.log('TRIGGER FIRED but no message data');
        return null;
      }

      const {to, from, sessionId} = message;

      console.log(
        `TRIGGER FIRED: sessionId=${sessionId}, messageId=${context.params.messageId}, from=${from}, to=${to}`
      );

      if (!to) {
        console.log('EARLY RETURN: message has no "to" field');
        return null;
      }
      if (!from) {
        console.log('EARLY RETURN: message has no "from" field');
        return null;
      }
      if (to === from) {
        console.log('EARLY RETURN: sender and receiver are the same');
        return null;
      }

      try {
        // Both from and to are Firebase Auth UIDs (consistent identity model)
        console.log(`Looking up recipient user doc: users/${to}`);
        const recipientDoc = await db.collection('users').doc(to).get();
        if (!recipientDoc.exists) {
          console.log(`RECIPIENT NOT FOUND: no user doc for uid=${to}`);
          return null;
        }

        const recipientData = recipientDoc.data();
        const fcmToken = recipientData?.fcmToken;
        if (!fcmToken) {
          console.log(`NO FCM TOKEN: user ${to} has no fcmToken field`);
          return null;
        }
        console.log(`RECIPIENT FOUND: uid=${to}, fcmToken=${fcmToken.substring(0, 20)}...`);

        console.log(`Looking up sender user doc: users/${from}`);
        const senderDoc = await db.collection('users').doc(from).get();
        const senderName = senderDoc.exists
            ? (senderDoc.data()?.displayName || 'Someone')
            : 'Someone';
        console.log(`SENDER: uid=${from}, displayName=${senderName}`);

        const payload = {
          token: fcmToken,
          data: {
            sessionId: sessionId || '',
            messageId: context.params.messageId || '',
            title: senderName,
            body: 'New secure message',
            clickAction: 'FLUTTER_NOTIFICATION_CLICK',
          },
        };

        console.log(`SENDING FCM: to token ${fcmToken.substring(0, 20)}..., payload data keys: ${Object.keys(payload.data).join(', ')}`);

        const response = await admin.messaging().send(payload);
        console.log(`FCM SENT SUCCESS: messageId=${response}`);
        return null;
      } catch (error) {
        console.error('FCM SEND ERROR:', error);
        return null;
      }
    });
