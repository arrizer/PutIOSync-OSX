
#import "PutIOAPIRequest.h"
#import "PutIOAPITransfer.h"

@interface PutIOAPITransfersRequest : PutIOAPIRequest

@property (readonly) NSArray *transfers;

+ (instancetype)requestAllTransfersWithCompletion:(PutIOAPIRequestCompletion)completion;

@end
