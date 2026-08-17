# PlayHub Project: Frontend MVP

## 1. Introduction

This document details the implementation of PlayHub, a Sports & Activity Booking Platform, developed as a frontend-only Minimum Viable Product (MVP) using Flutter. The application adheres to a clean architecture, providing a responsive user interface across multiple platforms (Android, iOS, Web, Tablet, Desktop) without any direct backend or database integrations. All backend interactions are represented by abstract interfaces and dummy local data.

## 2. Implemented Features

This MVP includes the following key features:

*   **Complete Flutter Project Structure**: Organized using a feature-first approach within a Clean Architecture paradigm.
*   **Core Models**: Dart classes for `User`, `Business`, `Venue`, `Activity`, `Category`, `Slot`, `Booking`, `Review`, `City`, and `Notification`.
*   **Abstract Repositories & Dummy Data**: Interfaces for data access and concrete implementations using in-memory dummy data, ensuring backend independence.
*   **State Management**: Integrated with Riverpod for efficient and scalable state management.
*   **Routing**: Configured with GoRouter for declarative navigation.
*   **Theming**: Implemented with Material 3, supporting both Light and Dark modes using `flex_color_scheme` and `google_fonts`.
*   **Responsive Layouts**: Utilizes `responsive_framework` to adapt the UI across various screen sizes.
*   **Customer Application Screens**:
    *   **Login Screen**: Basic UI for user authentication.
    *   **Home Screen**: Displays categories, popular venues, and a search bar.
    *   **Venue Details Screen**: Shows detailed information about a venue, including images, description, amenities, and a booking call-to-action.
    *   **Profile Screen**: User profile view with options for bookings, favorites, and navigation to dashboards.
*   **Business Owner Dashboard UI**: A basic dashboard providing an overview of bookings, revenue, and venue management options.
*   **Admin Dashboard UI**: A responsive web dashboard for platform overview, pending approvals, and management functionalities.

## 3. Technical Stack

*   **Framework**: Flutter (Latest Stable)
*   **Architecture**: Clean Architecture, Feature-First Structure, SOLID Principles, Repository Pattern, Dependency Injection Ready.
*   **State Management**: Riverpod
*   **Routing**: GoRouter
*   **UI/Styling**: Material 3, FlexColorScheme, Google Fonts, Responsive Framework
*   **Local Storage (Abstraction)**: SharedPreferences (abstraction only)

## 4. Project Structure

The project adheres to the following directory structure:

```
playhub/
├── lib/
│   ├── core/               # Core functionalities, common utilities, base classes
│   │   ├── constants/      # App-wide constants
│   │   ├── models/         # Global data models
│   │   ├── providers/      # Riverpod providers for repositories
│   │   ├── repositories/   # Abstract repository interfaces and dummy implementations
│   │   └── theme/          # Application theme definitions
│   ├── features/           # Feature-specific modules
│   │   ├── admin_dashboard/ # Admin dashboard feature
│   │   ├── auth/           # Authentication feature
│   │   ├── booking/        # Booking feature
│   │   ├── business_dashboard/ # Business owner dashboard feature
│   │   ├── home/           # Home screen feature
│   │   ├── profile/        # User profile feature
│   │   ├── search/         # Search feature
│   │   └── venues/         # Venue management/details feature
│   ├── routes/             # GoRouter configuration
│   ├── shared/             # Reusable widgets, components
│   ├── main.dart           # Application entry point
│   └── app.dart            # Root widget, theme, router setup
├── assets/                 # Images, fonts, other assets
├── test/                   # Unit and widget tests
├── pubspec.yaml            # Project dependencies and metadata
└── README.md               # Project documentation
```

## 5. How to Run the Application

To run the PlayHub application, follow these steps:

1.  **Ensure Flutter is Installed**: Make sure you have Flutter installed on your system. If not, follow the official Flutter installation guide: [https://flutter.dev/docs/get-started/install](https://flutter.dev/docs/get-started/install)

2.  **Navigate to Project Directory**:
    ```bash
    cd playhub
    ```

3.  **Get Dependencies**:
    ```bash
    flutter pub get
    ```

4.  **Run the Application**:
    *   **For Web**: 
        ```bash
        flutter run -d chrome
        ```
    *   **For Desktop (Linux/Windows/macOS)**: Ensure desktop support is enabled (`flutter config --enable-linux-desktop`, etc.) then:
        ```bash
        flutter run -d linux # or windows, macos
        ```
    *   **For Android/iOS**: Connect a device or start an emulator/simulator, then:
        ```bash
        flutter run
        ```

    The application will start on the login screen (`/login`). You can navigate to other screens using the GoRouter setup.

## 6. Future Enhancements

The architecture is designed to support future additions such as:

*   Payments, Wallet, Membership Plans, Coupons, Referral Program
*   Tournaments, Team Creation, Chat
*   WhatsApp Notifications, Push Notifications, Live Availability
*   AI Recommendations, Multi-language Support, Multi-country Expansion
*   Integration with a real backend service (e.g., Firebase, Supabase, custom API) by implementing the abstract repository interfaces.

This MVP provides a solid foundation for a production-grade application, ready for backend integration and further feature development.
