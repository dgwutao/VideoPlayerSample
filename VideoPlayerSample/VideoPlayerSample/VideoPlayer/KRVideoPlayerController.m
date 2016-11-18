//
//  KRVideoPlayerController.m
//  KRKit
//
//  Created by aidenluo on 5/23/17.
//  Copyright (c) 2017 axel. All rights reserved.
//

#import "KRVideoPlayerController.h"
#import "KRVideoPlayerControlView.h"

@interface KRVideoPlayerController ()
{
    UIView *_videoView;
    bool _isFinished;
    BOOL _isStalled;
}

@property (strong, nonatomic) AVPlayer *player;
@property (strong, nonatomic) KRVideoPlayerControlView *videoControl;
@property (strong, nonatomic) AVPlayerLayer *playerLayer;
@property (assign, nonatomic) BOOL isFullscreenMode;
@property (assign, nonatomic) CGRect originFrame;
@property (assign, nonatomic) BOOL isVolumeAdjust;
@property (strong, nonatomic) UISlider *volumeViewSlider;
@property (assign, nonatomic) BOOL isHorizontalMove;
@property (nonatomic, assign) CGFloat currentTime;
@property (nonatomic, assign) CGFloat lastSliderValue;
@end

@implementation KRVideoPlayerController

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor blackColor];
    
    _videoView = [[UIView alloc]initWithFrame:CGRectMake(0, ([UIScreen mainScreen].bounds.size.width - [UIScreen mainScreen].bounds.size.width * (9.0/16.0)) / 2 , [UIScreen mainScreen].bounds.size.width, [UIScreen mainScreen].bounds.size.width * (9.0/16.0))];
    _videoView.backgroundColor = [UIColor blackColor];
    
    AVPlayerItem *playerItem = [AVPlayerItem playerItemWithURL:self.videoUrl];
    _player = [AVPlayer playerWithPlayerItem:playerItem];
    self.playerLayer = [AVPlayerLayer playerLayerWithPlayer:_player];
    self.playerLayer.frame = _videoView.bounds;
    self.playerLayer.videoGravity = AVLayerVideoGravityResizeAspect;
    [_videoView.layer addSublayer:self.playerLayer];
    
    __weak typeof (self) weakSelf = self;
    [_player addPeriodicTimeObserverForInterval:CMTimeMake(1.0, 1.0) queue:dispatch_get_main_queue() usingBlock:^(CMTime time) {
        CGFloat current = CMTimeGetSeconds(time);
        CGFloat total = CMTimeGetSeconds([weakSelf.player.currentItem duration]);
        if (current) {
            weakSelf.videoControl.progressSlider.value = floor(current);
            [weakSelf setTimeLabelValues:floor(current) totalTime:floor(total)];
        }
    }];
    
    [self.view addSubview:_videoView];
    [_videoView addSubview:self.videoControl];
    
    UIPanGestureRecognizer *pan = [[UIPanGestureRecognizer alloc]initWithTarget:self action:@selector(panDirection:)];
    [self.videoControl addGestureRecognizer:pan];
    
    [self addObserverAndNotification:playerItem];
    
    [self configVolume];
    
    [self.videoControl.indicatorView startAnimating];
    
    _isStalled = YES;
}

-(void)addObserverAndNotification:(AVPlayerItem *)playerItem{
    [playerItem addObserver:self forKeyPath:@"status" options:NSKeyValueObservingOptionNew context:nil];
    [playerItem addObserver:self forKeyPath:@"loadedTimeRanges" options:NSKeyValueObservingOptionNew context:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(enterForegroundNotification) name:UIApplicationWillEnterForegroundNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(resignActiveNotification) name:UIApplicationDidEnterBackgroundNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(playbackFinished:) name:AVPlayerItemDidPlayToEndTimeNotification object:_player.currentItem];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(playbackStalled:) name:AVPlayerItemPlaybackStalledNotification object:_player.currentItem];
    
    [[UIDevice currentDevice] beginGeneratingDeviceOrientationNotifications];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(onDeviceOrientationChange)
                                                 name:UIDeviceOrientationDidChangeNotification
                                               object:nil
     ];
}

- (void)onDeviceOrientationChange{
    UIDeviceOrientation orientation = [UIDevice currentDevice].orientation;
    UIInterfaceOrientation interfaceOrientation = (UIInterfaceOrientation)orientation;
    switch (interfaceOrientation) {
        case UIInterfaceOrientationPortraitUpsideDown:{
            [self backOrientationPortrait];
            break;
        }
        case UIInterfaceOrientationPortrait:{
            [self backOrientationPortrait];
            break;
        }
        case UIInterfaceOrientationLandscapeLeft:{
            [self setDeviceOrientationLandscape:-M_PI_2];
            break;
        }
        case UIInterfaceOrientationLandscapeRight:{
            [self setDeviceOrientationLandscape:M_PI_2];
            break;
        }
        default:
            break;
    }
}

