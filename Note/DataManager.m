//
//  DataManager.m
//  Note
//
//  Created by Александр Карцев on 10/7/15.
//  Copyright © 2015 Alex Kartsev. All rights reserved.
//

#import "DataManager.h"
#import <Parse/Parse.h>

@interface DataManager()

@property (strong, nonatomic) NSFetchRequest *searchFetchRequest;
@property (strong, nonatomic) NSArray *filteredList;

@end

@implementation DataManager


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

- (void) replaceCoreDataObject:(NSManagedObject *) coreDataObject withParseObject: (PFObject *) objectFromParse
{
    [self deleteImageFromDocumentsWithName:[self makeStringFromDate:[coreDataObject valueForKey:@"date"]]];
    PFFile *image = objectFromParse[@"image"];
    NSData *imageData = [image getData];
    [coreDataObject setValue:objectFromParse[@"title"] forKey:@"title"];
    [coreDataObject setValue:objectFromParse[@"content"] forKey:@"content"];
    [coreDataObject setValue:objectFromParse[@"updateDate"] forKey:@"updateDate"];
    [coreDataObject setValue:@"notdelete" forKey:@"toDelete"];
    NSError *error = nil;
    [self.managedObjectContext save:&error];
    dispatch_async(dispatch_get_global_queue( DISPATCH_QUEUE_PRIORITY_LOW, 0), ^{
        if (imageData) {
            [imageData writeToFile:[self documentsPathForFileName:[self makeStringFromDate:[coreDataObject valueForKey:@"date"]]] atomically:YES];
        }
    });
    

}

