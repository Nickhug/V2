# Achievements System

## Overview
The achievements system provides a gamified experience for MeetSpot users, rewarding them for completing various activities within the app. Achievements are displayed in the user's profile and include visual progress tracking.

## Components

### Models
- **Achievement**: Represents a single user achievement with properties for type, title, description, icon, and earned date.
- **AchievementType**: Enum defining all possible achievement types (meetCreated, profileComplete, etc.).
- **Activity/ActivityType**: Tracks user actions that might lead to achievements.

### ViewModels
- **AchievementViewModel**: Handles loading, checking, and awarding achievements.

### Views
- **AchievementsView**: List-based view showing earned achievements.
- **AchievementsGridView**: Grid-based view with progress tracking.
- **AchievementEarnedView**: Animated overlay shown when a new achievement is earned.

### Database
- **achievements table**: Stores user achievements.
- **user_activities table**: Tracks user actions for achievement awarding.
- **users.achievements column**: JSONB array in the users table that caches earned achievements.

## Achievement Types
The system currently supports 11 achievement types:

1. **Meet Created** - Created your first car meet
2. **Meet Joined** - Joined your first car meet
3. **Meet Completed** - Completed your first car meet
4. **Route Created** - Created your first driving route
5. **Route Shared** - Shared your first driving route
6. **Friend Added** - Added your first friend
7. **Profile Complete** - Completed your profile with all information
8. **First Meet** - Attended your first car meet
9. **Meet Streak** - Attended 3 meets in a month
10. **Social Butterfly** - Connected with 5 different people
11. **Attend Five Meets** - Attended 5 different car meets

## Implementation Notes

### How Achievements Are Awarded
Achievements are awarded through two mechanisms:

1. **Direct tracking**: When specific actions are performed (e.g., creating a meet), the system directly awards the relevant achievement.
2. **Periodic checking**: The system periodically checks for achievements that depend on accumulated data (e.g., attending 5 meets).

### Database Structure
- Achievements are stored in both the dedicated `achievements` table and cached in the user's record.
- The `user_activities` table tracks all user actions for achievement evaluation.

### UI/UX Considerations
- The system provides visual feedback when achievements are earned.
- Achievements are categorized by rarity (Common, Uncommon, Rare, Epic).
- Progress tracking is displayed visually for motivation.

## How to Use

### Tracking an Activity
```swift
// In view models or services:
authManager.trackActivity(.meetCreated, relatedId: "meet-id-here")
```

### Manually Checking for Achievements
```swift
// To trigger a check for all possible achievements:
Task {
    let viewModel = AchievementViewModel()
    await viewModel.checkForAchievements(userId: userId)
}
```

### Displaying Achievements
```swift
// Display the achievements grid:
AchievementsGridView()
    .environmentObject(authManager)
```

## Extending the System
To add new achievement types:

1. Add the new type to the `AchievementType` enum in `Achievement.swift`
2. Add the achievement definition in `AchievementViewModel`'s `achievementDefinitions` dictionary
3. Implement the logic for when/how the achievement is awarded
4. Update the total achievement count in relevant views

## Installation
Run the included SQL script `achievements-db-setup.sql` to ensure the database is properly configured.

## Technical Debt and Future Improvements
- Create a dedicated AchievementService to separate business logic from the ViewModel
- Add notification support for achievement unlocks
- Add sharing functionality for achievements
- Implement a badge system for displaying achievements on user profiles
- Add leaderboards for achievement counts 