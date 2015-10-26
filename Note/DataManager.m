//
//  DataManager.m
//  Note
//
//  Created by Александр Карцев on 10/7/15.
//  Copyright © 2015 Alex Kartsev. All rights reserved.
//

#import "DataManager.h"
#import <Parse/Parse.h>
#import "Event+CoreDataProperties.h"

@interface DataManager()

@property (strong, nonatomic) NSFetchRequest *searchFetchRequest;
@property (strong, nonatomic) NSArray *filteredList;

@end

@implementation DataManager

static const double epsilon = 0.001; //time from parse hasn't milliseconds, but CoreData has it

+ (DataManager*) sharedManager {
    
    static DataManager* manager = nil;
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        manager = [[DataManager alloc] init];
    });
    
    return manager;
}

-(id)init
{
    if (self = [super init])
    {
        
        
    }
    
    return self;
}

- (void) replaceCoreDataObject:(Event *) coreDataObject withParseObject: (PFObject *) objectFromParse
{
    [self deleteImageFromDocumentsWithName:coreDataObject.imageName];
    PFFile *image = objectFromParse[@"image"];
    NSData *imageData = [image getData];
    coreDataObject.title = objectFromParse[@"title"];
    coreDataObject.content = objectFromParse[@"content"];
    coreDataObject.updateDate = objectFromParse[@"updateDate"];
    NSError *error = nil;
    [self.managedObjectContext save:&error];
    dispatch_async(dispatch_get_global_queue( DISPATCH_QUEUE_PRIORITY_LOW, 0), ^{
        if (imageData) {
            [imageData writeToFile:[self documentsPathForFileName:coreDataObject.imageName] atomically:YES];
        }
    });
}

- (void) replaceParseObject:(PFObject *) parseObject withCoreDataObject: (Event *) objectCoreData
{
    parseObject[@"title"] = objectCoreData.title;
    parseObject[@"content"] = objectCoreData.content;
    parseObject[@"createDate"] = objectCoreData.date;
    parseObject[@"updateDate"] = objectCoreData.updateDate;
    parseObject[@"imageName"] = objectCoreData.imageName;
    NSData *data = [self getImageFromDocumentsWithName:objectCoreData.imageName];
    if (data) {
        PFFile *file = [PFFile fileWithName:@"image.png" data:data];
        [file saveInBackground];
        parseObject[@"image"] = file;
    }
    else
    {
        [parseObject removeObjectForKey:@"image"];
    }
    [parseObject saveInBackground];
}

- (void) saveDetailItem: (Event *)detailItem
              withTitle:(NSString *)title
            withContent:(NSString *) content
          withImageData: (NSData *) imageData{
    if (imageData) {
        dispatch_async(dispatch_get_global_queue( DISPATCH_QUEUE_PRIORITY_LOW, 0), ^{
            [self deleteImageFromDocumentsWithName:detailItem.imageName];
            [imageData writeToFile:[self documentsPathForFileName:detailItem.imageName] atomically:YES];
        });
    }
    detailItem.title = title;
    detailItem.content = content;
    detailItem.updateDate = [NSDate date];
    NSError *error = nil;
    if (![self.managedObjectContext save:&error]) {
        NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
        abort();
    }
    
    PFQuery *query = [PFQuery queryWithClassName:@"note"];
    [query whereKey:@"createDate" equalTo:detailItem.date];
    [query getFirstObjectInBackgroundWithBlock:^(PFObject *object, NSError *error) {
        if (!object) {
            NSLog(@"The getFirstObject request failed.");
        } else {
            // The find succeeded.
            object[@"title"] = title;
            object[@"content"] = content;
            object[@"updateDate"] = [NSDate date];
            if (imageData) {
                PFFile *file = [PFFile fileWithName:@"image.png" data:imageData];
                [file saveInBackground];
                object[@"image"] = file;
            }
            [object saveInBackground];
        }
    }];

    
}

- (void) removeObjectFromCoreDataAnywhere:(Event *) objectFromCoreData
{
    [self removeObjectFromParseWithCreateDate:objectFromCoreData.date];
    [self.managedObjectContext deleteObject:objectFromCoreData];
    [self deleteImageFromDocumentsWithName:objectFromCoreData.imageName];
    NSError *error = nil;
    if (![self.managedObjectContext save:&error]) {
        NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
        abort();
    }
}

