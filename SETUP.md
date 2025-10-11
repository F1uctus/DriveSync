# Drive Sync - Setup Guide

## Prerequisites

- Flutter SDK 3.24.0 or later
- Python 3.6+ (for project configuration)
- A Google Cloud Project with Drive API enabled
- iPad running iPadOS 16+
- LiveContainer installed on your iPad (for unsigned app installation)
- GitHub account (for free CI builds)

**Note:** Xcode is NOT required! The project is configured via Python script and built in CI.

## Google Cloud OAuth Setup

1. Go to [Google Cloud Console](https://console.cloud.google.com/)
2. Create a new project or select an existing one
3. Enable the Google Drive API:
   - Navigate to "APIs & Services" > "Library"
   - Search for "Google Drive API" and enable it
4. Configure OAuth consent screen:
   - Go to "APIs & Services" > "OAuth consent screen"
   - Choose "External" user type
   - Set Publishing status to "Testing" (for up to 5 users)
   - Add your email as a test user
5. Create OAuth 2.0 credentials:
   - Go to "APIs & Services" > "Credentials"
   - Click "Create Credentials" > "OAuth client ID"
   - Choose "iOS" application type
   - Enter bundle ID: `com.drivesync.app`
   - Download the credentials JSON

## Configure the App

### 1. Update Info.plist with OAuth Client ID

Edit `ios/Runner/Info.plist` and replace `YOUR_CLIENT_ID` with your actual Google OAuth client ID:

```xml
<string>com.googleusercontent.apps.YOUR_CLIENT_ID</string>
```

### 2. Configure Xcode Project (No Xcode Required!)

**You don't need Xcode or macOS!** Run this Python script to configure everything automatically:

```bash
python3 configure_xcode.py
```

This script will:

- Add File Provider Extension target
- Set bundle identifiers
- Configure capabilities and entitlements
- Link Swift source files
- Set deployment targets

**Manual Xcode Configuration (Alternative)**

If you prefer to use Xcode (optional), open `ios/Runner.xcworkspace` and configure:

#### Main App Target (Runner):

- **General** tab:
  - Bundle Identifier: `com.drivesync.app`
  - Version: 0.1.0
  - Deployment Target: iOS 16.0+
- **Signing & Capabilities** tab:
  - Disable "Automatically manage signing"
  - Add capability: "Background Modes" (fetch, processing)
  - Add capability: "App Groups" (`group.com.drivesync.app`)
  - Add capability: "Keychain Sharing"

#### File Provider Extension Target:

1. File > New > Target > File Provider Extension
2. Product Name: `FileProviderExt`
3. Bundle Identifier: `com.drivesync.app.FileProvider`
4. Configure same capabilities as main app
5. Link the Swift files from `ios/FileProviderExt/`

## Installation Steps

### 1. Configure the Project

```bash
cd /mnt/d/Dev/dart/DriveSync/drive_sync

# Install Flutter dependencies
flutter pub get

# Configure Xcode project (no Xcode needed!)
python3 configure_xcode.py
```

The configuration script will automatically set up the File Provider Extension and all necessary settings.

### 2. Build the App

#### Option A: GitHub Actions (Recommended - No macOS Required!)

1. Push your code to GitHub
2. The workflow will automatically build the unsigned .ipa
3. Download the artifact from the Actions tab

#### Option B: Local Build

```bash
flutter build ios --release --no-codesign
cd build/ios/iphoneos
mkdir -p Payload
cp -r Runner.app Payload/
zip -r DriveSync.ipa Payload/
```

The unsigned .ipa will be at: `build/ios/iphoneos/DriveSync.ipa`

### 3. Install on iPad via LiveContainer

1. Install LiveContainer on your iPad
2. Transfer `DriveSync.ipa` to your iPad (via AirDrop, iCloud, etc.)
3. Open LiveContainer
4. Tap "+" to import the .ipa
5. Select DriveSync.ipa
6. Tap to launch the app

## First Run Setup

1. **Sign in with Google**: Tap the sign-in button and authorize the app
2. **Add Folder Pairs**:
   - Tap the "+" button on the home screen
   - Select a Google Drive folder
   - The app will sync it to local storage
3. **Configure Settings**:
   - Tap the settings icon
   - Set sync frequency (default: 1 hour)
   - Choose conflict resolution strategy
   - Enable/disable background sync
   - Configure cellular data usage

## Features

### Background Sync

- The app registers background tasks for automatic syncing
- Background fetch: Quick check for changes every 15-60 minutes
- Background processing: Full sync when device is idle/charging

### Files App Integration

- Synced files appear in the Files app under "Drive Sync"
- Files are available offline
- Edit files in Files app, and changes sync back to Drive

### Settings

- **Sync Frequency**: 15 minutes, 1 hour, 6 hours, daily
- **Conflict Resolution**: Drive wins, Local wins, Newer file wins
- **Background Sync**: Enable/disable automatic syncing
- **Cellular Data**: Allow syncing over mobile data
- **Storage Management**: View used storage, clear cache

## Limitations

- Maximum 5 users (Google OAuth Testing mode)
- No code signing (requires LiveContainer or jailbreak)
- Background sync frequency limited by iOS
- File Provider Extension has minimal implementation

## Troubleshooting

### App Crashes on Launch

- Ensure LiveContainer is up to date
- Check that all entitlements are properly configured

### Sign-in Fails

- Verify OAuth client ID in Info.plist
- Check that your email is added as a test user in Google Cloud Console
- Ensure Drive API is enabled

### Background Sync Not Working

- Go to Settings and ensure "Background Sync" is enabled
- iOS may limit background execution based on battery/usage

### Files Not Appearing in Files App

- File Provider Extension must be properly configured in Xcode
- Check App Group identifier matches in both targets

## Development Notes

### Bundle IDs

- Main app: `com.drivesync.app`
- File Provider: `com.drivesync.app.FileProvider`
- App Group: `group.com.drivesync.app`

### Architecture

- **State Management**: Bloc pattern
- **Storage**: SQLite for metadata, filesystem for files
- **Background**: workmanager package
- **Files Integration**: iOS File Provider Extension

### Key Files

- `lib/main.dart` - App entry point
- `lib/services/google_drive_service.dart` - Drive API integration
- `lib/services/sync_service.dart` - Core sync logic
- `ios/FileProviderExt/` - Files app integration

## Cost Breakdown

- ✅ **Development**: $0 (open source tools)
- ✅ **Google Cloud**: $0 (free tier, <5 users)
- ✅ **CI/CD**: $0 (GitHub Actions free tier)
- ✅ **Distribution**: $0 (LiveContainer, no App Store)
- ✅ **Code Signing**: $0 (unsigned build)

Total: **$0.00**

## Next Steps

1. Install dependencies: `flutter pub get`
2. Configure Google OAuth credentials
3. Update bundle identifiers in Xcode
4. Build and deploy via GitHub Actions
5. Install on iPad via LiveContainer
6. Add your Google account as test user
7. Start syncing!
