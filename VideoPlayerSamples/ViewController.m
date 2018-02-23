//
//  ViewController.m
//  VideoPlayerSamples
//
//  Created by Ralph Zhou on 2018/01/28.
//  Copyright © 2018 Genmis Inc. All rights reserved.
//

#import "ViewController.h"
#import "PlayerView.h"

@import AVFoundation;

static NSString *const kVideoUrlContent = @"https://aka-uae-dl.uliza.jp/ad-dev/20170628/video/201707/596448bf-dfa4-49b9-82e9-46190a920004-750.mp4";
static NSString *const kVideoUrlAd = @"https://aka-uae-dl.uliza.jp/ad-dev/861/video/201709/59ccbde4-82c8-44b9-a621-45950a920004-750.mp4";
static NSString *const kVideoUrlInvalid = @"http://ad-dev.uliza.jp/work/kuchida/movie/30sec_Paris.mp4";

static void * ContentContext = &ContentContext;
static void * AdContext = &AdContext;

@interface ViewController ()

@property (weak, nonatomic) IBOutlet PlayerView *contentPlayerView;
@property (weak, nonatomic) IBOutlet PlayerView *adPlayerView;
@property (nonatomic) AVPlayer *contentPlayer;
@property (nonatomic) AVPlayer *adPlayer;

@property (nonatomic) NSTimer *timer;

@end

@implementation ViewController

#pragma mark - Override

- (void)dealloc
{
    NSLog(@"dealloc");
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    
}

#pragma - KVO

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context
{
    if (context == ContentContext) {
        if ([keyPath isEqualToString:NSStringFromSelector(@selector(status))]) {
            NSLog(@"content playerItem's status KVO gets called");
            AVPlayerItem *playerItem = (AVPlayerItem *)object;
            switch (playerItem.status) {
                case AVPlayerItemStatusReadyToPlay:
                {
                    NSLog(@"playerItem's duration: %lf", CMTimeGetSeconds(playerItem.duration));
                    [playerItem removeObserver:self forKeyPath:NSStringFromSelector(@selector(status)) context:context];
                    
                    [self.contentPlayer play];
                    NSLog(@"content begins to play");
                }
                    break;
                case AVPlayerItemStatusFailed:
                case AVPlayerItemStatusUnknown:
                {
                    NSLog(@"player failed to play");
                }
                    break;
            }
        }
    } else if (context == AdContext) {
        if ([keyPath isEqualToString:NSStringFromSelector(@selector(status))]) {
            NSLog(@"ad playerItem's status KVO gets called");
            AVPlayerItem *playerItem = (AVPlayerItem *)object;
            switch (playerItem.status) {
                case AVPlayerItemStatusReadyToPlay:
                {
                    [playerItem removeObserver:self forKeyPath:NSStringFromSelector(@selector(status)) context:context];
                    [self.adPlayer play];
                    NSLog(@"ad begins to play");
                }
                    break;
                case AVPlayerItemStatusFailed:
                case AVPlayerItemStatusUnknown:
                {
                    NSLog(@"ad failed to play");
                }
                    break;
            }
        }
    }
    
}

#pragma mark - Private
#pragma mark IBActions

