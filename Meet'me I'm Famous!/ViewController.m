//
//  ViewController.m
//  Meet'me I'm Famous!
//
//  Created by Rodolphe on 03/05/2015.
//  Copyright (c) 2015 Rodolphe Hugel. All rights reserved.
//

#import "ViewController.h"


#import <Parse/Parse.h>
#import <ParseFacebookUtilsV4/PFFacebookUtils.h>
#import <FBSDKCoreKit/FBSDKCoreKit.h>
#import <FBSDKLoginKit/FBSDKLoginKit.h>
#import <ParseUI/ParseUI.h>
#import <CoreLocation/CoreLocation.h>
#import <MapKit/MapKit.h>
#import <UIKit/UIKit.h>
#import "PAUser.h"



@interface ViewController ()

@property (nonatomic, strong) CLLocationManager *locationManager;
@property (nonatomic, strong) CLLocation *currentLocation;
@property (nonatomic, strong) NSMutableArray  *allUsers;


@property (nonatomic, assign) BOOL mapPinsPlaced;
@property (nonatomic, assign) BOOL mapPannedSinceLocationUpdate;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    if (![PFUser currentUser]) { // No user logged in
        [[self loginButton] setTitle:@"Login" forState:UIControlStateNormal];
 
    }
    else{
        [[self loginButton] setTitle:@"Login" forState:UIControlStateNormal];
        [self userInfoGrab:[PFUser currentUser]];

    }
    
    // Do any additional setup after loading the view, typically from a nib.
   [self startStandardUpdates];
    self.mapView.region = MKCoordinateRegionMake(CLLocationCoordinate2DMake(37.332495f, -122.029095f),
                                                 MKCoordinateSpanMake(0.008516f, 0.021801f));
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    self.profileImage.layer.cornerRadius = self.profileImage.layer.bounds.size.height/2;
    self.profileImage.layer.masksToBounds = YES;
    
    self.profileImage.layer.borderWidth = 2.0f;
    
    self.profileImage.layer.borderColor = [UIColor whiteColor].CGColor;
    [self.locationManager requestAlwaysAuthorization];
    
    if (![PFUser currentUser]) { // No user logged in
         NSLog(@"USer NOT Logged In");
        [[self loginButton] setTitle:@"Login" forState:UIControlStateNormal];
        // Create the log in view controller
            }
    else{
        NSLog(@"USer Logged In");
        [[self loginButton] setTitle:@"Logout" forState:UIControlStateNormal];

    }

    
  }

- (IBAction)loginButtonPressed:(UIButton *)sender
{
    if (![PFUser currentUser]) { // No user logged in
        NSLog(@"USer NOT Logged In");
        [[self loginButton] setTitle:@"Login" forState:UIControlStateNormal];
        // Create the log in view controller
        PFLogInViewController *logInViewController = [[PFLogInViewController alloc] init];
        [logInViewController setDelegate:self]; // Set ourselves as the delegate
        [logInViewController setFacebookPermissions:[NSArray arrayWithObjects:@"public_profile",@"email" ,nil]];
        [logInViewController setFields: PFLogInFieldsDefault| PFLogInFieldsTwitter | PFLogInFieldsFacebook | PFLogInFieldsDismissButton];
        
        // Create the sign up view controller
        PFSignUpViewController *signUpViewController = [[PFSignUpViewController alloc] init];
        [signUpViewController setDelegate:self]; // Set ourselves as the delegate
        
        // Assign our sign up controller to be displayed from the login controller
        [logInViewController setSignUpController:signUpViewController];
        
        // Present the log in view controller
        [self presentViewController:logInViewController animated:YES completion:NULL];

    }
    else{
        NSLog(@"USer Logged In");
        [[self loginButton] setTitle:@"Login" forState:UIControlStateNormal];
         [PFUser logOut];
        [self.profileImage setHidden:TRUE];
        [self.pseudoLabel setHidden:  TRUE];
        
    }
    

    
}


// Sent to the delegate to determine whether the log in request should be submitted to the server.
- (BOOL)logInViewController:(PFLogInViewController *)logInController shouldBeginLogInWithUsername:(NSString *)username password:(NSString *)password {
    // Check if both fields are completed
    if (username && password && username.length != 0 && password.length != 0) {
        return YES; // Begin login process
    }
    
    [[[UIAlertView alloc] initWithTitle:@"Missing Information"
                                message:@"Make sure you fill out all of the information!"
                               delegate:nil
                      cancelButtonTitle:@"ok"
                      otherButtonTitles:nil] show];
    return NO; // Interrupt login process
}


