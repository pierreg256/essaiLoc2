//
//  PGTMenuViewController.h
//  essaiLoc
//
//  Created by famille on 11/07/12.
//  Copyright (c) 2012 Pierre Gilot. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "PGTNewParcoursViewController.h"

@interface PGTMenuViewController : UITableViewController <UITextFieldDelegate, PGTNewParcoursViewControllerDelegate>

@property (nonatomic, retain) IBOutlet UINavigationItem* addButtonItem;

-(IBAction)insertNewObject:(id)sender;

@end
