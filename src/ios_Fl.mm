#include "config.h"

#if __FLTK_IPHONEOS__

#include "Fl.H"
#include "x.H"
#include "Fl_Window.H"
#include "Fl_Tooltip.H"
#include "Fl_Printer.H"
#include "Fl_Input_.H"
#include "Fl_Text_Display.H"
#include <stdio.h>
#include <stdlib.h>
#include "flstring.h"
#include <unistd.h>
#include <stdarg.h>
#include <math.h>
#include <limits.h>

#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>

#define FLTK_min(x, y) (((x) < (y)) ? (x) : (y))
#define FLTK_max(x, y) (((x) > (y)) ? (x) : (y))

// ***********************************************************
static int forward_argc;
static char **forward_argv;
static int exit_status;
static UIWindow *launch_window;

// ***********************************************************
// Event
// ***********************************************************
static BOOL UIKit_EventPumpEnabled = YES;
static void FLTK_iPhoneSetEventPump(BOOL enabled)
{
    UIKit_EventPumpEnabled = enabled;
}
static void UIKit_PumpEvents(_THIS)
{
    if (!UIKit_EventPumpEnabled) return;

    /* Let the run loop run for a short amount of time: long enough for
       touch events to get processed (which is important to get certain
       elements of Game Center's GKLeaderboardViewController to respond
       to touch input), but not long enough to introduce a significant
       delay in the rest of the app.
    */
    const CFTimeInterval seconds = 0.000002;

    /* Pump most event types. */
    SInt32 result;
    do {
        result = CFRunLoopRunInMode(kCFRunLoopDefaultMode, seconds, TRUE);
    } while (result == kCFRunLoopRunHandledSource);

    /* Make sure UIScrollView objects scroll properly. */
    do {
        result = CFRunLoopRunInMode((CFStringRef)UITrackingRunLoopMode, seconds, TRUE);
    } while(result == kCFRunLoopRunHandledSource);
}

// ****************************************************************
static void FLTK_IdleTimerDisabledChanged(void *userdata, const char *name, const char *oldValue, const char *hint)
{
    BOOL disable = (hint && *hint != '0');
    [UIApplication sharedApplication].idleTimerDisabled = disable;
}

// ****************** Class Interface ***************************
// ***********************************************************
// FLTKUIKitDelegate Interface
// ***********************************************************
@interface FLTKUIKitDelegate : NSObject<UIApplicationDelegate> {
}
+ (id) sharedAppDelegate;
+ (NSString *)getAppDelegateClassName;
@end

// ***********************************************************
// FLTK_splashviewcontroller Interface
// ***********************************************************
@interface FLTK_splashviewcontroller : UIViewController {
    UIImageView *splash;
    UIImage *splashPortrait;
    UIImage *splashLandscape;
}
- (void)updateSplashImage:(UIInterfaceOrientation)interfaceOrientation;
@end

// ****************************************************************
// these pointers are set by the Fl::lock() function:
static void nothing() { }
void (*fl_lock_function)() = nothing;
void (*fl_unlock_function)() = nothing;

//******************* spot **********************************
void fl_reset_spot()
{
}

void fl_set_spot(int font, int size, int X, int Y, int W, int H, Fl_Window *win)
{
}

Fl_Display_Device *Fl_Display_Device::_display = 0;//new Fl_Display_Device(new Fl_Quartz_Graphics_Driver); // the platform display
// public variables
CGContextRef fl_gc = 0;
void *fl_capture = 0;           // (NSWindow*) we need this to compensate for a missing(?) mouse capture
bool fl_show_iconic;                    // true if called from iconize() - shows the next created window in collapsed state
//int fl_disable_transient_for;           // secret method of removing TRANSIENT_FOR
Window fl_window;
Fl_Window *Fl_Window::current_;
Fl_Fontdesc *fl_fonts = Fl_X::calc_fl_fonts();

int fl_mac_os_version = 0;


void fl_set_status(int x, int y, int w, int h)
{
}

void fl_open_display()
{
}

// so a CGRect matches exactly what is denoted x,y,w,h for clipping purposes
CGRect fl_cgrectmake_cocoa(int x, int y, int w, int h)
{
	return CGRectMake(x, y, w > 0 ? w - 0.9 : 0, h > 0 ? h - 0.9 : 0);
}

double fl_mac_flush_and_wait(double time_to_wait)
{
	return 0.0;
}

void fl_clipboard_notify_change()
{
	// No need to do anything here...
}

/*
 * Check if there is actually a message pending
 */
int fl_ready()
{
	return 0;
}

