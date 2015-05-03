//
//  ViewController.h
//  Meet'me I'm Famous!
//
//  Created by Rodolphe on 03/05/2015.
//  Copyright (c) 2015 Rodolphe Hugel. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <ParseFacebookUtilsV4/PFFacebookUtils.h>
#import <ParseUI/ParseUI.h> 

// Implement both delegates

@interface ViewController : UIViewController<PFLogInViewControllerDelegate, PFSignUpViewControllerDelegate>

@end

