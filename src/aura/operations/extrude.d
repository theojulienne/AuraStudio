module aura.operations.extrude;

import std.stdio;

import aura.model;
import aura.operation;

class ExtrudeFace
{
	Face face;
	Face[] bridges;
	Vertex orig_verts[];
	
	void copyOriginalVerts( Face f )
	{
		orig_verts.length = f.verts.length;
		
		foreach ( a, v; f.verts )
		{
			orig_verts[a] = new Vertex( v, false );
		}
	}
	
	void createNewFaceFor( Face f )
	{
		copyOriginalVerts( f );
		
		Vertex nverts[];
		
		nverts.length = orig_verts.length;
		
		foreach ( a, v; orig_verts )
		{
			// small + (big - small)
			nverts[a] = new Vertex( f.f_body );
			nverts[a].setTo( v );
		}
		
		face = f.f_body.addFace( orig_verts.length, nverts );
	}
	
	void createBridgesTo( Face f )
	{
		bridges.length = f.verts.length;
		
		for ( int a = 0; a < f.verts.length; a++ )
		{
			int b = a+1;
			
			if ( b == f.verts.length ) b = 0; // wrap to start
			
			bridges[a] = f.f_body.addFace( 4, f.verts[a], f.verts[b], face.verts[b], face.verts[a] );
		}
	}
	
	void update( float value )
	{
		Vertex tmp = new Vertex( null, 0, 0, 0 );
		Normal n = face.calculateNormal( );
		
		value *= 5;
		
		foreach ( a, v; face.verts )
		{
			v.setTo( orig_verts[a] );
			v.x += value * n.x;
			v.y += value * n.y;
			v.z += value * n.z;
		}
	}
}

class ExtrudeOperation : Operation
{
	ExtrudeFace[] ifaces;
	
	bool prepare( Selection sel )
	{
		if ( !Operation.prepare( sel ) )
			return false;
		
		auto faces = sel.getFaces( );
		sel.resetSelection( );
		
		ifaces.length = faces.length;
		
		foreach ( n, f; faces )
		{
			ifaces[n] = new ExtrudeFace;
			
			ifaces[n].createNewFaceFor( f );
			
			ifaces[n].createBridgesTo( f );
			
			sel.select( ifaces[n].face );
			
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
