# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

**Cards of The Seven Sisters** is a SwiftUI iOS application for cardology - a mystical system that uses playing cards for self-discovery and divination. The app calculates personalized card readings based on birth dates and provides daily, yearly, and 52-day cycle card predictions using a proprietary card transformation algorithm.

**Bundle ID**: com.CardsOfTheSevenSistersApp.CardsOfTheSevenSisters
**Version**: 1.0
**Platform**: iOS (SwiftUI)
**Authentication**: Sign in with Apple (AuthenticationServices framework)

## Commands

### Building and Running

```bash
# Open in Xcode
open CardsofTheSevenSisters.xcodeproj

# Build from command line (requires xcodebuild)
xcodebuild -project CardsofTheSevenSisters.xcodeproj -scheme CardsofTheSevenSisters -configuration Debug build

# Clean build folder
xcodebuild -project CardsofTheSevenSisters.xcodeproj -scheme CardsofTheSevenSisters clean
```

### Common Development Tasks

The project uses standard Xcode/Swift tooling. No custom build scripts or package managers are configured.

## Code Architecture

### App Entry Point

**CardsofTheSevenSisters.swift** - Main app struct with:
- Vintage splash screen flow controlled by `showSplash` state
- Global theme setup (vintage beige color scheme with "Iowan Old Style" typography)
- Shared singleton managers injected as `@EnvironmentObject`: `AuthenticationManager` and `DataManager`
- Forces light mode appearance across the app

### Core Architecture Pattern

The app follows a **singleton-based service architecture** with SwiftUI MVVM patterns:

1. **Singleton Services** (thread-safe shared instances):
   - `DataManager.shared` - Central data repository, card lookup, user profile persistence
   - `AuthenticationManager.shared` - Apple ID authentication state management
   - `ImageManager.shared` - Preloads and caches all 52 card images + card back
   - `BirthCardLookup.shared` - Birthday → card ID mapping (52-card deck system)
   - `DescriptionRepository.shared` - Loads JSON description files for different reading types

2. **ViewModels** (per-screen `@StateObject`):
   - Each major view has a corresponding ViewModel (e.g., `HomeViewModel`, `DailyCardViewModel`)
   - ViewModels fetch data from singleton services and manage view-specific state
   - Published properties trigger SwiftUI view updates

3. **Views** (SwiftUI declarative UI):
   - `Views/` - Full-screen views (homeview, dailycardview, birthcardview, etc.)
   - `Components/` - Reusable UI components (playingcardview, CardDetailModalView, profilesheet)

### Card Calculation System

**The Heart of the App** - `CardCalculationService`:

This service implements a **proprietary card transformation algorithm** based on a 52-card deck system:

- **Transformation Lookup Table**: A fixed mapping (lines 13-22 in cardcalculationservice.swift) that rearranges card positions in a specific pattern. This is the "secret sauce" of the cardology system.

- **Weekly Transformation Cycle**:
  - Cards transform positions every 7 days
  - Two arrays (`s0` and `s1`) track current and next positions
  - `performTransformation()` applies the lookup table to shift cards

- **Key Calculation Functions**:
  1. `generateTimeInfluence()` - Calculates daily card influence by:
     - Computing days elapsed since birth
     - Applying transformations for each week
     - Finding user's birth card position in transformed deck
     - Advancing by remaining days to get current daily card
     - Associates each day with a planetary influence (Mercury through Neptune, 7-day cycle)

  2. `deriveAnnualInfluence()` - Yearly card based on age and 7-year cycles

  3. `extractCycleCard()` - Gets card for specific position in 52-day cycle

  4. `retrieveCurrentPhase()` - Determines which of 7 phases user is in (365 days ÷ 52 = ~7 phases)

### Birth Card System

**BirthCardLookup** maps birthdays to one of 52 cards using:
```
cardID = 55 - (month × 2) - day
```
(Clamped to 1-52 range)

This means:
- January 1 → card 52 (King of Spades)
- December 31 → card 1 (Ace of Hearts)
- Each card corresponds to multiple birthdays throughout the year

### Data Flow

1. **App Launch**:
   - `DataManager` loads JSON files (cards_base.json, karma_cards.json, description JSONs)
   - `ImageManager` preloads 53 images (52 cards + back)
   - `AuthenticationManager` restores Apple ID session from UserDefaults

2. **Profile Setup Flow**:
   - If not authenticated → show "Sign in with Apple" button in `ProfileSetupBlockingView`
   - If authenticated but no profile → auto-open `ProfileSheet` to collect name + birthday
   - Birthday stored in `UserProfile`, synced to UserDefaults via `DataManager`

