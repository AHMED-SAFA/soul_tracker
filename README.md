<div align='center'>
  
  # Soul Tracker 
  A real-time location tracking Flutter application that allows users to securely track and be tracked by people they trust. Built with Firebase, Cloudinary, and modern geolocation technologies.

</div>


## 📱 Description

Soul Tracker enables secure, mutual location sharing between trusted contacts. Users can generate unique tracking keys and share them with people they want to track. Recipients can accept or reject tracking requests, and either party can revoke access at any time. Real-time location updates are displayed on an interactive map with comprehensive device information.

### Key Features

- **Mutual Tracking**: Generate unique keys to share with contacts and receive tracking keys from others
- **Real-time Location Tracking**: Continuous GPS updates displayed on an interactive map
- **Access Control**: Easy revocation of tracking keys to instantly stop sharing location
- **Device Information**: View tracked device details including model, OS version, and IP address
- **Secure Authentication**: Firebase-based user authentication
- **Media Management**: Cloudinary integration for profile image uploads
- **Background Tracking**: Location updates continue in the background
- **Distance-based Updates**: Optimized location polling every 1 meter movement or 10 seconds

## 🛠️ Tech Stack

### Frontend
- **Flutter** - Cross-platform mobile framework

### Backend
- **Firebase Authentication**: Firebase Auth
- **Database**: Cloud Firestore
- **Real-time Updates**: Firestore Listeners
- **Media Storage**: Cloudinary - Cloud-based image management

### Geolocation & Device
- **Geolocator** - Location services
- **Device Info Plus** - Device metadata

### State Management
- **Provider** pattern with **GetIt** service locator

### UI Components
- **Flutter Material Design**

## 📋 Prerequisites

- Flutter SDK
- Dart SDK
- Firebase project configured
- Cloudinary account
- Android/iOS development environment

## 🚀 Getting Started

### 1. Clone the Repository

```bash
git clone https://github.com/AHMED-SAFA/soul_tracker
cd soul_tracker
```
### 2. Environment Setup
Create a .env file in the project root:
```bash
# Firebase Configuration
FIREBASE_API_KEY_ANDROID=android_api_key
FIREBASE_APP_ID_ANDROID=android_app_id
FIREBASE_API_KEY_IOS=ios_api_key
FIREBASE_APP_ID_IOS=ios_app_id
FIREBASE_API_KEY_WEB=web_api_key
FIREBASE_APP_ID_WEB=web_app_id
FIREBASE_API_KEY_WINDOWS=windows_api_key
FIREBASE_APP_ID_WINDOWS=windows_app_id
FIREBASE_MESSAGING_SENDER_ID=messaging_sender_id
FIREBASE_PROJECT_ID=project_id
FIREBASE_STORAGE_BUCKET=storage_bucket
FIREBASE_AUTH_DOMAIN=auth_domain
FIREBASE_MEASUREMENT_ID_WEB=measurement_id_web
FIREBASE_MEASUREMENT_ID_WINDOWS=measurement_id_windows
FIREBASE_IOS_BUNDLE_ID=com.example.maptracker

# Cloudinary Configuration
CLOUDINARY_CLOUD_NAME=cloud_name
CLOUDINARY_API_KEY=api_key
CLOUDINARY_SECRET_KEY=secret_key
```

### 3. Install Dependencies
```bash
flutter pub get
```

### 4. Run App
```bash
flutter run
```

## 📁 Project Structure
```bash
lib/
├── config/
│   └── cloudinary_config.dart      # Cloudinary settings
├── providers/
│   ├── location_provider.dart       # Real-time location tracking
│   └── device_record_provider.dart  # Device information provider
├── services/
│   ├── auth_service.dart            # Firebase authentication
│   ├── background_service.dart       # Background location tracking
│   ├── location_foreground_service.dart
│   ├── media_service.dart           # Cloudinary integration
│   ├── devic_tracking_service.dart  # Tracking logic
│   └── navigation_service.dart       # In-app navigation
├── firebase_options.dart            # Firebase configuration
└── utils.dart                       # Initialization utilities
```

