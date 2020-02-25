#import "../Headers/NFDriverWrapper.h"
#import "../Headers/NFTag.h"

@interface NBETagLockProvider : NSObject {
	NSMutableDictionary *_stateOneStopFlag;
	NSTimer *_stateOneDebounceTimer;
	NSTimer *_stateTwoTimeoutTimer;
}

@property(nonatomic, retain) NFDriverWrapper *driverWrapper;
@property(nonatomic, assign) int currentState;
@property(nonatomic, retain) NSObject<NFTag> *latestTag;
@property(nonatomic, assign) bool screenStateFlag;
@property(nonatomic, assign) float debounceTime;

- (id)initWithDriver:(NFDriverWrapper *)driver;
- (void)_stopStateActivity;
- (void)_changeToState:(int)state;
- (bool)shouldSkipTag:(NSObject <NFTag> *)tag;
- (void)screenStateChanged:(bool)state;
@end