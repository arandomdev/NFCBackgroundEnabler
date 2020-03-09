#import "NBETagLockProvider.h"

@implementation NBETagLockProvider

- (id)initWithDriver:(NFDriverWrapper *)driver{
	self = [super init];
	if (self) {
		self.driverWrapper = driver;
		[self _changeToState:0];
	}
	return self;
}

/**
*	Stops ongoing activity in state 1 and 2, and then resets them.
*/
- (void)_stopStateActivity {
	if (self.currentState == 1) {
		if (_stateOneStopFlag) {
			[_stateOneStopFlag setObject:@"1" forKey:@"flag"];
			_stateOneStopFlag = nil;
		}
		if (_stateOneDebounceTimer) {
			[_stateOneDebounceTimer invalidate];
		}
	}
	else if (self.currentState == 2) {
		if (_stateTwoTimeoutTimer) {
			[_stateTwoTimeoutTimer invalidate];
		}
	}
}

- (void)_changeToState:(int)state {
	[self _stopStateActivity];
	self.currentState = state;

	if (state == 1) {
		dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
			// Create the "cancellation token" for this specific dispatch
			NSMutableDictionary *stopFlag = [NSMutableDictionary dictionaryWithObjectsAndKeys:@"0", @"flag", nil];
			_stateOneStopFlag = stopFlag;

			/**
			*	Try to connect to the latestTag, and query it's presence.
			*	On completion, assume the session ended, the tag is no longer present, or it was canceled.
			*/
			if ([self.driverWrapper connectTag:self.latestTag]) {
				while ([self.driverWrapper checkTagPresence:self.latestTag]) {
					[NSThread sleepForTimeInterval:0.1];
					if ([stopFlag[@"flag"] isEqual:@"1"]) {
						[self.driverWrapper disconnectTag:self.latestTag tagRemovalDetect:true];
						return;
					}
				}
				[self.driverWrapper disconnectTag:self.latestTag tagRemovalDetect:true];
			}

			// Notify the delegate of the tag removal
			if (self.tagRemovalDelegate) {
				[self.tagRemovalDelegate tagPresenceRemoved];
			}

			// Start a timer to account for the "debounceTime" between sessions.
			dispatch_async(dispatch_get_main_queue(), ^{
				_stateOneDebounceTimer = [NSTimer scheduledTimerWithTimeInterval:self.debounceTime repeats:false block:^void (NSTimer *timer) {
					[self _changeToState:2];
				}];
			});
			
		});
	}
	else if (state == 2) {
		// Start a timeout timer
		const float timeout = 0.5;
		dispatch_async(dispatch_get_main_queue(), ^{
			_stateTwoTimeoutTimer = [NSTimer scheduledTimerWithTimeInterval:timeout repeats:false block:^void (NSTimer *timer) {
				HBLogInfo(@"Timeout timer elapsed");
				[self _changeToState:0];
			}];
		});
	}
}

- (bool)shouldSkipTag:(NSObject <NFTag> *)tag {
	bool shouldSkip;
	if (self.currentState == 0) {
		self.latestTag = tag;
		[self _changeToState:1];

		shouldSkip = false;
	}
	else {
		if ([self.latestTag.tagID isEqual:tag.tagID]) {
			self.latestTag = tag;
			shouldSkip = true;
		}
		else {
			self.latestTag = tag;
			shouldSkip = false;
		}
		[self _changeToState:1];
	}
	return shouldSkip;
}

/**
*	A method to be called when the screen turns on or off.
*	If the screen turns off during state 1 or 2, assume that the tag stays present during this period of inactivity.
*/
- (void)screenStateChanged:(bool)state {
	if (state == 0) {
		if (self.currentState == 0) {
			self.screenStateFlag = false;
		}
		else {
			self.screenStateFlag = true;
		}
	}
	else {
		if (self.screenStateFlag == true) {
			self.screenStateFlag = false;
			[self _changeToState:2];
		}
		else {
			[self _changeToState:0];
		}
	}
}
@end