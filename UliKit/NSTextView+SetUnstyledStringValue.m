//
//  NSTextView+SetUnstyledStringValue.m
//  MAS
//
//  Created by Uli Kusterer on 08.03.07.
//  Copyright 2007 M. Uli Kusterer. All rights reserved.
//

#import "NSTextView+SetUnstyledStringValue.h"


@implementation NSTextView (UKSetUnstyledStringValue)

-(void)	setUnstyledStringValue: (NSString*)str
{
	NSAttributedString*	astr = [[NSAttributedString alloc] initWithString: str];
	NS_DURING
		[[self textStorage] setAttributedString: astr];
	NS_HANDLER
		[astr release];
		[localException raise];
	NS_ENDHANDLER
	[astr release];
}

@end
