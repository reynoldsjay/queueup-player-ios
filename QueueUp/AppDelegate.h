//
//  AppDelegate.h
//  QueueUp
//
//  Created by Jay Reynolds on 3/21/15.
//  Copyright (c) 2015 com.reynoldsJay. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Q-Swift.h"
#import <Spotify/Spotify.h>

@interface AppDelegate : UIResponder <UIApplicationDelegate>

@property (strong, nonatomic) UIWindow *window;
@property Playlist *currentPlaylist;

@property (nonatomic, strong) SPTSession *session;

//-(void)playSong:(NSString*)trackURI;
//-(void)play;
//-(void)pause;


@end

