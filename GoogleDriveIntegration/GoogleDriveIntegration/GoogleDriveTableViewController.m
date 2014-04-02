//
//  GoogleDriveTableViewController.m
//  GoogleDriveIntegration
//
//  Created by Rajeev Kumar on 02/04/14.
//  Copyright (c) 2014 rajeev. All rights reserved.
//

#import "GoogleDriveTableViewController.h"
#import "GTLDrive.h"
#import "GTMOAuth2ViewControllerTouch.h"


static NSString *const scopes = @"https://www.googleapis.com/auth/drive.file";
static NSString *const keychainItemName = @"gDrive";
static NSString *const clientId = @"516271788433-npfpoi6el7noilv874asmmjfupaaqljqc.apps.googleusercontent.com";
static NSString *const clientSecret = @"yCOifH7LyIHrZHPAWwksqQxl2";


@interface GoogleDriveTableViewController ()

@property (weak, readonly) GTLServiceDrive *driveService;
@property (retain) NSMutableArray *driveFiles;
@property BOOL isAuthorized;

- (void)viewController:(GTMOAuth2ViewControllerTouch *)viewController finishedWithAuth:(GTMOAuth2Authentication *)auth error:(NSError *)error;
- (void)isAuthorizedWithAuthentication:(GTMOAuth2Authentication *)auth;
- (void)loadDriveFiles;

@end

@implementation GoogleDriveTableViewController

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    GTMOAuth2Authentication *auth =
    [GTMOAuth2ViewControllerTouch authForGoogleFromKeychainForName:keychainItemName clientID:clientId clientSecret:clientSecret];
    
     if ([auth canAuthorize]) {
        [self isAuthorizedWithAuthentication:auth];
     }else{
         [self authorizeUser];
     }
}

- (void)authorizeUser {
    
    if (!self.isAuthorized) {
        // Sign in.
        SEL finishedSelector = @selector(viewController:finishedWithAuth:error:);
        // Applications that only need to access files created by this app should use kGTLAuthScopeDriveFile.
        
        GTMOAuth2ViewControllerTouch *authViewController =
        [[GTMOAuth2ViewControllerTouch alloc] initWithScope:kGTLAuthScopeDrive
                                                   clientID:clientId
                                               clientSecret:clientSecret
                                           keychainItemName:keychainItemName
                                                   delegate:self
                                           finishedSelector:finishedSelector];
        [self presentModalViewController:authViewController
                                animated:YES];
    }
}

- (void)viewController:(GTMOAuth2ViewControllerTouch *)viewController
      finishedWithAuth:(GTMOAuth2Authentication *)auth
                 error:(NSError *)error {
    [self dismissModalViewControllerAnimated:YES];
    if (error == nil) {
        [self isAuthorizedWithAuthentication:auth];
    }
}

- (void)isAuthorizedWithAuthentication:(GTMOAuth2Authentication *)auth {
    [[self driveService] setAuthorizer:auth];
    self.isAuthorized = YES;
    [self loadDriveFiles];
}

- (void)loadDriveFiles {
    NSLog(@"Going to load files from Google drive.....");
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
     return 3;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"Cell" forIndexPath:indexPath];
    
    // Configure the cell...
    UILabel *label = (UILabel *)[cell viewWithTag:100];
    label.text = [NSString stringWithFormat:@"%i", indexPath.row];
    return cell;
}

@end
