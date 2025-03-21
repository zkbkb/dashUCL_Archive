# About dashUCL
**dashUCL** is an iOS-native application that provides students at **University College London** with access to essential information to help them navigate their study and campus life. The underlying technology retrieves UCL data from API endpoints developed by **[UCL API](https://github.com/uclapi/uclapi)**.

This app integrates and **displays** ```user information``` and ```timetables```, as well as **search** functionality for ```people, department information, study spaces, and available rooms```. 

Other features such as ```booking and management``` of ```study spaces and available rooms``` may also be developed in the future.

# Setup    
## Development Setup
For this setup to work you need to have xcode and node + pnpm installed. This guide has only been tested on MacOS.

1. Clone the repository:
```bash
git clone https://github.com/zkbkb/dashUCL.git
cd dashUCL
```

2. Install dependencies:
```bash
pnpm install
```

3. Open the project in xcode:
	```bash
	open DashUCL.xcodeproj
	```

4. Run the project:
```bash
pnpm run ios
```
Before running the project, you need to setup the configuration files. Including:
- Get UCL API Client ID and Client Secret from [UCL API](https://github.com/uclapi/uclapi)
  
## Configuration
This project uses xcconfig files to manage environment-specific settings such as API keys and service URLs. I use supabase to perform the backend functions. Take it as an example, to set up your configuration:

1. Copy the example configuration file:
```bash
cp Config.xcconfig.example Config.xcconfig
```

2. Setup Supabase project, create your own edge functions:
```bash
cd supabase
supabase functions new [YOUR_FUNCTION_NAME]
```  

3. Deploy your edge functions:
```bash
supabase functions deploy [YOUR_FUNCTION_NAME]
```

4. Edit `Config.xcconfig` with your actual values:
```
UCL_CLIENT_ID = your_client_id_here  # Get from UCL API
SUPABASE_URL = your_supabase_url_here
SUPABASE_FUNCTIONS_URL = your_supabase_functions_url_here
SUPABASE_AUTH_URL = your_supabase_auth_url_here
```
You can stored the UCL API Client ID and Secret in the environment variables of the supabase project.

1. Setup Supabase environment variables:
```bash
cd supabase
cp .env.example .env
```

1. Edit `supabase/.env` with your credentials.

Note: Make sure to exclude the configuration files containing secrets (*.xcconfig and supabase/.env) from version control in .gitignore.

---

# Technical Overview 
(Generated on 2025-03-21 by Claude)

## Technology Stack

- **Frontend Framework**: Swift and SwiftUI
- **Backend**: Edge functions written in TypeScript for API integration
- **Server**: Supabase cloud computing services
- **Architecture Pattern**: MVVM (Model-View-ViewModel)

The application follows a feature-oriented directory structure, organizing code by functionality, which makes the codebase more maintainable and enables better feature isolation.

## Directory Structure

- **App**: Application entry point and configuration
- **Features**: Feature modules organized by business domain
- **Core**: Shared services, models, and utilities
- **UI**: Reusable UI components and views
- **Extensions**: Swift and iOS framework extensions
- **Resources**: Assets and static resources

## Core Components

### App Initialisation and Lifecycle

The application initializes global services like theme management and authentication state observation during startup.

### Navigation

A centralized `NavigationManager` handles all navigation throughout the app, enabling:
- Programmatic navigation between screens
- Deep linking support
- Navigation history management
- Tab-based navigation with a custom tab bar

### Network Layer

The network layer is responsible for all API interactions and includes:
- REST API client for UCL services
- Response parsing and error handling
- Caching of network responses
- Mock services for testing and development
- Type-safe API endpoints definition

### Storage System

The application implements several storage mechanisms:
- `CacheManager`: For temporary data caching
- `PersistentStorage`: For long-term data persistence
- `DataCleanupService`: For maintaining storage efficiency
- `StaticDataManager`: For managing predefined data sets

### Theme Management

The app supports theming with:
- Light and dark mode
- In SwiftUI, uses `Color` and `ColorScheme` to manage the theme.

## Feature Modules

### Home

The home screen provides access to key information and serves as the main entry point to the application. It includes personalized content for the signed-in user, such as upcoming timetable events and frequently accessed resources.

### Timetable

The timetable feature displays the student's class schedule with:
- Day, week, and month views
- Event details including location, time, and instructor information
- Notifications for upcoming events (In Settings)

### Spaces

The spaces feature helps students find and use campus facilities:
- Study space and Computer cluster availability monitoring and search
- Navigation to spaces
- Though data is retrieved from UCL API, the app hardcodes some public building information for response consistency.

### Search

A universal search feature allows searching across:
- People and staff directories
- Department information
- Study Spaces and Computer Clusters

### Settings

The settings section provides user configuration options:
- Account management
- Notification preferences
- Theme selection
- Other entries for information and support

### Login

The login feature handles user authentication:
- UCL credentials login
- Session persistence
- Secure token management
- Terms and conditions agreement

### Others (To be completed)   
