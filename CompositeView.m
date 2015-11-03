/*
 CompositeView implements a view with three horizontal, equal-sized areas.
 The left-most area is the "source," the middle area is the "destination,"
 and the right-most area is the "result." CompositeView assures that the
 contents of the result area is always generated by compositing the other
 two areas using the compositing mode set in the setOperator: method.
 It is also possible to change the contents, color, and alpha of the
 source and destination areas; see the methods setSourceColor:, 
 setSourceAlpha:, etc.

 CompositeView also demonstrates some of the drag & drop features
 by acting as a destination for colors & images.

 Written by Bruce Blumberg and Ali Ozer, 1988
 Converted to OpenStep, 1996
 Converted to Cocoa, 2001

 Copyright (c) 1988-2002, Apple Computer, Inc., all rights reserved.
*/
/*
 IMPORTANT:  This Apple software is supplied to you by Apple Computer, Inc. ("Apple") in
 consideration of your agreement to the following terms, and your use, installation, 
 modification or redistribution of this Apple software constitutes acceptance of these 
 terms.  If you do not agree with these terms, please do not use, install, modify or 
 redistribute this Apple software.
 
 In consideration of your agreement to abide by the following terms, and subject to these 
 terms, Apple grants you a personal, non-exclusive license, under Apple�s copyrights in 
 this original Apple software (the "Apple Software"), to use, reproduce, modify and 
 redistribute the Apple Software, with or without modifications, in source and/or binary 
 forms; provided that if you redistribute the Apple Software in its entirety and without 
 modifications, you must retain this notice and the following text and disclaimers in all 
 such redistributions of the Apple Software.  Neither the name, trademarks, service marks 
 or logos of Apple Computer, Inc. may be used to endorse or promote products derived from 
 the Apple Software without specific prior written permission from Apple. Except as expressly
 stated in this notice, no other rights or licenses, express or implied, are granted by Apple
 herein, including but not limited to any patent rights that may be infringed by your 
 derivative works or by other works in which the Apple Software may be incorporated.
 
 The Apple Software is provided by Apple on an "AS IS" basis.  APPLE MAKES NO WARRANTIES, 
 EXPRESS OR IMPLIED, INCLUDING WITHOUT LIMITATION THE IMPLIED WARRANTIES OF NON-INFRINGEMENT, 
 MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE, REGARDING THE APPLE SOFTWARE OR ITS 
 USE AND OPERATION ALONE OR IN COMBINATION WITH YOUR PRODUCTS.
 
 IN NO EVENT SHALL APPLE BE LIABLE FOR ANY SPECIAL, INDIRECT, INCIDENTAL OR CONSEQUENTIAL 
 DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS 
 OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) ARISING IN ANY WAY OUT OF THE USE, 
 REPRODUCTION, MODIFICATION AND/OR DISTRIBUTION OF THE APPLE SOFTWARE, HOWEVER CAUSED AND 
 WHETHER UNDER THEORY OF CONTRACT, TORT (INCLUDING NEGLIGENCE), STRICT LIABILITY OR 
 OTHERWISE, EVEN IF APPLE HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
*/

#import <AppKit/AppKit.h>
#import "CompositeView.h"

@implementation CompositeView

// initWithFrame: creates the view, initializes the rectangles that define the
// three areas described above, and creates the bitmaps used for rendering the
// source and destination bitmaps.

- (id)initWithFrame:(NSRect)rect {

    // Initialize the view

    if (!(self = [super initWithFrame:rect])) return nil;

    // Make rectangles for source, destination and result

    sRect = [self bounds];
    sRect.size.width /= 3.0;
    dRect = sRect;
    dRect.origin.x = sRect.size.width;
    rRect = dRect;
    rRect.origin.x = dRect.origin.x + dRect.size.width;

    // Create source, destination, and result images.

    [(source = [[NSImage allocWithZone:[self zone]] initWithSize:sRect.size]) addRepresentation:[[[NSCustomImageRep alloc] initWithDrawSelector:@selector(drawSource:) delegate:self] autorelease]];
    [source setBackgroundColor:[NSColor clearColor]];
    
    [(destination = [[NSImage allocWithZone:[self zone]] initWithSize:dRect.size]) addRepresentation:[[[NSCustomImageRep alloc] initWithDrawSelector:@selector(drawDestination:) delegate:self] autorelease]];
    [destination setBackgroundColor:[NSColor clearColor]];

    [(result = [[NSImage allocWithZone:[self zone]] initWithSize:dRect.size]) addRepresentation:[[[NSCustomImageRep alloc] initWithDrawSelector:@selector(drawResult:) delegate:self] autorelease]];
    [result setBackgroundColor:[NSColor clearColor]];

    // Set the default operator and source picture. No need to set the default
    // colors; these are read from the .nib file when the outlets to the wells
    // are estanblished.

    operator = NSCompositeCopy;
    sourcePicture = TrianglePicture;

    // Tell the application that alpha should be allowed in the color panel
    // and dragged colors. Most apps do not want to bother with this.

    [NSColor setIgnoresAlpha:NO];

    // Finally, register for dragging colors and files. 

    [self registerForDraggedTypes:[NSArray arrayWithObjects:NSColorPboardType, NSFilenamesPboardType, nil]];

    return self;
}

