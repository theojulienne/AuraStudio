module aura.operations.move;

import std.stdio;
import std.math;

import aura.model.all;
import aura.operation;
import aura.editing;

import aura.list;


class MoveGroup
{
	VertexList verts;
	VertexList orig_verts;
	
	Vertex centre;
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
		centre = new Vertex( null, 0, 0, 0 );
		foreach ( v; verts )
		{
			orig_verts.append( new Vertex( v ) );
			
			centre += v;
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
			v1.setToVertex( verts[i] - centre );
			v2.setToVertex( verts[i+1] - centre );
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
			
			// axis to move along
			if ( type == MoveOperation.DirectionX ) 
			{
				tv.x += value;
			} else
			if ( type == MoveOperation.DirectionY ) 
			{
				tv.y += value;
			} else
			if ( type == MoveOperation.DirectionZ ) 
			{
				tv.z += value;
			} else
			if ( type == MoveOperation.DirectionN ) 
			{
				tv.x += value * n.x;
				tv.y += value * n.y;
				tv.z += value * n.z;
				writefln("normal XYZ: %s %s %s", n.x, n.y, n.z);
			}
			
			v.vector = tv;
			
			a++;
		}
	}
}

class MoveGroupList
{
	mixin MixList!(MoveGroup);
}

class MoveOperation : Operation
{
	static int DirectionX = 1;
	static int DirectionY = 2;
	static int DirectionZ = 3;
	static int DirectionN = 4;
	
	int type = 1;
	
	EditMode emode;
	
	MoveGroupList groups;
	
	this( int _type )
	{
		type = _type;
	}
	
	bool prepare( Selection sel )
	{
		if ( !Operation.prepare( sel ) )
			return false;
		
		VertexList verts = new VertexList;
		groups = new MoveGroupList;
		
		emode = sel.mode;
		
		if ( emode == EditMode.Vertex ) {
			verts = sel.sel_verts.l;
			
			while ( verts.length > 0 )
			{
				Vertex v = verts[0];
				verts.remove( v );

				MoveGroup mg = new MoveGroup;
				groups.append( mg );
				mg.verts.append( v );

				mg.type = type;

				void addSelectedAdjacents( Vertex sv )
				{
					foreach ( e; sv.edges )
					{
						if ( e.va in verts )
						{
							mg.verts.append( e.va );
							verts.remove( e.va );
							addSelectedAdjacents( e.va );
						}

						if ( e.vb in verts )
						{
							mg.verts.append( e.vb );
							verts.remove( e.vb );
							addSelectedAdjacents( e.vb );
						}
					}
				}

				addSelectedAdjacents( v );

				mg.generateCenterAndBackup( );
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

			MoveGroup mg = new MoveGroup;
			groups.append( mg );
			mg.verts.append( e.va );
			mg.verts.append( e.vb );

			mg.type = type;

			void addSelectedAdjacentsE( Vertex sv )
			{
				foreach ( e; sv.edges )
				{
					if ( e in edges )
					{
						// if this edge is in the selection list,
						// add it's verts to the group and remove
						// the edge from the selection list
						
						mg.verts.append( e.va );
						mg.verts.append( e.vb );
						edges.remove( e );
						addSelectedAdjacentsE( e.va );
						addSelectedAdjacentsE( e.vb );
					}
				}
			}

			addSelectedAdjacentsE( e.va );
			addSelectedAdjacentsE( e.vb );

			mg.generateCenterAndBackup( );
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
