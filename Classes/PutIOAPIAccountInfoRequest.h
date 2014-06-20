
#import "PutIOAPIRequest.h"
#import "PutIOAPIAccountInfo.h"

@interface PutIOAPIAccountInfoRequest : PutIOAPIRequest

@property (readonly) PutIOAPIAccountInfo *accountInfo;

+ (instancetype)requestWithCompletion:(PutIOAPIRequestCompletion)completion;

@end
