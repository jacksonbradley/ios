//
// Copyright (C) Posten Norge AS
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//         http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//

#import "POSRootResource.h"
#import "POSFolder+Methods.h"
#import "POSDocumentsViewController.h"
#import "SHCLoginViewController.h"
#import "SHCOAuthViewController.h"
#import "POSModelManager.h"
#import "POSMailbox+Methods.h"
#import "POSFoldersViewController.h"
#import "POSOAuthManager.h"
#import "UIActionSheet+Blocks.h"
#import "SHCSplitViewController.h"
#import "digipost-Swift.h"

// Storyboard identifiers (to enable programmatic storyboard instantiation)
NSString *const kLoginNavigationControllerIdentifier = @"LoginNavigationController";
NSString *const kLoginViewControllerIdentifier = @"LoginViewController";

// Segue identifiers (to enable programmatic triggering of segues)
NSString *const kPresentLoginModallyIdentifier = @"PresentLoginModally";

// Notification names
NSString *const kShowLoginViewControllerNotificationName = @"ShowLoginViewControllerNotification";

// Google Analytics screen name
NSString *const kLoginViewControllerScreenName = @"Login";

@interface SHCLoginViewController () <SHCOAuthViewControllerDelegate>

@property (weak, nonatomic) IBOutlet UIButton *loginButton;
@property (weak, nonatomic) IBOutlet UIButton *registerButton;
@property (weak, nonatomic) IBOutlet UIButton *privacyButton;
@property (strong, nonatomic) UIImageView *titleImageView;

@end

@implementation SHCLoginViewController

#pragma mark - NSObject

- (void)dealloc
{
    @try {
        [[NSNotificationCenter defaultCenter] removeObserver:self
                                                        name:kShowLoginViewControllerNotificationName
                                                      object:nil];
    }
    @catch (NSException *exception)
    {
        DDLogWarn(@"Caught an exception: %@", exception);
    }
}

#pragma mark - UIViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self.navigationController setToolbarHidden:YES animated:NO];
    self.screenName = kLoginViewControllerScreenName;

    @try {
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(popToSelf:)
                                                     name:kShowLoginViewControllerNotificationName
                                                   object:nil];
    }
    @catch (NSException *exception)
    {
        DDLogWarn(@"Caught an exception: %@", exception);
    }

    [self.loginButton setTitle:NSLocalizedString(@"LOGIN_VIEW_CONTROLLER_LOGIN_BUTTON_TITLE", @"Sign In")
                      forState:UIControlStateNormal];
    [self.registerButton setTitle:NSLocalizedString(@"LOGIN_VIEW_CONTROLLER_REGISTER_BUTTON_TITLE", @"New user")
                         forState:UIControlStateNormal];
    [self.privacyButton setTitle:NSLocalizedString(@"LOGIN_VIEW_CONTROLLER_PRIVACY_BUTOTN_TITLE", @"Privacy")
                        forState:UIControlStateNormal];

    if ([OAuthToken oAuthTokenWithScope:kOauth2ScopeFull].refreshToken) {
        if ([UIDevice currentDevice].userInterfaceIdiom != UIUserInterfaceIdiomPad) {
            // @ TODO WILL BUG fIRST TIME
            POSRootResource *resource = [POSRootResource existingRootResourceInManagedObjectContext:[POSModelManager sharedManager].managedObjectContext];

            if ([resource.mailboxes.allObjects count] > 0) {
                [self performSegueWithIdentifier:@"goToDocumentsFromLoginSegue"
                                          sender:self];
            }
        }
    }

    if ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPad) {
        UIBarButtonItem *backBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@""
                                                                              style:UIBarButtonItemStyleBordered
                                                                             target:nil
                                                                             action:nil];
        self.navigationItem.backBarButtonItem = backBarButtonItem;
    }
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];

    UIImage *titleImage = [UIImage imageNamed:@"navbar-icon-posten"];
    self.titleImageView = [[UIImageView alloc] initWithImage:titleImage];
    self.titleImageView.frame = CGRectMake(0.0, 0.0, titleImage.size.width, titleImage.size.height);
    self.navigationItem.titleView = self.titleImageView;
    self.navigationItem.leftBarButtonItem = nil;
    self.navigationController.interactivePopGestureRecognizer.enabled = YES;
    self.navigationItem.rightBarButtonItem = nil;
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([segue.identifier isEqualToString:kPresentOAuthModallyIdentifier]) {
        SHCOAuthViewController *oAuthViewController;
        UINavigationController *navigationController = segue.destinationViewController;

        if ([navigationController isKindOfClass:[UINavigationController class]]) {
            oAuthViewController = (id)navigationController.topViewController;
        } else {
            oAuthViewController = (id)segue.destinationViewController;
        }
        oAuthViewController.delegate = self;
        oAuthViewController.scope = kOauth2ScopeFull;
    } else if ([segue.identifier isEqualToString:@"goToDocumentsFromLoginSegue"]) {
        POSMailbox *mailbox = [POSMailbox mailboxOwnerInManagedObjectContext:[POSModelManager sharedManager].managedObjectContext];
        POSDocumentsViewController *documentsViewController = (id)segue.destinationViewController;
        documentsViewController.folderName = kFolderInboxName;
        documentsViewController.mailboxDigipostAddress = mailbox.digipostAddress;
    }
}

