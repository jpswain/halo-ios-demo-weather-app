//
//  ApiClientYQL.m
//  HLWeather
//
//  Created by Jamie Swain on 1/26/15.
//  Copyright (c) 2015 HauteLook. All rights reserved.
//

#import "ApiClientYQL.h"
#import "AFNetworking.h"
#import "AFHTTPRequestOperationManager.h"


@interface ApiClientYQL ()

@property (nonatomic, strong) AFHTTPRequestOperationManager *manager;
@property (nonatomic, assign) NSUInteger numOutstandingRequests;
@end

@implementation ApiClientYQL

+ (ApiClientYQL *)instance {
    static ApiClientYQL *_instance;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _instance = [[ApiClientYQL alloc] init];
    });
    return _instance;
}

- (instancetype)init
{
    self = [super init];
    if (self) {

    }
    return self;
}


- (void)findWeatherForZipcode:(NSString *)zipCode country:(NSString *)country onComplete:(void(^)(NSDictionary *weather))onComplete {
    if (self.numOutstandingRequests == 0) {
        [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
    }
    self.numOutstandingRequests += 1;

    // 1. get woeid for zipcode
    [self findWoeidForZipcode:zipCode country:country onComplete:^(NSDictionary *placeInfo) {
        
        NSString *woeid = [placeInfo objectForKey:@"woeid"];
        
        // 2. get weather for woeid
        [self findWeatherForWoeid:woeid onComplete:^(NSDictionary *weather) {
            self.numOutstandingRequests -= 1;
            if (self.numOutstandingRequests == 0) {
                [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
            }
            
            NSMutableDictionary *weatherPlaceInfo = [NSMutableDictionary dictionary];
            [weatherPlaceInfo addEntriesFromDictionary:placeInfo];
            [weatherPlaceInfo addEntriesFromDictionary:weather]; 
            
            onComplete(weatherPlaceInfo);
        }];
    }];    
}

- (void)findWoeidForZipcode:(NSString *)zipcode country:(NSString *)country onComplete:(void(^)(NSDictionary *))onComplete {
    if (!country) {
        country = @"usa";
    }
    NSString *url = [NSString stringWithFormat:@"https://query.yahooapis.com/v1/public/yql"];
    NSString *query = [NSString stringWithFormat:@"select * from geo.places where text=\"%@,%@\"", zipcode, country];
    NSDictionary *params = [NSDictionary dictionaryWithObjectsAndKeys:
                            query, @"q", 
                            @"json", @"format",
                            nil];
    
    [[AFHTTPRequestOperationManager manager] GET:url parameters:params success:^(AFHTTPRequestOperation *operation, id responseObject) {
        
        NSDictionary *placeInfo = [self mapResponseForWoeid:responseObject];
        onComplete(placeInfo);
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        
        NSLog(@"failure: %@, %@", operation, error);
        onComplete(nil);
    }];    
}

- (void)findWeatherForWoeid:(NSString *)woeid onComplete:(void(^)(NSDictionary *))onComplete {
    NSString *url = [NSString stringWithFormat:@"https://query.yahooapis.com/v1/public/yql"];
    NSString *query = [NSString stringWithFormat:@"select * from weather.forecast where woeid=%@", woeid];
    NSDictionary *params = [NSDictionary dictionaryWithObjectsAndKeys:
                            query, @"q", 
                            @"json", @"format",
                            nil];
    
    [[AFHTTPRequestOperationManager manager] GET:url parameters:params success:^(AFHTTPRequestOperation *operation, id responseObject) {
        
        NSDictionary *weather = [self mapResponseForWeather:responseObject];
        onComplete(weather);
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
            
        NSLog(@"failure: %@, %@", operation, error);
        onComplete(nil);
    }];    
}


- (NSDictionary *)mapResponseForWoeid:(NSDictionary *)json {
    NSArray *places = [[[json objectForKey:@"query"] objectForKey:@"results"] objectForKey:@"place"];
    // just take the first one:
    NSDictionary *placeDict = [[places objectEnumerator] nextObject];
    NSString *woeid = [placeDict objectForKey:@"woeid"];
    NSDictionary *locality1 = [placeDict objectForKey:@"locality1"];
    NSString *locality = nil;
    if (![locality1 isKindOfClass:[NSNull class]]) {
        locality = [locality1 objectForKey:@"content"];
    }
    
    NSMutableDictionary *placeInfo = [NSMutableDictionary dictionary];
    [placeInfo setValue:woeid forKey:@"woeid"];
    [placeInfo setValue:locality forKey:@"locality"];
    return placeInfo;
}

- (NSDictionary *)mapResponseForWeather:(NSDictionary *)json {
    // query, results, channel, item
        // condition / forecast
    NSDictionary *item = [[[[json objectForKey:@"query"] objectForKey:@"results"] objectForKey:@"channel"] objectForKey:@"item"];
    
    NSDictionary *conditionDict = [item objectForKey:@"condition"];

    NSArray *forecastDicts = [item objectForKey:@"forecast"];
    
    NSDictionary *todayForecast = nil;
    NSDictionary *tomorrowForecast = nil;
    if ([forecastDicts count] > 0) {
        todayForecast = [forecastDicts objectAtIndex:0];

        if ([forecastDicts count] > 1) {
            tomorrowForecast = [forecastDicts objectAtIndex:1];
        }
    }
    
    NSMutableDictionary *weatherInfo = [NSMutableDictionary dictionary];
    [weatherInfo setValue:conditionDict forKey:@"now"];
    [weatherInfo setValue:todayForecast forKey:@"today"];
    [weatherInfo setValue:tomorrowForecast forKey:@"tomorrow"];
    return weatherInfo;
}


@end
