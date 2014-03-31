
#import <Foundation/Foundation.h>
#import "PutIOAPIObject.h"
#import "PutIOAPIAccountInfo.h"
#import "PutIOAPIFile.h"
#import "PutIOAPITransfer.h"

typedef enum{
    PutIOAPIRequestObtainOAuthToken,
    PutIOAPIRequestAccountInfo,
    PutIOAPIRequestFilesList,
    PutIOAPIRequestFilesDelete,
    PutIOAPIRequestTransfersList
} PutIOAPIRequest;

typedef void (^PutIOAPICompletionBlock)(id result, NSError *error, BOOL cancelled);

//@class PutIOAPI;
//
//@protocol PutIOAPIDelegate <NSObject>
//@optional
//- (void)api:(PutIOAPI*)api didBeginRequest:(PutIOAPIRequest)request;
//- (void)api:(PutIOAPI*)api didFinishRequest:(PutIOAPIRequest)request withResult:(id)result;
//- (void)api:(PutIOAPI*)api didFailRequest:(PutIOAPIRequest)request withError:(NSError*)error;
//- (void)api:(PutIOAPI*)api didCancelRequest:(PutIOAPIRequest)request;
//@end

@interface PutIOAPI : NSObject
<NSURLConnectionDataDelegate>

+ (id)api;
//+ (id)apiWithDelegate:(id<PutIOAPIDelegate>)delegate;
+ (void)setOAuthAccessToken:(NSString*)accessToken;
+ (NSString*)oAuthAccessToken;

@property (readonly, getter = isBusy) BOOL busy;
//@property (unsafe_unretained) id<PutIOAPIDelegate>delegate;

- (NSURL*)oauthAuthenticationURL;
- (NSURL*)oauthAuthenticationCallbackURL;

// Authentication
- (void)obtainOAuthAccessTokenForCode:(NSString*)authCode completion:(PutIOAPICompletionBlock)callback;

// Account Info
- (void)accountInfoWithCompletion:(PutIOAPICompletionBlock)callback;

// Files
- (void)filesInRootFolderWithCompletion:(PutIOAPICompletionBlock)callback;
- (void)filesInFolderWithID:(NSInteger)folderID completion:(PutIOAPICompletionBlock)callback;
- (void)deleteFileWithID:(NSInteger)fileID completion:(PutIOAPICompletionBlock)callback;

// Transfers
- (void)activeTransfersWithCompletion:(PutIOAPICompletionBlock)callback;

- (void)cancel;

// Helpers
+(NSString*)urlParameterStringFromDictionary:(NSDictionary*)parameters;

@end