- (void) syncWithParse
{
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] initWithEntityName:@"Event"];
    
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"Event" inManagedObjectContext:self.managedObjectContext];
    [fetchRequest setEntity:entity];
    NSMutableArray *array = [[self.managedObjectContext executeFetchRequest:fetchRequest error:nil] mutableCopy];
    for (Event *object in array) {
        if ([object.needToDelete isEqual:@YES])
        {
            [self removeObjectFromCoreDataAnywhere:object];
        }
    }
    NSMutableArray *arrayFromCoreData = [[self.managedObjectContext executeFetchRequest:fetchRequest error:nil] mutableCopy];
    PFQuery *query = [PFQuery queryWithClassName:@"note"];
    NSMutableIndexSet *indexesForCoreData = [[NSMutableIndexSet alloc] init];
    NSMutableIndexSet *indexesForParse = [[NSMutableIndexSet alloc] init];
    [query findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
        if (!error) {
            NSMutableArray *arrayFromParse = [[NSMutableArray alloc] initWithArray:objects];
            for (int i=0;i<arrayFromCoreData.count;i++) {
                Event *objectFromCoreData = [arrayFromCoreData objectAtIndex:i];
                for (int j=0;j<arrayFromParse.count;j++)
                {
                    PFObject *objectFromParse = [arrayFromParse objectAtIndex:j];
                    NSTimeInterval intervalUpdateDates = [objectFromCoreData.updateDate timeIntervalSinceDate:[objectFromParse valueForKey:@"updateDate"]];
                    if((intervalUpdateDates<epsilon) && (intervalUpdateDates>(-epsilon))) {
                        [indexesForCoreData addIndex:i];
                        [indexesForParse addIndex:j];
                        break;
                    }
                    NSInteger intervalCreateDates = [objectFromCoreData.date timeIntervalSinceDate:[objectFromParse valueForKey:@"createDate"]];
                    if ((intervalCreateDates<epsilon) && (intervalCreateDates>(-epsilon))) {
                        if([objectFromCoreData.updateDate compare:[objectFromParse valueForKey:@"updateDate"]] == NSOrderedDescending)
                        {
                            [self replaceParseObject:objectFromParse withCoreDataObject:objectFromCoreData];
                        }
                        else
                        {
                            [self replaceCoreDataObject:objectFromCoreData withParseObject:objectFromParse];
                        }
                        [indexesForCoreData addIndex:i];
                        [indexesForParse addIndex:j];
                    }
                }
            }
            
            [arrayFromCoreData removeObjectsAtIndexes:indexesForCoreData];
            [arrayFromParse removeObjectsAtIndexes:indexesForParse];
            
            //if we have data at CoreData, but haven't this data at Parse
            if (arrayFromCoreData.count) {
                for (int i = 0; i<arrayFromCoreData.count; i++) {
                    Event *objectFromCoreData = [arrayFromCoreData objectAtIndex:i];
                    PFObject *objectForParse = [PFObject objectWithClassName:@"note"];
                    objectForParse[@"title"] = objectFromCoreData.title;
                    objectForParse[@"content"] = objectFromCoreData.content;
                    objectForParse[@"createDate"] = objectFromCoreData.date;
                    objectForParse[@"updateDate"] = objectFromCoreData.updateDate ;
                    objectForParse[@"imageName"] = objectFromCoreData.imageName;
                    NSData *data = [self getImageFromDocumentsWithName:objectFromCoreData.imageName];
                    if (data) {
                        PFFile *file = [PFFile fileWithName:@"image.png" data:data];
                        [file saveInBackground];
                        objectForParse[@"image"] = file;
                    }
                    [objectForParse saveInBackground];
                }
            }
            
            //if we have data at Parse, but haven't this data at CoreData
            if (arrayFromParse.count) {
                for (int i = 0; i<arrayFromParse.count; i++) {
                    PFObject *objectForCoreData = [arrayFromParse objectAtIndex:i];
                    PFFile *image = objectForCoreData[@"image"];
                    NSData *imageData = [image getData];
                    [self addNewObjectToContextFromParseWithTitle:[objectForCoreData valueForKey:@"title"]
                                                      withContent:[objectForCoreData valueForKey:@"content"]
                                                        withImage:imageData
                                                   withCreateDate:[objectForCoreData valueForKey:@"createDate"]
                                                    withImageName:[objectForCoreData valueForKey:@"imageName"]
                                                   withUpdateDate:[objectForCoreData valueForKey:@"updateDate"]];
                }
            }
            
            
        } else {
            // Log details of the failure
            NSLog(@"Error: %@ %@", error, [error userInfo]);
        }
        dispatch_async(dispatch_get_main_queue(), ^{
            [[NSNotificationCenter defaultCenter] postNotificationName:@"Data not need to Parse" object:nil];
        });
    }];
}

