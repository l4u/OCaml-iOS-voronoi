/* wrap.m     Simple custom wrappers for Voronoi example
 *
 * Copyright (c) 2011 Psellos   http://psellos.com
 * Licensed under the MIT license:
 *     http://www.opensource.org/licenses/mit-license.php
 */
# import <stdlib.h>
# import <objc/runtime.h>
# import <UIKit/UIKit.h>
# import <caml/mlvalues.h>
# import <caml/memory.h>
# import <caml/alloc.h>
# import <caml/callback.h>
# import "ViewDelegator.h"
# import "wrap.h"

/* Represent raw ObjC object pointers in OCaml as nativeint values.
 *
 * Note: to keep things simple, we retain ObjC values and don't release
 * them.  It works for this example because the few ObjC objects
 * accessible from the OCaml side are never destroyed.
 * 
 * In a more dynamic setting, need to gain control when the OCaml
 * wrapper objects are GCed and release the wrapped up ObjC objects.
 */
static value wrapRawObjC(id obj) {
    CAMLparam0();
    [obj retain];
    CAMLreturn(caml_copy_nativeint((intnat) obj));
}

static id unwrapRawObjC(value objcval) {
    return (id) Nativeint_val(objcval);
}

/* Need to be able to determine the OCaml object that wraps a given ObjC
 * object.  In the simple setup here, the association is permanent and
 * there are very few objects involved.  So we can use a little table.
 * (Getting the ObjC object that wraps an OCaml object is easier; we
 * just use the container method of Wrappee.t.)
 */
static struct {
    id objc_obj;
    value ocaml_obj;
} g_ocaml_wrapper[16];
static int g_ocwrap_ct = 0;


static value find_ocaml_wrapper(id obj) {
    int i;

    for(i = 0; i < g_ocwrap_ct; i++)
        if(g_ocaml_wrapper[i].objc_obj == obj)
            return g_ocaml_wrapper[i].ocaml_obj;
    return 0;
}


static value wrapObjC(char *wrapcs, id obj) {
    /* Create a new OCaml object that wraps the given ObjC object.
     * wrapcs gives the name of the closure for creating an OCaml
     * wrapper of the correct type.  A closure is registered by each
     * OCaml class that wraps an ObjC class (i.e., each subclass of
     * Wrapper.t).
     */
    CAMLparam0();
    CAMLlocal1(val);
    value *closure;

    closure = (value *) caml_named_value(wrapcs);
    if(closure == NULL) {
        /* Can't create an instance of an unregistered class.  If this
         * happens, things will go very bad from here.
         */
        printf("wrapObjC lookup failure for %s\n", wrapcs);
        fflush(stdout);
        CAMLreturn(Val_unit); /* Not type safe, should never happen */
    }
    val = caml_callback(*closure, wrapRawObjC(obj));

    /* Enter the wrapping into the table.
     */
    if(g_ocwrap_ct >= sizeof g_ocaml_wrapper / sizeof g_ocaml_wrapper[0]) {
        /* Things might go bad from here if we need to access the
         * wrapper later from the ObjC side.  For this simple example it
         * never happens because there are only 2 or 3 wrapped ObjC
         * objects.
         */
        printf("wrapObjC table overflow for %s\n", wrapcs);
        fflush(stdout);
    } else {
        g_ocaml_wrapper[g_ocwrap_ct].objc_obj = obj;
        g_ocaml_wrapper[g_ocwrap_ct].ocaml_obj = val;
        caml_register_global_root(&g_ocaml_wrapper[g_ocwrap_ct].ocaml_obj);
        g_ocwrap_ct++;
    }

    CAMLreturn(val);
}

static id unwrapObjC(value obj) {
    /* Return the ObjC object wrapped by the given OCaml object.
     */
    CAMLparam1(obj);
    CAMLlocal1(objcval);

    objcval =
        caml_callback(
            caml_get_public_method(obj, caml_hash_variant("contents")),
            obj);
    CAMLreturnT(id, unwrapRawObjC(objcval));
}


/* Subclasses of WrapOCaml wrap OCaml objects as ObjC objects.
 */
@implementation WrapOCaml {
}

@dynamic contents;

- (value) contents
{
    return contents;
}


- (void) setContents: (value) aValue
{
    contents = aValue;
}


