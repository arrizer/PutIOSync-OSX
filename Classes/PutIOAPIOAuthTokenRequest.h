
#import "PutIOAPIRequest.h"

@class PutIOAPI;

@interface PutIOAPIOAuthTokenRequest : PutIOAPIRequest

+(instancetype)requestOAuthTokenForCode:(NSString *)code api:(PutIOAPI*)api secret:(NSString*)clientSecret completion:(PutIOAPIRequestCompletion)completion;

@end
