//
//  AbstractPlaylistView.h
//  QueueUp
//
//  Created by Jay Reynolds on 12/20/15.
//  Copyright © 2015 com.reynoldsJay. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "AppDelegate.h"
#import "SWRevealViewController.h"
#import "ServerAPI.h"
#import "Config.h"
#import "UIImageView+WebCache.h"
#import "SpotifyPlayer.h"
#import "LocationGetter.h"
#import "LocationManager.h"

@interface AbstractPlaylistView : UIViewController <UICollectionViewDelegate, UICollectionViewDataSource, LocationGetter> {
    NSMutableArray *playlists;
    NSMutableArray *creators;
    ServerAPI *api;
    double lattitude;
    double longitude;
    LocationManager *lManager;
}

@property (weak, nonatomic) IBOutlet UIBarButtonItem *sidebarButton;
@property IBOutlet UICollectionView *collectionView;



@end