//
// "$Id: mac.H 10159 2014-05-23 16:47:21Z manolo $"
//
// Mac header file for the Fast Light Tool Kit (FLTK).
//
// Copyright 1998-2011 by Bill Spitzak and others.
//
// This library is free software. Distribution and use rights are outlined in
// the file "COPYING" which should have been included with this file.  If this
// file is missing or damaged, see the license at:
//
//     http://www.fltk.org/COPYING.php
//
// Please report all bugs and problems on the following page:
//
//     http://www.fltk.org/str.php
//

// Do not directly include this file, instead use <x.H>.  It will
// include this file if "__APPLE__" is defined.  This is to encourage
// portability of even the system-specific code...

#if __FLTK_IPHONEOS__

#ifndef FL_DOXYGEN

#if !defined(Fl_X_H)
#  error "Never use <x_mac.H> directly; include <x.H> instead."
#endif // !Fl_X_H

//#ifdef __OBJC__
@class FLWindow; // a subclass of the NSWindow Cocoa class
typedef FLWindow *Window;
//#else
//typedef class FLWindow_opaque *Window; // pointer to the FLWindow objective-c class
//#endif // __OBJC__


// Standard MacOS C/C++ includes...
#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>

//Import AudioToolbox.framework
#import <AudioToolbox/AudioToolbox.h>

#undef check // because of Fl::check()

// ======================================================
/*
 *  System Versioning Preprocessor Macros
 */

#define SYSTEM_VERSION_EQUAL_TO(v)                  ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] == NSOrderedSame)
#define SYSTEM_VERSION_GREATER_THAN(v)              ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] == NSOrderedDescending)
#define SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(v)  ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] != NSOrderedAscending)
#define SYSTEM_VERSION_LESS_THAN(v)                 ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] == NSOrderedAscending)
#define SYSTEM_VERSION_LESS_THAN_OR_EQUAL_TO(v)     ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] != NSOrderedDescending)

/*
//  Usage
if (SYSTEM_VERSION_LESS_THAN(@"4.0")) {
    ...
}
if (SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"3.1.1")) {
    ...
}
*/
// ======================================================

typedef CGContextRef Fl_Offscreen;

typedef struct flIOSRegion {
	int count;
	CGRect *rects;
} *Fl_Region;  // a region is the union of a series of rectangles

#  include "Fl_Window.H"
#  include "src/Fl_Font.H"

// Some random X equivalents
struct XPoint {
	int x, y;
};
struct XRectangle {
	int x, y, width, height;
};
#ifndef CGFLOAT_DEFINED //appears with 10.5 in CGBase.h
#if defined(__LP64__) && __LP64__
typedef double CGFloat;
#else
typedef float CGFloat;
#endif
#endif // CGFLOAT_DEFINED

extern CGRect fl_cgrectmake_cocoa(int x, int y, int w, int h);
inline Fl_Region XRectangleRegion(int x, int y, int w, int h)
{
	Fl_Region R = (Fl_Region)malloc(sizeof(*R));
	R->count = 1;
	R->rects = (CGRect *)malloc(sizeof(CGRect));
	*(R->rects) = fl_cgrectmake_cocoa(x, y, w, h);
	return R;
}
inline void XDestroyRegion(Fl_Region r)
{
	if(r) {
		free(r->rects);
		free(r);
	}
}

// This object contains all mac-specific stuff about a window:
// WARNING: this object is highly subject to change!
class Fl_X
{
public:
	Window xid;              // pointer to the Cocoa window object (FLWindow*)
	Fl_Offscreen other_xid;  // pointer for offscreen bitmaps (overlay window)
	Fl_Window *w;            // FLTK window for
	Fl_Region region;
	Fl_Region subRegion;     // region for this specific subwindow
	Fl_X *next;              // linked tree to support subwindows
	Fl_X *xidChildren, *xidNext; // more subwindow tree
	int wait_for_expose;
	static Fl_X* first;
	static Fl_X* i(const Fl_Window* w) {
		return w->flx;
	}
    static int fake_X_wm(const Fl_Window*,int&,int&,int&,int&,int&);
	static void make(Fl_Window*);
	void flush();
    static void set_high_resolution(bool);
    CGRect* subRect() {
        return subRect_;        // getter
    }
    void subRect(CGRect *r) {
        subRect_ = r;        // setter
    }
    bool mapped_to_retina();      // is window mapped to retina display?
    void mapped_to_retina(bool);  // sets whether window is mapped to retina display
    bool changed_resolution();      // did window just moved to display with another resolution?
    void changed_resolution(bool);// sets whether window just moved to display with another resolution
    bool in_windowDidResize();      // is window performing windowDidResize?
    void in_windowDidResize(bool);  // sets whether window is performing windowDidResize
	// Quartz additions:
	CGContextRef gc;                 // graphics context (NULL when using QD)
	static void q_fill_context();    // fill a Quartz context with current FLTK state
	static void q_clear_clipping();  // remove all clipping from a Quartz context
	static void q_release_context(Fl_X *x=0); // free all resources associated with fl_gc
	static void q_begin_image(CGRect&, int x, int y, int w, int h);
	static void q_end_image();
	// Cocoa additions
	void destroy(void);
	void map(void);
	void unmap(void);
	//int unlink(Fl_X* start = NULL);
	void collapse(void);
	void set_key_window(void);
	static CGImageRef CGImage_from_window_rect(Fl_Window *win, int x, int y, int w, int h);
	static unsigned char *bitmap_from_window_rect(Fl_Window *win, int x, int y, int w, int h, int *bytesPerPixel);
	static CFDataRef CGBitmapContextToTIFF(CGContextRef c);
	static Fl_Region intersect_region_and_rect(Fl_Region current, int x,int y,int w, int h);
	static void screen_work_area(int &X, int &Y, int &W, int &H, int n); // compute work area of a given screen
	static int next_marked_length; // next length of marked text after current marked text will have been replaced
	static int insertion_point_location(int *px, int *py, int *pheight); // computes window coordinates & height of insertion point
	static const int CoreText_threshold;  // Mac OS version from which the Core Text API is used to display text
	static Fl_Fontdesc* calc_fl_fonts(void); // computes the fl_fonts global variable
    static int dnd(int use_selection); // call Fl_X::dnd(1) to support text dragging
	
