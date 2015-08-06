//
//  PlayerViewController.m
//  QueueUp
//
//  Created by Jay Reynolds on 6/16/15.
//  Copyright (c) 2015 com.reynoldsJay. All rights reserved.
//

#import "Config.h"
#import "PlayerViewController.h"
#import <Spotify/SPTDiskCache.h>
#import "SpotifyPlayer.h"
#import "UIImageView+WebCache.h"
#import "NSString+FontAwesome.h"
#import "SWRevealViewController.h"
#import "ServerAPI.h"

@interface PlayerViewController ()


@property (weak, nonatomic) IBOutlet UILabel *titleLabel;
@property (weak, nonatomic) IBOutlet UILabel *albumLabel;
@property (weak, nonatomic) IBOutlet UILabel *artistLabel;
@property IBOutlet UILabel *playNameLabel;
@property (weak, nonatomic) IBOutlet UIImageView *coverView;
@property (weak, nonatomic) IBOutlet UIButton *playpause;
@property (weak, nonatomic) IBOutlet UIButton *nextTrack;

@property IBOutlet UITableView *queueView;


@end

@implementation PlayerViewController {
    SpotifyPlayer *player;
    NSArray *queue;
    ServerAPI *api;
}

-(void)viewDidLoad {
    [super viewDidLoad];
    
    api = [ServerAPI getInstance];
    
    if (api.currentPlaylist) {
        self.playNameLabel.text = ((NSDictionary *)api.currentPlaylist)[@"name"];
    } else {
        self.playNameLabel.text = @"";
    }
    
    
    self.titleLabel.text = @"Nothing Playing";
    self.albumLabel.text = @"";
    self.artistLabel.text = @"";
    
    [self.playpause.titleLabel setFont:[UIFont fontWithName:@"FontAwesome" size:30]];
    [self.playpause setTitle:[NSString awesomeIcon:FaPlay] forState:UIControlStateNormal];
    
    [self.nextTrack.titleLabel setFont:[UIFont fontWithName:@"FontAwesome" size:30]];
    [self.nextTrack setTitle:[NSString awesomeIcon:FaFastForward] forState:UIControlStateNormal];
    
    SWRevealViewController *revealViewController = self.revealViewController;
    if ( revealViewController )
    {
        
        [self.sidebarButton setTarget: self.revealViewController];
        [self.sidebarButton setAction: @selector( revealToggle: )];
        [self.view addGestureRecognizer:self.revealViewController.panGestureRecognizer];
    }
    
    
}





-(void)updateUI {
    
    NSDictionary *track = player.curTrack;
        
    self.titleLabel.text = track[@"name"];
    self.artistLabel.text = [(NSArray*) track[@"artists"] firstObject][@"name"];
    self.albumLabel.text = track[@"album"][@"name"];
    NSString *coverURL = [(NSArray *)track[@"album"][@"images"] firstObject][@"url"];
    [self.coverView sd_setImageWithURL:[NSURL URLWithString:coverURL]
                      placeholderImage:[UIImage imageNamed:@"albumShade.png"]];
    
    queue = player.queue;
    //NSLog(@"%@", queue);
    [self.queueView reloadData];
    
    if (player.playing) {
        [self.playpause setTitle:[NSString awesomeIcon:FaPause] forState:UIControlStateNormal];
    } else {
        [self.playpause setTitle:[NSString awesomeIcon:FaPlay] forState:UIControlStateNormal];
    }
    
}




- (IBAction)play_pause:(id)sender {
    [player playPause];
}

- (IBAction)next:(id)sender {
    [player nextTrack];
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
    button.frame = CGRectMake(280.0f, 1.0f, 35.0f, 35.0f);
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





- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    player = [SpotifyPlayer getInstance];
    [player handleNewSession:self];
}


@end