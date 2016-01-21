//
//  ClientViewController.m
//  QueueUp
//
//  Created by Jay Reynolds on 3/23/15.
//  Copyright (c) 2015 com.reynoldsJay. All rights reserved.
//

#import "Config.h"
#import "ClientViewController.h"
#import <SIOSocket/SIOSocket.h>
#import "AppDelegate.h"
#import "SWRevealViewController.h"
#import "ServerAPI.h"
#import "NSString+FontAwesome.h"
#import "UIImageView+WebCache.h"


@interface ClientViewController ()

@property SIOSocket *socket;
@property BOOL socketIsConnected;


@property (weak, nonatomic) IBOutlet UILabel *titleLabel;
@property (weak, nonatomic) IBOutlet UILabel *albumLabel;
@property (weak, nonatomic) IBOutlet UILabel *artistLabel;

@property (weak, nonatomic) IBOutlet UIImageView *coverView;

@property IBOutlet UIButton *playHere;

@property IBOutlet UILabel *playNameLabel;


@property IBOutlet UITableView *queueView;

@end

@implementation ClientViewController {

    AppDelegate *appDelegate;
    NSString *currentURI;
    ServerAPI *api;
    NSArray *queue;
    
    
}

@synthesize playing;


- (void)viewWillAppear:(BOOL)animated {
    
    if (api.hosting) {
//        NSLog(@"go to player");
        [self performSegueWithIdentifier:@"realPlayer" sender:self];
    }
//    NSLog(@"hosting: %hhd", api.hosting);
    

    
}


- (void)viewDidLoad {
    
    [super viewDidLoad];
    
//    Player *sptPlayer = [[Player alloc] init];
//    
//    SPTAuth *auth = [SPTAuth defaultInstance];
//    
//    // Check if we have a token at all
//    if (auth.session != nil && [auth.session isValid]) {
//        [sptPlayer handleNewSession];
//    }
    
    

    
    
    // get api instance
    api = [ServerAPI getInstance];
    
    
    
    
    if (api.currentPlaylist) {
        self.playNameLabel.text = ((NSDictionary *)api.currentPlaylist)[@"name"];
    } else {
        self.playNameLabel.text = @"";
    }
    
    
    NSString *me = ((NSDictionary *)api.idAndToken)[@"user_id"];
    NSString *admin = ((NSDictionary *)api.currentPlaylist)[@"admin"];
    if (![me isEqualToString:admin]) {
//        NSLog(@"not admin");
        self.playHere.hidden = YES;
    }

    
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
            
            

            [self.socket on: @"state_change" callback: ^(SIOParameterArray *args) {
                
                NSMutableDictionary *dictionaryStateData = [args firstObject];
                //NSLog(@"%@", dictionaryStateData);
                
                
                // update current track
                if (dictionaryStateData) {
                    NSDictionary *track = dictionaryStateData[@"track"];
                    if (track != [NSNull null]) {
                        NSString *trackURI = track[@"uri"];
                        if (![currentURI isEqualToString:trackURI] && trackURI != nil) {
                            //[self playSong:trackURI];
                            NSLog(@"New song.");
                            currentURI = trackURI;
                            
                            
                            self.titleLabel.text = track[@"name"];
                            self.artistLabel.text = [(NSArray*) track[@"artists"] firstObject][@"name"];
                            self.albumLabel.text = track[@"album"][@"name"];
                            NSString *coverURL = [(NSArray *)track[@"album"][@"images"] firstObject][@"url"];
                            [self.coverView sd_setImageWithURL:[NSURL URLWithString:coverURL]
                                          placeholderImage:[UIImage imageNamed:@"albumShade.png"]];
                            
                        }
                    }
                }



                
                // update play state, does the client view show this?
//                if (dictionaryStateData[@"play"] != nil) {
//                    BOOL playState = [dictionaryStateData[@"play"] boolValue];
//                    [self.player setIsPlaying:playState callback:nil];
//                    if (playState) {
//                        //self.playpause.image = [UIImage imageNamed:@"pause.png"];
//                    } else {
//                        //self.playpause.image = [UIImage imageNamed:@"play.png"];
//                    }
//                }
                
                
                // update queue
                NSDictionary *recQ = dictionaryStateData[@"queue"];
                if (recQ != nil) {
                    queue = (NSArray *) recQ;
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [self.queueView reloadData];
                    });
                }
                
            }];
            
            
        }];
    
    }
}



- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


