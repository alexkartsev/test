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
@property (weak, nonatomic) IBOutlet UIImageView *imageView;
@property (strong, nonatomic) UIAlertController *alertEditImageController;
@property (strong, nonatomic) UIAlertController *alertAddingImageController;
@end

@implementation DetailViewController

bool imageWasChanged;

- (void)viewDidLoad {
    [super viewDidLoad];
    [self configureView];
    [self.imageView setUserInteractionEnabled:YES];
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(myTapImageMethod)];
    [tap setNumberOfTouchesRequired:1];
    [tap setNumberOfTapsRequired:1];
    [self.imageView addGestureRecognizer:tap];
    UIBarButtonItem *shareButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAction target:self action:@selector(shareButton)];
    UIBarButtonItem *saveButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemSave target:self action:@selector(saveButton)];
    UIBarButtonItem *addImageButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(addImageButton)];
    [self.navigationItem setRightBarButtonItems:[NSArray arrayWithObjects:saveButton, shareButton,addImageButton, nil]];
    self.contentTextView.layer.borderWidth = 1.0f;
    self.contentTextView.layer.borderColor = [[UIColor grayColor] CGColor];
    UITapGestureRecognizer *touch = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(touchEndEditing)];
    [self.view addGestureRecognizer:touch];
    self.alertEditImageController = [UIAlertController
                                          alertControllerWithTitle:@"Please"
                                          message:@"Delete or edit image"
                                          preferredStyle:UIAlertControllerStyleActionSheet];
    UIAlertAction *deleteAction = [UIAlertAction
                                 actionWithTitle:@"Delete"
                                 style:UIAlertActionStyleDestructive
                                 handler:^(UIAlertAction * action)
                                 {
                                     self.imageView.image=nil;
                                     NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
                                     [dateFormatter setDateFormat:@"yyyyMMddHHmmss"];
                                     NSString *newDate = [dateFormatter stringFromDate:[self.detailItem valueForKey:@"date"]];
                                     [[DataManager sharedManager] deleteImageFromDocumentsWithName:newDate];
                                     [self.alertEditImageController dismissViewControllerAnimated:YES completion:nil];
                                 }];
    
    UIAlertAction* cancel = [UIAlertAction
                             actionWithTitle:@"Cancel"
                             style:UIAlertActionStyleCancel
                             handler:^(UIAlertAction * action)
                             {
                                 [self.alertEditImageController dismissViewControllerAnimated:YES completion:nil];
                             }];
    
    self.alertAddingImageController = [UIAlertController
                                     alertControllerWithTitle:@"Please"
                                     message:@"Choose the resource for import Photo"
                                     preferredStyle:UIAlertControllerStyleActionSheet];
    UIAlertAction *fromGalleryAction = [UIAlertAction
                                 actionWithTitle:@"Import from Gallery"
                                 style:UIAlertActionStyleDefault
                                 handler:^(UIAlertAction * action)
                                 {
                                     UIImagePickerController *picker = [[UIImagePickerController alloc] init];
                                     picker.delegate = self;
                                     picker.allowsEditing = YES;
                                     picker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
                                     [self presentViewController:picker animated:YES completion:NULL];
                                 }];
    UIAlertAction *fromCameraAction = [UIAlertAction
                                   actionWithTitle:@"Import from Camera"
                                   style:UIAlertActionStyleDefault
                                   handler:^(UIAlertAction * action)
                                   {
                                       UIImagePickerController *picker = [[UIImagePickerController alloc] init];
                                       picker.delegate = self;
                                       picker.allowsEditing = YES;
                                       picker.sourceType = UIImagePickerControllerSourceTypeCamera;
                                       [self presentViewController:picker animated:YES completion:NULL];
                                   }];
    UIAlertAction* cancelAddingImage = [UIAlertAction
                             actionWithTitle:@"Cancel"
                             style:UIAlertActionStyleCancel
                             handler:^(UIAlertAction * action)
                             {
                                 [self.alertAddingImageController dismissViewControllerAnimated:YES completion:nil];
                             }];
    
    [self.alertAddingImageController addAction:fromGalleryAction];
    [self.alertAddingImageController addAction:fromCameraAction];
    [self.alertAddingImageController addAction:cancelAddingImage];
    [self.alertEditImageController addAction:fromGalleryAction];
    [self.alertEditImageController addAction:fromCameraAction];
    [self.alertEditImageController addAction:deleteAction];
    [self.alertEditImageController addAction:cancel];
    
}

- (void) shareButton
{
    if (self.detailItem)
    {
        NSArray *itemsToShare = [[NSArray alloc]initWithObjects:[self.detailItem valueForKey:@"title"], [self.detailItem valueForKey:@"content"], [UIImage imageWithData:[self.detailItem valueForKey:@"image"]],nil];
        UIActivityViewController *activityController = [[UIActivityViewController alloc] initWithActivityItems:itemsToShare applicationActivities:nil];
        activityController.excludedActivityTypes = @[];
        [self presentViewController:activityController animated:YES completion:nil];
    }
    else
    {
        [self showAlertViewWithMessage:@"Sorry, you have no saved note"];
    }
}

- (void) myTapImageMethod
{
    if (self.imageView.image)
    {
        [self presentViewController:self.alertEditImageController animated:YES completion:nil];
    }
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker {
    [picker dismissViewControllerAnimated:YES completion:NULL];
}

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info {
    UIImage *selectedImage = info[UIImagePickerControllerEditedImage];
    self.imageView.image = selectedImage;
    [picker dismissViewControllerAnimated:YES completion:NULL];
}

- (void) addImageButton
{
    [self presentViewController:self.alertAddingImageController animated:YES completion:nil];
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
                NSData *imageData = UIImagePNGRepresentation(self.imageView.image);
                NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
                [dateFormatter setDateFormat:@"yyyyMMddHHmmss"];
                NSString *newDate = [dateFormatter stringFromDate:[self.detailItem valueForKey:@"date"]];
                [[DataManager sharedManager] asyncSavingOfNSManagedObject:self.detailItem withImage:imageData withName:newDate];
                [self.navigationController.navigationController popViewControllerAnimated:YES];
        }
        else
        {
            NSData *imageData = UIImagePNGRepresentation(self.imageView.image);
            [[DataManager sharedManager] addNewObjectToContextWithTitle:self.titleTextField.text withContent:self.contentTextView.text withImage:imageData];
            [self.navigationController.navigationController popViewControllerAnimated:YES];
            self.titleTextField.text=nil;
            self.contentTextView.text = nil;
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
        NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
        [dateFormatter setDateFormat:@"yyyyMMddHHmmss"];
        NSString *newDate = [dateFormatter stringFromDate:[self.detailItem valueForKey:@"date"]];
        self.imageView.image = [UIImage imageWithData:[[DataManager sharedManager] getImageFromDocumentsWithName:newDate]];
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
