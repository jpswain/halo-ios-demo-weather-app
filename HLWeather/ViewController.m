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

typedef enum {
    HLKeyboardInputStateReady = 0,
    HLKeyboardInputStateEditing = 1,
    HLKeyboardInputStateTextClearing = 2,
    HLKeyboardInputStateWillDismiss = 3
} HLKeyboardInputState;

@interface ViewController ()

@property (strong, nonatomic) UIView *weatherView;

@property (strong, nonatomic) UITableView *tableView;

@property (strong, nonatomic) UIBarButtonItem *rightBarButton;

@property (strong, nonatomic) UITextField *zipcodeField;
@property (strong, nonatomic) UIButton *searchButton;
@property (strong, nonatomic) UIToolbar *keyboardToolbar;

@property (strong, nonatomic) UITextView *messageToUser;

@property (assign, nonatomic) HLKeyboardInputState keyboardInputState;

@end

@implementation ViewController


#pragma mark -
#pragma View methods
- (void)viewDidLoad {
    [super viewDidLoad];
    
    
    // Build weatherView and its subviews
    self.weatherView = [[UIView alloc] initWithFrame:self.view.bounds];
    [self.view addSubview:self.weatherView];
    self.weatherView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    
    self.zipcodeField = [[UITextField alloc] initWithFrame:CGRectZero];
    
    [self.weatherView addSubview:self.zipcodeField];
    self.zipcodeField.delegate = self;
    self.zipcodeField.placeholder = @"Enter Zip";
    self.zipcodeField.adjustsFontSizeToFitWidth = YES;
    [self.zipcodeField setBorderStyle:UITextBorderStyleRoundedRect];
    [self.zipcodeField setEnablesReturnKeyAutomatically:YES];
    [self.zipcodeField setClearButtonMode:UITextFieldViewModeAlways];
    [self.zipcodeField setKeyboardType:UIKeyboardTypeDefault];
    [self.zipcodeField setReturnKeyType:UIReturnKeyGo];
    
    self.searchButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    [self.weatherView addSubview:self.searchButton];
    [self.searchButton setTitle:@"Check Weather" forState:UIControlStateNormal];
    [self.searchButton addTarget:self action:@selector(didTapButton:) forControlEvents:UIControlEventTouchUpInside];
    
    UIBarButtonItem *dismissButton = [[UIBarButtonItem alloc] initWithTitle:@"Dismiss" style:UIBarButtonItemStylePlain target:self action:@selector(dismissKeyboard:)];
    self.keyboardToolbar = [[UIToolbar alloc] initWithFrame:CGRectMake(0.0f, 0.0f, CGRectGetWidth(self.weatherView.bounds), 44.0f)];
    self.keyboardToolbar.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    self.keyboardToolbar.barStyle = UIBarStyleDefault;
    self.keyboardToolbar.items = @[dismissButton];
    
    self.keyboardInputState = HLKeyboardInputStateReady;
    
    self.messageToUser = [[UITextView alloc] initWithFrame:CGRectZero];
    self.messageToUser.userInteractionEnabled = NO;
    self.messageToUser.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleBottomMargin;
    [self.messageToUser setTextContainerInset:UIEdgeInsetsZero];
    [self.messageToUser.textContainer setLineFragmentPadding:0.0f];
    [self.weatherView addSubview:self.messageToUser];
    
    
    
    // Build tableView and its subviews
    self.tableView = [[UITableView alloc] initWithFrame:self.view.bounds];
    self.tableView.dataSource = self;
    self.tableView.delegate = self;
    self.tableView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [self.view addSubview:self.tableView];
    self.tableView.contentInset = UIEdgeInsetsMake([self topInset], 0.0f, 0.0f, 0.0f);
    self.tableView.hidden = YES; 
    
       
    // Set up navBar
    [self.navigationItem setTitle:@"HLWeather"];
    self.rightBarButton = [[UIBarButtonItem alloc] initWithTitle:[self titleForBarButton:NO] style:UIBarButtonItemStylePlain target:self action:@selector(toggleTableView:)];
    self.navigationItem.rightBarButtonItem = self.rightBarButton;
}

- (NSString *)titleForBarButton:(BOOL)alternate {
    if (alternate) {
        return @"Search";
    }
    else {
        return @"List";
    }
}

- (void)toggleTableView:(id)sender {
    self.tableView.hidden = !self.tableView.hidden;
    self.weatherView.hidden = !self.tableView.hidden;
    self.rightBarButton.title = [self titleForBarButton:!self.tableView.hidden];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    
    self.zipcodeField.frame = CGRectMake(20.0f, [self topInset] + 20.0f, 140.0f, 45.0f);
    
    self.searchButton.frame = CGRectMake(CGRectGetMaxX(self.zipcodeField.frame) + 20.0f, 
                                         CGRectGetMinY(self.zipcodeField.frame), 
                                         [self.searchButton sizeThatFits:CGSizeMake(150.0f, CGRectGetHeight(self.zipcodeField.bounds))].width, 
                                         CGRectGetHeight(self.zipcodeField.bounds));
                                         
    self.messageToUser.text = @"Type a zipcode and search, the api will return current weather and forecast.\n\nMake the current view display the current temperature and tomorrow's forecast.\n\nAlso, it should be added to the list of forecasts you see in the list view.";    

    CGRect messageFrame = CGRectMake(CGRectGetMinX(self.zipcodeField.frame), CGRectGetMaxY(self.zipcodeField.frame) + 20.0f, CGRectGetWidth(self.weatherView.bounds) - 20.0f * 2, 300.0f);
    self.messageToUser.frame = messageFrame;
}


