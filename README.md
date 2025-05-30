# About

BikeCheck is your personal bike maintenance assistant. Connect with Strava to sync your bikes and track your riding hours. Get timely service reminders for your ALL of your bikes and components.
KEY FEATURES:

Seamless Strava integration auto imports your bikes and activities
Customizable service intervals for different bike components
Smart notifications when maintenance is due
Track multiple bikes with individual service schedules
Create default service templates for quick setup
Never miss critical maintenance again. BikeCheck helps you extend the life of your components and ensures your bike is always ready to ride. Perfect for mountain bikers, road cyclists, and anyone who wants to keep their bike running smoothly.
Download BikeCheck today and give your bike the care it deserves!

# App Privacy

BikeCheck is built with your privacy as a priority. The app only collects Strava data that you explicitly authorize during sign-in, and all information remains securely stored on your device—we never upload or sync your data to external servers. The Strava information we store locally includes: athlete profile details (name and profile picture), bike information (names, IDs, and distances), activity data (rides, moving times, distances, dates, and average speeds), and authentication tokens for maintaining your Strava connection. Your cycling habits and maintenance schedules are your business alone.

# BikeCheck User Guide

## Getting Started

When you first open BikeCheck, you'll be greeted with a login screen featuring the BikeCheck logo. Tap "Sign in with Strava" to connect your Strava account. After authorizing the app, BikeCheck will automatically import your bikes and riding activities.

## Main Interface

BikeCheck features three main tabs at the bottom of your screen:

1. **Service Intervals** - This is your maintenance dashboard. You'll see a list of all your service intervals sorted by urgency, displaying the bike name, component to be serviced, and time remaining until service is due. Components that are overdue will be highlighted in red.

2. **Bikes** - View all your imported Strava bikes. Each bike shows its name and total ride time. Tap on any bike to see detailed information including total mileage, ride hours, and activity count.

3. **Activities** - Browse your recent rides imported from Strava. Each activity displays the name, duration, distance, associated bike, and date.

## Managing Service Intervals

### Creating Service Intervals

You can add new service intervals in two ways:
- Tap the "+" button in the Service Intervals tab to create a custom interval
- From a bike's detail page, tap "Create Default Service Intervals" to quickly generate common maintenance schedules

When creating a service interval, you'll select a bike, specify the part to be maintained (e.g., "chain"), set the interval time in hours, and choose whether to receive notifications.

### Editing and Resetting

When viewing a service interval, you can:
- Edit any detail by changing the values
- Reset the interval to start the countdown fresh after performing maintenance
- Delete the interval when no longer needed

## Notifications

BikeCheck will send you notifications when components are due for service, ensuring you never miss critical maintenance. All notifications are managed locally on your device.

Enjoy keeping your bikes in peak condition with BikeCheck!

# BikeCheck Application Architecture

BikeCheck is an iOS application designed to help cyclists track and manage bicycle maintenance schedules based on ride time. The app integrates with Strava to fetch ride data and calculates when maintenance should be performed on different bike components.

## Overview

BikeCheck follows the MVVM (Model-View-ViewModel) architectural pattern with SwiftUI for the user interface. The app uses Core Data for local data persistence and includes Strava API integration for fetching athlete data, bikes, and activities.

## Application Structure

### Models

The data model layer consists of Core Data entities:

1. **Bike**: Represents a bicycle with properties such as ID, name, and distance.
2. **Activity**: Represents a riding activity with properties like distance, duration, and date.
3. **ServiceInterval**: Represents maintenance schedules for bike components.
4. **Athlete**: Represents the user with Strava profile information.
5. **TokenInfo**: Manages authentication tokens for Strava API access.

### ViewModels

ViewModels serve as intermediaries between Views and Models, handling business logic and data transformations:

1. **BikesViewModel**: Manages bikes data for display and manipulation.
2. **ActivitiesViewModel**: Handles activity data processing and formatting.
3. **ServiceViewModel**: Manages service intervals and maintenance calculations.
4. **AddServiceIntervalViewModel**: Handles creation and editing of service intervals.
5. **BikeDetailViewModel**: Provides bike-specific data and operations.
6. **LoginViewModel**: Manages authentication flow.

### Views

The UI layer is built with SwiftUI and organized into several key screens:

1. **HomeView**: Main tab-based container view with navigation to other screens.
2. **BikesView**: Displays the user's bikes and provides navigation to bike details.
3. **BikeDetailView**: Shows detailed information about a specific bike.
4. **ActivitiesView**: Lists riding activities with relevant information.
5. **ServiceView**: Displays maintenance schedules and service intervals.
6. **AddServiceIntervalView**: Interface for creating or editing service intervals.
7. **LoginView**: Handles authentication with Strava.

