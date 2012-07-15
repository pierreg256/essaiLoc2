//
//  PGTNewParcoursViewController.h
//  essaiLoc
//
//  Created by famille on 11/07/12.
//  Copyright (c) 2012 Pierre Gilot. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MapKit/MapKit.h>
#import "PGTPath.h"
#import "PGTPathView.h"

@class PGTDocument;
@class PGTNewParcoursViewController;

@protocol PGTNewParcoursViewControllerDelegate
- (void)detailViewControllerDidClose:(PGTNewParcoursViewController *)detailViewController;
@end

@interface PGTNewParcoursViewController : UIViewController <MKMapViewDelegate, CLLocationManagerDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate>

@property (nonatomic, assign) IBOutlet MKMapView* mapView;
@property (nonatomic, strong) PGTPath* crumbs;
@property (nonatomic, strong) PGTPathView* crumbView;
@property (nonatomic, strong) CLLocationManager* locationManager;

@property (strong, nonatomic) PGTDocument * doc;
@property (weak, nonatomic) IBOutlet UIImageView *imageView;
@property (weak) id <PGTNewParcoursViewControllerDelegate> delegate;

@end




