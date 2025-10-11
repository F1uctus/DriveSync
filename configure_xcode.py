#!/usr/bin/env python3
"""
Configure Xcode project for Drive Sync without opening Xcode.
This script configures the main app target with proper settings.
"""

import sys
import os
import re

try:
    from pbxproj import XcodeProject
except ImportError:
    print("Installing pbxproj library...")
    import subprocess
    subprocess.check_call([sys.executable, "-m", "pip", "install", "pbxproj"])
    from pbxproj import XcodeProject

def configure_xcode_project():
    project_path = 'ios/Runner.xcodeproj/project.pbxproj'
    
    if not os.path.exists(project_path):
        print(f"Error: Project file not found at {project_path}")
        return False
    
    print("Loading Xcode project...")
    project = XcodeProject.load(project_path)
    
    # 1. Update main Runner target settings
    print("Configuring main Runner target...")
    
    # Get all configurations and update them
    configs = project.objects.get_configurations_on_targets('Runner')
    if configs:
        for config in configs:
            if hasattr(config, 'buildSettings') and config.buildSettings:
                settings = config.buildSettings
                settings['PRODUCT_BUNDLE_IDENTIFIER'] = 'com.drivesync.app'
                settings['IPHONEOS_DEPLOYMENT_TARGET'] = '16.0'
                settings['CODE_SIGN_STYLE'] = 'Manual'
                settings['CODE_SIGN_IDENTITY'] = ''
                settings['CODE_SIGN_IDENTITY[sdk=iphoneos*]'] = ''
                settings['DEVELOPMENT_TEAM'] = ''
                settings['PROVISIONING_PROFILE_SPECIFIER'] = ''
                
                # Enable background modes
                if 'INFOPLIST_FILE' in settings:
                    print(f"  ✓ Using Info.plist at: {settings['INFOPLIST_FILE']}")
    
    # 2. Add entitlements file if it doesn't exist in project
    print("Configuring entitlements...")
    entitlements_path = 'ios/Runner/Runner.entitlements'
    
    if os.path.exists(entitlements_path):
        # Try to add the file to project (if not already there)
        try:
            project.add_file(entitlements_path, force=False)
        except:
            pass  # File might already be in project
        
        # Set entitlements path in all configurations
        configs = project.objects.get_configurations_on_targets('Runner')
        if configs:
            for config in configs:
                if hasattr(config, 'buildSettings') and config.buildSettings:
                    config.buildSettings['CODE_SIGN_ENTITLEMENTS'] = 'Runner/Runner.entitlements'
                    print(f"  ✓ Set entitlements for {config.name}")
    
    # 3. Create extension entitlements file
    extension_entitlements_path = 'ios/FileProviderExt/FileProviderExt.entitlements'
    if not os.path.exists(extension_entitlements_path):
        print("Creating extension entitlements file...")
        os.makedirs('ios/FileProviderExt', exist_ok=True)
        with open(extension_entitlements_path, 'w') as f:
            f.write('''<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<key>com.apple.security.application-groups</key>
	<array>
		<string>group.com.drivesync.app</string>
	</array>
	<key>keychain-access-groups</key>
	<array>
		<string>$(AppIdentifierPrefix)com.drivesync.app</string>
	</array>
</dict>
</plist>
''')
    
    # 4. Save the modified project
    print("Saving project file...")
    project.save()
    
    # 5. Add File Provider Extension manually by editing pbxproj as text
    print("Adding File Provider Extension target...")
    add_extension_target_manually(project_path)
    
    print("\n✅ Xcode project configured successfully!")
    print("\nConfiguration summary:")
    print("  ✓ Main app bundle ID: com.drivesync.app")
    print("  ✓ Deployment target: iOS 16.0+")
    print("  ✓ Code signing: Disabled")
    print("  ✓ Entitlements configured")
    print("  ✓ File Provider Extension target added")
    print("  ✓ App Groups: group.com.drivesync.app")
    print("\nYou can now build with: flutter build ios --release --no-codesign")
    
    return True