### Services

Service classes handle specific application functionalities:

1. **StravaService**: Manages Strava API integration, authentication, and data fetching.
2. **DataService**: Provides Core Data operations for fetching and manipulating local data.
3. **NotificationService**: Handles local notifications for service reminders.
4. **PersistenceController**: Manages Core Data stack initialization and context.

## Data Flow

1. **Authentication Flow**:
   - User authenticates with Strava via OAuth in LoginView
   - TokenInfo is stored in Core Data
   - StravaService uses tokens to fetch user data

2. **Data Synchronization**:
   - StravaService fetches athlete data, bikes, and activities
   - Data is decoded and stored in Core Data
   - ViewModels load data from Core Data via DataService

3. **Service Interval Management**:
   - User creates service intervals for bike components
   - App calculates ride time from activities
   - Notifications are sent when service is due

## Background Tasks

BikeCheck supports background tasks for:
1. Checking service intervals and sending notifications
2. Fetching new activities from Strava

## Demo Mode

The app includes a demo mode for testing without Strava authentication, which creates sample bikes, activities, and service intervals.

## Shared Objects and Singletons

BikeCheck makes extensive use of the singleton pattern to ensure consistent state management throughout the app lifecycle:

1. **StravaService.shared**:
   - Central hub for all Strava API interactions
   - Manages authentication state, athlete data, and API requests
   - Publishes state changes via Combine's @Published properties
   - Ensures only one instance handles network operations and maintains tokens

2. **DataService.shared**:
   - Provides standardized access to Core Data operations
   - Centralizes data fetching and persistence logic
   - Ensures consistency in how data is retrieved and manipulated

3. **PersistenceController.shared**:
   - Single source of truth for Core Data stack configuration
   - Manages NSPersistentContainer and viewContext creation
   - Handles merge policies and automatic merging of changes

4. **NotificationService.shared**:
   - Centralizes notification logic and permissions handling
   - Manages scheduling of local notifications for service reminders
   - Handles background task registration for service checks

### Dependency Injection

The app uses environment objects to inject these shared services down the view hierarchy:

```swift
// In bikecheckApp.swift
@StateObject var stravaService = StravaService.shared
// ...

HomeView()
    .environmentObject(stravaService)
    .environmentObject(bikesViewModel)
    // ...
```

This approach allows views to access shared objects via the @EnvironmentObject property wrapper:

```swift
// In a view file
@EnvironmentObject var stravaService: StravaService
```

### Shared ViewModels

ViewModels are initialized as @StateObject instances at the app level in bikecheckApp.swift to maintain consistent state across view transitions:

```swift
@StateObject var bikesViewModel = BikesViewModel()
@StateObject var activitiesViewModel = ActivitiesViewModel()
@StateObject var serviceViewModel = ServiceViewModel()
@StateObject var loginViewModel = LoginViewModel()
```

This ensures that data doesn't need to be reloaded when navigating between tabs and helps preserve application state.

## Dependencies

- **Alamofire**: HTTP networking library for API requests
- **Core Data**: For local data persistence
- **Combine**: For reactive programming patterns
- **SwiftUI**: For building the user interface
- **BackgroundTasks**: For background processing

## Application Lifecycle

1. App initializes with PersistenceController to set up Core Data
2. StravaService checks for existing authentication
3. If authenticated, HomeView is presented with tabs for Services, Bikes, and Activities
4. If not authenticated, LoginView is presented for Strava login
5. After successful authentication, data is fetched and displayed in the appropriate views

## Architecture Diagram

```
┌─────────────────────────────────────────────────┐
│                     Views                        │
│  ┌───────────┐ ┌───────────┐ ┌───────────┐      │
│  │ HomeView  │ │ BikesView │ │ServiceView│ ...  │
│  └───────────┘ └───────────┘ └───────────┘      │
└───────────────────┬─────────────────────────────┘
                    │
┌───────────────────▼─────────────────────────────┐
│                 ViewModels                       │
│  ┌───────────┐ ┌───────────┐ ┌───────────┐      │
│  │BikesVM    │ │ServiceVM  │ │ActivitiesVM ...  │
│  └───────────┘ └───────────┘ └───────────┘      │
└───────────────────┬─────────────────────────────┘
                    │
┌───────────────────▼─────────────────────────────┐
│                  Services                        │
│  ┌───────────┐ ┌───────────┐ ┌───────────┐      │
│  │StravaService│DataService│ │NotificationService│
│  └───────────┘ └───────────┘ └───────────┘      │
└───────────────────┬─────────────────────────────┘
                    │
┌───────────────────▼─────────────────────────────┐
│                   Models                         │
│  ┌───────────┐ ┌───────────┐ ┌───────────┐      │
│  │   Bike    │ │  Activity │ │ServiceInterval    │
│  └───────────┘ └───────────┘ └───────────┘      │
└───────────────────┬─────────────────────────────┘
                    │
┌───────────────────▼─────────────────────────────┐
│              Persistence Layer                   │
│            (Core Data, UserDefaults)             │
└─────────────────────────────────────────────────┘
```