void Fl::add_timeout(double time, Fl_Timeout_Handler cb, void *data)
{
/*
	// check, if this timer slot exists already
	for (int i = 0; i < mac_timer_used; ++i) {
		MacTimeout &t = mac_timers[i];
		// if so, simply change the fire interval
		if (t.callback == cb  &&  t.data == data) {
			t.next_timeout = CFAbsoluteTimeGetCurrent() + time;
			CFRunLoopTimerSetNextFireDate(t.timer, t.next_timeout);
			t.pending = 1;
			return;
		}
	}
	// no existing timer to use. Create a new one:
	int timer_id = -1;
	// find an empty slot in the timer array
	for (int i = 0; i < mac_timer_used; ++i) {
		if (!mac_timers[i].timer) {
			timer_id = i;
			break;
		}
	}
	// if there was no empty slot, append a new timer
	if (timer_id == -1) {
		// make space if needed
		if (mac_timer_used == mac_timer_alloc) {
			realloc_timers();
		}
		timer_id = mac_timer_used++;
	}
	// now install a brand new timer
	MacTimeout &t = mac_timers[timer_id];
	CFRunLoopTimerContext context = { 0, &t, NULL, NULL, NULL };
	CFRunLoopTimerRef timerRef = CFRunLoopTimerCreate(kCFAllocatorDefault,
													  CFAbsoluteTimeGetCurrent() + time,
													  1E30,
													  0,
													  0,
													  do_timer,
													  &context
													 );
	if (timerRef) {
		CFRunLoopAddTimer(CFRunLoopGetCurrent(),
						  timerRef,
						  kCFRunLoopDefaultMode);
		t.callback = cb;
		t.data     = data;
		t.timer    = timerRef;
		t.pending  = 1;
		t.next_timeout = CFRunLoopTimerGetNextFireDate(timerRef);
	}
	*/
}

void Fl::repeat_timeout(double time, Fl_Timeout_Handler cb, void *data)
{
/*
	if (current_timer) {
		// k = how many times 'time' seconds after the last scheduled timeout until the future
		double k = ceil((CFAbsoluteTimeGetCurrent() - current_timer->next_timeout) / time);
		if (k < 1) k = 1;
		current_timer->next_timeout += k * time;
		CFRunLoopTimerSetNextFireDate(current_timer->timer, current_timer->next_timeout);
		current_timer->callback = cb;
		current_timer->data = data;
		current_timer->pending = 1;
		return;
	}
	add_timeout(time, cb, data);
	*/
}

int Fl::has_timeout(Fl_Timeout_Handler cb, void *data)
{
/*
	for (int i = 0; i < mac_timer_used; ++i) {
		MacTimeout &t = mac_timers[i];
		if (t.callback == cb  &&  t.data == data && t.pending) {
			return 1;
		}
	}
	*/
	return 0;
}

void Fl::remove_timeout(Fl_Timeout_Handler cb, void *data)
{
/*
	for (int i = 0; i < mac_timer_used; ++i) {
		MacTimeout &t = mac_timers[i];
		if (t.callback == cb  && (t.data == data || data == NULL)) {
			delete_timer(t);
		}
	}
	*/
}

/*
 * smallest x coordinate in screen space of work area of menubar-containing display
 */
int Fl::x()
{
	return 0;//int([[[NSScreen screens] objectAtIndex: 0] visibleFrame].origin.x);
}


/*
 * smallest y coordinate in screen space of work area of menubar-containing display
 */
int Fl::y()
{
	return 0;
	/*
	fl_open_display();
	NSRect visible = [[[NSScreen screens] objectAtIndex: 0] visibleFrame];
	return int(main_screen_height - (visible.origin.y + visible.size.height));
	*/
}


/*
 * width of work area of menubar-containing display
 */
int Fl::w()
{
	return 0;
	/*
	return int([[[NSScreen screens] objectAtIndex: 0] visibleFrame].size.width);
	*/
}


/*
 * height of work area of menubar-containing display
 */
int Fl::h()
{
	return 0;
	//return int([[[NSScreen screens] objectAtIndex: 0] visibleFrame].size.height);
}

// computes the work area of the nth screen (screen #0 has the menubar)
void Fl_X::screen_work_area(int &X, int &Y, int &W, int &H, int n)
{
/*
	fl_open_display();
	NSRect r = [[[NSScreen screens] objectAtIndex: n] visibleFrame];
	X   = int(r.origin.x);
	Y   = main_screen_height - int(r.origin.y + r.size.height);
	W   = int(r.size.width);
	H   = int(r.size.height);
	*/
}

/*
 * get the current mouse pointer world coordinates
 */
void Fl::get_mouse(int &x, int &y)
{
/*
	fl_open_display();
	NSPoint pt = [NSEvent mouseLocation];
	x = int(pt.x);
	y = int(main_screen_height - pt.y);
*/	
}


/*
 * Gets called when a window is created, resized, or deminiaturized
 */
static void handleUpdateEvent(Fl_Window *window)
{
/*
	if (!window) return;
	Fl_X *i = Fl_X::i(window);
	i->wait_for_expose = 0;

	if (i->region) {
		XDestroyRegion(i->region);
		i->region = 0;
	}

	for (Fl_X *cx = i->xidChildren; cx; cx = cx->xidNext) {
		if (cx->region) {
			XDestroyRegion(cx->region);
			cx->region = 0;
		}
		cx->w->clear_damage(FL_DAMAGE_ALL);
		CGContextRef gc = (CGContextRef)[[NSGraphicsContext currentContext] graphicsPort];
		CGContextSaveGState(gc); // save original context
		cx->flush();
		CGContextRestoreGState(gc); // restore original context
		cx->w->clear_damage();
	}
	window->clear_damage(FL_DAMAGE_ALL);
	i->flush();
	window->clear_damage();
	*/
}


