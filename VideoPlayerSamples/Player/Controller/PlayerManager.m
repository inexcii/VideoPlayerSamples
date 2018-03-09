//
//  PlayerManager.m
//  VideoPlayerSamples
//
//  Created by Ralph Zhou on 2018/02/24.
//  Copyright © 2018 Genmis Inc. All rights reserved.
//

#import "PlayerManager.h"
@import AVFoundation;
@import UIKit;

/** interval value(as seconds) for addPeriodicTimeObserverForInterval: which is added to AVPlayer for observing its playback progress */
static Float64 kIntervalForPlayerTimeObserver = 0.1f;

@interface PlayerManager()

@property (nonatomic) AVPlayer *player;
@property (nonatomic, nonnull) AVPlayerLayer *playerLayer;
@property (nonatomic) NSTimer *mediaLoadTimer;
@property (nonatomic, readwrite) Float64 duration;
/** current playback time of AVPlayer */
@property (nonatomic, readwrite) Float64 currentTime;
/** observer asset's playback time as it progresses */
@property (nonatomic) id playerObserver;

@end

@implementation PlayerManager

#pragma mark - Override

- (void)dealloc
{
    NSLog(@"dealloc PlayerManager");
    
    if (_player && _playerObserver) {
        [_player removeTimeObserver:_playerObserver];
        _playerObserver = nil;
    }
}

- (instancetype)initWithPlayerLayer:(AVPlayerLayer *)layer
{
    self = [super init];
    
    if (self) {
        _mediaLoadTimeout = 2.0;
        _playerLayer = layer;
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
                [playerItem removeObserver:self forKeyPath:NSStringFromSelector(@selector(status)) context:context];
                
                [self.player play];
                NSLog(@"video content is fired to play");
                
                [self.delegate manager:self didReceivePlayerEvent:PlayerDidStartToPlay];
                
                __weak PlayerManager *weakSelf = self;
                self.playerObserver = [self.player addPeriodicTimeObserverForInterval:CMTimeMakeWithSeconds(kIntervalForPlayerTimeObserver, NSEC_PER_SEC)
                                                                                queue:nil
                                                                           usingBlock:^(CMTime time) {
                                                                               weakSelf.currentTime = CMTimeGetSeconds(time);
//                                                                               NSLog(@"current time is updated: %lf", weakSelf.currentTime);
                                                                               [weakSelf.delegate manager:weakSelf didReceivePlayerEvent:PlaybackTimeUpdated];
                                                                           }];
                // add notification for playing-to-end event
                [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handlePlayingToEnd:) name:AVPlayerItemDidPlayToEndTimeNotification object:playerItem];
            }
                break;
            case AVPlayerItemStatusFailed:
            case AVPlayerItemStatusUnknown:
            {
                NSLog(@"player failed to play");
            }
                break;
        }
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wundeclared-selector"
    } else if ([keyPath isEqualToString:NSStringFromSelector(@selector(readyForDisplay))]) {
        AVPlayerLayer *layer = (AVPlayerLayer *)object;
        [layer removeObserver:self forKeyPath:NSStringFromSelector(@selector(readyForDisplay)) context:context];
#pragma clang diagnostic pop
        
        NSLog(@"video content is ready for display");
        [self.delegate manager:self didReceivePlayerEvent:PlayerLayerIsReadyForDisplay];
    }
}

#pragma mark - Public

- (void)setup:(NSString *)mediaUrl
{
    AVAsset *asset = [[AVURLAsset alloc] initWithURL:[NSURL URLWithString:mediaUrl] options:nil];
    
    self.mediaLoadTimer = [NSTimer scheduledTimerWithTimeInterval:self.mediaLoadTimeout target:self selector:@selector(handleAssetTimeout:) userInfo:asset repeats:NO];
    
    NSLog(@"begin to load asset properties");
    NSArray *keys = @[@"playable", @"duration", @"tracks"];
    [asset loadValuesAsynchronouslyForKeys:keys completionHandler:^{
        NSError *error = nil;
        
        // playable
        AVKeyValueStatus statusPlayable = [asset statusOfValueForKey:@"playable" error:&error];
        switch (statusPlayable) {
            case AVKeyValueStatusLoaded:
            {
                NSLog(@"is asset playable? %ld", (long)asset.isPlayable);
                
                if (asset.isPlayable) {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        AVPlayerItem *item = [AVPlayerItem playerItemWithAsset:asset];
                        [item addObserver:self forKeyPath:NSStringFromSelector(@selector(status)) options:NSKeyValueObservingOptionNew context:nil];
                        NSLog(@"observer is added on playerItem's status property");
                        
                        AVPlayer *player = [AVPlayer playerWithPlayerItem:item];
                        [self.playerLayer setPlayer:player];
                        
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wundeclared-selector"
                        [self.playerLayer addObserver:self forKeyPath:NSStringFromSelector(@selector(readyForDisplay)) options:NSKeyValueObservingOptionNew context:nil];
#pragma clang diagnostic pop
                        
                        self.player = player;
                    });
                } else {
                    NSLog(@"asset is not playable");
                }
            }
                break;
            default:
                NSLog(@"asset's playable cannot be retrieved due to the AVKeyValueStatus of %ld, error:%@", (long)statusPlayable, error);
                break;
        }
        
        // duration
        AVKeyValueStatus statusDuration = [asset statusOfValueForKey:@"duration" error:&error];
        switch (statusDuration) {
            case AVKeyValueStatusLoaded:
            {
                Float64 duration = CMTimeGetSeconds(asset.duration);
                NSLog(@"asset duration: %lf", duration);
                self.duration = duration;
            }
                break;
            default:
                NSLog(@"asset's duration cannot be retrieved due to the AVKeyValueStatus of %ld, error:%@", (long)statusDuration, error);
                break;
        }
        
        // tracks
        AVKeyValueStatus statusTracks = [asset statusOfValueForKey:@"tracks" error:&error];
        switch (statusTracks) {
            case AVKeyValueStatusLoaded:
            {
                NSArray<AVAssetTrack *> *tracks = [asset tracksWithMediaType:AVMediaTypeVideo];
                if (tracks.count > 0) {
                    NSLog(@"tracks number: %ld", (long)tracks.count);
                    AVAssetTrack *track = (AVAssetTrack *)[asset tracksWithMediaType:AVMediaTypeVideo][0];
                    NSLog(@"size of 1st asset in the tracks: %@", NSStringFromCGSize(track.naturalSize));
                } else {
                    NSLog(@"no video track found");
                }
            }
                break;
            default:
                NSLog(@"asset's tracks cannot be retrieved due to the AVKeyValueStatus of %ld, error:%@", (long)statusTracks, error);
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

- (void)handlePlayingToEnd:(NSNotification *)notification
{
    NSLog(@"player plays to end with object: %@", notification.object);
    [self.delegate manager:self didReceivePlayerEvent:PlayToEnd];
}

@end
