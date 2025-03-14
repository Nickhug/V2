## [1.0.12] - 2025-03-25

### Fixed
- [FIX] **Fixed Story Creation flow and Supabase permission issues**:
  - Fixed photo/video upload workflow to show the story editor instead of bypassing it
  - Corrected immediate upload issue to allow users to review content before sharing
  - Added proper Supabase row-level security policies for stories storage bucket
  - Created missing stories storage bucket and configured proper permissions
  - Fixed media sharing user experience to match Instagram-like story creation flow
  - [REF:StoryCreationView.swift, Supabase RLS]

## [1.0.11] - 2025-03-25

### Fixed
- [FIX] **Fixed critical hang risk and Swift 6 compatibility issues in StoryCreationView.swift**:
  - Fixed major hang risk by properly moving AVCaptureSession.startRunning() to background thread
  - Added await keywords for AVCaptureSession.startRunning() to comply with Swift 6 requirements
  - Added dispatchPrecondition check to ensure camera operations never run on main thread
  - Fixed unused result warning for uploadStory() method by properly handling return value
  - Enhanced camera session management for better UI responsiveness and stability
  - Improved thread safety throughout the camera capture process
  - [REF:StoryCreationView.swift]

## [1.0.10] - 2025-03-22

### Fixed
- [FIX] **Resolved type ambiguity issues in camera code:**
  - Added explicit type annotations for closures in CameraComponents.swift
  - Fixed weak self references with explicit type annotations
  - Ensured proper handling of self in closure contexts
  - Improved code stability for Swift 6 compatibility
  - [REF:CameraComponents.swift] 