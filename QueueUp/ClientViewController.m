//
//  PlayerViewController.m
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


@property IBOutlet UITableView *queueView;

@end

@implementation ClientViewController {

    AppDelegate *appDelegate;
    NSString *currentURI;
    ServerAPI *api;
    NSArray *queue;
    
}

- (void)viewDidLoad {
    
    [super viewDidLoad];
    
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
                NSDictionary *track = dictionaryStateData[@"track"];
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
                    [self.queueView reloadData];
                }
                
            }];
            
            
        }];
    
    }
}



- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
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
    [button.titleLabel setFont:[UIFont fontWithName:@"FontAwesome" size:30]];
    [button setTitle:[NSString awesomeIcon:FaArrowUp] forState:UIControlStateNormal];
    button.frame = CGRectMake(280.0f, 9.0f, 35.0f, 35.0f);
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
    
    
    
    NSString *toSend = [[NSString alloc] initWithFormat:@"{\"user_id\" : \"%@\", \"client_token\" : \"%@\", \"track_id\" : \"%@\", \"vote\" : \"%@\"}", clientID, token, trackid, strVote];
    
    id jsonVote = [api parseJson:toSend];
    
    NSString *postVoteURL = [NSString stringWithFormat:@"%@/api/playlists/%@/vote", @hostDomain, (api.currentPlaylist)[@"_id"]];
    
    NSLog(@"post: %@ to %@", jsonVote, postVoteURL);
    
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