- (void)userInfoGrab:(PFUser*) user{
    
    [[[FBSDKGraphRequest alloc] initWithGraphPath:@"me" parameters:@{@"fields": @"first_name, last_name, picture.type(normal), email"}]
     startWithCompletionHandler:^(FBSDKGraphRequestConnection *connection, id result, NSError *error) {
         if (!error) {
             NSLog(@"fetched user:%@", result);
             [[PFUser currentUser] setObject:[result objectForKey:@"id"] forKey:@"fbid"];
             [[PFUser currentUser] setObject:[result objectForKey:@"first_name"] forKey:@"firstname"];
             [[PFUser currentUser] setObject:[result objectForKey:@"last_name"] forKey:@"lastname"];
             [[PFUser currentUser] setObject:[result objectForKey:@"email"] forKey:@"email"];
             
             PFGeoPoint *point = [PFGeoPoint geoPointWithLatitude:self.currentLocation.coordinate.latitude longitude:self.currentLocation.coordinate.longitude];
             
             [[PFUser currentUser] setObject:point forKey:@"lastPosition"];
             
             
             [[PFUser currentUser] saveInBackground];
             NSURL *pictureURL = [NSURL URLWithString:[[[result objectForKey:@"picture"] objectForKey:@"data"] objectForKey:@"url"]];
             NSString *pseudo = [result objectForKey:@"first_name"];
             self.profileImage.image = [UIImage imageWithData:[NSData dataWithContentsOfURL:pictureURL]];
             self.pseudoLabel.text = pseudo;
             [self.profileImage setHidden:false];
             [self.pseudoLabel setHidden:  false];
             
             // Update the map with new pins:
             [self queryForAllUsersNearLocation:self.currentLocation withNearbyDistance:50];
             // And update the existing pins to reflect any changes in filter distance:
             [self updateUsersForLocation:self.currentLocation withNearbyDistance:50];

            
             // If they panned the map since our last location update, don't recenter it.
             if (!self.mapPannedSinceLocationUpdate) {
                 // Set the map's region centered on their location at 2x filterDistance
                 MKCoordinateRegion newRegion = MKCoordinateRegionMakeWithDistance(self.currentLocation.coordinate, 50 * 2.0f, 50 * 2.0f);
                 
                 [self.mapView setRegion:newRegion animated:YES];
                 self.mapPannedSinceLocationUpdate = NO;
             } else {
                 // Just zoom to the new search radius (or maybe don't even do that?)
                 MKCoordinateRegion currentRegion = self.mapView.region;
                 MKCoordinateRegion newRegion = MKCoordinateRegionMakeWithDistance(currentRegion.center, 50 * 2.0f, 50 * 2.0f);
                 
                 BOOL oldMapPannedValue = self.mapPannedSinceLocationUpdate;
                 [self.mapView setRegion:newRegion animated:YES];
                 self.mapPannedSinceLocationUpdate = oldMapPannedValue;
             }

         }
     }];
    
}

// Sent to the delegate when a PFUser is logged in.
- (void)logInViewController:(PFLogInViewController *)logInController didLogInUser:(PFUser *)user {

    [self userInfoGrab:user];

    [self dismissViewControllerAnimated:YES completion:NULL];

}

// Sent to the delegate when the log in attempt fails.
- (void)logInViewController:(PFLogInViewController *)logInController didFailToLogInWithError:(NSError *)error {
    NSLog(@"Failed to log in...");
}

// Sent to the delegate when the log in screen is dismissed.
- (void)logInViewControllerDidCancelLogIn:(PFLogInViewController *)logInController {
    [self.navigationController popViewControllerAnimated:YES];
}

// Sent to the delegate to determine whether the sign up request should be submitted to the server.
- (BOOL)signUpViewController:(PFSignUpViewController *)signUpController shouldBeginSignUp:(NSDictionary *)info {
    BOOL informationComplete = YES;
    
    // loop through all of the submitted data
    for (id key in info) {
        NSString *field = [info objectForKey:key];
        if (!field || field.length == 0) { // check completion
            informationComplete = NO;
            break;
        }
    }
    
    // Display an alert if a field wasn't completed
    if (!informationComplete) {
        [[[UIAlertView alloc] initWithTitle:@"Missing Information"
                                    message:@"Make sure you fill out all of the information!"
                                   delegate:nil
                          cancelButtonTitle:@"ok"
                          otherButtonTitles:nil] show];
    }
    
    return informationComplete;
}

// Sent to the delegate when a PFUser is signed up.
- (void)signUpViewController:(PFSignUpViewController *)signUpController didSignUpUser:(PFUser *)user {
    [self dismissModalViewControllerAnimated:YES]; // Dismiss the PFSignUpViewController
}

// Sent to the delegate when the sign up attempt fails.
- (void)signUpViewController:(PFSignUpViewController *)signUpController didFailToSignUpWithError:(NSError *)error {
    NSLog(@"Failed to sign up...");
}