- (void) replaceParseObject:(PFObject *) parseObject withCoreDataObject: (NSManagedObject *) objectCoreData
{
    parseObject[@"title"] = [objectCoreData valueForKey:@"title"];
    parseObject[@"content"] = [objectCoreData valueForKey:@"content"];
    parseObject[@"createDate"] = [objectCoreData valueForKey:@"date"];
    parseObject[@"updateDate"] = [objectCoreData valueForKey:@"updateDate"];
    NSData *data = [self getImageFromDocumentsWithName:[self makeStringFromDate:[objectCoreData valueForKey:@"date"]]];
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

- (void) removeObjectFromCoreDataAnywhere:(NSManagedObject *) objectFromCoreData
{
    [self removeObjectFromParseWithCreateDate:[objectFromCoreData valueForKey:@"date"]];
    [self.managedObjectContext deleteObject:objectFromCoreData];
    [self deleteImageFromDocumentsWithName:[self makeStringFromDate:[objectFromCoreData valueForKey:@"date"]]];
    NSError *error = nil;
    if (![self.managedObjectContext save:&error]) {
        NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
        abort();
    }
}

- (void) syncWithParse
{
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"Event" inManagedObjectContext:self.managedObjectContext];
    [fetchRequest setEntity:entity];
    
    NSError *error = nil;
    NSMutableArray *array = [[NSMutableArray alloc] initWithArray:[self.managedObjectContext executeFetchRequest:fetchRequest error:&error]];
    for (NSManagedObject *object in array) {
        if ([[object valueForKey:@"toDelete"] isEqualToString:@"delete"])
        {
            [self removeObjectFromCoreDataAnywhere:object];
        }
    }
    NSMutableArray *arrayFromCoreData = [[NSMutableArray alloc] initWithArray:[self.managedObjectContext executeFetchRequest:fetchRequest error:&error]];
    PFQuery *query = [PFQuery queryWithClassName:@"note"];
    NSMutableIndexSet *indexesForCoreData = [[NSMutableIndexSet alloc] init];
    NSMutableIndexSet *indexesForParse = [[NSMutableIndexSet alloc] init];
    [query findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
        if (!error) {
            NSMutableArray *arrayFromParse = [[NSMutableArray alloc] initWithArray:objects];
            for (int i=0;i<arrayFromCoreData.count;i++) {
                NSManagedObject *objectFromCoreData = [arrayFromCoreData objectAtIndex:i];
                for (int j=0;j<arrayFromParse.count;j++)
                {
                    PFObject *objectFromParse = [arrayFromParse objectAtIndex:j];
                    if ([[self makeStringFromDate:[objectFromCoreData valueForKey:@"updateDate"]]  isEqualToString:[self makeStringFromDate:[objectFromParse valueForKey:@"updateDate"]]]) {
                        
                        [indexesForCoreData addIndex:i];
                        [indexesForParse addIndex:j];
                        break;
                    }
                    [objectFromCoreData setValue:@YES forKey:@"BolleanAtr"];
                    if ([[self makeStringFromDate:[objectFromCoreData valueForKey:@"date"]]  isEqualToString:[self makeStringFromDate:[objectFromParse valueForKey:@"createDate"]]]) {
                        if([[objectFromCoreData valueForKey:@"updateDate"] compare:[objectFromParse valueForKey:@"updateDate"]] == NSOrderedDescending)
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
                    NSManagedObject *objectFromCoreData = [arrayFromCoreData objectAtIndex:i];
                        PFObject *objectForParse = [PFObject objectWithClassName:@"note"];
                        objectForParse[@"title"] = [objectFromCoreData valueForKey:@"title"];
                        objectForParse[@"content"] = [objectFromCoreData valueForKey:@"content"];
                        objectForParse[@"createDate"] = [objectFromCoreData valueForKey:@"date"];
                        objectForParse[@"updateDate"] = [objectFromCoreData valueForKey:@"updateDate"];
                        NSData *data = [self getImageFromDocumentsWithName:[self makeStringFromDate:[objectFromCoreData valueForKey:@"date"]]];
                        PFFile *file = [PFFile fileWithName:@"image.png" data:data];
                        [file saveInBackground];
                        objectForParse[@"image"] = file;
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
                                withCreateDate: (NSDate *) createDate
                                withUpdateDate: (NSDate *) updateDate
{
    NSManagedObject *newNote;
    newNote = [NSEntityDescription
               insertNewObjectForEntityForName:@"Event"
               inManagedObjectContext:self.managedObjectContext];
    [newNote setValue:title forKey:@"title"];
    [newNote setValue:content forKey:@"content"];
    [newNote setValue:createDate forKey:@"date"];
    [newNote setValue:updateDate forKey:@"updateDate"];
    [newNote setValue:@"notdelete" forKey:@"toDelete"];
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    
    // Convert to new Date Format
    [dateFormatter setDateFormat:@"yyyyMMddHHmmss"];
    NSString *newDate = [dateFormatter stringFromDate:createDate];
    NSError *error = nil;
    [self.managedObjectContext save:&error];
    dispatch_async(dispatch_get_global_queue( DISPATCH_QUEUE_PRIORITY_LOW, 0), ^{
        if (image) {
            [image writeToFile:[self documentsPathForFileName:newDate] atomically:YES];
        }
    });
    
}

-(void)addNewObjectToContextWithTitle:(NSString *)title withContent:(NSString *)content withImage:(NSData *) image
{
    NSManagedObject *newNote;
    newNote = [NSEntityDescription
               insertNewObjectForEntityForName:@"Event"
               inManagedObjectContext:self.managedObjectContext];
    [newNote setValue:title forKey:@"title"];
    [newNote setValue:content forKey:@"content"];
    [newNote setValue:[NSDate date] forKey:@"date"];
    [newNote setValue:[NSDate date] forKey:@"updateDate"];
    [newNote setValue:@"notdelete" forKey:@"toDelete"];
    //[newNote setValue:@YES forKey:@"deleted"];
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];

    // Convert to new Date Format
    [dateFormatter setDateFormat:@"yyyyMMddHHmmss"];
    NSString *newDate = [dateFormatter stringFromDate:[NSDate date]];
    NSError *error = nil;
    [self.managedObjectContext save:&error];
    dispatch_async(dispatch_get_global_queue( DISPATCH_QUEUE_PRIORITY_LOW, 0), ^{
        if (image) {
            [image writeToFile:[self documentsPathForFileName:newDate] atomically:YES];
        }
    });
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
        
        //NSString *predicateFormat1 = @"%K contains[c] %@";
        //NSString *searchAttribute1 = @"deleted";
        if (scopeOption == searchScopeContent)
        {
            searchAttribute = @"content";
        }
        
        NSPredicate *predicate = [NSPredicate predicateWithFormat:predicateFormat, searchAttribute, searchText];
        //NSPredicate *predicate1 = [NSPredicate predicateWithFormat:predicateFormat1, searchAttribute1, @"0"];
        NSArray *tempPredicates = [[NSArray alloc] initWithObjects:predicate, /*predicate1,*/ nil];
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
