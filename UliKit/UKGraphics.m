//
//  UKGraphics.m
//  Shovel
//
//  Created by Uli Kusterer on Thu Mar 25 2004.
//  Copyright (c) 2004 M. Uli Kusterer. All rights reserved.
//

#import "UKGraphics.h"
#if UK_GRAPHICS_USE_HITHEME
#if MAC_OS_X_VERSION_MAX_ALLOWED >= MAC_OS_X_VERSION_10_3
#import <Carbon/Carbon.h>
#else
#undef UK_GRAPHICS_USE_HITHEME
#endif
#endif


void	UKDrawWhiteBezel( NSRect box, NSRect clipBox )
{
	UKDrawDropHighlightedWhiteBezel( NO, box, clipBox );
}


void	UKDrawDropHighlightedWhiteBezel( BOOL doHighlight, NSRect box, NSRect clipBox )
{
	UKDrawDropHighlightedEditableWhiteBezel( doHighlight, NO, box, clipBox );
}


void	UKDrawDropHighlightedEditableWhiteBezel( BOOL doHighlight, BOOL isEditable, NSRect box, NSRect clipBox )
{
    NSRect			drawBox = box;
    [NSGraphicsContext saveGraphicsState];
    float lw = [NSBezierPath defaultLineWidth];
    [NSBezierPath setDefaultLineWidth: 1];
        
    #if UK_GRAPHICS_USE_HITHEME
    unsigned long        sysVersion;
    
    if( noErr != Gestalt( gestaltSystemVersion, (long*) &sysVersion ) )
        sysVersion = 0;
    
    if( sysVersion < 0x00001030 )
    {
    #endif
        // Fix up rect so it draws *on* the pixels:
        drawBox.origin.x += 0.5;
        drawBox.origin.y += 0.5;
        drawBox.size.width -= 1;
        drawBox.size.height -= 1;
    #if UK_GRAPHICS_USE_HITHEME
    }
    #endif
    
    // Draw background in white:
    [[NSColor controlBackgroundColor] set];
    [NSBezierPath fillRect: drawBox];
    
    
    #if UK_GRAPHICS_USE_HITHEME
    if( sysVersion >= 0x00001030 )
    {
        CGContextRef            context = [[NSGraphicsContext currentContext] graphicsPort];
        HIThemeFrameDrawInfo    info = { 0, kHIThemeFrameTextFieldSquare, kThemeStateActive, NO };
        drawBox = NSInsetRect( drawBox, 1, 1 );
       
        if( !isEditable )
            info.state = kThemeStateInactive;
        
        HIThemeDrawFrame( (HIRect*) &drawBox, &info, context, kHIThemeOrientationInverted );
        CGContextSynchronize( context );
        
        if( isEditable )
            drawBox.size.height -= 1;
    }
    else
    {
    #endif
        // Draw three edges in grey
        if( isEditable )
        {
            drawBox.size.height--;
            [[[NSColor lightGrayColor] colorWithAlphaComponent: 0.8] set];
        }
        else
            [[NSColor lightGrayColor] set];
        [NSBezierPath strokeRect: drawBox];
        if( isEditable )
            drawBox.size.height++;

        // Draw top a little darker:
        [[NSColor grayColor] set];
        [NSBezierPath strokeLineFromPoint: NSMakePoint(drawBox.origin.x +drawBox.size.width +1, drawBox.origin.y +drawBox.size.height)
            toPoint: NSMakePoint(drawBox.origin.x -1, drawBox.origin.y +drawBox.size.height)];
    #if UK_GRAPHICS_USE_HITHEME
    }
    #endif
    
    // Draw drop highlight if requested:
    if( doHighlight )
    {
        drawBox = NSInsetRect( drawBox, 1, 1 );
        
        [[[NSColor selectedControlColor] colorWithAlphaComponent: 0.8] set];
        [NSBezierPath setDefaultLineWidth: 2];
        [NSBezierPath strokeRect: drawBox];
        [[NSColor blackColor] set];
    }
    
    [NSBezierPath setDefaultLineWidth: lw];
    [NSGraphicsContext restoreGraphicsState];
}


void	UKDrawGenericWell( NSRect box, NSRect clipBox )
{
    NSImageCell*    borderCell = [[[NSImageCell alloc] initImageCell: [[[NSImage alloc] initWithSize: NSMakeSize(2,2)] autorelease]] autorelease];
    [borderCell setImageFrameStyle: NSImageFrameGrayBezel];
    [borderCell drawWithFrame: box inView: nil];
}

