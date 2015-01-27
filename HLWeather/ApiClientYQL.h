//
//  ApiClientYQL.h
//  HLWeather
//
//  Created by Jamie Swain on 1/26/15.
//  Copyright (c) 2015 HauteLook. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ApiClientYQL : NSObject

+ (ApiClientYQL *)instance;

- (void)findWeatherForZipcode:(NSString *)zipCode country:(NSString *)country onComplete:(void(^)(NSDictionary *weather))onComplete;

@end
