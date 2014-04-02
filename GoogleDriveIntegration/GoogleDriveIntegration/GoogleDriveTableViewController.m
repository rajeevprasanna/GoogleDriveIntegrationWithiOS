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
#import "ViewController.h"


static NSString *const scopes = @"https://www.googleapis.com/auth/drive.file";
static NSString *const keychainItemName = @"gDrive";
static NSString *const clientId = @"516271788433-npfpoi6el7noilv874ammjfupaaqljqc.apps.googleusercontent.com";
static NSString *const clientSecret = @"yCOifH7LyIHrZHPAWwkqQxl2";


@interface GoogleDriveTableViewController ()

@property (weak, readonly) GTLServiceDrive *driveService;
@property (retain) NSMutableArray *driveFolders;
@property (retain) NSMutableArray *driveFiles;
@property BOOL isAuthorized;

- (void)viewController:(GTMOAuth2ViewControllerTouch *)viewController finishedWithAuth:(GTMOAuth2Authentication *)auth error:(NSError *)error;
- (void)isAuthorizedWithAuthentication:(GTMOAuth2Authentication *)auth;
- (void)loadDriveFiles:(NSString *)parentId;

@end

@implementation GoogleDriveTableViewController

@synthesize driveFiles = _driveFiles;
@synthesize driveFolders = _driveFolders;
@synthesize isAuthorized = _isAuthorized;

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
    [self driveService];
    
    GTMOAuth2Authentication *auth =
    [GTMOAuth2ViewControllerTouch authForGoogleFromKeychainForName:keychainItemName clientID:clientId clientSecret:clientSecret];
    
     if ([auth canAuthorize]) {
        [self isAuthorizedWithAuthentication:auth];
     }else{
         [self authorizeUser];
     }
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    // Sort Drive Files by modified date (descending order).
    [self.driveFiles sortUsingComparator:^NSComparisonResult(GTLDriveFile *lhs,
                                                             GTLDriveFile *rhs) {
        return [rhs.modifiedDate.date compare:lhs.modifiedDate.date];
    }];
    [self.driveFolders sortUsingComparator:^NSComparisonResult(GTLDriveFile *lhs,
                                                             GTLDriveFile *rhs) {
        return [rhs.modifiedDate.date compare:lhs.modifiedDate.date];
    }];
    [self.tableView reloadData];
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
    [self loadDriveFiles:@"root"];
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    //section 0 refers to folder selection and section 1 refers to file selection
    if(indexPath.section == 0){
        //Display files inside that folder
        GTLDriveFile * folder = [self.driveFolders objectAtIndex:indexPath.row];
        [self loadDriveFiles:folder.identifier];
    }else{
        GTLDriveFile * file = [self.driveFiles objectAtIndex:indexPath.row];
        [self.navigationController popViewControllerAnimated: YES];

        ViewController* viewController = (ViewController*)self.navigationController.topViewController;
        viewController.fileName.text = file.title;
    }
}

- (void)loadDriveFiles:(NSString *)parentId {
    
    GTLQueryDrive *query = [GTLQueryDrive queryForFilesList];
    query.q = [NSString stringWithFormat:@"'%@' IN parents and trashed=false and hidden=false", parentId];
    
    UIAlertView *alert = [self showLoadingMessageWithTitle:@"Loading files" delegate:self];
    self.driveService.shouldFetchNextPages = YES;
    [self.driveService executeQuery:query completionHandler:^(GTLServiceTicket *ticket,
                                                              GTLDriveFileList *files,
                                                              NSError *error) {
        
        [alert dismissWithClickedButtonIndex:0 animated:YES];
        
        if (error == nil) {
            if (self.driveFiles == nil) {
                self.driveFiles = [[NSMutableArray alloc] init];
            }
            
            if(self.driveFolders == nil){
                self.driveFolders = [[NSMutableArray alloc] init];
            }
            
            [self.driveFiles removeAllObjects];
            [self.driveFolders removeAllObjects];
            for(GTLDriveFile* file in files){
                if([file.mimeType  isEqual: @"application/vnd.google-apps.folder"]){
                    [self.driveFolders addObject:file];
                }else{
                    [self.driveFiles addObject:file];
                }
             }
             [self.tableView reloadData];
        } else {
            NSLog(@"An error occurred: %@", error);
            [self showErrorMessageWithTitle:@"Unable to load files from Google Drive"
                                                message:[error description]
                                              delegate:self];
        }
    }];
}

- (GTLServiceDrive *)driveService {
    static GTLServiceDrive *service = nil;
    
    if (!service) {
        service = [[GTLServiceDrive alloc] init];
        
        // Have the service object set tickets to fetch consecutive pages
        // of the feed so we do not need to manually fetch them.
        service.shouldFetchNextPages = YES;
        
        // Have the service object set tickets to retry temporary error conditions
        // automatically.
        service.retryEnabled = YES;
    }
    return service;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if(section == 0){
        return self.driveFolders.count;
    }else{
        return self.driveFiles.count;
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"Cell"];
    
    if(indexPath.section == 0){//load folders
        GTLDriveFile *file = [self.driveFolders objectAtIndex:indexPath.row];
        cell.textLabel.text = file.title;
    }else if(indexPath.section == 1){ //load files
        GTLDriveFile *file = [self.driveFiles objectAtIndex:indexPath.row];
        cell.textLabel.text = file.title;
    }
    return cell;
}

-(UIAlertView *)showLoadingMessageWithTitle:(NSString *)title
delegate:(id)delegate {
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:title
                                                    message:@""
                                                   delegate:self
                                          cancelButtonTitle:nil
                                          otherButtonTitles:nil];
    UIActivityIndicatorView *progress=
    [[UIActivityIndicatorView alloc] initWithFrame:CGRectMake(125, 50, 30, 30)];
    progress.activityIndicatorViewStyle = UIActivityIndicatorViewStyleWhiteLarge;
    [alert addSubview:progress];
    [progress startAnimating];
    [alert show];
    return alert;
}

- (void)showErrorMessageWithTitle:(NSString *)title
                          message:(NSString*)message
                         delegate:(id)delegate {
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:title
                                                    message:message
                                                   delegate:self
                                          cancelButtonTitle:@"Dismiss"
                                          otherButtonTitles:nil];
    [alert show];
}
@end
