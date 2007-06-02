module aura.model;

import aura.selection;
import aura.editing;

private import opengl.gl;
private import std.stdio;

struct Colour
{
	float r, g, b, a;
	
	void set( float _r, float _g, float _b, float _a=1.0f )
	{
		r = _r; g = _g; b = _b; a = _a;
	}
}

class Vertex
{
	float x, y, z;
	
	Body p_body;
	
	bool selected = false;
	bool hot = false;
	
	// a Vertex can have many Faces and Edges
	Face faces[];
	Edge edges[];
	
	this() { this(null,0,0,0); }
	
	this( Body _b, float _x, float _y, float _z )
	{
		p_body = _b;
		x = _x;
		y = _y;
		z = _z;
	}
	
	void zero( )
	{
		x = y = z = 0.0f;
	}
	
	int opAddAssign( Vertex o )
	{
		x += o.x;
		y += o.y;
		z += o.z;
		
		return 0;
	}
	
	int opDivAssign( float n )
	{
		x /= n;
		y /= n;
		z /= n;
		
		return 0;
	}
	
	static Vertex makeCenterOf( Vertex a, Vertex b )
	{
		Vertex v = new Vertex( null, 0, 0, 0 );
		
		v.zero( );
		v += a;
		v += b;
		v /= 2;
		
		return v;
	}
	
	void glv()
	{
		glVertex3f( x, y, z );
	}
}

class Edge
{
	// an edge can only have 2 Vertex
	Vertex va;
	Vertex vb;
	
	// and can belong to more than 1 Face
	Object faces[];
	
	bool selected = false;
	bool hot = false;
	
	this( Vertex a, Vertex b )
	{
		va = a;
		vb = b;
		
		int en = va.edges.length;
		va.edges.length = en+1;
		va.edges[en] = this;
		
		en = vb.edges.length;
		vb.edges.length = en+1;
		vb.edges[en] = this;
	}
	
	void addFace( Face f )
	{
		if ( f is null ) return;
		
		int fn = faces.length;
		faces.length = fn+1;
		faces[fn] = f;
	}
	
	bool hasVertex( Vertex v )
	{
		return ( va == v || vb == v );
	}
	
	static Edge getEdge( Face f, Vertex a, Vertex b )
	{
		foreach ( e; a.edges )
		{
			if ( e.hasVertex( b ) )
			{
				e.addFace( f );
				return e;
			}
		}
		
		Edge e = new Edge( a, b );
		e.addFace( f );
		
		return e;
	}
}

class SubTri
{
	Vertex verts[3];
	
	this( Vertex a, Vertex b, Vertex c )
	{
		verts[0] = a;
		verts[1] = b;
		verts[2] = c;
	}
}

class Face
{
	Vertex verts[];
	Edge edges[];
	
	SubTri tris[];
	
	Colour colour;
	
	bool selected = false;
	bool hot = false;
	
	void rebuildTris( )
	{
		foreach ( t; tris )
		{
			delete t;
		}
		
		tris.length = 0;
		
		// now let's make our subtris
		
		tris.length = verts.length - 2;
		
		writefln( "Tris calculated: %s", tris.length );
		
		if ( verts.length < 3 )
		{
			return;
		} else if ( verts.length == 3 )
		{
			// tri already
			tris[0] = new SubTri( verts[0], verts[1], verts[2] );
		}
		else if ( verts.length == 4 )
		{
			// quad
			tris[0] = new SubTri( verts[0], verts[1], verts[2] );
			tris[1] = new SubTri( verts[2], verts[3], verts[0] );
		}
		else
		{
			throw new Exception( "Ear clipping not yet implemented, yet a face with more than 4 verts encountered!");
		}
	}
	
	void addVertex( Vertex v )
	{
		int vl = verts.length;
		
		verts.length = vl+1;
		verts[vl] = v;
	}
	
	void computeEdges( )
	{
		int a;
		
		edges.length = verts.length;
		for ( a = 1; a < verts.length; a++ )
			edges[a-1] = Edge.getEdge( this, verts[a-1], verts[a] );
		
		edges[verts.length-1] = Edge.getEdge( this, verts[verts.length-1], verts[0] );
		
		rebuildTris( );
	}
	
	void renderSelect( int selectMode )
	{
		glDisable(GL_CULL_FACE);
		
		if ( selectMode == aSelectFace )
		{
			glPushName( cast(int)this );
		
			glBegin( GL_TRIANGLES );
			glColor4f( colour.r, colour.g, colour.b, colour.a );
			
			foreach ( t; tris )
			{
				t.verts[0].glv;
				t.verts[1].glv;
				t.verts[2].glv;
			}
			
			glEnd( );
			
			glPopName( );
		}
	}
	
