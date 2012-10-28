
#import "TransfersPanel.h"
#import "ApplicationDelegate.h"

@implementation TransfersPanel

-(void)preferencesButtonClicked:(id)sender
{
    [(ApplicationDelegate*)[NSApp delegate] showPreferences:self];
}

@end
