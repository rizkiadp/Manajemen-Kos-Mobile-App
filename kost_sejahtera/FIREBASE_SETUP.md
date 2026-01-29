# Firebase Setup Guide

## 1. Create Firebase Project

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Click "Add Project"
3. Enter project name: `kost-sejahtera`
4. Disable Google Analytics (optional)
5. Click "Create Project"

## 2. Enable Authentication

1. In Firebase Console, go to **Authentication**
2. Click "Get Started"
3. Enable **Email/Password** sign-in method
4. Click "Save"

## 3. Create Firestore Database

1. Go to **Firestore Database**
2. Click "Create Database"
3. Select "Start in test mode" (for development)
4. Choose location closest to you
5. Click "Enable"

### Firestore Security Rules (Development)

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Users collection
    match /users/{userId} {
      allow read: if request.auth != null;
      allow write: if request.auth.uid == userId;
    }
    
    // Rooms collection
    match /rooms/{roomId} {
      allow read: if true; // Public can view rooms
      allow write: if request.auth != null && 
                     get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role == 'admin';
    }
    
    // Tenants collection
    match /tenants/{tenantId} {
      allow read: if request.auth != null;
      allow write: if request.auth != null && 
                     get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role == 'admin';
    }
    
    // Invoices collection
    match /invoices/{invoiceId} {
      allow read: if request.auth != null;
      allow write: if request.auth != null && 
                     get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role == 'admin';
    }
    
    // Transactions collection
    match /transactions/{transactionId} {
      allow read: if request.auth != null && 
                    get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role == 'admin';
      allow write: if request.auth != null && 
                     get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role == 'admin';
    }
    
    // Payments collection
    match /payments/{paymentId} {
      allow read: if request.auth != null;
      allow write: if request.auth != null;
    }
  }
}
```

## 4. Setup Firebase Storage

1. Go to **Storage**
2. Click "Get Started"
3. Use default security rules
4. Click "Done"

### Storage Security Rules

```javascript
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {
    match /rooms/{allPaths=**} {
      allow read: if true;
      allow write: if request.auth != null;
    }
    
    match /avatars/{allPaths=**} {
      allow read: if true;
      allow write: if request.auth != null;
    }
  }
}
```

## 5. Add Android App

1. In Project Overview, click Android icon
2. Enter package name: `com.kostsejahtera.app`
3. Download `google-services.json`
4. Place file in: `android/app/google-services.json`

### Update android/build.gradle

```gradle
buildscript {
    dependencies {
        // Add this line
        classpath 'com.google.gms:google-services:4.3.15'
    }
}
```

### Update android/app/build.gradle

```gradle
apply plugin: 'com.android.application'
apply plugin: 'kotlin-android'
apply from: "$flutterRoot/packages/flutter_tools/gradle/flutter.gradle"

// Add this line
apply plugin: 'com.google.gms.google-services'

android {
    defaultConfig {
        applicationId "com.kostsejahtera.app"
        minSdkVersion 21  // Important for Firebase
        targetSdkVersion flutter.targetSdkVersion
        versionCode flutterVersionCode.toInteger()
        versionName flutterVersionName
        multiDexEnabled true  // Add this
    }
}

dependencies {
    implementation platform('com.google.firebase:firebase-bom:32.7.0')
}
```

## 6. Initialize Firebase in Flutter

Update `lib/main.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'core/theme/app_theme.dart';
import 'presentation/screens/auth/login_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Kost Sejahtera',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const LoginScreen(),
    );
  }
}
```

## 7. Create Initial Admin User

Use Firebase Console to create first admin:

1. Go to **Authentication** → **Users**
2. Click "Add User"
3. Email: `admin@kostsejahtera.com`
4. Password: `admin123` (change later!)
5. Click "Add User"

Then add user document in Firestore:

1. Go to **Firestore Database**
2. Create collection: `users`
3. Document ID: (use the UID from Authentication)
4. Add fields:
   ```json
   {
     "id": "USER_UID_HERE",
     "email": "admin@kostsejahtera.com",
     "name": "Admin",
     "phone": "08123456789",
     "role": "admin",
     "avatar": null,
     "createdAt": "2024-01-29T00:00:00.000Z",
     "updatedAt": "2024-01-29T00:00:00.000Z"
   }
   ```

## 8. Test Firebase Connection

Run the app:

```bash
flutter run
```

Try logging in with admin credentials.

## 9. Setup Cloud Messaging (Optional)

For push notifications:

1. Go to **Cloud Messaging**
2. Click "Get Started"
3. Follow setup instructions
4. Add FCM token handling in Flutter

## 10. Production Setup

Before going to production:

1. **Update Firestore Rules** to production-ready rules
2. **Update Storage Rules** to restrict access
3. **Enable App Check** for security
4. **Setup Firebase Functions** for backend logic
5. **Configure billing** (Blaze plan for production)

## Troubleshooting

### Error: "Default FirebaseApp is not initialized"

Make sure you called `Firebase.initializeApp()` in `main()`.

### Error: "google-services.json not found"

Place the file in `android/app/` directory.

### Error: "Multidex error"

Add `multiDexEnabled true` in `android/app/build.gradle`.

## Useful Commands

```bash
# Install FlutterFire CLI
dart pub global activate flutterfire_cli

# Configure Firebase automatically
flutterfire configure

# Update dependencies
flutter pub get

# Clean build
flutter clean
flutter pub get
flutter run
```

## Next Steps

1. ✅ Firebase is now configured
2. Implement authentication flow
3. Create Firestore CRUD operations
4. Add image upload to Storage
5. Setup Cloud Functions for Midtrans webhook
6. Deploy to production

## Resources

- [FlutterFire Documentation](https://firebase.flutter.dev/)
- [Firebase Console](https://console.firebase.google.com/)
- [Firestore Documentation](https://firebase.google.com/docs/firestore)
