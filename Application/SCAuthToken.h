//
//  SCAuthToken.h
//  SCPlugin
//
//  Created by Christopher Pavicich on Thu Jun 10 2004.
//  Copyright (c) 2004 Christopher Pavicich. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface SCAuthToken : NSObject
{
    @private
    NSString *username;
    NSString *password;
}

- (NSString *) username;
- (void) setUsername:(NSString *)value;

- (NSString *) password;
- (void) setPassword:(NSString *)value;

@end
