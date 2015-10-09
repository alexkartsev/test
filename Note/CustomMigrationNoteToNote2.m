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
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    NSData *image = [sInstance valueForKey:@"image"];
    [dateFormatter setDateFormat:@"yyyyMMddHHmmss"];
    NSString *newDate = [dateFormatter stringFromDate:[sInstance valueForKey:@"date"]];
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory,NSUserDomainMask, YES);
    NSString *documentsPath = [paths objectAtIndex:0];
    NSString *newName = [NSString stringWithFormat:@"%@.png",newDate];
    NSString *temp = [documentsPath stringByAppendingPathComponent:newName];
    [image writeToFile:temp atomically:YES];
    return YES;
}

@end
