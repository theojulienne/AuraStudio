module aura.window;

import aura.camera;

import claro.core;
import claro.base.all;
import claro.graphics.all;

import opengl.gl;

import std.stdio;
import std.math;
import std.c.time;
import std.date;
import std.conv;
import std.random;
import std.boxer;
import std.gc;

abstract class AuraWindow : WindowWidget {
	OpenGLWidget ogl;
	Layout lt;
	
	Camera cam;
	
	this( char[] type, char[] layout ) {
		super( null, new Bounds( 100, 50, 1024, 768 ), 0 );
		
		this.title = "Aura Studio - " ~ type;
		
		lt = new Layout( this, layout, 10, 10 );
		
		Claro.addToLoop( &this.handle_main );
		
		this.add_handler( "destroy", &this.closed );
		
		this.ogl = new OpenGLWidget( this, lt.bounds("scene") );
		this.ogl.redrawDelegate = &this.gl_redraw;
		
		this.ogl.notify = Widget.NotifyKey;
		
		glShadeModel(GL_SMOOTH);							// Enable Smooth Shading
		glClearColor(0.0f, 0.0f, 0.0f, 0.5f);				// Black Background
		glClearDepth(1.0f);									// Depth Buffer Setup
		glEnable(GL_DEPTH_TEST);							// Enables Depth Testing
		glDepthFunc(GL_LEQUAL);								// The Type Of Depth Testing To Do
		glHint(GL_PERSPECTIVE_CORRECTION_HINT, GL_NICEST);	// Really Nice Perspective Calculations
		
		this.ogl.add_handler( "resized", &this.gl_resized );
		//this.ogl.add_handler( "clicked", &this.clicked );
		//this.ogl.add_handler( "released", &this.released );
		this.ogl.add_handler( "mouse_moved", &this.mousemoved );
		this.ogl.add_handler( "middle_clicked", &this.middleclicked );
		this.ogl.add_handler( "middle_released", &this.middlereleased );
		this.ogl.add_handler( "scroll_wheel", &this.scrollwheel );
		//this.ogl.add_handler( "right_clicked", &this.context );
		//this.ogl.add_handler( "key_down", &this.key_down );
		//this.ogl.add_handler( "key_up", &this.key_up );
		this.gl_resized( null, this.ogl );
	}
	
	bool middle_tracking;
	int mouse_lastx, mouse_lasty;
	void middleclicked( CEvent evt, CObject obj )
	{
		int x = evt.getArgumentAsInt("x");
		int y = evt.getArgumentAsInt("y");
		
		if ( middle_tracking )
			return;
		
		Cursor.capture( );
		Cursor.hide( );
		
		middle_tracking = true;
		mouse_lastx = x;
		mouse_lasty = y;
	}
	
	void middlereleased( CEvent evt, CObject obj )
	{
		middle_tracking = false;
		
		Cursor.show( );
		Cursor.release( );
	}
	
	void scrollwheel( CEvent evt, CObject obj )
	{
		double deltaY = evt.getArgumentAsDouble( "deltaY" );
		double deltaX = evt.getArgumentAsDouble( "deltaX" );
		
		int modifiers = evt.getArgumentAsInt("modifiers");
		
		cam.spin_horiz += deltaX;
		
		if ( modifiers & Widget.ModifierKeyAlternate )
			cam.spin_vert += deltaY;
		else
			cam.dist -= deltaY * 0.25f;
	}
	
	void middledragged( CEvent evt, CObject obj )
	{
		int a, b;
		
		a = evt.getArgumentAsInt("deltaX");//x - mouse_lastx;
		b = evt.getArgumentAsInt("deltaY");//y - mouse_lasty;

		//mouse_lastx = x;
		//mouse_lasty = y;
		
		cam.spin_horiz -= a * 0.5f;
		cam.spin_vert -= b * 0.5f;
	}
	
	void mousemoved( CEvent evt, CObject obj )
	{
		int x = evt.getArgumentAsInt("x");
		int y = evt.getArgumentAsInt("y");
		
		if ( middle_tracking )
		{
			middledragged( evt, obj );
			return true;
		}
		
		mouse_moved( evt, obj );
	}
	
