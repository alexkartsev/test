//
//  MasterViewController.m
//  Note
//
//  Created by Александр Карцев on 10/6/15.
//  Copyright © 2015 Alex Kartsev. All rights reserved.
//

#import "MasterViewController.h"
#import "DetailViewController.h"
#import "MBProgressHud.h"

@interface MasterViewController () <NSFetchedResultsControllerDelegate, UISearchBarDelegate, UISearchResultsUpdating>

@property (strong, nonatomic) UISearchController *searchController;
@property (strong, nonatomic) NSArray *filteredList;
@property (strong,nonatomic) MBProgressHUD * hud;

@end

@implementation MasterViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(stopActivityIndicator) name:@"Data not need to Parse" object:nil];
    // Do any additional setup after loading the view, typically from a nib.
    //self.navigationItem.leftBarButtonItem = self.editButtonItem;
    self.detailViewController = (DetailViewController *)[[self.splitViewController.viewControllers lastObject] topViewController];
    
    self.searchController = [[UISearchController alloc] initWithSearchResultsController:nil];
    self.searchController.searchResultsUpdater = self;
    self.searchController.searchBar.clipsToBounds = YES;
    self.searchController.dimsBackgroundDuringPresentation = NO;
    self.searchController.searchBar.scopeButtonTitles = @[NSLocalizedString(@"Title",@"Title"),
                                                          NSLocalizedString(@"Content",@"Content")];
    self.searchController.searchBar.delegate = self;
    self.tableView.tableHeaderView = self.searchController.searchBar;
    self.definesPresentationContext = YES;
    [self.searchController.searchBar sizeToFit];
    
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleNetworkChange) name:kReachabilityChangedNotification object:nil];
    
    self.internetReachable = [Reachability reachabilityForInternetConnection];
    [self.internetReachable startNotifier];
    [self handleNetworkChange];
}

- (IBAction)updateAction:(id)sender {
    if (self.isInternetConnection)
    {
        [self startActivityIndicator];
        dispatch_async(dispatch_get_global_queue( DISPATCH_QUEUE_PRIORITY_LOW, 0), ^{
            [[DataManager sharedManager] syncWithParse];
        });
    }
    else
    {
        [self showAlertViewWithMessage:@"Sorry, internet connection not available"];
    }
}

- (void) showAlertViewWithMessage:(NSString *) message
{
    UIAlertController *alertController = [UIAlertController  alertControllerWithTitle:@"Attention!"  message:message  preferredStyle:UIAlertControllerStyleAlert];
    [alertController addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        [self dismissViewControllerAnimated:YES completion:nil];
    }]];
    [self presentViewController:alertController animated:YES completion:nil];
}

- (void) handleNetworkChange
{
    NetworkStatus remoteHostStatus = [self.internetReachable currentReachabilityStatus];
    
    if(remoteHostStatus == NotReachable)
    {
        self.isInternetConnection = NO;
        NSLog(@"no internet connection");
    }
    else
    {
        if (!self.isInternetConnection) {
            [self startActivityIndicator];
            self.isInternetConnection = YES;
            dispatch_async(dispatch_get_global_queue( DISPATCH_QUEUE_PRIORITY_LOW, 0), ^{
                [[DataManager sharedManager] syncWithParse];
            });

        }
        NSLog(@"there is internet connection");
    }
}

- (void) startActivityIndicator
{
    self.hud =  [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    NSString *strloadingText = [NSString stringWithFormat:@"Updating Data Base"];
    NSString *strloadingText2 = [NSString stringWithFormat:@" Please wait\r a few seconds"];
    self.hud.labelText = strloadingText;
    self.hud.detailsLabelText=strloadingText2;
}

- (void) stopActivityIndicator
{
    [self.hud hide:YES];
    [self.tableView reloadData];
}

- (void) viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
}

