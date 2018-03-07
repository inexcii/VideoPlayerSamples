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

typedef NS_ENUM(NSInteger, PlayerEvent) {
    PlayerDidStartToPlay
};

NS_ASSUME_NONNULL_BEGIN

@protocol PlayerManagerDelegate <NSObject>

- (void)didReceivePlayerEvent:(PlayerEvent)event;

@end

@interface PlayerManager : NSObject

@property (nonatomic) NSTimeInterval mediaLoadTimeout;
@property (nonatomic, weak) id<PlayerManagerDelegate> delegate;

- (instancetype)initWithPlayerLayer:(AVPlayerLayer *)layer;
- (void)setup:(NSString *)mediaUrl;
- (void)play;
- (void)pause;

NS_ASSUME_NONNULL_END

@end
