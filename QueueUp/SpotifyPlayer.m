//
//  SpotifyPlayer.m
//  QueueUp
//
//  Created by Jay Reynolds on 6/17/15.
//  Copyright (c) 2015 com.reynoldsJay. All rights reserved.
//

#import "SpotifyPlayer.h"
#import <Spotify/SPTDiskCache.h>
#import "ServerAPI.h"
#import <SIOSocket/SIOSocket.h>
#import "Config.h"
#import "PlayerUIProtocol.h"

@interface SpotifyPlayer () <SPTAudioStreamingDelegate>

@property (nonatomic, strong) SPTAudioStreamingController *player;

@property SIOSocket *socket;
@property BOOL socketIsConnected;

@end

@implementation SpotifyPlayer {

    ServerAPI *api;
    UIViewController<PlayerUIProtocol> *watcher;

}

@synthesize queue;
@synthesize currentURI;
@synthesize curTrack;
@synthesize playing;

static SpotifyPlayer *singletonInstance;

+ (SpotifyPlayer*)getInstance {
    if (singletonInstance == nil) {
        singletonInstance = [[super alloc] init];
    }
    return singletonInstance;
}

#pragma mark - Actions

-(void)rewind:(id)sender {
    [self.player skipPrevious:nil];
}

-(void)playPause:(id)sender {
    [self.player setIsPlaying:!self.player.isPlaying callback:nil];
}

-(void)fastForward:(id)sender {
    [self.player skipNext:nil];
}

- (void)logoutClicked:(id)sender {
    SPTAuth *auth = [SPTAuth defaultInstance];
    if (self.player) {
        [self.player logout:^(NSError *error) {
            auth.session = nil;
            // seque somewhere
        }];
    }
//    } else {
//        [self.navigationController popViewControllerAnimated:YES];
//    }
}


-(void)handleNewSession:(id)sender {
    
    watcher = sender;
    
    SPTAuth *auth = [SPTAuth defaultInstance];
    
    if (self.player == nil) {
        self.player = [[SPTAudioStreamingController alloc] initWithClientId:auth.clientID];
        self.player.playbackDelegate = self;
        self.player.diskCache = [[SPTDiskCache alloc] initWithCapacity:1024 * 1024 * 64];
    }
    
//    [self.player loginWithSession:auth.session callback:^(NSError *error) {
//        
//        if (error != nil) {
//            NSLog(@"*** Enabling playback got error: %@", error);
//            return;
//        }
//        
//        //[self updateUI];
//        
//        NSURLRequest *playlistReq = [SPTPlaylistSnapshot createRequestForPlaylistWithURI:[NSURL URLWithString:@"spotify:user:cariboutheband:playlist:4Dg0J0ICj9kKTGDyFu0Cv4"]
//                                                                             accessToken:auth.session.accessToken
//                                                                                   error:nil];
//        
//        [[SPTRequest sharedHandler] performRequest:playlistReq callback:^(NSError *error, NSURLResponse *response, NSData *data) {
//            if (error != nil) {
//                NSLog(@"*** Failed to get playlist %@", error);
//                return;
//            }
//            
//            SPTPlaylistSnapshot *playlistSnapshot = [SPTPlaylistSnapshot playlistSnapshotFromData:data withResponse:response error:nil];
//            
//            [self.player playURIs:playlistSnapshot.firstTrackPage.items fromIndex:0 callback:nil];
//        }];
//    }];
//    
    
    
    
    // AFTER handling login
    
    
    
    
    
    // get api instance
    api = [ServerAPI getInstance];
    
    
//    // side bar set up
//    SWRevealViewController *revealViewController = self.revealViewController;
//    if ( revealViewController )
//    {
//        [self.sidebarButton setTarget: self.revealViewController];
//        [self.sidebarButton setAction: @selector( revealToggle: )];
//        [self.view addGestureRecognizer:self.revealViewController.panGestureRecognizer];
//    }
    
    
    
    if (api.currentPlaylist != nil) {
        
        [SIOSocket socketWithHost: @hostDomain response: ^(SIOSocket *socket) {
            
            self.socket = socket;
            __weak typeof(self) weakSelf = self;
            __weak typeof(api) weakapi = api;
            
            
            // on connecting to socket
            self.socket.onConnect = ^()
            {
                weakSelf.socketIsConnected = YES;
                NSLog(@"Connected.");
                [weakSelf.socket emit: @"auth" args: [[NSArray alloc] initWithObjects:weakapi.idAndToken, nil]];
            };
            
            [self.socket on: @"auth_response" callback: ^(SIOParameterArray *args)
             {
                 NSLog(@"RESPONSE");
                 if ([args firstObject] == nil) {
                     NSLog(@"Server responded to auth request.");
                     id json = [api parseJson:[[NSString alloc] initWithFormat:@"{\"playlist_id\" : \"%@\"}", (api.currentPlaylist)[@"_id"]]];
                     
                    // CHANGE TO PLAYER EVENTUALLY
                     [self.socket emit: @"client_subscribe" args: [[NSArray alloc] initWithObjects:json, nil]];
                 } else {
                     NSLog(@"%@", [args firstObject]);
                 }
                 
                 
             }];
//            [self.socket on: @"player_subscribe_response" callback: ^(SIOParameterArray *args)
//             {
//                 
//                 NSLog(@"%@", [args firstObject]);
//                 
//                 
//             }];
            
            
            
            [self.socket on: @"state_change" callback: ^(SIOParameterArray *args) {
                
                NSMutableDictionary *dictionaryStateData = [args firstObject];
                //NSLog(@"%@", dictionaryStateData);
                
                
                // update current track
                NSDictionary *track = dictionaryStateData[@"track"];
                NSString *trackURI = track[@"uri"];
                if (![currentURI isEqualToString:trackURI] && trackURI != nil) {
                    [self playSong:trackURI];
                    NSLog(@"New song (player).");
                    currentURI = trackURI;
                    curTrack = track;
                    
                }
                
                
                
                
                 //update play state, does the client view show this?
                if (dictionaryStateData[@"play"] != nil) {
                    BOOL playState = [dictionaryStateData[@"play"] boolValue];
                    [self.player setIsPlaying:playState callback:nil];
                    playing = playState;
                }
                
                
                // update queue
                
                
                NSDictionary *recQ = dictionaryStateData[@"queue"];
                if (recQ != nil) {
                    queue = (NSArray *) recQ;
                }
                
                [sender updateUI];
                
                
                
            }];
            
            
        }];
        
    }

    
    
    
    
    
    
}




