# Setting Up Without Xcode

This guide shows how to configure the Drive Sync project **without Xcode or macOS**, using only command-line tools and CI/CD.

## Prerequisites

- Python 3.6+ (already available on most systems)
- Git
- Text editor

## Quick Setup (5 minutes)

### 1. Update OAuth Client ID

Edit `ios/Runner/Info.plist` and replace `YOUR_CLIENT_ID`:

```bash
# Use sed or your text editor
sed -i 's/YOUR_CLIENT_ID/796748352227-4oo7d7up5b42gj9lj3e73t8v91n203km/' ios/Runner/Info.plist
```

Or manually edit line 55 in `ios/Runner/Info.plist`.

### 2. Run the Configuration Script

This Python script automatically configures the Xcode project:

```bash
python3 configure_xcode.py
```

The script will:

- ✅ Install pbxproj library (if needed)
- ✅ Add File Provider Extension target
- ✅ Set bundle identifiers (com.drivesync.app)
- ✅ Configure deployment target (iOS 16.0+)
- ✅ Disable code signing
- ✅ Set up App Groups
- ✅ Link Swift source files
- ✅ Configure entitlements

**Output:**

```
Loading Xcode project...
Configuring main Runner target...
Adding File Provider Extension target...
Adding Swift files to extension target...
Configuring entitlements...
Embedding extension in main app...
Saving project file...

✅ Xcode project configured successfully!
```

### 3. Push to GitHub for CI Build

```bash
git add .
git commit -m "Configure project for build"
git push
```

GitHub Actions will automatically build the unsigned .ipa (takes ~10-15 minutes).

## What the Script Does

The `configure_xcode.py` script uses the pbxproj Python library to programmatically edit the Xcode project file, performing all the tasks that would normally require opening Xcode:

### Main App Configuration

- Sets bundle ID to `com.drivesync.app`
- Sets iOS deployment target to 16.0+
- Disables automatic code signing
- Configures entitlements file path

### File Provider Extension

- Creates new extension target
- Sets bundle ID to `com.drivesync.app.FileProvider`
- Links Swift source files:
  - `FileProviderExtension.swift`
  - `FileProviderItem.swift`
- Configures Info.plist
- Creates and links entitlements file
- Sets Swift version to 5.0
- Embeds extension in main app

### Capabilities

- App Groups: `group.com.drivesync.app`
- Keychain Sharing
- Background Modes (via Info.plist)

## Verify Configuration

After running the script, verify:

```bash
# Check bundle IDs are set
grep -A2 "PRODUCT_BUNDLE_IDENTIFIER" ios/Runner.xcodeproj/project.pbxproj

# Check entitlements exist
ls ios/Runner/Runner.entitlements
ls ios/FileProviderExt/FileProviderExt.entitlements

# Check Swift files are present
ls ios/FileProviderExt/*.swift
```

## Build Options

### Option 1: GitHub Actions (Recommended)

The CI workflow in `.github/workflows/build.yml` automatically:

1. Sets up Flutter
2. Installs dependencies
3. Runs the configuration script
4. Builds the unsigned .ipa
5. Uploads as artifact

Just push your code and download the result!

### Option 2: Linux/WSL Build (Advanced)

While you can't build iOS apps directly on Linux, you can:

1. Use the script to configure the project
2. Push to GitHub for CI build
3. Or use a remote macOS build service

## Troubleshooting

### "pbxproj not found"

The script auto-installs it, but if that fails:

```bash
pip3 install pbxproj
```

### "Permission denied"

Make the script executable:

```bash
chmod +x configure_xcode.py
```

### "Project file not found"

Make sure you're in the project root:

```bash
cd /mnt/d/Dev/dart/DriveSync/drive_sync
python3 configure_xcode.py
```

### Verify Configuration Was Applied

```bash
# Check if extension target was added
grep -c "FileProviderExt" ios/Runner.xcodeproj/project.pbxproj
# Should output: ~10-20 (multiple references)

# Check bundle IDs
grep "com.drivesync.app" ios/Runner.xcodeproj/project.pbxproj
# Should show both main app and .FileProvider
```

## What You Get

With this no-Xcode setup, you get:

- ✅ Fully configured Xcode project
- ✅ File Provider Extension target
- ✅ All capabilities enabled
- ✅ Ready for CI builds
- ✅ Native Files app integration
- ✅ Complete functionality

**No compromises!**

## Integration with CI

Update `.github/workflows/build.yml` to run the script automatically:

```yaml
- name: Configure Xcode project
  run: python3 configure_xcode.py

- name: Build iOS (unsigned)
  run: flutter build ios --release --no-codesign
```

This ensures every build has the correct configuration.

## Manual Verification (Optional)

If you have access to a Mac later, you can verify the configuration by opening the project in Xcode. Everything should be properly set up:

- Both targets visible in project navigator
- All capabilities enabled
- Swift files linked correctly
- Bundle IDs configured
- Entitlements present

But this verification is **optional** - the script handles everything needed for building!

## Summary

**Traditional Xcode Setup:** 30+ minutes of clicking through Xcode  
**Script Setup:** 30 seconds

```bash
python3 configure_xcode.py
git push
# Wait for CI build
# Download .ipa
# Done!
```

The script eliminates the need for Xcode entirely while providing the same result.
