module aura.model;

import aura.selection;
import aura.editing;

private import opengl.gl;
private import std.stdio;

import std.math;

struct Colour
{
	float r, g, b, a;
	
	void set( float _r, float _g, float _b, float _a=1.0f )
	{
		r = _r; g = _g; b = _b; a = _a;
	}
}

struct Normal
{
	float x, y, z;
	
	void normalize( )
	{
		float length;
		
		length = cast(float)sqrt((x*x) + (y*y) + (z*z));

		if(length == 0.0f)						// Prevents Divide By 0 Error By Providing
			length = 1.0f;						// An Acceptable Value For Vectors To Close To 0.

		x /= length;						// Dividing Each Element By
		y /= length;						// The Length Results In A
		z /= length;						// Unit Normal Vector.
	}
	
	int opAssign( Vertex v )
	{
		
		return 0;
	}
	
	void zero( )
	{
		x = y = z = 0;
	}
	
	int opSubAssign( Vertex v )
	{
		x -= v.x;
		y -= v.y;
		z -= v.z;
		
		return 0;
	}
	
	int opAddAssign( Normal n )
	{
		x += n.x;
		y += n.y;
		z += n.z;
		
		return 0;
	}
	
	int opDivAssign( int n )
	{
		x /= n;
		y /= n;
		z /= n;
		
		return 0;
	}
	
	Normal cross( Normal on )
	{
		Normal n;
		
		n.x = y*on.z - z*on.y;				// Cross Product For Y - Z
		n.y = z*on.x - x*on.z;				// Cross Product For X - Z
		n.z = x*on.y - y*on.x;				// Cross Product For X - Y
		
		return n;
	}
	
