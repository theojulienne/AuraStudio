module aura.modeller;

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
import aura.operations.subdivide;
import aura.operations.extrude;
import aura.operations.move;
import aura.operations.smooth;
import aura.operations.scale;
import aura.operations.rotate;
import aura.operations.bridge;

import aura.window;

class AuraModellerWindow : AuraWindow {
	Body model;
	
	ButtonWidget set_btn;
	TextBoxWidget tb_r, tb_R, tb_d;
	ComboWidget mode;
	
	Selection sel;
	
	ListItem mode_body, mode_face, mode_edge, mode_vertex;
	
	this( ) {
		super( "Modeller", "[_scene][{25}status|(150)mode|(20)]" );
		
		this.make_menu( );
		
		sel = new Selection;
		sel.window_selection = true;
		
		mode = new ComboWidget( this, lt.bounds("mode") );
		mode_body = mode.appendItem( "Body" );
		mode_body.appdata = box(EditMode.Body);
		mode_face = mode.appendItem( "Face" );
		mode_face.appdata = box(EditMode.Face);
		mode_edge = mode.appendItem( "Edge" );
		mode_edge.appdata = box(EditMode.Edge);
		mode_vertex = mode.appendItem( "Vertex" );
		mode_vertex.appdata = box(EditMode.Vertex);
		mode.add_handler( "selected", &this.mode_selected );
		mode.selected = mode_face;
		
		model = new Body;
		
		this.ogl.add_handler( "clicked", &this.clicked );
		this.ogl.add_handler( "released", &this.released );
		this.ogl.add_handler( "right_clicked", &this.context );
		this.ogl.add_handler( "key_down", &this.key_down );
		this.ogl.add_handler( "key_up", &this.key_up );
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
			appendTo( face_menu, i, "Normal?", new MoveOperation(MoveOperation.DirectionN) );
			appendTo( face_menu, i, "X", new MoveOperation(MoveOperation.DirectionX) );
			appendTo( face_menu, i, "Y", new MoveOperation(MoveOperation.DirectionY) );
			appendTo( face_menu, i, "Z", new MoveOperation(MoveOperation.DirectionZ) );
			
		i = appendToP( face_menu, "Rotate");
			appendTo( face_menu, i, "Normal?",  new RotateOperation(RotateOperation.axisN) );
			appendTo( face_menu, i, "X", new RotateOperation(RotateOperation.axisX) );
			appendTo( face_menu, i, "Y", new RotateOperation(RotateOperation.axisY) );
			appendTo( face_menu, i, "Z", new RotateOperation(RotateOperation.axisZ) );
		
		i = appendToP( face_menu, "Scale" );
			appendTo( face_menu, i, "Uniform", new ScaleOperation(ScaleOperation.scaleUniform) );
			appendTo( face_menu, i, "X", new ScaleOperation(ScaleOperation.scaleX) );
			appendTo( face_menu, i, "Y", new ScaleOperation(ScaleOperation.scaleY) );
			appendTo( face_menu, i, "Z", new ScaleOperation(ScaleOperation.scaleZ) );
			appendTo( face_menu, i, "Radial X", new ScaleOperation(ScaleOperation.scaleRadialX) );
			appendTo( face_menu, i, "Radial Y", new ScaleOperation(ScaleOperation.scaleRadialY) );
			appendTo( face_menu, i, "Radial Z", new ScaleOperation(ScaleOperation.scaleRadialZ) );
		
		i = appendToP( face_menu, "Extrude" );
			appendTo( face_menu, i, "Normal", new ExtrudeOperation(ExtrudeOperation.DirectionN) );
			appendTo( face_menu, i, "X", new ExtrudeOperation(ExtrudeOperation.DirectionX) );
			appendTo( face_menu, i, "Y", new ExtrudeOperation(ExtrudeOperation.DirectionY) );
			appendTo( face_menu, i, "Z", new ExtrudeOperation(ExtrudeOperation.DirectionZ) );
		
		appendToP( face_menu, "Subdivide", new SubdivideOperation );
		appendToP( face_menu, "Inset", new InsetOperation );
		appendToP( face_menu, "Smooth", new SmoothOperation );
		appendToP( face_menu, "*Bridge", new BridgeOperation );
		
		i = appendToP( edge_menu, "Move" );
			appendTo( edge_menu, i, "Normal?", new MoveOperation(MoveOperation.DirectionN) );
			appendTo( edge_menu, i, "X", new MoveOperation(MoveOperation.DirectionX) );
			appendTo( edge_menu, i, "Y", new MoveOperation(MoveOperation.DirectionY) );
			appendTo( edge_menu, i, "Z", new MoveOperation(MoveOperation.DirectionZ) );
			
		i = appendToP( edge_menu, "Rotate");
			appendTo( edge_menu, i, "Normal?", new RotateOperation(RotateOperation.axisN) );
			appendTo( edge_menu, i, "X", new RotateOperation(RotateOperation.axisX) );
			appendTo( edge_menu, i, "Y", new RotateOperation(RotateOperation.axisY) );
			appendTo( edge_menu, i, "Z", new RotateOperation(RotateOperation.axisZ) );
				
		i = appendToP( edge_menu, "Scale" );
			appendTo( edge_menu, i, "Uniform", new ScaleOperation(ScaleOperation.scaleUniform) );
			appendTo( edge_menu, i, "X", new ScaleOperation(ScaleOperation.scaleX) );
			appendTo( edge_menu, i, "Y", new ScaleOperation(ScaleOperation.scaleY) );
			appendTo( edge_menu, i, "Z", new ScaleOperation(ScaleOperation.scaleZ) );
			appendTo( edge_menu, i, "Radial X", new ScaleOperation(ScaleOperation.scaleRadialX) );
			appendTo( edge_menu, i, "Radial Y", new ScaleOperation(ScaleOperation.scaleRadialY) );
			appendTo( edge_menu, i, "Radial Z", new ScaleOperation(ScaleOperation.scaleRadialZ) );
		
		appendToP( edge_menu, "Subdivide", new SubdivideOperation );
		
		i = appendToP( verts_menu, "Move" );
			appendTo( verts_menu, i, "Normal?", new MoveOperation(MoveOperation.DirectionN) );
			appendTo( verts_menu, i, "X", new MoveOperation(MoveOperation.DirectionX) );
			appendTo( verts_menu, i, "Y", new MoveOperation(MoveOperation.DirectionY) );
			appendTo( verts_menu, i, "Z", new MoveOperation(MoveOperation.DirectionZ) );

		i = appendToP( verts_menu, "Rotate");
			appendTo( verts_menu, i, "Normal?",  new RotateOperation(RotateOperation.axisN) );
			appendTo( verts_menu, i, "X", new RotateOperation(RotateOperation.axisX) );
			appendTo( verts_menu, i, "Y", new RotateOperation(RotateOperation.axisY) );
			appendTo( verts_menu, i, "Z", new RotateOperation(RotateOperation.axisZ) );
			
		i = appendToP( verts_menu, "Scale" );
			appendTo( verts_menu, i, "Uniform", new ScaleOperation(ScaleOperation.scaleUniform) );
			appendTo( verts_menu, i, "X", new ScaleOperation(ScaleOperation.scaleX) );
			appendTo( verts_menu, i, "Y", new ScaleOperation(ScaleOperation.scaleY) );
			appendTo( verts_menu, i, "Z", new ScaleOperation(ScaleOperation.scaleZ) );
			appendTo( verts_menu, i, "Radial X", new ScaleOperation(ScaleOperation.scaleRadialX) );
			appendTo( verts_menu, i, "Radial Y", new ScaleOperation(ScaleOperation.scaleRadialY) );
			appendTo( verts_menu, i, "Radial Z", new ScaleOperation(ScaleOperation.scaleRadialZ) );
		
		appendToP( verts_menu, "Subdivide", new SubdivideOperation );
		
		i = appendToP( body_menu, "Move" );
			appendTo( body_menu, i, "X", new MoveOperation(MoveOperation.DirectionX) );
			appendTo( body_menu, i, "Y", new MoveOperation(MoveOperation.DirectionY) );
			appendTo( body_menu, i, "Z", new MoveOperation(MoveOperation.DirectionZ) );

		i = appendToP( body_menu, "Rotate");
			appendTo( body_menu, i, "X", new RotateOperation(RotateOperation.axisX) );
			appendTo( body_menu, i, "Y", new RotateOperation(RotateOperation.axisY) );
			appendTo( body_menu, i, "Z", new RotateOperation(RotateOperation.axisZ) );
			
		i = appendToP( body_menu, "Scale" );
			appendTo( body_menu, i, "Uniform", new ScaleOperation(ScaleOperation.scaleUniform) );
			appendTo( body_menu, i, "X", new ScaleOperation(ScaleOperation.scaleX) );
			appendTo( body_menu, i, "Y", new ScaleOperation(ScaleOperation.scaleY) );
			appendTo( body_menu, i, "Z", new ScaleOperation(ScaleOperation.scaleZ) );
			appendTo( body_menu, i, "Radial X", new ScaleOperation(ScaleOperation.scaleRadialX) );
			appendTo( body_menu, i, "Radial Y", new ScaleOperation(ScaleOperation.scaleRadialY) );
			appendTo( body_menu, i, "Radial Z", new ScaleOperation(ScaleOperation.scaleRadialZ) );		
		
		appendToP( body_menu, "Subdivide", new SubdivideOperation );
		appendToP( body_menu, "*Smooth" );
	}
	
