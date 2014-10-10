
#import "PutIOAPIRequest.h"
#import "PutIOAPI.h"
#import "NSDictionary+URLQueryString.h"

@interface PutIOAPIRequest()

@property (assign) PutIOAPIMethod method;
@property (strong) NSString *endpoint;
@property (strong) NSDictionary *parameters;

@end

@implementation PutIOAPIRequest

-(id)initWithMethod:(PutIOAPIMethod)method
           endpoint:(NSString *)endpoint
         parameters:(NSDictionary *)parameters
    completionBlock:(PutIOAPIRequestCompletion)completionBlock
{
    self = [super init];
    if (self) {
        self.method = method;
        self.endpoint = endpoint;
        self.parameters = parameters;
        self.completion = completionBlock;
        self.parseAPIResponse = YES;
    }
    return self;
}

-(NSString *)queryString
{
    return [self.parameters URLQueryString];
}

-(void)main
{
    NSString *requestURLString = [self.api.baseURL absoluteString];
    requestURLString = [requestURLString stringByAppendingPathComponent:self.endpoint];
    NSMutableDictionary *parameters;
    if(self.parameters == nil){
        parameters = [NSMutableDictionary dictionary];
    }else{
        parameters = [self.parameters mutableCopy];
    }
    
    // only add the oauth token if we are logged in
    if (self.api.oAuthAccessToken) {
        parameters[@"oauth_token"] = self.api.oAuthAccessToken;
    }
    
    NSString *parameterString = [parameters URLQueryString];
    if(self.method == PutIOAPIMethodGET){
        requestURLString = [requestURLString stringByAppendingFormat:@"?%@", parameterString];
    }
    NSURL *requestURL = [NSURL URLWithString:requestURLString];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:requestURL];
    if(self.method == PutIOAPIMethodPOST){
        [request setHTTPBody:[parameterString dataUsingEncoding:NSUTF8StringEncoding]];
        [request setHTTPMethod:@"POST"];
        [request setValue:@"application/x-www-form-urlencoded" forHTTPHeaderField:@"Content-Type"];
    }
    NSLog(@"<API> %@\nParameters: %@", requestURL, [self.parameters description]);

    NSError *networkError;
    NSURLResponse *response;
    NSData *data = [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&networkError];
    _urlResponse = response;
    if(networkError){
        [self failWithInternalError:PutIOAPIInternalErrorNetworkError userMessage:networkError.localizedDescription];
    }else{
        [self parseResponse:data];
    }
    dispatch_sync(dispatch_get_main_queue(), ^{
        if(self.completion != nil){
            self.completion();
        }
    });
}

- (void)parseResponse:(NSData*)data
{
    NSDictionary *responseHeaders = [(NSHTTPURLResponse*)self.urlResponse allHeaderFields];
    NSInteger httpStatus = [(NSHTTPURLResponse*)self.urlResponse statusCode];
    if(httpStatus >= 400){
        [self failWithInternalError:PutIOAPIInternalErrorBadHTTPStatus
                        userMessage:NSLocalizedString(@"The server responded with an error", nil)];
    }else{
        if(data){
            NSString *contentType = [responseHeaders objectForKey:@"Content-Type"];
            if([contentType isEqualToString:@"application/json"]){
                NSError *JSONError;
                id result = [NSJSONSerialization JSONObjectWithData:data options:0 error:&JSONError];
                _responseObject = result;
                if(self.parseAPIResponse){
                    if(result && [result isKindOfClass:[NSDictionary class]]){
                        NSString *status = [(NSDictionary*)result objectForKey:@"status"];
                        if([status isEqualToString:@"OK"]){
                            [self parseResponseObject:result];
                        }else{
                            NSString *errorType = ((NSDictionary*)result)[@"error_type"];
                            NSString *errorMessage = ((NSDictionary*)result)[@"error_message"];
                            [self failWithPutIOErrorName:errorType userMessage:errorMessage];
                        }
                    }else{
                        [self failWithInternalError:PutIOAPIInternalErrorMalformedJSON
                                        userMessage:[JSONError localizedDescription]];
                    }
                }
            }else{
                [self failWithInternalError:PutIOAPIInternalErrorUnexpectedData userMessage:nil];
            }
        }else{
            [self failWithInternalError:PutIOAPIInternalErrorUnexpectedData userMessage:nil];
        }
    }

}

- (void)parseResponseObject:(id)response
{
    
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
    NSLog(@"API Error: %@", [error description]);
    _error = error;
}

@end
