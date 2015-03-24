//
//  AppDelegate.h
//  QueueUp
//
//  Created by Jay Reynolds on 3/21/15.
//  Copyright (c) 2015 com.reynoldsJay. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Playlist.h"

@interface AppDelegate : UIResponder <UIApplicationDelegate>

@property (strong, nonatomic) UIWindow *window;
@property Playlist *currentPlaylist;

-(void)playSong:(NSString*)trackURI;
-(void)play;
-(void)pause;


@end

