//
//  DataManager.h
//  Note
//
//  Created by Александр Карцев on 10/7/15.
//  Copyright © 2015 Alex Kartsev. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "CustomMigrationNoteToNote2.h"
#import "Reachability.h"
#import "Event.h"

@interface DataManager : NSObject

typedef NS_ENUM(NSInteger, UYLWorldFactsSearchScope)
{
    searchScopeTitle = 0,
    searchScopeContent = 1
};

@property (readonly, strong, nonatomic) NSManagedObjectContext *managedObjectContext;
@property (readonly, strong, nonatomic) NSManagedObjectModel *managedObjectModel;
@property (readonly, strong, nonatomic) NSPersistentStoreCoordinator *persistentStoreCoordinator;

+ (DataManager*) sharedManager;

- (void) saveContext;

- (void) addNewObjectToContextWithTitle:(NSString *)title
                          withContent:(NSString *)content
                            withImage:(NSData *) image;

- (NSArray *) searchForText:(NSString *)searchText scope:(UYLWorldFactsSearchScope)scopeOption;

- (NSData *) getImageFromDocumentsWithName: (NSString *) imageName;

- (void) deleteImageFromDocumentsWithName:(NSString *)imageName;

- (void) updateDataBase;

- (void) syncWithParse;

- (void) removeObjectFromParseWithCreateDate:(NSDate *) date;

- (NSString *) documentsPathForFileName:(NSString *)name;

- (void) saveDetailItem: (Event *)detailItem
              withTitle:(NSString *)title
            withContent:(NSString *) content
          withImageData: (NSData *) imageData;

@end
