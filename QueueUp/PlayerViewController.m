//
//  PlayerViewController.m
//  QueueUp
//
//  Created by Jay Reynolds on 3/23/15.
//  Copyright (c) 2015 com.reynoldsJay. All rights reserved.
//

#import "Config.h"
#import "PlayerViewController.h"
#import <SIOSocket/SIOSocket.h>
#import "AppDelegate.h"
#import "SWRevealViewController.h"
#import "ServerAPI.h"

@interface PlayerViewController () <SPTAudioStreamingDelegate>

@property SIOSocket *socket;
@property BOOL socketIsConnected;
@property BOOL serverPlay;


@property (weak, nonatomic) IBOutlet UILabel *titleLabel;
@property (weak, nonatomic) IBOutlet UILabel *albumLabel;
@property (weak, nonatomic) IBOutlet UILabel *artistLabel;
@property (weak, nonatomic) IBOutlet UIImageView *coverView;
@property (weak, nonatomic) IBOutlet UIImageView *coverView2;
@property (weak, nonatomic) IBOutlet UIImageView *playpause;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *spinner;

@property IBOutlet UITableView *queue;

@property (nonatomic, strong) SPTSession *session;
@property (nonatomic, strong) SPTAudioStreamingController *player;

@end

@implementation PlayerViewController {

    AppDelegate *appDelegate;
    Playlist *currentPlaylist;
    NSString *currentURI;
    ServerAPI *api;
    NSArray *tracks;
    
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.playpause.image = [UIImage imageNamed:@"play.png"];
    // get api instance
    api = [ServerAPI getInstance];
    SWRevealViewController *revealViewController = self.revealViewController;
    
    // side bar set up
    if ( revealViewController )
    {
        [self.sidebarButton setTarget: self.revealViewController];
        [self.sidebarButton setAction: @selector( revealToggle: )];
        [self.view addGestureRecognizer:self.revealViewController.panGestureRecognizer];
    }
    
    
    self.titleLabel.text = @"Nothing Playing";
    self.albumLabel.text = @"";
    self.artistLabel.text = @"";
    
    appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    currentPlaylist = appDelegate.currentPlaylist;
    
    self.session = appDelegate.session;
    [self handleNewSession:self.session];
    
    [SIOSocket socketWithHost: @hostDomain response: ^(SIOSocket *socket) {
        self.socket = socket;
        
        __weak typeof(self) weakSelf = self;
        __weak typeof(api) weakapi = api;
        
        // on connecting to socket
        self.socket.onConnect = ^()
        {
            weakSelf.socketIsConnected = YES;
            NSLog(@"Connected.");
            [weakSelf.socket emit: @"auth" args: [[NSArray alloc] initWithObjects:weakapi.idAndEmail, nil]];
        };
        
        [self.socket on: @"auth_response" callback: ^(SIOParameterArray *args)
                 {
                     NSLog(@"RESPONSE");
                     if ([args firstObject] == nil) {
                         NSLog(@"Server responded to auth request.");
                         id json = [api parseJson:[[NSString alloc] initWithFormat:@"{\"playlist_id\" : \"%@\"}", currentPlaylist.playID]];
                         [self.socket emit: @"client_subscribe" args: [[NSArray alloc] initWithObjects:json, nil]];
                     } else {
                         NSLog(@"%@", [args firstObject]);
                     }
                     
                     
                 }];
        
        // OLD PLAYLIST SUB API
        
//        [self.socket on: @"auth_request" callback: ^(SIOParameterArray *args)
//        {
//            NSLog(@"Request auth");
//            id json = [api parseJson:[[NSString alloc] initWithFormat:@"{\"id\" : \"%@\"}", currentPlaylist.playID]];
//            [self.socket emit: @"auth_send" args: [[NSArray alloc] initWithObjects:json, nil]];
//            
//        }];
//        
//        [self.socket on: @"auth_success" callback: ^(SIOParameterArray *args) {
//            NSLog(@"Authenticated!");
//            NSMutableDictionary *dictionaryStateData = [args firstObject];
//            _serverPlay = [dictionaryStateData[@"play"] boolValue];
//            [self.player setIsPlaying:_serverPlay callback:nil];
//            
//        }];
//        
//        [self.socket on: @"auth_fail" callback: ^(SIOParameterArray *args) {
//             NSLog(@"Authentication failed.");
//        }];
        
        [self.socket on: @"state_change" callback: ^(SIOParameterArray *args) {
            
            NSMutableDictionary *dictionaryStateData = [args firstObject];
            
            
            @try {
                if (dictionaryStateData[@"play"] != nil) {
                    _serverPlay = [dictionaryStateData[@"play"] boolValue];
                    [self.player setIsPlaying:_serverPlay callback:nil];
                }
            }
            @catch (NSException *exception) {
            }
            @finally {
            }
            
            @try {
                NSDictionary *track = dictionaryStateData[@"track"];
                NSString *trackURI = track[@"uri"];
                if (![currentURI isEqualToString:trackURI] && _serverPlay && trackURI != nil) {
                    [self playSong:trackURI];
                    NSLog(@"New song.");
                    currentURI = trackURI;
                }
                [self.spinner startAnimating];
                [NSThread sleepForTimeInterval:1.0f];
                [self updateUI];
            }
            @catch (NSException *exception) {
            }
            @finally {
            }
            
            
        }];
        
        
    }];
    
    
}