	Operation curr_op;
	
	void key_down( CEvent evt, CObject obj )
	{
		int key = evt.getArgumentAsInt("key");
		int modifiers = evt.getArgumentAsInt("modifiers");
		writefln( "DN: %s (%s)", key, modifiers );
	}
	
	void key_up( CEvent evt, CObject obj )
	{
		int key = evt.getArgumentAsInt("key");
		int modifiers = evt.getArgumentAsInt("modifiers");
		writefln( "UP: %s (%s)", key, modifiers );
		
		if ( key == ' ' )
		{
			sel.resetSelection( );
		}
		
		else if ( key == 's' ) {
			if ( edmode == EditMode.Body || edmode == EditMode.Face )
			{
				SmoothOperation s = new SmoothOperation;
				s.prepare( sel );
				s.cleanup( );
			}
		}
		
		else if ( key == '+' || key == '=' ) {
			sel.grow( );
		}
		
		else if ( key == '-' ) {
			sel.shrink( );
		}
		
		else if ( key == 'i' ) {
			sel.selectSimilar( );
		}
		
		else if ( key == 'b' )
			mode.selected = mode_body;
		else if ( key == 'e' )
			mode.selected = mode_edge;
		else if ( key == 'f' )
			mode.selected = mode_face;
		else if ( key == 'v' )
			mode.selected = mode_vertex;
	}
	
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
		if ( curr_op !is null )
			clicked( evt, obj );
		
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
		//sel.resetSelection( );
		sel.mode = edmode;
	}
	
	void mouse_moved( CEvent evt, CObject obj )
	{
		int x = evt.getArgumentAsInt("x");
		int y = evt.getArgumentAsInt("y");
		
		if ( curr_op !is null )
		{
			curr_op.updateFromMouse( evt.getArgumentAsInt("deltaX"), evt.getArgumentAsInt("deltaY") );
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
}