- (IBAction)contentLoadButtonTapped:(id)sender
{
    NSLog(@"content load button tapped");
    
    NSURL *videoUrl = [NSURL URLWithString:kVideoUrlContent];
//    NSURL *videoUrl = [NSURL URLWithString:kVideoUrlInvalid];
    
    AVURLAsset *asset = [[AVURLAsset alloc] initWithURL:videoUrl options:nil];
    NSLog(@"asset created");
    
    self.timer = [NSTimer scheduledTimerWithTimeInterval:2 target:self selector:@selector(handleAssetTimeout:) userInfo:asset repeats:NO];
    
    // retrieve asset's duration, video track and its size asynchronously
    NSArray *keys = @[@"playable", @"duration", @"tracks"];
    [asset loadValuesAsynchronouslyForKeys:keys completionHandler:^{
        
        NSError *error = nil;
        
        AVKeyValueStatus trackStatusPlayable = [asset statusOfValueForKey:@"playable" error:&error];
        switch (trackStatusPlayable) {
            case AVKeyValueStatusLoaded:
            {
                NSLog(@"asset is playable: %ld", (long)asset.isPlayable);
                
                if (asset.isPlayable) {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        AVPlayerItem *playerItem = [AVPlayerItem playerItemWithAsset:asset];
                        NSLog(@"player item created");
                        NSLog(@"playerItem's duration: %lf", CMTimeGetSeconds(playerItem.duration));
                        
                        self.contentPlayer = [AVPlayer playerWithPlayerItem:playerItem];
                        NSLog(@"player created");
                        
                        AVPlayerLayer *layer = (AVPlayerLayer *)self.contentPlayerView.layer;
                        [layer setPlayer:self.contentPlayer];
                        NSLog(@"player set to video view's layer");
                        
                        [playerItem addObserver:self forKeyPath:NSStringFromSelector(@selector(status)) options:NSKeyValueObservingOptionNew context:ContentContext];
                        NSLog(@"observer is added on playerItem's status property");
                    });
                }
            }
                break;
            default:
            {
                NSLog(@"content's playable cannot be retrieved due to the AVKeyValueStatus of %ld, error:%@", (long)trackStatusPlayable, error);
            }
                break;
        }
        
        AVKeyValueStatus trackStatusDuration = [asset statusOfValueForKey:@"duration" error:&error];
        switch (trackStatusDuration) {
            case AVKeyValueStatusLoaded:
            {
                NSLog(@"duration is %lf", CMTimeGetSeconds(asset.duration));
            }
                break;
            default:
            {
                NSLog(@"duration cannot be retrieved due to the AVKeyValueStatus of %ld", (long)trackStatusDuration);
            }
                break;
        }
        
        AVKeyValueStatus trackStatusTracks = [asset statusOfValueForKey:@"tracks" error:&error];
        switch (trackStatusTracks) {
            case AVKeyValueStatusLoaded:
            {
                AVAssetTrack *track = (AVAssetTrack *)[asset tracksWithMediaType:AVMediaTypeVideo][0];
                NSLog(@"tracks are: %@", NSStringFromCGSize(track.naturalSize));
            }
                break;
                
            default:
                NSLog(@"tracks cannot be retrieved due to the AVKeyValueStatus of %ld", (long)trackStatusTracks);
                break;
        }
        
        [self invalidateTimer];
    }];
}

- (IBAction)adLoadButtonTapped:(id)sender
{
    NSLog(@"ad load button tapped");
    
    NSURL *url = [NSURL URLWithString:kVideoUrlAd];
//    NSURL *url = [NSURL URLWithString:kVideoUrlInvalid];
    AVURLAsset *asset = [[AVURLAsset alloc] initWithURL:url options:nil];
    
    NSArray *keys = @[@"playable"];
    [asset loadValuesAsynchronouslyForKeys:keys completionHandler:^{
        NSError *error = nil;
        
        AVKeyValueStatus trackStatusPlayable = [asset statusOfValueForKey:@"playable" error:&error];
        switch (trackStatusPlayable) {
            case AVKeyValueStatusLoaded:
            {
                if (asset.isPlayable) {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        AVPlayerItem *item = [AVPlayerItem playerItemWithAsset:asset];
                        NSLog(@"ad player item created");
                        self.adPlayer = [AVPlayer playerWithPlayerItem:item];
                        AVPlayerLayer *layer = (AVPlayerLayer *)self.adPlayerView.layer;
                        [layer setPlayer:self.adPlayer];
                        NSLog(@"ad player created and set to player layer");
                        
                        [item addObserver:self forKeyPath:NSStringFromSelector(@selector(status)) options:NSKeyValueObservingOptionNew context:AdContext];
                    });
                }
            }
                break;
                
            default:
            {
                NSLog(@"ad's playable cannot be retrieved due to the AVKeyValueStatus of %ld, error:%@", (long)trackStatusPlayable, error);
            }
                break;
        }
    }];
}

- (IBAction)contentPlayButtonTapped:(id)sender
{
    if (self.contentPlayer) {
        [self.contentPlayer play];
    }
}

- (IBAction)contentPauseButtonTapped:(id)sender
{
    if (self.contentPlayer) {
        [self.contentPlayer pause];
    }
}

- (IBAction)adPlayButtonTapped:(id)sender
{
    if (self.adPlayer) {
        [self.adPlayer play];
    }
}

- (IBAction)adPauseButtonTapped:(id)sender
{
    if (self.adPlayer) {
        [self.adPlayer pause];
    }
}

#pragma mark Others

- (void)handleAssetTimeout:(NSTimer *)timer
{
    NSLog(@"timer is fired!!!");
    
    AVAsset *asset = (AVAsset *)timer.userInfo;
    [asset cancelLoading];
}

- (void)invalidateTimer
{
    if (self.timer) {
        if (self.timer.isValid) {
            NSLog(@"invalidate timer before it fires");
            [self.timer invalidate];
        }
        NSLog(@"nil the timer");
        self.timer = nil;
    }
}

@end
