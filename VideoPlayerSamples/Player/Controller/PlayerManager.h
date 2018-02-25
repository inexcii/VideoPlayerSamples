//
//  PlayerManager.h
//  VideoPlayerSamples
//
//  Created by Ralph Zhou on 2018/02/24.
//  Copyright © 2018 Genmis Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

@class AVPlayer;


@interface PlayerManager : NSObject

@property (nonatomic) NSTimeInterval mediaLoadTimeout;
@property (nonatomic, readonly) AVPlayer *player;

- (void)setup:(NSString *)mediaUrl completion:(void (^)(AVPlayer *))completion;
- (void)play;
- (void)pause;

@end
