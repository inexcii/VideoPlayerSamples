//
//  PlayerView.m
//  VideoPlayerSamples
//
//  Created by Ralph Zhou on 2018/01/29.
//  Copyright © 2018 Genmis Inc. All rights reserved.
//

#import "PlayerView.h"

@import AVFoundation;

@implementation PlayerView

+ (Class)layerClass
{
    return AVPlayerLayer.class;
}

@end
