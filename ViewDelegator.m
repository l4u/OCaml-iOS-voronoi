/* ViewDelegator.m     UIView subclass to delegate touches, motions, and
 *                     drawRect:
 *
 * Copyright (c) 2011 Psellos   http://psellos.com
 * Licensed under the MIT license:
 *     http://www.opensource.org/licenses/mit-license.php
 *
 * This code is logically a small extension of Cocoa Touch.  It doesn't
 * need to know anything about OCaml.
 */
#import <UIKit/UIKit.h>

#import "ViewDelegator.h"

@implementation ViewDelegator

@dynamic delegate;

- (NSObject<ViewDelegate> *) delegate
{
    return delegate;
}


- (void) setDelegate: (NSObject<ViewDelegate> *) aDelegate
{
    delegate = aDelegate;
}

- (BOOL) canBecomeFirstResponder
{
    if([delegate respondsToSelector: @selector(viewCanBecomeFirstResponder:)])
        return [delegate viewCanBecomeFirstResponder: self];
    return [super canBecomeFirstResponder];
}

- (void) touchesBegan: (NSSet *) touches withEvent: (UIEvent *) event
{
    if([delegate respondsToSelector: @selector(view:touchesBegan:withEvent:)])
        [delegate view: self touchesBegan: touches withEvent: event];
}


- (void) touchesMoved: (NSSet *) touches withEvent: (UIEvent *) event
{
    if([delegate respondsToSelector: @selector(view:touchesMoved:withEvent:)])
        [delegate view: self touchesMoved: touches withEvent: event];
}


- (void) touchesEnded: (NSSet *) touches withEvent: (UIEvent *) event
{
    if([delegate respondsToSelector: @selector(view:touchesEnded:withEvent:)])
        [delegate view: self touchesEnded: touches withEvent: event];
}


- (void) touchesCancelled: (NSSet *) touches withEvent: (UIEvent *) event
{
    if([delegate respondsToSelector:
            @selector(view:touchesCancelled:withEvent:)])
        [delegate view: self touchesCancelled: touches withEvent: event];
}


- (void) motionBegan: (UIEventSubtype) motion withEvent: (UIEvent *) event
{
    if([delegate respondsToSelector: @selector(view:motionBegan:withEvent:)])
        [delegate view: self motionBegan: motion withEvent: event];
}


- (void) motionCancelled: (UIEventSubtype) motion withEvent: (UIEvent *) event
{
    if([delegate respondsToSelector:
            @selector(view:motionCancelled:withEvent:)])
        [delegate view: self motionCancelled: motion withEvent: event];
}


- (void) motionEnded: (UIEventSubtype) motion withEvent: (UIEvent *) event
{
    if([delegate respondsToSelector: @selector(view:motionEnded:withEvent:)])
        [delegate view: self motionEnded: motion withEvent: event];
}


- (void) drawRect: (CGRect) rect
{
    if([delegate respondsToSelector: @selector(view:drawRect:)])
        [delegate view: self drawRect: rect];
}
@end
