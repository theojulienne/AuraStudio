module aura.operations.bridge;

import std.stdio;

import aura.model.all;
import aura.operation;
import aura.list;


class BridgeOperation : Operation
{
	Face f1;
	Face f2;
	FaceList bridges;
	
	this ( )
	{
		bridges = new FaceList;
	}
	
	// intelligentify me
	void createBridge( Face f1, Face f2 )
	{
		for ( int a = 0; a < f1.verts.length; a++ )
		{
			int b = a+1;
			
			if ( b == f1.verts.length ) b = 0; // wrap to start
			
			bridges.append( f1.f_body.addFace( 4, f1.verts[a], f1.verts[b], f2.verts[b], f2.verts[a] ) );
		}
	}
	
	bool prepare( Selection sel )
	{
		if ( !Operation.prepare( sel ) )
			return false;
		
		auto faces = sel.getFaces( );
		
		// need two faces
		if ( faces.length != 2 ) return false;
		
		f1 = faces[0];
		f2 = faces[1];
		
		sel.resetSelection( );
		
		createBridge( f1, f2 );
		f1.f_body.removeFace( f1 );
		f2.f_body.removeFace( f2 );
		
		return false;
	}
	
	void update( )
	{

	}
	
	void complete( )
	{
		
	}
	
	void cleanup( )
	{
		Operation.cleanup( );
	}
}
