
#import "PutIOAPIAccountInfoRequest.h"

@implementation PutIOAPIAccountInfoRequest

+(instancetype)requestWithCompletion:(PutIOAPIRequestCompletion)completion
{
    return [[self alloc] initWithMethod:PutIOAPIMethodGET
                               endpoint:@"account/info"
                             parameters:nil
                        completionBlock:completion];
}

-(void)parseResponseObject:(id)response
{
    _accountInfo = [[PutIOAPIAccountInfo alloc] initWithRawData:response];
}

@end