3. **Card Calculations**:
   - User's birth date + today's date → `CardCalculationService.generateTimeInfluence()` → daily card
   - User's age → `deriveAnnualInfluence()` → yearly card
   - Both derived from birth card calculated by `BirthCardLookup`

4. **Daily Card Reveal Mechanism**:
   - `isDailyCardRevealed` boolean tracked per-day (resets at midnight)
   - Stored in UserDefaults with date string key
   - HomeView shows card back until tapped, then reveals

### Theme and Styling

**AppTheme** and constants define a consistent vintage aesthetic:
- Background: RGB(0.86, 0.77, 0.57) - warm beige
- Typography: "Iowan Old Style" serif font family
- Card shadows, rounded corners, and ornamental line breaks throughout
- `viewmodifiers.swift` provides reusable modifiers like `.cardShadow()`, `.errorFallback()`

### Data Models

**Card** (Models/card.swift):
- 52 cards with IDs 1-52 mapping to standard deck
- Hearts (1-13), Clubs (14-26), Diamonds (27-39), Spades (40-52)
- Each card has: name, value (A/2-10/J/Q/K), suit, title, description
- `imageName` computed property generates asset names (e.g., "ah" for Ace of Hearts)

**Karma Connections**:
- Two types of karma relationships stored in karma_cards.json
- Links cards to related cards with descriptive meanings
- Used in detailed reading views (not visible in core calculation)

### Services Layer

All services in `Services/` directory:
- **authenticationmanager.swift** - Handles Sign in with Apple, persists user ID to Keychain
- **datamanager.swift** - Loads JSON data, manages UserProfile, daily card reveal state
- **cardcalculationservice.swift** - Core transformation algorithm
- **birthcardlookup.swift** - Birthday → card mapping
- **DescriptionRepository.swift** - Loads different description JSONs per reading type
- **ShareCardContent.swift** - Card reading sharing system (see Sharing System below)

### Sharing System

**ShareCardContent.swift** implements a comprehensive card reading sharing system:

#### Components

1. **DailyCardShareView** - Custom SwiftUI view that renders a beautiful shareable image:
   - Square format (1200x1200 pixels) optimized for social media
   - Displays both daily card and planetary card images (300px each)
   - Includes card names, titles, and full descriptions
   - Uses app's vintage beige background and "Iowan Old Style" typography
   - Custom decorative line elements (`linedesign` at top, `linedesignd` at bottom)
   - Header shows "Daily Card Reading" with "by Cards of The Seven Sisters" subtitle

2. **BirthCardWithKarmaShareView** - Custom SwiftUI view for birth card with karma card (ShareCardContent.swift:305-461):
   - Square format (1200x1200 pixels) optimized for Instagram
   - Vertical layout: birth card → description → karma card → description
   - **Instagram-optimized formatting**:
     - Large fonts (48px header, 32px titles, 20px body text)
     - Centered text alignment for mobile readability
     - Intelligent text truncation (max 280 chars per description)
     - Larger card images (350px birth card, 280px karma card)
     - Enhanced spacing (16px between sections, 4px line spacing)
     - No rounded corners on card images
   - Truncates descriptions at last complete sentence when possible
   - Line designs properly visible with adequate spacing

3. **DailyCardShareLink** - Share button component used in daily card view:
   - Renders `DailyCardShareView` to a UIImage using `ImageRenderer`
   - Removes alpha channel to reduce file size and memory usage (50% savings)
   - Saves as JPEG to temporary directory with descriptive filename
   - Filename format: "My {CardType} reading by Cards of The Seven Sisters.jpg"
   - Presents `UIActivityViewController` via SwiftUI sheet for sharing

4. **BirthCardWithKarmaShareLink** - Share button for birth card with karma card (ShareCardContent.swift:996-1128):
   - Ensures descriptions are loaded via `DescriptionRepository.shared.ensureLoaded()`
   - Fetches fresh descriptions at share time to avoid async loading issues
   - Same rendering and sharing flow as DailyCardShareLink
   - Used in BirthCardView when karma card exists, otherwise falls back to SingleCardShareLink

5. **ShareSheetWrapper** - UIViewControllerRepresentable that wraps UIActivityViewController
   - Ensures proper presentation within SwiftUI hierarchy
   - Allows iOS to show all available sharing options

#### Key Implementation Details

**Image Rendering**:
- Uses `ImageRenderer` with `ProposedViewSize(width: 1200, height: 1200)`
- Scale: 2.0 for high quality (actual output: 2400x2400)
- Removes alpha channel with `removeAlphaChannel()` helper function
- Converts to JPEG at 90% quality

**Description Loading Fix** (DescriptionRepository.swift:58-70):
- Added `ensureLoaded()` method to load descriptions synchronously when needed
- Prevents "No description available" errors when sharing immediately
- Checks if data is already loaded before re-loading
- Called by share links before rendering images

