
#import "PutIOAPITransfersRequest.h"

@implementation PutIOAPITransfersRequest

+(instancetype)requestAllTransfersWithCompletion:(PutIOAPIRequestCompletion)completion
{
    return [[self alloc] initWithMethod:PutIOAPIMethodGET
                               endpoint:@"transfers/list"
                             parameters:nil
                        completionBlock:completion];
}

-(void)parseResponseObject:(id)response
{
    NSMutableArray *transfers = [NSMutableArray array];
    for(NSDictionary *transferData in response[@"transfers"]){
        PutIOAPITransfer *transfer = [[PutIOAPITransfer alloc] initWithRawData:transferData];
        [transfers addObject:transfer];
    }
    _transfers = transfers;
}

@end
