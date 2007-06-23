module aura.model.edge;

import aura.list;
import aura.model.vertex;
import aura.model.face;
import aura.model.vector;

import std.stdio;

class EdgeList
{
	mixin MixList!(Edge);
}

class Edge
{
	// an edge can only have 2 Vertex
	Vertex va;
	Vertex vb;
	
	// and can belong to more than 1 Face
	FaceList faces;
	
	bool selected = false;
	bool hot = false;
	
	void cleanReferencesToFace( Face f )
	{
		faces.remove( f );
		
		if ( faces.length == 0 )
		{
			// edge gone
		}
	}
	
	this( Vertex a, Vertex b )
	{
		faces = new FaceList;
		
		va = a;
		vb = b;
		
		va.edges.append( this );
		vb.edges.append( this );
	}
	
	Vertex getOther( Vertex v )
	{
		if ( va == v ) return vb;
		return va;
	}
	
	bool hasFace( Face f )
	{
		return (faces.find(f) > -1);
	}
	
	void addFace( Face f )
	{
		if ( f is null ) return;
		
		faces.appendUnique( f );
	}
	
	bool hasVertex( Vertex v )
	{
		return ( va == v || vb == v );
	}
	
	Vector getCenter( )
	{
		return Vertex.makeCenterOf( va, vb );
	}
	
	Vertex getCommonVertex( Edge b )
	{
		if ( b.hasVertex( va ) )
			return va;
		
		return vb;
	}
	
	bool isReal( )
	{
		return faces.length > 0;
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
