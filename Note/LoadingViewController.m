//
//  LoadingViewController.m
//  Note
//
//  Created by Александр Карцев on 10/12/15.
//  Copyright © 2015 Alex Kartsev. All rights reserved.
//

#import "LoadingViewController.h"
#import "MBProgressHud.h"
#import "DataManager.h"

@interface LoadingViewController ()

@property (strong,nonatomic) MBProgressHUD * hud;

@end

@implementation LoadingViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(stopWrite) name:@"Data base updated" object:nil];
    dispatch_async(dispatch_get_global_queue( DISPATCH_QUEUE_PRIORITY_LOW, 0), ^{
        [[DataManager sharedManager] updateDataBase];});
    self.hud =  [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    NSString *strloadingText = [NSString stringWithFormat:@"Updating Data Base"];
    NSString *strloadingText2 = [NSString stringWithFormat:@" Please wait\r a few seconds"];
    self.hud.labelText = strloadingText;
    self.hud.detailsLabelText=strloadingText2;
}

- (void) stopWrite
{
        [self.hud hide:YES];
        [self performSegueWithIdentifier:@"segueToNextView" sender:self];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void) dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

@end
