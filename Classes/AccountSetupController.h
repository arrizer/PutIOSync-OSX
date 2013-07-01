
#import <Cocoa/Cocoa.h>
#import <WebKit/WebKit.h>

#import "PutIOAPI.h"

@class AccountSetupController;
@protocol AccountSetupControllerDelegate <NSObject>
-(void)accountSetupController:(AccountSetupController*)c didFinishSetupWithOAuthAccessToken:(NSString*)token;
-(void)accountSetupControllerDidCancelSetup:(AccountSetupController*)c;
@end

@interface AccountSetupController : NSWindowController
<NSWindowDelegate, PutIOAPIDelegate>
{
    IBOutlet WebView *webView;
    IBOutlet NSProgressIndicator *spinner;
    PutIOAPI *putio;
}

@property (unsafe_unretained) id<AccountSetupControllerDelegate> delegate;

-(void)beginAccountSetup;
-(IBAction)cancelButtonClicked:(id)sender;

@end
