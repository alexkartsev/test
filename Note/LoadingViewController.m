//
//  LoadingViewController.m
//  Note
//
//  Created by Александр Карцев on 10/12/15.
//  Copyright © 2015 Alex Kartsev. All rights reserved.
//

#import "LoadingViewController.h"
#import "MBProgressHud.h"
#import "SplitViewController.h"
#import "DataManager.h"

@interface LoadingViewController ()

@property (strong, nonatomic) MBProgressHUD *hud;

@end

@implementation LoadingViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(stopWrite) name:@"Data base need to updating" object:nil];
    self.hud.labelText = @"Updating Data Base";
    self.hud = [MBProgressHUD showHUDAddedTo:[[UIApplication sharedApplication].delegate window].rootViewController.view animated:YES];
    // Do any additional setup after loading the view.
}

- (void) viewDidAppear:(BOOL)animated
{
    dispatch_async(dispatch_get_global_queue( DISPATCH_QUEUE_PRIORITY_LOW, 0), ^{
        [[DataManager sharedManager] updateDataBase];});
}

- (void) stopWrite
{
    [self.hud hide:YES];
    SplitViewController *dvc = [self.storyboard instantiateViewControllerWithIdentifier:@"splitViewController"];
    [dvc setModalTransitionStyle:UIModalTransitionStyleCoverVertical];
    [self presentViewController:dvc animated:YES completion:nil];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
