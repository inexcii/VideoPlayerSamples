//
//  SettingsViewController.m
//  VideoPlayerSamples
//
//  Created by Ralph Zhou on 2018/03/07.
//  Copyright © 2018 Genmis Inc. All rights reserved.
//

#import "SettingsViewController.h"
#import "ViewController.h"
#import "Util.h"

@interface SettingsViewController () <UIPickerViewDelegate, UIPickerViewDataSource>

@property (weak, nonatomic) IBOutlet UISwitch *adDisplaySwitch;
@property (weak, nonatomic) IBOutlet UIButton *contentVideoSelectButton;
@property (weak, nonatomic) IBOutlet UIButton *adVideoSelectButton;
@property (weak, nonatomic) IBOutlet UIPickerView *contentVideoPicker;
@property (weak, nonatomic) IBOutlet UIPickerView *adVideoPicker;
/** An array which contains content video urls */
@property (nonatomic) NSArray<NSString *> *contentVideoData;
@property (nonatomic) Util *util;
@property (nonatomic) NSString *videoUrlContent;
@property (nonatomic) NSString *videoUrlAd;

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
    
    self.util = [Util new];
}

#pragma mark - Delegate

#pragma mark UIPickerView

- (NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView
{
    return 1;
}

- (NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component
{
    return self.util.videoData.allKeys.count;
}

- (NSString *)pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component
{
    return self.util.videoData.allKeys[row];
}

- (void)pickerView:(UIPickerView *)pickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component
{
    NSString *key = self.util.videoData.allKeys[row];
    NSString *url = self.util.videoData[key];
    
    if ([pickerView isEqual:self.contentVideoPicker]) {
        self.videoUrlContent = url;
        [self.contentVideoSelectButton setTitle:key forState:UIControlStateNormal];
    } else if ([pickerView isEqual:self.adVideoPicker]) {
        self.videoUrlAd = url;
        [self.adVideoSelectButton setTitle:key forState:UIControlStateNormal];
        if (!self.adDisplaySwitch.isOn) {
            [self.adDisplaySwitch setOn:YES animated:YES];
        }
    }
    
    [UIView animateWithDuration:0.3f animations:^{
        pickerView.alpha = 0.0f;
    }];
}

#pragma mark - Private

#pragma mark IBAction

- (IBAction)startButtonTapped:(id)sender
{
    UIStoryboard *sb = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    ViewController *vc = (ViewController *)[sb instantiateViewControllerWithIdentifier:@"ViewController"];
    vc.isAdDisplayed = self.adDisplaySwitch.isOn;
    vc.videoUrlContent = self.videoUrlContent;
    vc.videoUrlAd = self.videoUrlAd;
    
    [self.navigationController pushViewController:vc animated:YES];
    
    if (self.contentVideoPicker.alpha > 0.0f) {
        self.contentVideoPicker.alpha = 0.0f;
    }
    if (self.adVideoPicker.alpha > 0.0f) {
        self.adVideoPicker.alpha = 0.0f;
    }
}

- (IBAction)contentVideoSelectButtonTapped:(id)sender
{
    UIButton *button = (UIButton *)sender;
    
    [UIView animateWithDuration:0.3f animations:^{
        if ([button isEqual:self.contentVideoSelectButton]) {
            self.contentVideoPicker.alpha = self.contentVideoPicker.alpha > 0.0f ? 0.0f: 1.0f;
            self.adVideoPicker.alpha = 0.0f;
        } else if ([button isEqual:self.adVideoSelectButton]) {
            self.adVideoPicker.alpha = self.adVideoPicker.alpha > 0.0f ? 0.0f: 1.0f;
            self.contentVideoPicker.alpha = 0.0f;
        }
    }];
}

@end
