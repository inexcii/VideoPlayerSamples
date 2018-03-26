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

/** default timeout value(seconds) of loading a video media */
static Float64 kMediaLoadTimeoutSeconds = 2.0f;

@interface PlayerManager()

@property (nonatomic) AVPlayer *player;
@property (nonatomic, nonnull) AVPlayerLayer *playerLayer;
@property (nonatomic) NSTimer *mediaLoadTimer;
@property (nonatomic, readwrite) Float64 duration;
/** current playback time of AVPlayer */
@property (nonatomic, readwrite) Float64 currentTime;
@property (nonatomic, readwrite) Float64 bufferedTime;
/** observer asset's playback time as it progresses */
@property (nonatomic) id playerObserver;
/** Whether the player has constrained all the buffer and is storing the new buffers */
@property (nonatomic) BOOL isPlayerBuffering;

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
    
    [_player.currentItem removeObserver:self forKeyPath:NSStringFromSelector(@selector(loadedTimeRanges)) context:nil];
    
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wundeclared-selector"
    [_player.currentItem removeObserver:self forKeyPath:NSStringFromSelector(@selector(playbackBufferEmpty)) context:nil];
    [_player.currentItem removeObserver:self forKeyPath:NSStringFromSelector(@selector(playbackLikelyToKeepUp)) context:nil];
#pragma clang diagnostic pop
}

- (instancetype)initWithPlayerLayer:(AVPlayerLayer *)layer
{
    self = [super init];
    
    if (self) {
        _mediaLoadTimeout = kMediaLoadTimeoutSeconds;
        _playerLayer = layer;
        
        NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
        [nc addObserver:self selector:@selector(appWillResignActive) name:UIApplicationWillResignActiveNotification object:nil];
        [nc addObserver:self selector:@selector(appDidEnterBackground) name:UIApplicationDidEnterBackgroundNotification object:nil];
        [nc addObserver:self selector:@selector(appWillEnterForeground) name:UIApplicationWillEnterForegroundNotification object:nil];
        [nc addObserver:self selector:@selector(appDidBecomeActive) name:UIApplicationDidBecomeActiveNotification object:nil];
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
                
                [self.delegate manager:self didReceivePlayerEvent:PlayerDidStartToPlay userInfo:nil];
                
                __weak PlayerManager *weakSelf = self;
                self.playerObserver = [self.player addPeriodicTimeObserverForInterval:CMTimeMakeWithSeconds(kIntervalForPlayerTimeObserver, NSEC_PER_SEC)
                                                                                queue:nil
                                                                           usingBlock:^(CMTime time) {
                                                                               weakSelf.currentTime = CMTimeGetSeconds(time);
//                                                                               NSLog(@"current time is updated: %lf", weakSelf.currentTime);
                                                                               [weakSelf.delegate manager:weakSelf didReceivePlayerEvent:PlaybackTimeUpdated userInfo:nil];
                                                                           }];
                // add notification for playing-to-end event
                [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handlePlayingToEnd:) name:AVPlayerItemDidPlayToEndTimeNotification object:playerItem];
                
                // add KVO on loadedTimeRange to retrieve buffered time of video
                [playerItem addObserver:self
                             forKeyPath:NSStringFromSelector(@selector(loadedTimeRanges))
                                options:NSKeyValueObservingOptionInitial | NSKeyValueObservingOptionNew
                                context:nil];
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
        [self.delegate manager:self didReceivePlayerEvent:PlayerLayerIsReadyForDisplay userInfo:nil];
    } else if ([keyPath isEqualToString:NSStringFromSelector(@selector(loadedTimeRanges))]) {
        AVPlayerItem *playerItem = (AVPlayerItem *)object;
        NSArray<NSValue *> *ranges = playerItem.loadedTimeRanges;
//        NSLog(@"loadedTimeRanges: %@", ranges);
        if (ranges.count > 0) {
            CMTimeRange range = [ranges[0] CMTimeRangeValue];
            self.bufferedTime = CMTimeGetSeconds(range.start) + CMTimeGetSeconds(range.duration);
            [self.delegate manager:self didReceivePlayerEvent:PlayBufferUpdated userInfo:nil];
        } else {
            NSLog(@"loadedTimeRanges does not contain any value");
        }
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wundeclared-selector"
    } else if ([keyPath isEqualToString:NSStringFromSelector(@selector(playbackBufferEmpty))]) {
        AVPlayerItem *item = (AVPlayerItem *)object;
        if (item.playbackBufferEmpty) {
            NSLog(@"playback's buffer becomes empty, starts to buffer");
            self.isPlayerBuffering = YES;
            
            // If necessary, add code to handle the situation when player starts to store new buffers, such as displaying a buffer-loading view.
            
        }
    } else if ([keyPath isEqualToString:NSStringFromSelector(@selector(playbackLikelyToKeepUp))]) {
        AVPlayerItem *item = (AVPlayerItem *)object;
        NSLog(@"playbackLikelyToKeepUp: %ld", (long)item.isPlaybackLikelyToKeepUp);
        if (item.isPlaybackLikelyToKeepUp && self.isPlayerBuffering) {
            NSLog(@"resume the player after getting enough buffer");
            
            // If necessary, add code to handle the situation when player has stored the enough buffer and likely to play the video continuously.
            
            [self.player play];
            self.isPlayerBuffering = NO;
        }
#pragma clang diagnostic pop
    }
}