int Fl_X::fake_X_wm(const Fl_Window *w, int &X, int &Y, int &bt, int &bx, int &by)
{
	int W, H, xoff, yoff, dx, dy;
	int ret = bx = by = bt = 0;
	if (w->border() && !w->parent()) {
		if (w->maxw != w->minw || w->maxh != w->minh) {
			ret = 2;
		} else {
			ret = 1;
		}
		get_window_frame_sizes(bx, by, bt);
	}
	// The coordinates of the whole window, including non-client area
	xoff = bx;
	yoff = by + bt;
	dx = 2 * bx;
	dy = 2 * by + bt;
	X = w->x() - xoff;
	Y = w->y() - yoff;
	W = w->w() + dx;
	H = w->h() + dy;

	// Proceed to positioning the window fully inside the screen, if possible

	// let's get a little elaborate here. Mac OS X puts a lot of stuff on the desk
	// that we want to avoid when positioning our window, namely the Dock and the
	// top menu bar (and even more stuff in 10.4 Tiger). So we will go through the
	// list of all available screens and find the one that this window is most
	// likely to go to, and then reposition it to fit withing the 'good' area.
	//  Rect r;
	// find the screen, that the center of this window will fall into
	int R = X + W, B = Y + H; // right and bottom
	int cx = (X + R) / 2, cy = (Y + B) / 2; // center of window;
	NSScreen *gd = NULL;
	NSArray *a = [NSScreen screens]; int count = (int)[a count]; NSRect r; int i;
	for (i = 0; i < count; i++) {
		r = [[a objectAtIndex: i] frame];
		r.origin.y = main_screen_height - (r.origin.y + r.size.height); // use FLTK's multiscreen coordinates
		if (cx >= r.origin.x && cx <= r.origin.x + r.size.width
			&& cy >= r.origin.y && cy <= r.origin.y + r.size.height) break;
	}
	if (i < count) gd = [a objectAtIndex: i];

	// if the center doesn't fall on a screen, try the top left
	if (!gd) {
		for (i = 0; i < count; i++) {
			r = [[a objectAtIndex: i] frame];
			r.origin.y = main_screen_height - (r.origin.y + r.size.height); // use FLTK's multiscreen coordinates
			if (X >= r.origin.x && X <= r.origin.x + r.size.width
				&& Y >= r.origin.y  && Y <= r.origin.y + r.size.height) break;
		}
		if (i < count) gd = [a objectAtIndex: i];
	}
	// if that doesn't fall on a screen, try the top right
	if (!gd) {
		for (i = 0; i < count; i++) {
			r = [[a objectAtIndex: i] frame];
			r.origin.y = main_screen_height - (r.origin.y + r.size.height); // use FLTK's multiscreen coordinates
			if (R >= r.origin.x && R <= r.origin.x + r.size.width
				&& Y >= r.origin.y  && Y <= r.origin.y + r.size.height) break;
		}
		if (i < count) gd = [a objectAtIndex: i];
	}
	// if that doesn't fall on a screen, try the bottom left
	if (!gd) {
		for (i = 0; i < count; i++) {
			r = [[a objectAtIndex: i] frame];
			r.origin.y = main_screen_height - (r.origin.y + r.size.height); // use FLTK's multiscreen coordinates
			if (X >= r.origin.x && X <= r.origin.x + r.size.width
				&& Y + H >= r.origin.y  && Y + H <= r.origin.y + r.size.height) break;
		}
		if (i < count) gd = [a objectAtIndex: i];
	}
	// last resort, try the bottom right
	if (!gd) {
		for (i = 0; i < count; i++) {
			r = [[a objectAtIndex: i] frame];
			r.origin.y = main_screen_height - (r.origin.y + r.size.height); // use FLTK's multiscreen coordinates
			if (R >= r.origin.x && R <= r.origin.x + r.size.width
				&& Y + H >= r.origin.y  && Y + H <= r.origin.y + r.size.height) break;
		}
		if (i < count) gd = [a objectAtIndex: i];
	}
	// if we still have not found a screen, we will use the main
	// screen, the one that has the application menu bar.
	if (!gd) gd = [a objectAtIndex: 0];
	if (gd) {
		r = [gd visibleFrame];
		r.origin.y = main_screen_height - (r.origin.y + r.size.height); // use FLTK's multiscreen coordinates
		if (R > r.origin.x + r.size.width) X -= int(R - (r.origin.x + r.size.width));
		if (B > r.size.height + r.origin.y) Y -= int(B - (r.size.height + r.origin.y));
		if (X < r.origin.x) X = int(r.origin.x);
		if (Y < r.origin.y) Y = int(r.origin.y);
	}

	// Return the client area's top left corner in (X,Y)
	X += xoff;
	Y += yoff;

	return ret;
}

