# WARP.md

This file provides guidance to WARP (warp.dev) when working with code in this repository.

## Project Overview

**DailyNotes** is a SwiftUI iOS app (iOS 17.0+) that helps users maintain structured daily notes with auto-creation from templates, calendar tracking, and export capabilities.

## Commands

### Building & Running
```bash
# Open the Xcode project
open DailyNotes-iOS-SwiftUI/DailyNotes.xcodeproj

# Build from command line (requires setting team and bundle ID first)
xcodebuild -project DailyNotes-iOS-SwiftUI/DailyNotes.xcodeproj -scheme DailyNotes -destination 'platform=iOS Simulator,name=iPhone 15' build

# Run on simulator
xcodebuild -project DailyNotes-iOS-SwiftUI/DailyNotes.xcodeproj -scheme DailyNotes -destination 'platform=iOS Simulator,name=iPhone 15' run
```

### Configuration Requirements
Before building, you must:
1. Open **DailyNotes.xcodeproj** in Xcode 15+
2. Set your Team in target Signing & Capabilities
3. Set a unique Bundle Identifier

## Architecture

### Data Layer
- **SwiftData** is used for persistence (iOS 17+)
- Single model: `NoteEntry` with unique `dayKey` constraint per day
- `NoteEntry.isCompleted` is computed based on non-empty content
- ModelContainer configured at app level in `DailyNotesApp.swift`

### Navigation Structure
Tab-based navigation with 4 main screens:
1. **TodayView** - Today's note with auto-creation from template
2. **CalendarScreen** - Month grid showing completion status
3. **HistoryScreen** - Searchable list of all entries
4. **SettingsScreen** - Template editor and reminder configuration

### Key Patterns

#### Template System
- Default template stored in `@AppStorage("noteTemplate")`
- Managed by `AppTemplate` ObservableObject
- New entries auto-populated with current template
- User can edit template in Settings

#### Date Normalization
- All dates normalized to start-of-day using `Calendar.current.startOfDay(for:)`
- `dayKey` format: "yyyy-MM-dd" string for unique identification
- Prevents duplicate entries for same calendar day

#### Entry Creation
- Today's entry auto-created on first view
- Past/future entries created on-demand when opened from calendar
- New entries populated with template only if created through Today view

### Export System (`Exporter.swift`)
- **CSV Export**: Supports bulk export with date, completion status, and content
- **PDF Export**: Uses `ImageRenderer` to convert SwiftUI views to PDF
- Both export to temporary files for sharing via `UIActivityViewController`

### Notifications
- Optional daily reminders using `UNUserNotificationCenter`
- Scheduled with `UNCalendarNotificationTrigger` for repeating notifications
- User configures time in Settings

## Code Guidelines

### SwiftData Queries
When querying entries, use `@Query` with sort on `date` field:
```swift
@Query(sort: \\NoteEntry.date, order: .reverse) private var entries: [NoteEntry]
```

### Finding Entries by Date
Always use the `dayKey` approach:
```swift
let key = NoteEntry.key(for: someDate)
entries.first(where: { $0.dayKey == key })
```

### Saving Changes
Context saves are wrapped in `try?` throughout the codebase. After modifying entries:
```swift
entry.updatedAt = Date()
try? ctx.save()
```

### Calendar Grid Logic
Calendar layout in `CalendarScreen.swift` uses placeholder dates (`.distantPast`) for empty leading cells to align the first day of the month with correct weekday.
