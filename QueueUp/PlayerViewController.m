//
//  PlayerViewController.m
//  QueueUp
//
//  Created by Jay Reynolds on 6/16/15.
//  Copyright (c) 2015 com.reynoldsJay. All rights reserved.
//

#import "Config.h"
#import "PlayerViewController.h"
#import <Spotify/SPTDiskCache.h>
#import "SpotifyPlayer.h"
#import "PlayerUIProtocol.h"

@interface PlayerViewController ()

@end

@implementation PlayerViewController {
    SpotifyPlayer *player;
}

-(void)viewDidLoad {
    [super viewDidLoad];
//    self.titleLabel.text = @"Nothing Playing";
//    self.albumLabel.text = @"";
//    self.artistLabel.text = @"";
}

//- (BOOL)prefersStatusBarHidden {
//    return YES;
//}




#pragma mark - Logic



- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    player = [SpotifyPlayer getInstance];
    [player handleNewSession];
}


@end