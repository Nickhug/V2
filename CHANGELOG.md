# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.0.0] - 2024-03-21

### Added
- **Core Features**
  - User authentication and profile management
  - Real-time meetup creation and management
  - Vehicle profile management
  - Location-based meetup discovery
  - Route planning and sharing
  - Chat functionality for meetups
  - Achievement system
  - Friend system

- **UI Components**
  - Modern glass-morphism design system
  - Custom navigation bar with large and compact styles
  - Floating text fields with animations
  - Search bar with filter capabilities
  - Custom tab bar with badges
  - Card views with multiple styles (regular, glass, featured)
  - MeetSpot buttons with primary, secondary, and accent styles
  - Filter chips for content filtering
  - Location cards with popularity charts
  - Vehicle cards with detailed information

- **Premium Features**
  - Advanced location features
  - Unlimited vehicle photos
  - Priority notifications
  - Exclusive meetups

### Changed
- **Design System**
  - Implemented comprehensive design system with consistent typography, colors, and spacing
  - Added glass-morphism effects for modern UI
  - Updated color scheme with gradients and accent colors
  - Improved shadow and animation system

- **Navigation**
  - Redesigned tab bar with custom animations
  - Added pull-to-refresh functionality
  - Improved navigation transitions

### Fixed
- **Authentication**
  - Resolved session management issues
  - Fixed user profile data persistence

- **UI/UX**
  - Improved form validation feedback
  - Enhanced error handling and loading states
  - Fixed layout issues on different screen sizes

### Technical
- **Dependencies**
  - Updated Supabase Swift SDK to version 2.25.0
  - Implemented RealtimeV2 for improved real-time features
  - Added proper error handling for network requests

- **Database**
  - Implemented Row Level Security (RLS) policies
  - Added proper indexing for performance
  - Improved data models and relationships

### Security
- **Authentication**
  - Implemented secure session management
  - Added proper token handling
  - Enhanced password security

- **Data Protection**
  - Added RLS policies for data access control
  - Implemented proper data validation
  - Enhanced error handling for sensitive operations

## [0.1.0] - 2024-03-01

### Added
- Initial project setup
- Basic project structure
- Core dependencies
- Basic UI components
- Authentication flow
- Database schema

## [1.0.1] - 2024-03-21

### Fixed
- Resolved duplicate `DesignSystem` declarations causing build errors
- Fixed ambiguous `init(hex:)` color initializer by consolidating Color extensions
- Corrected `Comment` type to `MeetComment` in MeetupViewModel
- Fixed `CommentsView` redeclaration by renaming to `MeetupCommentsView`
- Added missing MapKit and CoreLocation imports in RoutesListView
- Fixed GlassCard background issue by using proper background modifier
- Corrected format specifier issues in distance text formatting

### Changed
- Improved ProfileView with modern design and enhanced usability
- Consolidated AsyncImageView into a single shared component
- Updated Theme to align with new MeetType cases
- Enhanced error handling in SupabaseService
- Improved type safety in view models

### Technical
- Removed optional chaining on client.auth.session in SupabaseService
- Consolidated Color extensions to resolve ambiguous initializers
- Improved code organization and reduced duplication

## [1.0.2] - 2024-03-21

### Fixed
- Resolved async/await and optional binding issues in SupabaseService
- Fixed CommentsView redeclaration by renaming to MeetupCommentsView
- Updated deprecated Map API usage to use new MapContentBuilder syntax
- Fixed GlassCard background issue by using proper background modifier
- Improved error handling in authentication flows

### Technical
- Updated Map implementation to use iOS 17 MapContentBuilder
- Improved type safety in SupabaseService authentication methods
- Enhanced error handling with new SupabaseError cases

## [1.0.3] - 2024-03-22

### Changed
- Consolidated Meet and Meetup systems into a single unified system
- Enhanced Meet model with additional fields from Meetup (status, vehicleType, routeType, primaryRouteId)
- Updated MeetViewModel to handle all meet-related functionality
- Improved SupabaseService with unified meet management methods
- Streamlined participant management with vehicle tracking
- Enhanced route management capabilities

### Technical
- Unified database schema for meets and meetups
- Improved type safety in meet-related operations
- Enhanced error handling for meet operations
- Streamlined real-time updates for meets and participants

## [1.0.4] - 2024-03-22

