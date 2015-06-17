//
//  PlayerViewController.h
//  QueueUp
//
//  Created by Jay Reynolds on 6/16/15.
//  Copyright (c) 2015 com.reynoldsJay. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Spotify/Spotify.h>

@interface PlayerViewController : UIViewController<SPTAudioStreamingDelegate, SPTAudioStreamingPlaybackDelegate>

@end
