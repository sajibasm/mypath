# MyPath – Accessible Navigation for All

MyPath is a cross-platform Flutter application designed to help users find wheelchair-accessible routes in real-time using Google Maps integration, user reports, and custom data.

## 🚀 Features
- Login, Sign-up, Reset Password screens
- JWT-based authentication with secure token storage
- Reusable constants and design tokens
- Google Maps integration (lat/lng, directions, markers)
- Platform-specific setup for Android & iOS
- Clean API integration with retry, timeout, and global error handling

## 📦 Requirements
- Flutter 3.22.2 (or latest stable)
- Dart 3.4.3
- Xcode (for iOS)
- Android Studio / SDK (for Android)
- Google Maps API Key (for both platforms)

## 🛠️ Project Structure
    lib/
    ├── constants/                      # App-wide constants and reusable definitions
    │   ├── colors.dart                 # Centralized color palette
    │   ├── styles.dart                 # Text styles and UI design tokens
    │   ├── constants.dart              # Core values (e.g. lat/lng, durations)
    │   └── endpoints.dart              # Backend API endpoints
    │
    ├── screens/                        # UI screens for different app states
    │   ├── welcome_screen.dart         # Welcome/onboarding UI
    │   ├── login_screen.dart           # Login form
    │   ├── reset_password_screen.dart  # Reset password functionality
    │   └── home_screen.dart            # Main app landing screen after login
    │
    ├── services/                       # Backend logic and HTTP integrations
    │   └── api_service.dart            # API calls with retry, token auth, error handling
    │
    └── main.dart                       # App entry point and route configuration
    
    assets/
    ├── images/                         # Static images and logos used in the UI
    │   └── logo.png                    # Main MyPath logo used on welcome screen
    └── icons/                          # Optional: custom icons (if any)


## 🔧 How to Run
#### ✅ Android

    flutter clean  
    flutter pub get  
    flutter run

#### ✅ iOS

    cd ios  
    pod install  
    cd ..  
    flutter clean  
    flutter pub get  
    flutter run


## Set minimum deployment target in ios/Podfile to 13.0 or higher:
> platform :ios, '13.0'

## Also update AppDelegate.swift with your Google Maps API Key:
> GMSServices.provideAPIKey("YOUR_API_KEY")

## Google Maps API Setup

#### Android
Edit `android/app/src/main/AndroidManifest.xml:`

    <meta-data  
     android:name="com.google.android.geo.API_KEY" android:value="YOUR_API_KEY"/>


#### iOS
Edit `ios/Runner/AppDelegate.swift:`

     import GoogleMaps  
    GMSServices.provideAPIKey("YOUR_API_KEY")

## Environment & Constants

    class AppConstants {  
     static const String apiBaseUrl = 'https://your-api.com/api'; static const LatLng homeLatLng = LatLng(39.2904, -76.6122);}  
      
    class AppEndpoints {  
     static final Uri login = Uri.parse('${AppConstants.apiBaseUrl}/user/login/');}

## 🏗️ Build for ReleaseAndroid

#### Android

    flutter build apk --release  

#### iOS

    flutter build ios --release  