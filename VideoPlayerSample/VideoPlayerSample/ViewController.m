//
//  ViewController.m
//  VideoPlayerSample
//
//  Created by xf on 2016/11/18.
//  Copyright © 2016年 HappyNetwork. All rights reserved.
//

#import "ViewController.h"
#import "KRVideoPlayerController.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    KRVideoPlayerController *videoViewController = [[KRVideoPlayerController alloc]init];
    NSURL *path = [[NSBundle mainBundle] URLForResource:@"150511_JiveBike" withExtension:@"mov"];
    videoViewController.videoUrl = path;
    [self.navigationController presentViewController:videoViewController animated:YES completion:nil];
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
