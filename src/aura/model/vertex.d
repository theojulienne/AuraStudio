module aura.model.vertex;

import aura.list;
import aura.model.mbody;
import aura.model.face;
import aura.model.edge;

import opengl.gl;
import std.stdio;

//alias List!(Vertex) VertexList;

class VertexList
{
	mixin MixList!(Vertex);
}

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
	FaceList faces;
	EdgeList edges;
	
	void cleanReferencesToFace( Face f )
	{
		faces.remove( f );
		/*
		foreach ( a, tf; faces )
		{
			if ( tf != f )
				continue;
			
			auto n = faces[0..a];
			auto m = faces[a+1..length];
			faces = n ~ m;
			break;
		}*/
		
		if ( faces.length == 0 )
		{
			// edge gone
		}
	}
	
	void prepare( )
	{
		faces = new FaceList;
		edges = new EdgeList;
	}
	
	this() { this(null,0,0,0); }
	
	this( Body _b, float _x=0, float _y=0, float _z=0 )
	{
		prepare( );
		
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
	
	Vertex opMul( float a )
	{
		Vertex v = new Vertex( null, 0, 0, 0 );
		
		v += this;
		
		v.x *= a;
		v.y *= a;
		v.z *= a;
		
		return v;
	}
	
	Vertex opAdd( Vertex vt )
	{
		Vertex v = new Vertex( null, 0, 0, 0 );
		
		v += this;
		
		v += vt;
		
		return v;
	}
	
	Vertex opDiv( float a )
	{
		Vertex v = new Vertex( null, 0, 0, 0 );
		
		v += this;
		
		v /= a;
		
		return v;
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
