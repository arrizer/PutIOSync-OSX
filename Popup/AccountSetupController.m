
#import "AccountSetupController.h"

@implementation AccountSetupController

-(id)init
{
    self = [super initWithWindowNibName:NSStringFromClass([self class])];
    if(self){
        
    }
    return self;
}

-(void)cancelButtonClicked:(id)sender
{
    [webView stopLoading:self];
    [putio cancel];
    [_delegate accountSetupControllerDidCancelSetup:self];
}

-(void)windowDidLoad
{
    putio = [PutIOAPI api];
    [putio setDelegate:self];
    [webView setFrameLoadDelegate:self];
    [webView setPolicyDelegate:self];
    [webView setHidden:YES];
    [spinner startAnimation:self];
}

-(void)windowWillClose:(NSNotification *)notification
{
    [webView setHidden:YES];
}

-(void)beginAccountSetup
{
    [webView setMainFrameURL:[[putio oauthAuthenticationURL] absoluteString]];
}

-                 (void)webView:(WebView *)webView
decidePolicyForNavigationAction:(NSDictionary *)actionInformation
                        request:(NSURLRequest *)request
                          frame:(WebFrame *)frame
               decisionListener:(id<WebPolicyDecisionListener>)listener
{
    NSString *URL = [[request URL] absoluteString];
    NSString *callbackURL = [[putio oauthAuthenticationCallbackURL] absoluteString];
    if([URL hasPrefix:callbackURL]){
        callbackURL = [callbackURL stringByAppendingString:@"?code="];
        NSString *code = [URL stringByReplacingOccurrencesOfString:callbackURL withString:@""];
        NSLog(@"Obtained OAuth auth code: %@", code);
        [putio obtainOAuthAccessTokenForCode:code];
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
}

-(void)api:(PutIOAPI *)api didFinishRequest:(PutIOAPIRequest)request withResult:(id)result
{
    NSDictionary *rawData = (NSDictionary*)[result rawData];
    NSString *accessToken = [rawData objectForKey:@"access_token"];
    NSLog(@"Obtained OAuth access token: %@", accessToken);
    [_delegate accountSetupController:self didFinishSetupWithOAuthAccessToken:accessToken];
}

@end