void Fl_Window::fullscreen_x()
{
}

void Fl_Window::fullscreen_off_x(int X, int Y, int W, int H)
{
}

/*
 * Initialize the given port for redraw and call the window's flush() to actually draw the content
 */
void Fl_X::flush()
{
}


/*
 * go ahead, create that (sub)window
 */
void Fl_X::make(Fl_Window *w)
{
	if (w->parent()) {      // create a subwindow
		Fl_Group::current(0);
		// our subwindow needs this structure to know about its clipping.
		Fl_X *x = new Fl_X;
		x->subwindow = true;
		x->other_xid = 0;
		x->region = 0;
		x->subRegion = 0;
		x->cursor = NULL;
		x->gc = 0;          // stay 0 for Quickdraw; fill with CGContext for Quartz
		w->set_visible();
		Fl_Window *win = w->window();
		Fl_X *xo = Fl_X::i(win);
		if (xo) {
			x->xidNext = xo->xidChildren;
			x->xidChildren = 0L;
			xo->xidChildren = x;
			x->xid = win->i->xid;
			x->w = w; w->i = x;
			x->wait_for_expose = 0;
			{
				Fl_X *z = xo->next; // we don't want a subwindow in Fl_X::first
				xo->next = x;
				x->next = z;
			}
			int old_event = Fl::e_number;
			w->handle(Fl::e_number = FL_SHOW);
			Fl::e_number = old_event;
			w->redraw();      // force draw to happen
		}
		/*
		if (w->as_gl_window()) { // if creating a sub-GL-window
			while (win->window()) win = win->window();
			[Fl_X::i(win)->xid containsGLsubwindow: YES];
		}
		*/
		fl_show_iconic = 0;
	} else {            // create a desktop window
		Fl_Group::current(0);
		fl_open_display();
		NSInteger winlevel = NSNormalWindowLevel;
		NSUInteger winstyle;
		if (w->border()) winstyle = NSTitledWindowMask | NSClosableWindowMask | NSMiniaturizableWindowMask;
		else winstyle = NSBorderlessWindowMask;
		int xp = w->x();
		int yp = w->y();
		int wp = w->w();
		int hp = w->h();
		if (w->size_range_set) {
			if (w->minh != w->maxh || w->minw != w->maxw) {
				if (w->border()) winstyle |= NSResizableWindowMask;
			}
		} else {
			if (w->resizable()) {
				Fl_Widget *o = w->resizable();
				int minw = o->w(); if (minw > 100) minw = 100;
				int minh = o->h(); if (minh > 100) minh = 100;
				w->size_range(w->w() - o->w() + minw, w->h() - o->h() + minh, 0, 0);
				if (w->border()) winstyle |= NSResizableWindowMask;
			} else {
				w->size_range(w->w(), w->h(), w->w(), w->h());
			}
		}
		int xwm = xp, ywm = yp, bt, bx, by;

		if (!fake_X_wm(w, xwm, ywm, bt, bx, by)) {
			// menu windows and tooltips
			if (w->modal() || w->tooltip_window()) {
				winlevel = modal_window_level();
			}
			//winstyle = NSBorderlessWindowMask;
		}
		if (w->modal()) {
			winstyle &= ~NSMiniaturizableWindowMask;
			// winstyle &= ~(NSResizableWindowMask | NSMiniaturizableWindowMask);
			winlevel = modal_window_level();
		} else if (w->non_modal()) {
			winlevel = non_modal_window_level();
		}

		if (by + bt) {
			wp += 2 * bx;
			hp += 2 * by + bt;
		}
		if (w->force_position()) {
			if (!Fl::grab()) {
				xp = xwm; yp = ywm;
				w->x(xp); w->y(yp);
			}
			xp -= bx;
			yp -= by + bt;
		}

		if (w->non_modal() && Fl_X::first /*&& !fl_disable_transient_for*/) {
			// find some other window to be "transient for":
			Fl_Window *w = Fl_X::first->w;
			while (w->parent()) w = w->window(); // todo: this code does not make any sense! (w!=w??)
		}

		Fl_X *x = new Fl_X;
		x->subwindow = false;
		x->other_xid = 0; // room for doublebuffering image map. On OS X this is only used by overlay windows
		x->region = 0;
		x->subRegion = 0;
		x->cursor = NULL;
		x->xidChildren = 0;
		x->xidNext = 0;
		x->gc = 0;

		NSRect crect;
		if (w->fullscreen_active()) {
			int top, bottom, left, right;
			int sx, sy, sw, sh, X, Y, W, H;

			top = w->fullscreen_screen_top;
			bottom = w->fullscreen_screen_bottom;
			left = w->fullscreen_screen_left;
			right = w->fullscreen_screen_right;

			if ((top < 0) || (bottom < 0) || (left < 0) || (right < 0)) {
				top = Fl::screen_num(w->x(), w->y(), w->w(), w->h());
				bottom = top;
				left = top;
				right = top;
			}

			Fl::screen_xywh(sx, sy, sw, sh, top);
			Y = sy;
			Fl::screen_xywh(sx, sy, sw, sh, bottom);
			H = sy + sh - Y;
			Fl::screen_xywh(sx, sy, sw, sh, left);
			X = sx;
			Fl::screen_xywh(sx, sy, sw, sh, right);
			W = sx + sw - X;

			w->resize(X, Y, W, H);

			winstyle = NSBorderlessWindowMask;
			winlevel = NSStatusWindowLevel;
		}
		crect.origin.x = w->x();
		crect.origin.y = main_screen_height - (w->y() + w->h());
		crect.size.width = w->w();
		crect.size.height = w->h();
		FLWindow *cw = [[FLWindow alloc] initWithFl_W: w
										  contentRect: crect
											styleMask: winstyle];
		[cw setFrameOrigin: crect.origin];
		[cw setHasShadow: YES];
		[cw setAcceptsMouseMovedEvents: YES];
		x->xid = cw;
		x->w = w; w->i = x;
		x->wait_for_expose = 1;
		x->next = Fl_X::first;
		Fl_X::first = x;
		FLView *myview = [[FLView alloc] init];
		[cw setContentView: myview];
		[myview release];
		[cw setLevel: winlevel];

		q_set_window_title(cw, w->label(), w->iconlabel());
		if (!w->force_position()) {
			if (w->modal()) {
				[cw center];
			} else if (w->non_modal()) {
				[cw center];
			} else {
				static NSPoint delta = NSZeroPoint;
				delta = [cw cascadeTopLeftFromPoint: delta];
			}
		}
		if (w->menu_window()) { // make menu windows slightly transparent
			[cw setAlphaValue: 0.97];
		}
		// Install DnD handlers
		[myview registerForDraggedTypes: [NSArray arrayWithObjects: utf8_format,  NSFilenamesPboardType, nil]];
		if (!Fl_X::first->next) {
			// if this is the first window, we need to bring the application to the front
			ProcessSerialNumber psn = { 0, kCurrentProcess };
			SetFrontProcess(&psn);
		}

		if (w->size_range_set) w->size_range_();

		if (w->border() || (!w->modal() && !w->tooltip_window())) {
			Fl_Tooltip::enter(0);
		}

		if (w->modal()) Fl::modal_ = w;

		w->set_visible();
		if (w->border() || (!w->modal() && !w->tooltip_window())) Fl::handle(FL_FOCUS, w);
		Fl::first_window(w);
		[cw setDelegate: [FLWindowDelegate createOnce]];
		if (fl_show_iconic) {
			fl_show_iconic = 0;
			[cw miniaturize: nil];
		} else {
			[cw makeKeyAndOrderFront: nil];
		}

		crect = [[cw contentView] frame];
		w->w(int(crect.size.width));
		w->h(int(crect.size.height));
		crect = [cw frame];
		w->x(int(crect.origin.x));
		w->y(int(main_screen_height - (crect.origin.y + w->h())));

		int old_event = Fl::e_number;
		w->handle(Fl::e_number = FL_SHOW);
		Fl::e_number = old_event;

		// if (w->modal()) { Fl::modal_ = w; fl_fix_focus(); }
	}
}


