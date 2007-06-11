
import aura.selection;
import aura.editing;
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

import aura.model.all;

import aura.operation;
import aura.operations.inset;
import aura.operations.extrude;
import aura.operations.move;

class AuraWindow : WindowWidget {
	Body model;
	
	OpenGLWidget ogl;
	ButtonWidget set_btn;
	TextBoxWidget tb_r, tb_R, tb_d;
	ComboWidget mode;
	Layout lt;
	
	Selection sel;
	
	this( ) {
		super( null, new Bounds( 100, 50, 1024, 768 ), 0 );
		
		this.title = "Aura Studio";
		
		lt = new Layout( this, "[_clock][{25}status|(150)mode|(20)]", 10, 10 );
		
		Claro.addToLoop( &this.handle_main );
		
		this.add_handler( "destroy", &this.closed );
		
		this.ogl = new OpenGLWidget( this, lt.bounds("clock") );
		this.ogl.redrawDelegate = &this.gl_redraw;
		
		this.make_menu( );
		
		sel = new Selection;
		
		ListItem n, m;
		
		mode = new ComboWidget( this, lt.bounds("mode") );
		n = mode.appendItem( "Body" );
		n.appdata = box(EditMode.Body);
		m = mode.appendItem( "Face" );
		m.appdata = box(EditMode.Face);
		n = mode.appendItem( "Edge" );
		n.appdata = box(EditMode.Edge);
		n = mode.appendItem( "Vertex" );
		n.appdata = box(EditMode.Vertex);
		mode.add_handler( "selected", &this.mode_selected );
		mode.selected = m;
		
		glShadeModel(GL_SMOOTH);							// Enable Smooth Shading
		glClearColor(0.0f, 0.0f, 0.0f, 0.5f);				// Black Background
		glClearDepth(1.0f);									// Depth Buffer Setup
		glEnable(GL_DEPTH_TEST);							// Enables Depth Testing
		glDepthFunc(GL_LEQUAL);								// The Type Of Depth Testing To Do
		glHint(GL_PERSPECTIVE_CORRECTION_HINT, GL_NICEST);	// Really Nice Perspective Calculations
		
		model = new Body;
		
		this.ogl.add_handler( "resized", &this.gl_resized );
		this.ogl.add_handler( "clicked", &this.clicked );
		this.ogl.add_handler( "released", &this.released );
		this.ogl.add_handler( "mouse_moved", &this.mousemoved );
		this.ogl.add_handler( "middle_clicked", &this.middleclicked );
		this.ogl.add_handler( "middle_released", &this.middlereleased );
		this.ogl.add_handler( "scroll_wheel", &this.scrollwheel );
		this.ogl.add_handler( "right_clicked", &this.context );
		this.gl_resized( null, this.ogl );
	}
	
	MenuWidget body_menu, face_menu, edge_menu, verts_menu;
	
