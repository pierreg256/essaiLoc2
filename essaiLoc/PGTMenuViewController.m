//
//  PGTMenuViewController.m
//  essaiLoc
//
//  Created by famille on 11/07/12.
//  Copyright (c) 2012 Pierre Gilot. All rights reserved.
//

#import "PGTMenuViewController.h"
#import "PGTDocument.h"
#import "NSDate+FormattedStrings.h"
#import "PGTEntry.h"
#import "PGTMetaData.h"
#import "PGTEntryCell.h"
#import "DDLog.h"

@interface PGTMenuViewController ()
{
    NSMutableArray* _objects;
    NSURL * _localRoot;
    NSURL * _iCloudRoot;
    BOOL _iCloudAvailable;
    PGTDocument * _selDocument;
    NSMetadataQuery * _query;
    BOOL _iCloudURLsReady;
    NSMutableArray * _iCloudURLs;
    UITextField * _activeTextField;
}
@end

@implementation PGTMenuViewController

@synthesize addButtonItem;

#pragma mark -
#pragma mark Helpers

- (BOOL)iCloudOn {
    return [[NSUserDefaults standardUserDefaults] boolForKey:@"iCloudOn"];
}

- (void)setiCloudOn:(BOOL)on {
    [[NSUserDefaults standardUserDefaults] setBool:on forKey:@"iCloudOn"];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (BOOL)iCloudWasOn {
    return [[NSUserDefaults standardUserDefaults] boolForKey:@"iCloudWasOn"];
}

- (void)setiCloudWasOn:(BOOL)on {
    [[NSUserDefaults standardUserDefaults] setBool:on forKey:@"iCloudWasOn"];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (BOOL)iCloudPrompted {
    return [[NSUserDefaults standardUserDefaults] boolForKey:@"iCloudPrompted"];
}

- (void)setiCloudPrompted:(BOOL)prompted {
    [[NSUserDefaults standardUserDefaults] setBool:prompted forKey:@"iCloudPrompted"];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (NSURL *)localRoot {
    if (_localRoot != nil) {
        return _localRoot;
    }
    
    NSArray * paths = [[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask];
    _localRoot = [paths objectAtIndex:0];
    return _localRoot;
}

- (NSURL *)getDocURL:(NSString *)filename {
    if ([self iCloudOn]) {
        NSURL * docsDir = [_iCloudRoot URLByAppendingPathComponent:@"Documents" isDirectory:YES];
        return [docsDir URLByAppendingPathComponent:filename];
    } else {
        return [self.localRoot URLByAppendingPathComponent:filename];
    }
}

- (BOOL)docNameExistsInObjects:(NSString *)docName {
    BOOL nameExists = NO;
    for (PGTEntry * entry in _objects) {
        if ([[entry.fileURL lastPathComponent] isEqualToString:docName]) {
            nameExists = YES;
            break;
        }
    }
    return nameExists;
}

- (NSString*)getDocFilename:(NSString *)prefix uniqueInObjects:(BOOL)uniqueInObjects {
    NSInteger docCount = 0;
    NSString* newDocName = nil;
    
    // At this point, the document list should be up-to-date.
    BOOL done = NO;
    BOOL first = YES;
    while (!done) {
        if (first) {
            first = NO;
            newDocName = [NSString stringWithFormat:@"%@.%@",
                          prefix, PGT_EXTENSION];
        } else {
            newDocName = [NSString stringWithFormat:@"%@ %d.%@",
                          prefix, docCount, PGT_EXTENSION];
        }
        
        // Look for an existing document with the same name. If one is
        // found, increment the docCount value and try again.
        BOOL nameExists;
        if (uniqueInObjects) {
            nameExists = [self docNameExistsInObjects:newDocName];
        } else {
            // TODO
            return nil;
        }
        if (!nameExists) {
            break;
        } else {
            docCount++;
        }
        
    }
    
    return newDocName;
}

-(IBAction)insertNewObject:(id)sender
{
    // Determine a unique filename to create
    NSURL * fileURL = [self getDocURL:[self getDocFilename:@"Parcours" uniqueInObjects:YES]];
    NSLog(@"Want to create file at %@", fileURL);
    
    // Create new document and save to the filename
    PGTDocument * doc = [[PGTDocument alloc] initWithFileURL:fileURL];
    [doc saveToURL:fileURL forSaveOperation:UIDocumentSaveForCreating completionHandler:^(BOOL success) {
        
        if (!success) {
            NSLog(@"Failed to create file at %@", fileURL);
            return;
        }
        
        NSLog(@"File created at %@", fileURL);
        PGTMetaData * metadata = doc.metadata;
        NSURL * fileURL = doc.fileURL;
        UIDocumentState state = doc.documentState;
        NSFileVersion * version = [NSFileVersion currentVersionOfItemAtURL:fileURL];
        
        // Add on the main thread and perform the segue
        _selDocument = doc;
        dispatch_async(dispatch_get_main_queue(), ^{
            [self addOrUpdateEntryWithURL:fileURL metadata:metadata state:state version:version];
            [self performSegueWithIdentifier:@"showDetail" sender:self];
        });
        
    }]; 
}

- (void)initializeiCloudAccessWithCompletion:(void (^)(BOOL available)) completion {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        _iCloudRoot = [[NSFileManager defaultManager] URLForUbiquityContainerIdentifier:nil];
        if (_iCloudRoot != nil) {
            dispatch_async(dispatch_get_main_queue(), ^{
                DDLog(@"iCloud available at: %@", _iCloudRoot);
                completion(TRUE);
            });
        }
        else {
            dispatch_async(dispatch_get_main_queue(), ^{
                DDLog(@"iCloud not available");
                completion(FALSE);
            });
        }
    });
}

#pragma mark - Entry management methods

- (int)indexOfEntryWithFileURL:(NSURL *)fileURL {
    __block int retval = -1;
    [_objects enumerateObjectsUsingBlock:^(PGTEntry * entry, NSUInteger idx, BOOL *stop) {
        if ([entry.fileURL isEqual:fileURL]) {
            retval = idx;
            *stop = YES;
        }
    }];
    return retval;
}

- (void)addOrUpdateEntryWithURL:(NSURL *)fileURL metadata:(PGTMetaData *)metadata state:(UIDocumentState)state version:(NSFileVersion *)version {
    
    int index = [self indexOfEntryWithFileURL:fileURL];
    
    // Not found, so add
    if (index == -1) {
        
        PGTEntry * entry = [[PGTEntry alloc] initWithFileURL:fileURL metadata:metadata state:state version:version];
        
        [_objects addObject:entry];
        [self.tableView insertRowsAtIndexPaths:[NSArray arrayWithObject:[NSIndexPath indexPathForRow:(_objects.count - 1) inSection:1]] withRowAnimation:UITableViewRowAnimationRight];
        
    }
    
    // Found, so edit
    else {
        
        PGTEntry * entry = [_objects objectAtIndex:index];
        entry.metadata = metadata;
        entry.state = state;
        entry.version = version;
        
        [self.tableView reloadRowsAtIndexPaths:[NSArray arrayWithObject:[NSIndexPath indexPathForRow:index inSection:1]] withRowAnimation:UITableViewRowAnimationNone];
        
    }
    
}

- (BOOL)renameEntry:(PGTEntry *)entry to:(NSString *)filename {
    
    // Bail if not actually renaming
    if ([entry.description isEqualToString:filename]) {
        return YES;
    }
    
    // Check if can rename file
    NSString * newDocFilename = [NSString stringWithFormat:@"%@.%@",
                                 filename, PGT_EXTENSION];
    if ([self docNameExistsInObjects:newDocFilename]) {
        NSString * message = [NSString stringWithFormat:@"\"%@\" is already taken.  Please choose a different name.", filename];
        UIAlertView * alertView = [[UIAlertView alloc] initWithTitle:nil message:message delegate:nil cancelButtonTitle:nil otherButtonTitles:@"OK", nil];
        [alertView show];
        return NO;
    }
    
    NSURL * newDocURL = [self getDocURL:newDocFilename];
    NSLog(@"Moving %@ to %@", entry.fileURL, newDocURL);
    NSURL* oldURL = [entry.fileURL copy];
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(void) {
        NSError * error;
        NSFileCoordinator *coordinator = [[NSFileCoordinator alloc] initWithFilePresenter:nil];
        [coordinator coordinateWritingItemAtURL:oldURL options: NSFileCoordinatorWritingForMoving writingItemAtURL:newDocURL options: NSFileCoordinatorWritingForReplacing error:&error byAccessor:^(NSURL *newURL1, NSURL *newURL2) {
            
            // Simple renaming to start
            NSFileManager* fileManager = [[NSFileManager alloc] init];
            NSError * error;
            BOOL success = [fileManager moveItemAtURL:oldURL toURL:newDocURL error:&error];
            if (!success) {
                NSLog(@"Failed to move file: %@", error.localizedDescription);
                return;
            }
            
        }];
    });
    
    // Fix up entry
    entry.fileURL = newDocURL;
    int index = [self indexOfEntryWithFileURL:entry.fileURL];
    [self.tableView reloadRowsAtIndexPaths:[NSArray arrayWithObject:[NSIndexPath indexPathForRow:index inSection:0]] withRowAnimation:UITableViewRowAnimationNone];
    
    return YES;
    
}

- (void)removeEntryWithURL:(NSURL *)fileURL {
    int index = [self indexOfEntryWithFileURL:fileURL];
    [_objects removeObjectAtIndex:index];
    [self.tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:[NSIndexPath indexPathForRow:index inSection:1]] withRowAnimation:UITableViewRowAnimationLeft];
}

