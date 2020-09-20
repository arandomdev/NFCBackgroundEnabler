@interface NFCNDEFPayload : NSObject
@property (nonatomic,copy) NSData *type;                               //@synthesize type=_type - In the implementation block
@property (nonatomic,copy) NSData *identifier;                         //@synthesize identifier=_identifier - In the implementation block
@property (nonatomic,copy) NSData *payload;                            //@synthesize payload=_payload - In the implementation block
@end
