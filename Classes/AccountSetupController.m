
#import "AccountSetupController.h"
#import "PutIOAPIOAuthTokenRequest.h"

#define kAPISecret @"a4gz4pnrnxm2jxchok8v"

@implementation AccountSetupController

-(instancetype)init
{
    self = [super initWithWindowNibName:NSStringFromClass([self class])];
    if(self){
        
    }
    return self;
}

-(void)cancelButtonClicked:(id)sender
{
    [webView stopLoading:self];
    [putio cancelAllRequests];
    [_delegate accountSetupControllerDidCancelSetup:self];
}

-(void)windowDidLoad
{
    putio = [PutIOAPI api];
    //[putio setDelegate:self];
    webView.frameLoadDelegate = self;
    webView.policyDelegate = self;
    [webView setHidden:YES];
    [spinner startAnimation:self];
}

-(void)windowWillClose:(NSNotification *)notification
{
    [webView setHidden:YES];
}

-(void)beginAccountSetup
{
    loggingOut = YES;
    webView.mainFrameURL = (putio.oAuthLogoutURL).absoluteString;
    
}

-(void)beginAuthentication
{
    webView.mainFrameURL = (putio.oAuthAuthenticationURL).absoluteString;
}

-                 (void)webView:(WebView *)webView
decidePolicyForNavigationAction:(NSDictionary *)actionInformation
                        request:(NSURLRequest *)request
                          frame:(WebFrame *)frame
               decisionListener:(id<WebPolicyDecisionListener>)listener
{
    NSString *URL = request.URL.absoluteString;
    NSString *callbackURL = putio.oAuthRedirectURI;
    if([URL hasPrefix:callbackURL]){
        callbackURL = [callbackURL stringByAppendingString:@"?code="];
        NSString *code = [URL stringByReplacingOccurrencesOfString:callbackURL withString:@""];
        __block PutIOAPIOAuthTokenRequest *request = [PutIOAPIOAuthTokenRequest requestOAuthTokenForCode:code api:putio secret:kAPISecret completion:^{
            if(request.error == nil && !request.isCancelled){
                NSDictionary *rawData = (NSDictionary*)request.responseObject;
                NSString *accessToken = rawData[@"access_token"];
                [_delegate accountSetupController:self didFinishSetupWithOAuthAccessToken:accessToken];
            }else if (request.error != nil){
                [self.window presentError:request.error
                           modalForWindow:self.window
                                 delegate:self
                       didPresentSelector:@selector(errorDismissed) contextInfo:nil];
            }
        }];
        [putio performRequest:request];
        [listener ignore];
    }else{
        [listener use];
    }
}

-(void)webView:(WebView *)sender didStartProvisionalLoadForFrame:(WebFrame *)frame
{
    [webView setHidden:YES];
    [spinner startAnimation:self];
}

-(void)webView:(WebView *)sender didFinishLoadForFrame:(WebFrame *)frame
{
    [webView setHidden:NO];
    [spinner stopAnimation:self];
    if(loggingOut){
        loggingOut = NO;
        [self beginAuthentication];
    }
}

- (void)errorDismissed
{
    [self cancelButtonClicked:self];
}

@end