	void renderFaceSelectVertex( )
	{
		Vertex center = new Vertex( null, 0, 0, 0 );
		foreach ( v; verts )
			center += v;
		center /= verts.length;
		
		glDisable(GL_CULL_FACE);
		
		Vertex va = verts[0];
		Vertex vb = verts[1];
		Vertex vc = verts[2];
		
		Vertex ca = Vertex.makeCenterOf( va, vb );
		Vertex cb = Vertex.makeCenterOf( vb, vc );
		Vertex cc = Vertex.makeCenterOf( vc, va );
		
		glPushName( cast(int)va );
		glBegin( GL_TRIANGLES );
		glColor3f( 1.0f, 0.0f, 0.0f );
		va.glv; ca.glv; center.glv;
		glColor3f( 1.0f, 0.5f, 0.0f );
		va.glv; cc.glv; center.glv;
		glEnd( );
		glPopName( );
		
		glPushName( cast(int)vb );
		glBegin( GL_TRIANGLES );
		glColor3f( 0.0f, 1.0f, 0.0f );
		vb.glv; cb.glv; center.glv;
		glColor3f( 0.0f, 1.0f, 0.5f );
		vb.glv; ca.glv; center.glv;
		glEnd( );
		glPopName( );
		
		glPushName( cast(int)vc );
		glBegin( GL_TRIANGLES );
		glColor3f( 0.0f, 0.0f, 1.0f );
		vc.glv; cc.glv; center.glv;
		glColor3f( 0.0f, 0.5f, 1.0f );
		vc.glv; cb.glv; center.glv;
		glEnd( );
		glPopName( );
	}
	
	void renderFaceSelectEdge( )
	{
		Vertex center = new Vertex( null, 0, 0, 0 );
		foreach ( v; verts )
			center += v;
		center /= verts.length;
		
		glDisable(GL_CULL_FACE);
		
		Vertex va = verts[0];
		Vertex vb = verts[1];
		Vertex vc = verts[2];
		
		Edge ea = Edge.getEdge( null, va, vb );
		Edge eb = Edge.getEdge( null, vb, vc );
		Edge ec = Edge.getEdge( null, vc, va );
		
		glPushName( cast(int)ea );
		glBegin( GL_TRIANGLES );
		glColor3f( 1.0f, 0.0f, 0.0f );
		va.glv; vb.glv; center.glv;
		glEnd( );
		glPopName( );
		
		glPushName( cast(int)eb );
		glBegin( GL_TRIANGLES );
		glColor3f( 0.0f, 1.0f, 0.0f );
		vb.glv; vc.glv; center.glv;
		glEnd( );
		glPopName( );
		
		glPushName( cast(int)ec );
		glBegin( GL_TRIANGLES );
		glColor3f( 0.0f, 0.0f, 1.0f );
		vc.glv; va.glv; center.glv;
		glEnd( );
		glPopName( );
	}
	
	void renderFaceSelect( int selectMode )
	{
		if ( selectMode == aSelectVertex ) renderFaceSelectVertex( );
		else if ( selectMode == aSelectEdge ) renderFaceSelectEdge( );
	}
}
/*
glVertex3f( 0.0f, 1.0f, 0.0f);					// Top Of Triangle (Right)
glVertex3f( 1.0f,-1.0f, 1.0f);					// Left Of Triangle (Right)
glVertex3f( 1.0f,-1.0f, -1.0f);					// Right Of Triangle (Right)
glVertex3f( 0.0f, 1.0f, 0.0f);					// Top Of Triangle (Back)
glVertex3f( 1.0f,-1.0f, -1.0f);					// Left Of Triangle (Back)
glVertex3f(-1.0f,-1.0f, -1.0f);					// Right Of Triangle (Back)
glVertex3f( 0.0f, 1.0f, 0.0f);					// Top Of Triangle (Left)
glVertex3f(-1.0f,-1.0f,-1.0f);					// Left Of Triangle (Left)
glVertex3f(-1.0f,-1.0f, 1.0f);					// Right Of Triangle (Left)
*/
class Body
{
	Vertex verts[];
	Face faces[];
	
