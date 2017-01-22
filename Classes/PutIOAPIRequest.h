
@import Foundation;

@class PutIOAPI;

typedef NS_ENUM(unsigned int, PutIOAPIMethod) {
    PutIOAPIMethodGET,
    PutIOAPIMethodPOST
};

typedef NS_ENUM(unsigned int, PutIOAPIInternalError) {
    PutIOAPIInternalErrorBadHTTPStatus = 1,
    PutIOAPIInternalErrorNetworkError = 2,
    PutIOAPIInternalErrorMalformedJSON = 3,
    PutIOAPIInternalErrorUnexpectedData = 4,
    PutIOAPIInternalErrorNotAuthorized = 5
};

typedef void (^PutIOAPIRequestCompletion)(void);

@interface PutIOAPIRequest : NSOperation

@property (weak) PutIOAPI *api;
@property (readonly) PutIOAPIMethod method;
@property (assign) BOOL doesNotRequireAuthentication;
@property (readonly) NSString *endpoint;
@property (readonly) NSDictionary *parameters;
@property (readonly) NSString *queryString;
@property (readonly) NSError *error;
@property (readonly) NSURLResponse *urlResponse;
@property (readonly) id responseObject;
@property (assign) BOOL parseAPIResponse;
@property (copy) PutIOAPIRequestCompletion completion;
@property (assign) dispatch_queue_t completionQueue;

- (instancetype)init NS_UNAVAILABLE;

- (instancetype)initWithMethod:(PutIOAPIMethod)method
            endpoint:(NSString*)endpoint
          parameters:(NSDictionary *)parameters
     completionBlock:(PutIOAPIRequestCompletion)completionBlock NS_DESIGNATED_INITIALIZER;

- (void)parseResponseObject:(id)response;

@end
