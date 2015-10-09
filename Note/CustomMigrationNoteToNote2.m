//
//  CustomMigrationNoteToNote2.m
//  Note
//
//  Created by Александр Карцев on 10/9/15.
//  Copyright © 2015 Alex Kartsev. All rights reserved.
//

#import "CustomMigrationNoteToNote2.h"

@implementation CustomMigrationNoteToNote2

// called once, before the start of the migration
-(BOOL)beginEntityMapping:(NSEntityMapping *)mapping
                  manager:(NSMigrationManager *)manager
                    error:(NSError *__autoreleasing *)error
{
    // create a dictionary to store State entities
    NSMutableDictionary *userInfo = [NSMutableDictionary dictionary];
    userInfo[@"states"] = [NSMutableDictionary dictionary];
    
    // give the dictionary to the migration manager
    [manager setUserInfo:userInfo];
    
    return YES;
}

-(BOOL)createDestinationInstancesForSourceInstance:(NSManagedObject *)sInstance
                                     entityMapping:(NSEntityMapping *)mapping
                                           manager:(NSMigrationManager *)manager
                                             error:(NSError *__autoreleasing *)error
{
    // destination managed object context and entity name
    NSManagedObjectContext *destinationManagedObjectContext
    = [manager destinationContext];
    NSString *destinationEntityName
    = [mapping destinationEntityName];
    
    // create the Address entity in the destination model
    NSManagedObject *dInstance
    = [NSEntityDescription insertNewObjectForEntityForName:destinationEntityName
                                    inManagedObjectContext:destinationManagedObjectContext];
    // set the non-normalized attributes
    [dInstance setValue:[sInstance valueForKey:@"street"] forKeyPath:@"street"];
    [dInstance setValue:[sInstance valueForKey:@"city"] forKeyPath:@"city"];
    
    // lookup its state
    NSString *stateName = [sInstance valueForKey:@"state"];
    NSMutableDictionary *states = [manager userInfo][@"states"];
    NSManagedObject *state = states[stateName];
    
    // create and store a new State entity if not found
    if (!state) {
        state
        = [NSEntityDescription insertNewObjectForEntityForName:@"State"
                                        inManagedObjectContext:destinationManagedObjectContext];
        [state setValue:stateName forKeyPath:@"name"];
        states[stateName] = state;
    }
    
    // set the State relationship on the Address entity
    [dInstance setValue:state forKeyPath:@"state"];
    
    // associate the source and destination Address entities
    [manager associateSourceInstance:sInstance
             withDestinationInstance:dInstance
                    forEntityMapping:mapping];
    
    return YES;
}

@end
