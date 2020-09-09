@interface NFCNDEFMessage : NSObject
@property (nonatomic,copy) NSArray *records;
-(id)initWithNFNdefMessage:(id)message;
@end
