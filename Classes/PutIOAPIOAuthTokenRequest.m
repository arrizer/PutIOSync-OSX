
#import "PutIOAPIOAuthTokenRequest.h"
#import "PutIOAPI.h"

@implementation PutIOAPIOAuthTokenRequest

+(instancetype)requestOAuthTokenForCode:(NSString *)code
                                    api:(PutIOAPI *)api
                                 secret:(NSString *)clientSecret
                             completion:(PutIOAPIRequestCompletion)completion
{
    NSDictionary *parameters = @{
        @"client_id" : api.oAuthClientID,
        @"client_secret" : clientSecret,
        @"grant_type" : @"authorization_code",
        @"redirect_uri" : api.oAuthRedirectURI,
        @"code" : code
    };
    PutIOAPIOAuthTokenRequest *request = [[self alloc] initWithMethod:PutIOAPIMethodGET
                                                             endpoint:@"oauth2/access_token"
                                                           parameters:parameters
                                                      completionBlock:completion];
    request.parseAPIResponse = NO;
    return request;
}

@end
