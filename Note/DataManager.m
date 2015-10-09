//
//  DataManager.m
//  Note
//
//  Created by Александр Карцев on 10/7/15.
//  Copyright © 2015 Alex Kartsev. All rights reserved.
//

#import "DataManager.h"

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
        // Initialization nested contexts
        
        childManagedObjectContext_ = [[NSManagedObjectContext alloc]
                  initWithConcurrencyType:NSMainQueueConcurrencyType];
        
        //The parent context has ConcurrencyType Private Queue to let him perform asyn operation
        managedObjectContext_ = [[NSManagedObjectContext alloc]
                   initWithConcurrencyType:NSPrivateQueueConcurrencyType];
        
        
        NSPersistentStoreCoordinator *coordinator = self.persistentStoreCoordinator;
        if (coordinator != nil) {
            
            [managedObjectContext_ setPersistentStoreCoordinator:coordinator];
        }
        
        
        [childManagedObjectContext_ setParentContext:managedObjectContext_];
        
    }
    
    return self;
}

- (void) asyncSavingOfNSManagedObject: (NSManagedObject *) aObject
                            withImage: (NSData *)image
                             withName: (NSString *) imageName
{
    NSError *error = nil;
    __block NSError *parentError = nil;
    
    //Commit changes in child MOC (Managed Object Context)
    [self.childManagedObjectContext save:&error];
    
    if(!error){
        //Save async in the parent MOC (Managed Object Context)
        [self.managedObjectContext performBlock:^{
            
            [self.managedObjectContext save:&parentError];
            
            if (image) {
                [image writeToFile:[self documentsPathForFileName:imageName] atomically:YES];
            }
            
            if(parentError){
                
                NSLog(@"%s Error saving parent context", __PRETTY_FUNCTION__);
            }
            
            
        }];
    }else {
        NSLog(@"%s Error saving child context", __PRETTY_FUNCTION__);
    }
    
}

- (NSString *)documentsPathForFileName:(NSString *)name
{
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory,NSUserDomainMask, YES);
    NSString *documentsPath = [paths objectAtIndex:0];
    NSString *newName = [NSString stringWithFormat:@"%@.png",name];

    return [documentsPath stringByAppendingPathComponent:newName];
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
    
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];

    // Convert to new Date Format
    [dateFormatter setDateFormat:@"yyyyMMddHHmmss"];
    NSString *newDate = [dateFormatter stringFromDate:[NSDate date]];
    [self asyncSavingOfNSManagedObject:newNote withImage:image withName:newDate];
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
        
        if (scopeOption == searchScopeContent)
        {
            searchAttribute = @"content";
        }
        
        NSPredicate *predicate = [NSPredicate predicateWithFormat:predicateFormat, searchAttribute, searchText];
        [self.searchFetchRequest setPredicate:predicate];
        
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

@synthesize childManagedObjectContext = childManagedObjectContext_;
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

- (NSPersistentStoreCoordinator *)persistentStoreCoordinator {
    // The persistent store coordinator for the application. This implementation creates and returns a coordinator, having added the store for the application to it.
    if (_persistentStoreCoordinator != nil) {
        return _persistentStoreCoordinator;
    }
    
    // Create the coordinator and store
    
    _persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:[self managedObjectModel]];
    NSURL *storeURL = [[self applicationDocumentsDirectory] URLByAppendingPathComponent:@"Note.sqlite"];
    NSError *error = nil;
    NSDictionary *options = @{NSMigratePersistentStoresAutomaticallyOption: @YES,
                              NSInferMappingModelAutomaticallyOption: @YES};
    NSString *failureReason = @"There was an error creating or loading the application's saved data.";
    if (![_persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:storeURL options:options error:&error]) {
        // Report any error we got.
        NSMutableDictionary *dict = [NSMutableDictionary dictionary];
        dict[NSLocalizedDescriptionKey] = @"Failed to initialize the application's saved data";
        dict[NSLocalizedFailureReasonErrorKey] = failureReason;
        dict[NSUnderlyingErrorKey] = error;
        error = [NSError errorWithDomain:@"YOUR_ERROR_DOMAIN" code:9999 userInfo:dict];
        // Replace this with code to handle the error appropriately.
        // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
        NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
        abort();
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


- (NSManagedObjectContext *)childManagedObjectContext {
    // Returns the managed object context for the application (which is already bound to the persistent store coordinator for the application.)
    if (childManagedObjectContext_ != nil) {
        return childManagedObjectContext_;
    }
    
    NSPersistentStoreCoordinator *coordinator = [self persistentStoreCoordinator];
    if (!coordinator) {
        return nil;
    }
    childManagedObjectContext_ = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSMainQueueConcurrencyType];
    [childManagedObjectContext_ setPersistentStoreCoordinator:coordinator];
    return childManagedObjectContext_;
}

#pragma mark - Core Data Saving support

- (void)saveContext {
    NSManagedObjectContext *managedObjectContext = self.managedObjectContext;
    if (managedObjectContext != nil) {
        NSError *error = nil;
        if ([managedObjectContext hasChanges] && ![managedObjectContext save:&error]) {
            // Replace this implementation with code to handle the error appropriately.
            // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
            NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
            abort();
        }
    }
}


@end