#pragma mark - File management methods

- (void)loadDocAtURL:(NSURL *)fileURL {
    
    // Open doc so we can read metadata
    PGTDocument * doc = [[PGTDocument alloc] initWithFileURL:fileURL];
    [doc openWithCompletionHandler:^(BOOL success) {
        
        // Check status
        if (!success) {
            NSLog(@"Failed to open %@", fileURL);
            return;
        }
        
        // Preload metadata on background thread
        PGTMetaData * metadata = doc.metadata;
        NSURL * fileURL = doc.fileURL;
        UIDocumentState state = doc.documentState;
        NSFileVersion * version = [NSFileVersion currentVersionOfItemAtURL:fileURL];
        NSLog(@"Loaded File URL: %@", [doc.fileURL lastPathComponent]);
        
        // Close since we're done with it
        [doc closeWithCompletionHandler:^(BOOL success) {
            
            // Check status
            if (!success) {
                NSLog(@"Failed to close %@", fileURL);
                // Continue anyway...
            }
            
            // Add to the list of files on main thread
            dispatch_async(dispatch_get_main_queue(), ^{
                [self addOrUpdateEntryWithURL:fileURL metadata:metadata state:state version:version];
            });
        }];             
    }];
    
}

- (void)deleteEntry:(PGTEntry *)entry {
    
    // Wrap in file coordinator
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(void) {
        NSFileCoordinator* fileCoordinator = [[NSFileCoordinator alloc] initWithFilePresenter:nil];
        [fileCoordinator coordinateWritingItemAtURL:entry.fileURL
                                            options:NSFileCoordinatorWritingForDeleting
                                              error:nil
                                         byAccessor:^(NSURL* writingURL) {
                                             // Simple delete to start
                                             NSFileManager* fileManager = [[NSFileManager alloc] init];
                                             [fileManager removeItemAtURL:entry.fileURL error:nil];
                                         }];
    });
    
    // Fixup view
    [self removeEntryWithURL:entry.fileURL];
    
}

