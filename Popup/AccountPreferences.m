
#import "AccountPreferences.h"

@implementation AccountPreferences

- (id)init
{
    self = [super initWithNibName:@"AccountPreferences" bundle:nil];
    self.putio = [PutIOAPI apiWithDelegate:self];
    return self;
}

#pragma mark - PreferencesViewController

- (NSString *)identifier
{
    return @"AdvancedPreferences";
}

- (NSImage *)toolbarItemImage
{
    return [NSImage imageNamed:NSImageNameUser];
}

- (NSString *)toolbarItemLabel
{
    return NSLocalizedString(@"Account", @"Account Preferences Title");
}

-(void)viewWillAppear
{
    [self updateAccountDetailLabels];
    [self fetchAccountDetails];
}

#pragma mark - Actions

-(void)connectAccountButtonClicked:(id)sender
{
    if(!accountSetup)
        accountSetup = [[AccountSetupController alloc] init];
    [accountSetup setDelegate:self];
    [NSApp beginSheet:[accountSetup window]
       modalForWindow:[self.view window]
        modalDelegate:nil 
       didEndSelector:nil
          contextInfo:nil];
    [accountSetup beginAccountSetup];
}

#pragma mark - PutIO API Delegate

-(void)api:(PutIOAPI *)api
didFinishRequest:(PutIOAPIRequest)request
withResult:(id)result
{
    PutIOAPIAccountInfo *accountInfo = (PutIOAPIAccountInfo*)result;
    
    NSUserDefaults *d = [NSUserDefaults standardUserDefaults];
    [d setObject:[accountInfo eMailAddress] forKey:@"account_email"];
    [d setObject:[accountInfo username] forKey:@"account_username"];
    [d setInteger:[accountInfo usedDiskSpace] forKey:@"account_space_used"];
    [d setInteger:[accountInfo totalDiskSpace] forKey:@"account_space_total"];
    
    [activityLabel setHidden:YES];
    [activitySpinner setHidden:YES];
    [self updateAccountDetailLabels];
}


#pragma mark - Account Setup Delegate

-(void)accountSetupController:(AccountSetupController *)c didFinishSetupWithOAuthAccessToken:(NSString *)token
{
    [[accountSetup window] close];
    [NSApp endSheet:[accountSetup window]];
    NSUserDefaults *d = [NSUserDefaults standardUserDefaults];
    [d setBool:YES forKey:@"account_setup"];
    [PutIOAPI setOAuthAccessToken:token];
    // TODO: Store the access token in the keychain here
    [self viewWillAppear];
}

-(void)accountSetupControllerDidCancelSetup:(AccountSetupController *)c
{
    [[accountSetup window] close];
    [NSApp endSheet:[accountSetup window]];    
}

#pragma mark - Account Details

- (void)fetchAccountDetails
{
    NSUserDefaults *d = [NSUserDefaults standardUserDefaults];
    BOOL accountSetUp = [d boolForKey:@"account_setup"];
    if(accountSetUp){
        [spaceLabel setHidden:YES];
        [activitySpinner startAnimation:self];
        [activityLabel setHidden:NO];
        [activitySpinner setHidden:NO];
        [self.putio accountInfo];
    }
}

- (void)updateAccountDetailLabels
{
    NSUserDefaults *d = [NSUserDefaults standardUserDefaults];
    BOOL accountSetUp = [d boolForKey:@"account_setup"];
    NSString *accountEMailAddress = [d stringForKey:@"account_email"];
    NSString *accountUsername = [d stringForKey:@"account_username"];
    NSInteger accountUsedSpace = [d integerForKey:@"account_space_used"];
    NSInteger accountTotalSpace = [d integerForKey:@"account_space_total"];
    
    [signedInView setHidden:!accountSetUp];
    [signedOutView setHidden:accountSetUp];
    
    [accountEMailAddressLabel setHidden:(!accountEMailAddress)];
    [accountUsernameLabel setHidden:(!accountUsername)];
    [spaceLabel setHidden:(accountUsedSpace == 0 || accountTotalSpace == 0)];
    if(accountUsername)
        [accountUsernameLabel setStringValue:accountUsername];
    if(accountEMailAddress)
        [accountEMailAddressLabel setStringValue:accountEMailAddress];
    if(accountUsedSpace > 0 && accountTotalSpace > 0)
        [spaceLabel setStringValue:[NSString stringWithFormat:NSLocalizedString(@"Used space: %i of %i", @"Account used and total space"), accountUsedSpace, accountTotalSpace]];
}

@end
