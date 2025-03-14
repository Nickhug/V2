# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.0.5] - 2025-03-19

### Fixed
- [FIX] **Resolved compiler errors in StoryCreationView.swift**:
  - Fixed 'Cannot find activeTextEditId in scope' error by removing reference in handleToolTap method
  - Fixed 'Cannot find getFont in scope' error by adding the function to StoryEditorView
  - Removed extraneous closing brace that was causing compilation failure at line 1720
  - Improved code organization and scope management in text editing functionality
  - [REF:StoryCreationView.swift]

### Changed
- [UI] **Redesigned picture editing tools with Instagram-style minimalist interface**:
  - Streamlined bottom toolbar with simplified icon-only controls
  - Improved photo/video display with better error handling and recovery options
  - Redesigned tool options bars for a cleaner, more intuitive experience
  - Improved visual feedback for selected tools and options
  - Enhanced media loading and reference handling to prevent "media not available" issues
  - Added smoother animations and transitions between editing modes
  - Applied Instagram's minimal aesthetic with subtle transparent overlays
  - Removed cluttered UI elements for a more focused editing experience
  - [REF:StoryCreationView.swift]

## [1.0.4] - 2025-03-17

### Changed
- [UI] **Redesigned picture editing tools for improved interactivity and user experience**:
  - Completely redesigned editing toolkit with modern Instagram/TikTok inspired interface
  - Added intuitive circular tool selector with visual feedback and animations
  - Enhanced drawing tools with more color options, variable brush sizes, and undo capability
  - Implemented continuous font size slider for text editing replacing discrete size options
  - Added visual previews for all editing options for better usability
  - Improved layout with dedicated sections for each editing mode
  - Enhanced visual feedback with animations and state indicators
  - Applied consistent styling with shadows and rounded corners
  - [REF:StoryCreationView.swift, StoryCreationViewModel.swift]

### Fixed
- [FIX] **Resolved compiler errors in StoryCreationView.swift**:
  - Fixed scope issues with EditingMode references
  - Resolved getFont function reference problems
  - Improved code organization by breaking up complex expressions
  - Properly passed font rendering functions between components
  - Enhanced code maintainability with better component structure
  - [REF:StoryCreationView.swift]

## [1.0.3] - 2025-03-15

### Added
- [FEATURE] **Enhanced Stories creation with Instagram-like editor**:
  - Added image transformation with scale, rotation, and positioning
  - Implemented text overlay tool with customizable fonts and colors
  - Added drawing tool with multiple brush sizes and colors
  - Placeholder for future sticker functionality
  - Improved user experience with tool-specific option bars
  - [REF:StoryCreationView.swift, StoryCreationViewModel.swift]

## [1.0.2] - 2025-03-12

### Fixed
- [FIX] **Added missing microphone permission in Info.plist**:
  - Fixed app crash when accessing microphone for video recording in Stories feature
  - Added NSMicrophoneUsageDescription with clear explanation for users
  - Ensures proper permissions handling for Story video recording

- [FIX] **Fixed Story creation camera capture issues**:
  - Fixed photo capture not working correctly in the camera interface
  - Resolved issue with caption sheet appearing briefly and disappearing for videos
  - Added more reliable state handling for view transitions after media capture
  - Improved thread handling in AVFoundation camera capture delegates
  - Added better error logging to troubleshoot camera issues
  - [REF:StoryCreationView.swift, CameraViewModel]

- [FIX] **Fixed Stories feature compilation errors and Swift concurrency issues**:
  - Fixed missing properties in StoryCreationViewModel after UI redesign
  - Resolved unreachable catch block by removing unnecessary try/catch
  - Fixed Swift actor isolation warnings by properly using async/await with @MainActor
  - Optimized code by changing mutable variables to constants where appropriate
  - [REF:StoryCreationViewModel.swift, StoriesViewModel.swift, StoryPlayerView.swift]

### Changed
- [UI] **Redesigned Stories creation experience with Instagram-like interface**:
  - Launches camera directly when creating a new story for immediate capture
  - Added photo library access button in bottom left corner (Instagram-style)
  - Improved camera controls with mode selector between photo and video
  - Added flash toggle button for better low-light photography
  - Created sleek, modern design with intuitive controls and improved visual feedback
  - Enhanced caption and location screens with more modern styling
  - [REF:StoryCreationView.swift, CameraViewModel]
