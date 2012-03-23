/* ViewDelegator.h     UIView subclass to delegate touches, motions, and
 *                     drawRect:
 *
 * Copyright (c) 2011 Psellos   http://psellos.com
 * Licensed under the MIT license:
 *     http://www.opensource.org/licenses/mit-license.php
 */

/* Protocol for the delegate.
 */
@protocol ViewDelegate
@optional
- (BOOL) viewCanBecomeFirstResponder: (UIView *) view;

- (void) view: (UIView *) view
         touchesBegan: (NSSet *) touches
         withEvent: (UIEvent *) event;
- (void) view: (UIView *) view
         touchesCancelled: (NSSet *) touches
         withEvent: (UIEvent *) event;
- (void) view: (UIView *) view
         touchesEnded: (NSSet *) touches
         withEvent: (UIEvent *) event;
- (void) view: (UIView *) view
         touchesMoved: (NSSet *) touches
         withEvent: (UIEvent *) event;

- (void) view: (UIView *) view
         motionBegan: (UIEventSubtype) motion
         withEvent: (UIEvent *) event;
- (void) view: (UIView *) view
         motionCancelled: (UIEventSubtype) motion
         withEvent: (UIEvent *) event;
- (void) view: (UIView *) view
         motionEnded: (UIEventSubtype) motion
         withEvent: (UIEvent *) event;

- (void) view: (UIView *) view drawRect: (CGRect) rect;
@end

/* Interface for the delegator.
 */
@interface ViewDelegator : UIView
{
    NSObject<ViewDelegate> *delegate;
}
@property(nonatomic, assign) IBOutlet NSObject<ViewDelegate> *delegate;
@end
