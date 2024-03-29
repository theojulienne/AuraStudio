module aura.operations.inset;

import std.stdio;

import aura.model.all;
import aura.operation;
import aura.list;

class InsetFace
{
	Face face;
	FaceList bridges;
	VertexList orig_verts;
	Vector center;
	
	this( )
	{
		orig_verts = new VertexList;
		bridges = new FaceList;
	}
	
	void calculateOriginalCenter( Face f )
	{
		center.zero;
		
		foreach ( v; f.verts )
			center += v;
		
		center /= f.verts.length;
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
		Vector tmp;
		
		int a = 0;
		
		foreach ( v; face.verts )
		{
			tmp.zero;
			tmp.set( orig_verts[a] );
			tmp -= center;
			tmp *= value;
			
			v.vector = center + tmp;
			
			a++;
		}
	}
}

class InsetFaceList
{
	mixin MixList!(InsetFace);
}

class InsetOperation : Operation
{
	InsetFaceList ifaces;
	
	bool prepare( Selection sel )
	{
		if ( !Operation.prepare( sel ) )
			return false;
		
		ifaces = new InsetFaceList;
		
		auto faces = sel.getFaces( );
		sel.resetSelection( );
		
		foreach ( n, f; faces )
		{
			InsetFace i;
			
			i = new InsetFace;
			ifaces.append( i );
			
			i.calculateOriginalCenter( f );
			
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
			// inset relative to 100% moving in
			f.update( 1-value );
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
