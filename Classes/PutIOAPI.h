
#import <Foundation/Foundation.h>
#import "PutIOAPIRequest.h"

@interface PutIOAPI : NSObject

+ (id)api;

@property (readonly) NSURL *baseURL;
@property (readonly) NSURL *oAuthAuthenticationURL;
@property (readonly) NSString *oAuthClientID;
@property (readonly) NSString *oAuthClientSecret;
@property (readonly) NSString *oAuthRedirectURI;
@property (strong) NSString *oAuthAccessToken;
@property (readonly) BOOL isAuthenticated;

- (instancetype)initWithBaseURL:(NSURL*)baseURL oAuthAccessToken:(NSString*)oAuthAccessToken oAuthClientID:(NSString*)clientID oAuthRedirectURI:(NSString*)redirectURI;
- (NSURL*)downloadURLForFileWithID:(NSInteger)fileID;
- (void)performRequest:(PutIOAPIRequest*)request;
- (void)cancelAllRequests;

@end