- (void)iCloudToLocal {
    DDLog(@"iCloud => local");
}

- (void)localToiCloud {
    DDLog(@"local => iCloud");
}

- (void)processiCloudFiles:(NSNotification *)notification {
    
    // Always disable updates while processing results
    [_query disableUpdates];
    
    [_iCloudURLs removeAllObjects];
    
    // The query reports all files found, every time.
    NSArray * queryResults = [_query results];
    for (NSMetadataItem * result in queryResults) {
        NSURL * fileURL = [result valueForAttribute:NSMetadataItemURLKey];
        NSNumber * aBool = nil;
        
        // Don't include hidden files
        [fileURL getResourceValue:&aBool forKey:NSURLIsHiddenKey error:nil];
        if (aBool && ![aBool boolValue]) {
            [_iCloudURLs addObject:fileURL];
        }
        
    }
    
    NSLog(@"Found %d iCloud files.", _iCloudURLs.count);
    _iCloudURLsReady = YES;
    
    if ([self iCloudOn]) {
        
        // Remove deleted files
        // Iterate backwards because we need to remove items form the array
        for (int i = _objects.count -1; i >= 0; --i) {
            PGTEntry * entry = [_objects objectAtIndex:i];
            if (![_iCloudURLs containsObject:entry.fileURL]) {
                [self removeEntryWithURL:entry.fileURL];
            }
        }
        
        // Add new files
        for (NSURL * fileURL in _iCloudURLs) {
            [self loadDocAtURL:fileURL];
        }
        
        self.navigationItem.rightBarButtonItem.enabled = YES;
        
    } 
    
    [_query enableUpdates];
    
}
#pragma mark - iCloud Query

