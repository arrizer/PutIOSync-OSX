
#import "PutIOAPITransfer.h"

@implementation PutIOAPITransfer

-(id)initWithRawData:(id)data
{
    self = [super initWithRawData:data];
    if (self) {
        self.transferID = [data[@"id"] integerValue];
        if(data[@"file_id"] != [NSNull null]){
            self.fileID = [data[@"file_id"] integerValue];
        }else{
            self.fileID = -1;
        }
        if(data[@"save_parent_id"] != [NSNull null]){
            self.destinationFolderID = [data[@"save_parent_id"] integerValue];
        }else{
            self.destinationFolderID = -1;
        }
        if(data[@"subscription_id"] != [NSNull null]){
            self.originatingSubscriptionID = [data[@"subscription_id"] integerValue];
        }else{
            self.originatingSubscriptionID = -1;
        }
        self.status = PutIOAPITransferStatusUnknown;
        if([data[@"status"] isEqualToString:@"IN_QUEUE"])
            self.status = PutIOAPITransferStatusInQueue;
        else if([data[@"status"] isEqualToString:@"DOWNLOADING"])
            self.status = PutIOAPITransferStatusDownloading;
        else if([data[@"status"] isEqualToString:@"SEEDING"])
            self.status = PutIOAPITransferStatusSeeding;
        else if([data[@"status"] isEqualToString:@"COMPLETED"])
            self.status = PutIOAPITransferStatusCompleted;
        else if([data[@"status"] isEqualToString:@"ERROR"])
            self.status = PutIOAPITransferStatusFailed;

        self.filename = data[@"name"];
        self.progress = (float)[data[@"percent_done"] integerValue];
        self.seedingToPeersCount = [data[@"peers_getting_from_us"] integerValue];
        self.leechingFromPeersCount = [data[@"peers_sending_to_us"] integerValue];
        if(data[@"size"] != [NSNull null]){
            self.size = [data[@"size"] integerValue];
        }else{
            self.size = 0;
        }
        self.sizeUploaded = [data[@"uploaded"] integerValue];
        self.uploadSpeed = [data[@"up_speed"] integerValue];
        self.sizeDownloaded = [data[@"downloaded"] integerValue];
        self.downloadSpeed = [data[@"down_speed"] integerValue];
        self.willExtractWhenFinished = [data[@"extract"] boolValue];
        self.isSeeding = [data[@"is_seeding"] boolValue];
        if(data[@"tracker_message"] != [NSNull null]){
            self.trackerMessage = data[@"tracker_message"];
        }else{
            self.trackerMessage = nil;
        }
        if(data[@"error_message"] != [NSNull null]){
            self.errorMessage = data[@"error_message"];
        }else{
            self.errorMessage = nil;
        }
        self.sourceURL = [NSURL URLWithString:data[@"source"]];
        self.startTime = [PutIOAPIObject dateFromRawDataString:data[@"created_at"]];
        if(data[@"estimated_time"] != [NSNull null]){
            self.estimatedTimeRemaining = [data[@"estimated_time"] doubleValue];
        }else{
            self.estimatedTimeRemaining = 0.0f;
        }
        self.torrentRatio = [data[@"current_ratio"] floatValue];
    }
    return self;
}

@end