/*
 * Tell the OS what window sizes we want to allow
 */
void Fl_Window::size_range_()
{
}


/*
 * returns pointer to the filename, or null if name ends with ':'
 */
const char* fl_filename_name(const char *name)
{
	const char *p, *q;
	if (!name) return (0);
	for (p = q = name; *p;) {
		if ((p[0] == ':') && (p[1] == ':')) {
			q = p + 2;
			p++;
		} else if (p[0] == '/') {
			q = p + 1;
		}
		p++;
	}
	return q;
}


/*
 * set the window title bar name
 */
void Fl_Window::label(const char *name, const char *mininame)
{
}


/*
 * make a window visible
 */
void Fl_Window::show()
{
	image(Fl::scheme_bg_);
	if (Fl::scheme_bg_) {
		labeltype(FL_NORMAL_LABEL);
		align(FL_ALIGN_CENTER | FL_ALIGN_INSIDE | FL_ALIGN_CLIP);
	} else {
		labeltype(FL_NO_LABEL);
	}
	Fl_Tooltip::exit(this);
	if (!shown() || !i) {
		Fl_X::make(this);
	} else {
		if (!parent()) {
			if ([i->xid isMiniaturized]) {
				i->w->redraw();
				[i->xid deminiaturize: nil];
			}
			if (!fl_capture) {
				[i->xid makeKeyAndOrderFront: nil];
			}
		}
	}
}

/*
 * resize a window
 */
void Fl_Window::resize(int X, int Y, int W, int H)
{
}

void Fl_Window::make_current()
{
}

// FLTK has only one global graphics state. This function copies the FLTK state into the
// current Quartz context
void Fl_X::q_fill_context()
{
}

