//
//  DetailViewController.h
//  Note
//
//  Created by Александр Карцев on 10/6/15.
//  Copyright © 2015 Alex Kartsev. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreData/CoreData.h>
#import "DataManager.h"

@interface DetailViewController : UIViewController <UIImagePickerControllerDelegate, UINavigationControllerDelegate>
{
    
}

@property (strong, nonatomic) id detailItem;

@end

