# ELESS - Electrical Engineering Student's Society

<div align="center">
  
  [![Flutter](https://img.shields.io/badge/Flutter-3.10+-02569B?style=for-the-badge&logo=flutter)](https://flutter.dev)
  [![Dart](https://img.shields.io/badge/Dart-3.10+-0175C2?style=for-the-badge&logo=dart)](https://dart.dev)
  [![Firebase](https://img.shields.io/badge/Firebase-FFCA28?style=for-the-badge&logo=firebase&logoColor=black)](https://firebase.google.com)
  [![License](https://img.shields.io/badge/License-MIT-green?style=for-the-badge)](LICENSE)

  **A comprehensive mobile application for managing electronics lab equipment, events, and device requests with real-time notifications**
</div>

---

## 👨‍💻 Developer

**Chandan Kumar Singh**
- GitHub: [@chandan-kumar-singh2063](https://github.com/chandan-kumar-singh2063)
- Project Repository: [eless-app](https://github.com/chandan-kumar-singh2063/eless-app)

---

## 📱 About ELESS

ELESS (Electrical Engineering Student's Society) is a modern, feature-rich mobile application designed to streamline the management of electronics laboratory equipment. The app provides students and administrators with an intuitive platform to browse devices, request equipment, track events, and receive real-time notifications.

Built with Flutter and powered by a Django backend, ELESS offers a seamless offline-first experience with intelligent caching, responsive design for all screen sizes, and comprehensive state management.

---

## ✨ Key Features

### 🔐 Authentication & Security
- **QR Code Authentication**: Fast and secure login using QR scanner
- **JWT Token Management**: Automatic token refresh and secure API communication
- **Guest Mode**: Browse content without authentication
- **Session Management**: Persistent login with automatic logout on token expiry
- **Device Fingerprinting**: Unique device identification for enhanced security

### 📱 Device Management
- **Device Catalog**: Browse available lab equipment with detailed specifications
- **Advanced Search**: Filter devices by category, availability, and type
- **Device Details**: View comprehensive information, images, and availability status
- **Request System**: Submit device requests with date range and purpose
- **Real-time Availability**: Check current device availability before requesting
- **Image Optimization**: Cached network images with progressive loading

### 📅 Event Management
- **Event Listings**: View ongoing, upcoming, and past lab events
- **Event Categories**: Organize events by workshops, seminars, competitions
- **Event Details**: Complete event information with images, date, time, venue
- **Registration System**: Direct registration for upcoming events
- **Event Notifications**: Get notified about new and upcoming events
- **Pull-to-Refresh**: Update event listings in real-time

### 🛒 Cart & Request Tracking
- **Request Management**: Track all device requests in one place
- **Status Tracking**: Monitor request status (pending, approved, rejected, returned, overdue)
- **Admin Actions**: View administrative decisions on requests
- **Status Badges**: Color-coded status indicators for quick identification
- **Request History**: Access complete history of all device requests
- **Request Counts**: Real-time count of requests by status

### 🔔 Push Notifications
- **Firebase Cloud Messaging**: Real-time push notifications
- **Image Notifications**: Rich notifications with images (BigPicture style)
- **Background Processing**: Handle notifications when app is closed
- **Notification Center**: View all notifications with read/unread status
- **Click Actions**: Navigate to relevant screens from notifications
- **Token Management**: Automatic FCM token registration and refresh

### 🏠 Home Dashboard
- **Carousel Banners**: Auto-playing promotional banners
- **Event Sections**: Categorized display of ongoing, upcoming, and past events
- **Quick Navigation**: Easy access to all major features
- **Pull-to-Refresh**: Update content with a simple swipe
- **Shimmer Loading**: Beautiful loading states with shimmer effects
- **Cached Content**: Instant loading with offline-first architecture

### 🔍 Explore & Discover
- **Category Browser**: Explore devices by categories
- **Visual Cards**: Image-rich category cards with smooth animations
- **Event Discovery**: Browse all events in a dedicated explore section
- **Search Functionality**: Quick search across devices and events
- **Filter Options**: Advanced filtering for refined searches

### 👤 User Profile
- **Profile Management**: View and edit user information
- **Request History**: Complete history of device requests
- **Notification Preferences**: Manage notification settings
- **About Section**: Learn about ELESS and developers
- **Logout**: Secure session termination

### 📲 Responsive Design
- **All Screen Sizes**: Optimized for small (320px) to large (480px+) devices
- **Dynamic Layouts**: Responsive calculations using MediaQuery
- **Aspect Ratio Preservation**: Consistent visuals across devices
- **Overflow Prevention**: No layout breaks on any device size
- **Fluid Animations**: Smooth transitions and animations

### 💾 Offline-First Architecture
- **Local Caching**: Hive database for offline data storage
- **Instant Loading**: Show cached data immediately
- **Background Sync**: Fetch fresh data in background
- **Smart Updates**: Only update UI when new data arrives
- **Network Optimization**: Minimize API calls with intelligent caching

---

## 🏗️ Architecture & Tech Stack

### Frontend (Flutter)
```
lib/
├── main.dart                      # App entry point with initialization
├── auth_wrapper.dart              # Authentication state wrapper
├── app_wrapper.dart               # Main app wrapper
│
├── controller/                    # GetX State Management
│   ├── auth_controller.dart       # Authentication & user state
│   ├── home_controller.dart       # Home screen state
│   ├── devices_controller.dart    # Device catalog state
│   ├── event_controller.dart      # Events state management
│   ├── cart_controller.dart       # Request cart state
│   ├── notification_controller.dart # Notifications state
│   └── dashboard_controller.dart  # Bottom navigation state
│
├── view/                          # UI Screens (53+ files)
│   ├── home/                      # Home screen with banners & events
│   ├── Devices/                   # Device catalog & grid
│   ├── device_details/            # Device detail screen
│   ├── device_request/            # Device request form
│   ├── cart/                      # Request tracking screen
│   ├── event_details/             # Event detail screens
│   ├── notification/              # Notification center
│   ├── account/                   # User profile & auth
│   ├── Explore/                   # Category & event explore
│   └── about_us/                  # About app & developers
│
├── model/                         # Data Models with Hive
│   ├── user.dart                  # User model
│   ├── device.dart                # Device model
│   ├── event.dart                 # Event model
│   ├── cart_item.dart             # Cart/Request model
│   ├── notification.dart          # Notification model
│   ├── ad_banner.dart             # Banner model
│   └── category.dart              # Category model
│
├── service/                       # Business Logic Layer
│   ├── api_client.dart            # HTTP client with JWT
│   ├── api_client_v2.dart         # Enhanced API client
│   ├── fcm_token_manager.dart     # Firebase token management
│   ├── device_service.dart        # Device CRUD operations
│   ├── notification_service.dart  # Notification handling
│   ├── local_service/             # Hive local database services
│   └── remote_service/            # API endpoint services
│
├── component/                     # Reusable Widgets
│   ├── main_header.dart           # App header with cart/notifications
│   └── home_header.dart           # Home screen header
│
├── route/                         # Navigation
│   ├── app_page.dart              # Route definitions
│   └── app_route.dart             # Route names
│
├── theme/                         # Styling
│   └── app_theme.dart             # Color scheme & theme data
│
├── extention/                     # Helper Extensions
│   └── image_url_helper.dart      # Image URL utilities
│
└── FIrebaseNotifications/         # Push Notifications
    └── firebase_notifications_service.dart
```

### Backend Integration
- **Django REST Framework**: RESTful API backend
- **JWT Authentication**: Secure token-based auth
- **Firebase Admin SDK**: Server-side push notifications
- **PostgreSQL/MySQL**: Primary database
- **Media Storage**: Image hosting with CDN support

### State Management
- **GetX**: Lightweight reactive state management
- **RxDart**: Reactive observables for real-time updates
- **Persistent State**: Automatic state preservation

### Local Database
- **Hive**: Fast NoSQL database for offline storage
- **Type Adapters**: Custom serialization for models
- **Boxes**: Separate storage for each data type
  - User box
  - Devices box
  - Events box
  - Notifications box
  - Cart box
  - Banners box

### Network Layer
- **HTTP Package**: RESTful API communication
- **Retry Logic**: Automatic retry on network failure
- **Queue Management**: Request queuing for offline support
- **JWT Interceptor**: Automatic token injection
- **Error Handling**: Comprehensive error management

### Image Handling
- **Cached Network Image**: Progressive image loading
- **Memory Cache**: In-memory image caching
- **Disk Cache**: Persistent image storage
- **Shimmer Effects**: Loading placeholders
- **Error Fallbacks**: Graceful error handling

### Push Notifications
- **Firebase Cloud Messaging**: Real-time notifications
- **Background Handler**: Process notifications when app is closed
- **Local Notifications**: Display rich notifications with images
- **BigPicture Style**: Full-width image notifications
- **Click Actions**: Deep linking to relevant screens

---

## 📦 Dependencies

### Core
```yaml
flutter: SDK
get: ^4.7.2                    # State management
hive: ^2.2.3                   # Local database
hive_flutter: ^1.1.0           # Hive Flutter integration
http: ^1.6.0                   # HTTP client
```

### UI & UX
```yaml
shimmer: ^3.0.0                # Loading effects
badges: ^3.1.2                 # Badge widgets
cached_network_image: ^3.4.1   # Image caching
carousel_slider: ^5.1.1        # Carousel banners
flutter_easyloading: ^3.0.5    # Loading indicators
flutter_snake_navigationbar: ^0.6.1  # Bottom navigation
modal_bottom_sheet: ^3.0.0     # Bottom sheets
icons_plus: ^5.0.0             # Extended icon set
```

### Firebase
```yaml
firebase_core: ^4.2.1          # Firebase core
firebase_messaging: ^16.0.4    # Push notifications
flutter_local_notifications: ^19.5.0  # Local notifications
```

### Utilities
```yaml
intl: ^0.20.2                  # Date formatting
url_launcher: ^6.3.2           # URL opening
fluttertoast: ^9.0.0           # Toast messages
permission_handler: ^12.0.1    # Permission management
mobile_scanner: ^7.1.3         # QR code scanner
syncfusion_flutter_datepicker: ^31.2.10  # Date picker
uuid: ^4.5.1                   # UUID generation
flutter_dotenv: ^6.0.0         # Environment variables
device_info_plus: ^12.2.0      # Device information
```

---

## 🚀 Getting Started

### Prerequisites
- Flutter SDK 3.10 or higher
- Dart SDK 3.10 or higher
- Android Studio / VS Code
- Git
- Firebase account (for push notifications)
- Django backend server

### Installation

1. **Clone the repository**
```bash
git clone https://github.com/chandan-kumar-singh2063/eless-app.git
cd eless-app
```

2. **Install dependencies**
```bash
flutter pub get
```

3. **Configure Firebase**
   - Add `google-services.json` to `android/app/`
   - Add `GoogleService-Info.plist` to `ios/Runner/`
   - Update `firebase_options.dart` with your Firebase configuration

4. **Set up environment variables**
   - Create `.env` file in root directory
   - Add backend API URL and other configurations

5. **Generate Hive adapters**
```bash
flutter packages pub run build_runner build --delete-conflicting-outputs
```

6. **Run the app**
```bash
flutter run
```

---

## 🔧 Configuration

### Backend API Configuration
Update the API base URL in your service files or environment configuration:
```dart
static const String baseUrl = 'https://your-backend-api.com/api/';
```

### Firebase Setup
1. Create a Firebase project
2. Add Android/iOS apps in Firebase Console
3. Download configuration files
4. Enable Cloud Messaging
5. Configure FCM in Django backend

### Image Size Requirements
For optimal display across all devices:

| Image Type | Size | Aspect Ratio |
|-----------|------|--------------|
| Carousel Banner | 1200×675px | 16:9 |
| Device Image | 400×600px | 2:3 |
| Event Card | 640×360px | 16:9 |
| Notification | 1024×512px | 2:1 |
| Category | 400×400px | 1:1 |

---

## 🎯 App Flow

### User Journey
1. **Launch** → Splash Screen → Authentication Check
2. **Guest Mode** → Browse devices & events (limited features)
3. **Login** → QR Scan → Home Dashboard
4. **Browse** → Devices/Events → Details → Request/Register
5. **Track** → Cart Screen → Monitor request status
6. **Notifications** → Receive updates → Navigate to details

### Data Flow
1. **App Launch** → Load cached data → Display instantly
2. **Background** → Fetch fresh data from API
3. **Update** → Compare with cache → Update UI if changed
4. **Offline** → Use cached data → Queue requests
5. **Online** → Sync queued requests → Update cache

---

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

---

## 🤝 Contributing

Contributions, issues, and feature requests are welcome!

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

---

## 📞 Contact & Support

**Developer**: Chandan Kumar Singh

For questions, suggestions, or issues:
- GitHub: [@chandan-kumar-singh2063](https://github.com/chandan-kumar-singh2063)
- Repository: [eless-app](https://github.com/chandan-kumar-singh2063/eless-app)
- Issues: [GitHub Issues](https://github.com/chandan-kumar-singh2063/eless-app/issues)

---

## 🙏 Acknowledgments

- Flutter Team for the amazing framework
- GetX Team for state management
- Firebase Team for backend services
- Django REST Framework for API backend
- Open source community for packages and support

---

## 📊 Project Stats

- **Lines of Code**: 10,000+
- **Screens**: 53+
- **Controllers**: 10
- **Models**: 7
- **Services**: 20+
- **Reusable Widgets**: 50+
- **Development Time**: 3+ months

---

<div align="center">
  
  **Made with ❤️ by Chandan Kumar Singh**
  
  ⭐ Star this repo if you find it helpful!
  
</div>
