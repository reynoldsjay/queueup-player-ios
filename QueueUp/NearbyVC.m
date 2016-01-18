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
    
}

- (void)viewDidLoad {
    
    [super viewDidLoad];
    // get api object
    api = [ServerAPI getInstance];
    [self startStandardUpdates];
    
    
    
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
        
        NSString *toSend = [[NSString alloc] initWithFormat:@"{\"location\" : {\"latitude\" : \"%.6f\", \"longitude\" : \"%.6f\"}}", location.coordinate.latitude,
                            location.coordinate.longitude];
        id jsonLocation = [api parseJson:toSend];
        NSString *postURL = [NSString stringWithFormat:@"/api/v2/playlists/nearby"];
        NSLog(@"post: %@ to %@", jsonLocation, postURL);
        NSString *playlistString = [api postData:jsonLocation toURL:postURL];
        NSLog(playlistString);
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
        
        
        
    }
}















@end