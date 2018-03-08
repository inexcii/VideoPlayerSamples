//
//  ViewController.m
//  VideoPlayerSamples
//
//  Created by Ralph Zhou on 2018/01/28.
//  Copyright © 2018 Genmis Inc. All rights reserved.
//

#import "ViewController.h"
#import "PlayerView.h"
#import "PlayerManager.h"

@import AVFoundation;

static NSString *const kVideoUrlContent = @"https://aka-uae-dl.uliza.jp/ad-dev/20170628/video/201707/596448bf-dfa4-49b9-82e9-46190a920004-750.mp4";
static NSString *const kVideoUrlAd = @"https://aka-uae-dl.uliza.jp/ad-dev/861/video/201709/59ccbde4-82c8-44b9-a621-45950a920004-750.mp4";
static NSString *const kVideoUrlInvalid = @"http://ad-dev.uliza.jp/work/kuchida/movie/30sec_Paris.mp4";

@interface ViewController () <PlayerManagerDelegate>

@property (weak, nonatomic) IBOutlet UIView *adView;
@property (weak, nonatomic) IBOutlet PlayerView *adPlayerView;

@property (weak, nonatomic) IBOutlet PlayerView *contentPlayerView;
@property (weak, nonatomic) IBOutlet UILabel *contentTimeLabel;

@property (nonatomic) PlayerManager *contentPlayerManager;
@property (nonatomic) PlayerManager *adPlayerManager;

@end

@implementation ViewController

#pragma mark - Override

- (void)dealloc
{
    NSLog(@"dealloc ViewController");
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self.adView setHidden:!self.isAdDisplayed];
}

#pragma mark - Delegate

#pragma mark PlayerManagerDelegate

- (void)manager:(PlayerManager *)manager didReceivePlayerEvent:(PlayerEvent)event
{
    switch (event) {
        case PlayerDidStartToPlay:
        {
            NSLog(@"event received: PlayerDidStartToPlay");
            
            if ([manager isEqual:self.contentPlayerManager]) {
                [self updateTimeLabel:self.contentTimeLabel currentTime:0.0f duration:self.contentPlayerManager.duration];
            }
        }
            break;
        case PlayerLayerIsReadyForDisplay:
        {
            NSLog(@"event received: PlayerLayerIsReadyForDisplay");
        }
            break;
        case PlaybackTimeUpdated:
        {
            [self updateTimeLabel:self.contentTimeLabel currentTime:self.contentPlayerManager.currentTime duration:self.contentPlayerManager.duration];
        }
            break;
    }
}

#pragma mark - Private
#pragma mark IBActions

- (IBAction)contentLoadButtonTapped:(id)sender
{
    NSLog(@"content load button tapped");
    
    if (self.contentPlayerManager) {
        self.contentPlayerManager = nil;
    }
    
    NSString *urlString = kVideoUrlContent;
//    NSString *urlString = kVideoUrlInvalid;
    
    AVPlayerLayer *layer = (AVPlayerLayer *)self.contentPlayerView.layer;
    self.contentPlayerManager = [[PlayerManager alloc] initWithPlayerLayer:layer];
    self.contentPlayerManager.delegate = self;
    [self.contentPlayerManager setup:urlString];
}

- (IBAction)adLoadButtonTapped:(id)sender
{
    NSLog(@"ad load button tapped");
    
    if (self.adPlayerManager) {
        self.adPlayerManager = nil;
    }
    
    NSString *urlString = kVideoUrlAd;
//    NSString *urlString = kVideoUrlInvalid;
    
    AVPlayerLayer *layer = (AVPlayerLayer *)self.adPlayerView.layer;
    self.adPlayerManager = [[PlayerManager alloc] initWithPlayerLayer:layer];
    self.adPlayerManager.delegate = self;
    // comment-out to set a 5.0 sec timer for loading media instead of the default value.
//    self.adPlayerManager.mediaLoadTimeout = 5.0;
    [self.adPlayerManager setup:urlString];
}

- (IBAction)contentPlayButtonTapped:(id)sender
{
    [self.contentPlayerManager play];
}

- (IBAction)contentPauseButtonTapped:(id)sender
{
    [self.contentPlayerManager pause];
}

- (IBAction)adPlayButtonTapped:(id)sender
{
    [self.adPlayerManager play];
}

- (IBAction)adPauseButtonTapped:(id)sender
{
    [self.adPlayerManager pause];
}

#pragma mark Others

- (void)updateTimeLabel:(UILabel *)label currentTime:(Float64)currentTime duration:(Float64)duration
{
    label.text = [NSString stringWithFormat:@"%.2lf/%.2lf", currentTime, duration];
}

@end
