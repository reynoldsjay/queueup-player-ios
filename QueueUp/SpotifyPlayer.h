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


@property (nonatomic, strong) SPTAudioStreamingController *player;


@property NSString *currentURI;
@property NSArray *queue;
@property NSDictionary *curTrack;
@property BOOL playing;


+ (SpotifyPlayer*) getInstance;

-(void)handleNewSession:(id)sender;
-(void)playPause;
-(void)subToPlaylist;
-(void)pause;
-(void)nextTrack;

@end