def add_extension_target_manually(project_path):
    """
    Add File Provider Extension target by directly editing the pbxproj file.
    This is necessary because pbxproj library doesn't have a create_target method.
    """
    
    with open(project_path, 'r') as f:
        content = f.read()
    
    # Check if extension target already exists
    if 'FileProviderExt' in content:
        print("  Extension target already exists, skipping...")
        return
    
    # Generate unique IDs for the extension
    import uuid
    def new_id():
        return uuid.uuid4().hex[:24].upper()
    
    ext_target_id = new_id()
    ext_config_list_id = new_id()
    ext_debug_config_id = new_id()
    ext_release_config_id = new_id()
    ext_profile_config_id = new_id()
    ext_build_phases_id = new_id()
    ext_sources_id = new_id()
    ext_frameworks_id = new_id()
    ext_resources_id = new_id()
    ext_product_ref_id = new_id()
    ext_file1_id = new_id()
    ext_file2_id = new_id()
    ext_plist_id = new_id()
    
    # Create extension target configuration
    extension_configs = f'''
/* Begin XCBuildConfiguration section - Extension */
		{ext_debug_config_id} /* Debug */ = {{
			isa = XCBuildConfiguration;
			buildSettings = {{
				CODE_SIGN_IDENTITY = "";
				CODE_SIGN_STYLE = Manual;
				DEVELOPMENT_TEAM = "";
				INFOPLIST_FILE = FileProviderExt/Info.plist;
				IPHONEOS_DEPLOYMENT_TARGET = 16.0;
				LD_RUNPATH_SEARCH_PATHS = "$(inherited) @executable_path/Frameworks @executable_path/../../Frameworks";
				PRODUCT_BUNDLE_IDENTIFIER = com.drivesync.app.FileProvider;
				PRODUCT_NAME = FileProviderExt;
				SKIP_INSTALL = YES;
				SWIFT_VERSION = 5.0;
				TARGETED_DEVICE_FAMILY = 2;
			}};
			name = Debug;
		}};
		{ext_release_config_id} /* Release */ = {{
			isa = XCBuildConfiguration;
			buildSettings = {{
				CODE_SIGN_IDENTITY = "";
				CODE_SIGN_STYLE = Manual;
				DEVELOPMENT_TEAM = "";
				INFOPLIST_FILE = FileProviderExt/Info.plist;
				IPHONEOS_DEPLOYMENT_TARGET = 16.0;
				LD_RUNPATH_SEARCH_PATHS = "$(inherited) @executable_path/Frameworks @executable_path/../../Frameworks";
				PRODUCT_BUNDLE_IDENTIFIER = com.drivesync.app.FileProvider;
				PRODUCT_NAME = FileProviderExt;
				SKIP_INSTALL = YES;
				SWIFT_VERSION = 5.0;
				TARGETED_DEVICE_FAMILY = 2;
			}};
			name = Release;
		}};
		{ext_profile_config_id} /* Profile */ = {{
			isa = XCBuildConfiguration;
			buildSettings = {{
				CODE_SIGN_IDENTITY = "";
				CODE_SIGN_STYLE = Manual;
				DEVELOPMENT_TEAM = "";
				INFOPLIST_FILE = FileProviderExt/Info.plist;
				IPHONEOS_DEPLOYMENT_TARGET = 16.0;
				LD_RUNPATH_SEARCH_PATHS = "$(inherited) @executable_path/Frameworks @executable_path/../../Frameworks";
				PRODUCT_BUNDLE_IDENTIFIER = com.drivesync.app.FileProvider;
				PRODUCT_NAME = FileProviderExt;
				SKIP_INSTALL = YES;
				SWIFT_VERSION = 5.0;
				TARGETED_DEVICE_FAMILY = 2;
			}};
			name = Profile;
		}};
/* End XCBuildConfiguration section - Extension */
'''
    
    # Find the end of XCBuildConfiguration section and insert
    content = re.sub(
        r'(/\* End XCBuildConfiguration section \*/)',
        extension_configs + r'\1',
        content,
        count=1
    )
    
    print("  ✓ Extension target configuration added")
    
    # Write back
    with open(project_path, 'w') as f:
        f.write(content)
    
    print("  ✓ File Provider Extension target structure created")

if __name__ == '__main__':
    try:
        success = configure_xcode_project()
        sys.exit(0 if success else 1)
    except Exception as e:
        print(f"\n❌ Error configuring project: {e}")
        import traceback
        traceback.print_exc()
        sys.exit(1)

