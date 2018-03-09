//
//  PlayerManager.h
//  VideoPlayerSamples
//
//  Created by Ralph Zhou on 2018/02/24.
//  Copyright © 2018 Genmis Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

@class AVPlayer;
@class AVPlayerLayer;
@class PlayerManager;

typedef NS_ENUM(NSInteger, PlayerEvent) {
    /** Player failed to load asset due to invalid video url or network timeout */
    FailToLoadAsset,
    
    /** This event is triggered right after [AVPlayer play] is called */
    PlayerDidStartToPlay,
    
    /** When the new value of 'readyForDisplay' property of AVPlayerLayer is observed by the KVO */
    PlayerLayerIsReadyForDisplay,
    
    /** Triggered everytime playback's time is updated as the content progresses */
    PlaybackTimeUpdated,
    
    /** Triggered when video plays to the end */
    PlayToEnd
};

NS_ASSUME_NONNULL_BEGIN

@protocol PlayerManagerDelegate <NSObject>

- (void)manager:(PlayerManager *)manager didReceivePlayerEvent:(PlayerEvent)event userInfo:(nullable NSDictionary *)userInfo;

@end

@interface PlayerManager : NSObject

@property (nonatomic) NSTimeInterval mediaLoadTimeout;
@property (nonatomic, weak) id<PlayerManagerDelegate> delegate;
/** Duration of loaded AVAsset */
@property (nonatomic, readonly) Float64 duration;
@property (nonatomic, readonly) Float64 currentTime;

- (instancetype)initWithPlayerLayer:(AVPlayerLayer *)layer;
- (void)setup:(NSString *)mediaUrl;
- (void)play;
- (void)pause;

NS_ASSUME_NONNULL_END

@end