	this()
	{
		Vertex a, b, c, d, e, f, g, h, i;
		
		a = addVertex(-1.0f,  1.0f,  1.0f ); // front top left
		b = addVertex(-1.0f, -1.0f,  1.0f ); // front bottom left
		c = addVertex( 1.0f,  1.0f,  1.0f ); // front top right
		d = addVertex( 1.0f, -1.0f,  1.0f ); // front bottom right
		
		e = addVertex(-1.0f,  1.0f, -1.0f ); // rear top left
		f = addVertex(-1.0f, -1.0f, -1.0f ); // rear bottom left
		g = addVertex( 1.0f,  1.0f, -1.0f ); // rear top right
		h = addVertex( 1.0f, -1.0f, -1.0f ); // rear bottom right
		
		i = addVertex( 0.0f,  2.0f,  0.0f ); // rear bottom right
		
		Face fa;
		fa = addFace( 4, a, c, d, b );
		fa = addFace( 4, a, b, f, e );
		fa = addFace( 4, c, d, h, g );
		fa = addFace( 4, e, f, h, g );
		//fa = addFace( 4, a, e, g, c );
		fa = addFace( 4, b, f, h, d );
		
		fa = addFace( 3, a, i, c );
		fa = addFace( 3, e, i, g );
		fa = addFace( 3, a, i, e );
		fa = addFace( 3, g, i, c );
		
		/*
		a = addVertex( 0.0f,  1.0f,  0.0f ); // top
		b = addVertex(-1.0f, -1.0f,  1.0f ); // front left
		c = addVertex( 1.0f, -1.0f,  1.0f ); // front right
		d = addVertex( 1.0f, -1.0f, -1.0f ); // rear right
		e = addVertex(-1.0f, -1.0f, -1.0f ); // rear left
		
		Face f;
		f = addFace( 3, a, b, c );
		f.colour.set( 0.0f, 1.0f, 0.0f, 1.0f );
		f = addFace( 3, a, c, d );
		f.colour.set( 0.0f, 1.0f, 0.0f, 1.0f );
		f = addFace( 3, a, d, e );
		f.colour.set( 0.0f, 1.0f, 0.0f, 1.0f );
		f = addFace( 3, a, e, b );
		f.colour.set( 0.0f, 1.0f, 0.0f, 1.0f );
		*/
	}
	
	Vertex addVertex( float x, float y, float z )
	{
		int v = verts.length;
		
		verts.length = v+1;
		verts[v] = new Vertex( this, x, y, z );
		/*verts[v].x = x;
		verts[v].y = y;
		verts[v].z = z;*/
		
		return verts[v];
	}
	
	Face addFace( int num_verts, Vertex[] fverts ... )
	{
		int f = faces.length;
		
		faces.length = f+1;
		faces[f] = new Face;
		
		foreach ( v; fverts )
			faces[f].addVertex( v );
		
		faces[f].computeEdges( );
		/*
		faces[f].verts.length = fverts.length;
		faces[f].verts[0..length] = fverts[0..length];
		*/
		
		return faces[f];
	}
	
	// renders a single face, with all transformations, and
	// passes on the selectMode choice.
	void renderFaceSelect( Face f, int selectMode )
	{
		f.renderFaceSelect( selectMode );
	}
	
	// renders all faces of the object, either with object
	// naming or with face naming.
	void renderSelect( int selectMode )
	{
		if ( selectMode == aSelectObject )
		{
			glPushName( cast(int)this );
			
			render( aEditNone ); // render as usual
			
			glPopName( );
		}
		else
		{
			foreach ( f; faces )
			{
				// render in face mode, rest done later
				f.renderSelect( aSelectFace );
			}
		}
	}
	
	void render( int editMode )
	{
		glBegin( GL_TRIANGLES );
		foreach ( f; faces )
		{
			if ( editMode == aEditFace )
			{
				float r, g, b;
				float w = 1.0f;
				
				r = g = b = 0.0f;
				if ( f.hot )
				{
					g = 0.4;
					w = 3.0;
				}
				
				if ( f.selected )
				{
					r = 0.5;
					w = 3.0;
				}
				
				if ( !f.selected && !f.hot )
					r = g = b = 0.5f;
				
				glColor4f( r, g, b, 1.0 );
			}
			else
				glColor4f( f.colour.r, f.colour.g, f.colour.b, f.colour.a );
			
			foreach ( t; f.tris )
			{
				t.verts[0].glv;
				t.verts[1].glv;
				t.verts[2].glv;
			}
		}
		glEnd( );
		
		//glEnable(GL_CULL_FACE);
		glCullFace(GL_BACK);
		
		glEnable(GL_NORMALIZE);
		foreach ( f; faces )
		{
			foreach ( e; f.edges )
			{
				float r, g, b;
				float w = 1.0f;
				
				r = g = b = 0.0f;
				if ( e.hot )
				{
					g = 0.5;
					w = 3.0;
				}
				if ( e.selected )
				{
					r = 0.8;
					w = 3.0;
				}
			
				glColor3f( r, g, b );
				glLineWidth( w );
				
				glBegin( GL_LINES );
				glVertex3f( e.va.x, e.va.y, e.va.z );
				glVertex3f( e.vb.x, e.vb.y, e.vb.z );
				glEnd( );
			}
		}
		
		if ( editMode == aEditVertex )
		{
			glPointSize(4.0);
		
			glBegin( GL_POINTS );
			foreach ( f; faces )
			{
				foreach ( v; f.verts )
				{
					float r, g, b;
					r = g = b = 0.0f;
					if ( v.hot )
						g = 0.5;
					if ( v.selected )
						r = 0.8;
				
					glColor3f( r, g, b );
				
					glVertex3f( v.x, v.y, v.z );
				}
			}
			glEnd( );
		}
		
		//renderSelect( aEditFace );
		
		//foreach ( f; faces ) f.renderFaceSelectVertex( );
	}
}
