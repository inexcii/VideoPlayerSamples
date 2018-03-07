//
//  SettingsViewController.m
//  VideoPlayerSamples
//
//  Created by Ralph Zhou on 2018/03/07.
//  Copyright © 2018 Genmis Inc. All rights reserved.
//

#import "SettingsViewController.h"
#import "ViewController.h"

@interface SettingsViewController ()

@end

@implementation SettingsViewController

#pragma mark - Override

- (void)dealloc
{
    NSLog(@"dealloc SettingsViewController");
}

- (void)viewDidLoad
{
    [super viewDidLoad];
}

#pragma mark - Private

#pragma mark IBAction

- (IBAction)startButtonTapped:(id)sender
{
    UIStoryboard *sb = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    ViewController *vc = (ViewController *)[sb instantiateViewControllerWithIdentifier:@"ViewController"];
    
    [self.navigationController pushViewController:vc animated:YES];
}

@end