- (WrapOCaml *) init
{
    /* Create a new OCaml object that is wrapped by self.  We match the
     * OCaml class to our own class by name--simple but effective.  We
     * then call the closure for creating a wrapped object, which is
     * registered by each OCaml class that can be wrapped by an ObjC
     * class (i.e., each subtype of Wrappee.t).
     */
#   define CLOSURE_SFX      ".wrapped"
#   define CLOSURE_SFX_LEN  (sizeof CLOSURE_SFX - 1)
    const char *classname;
    char closurename[128];
    value *closure;

    if((self = [super init]) != nil) {
        classname = object_getClassName(self);
        if(strlen(classname) + CLOSURE_SFX_LEN >= sizeof closurename) {
            printf("[WrapOCaml init]: class name too long: %s\n", classname);
            fflush(stdout);
            return nil;
        }
        strcpy(closurename, classname);
        strcat(closurename, CLOSURE_SFX);
        closure = (value *) caml_named_value(closurename);
        if(closure == NULL) {
            printf("[WrapOCaml init]: lookup failure for %s\n", closurename);
            fflush(stdout);
            return nil;
        }
        contents = caml_callback(*closure, wrapRawObjC(self));
        caml_register_global_root(&contents);
    }
    return self;
}

- (void) dealloc
{
    if(contents != 0) {
        caml_remove_global_root(&contents);
        contents = 0;
    }
    [super dealloc];
}

@end

/* Conversion utilities.
 */
static void Point_val(CGPoint *ptp, value pointval)
{
    CAMLparam1(pointval);

    ptp->x = Double_val(Field(pointval, 0));
    ptp->y = Double_val(Field(pointval, 1));

    CAMLreturn0;
}

static value Val_rect(CGRect *rectp)
{
    CAMLparam0();
    CAMLlocal1(rectval);

    rectval = caml_alloc(4, 0);
    Store_field(rectval, 0, caml_copy_double(rectp->origin.x));
    Store_field(rectval, 1, caml_copy_double(rectp->origin.y));
    Store_field(rectval, 2, caml_copy_double(rectp->size.width));
    Store_field(rectval, 3, caml_copy_double(rectp->size.height));

    CAMLreturn(rectval);
}

static void Rect_val(CGRect *rectp, value rectval)
{
    CAMLparam1(rectval);

    rectp->origin.x = Double_val(Field(rectval, 0));
    rectp->origin.y = Double_val(Field(rectval, 1));
    rectp->size.width = Double_val(Field(rectval, 2));
    rectp->size.height = Double_val(Field(rectval, 3));

    CAMLreturn0;
}


static SEL SEL_val(value selectval)
{
    /* Translate the OCaml string into an ObjC selector.
     *
     * Conventionally we use '\'' in OCaml where ':' appears in ObjC.
     * So here we translate back.
     */
    char *prime;
    SEL res;

    char *ocamlsel = String_val(selectval);
    char *buf = malloc(strlen(ocamlsel) + 1);
    strcpy(buf, ocamlsel);
    prime = buf;
    while((prime = strchr(prime, '\'')) != NULL)
        *prime = ':';
    res = sel_registerName(buf);
    free(buf);
    return res;
}

static NSString *StringO_val(value so)
{
    CAMLparam1(so);
    NSString *res;

    if(Is_long(so))
        res = nil;
    else
        res = [NSString stringWithUTF8String: String_val(Field(so, 0))];
    CAMLreturnT(NSString *, res);
}


/* OCaml objects accessed from ObjC.
 */

@implementation Voronoictlr : WrapOCaml
{
}

@dynamic delegator;

- (UIView *) delegator
{
    CAMLparam0();
    CAMLlocal2(selfval, delegatorval);

    selfval = [self contents];
    delegatorval =
        caml_callback(
            caml_get_public_method(selfval, caml_hash_variant("delegator")),
            selfval);
    CAMLreturnT(UIView *, unwrapObjC(delegatorval));
}

- (void) setDelegator: (UIView *) aView
{
    CAMLparam0();
    CAMLlocal2(selfval, delegatorval);

    selfval = [self contents];
    delegatorval = wrapObjC("UIView.wrap", (id) aView);
    (void)
        caml_callback2(
            caml_get_public_method(selfval, caml_hash_variant("setDelegator'")),
            selfval,
            delegatorval);
    CAMLreturn0;
}