## Key Features

1. **Strava Integration**: Seamlessly imports bikes and activities from Strava
2. **Service Tracking**: Tracks maintenance schedules based on actual ride time
3. **Notifications**: Sends reminders when service is due
4. **Component-specific Tracking**: Manages maintenance for different bike components separately

# Testing Framework

BikeCheck includes comprehensive unit and UI testing infrastructure to ensure code quality and reliability.

## Unit Tests (`bikecheckTests`)

Unit tests use dependency injection with mock objects to test business logic in isolation. The mock infrastructure provides an in-memory Core Data stack and test data creation utilities. Tests inject mock dependencies into services to verify functionality without affecting real app data.

**Key Components:**
- MockPersistenceController with in-memory Core Data
- PersistenceControllerProtocol for dependency injection
- Automated test data creation methods
- Isolated test environment

## UI Tests (`bikecheckUITests`)

UI tests use automatic test data injection without manual UI interaction. When launched with the `UI_TESTING` argument, the app automatically loads test data, eliminating the need for button tapping or manual setup.

**Key Components:**
- BikeCheckUITestCase base class for shared setup
- Automatic test data loading via launch arguments
- Helper methods for common UI operations
- No manual UI interaction required for test data

## Test Architecture Diagram

```
┌─────────────────────────────────────────────────────────┐
│                    Main App Target                       │
│  ┌─────────────────┐    ┌─────────────────┐            │
│  │PersistenceController │   StravaService │            │
│  │     (Real)       │    │     (Real)      │            │
│  └─────────────────┘    └─────────────────┘            │
└─────────────────────────────────────────────────────────┘
                               │
           ┌───────────────────┼───────────────────┐
           │                   │                   │
           ▼                   ▼                   ▼
┌─────────────────┐  ┌─────────────────┐  ┌─────────────────┐
│ bikecheckTests  │  │bikecheckUITests │  │    App with     │
│    Target       │  │    Target       │  │  UI_TESTING     │
│                 │  │                 │  │    Flag         │
│ ┌─────────────┐ │  │ ┌─────────────┐ │  │ ┌─────────────┐ │
│ │MockPersist- │ │  │ │BikeCheckUI- │ │  │ │Auto Test    │ │
│ │enceController│ │  │ TestCase    │ │  │ │Data Loading │ │
│ │             │ │  │             │ │  │ │             │ │
│ │ • In-memory │ │  │ • Launch    │ │  │ │ • Detects   │ │
│ │   Core Data │ │  │   args      │ │  │ │   UI_TESTING│ │
│ │ • Test data │ │  │ • Helper    │ │  │ │ • Calls     │ │
│ │   creation  │ │  │   methods   │ │  │ │   insertTest│ │
│ │             │ │  │             │ │  │ │   Data()    │ │
│ └─────────────┘ │  │ └─────────────┘ │  │ └─────────────┘ │
│                 │  │                 │  │                 │
│ ┌─────────────┐ │  │ ┌─────────────┐ │  │                 │
│ │DataService- │ │  │ │Actual UI    │ │  │                 │
│ │Tests        │ │  │ │Tests        │ │  │                 │
│ │             │ │  │             │ │  │                 │
│ │ • Injects   │ │  │ • Inherit   │ │  │                 │
│ │   mocks     │ │  │   from base │ │  │                 │
│ │ • Tests     │ │  │ • Test user │ │  │                 │
│ │   business  │ │  │   workflows │ │  │                 │
│ │   logic     │ │  │             │ │  │                 │
│ └─────────────┘ │  │ └─────────────┘ │  │                 │
└─────────────────┘  └─────────────────┘  └─────────────────┘
```

## Test Flow

**Unit Test Flow:**
1. Test creates MockPersistenceController with in-memory Core Data
2. Mock is injected into service under test
3. Test data is created programmatically
4. Business logic is tested in isolation
5. No real app data is affected

**UI Test Flow:**
1. Test launches app with UI_TESTING launch argument
2. App detects flag and automatically loads test data
3. UI test runs against fully populated app
4. Tests verify user workflows and navigation
5. No manual setup or button interaction required

This architecture ensures test isolation, reliability, and maintainability while providing comprehensive coverage of both business logic and user experience.

## Future Improvements

1. Offline mode with manual activity entry
2. Service history tracking
3. More detailed component tracking
4. Multiple service notification thresholds
5. Additional fitness platform integrations