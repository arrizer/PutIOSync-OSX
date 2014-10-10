
#import "Utilities.h"
#import "AccountPreferences.h"
#import "SyncScheduler.h"
#import "PutIOAPIKeychainManager.h"
#import "PutIOAPIAccountInfoRequest.h"
#import "PutIODownloadManager.h"
#import "Download.h"

@implementation AccountPreferences

- (id)init
{
    self = [super initWithNibName:@"AccountPreferences" bundle:nil];
    self.putio = [PutIOAPI api];
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
    [activityLabel setHidden:YES];
    [activitySpinner setHidden:YES];
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

#pragma mark - Account Setup Delegate

-(void)accountSetupController:(AccountSetupController *)c didFinishSetupWithOAuthAccessToken:(NSString *)token
{
    [[accountSetup window] close];
    [NSApp endSheet:[accountSetup window]];
    
    // Abort all running syncs and downloads
    [[SyncScheduler sharedSyncScheduler] cancelAllSyncsInProgress];
    for(Download* download in [[PutIODownloadManager manager] allDownloads]){
        [download cancelDownload];
    }
    
    // Nuke all sync instructions (since we change the put.io account)
    for(SyncInstruction *syncInstruction in [SyncInstruction allSyncInstructions]){
        [syncInstruction.managedObjectContext deleteObject:syncInstruction];
    }
    [PutIOAPIKeychainManager setKeychainItemPassword:token];
    [[PutIOAPI api] setOAuthAccessToken:token];
    
    // Reset username/email, we need to retrieve those from put.io
    NSUserDefaults *d = [NSUserDefaults standardUserDefaults];
    [d setObject:@"" forKey:@"account_email"];
    [d setObject:@"" forKey:@"account_username"];
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
    BOOL accountSetUp = [[PutIOAPI api] isAuthenticated];
    if(accountSetUp){
        [spaceLabel setHidden:YES];
        [activitySpinner startAnimation:self];
        [activityLabel setHidden:NO];
        [activitySpinner setHidden:NO];
        __block PutIOAPIAccountInfoRequest *request = [PutIOAPIAccountInfoRequest requestWithCompletion:^{
            if(request.error == nil && !request.isCancelled){
                PutIOAPIAccountInfo *accountInfo = request.accountInfo;
                NSUserDefaults *d = [NSUserDefaults standardUserDefaults];
                [d setObject:[accountInfo eMailAddress] forKey:@"account_email"];
                [d setObject:[accountInfo username] forKey:@"account_username"];
                [d setInteger:[accountInfo usedDiskSpace] forKey:@"account_space_used"];
                [d setInteger:[accountInfo totalDiskSpace] forKey:@"account_space_total"];

                [self updateAccountDetailLabels];
            }
            [activityLabel setHidden:YES];
            [activitySpinner setHidden:YES];
        }];
        [self.putio performRequest:request];
    }
}

- (void)updateAccountDetailLabels
{
    NSUserDefaults *d = [NSUserDefaults standardUserDefaults];
    BOOL accountSetUp = [[PutIOAPI api] isAuthenticated];

    
    if(accountSetUp){
        infoLabel.stringValue = NSLocalizedString(@"You are signed in as", nil);
        connectButton.stringValue = NSLocalizedString(@"Change account...", nil);
        
        NSString *accountEMailAddress = [d stringForKey:@"account_email"];
        NSString *accountUsername = [d stringForKey:@"account_username"];
        NSUInteger accountUsedSpace = [d integerForKey:@"account_space_used"];
        NSUInteger accountTotalSpace = [d integerForKey:@"account_space_total"];
        if(accountUsername){
            [accountUsernameLabel setHidden:NO];
            [accountUsernameLabel setStringValue:accountUsername];
        }
        if(accountEMailAddress){
            [accountEMailAddressLabel setHidden:NO];
            [accountEMailAddressLabel setStringValue:accountEMailAddress];
        }
        if(accountUsedSpace > 0 || accountTotalSpace > 0){
            NSString *accountUsedSpaceString = unitStringFromBytes(accountUsedSpace);
            NSString *accountTotalSpaceString = unitStringFromBytes(accountTotalSpace);
            [spaceLabel setStringValue:[NSString stringWithFormat:NSLocalizedString(@"Used space: %@ of %@", nil), accountUsedSpaceString, accountTotalSpaceString]];
            [spaceLabel setHidden:NO];
        }
    }else{
        infoLabel.stringValue = NSLocalizedString(@"You did not connect your put.io account yet", nil);
        connectButton.stringValue = NSLocalizedString(@"Sign in...", nil);
        [accountEMailAddressLabel setHidden:YES];
        [accountUsernameLabel setHidden:YES];
        [spaceLabel setHidden:YES];
    }
}

@end