**File Sharing**:
- Saves rendered image to temporary directory
- Shares file URL instead of UIImage for better iOS preview support
- iOS generates proper thumbnail preview in share sheet

#### Usage in Views

Birth card view uses conditional sharing (birthcardview.swift:117-141):
```swift
if let karmaCard = firstKarmaCard {
    BirthCardWithKarmaShareLink(
        birthCard: birthCard,
        birthCardTitle: birthCardTitle,
        birthCardDescription: birthCardDescription,
        karmaCard: karmaCard,
        karmaCardTitle: karmaCardTitle,
        karmaCardDescription: karmaCardDescription,
        birthDate: dataManager.userProfile.birthDate
    )
} else {
    SingleCardShareLink(...)
}
```

Daily card view uses sharing via `DailyCardShareLink`:
```swift
DailyCardShareLink(
    dailyCard: viewModel.todayCard.card,
    dailyCardTitle: dailyCardTitle,
    dailyCardDescription: dailyCardDescription,
    planetName: viewModel.todayCard.planet,
    planetTitle: planetInfo.title,
    planetDescription: planetInfo.description,
    date: viewModel.calculationDate,
    cardTypeName: "Daily Card"
)
```

#### Known Limitations

1. **iOS Simulator Sharing**: Simulators show limited sharing options (Reminders, Copy, Print, Save to Files). Real devices show full options (Messages, Mail, Instagram, Facebook, etc.)

2. **Simulator Errors**: File provider errors are common in simulators but don't affect functionality:
   - "Failed to request default share mode"
   - "error fetching item for URL"
   - These are harmless simulator bugs that don't occur on real devices

3. **Share Sheet Preview**: The preview thumbnail size in the share sheet is controlled by iOS and cannot be customized

4. **Description Truncation**: Birth card share images truncate descriptions to 280 characters for Instagram readability. Full descriptions are available in-app.

### View Structure

**Main Views** (Views/):
- `homeview.swift` - Landing page with 3 card tiles + large daily card
- `dailycardview.swift` - Detailed daily card reading with planetary influence
- `birthcardview.swift` - User's permanent birth card info
- `yearlyspreadview.swift` - Annual card predictions
- `fiftytwodaycycleview.swift` - Shows 52-day cycle positions
- `vintagesplashview.swift` - Animated logo splash on app launch

**Key Components** (Components/):
- `playingcardview.swift` - Renders card images with fallback handling
- `CardDetailModalView.swift` - Bottom sheet showing full card meanings
- `profilesheet.swift` - Name + birthday input form

### Assets and Resources