-(void) playSong:(NSString*)trackURIString {
    
    SPTAuth *auth = [SPTAuth defaultInstance];
    
    [self.player loginWithSession:auth.session callback:^(NSError *error) {
        
        NSLog(@"Playing a song");
        if (error != nil) {
            NSLog(@"*** Enabling playback got error: %@", error);
            return;
        }
    }];
    
    NSURL *trackURI = [NSURL URLWithString:trackURIString];
    [self.player playURIs:@[ trackURI ] fromIndex:0 callback:^(NSError *error) {
        if (error != nil) {
            NSLog(@"*** Starting playback got error: %@", error);
            return;
        }
        NSLog(@"track to play: %@", trackURIString);
    }];
    [self.player setIsPlaying:playing callback:nil];

}






#pragma mark - Track Player Delegates

- (void)audioStreaming:(SPTAudioStreamingController *)audioStreaming didReceiveMessage:(NSString *)message {
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Message from Spotify"
                                                        message:message
                                                       delegate:nil
                                              cancelButtonTitle:@"OK"
                                              otherButtonTitles:nil];
    [alertView show];
}

- (void)audioStreaming:(SPTAudioStreamingController *)audioStreaming didFailToPlayTrack:(NSURL *)trackUri {
    NSLog(@"failed to play track: %@", trackUri);
}

- (void) audioStreaming:(SPTAudioStreamingController *)audioStreaming didChangeToTrack:(NSDictionary *)trackMetadata {
    NSLog(@"track changed = %@", [trackMetadata valueForKey:SPTAudioStreamingMetadataTrackURI]);
    //[self updateUI];
}

- (void)audioStreaming:(SPTAudioStreamingController *)audioStreaming didChangePlaybackStatus:(BOOL)isPlaying {
    NSLog(@"is playing = %d", isPlaying);
}



@end
