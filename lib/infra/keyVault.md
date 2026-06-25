# KeyVault

A privacy-first messenger based on **Physical Trust**.

## Project Vision

KeyVault is an encrypted messaging application where encryption keys are exchanged **only through physical interaction**.

Messages are encrypted locally, stored in the database as ciphertext, and decrypted only on the recipient's device.

The server never possesses encryption keys.

---

## Current Status

### ✅ Completed

- Flutter project setup
- Firebase Authentication
- Firestore setup
- Home Screen UI
- Chat UI
- Firestore service
- UserModel

### 🚧 In Progress

- User Repository

### 📅 Upcoming

- Contact Repository
- Conversations
- Real-time Messaging
- QR Key Exchange
- AES-256 Encryption
- Secure Storage
- NFC Support

---

## Architecture

```
UI
│
├── Screens
├── Widgets
│
▼
Repositories
│
▼
Services
│
▼
Firebase
```

---

## Project Structure

```
lib/
├── core/
├── infra/
├── models/
└── ui/
```

---

## Security Principles

- Physical key exchange only
- End-to-end encryption
- No server-side encryption keys
- Keys stored only in secure device storage
- Firestore stores ciphertext only
