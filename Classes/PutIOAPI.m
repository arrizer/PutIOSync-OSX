
#import "PutIOAPI.h"
#include <Security/Security.h>
#include <CoreServices/CoreServices.h>

#define PUTIO_API_SECRET @"a4gz4pnrnxm2jxchok8v"
#define PUTIO_API_CLIENTID @"197"
#define PUTIO_API_OAUTH_REDIRECTURI @"https://matthiasschwab.de/putiosync/callback.html"
#define PUTIO_API_URL @"https://api.put.io/v2"

typedef enum{
    PutIOAPIEndpointMethodGET,
    PutIOAPIEndpointMethodPOST
} PutIOAPIEndpointMethod;

typedef enum{
    PutIOAPIInternalErrorBadHTTPStatus,
    PutIOAPIInternalErrorNetworkError,
    PutIOAPIInternalErrorMalformedJSON,
    PutIOAPIInternalErrorUnexpectedData,
    PutIOAPIInternalErrorNotAuthorized
} PutIOAPIInternalError;

static NSString *oAuthAccessToken;

@interface PutIOAPI()
{
    PutIOAPIRequest currentRequest;
    PutIOAPICompletionBlock callback;
    NSURLConnection *urlConnection;
    NSURLResponse *urlResponse;
    NSMutableData *incomingData;
}

@property (assign) BOOL busy;

@end

@implementation PutIOAPI
@synthesize busy;

#pragma mark - Class Methods

+ (id)api
{
    PutIOAPI *api = [[PutIOAPI alloc] init];
    return api;
}

+ (void)setOAuthAccessToken:(NSString*)accessToken
{
    oAuthAccessToken = accessToken;
    [PutIOAPI setKeychainItemPassword:oAuthAccessToken];
}

static BOOL triedToLoadAccessToken = NO;

+ (NSString *)oAuthAccessToken
{
    if(oAuthAccessToken == nil && !triedToLoadAccessToken){
        oAuthAccessToken = [PutIOAPI keychainItemPassword];
        //triedToLoadAccessToken = YES;
    }
    return oAuthAccessToken;
}

#pragma mark -

- (id)init
{
    self = [super init];
    if (self) {

    }
    return self;
}

#pragma mark - OAuth

- (NSURL *)oauthAuthenticationURL
{
    NSString *url = @"https://api.put.io/v2/oauth2/authenticate?";
    NSDictionary *parameters = @{
        @"client_id" : PUTIO_API_CLIENTID,
        @"response_type" : @"code",
        @"redirect_uri" : PUTIO_API_OAUTH_REDIRECTURI
    };
    url = [url stringByAppendingString:[PutIOAPI urlParameterStringFromDictionary:parameters]];
    return [NSURL URLWithString:url];
}

- (NSURL *)oauthAuthenticationCallbackURL
{
    return [NSURL URLWithString:PUTIO_API_OAUTH_REDIRECTURI];    
}

- (void)obtainOAuthAccessTokenForCode:(NSString *)authCode completion:(PutIOAPICompletionBlock)aCallback;
{
    NSString *url = @"https://api.put.io/v2/oauth2/access_token?";
    NSDictionary *parameters = @{
        @"client_id" : PUTIO_API_CLIENTID,
        @"client_secret" : PUTIO_API_SECRET,
        @"grant_type" : @"authorization_code",
        @"redirect_uri" : PUTIO_API_OAUTH_REDIRECTURI,
        @"code" : authCode
    };
    url = [url stringByAppendingString:[PutIOAPI urlParameterStringFromDictionary:parameters]];
    currentRequest = PutIOAPIRequestObtainOAuthToken;
    callback = aCallback;
    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:url]];
    incomingData = nil;
    urlConnection = [NSURLConnection connectionWithRequest:request delegate:self];
    self.busy = YES;
}

#pragma mark - Perform Requests

