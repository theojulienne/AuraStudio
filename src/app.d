
import aura.selection;
import aura.editing;

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

import aura.model;

class AuraWindow : WindowWidget {
	Body model;
	
	OpenGLWidget ogl;
	ButtonWidget set_btn;
	TextBoxWidget tb_r, tb_R, tb_d;
	Layout lt;
	this( ) {
		super( null, new Bounds( 0, 0, 640, 480 ), 0 );
		
		this.title = "Aura Studio";
		
		lt = new Layout( this, "[][_<|clock|<][]", 10, 10 );
		
		Claro.addToLoop( &this.handle_main );
		
		this.add_handler( "destroy", &this.closed );
		
		this.make_menu( );
		
		this.ogl = new OpenGLWidget( this, lt.bounds("clock") );
		this.ogl.redrawDelegate = &this.gl_redraw;
		
		glShadeModel(GL_SMOOTH);							// Enable Smooth Shading
		glClearColor(0.0f, 0.0f, 0.0f, 0.5f);				// Black Background
		glClearDepth(1.0f);									// Depth Buffer Setup
		glEnable(GL_DEPTH_TEST);							// Enables Depth Testing
		glDepthFunc(GL_LEQUAL);								// The Type Of Depth Testing To Do
		glHint(GL_PERSPECTIVE_CORRECTION_HINT, GL_NICEST);	// Really Nice Perspective Calculations
		
		model = new Body;
		
		this.ogl.add_handler( "resized", &this.gl_resized );
		this.ogl.add_handler( "clicked", &this.clicked );
		this.ogl.add_handler( "mouse_moved", &this.mousemoved );
		this.gl_resized( null, this.ogl );
	}
	
	MenuBarWidget mb;
	void make_menu( ) {
		this.mb = new MenuBarWidget( this );
		auto file_menu = this.mb.appendItem( "File" );
		auto file_quit = this.mb.appendItem( file_menu, Stock.getImage("system-log-out", StockSize.Menu), "Quit" );
		this.mb.addKeyBinding( file_quit, "Q", MenuBarWidget.ModifierCommand );
		file_quit.add_handler( "pushed", &this.closed );
	}
	
	Vertex v_hot = null;
	Edge e_hot = null;
	Face f_hot = null;
	Body b_hot = null;
	void mousemoved( CEvent evt, CObject obj )
	{
		int x = evt.getArgumentAsInt("x");
		int y = evt.getArgumentAsInt("y");
		
		if ( x < 0 || y < 0 || x > ogl.bounds.width || y > ogl.bounds.height )
			return;
		
		Face f = pickFace( x, y );
		
		if ( f_hot !is null )
			f_hot.hot = false;
			
		if ( f is null )
			return;
			
		f_hot = f;
		f_hot.hot = true;
	
		/*
		Edge e = pickEdge( x, y );
		
		if ( e_hot !is null )
			e_hot.hot = false;
		
		if ( e is null )
			return;
		
		e_hot = e;
		e_hot.hot = true;
		*/
		
		/*
		Vertex v = pickVertex( x, y );
		
		if ( v_hot !is null )
			v_hot.hot = false;
		
		if ( v is null )
			return;
		
		v_hot = v;
		v_hot.hot = true;
		*/
	}
	
	void clicked( CEvent evt, CObject obj )
	{
		int x = evt.getArgumentAsInt("x");
		int y = evt.getArgumentAsInt("y");
		
		Face f = pickFace( x, y );
		if ( f !is null )
		{
			f.selected = !f.selected;
		}
		
		/*
		Edge e = pickEdge( x, y );
		if ( e !is null )
		{
			e.selected = !e.selected;
		}
		*/
		
		/*Vertex v = pickVertex( x, y );
		if ( v !is null )
		{
			v.selected = !v.selected;
		}*/
		//writefln( "%s", v );
	}
	
	Body pickObject( int x, int y )
	{
		Object o;
		
		startPicking( x, y );
		this.render( this.ogl, aSelectObject );
		o = endPicking( );
		
		return cast(Body)o;
	}
	
	Face pickFace( int x, int y )
	{
		Object o;
		
		startPicking( x, y );
		this.render( this.ogl, aSelectFace );
		o = endPicking( );
		
		return cast(Face)o;
	}
	
	Edge pickEdge( int x, int y )
	{
		Face f;
		Edge e;
		
		startPicking( x, y );
		this.render( this.ogl, aSelectFace );
		f = cast(Face)endPicking( );
		
		if ( f is null )
			return null;
		
		startPicking( x, y );
		this.render( this.ogl, aSelectEdge, f );
		e = cast(Edge)endPicking( );
		
		return e;
	}
	
