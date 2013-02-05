
#import <Cocoa/Cocoa.h>
#import "PutIOAPITransfer.h"

@interface TransferCellView : NSTableCellView
{
    IBOutlet NSProgressIndicator *progressBar;
    IBOutlet NSTextField *statusLabel;
    IBOutlet NSButton *cancelButton;
    IBOutlet NSImageView *icon;
}

- (IBAction)cancelTransfer:(id)sender;

@end