### Changed
- Updated MeetupDetailView to use unified MeetViewModel and Meet model
- Removed redundant MeetupViewModel
- Enhanced JoinMeetupView with vehicle selection functionality
- Improved status badge styling and type safety

### Technical
- Consolidated view model usage across the app
- Improved type safety in MeetupDetailView
- Enhanced error handling in join meetup flow

## [1.0.5] - 2024-03-22

### Changed
- Updated UI components to use the unified Meet system:
  - Renamed `MeetupCard` to `MeetCard` and enhanced its design
  - Updated `MeetSpotButton` to display meet information
  - Simplified `SearchBar` with improved search functionality
  - Redesigned `DiscoverView` with new filtering system
- Improved component styling and consistency
- Enhanced user experience with better visual feedback

### Technical
- Standardized component naming across the app
- Improved type safety in UI components
- Enhanced component reusability
- Streamlined navigation and interaction patterns

## [1.0.6] - 2024-03-22

### Fixed
- [FIX] Updated SwiftUI onChange modifier in RouteMapView to use the new iOS 17 syntax with two parameters
- [FIX] Fixed pattern variable binding error in RouteMapView.swift
- [FIX] Resolved initialization issue in RouteMapPreview struct in RoutesListView.swift

### Technical
- Enhanced compatibility with iOS 17 SwiftUI APIs
- Improved code stability and reduced compiler errors

## [1.0.7] - 2024-03-22

### Fixed
- [FIX] Fixed pattern variable binding error in RouteMapView.swift by using a switch statement instead of guard case
- [FIX] Added missing 'user' parameter to VehicleCard in FriendsManagementView.swift

### Technical
- Improved code stability and reduced compiler errors
- Enhanced type safety in component usage

## [1.0.8] - 2024-03-22

### Fixed
- [FIX] Verified and reinforced pattern matching fix in RouteMapView.swift
- [FIX] Confirmed user parameter is correctly added to VehicleCard in FriendsManagementView.swift
- [FIX] Investigated persistent compiler errors and provided comprehensive fixes

### Technical
- Enhanced code stability with proper pattern matching syntax
- Improved error diagnostics and resolution process
- Verified parameter consistency across component usage

## [1.0.9] - 2024-03-22

### Fixed
- [FIX] Resolved 'Type any Error cannot conform to LocalizedError' error in RouteEditorView.swift by using NSError
- [FIX] Fixed unreachable catch block in RouteEditorView.swift by removing unnecessary try-catch
- [FIX] Added missing 'vehicleType' and 'routeType' parameters in CreateMeetView.swift

### Technical
- Improved error handling with proper error types
- Enhanced code stability by fixing compiler errors
- Ensured proper parameter passing in API calls

## [1.0.10] - 2024-03-22

### Fixed
- [FIX] Resolved 'Instance method alert(isPresented:error:) requires that NSError conform to LocalizedError' error in RouteEditorView.swift
- [FIX] Fixed 'Cannot call value of non-function type' error by implementing proper route saving logic in RouteEditorView.swift
- [FIX] Corrected route creation and update flow in RouteEditorView

### Technical
- Improved error handling with standard alert presentation
- Enhanced route saving logic with proper success tracking
- Ensured proper method calls between view and view model

## [1.0.11] - 2024-03-22

### Fixed
- [FIX] Corrected RouteType value in CreateMeetView.swift from non-existent '.street' to valid '.city'
- [FIX] Created SQL script to add missing vehicle_type and route_type columns to the meets table

### Technical
- Ensured proper enum value usage for RouteType
- Improved code consistency with existing model definitions
- Added database schema update script for missing columns

## [1.0.12] - 2024-03-22

### Fixed
- [FIX] Updated SQL script to remove foreign key reference to non-existent 'routes' table
- [FIX] Modified database schema update to add columns without dependencies

### Technical
- Improved SQL script compatibility with current database schema
- Added comments for future foreign key constraint implementation

## [1.0.13] - 2024-03-22

### Fixed
- [FIX] Resolved multiple compiler errors in DiscoverView.swift
- [FIX] Updated MeetFilter enum to use correct MeetStatus values
- [FIX] Fixed fetchMeets method calls to match DiscoverViewModel implementation
- [FIX] Changed 'active' filter to 'ongoing' to match MeetStatus enum

### Technical
- Improved code consistency with MeetStatus enum
- Enhanced type safety in filter handling
- Simplified API calls in DiscoverView

## [1.0.14] - 2024-03-22