// The only way to reset clipping to its original state is to pop the current graphics
// state and restore the global state.
void Fl_X::q_clear_clipping()
{
}

// Give the Quartz context back to the system
void Fl_X::q_release_context(Fl_X *x)
{
}

void Fl_X::q_begin_image(CGRect &rect, int cx, int cy, int w, int h)
{
}

void Fl_X::q_end_image()
{
}

/*
 * create a selection
 * stuff: pointer to selected data
 * len: size of selected data
 * type: always "plain/text" for now
 */
void Fl::copy(const char *stuff, int len, int clipboard, const char *type)
{
}

// Call this when a "paste" operation happens:
void Fl::paste(Fl_Widget &receiver, int clipboard, const char *type)
{
}

int Fl::clipboard_contains(const char *type)
{
	return 0;
}

int Fl_X::unlink(Fl_X *start)
{
	return 0;
}

void Fl_X::relink(Fl_Window *w, Fl_Window *wp)
{
}

void Fl_X::destroy()
{
	// subwindows share their xid with their parent window, so should not close it
	if (!subwindow && w && !w->parent() && xid) {
		[xid close];
	}
}

void Fl_X::map()
{
}

void Fl_X::unmap()
{
}

// intersects current and x,y,w,h rectangle and returns result as a new Fl_Region
Fl_Region Fl_X::intersect_region_and_rect(Fl_Region current, int x, int y, int w, int h)
{
	return 0;
}

void Fl_X::collapse()
{
}

CFDataRef Fl_X::CGBitmapContextToTIFF(CGContextRef c)
{ 
	return (CFDataRef)0;
}

int Fl_X::set_cursor(Fl_Cursor c)
{
	return 1;
}

int Fl_X::set_cursor(const Fl_RGB_Image *image, int hotx, int hoty)
{
	return 1;
}

void Fl_X::set_key_window()
{
}

int Fl::dnd(void)
{
	return true;
}

unsigned char* Fl_X::bitmap_from_window_rect(Fl_Window *win, int x, int y, int w, int h, int *bytesPerPixel)
/* Returns a capture of a rectangle of a mapped window as a pre-multiplied RGBA array of bytes.
 Alpha values are always 1 (except for the angles of a window title bar)
 so pre-multiplication can be ignored. 
 *bytesPerPixel is always set to the value 4 upon return.
 delete[] the returned pointer after use
 */
{
	return 0;
}

CGImageRef Fl_X::CGImage_from_window_rect(Fl_Window *win, int x, int y, int w, int h)
// CFRelease the returned CGImageRef after use
{
	return 0;
}

Window fl_xid(const Fl_Window *w)
{
	Fl_X *temp = Fl_X::i(w);
	return temp ? temp->xid : 0;
}

int Fl_Window::decorated_w()
{
	return 0;
}

int Fl_Window::decorated_h()
{
	return 0;
}

/* Returns the address of a Carbon function after dynamically loading the Carbon library if needed.
 Supports old Mac OS X versions that may use a couple of Carbon calls:
 GetKeys used by OS X 10.3 or before (in Fl::get_key())
 PMSessionPageSetupDialog and PMSessionPrintDialog used by 10.4 or before (in Fl_Printer::start_job())
 GetWindowPort used by 10.4 or before (in Fl_Gl_Choice.cxx)
 */
void* Fl_X::get_carbon_function(const char *function_name)
{
	return 0;
}

void Fl::add_fd(int n, int events, void (*cb)(int, void *), void *v)
{
}

void Fl::add_fd(int fd, void (*cb)(int, void *), void *v)
{
}

void Fl::remove_fd(int n, int events)
{
}

void Fl::remove_fd(int n)
{
}

//*********************** main ************************************
#ifdef main
#undef main
#endif

int main(int argc, char **argv)
{
    int i;
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];

    /* store arguments */
    forward_argc = argc;
    forward_argv = (char **)malloc((argc+1) * sizeof(char *));
    for (i = 0; i < argc; i++) {
        forward_argv[i] = (char*)malloc( (strlen(argv[i])+1) * sizeof(char));
        strcpy(forward_argv[i], argv[i]);
    }
    forward_argv[i] = NULL;

    /* Give over control to run loop, FLTKUIKitDelegate will handle most things from here */
    UIApplicationMain(argc, argv, NULL, [FLTKUIKitDelegate getAppDelegateClassName]);

    /* free the memory we used to hold copies of argc and argv */
    for (i = 0; i < forward_argc; i++) {
        free(forward_argv[i]);
    }
    free(forward_argv);

    [pool release];
    return exit_status;
}