- (NSMetadataQuery *)documentQuery {
    
    NSMetadataQuery * query = [[NSMetadataQuery alloc] init];
    if (query) {
        
        // Search documents subdir only
        [query setSearchScopes:[NSArray arrayWithObject:NSMetadataQueryUbiquitousDocumentsScope]];
        
        // Add a predicate for finding the documents
        NSString * filePattern = [NSString stringWithFormat:@"*.%@", PGT_EXTENSION];
        [query setPredicate:[NSPredicate predicateWithFormat:@"%K LIKE %@",
                             NSMetadataItemFSNameKey, filePattern]];
        
    }
    return query;
    
}

- (void)stopQuery {
    
    if (_query) {
        
        NSLog(@"No longer watching iCloud dir...");
        
        [[NSNotificationCenter defaultCenter] removeObserver:self name:NSMetadataQueryDidFinishGatheringNotification object:nil];
        [[NSNotificationCenter defaultCenter] removeObserver:self name:NSMetadataQueryDidUpdateNotification object:nil];
        [_query stopQuery];
        _query = nil;
    }
    
}

- (void)startQuery {
    
    [self stopQuery];
    
    NSLog(@"Starting to watch iCloud dir...");
    
    _query = [self documentQuery];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(processiCloudFiles:)
                                                 name:NSMetadataQueryDidFinishGatheringNotification
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(processiCloudFiles:)
                                                 name:NSMetadataQueryDidUpdateNotification
                                               object:nil];
    
    [_query startQuery];
}

#pragma mark - Refresh Methods

- (void)loadLocal {
    
    NSArray * localDocuments = [[NSFileManager defaultManager] contentsOfDirectoryAtURL:self.localRoot includingPropertiesForKeys:nil options:0 error:nil];
    NSLog(@"Found %d local files.", localDocuments.count);
    for (int i=0; i < localDocuments.count; i++) {
        
        NSURL * fileURL = [localDocuments objectAtIndex:i];
        if ([[fileURL pathExtension] isEqualToString:PGT_EXTENSION]) {
            NSLog(@"Found local file: %@", fileURL);
            [self loadDocAtURL:fileURL];
        }
    }
    
    self.navigationItem.rightBarButtonItem.enabled = YES;
}

- (void)refresh {
    _iCloudURLsReady = NO;
    [_iCloudURLs removeAllObjects];
    [_objects removeAllObjects];
    [self.tableView reloadData];
    
    self.navigationItem.rightBarButtonItem.enabled = NO;
    [self initializeiCloudAccessWithCompletion:^(BOOL available) {
        
        _iCloudAvailable = available;
        
        // Replace the "TODO" in refresh with the following
        if (!_iCloudAvailable) {
            
            // If iCloud isn't available, set promoted to no (so we can ask them next time it becomes available)
            [self setiCloudPrompted:NO];
            
            // If iCloud was toggled on previously, warn user that the docs will be loaded locally
            if ([self iCloudWasOn]) {
                UIAlertView * alertView = [[UIAlertView alloc] initWithTitle:@"You're Not Using iCloud" message:@"Your documents were removed from this iPad but remain stored in iCloud." delegate:nil cancelButtonTitle:nil otherButtonTitles:@"OK", nil];
                [alertView show];
            }
            
            // No matter what, iCloud isn't available so switch it to off.
            [self setiCloudOn:NO];
            [self setiCloudWasOn:NO];
            
        } else {
            
            // Ask user if want to turn on iCloud if it's available and we haven't asked already
            if (![self iCloudOn] && ![self iCloudPrompted]) {
                
                [self setiCloudPrompted:YES];
                
                UIAlertView * alertView = [[UIAlertView alloc] initWithTitle:@"iCloud is Available" message:@"Automatically store your documents in the cloud to keep them up-to-date across all your devices and the web." delegate:self cancelButtonTitle:@"Later" otherButtonTitles:@"Use iCloud", nil];
                alertView.tag = 1;
                [alertView show];
                
            }
            
            // If iCloud newly switched off, move local docs to iCloud
            if ([self iCloudOn] && ![self iCloudWasOn]) {
                [self localToiCloud];
            }
            
            // If iCloud newly switched on, move iCloud docs to local
            if (![self iCloudOn] && [self iCloudWasOn]) {
                [self iCloudToLocal];                    
            }
            
            // Start querying iCloud for files, whether on or off
            [self startQuery];
            
            // No matter what, refresh with current value of iCloudOn
            [self setiCloudWasOn:[self iCloudOn]];
            
        }

        
        if (![self iCloudOn]) {
            [self loadLocal];
        }
        
    }];
}

