
#import "GeneralPreferences.h"

@implementation GeneralPreferences

- (id)init
{
    return [super initWithNibName:@"GeneralPreferences" bundle:nil];
}

#pragma mark -
#pragma mark MASPreferencesViewController

- (NSString *)identifier
{
    return @"GeneralPreferences";
}

- (NSImage *)toolbarItemImage
{
    return [NSImage imageNamed:NSImageNamePreferencesGeneral];
}

- (NSString *)toolbarItemLabel
{
    return NSLocalizedString(@"General", @"General Preferences title");
}

@end