// Sent to the delegate when the sign up screen is dismissed.
- (void)signUpViewControllerDidCancelSignUp:(PFSignUpViewController *)signUpController {
    NSLog(@"User dismissed the signUpViewController");
}


#pragma mark -
#pragma mark CLLocationManagerDelegate methods and helpers

- (CLLocationManager *)locationManager {
    if (_locationManager == nil) {
        _locationManager = [[CLLocationManager alloc] init];
        
        _locationManager.delegate = self;
        _locationManager.desiredAccuracy = kCLLocationAccuracyBest;
        
        // Set a movement threshold for new events.
        _locationManager.distanceFilter = kCLLocationAccuracyNearestTenMeters;
    }
    return _locationManager;
}

- (void)startStandardUpdates {
    [self.locationManager startUpdatingLocation];
    
    CLLocation *currentLocation = self.locationManager.location;
    if (currentLocation) {
        self.currentLocation = currentLocation;
    }
}

- (void)locationManager:(CLLocationManager *)manager didChangeAuthorizationStatus:(CLAuthorizationStatus)status {
    NSLog(@"%s", __PRETTY_FUNCTION__);
    switch (status) {
        case kCLAuthorizationStatusAuthorized:
        {
            NSLog(@"kCLAuthorizationStatusAuthorized");
            // Re-enable the post button if it was disabled before.
            [self.locationManager startUpdatingLocation];
        }
            break;
        case kCLAuthorizationStatusDenied:
            NSLog(@"kCLAuthorizationStatusDenied");
        {
            UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Anywall can’t access your current location.\n\nTo view nearby posts or create a post at your current location, turn on access for Anywall to your location in the Settings app under Location Services." message:nil delegate:self cancelButtonTitle:nil otherButtonTitles:@"OK", nil];
            [alertView show];
            // Disable the post button.
            self.navigationItem.rightBarButtonItem.enabled = NO;
        }
            break;
        case kCLAuthorizationStatusNotDetermined:
        {
            NSLog(@"kCLAuthorizationStatusNotDetermined");
        }
            break;
        case kCLAuthorizationStatusRestricted:
        {
            NSLog(@"kCLAuthorizationStatusRestricted");
        }
            break;
        default:break;
    }
}

- (void)locationManager:(CLLocationManager *)manager
    didUpdateToLocation:(CLLocation *)newLocation
           fromLocation:(CLLocation *)oldLocation {
    NSLog(@"%s", __PRETTY_FUNCTION__);
    
    self.currentLocation = newLocation;
}

- (void)locationManager:(CLLocationManager *)manager
       didFailWithError:(NSError *)error {
    NSLog(@"%s", __PRETTY_FUNCTION__);
    NSLog(@"Error: %@", [error description]);
    
    if (error.code == kCLErrorDenied) {
        [self.locationManager stopUpdatingLocation];
    } else if (error.code == kCLErrorLocationUnknown) {
        // todo: retry?
        // set a timer for five seconds to cycle location, and if it fails again, bail and tell the user.
    } else {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error retrieving location"
                                                        message:[error localizedDescription]
                                                       delegate:nil
                                              cancelButtonTitle:nil
                                              otherButtonTitles:@"OK", nil];
        [alert show];
    }
}

#pragma mark -
#pragma mark MKMapViewDelegate



- (MKAnnotationView *)mapView:(MKMapView *)mapVIew viewForAnnotation:(id<MKAnnotation>)annotation {
    // Let the system handle user location annotations.
    if ([annotation isKindOfClass:[MKUserLocation class]]) {
        return nil;
    }
    
    static NSString *pinIdentifier = @"CustomPinAnnotation";
    
    // Handle any custom annotations.
    if ([annotation isKindOfClass:[PAUser class]]) {
        // Try to dequeue an existing pin view first.
        MKPinAnnotationView *pinView = (MKPinAnnotationView*)[mapVIew dequeueReusableAnnotationViewWithIdentifier:pinIdentifier];
        
        if (!pinView) {
            // If an existing pin view was not available, create one.
            pinView = [[MKPinAnnotationView alloc] initWithAnnotation:annotation
                                                      reuseIdentifier:pinIdentifier];
        } else {
            pinView.annotation = annotation;
        }
        pinView.pinColor = MKPinAnnotationColorRed;
        pinView.animatesDrop = TRUE;
        pinView.canShowCallout = YES;
        
        return pinView;
    }
    
    return nil;
}

- (void)mapView:(MKMapView *)mapView didSelectAnnotationView:(MKAnnotationView *)view {
   
}

- (void)mapView:(MKMapView *)mapView didDeselectAnnotationView:(MKAnnotationView *)view {

}

- (void)mapView:(MKMapView *)mapView regionWillChangeAnimated:(BOOL)animated {
   // self.mapPannedSinceLocationUpdate = YES;
}