#pragma mark - UIAlertViewDelegate

- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex {
    
    // @"Automatically store your documents in the cloud to keep them up-to-date across all your devices and the web."
    // Cancel: @"Later"
    // Other: @"Use iCloud"
    if (alertView.tag == 1) {
        if (buttonIndex == alertView.firstOtherButtonIndex)
        {
            [self setiCloudOn:YES];
            [self refresh];
        }
    }
}

#pragma mark - PTKDetailViewControllerDelegate

- (void)detailViewControllerDidClose:(PGTNewParcoursViewController *)detailViewController {
    [self.navigationController popViewControllerAnimated:YES];
    NSFileVersion * version = [NSFileVersion currentVersionOfItemAtURL:detailViewController.doc.fileURL];
    [self addOrUpdateEntryWithURL:detailViewController.doc.fileURL metadata:detailViewController.doc.metadata state:detailViewController.doc.documentState version:version];
}

#pragma mark - Text Views
-(void) keyboardWillShow:(NSNotification *)note
{
    // Get the keyboard size
    CGRect keyboardBounds;
    [[note.userInfo valueForKey:UIKeyboardFrameBeginUserInfoKey] getValue: &keyboardBounds];
    
    // Detect orientation
    UIInterfaceOrientation orientation = [[UIApplication sharedApplication] statusBarOrientation];
    CGRect frame = self.tableView.frame;
    
    // Start animation
    [UIView beginAnimations:nil context:NULL];
    [UIView setAnimationBeginsFromCurrentState:YES];
    [UIView setAnimationDuration:0.3f];
    
    // Reduce size of the Table view
    if (orientation == UIInterfaceOrientationPortrait || orientation == UIInterfaceOrientationPortraitUpsideDown)
        frame.size.height -= keyboardBounds.size.height;
    else
        frame.size.height -= keyboardBounds.size.width;
    
    // Apply new size of table view
    self.tableView.frame = frame;
    
    // Scroll the table view to see the TextField just above the keyboard
    if (_activeTextField)
    {
        CGRect textFieldRect = [self.tableView convertRect:_activeTextField.superview.bounds fromView:_activeTextField.superview];
        [self.tableView scrollRectToVisible:textFieldRect animated:NO];
    }
    
    [UIView commitAnimations];
}

-(void) keyboardWillHide:(NSNotification *)note
{
    // Get the keyboard size
    CGRect keyboardBounds;
    [[note.userInfo valueForKey:UIKeyboardFrameBeginUserInfoKey] getValue: &keyboardBounds];
    
    // Detect orientation
    UIInterfaceOrientation orientation = [[UIApplication sharedApplication] statusBarOrientation];
    CGRect frame = self.tableView.frame;
    
    [UIView beginAnimations:nil context:NULL];
    [UIView setAnimationBeginsFromCurrentState:YES];
    [UIView setAnimationDuration:0.3f];
    
    // Reduce size of the Table view
    if (orientation == UIInterfaceOrientationPortrait || orientation == UIInterfaceOrientationPortraitUpsideDown)
        frame.size.height += keyboardBounds.size.height;
    else
        frame.size.height += keyboardBounds.size.width;
    
    // Apply new size of table view
    self.tableView.frame = frame;
    
    [UIView commitAnimations];
}

- (IBAction)textFieldDidBeginEditing:(UITextField *)textField
{
    _activeTextField = textField;
}

- (IBAction)textFieldDidEndEditing:(UITextField *)textField
{
    _activeTextField = nil;
}

- (void)textChanged:(UITextField *)textField {
    UIView * view = textField.superview;
    while( ![view isKindOfClass: [PGTEntryCell class]]){
        view = view.superview;
    }
    PGTEntryCell *cell = (PGTEntryCell *) view;
    NSIndexPath * indexPath = [self.tableView indexPathForCell:cell];
    PGTEntry * entry = [_objects objectAtIndex:indexPath.row];
    NSLog(@"Want to rename %@ to %@", entry.description, textField.text);
    [self renameEntry:entry to:textField.text];
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
	[textField resignFirstResponder];
    [self textChanged:textField];
	return YES;
}

