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

static NSString *const kVideoUrl = @"https://aka-uae-dl.uliza.jp/ad-dev/20170628/video/201707/596448bf-dfa4-49b9-82e9-46190a920004-750.mp4";
static NSString *const kInvalidVideoUrl = @"http://ad-dev.uliza.jp/work/kuchida/movie/30sec_Paris.mp4";

@interface ViewController ()

@property (weak, nonatomic) IBOutlet PlayerView *playerView;
@property (nonatomic) AVPlayer *player;
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
    if ([keyPath isEqualToString:NSStringFromSelector(@selector(status))]) {
        
        NSLog(@"status KVO gets called");
        
        AVPlayerItem *playerItem = (AVPlayerItem *)object;
        switch (playerItem.status) {
            case AVPlayerItemStatusReadyToPlay:
            {
                NSLog(@"playerItem's duration: %lf", CMTimeGetSeconds(playerItem.duration));
                [playerItem removeObserver:self forKeyPath:NSStringFromSelector(@selector(status)) context:context];
                
                [self.player play];
                NSLog(@"play the video");
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
}

#pragma mark - Private
#pragma mark IBActions

- (IBAction)loadButtonTapped:(id)sender
{
    NSLog(@"load button tapped");
    
    NSURL *videoUrl = [NSURL URLWithString:kVideoUrl];
//    NSURL *videoUrl = [NSURL URLWithString:kInvalidVideoUrl];
    
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
                        
                        self.player = [AVPlayer playerWithPlayerItem:playerItem];
                        NSLog(@"player created");
                        
                        AVPlayerLayer *layer = (AVPlayerLayer *)self.playerView.layer;
                        [layer setPlayer:self.player];
                        NSLog(@"player set to video view's layer");
                        
                        [playerItem addObserver:self forKeyPath:NSStringFromSelector(@selector(status)) options:NSKeyValueObservingOptionNew context:nil];
                        NSLog(@"observer is added on playerItem's status property");
                    });
                }
            }
                break;
            default:
            {
                NSLog(@"playable cannot be retrieved due to the AVKeyValueStatus of %ld, error:%@", (long)trackStatusPlayable, error);
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

- (IBAction)playButtonTapped:(id)sender
{
    if (self.player) {
        [self.player play];
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