- (void) applicationDidFinishLaunching: (UIApplication *) anApplication
{
    CAMLparam0();
    CAMLlocal2(selfval, applval);

    selfval = [self contents];
    if((applval = find_ocaml_wrapper(anApplication)) == 0)
        applval = wrapObjC("UIApplication.wrap", (id) anApplication);
    (void)
        caml_callback2(
            caml_get_public_method(
                selfval,
                caml_hash_variant("applicationDidFinishLaunching'")),
            selfval,
            applval);
    CAMLreturn0;
}

- (void) applicationWillResignActive: (UIApplication *) anApplication
{
    CAMLparam0();
    CAMLlocal2(selfval, applval);

    selfval = [self contents];
    if((applval = find_ocaml_wrapper(anApplication)) == 0)
        applval = wrapObjC("UIApplication.wrap", (id) anApplication);
    (void)
        caml_callback2(
            caml_get_public_method(
                selfval,
                caml_hash_variant("applicationWillResignActive'")),
            selfval,
            applval);
    CAMLreturn0;
}

- (void) applicationDidBecomeActive: (UIApplication *) anApplication
{
    CAMLparam0();
    CAMLlocal2(selfval, applval);

    selfval = [self contents];
    if((applval = find_ocaml_wrapper(anApplication)) == 0)
        applval = wrapObjC("UIApplication.wrap", (id) anApplication);
    (void)
        caml_callback2(
            caml_get_public_method(
                selfval,
                caml_hash_variant("applicationDidBecomeActive'")),
            selfval,
            applval);
    CAMLreturn0;
}


- (BOOL) viewCanBecomeFirstResponder: (UIView *) aView
{
    CAMLparam0();
    CAMLlocal3(selfval, viewval, resval);

    selfval = [self contents];

    if((viewval = find_ocaml_wrapper(aView)) == 0)
        viewval = wrapObjC("UIView.wrap", (id) aView);

    resval =
        caml_callback2(
            caml_get_public_method(selfval,
                            caml_hash_variant("viewCanBecomeFirstResponder'")),
            selfval,
            viewval);
    CAMLreturnT(BOOL, Bool_val(resval));
}


static void touch_event(value selfval, UIView *aView, NSSet *touches,
                    UIEvent *event, char *ocmeth)
{
    /* For this simple test, we assume there's just one touch, and we
     * represent it by a point.
     */
    CAMLparam1(selfval);
    CAMLlocal2(viewval, pointval);
    UITouch *touch;
    CGPoint location;

    if((viewval = find_ocaml_wrapper(aView)) == 0)
        viewval = wrapObjC("UIView.wrap", (id) aView);

    if((touch = (UITouch *) [touches anyObject]) == nil)
        CAMLreturn0; /* Not really possible */

    location = [touch locationInView: aView];

    pointval = caml_alloc(2, 0);
    Store_field(pointval, 0, caml_copy_double(location.x));
    Store_field(pointval, 1, caml_copy_double(location.y));

    (void)
        caml_callback3(
            caml_get_public_method(
                selfval,
                caml_hash_variant(ocmeth)),
            selfval,
            viewval,
            pointval);
    CAMLreturn0;
}


- (void) view: (UIView *) aView
         touchesBegan: (NSSet *) touches
         withEvent: (UIEvent *) event
{
    touch_event([self contents], aView, touches, event,
                "view'touchesBegan'");
}


- (void) view: (UIView *) aView
         touchesMoved: (NSSet *) touches
         withEvent: (UIEvent *) event
{
    touch_event([self contents], aView, touches, event,
                "view'touchesMoved'");
}


- (void) view: (UIView *) aView
         touchesEnded: (NSSet *) touches
         withEvent: (UIEvent *) event
{
    touch_event([self contents], aView, touches, event,
                "view'touchesEnded'");
}


- (void) view: (UIView *) aView
         touchesCancelled: (NSSet *) touches
         withEvent: (UIEvent *) event
{
    touch_event([self contents], aView, touches, event,
                "view'touchesCancelled'");
}


static void motion_event(value selfval, UIView *aView, UIEventSubtype motion,
                    UIEvent *event, char *ocmeth)
{
    CAMLparam1(selfval);
    CAMLlocal1(viewval);

    if((viewval = find_ocaml_wrapper(aView)) == 0)
        viewval = wrapObjC("UIView.wrap", (id) aView);

    (void)
        caml_callback3(
            caml_get_public_method(selfval, caml_hash_variant(ocmeth)),
            selfval,
            viewval,
            Val_int(motion));
    CAMLreturn0;
}