- (void) removeObjectFromParseWithCreateDate:(NSDate *) date
{
    PFQuery *query = [PFQuery queryWithClassName:@"note"];
    [query whereKey:@"createDate" equalTo:date];
    [query getFirstObjectInBackgroundWithBlock:^(PFObject *object, NSError *error) {
        if (!object) {
            NSLog(@"The getFirstObject request failed.");
        } else {
            // The find succeeded.
            [object deleteInBackground];
        }
    }];
}

- (NSString *)makeStringFromDate:(NSDate *) date
{
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"yyyyMMddHHmmss"];
    NSString *newDate = [dateFormatter stringFromDate:date];
    return newDate;
}

- (NSString *)documentsPathForFileName:(NSString *)name
{
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory,NSUserDomainMask, YES);
    NSString *documentsPath = [paths objectAtIndex:0];
    NSString *newName = [NSString stringWithFormat:@"%@.png",name];
    
    return [documentsPath stringByAppendingPathComponent:newName];
}

-(void)addNewObjectToContextFromParseWithTitle:(NSString *)title
                                   withContent:(NSString *)content
                                     withImage:(NSData *) image
                                withCreateDate:(NSDate *) createDate
                                 withImageName:(NSString *) imageName
                                withUpdateDate:(NSDate *) updateDate
{
    Event *newNote = [NSEntityDescription insertNewObjectForEntityForName:@"Event"
                                                   inManagedObjectContext:[[DataManager sharedManager] managedObjectContext]];
    newNote.title = title;
    newNote.content = content;
    newNote.date = createDate;
    newNote.updateDate = updateDate;
    newNote.imageName = imageName;
    NSError *error = nil;
    [self.managedObjectContext save:&error];
    dispatch_async(dispatch_get_global_queue( DISPATCH_QUEUE_PRIORITY_LOW, 0), ^{
        if (image) {
            [image writeToFile:[self documentsPathForFileName:newNote.imageName] atomically:YES];
        }
    });
    
}

-(void)addNewObjectToContextWithTitle:(NSString *)title withContent:(NSString *)content withImage:(NSData *) image
{
    Event *newNote = [NSEntityDescription insertNewObjectForEntityForName:@"Event"
                                                   inManagedObjectContext:[[DataManager sharedManager] managedObjectContext]];
    newNote.title = title;
    newNote.content = content;
    newNote.date = [NSDate date];
    newNote.updateDate = newNote.date;
    newNote.imageName = [[NSUUID UUID] UUIDString];
    NSError *error = nil;
    [self.managedObjectContext save:&error];
    dispatch_async(dispatch_get_global_queue( DISPATCH_QUEUE_PRIORITY_LOW, 0), ^{
        if (image) {
            [image writeToFile:[self documentsPathForFileName:newNote.imageName] atomically:YES];
        }
    });
    PFObject *parseObject = [PFObject objectWithClassName:@"note"];
    parseObject[@"title"] = title;
    parseObject[@"content"] = content;
    parseObject[@"createDate"] = newNote.date;
    parseObject[@"updateDate"] = newNote.date;
    parseObject[@"imageName"] = newNote.imageName;
    if (image) {
        PFFile *file = [PFFile fileWithName:@"image.png" data:image];
        [file saveInBackground];
        parseObject[@"image"] = file;
    }
    [parseObject saveInBackground];

}

- (NSData *)getImageFromDocumentsWithName: (NSString *) imageName
{
    NSData *pngData = [NSData dataWithContentsOfFile:[self documentsPathForFileName:imageName]];
    return pngData;
}

- (void)deleteImageFromDocumentsWithName:(NSString *)imageName
{
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSError *error;
    [fileManager removeItemAtPath:[self documentsPathForFileName:imageName] error:&error];
}

#pragma mark - Search Methods

