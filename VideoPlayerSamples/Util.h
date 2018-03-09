//
//  Util.h
//  VideoPlayerSamples
//
//  Created by g.shu on 2018/03/09.
//  Copyright © 2018 Genmis Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

/** Enum that defines the video urls in VideoData.plist file */
typedef NS_ENUM(NSInteger, VideoName) {
    VideoInvalid,
    VideoSec5,
    VideoSec15_1,
    VideoSec15_2,
    VideoSec31,
    VideoSec71,
    VideoSec600,
    VideoSec3600
};

@interface Util : NSObject

@property (nonatomic, readonly) NSDictionary<NSString *, NSString *> *videoData;

@end
