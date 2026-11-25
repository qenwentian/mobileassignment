# FINDER (`mobile_app`)

Campus Lost & Found Flutter app using MVVM (`provider`), **Firebase Authentication**, and **Cloud Firestore** user records with role-based access (`normal` vs `admin`).

## Firebase Setup (Console & App Config)

1. **Create a Firebase project** in the [Firebase Console](https://console.firebase.google.com/).
2. **Enable Email/Password Authentication**:
   - Open **Build -> Authentication -> Sign-in method** and enable **Email/Password**.
   - Optionally create a demo user matching `demo@univ.edu` / `campus123` if you want the **Use demo account** button on the login screen to work against your project.
3. **Create Cloud Firestore & deploy Security Rules**:
   - Open **Build -> Firestore Database** and create the default database.
   - Publish `firestore.rules` either by pasting its contents into the **Firestore -> Rules** tab in the Console or running:
     ```sh
     npx firebase-tools deploy --only firestore:rules --project YOUR_PROJECT_ID
     ```
4. **Register your app & add credentials**:
   - For **Android** (`com.example.mobile_app`): download `google-services.json` from Project Settings and place it in `android/app/google-services.json` (and/or fill in `lib/firebase_options.dart`), or run:
     ```sh
     flutterfire configure
     ```
   - Alternatively, copy your Firebase Web/Android keys into `lib/firebase_options.dart`, or create a Git-ignored `firebase.local.json` and run:
     ```sh
     flutter run --dart-define-from-file=firebase.local.json
     ```
     ```json
     {
       "FIREBASE_API_KEY": "your-api-key",
       "FIREBASE_APP_ID": "your-app-id",
       "FIREBASE_MESSAGING_SENDER_ID": "your-sender-id",
       "FIREBASE_PROJECT_ID": "your-project-id",
       "FIREBASE_AUTH_DOMAIN": "your-project-id.firebaseapp.com"
     }
     ```
5. **Create the first Admin account**:
   - Register a user through the app (all self-registered accounts are enforced as `role: "normal"` by `firestore.rules`).
   - In the Firebase Console, open **Firestore Database -> `users/{uid}`** and change `role` from `"normal"` to `"admin"`.

## Local Firebase Emulators (Optional)

```sh
firebase emulators:start --only auth,firestore
flutter run --dart-define=USE_FIREBASE_EMULATORS=true
```
