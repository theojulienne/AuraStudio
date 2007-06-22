module aura.operations.extrude;

import std.stdio;

import aura.model.all;
import aura.operation;
import aura.list;

class ExtrudeFace
{
	Face face;
	FaceList bridges;
	VertexList orig_verts;
	
	int dir;
	
	this( int _dir )
	{
		dir = _dir;
		orig_verts = new VertexList;
		bridges = new FaceList;
	}
	
	void copyOriginalVerts( Face f )
	{
		foreach ( v; f.verts )
		{
			orig_verts.append( new Vertex( v, false ) );
		}
	}
	
	void createNewFaceFor( Face f )
	{
		copyOriginalVerts( f );
		
		VertexList nverts = new VertexList;
		
		foreach ( v; orig_verts )
		{
			// small + (big - small)
			Vertex vn = new Vertex( f.f_body );
			vn.setTo( v );
			
			nverts.append( vn );
		}
		
		face = f.f_body.addFace( orig_verts.length, nverts.get );
	}
	
	void createBridgesTo( Face f )
	{
		for ( int a = 0; a < f.verts.length; a++ )
		{
			int b = a+1;
			
			if ( b == f.verts.length ) b = 0; // wrap to start
			
			bridges.append( f.f_body.addFace( 4, f.verts[a], f.verts[b], face.verts[b], face.verts[a] ) );
		}
	}
	
	void update( float value )
	{
		Vertex tmp = new Vertex( null, 0, 0, 0 );
		Vector n = face.calculateNormal( );
		
		value *= 2;
		
		int a = 0;
		
		foreach ( v; face.verts )
		{
			Vector tv;
			
			tv.set( orig_verts[a] );
			
			if ( dir == ExtrudeOperation.DirectionX )
			{
				tv.x += value;
			}
			else
			if ( dir == ExtrudeOperation.DirectionY )
			{
				tv.y += value;
			}
			else
			if ( dir == ExtrudeOperation.DirectionZ )
			{
				tv.z += value;
			}
			else
			if ( dir == ExtrudeOperation.DirectionN )
			{
				tv.x += value * n.x;
				tv.y += value * n.y;
				tv.z += value * n.z;
			}
			
			v.vector = tv;
			
			a++;
		}
	}
}

class ExtrudeFaceList
{
	mixin MixList!(ExtrudeFace);
}


class ExtrudeOperation : Operation
{
	static int DirectionX = 1;
	static int DirectionY = 2;
	static int DirectionZ = 3;
	static int DirectionN = 4;
	
	int dir = 1;
	
	ExtrudeFaceList ifaces;
	
	this( int _dir )
	{
		dir = _dir;
	}
	
	bool prepare( Selection sel )
	{
		if ( !Operation.prepare( sel ) )
			return false;
		
		ifaces = new ExtrudeFaceList;
		
		auto faces = sel.getFaces( );
		sel.resetSelection( );
		
		foreach ( n, f; faces )
		{
			ExtrudeFace i;
			
			i = new ExtrudeFace( dir );
			ifaces.append( i );
			
			i.createNewFaceFor( f );
			
			i.createBridgesTo( f );
			
			sel.select( i.face );
			
			f.f_body.removeFace( f );
		}
		
		return true;
	}
	
	void update( )
	{
		foreach ( f; ifaces )
		{
			f.update( value );
		}
	}
	
	void complete( )
	{
		
	}
	
	void cleanup( )
	{
		Operation.cleanup( );
	}
}
