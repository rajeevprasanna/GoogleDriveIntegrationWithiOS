//
//  ViewController.h
//  GoogleDriveIntegration
//
//  Created by Rajeev Kumar on 02/04/14.
//  Copyright (c) 2014 rajeev. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ViewController : UIViewController
@property (weak, nonatomic) IBOutlet UILabel *fileName;
- (IBAction)connectDrive:(id)sender;

@end
