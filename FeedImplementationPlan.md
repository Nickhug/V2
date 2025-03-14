# Instagram-like Feed Implementation Plan

## Overview
This document outlines the plan for implementing a fullstack "Instagram-like" feed in our SwiftUI application. The feed will allow users to post pictures of their vehicles and interact with the community. We'll replace the existing Routes tab with this new Feed tab, and integrate the Routes feature into the Explore Meets page.

## Table of Contents
1. [Data Model Changes](#data-model-changes)
2. [Backend Implementation](#backend-implementation)
3. [Frontend Implementation](#frontend-implementation)
4. [Routes Feature Integration](#routes-feature-integration)
5. [Implementation Phases](#implementation-phases)

## Data Model Changes

### New Tables
1. **posts**
   - `id` (UUID): Primary key
   - `user_id` (UUID): Foreign key to users table
   - `vehicle_id` (UUID, optional): Foreign key to vehicles table
   - `caption` (text): Caption for the post
   - `image_urls` (text[]): Array of image URLs
   - `location` (point, optional): Geographic location of the post
   - `location_name` (text, optional): Name of the location
   - `created_at` (timestamp): When the post was created
   - `updated_at` (timestamp): When the post was last updated

2. **post_likes**
   - `id` (UUID): Primary key
   - `post_id` (UUID): Foreign key to posts table
   - `user_id` (UUID): Foreign key to users table
   - `created_at` (timestamp): When the like was created

3. **post_comments**
   - `id` (UUID): Primary key
   - `post_id` (UUID): Foreign key to posts table
   - `user_id` (UUID): Foreign key to users table
   - `content` (text): Comment content
   - `created_at` (timestamp): When the comment was created
   - `updated_at` (timestamp): When the comment was last updated

4. **post_tags**
   - `id` (UUID): Primary key
   - `post_id` (UUID): Foreign key to posts table
   - `tag` (text): Tag content

### RLS Policies
- Posts: Users can read all posts, but only create/update/delete their own
- Likes: Users can read all likes, but only create/delete their own
- Comments: Users can read all comments, but only create/update/delete their own
- Tags: Same as posts

## Backend Implementation

### Supabase Functions
1. **Create Post**
   - Handle image uploads to storage
   - Create post record with tags
   - Return created post with user info

2. **Get Feed Posts**
   - Pagination support (limit/offset or cursor-based)
   - Include user and vehicle information
   - Include like count and comment count
   - Optional filtering (following only, trending, etc.)

3. **Like/Unlike Post**
   - Toggle like status for current user

4. **Add Comment**
   - Create comment with validation

5. **Get Post Comments**
   - Pagination support
   - Include user information

### Storage Setup
- Create dedicated bucket for post images
- Set up appropriate access rules
- Configure image optimization for thumbnails

### Realtime Setup
- Enable realtime for posts, likes, and comments tables
- Implement appropriate broadcast settings

## Frontend Implementation

### Swift Models
1. **Post Model**
   ```swift
   struct Post: Identifiable, Codable {
       let id: String
       let userId: String
       let vehicleId: String?
       let caption: String
       let imageUrls: [String]
       let location: CLLocationCoordinate2D?
       let locationName: String?
       let createdAt: Date
       let updatedAt: Date
       var likeCount: Int
       var commentCount: Int
       var isLikedByCurrentUser: Bool
       var user: User?
       var vehicle: Vehicle?
   }
   ```

2. **Comment Model**
   ```swift
   struct PostComment: Identifiable, Codable {
       let id: String
       let postId: String
       let userId: String
       let content: String
       let createdAt: Date
       let updatedAt: Date
       var user: User?
   }
   ```

### ViewModels
1. **FeedViewModel**
   - Fetch feed posts with pagination
   - Handle post creation
   - Handle post interaction (likes, comments)
   - Track currently viewed posts
   - Support for pull-to-refresh

2. **PostCreationViewModel**
   - Handle image selection/capture
   - Upload images
   - Create post with caption and tags
   - Manage form state

### UI Components
1. **FeedView**
   - Main tab view replacement
   - Infinite scrolling list of posts
   - Pull-to-refresh functionality
   - Navigation to post creation

2. **PostView**
   - Display individual post with images
   - Like button functionality
   - Comment display and creation
   - User and vehicle information
   - Image carousel for multiple images

3. **PostCreationView**
   - Photo picker integration
   - Optional vehicle selection
   - Caption and location input
   - Tag input with autocomplete
   - Submit button with loading state

4. **CommentView**
   - Display comments with pagination
   - Add new comment UI
   - User avatars and timestamps

## Routes Feature Integration

### Explore Meets Page Updates
1. **UI Changes**
   - Add Routes button next to existing Create Meet button
   - Design it to match the existing UI style
   - Make both buttons work well together

2. **Routes Button Implementation**
   - Open a modal or navigate to Routes view
   - Maintain same functionality as current Routes tab

3. **Routes View Integration**
   - Reuse existing RoutesView logic
   - Adapt UI to work as a modal/sheet if needed
   - Ensure all create/edit/delete functionality works

## Implementation Phases

### Phase 1: Backend Setup
- Create database tables with proper relationships
- Set up RLS policies
- Create storage buckets
- Implement initial API endpoints
- Test with Supabase CLI and/or Postman

### Phase 2: Core Models and ViewModels
- Create Swift models for new database entities
- Implement FeedViewModel with basic functionality
- Set up Supabase service methods for feed operations
- Build image upload service for posts

### Phase 3: Feed UI Implementation
- Create FeedView to replace Routes tab
- Implement PostView for rendering individual posts
- Build infinite scroll functionality
- Add pull-to-refresh

### Phase 4: Interaction Features
- Implement like functionality
- Add commenting system
- Support user and vehicle tagging

### Phase 5: Post Creation
- Build PostCreationView
- Implement image selection/capture
- Add vehicle selection
- Build submission flow

### Phase 6: Routes Integration
- Add Routes button to Explore Meets page
- Integrate RoutesView as a modal/sheet
- Ensure full functionality is preserved

### Phase 7: Testing and Refinement
- Test all features extensively
- Optimize performance
- Add loading states and error handling
- Refine UI animations and transitions

## Conclusion
This implementation plan provides a comprehensive roadmap for building an Instagram-like feed feature while preserving the Routes functionality by integrating it with the Explore Meets page. By following this structured approach, we can ensure a smooth development process and a high-quality end result. 