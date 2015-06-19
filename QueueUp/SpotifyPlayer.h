//
//  SpotifyPlayer.h
//  QueueUp
//
//  Created by Jay Reynolds on 6/17/15.
//  Copyright (c) 2015 com.reynoldsJay. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Spotify/Spotify.h>

@interface SpotifyPlayer : NSObject <SPTAudioStreamingDelegate, SPTAudioStreamingPlaybackDelegate>



@property NSString *currentURI;
@property NSArray *queue;


+ (SpotifyPlayer*) getInstance;

-(void)handleNewSession;
-(void)playPause:(id)sender;

@end
