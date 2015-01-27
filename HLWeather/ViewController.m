//
//  ViewController.m
//  HLWeather
//
//  Created by Jamie Swain on 1/26/15.
//  Copyright (c) 2015 HauteLook. All rights reserved.
//

#import "ViewController.h"
#import "AFHTTPRequestOperationManager.h"
#import "AFURLRequestSerialization.h"
#import "ApiClientYQL.h"

@interface ViewController ()

@property (strong, nonatomic) UITextField *zipcodeField;
@property (strong, nonatomic) UIButton *searchButton;
@property (strong, nonatomic) UIToolbar *keyboardToolbar;

@property (assign, nonatomic) BOOL searchEnabled;

@property (strong, nonatomic) UITextView *messageToUser;

@end

@implementation ViewController


- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    self.zipcodeField = [[UITextField alloc] initWithFrame:CGRectZero];
    
    [self.view addSubview:self.zipcodeField];
    self.zipcodeField.delegate = self;
    self.zipcodeField.placeholder = @"Enter Zip";
    self.zipcodeField.adjustsFontSizeToFitWidth = YES;
    [self.zipcodeField setBorderStyle:UITextBorderStyleRoundedRect];
    [self.zipcodeField setEnablesReturnKeyAutomatically:YES];
    [self.zipcodeField setClearButtonMode:UITextFieldViewModeAlways];
    [self.zipcodeField setKeyboardType:UIKeyboardTypeDefault];
    [self.zipcodeField setReturnKeyType:UIReturnKeyGo];
    
    self.searchButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    [self.view addSubview:self.searchButton];
    [self.searchButton setTitle:@"Check Weather" forState:UIControlStateNormal];
    [self.searchButton addTarget:self action:@selector(didTapButton:) forControlEvents:UIControlEventTouchUpInside];
    
    UIBarButtonItem *dismissButton = [[UIBarButtonItem alloc] initWithTitle:@"Dismiss" style:UIBarButtonItemStylePlain target:self action:@selector(dismissKeyboard:)];
    self.keyboardToolbar = [[UIToolbar alloc] initWithFrame:CGRectMake(0.0f, 0.0f, CGRectGetWidth(self.view.bounds), 44.0f)];
    self.keyboardToolbar.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    self.keyboardToolbar.barStyle = UIBarStyleDefault;
    self.keyboardToolbar.items = @[dismissButton];
    
    self.searchEnabled = YES;
    
    self.messageToUser = [[UITextView alloc] initWithFrame:CGRectZero];
    self.messageToUser.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleBottomMargin;
    [self.messageToUser setTextContainerInset:UIEdgeInsetsZero];
    [self.messageToUser.textContainer setLineFragmentPadding:0.0f];
    [self.view addSubview:self.messageToUser];
    
    [self.navigationItem setTitle:@"HLWeather"];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    CGFloat topInset = 64.0f;
    
    self.zipcodeField.frame = CGRectMake(20.0f, topInset + 20.0f, 140.0f, 45.0f);
    
    self.searchButton.frame = CGRectMake(CGRectGetMaxX(self.zipcodeField.frame) + 20.0f, 
                                         CGRectGetMinY(self.zipcodeField.frame), 
                                         [self.searchButton sizeThatFits:CGSizeMake(150.0f, CGRectGetHeight(self.zipcodeField.bounds))].width, 
                                         CGRectGetHeight(self.zipcodeField.bounds));
                                         
    self.messageToUser.text = @"Type a zipcode and search, the api will return current weather and forecast.\n\nMake the UI display the current weather and forecast with appropriate image.";    

    CGRect messageFrame = CGRectMake(CGRectGetMinX(self.zipcodeField.frame), CGRectGetMaxY(self.zipcodeField.frame) + 20.0f, CGRectGetWidth(self.view.bounds) - 20.0f * 2, 10000.0f);
    messageFrame.size = [self.messageToUser sizeThatFits:messageFrame.size];
    self.messageToUser.frame = messageFrame;
}

- (void)searchWeatherIfEnabled {
    if (!self.searchEnabled) {
        return;
    }

    NSString *textFieldText = [self.zipcodeField.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    
    if ([textFieldText length] > 0) {
        [[ApiClientYQL instance] findWeatherForZipcode:textFieldText country:@"usa" onComplete:^(NSDictionary *weather) {
            
            NSLog(@"weather: %@", weather);
        }];
    }
}

- (void)didTapButton:(id)sender {
    self.searchEnabled = YES;
    if ([self.zipcodeField isFirstResponder]) {
        [self.zipcodeField resignFirstResponder];
    }
    else {
        [self searchWeatherIfEnabled];
    }
}

- (void)dismissKeyboard:(id)sender {
    self.searchEnabled = NO;
    [self.zipcodeField resignFirstResponder];
}

#pragma mark -
#pragma mark TextDelegate
- (UIView *)inputAccessoryView {
    return self.keyboardToolbar;
}

- (void)textFieldDidBeginEditing:(UITextField *)textField {
    self.searchEnabled = YES;
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    self.searchEnabled = YES;
    [textField resignFirstResponder];
    return YES;
}

- (BOOL)textFieldShouldEndEditing:(UITextField *)textField {
    return YES;
}

- (void)textFieldDidEndEditing:(UITextField *)textField {
    [self searchWeatherIfEnabled];
}


@end


