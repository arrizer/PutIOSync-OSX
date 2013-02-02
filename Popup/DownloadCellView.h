
#import <Cocoa/Cocoa.h>
#import "PutIODownload.h"

@interface DownloadCellView : NSTableCellView
<NSURLConnectionDataDelegate>
{
    IBOutlet NSProgressIndicator *progressBar;
    IBOutlet NSTextField *statusLabel;
    IBOutlet NSLayoutConstraint *statusLabelConstraint;
    IBOutlet NSLayoutConstraint *textLabelConstraint;
    IBOutlet NSButton *pauseResumeButton;
    PutIODownload *_download;
    NSURLConnection *iconLoader;
    NSMutableData *iconImageData;
}

@property (strong) PutIODownload *download;

- (IBAction)pauseOrResumeDownload:(id)sender;

@end
