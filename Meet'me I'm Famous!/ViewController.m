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




@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
   
    
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
        [logInViewController setFacebookPermissions:[NSArray arrayWithObjects:@"public_profile",@"email",@"user_about_me" ,nil]];
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

// Sent to the delegate when a PFUser is logged in.
- (void)logInViewController:(PFLogInViewController *)logInController didLogInUser:(PFUser *)user {

    [[[FBSDKGraphRequest alloc] initWithGraphPath:@"me" parameters:@{@"fields": @"first_name, last_name, picture.type(normal), email"}]
     startWithCompletionHandler:^(FBSDKGraphRequestConnection *connection, id result, NSError *error) {
         if (!error) {
             NSLog(@"fetched user:%@", result);
             [[PFUser currentUser] setObject:[result objectForKey:@"id"] forKey:@"fbid"];
             [[PFUser currentUser] setObject:[result objectForKey:@"first_name"] forKey:@"firstname"];
             [[PFUser currentUser] setObject:[result objectForKey:@"last_name"] forKey:@"lastname"];
             [[PFUser currentUser] setObject:[result objectForKey:@"email"] forKey:@"email"];
             [[PFUser currentUser] saveInBackground];
             NSURL *pictureURL = [NSURL URLWithString:[[[result objectForKey:@"picture"] objectForKey:@"data"] objectForKey:@"url"]];
        
             self.profileImage.image = [UIImage imageWithData:[NSData dataWithContentsOfURL:pictureURL]];
        //     = [UIImage imageWithData:[NSData dataWithContentsOfURL:pictureURL]];
             // @{@"fields": @"first_name, last_name, picture.type(normal), email"}
             

         }
     }];

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

@end