	static void set_default_icons(const Fl_RGB_Image*[], int) {};
	void set_icons() {};
	int set_cursor(Fl_Cursor){return 1;}
	int set_cursor(const Fl_RGB_Image*, int, int) {return 1;}
    
    static int softkeyboard_isshow();
    static void softkeyboard_work_area(int &X, int &Y, int &W, int &H);
    // touch
    static int mouse_simulate_by_touch();
    static int touch_type();
    static int touch_tapcount();
    static int touch_finger();
    static int touch_x(int finger);
    static int touch_y(int finger);
    static int touch_x_root(int finger);
    static int touch_y_root(int finger);
    
    static int touch_end_finger();
    static int touch_end_x(int finger);
    static int touch_end_y(int finger);
    static int touch_end_x_root(int finger);
    static int touch_end_y_root(int finger);
    
    static void setAlpha(const Fl_Window *win, const float alpha);
private:
	//static void relink(Fl_Window*, Fl_Window*);
	//bool subwindow;
    CGRect* subRect_;           // makes sure subwindow remains inside its parent window
    // stores 3 binary flags: whether window is mapped to retina display; whether resolution just changed;
    // whether window is OpenGL and is currently being resized.
    unsigned mapped_to_retina_;
    
public:
    static void beep()
    {
        //SystemSoundID soundID;
        //NSString *strSoundFile =  @"alertsound.wav";
        //AudioServicesCreateSystemSoundID((__bridge CFURLRef)[NSURL fileURLWithPath:strSoundFile],&soundID);
        AudioServicesPlaySystemSound(1104);
        //[[UIDevice currentDevice] playInputClick];
    }
};

extern Window fl_window;

//#endif // FL_LIBRARY || FL_INTERNALS

typedef CGImageRef Fl_Bitmask;

extern CGContextRef fl_gc;

extern Window fl_xid(const Fl_Window*);
extern Fl_Window* fl_find(Window xid);
void fl_clip_region(Fl_Region);

extern Fl_Bitmask fl_create_bitmask(int w, int h, const uchar *data);
extern Fl_Bitmask fl_create_alphamask(int w, int h, int d, int ld, const uchar *data);
extern void fl_delete_bitmask(Fl_Bitmask bm);
extern Fl_Offscreen fl_create_offscreen(int w, int h);
extern void fl_copy_offscreen(int x,int y,int w,int h, Fl_Offscreen gWorld, int srcx,int srcy);
extern void fl_delete_offscreen(Fl_Offscreen gWorld);
extern void fl_begin_offscreen(Fl_Offscreen gWorld);
extern void fl_end_offscreen();

extern int fl_parse_color(const char* p, uchar& r, uchar& g, uchar& b);
extern void fl_open_display();

#endif // FL_DOXYGEN
/** \file
 Mac OS X-specific symbols.
 */

/** \defgroup group_macosx Mac OS X-specific symbols
 Mac OS X-specific symbols declared in <x.H> or <gl.h>
 \sa \ref osissues_macos
 @{ */

/** @brief Register a function called for each file dropped onto an application icon.
 \e cb will be called with a single Unix-style file name and path.
 If multiple files were dropped, \e cb will be called multiple times.
 */
extern void fl_open_callback(void (*cb)(const char *));

// get document dir
extern char *ios_getcwd(char *b, int l);
extern char *ios_getworkdir(char *b, int l);
extern char *ios_getcurrentlang();
extern char *ios_getversion();
extern void ios_keyboard_quickclick(unsigned char active);

/** @} */

#endif

//
// End of "$Id: mac.H 10159 2014-05-23 16:47:21Z manolo $".
//