	MenuBarWidget mb;
	void make_menu( ) {
		this.mb = new MenuBarWidget( this );
		auto file_menu = this.mb.appendItem( "File" );
		auto file_quit = this.mb.appendItem( file_menu, Stock.getImage("system-log-out", StockSize.Menu), "Quit" );
		this.mb.addKeyBinding( file_quit, "Q", MenuBarWidget.ModifierCommand );
		file_quit.add_handler( "pushed", &this.closed );
		
		
		body_menu = new MenuWidget( this.ogl );
		face_menu = new MenuWidget( this.ogl );
		edge_menu = new MenuWidget( this.ogl );
		verts_menu = new MenuWidget( this.ogl );
		ListItem i, ii;
		
		//i = face_menu.appendItem( "Move" );
		
		ListItem appendTo( MenuWidget menu, ListItem parent, char[] title, Operation op=null )
		{
			ListItem li;
			
			li = menu.appendItem( parent, title );
			
			if ( op !is null )
			{
				li.appdata = box( op );
				li.add_handler( "pushed", &this.runOperation );
			}
			
			return li;
		}
		
		ListItem appendToP( MenuWidget menu, char[] title, Operation op=null )
		{
			return appendTo( menu, null, title, op );
		}
		
		i = appendToP( face_menu, "Move" );
			appendTo( face_menu, i, "*Normal", new MoveOperation(MoveOperation.DirectionN) );
			appendTo( face_menu, i, "X", new MoveOperation(MoveOperation.DirectionX) );
			appendTo( face_menu, i, "Y", new MoveOperation(MoveOperation.DirectionY) );
			appendTo( face_menu, i, "Z", new MoveOperation(MoveOperation.DirectionZ) );
			
		i = appendToP( face_menu, "*Rotate");
			appendTo( face_menu, i, "*Normal");
			appendTo( face_menu, i, "*Free");
			appendTo( face_menu, i, "*X");
			appendTo( face_menu, i, "*Y");
			appendTo( face_menu, i, "*Z");
		
		i = appendToP( face_menu, "*Scale" );
			appendTo( face_menu, i, "*Uniform");
			appendTo( face_menu, i, "*X");
			appendTo( face_menu, i, "*Y");
			appendTo( face_menu, i, "*Z");
			appendTo( face_menu, i, "*Radial X");
			appendTo( face_menu, i, "*Radial Y");
			appendTo( face_menu, i, "*Radial Z");
		
		i = appendToP( face_menu, "Extrude" );
			appendTo( face_menu, i, "Normal", new ExtrudeOperation(ExtrudeOperation.DirectionN) );
			appendTo( face_menu, i, "X", new ExtrudeOperation(ExtrudeOperation.DirectionX) );
			appendTo( face_menu, i, "Y", new ExtrudeOperation(ExtrudeOperation.DirectionY) );
			appendTo( face_menu, i, "Z", new ExtrudeOperation(ExtrudeOperation.DirectionZ) );
		
		appendToP( face_menu, "Inset", new InsetOperation );
		
		i = appendToP( edge_menu, "Move" );
			appendTo( edge_menu, i, "*Normal", new MoveOperation(MoveOperation.DirectionN) );
			appendTo( edge_menu, i, "X", new MoveOperation(MoveOperation.DirectionX) );
			appendTo( edge_menu, i, "Y", new MoveOperation(MoveOperation.DirectionY) );
			appendTo( edge_menu, i, "Z", new MoveOperation(MoveOperation.DirectionZ) );
		
		i = appendToP( verts_menu, "Move" );
			appendTo( verts_menu, i, "*Normal", new MoveOperation(MoveOperation.DirectionN) );
			appendTo( verts_menu, i, "X", new MoveOperation(MoveOperation.DirectionX) );
			appendTo( verts_menu, i, "Y", new MoveOperation(MoveOperation.DirectionY) );
			appendTo( verts_menu, i, "Z", new MoveOperation(MoveOperation.DirectionZ) );
		
		i = appendToP( body_menu, "Move" );
			appendTo( body_menu, i, "*Normal", new MoveOperation(MoveOperation.DirectionN) );
			appendTo( body_menu, i, "X", new MoveOperation(MoveOperation.DirectionX) );
			appendTo( body_menu, i, "Y", new MoveOperation(MoveOperation.DirectionY) );
			appendTo( body_menu, i, "Z", new MoveOperation(MoveOperation.DirectionZ) );
	}
	
	Operation curr_op;
	
	void runOperation( CEvent evt, CObject obj )
	{
		Operation c = unbox!(Operation)(obj.appdata);
		if ( c.prepare( sel ) )
			curr_op = c;
		else
			c.cleanup( );
		//writefln( "%s", classname );
	}
	
	void context( CEvent evt, CObject obj )
	{
		sel.clearHot( );
		if ( edmode == EditMode.Body )
			body_menu.popup( );
		else if ( edmode == EditMode.Face )
			face_menu.popup( );
		else if ( edmode == EditMode.Edge )
			edge_menu.popup( );
		else if ( edmode == EditMode.Vertex )
			verts_menu.popup( );
	}
	
	EditMode edmode;
	void mode_selected( CEvent evt, CObject obj )
	{
		ListItem i = cast(ListItem)evt.getArgumentAsObject("row");
		
		if ( i is null ) return;
		
		edmode = unbox!(EditMode)( i.appdata );
		sel.resetSelection( );
		sel.mode = edmode;
	}
	
	bool middle_tracking;
	int mouse_lastx, mouse_lasty;
	void middleclicked( CEvent evt, CObject obj )
	{
		int x = evt.getArgumentAsInt("x");
		int y = evt.getArgumentAsInt("y");
		
		if ( middle_tracking )
			return;
		
		middle_tracking = true;
		mouse_lastx = x;
		mouse_lasty = y;
	}
	
	void middlereleased( CEvent evt, CObject obj )
	{
		middle_tracking = false;
	}
	
	void scrollwheel( CEvent evt, CObject obj )
	{
		double deltaY = evt.getArgumentAsDouble( "deltaY" );
		double deltaX = evt.getArgumentAsDouble( "deltaX" );
		
		cam.spin_horiz += deltaX;
		cam.dist -= deltaY * 0.25f;
	}
	
