//
//  DetailViewController.h
//  Note
//
//  Created by Александр Карцев on 10/6/15.
//  Copyright © 2015 Alex Kartsev. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface DetailViewController : UIViewController

@property (strong, nonatomic) id detailItem;
@property (weak, nonatomic) IBOutlet UILabel *detailDescriptionLabel;

@end

