
#import "TransferCellView.h"
#import "Utilities.h"

@implementation TransferCellView

-(void)setObjectValue:(id)objectValue
{
    [super setObjectValue:objectValue];
    PutIOAPITransfer *transfer = (PutIOAPITransfer*)objectValue;

    NSString *status = [NSMutableString string];
    if(transfer.status == PutIOAPITransferStatusInQueue){
        status = NSLocalizedString(@"In queue", nil);
    }else if(transfer.status == PutIOAPITransferStatusDownloading){
        status = [status stringByAppendingFormat:@"%@ of %@", unitStringFromBytes(transfer.sizeDownloaded), unitStringFromBytes(transfer.size)];
        status = [status stringByAppendingFormat:@" (%@/s)", unitStringFromBytes(transfer.downloadSpeed)];
        if(transfer.estimatedTimeRemaining > 0.0f)
            status = [status stringByAppendingFormat:@" - %@remaining", unitStringFromSeconds(transfer.estimatedTimeRemaining)];
    }else if(transfer.status == PutIOAPITransferStatusSeeding){
        status = [NSString stringWithFormat:NSLocalizedString(@"Finished, seeding to %i peers - ", nil), transfer.seedingToPeersCount];
        status = [status stringByAppendingFormat:@"%@", unitStringFromBytes(transfer.sizeUploaded)];
        status = [status stringByAppendingFormat:@" (%@/s)", unitStringFromBytes(transfer.uploadSpeed)];
        status = [status stringByAppendingFormat:@" - Ratio: %.2f", transfer.torrentRatio];
    }else{
        status = @"";
    }
    statusLabel.stringValue = status;
}

-(void)cancelTransfer:(id)sender
{
    
}

@end