- (void) view: (UIView *) aView
         motionBegan: (UIEventSubtype) motion
         withEvent: (UIEvent *) event
{
    motion_event([self contents], aView, motion, event,
                 "view'motionBegan'");
}


- (void) view: (UIView *) aView
         motionCancelled: (UIEventSubtype) motion
         withEvent: (UIEvent *) event
{
    motion_event([self contents], aView, motion, event,
                 "view'motionCancelled'");
}


- (void) view: (UIView *) aView
         motionEnded: (UIEventSubtype) motion
         withEvent: (UIEvent *) event
{
    motion_event([self contents], aView, motion, event,
                 "view'motionEnded'");
}


- (void) view: (UIView *) aView drawRect: (CGRect) rect
{
    CAMLparam0();
    CAMLlocal2(selfval, viewval);

    selfval = [self contents];

    if((viewval = find_ocaml_wrapper(aView)) == 0)
        viewval = wrapObjC("UIView.wrap", (id) aView);

    (void)
        caml_callback3(
            caml_get_public_method(selfval,
                                   caml_hash_variant("view'drawRect'")),
            selfval,
            viewval,
            Val_rect(&rect));
    CAMLreturn0;
}

@end


/* ObjC objects accessed from OCaml.
 */

/* UIKit
 */

value UIKit_RectFill(value rectval)
/* Cocoa.rect -> unit */
{
    CAMLparam1(rectval);
    CGRect rect;

    Rect_val(&rect, rectval);
    UIRectFill(rect);

    CAMLreturn(Val_unit);
}


value UIKit_set(value colorval)
/* UiKit.color -> unit */
{
    CAMLparam1(colorval);

    UIColor *color =
        [UIColor colorWithHue: Double_val(Field(colorval, 0))
                 saturation: Double_val(Field(colorval, 1))
                 brightness: Double_val(Field(colorval, 2))
                 alpha: Double_val(Field(colorval, 3))];
    [color set];

    CAMLreturn(Val_unit);
}


value UIKit_setFill(value colorval)
/* UiKit.color -> unit */
{
    CAMLparam1(colorval);

    UIColor *color =
        [UIColor colorWithHue: Double_val(Field(colorval, 0))
                 saturation: Double_val(Field(colorval, 1))
                 brightness: Double_val(Field(colorval, 2))
                 alpha: Double_val(Field(colorval, 3))];
    [color setFill];

    CAMLreturn(Val_unit);
}


value UIKit_setStroke(value colorval)
/* UiKit.color -> unit */
{
    CAMLparam1(colorval);

    UIColor *color =
        [UIColor colorWithHue: Double_val(Field(colorval, 0))
                 saturation: Double_val(Field(colorval, 1))
                 brightness: Double_val(Field(colorval, 2))
                 alpha: Double_val(Field(colorval, 3))];
    [color setStroke];

    CAMLreturn(Val_unit);
}


value UIKit_string_sizeWithFont_(value stringval, value objcval)
/* string -> nativeint -> Cocoa.size */
{
    CAMLparam2(stringval, objcval);
    CAMLlocal1(sizeval);
    NSString *string;
    UIFont *font;
    CGSize size;

    string = [NSString stringWithUTF8String: String_val(stringval)];
    font = unwrapRawObjC(objcval);

    size = [string sizeWithFont: font];

    sizeval = caml_alloc(2, 0);
    Store_field(sizeval, 0, caml_copy_double(size.width));
    Store_field(sizeval, 1, caml_copy_double(size.height));

    CAMLreturn(sizeval);
}

value UIKit_string_drawAtPoint_withFont_(value stringval, value pointval,
                    value objcval)
/* string -> Cocoa.point -> nativeint -> unit */
{
    CAMLparam3(stringval, pointval, objcval);
    NSString *string;
    CGPoint pt;
    UIFont *font;

    string = [NSString stringWithUTF8String: String_val(stringval)];
    Point_val(&pt, pointval);
    font = unwrapRawObjC(objcval);

    [string drawAtPoint: pt withFont: font];

    CAMLreturn(Val_unit);
}

/* UIFont
 */