	void mouse_moved( CEvent evt, CObject obj )
	{
		
	}
	
	void gl_redraw( OpenGLWidget w ) {
		
	}
	
	void prepareGl( )
	{
		glMatrixMode( GL_MODELVIEW );
		glLoadIdentity( );

		// clear depth
		glClearDepth( 1.0f );

		// enable some GL features
		glEnable( GL_DEPTH_TEST );
		glDepthFunc( GL_LESS ); //QUAL );

		glHint( GL_PERSPECTIVE_CORRECTION_HINT, GL_NICEST );
		glHint( GL_POINT_SMOOTH_HINT, GL_NICEST );

		glEnable( GL_TEXTURE_2D );

		glEnable( GL_ALPHA_TEST );
		glEnable( GL_BLEND );
		//glBlendFunc(GL_SRC_ALPHA,GL_ONE);
		glBlendFunc( GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA );
		glAlphaFunc( GL_GEQUAL, 0.01f );

		glShadeModel( GL_SMOOTH );

		glEnable( GL_CULL_FACE );
		glCullFace( GL_BACK );

		// smoothing
		//glEnable( GL_POLYGON_SMOOTH );
		glEnable( GL_LINE_SMOOTH );
		glEnable( GL_POINT_SMOOTH );
	}
	
	void drawGrid( )
	{
		float grids = 0.5f;
		int size = 20;
		int start = -size/2;
		int end = -start;
		int a;

		glBegin( GL_LINES );

		glColor4f( 0.0f, 0.0f, 0.0f, 0.2f );

		for ( a = start; a <= end; a++ )
		{
			glVertex3f( a*grids, 0.0f, start*grids );
			glVertex3f( a*grids, 0.0f, end*grids );

			glVertex3f( start*grids, 0.0f, a*grids );
			glVertex3f( end*grids, 0.0f, a*grids );
		}

		glEnd( );
	}
	
	void drawDir( )
	{
		float len = 20.0f;

		glBegin( GL_LINES );

			// X +
			glColor4f( 0.6f, 0.0f, 0.0f, 0.7f );
			glVertex3f( 0.0f, 0.001f, 0.0f );
			glVertex3f( len, 0.001f, 0.0f );

			// X -
			glColor4f( 0.0f, 0.0f, 0.0f, 0.2f );
			glVertex3f( 0.0f, 0.001f, 0.0f );
			glVertex3f( -len, 0.001f, 0.0f );

			// Y +
			glColor4f( 0.0f, 0.6f, 0.0f, 0.7f );
			glVertex3f( 0.0f, 0.0f, 0.0f );
			glVertex3f( 0.0f, len, 0.0f );

			// Y -
			glColor4f( 0.0f, 0.0f, 0.0f, 0.2f );
			glVertex3f( 0.0f, 0.0f, 0.0f );
			glVertex3f( 0.0f, -len, 0.0f );

			// Z +
			glColor4f( 0.0f, 0.0f, 0.6f, 0.7f );
			glVertex3f( 0.0f, 0.001f, 0.0f );
			glVertex3f( 0.0f, 0.001f, len );

			// Z -
			glColor4f( 0.0f, 0.0f, 0.0f, 0.2f );
			glVertex3f( 0.0f, 0.001f, 0.0f );
			glVertex3f( 0.0f, 0.001f, -len );

		glEnd( );
	}
	
	void gl_resized( CEvent evt, CObject obj ) {
		int width = ogl.bounds.width;
		int height = ogl.bounds.height;
		
		if ( height == 0 ) height = 1;
		
		glViewport( 0, 0, width, height );

		glMatrixMode(GL_PROJECTION);
		glLoadIdentity();
		
		gluPerspective(45.0f,cast(float)width/cast(float)height,0.1f,10000);

		glMatrixMode(GL_MODELVIEW);
		glLoadIdentity();
	}
	
	void closed( CEvent evt, CObject obj ) {
		Claro.shutdown( );
	}
	
	// Gets run every claro loop iteration. Every second, redraws canvas.
	void handle_main( CEvent evt, CObject obj ) {
		this.ogl.redraw( );
		
		std.gc.fullCollect( );
	}
}

