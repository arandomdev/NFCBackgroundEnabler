#import <Preferences/PSSpecifier.h>
#import "NBEPRootListController.h"

@implementation NBEPRootListController

- (NSArray *)specifiers {
	if (!_specifiers) {
		_specifiers = [self loadSpecifiersFromPlistName:@"Root" target:self];
	}

	return _specifiers;
}

// Section copied and modified from https://iphonedevwiki.net/index.php/PreferenceBundles#Into_sandboxed.2Funsandboxed_processes_in_iOS_8
- (id)readPreferenceValue:(PSSpecifier *)specifier {
	// Read and return the value from the file
	NSString *preferencesFilePath = [NSString stringWithFormat:@"/User/Library/Preferences/%@.plist", specifier.properties[@"defaults"]];
	id preferenceValue = specifier.properties[@"default"];

	NSData *fileData = [NSData dataWithContentsOfFile:preferencesFilePath];
	if (fileData) {
		NSError *error = nil;
		NSDictionary *preferences = [NSPropertyListSerialization propertyListWithData:fileData options:NSPropertyListImmutable format:NULL error:&error];
		
		if (error) {
			HBLogError(@"Unable to read preference file, Error: %@", error);
		}
		else if (preferences[specifier.properties[@"key"]]) {
			preferenceValue = preferences[specifier.properties[@"key"]];
		}
	}
	
	// Disable the ProtectionTime option when TagLockEnable is enabled.
	if ([specifier.properties[@"key"] isEqual:@"TagLockEnable"]) {
		self.protectionTimeEnable = ![preferenceValue boolValue];
		[self updateProtectionTimeEnable];
	}

	return preferenceValue;
}

- (void)setPreferenceValue:(id)value specifier:(PSSpecifier*)specifier {
	// Disable the ProtectionTime option when TagLockEnable is enabled.
	if ([specifier.properties[@"key"] isEqual:@"TagLockEnable"]) {
		self.protectionTimeEnable = ![value boolValue];
		[self updateProtectionTimeEnable];
	}

	NSString *preferencesFilePath = [NSString stringWithFormat:@"/User/Library/Preferences/%@.plist", specifier.properties[@"defaults"]];

	// Read the old preference file.
	NSDictionary *preferences = nil;
	NSError *error = nil;
	
	NSData *fileData = [NSData dataWithContentsOfFile:preferencesFilePath];
	if (fileData) {
		preferences = [NSPropertyListSerialization propertyListWithData:fileData options:NSPropertyListImmutable format:NULL error:&error];

		if (error) {
			HBLogError(@"Unable to read old preference file, Error: %@", error);
		}
	}

	// Copy the old preferences with the current value.
	NSMutableDictionary *updatedPreferences = [NSMutableDictionary dictionary];
	[updatedPreferences addEntriesFromDictionary:preferences];
	[updatedPreferences setObject:value forKey:specifier.properties[@"key"]];

	// Write the file to disk.
	NSData *newFileData = [NSPropertyListSerialization dataWithPropertyList:updatedPreferences format:NSPropertyListXMLFormat_v1_0 options:0 error:&error];
	if (error) {
		HBLogError(@"Unable to format updatePreferences to NSData, Error: %@", error);
	}
	[newFileData writeToFile:preferencesFilePath atomically:YES];

	CFStringRef notificationName = (__bridge CFStringRef)specifier.properties[@"PostNotification"];
	if (notificationName) {
		CFNotificationCenterPostNotification(CFNotificationCenterGetDarwinNotifyCenter(), notificationName, NULL, NULL, YES);
	}
}

- (void)updateProtectionTimeEnable {
	PSSpecifier *protectionSlider = [self specifiers][2];

	[[protectionSlider propertyForKey:@"cellObject"] setCellEnabled:self.protectionTimeEnable];
	[[protectionSlider propertyForKey:@"control"] setEnabled:self.protectionTimeEnable];
}

- (void)viewDidAppear:(BOOL)animated; {
	[self updateProtectionTimeEnable];
	[super viewDidAppear:animated];
}
@end
