
#import "PutIOAPI.h"
#import "PutIOAPIKeychainManager.h"
#import "NSDictionary+URLQueryString.h"

#define kDefaultBaseURL @"https://api.put.io/v2"
#define kDefaultAPISecret @"a4gz4pnrnxm2jxchok8v"
#define kDefaultClientID @"197"
#define kDefaultRedirectURI @"https://matthiasschwab.de/putiosync/callback.html"

@interface PutIOAPI()
{
    NSOperationQueue *queue;
}
@end

@implementation PutIOAPI

#pragma mark - Class Methods

+(instancetype)api
{
    static PutIOAPI *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[PutIOAPI alloc] initWithBaseURL:[NSURL URLWithString:kDefaultBaseURL]
                                          oAuthAccessToken:[PutIOAPIKeychainManager keychainItemPassword]
                                             oAuthClientID:kDefaultClientID
                                          oAuthRedirectURI:kDefaultRedirectURI];
    });
    return sharedInstance;
}

#pragma mark - Initializers

-(instancetype)initWithBaseURL:(NSURL *)baseURL
              oAuthAccessToken:(NSString *)oAuthAccessToken
                 oAuthClientID:(NSString *)clientID
              oAuthRedirectURI:(NSString *)redirectURI
{
    self = [super init];
    if (self) {
        _baseURL = baseURL;
        _oAuthAccessToken = oAuthAccessToken;
        _oAuthClientID = clientID;
        _oAuthRedirectURI = redirectURI;
        queue = [[NSOperationQueue alloc] init];
        queue.maxConcurrentOperationCount = 1;
    }
    return self;
}

-(BOOL)isAuthenticated
{
    return (_oAuthAccessToken != nil);
}

#pragma mark - OAuth

- (NSURL *)oAuthAuthenticationURL
{
    NSDictionary *parameters = @{
        @"client_id" : self.oAuthClientID,
        @"response_type" : @"code",
        @"redirect_uri" : self.oAuthRedirectURI
    };
    NSString *urlString = [[self.baseURL URLByAppendingPathComponent:@"oauth2/authenticate"] absoluteString];
    urlString = [urlString stringByAppendingFormat:@"?%@", [parameters URLQueryString]];
    return [NSURL URLWithString:urlString];
}

#pragma mark - Performing Requests

-(void)performRequest:(PutIOAPIRequest *)request
{
    request.api = self;
    [queue addOperation:request];
}

-(void)cancelAllRequests
{
    [queue cancelAllOperations];
}

-(NSURL *)downloadURLForFileWithID:(NSInteger)fileID
{
    NSString *requestURLString = [self.baseURL absoluteString];
    requestURLString = [requestURLString stringByAppendingFormat:@"/files/%ld/download?oauth_token=%@", fileID, self.oAuthAccessToken];
    return [NSURL URLWithString:requestURLString];
}

@end
