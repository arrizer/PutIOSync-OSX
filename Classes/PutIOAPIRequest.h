
#import <Foundation/Foundation.h>

@class PutIOAPI;

typedef enum{
    PutIOAPIMethodGET,
    PutIOAPIMethodPOST
} PutIOAPIMethod;

typedef enum{
    PutIOAPIInternalErrorBadHTTPStatus = 1,
    PutIOAPIInternalErrorNetworkError = 2,
    PutIOAPIInternalErrorMalformedJSON = 3,
    PutIOAPIInternalErrorUnexpectedData = 4,
    PutIOAPIInternalErrorNotAuthorized = 5
} PutIOAPIInternalError;

typedef void (^PutIOAPIRequestCompletion)(void);

@interface PutIOAPIRequest : NSOperation

@property (weak) PutIOAPI *api;
@property (readonly) PutIOAPIMethod method;
@property (readonly) NSString *endpoint;
@property (readonly) NSDictionary *parameters;
@property (readonly) NSString *queryString;
@property (readonly) NSError *error;
@property (readonly) NSURLResponse *urlResponse;
@property (readonly) id responseObject;
@property (assign) BOOL parseAPIResponse;
@property (copy) PutIOAPIRequestCompletion completion;

- (id)initWithMethod:(PutIOAPIMethod)method
            endpoint:(NSString*)endpoint
          parameters:(NSDictionary *)parameters
     completionBlock:(PutIOAPIRequestCompletion)completionBlock;

- (void)parseResponseObject:(id)response;

@end
