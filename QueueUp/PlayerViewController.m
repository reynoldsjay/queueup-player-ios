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


@property (weak, nonatomic) IBOutlet UILabel *titleLabel;
@property (weak, nonatomic) IBOutlet UILabel *albumLabel;
@property (weak, nonatomic) IBOutlet UILabel *artistLabel;


@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *spinner;
@property (weak, nonatomic) IBOutlet UIImageView *coverView;
@property (weak, nonatomic) IBOutlet UIImageView *coverView2;


@property (weak, nonatomic) IBOutlet UIImageView *playpause;

@property IBOutlet UITableView *queueView;


@property (nonatomic, strong) SPTSession *session;
@property (nonatomic, strong) SPTAudioStreamingController *player;

@end

@implementation PlayerViewController {

    AppDelegate *appDelegate;
    NSString *currentURI;
    ServerAPI *api;
    NSArray *queue;
    
}

- (void)viewDidLoad {
    
    [super viewDidLoad];
    
    self.playpause.image = [UIImage imageNamed:@"play.png"];
    
    // get api instance
    api = [ServerAPI getInstance];
    
    // side bar set up
    SWRevealViewController *revealViewController = self.revealViewController;
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
    //currentPlaylist = appDelegate.currentPlaylist;
    
    self.session = appDelegate.session;
    [self handleNewSession:self.session];
    
    
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
                             [self.socket emit: @"client_subscribe" args: [[NSArray alloc] initWithObjects:json, nil]];
                         } else {
                             NSLog(@"%@", [args firstObject]);
                         }
                         
                         
                     }];
            
            
            // CHANGE TO NEW API
            [self.socket on: @"state_change" callback: ^(SIOParameterArray *args) {
                
                NSMutableDictionary *dictionaryStateData = [args firstObject];
                //NSLog(@"%@", dictionaryStateData);
                
                
                // update current track
                NSDictionary *track = dictionaryStateData[@"track"];
                NSString *trackURI = track[@"uri"];
                if (![currentURI isEqualToString:trackURI] && trackURI != nil) {
                    [self playSong:trackURI];
                    NSLog(@"New song.");
                    currentURI = trackURI;
                }
                [self.spinner startAnimating];
                [NSThread sleepForTimeInterval:1.0f];
                [self updateUI];

                
                // update play state
                if (dictionaryStateData[@"play"] != nil) {
                    BOOL playState = [dictionaryStateData[@"play"] boolValue];
                    [self.player setIsPlaying:playState callback:nil];
                    if (playState) {
                        self.playpause.image = [UIImage imageNamed:@"pause.png"];
                    } else {
                        self.playpause.image = [UIImage imageNamed:@"play.png"];
                    }
                }
                
                
                // update queue
                NSDictionary *recQ = dictionaryStateData[@"queue"];
                if (recQ != nil) {
                    queue = (NSArray *) recQ;
                    [self.queueView reloadData];
                }
                
            }];
            
            
        }];
    
    }
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

-(IBAction)playPauseButton:(id)sender {
    //[self.player setIsPlaying:!self.player.isPlaying callback:nil];
    NSLog(@"%d", self.player.isPlaying);
    NSString *toSend;
    if (self.player.isPlaying) {
        toSend = @"false";
    } else {
        toSend = @"true";
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
}




// table view methods

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [queue count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *simpleTableIdentifier = @"cell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:simpleTableIdentifier forIndexPath:indexPath];
    
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:simpleTableIdentifier];
    }
    
    // table cell track name
    NSDictionary *qItem = (NSDictionary *)[queue objectAtIndex:indexPath.row];
    NSDictionary *qTrack = qItem[@"track"];
    UILabel *cellLabel = (UILabel *)[cell viewWithTag:10];
    cellLabel.text = qTrack[@"name"];
    
    
    // table cell album over
    UIImageView *albumcover = (UIImageView *)[cell viewWithTag:20];
    NSArray *coverImURLs = qTrack[@"album"][@"images"];
    NSString *coverURL = [coverImURLs firstObject][@"url"];
    NSData * imageData = [[NSData alloc] initWithContentsOfURL: [NSURL URLWithString:coverURL]];
    albumcover.image = [[UIImageView alloc] initWithImage:[UIImage imageWithData:imageData]].image;
    
    // table cell vote
    UIImageView *upvote = (UIImageView *)[cell viewWithTag:40];
    upvote.image = [UIImage imageNamed:@"upvote.png"];
//    NSLog(@"%d", [upvote.image isEqual:[UIImage imageNamed:@"upvote.png"]]);
    upvote.tintColor = [UIColor redColor];
    
    
    // create upvote button
    UIButton *button = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    [button addTarget:self action:@selector(voteButtonPress:)
     forControlEvents:UIControlEventTouchDown];
    [button setTitle:@"" forState:UIControlStateNormal];
    button.frame = CGRectMake(280.0f, 5.0f, 35.0f, 35.0f);
    //[button.layer setBorderColor:[[UIColor redColor] CGColor]];
    //[[button layer] setBorderWidth:2.0f];
    [cell addSubview:button];
    
    
    
    
    return cell;
}



// upvote button handler

-(void)voteButtonPress :(id)sender
{
    //Get the superview from this button which will be our cell
    UITableViewCell *owningCell = (UITableViewCell*)[sender superview];
    
    //From the cell get its index path.
    //
    //In this example I am only using the indexpath to show a unique message based
    //on the index of the cell.
    //If you were using an array of data to build the table you might use
    //the index here to do something with that array.
    NSIndexPath *pathToCell = [_queueView indexPathForCell:owningCell];
    
    UIImageView *upvote = (UIImageView *)[owningCell viewWithTag:40];
    NSLog(@"%hhd", [upvote.image isEqual:[UIImage imageNamed:@"upvote.png"]]);
    
    
    NSString *strVote;
    NSDictionary *qItem = (NSDictionary *) [queue objectAtIndex:pathToCell.row];
    NSString *trackid = qItem[@"track"][@"id"];
                  
    if ([upvote.image isEqual:[UIImage imageNamed:@"upvote.png"]]) {
        upvote.image = [UIImage imageNamed:@"greenvote.png"];
        strVote = @"true";
        
    } else {
        upvote.image = [UIImage imageNamed:@"upvote.png"];
        strVote = @"false";
    }
    
    NSString *clientID = ((NSDictionary*)api.idAndToken)[@"user_id"];
    NSString *token = ((NSDictionary*)api.idAndToken)[@"client_token"];
    
    
    
    NSString *toSend = [[NSString alloc] initWithFormat:@"{\"client_id\" : \"%@\", \"email\" : \"%@\", \"track_id\" : \"%@\", \"vote\" : \"%@\"}", clientID, token, trackid, strVote];
    
    id jsonVote = [api parseJson:toSend];
    
    NSString *postVoteURL = [NSString stringWithFormat:@"%@/api/playlists/%@/vote", @hostDomain, (api.currentPlaylist)[@"_id"]];
    
    NSLog(@"post: %@ to %@,, %@", toSend, postVoteURL, api.idAndToken);
    
    //[api postData:jsonVote toURL:postVoteURL];
    
    NSLog(@"Pressed: %ld", (long)pathToCell.row);
    
}







- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
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
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
