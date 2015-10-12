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
#import "MasterViewController.h"

@interface LoadingViewController ()

@end

@implementation LoadingViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(stopWrite) name:@"Data base updated" object:nil];
    [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    // Do any additional setup after loading the view.
//    [self performSelector:@selector(stopWrite) withObject:nil afterDelay:3];
}

- (void) viewDidAppear:(BOOL)animated
{
    dispatch_async(dispatch_get_global_queue( DISPATCH_QUEUE_PRIORITY_LOW, 0), ^{
        [[DataManager sharedManager] updateDataBase];});
}

- (void) stopWrite
{
//    dispatch_async(dispatch_get_main_queue(), ^{
        [MBProgressHUD hideHUDForView:self.view animated:YES];
        [self performSegueWithIdentifier:@"segueToNextView" sender:self];
//    });
//    MasterViewController *dvc = [self.storyboard instantiateViewControllerWithIdentifier:@"masterTableViewController"];
//    [dvc setModalTransitionStyle:UIModalTransitionStyleCoverVertical];
//    [self.navigationController pushViewController:[[UINavigationController alloc] initWithRootViewController:dvc] animated:YES];
    

    
//    UIStoryboard *mainStoryboard = [UIStoryboard storyboardWithName:@"Main" bundle: nil];
//    SplitViewController *controller = (SplitViewController*)[mainStoryboard instantiateViewControllerWithIdentifier: @"splitViewController"];
//    //self.window.rootViewController = controller;
//    //UISplitViewController *splitViewController = (UISplitViewController *)self.window.rootViewController;
//    UINavigationController *navigationController = [splitViewController.viewControllers lastObject];
//    navigationController.topViewController.navigationItem.leftBarButtonItem = splitViewController.displayModeButtonItem;
//    splitViewController.delegate = self;

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
