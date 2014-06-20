
#import "PutIOAPIRequest.h"

@interface PutIOAPIFileDeletionRequest : PutIOAPIRequest

+ (instancetype)requestDeletionOfFileWithID:(NSInteger)fileID completion:(PutIOAPIRequestCompletion)completion;

@end
