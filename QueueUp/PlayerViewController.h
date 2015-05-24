//
//  PlayerViewController.h
//  QueueUp
//
//  Created by Jay Reynolds on 3/23/15.
//  Copyright (c) 2015 com.reynoldsJay. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Spotify/Spotify.h>

@interface PlayerViewController : UIViewController <SPTAudioStreamingDelegate, SPTAudioStreamingPlaybackDelegate>

-(void)playSong:(NSString*)trackURI;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *sidebarButton;

@end