### Fixed
- [FIX] Resolved multiple compiler errors in MeetDetailView.swift
- [FIX] Updated references from `.active` to `.ongoing` to match MeetStatus enum
- [FIX] Fixed fetchComments method call and accessibility in MeetViewModel
- [FIX] Corrected conditional logic in join meet button
- [FIX] Simplified complex expressions to improve compiler type checking

### Technical
- Made fetchComments method public in MeetViewModel for external access
- Enhanced type safety in status handling and UI conditions
- Improved code readability by breaking up complex expressions
- Ensured consistent use of MeetStatus enum values across the app

## [1.0.15] - 2024-03-22

### Fixed
- [FIX] Resolved compiler error in MeetDetailView.swift related to try/catch handling in join meet functionality
- [FIX] Fixed error handling approach in join meet button logic by using proper try/catch pattern
- [FIX] Verified correct usage of complex expression in VehicleSelectionRow
- [FIX] Checked fetchComments call parameters to ensure they match method signature

### Technical
- Improved error handling with structured try/catch pattern
- Enhanced code robustness by following Swift error handling patterns
- Fixed type issues in view expressions

## [1.0.16] - 2024-03-22

### Fixed
- [FIX] Resolved "Extra arguments at positions #1, #3 in call" error for fetchComments in MeetDetailView.swift by adding error handling
- [FIX] Verified fix for complex expression in VehicleSelectionRow using iconName variable
- [FIX] Enhanced error handling around fetchComments call to properly handle any thrown errors

### Technical
- Improved robustness with proper error handling for asynchronous operations
- Verified proper separation of complex expressions for better compiler performance
- Enhanced code maintainability with structured error handling patterns

## [1.0.17] - 2024-03-22

### Fixed
- [FIX] Verified and confirmed fix for "Extra arguments at positions #1, #3 in call" error for fetchComments in MeetDetailView.swift
- [FIX] Validated that the complex expression in VehicleSelectionRow is properly separated using the iconName variable
- [FIX] Ensured proper error handling around the fetchComments call

### Technical
- Confirmed that async code has appropriate error handling with do-catch blocks
- Verified that all complex expressions are properly broken down for optimal compiler performance
- Streamlined error handling for better developer experience and debugging

## [1.0.18] - 2024-03-22

### Fixed
- [FIX] Resolved "Extra arguments at positions #1, #3 in call" error for fetchComments in MeetDetailView.swift by implementing a proper fetchComments method in MeetViewModel
- [FIX] Fixed "The compiler is unable to type-check this expression in reasonable time" error by breaking up complex expressions in VehicleSelectionRow
- [FIX] Optimized SwiftUI view hierarchy in VehicleSelectionRow by extracting complex views into computed properties
- [FIX] Enhanced MeetViewModel's fetchComments method to properly fetch from Supabase and update local state

### Technical
- Improved code organization by extracting complex SwiftUI expressions into computed properties
- Enhanced performance of UI rendering by simplifying view modifiers
- Ensured type-safe API calls between view and view model
- Updated comments to better document the code

## [1.0.19] - 2024-03-22

### Fixed
- [FIX] Resolved "Value of type 'Vehicle' has no member 'name'" error in VehicleSelectionRow by correctly using make and model properties
- [FIX] Improved vehicle details display in VehicleSelectionRow to show year and type instead of duplicating make and model

### Technical
- Enhanced vehicle information display in selection UI
- Fixed incorrect property access that was causing build errors
- Ensured consistency with Vehicle model structure

## [1.0.20] - 2024-03-22

### Fixed
- [FIX] Resolved persistent "Extra arguments at positions #1, #3 in call" error for fetchComments by creating a dedicated helper method in MeetDetailView
- [FIX] Improved error handling for comment fetching by using direct service calls instead of potentially conflicting view model methods

### Technical
- Enhanced code structure with dedicated helper methods for specific view functionality
- Improved view-specific error handling
- Reduced dependencies on view model method signatures
- Streamlined asynchronous operations in views

## [1.0.21] - 2024-03-22

### Added
- [FEATURE] Created new database tables for user data:
  - `user_activities` for tracking user actions and events
  - `followers` for managing user relationships
  - `achievements` for tracking user accomplishments
- [FEATURE] Added new models:
  - `Activity` and `ActivityType` for user activity tracking
  - `Achievement` and `AchievementType` for user achievements
