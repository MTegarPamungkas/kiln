# Aturan keamanan Firestore dan Storage

Aturan di bawah cocok dengan `RemoteDatabase` dan `FileStorage` dari extension
ini: dokumen milik pengguna hanya dapat dibaca dan diubah oleh pemiliknya.

## Firestore

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    function signedIn() {
      return request.auth != null;
    }

    function owner(userId) {
      return signedIn() && request.auth.uid == userId;
    }

    match /users/{userId} {
      allow read: if owner(userId);
      allow create: if owner(userId);
      allow update: if owner(userId);
      allow delete: if owner(userId);
    }

    match /tasks/{taskId} {
      allow read: if signedIn() && resource.data.ownerId == request.auth.uid;
      allow create: if signedIn()
        && request.resource.data.ownerId == request.auth.uid;
      allow update: if signedIn()
        && resource.data.ownerId == request.auth.uid
        && request.resource.data.ownerId == request.auth.uid;
      allow delete: if signedIn() && resource.data.ownerId == request.auth.uid;
    }
  }
}
```

## Cloud Storage

```javascript
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {
    match /avatars/{userId}/{fileName} {
      allow read: if request.auth != null;
      allow write: if request.auth != null
        && request.auth.uid == userId
        && request.resource.size < 5 * 1024 * 1024
        && request.resource.contentType.matches('image/.*');
    }

    match /{allPaths=**} {
      allow read, write: if false;
    }
  }
}
```

## Catatan query

- `FirestoreQueryMapper` menolak filter rentang pada beberapa field dan
  orderBy pada field berbeda karena membutuhkan indeks komposit. Bila pola itu
  memang dibutuhkan, buat indeks di Firebase Console lalu gunakan query native
  Firestore di luar kontrak.
- Aturan di atas memakai `resource.data.ownerId`; pastikan setiap dokumen baru
  menulis field tersebut, atau gunakan Cloud Functions untuk mengisinya.
- Uji aturan dengan `firebase emulators:exec --only firestore,storage "test"`.
