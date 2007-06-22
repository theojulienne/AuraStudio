module aura.operations.rotate;

import std.stdio;
import std.math;

import aura.model.all;
import aura.operation;
import aura.editing;

import aura.list;


class RotateGroup
{
	VertexList verts;
	VertexList orig_verts;
	
	Vector centre;
	Vector n;
	
	int type = 1;
	
	this( )
	{
		verts = new VertexList;
	}
	
	void generateCenterAndBackup( )
	{
		orig_verts = new VertexList;

		// calculate centre
		int numVerts = 0;
		centre.set( 0, 0, 0 );// = new Vertex( null, 0, 0, 0 );
		foreach ( v; verts )
		{
			orig_verts.append( new Vertex( v ) );
			
			centre += v.vector;
			numVerts++;
		}
		centre /= numVerts;
		
		// calculate normal? using the Dave-method
		// better to calculate face/vertex normals properly
		Vector v1;
		Vector v2;
		n.setToVertex( new Vertex( null, 0, 0, 0 ) );
		for( int i = 0; i < verts.length; i+=2)
		{
			v1.set( verts[i].vector - centre );
			v2.set( verts[i+1].vector - centre );
			n += v1.cross( v2 );
		}
		n.normalize( );
		
	}
	
	void update( float value )
	{
		int a = 0;
		
		foreach ( v; verts )
		{
			Vertex ov = orig_verts[a];
			Vector tv;
			
			tv.set( ov );
			
			Vector p;
			p.set( 0, 0, 0 );
			
			// translate to origin
			p = v.vector - centre;
			
			// axis to rotate around
			float X = 0, Y = 0, Z = 0;
			if ( type == RotateOperation.axisX ) 
			{
				X = 1;
			} else
			if ( type == RotateOperation.axisY ) 
			{
				Y = 1;
			} else
			if ( type == RotateOperation.axisZ ) 
			{
				Z = 1;
			} else
			if ( type == RotateOperation.axisN ) 
			{
				X = n.x;
				Y = n.y;
				Z = n.z;
				writefln("normal XYZ: %s %s %s", n.x, n.y, n.z);
			}
			
			float c = cos(value);
			float t = (1 - c);
			float s = sin(value);
			
			// rotation matrix
			float m11 = t * X*X + c;
			float m12 = t * X*Y - s*Z;
			float m13 = t * X*Z + s*Y;
			
			float m21 = t * Y*X + s*Z;
			float m22 = t * Y*Y + c;
			float m23 = t * Y*Z - s*X;
			
			float m31 = t * Z*X - s*Y;
			float m32 = t * Z*Y + s*X;
			float m33 = t * Z*Z + c;
			
			// matrix * point
		    v.vector.x = m11 * p.x + m12 * p.y + m13 * p.z;
		    v.vector.y = m21 * p.x + m22 * p.y + m23 * p.z;
		    v.vector.z = m31 * p.x + m32 * p.y + m33 * p.z;

			// translate back
			v.vector += centre;
			
			a++;
		}
	}
}

class RotateGroupList
{
	mixin MixList!(RotateGroup);
}

class RotateOperation : Operation
{
	static int axisX = 1;
	static int axisY = 2;
	static int axisZ = 3;
	static int axisN = 4;

	
	int type = 1;
	
	EditMode emode;
	
	RotateGroupList groups;
	
	this( int _type )
	{
		type = _type;
	}
	
	bool prepare( Selection sel )
	{
		if ( !Operation.prepare( sel ) )
			return false;
		
		VertexList verts = new VertexList;
		groups = new RotateGroupList;
		
		emode = sel.mode;
		
		if ( emode == EditMode.Vertex ) {
			verts = sel.sel_verts.l;
			
			while ( verts.length > 0 )
			{
				Vertex v = verts[0];
				verts.remove( v );

				RotateGroup rg = new RotateGroup;
				groups.append( rg );
				rg.verts.append( v );

				rg.type = type;

				void addSelectedAdjacents( Vertex sv )
				{
					foreach ( e; sv.edges )
					{
						if ( e.va in verts )
						{
							rg.verts.append( e.va );
							verts.remove( e.va );
							addSelectedAdjacents( e.va );
						}

						if ( e.vb in verts )
						{
							rg.verts.append( e.vb );
							verts.remove( e.vb );
							addSelectedAdjacents( e.vb );
						}
					}
				}

				addSelectedAdjacents( v );

				rg.generateCenterAndBackup( );
			}
			
			return true;
		}
		
		EdgeList edges = new EdgeList;
		
		if ( emode == EditMode.Edge )
		{
			edges = sel.sel_edges.l;
		}
		else if ( emode == EditMode.Face )
		{
			foreach ( f; sel.sel_faces )
			{
				foreach ( e; f.edges )
				{
					edges.append( e );
				}
			}
		}
		else if ( emode == EditMode.Body )
		{
			foreach ( b; sel.sel_bodies )
			{
				foreach ( f; b.faces )
				{
					foreach ( e; f.edges )
					{
						edges.append( e );
					}
				}
			}
		}
		
		while ( edges.length > 0 )
		{
			Edge e = edges[0];
			edges.remove( e );

			RotateGroup rg = new RotateGroup;
			groups.append( rg );
			rg.verts.append( e.va );
			rg.verts.append( e.vb );

			rg.type = type;

			void addSelectedAdjacentsE( Vertex sv )
			{
				foreach ( e; sv.edges )
				{
					if ( e in edges )
					{
						// if this edge is in the selection list,
						// add it's verts to the group and remove
						// the edge from the selection list
						
						rg.verts.append( e.va );
						rg.verts.append( e.vb );
						edges.remove( e );
						addSelectedAdjacentsE( e.va );
						addSelectedAdjacentsE( e.vb );
					}
				}
			}

			addSelectedAdjacentsE( e.va );
			addSelectedAdjacentsE( e.vb );

			rg.generateCenterAndBackup( );
		}
		
		return true;
	}
	
	void update( )
	{
		foreach ( g; groups )
		{
			g.update( value );
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