// ****************** Class Implement ***************************
// ***********************************************************
// FLTKUIKitDelegate Implement
// ***********************************************************
@implementation FLTKUIKitDelegate
/* convenience method */
+ (id) sharedAppDelegate
{
    /* the delegate is set in UIApplicationMain(), which is garaunteed to be called before this method */
    return [[UIApplication sharedApplication] delegate];
}
+ (NSString *)getAppDelegateClassName
{
    /* subclassing notice: when you subclass this appdelegate, make sure to add a category to override
       this method and return the actual name of the delegate */
    return @"FLTKUIKitDelegate";
}
- (id)init
{
    self = [super init];
    return self;
}
- (void)postFinishLaunch
{
    /* run the user's application, passing argc and argv */
    FLTK_iPhoneSetEventPump(YES);
    exit_status = IOS_main(forward_argc, forward_argv);
    FLTK_iPhoneSetEventPump(NO);

    /* If we showed a splash image, clean it up */
    if (launch_window) {
        [launch_window release];
        launch_window = NULL;
    }

    /* exit, passing the return status from the user's application */
    /* We don't actually exit to support applications that do setup in
     * their main function and then allow the Cocoa event loop to run.
     */
    /* exit(exit_status); */
}
- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    /* Keep the launch image up until we set a video mode */
    launch_window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];

    UIViewController *splashViewController = [[FLTK_splashviewcontroller alloc] init];
    launch_window.rootViewController = splashViewController;
    [launch_window addSubview:splashViewController.view];
    [launch_window makeKeyAndVisible];

    /* Set working directory to resource path */
    [[NSFileManager defaultManager] changeCurrentDirectoryPath: [[NSBundle mainBundle] resourcePath]];

    /* register a callback for the idletimer hint */
    //SDL_AddHintCallback(SDL_HINT_IDLE_TIMER_DISABLED, SDL_IdleTimerDisabledChanged, NULL);

    //SDL_SetMainReady();
    [self performSelector:@selector(postFinishLaunch) withObject:nil afterDelay:0.0];

    return YES;
}
- (void)applicationWillTerminate:(UIApplication *)application
{
    //SDL_SendAppEvent(SDL_APP_TERMINATING);
	
	fl_lock_function();
	//NSApplicationTerminateReply reply = NSTerminateNow;
	while (Fl_X::first) {
		Fl_X *x = Fl_X::first;
		Fl::handle(FL_CLOSE, x->w);
		Fl::do_widget_deletion();
		if (Fl_X::first == x) {
			//reply = NSTerminateCancel; // FLTK has not closed all windows, so we return to the main program now
			break;
		}
	}
	fl_unlock_function();
	//return reply;
}

- (void)applicationDidReceiveMemoryWarning:(UIApplication *)application
{
    //SDL_SendAppEvent(SDL_APP_LOWMEMORY);
}

- (void) applicationWillResignActive:(UIApplication*)application
{
	/*
    SDL_VideoDevice *_this = SDL_GetVideoDevice();
    if (_this) {
        SDL_Window *window;
        for (window = _this->windows; window != nil; window = window->next) {
            SDL_SendWindowEvent(window, SDL_WINDOWEVENT_FOCUS_LOST, 0, 0);
            SDL_SendWindowEvent(window, SDL_WINDOWEVENT_MINIMIZED, 0, 0);
        }
    }
    SDL_SendAppEvent(SDL_APP_WILLENTERBACKGROUND);
	*/
	
	fl_lock_function();
	Fl_X *x;
	FLWindow *top = 0;
	// sort in all regular windows
	for (x = Fl_X::first; x; x = x->next) {
		FLWindow *cw = x->xid;
		Fl_Window *win = x->w;
		if (win && cw) {
			if (win->modal()) {
			} else if (win->non_modal()) {
			} else {
				if (!top) top = cw;
			}
		}
	}
	// now sort in all modals
	for (x = Fl_X::first; x; x = x->next) {
		FLWindow *cw = x->xid;
		Fl_Window *win = x->w;
		if (win && cw && [cw isVisible]) {
			if (win->modal()) {
				[cw setLevel: NSNormalWindowLevel];
				if (top) [cw orderWindow: NSWindowAbove relativeTo: [top windowNumber]];
			}
		}
	}
	// finally all non-modals
	for (x = Fl_X::first; x; x = x->next) {
		FLWindow *cw = x->xid;
		Fl_Window *win = x->w;
		if (win && cw && [cw isVisible]) {
			if (win->non_modal()) {
				[cw setLevel: NSNormalWindowLevel];
				if (top) [cw orderWindow: NSWindowAbove relativeTo: [top windowNumber]];
			}
		}
	}
	fl_unlock_function();
}

- (void) applicationDidEnterBackground:(UIApplication*)application
{
    //SDL_SendAppEvent(SDL_APP_DIDENTERBACKGROUND);
	fl_lock_function();
	Fl_X *x;
	for (x = Fl_X::first; x; x = x->next) {
		Fl_Window *window = x->w;
		if (!window->parent()) Fl::handle(FL_HIDE, window);
	}
	fl_unlock_function();
}

- (void) applicationWillEnterForeground:(UIApplication*)application
{
    //SDL_SendAppEvent(SDL_APP_WILLENTERFOREGROUND);
	fl_lock_function();
	Fl_X *x;
	for (x = Fl_X::first; x; x = x->next) {
		Fl_Window *w = x->w;
		if (!w->parent() && ![x->xid isMiniaturized]) {
			Fl::handle(FL_SHOW, w);
		}
	}
	fl_unlock_function();
}

