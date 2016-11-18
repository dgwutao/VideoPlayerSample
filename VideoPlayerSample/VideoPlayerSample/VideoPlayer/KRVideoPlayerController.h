//
//  KRVideoPlayerController.h
//  KRKit
//
//  Created by aidenluo on 5/23/17.
//  Copyright (c) 2017 axel. All rights reserved.
//

@import MediaPlayer;

@interface KRVideoPlayerController : UIViewController
@property (copy, nonatomic) NSURL *videoUrl;
@property (nonatomic, copy)void(^dimissCompleteBlock)(void);

@end
