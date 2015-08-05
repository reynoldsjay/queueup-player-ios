//
//  AddTrackVC.m
//  QueueUp
//
//  Created by Jay Reynolds on 7/19/15.
//  Copyright (c) 2015 com.reynoldsJay. All rights reserved.
//

#import "AddTrackVC.h"
#import "ServerAPI.h"
#import "UIImageView+WebCache.h"

@interface AddTrackVC ()

@property IBOutlet UITableView *trackTable;
@property IBOutlet UISearchBar *search;

@end

@implementation AddTrackVC {
    ServerAPI *api;
    NSArray *tracks;
    NSString *toSearch;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do view setup here.
    api = [ServerAPI getInstance];
}


- (void) viewDidAppear:(BOOL)animated {
    [self.search becomeFirstResponder];
}


- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText {
    
    toSearch = searchText;
    NSLog(@"Timer=%@",myTimer);
    if (myTimer)
    {
        if ([myTimer isValid])
        {
            [myTimer invalidate];
        }
        myTimer=nil;
    }
    myTimer = [NSTimer scheduledTimerWithTimeInterval:0.5 target:self selector:@selector(onTextChange:) userInfo:nil repeats:NO];
    

}


-(void)onTextChange:(id)sender {
    toSearch = [toSearch stringByReplacingOccurrencesOfString:@" " withString:@"+"];
    NSString *searchURL = [NSString stringWithFormat:@"/api/v2/search/tracks/%@/0", toSearch];
    NSDictionary *dict = (NSDictionary *) [api parseJson:[api getDataFromURL:searchURL]];
    tracks = (NSArray *) dict[@"tracks"];
    [self.trackTable reloadData];
}

// table view methods

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [tracks count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *simpleTableIdentifier = @"cell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:simpleTableIdentifier forIndexPath:indexPath];
    
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:simpleTableIdentifier];
    }
    
    // table cell track name
    NSDictionary *qTrack = (NSDictionary *)[tracks objectAtIndex:indexPath.row];
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
    
    
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSString *trackid = ((NSDictionary *)[tracks objectAtIndex:indexPath.row])[@"id"];
    NSString *toSend = [[NSString alloc] initWithFormat:@"{\"track_id\" : \"%@\"}", trackid];
    id jsonVote = [api parseJson:toSend];
    
    NSString *postVoteURL = [NSString stringWithFormat:@"/api/v2/playlists/%@/add", (api.currentPlaylist)[@"_id"]];
    
    NSLog(@"post: %@ to %@", jsonVote, postVoteURL);
    NSString *response = [api postData:jsonVote toURL:postVoteURL];
    NSLog(@"%@", response);
    [self performSegueWithIdentifier:@"back" sender:self];
}



@end