// makes sure modal and non-modal windows stay on top
static void fixup_window_levels(void)
{
	NSInteger modal_level, non_modal_level;

	Fl_X *x;
	FLWindow * prev_modal,*prev_non_modal;

	modal_level = modal_window_level();
	non_modal_level = non_modal_window_level();

	prev_modal = NULL;
	prev_non_modal = NULL;

	for (x = Fl_X::first; x; x = x->next) {
		FLWindow *cw = x->xid;
		Fl_Window *win = x->w;
		if (!win || !cw || ![cw isVisible]) continue;
		if (win->modal()) {
			if ([cw level] != modal_level) {
				[cw setLevel: modal_level];
				// changing level puts then in front, so make sure the
				// stacking isn't messed up
				if (prev_modal != NULL) [cw orderWindow: NSWindowBelow
											 relativeTo: [prev_modal windowNumber]];
			}
			prev_modal = cw;
		} else if (win->non_modal()) {
			if ([cw level] != non_modal_level) {
				[cw setLevel: non_modal_level];
				if (prev_non_modal != NULL) [cw orderWindow: NSWindowBelow relativeTo: [prev_non_modal windowNumber]];
			}
			prev_non_modal = cw;
		}
	}
}
- (void) applicationDidBecomeActive:(UIApplication*)application
{
	/*
    SDL_SendAppEvent(SDL_APP_DIDENTERFOREGROUND);

    SDL_VideoDevice *_this = SDL_GetVideoDevice();
    if (_this) {
        SDL_Window *window;
        for (window = _this->windows; window != nil; window = window->next) {
            SDL_SendWindowEvent(window, SDL_WINDOWEVENT_FOCUS_GAINED, 0, 0);
            SDL_SendWindowEvent(window, SDL_WINDOWEVENT_RESTORED, 0, 0);
        }
    }
	*/
	
	fl_lock_function();

	// update clipboard status
	clipboard_check();

	/**
	 * Cocoa organizes the Z depth of windows on a global priority. FLTK however
	 * expects the window manager to organize Z level by application. The trickery
	 * below will change Z order during activation and deactivation.
	 */
	fixup_window_levels();

	fl_unlock_function();
}

- (BOOL)application:(UIApplication *)application openURL:(NSURL *)url sourceApplication:(NSString *)sourceApplication annotation:(id)annotation
{
/*
    NSURL *fileURL = [url filePathURL];
    if (fileURL != nil) {
        SDL_SendDropFile([[fileURL path] UTF8String]);
    } else {
        SDL_SendDropFile([[url absoluteString] UTF8String]);
    }
*/	
    return YES;
}
@end

// ***********************************************************
// FLTK_splashviewcontroller Implement
// ***********************************************************
@implementation FLTK_splashviewcontroller
- (id)init
{
    self = [super init];
    if (self == nil) {
        return nil;
    }

    self->splash = [[UIImageView alloc] init];
    [self setView:self->splash];

    CGSize size = [UIScreen mainScreen].bounds.size;
    float height = FLTK_max(size.width, size.height);
    self->splashPortrait = [UIImage imageNamed:[NSString stringWithFormat:@"Default-%dh.png", (int)height]];
    if (!self->splashPortrait) {
        self->splashPortrait = [UIImage imageNamed:@"Default.png"];
    }
    self->splashLandscape = [UIImage imageNamed:@"Default-Landscape.png"];
    if (!self->splashLandscape && self->splashPortrait) {
        self->splashLandscape = [[UIImage alloc] initWithCGImage: self->splashPortrait.CGImage scale: 1.0 orientation: UIImageOrientationRight];
    }
    if (self->splashPortrait) {
        [self->splashPortrait retain];
    }
    if (self->splashLandscape) {
        [self->splashLandscape retain];
    }

    [self updateSplashImage:[[UIApplication sharedApplication] statusBarOrientation]];

    return self;
}
- (NSUInteger)supportedInterfaceOrientations
{
    NSUInteger orientationMask = UIInterfaceOrientationMaskAll;

    /* Don't allow upside-down orientation on the phone, so answering calls is in the natural orientation */
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
        orientationMask &= ~UIInterfaceOrientationMaskPortraitUpsideDown;
    }
    return orientationMask;
}
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)orient
{
    NSUInteger orientationMask = [self supportedInterfaceOrientations];
    return (orientationMask & (1 << orient));
}
- (void)willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation duration:(NSTimeInterval)duration
{
    [self updateSplashImage:interfaceOrientation];
}
- (void)updateSplashImage:(UIInterfaceOrientation)interfaceOrientation
{
    UIImage *image;

    if (UIInterfaceOrientationIsLandscape(interfaceOrientation)) {
        image = self->splashLandscape;
    } else {
        image = self->splashPortrait;
    }
    if (image)
    {
        splash.image = image;
    }
}
@end

#endif // __FLTK_IPHONEOS__