#pragma mark -
#pragma mark View lifecycle
- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
 
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    self.navigationItem.leftBarButtonItem = self.editButtonItem;
    
    _objects = [[NSMutableArray alloc] init];
    _iCloudURLs = [[NSMutableArray alloc] init];
    
    [self refresh];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didBecomeActive:) name:UIApplicationDidBecomeActiveNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillShow:) name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillHide:) name:UIKeyboardWillHideNotification object:nil];
    

}

- (void)viewDidUnload
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)viewWillAppear:(BOOL)animated {
    [_query enableUpdates];
}

- (void)viewWillDisappear:(BOOL)animated {
    [_query disableUpdates];
}

- (void)didBecomeActive:(NSNotification *)notification {
    [self refresh];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // Return the number of sections.
    return 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    //NSLog(@"section:%d", section);
    // Return the number of rows in the section.
    return (section==0?2:[_objects count]);
}

- (NSString*)tableView:(UITableView*)tableView titleForHeaderInSection:(NSInteger)section
{
    return (section==0?@"Gestion":@"Parcours enregistrés");
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    //DDLog(@"indexPath: %@", indexPath);
    // Configure the cell...
    if (indexPath.section == 0){
        static NSString *CellIdentifier = @"Cell";
        UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
        
        if (indexPath.row==0){
            cell.textLabel.text = @"Ajouter un parcours";
            cell.detailTextLabel.text = @"Géollocalisez un nouveau parcours";
            cell.imageView.image = [UIImage imageNamed:@"10-medical"];
            
            return cell;
        } else {
            cell.textLabel.text = @"Paramètres";
            cell.detailTextLabel.text = @"configuration de l'application";
            cell.imageView.image = [UIImage imageNamed:@"20-gear2"];
        }
        
        return cell;
    }
    else {

        PGTEntryCell *cell = [tableView dequeueReusableCellWithIdentifier:@"EntryCell"];
        
        PGTEntry *entry = [_objects objectAtIndex:indexPath.row];
        //DDLog(@"desc: %@, version: %@", entry.description, [entry.version.modificationDate mediumString]);
        
        cell.titleTextField.text = entry.description;
        cell.titleTextField.delegate = self;
        cell.photoImageView.layer.cornerRadius = 10;
        cell.photoImageView.layer.masksToBounds = YES;
        if (entry.metadata && entry.metadata.thumbnail) {
            cell.photoImageView.image = entry.metadata.thumbnail;
        } else {
            cell.photoImageView.image = nil;
        }
        if (entry.version) {
            cell.subtitleLabel.text = [entry.version.modificationDate mediumString];
        } else {
            cell.subtitleLabel.text = @"";
        }
        
        return cell;
        
/*
        PGTEntry *entry = [_objects objectAtIndex:indexPath.row];
        cell.imageView.image = entry.metadata.thumbnail;
        cell.textLabel.text = entry.description;
        cell.detailTextLabel.text = [entry.version.modificationDate mediumString];
*/
    }
    return nil;
    
}


// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the specified item to be editable.
    return (indexPath.section==1);
}



// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        PGTEntry * entry = [_objects objectAtIndex:indexPath.row];
        [self deleteEntry:entry];
    }
}


/*
// Override to support rearranging the table view.
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath
{
}
*/

/*
// Override to support conditional rearranging of the table view.
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the item to be re-orderable.
    return YES;
}
*/

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if ((indexPath.section==0) && (indexPath.row==0)){
        [self insertNewObject:self];
    }
    if (indexPath.section==1){
        PGTEntry * entry = [_objects objectAtIndex:indexPath.row];
        [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
        
        _selDocument = [[PGTDocument alloc] initWithFileURL:entry.fileURL];
        [_selDocument openWithCompletionHandler:^(BOOL success) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [self performSegueWithIdentifier:@"showDetail" sender:self];
            });
        }];
    }

    // Navigation logic may go here. Create and push another view controller.
    /*
     <#DetailViewController#> *detailViewController = [[<#DetailViewController#> alloc] initWithNibName:@"<#Nib name#>" bundle:nil];
     // ...
     // Pass the selected object to the new view controller.
     [self.navigationController pushViewController:detailViewController animated:YES];
     */
}

#pragma mark - Segue operations
// Replace prepareForSegue with the following
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([[segue identifier] isEqualToString:@"showDetail"]) {
        [[segue destinationViewController] setDelegate:self];
        [[segue destinationViewController] setDoc:_selDocument];
    }
}

@end