value UIFont_fontWithName_size_(value nameval, value sizeval)
/* string -> float -> UiFont.t */
{
    CAMLparam2(nameval, sizeval);
    NSString *name;
    CGFloat size;
    UIFont *font;

    name = [NSString stringWithUTF8String: String_val(nameval)];
    size = Double_val(sizeval);
    font = [UIFont fontWithName: name size: size];

    CAMLreturn(wrapObjC("UIFont.wrap", (id) font));
}

/* UIBezierPath
 */
value UIBezierPath_bezierPath(value unitval)
/* unit -> UiBezierPath.t */
{
    CAMLparam1(unitval);
    UIBezierPath *bzp;

    bzp = [UIBezierPath bezierPath];
    CAMLreturn(wrapObjC("UIBezierPath.wrap", (id) bzp));
}

value UIBezierPath_bezierPathWithOvalInRect_(value rectval)
/* Cocoa.rect -> UiBezierPath.t */
{
    CAMLparam1(rectval);
    CGRect rect;
    UIBezierPath *bzp;

    Rect_val(&rect, rectval);
    bzp = [UIBezierPath bezierPathWithOvalInRect: rect];

    CAMLreturn(wrapObjC("UIBezierPath.wrap", (id) bzp));
}

value UIBezierPath_moveToPoint_(value objcval, value pointval)
/* nativeint -> Cocoa.point -> unit */
{
    CAMLparam2(objcval, pointval);
    UIBezierPath *bzp = unwrapRawObjC(objcval);
    CGPoint pt;

    Point_val(&pt, pointval);
    [bzp moveToPoint: pt];

    CAMLreturn(Val_unit);
}

value UIBezierPath_addLineToPoint_(value objcval, value pointval)
/* nativeint -> Cocoa.point -> unit */
{
    CAMLparam2(objcval, pointval);
    UIBezierPath *bzp = unwrapRawObjC(objcval);
    CGPoint pt;

    Point_val(&pt, pointval);
    [bzp addLineToPoint: pt];

    CAMLreturn(Val_unit);
}

value UIBezierPath_addCurveToPoint_controlPoint1_controlPoint2_(value objcval,
                    value pointval, value cp1val, value cp2val)
/* nativeint -> Cocoa.point -> Cocoa.point -> Cocoa.point -> unit */
{
    CAMLparam4(objcval, pointval, cp1val, cp2val);
    UIBezierPath *bzp = unwrapRawObjC(objcval);
    CGPoint pt, cp1, cp2;

    Point_val(&pt, pointval);
    Point_val(&cp1, cp1val);
    Point_val(&cp2, cp2val);
    [bzp addCurveToPoint: pt
            controlPoint1: cp1
            controlPoint2: cp2];

    CAMLreturn(Val_unit);
}

value UIBezierPath_closePath(value objcval)
/* nativeint -> unit */
{
    CAMLparam1(objcval);
    UIBezierPath *bzp = unwrapRawObjC(objcval);

    [bzp closePath];

    CAMLreturn(Val_unit);
}

value UIBezierPath_removeAllPoints(value objcval)
/* nativeint -> unit */
{
    CAMLparam1(objcval);
    UIBezierPath *bzp = unwrapRawObjC(objcval);

    [bzp removeAllPoints];

    CAMLreturn(Val_unit);
}

value UIBezierPath_lineWidth(value objcval)
/* nativeint -> float */
{
    CAMLparam1(objcval);

    UIBezierPath *bzp = unwrapRawObjC(objcval);

    CAMLreturn(caml_copy_double([bzp lineWidth]));
}

value UIBezierPath_setLineWidth_(value objcval, value widval)
/* nativeint -> float -> unit */
{
    CAMLparam2(objcval, widval);

    UIBezierPath *bzp = unwrapRawObjC(objcval);
    [bzp setLineWidth: Double_val(widval)];

    CAMLreturn(Val_unit);
}

value UIBezierPath_fill(value objcval)
/* nativeint -> unit */
{
    CAMLparam1(objcval);

    UIBezierPath *bzp = unwrapRawObjC(objcval);
    [bzp fill];
    CAMLreturn(Val_unit);
}

value UIBezierPath_stroke(value objcval)
/* nativeint -> unit */
{
    CAMLparam1(objcval);

    UIBezierPath *bzp = unwrapRawObjC(objcval);
    [bzp stroke];
    CAMLreturn(Val_unit);
}

value UIBezierPath_containsPoint_(value objcval, value pointval)
/* nativeint -> Cocoa.point -> bool */
{
    CAMLparam2(objcval, pointval);
    CGPoint pt;

    UIBezierPath *bzp = unwrapRawObjC(objcval);
    Point_val(&pt, pointval);

    CAMLreturn(Val_bool([bzp containsPoint: pt]));
}

