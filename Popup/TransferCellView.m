
#import "TransferCellView.h"
#import "Utilities.h"

@implementation TransferCellView

-(void)setObjectValue:(id)objectValue
{
    [super setObjectValue:objectValue];
    PutIOAPITransfer *transfer = (PutIOAPITransfer*)objectValue;
    
    icon.image = [NSImage imageNamed:@"transfer"];

    NSString *status = [NSMutableString string];
    switch (transfer.status) {
        case PutIOAPITransferStatusInQueue:{
            status = NSLocalizedString(@"In queue", nil);
            break;
        }
        case PutIOAPITransferStatusDownloading:{
            status = [status stringByAppendingFormat:@"%@ of %@", unitStringFromBytes(transfer.sizeDownloaded), unitStringFromBytes(transfer.size)];
            status = [status stringByAppendingFormat:@" (%@/s)", unitStringFromBytes(transfer.downloadSpeed)];
            if(transfer.estimatedTimeRemaining > 0.0f)
                status = [status stringByAppendingFormat:@" - %@remaining", unitStringFromSeconds(transfer.estimatedTimeRemaining)];
            break;
        }
        case PutIOAPITransferStatusCompleted:{
            status = NSLocalizedString(@"Finished", nil);
            status = [status stringByAppendingFormat:@" - %@", unitStringFromBytes(transfer.size)];
            icon.image = [NSImage imageNamed:@"transfer_finished"];
            break;
        }
        case PutIOAPITransferStatusSeeding:{
            status = [NSString stringWithFormat:NSLocalizedString(@"Finished, seeding to %i peers - ", nil), transfer.seedingToPeersCount];
            status = [status stringByAppendingFormat:@"%@", unitStringFromBytes(transfer.sizeUploaded)];
            status = [status stringByAppendingFormat:@" (%@/s)", unitStringFromBytes(transfer.uploadSpeed)];
            status = [status stringByAppendingFormat:@" - Ratio: %.2f", transfer.torrentRatio];
            icon.image = [NSImage imageNamed:@"transfer_finished"];
            break;
        }
        case PutIOAPITransferStatusFailed:{
            status = [NSString stringWithFormat:NSLocalizedString(@"Error: %@", nil), transfer.errorMessage];
            icon.image = [NSImage imageNamed:@"transfer_failed"];
            break;
        }
        default:
            status = @"";
            break;
    }
    [cancelButton setHidden:(transfer.status == PutIOAPITransferStatusCompleted || transfer.status == PutIOAPITransferStatusFailed)];
    statusLabel.stringValue = status;
}

-(void)cancelTransfer:(id)sender
{
    
}

@end