- (void)willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration
{
    if ([UIDevice currentDevice].userInterfaceIdiom != UIUserInterfaceIdiomPad) {
        UIImage *titleImage;
        if (UIInterfaceOrientationIsPortrait(toInterfaceOrientation)) {
            titleImage = [UIImage imageNamed:@"navbar-icon-posten"];
        } else {
            titleImage = [UIImage imageNamed:@"navbar-icon-posten-iphone-landscape"];
        }
        self.titleImageView.image = titleImage;
        self.titleImageView.frame = CGRectMake(0.0, 0.0, titleImage.size.width, titleImage.size.height);
        self.navigationItem.titleView = self.titleImageView;
    }
}

#pragma mark - SHCOAuthViewControllerDelegate

- (void)OAuthViewControllerDidAuthenticate:(SHCOAuthViewController *)OAuthViewController
{
    if ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPad) {
        [self.navigationController dismissViewControllerAnimated:YES
                                                      completion:nil];
        [[NSNotificationCenter defaultCenter] postNotificationName:kRefreshDocumentsContentNotificationName
                                                            object:@NO];
    } else {
        POSRootResource *resource = [POSRootResource existingRootResourceInManagedObjectContext:[POSModelManager sharedManager].managedObjectContext];

        if ([resource.mailboxes.allObjects count] == 1) {
            [self performSegueWithIdentifier:kGoToInboxFolderAtStartupSegue
                                      sender:self];
        } else {
            [self performSegueWithIdentifier:@"accountSegue"
                                      sender:self];
        }
    }
}

#pragma mark - IBActions

- (IBAction)didTapSecondaryButton:(UIButton *)sender
{
    NSURL *url;
    if (sender == self.registerButton) {
        url = [NSURL URLWithString:@"https://www.digipost.no/app/registrering#/"];
    } else {
        url = [NSURL URLWithString:@"https://www.digipost.no/juridisk/#personvern"];
    }

    [UIActionSheet showFromRect:sender.frame
                         inView:[sender superview]
                       animated:YES
                      withTitle:[url host]
              cancelButtonTitle:NSLocalizedString(@"GENERIC_CANCEL_BUTTON_TITLE", @"Cancel")
         destructiveButtonTitle:nil
              otherButtonTitles:@[ NSLocalizedString(@"GENERIC_OPEN_IN_SAFARI_BUTTON_TITLE", @"Open in Safari") ]
                       tapBlock:^(UIActionSheet *actionSheet, NSInteger buttonIndex) {
                           if (buttonIndex == 0) {
                               [[UIApplication sharedApplication] openURL:url];
                           }
                       }];
}

- (IBAction)unwindToLoginViewController:(UIStoryboardSegue *)unwindSegue
{
}

#pragma mark - Private methods

- (void)popToSelf:(NSNotification *)notification
{
    if ([UIDevice currentDevice].userInterfaceIdiom != UIUserInterfaceIdiomPad) {
        [self.navigationController popToViewController:self
                                              animated:YES];
    } else {
    }
}

@end
