
@import Cocoa;
@import WebKit;

#import "PutIOAPI.h"

@class AccountSetupController;
@protocol AccountSetupControllerDelegate <NSObject>
-(void)accountSetupController:(AccountSetupController*)c didFinishSetupWithOAuthAccessToken:(NSString*)token;
-(void)accountSetupControllerDidCancelSetup:(AccountSetupController*)c;
@end

@interface AccountSetupController : NSWindowController <NSWindowDelegate, WebFrameLoadDelegate, WebPolicyDelegate>
{
    IBOutlet WebView *webView;
    IBOutlet NSProgressIndicator *spinner;
    BOOL loggingOut;
    PutIOAPI *putio;
}

@property (unsafe_unretained) id<AccountSetupControllerDelegate> delegate;

-(void)beginAccountSetup;
-(IBAction)cancelButtonClicked:(id)sender;

@end
