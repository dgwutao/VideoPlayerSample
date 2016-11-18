//
//  KRVideoPlayerControlView.h
//  KRKit
//
//  Created by aidenluo on 5/23/17.
//  Copyright (c) 2015 axel. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "KRVideoPlayerTimeIndicatorView.h"
#import "KRVideoPlayerBrightnessView.h"
#import "KRVideoPlayerVolumeView.h"


@interface KRVideoPlayerControlView : UIView

@property (nonatomic, strong, readonly) UIView *topBar;
@property (nonatomic, strong, readonly) UIView *bottomBar;
@property (nonatomic, strong, readonly) UIButton *playButton;
@property (nonatomic, strong, readonly) UIButton *pauseButton;
@property (nonatomic, strong, readonly) UIButton *fullScreenButton;
@property (nonatomic, strong, readonly) UIButton *shrinkScreenButton;
@property (nonatomic, strong, readonly) UISlider *progressSlider;
@property (nonatomic, strong, readonly) UIButton *closeButton;
@property (nonatomic, strong, readonly) UILabel *timeLabel;
@property (nonatomic, strong, readonly) UIActivityIndicatorView *indicatorView;
@property (nonatomic, strong, readwrite) KRVideoPlayerTimeIndicatorView *timeIndicatorView;
@property (nonatomic, strong, readwrite) KRVideoPlayerBrightnessView *brightnessIndicatorView;
@property (nonatomic, strong, readwrite) KRVideoPlayerVolumeView *volumeIndicatorView;
@property (nonatomic, strong, readonly) UIButton *replayButton;
- (void)animateHide;
- (void)animateShow;
- (void)autoFadeOutControlBar;
- (void)cancelAutoFadeOutControlBar;

@end
