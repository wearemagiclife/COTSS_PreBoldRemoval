# App Store Screenshots Checklist
## Cards of The Seven Sisters

---

## Required Device Sizes

Apple requires screenshots for the following device sizes:

### iPhone (REQUIRED)
- ✅ **6.9" Display** - iPhone 16 Pro Max (2868 x 1320 px)
- ✅ **6.7" Display** - iPhone 15 Pro Max, 14 Pro Max (2796 x 1290 px)
- ✅ **5.5" Display** - iPhone 8 Plus (2208 x 1242 px)

### iPad (RECOMMENDED)
- ✅ **12.9" Display** - iPad Pro 12.9" 6th gen (2048 x 2732 px)

**Note**: You must provide at least ONE iPhone size. Providing all three iPhone sizes + iPad ensures compatibility across all devices.

---

## Screenshot Requirements (Apple Guidelines 2.3.3)

### ✅ DO:
- Show the app **in actual use** (not just splash screens)
- Use **actual device screenshots** (not mockups)
- Show **real content** that users will see
- Include **UI elements** (status bar optional but recommended)
- Use **localized content** if submitting in multiple languages
- Keep screenshots **current** with your submitted build

### ❌ DON'T:
- Use only splash screens or launch screens
- Add fake device frames (Apple adds them automatically)
- Include pricing, promotional text, or "limited time" offers
- Show features not available in this version
- Use outdated screenshots from old versions

---

## Recommended Screenshot Sequence (5-10 screenshots)

Based on your app's core features, here's a strategic sequence:

### Screenshot 1: **Home View - Daily Card Overview** ⭐ HERO SHOT
**Screen**: HomeView with daily card displayed
**Why**: Shows main value proposition - your daily card reading
**Capture**:
- Main home screen with 3 card tiles visible
- Large daily card section prominent
- Clean, welcoming first impression

### Screenshot 2: **Birth Card Reading**
**Screen**: BirthCardView showing user's permanent birth card
**Why**: Demonstrates core feature - personalized birth card
**Capture**:
- Full birth card with title and description visible
- Karma card connection if available
- Shows depth of content

### Screenshot 3: **Daily Card Detail View**
**Screen**: DailyCardView with planetary influence
**Why**: Shows detailed reading experience
**Capture**:
- Daily card with full description
- Planetary influence card displayed
- Demonstrates educational content quality

### Screenshot 4: **Yearly Solar Cycle**
**Screen**: YearlySpreadView
**Why**: Shows annual reading feature
**Capture**:
- Yearly card with description
- Clear date/cycle information
- Demonstrates long-term guidance

### Screenshot 5: **52-Day Astral Cycle**
**Screen**: FiftyTwoDayCycleView
**Why**: Unique feature - 7 planetary cycles
**Capture**:
- Cycle view with current position highlighted
- Shows the 7-cycle rhythm
- Demonstrates sophisticated calculation system

### Screenshot 6 (Optional): **Learn Section**
**Screen**: LearnView with educational links
**Why**: Shows educational resources and credibility
**Capture**:
- "Get to know The Cards" header
- Educational link cards visible
- Shows app provides guidance/learning

### Screenshot 7 (Optional): **Profile/Settings**
**Screen**: ProfileSheet or settings area
**Why**: Shows customization and privacy commitment
**Capture**:
- Clean profile interface
- Shows Sign in with Apple integration
- Demonstrates privacy-first design

### Screenshot 8 (Optional): **Card Detail Modal**
**Screen**: CardDetailModalView showing card meanings
**Why**: Shows depth of card database
**Capture**:
- Beautiful card image
- Detailed description text
- Clean, readable design

---

## How to Capture Screenshots

### Method 1: Using Xcode Simulator (Fastest)
1. Open your project in Xcode
2. Select device: Product → Destination → Choose device size
3. Run app: Cmd+R
4. Navigate to desired screen
5. Capture: Cmd+S (saves to Desktop)
6. Repeat for each device size