// Get handles to the wells and read their initial colors.

- (void)setSourceColorWell:(id)anObject {
    sourceColorWell = anObject;
    sourceColor = [[anObject color] copyWithZone:[self zone]]; 
}

- (void)setDestColorWell:(id)anObject {
    destColorWell = anObject;
    destColor = [[anObject color] copyWithZone:[self zone]];
}

- (void)setBackColorWell:(id)anObject {
    backColorWell = anObject;
    backgroundColor = [[anObject color] copyWithZone:[self zone]]; 
}

// drawSource: creates the source image in the  currently locked focus.
// It's specified as a callback to the source NSImage, allowed the image to
// be redrawn whenever needed... Note that this method will change some graphics
// state parameters, including the transformation matrix; however, we don't save and restore
// the graphics state because this method is called in isolation with no other drawing
// afterwards. Otherwise it's a good idea to save/restore the graphics state (or restore individually
// the parameters that were changed). 

- (void)drawSource:(NSCustomImageRep *)imageRep {
    NSBezierPath *path = [NSBezierPath bezierPath];

    switch (sourcePicture) {

	case TrianglePicture: {
                [path moveToPoint:NSMakePoint(0.0, 0.0)];
                [path lineToPoint:NSMakePoint(0.0, sRect.size.height)];
                [path lineToPoint:NSMakePoint(sRect.size.width, sRect.size.height)];
            }
	    break;

	case CirclePicture: {
                // Draw an oval in a rect 80% of the size of the area
                [path appendBezierPathWithOvalInRect:NSInsetRect(sRect, floor(sRect.size.width * 0.1), floor(sRect.size.height * 0.1))];
            }
 	    break;

	case DiamondPicture: {
                [path moveToPoint:NSMakePoint(0.0, sRect.size.height / 2.0)];
                [path lineToPoint:NSMakePoint(sRect.size.width / 2.0, 0.0)];
                [path lineToPoint:NSMakePoint(sRect.size.width, sRect.size.height / 2.0)];
                [path lineToPoint:NSMakePoint(sRect.size.width / 2.0, sRect.size.height)];
	    }
            break;

	case HeartPicture: {
                NSAffineTransform *transform = [NSAffineTransform transform];
                [transform scaleXBy:sRect.size.width yBy:sRect.size.height];
                [transform concat];
                [path moveToPoint:NSMakePoint(0.5, 0.6)];
                [path curveToPoint:NSMakePoint(0.5, 0.1) controlPoint1:NSMakePoint(0.3, 1.0) controlPoint2:NSMakePoint(0.0, 0.5)];
                [path moveToPoint:NSMakePoint(0.5, 0.6)];
                [path curveToPoint:NSMakePoint(0.5, 0.1) controlPoint1:NSMakePoint(0.7, 1.0) controlPoint2:NSMakePoint(1.0, 0.5)];
	    }
            break;

	case FlowerPicture: {
                int cnt;
                NSAffineTransform *transform = [NSAffineTransform transform];
                [transform scaleXBy:sRect.size.width yBy:sRect.size.height];
                [transform translateXBy:0.5 yBy:0.5];
                [transform concat];
                [path moveToPoint:NSZeroPoint];
                transform = [NSAffineTransform transform];
                [transform rotateByDegrees:60.0];
                for (cnt = 0; cnt < 6; cnt++) {
                    [path transformUsingAffineTransform:transform];	// Rotates by 60 degrees each time
                    [path curveToPoint:NSZeroPoint controlPoint1:NSMakePoint(0.4, 0.5) controlPoint2:NSMakePoint(-0.4, 0.5)];
                }
	    }
            break;

	 case CustomPicture:
	    if (!customImage) {
		NSString *fileName = [[NSBundle mainBundle] pathForImageResource:@"DefaultCustomImage"];
		if (fileName) {
                    customImage = [[NSImage allocWithZone:[self zone]] initByReferencingFile:fileName];
                    [customImage setScalesWhenResized:YES];
                    [customImage setSize:rRect.size];
		}
	    }
            [customImage compositeToPoint:NSZeroPoint operation:NSCompositeSourceOver];
	    break;
 
	default:
	    break;
    }
    [path closePath];
    
    [sourceColor set];
    [path fill];
}

// drawDestination: creates the destination image; like drawSource: is it
// specified as a callback to the destination NSImage

