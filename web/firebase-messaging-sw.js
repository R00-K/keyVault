importScripts('https://www.gstatic.com/firebasejs/10.14.0/firebase-app-compat.js');
importScripts('https://www.gstatic.com/firebasejs/10.14.0/firebase-messaging-compat.js');

firebase.initializeApp({
  apiKey: 'AIzaSyBtEx02tYJGY48AqJpLcaaTHWfY1DgBgT8',
  projectId: 'keyvault-e703b',
  messagingSenderId: '714342543956',
  appId: '1:714342543956:web:PLACEHOLDER_REGISTER_WEB_APP_IN_FIREBASE_CONSOLE',
});

const messaging = firebase.messaging();

messaging.onBackgroundMessage((payload) => {
  const { title, body } = payload.data;
  const notificationOptions = {
    body: body || 'New secure message',
    icon: '/favicon.png',
  };

  self.registration.showNotification(title || 'KeyVault', notificationOptions);
});
