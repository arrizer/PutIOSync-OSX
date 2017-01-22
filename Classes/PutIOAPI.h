
@import Foundation;
#import "PutIOAPIRequest.h"

@interface PutIOAPI : NSObject

+ (instancetype)api;

@property (readonly) NSURL *baseURL;
@property (readonly) NSURL *oAuthAuthenticationURL;
@property (readonly) NSURL *oAuthLogoutURL;
@property (readonly) NSString *oAuthClientID;
@property (readonly) NSString *oAuthClientSecret;
@property (readonly) NSString *oAuthRedirectURI;
@property (strong, nonatomic) NSString *oAuthAccessToken;
@property (readonly) BOOL isAuthenticated;

- (instancetype)initWithBaseURL:(NSURL*)baseURL oAuthAccessToken:(NSString*)oAuthAccessToken oAuthClientID:(NSString*)clientID oAuthRedirectURI:(NSString*)redirectURI NS_DESIGNATED_INITIALIZER;
- (NSURL*)downloadURLForFileWithID:(NSInteger)fileID;
- (void)performRequest:(PutIOAPIRequest*)request;
- (void)cancelAllRequests;

@end