- (void)drawDestination:(NSCustomImageRep *)imageRep {
    NSBezierPath *path = [NSBezierPath bezierPath];

    [destColor set];
    [path moveToPoint:NSMakePoint(dRect.size.width, 0.0)];
    [path lineToPoint:NSMakePoint(dRect.size.width, dRect.size.height)];
    [path lineToPoint:NSMakePoint(0.0, dRect.size.height)];
    [path closePath];
    
    [destColor set];
    [path fill];
}

// drawResult: creates the resulting image, formed by compositing the
// source image after the destination image with the specified operator. 

- (void)drawResult:(NSCustomImageRep *)imageRep {
    [destination compositeToPoint:NSZeroPoint operation:NSCompositeCopy];
    [source compositeToPoint:NSZeroPoint operation:operator]; 
}
    
// setSourcePicture: allows setting the picture to be drawn in the source
// image. Buttons connected to this method should have tags that are 
// set to the various possible pictures.
//
// After setting the sourcePicture instance variable, setSourcePicture:
// invalidates the images and the view to reflect the new configuration.

- (void)setSourcePicture:(id)sender {
    sourcePicture = [sender selectedTag];
    [source recache];
    [result recache];
    [self setNeedsDisplay:YES]; 
}

// changeCustomImageTo: allows changing the image to be drawn
// in the "Custom" drawing mode

- (BOOL)changeCustomImageTo:(NSImage *)newImage {
    if (newImage && (newImage != customImage)) {
	[newImage setSize:rRect.size];
	[newImage setScalesWhenResized:YES];
	if ([newImage isValid]) {
	    [customImage release];
	    customImage = newImage;
	    if (sourcePicture != CustomPicture) {
		sourcePicture = CustomPicture;
		[sourcePictureMatrix selectCellWithTag:CustomPicture];
	    }
	    [source recache];
	    [result recache];
	    [self setNeedsDisplay:YES];
	    return YES;
	}
    }
    return NO;
}

// Action method to change the custom image; puts up an open panel allowing any
// recognized image file type to be chosen

- (void)changeCustomImage:(id)sender {
    NSOpenPanel *openPanel = [NSOpenPanel openPanel];
    if ([openPanel runModalForTypes:[NSImage imageFileTypes]]) {
	(void)[self changeCustomImageTo:[[NSImage allocWithZone:[self zone]] initByReferencingFile:[openPanel filename]]];
    } 
}

// The following methods change the colors and update
// the source or destination bitmaps and the view to reflect the change.
// They should typically be called by a control capable of returning
// a color (for instance, an NSColorWell).

- (void)changeSourceColor:(id)sender {
    [self changeSourceColorTo:[sender color] andDisplay:YES]; 
}

- (void)changeDestColor:(id)sender {
    [self changeDestColorTo:[sender color] andDisplay:YES]; 
}

- (void)changeBackgroundColor:(id)sender {
    [self changeBackgroundColorTo:[sender color] andDisplay:YES]; 
}

- (void)changeSourceColorTo:(NSColor *)color andDisplay:(BOOL)flag {
    if (![sourceColor isEqual:color]) {
	[sourceColor release];
	sourceColor = [color copyWithZone:[self zone]];
	[source recache];
	[result recache];
	if (flag) [self setNeedsDisplay:YES];
    }
}

- (void)changeDestColorTo:(NSColor *)color andDisplay:(BOOL)flag {
    if (![destColor isEqual:color]) {
	[destColor release];
	destColor = [color copyWithZone:[self zone]];
	[destination recache];
	[result recache];
        if (flag) [self setNeedsDisplay:YES];
    }
}

- (void)changeBackgroundColorTo:(NSColor *)color andDisplay:(BOOL)flag {
    if (![backgroundColor isEqual:color]) {
	[backgroundColor release];
	backgroundColor = [color copyWithZone:[self zone]];
        if (flag) [self setNeedsDisplay:YES];
    }
}

// The operator method returns the operator currently in use.

- (NSCompositingOperation)operator {
    return operator;
}    

// setOperator sets: the operator to be used in the compositing operations
// and updates the view to reflect the change. Note that setOperator needs
// to be connected to a row of buttons.

- (void)setOperator:(id)sender {
    switch ([sender selectedRow]) {
	case 0: operator = NSCompositeCopy;			break;
	case 1: operator = NSCompositeClear;			break;
	case 2: operator = NSCompositeSourceOver; 		break;
	case 3: operator = NSCompositeDestinationOver;		break;
	case 4: operator = NSCompositeSourceIn; 		break;
	case 5: operator = NSCompositeDestinationIn; 		break;
	case 6: operator = NSCompositeSourceOut;		break;
	case 7: operator = NSCompositeDestinationOut;		break;
	case 8: operator = NSCompositeSourceAtop;		break; 
	case 9: operator = NSCompositeDestinationAtop;		break;
	case 10: operator = NSCompositeXOR; 			break;
	case 11: operator = NSCompositePlusDarker;		break;
	case 12: operator = NSCompositePlusLighter;		break;
	default: break;
    }
    [result recache];
    [self setNeedsDisplayInRect:rRect];
}

		
// drawRect: simply redisplays the contents of the view. The source and
// destination rectangles are updated from the bitmaps while the result
// rectangle is created by compositing the two bitmaps.

