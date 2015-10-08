//
//  MergingNoteToNote2.m
//  Note
//
//  Created by Александр Карцев on 10/8/15.
//  Copyright © 2015 Alex Kartsev. All rights reserved.
//

#import "MergingNoteToNote2.h"

@implementation MergingNoteToNote2

- (BOOL)createDestinationInstancesForSourceInstance:(NSManagedObject *)sInstance entityMapping:(NSEntityMapping *)mapping manager:(NSMigrationManager *)manager error:(NSError **)error
{
    NSManagedObject *newObject = [NSEntityDescription insertNewObjectForEntityForName:[mapping destinationEntityName] inManagedObjectContext:[manager destinationContext]];
    NSString *title = [sInstance valueForKey:@"title"];
    [newObject setValue:title forKey:@"noteTitle"];
    [manager associateSourceInstance:sInstance withDestinationInstance:newObject forEntityMapping:mapping];
    
    return YES;  
}

@end