	void mousemoved( CEvent evt, CObject obj )
	{
		int x = evt.getArgumentAsInt("x");
		int y = evt.getArgumentAsInt("y");
		
		if ( middle_tracking )
		{
			int a, b;
			
			a = x - mouse_lastx;
			b = y - mouse_lasty;

			mouse_lastx = x;
			mouse_lasty = y;
			
			cam.spin_horiz -= a * 0.5f;
			cam.spin_vert -= b * 0.5f;
			
			return;
		} else if ( curr_op !is null )
		{
			curr_op.updateFromMouse( x, y );
			return;
		}
		
		if ( x < 0 || y < 0 || x > ogl.bounds.width || y > ogl.bounds.height )
			return;
		
		// temporarily disable the GC; otherwise issues happen with the opengl picking
		// and object->int casting.. yes, this is a lazy fix.
		std.gc.disable( );
		
		if ( edmode == EditMode.Face )
		{
			Face f = pickFace( x, y );
			
			if ( is_select_running )
				sel.select( f, false, select_in_path );
			
			sel.makeHot( f );
		}
		
		else if ( edmode == EditMode.Edge )
		{
			Edge e = pickEdge( x, y );
			
			if ( is_select_running )
				sel.select( e, false, select_in_path );
			
			sel.makeHot( e );
		}
		
		else if ( edmode == EditMode.Vertex )
		{
			Vertex v = pickVertex( x, y );
			
			if ( is_select_running )
				sel.select( v, false, select_in_path );
			
			sel.makeHot( v );
		}
		
		else
		{
			Body b = pickBody( x, y );
			
			if ( is_select_running )
				sel.select( b, false, select_in_path );
			
			sel.makeHot( b );
		}
		
		std.gc.enable( );
	}
	
	bool is_select_running = false;
	bool select_in_path = false;
	void released( CEvent evt, CObject obj )
	{
		is_select_running = false;
	}
	void clicked( CEvent evt, CObject obj )
	{
		int x = evt.getArgumentAsInt("x");
		int y = evt.getArgumentAsInt("y");
		
		if ( curr_op !is null )
		{
			curr_op.complete( );
			curr_op.cleanup( );
			curr_op = null;
			mousemoved( evt, obj );
			return;
		}
		
		
		// temporarily disable the GC; otherwise issues happen with the opengl picking
		// and object->int casting.. yes, this is a lazy fix.
		std.gc.disable( );
		if ( edmode == EditMode.Face )
		{
			Face f = pickFace( x, y );
			sel.select( f );
			if ( f !is null ) { select_in_path = f.selected; is_select_running = true; }
		}
		
		else if ( edmode == EditMode.Edge )
		{
			Edge e = pickEdge( x, y );
			if ( e !is null ) { select_in_path = e.selected; is_select_running = true; }
			sel.select( e );
		}
		
		else if ( edmode == EditMode.Vertex )
		{
			Vertex v = pickVertex( x, y );
			sel.select( v );
			if ( v !is null ) { select_in_path = v.selected; is_select_running = true; }
		}
		
		else
		{
			Body b = pickBody( x, y );
			sel.select( b );
			if ( b !is null ) { select_in_path = b.selected; is_select_running = true; }
		}
		std.gc.enable( );
	}
	
	Body pickBody( int x, int y )
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
	
	const int BUFSIZE = 8192;
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
		
		gluPerspective(45,width/height,0.1,10000);
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
	
	Camera cam;
	void render( OpenGLWidget w, int selectMode, Face f = null ) {
		this.ogl.activate( );
		
		if ( cam is null )
		{
			cam = new Camera;
		}
		
		prepareGl( );
		
		glClearColor( 0.8, 0.8, 0.8, 1 );
		glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);	// Clear Screen And Depth Buffer
		/*glLoadIdentity();									// Reset The Current Modelview Matrix
		glTranslatef(0.0f,0.0f,-6.0f);						// Move Left 1.5 Units And Into The Screen 6.0
		glRotatef(rtri,0.0f,1.0f,0.0f);						// Rotate The Triangle On The Y axis ( NEW )*/
		
		cam.setupPosition( );

		if ( selectMode == aSelectNone )
			model.render( edmode );
		else if ( selectMode == aSelectObject || selectMode == aSelectFace )
			model.renderSelect( selectMode );
		else
			model.renderFaceSelect( f, selectMode );

		glDisable( GL_LIGHTING );
		if ( selectMode == aSelectNone )
		{
			glLineWidth( 1 );
			drawGrid( );
			drawDir( );
		}
		
		this.ogl.flip( );
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
	
	GLfloat rtri = 0;
	GLfloat rquad = 0;
	
	// Gets run every claro loop iteration. Every second, redraws canvas.
	void handle_main( CEvent evt, CObject obj ) {
		this.ogl.redraw( );
		
		rtri+=0.2f;											// Increase The Rotation Variable For The Triangle ( NEW )
		rquad-=0.15f;										// Decrease The Rotation Variable For The Quad ( NEW )
		
		std.gc.fullCollect( );
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
