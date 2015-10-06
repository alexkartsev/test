//
//  DetailViewController.m
//  Note
//
//  Created by Александр Карцев on 10/6/15.
//  Copyright © 2015 Alex Kartsev. All rights reserved.
//

#import "DetailViewController.h"

@interface DetailViewController ()
@property (weak, nonatomic) IBOutlet UITextField *titleTextField;
@property (weak, nonatomic) IBOutlet UITextView *contentTextView;

@end

@implementation DetailViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self configureView];
    
    UIBarButtonItem *saveButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemSave target:self action:@selector(saveButton)];
    self.navigationItem.rightBarButtonItem = saveButton;
    self.contentTextView.layer.borderWidth = 1.0f;
    self.contentTextView.layer.borderColor = [[UIColor grayColor] CGColor];
    UITapGestureRecognizer *touch = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(touchEndEditing)];
    [self.view addGestureRecognizer:touch];
}

- (void) touchEndEditing{
            [self.view endEditing:YES];
}

- (void) showAlertViewWithMessage:(NSString *) message
{
    UIAlertController *alertController = [UIAlertController  alertControllerWithTitle:@"Attention!"  message:message  preferredStyle:UIAlertControllerStyleAlert];
    [alertController addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        [self dismissViewControllerAnimated:YES completion:nil];
    }]];
    [self presentViewController:alertController animated:YES completion:nil];
}

-(void) saveButton
{
    if (self.titleTextField.text.length==0 || self.contentTextView.text.length==0) {
        [self showAlertViewWithMessage:@"Please enter Title and Content"];
    }
    else
    {
        if (self.detailItem)
        {
            [self.detailItem setValue:self.titleTextField.text forKey:@"title"];
            [self.detailItem setValue:self.contentTextView.text forKey:@"content"];
            NSError *error;
            [self.managedObjectContext save:&error];
            //[self.navigationController popToRootViewControllerAnimated:YES];
            UIViewController *prevVC = [self.navigationController.viewControllers objectAtIndex:0];
            [self.navigationController popToViewController:prevVC animated:YES];
            [self dismissViewControllerAnimated:YES completion:nil];
        }
        else
        {
            NSManagedObject *newNote;
            newNote = [NSEntityDescription
                       insertNewObjectForEntityForName:@"Event"
                       inManagedObjectContext:self.managedObjectContext];
            [newNote setValue:self.titleTextField.text forKey:@"title"];
            [newNote setValue:self.contentTextView.text forKey:@"content"];
            [newNote setValue:[NSDate date] forKey:@"date"];
            NSError *error;
            [self.managedObjectContext save:&error];
            [self.navigationController popViewControllerAnimated:YES];
        }
    }
}

#pragma mark - Managing the detail item

- (void)setDetailItem:(id)newDetailItem {
    if (_detailItem != newDetailItem) {
        _detailItem = newDetailItem;
            
        // Update the view.
        [self configureView];
    }
}

- (void)configureView {
    // Update the user interface for the detail item.
    if (self.detailItem) {
        self.titleTextField.text = [[self.detailItem valueForKey:@"title"] description];
        self.contentTextView.text = [[self.detailItem valueForKey:@"content"] description];
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
