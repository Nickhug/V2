# MeetSpot Notification System

## Overview

The MeetSpot notification system provides real-time, persistent notifications for users across the application. This document outlines the architecture and implementation details of the notification system.

## Architecture

The notification system follows a Model-View-ViewModel (MVVM) architecture and consists of:

1. **Database Schema**: A `notifications` table in Supabase for storing notification data
2. **Models**: Swift models representing notification objects
3. **SupabaseService**: Methods for CRUD operations on notifications
4. **ViewModel**: Business logic for notifications
5. **Views**: UI components for displaying notifications

## Components

### Database Schema

The Supabase database contains a `notifications` table with the following structure:
- `id`: UUID (primary key)
- `user_id`: UUID (foreign key to users)
- `title`: Text (notification title)
- `message`: Text (notification message)
- `type`: Text (notification type)
- `related_id`: UUID (optional - reference to related entity)
- `is_read`: Boolean (read status)
- `created_at`: Timestamp
- `updated_at`: Timestamp

### Models

1. **NotificationType Enum**:
   ```swift
   enum NotificationType: String, Codable, CaseIterable {
       case meetInvite = "meet_invite"
       case meetJoin = "meet_join"
       case meetStarting = "meet_starting"
       case friendRequest = "friend_request"
       case routeShared = "route_shared"
       case systemMessage = "system_message"
   }
   ```

2. **NotificationModel**:
   ```swift
   struct NotificationModel: Identifiable, Codable, Equatable {
       let id: String
       let userId: String
       let title: String
       let message: String
       let type: NotificationType
       let relatedId: String?
       var isRead: Bool
       let createdAt: Date
       let updatedAt: Date
   }
   ```

### SupabaseService Methods

The SupabaseService includes methods for:
- Fetching notifications for the current user
- Counting unread notifications
- Marking notifications as read (single or all)
- Deleting notifications
- Creating new notifications

### NotificationsViewModel

The ViewModel provides:
- Loading notifications from Supabase
- Managing local notification state
- Handling notification actions (mark as read, delete)
- Error handling with user feedback

### UI Components

1. **NotificationsView**: Main view for displaying notifications with:
   - List of notifications
   - Empty state view
   - Loading state
   - Error handling
   - Pull-to-refresh functionality

2. **EnhancedNotificationRow**: Specialized row showing:
   - Type-specific icon and color
   - Notification title, message, and timestamp
   - Read/unread status indicator
   - Swipe actions for notification management

3. **NotificationButton**: Displays notification count in the app header

## Features

- **Real-Time Count**: Badge displaying number of unread notifications
- **Type-Specific Styling**: Icons and colors based on notification type
- **Swipe Actions**: Quick actions to mark as read or delete
- **Error Handling**: Graceful error handling with user feedback
- **Pull-to-Refresh**: Easy refreshing of notification data
- **Offline Fallback**: Displays cached data when offline

## Integration Points

- **HomeView**: Notification badge updates in real-time
- **User Actions**: Various user actions can trigger notifications (meet creation, friend requests, etc.)
- **Supabase**: Database storage and retrieval

## Future Enhancements

- Real-time push notifications
- Notification preferences and filtering
- More advanced grouping and categorization
- Enhanced notification actions (e.g., accept/reject friend requests directly)
- Background notification fetching 