- (void)viewWillAppear:(BOOL)animated {
    [self.tableView reloadData];
    self.clearsSelectionOnViewWillAppear = self.splitViewController.isCollapsed;
    [super viewWillAppear:animated];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Search Methods

- (void)updateSearchResultsForSearchController:(UISearchController *)searchController
{
    NSString *searchString = searchController.searchBar.text;
    self.filteredList = [[NSArray alloc] initWithArray:[[DataManager sharedManager] searchForText:searchString scope:searchController.searchBar.selectedScopeButtonIndex]];
    [self.tableView reloadData];
}

- (void)searchBar:(UISearchBar *)searchBar selectedScopeButtonIndexDidChange:(NSInteger)selectedScope
{
    [self updateSearchResultsForSearchController:self.searchController];
}


#pragma mark - Segues

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([[segue identifier] isEqualToString:@"showDetail"]) {
        NSIndexPath *indexPath = [self.tableView indexPathForSelectedRow];
        NSManagedObject *object = [[self fetchedResultsController] objectAtIndexPath:indexPath];
        DetailViewController *controller = (DetailViewController *)[[segue destinationViewController] topViewController];
        [controller setDetailItem:object];
        controller.navigationItem.leftBarButtonItem = self.splitViewController.displayModeButtonItem;
        controller.navigationItem.leftItemsSupplementBackButton = YES;
    } else if ([[segue identifier] isEqualToString:@"addingNewItem"])
    {
        DetailViewController *controller = (DetailViewController *)[[segue destinationViewController] topViewController];
        controller.navigationItem.leftBarButtonItem = self.splitViewController.displayModeButtonItem;
        controller.navigationItem.leftItemsSupplementBackButton = YES;
    }
}

#pragma mark - Table View

-(void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Explictly set your cell's layout margins
    if ([cell respondsToSelector:@selector(setLayoutMargins:)]) {
        [cell setLayoutMargins:UIEdgeInsetsZero];
    }
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    if (self.searchController.active)
    {
        return 1;
    }
    else
    {
        return [[self.fetchedResultsController sections] count];
    }
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (self.searchController.active)
    {
        return [self.filteredList count];
    }
    else
    {
        id <NSFetchedResultsSectionInfo> sectionInfo = [[self.fetchedResultsController sections] objectAtIndex:section];
        return [sectionInfo numberOfObjects];
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"Cell" forIndexPath:indexPath];
    [self configureCell:cell atIndexPath:indexPath];
    return cell;
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the specified item to be editable.
    return YES;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        NSManagedObjectContext *context = [self.fetchedResultsController managedObjectContext];
        if (self.isInternetConnection)
        {
            [context deleteObject:[self.fetchedResultsController objectAtIndexPath:indexPath]];
            NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
            [dateFormatter setDateFormat:@"yyyyMMddHHmmss"];
            NSString *newDate = [dateFormatter stringFromDate:[[self.fetchedResultsController objectAtIndexPath:indexPath] valueForKey:@"date"]];
            [[DataManager sharedManager] removeObjectFromParseWithCreateDate:[[self.fetchedResultsController objectAtIndexPath:indexPath] valueForKey:@"date"]];
            [[DataManager sharedManager] deleteImageFromDocumentsWithName:newDate];
            NSError *error = nil;
            if (![context save:&error]) {
                NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
                abort();
            }
        }
        else
        {
            NSManagedObject *newNote;
            newNote = [self.fetchedResultsController objectAtIndexPath:indexPath];
            //NSNumber *yesNum = [NSNumber numberWithBool:YES];

            [newNote setValue:@"delete" forKey:@"deleteNote"];
            NSError *error = nil;
            self.wantToRemoveRow = TRUE;
            if (![context save:&error]) {
                NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
                abort();
            }
            //[self.tableView reloadData];
        }
    }
}

