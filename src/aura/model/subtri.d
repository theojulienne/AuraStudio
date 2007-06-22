module aura.model.subtri;

import aura.list;
import aura.model.vertex;
import aura.model.vector;

class SubTriList
{
	mixin MixList!(SubTri);
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
	
	Vector calculateNormal( )
	{
	 	Vector v1, v2;
		v1.setToVertex( verts[1] );
		v1 -= verts[0];
		v2.setToVertex( verts[2] );
		v2 -= verts[0];
		
		return v1.cross( v2 );
	}
}
