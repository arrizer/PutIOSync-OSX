
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

@class PutIOAPI;

@protocol PutIOAPIDelegate <NSObject>
@optional
- (void)api:(PutIOAPI*)api didBeginRequest:(PutIOAPIRequest)request;
- (void)api:(PutIOAPI*)api didFinishRequest:(PutIOAPIRequest)request withResult:(id)result;
- (void)api:(PutIOAPI*)api didFailRequest:(PutIOAPIRequest)request withError:(NSError*)error;
- (void)api:(PutIOAPI*)api didCancelRequest:(PutIOAPIRequest)request;
@end

@interface PutIOAPI : NSObject
<NSURLConnectionDataDelegate>
{
    PutIOAPIRequest currentRequest;
    NSURLConnection *urlConnection;
    NSURLResponse *urlResponse;
    NSMutableData *incomingData;
}

+(id)api;
+(id)apiWithDelegate:(id<PutIOAPIDelegate>)delegate;
+(void)setOAuthAccessToken:(NSString*)accessToken;
+(NSString*)oAuthAccessToken;

@property (readonly, getter = isBusy) BOOL busy;
@property (unsafe_unretained) id<PutIOAPIDelegate>delegate;

- (NSURL*)oauthAuthenticationURL;
- (NSURL*)oauthAuthenticationCallbackURL;

// Authentication
- (void)obtainOAuthAccessTokenForCode:(NSString*)authCode;

// Account Info
- (void)accountInfo;

// Files
- (void)filesInRootFolder;
- (void)filesInFolderWithID:(NSInteger)folderID;
- (void)deleteFileWithID:(NSInteger)fileID;

// Transfers
- (void)activeTransfers;

- (void)cancel;

// Helpers
+(NSString*)urlParameterStringFromDictionary:(NSDictionary*)parameters;

@end
