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

@interface ViewController () <PlayerManagerDelegate>

@property (weak, nonatomic) IBOutlet UIView *adView;
@property (weak, nonatomic) IBOutlet PlayerView *adPlayerView;

@property (weak, nonatomic) IBOutlet PlayerView *contentPlayerView;
@property (weak, nonatomic) IBOutlet UILabel *contentTimeLabel;
@property (weak, nonatomic) IBOutlet UISlider *contentSeekSlider;

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

- (void)manager:(PlayerManager *)manager didReceivePlayerEvent:(PlayerEvent)event userInfo:(nullable NSDictionary *)userInfo
{
    switch (event) {
        case FailToLoadAsset:
        {
            NSLog(@"event received: FailToLoadAsset with info: %@", userInfo);
            [self presentAssetLoadAlertWithLoadingKey:userInfo[@"keyToLoad"]];
        }
            break;
        case PlayerDidStartToPlay:
        {
            NSLog(@"event received: PlayerDidStartToPlay");
            
            if ([manager isEqual:self.contentPlayerManager]) {
                [self updateTime];
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
            [self updateTime];
            [self.contentSeekSlider setValue:(self.contentPlayerManager.currentTime / self.contentPlayerManager.duration)
                                    animated:YES];
        }
            break;
        case PlayBufferUpdated:
        {
            NSLog(@"event received: PlayBufferUpdated with info: %lf", self.contentPlayerManager.bufferedTime);
        }
            break;
        case PlayToEnd:
        {
            NSLog(@"event received: PlayToEnd");
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
    
    AVPlayerLayer *layer = (AVPlayerLayer *)self.contentPlayerView.layer;
    self.contentPlayerManager = [[PlayerManager alloc] initWithPlayerLayer:layer];
    self.contentPlayerManager.delegate = self;
    [self.contentPlayerManager setup:self.videoUrlContent];
}

- (IBAction)adLoadButtonTapped:(id)sender
{
    NSLog(@"ad load button tapped");
    
    if (self.adPlayerManager) {
        self.adPlayerManager = nil;
    }
    
    AVPlayerLayer *layer = (AVPlayerLayer *)self.adPlayerView.layer;
    self.adPlayerManager = [[PlayerManager alloc] initWithPlayerLayer:layer];
    self.adPlayerManager.delegate = self;
    // comment-out to set a 5.0 sec timer for loading media instead of the default value.
//    self.adPlayerManager.mediaLoadTimeout = 5.0;
    [self.adPlayerManager setup:self.videoUrlAd];
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

- (IBAction)contentSeekSliderTouchedDown:(id)sender
{
    [self.contentPlayerManager pause];
}

- (IBAction)contentSeekSliderValueChanged:(id)sender
{
    UISlider *seekSlider = (UISlider *)sender;
    
    [self updateTimeByCurrentTime:self.contentPlayerManager.duration * seekSlider.value
                     bufferedTime:self.contentPlayerManager.bufferedTime
                         duration:self.contentPlayerManager.duration];
}

- (IBAction)contentSeekSliderTouchedUp:(id)sender
{
    UISlider *seekSlider = (UISlider *)sender;
    [self.contentPlayerManager seekTo:seekSlider.value];
}

#pragma mark Others

- (void)updateTime
{
    [self updateTimeByCurrentTime:self.contentPlayerManager.currentTime
                     bufferedTime:self.contentPlayerManager.bufferedTime
                         duration:self.contentPlayerManager.duration];
}

- (void)updateTimeByCurrentTime:(Float64)currentTime bufferedTime:(Float64)bufferedTime duration:(Float64)duration
{
    self.contentTimeLabel.text = [NSString stringWithFormat:@"%.2lf/%.2lf/%.2lf", currentTime, bufferedTime, duration];
}

- (void)presentAssetLoadAlertWithLoadingKey:(NSString *)key
{
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Failed to Load Asset"
                                                                   message:[NSString stringWithFormat:@"Asset '%@' cannot be loaded", key]
                                                            preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *cancel = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleCancel handler:nil];
    [alert addAction:cancel];
    [self presentViewController:alert animated:YES completion:nil];
}

@end