	void setToVertex( Vertex v )
	{
		x = v.x;
		y = v.y;
		z = v.z;
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
	
	void cleanReferencesToFace( Face f )
	{
		foreach ( a, tf; faces )
		{
			if ( tf != f )
				continue;
			
			auto n = faces[0..a];
			auto m = faces[a+1..length];
			faces = n ~ m;
			break;
		}
		
		if ( faces.length == 0 )
		{
			// edge gone
		}
	}
	
	this() { this(null,0,0,0); }
	
	this( Body _b, float _x=0, float _y=0, float _z=0 )
	{
		p_body = _b;
		x = _x;
		y = _y;
		z = _z;
	}
	
	this( Vertex src, bool copy_refs=false )
	{
		this( null, 0, 0, 0 );
		
		this += src;
		
		if ( copy_refs )
		{
			// copy body and/or faces and/or edges here.. whatever is sane?
		}
	}
	
	void zero( )
	{
		x = y = z = 0.0f;
	}
	
	void deb( )
	{
		writefln( "%s,%s,%s", x, y, z );
	}
	
	int opAddAssign( Vertex o )
	{
		x += o.x;
		y += o.y;
		z += o.z;
		
		return 0;
	}
	
	int opSubAssign( Vertex o )
	{
		x -= o.x;
		y -= o.y;
		z -= o.z;
		
		return 0;
	}
	
	int opDivAssign( float n )
	{
		x /= n;
		y /= n;
		z /= n;
		
		return 0;
	}
	
	int opMulAssign( float n )
	{
		x *= n;
		y *= n;
		z *= n;
		
		return 0;
	}
	
	void setTo( Vertex v )
	{
		x = v.x;
		y = v.y;
		z = v.z;
	}
	
	Vertex opSub( Vertex v )
	{
		Vertex nv = new Vertex( null, 0, 0, 0 );
		
		nv += this;
		nv -= v;
		
		return nv;
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
	
	void cleanReferencesToFace( Face f )
	{
		foreach ( a, tf; faces )
		{
			if ( tf != f )
				continue;
			
			auto n = faces[0..a];
			auto m = faces[a+1..length];
			faces = n ~ m;
			break;
		}
		
		if ( faces.length == 0 )
		{
			// edge gone
		}
	}
	
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
	
	Vertex getOther( Vertex v )
	{
		if ( va == v ) return vb;
		return va;
	}
	
	bool hasFace( Face f )
	{
		foreach ( mf; faces )
		{
			if ( mf == f )
				return true;
		}
		
		return false;
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
	
	Vertex getCenter( )
	{
		return Vertex.makeCenterOf( va, vb );
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
	
	Normal calculateNormal( )
	{
	 	Normal v1, v2;
		v1.setToVertex( verts[1] );
		v1 -= verts[0];
		v2.setToVertex( verts[2] );
		v2 -= verts[0];
		
		return v1.cross( v2 );
	}
}

class Face
{
	Vertex verts[];
	Edge edges[];
	
	SubTri tris[];
	
	Body f_body;
	
	Colour colour;
	
	bool selected = false;
	bool hot = false;
	
	Normal normal;
	
	Normal calculateNormal( )
	{
		normal.zero( );
		
		foreach ( t; tris )
		{
			normal += t.calculateNormal( );
		}
		
		normal /= tris.length;
		
		return normal;
	}
	
	void cleanReferences( )
	{
		foreach ( v; verts )
			v.cleanReferencesToFace( this );
		
		foreach ( e; edges )
			e.cleanReferencesToFace( this );
	}
	
	void rebuildTris( )
	{
		foreach ( t; tris )
		{
			delete t;
		}
		
		tris.length = 0;
		
		// now let's make our subtris
		
		tris.length = verts.length - 2;
		
		//writefln( "Tris calculated: %s", tris.length );
		
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
		foreach ( t; tris )
		{
			Vertex center = new Vertex( null, 0, 0, 0 );
			foreach ( v; t.verts )
				center += v;
			center /= t.verts.length;
			
			Vertex va = t.verts[0];
			Vertex vb = t.verts[1];
			Vertex vc = t.verts[2];
			
			Edge ea = Edge.getEdge( null, va, vb );
			Edge eb = Edge.getEdge( null, vb, vc );
			Edge ec = Edge.getEdge( null, vc, va );
			
			Vertex ca = Vertex.makeCenterOf( va, vb );
			Vertex cb = Vertex.makeCenterOf( vb, vc );
			Vertex cc = Vertex.makeCenterOf( vc, va );
			
			int real_edges = 0;
			
			if ( ea.hasFace(this) )
				real_edges++;
			else
				ea = null;
			
			if ( eb.hasFace(this) )
				real_edges++;
			else
				eb = null;
				
			if ( ec.hasFace(this) )
				real_edges++;
			else
				ec = null;
			
			if ( real_edges == 3 )
			{
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
			
			else if ( real_edges == 2 )
			{
				// move the edges down the stack so the 2 real edges are "ea" and "eb"
				if ( ea is null )
				{
					ea = eb;
					eb = ec;
				}
				else if ( eb is null )
				{
					eb = ec;
				}
				
				// which vertex is shared?
				Vertex shared = ea.va;
				if ( !eb.hasVertex( shared ) ) shared = ea.vb;
				if ( !eb.hasVertex( shared ) ) throw new Exception( "2 edges of a triangle don't share a common vertex!" );
				
				if ( !ea.hasVertex( shared ) || !eb.hasVertex( shared ) )
					throw new Exception( "Something broke :)" );
				
				// find the 2 verts that are unique (not shared by a real edge)
				Vertex ua = ea.getOther( shared );
				Vertex ub = eb.getOther( shared );
				
				if ( ua == shared || ub == shared )
					throw new Exception( "Unique vertex was same as shared vertex" );
				
				// calculate the center of the edge between ua and ub
				Vertex ecenter = Vertex.makeCenterOf( ua, ub );
				
				// calculate the center of each real edges
				Vertex eac = ea.getCenter( );
				Vertex ebc = eb.getCenter( );
				
				glDisable( GL_CULL_FACE );
				
				glPushName( cast(int)shared );
				glBegin( GL_TRIANGLES );
				glColor3f( 1.0f, 0.0f, 0.0f );
				shared.glv; eac.glv; ecenter.glv;
				shared.glv; ebc.glv; ecenter.glv;
				glEnd( );
				glPopName( );
				
				glPushName( cast(int)ua );
				glBegin( GL_TRIANGLES );
				glColor3f( 1.0f, 0.0f, 0.0f );
				ua.glv; eac.glv; ecenter.glv;
				glEnd( );
				glPopName( );
				
				glPushName( cast(int)ub );
				glBegin( GL_TRIANGLES );
				glColor3f( 1.0f, 0.0f, 0.0f );
				ub.glv; ebc.glv; ecenter.glv;
				glEnd( );
				glPopName( );
				
				//writefln( "(%s) %s, %s, %s", real_edges, ea, eb, ec );
			}
			
			else if ( real_edges == 1 )
			{
				throw new Exception( "Encountered a sub-triangle with only 1 real edge. Was triangulation implemented without adding vertex detection code for this case? Oops!" );
			}
		}
		
		/*
		
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
		*/
	}
	
	void renderFaceSelectEdge( )
	{
		foreach ( t; tris )
		{
			Vertex center = new Vertex( null, 0, 0, 0 );
			foreach ( v; t.verts )
				center += v;
			center /= t.verts.length;
			
			Vertex va = t.verts[0];
			Vertex vb = t.verts[1];
			Vertex vc = t.verts[2];
			
			Edge ea = Edge.getEdge( null, va, vb );
			Edge eb = Edge.getEdge( null, vb, vc );
			Edge ec = Edge.getEdge( null, vc, va );
			
			int real_edges = 0;
			
			if ( ea.hasFace(this) )
				real_edges++;
			else
				ea = null;
			
			if ( eb.hasFace(this) )
				real_edges++;
			else
				eb = null;
				
			if ( ec.hasFace(this) )
				real_edges++;
			else
				ec = null;
			
			if ( real_edges == 3 )
			{
				// we have 3 edges that belong to this face.
				// render the tris from the center to the verts
				
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
			
			else if ( real_edges == 2 )
			{
				// move the edges down the stack so the 2 real edges are "ea" and "eb"
				if ( ea is null )
				{
					ea = eb;
					eb = ec;
				}
				else if ( eb is null )
				{
					eb = ec;
				}
				
				// which vertex is shared?
				Vertex shared = ea.va;
				if ( !eb.hasVertex( shared ) ) shared = ea.vb;
				if ( !eb.hasVertex( shared ) ) throw new Exception( "2 edges of a triangle don't share a common vertex!" );
				
				if ( !ea.hasVertex( shared ) || !eb.hasVertex( shared ) )
					throw new Exception( "Something broke :)" );
				
				// find the 2 verts that are unique (not shared by a real edge)
				Vertex ua = ea.getOther( shared );
				Vertex ub = eb.getOther( shared );
				
				if ( ua == shared || ub == shared )
					throw new Exception( "Unique vertex was same as shared vertex" );
				
				// calculate the center of the edge between ua and ub
				Vertex ecenter = Vertex.makeCenterOf( ua, ub );
				
				// got all we need!
				
				glDisable( GL_CULL_FACE );
				
				glPushName( cast(int)ea );
				glBegin( GL_TRIANGLES );
				glColor3f( 1.0f, 0.0f, 0.0f );
				shared.glv; ua.glv; ecenter.glv;
				glEnd( );
				glPopName( );

				glPushName( cast(int)eb );
				glBegin( GL_TRIANGLES );
				glColor3f( 0.0f, 1.0f, 0.0f );
				eb.va.glv; eb.vb.glv; ecenter.glv;
				glEnd( );
				glPopName( );
				
				//writefln( "(%s) %s, %s, %s", real_edges, ea, eb, ec );
			}
			
			else if ( real_edges == 1 )
			{
				throw new Exception( "Encountered a sub-triangle with only 1 real edge. Was triangulation implemented without adding edge detection code for this case? Oops!" );
			}
		}
		
		/*return;
		
		////// OLD //////
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
		glPopName( );*/
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
	
	bool selected = false;
	bool hot = false;
	
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
		fa = addFace( 4, a, b, d, c );
		fa = addFace( 4, f, b, a, e );
		fa = addFace( 4, c, d, h, g );
		fa = addFace( 4, e, g, h, f );
		//fa = addFace( 4, a, e, g, c );
		fa = addFace( 4, b, f, h, d );
		
		fa = addFace( 3, c, i, a );
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
		faces[f].f_body = this;
		
		foreach ( v; fverts )
			faces[f].addVertex( v );
		
		faces[f].computeEdges( );
		/*
		faces[f].verts.length = fverts.length;
		faces[f].verts[0..length] = fverts[0..length];
		*/
		
		return faces[f];
	}
	
	void removeFace( Face f )
	{
		// remove the face from the faces list
		foreach ( a, sf; faces )
		{
			if ( sf == f )
			{
				auto n = faces[0..a];
				auto m = faces[a+1..length];
				faces = n ~ m;
				break;
			}
		}
		
		f.cleanReferences( );
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
			
			render( EditMode.None ); // render as usual
			
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
		glEnable(GL_POLYGON_OFFSET_FILL);
		glPolygonOffset(1.0f, 1.0f);
		
		glBegin( GL_TRIANGLES );
		
		if ( editMode == EditMode.Body )
		{
			float r, g, b;
			
			r = g = b = 0.0f;
			if ( this.hot )
				g = 0.4;
			
			if ( this.selected )
				r = 0.5;
			
			if ( !this.selected && !this.hot )
				r = g = b = 0.5f;
			
			glColor4f( r, g, b, 1.0 );
		}
		
		foreach ( f; faces )
		{
			if ( editMode == EditMode.Face )
			{
				float r, g, b;
				
				r = g = b = 0.0f;
				if ( f.hot )
					g = 0.4;
				
				if ( f.selected )
					r = 0.5;
				
				if ( !f.selected && !f.hot )
					r = g = b = 0.5f;
				
				glColor4f( r, g, b, 1.0 );
			}
			else if ( editMode != EditMode.Body )
				glColor4f( 0.5, 0.5, 0.5, 1 );
			
			foreach ( t; f.tris )
			{
				if ( t.verts[0] is null || t.verts[1] is null || t.verts[2] is null )
					continue; // bandaid to fix strange crashes
				t.verts[0].glv;
				t.verts[1].glv;
				t.verts[2].glv;
			}
		}
		glEnd( );
		
		//glEnable(GL_CULL_FACE);
		glCullFace(GL_BACK);
		glEnable(GL_POLYGON_OFFSET_LINE);
		glPolygonOffset(-1.0f, -1.0f);
		
		glEnable(GL_NORMALIZE);
		foreach ( f; faces )
		{
			foreach ( e; f.edges )
			{
				float r, g, b;
				float w = 1.0f;
				
				r = g = b = 0.0f;
				
				if ( editMode == EditMode.Edge )
				{
					if ( e.hot )
					{
						g = 0.5;
						w = 2.0;
					}
					if ( e.selected )
					{
						r = 0.8;
						w = 2.0;
					}
				}
			
				glColor3f( r, g, b );
				glLineWidth( w );
				
				glBegin( GL_LINES );
				glVertex3f( e.va.x, e.va.y, e.va.z );
				glVertex3f( e.vb.x, e.vb.y, e.vb.z );
				glEnd( );
			}
		}
		
		if ( editMode == EditMode.Vertex )
		{
			glEnable(GL_POLYGON_OFFSET_POINT);
			glPolygonOffset(5.0f, 5.0f);
			
			foreach ( f; faces )
			{
				foreach ( v; f.verts )
				{
					float r, g, b;
					float s = 4.0;
					r = g = b = 0.0f;
					if ( v.hot )
					{
						g = 0.5;
						s = 5;
					}
					if ( v.selected )
					{
						r = 0.8;
						s = 5;
					}
				
					glPointSize( s );

					glBegin( GL_POINTS );
					glColor3f( r, g, b );
					glVertex3f( v.x, v.y, v.z );
					glEnd( );
				}
			}
		}
		
		/*
		foreach ( f; faces )
		{
			// render in face mode, rest done later
			f.renderFaceSelectEdge( );
		}*/
		
		//foreach ( f; faces ) f.renderFaceSelectVertex( );
	}
}
