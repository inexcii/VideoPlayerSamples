//
//  Util.m
//  VideoPlayerSamples
//
//  Created by g.shu on 2018/03/09.
//  Copyright © 2018 Genmis Inc. All rights reserved.
//

#import "Util.h"

@interface Util()

@property (nonatomic, readwrite) NSDictionary<NSString *, NSString *> *videoData;

@end

@implementation Util

#pragma mark - Override

- (instancetype)init
{
    self = [super init];
    
    if (self) {
        NSString *path = [[NSBundle mainBundle] pathForResource:@"VideoData" ofType:@"plist"];
        _videoData = [NSDictionary dictionaryWithContentsOfFile:path];
    }
    
    return self;
}

@end
