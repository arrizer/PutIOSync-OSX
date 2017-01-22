
#import "PutIOAPIFileDeletionRequest.h"

@implementation PutIOAPIFileDeletionRequest

+(instancetype)requestDeletionOfFileWithID:(NSInteger)fileID completion:(PutIOAPIRequestCompletion)completion
{
    return [[self alloc] initWithMethod:PutIOAPIMethodPOST
                               endpoint:@"files/delete"
                             parameters:@{@"file_ids" : (@(fileID)).stringValue}
                        completionBlock:completion];
}

@end