#pragma mark - Public

- (void)setup:(NSString *)mediaUrl
{
    AVAsset *asset = [[AVURLAsset alloc] initWithURL:[NSURL URLWithString:mediaUrl] options:nil];
    
    self.mediaLoadTimer = [NSTimer scheduledTimerWithTimeInterval:self.mediaLoadTimeout target:self selector:@selector(handleAssetTimeout:) userInfo:asset repeats:NO];
    
    NSLog(@"begin to load asset properties with url: %@", mediaUrl);
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
                        // KVO on AVPlayerItem.status
                        [item addObserver:self forKeyPath:NSStringFromSelector(@selector(status)) options:NSKeyValueObservingOptionNew context:nil];
                        NSLog(@"observer is added on playerItem's status property");

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wundeclared-selector"
                        // KVO on AVPlayerItem.playbackBufferEmpty
                        [item addObserver:self forKeyPath:NSStringFromSelector(@selector(playbackBufferEmpty)) options:NSKeyValueObservingOptionNew context:nil];
                        // KVO on AVPlayerItem.playbackLikelyToKeepUp
                        [item addObserver:self forKeyPath:NSStringFromSelector(@selector(playbackLikelyToKeepUp)) options:NSKeyValueObservingOptionNew context:nil];
#pragma clang diagnostic pop
                        
                        AVPlayer *player = [AVPlayer playerWithPlayerItem:item];
                        [self.playerLayer setPlayer:player];
                        
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wundeclared-selector"
                        // KVO on AVPlayerLayer.readyForDisplay
                        [self.playerLayer addObserver:self forKeyPath:NSStringFromSelector(@selector(readyForDisplay)) options:NSKeyValueObservingOptionNew context:nil];
#pragma clang diagnostic pop
                        
                        self.player = player;
                    });
                } else {
                    NSLog(@"asset is not playable");
                }
            }
                break;
            case AVKeyValueStatusCancelled:
            {
                [self.delegate manager:self didReceivePlayerEvent:FailToLoadAsset userInfo:@{@"keyToLoad": @"playable"}];
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
            case AVKeyValueStatusCancelled:
            {
                [self.delegate manager:self didReceivePlayerEvent:FailToLoadAsset userInfo:@{@"keyToLoad": @"duration"}];
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
            case AVKeyValueStatusCancelled:
            {
                [self.delegate manager:self didReceivePlayerEvent:FailToLoadAsset userInfo:@{@"keyToLoad": @"tracks"}];
            }
                break;
            default:
                NSLog(@"asset's tracks cannot be retrieved due to the AVKeyValueStatus of %ld, error:%@", (long)statusTracks, error);
                break;
        }
        
        [self invalidateMediaLoadTimer];
    }];
}

- (void)seekTo:(Float64)value
{
    Float64 second = self.duration * value;
    NSLog(@"seek video to %.2lf second", second);
    CMTime time = CMTimeMakeWithSeconds(second, NSEC_PER_SEC);
    
    // FIXME: Empty frame is displayed when seeking to the end of the video.
    [self.player seekToTime:time toleranceBefore:kCMTimeZero toleranceAfter:kCMTimeZero completionHandler:^(BOOL finished) {
        if (finished) {
            [self play];
        }
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
    [self.delegate manager:self didReceivePlayerEvent:PlayToEnd userInfo:nil];
}

#pragma mark Foreground & Background Switch

- (void)appWillResignActive
{
    NSLog(@"app will resign active");
}

- (void)appDidEnterBackground
{
    NSLog(@"app did enter background");
}

- (void)appWillEnterForeground
{
    NSLog(@"app will enter foreground");
}

- (void)appDidBecomeActive
{
    NSLog(@"app did become active");
}

@end
