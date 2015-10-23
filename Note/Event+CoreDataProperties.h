//
//  Event+CoreDataProperties.h
//  
//
//  Created by Александр Карцев on 10/23/15.
//
//
//  Choose "Create NSManagedObject Subclass…" from the Core Data editor menu
//  to delete and recreate this implementation file for your updated model.
//

#import "Event.h"

NS_ASSUME_NONNULL_BEGIN

@interface Event (CoreDataProperties)

@property (nullable, nonatomic, retain) NSString *content;
@property (nullable, nonatomic, retain) NSDate *date;
@property (nullable, nonatomic, retain) NSString *title;
@property (nullable, nonatomic, retain) NSDate *updateDate;
@property (nullable, nonatomic, retain) NSString *deleteNote;

@end

NS_ASSUME_NONNULL_END