/* UIView
 */

value UIView_isFirstResponder(value objcval)
/* nativeint -> bool */
{
    CAMLparam1(objcval);

    UIView *view = unwrapRawObjC(objcval);
    CAMLreturn(Val_bool([view isFirstResponder]));
}

value UIView_becomeFirstResponder(value objcval)
/* nativeint -> bool */
{
    CAMLparam1(objcval);

    UIView *view = unwrapRawObjC(objcval);
    CAMLreturn(Val_bool([view becomeFirstResponder]));
}

value UIView_frame(value objcval)
/* nativeint -> Cocoa.rect */
{
    CAMLparam1(objcval);
    CGRect rect;

    UIView *view = unwrapRawObjC(objcval);
    rect = [view frame];
    CAMLreturn(Val_rect(&rect));
}

value UIView_setNeedsDisplay(value objcval)
/* nativeint -> unit */
{
    CAMLparam1(objcval);

    UIView *view = unwrapRawObjC(objcval);
    [view setNeedsDisplay];
    CAMLreturn(Val_unit);
}

/* UIActionSheet
 */

/* A little class to wrap the delegate.
 */
@interface ASDelegate : NSObject <UIActionSheetDelegate> {
    value contents;
}
- (void) setContents: (value) aValue;
@end

@implementation ASDelegate {
}

- (void) setContents: (value) aValue
{
    contents = aValue;
    caml_register_global_root(&contents);
}

- (void) actionSheet: (UIActionSheet *) a clickedButtonAtIndex: (NSInteger) ix
{
    CAMLparam0();
    CAMLlocal1(asval);

    if((asval = find_ocaml_wrapper(a)) == 0)
        asval = wrapObjC("UIActionSheet.wrap", (id) a);

    (void)
        caml_callback3(
            caml_get_public_method(contents,
                       caml_hash_variant("actionSheet'clickedButtonAtIndex'")),
            contents,
            asval,
            Val_int(ix));
    CAMLreturn0;
}
@end

value UIActionSheet_initWithTDCDO(value objcval, value titleoval,
                    value delegval, value canceloval, value destruoval,
                    value othersval)
/* nativeint -> string option -> UiActionSheet.delegate -> string option ->
 *     string option -> string list -> UiActionSheet.t
 */
{
#   define MAXOTITLES 7
    CAMLparam5(objcval, titleoval, delegval, canceloval, destruoval);
    CAMLxparam1(othersval);
    UIActionSheet *as, *asi;
    NSString *title, *cancel, *destructive, *others[MAXOTITLES + 1];
    ASDelegate *deleg;
    int i;

    as = unwrapRawObjC(objcval);
    if(as == nil)
        as = [UIActionSheet alloc];
    title = StringO_val(titleoval);
    deleg = [[ASDelegate alloc] init];
    [deleg setContents: delegval];
    cancel = StringO_val(canceloval);
    destructive = StringO_val(destruoval);
    for(i = 0; i < MAXOTITLES; i++) {
        if(Is_long(othersval))
            break;
        others[i] =
            [NSString stringWithUTF8String: String_val(Field(othersval, 0))];
        othersval = Field(othersval, 1);
    }
    others[i] = nil;

    asi = [as initWithTitle: title
              delegate: deleg
              cancelButtonTitle: cancel
              destructiveButtonTitle: destructive
              otherButtonTitles:
                others[0], others[1], others[2], others[3],
                others[4], others[5], others[6], others[7], nil];
    [asi autorelease]; /* wrapObjC will retain */

    CAMLreturn(wrapObjC("UIActionSheet.wrap", (id) asi));
}


value UIActionSheet_initWithTDCDO_bytecode(value *argv, int argn)
{
    return UIActionSheet_initWithTDCDO(argv[0], argv[1], argv[2], argv[3],
                    argv[4], argv[5]);
}

value UIActionSheet_showInView_(value objcval, value viewval)
/* nativeint -> nativeint -> unit */
{
    CAMLparam2(objcval, viewval);

    UIActionSheet *as;
    UIView *view;

    as = unwrapRawObjC(objcval);
    view = unwrapRawObjC(viewval);

    [as showInView: view];

    CAMLreturn(Val_unit);
}
