//
//  ViewController.m
//  GoogleDriveIntegration
//
//  Created by Rajeev Kumar on 02/04/14.
//  Copyright (c) 2014 rajeev. All rights reserved.
//

#import "ViewController.h" 

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    NSLog(@"viewDidLoad is called in ViewController");
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)connectDrive:(id)sender {
    NSLog(@"clicked on connect drive button");
    [self performSegueWithIdentifier:@"drive" sender:self];
}

@end