- (void)backOrientationPortrait{
    if (!self.isFullscreenMode) {
        return;
    }
    [UIView animateWithDuration:0.3f animations:^{
        [_videoView setTransform:CGAffineTransformIdentity];
        _videoView.frame = self.originFrame;
        self.playerLayer.frame = _videoView.bounds;
        self.videoControl.frame = _videoView.bounds;
        [self.videoControl setNeedsLayout];
        [self.videoControl layoutIfNeeded];
    } completion:^(BOOL finished) {
        self.isFullscreenMode = NO;
        self.videoControl.fullScreenButton.hidden = NO;
        self.videoControl.shrinkScreenButton.hidden = YES;
        [[UIApplication sharedApplication] setStatusBarHidden:NO withAnimation:UIStatusBarAnimationFade];
    }];
}

- (void)setDeviceOrientationLandscape:(CGFloat)angel{
    if (self.isFullscreenMode) {
        return;
    }
    self.originFrame = _videoView.frame;
    CGFloat height = [[UIScreen mainScreen] bounds].size.width;
    CGFloat width = [[UIScreen mainScreen] bounds].size.height;
    CGRect frame = CGRectMake((height - width) / 2, (width - height) / 2, width, height);
    [UIView animateWithDuration:0.3f animations:^{
        _videoView.frame = frame;
        self.playerLayer.frame = CGRectMake(0, 0, width, height);
        [self.videoControl setFrame:CGRectMake(0, 0, width, height)];
        [_videoView setTransform:CGAffineTransformMakeRotation(angel)];
        [self.videoControl setNeedsLayout];
        [self.videoControl layoutIfNeeded];
    } completion:^(BOOL finished) {
        self.isFullscreenMode = YES;
        self.videoControl.fullScreenButton.hidden = YES;
        self.videoControl.shrinkScreenButton.hidden = NO;
        [[UIApplication sharedApplication] setStatusBarHidden:YES withAnimation:UIStatusBarAnimationFade];
    }];
}

-(void)removeObserverFromPlayerItem:(AVPlayerItem *)playerItem{
    [playerItem removeObserver:self forKeyPath:@"status"];
    [playerItem removeObserver:self forKeyPath:@"loadedTimeRanges"];
}

