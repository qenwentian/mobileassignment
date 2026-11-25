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
5. **Built-in Admin account**:
   - Deploy the updated `firestore.rules` (`firebase deploy --only firestore:rules`).
   - Sign in once with the built-in admin credentials. The account is created in Firebase Auth and
     Firestore automatically on first sign-in (debug builds also show a **Use admin account (debug)** button).

     | Email | Password |
     | --- | --- |
     | `admin@univ.edu` | `admin123` |

   - Do this right after deploying the rules, then **change the password** (Firebase Console -> Authentication, or
     use "forgot password"), because the default is stored in the app source (`AuthService.builtInAdminPassword`).
   - `admin@univ.edu` is reserved: it cannot be registered as a normal account and other admins cannot demote it.
   - To make any other user an admin, use **Admin -> Manage Users** in the app.

## Admin features

Admins get an extra **Admin** tab with:

- **Dashboard**: user, admin, post, claim, lost and found counts.
- **Manage Users**: search and filter accounts; promote to Admin or demote to Normal (you cannot change your own role).
- **Moderate Items**: filter posts; approve a pending claim (marks the item *Returned* and hides it from the feed/map),
  reject a claim, or delete a post.

Note: items are still stored in memory (`ItemsViewModel`), so moderation changes last for the current app session only.

## Local Firebase Emulators (Optional)

```sh
firebase emulators:start --only auth,firestore
flutter run --dart-define=USE_FIREBASE_EMULATORS=true
```
