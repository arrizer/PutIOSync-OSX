
#import "PutIOAPIFileRequest.h"

@implementation PutIOAPIFileRequest

+(instancetype)requestFilesInRootFolderWithCompletion:(PutIOAPIRequestCompletion)completion
{
    return [self requestFilesInFolderWithID:0 completion:completion];
}

+(instancetype)requestFilesInFolderWithID:(NSInteger)folderID
                               completion:(PutIOAPIRequestCompletion)completion
{
    return [[self alloc] initWithMethod:PutIOAPIMethodGET
                               endpoint:@"files/list"
                             parameters:@{@"parent_id" : (@(folderID)).stringValue}
                        completionBlock:completion];
}

-(void)parseResponseObject:(id)response
{
    self.parentFolder = [[PutIOAPIFile alloc] initWithRawData:response[@"parent"]];
    
    NSMutableArray *files = [NSMutableArray array];
    for(NSDictionary *fileData in response[@"files"]){
        PutIOAPIFile *file = [[PutIOAPIFile alloc] initWithRawData:fileData];
        [files addObject:file];
    }
    self.files = files;
}

@end