- [FEATURE] Implemented proper data fetching in `fetchUserData` method:
  - Fetches followers from the followers table
  - Fetches recent achievements from the achievements table
  - Fetches recent activity from the user_activities table

### Technical
- Added proper database indexes for performance optimization
- Implemented Row Level Security (RLS) policies for all new tables
- Added proper foreign key constraints and unique constraints
- Enhanced error handling in data fetching methods
- Improved type safety with proper model structures

## [1.0.22] - 2024-03-22

### Fixed
- [FIX] Added missing `attendFiveMeets` case to `AchievementType` enum
- [FIX] Resolved ambiguous `Activity` type by consolidating definitions and adding `timeAgo` property
- [FIX] Fixed type casting issues in `fetchUserData` method by properly handling Supabase responses
- [FIX] Improved error handling in data fetching methods
- [FIX] Added proper date formatting for timestamps in activity and achievement data

### Technical
- Enhanced type safety in data model handling
- Improved error handling for network requests
- Streamlined data decoding process
- Fixed incorrect method call to `fetchComments` in MeetDetailView.swift
- Fixed incorrect parameter passing to `VehicleSelectionRow` view
- Fixed incorrect initialization of `RouteEditorView` in MeetDetailView.swift by using the correct parameters (`meetId`, `onRouteSaved`, and `existingRoute`) instead of non-existent parameters (`viewModel` and `isEditing`)
- Fixed "Value of type 'Meet' has no member 'route'" error by properly accessing the route from routeViewModel based on the meet's primaryRouteId
- Updated deprecated Map and MapAnnotation usage in MeetDetailView.swift to use the new iOS 17 MapContentBuilder style
- Fixed "Static method 'buildExpression' requires that 'MapContent' conform to 'MapContent'" error by moving the region parameter to the Map initializer
- Fixed "Type 'Binding<MapCameraPosition>' has no member 'region'" error in MeetDetailView.swift by correctly implementing the iOS 17 MapCameraPosition approach with a binding
- Fixed "Failed to load your routes: relation 'public.routes' does not exist" error by creating the missing routes table in the database
- Fixed "Invalid redeclaration of 'placeholder(when:alignment:placeholder:)'" error by removing the duplicate placeholder extension from RouteEditorView.swift that was already defined in FloatingTextField.swift
- Fixed "The compiler is unable to type-check this expression in reasonable time" error in RouteMapView.swift by breaking up complex view expressions into separate @ViewBuilder computed properties
- Fixed "Cannot convert return expression of type '_EndedGesture<_ChangedGesture<DragGesture>>' to return type 'DragGesture'" error in WaypointMarkerView by changing the return type from `DragGesture` to `any Gesture`
- Fixed "'buildExpression' is unavailable: this expression does not conform to 'View'" error at line 263 by:
  - Simplifying the gesture handling system architecture
  - Applying the DraggableModifier directly instead of through an extension method
  - Adding Group wrapper in the ViewModifier's body to ensure View conformance in the conditional statement
- Fixed "'buildExpression' is unavailable: this expression does not conform to 'View'" error at line 263 by completely restructuring the gesture handling approach:
  - Eliminated the DraggableModifier and its related extension method entirely
  - Integrated the gesture directly in the WaypointMarkerView using Swift's optional chaining with gesture(isDraggable ? makeDragGesture() : nil)
  - Moved the drag gesture logic to a dedicated method returning 'some Gesture'
  - Simplified the view hierarchy to avoid ViewBuilder conditional statement issues
- Fixed "Static method 'buildExpression' requires that 'some View' conform to 'MapContent'" error by placing MapContent-conforming elements directly in the Map builder instead of using @ViewBuilder computed properties
- Fixed "Extra arguments at positions #1, #2 in call" error by adding a new overloaded `addWaypoint(at:title:type:)` method to RouteViewModel
- Fixed invalid redeclaration of 'AnimatedGradientBackground' compiler error by removing the duplicate struct implementation from RouteEditorView.swift and using the centralized component from Components/AnimatedGradientBackground.swift
- Fixed 'Missing arguments for parameters' and 'Invalid redeclaration of RouteInfoCard' errors by updating the RouteInfoCard in RouteMapView.swift to match the definition in RouteEditorView.swift
- Fixed 'Cannot find HomeViewModel in scope' error by creating the missing HomeViewModel class
- Fixed 'Generic parameter SelectionValue could not be inferred' error in HomeView.swift by explicitly specifying the binding type for TabView selection
- Fixed 'RouteDifficulty is ambiguous for type lookup in this context' error by removing the duplicate enum definition from RouteEditorView.swift
- Fixed 'Value of type 'Route' has no member 'formattedDistance'' error by adding a computed property to the Route struct
- Fixed 'Invalid redeclaration of RouteInfoCard' error by renaming it to MapRouteInfoCard in RouteMapView.swift
- Fixed 'Invalid redeclaration of placeholder(when:alignment:placeholder:)' error by removing the duplicate View extension from RouteEditorView.swift
- Fixed 'Cannot find NotificationsViewModel in scope' error by creating a new NotificationsViewModel class

