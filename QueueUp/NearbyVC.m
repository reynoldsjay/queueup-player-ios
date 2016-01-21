//
//  NearbyVC.m
//  QueueUp
//
//  Created by Jay Reynolds on 1/9/16.
//  Copyright © 2016 com.reynoldsJay. All rights reserved.
//

#import "NearbyVC.h"
#import "ServerAPI.h"



@implementation NearbyVC {
    double lattitude;
    double longitude;
}

- (void)viewDidLoad {
    
    [super viewDidLoad];
    // get api object
    api = [ServerAPI getInstance];
    [self startStandardUpdates];
    
    [NSTimer scheduledTimerWithTimeInterval:2.0
                                     target:self
                                   selector:@selector(setPlaylistData:)
                                   userInfo:nil
                                    repeats:NO];

    
    
}


- (void)setPlaylistData:(id)sender {
    NSLog(@"setting playlists for %fl and %fl", lattitude, longitude);
    
    NSString *playlistString = [api getDataFromURL:(@"/api/v2/playlists")];
    
    NSMutableDictionary *dictionaryData = (NSMutableDictionary*) [api parseJson:playlistString];
    playlists = dictionaryData[@"playlists"];
    
    // get the admins names
    creators = [[NSMutableArray alloc] init];
    for (NSMutableDictionary *aPlaylist in playlists) {
        NSString *creatorName = aPlaylist[@"admin_name"];
        if (!creatorName) {
            [creators addObject:@"?"];
        } else {
            [creators addObject:creatorName];
        }
    }
    [self.collectionView reloadData];
    
    
//            NSString *toSend = [[NSString alloc] initWithFormat:@"{\"location\" : {\"latitude\" : %.6f, \"longitude\" : %.6f}}", lat, longi];
//            id jsonLocation = [api parseJson:toSend];
//            NSString *postURL = [NSString stringWithFormat:@"/api/v2/playlists/nearby"];
//            NSString *playlistString = [api postData:jsonLocation toURL:postURL];
//            NSMutableDictionary *dictionaryData = (NSMutableDictionary*) [api parseJson:playlistString];
//            playlists = dictionaryData[@"playlists"];
//    
//    
//    
//    
//            // get the admins names
//            creators = [[NSMutableArray alloc] init];
//            for (NSMutableDictionary *aPlaylist in playlists) {
//                NSString *creatorName = aPlaylist[@"admin_name"];
//                if (!creatorName) {
//                    [creators addObject:@"?"];
//                } else {
//                    [creators addObject:creatorName];
//                }
//            }
//            
//            [self.collectionView reloadData];
}



- (void)startStandardUpdates
{
    // Create the location manager if this object does not
    // already have one.
    if (nil == locationManager)
        locationManager = [[CLLocationManager alloc] init];
    
    locationManager.delegate = self;
    locationManager.desiredAccuracy = kCLLocationAccuracyKilometer;
    
    // Set a movement threshold for new events.
    //locationManager.distanceFilter = 500; // meters
    if ([[[UIDevice currentDevice] systemVersion] floatValue] >= 8.0)
        [locationManager requestWhenInUseAuthorization];
    
    
    [locationManager startUpdatingLocation];
    
}


// Delegate method from the CLLocationManagerDelegate protocol.
- (void)locationManager:(CLLocationManager *)manager
     didUpdateLocations:(NSArray *)locations {
    // If it's a relatively recent event, turn off updates to save power.
    CLLocation* location = [locations lastObject];
    NSDate* eventDate = location.timestamp;
    NSTimeInterval howRecent = [eventDate timeIntervalSinceNow];
    if (fabs(howRecent) < 15.0) {
        // If the event is recent, do something with it.
        NSLog(@"latitude %+.6f, longitude %+.6f\n",
              location.coordinate.latitude,
              location.coordinate.longitude);
        lattitude = location.coordinate.latitude;
        longitude = location.coordinate.longitude;
        
    }
}















@end