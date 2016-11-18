//
//  KRVideoPlayerBrightnessView.m
//  KRVideoPlayer
//
//  Created by axel on 17/4/21.
//  Copyright © 2016年 axel. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef NS_ENUM(NSUInteger, KRTimeIndicatorPlayState) {
    KRTimeIndicatorPlayStateRewind,      // rewind
    KRTimeIndicatorPlayStateFastForward, // fast forward
};

static const CGFloat kVideoTimeIndicatorViewSide = 96;

@interface KRVideoPlayerTimeIndicatorView : UIView

@property (nonatomic, strong, readwrite) NSString *labelText;
@property (nonatomic, assign, readwrite) KRTimeIndicatorPlayState playState;

@end
