/* wrap.h     Simple custom wrappers for Voronoi example
 *
 * Copyright (c) 2011 Psellos   http://psellos.com
 * Licensed under the MIT license:
 *     http://www.opensource.org/licenses/mit-license.php
 */

/* An OCaml value wrapped up for access from ObjC.
 */
@interface WrapOCaml : NSObject {
    value contents;
}
@property (nonatomic, readonly) value contents;
@end

/* Wrapped version of Voronoictlr.t
 */
@interface Voronoictlr : WrapOCaml <UIApplicationDelegate, ViewDelegate>
{
}
@property (nonatomic, retain) IBOutlet UIView *delegator;
@end