#pragma mark -
#pragma mark View Aux methods
- (CGFloat)topInset {
    // Status Bar height - http://stackoverflow.com/a/16598350/192819
    CGSize statusBarSize = [[UIApplication sharedApplication] statusBarFrame].size;
    CGFloat statusBarHeight = MIN(statusBarSize.width, statusBarSize.height);
    
    // Add navigation bar
    CGFloat _topInset = statusBarHeight + CGRectGetHeight(self.navigationController.navigationBar.bounds);
    
    // sanity limit
    _topInset = MIN(_topInset, 100.0f);
    
    return _topInset;
}


#pragma mark -
#pragma Api service
- (void)searchWeatherIfEnabled {
    if (! (self.keyboardInputState == HLKeyboardInputStateReady || self.keyboardInputState == HLKeyboardInputStateEditing)) {
        return;
    }
    
    NSString *textFieldText = [self.zipcodeField.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    
    if ([textFieldText length] > 0) {
        [[ApiClientYQL instance] findWeatherForZipcode:textFieldText country:@"usa" onComplete:^(NSDictionary *weather) {
            
            NSLog(@"weather: %@", weather);
        }];
    }
}


#pragma mark -
#pragma mark Targets of user interaction events
- (void)didTapButton:(id)sender {
    if (self.keyboardInputState == HLKeyboardInputStateEditing) {
        NSAssert([self.zipcodeField isFirstResponder], @"");
        [self.zipcodeField resignFirstResponder];
    }
    else if (self.keyboardInputState == HLKeyboardInputStateReady) {
        [self searchWeatherIfEnabled];
    }
    else {
        NSAssert(NO, @"fallthru");
    }
}

- (void)dismissKeyboard:(id)sender {
    self.keyboardInputState = HLKeyboardInputStateWillDismiss;
    [self.zipcodeField resignFirstResponder];
}


#pragma mark -
#pragma mark UITextFieldDelegate (Keyboard stuff)
- (UIView *)inputAccessoryView {
    return self.keyboardToolbar;
}

- (void)textFieldDidBeginEditing:(UITextField *)textField {
    if (self.keyboardInputState == HLKeyboardInputStateReady) {
        self.keyboardInputState = HLKeyboardInputStateEditing;
        self.rightBarButton.enabled = NO;
    }
    else if (self.keyboardInputState == HLKeyboardInputStateTextClearing) {
        self.keyboardInputState = HLKeyboardInputStateWillDismiss;
        [textField resignFirstResponder];
    }
    else {
        NSAssert(NO, @"fallthru");
    }
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [textField resignFirstResponder];
    return YES;
}

- (BOOL)textFieldShouldEndEditing:(UITextField *)textField {
    return YES;
}

- (void)textFieldDidEndEditing:(UITextField *)textField {
    [self searchWeatherIfEnabled];
    if (self.keyboardInputState != HLKeyboardInputStateTextClearing) {
        self.keyboardInputState = HLKeyboardInputStateReady;
        self.rightBarButton.enabled = YES;
    }
}

- (BOOL)textFieldShouldClear:(UITextField *)textField {
    self.keyboardInputState = HLKeyboardInputStateTextClearing;
    [textField resignFirstResponder];
    return YES;
}

#pragma mark -
#pragma mark UITableViewDataSource
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return 2;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"cell"];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"cell"];
        [cell.textLabel setFont:[UIFont systemFontOfSize:12.0f]];
        cell.textLabel.text = [self textForIndexPath:indexPath];
        UIImage *image = nil;
        [cell.imageView setImage:image];
    }
    return cell;
}

- (NSString *)textForIndexPath:(NSIndexPath *)indexPath {
    NSUInteger row = indexPath.row;
    if (row == 0) {
        return @"display cities with weather as list, in this format:";
    }
    else {
        return @"(temp F°) (hi)/(low) (description)";
    }
}

#pragma mark -
#pragma mark UITableViewDelegate
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}


#pragma mark -
#pragma mark Debug Aux methods
- (void)printKeyboardState {
    if (self.keyboardInputState == HLKeyboardInputStateReady) {
        NSLog(@"keyboardState: ready");
    }
    else if (self.keyboardInputState == HLKeyboardInputStateEditing) {
        NSLog(@"keyboardState: editing");
    }
    else if (self.keyboardInputState == HLKeyboardInputStateTextClearing) {
        NSLog(@"keyboardState: textClearing");
    }
    else if (self.keyboardInputState == HLKeyboardInputStateWillDismiss) {
        NSLog(@"keyboardState: willDismiss");
    }
}


@end


