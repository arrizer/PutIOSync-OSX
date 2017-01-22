
#import "TransferCellView.h"
#import "BytesFormatter.h"
#import "TimeIntervalFormatter.h"

static BytesFormatter *bytesFormatter;
static TimeIntervalFormatter *timeIntervalFormatter;

@implementation TransferCellView

-(void)setObjectValue:(id)objectValue
{
    if(bytesFormatter == nil){
        bytesFormatter = [[BytesFormatter alloc] init];
    }
    if(timeIntervalFormatter == nil){
        timeIntervalFormatter = [[TimeIntervalFormatter alloc] init];
    }
    
    super.objectValue = objectValue;
    PutIOAPITransfer *transfer = (PutIOAPITransfer*)objectValue;
    
    icon.image = [NSImage imageNamed:@"transfer"];

    NSString *status = [NSMutableString string];
    switch (transfer.status) {
        case PutIOAPITransferStatusInQueue:{
            status = NSLocalizedString(@"In queue", nil);
            break;
        }
        case PutIOAPITransferStatusDownloading:{
            status = [status stringByAppendingFormat:@"%@ of %@", [bytesFormatter stringFromBytes:transfer.sizeDownloaded], [bytesFormatter stringFromBytes:transfer.size]];
            status = [status stringByAppendingFormat:@" (%@/s)", [bytesFormatter stringFromBytes:transfer.downloadSpeed]];
            if(transfer.estimatedTimeRemaining > 0.0f)
                status = [status stringByAppendingFormat:@" - %@remaining", [timeIntervalFormatter stringFromTimeInterval:transfer.estimatedTimeRemaining]];
            break;
        }
        case PutIOAPITransferStatusCompleted:{
            status = NSLocalizedString(@"Finished", nil);
            status = [status stringByAppendingFormat:@" - %@", [bytesFormatter stringFromBytes:transfer.size]];
            icon.image = [NSImage imageNamed:@"transfer_finished"];
            break;
        }
        case PutIOAPITransferStatusSeeding:{
            status = [NSString stringWithFormat:NSLocalizedString(@"Finished, seeding to %i peers - ", nil), transfer.seedingToPeersCount];
            status = [status stringByAppendingFormat:@"%@", [bytesFormatter stringFromBytes:transfer.sizeUploaded]];
            status = [status stringByAppendingFormat:@" (%@/s)", [bytesFormatter stringFromBytes:transfer.uploadSpeed]];
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
    cancelButton.hidden = (transfer.status == PutIOAPITransferStatusCompleted || transfer.status == PutIOAPITransferStatusFailed);
    statusLabel.stringValue = status;
}

-(void)setBackgroundStyle:(NSBackgroundStyle)backgroundStyle
{
    super.backgroundStyle = backgroundStyle;
    if(backgroundStyle == NSBackgroundStyleDark){
        statusLabel.textColor = [NSColor alternateSelectedControlTextColor];
        cancelButton.image = [NSImage imageNamed:@"stopImageInverted.png"];
    }else if (backgroundStyle == NSBackgroundStyleLight){
        statusLabel.textColor = [NSColor controlShadowColor];
        cancelButton.image = [NSImage imageNamed:@"stopImage.png"];
    }
}

-(void)cancelTransfer:(id)sender
{
    
}

@end