#pragma mark -
#pragma mark Fetch map pins

- (void)queryForAllUsersNearLocation:(CLLocation *)currentLocation withNearbyDistance:(CLLocationAccuracy)nearbyDistance {
    PFQuery *query = [PFQuery queryWithClassName:@"_User"];
    
    if (currentLocation == nil) {
        NSLog(@"%s got a nil location!", __PRETTY_FUNCTION__);
    }
    
    // If no objects are loaded in memory, we look to the cache first to fill the table
    // and then subsequently do a query against the network.
    if ([self.allUsers count] == 0) {
  //      query.cachePolicy = kPFCachePolicyCacheThenNetwork;
    }
    
    // Query for posts sort of kind of near our current location.
    PFGeoPoint *point = [PFGeoPoint geoPointWithLatitude:self.currentLocation.coordinate.latitude longitude:self.currentLocation.coordinate.longitude];
    [query whereKey:@"lastPosition" nearGeoPoint:point withinKilometers:1000];
 //   [query includeKey:@"user"];
    query.limit = 50;
    
    [query findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
        if (error) {
            NSLog(@"error in geo query!"); // todo why is this ever happening?
        } else {
            // We need to make new post objects from objects,
            // and update allPosts and the map to reflect this new array.
            // But we don't want to remove all annotations from the mapview blindly,
            // so let's do some work to figure out what's new and what needs removing.
            
            // 1. Find genuinely new posts:
            NSMutableArray *newUsers = [[NSMutableArray alloc] initWithCapacity:50];
            // (Cache the objects we make for the search in step 2:)
            NSMutableArray *allNewUsers = [[NSMutableArray alloc] initWithCapacity:[objects count]];
            for (PFObject *object in objects) {
                PAUser *newUser = [[PAUser alloc] initWithPFObject:object];
                [allNewUsers addObject:newUser];
                if (![_allUsers containsObject:newUser]) {
                    [newUsers addObject:newUser];
                }
            }
            // newPosts now contains our new objects.
            
            // 2. Find posts in allPosts that didn't make the cut.
            NSMutableArray *usersToRemove = [[NSMutableArray alloc] initWithCapacity:50];
            for (PAUser *currentUser in _allUsers) {
                if (![allNewUsers containsObject:currentUser]) {
                    [usersToRemove addObject:currentUser];
                }
            }
            // postsToRemove has objects that didn't come in with our new results.
            
            // 3. Configure our new posts; these are about to go onto the map.
            for (PAUser *newUser in newUsers) {
                PFGeoPoint *userLoc = [newUser.user objectForKey:@"lastPosition"];
                
                CLLocation *objectLocation = [[CLLocation alloc] initWithLatitude:userLoc.latitude
                                                                        longitude:userLoc.longitude];
                // if this post is outside the filter distance, don't show the regular callout.
               // CLLocationDistance distanceFromCurrent = [currentLocation distanceFromLocation:objectLocation];
             //   [newPost setTitleAndSubtitleOutsideDistance:( distanceFromCurrent > nearbyDistance ? YES : NO )];
                // Animate all pins after the initial load:
               // newPost.animatesDrop = self.mapPinsPlaced;
            }
            
            // At this point, newAllPosts contains a new list of post objects.
            // We should add everything in newPosts to the map, remove everything in postsToRemove,
            // and add newPosts to allPosts.
            [self.mapView removeAnnotations:usersToRemove];
            [self.mapView addAnnotations:newUsers];
            
            [_allUsers addObjectsFromArray:newUsers];
            [_allUsers removeObjectsInArray:usersToRemove];
            
//            self.mapPinsPlaced = YES;
        }
    }];
}

// When we update the search filter distance, we need to update our pins' titles to match.
- (void)updateUsersForLocation:(CLLocation *)currentLocation withNearbyDistance:(CLLocationAccuracy) nearbyDistance {
    for (PFUser *user in _allUsers) {
        
        PFGeoPoint *userLoc = [user objectForKey:@"lestPosition"];
        
        CLLocation *objectLocation = [[CLLocation alloc] initWithLatitude:userLoc.latitude
                                                                longitude:userLoc.longitude];
        
        // if this post is outside the filter distance, don't show the regular callout.
        CLLocationDistance distanceFromCurrent = [currentLocation distanceFromLocation:objectLocation];
        if (distanceFromCurrent > nearbyDistance) { // Outside search radius
           // [post setTitleAndSubtitleOutsideDistance:YES];
            [(MKPinAnnotationView *)[self.mapView viewForAnnotation:user] setPinColor:MKPinAnnotationColorRed];
        } else {
            [(MKPinAnnotationView *)[self.mapView viewForAnnotation:user] setPinColor:MKPinAnnotationColorRed];
        }
    }
}



@end