- (void)viewWillDisappear:(BOOL)animated {

    [self.socket emit: @"client_unsubscribe" args:nil];

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
    UILabel *qArtistLabel = (UILabel *)[cell viewWithTag:11];
    qArtistLabel.text = [(NSArray *)qTrack[@"artists"] firstObject][@"name"];
    
    UILabel *votesLabel = (UILabel *)[cell viewWithTag:12];
    int votes = [qItem[@"votes"] intValue];
    if (!votes) {
        votesLabel.text = @"0";
    } else {
        votesLabel.text = [NSString stringWithFormat:@"%d", votes];
    }
    
    
    // table cell album over
    UIImageView *albumcover = (UIImageView *)[cell viewWithTag:20];
    NSArray *coverImURLs = qTrack[@"album"][@"images"];
    NSString *coverURL = [coverImURLs firstObject][@"url"];
    [albumcover sd_setImageWithURL:[NSURL URLWithString:coverURL]
               placeholderImage:[UIImage imageNamed:@""]];
    
    
    // create upvote button
    UIButton *button = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    [button addTarget:self action:@selector(voteButtonPress:)
     forControlEvents:UIControlEventTouchDown];
    [button.titleLabel setFont:[UIFont fontWithName:@"FontAwesome" size:20]];
    [button setTitle:[NSString awesomeIcon:FaChevronUp] forState:UIControlStateNormal];
    [button setTitleColor:[UIColor grayColor] forState:UIControlStateNormal];
    button.frame = CGRectMake(self.view.frame.size.width - 40, 0.0f, 35.0f, 35.0f);
    //[button.layer setBorderColor:[[UIColor redColor] CGColor]];
    //[[button layer] setBorderWidth:2.0f];
    [cell addSubview:button];
    
    
    
    NSString *userID = ((NSDictionary*)api.idAndToken)[@"user_id"];
    NSArray *voters = qItem[@"voters"];
    bool userVoted = false;
    for (NSDictionary *aVoter in voters) {
        if ([aVoter[@"_id"] isEqualToString:userID]) {
            userVoted = true;
        }
    }
    
    if (userVoted) {
        [button setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    } else {
        [button setTitleColor:[UIColor grayColor] forState:UIControlStateNormal];
    }
    
    
    
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
    
    //UIImageView *upvote = (UIImageView *)[owningCell viewWithTag:40];
    //NSLog(@"%hhd", [upvote.image isEqual:[UIImage imageNamed:@"upvote.png"]]);
    
    
    NSNumber *strVote;
    NSDictionary *qItem = (NSDictionary *) [queue objectAtIndex:pathToCell.row];
    NSString *trackid = qItem[@"_id"];
    NSLog(@"%@", trackid);
    
    
    NSString *clientID = ((NSDictionary*)api.idAndToken)[@"user_id"];
    NSString *token = ((NSDictionary*)api.idAndToken)[@"client_token"];
    
    NSString *userID = ((NSDictionary*)api.idAndToken)[@"user_id"];
    NSArray *voters = qItem[@"voters"];
    bool userVoted = false;
    for (NSDictionary *aVoter in voters) {
        if ([aVoter[@"_id"] isEqualToString:userID]) {
            userVoted = true;
        }
    }
    
    if (userVoted) {
        strVote = [NSNumber numberWithBool:NO];
    } else {
        strVote = [NSNumber numberWithBool:YES];
    }
    
    
    
    NSString *toSend = [[NSString alloc] initWithFormat:@"{\"vote\" : %@, \"user_id\" : \"%@\", \"client_token\" : \"%@\", \"track_id\" : \"%@\"}", strVote, clientID, token, trackid];
    
    id jsonVote = [api parseJson:toSend];
    
    NSString *postVoteURL = [NSString stringWithFormat:@"/api/v2/playlists/%@/vote", (api.currentPlaylist)[@"_id"]];
    
    NSLog(@"post: %@ to %@", jsonVote, postVoteURL);
    
    
    
    NSString *response = [api postData:jsonVote toURL:postVoteURL];
    id jsonNewPlaylist = [api parseJson:response];
    queue = (NSArray *) jsonNewPlaylist[@"playlist"][@"tracks"];
    //NSLog(@"New queu: %@", queue);
    
    if (queue) {
        NSLog(@"newq");
        [self.queueView reloadData];
    }
    
    
    NSLog(@"Pressed: %ld", (long)pathToCell.row);
    
}




-(IBAction)clickedNowPlaying :(id)sender {
    UIAlertView *message = [[UIAlertView alloc] initWithTitle:@"Open in Spotify?"
                                                      message:nil
                                                     delegate:self
                                            cancelButtonTitle:@"Cancel"
                                            otherButtonTitles:@"Yes", nil];
    message.tag = 9999;
    [message setAlertViewStyle:UIAlertViewStyleDefault];
    [message show];
}


- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:NO];
    UIAlertView *message = [[UIAlertView alloc] initWithTitle:@"Open in Spotify?"
                                                      message:nil
                                                     delegate:self
                                            cancelButtonTitle:@"Cancel"
                                            otherButtonTitles:@"Yes", nil];
    message.tag = indexPath.row;
    [message setAlertViewStyle:UIAlertViewStyleDefault];
    [message show];
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    
    if (buttonIndex == 1) {
        
        if (alertView.tag == 9999) {
            NSString *link = [@"http://open.spotify.com/track/" stringByAppendingString:[currentURI substringFromIndex:14]];
            [[UIApplication sharedApplication] openURL:[NSURL URLWithString:link]];
            
        } else {
        
            NSDictionary *qItem = (NSDictionary *)[queue objectAtIndex:alertView.tag];
            NSString *qTrack = qItem[@"track"][@"uri"];
            
            NSString *link = [@"http://open.spotify.com/track/" stringByAppendingString:[qTrack substringFromIndex:14]];
            [[UIApplication sharedApplication] openURL:[NSURL URLWithString:link]];
        }
        
    }
    
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
