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

@interface DataManager : NSObject

typedef NS_ENUM(NSInteger, UYLWorldFactsSearchScope)
{
    searchScopeTitle = 0,
    searchScopeContent = 1
};

@property (readonly, strong, nonatomic) NSManagedObjectContext *childManagedObjectContext;
@property (readonly, strong, nonatomic) NSManagedObjectContext *managedObjectContext;
@property (readonly, strong, nonatomic) NSManagedObjectModel *managedObjectModel;
@property (readonly, strong, nonatomic) NSPersistentStoreCoordinator *persistentStoreCoordinator;

+ (DataManager*)sharedManager;

- (void)saveContext;

- (void)asyncSavingOfNSManagedObject: (NSManagedObject *) aObject
                            withImage: (NSData *)image
                             withName: (NSString *) imageName;

-(void)addNewObjectToContextWithTitle:(NSString *)title
                          withContent:(NSString *)content
                            withImage:(NSData *) image;

- (NSArray *)searchForText:(NSString *)searchText scope:(UYLWorldFactsSearchScope)scopeOption;

- (NSData *)getImageFromDocumentsWithName: (NSString *) imageName;

- (void)deleteImageFromDocumentsWithName:(NSString *)imageName;

@end