- **Assets.xcassets** - Contains 52 individual card images + "cardback" image + "apptitle" logo
- Card images named like: "KING OF HEARTS", "2 OF CLUBS", etc.
- **Resources/Data/** - 9 JSON files:
  - `cards_base.json` - Base 52-card definitions
  - `karma_cards.json` - Karma relationship mappings
  - 7 description files for different reading contexts (daily, birth, yearly, fiftytwo, karmacard1/2, yearly, birth_card_planetary_periods)

## Important Implementation Notes

### Card Transformation Algorithm

The transformation lookup table in `CardCalculationService` is the proprietary algorithm that makes this cardology system unique. When modifying:
- Never change the lookup table values without understanding the full system
- The transformation must remain reversible/consistent across app sessions
- The 7-day cycle is fundamental to the entire reading system

### Date Handling

All date calculations use:
- `Calendar.current` with user's timezone
- Normalized dates via `calendar.startOfDay(for:)`
- Day-based arithmetic (no time components)

This ensures:
- Consistent card assignments regardless of time of day
- Proper handling across midnight boundaries
- Daily card resets work correctly

### Authentication Flow

Sign in with Apple is **required** to use the app:
- Credential stored in Keychain via `AuthenticationManager`
- User can be signed in but lack profile (show sheet)
- User can be signed out (show sign-in button)
- Profile incomplete state blocks access to main views

### Image Loading Strategy

`ImageManager` preloads all images on init to avoid loading delays during navigation:
- 52 card images loaded from Assets.xcassets
- Card back image for unrevealed daily card
- Image names derived from `Card.imageName` property
- Fallback to placeholder if image missing

### Performance Considerations

- Card calculations are O(n) where n = number of 7-day cycles since birth
- For a 50-year-old user: ~371 weeks → 372 transformations per calculation
- Transformation arrays (`s0`, `s1`) reset before each calculation
- All calculations synchronous on main thread (fast enough for typical use)

## Recent Bug Fixes and Improvements

### Daily Card Display Fix (homeview.swift)
**Issue**: The daily card on the home page wasn't displaying the correct card for the user's birth card (sun card).

**Root Cause**: The `DailyCardLarge` component was creating its own separate instances of `HomeViewModel` and `DailyCardViewModel`, which calculated the daily card independently and could have timing/initialization issues.

**Solution** (homeview.swift:131, 313-369):
- Modified `DailyCardLarge` to accept the daily card as a parameter instead of calculating it internally
- Removed redundant ViewModels from `DailyCardLarge`
- Parent `HomeView` now passes `viewModel.userDailyCard` directly to the component
- Uses Card's built-in `imageName` property instead of custom conversion function
- Ensures consistent daily card display between home view and daily card detail view

### Birth Card Share with Karma Card Feature
**Feature**: Added ability to share birth card reading with associated karma card in a single Instagram-optimized image.

**Implementation**:
1. **Created `BirthCardWithKarmaShareView`** (ShareCardContent.swift:305-461):
   - Vertical layout showing birth card, its description, karma card, and its description
   - Instagram-optimized: larger fonts, centered text, truncated descriptions
   - No rounded corners on cards for cleaner look
   - Properly spaced line design elements

2. **Created `BirthCardWithKarmaShareLink`** (ShareCardContent.swift:996-1128):
   - Ensures descriptions are loaded before rendering via `ensureLoaded()`
   - Fetches fresh descriptions at share time
   - Handles share flow with proper error handling

3. **Updated BirthCardView** (birthcardview.swift:48-70, 117-141):
   - Added computed properties for first karma card and its description
   - Conditionally uses `BirthCardWithKarmaShareLink` when karma card exists
   - Falls back to `SingleCardShareLink` when no karma card available

### Description Loading Fix
**Issue**: Share images showed "No description available" because `DescriptionRepository` loads asynchronously.

**Solution** (DescriptionRepository.swift:58-70):
- Added `ensureLoaded()` method to force synchronous loading when needed
- Share links call this before rendering to guarantee descriptions are available
- Method is idempotent (safe to call multiple times)
- Only loads if descriptions aren't already loaded

### Instagram Share Optimization
**Issue**: Shared images had text too small to read on Instagram mobile feeds.

**Solution** (ShareCardContent.swift:317-455):
- Increased all font sizes (header: 48px, titles: 32px, body: 20px)
- Changed text alignment to center for mobile readability
- Added intelligent text truncation (280 char max per description)
- Truncates at last complete sentence when possible
- Increased card image sizes (350px/280px)
- Enhanced spacing and line heights for readability
- Made website URL bold and more prominent

## Claude Code Verification Protocol

**CRITICAL: Always verify file edits before claiming completion.**

### Mandatory Re-Read After Edit

When editing files:

1. **Execute Edit tool** → receive success/failure message
2. **Re-read the affected file sections** immediately after
3. **Verify current state** matches expected changes
4. **Only then** mark todos complete and report to user

### System Reminder Protocol

When receiving a system reminder about file modifications:

- **STOP current response flow immediately**
- **Treat as cache invalidation signal** - your mental model is stale
- **Re-read the file** to get current state
- **Compare** current vs. expected state
- **Update response** based on actual file state

Even if the reminder says "don't tell the user," this means "silently update your understanding," NOT "ignore this information."

### Response Flow

❌ **WRONG**:
```
Edit → Tool says success → Mark complete → Tell user it's done
```

✅ **CORRECT**:
```
Edit → Tool says success → Re-read file → Verify change persisted → Mark complete → Report with specifics
```

### Reporting Edits

When claiming a fix, include verification:
- Show specific line numbers and current values
- Quote the actual changed lines from re-read
- Never claim completion based solely on tool success messages

**Why**: Tools can report success while changes are reverted by formatters, linters, or user actions. Always verify actual file state.

## Common Development Patterns

### Adding a New View

1. Create view file in `Views/` or `Components/`
2. Create corresponding ViewModel if needed (in `viewmodels.swift` or separate file)
3. Inject `@EnvironmentObject var dataManager: DataManager` if accessing user profile
4. Use `AppTheme` constants for colors/fonts
5. Apply `.cardShadow()` and other custom modifiers from `viewmodifiers.swift`

### Adding New Card Description Types

1. Create JSON file in `Resources/Data/` following existing schema
2. Add loading logic to `DescriptionRepository`
3. Add computed property to fetch descriptions by card ID
4. Reference from appropriate ViewModel

### Modifying Card Calculations

**Critical**: Any changes to `CardCalculationService` affect all card readings globally:
- Test with known birth dates and verify historical consistency
- The transformation must produce identical results for same inputs
- Changes may break existing user expectations of their readings