- (void)performRequestToEndpoint:(NSString *)endpoint
                          method:(PutIOAPIEndpointMethod)method
                      parameters:(NSDictionary *)inParameters
                        callback:(PutIOAPICompletionBlock)newCallback
{
    if([self isBusy]){
        [self cancel];
    }
    if([PutIOAPI oAuthAccessToken] == nil){
        [self failWithInternalError:PutIOAPIInternalErrorNotAuthorized userMessage:nil];
        return;
    }
    callback = newCallback;
    
    NSString *requestURLString = PUTIO_API_URL;
    requestURLString = [requestURLString stringByAppendingString:endpoint];
    NSMutableDictionary *parameters;
    if(inParameters == nil){
        parameters = [NSMutableDictionary dictionary];
    }else{
        parameters = [inParameters mutableCopy];
    }
    [parameters setObject:[PutIOAPI oAuthAccessToken] forKey:@"oauth_token"];
    NSString *parameterString = [PutIOAPI urlParameterStringFromDictionary:parameters];
    if(method == PutIOAPIEndpointMethodGET)
        requestURLString = [requestURLString stringByAppendingFormat:@"?%@", parameterString];
    NSURL *requestURL = [NSURL URLWithString:requestURLString];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:requestURL];
    if(method == PutIOAPIEndpointMethodPOST){
        [request setHTTPBody:[parameterString dataUsingEncoding:NSUTF8StringEncoding]];
        [request setHTTPMethod:@"POST"];
        [request setValue:@"application/x-www-form-urlencoded" forHTTPHeaderField:@"Content-Type"];
    }
    //NSLog(@"API request to endpoint: %@\nParameters: %@", endpoint, [[parameters description] stringByReplacingOccurrencesOfString:@"\n" withString:@""]);
    incomingData = nil;
    urlConnection = [NSURLConnection connectionWithRequest:request delegate:self];
    self.busy = YES;
}

