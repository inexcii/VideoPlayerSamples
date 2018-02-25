//
//  PlayerManager.m
//  VideoPlayerSamples
//
//  Created by Ralph Zhou on 2018/02/24.
//  Copyright © 2018 Genmis Inc. All rights reserved.
//

#import "PlayerManager.h"
@import AVFoundation;

@interface PlayerManager()

@property (nonatomic, readwrite) AVPlayer *player;
@property (nonatomic) NSTimer *mediaLoadTimer;

@end

@implementation PlayerManager

#pragma mark - Override

- (void)dealloc
{
    NSLog(@"dealloc PlayerManager");
}

- (instancetype)init
{
    self = [super init];
    
    if (self) {
        _mediaLoadTimeout = 2.0;
    }
    
    return self;
}

#pragma mark KVO

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context
{
    if ([keyPath isEqualToString:NSStringFromSelector(@selector(status))]) {
        NSLog(@"content playeritem's status kvo gets called");
        AVPlayerItem *playerItem = (AVPlayerItem *)object;
        switch (playerItem.status) {
            case AVPlayerItemStatusReadyToPlay:
            {
                NSLog(@"playerItem's duration: %lf", CMTimeGetSeconds(playerItem.duration));
                [playerItem removeObserver:self forKeyPath:NSStringFromSelector(@selector(status)) context:context];
                
                [self.player play];
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
}


#pragma mark - Public

- (void)setup:(NSString *)mediaUrl completion:(void (^)(AVPlayer *))completion
{
    AVAsset *asset = [[AVURLAsset alloc] initWithURL:[NSURL URLWithString:mediaUrl] options:nil];
    
    self.mediaLoadTimer = [NSTimer scheduledTimerWithTimeInterval:self.mediaLoadTimeout target:self selector:@selector(handleAssetTimeout:) userInfo:asset repeats:NO];
    
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
                        AVPlayerItem *item = [AVPlayerItem playerItemWithAsset:asset];
                        [item addObserver:self forKeyPath:NSStringFromSelector(@selector(status)) options:NSKeyValueObservingOptionNew context:nil];
                        NSLog(@"observer is added on playerItem's status property");
                        
                        self.player = [AVPlayer playerWithPlayerItem:item];
                        if (completion) {
                            completion(self.player);
                        }
                    });
                } else {
                    NSLog(@"asset is not playable");
                }
            }
                break;
            default:
            {
                NSLog(@"asset's playable cannot be retrieved due to the AVKeyValueStatus of %ld, error:%@", (long)trackStatusPlayable, error);
            }
                break;
        }
        [self invalidateMediaLoadTimer];
    }];
}

- (void)play
{
    [self.player play];
}

- (void)pause
{
    [self.player pause];
}

#pragma mark - Private

- (void)handleAssetTimeout:(NSTimer *)timer
{
    NSLog(@"timer is fired!!!");
    
    AVAsset *asset = (AVAsset *)timer.userInfo;
    [asset cancelLoading];
}

- (void)invalidateMediaLoadTimer
{
    if (self.mediaLoadTimer) {
        if (self.mediaLoadTimer.isValid) {
            NSLog(@"invalidate timer before it fires");
            [self.mediaLoadTimer invalidate];
        }
        NSLog(@"nil the timer");
        self.mediaLoadTimer = nil;
    }
}

@end