-(void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context{
    AVPlayerItem *playerItem = object;
    if ([keyPath isEqualToString:@"status"]) {
        AVPlayerStatus status = self.player.status;
        switch(status)
        {
            case AVPlayerItemStatusReadyToPlay:
            {
                [self play];
                self.videoControl.progressSlider.minimumValue = 0.f;
                self.videoControl.progressSlider.maximumValue = floor(CMTimeGetSeconds(playerItem.duration));
                break;
            }
            case AVPlayerItemStatusFailed:
            {
                
                break;
            }
            case AVPlayerItemStatusUnknown:
            {
                break;
            }
        }
    }else if([keyPath isEqualToString:@"loadedTimeRanges"]){
        NSArray *array = playerItem.loadedTimeRanges;
        CMTimeRange timeRange = [array.firstObject CMTimeRangeValue];
        //        float startSeconds = CMTimeGetSeconds(timeRange.start);
        CGFloat durationSeconds = CMTimeGetSeconds(timeRange.duration);
        if (_isStalled && durationSeconds > 2.0f) {
            _isStalled = NO;
            [self.videoControl.indicatorView stopAnimating];
            [self.videoControl autoFadeOutControlBar];
            [self play];
        }
    }
}

- (void)playbackFinished:(NSNotification *)notification{
    _isFinished = YES;
    self.videoControl.replayButton.hidden = NO;
    self.videoControl.playButton.hidden = NO;
    self.videoControl.pauseButton.hidden = YES;
}

- (void)playbackStalled:(NSNotification *)notification{
    [self.videoControl.indicatorView startAnimating];
    _isStalled = YES;
    [self.videoControl animateShow];
    [self pause];
}

- (void)dismiss
{
    if (self.dimissCompleteBlock) {
        self.dimissCompleteBlock();
    }
    [self removeObserverFromPlayerItem:_player.currentItem];
    [self removeNotification];
    [[UIApplication sharedApplication] setStatusBarHidden:NO withAnimation:UIStatusBarAnimationFade];
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void) replayVideo:(id)sender
{
    if (_isFinished) {
        CMTime dragedCMTime = CMTimeMake(0, 1);
        [self.player.currentItem seekToTime:dragedCMTime];
    }
    [self play];
    self.videoControl.replayButton.hidden = YES;
}

- (void)playButtonClick
{
    if (_isFinished) {
        CMTime dragedCMTime = CMTimeMake(0, 1);
        [self.player.currentItem seekToTime:dragedCMTime];
    }
    [self play];
}

- (void)pauseButtonClick
{
    [self pause];
}

- (void)closeButtonClick
{
    [self dismiss];
}

- (void)fullScreenButtonClick
{
    if (self.isFullscreenMode) {
        return;
    }
    [self setDeviceOrientationLandscape:M_PI_2];
}

- (void)shrinkScreenButtonClick
{
    if (!self.isFullscreenMode) {
        return;
    }
    [self backOrientationPortrait];
}

- (void) play{
    [self.player play];
    self.videoControl.playButton.hidden = YES;
    self.videoControl.pauseButton.hidden = NO;
    self.videoControl.replayButton.hidden = YES;
}

- (void) pause{
    [self.player pause];
    self.videoControl.playButton.hidden = NO;
    self.videoControl.pauseButton.hidden = YES;
    if (!_isStalled) {
        self.videoControl.replayButton.hidden = NO;
    }
}

- (void)progressSliderValueChanged:(UISlider *)slider {
    [self pause];
    self.videoControl.replayButton.hidden = YES;
    [self.videoControl cancelAutoFadeOutControlBar];
    [self sliderMove:slider.value];
}

- (void)progressSliderTouchEnded:(UISlider *)slider {
    [self play];
    [self.videoControl autoFadeOutControlBar];
}

- (void)setTimeLabelValues:(double)currentTime totalTime:(double)totalTime {
    double minutesElapsed = floor(currentTime / 60.0);
    double secondsElapsed = fmod(currentTime, 60.0);
    NSString *timeElapsedString = [NSString stringWithFormat:@"%02.0f:%02.0f", minutesElapsed, secondsElapsed];
    double minutesRemaining = floor(totalTime / 60.0);;
    double secondsRemaining = floor(fmod(totalTime, 60.0));;
    NSString *timeRmainingString = [NSString stringWithFormat:@"%02.0f:%02.0f", minutesRemaining, secondsRemaining];
    self.videoControl.timeLabel.text = [NSString stringWithFormat:@"%@/%@",timeElapsedString,timeRmainingString];
}

- (KRVideoPlayerControlView *)videoControl
{
    if (!_videoControl) {
        _videoControl = [[KRVideoPlayerControlView alloc] initWithFrame:_videoView.bounds];
        [self configControlAction];
    }
    return _videoControl;
}

- (void)configControlAction
{
    [self.videoControl.playButton addTarget:self action:@selector(playButtonClick) forControlEvents:UIControlEventTouchUpInside];
    [self.videoControl.pauseButton addTarget:self action:@selector(pauseButtonClick) forControlEvents:UIControlEventTouchUpInside];
    [self.videoControl.closeButton addTarget:self action:@selector(closeButtonClick) forControlEvents:UIControlEventTouchUpInside];
    [self.videoControl.fullScreenButton addTarget:self action:@selector(fullScreenButtonClick) forControlEvents:UIControlEventTouchUpInside];
    [self.videoControl.shrinkScreenButton addTarget:self action:@selector(shrinkScreenButtonClick) forControlEvents:UIControlEventTouchUpInside];
    [self.videoControl.progressSlider addTarget:self action:@selector(progressSliderValueChanged:) forControlEvents:UIControlEventValueChanged];
    [self.videoControl.progressSlider addTarget:self action:@selector(progressSliderTouchEnded:) forControlEvents:UIControlEventTouchUpInside];
    [self.videoControl.progressSlider addTarget:self action:@selector(progressSliderTouchEnded:) forControlEvents:UIControlEventTouchUpOutside];
    [self.videoControl.replayButton addTarget:self action:@selector(replayVideo:) forControlEvents:UIControlEventTouchUpInside];
}

- (void)panDirection:(UIPanGestureRecognizer *)pan
{
    CGPoint locationPoint = [pan locationInView:self.videoControl];
    CGPoint veloctyPoint = [pan velocityInView:self.videoControl];
    
    switch (pan.state) {
        case UIGestureRecognizerStateBegan: {
            CGFloat x = fabs(veloctyPoint.x);
            CGFloat y = fabs(veloctyPoint.y);
            if (x > y) {
                self.isHorizontalMove = YES;
                self.currentTime = self.videoControl.progressSlider.value;
                [self pause];
                self.videoControl.replayButton.hidden = YES;
            } else if (x < y) {
                self.isHorizontalMove = NO;
                if (locationPoint.x > _videoView.frame.size.width / 2) {
                    self.isVolumeAdjust = YES;
                } else {
                    self.isVolumeAdjust = NO;
                }
            }
            break;
        }
        case UIGestureRecognizerStateChanged: {
            if (self.isHorizontalMove) {
                [self horizontalMove:veloctyPoint.x];
            }else{
                [self verticalMove:veloctyPoint.y];
            }
            break;
        }
        case UIGestureRecognizerStateEnded: {
            if (self.isHorizontalMove) {
                [self play];
                [self.videoControl autoFadeOutControlBar];
            }
            break;
        }
        default:
            break;
    }
}

- (void)horizontalMove:(CGFloat)value
{
    self.currentTime += value / 1000;
    CGFloat total = floor(CMTimeGetSeconds(self.player.currentItem.duration));
    if (self.currentTime > total) {
        self.currentTime = total;
    } else if (self.currentTime < 0) {
        self.currentTime = 0;
    }
    
    CGFloat currentTime = self.currentTime;
    CGFloat totalTime = total;
    [self setTimeLabelValues:currentTime totalTime:totalTime];
    self.videoControl.timeIndicatorView.labelText = self.videoControl.timeLabel.text;
    self.videoControl.progressSlider.value = self.currentTime;
    CMTime dragedCMTime = CMTimeMake(self.videoControl.progressSlider.value, 1);
    [self.player.currentItem seekToTime:dragedCMTime];
    KRTimeIndicatorPlayState playState;
    if (value < 0) {
        playState = KRTimeIndicatorPlayStateRewind;
    } else if (value > 0) {
        playState = KRTimeIndicatorPlayStateFastForward;
    }
    if (self.videoControl.timeIndicatorView.playState != playState) {
        self.videoControl.timeIndicatorView.playState = KRTimeIndicatorPlayStateFastForward;
        [self.videoControl.timeIndicatorView setNeedsLayout];
    }
}

- (void)sliderMove:(CGFloat)value
{
    CGFloat total = floor(CMTimeGetSeconds(self.player.currentItem.duration));
    if (value > total) {
        value = total;
    } else if (value < 0) {
        value = 0;
    }
    
    CGFloat currentTime = value;
    CGFloat totalTime = total;
    [self setTimeLabelValues:currentTime totalTime:totalTime];
    self.videoControl.timeIndicatorView.labelText = self.videoControl.timeLabel.text;
    CMTime dragedCMTime = CMTimeMake(value, 1.0);
    [self.player.currentItem seekToTime:dragedCMTime];
    KRTimeIndicatorPlayState playState;
    if (value < self.lastSliderValue) {
        playState = KRTimeIndicatorPlayStateRewind;
    } else if (value > self.lastSliderValue) {
        playState = KRTimeIndicatorPlayStateFastForward;
    }
    self.lastSliderValue = value;
    if (self.videoControl.timeIndicatorView.playState != playState) {
        self.videoControl.timeIndicatorView.playState = playState;
        [self.videoControl.timeIndicatorView setNeedsLayout];
    }
}

- (void)verticalMove:(CGFloat)value
{
    if (self.isVolumeAdjust) {
        self.volumeViewSlider.value -= value / 10000;
    }else {
        CGFloat currentBrightness = [UIScreen mainScreen].brightness;
        [[UIScreen mainScreen] setBrightness:currentBrightness - value / 10000];
    }
}

- (void)configVolume
{
    MPVolumeView *volumeView = [[MPVolumeView alloc] init];
    volumeView.center = CGPointMake(-1000, 0);
    [self.view addSubview:volumeView];
    
    for (UIView *view in [volumeView subviews]){
        if ([view.class.description isEqualToString:@"MPVolumeSlider"]){
            _volumeViewSlider = (UISlider *)view;
            break;
        }
    }
    
    NSError *error = nil;
    BOOL success = [[AVAudioSession sharedInstance] setCategory: AVAudioSessionCategoryPlayback error: &error];
    
    if (!success) {/* error */}
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(audioRouteChangeListenerCallback:) name:AVAudioSessionRouteChangeNotification object:nil];
}

- (void)audioRouteChangeListenerCallback:(NSNotification*)notification
{
    NSInteger routeChangeReason = [[notification.userInfo valueForKey:AVAudioSessionRouteChangeReasonKey] integerValue];
    switch (routeChangeReason) {
        case AVAudioSessionRouteChangeReasonNewDeviceAvailable:
            NSLog(@"---耳机插入");
            break;
            
        case AVAudioSessionRouteChangeReasonOldDeviceUnavailable: {
            NSLog(@"---耳机拔出");
            [self play];
            
            break;
        }
        case AVAudioSessionRouteChangeReasonCategoryChange:
            
            break;
            
        default:
            break;
    }
}

- (void)resignActiveNotification{
    [self pause];
}

- (void)enterForegroundNotification
{
    [self play];
}

-(void)removeNotification{
    [[UIDevice currentDevice]endGeneratingDeviceOrientationNotifications];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

@end
