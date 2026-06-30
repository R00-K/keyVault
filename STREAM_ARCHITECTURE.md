# Secure Stream Architecture

## Overview

The Secure Stream module enables two users in a trusted chat session to stream files securely. It is a **signaling-only** layer — it orchestrates the invitation/acceptance protocol and session state but currently has **no actual file transfer, WebRTC, HTTP, or networking** implemented. The actual streaming transport will be added in a future phase.

The module lives under `lib/stream/` and is independent of `ChatService`.

---

## Flow (End-to-End)

```
Sender taps "+" → "Stream File"
  → picks any file via FilePicker
  → StreamService.sendStreamInvite()
  → writes to Firestore: streamInvitations/{invitationId}

Recipient's app (via StreamService.listenForInvitations) 
  → Firestore onSnapshot on streamInvitations
  → where receiverUid == currentUser.uid && status == "pending"
  → shows AlertDialog: "[Sender] wants to stream: file.pdf (2.3 MB)"

Recipient taps:
  [Decline] → status set to "declined" → done
  [Accept]  → status set to "accepted"
           → new doc created in streamSessions/{streamId}
           → both navigate to StreamingScreen (placeholder)
```

---

## Data Models

### StreamInvitationModel
| Field          | Type              | Description                         |
|----------------|-------------------|-------------------------------------|
| invitationId   | String            | Unique ID (invite-{timestamp}-{id}) |
| sessionId      | String            | The chat session this belongs to    |
| senderUid      | String            | Firebase Auth UID of sender         |
| receiverUid    | String            | Firebase Auth UID of receiver       |
| fileName       | String            | Display name of the file            |
| mimeType       | String            | e.g. "application/pdf"              |
| fileSize       | int               | Size in bytes                       |
| createdAt      | DateTime          | When invitation was sent            |
| status         | InvitationStatus  | pending / accepted / declined / cancelled |

Stored at Firestore path: `streamInvitations/{invitationId}`

### StreamSessionModel
| Field          | Type              | Description                         |
|----------------|-------------------|-------------------------------------|
| streamId       | String            | Unique ID (stream-{timestamp}-{id}) |
| chatSessionId  | String            | The chat session this belongs to    |
| ownerUid       | String            | UID of the file owner (sender)      |
| viewerUid      | String            | UID of the recipient                |
| fileName       | String            | Display name of the file            |
| mimeType       | String            | e.g. "video/mp4"                    |
| fileSize       | int               | Size in bytes                       |
| createdAt      | DateTime          | When session was created            |
| isEncrypted    | bool              | Always true (reserved for crypto)   |
| streamState    | StreamState       | waiting / connecting / streaming / paused / ended |

Stored at Firestore path: `streamSessions/{streamId}`

---

## Layer Architecture

```
┌─────────────────────────────┐
│      StreamingScreen        │  UI placeholder
├─────────────────────────────┤
│      StreamService          │  Orchestration (static class)
│  - send/invite/accept/etc   │  Shows dialogs, navigates
│  - listenForInvitations     │  Listens to Firestore stream
├─────────────────────────────┤
│      StreamRepository       │  Firestore CRUD abstraction
├─────────────────────────────┤
│  StreamInvitationModel      │  Data models
│  StreamSessionModel         │
└─────────────────────────────┘
```

All layers follow the same patterns as the rest of KeyVault: static classes, no dependency injection, direct Firestore access via `FirestoreService`.

---

## Current State

### Working
- Invitation protocol: send, accept, decline (Firestore writes)
- Pending invitation listener: real-time listener on `streamInvitations` where `receiverUid == uid && status == "pending"`
- Dialog UI: shows file name, size, sender name, Accept/Decline buttons
- Session creation: document created in `streamSessions` on accept
- Both users navigate to `StreamingScreen`

### Placeholder
- `StreamingScreen` shows a simple "Waiting for stream..." UI — no actual streaming
- `FilePicker` opens for any file type — no filtering or validation
- No actual file upload, download, or transfer

### Not Yet Implemented (Phase 2+)
- Actual streaming transport (WebRTC, HTTP range requests, Firebase Storage, etc.)
- File chunking and reassembly
- End-to-end encryption of stream content
- Progress indicators, pause/resume controls
- Error handling for failed transfers
- File type specific UIs (image viewer, video player, PDF viewer)

---

## Future Directions

The signaling layer is designed to be transport-agnostic. Possible streaming approaches:

1. **WebRTC** — Peer-to-peer via STUN/TURN, good for real-time. `streamState` would map to WebRTC signaling states.
2. **Firebase Storage + Cloud Functions** — Sender uploads encrypted chunks, receiver downloads. Simpler but incurs bandwidth costs.
3. **Direct socket connection** — If both peers are on same network, direct TCP socket.

The `StreamState` enum (`waiting → connecting → streaming → paused → ended`) is designed to support any of these approaches.
