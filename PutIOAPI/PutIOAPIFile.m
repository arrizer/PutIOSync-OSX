
#import "PutIOAPIFile.h"

@implementation PutIOAPIFile

-(id)initWithRawData:(id)data
{
    self = [super initWithRawData:data];
    if(self){
        self.fileID = [data[@"id"] integerValue];
        if(data[@"parent_id"] != [NSNull null]){
            self.parentFileID = [data[@"parent_id"] integerValue];
        }else{
            self.parentFileID = -1;
        }
        self.name = data[@"name"];
        self.dateCreated = [PutIOAPIObject dateFromRawDataString:data[@"created_at"]];
        self.contentType = data[@"content_type"];
        self.iconURL = [NSURL URLWithString:data[@"icon"]];
        if(data[@"screenshot"] != [NSNull null])
            self.screenshotURL = [NSURL URLWithString:data[@"screenshot"]];
    }
    return self;
}

-(BOOL)isFolder
{
    return [self.contentType isEqualToString:@"application/x-directory"];
}

-(BOOL)isRootFolder
{
    return (self.isFolder && self.parentFileID == -1);
}

@end