- (void)configureCell:(UITableViewCell *)cell atIndexPath:(NSIndexPath *)indexPath {
    NSManagedObject *object;
    if (self.searchController.active)
    {
        object = [self.filteredList objectAtIndex:indexPath.row];
    }
    else
    {
        object = [self.fetchedResultsController objectAtIndexPath:indexPath];
    }
    cell.textLabel.text = [[object valueForKey:@"title"] description];
    cell.detailTextLabel.text = [[object valueForKey:@"content"] description];

}

#pragma mark - Fetched results controller

- (NSFetchedResultsController *)fetchedResultsController
{
    if (_fetchedResultsController != nil) {
        return _fetchedResultsController;
    }
    [NSFetchedResultsController deleteCacheWithName:@"Master"];
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    // Edit the entity name as appropriate.
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"Event" inManagedObjectContext:[[DataManager sharedManager] managedObjectContext]];
    [fetchRequest setEntity:entity];
    NSString *predicateFormat1 = @"%K contains[c] %@";
    NSString *searchAttribute1 = @"deleteNote";
    NSPredicate *predicate1 = [NSPredicate predicateWithFormat:predicateFormat1, searchAttribute1, @"notdelete"];
    [fetchRequest setPredicate:predicate1];
    // Edit the sort key as appropriate.
    NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"date" ascending:NO];
    [fetchRequest setSortDescriptors:@[sortDescriptor]];
    
    // Edit the section name key path and cache name if appropriate.
    // nil for section name key path means "no sections".
    NSFetchedResultsController *aFetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:fetchRequest managedObjectContext:[[DataManager sharedManager] managedObjectContext] sectionNameKeyPath:nil cacheName:@"Master"];
    aFetchedResultsController.delegate = self;
    self.fetchedResultsController = aFetchedResultsController;
    
	NSError *error = nil;
	if (![self.fetchedResultsController performFetch:&error]) {
	    NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
	    abort();
	}
    
    return _fetchedResultsController;
}

- (void)controllerWillChangeContent:(NSFetchedResultsController *)controller
{
    [self.tableView beginUpdates];
}

- (void)controller:(NSFetchedResultsController *)controller didChangeSection:(id <NSFetchedResultsSectionInfo>)sectionInfo
           atIndex:(NSUInteger)sectionIndex forChangeType:(NSFetchedResultsChangeType)type
{
    switch(type) {
        case NSFetchedResultsChangeInsert:
            [self.tableView insertSections:[NSIndexSet indexSetWithIndex:sectionIndex] withRowAnimation:UITableViewRowAnimationFade];
            break;
            
        case NSFetchedResultsChangeDelete:
            [self.tableView deleteSections:[NSIndexSet indexSetWithIndex:sectionIndex] withRowAnimation:UITableViewRowAnimationFade];
            break;
            
        default:
            return;
    }
}

- (void)controller:(NSFetchedResultsController *)controller didChangeObject:(id)anObject
       atIndexPath:(NSIndexPath *)indexPath forChangeType:(NSFetchedResultsChangeType)type
      newIndexPath:(NSIndexPath *)newIndexPath
{
    UITableView *tableView = self.tableView;
    
    switch(type) {
        case NSFetchedResultsChangeInsert:
            [tableView insertRowsAtIndexPaths:@[newIndexPath] withRowAnimation:UITableViewRowAnimationFade];
            break;
            
        case NSFetchedResultsChangeDelete:
            [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
            break;
            
        case NSFetchedResultsChangeUpdate:
            //[self configureCell:[tableView cellForRowAtIndexPath:indexPath] atIndexPath:indexPath];
            
            if (self.wantToRemoveRow) {
                [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
                self.wantToRemoveRow = FALSE;
            }
            
            
            break;
            
        case NSFetchedResultsChangeMove:
            [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
            [tableView insertRowsAtIndexPaths:@[newIndexPath] withRowAnimation:UITableViewRowAnimationFade];
            break;
    }
}

- (void)controllerDidChangeContent:(NSFetchedResultsController *)controller
{
    [self.tableView endUpdates];
}

@end
