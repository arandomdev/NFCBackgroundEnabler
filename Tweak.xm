#import "Headers/NFBackgroundTagReadingManager.h"
#import "Headers/NFDriverWrapper.h"
#import "Headers/NFTimer.h"
#import "Headers/NFTag.h"
#import "NBETagLockProvider/NBETagLockProvider.h"
#import "NBETagLockProvider/NBETagRemovalProtocol.h"

float protectionTime = 2;
float debounceTime = 1;
bool airplaneOverride = false;
bool tagLockEnable = YES;

%hook NFHardwareControllerInfo
- (bool)hasLPCDSupport {
	// Enables background tag detection.
	return YES;
}
%end

%hook NFTimer
- (void)startTimer:(double)time leeway:(double)leeway {
	/**
	*	_readermodeBurnoutProtectionDebounceTimer
	*	The timer that dictates how long to wait before a new session can start.
	*	Originally set for 5 seconds.
	*/
	const double originalDebounceTimerTime = 5;

	if (time == originalDebounceTimerTime) {
		%orig(debounceTime, leeway);
		HBLogInfo(@"DebounceTimer fired with: %f and: %f", debounceTime, leeway);
	}
	else {
		%orig();
	}
}
%end

%hook NFBackgroundTagReadingManager
%property(nonatomic, retain) NBETagLockProvider *tagLockProvider;

- (id)initWithQueue:(id)queue driverWrapper:(NFDriverWrapper *)driverWrapper lpcdHWSupport:(bool)arg3 {
	id orig = %orig;
	if (orig) {
		self.tagLockProvider = [[NBETagLockProvider alloc] initWithDriver:driverWrapper];
		self.tagLockProvider.tagRemovalDelegate = self;
	}
	return orig;
}

- (void)didScreenStateChange:(bool)state {
	[self.tagLockProvider screenStateChanged:state];
	%orig;
}

- (void)handleDetectedTags:(NSMutableArray <NSObject<NFTag> *> *)tags {
	HBLogInfo(@"Detected tags, count: %lu", [tags count]);

	/**
	*	_readermodeBurnoutProtectionTimer
	*	The timer that dictates how long a session can last.
	*	Modified here because it also affects app sessions.
	*/
	NFDriverWrapper *driverWrapper = MSHookIvar<NFDriverWrapper *>(self, "_driverWrapper");
	NFTimer *protectionTimer = MSHookIvar<NFTimer *>(driverWrapper, "_readermodeBurnoutProtectionTimer");

	if (!tagLockEnable) {
		HBLogInfo(@"Restarting Timer to: %f", protectionTime);
		[protectionTimer stopTimer];
		[protectionTimer startTimer:protectionTime leeway:0.1];
	}

	if (tagLockEnable) {
		self.tagLockProvider.debounceTime = debounceTime;
		if (![self.tagLockProvider shouldSkipTag:tags[0]]) {
			%orig;
		}
	}
	else {
		%orig;
	}
	
}

- (bool)updateAirplaneMode {
	bool orig = %orig;

	if (airplaneOverride) {
		MSHookIvar<bool>(self, "_airplaneMode") = NO;
	}
	return orig;
}

%new
- (void)tagPresenceRemoved {
	NFDriverWrapper *driverWrapper = MSHookIvar<NFDriverWrapper *>(self, "_driverWrapper");

	// A lock is used whenever the _burnoutProtectionState is accessed
	NSLock *lock = MSHookIvar<NSLock *>(driverWrapper, "_burnoutStateLock");
	[lock lock];

	// If the state is 1, the protection timer has not finished yet
	if (MSHookIvar<unsigned int>(driverWrapper, "_burnoutProtectionState") == 1) {
		HBLogInfo(@"End Session now");
		NFTimer *protectionTimer = MSHookIvar<NFTimer *>(driverWrapper, "_readermodeBurnoutProtectionTimer");
		[protectionTimer stopTimer];
		[protectionTimer startTimer:0 leeway:0];
	}
	[lock unlock];
}
%end

static void reloadPreferences() {
	NSString *preferencesFilePath = [NSString stringWithFormat:@"/User/Library/Preferences/com.haotestlabs.nfcbackgroundenablerpreferences.plist"];
	
	NSData *fileData = [NSData dataWithContentsOfFile:preferencesFilePath];
	if (fileData) {
		NSError *error = nil;
		NSDictionary *preferences = [NSPropertyListSerialization propertyListWithData:fileData options:NSPropertyListImmutable format:nil error:&error];
		
		if (error) {
			HBLogError(@"Unable to read preference file, Error: %@", error);
		}
		else {
			if (preferences[@"ProtectionTime"]) {
				protectionTime = [preferences[@"ProtectionTime"] floatValue];
			}
			if (preferences[@"DebounceTime"]) {
				debounceTime = [preferences[@"DebounceTime"] floatValue];
			}
			if (preferences[@"AirplaneOverride"]) {
				airplaneOverride = [preferences[@"AirplaneOverride"] boolValue];
			}
			if (preferences[@"TagLockEnable"]) {
				tagLockEnable = [preferences[@"TagLockEnable"] boolValue];
			}
		}
	}
}

%ctor {
	HBLogDebug(@"Hooked");

	reloadPreferences();
	CFNotificationCenterAddObserver(
		CFNotificationCenterGetDarwinNotifyCenter(),
		NULL,
		(CFNotificationCallback)reloadPreferences,
		CFSTR("com.haotestlabs.nfcbackgroundenablerpreferences.reload"),
		NULL,
		CFNotificationSuspensionBehaviorCoalesce
	);
}