**Devices to select in Xcode:**
- iPhone 16 Pro Max (6.9")
- iPhone 15 Pro Max (6.7")
- iPhone 8 Plus (5.5")
- iPad Pro 12.9" 6th gen

### Method 2: Using Physical Device (Best Quality)
1. Run app on your physical iPhone/iPad
2. Navigate to desired screen
3. Capture: Press Side Button + Volume Up simultaneously
4. Screenshots save to Photos app
5. AirDrop to Mac or sync via iCloud Photos

**Important**: Physical device screenshots must match required dimensions. You may need to use multiple devices or resize appropriately.

### Method 3: Using Screenshot Tool (Advanced)
```bash
# Install fastlane (if not already installed)
brew install fastlane

# Use snapshot tool to automate screenshot capture
fastlane snapshot
```

---

## Screenshot File Naming Convention

Organize your screenshots clearly:

```
screenshots/
├── iPhone_6.9/
│   ├── 01_home_daily_card.png
│   ├── 02_birth_card.png
│   ├── 03_daily_detail.png
│   ├── 04_yearly_cycle.png
│   └── 05_52day_cycle.png
├── iPhone_6.7/
│   ├── 01_home_daily_card.png
│   └── ...
├── iPhone_5.5/
│   └── ...
└── iPad_12.9/
    └── ...
```

---

## Pre-Upload Checklist

Before uploading to App Store Connect:

- [ ] **Verify dimensions** - Each screenshot matches required pixel dimensions
- [ ] **Check orientation** - All portrait (your app is portrait-only on iPhone)
- [ ] **Review content** - No sensitive/test data visible
- [ ] **Text readability** - All text is crisp and readable at full size
- [ ] **Consistent data** - Use same user profile across all screenshots
- [ ] **No status bar issues** - Clock shows reasonable time, full battery/signal
- [ ] **App in use** - Every screenshot shows actual app functionality
- [ ] **File format** - PNG or JPEG (PNG recommended for quality)
- [ ] **File size** - Under 500 KB per screenshot (compress if needed)

---

## Screenshot Tips for Your App

### Use a Clean Profile
Create a test profile with a clean name (e.g., "Alex" or "Jordan") to avoid personal data in screenshots.

### Choose Appealing Cards
Select birth dates that generate visually interesting card combinations:
- Mix of suits (Hearts, Clubs, Diamonds, Spades)
- Variety of face cards and number cards
- Cards with compelling descriptions

### Timing Matters
- Capture Daily Card screenshots when a visually appealing card is active
- You can test with different dates to find good card combinations

### Show Complete Content
- Scroll to show full card descriptions if possible
- Ensure card titles and images are fully visible
- Don't cut off important text

### Lighting & Theme
Your app uses light mode only (forced in code), so all screenshots will have consistent beige vintage theme - this is good for brand consistency!

---

## App Store Connect Upload Instructions

Once screenshots are captured:

1. Log in to [App Store Connect](https://appstoreconnect.apple.com)
2. Go to: My Apps → Cards of The Seven Sisters → App Store tab
3. Under "App Store Screenshots" section
4. Select device size from dropdown
5. Drag and drop screenshots (they will appear in order dragged)
6. Rearrange by dragging if needed
7. Repeat for each device size
8. Click "Save" at top right

**Screenshot Order**: First screenshot is your "hero" shot - most important! It appears in search results.

---

## Quick Reference: Device Resolutions

| Device | Resolution (px) | Aspect Ratio |
|--------|----------------|--------------|
| iPhone 16 Pro Max (6.9") | 2868 x 1320 | 19.5:9 |
| iPhone 15 Pro Max (6.7") | 2796 x 1290 | 19.5:9 |
| iPhone 8 Plus (5.5") | 2208 x 1242 | 16:9 |
| iPad Pro 12.9" | 2048 x 2732 | 4:3 |

**Orientation**: Portrait (vertical) for iPhone, can be portrait or landscape for iPad

---

## Optional: App Preview Video (Recommended)

Consider creating a 15-30 second video showing:
1. Splash screen → Home
2. Tap to reveal daily card
3. Navigate to Birth Card
4. Quick scroll through features

**Specs**:
- Resolution: Same as screenshots for each device
- Duration: 15-30 seconds
- Format: .mov, .m4v, or .mp4
- Max file size: 500 MB

**Tools**: QuickTime screen recording on Mac, or use Xcode's screen recording

---

## Need Help?

If you encounter issues:
- Screenshots appear stretched/wrong size → Verify you're using correct simulator
- Can't capture certain screens → Use Accessibility → Guided Access to prevent accidental taps
- File size too large → Use ImageOptim or similar tool to compress PNGs

---

**Last Updated**: 2025-11-16
**App Version**: 1.0 (Build 1)
