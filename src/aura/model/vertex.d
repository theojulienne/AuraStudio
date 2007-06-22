module aura.model.vertex;

import aura.list;
import aura.model.mbody;
import aura.model.face;
import aura.model.edge;
import aura.model.vector;

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
	Vector vector;
	
	Body p_body;
	
	bool selected = false;
	bool hot = false;
	
	// a Vertex can have many Faces and Edges
	FaceList faces;
	EdgeList edges;
	
	void cleanReferencesToFace( Face f )
	{
		faces.remove( f );
		
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
		
		vector.set( _x, _y, _z );
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
	
	// these functions allow writing to the vector class as if the contents were here
	float x( float _x ) { return vector.x = _x; }
	float y( float _y ) { return vector.y = _y; }
	float z( float _z ) { return vector.z = _z; }
	
	void zero( )
	{
		x = y = z = 0.0f;
	}
	
	void deb( )
	{
		writefln( "%s,%s,%s", vector.x, vector.y, vector.z );
	}
	
	int opAddAssign( Vertex o ) { vector += o; return 0; }
	int opSubAssign( Vertex o ) { vector -= o; return 0; }
	
	int opDivAssign( float n ) { vector /= n; return 0; }
	int opMulAssign( float n ) { vector *= n; return 0; }
	
	Vertex opMul( float a )
	{
		Vertex v = new Vertex( null, 0, 0, 0 );
		
		v += this;
		
		v *= a;
		
		writefln( "WARNING: Using an arithmetic operation on the Vertex class, code should be updated to use Vector!" );
		
		return v;
	}
	
	Vertex opAdd( Vertex vt )
	{
		Vertex v = new Vertex( null, 0, 0, 0 );
		
		v += this;
		
		v += vt;
		
		writefln( "WARNING: Using an arithmetic operation on the Vertex class, code should be updated to use Vector!" );
		
		return v;
	}
	
	Vertex opDiv( float a )
	{
		Vertex v = new Vertex( null, 0, 0, 0 );
		
		v += this;
		
		v /= a;
		
		writefln( "WARNING: Using an arithmetic operation on the Vertex class, code should be updated to use Vector!" );
		
		return v;
	}
	
	void setTo( Vertex v )
	{
		vector.set( v );
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
		glVertex3f( vector.x, vector.y, vector.z );
	}
}