+(NSString*)urlParameterStringFromDictionary:(NSDictionary*)parameters
{
    NSMutableArray *parts = [NSMutableArray array];
    for(NSString *key in parameters){
        NSString *value = [parameters objectForKey:key];
        NSString *encodedKey = [key stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
        NSString *encodedValue = [value stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
        NSString *part = [NSString stringWithFormat: @"%@=%@", encodedKey, encodedValue];
        [parts addObject: part];
    }
    return [parts componentsJoinedByString: @"&"];
}

-(void)cancel
{
    if(![self isBusy]){
        return;
    }
    [urlConnection cancel];
    incomingData = nil;
    self.busy = NO;
    if(callback != nil){
        callback(nil, nil, YES);
    }
}

#pragma mark - API Methods
#pragma mark Account Info

-(void)accountInfoWithCompletion:(PutIOAPICompletionBlock)aCallback
{
    currentRequest = PutIOAPIRequestAccountInfo;
    NSString *endpoint = @"/account/info";
    [self performRequestToEndpoint:endpoint method:PutIOAPIEndpointMethodGET parameters:nil callback:aCallback];
}

#pragma mark Files

-(void)filesInRootFolderWithCompletion:(PutIOAPICompletionBlock)aCallback
{
    [self filesInFolderWithID:0 completion:aCallback];
}

-(void)filesInFolderWithID:(NSInteger)folderID completion:(PutIOAPICompletionBlock)aCallback
{
    currentRequest = PutIOAPIRequestFilesList;
    NSString *endpoint = @"/files/list";
    NSDictionary *parameters = @{@"parent_id" : [@(folderID) stringValue]};
    [self performRequestToEndpoint:endpoint method:PutIOAPIEndpointMethodGET parameters:parameters callback:aCallback];
}

- (void)deleteFileWithID:(NSInteger)fileID completion:(PutIOAPICompletionBlock)aCallback
{
    currentRequest = PutIOAPIRequestFilesDelete;
    NSString *endpoint = @"/files/delete";
    NSDictionary *parameters = @{@"file_ids" : [@(fileID) stringValue]};
    [self performRequestToEndpoint:endpoint method:PutIOAPIEndpointMethodPOST parameters:parameters callback:aCallback];
}

#pragma mark Transfers

- (void)activeTransfersWithCompletion:(PutIOAPICompletionBlock)aCallback
{
    currentRequest = PutIOAPIRequestTransfersList;
    NSString *endpoint = @"/transfers/list";
    [self performRequestToEndpoint:endpoint method:PutIOAPIEndpointMethodGET parameters:nil callback:aCallback];
}

#pragma mark - Result Handling

-(void)handleResponseWithJSONResult:(NSDictionary*)jsonResponse
{
    //NSLog(@"Result: %@", [jsonResponse description]);
    id response;
    switch (currentRequest) {
        case PutIOAPIRequestObtainOAuthToken:{
            response = [[PutIOAPIObject alloc] initWithRawData:jsonResponse];
            break;
        }
        case PutIOAPIRequestAccountInfo:{
            response = [[PutIOAPIAccountInfo alloc] initWithRawData:jsonResponse];
            break;
        }
        case PutIOAPIRequestFilesList:{
            NSMutableArray *files = [NSMutableArray array];
            for(NSDictionary *fileData in jsonResponse[@"files"]){
                PutIOAPIFile *file = [[PutIOAPIFile alloc] initWithRawData:fileData];
                [files addObject:file];
            }
            response = @{
            @"files" : files,
            @"parent" : [[PutIOAPIFile alloc] initWithRawData:jsonResponse[@"parent"]]
            };
            break;
        }
        case PutIOAPIRequestTransfersList:{
            NSMutableArray *transfers = [NSMutableArray array];
            for(NSDictionary *transferData in jsonResponse[@"transfers"]){
                PutIOAPITransfer *transfer = [[PutIOAPITransfer alloc] initWithRawData:transferData];
                [transfers addObject:transfer];
            }
            response = transfers;
            break;
        }
        default:
            break;
    }
    [self finishRequestWithResult:response];
}

-(void)handleResponseWithDataResult:(NSData*)result
{
    
}

-(void)finishRequestWithResult:(PutIOAPIObject*)object
{
    self.busy = NO;
    if(callback != nil){
        callback(object, nil, NO);
    }
}

#pragma mark - URL Connection Delegate

- (void)connection:(NSURLConnection *)connection
didReceiveResponse:(NSURLResponse *)response
{
    urlResponse = response;
}

-(void)connection:(NSURLConnection *)connection
   didReceiveData:(NSData *)data
{
    if(!incomingData){
        incomingData = [NSMutableData data];
    }
    [incomingData appendData:data];
}

-(void)connectionDidFinishLoading:(NSURLConnection *)connection
{
    urlConnection = nil;
    NSDictionary *responseHeaders = [(NSHTTPURLResponse*)urlResponse allHeaderFields];
    NSInteger httpStatus = [(NSHTTPURLResponse*)urlResponse statusCode];
    if(httpStatus >= 400){
        [self failWithInternalError:PutIOAPIInternalErrorBadHTTPStatus userMessage:NSLocalizedString(@"The server responded with an error", nil)];
    }else{
        if(incomingData){
            NSString *contentType = [responseHeaders objectForKey:@"Content-Type"];
            if([contentType isEqualToString:@"application/json"]){
                NSError *JSONError;
                id result = [NSJSONSerialization JSONObjectWithData:incomingData options:0 error:&JSONError];
                if(result && [result isKindOfClass:[NSDictionary class]]){
                    NSString *status = [(NSDictionary*)result objectForKey:@"status"];
                    if([status isEqualToString:@"OK"] || currentRequest == PutIOAPIRequestObtainOAuthToken){
                        [self handleResponseWithJSONResult:result];
                    }else{
                        NSString *errorType = [(NSDictionary*)result objectForKey:@"error_type"];
                        NSString *errorMessage = [(NSDictionary*)result objectForKey:@"error_message"];
                        [self failWithPutIOErrorName:errorType userMessage:errorMessage];
                    }
                }else{
                    [self failWithInternalError:PutIOAPIInternalErrorMalformedJSON
                                    userMessage:[JSONError localizedDescription]];
                }
            }else{
                [self handleResponseWithDataResult:incomingData];
            }
        }else{
            [self failWithInternalError:PutIOAPIInternalErrorUnexpectedData userMessage:nil];
        }
    }
}

-(void)connection:(NSURLConnection *)connection
 didFailWithError:(NSError *)error
{
    urlConnection = nil;
    incomingData = nil;
    [self failWithInternalError:PutIOAPIInternalErrorNetworkError
                    userMessage:[error localizedDescription]];
}

#pragma mark - Error Handling

- (void)failWithInternalError:(PutIOAPIInternalError)internalError
                  userMessage:(NSString*)userMessage
{
    if(!userMessage)
        userMessage = NSLocalizedString(@"Communication with put.io failed", @"General internal API communication error");
    NSError *error = [NSError errorWithDomain:@"putioapi.internal"
                                         code:(NSInteger)internalError
                                     userInfo:@{NSLocalizedDescriptionKey : userMessage}];
    NSLog(@"Request failed: [internal error %i] %@", internalError, userMessage);
    [self failWithError:error];
}

- (void)failWithPutIOErrorName:(NSString*)errorName
                   userMessage:(NSString*)message
{
    NSDictionary *knownPutIOErrors = @{
    @"FileNotFoundError" : NSLocalizedString(@"File was not found on put.io", @"PutIO API Error 'FileNotFoundError'"),
    @"TransferNotFoundError" : NSLocalizedString(@"Transfer is not present at put.io", @"PutIO API Error 'TransferNotFoundError'")
    };
    if(!message)
        message = [knownPutIOErrors objectForKey:errorName];
    if(!message)
        message = errorName;
    NSError *error = [NSError errorWithDomain:@"putioapi"
                                         code:0
                                     userInfo:@{NSLocalizedDescriptionKey : message}];
    NSLog(@"Request failed: [PutIO error '%@'] %@", errorName, message);
    [self failWithError:error];
}

- (void)failWithError:(NSError*)error
{
    self.busy = NO;
    NSLog(@"API Error: %@", [error description]);
    if(callback != nil){
        callback(nil, error, NO);
    }
}

#pragma mark - Keychain

static void *keychainServiceName = "PutIOSync";
static void *keychainAccountName = "APIOAuthToken";

+ (NSString*)keychainItemPassword
{
    OSStatus status;
    UInt32 passwordLength;
    void *passwordData = nil;
    SecKeychainItemRef itemRef = nil;
    NSString *password = nil;
    status = SecKeychainFindGenericPassword(NULL,
                                            (UInt32)strlen(keychainServiceName), keychainServiceName,
                                            (UInt32)strlen(keychainAccountName), keychainAccountName,
                                            &passwordLength, &passwordData, &itemRef);
    if(status == noErr){
        password = [[NSString alloc] initWithBytes:passwordData length:passwordLength encoding:NSUTF8StringEncoding];
        SecKeychainItemFreeContent(NULL, passwordData);
        //NSLog(@"Successfully read keychain item");
    }else{
        if(status != noErr)
            NSLog(@"Failed to get keychain item: %@", (NSString*)CFBridgingRelease(SecCopyErrorMessageString(status, NULL)));
    }
    return password;
}

+ (void)setKeychainItemPassword:(NSString*)password
{
    OSStatus status;
    SecKeychainItemRef itemRef = nil;
    void *passwordData = (void*)[password cStringUsingEncoding:NSUTF8StringEncoding];
    // Check if the item is already in the keycain
    status = SecKeychainFindGenericPassword(NULL,
                                            (UInt32)strlen(keychainServiceName), keychainServiceName,
                                            (UInt32)strlen(keychainAccountName), keychainAccountName,
                                            NULL, NULL,
                                            &itemRef);
    if(status == noErr){
        // Update the existing item
        status = SecKeychainItemModifyAttributesAndData(itemRef, NULL, (UInt32)strlen(passwordData), passwordData);
        if(status != noErr)
            NSLog(@"Failed to update keychain item: %@", (NSString*)CFBridgingRelease(SecCopyErrorMessageString(status, NULL)));
    }else if(status == errSecItemNotFound){
        // Create a new item
        status = SecKeychainAddGenericPassword(NULL,
                                               (UInt32)strlen(keychainServiceName), keychainServiceName,
                                               (UInt32)strlen(keychainAccountName), keychainAccountName,
                                               (UInt32)strlen(passwordData), passwordData,
                                               NULL);
        if(status != noErr)
            NSLog(@"Failed to add new keychain item: %@", (NSString*)CFBridgingRelease(SecCopyErrorMessageString(status, NULL)));
    }
}

@end