- (void)drawRect:(NSRect)rect {

    // Erase the whole view

    [backgroundColor set];
    NSRectFill([self bounds]);

    // Color for the frame of the three sections...

    [[NSColor blackColor] set];

    // Draw the source bitmap and then frame it with black

    [source compositeToPoint:sRect.origin operation:NSCompositeSourceOver];
    NSFrameRect(sRect);

    // Draw the destination bitmap and frame it with black 

    [destination compositeToPoint:dRect.origin operation:NSCompositeSourceOver];
    NSFrameRect(dRect);

    // And now for the result image. Frame it with black as well

    [result compositeToPoint:rRect.origin operation:NSCompositeSourceOver];
    NSFrameRect(rRect);
}

// dealloc method to free all the images and colors along with the view.

- (void)dealloc {
    [source release];
    [destination release];
    [result release];
    [sourceColor release];
    [destColor release];
    [backgroundColor release];
    [customImage release];
    [super dealloc];
}


// Code to support dragging...
// This is mostly complicated by the fact that the code wants to demonstrate
// how to dynamically give feedback to the user as the colors are
// dragged (but not dropped). We don't dynamically give feedback when images
// are dragged (as it might take a long time).

- (unsigned int)draggingEntered:(id <NSDraggingInfo>)sender {
    return [self draggingUpdated:sender];
}

// To provide dragging feedback, we change the color of appropriate rect,
// force an immediate display, and then revert the color back. This way
// during the drag operation the colors still retain the original values.

- (unsigned int)draggingUpdated:(id <NSDraggingInfo>)sender {
    if ([sender draggingSourceOperationMask] & NSDragOperationGeneric) {
	NSPasteboard *pboard = [sender draggingPasteboard];
        if ([[pboard types] containsObject:NSColorPboardType]) {	// Color
	    NSColor *sourceColorSave = [[sourceColor retain] autorelease];
	    NSColor *destColorSave = [[destColor retain] autorelease];
	    NSColor *backgroundColorSave = [[backgroundColor retain] autorelease];
	    [self doColorDrag:sender];
	    [self displayIfNeeded];	/* Force a display right now */
	    [self changeSourceColorTo:sourceColorSave andDisplay:NO];	/* Revert without displaying */
	    [self changeDestColorTo:destColorSave andDisplay:NO];
	    [self changeBackgroundColorTo:backgroundColorSave andDisplay:NO];
	    return NSDragOperationGeneric;
	} else if ([NSImage canInitWithPasteboard:pboard]) {	// Image?
	    return NSDragOperationGeneric;
	}
    }
    return NSDragOperationNone;	    
}

- (void)draggingExited:(id <NSDraggingInfo>)sender {
    if ([[[sender draggingPasteboard] types] containsObject:NSColorPboardType]) {	// We need to fix the view up
	[self setNeedsDisplay:YES];
    } 
}

- (BOOL)performDragOperation:(id <NSDraggingInfo>)sender {
    return ([self draggingUpdated:sender] == NSDragOperationNone) ? NO : YES;
}

- (void)concludeDragOperation:(id <NSDraggingInfo>)sender {
    NSPasteboard *pboard = [sender draggingPasteboard];

    if ([[pboard types] containsObject:NSColorPboardType]) {
	[self doColorDrag:sender];
	[sourceColorWell setColor:sourceColor];
	[destColorWell setColor:destColor];
	[backColorWell setColor:backgroundColor];
    } else {
        (void)[self changeCustomImageTo:[[NSImage allocWithZone:[self zone]] initWithPasteboard:pboard]];
    }
}

- (void)doColorDrag:(id <NSDraggingInfo>)sender {
    NSPoint point = [sender draggingLocation];
    NSColor *color = [NSColor colorFromPasteboard:[sender draggingPasteboard]];

    point = [self convertPoint:point fromView:nil];

    switch ((int)(3 * point.x / NSWidth([self bounds]))) {
	case 0:
            [self changeSourceColorTo:color andDisplay:YES];
	    break;
	case 1:
            [self changeDestColorTo:color andDisplay:YES];
	    break;
	case 2:
            [self changeBackgroundColorTo:color andDisplay:YES];
	    break;
	default:
	    break;	// Shouldn't really happen...
    }
}


@end