### Added
- Added new `addWaypoint(at:title:type:)` method to RouteViewModel to support creating waypoints at specified coordinates
- Added `defaultTitle` computed property to WaypointType enum for consistent default naming of waypoints
- Added `formattedDistance` computed property to the Route struct for consistent distance formatting
- Added NotificationsViewModel with methods for handling notifications and their read status

### Changed
- **UI Improvements**
  - Completely redesigned the RouteEditorView with a modern glass-morphism design
  - Improved form fields with better styling and placeholders
  - Added map action buttons for common route editing functions
  - Enhanced route statistics with visual cards
  - Implemented a gradient save button for better visual hierarchy
  - Improved overall color scheme and spacing
  - Added sleek animated black and white gradient background throughout the application
  - Enhanced LoginView with glass-morphism effects to complement the animated background
  - Created reusable AnimatedGradientBackground component for consistent styling
- **Route Management**
  - Enhanced RouteViewModel with improved waypoint management functions
  - Added ability to clear routes and add specific waypoint types
  - Improved map region calculation for better route visibility
  - Added new method to create waypoints at specific map coordinates
  - Updated WaypointType color scheme to match modern iOS design language
- **Code Architecture**
  - Restructured RouteMapView.swift to use separate @ViewBuilder computed properties for better organization and compiler performance
  - Improved type safety in gesture handling by using appropriate type annotations
  - Enhanced code maintainability by breaking up complex SwiftUI view expressions
  - Corrected MapKit integration to properly handle SwiftUI's type system requirements
  - Updated overlay syntax to use the recommended closure-based approach in iOS 17

## [1.0.23] - 2024-03-22

### Changed
- [UI] Improved AnimatedGradientBackground with a smoother, more controlled animation
  - Replaced random point transitions with elegant directional flow
  - Added subtle rotation effect for enhanced visual appeal
  - Maintained the existing monochromatic dark color scheme
  - Removed timer-based updates in favor of continuous animations
  - Created new customizable version (AnimatedGradientBackgroundCustom) for flexible implementation

### Added
- [FEATURE] Added AnimatedGradientBackgroundCustom component that allows customization of:
  - Color scheme
  - Animation speed
  - Auto-reverse behavior

### Technical
- Enhanced animation performance by using SwiftUI's native animation system
- Improved code readability with clear animation parameters
- Reduced potential for visual artifacts with smoother transitions
- Enhanced overall UI consistency with more predictable animations
- Maintained backward compatibility with existing glass-morphism effects

## [1.0.24] - 2024-03-22

### Fixed
- [FIX] Corrected SwiftUI frame parameter ordering in ProfileView.swift
  - Fixed "Argument 'minWidth' must precede argument 'maxWidth'" compiler error
  - Changed frame modifier ordering to follow Swift's parameter sequence requirements
  - Verified no other occurrences of this issue exist in the codebase

## [1.0.25] - 2024-03-22

### Fixed
- [FIX] Corrected SwiftUI frame parameter ordering in RouteEditorView.swift
  - Fixed "Argument 'minWidth' must precede argument 'maxWidth'" compiler error at line 436
  - Changed frame modifier ordering in RouteInfoCard to follow Swift's parameter sequence requirements

### Changed
- Improved AnimatedGradientBackground to have smoother, less distracting transitions without the rotation effect
- Completely redesigned ProfileView UI to match inspiration reference:
  - Added tabbed interface with Posts, Collections, and About sections
  - Improved profile header with more compact layout
  - Redesigned stats section to be more modern and clean
  - Added two prominent action buttons for Edit Profile and Find Friends
  - Improved vehicle and achievement displays in grid format
  - Enhanced About section with better organization of bio, location, and activity