	Vertex pickVertex( int x, int y )
	{
		Face f;
		Vertex v;
		
		startPicking( x, y );
		this.render( this.ogl, aSelectFace );
		f = cast(Face)endPicking( );
		
		if ( f is null )
			return null;
		
		startPicking( x, y );
		this.render( this.ogl, aSelectVertex, f );
		v = cast(Vertex)endPicking( );
		
		return v;
	}
	
	const int BUFSIZE = 512;
	GLuint selectBuf[BUFSIZE];
	
	void startPicking( int cursorX, int cursorY )
	{
		GLint viewport[4];
		
		glSelectBuffer(BUFSIZE,selectBuf.ptr);
		glRenderMode(GL_SELECT);
		
		glMatrixMode(GL_PROJECTION);
		glPushMatrix();
		glLoadIdentity();
		
		float width = ogl.bounds.width;
		float height = ogl.bounds.height;
		
		if ( height == 0 ) height = 1;
		
		glGetIntegerv( GL_VIEWPORT, viewport.ptr );
		gluPickMatrix( cursorX, viewport[3]-cursorY, 5, 5, viewport.ptr );
		
		gluPerspective(45,width/height,0.1,1000);
		glMatrixMode(GL_MODELVIEW);
		glInitNames();
	}
	
	Object endPicking( )
	{
		int hits;
		
		// restoring the original projection matrix
		glMatrixMode(GL_PROJECTION);
		glPopMatrix();
		glMatrixMode(GL_MODELVIEW);
		glFlush();
		
		// returning to normal rendering mode
		hits = glRenderMode(GL_RENDER);
		
		// if there are hits process them
		if (hits == 0)
			return null;
		
		uint i, j;
		GLuint names, minZ, numberOfNames;
		GLuint *ptr, ptrNames;
	
		//writefln ("hits = %s", hits);
		ptr = cast(GLuint *) selectBuf;
		minZ = 0xffffffff;
		for (i = 0; i < hits; i++) {	
			names = *ptr;
			ptr++;
			if (*ptr < minZ) {
				numberOfNames = names;
				minZ = *ptr;
				ptrNames = ptr+2;
			}
			ptr += names+2;
		}
		
		if ( numberOfNames == 0 )
			return null;
		
		ptr = ptrNames;
		return cast(Object)*ptr;
	}
	
	void gl_redraw( OpenGLWidget w ) {
		render( w, aSelectNone );
	}
	
	void render( OpenGLWidget w, int selectMode, Face f = null ) {
		this.ogl.activate( );
		
		glClearColor( 0.8, 0.8, 0.8, 1 );
		glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);	// Clear Screen And Depth Buffer
		glLoadIdentity();									// Reset The Current Modelview Matrix
		glTranslatef(0.0f,0.0f,-6.0f);						// Move Left 1.5 Units And Into The Screen 6.0
		glRotatef(rtri,0.0f,1.0f,0.0f);						// Rotate The Triangle On The Y axis ( NEW )
		
		if ( selectMode == aSelectNone )
			model.render( aEditFace );
		else if ( selectMode == aSelectObject || selectMode == aSelectFace )
			model.renderSelect( selectMode );
		else
			model.renderFaceSelect( f, selectMode );
		
		this.ogl.flip( );
	}
	
	void gl_resized( CEvent evt, CObject obj ) {
		int width = ogl.bounds.width;
		int height = ogl.bounds.height;
		
		if ( height == 0 ) height = 1;
		
		glViewport( 0, 0, width, height );

		glMatrixMode(GL_PROJECTION);
		glLoadIdentity();
		
		gluPerspective(45.0f,cast(float)width/cast(float)height,0.1f,100.0f);

		glMatrixMode(GL_MODELVIEW);
		glLoadIdentity();
	}
	
	void closed( CEvent evt, CObject obj ) {
		Claro.shutdown( );
	}
	
	GLfloat rtri = 0;
	GLfloat rquad = 0;
	
	// Gets run every claro loop iteration. Every second, redraws canvas.
	void handle_main( CEvent evt, CObject obj ) {
		this.ogl.redraw( );
		
		rtri+=0.2f;											// Increase The Rotation Variable For The Triangle ( NEW )
		rquad-=0.15f;										// Decrease The Rotation Variable For The Quad ( NEW )
	}
}

void main( ) {
	Claro.init();
	Claro.Graphics.init();
	
	auto w = new AuraWindow( );
	
	w.show( );
	w.focus( );

	Claro.loop();
}
