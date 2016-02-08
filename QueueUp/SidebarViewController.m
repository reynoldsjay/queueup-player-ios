//
//  SidebarViewController.m
//  SidebarDemo
//
//  Created by Simon on 29/6/13.
//  Copyright (c) 2013 Appcoda. All rights reserved.
//


#import "SidebarViewController.h"
#import "SWRevealViewController.h"
#import <FBSDKCoreKit/FBSDKCoreKit.h>
#import "UIImageView+WebCache.h"
#import "ServerAPI.h"
#import <FBSDKCoreKit/FBSDKCoreKit.h>
#import <FBSDKLoginKit/FBSDKLoginKit.h>
#import "SpotifyPlayer.h"

@interface SidebarViewController ()

@property (nonatomic, strong) NSArray *menuItems;
@end

@implementation SidebarViewController {
    
    NSArray *_menuItems;
    NSString *photoURL;
    ServerAPI *api;
}

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization
    }
//    api = [ServerAPI getInstance];
    return self;
}

- (void)viewDidLoad
{
    api = [ServerAPI getInstance];
    _menuItems = @[@"user", @"nowplaying", @"nearby", @"playlists", @"yourplaylists", @"friendsplaylists", @"logo"];
    [self.tableView reloadData];
    [super viewDidLoad];

}



- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // Return the number of sections.
    // hide extra cells
    tableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // Return the number of rows in the section.
    return _menuItems.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSString *CellIdentifier = [_menuItems objectAtIndex:indexPath.row];
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
    
    // add profile picture
    if (indexPath.row == 0) {
        UIImageView *profilePicture = (UIImageView *)[cell viewWithTag:5];
        UIButton *logout = (UIButton *)[cell viewWithTag:111];
        [logout addTarget:self action:@selector(clickedLogout:) forControlEvents:UIControlEventTouchDown];
        UIButton *login = (UIButton *)[cell viewWithTag:112];
        UILabel *fbName = (UILabel *)[cell viewWithTag:10];
        if (!photoURL) {
            if ([FBSDKAccessToken currentAccessToken]) {
                profilePicture.hidden = NO;
                [[[FBSDKGraphRequest alloc] initWithGraphPath:@"me" parameters:@{@"fields": @"name, picture.type(large)"}]
                 startWithCompletionHandler:^(FBSDKGraphRequestConnection *connection, id result, NSError *error) {
                     if (!error) {
                         fbName.text = result[@"name"];
                         photoURL = result[@"picture"][@"data"][@"url"];
                         [profilePicture sd_setImageWithURL:[NSURL URLWithString:photoURL]
                                           placeholderImage:[UIImage imageNamed:@""]];
                     }
                 }];
            }
        }
        if ([FBSDKAccessToken currentAccessToken] == nil && api.loggedIn) {
//            NSLog(@"HITDABLOCK");
            NSString *clientID = ((NSDictionary*)api.idAndToken)[@"user_id"];
            NSString *url = [NSString stringWithFormat:@"/api/v2/users/%@", clientID];
            NSString *userString = [api getDataFromURL:url];
//            NSLog(userString);
            NSMutableDictionary *dictionaryData = (NSMutableDictionary*) [api parseJson:userString];
            NSString *name = dictionaryData[@"user"][@"name"];
            fbName.text = name;
            profilePicture.hidden = NO;
            profilePicture.image = [UIImage imageNamed:@"alphaLogo.png"];
            
            
        }
        
        if (!api.loggedIn) {
            profilePicture.hidden = YES;
            fbName.hidden = YES;
            logout.hidden = YES;
            logout.enabled = NO;
            login.hidden = NO;
            login.enabled = YES;
            
        } else {

            fbName.hidden = NO;
            logout.hidden = NO;
            logout.enabled = YES;
            login.hidden = YES;
            login.enabled = NO;
        }
        
    }
    
    return cell;
}

- (void)clickedLogout:(id)sender {
    if (api.hosting) {
        api.hosting = NO;
        SpotifyPlayer *curPlayer = [SpotifyPlayer getInstance];
        if (curPlayer.playing) {
            [curPlayer playPause];
        }
    }
    
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    api.loggedIn = NO;
    NSString *strUniqueIdentifier = [userDefaults valueForKey:@"uuid"];
    NSString *toPost = [[NSString alloc] initWithFormat:@"{\"device\" : {\"id\" : \"%@\"}}", strUniqueIdentifier];
    id json = [api parseJson:toPost];
    NSString *userInfo = [api postData:json toURL:(@"/api/v2/auth/init")];
    NSString *theID = ((NSDictionary*)[api parseJson:userInfo])[@"user_id"];
    NSString *token = ((NSDictionary*)[api parseJson:userInfo])[@"client_token"];
    NSString *combine = [[NSString alloc] initWithFormat:@"{\"user_id\":\"%@\", \"client_token\":\"%@\"}", theID, token];
    id combinedInfo = [api parseJson:combine];
    api.idAndToken = combinedInfo;
    [userDefaults setBool:NO forKey:@"loggedIn"];
    [userDefaults setObject:combinedInfo forKey:@"user_info"];
    [FBSDKAccessToken setCurrentAccessToken:nil];
    [FBSDKProfile setCurrentProfile:nil];
    [self viewDidLoad];
    [self performSegueWithIdentifier:@"toTrending" sender:self];
    
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    // top cell is bigger
    if(indexPath.row == 0) {
        if (api.loggedIn) {
            return 80.0;
        } else {
            return 80.0;
        }
    } else {
        return 57.0f;
    }
}



- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(nonnull NSIndexPath *)indexPath {
    if (indexPath.row == 1) {
        if (api.hosting) {
            //        NSLog(@"go to player");
            [self performSegueWithIdentifier:@"realPlayer" sender:self];
        } else {
            [self performSegueWithIdentifier:@"toClient" sender:self];
        }
    }
}

@end