## 🔐 Core Features Explained

### Location Tracking
- **Continuous Updates**: Timer-based updates every 10 seconds
- **Distance Filtering**: Updates triggered when device moves 1+ meter
  
### Access Control
- **Unique Keys**: Generate shareable tracking keys
- **Bidirectional Tracking**: Both users can track each other simultaneously
- **Instant Revocation**: Revoke keys to immediately stop tracking access
- **Key Management**: View and delete active tracking keys

### Device Information
- **Device Model & Manufacturer**
- **Operating System & Version**
- **Public IP Address**
- **Real-time GPS coordinates with accuracy metrics**

## 📍 Permissions Required

```xml
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />
<uses-permission android:name="android.permission.ACCESS_BACKGROUND_LOCATION" />
```

## 🔄 Workflow

- **User Registration**: Sign up with email/password via Firebase Auth
- **Generate Key**: Create a unique tracking key
- **Share Key**: Share the key
- **Accept Tracking**: Recipient enters the key to start tracking
- **View on Map**: Real-time location updates on interactive map
- **Manage Access**: Revoke keys anytime to stop tracking

## 📸 Screenshots

<div align="center">

  <h3>Authentication Screen</h3>
  
  <img src="https://github.com/user-attachments/assets/da9a2527-e40c-4481-ad32-c0beef597655" alt="Authentication Screen" height="500"/>
  <img src="https://github.com/user-attachments/assets/074c31b7-8ca8-428b-9469-9883181df4af" alt="Authentication Screen" height="500"/>

  <h3>Profile</h3>  
  <img src="https://github.com/user-attachments/assets/b707db71-2dcf-4037-b6c0-f36541b850fb" alt="Profile Screen" height="500"/>
  <img src="https://github.com/user-attachments/assets/cb419220-85e1-4333-a852-5cdd68d6f3aa" alt="Profile Screen" height="500"/>

  <h3>🗝️ Generate Tracking Keys</h3>
  <img src="https://github.com/user-attachments/assets/5403dacd-be5c-426b-b994-86c192a2e0bb" alt="Key Generate Screen" height="500"/>
  <img src="https://github.com/user-attachments/assets/d7617362-1c88-4314-be7a-af7ade93ff2b" alt="Key Generate Screen" height="500"/>

  <h3>📍 Real-Time Location on Map</h3>
  <img src="https://github.com/user-attachments/assets/823b7d9e-e7ab-445e-a4ce-07e559e5dc7a" alt="Map Tracking Screen" height="500"/>
  <img src="https://github.com/user-attachments/assets/a6d61d9d-b3ee-44b1-a39e-b5536dc0a6ff" alt="Map Tracking Screen" height="500"/>
  <img src="https://github.com/user-attachments/assets/a1783d8e-b548-4c32-9182-3aa9b2719495" alt="Map Tracking Screen" height="500"/>

  <h3>🗝️Keys management</h3>  
  <img src="https://github.com/user-attachments/assets/d29215a6-f09d-454c-adcc-4239efa45aca" alt="Key Management Screen" height="500"/>
  <img src="https://github.com/user-attachments/assets/2aef0f11-5f7d-4242-a90a-fc43324d112b" alt="Key Management Screen" height="500"/>

</div>

## 🎨 UI/UX Features

- Clean Material Design interface
- Interactive map integration
- Real-time location markers
- Toast notifications for user actions
- Responsive layout for various screen sizes

## 📦 Dependencies

```yaml
dependencies:
  flutter:
    sdk: flutter
  
  # Firebase
  firebase_core: ^2.15.0
  firebase_auth: ^4.7.0
  cloud_firestore: ^4.8.0
  
  # Location & Device
  geolocator: ^10.1.0
  device_info_plus: ^9.1.0
  
  # Media
  cloudinary_flutter: ^1.0.0
  
  # State Management
  get_it: ^7.6.0
  provider: ^6.0.5
  
  # Utilities
  flutter_dotenv: ^5.1.0
  fluttertoast: ^8.2.2
  http: ^1.1.0
```

## 🤝 Contributing
Feel free to submit a Pull Request.