- (NSArray *)searchForText:(NSString *)searchText scope:(UYLWorldFactsSearchScope)scopeOption
{
    if (self.managedObjectContext)
    {
        NSString *predicateFormat = @"%K contains[c] %@";
        NSString *searchAttribute = @"title";
        
        NSString *predicateFormat1 = @"%K == %@";
        NSString *searchAttribute1 = @"needToDelete";
        if (scopeOption == searchScopeContent)
        {
            searchAttribute = @"content";
        }
        
        NSPredicate *predicate = [NSPredicate predicateWithFormat:predicateFormat, searchAttribute, searchText];
        NSPredicate *predicate1 = [NSPredicate predicateWithFormat:predicateFormat1, searchAttribute1, @NO];
        NSArray *tempPredicates = [[NSArray alloc] initWithObjects:predicate, predicate1, nil];
        NSPredicate *compoundPredicate
        = [NSCompoundPredicate andPredicateWithSubpredicates:tempPredicates];
        
        [self.searchFetchRequest setPredicate:compoundPredicate];
        NSError *error = nil;
        self.filteredList = [self.managedObjectContext executeFetchRequest:self.searchFetchRequest error:&error];
        if (error)
        {
            NSLog(@"searchFetchRequest failed: %@",[error localizedDescription]);
        }
    }
    return self.filteredList;
}

- (NSFetchRequest *)searchFetchRequest
{
    if (_searchFetchRequest != nil)
    {
        return _searchFetchRequest;
    }
    
    _searchFetchRequest = [[NSFetchRequest alloc] init];
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"Event" inManagedObjectContext:self.managedObjectContext];
    [_searchFetchRequest setEntity:entity];
    
    NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"date" ascending:NO];
    NSArray *sortDescriptors = [NSArray arrayWithObjects:sortDescriptor, nil];
    [_searchFetchRequest setSortDescriptors:sortDescriptors];
    
    return _searchFetchRequest;
}


#pragma mark - Core Data stack

@synthesize managedObjectContext = managedObjectContext_;
@synthesize managedObjectModel = _managedObjectModel;
@synthesize persistentStoreCoordinator = _persistentStoreCoordinator;

- (NSURL *)applicationDocumentsDirectory {
    // The directory the application uses to store the Core Data store file. This code uses a directory named "Alex-Kartsev.Note" in the application's documents directory.
    return [[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject];
}

- (NSManagedObjectModel *)managedObjectModel {
    // The managed object model for the application. It is a fatal error for the application not to be able to find and load its model.
    if (_managedObjectModel != nil) {
        return _managedObjectModel;
    }
    NSURL *modelURL = [[NSBundle mainBundle] URLForResource:@"Note" withExtension:@"momd"];
    _managedObjectModel = [[NSManagedObjectModel alloc] initWithContentsOfURL:modelURL];
    return _managedObjectModel;
}

- (void) updateDataBase
{
    NSURL *storeURL = [[self applicationDocumentsDirectory] URLByAppendingPathComponent:@"Note.sqlite"];
    NSDictionary *options = @{NSMigratePersistentStoresAutomaticallyOption: @YES,
                              NSInferMappingModelAutomaticallyOption: @YES};
    NSError *error = nil;
    [_persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:storeURL options:options error:&error];
    dispatch_async(dispatch_get_main_queue(), ^{
        [[NSNotificationCenter defaultCenter] postNotificationName:@"Data base updated" object:nil];
    });
}

- (NSPersistentStoreCoordinator *)persistentStoreCoordinator {
    if (_persistentStoreCoordinator != nil) {
        return _persistentStoreCoordinator;
    }
    _persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:[self managedObjectModel]];
    NSURL *storeURL = [[self applicationDocumentsDirectory] URLByAppendingPathComponent:@"Note.sqlite"];
    NSError *error = nil;
    if ([_persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:storeURL options:nil error:&error]) {
        [[NSNotificationCenter defaultCenter] postNotificationName:@"Data base not need to updating" object:nil];
    }
    return _persistentStoreCoordinator;
}


- (NSManagedObjectContext *)managedObjectContext {
    // Returns the managed object context for the application (which is already bound to the persistent store coordinator for the application.)
    if (managedObjectContext_ != nil) {
        return managedObjectContext_;
    }
    
    NSPersistentStoreCoordinator *coordinator = [self persistentStoreCoordinator];
    if (!coordinator) {
        return nil;
    }
    managedObjectContext_ = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSMainQueueConcurrencyType];
    [managedObjectContext_ setPersistentStoreCoordinator:coordinator];
    return managedObjectContext_;
}

#pragma mark - Core Data Saving support

- (void)saveContext {
    NSManagedObjectContext *managedObjectContext = self.managedObjectContext;
    if (managedObjectContext != nil) {
        NSError *error = nil;
        if ([managedObjectContext hasChanges] && ![managedObjectContext save:&error]) {
            NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
            abort();
        }
    }
}


@end
