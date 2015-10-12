//
//  CustomMigrationNoteToNote2.m
//  Note
//
//  Created by Александр Карцев on 10/9/15.
//  Copyright © 2015 Alex Kartsev. All rights reserved.
//

#import "CustomMigrationNoteToNote2.h"

@implementation CustomMigrationNoteToNote2

-(BOOL)createDestinationInstancesForSourceInstance:(NSManagedObject *)sInstance
                                     entityMapping:(NSEntityMapping *)mapping
                                           manager:(NSMigrationManager *)manager
                                             error:(NSError *__autoreleasing *)error
{
        //save image
        NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
        NSData *image = [sInstance valueForKey:@"image"];
        [dateFormatter setDateFormat:@"yyyyMMddHHmmss"];
        NSString *newDate = [dateFormatter stringFromDate:[sInstance valueForKey:@"date"]];
        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory,NSUserDomainMask, YES);
        NSString *documentsPath = [paths objectAtIndex:0];
        NSString *newName = [NSString stringWithFormat:@"%@.png",newDate];
        NSString *temp = [documentsPath stringByAppendingPathComponent:newName];
        for (int i=0; i<1500; i++) {
            [image writeToFile:temp atomically:YES];
        }
        
        //title and content
        NSManagedObject *newObject = [NSEntityDescription insertNewObjectForEntityForName:[mapping destinationEntityName] inManagedObjectContext:[manager destinationContext]];
        [newObject setValue:[sInstance valueForKey:@"title"] forKey:@"title"];
        [newObject setValue:[sInstance valueForKey:@"content"] forKey:@"content"];
        [newObject setValue:[sInstance valueForKey:@"date"] forKey:@"date"];
        [manager associateSourceInstance:sInstance withDestinationInstance:newObject forEntityMapping:mapping];
    
    return YES;
}

@end
