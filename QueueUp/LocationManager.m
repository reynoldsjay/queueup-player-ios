//
//  LocationManager.m
//  QueueUp
//
//  Created by Jay Reynolds on 2/7/16.
//  Copyright © 2016 com.reynoldsJay. All rights reserved.
//

#import "LocationManager.h"
#import <UIKit/UIKit.h>
#import "AbstractPlaylistView.h"

@implementation LocationManager {
    AbstractPlaylistView *caller;
}


static LocationManager *singletonInstance;

+ (LocationManager*)getInstance {
    if (singletonInstance == nil) {
        singletonInstance = [[super alloc] init];
    }
    return singletonInstance;
}

- (void)getALocation:(id)sender
{
    // Create the location manager if this object does not
    // already have one.
    if (nil == locationManager)
        locationManager = [[CLLocationManager alloc] init];
    
    locationManager.delegate = self;
    locationManager.desiredAccuracy = kCLLocationAccuracyKilometer;
    
    caller = sender;
    
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
        //        NSLog(@"latitude %+.6f, longitude %+.6f\n",
        //              location.coordinate.latitude,
        //              location.coordinate.longitude);
        _lattitude = location.coordinate.latitude;
        _longitude = location.coordinate.longitude;
        [locationManager stopUpdatingLocation];
        [caller locationCallback];
        
    }
}

- (void)locationManager:(CLLocationManager *)manager
       didFailWithError:(NSError *)error {
    
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Enable location services for QueueUp in settings to see nearby playlists."
                                                    message:@""
                                                   delegate:nil
                                          cancelButtonTitle:@"OK"
                                          otherButtonTitles:nil];
    [alert show];
    
}


@end
