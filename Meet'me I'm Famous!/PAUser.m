//
//  PAUser.m
//  Meet'me I'm Famous!
//
//  Created by Rodolphe on 03/05/2015.
//  Copyright (c) 2015 Rodolphe Hugel. All rights reserved.
//

#import "PAUser.h"
#import <Parse/Parse.h>

@interface PAUser ()

@property (nonatomic, assign) CLLocationCoordinate2D coordinate;

@property (nonatomic, copy) NSString *title;
@property (nonatomic, copy) NSString *subtitle;

@property (nonatomic, strong) PFObject *object;
@property (nonatomic, strong) PFUser *user;
@property (nonatomic, assign) MKPinAnnotationColor pinColor;

@end

@implementation PAUser

#pragma mark -
#pragma mark Init

- (instancetype)initWithCoordinate:(CLLocationCoordinate2D)coordinate
                          andTitle:(NSString *)title
                       andSubtitle:(NSString *)subtitle {
    self = [super init];
    if (self) {
        self.coordinate = coordinate;
        self.title = title;
        self.subtitle = subtitle;
    }
    return self;
}

- (instancetype)initWithPFObject:(PFObject *)object {
    PFGeoPoint *geoPoint = object[@"lastPosition"];
    CLLocationCoordinate2D coordinate = CLLocationCoordinate2DMake(geoPoint.latitude, geoPoint.longitude);
    NSString *title = object[@"firstname"];

    self = [self initWithCoordinate:coordinate andTitle:title andSubtitle: nil];
    if (self) {
        self.object = object;
        self.user = object;
    }
    return self;
}

#pragma mark -
#pragma mark Equal

- (BOOL)isEqual:(id)other {
    if (![other isKindOfClass:[PAUser class]]) {
        return NO;
    }

    PAUser *user = (PAUser *)other;

    if (user.object && self.object) {
        // We have a PFObject inside the PAWPost, use that instead.
        return [user.object.objectId isEqualToString:self.object.objectId];
    }

    // Fallback to properties
    return ([user.title isEqualToString:self.title] &&
            [user.subtitle isEqualToString:self.subtitle] &&
            user.coordinate.latitude == self.coordinate.latitude &&
            user.coordinate.longitude == self.coordinate.longitude);
}


@end
