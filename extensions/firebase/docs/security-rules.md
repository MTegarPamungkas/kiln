# Firestore and Storage security rules

The rules below match `RemoteDatabase` and `FileStorage` from this extension:
user-owned documents can only be read and modified by their owner.

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

## Query notes

- `FirestoreQueryMapper` rejects range filters on multiple fields and orderBy on
  a different field because they require a composite index. If that pattern is
  really needed, create the index in the Firebase Console and then use native
  Firestore queries outside the contract.
- The rules above use `resource.data.ownerId`; make sure every new document
  writes that field, or use Cloud Functions to fill it in.
- Test the rules with `firebase emulators:exec --only firestore,storage "test"`.
