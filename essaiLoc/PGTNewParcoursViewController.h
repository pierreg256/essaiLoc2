//
//  PGTNewParcoursViewController.h
//  essaiLoc
//
//  Created by famille on 11/07/12.
//  Copyright (c) 2012 Pierre Gilot. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MapKit/MapKit.h>
#import "PGTCrumbPath.h"
#import "PGTCrumbPathView.h"

#import "DDLog.h"

@class PGTDocument;
@class PGTNewParcoursViewController;

@protocol PGTNewParcoursViewControllerDelegate
- (void)detailViewControllerDidClose:(PGTNewParcoursViewController *)detailViewController;
@end

@interface PGTNewParcoursViewController : UIViewController <MKMapViewDelegate, CLLocationManagerDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate>

@property (nonatomic, weak) IBOutlet MKMapView* mapView;
//@property (nonatomic, strong) PGTCrumbPath* crumbPath;
@property (nonatomic, strong) PGTCrumbPathView* crumbPathView;
@property (nonatomic, strong) CLLocationManager* locationManager;

@property (strong, nonatomic) PGTDocument * doc;
@property (weak, nonatomic) IBOutlet UIImageView *imageView;
@property (weak) id <PGTNewParcoursViewControllerDelegate> delegate;
@property (weak) IBOutlet UIBarButtonItem* btnTracking;
@property (weak) IBOutlet UIBarButtonItem* btnStartStopMap;

-(IBAction)addPhoto:(id)sender;
-(IBAction)autoLocateSwitch:(id)sender;
-(IBAction)startStopMap:(id)sender;

@end