-(void) playSong:(NSString*)trackURI {

    // Create a new player if needed
    if (self.player == nil) {
        self.player = [[SPTAudioStreamingController alloc] initWithClientId:@kClientId];
    }

    [self.player loginWithSession:self.session callback:^(NSError *error) {

        if (error != nil) {
            NSLog(@"*** Enabling playback got error: %@", error);
            return;
        }

        [SPTRequest requestItemAtURI:[NSURL URLWithString:trackURI]
                         withSession:nil
                            callback:^(NSError *error, SPTTrack *track) {

                                if (error != nil) {
                                    NSLog(@"*** Album lookup got error %@", error);
                                    return;
                                }
                                [self.player playTrackProvider:track callback:nil];

                            }];
    }];
    
    //[self updateUI];

}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}




#pragma mark - Actions

-(IBAction)rewind:(id)sender {
    [self.player skipPrevious:nil];
}

-(IBAction)playPause:(id)sender {
    //[self.player setIsPlaying:!self.player.isPlaying callback:nil];
    NSLog(@"%d", self.player.isPlaying);
    NSString *toSend;
    if (self.player.isPlaying) {
        toSend = @"false";
        self.playpause.image = [UIImage imageNamed:@"play.png"];
    } else {
        toSend = @"true";
        self.playpause.image = [UIImage imageNamed:@"pause.png"];
    }
    NSLog(@"playing now %@", toSend);
    NSData *jsonData = [[[NSString alloc] initWithFormat:@"{\"playing\" : %@}", toSend] dataUsingEncoding:NSUTF8StringEncoding];
    id json = [NSJSONSerialization JSONObjectWithData:jsonData options:0 error:nil];
    [self.socket emit: @"client_play_pause" args:[[NSArray alloc] initWithObjects:json, nil]];
}


-(IBAction)fastForward:(id)sender {
    [self.player skipNext:nil];
}

#pragma mark - Logic

-(void)updateUI {
    if (self.player.currentTrackMetadata == nil) {
        self.titleLabel.text = @"Nothing Playing";
        self.albumLabel.text = @"";
        self.artistLabel.text = @"";
    } else {
        self.titleLabel.text = [self.player.currentTrackMetadata valueForKey:SPTAudioStreamingMetadataTrackName];
        self.albumLabel.text = [self.player.currentTrackMetadata valueForKey:SPTAudioStreamingMetadataAlbumName];
        self.artistLabel.text = [self.player.currentTrackMetadata valueForKey:SPTAudioStreamingMetadataArtistName];
    }
    [self updateCoverArt];
}

-(void)updateCoverArt {
    if (self.player.currentTrackMetadata == nil) {
        self.coverView.image = nil;
        return;
    }
    
    
    [SPTAlbum albumWithURI:[NSURL URLWithString:[self.player.currentTrackMetadata valueForKey:SPTAudioStreamingMetadataAlbumURI]]
                   session:self.session
                  callback:^(NSError *error, SPTAlbum *album) {
                      
                      NSURL *imageURL = album.largestCover.imageURL;
                      if (imageURL == nil) {
                          NSLog(@"Album %@ doesn't have any images!", album);
                          self.coverView.image = nil;
                          return;
                      }
                      
                      // Pop over to a background queue to load the image over the network.
                      dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                          NSError *error = nil;
                          UIImage *image = nil;
                          NSData *imageData = [NSData dataWithContentsOfURL:imageURL options:0 error:&error];
                          
                          if (imageData != nil) {
                              image = [UIImage imageWithData:imageData];
                          }
                          
                          // …and back to the main queue to display the image.
                          dispatch_async(dispatch_get_main_queue(), ^{
                              [self.spinner stopAnimating];
                              self.coverView.image = image;
                              if (image == nil) {
                                  NSLog(@"Couldn't load cover image with error: %@", error);
                              }
                          });
                      });
                  }];
}


-(void)handleNewSession:(SPTSession *)session {
    
    self.session = session;
    
    if (self.player == nil) {
        self.player = [[SPTAudioStreamingController alloc] initWithClientId:@kClientId];
        self.player.playbackDelegate = self;
    }
    
    [self.player loginWithSession:session callback:^(NSError *error) {
        
        if (error != nil) {
            NSLog(@"*** Enabling playback got error: %@", error);
            return;
        }
        
        
    }];
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

- (void) audioStreaming:(SPTAudioStreamingController *)audioStreaming didChangeToTrack:(NSDictionary *)trackMetadata {
    NSLog(@"changed track");
    if (trackMetadata == nil) {
        NSLog(@"Track ended.");
        [self.socket emit: @"track_finished" args:nil];
    }
    [self updateUI];
}




// table view methods


//- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
//{
//    return [wlitems count];
//}
//
//- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
//{
//    static NSString *simpleTableIdentifier = @"cell";
//    
//    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:simpleTableIdentifier];
//    
//    if (cell == nil) {
//        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:simpleTableIdentifier];
//    }
//    
//    [[wlitems objectAtIndex:indexPath.row] fetchIfNeededInBackgroundWithBlock:^(PFObject *object, NSError *error) {
//        cell.textLabel.text = object[@"name"];
//    }];
//    
//    return cell;
//}
//
//
//
//- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
//{
//    [tableView deselectRowAtIndexPath:indexPath animated:NO];
//    [[wlitems objectAtIndex:indexPath.row] fetchIfNeededInBackgroundWithBlock:^(PFObject *object, NSError *error) {
//        
//        NSString *text = [NSString stringWithFormat:@"Price: %@",
//                          ((PFUser*)object)[@"price"]];
//        
//        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:object[@"name"]
//                                                        message:text
//                                                       delegate:nil
//                                              cancelButtonTitle:@"OK"
//                                              otherButtonTitles:nil];
//        [alert show];
//    }];
//    
//    
//}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
