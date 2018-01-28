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

@interface ViewController ()

@property (weak, nonatomic) IBOutlet PlayerView *playerView;
@property (nonatomic) AVPlayer *player;

@end

@implementation ViewController

#pragma mark - Override

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

#pragma mark - IBActions

- (IBAction)loadButtonTapped:(id)sender
{
    NSLog(@"load button tapped");
    
    NSString *videoUrlString = @"https://aka-uae-dl.uliza.jp/ad-dev/20170628/video/201707/596448bf-dfa4-49b9-82e9-46190a920004-750.mp4";
    NSURL *videoUrl = [NSURL URLWithString:videoUrlString];
    
//    AVAsset *asset = [AVAsset assetWithURL:videoUrl];
    AVURLAsset *asset = [[AVURLAsset alloc] initWithURL:videoUrl options:nil];
    NSLog(@"asset created");
    
//    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
//        NSLog(@"asset's duration is :%lf", CMTimeGetSeconds(asset.duration));
//    });
    
//    AVPlayerItem *playerItem = [AVPlayerItem playerItemWithURL:videoUrl];
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
}

- (IBAction)playButtonTapped:(id)sender
{
    if (self.player) {
        [self.player play];
    }
}

@end
