module aura.operations.scale;

import std.stdio;

import aura.model.all;
import aura.operation;
import aura.editing;

import aura.list;

class ScaleGroup
{
	VertexList verts;
	VertexList orig_verts;
	
	Vector centre;
	
	int type = 1;
	
	this( )
	{
		verts = new VertexList;
	}
	
	void generateCenterAndBackup( )
	{
		orig_verts = new VertexList;
		
		int numVerts = 0;
		centre.set( 0, 0, 0 );// = new Vertex( null, 0, 0, 0 );
		
		foreach ( v; verts )
		{
			orig_verts.append( new Vertex( v ) );
			centre += v.vector;
			numVerts++;
		}
		centre /= numVerts;
	}
	
	void update( float value )
	{
		int a = 0;
		
		// scale relative to 100% moving out
		value = 1+value;
		
		foreach ( v; verts )
		{
			Vertex ov = orig_verts[a];
			Vector tv;
			
			tv.set( ov );
			
			
			if ( type == ScaleOperation.scaleX 
				|| type == ScaleOperation.scaleUniform
				|| type == ScaleOperation.scaleRadialY
				|| type == ScaleOperation.scaleRadialZ )
			{
				tv.x = centre.x + (tv.x - centre.x) * value;
			}
			
			if ( type == ScaleOperation.scaleY 
				|| type == ScaleOperation.scaleUniform
				|| type == ScaleOperation.scaleRadialX
				|| type == ScaleOperation.scaleRadialZ )
			{
				tv.y = centre.y + (tv.y - centre.y) * value;
			}
			
			if ( type == ScaleOperation.scaleZ
				|| type == ScaleOperation.scaleUniform
				|| type == ScaleOperation.scaleRadialX
				|| type == ScaleOperation.scaleRadialY)
			{
				tv.z = centre.z + (tv.z - centre.z) * value;
			}
			
			v.vector = tv;

			a++;
		}
	}
}

class ScaleGroupList
{
	mixin MixList!(ScaleGroup);
}

class ScaleOperation : Operation
{
	static int scaleX = 1;
	static int scaleY = 2;
	static int scaleZ = 3;
	static int scaleUniform = 4;
	static int scaleRadialX = 5;
	static int scaleRadialY = 6;
	static int scaleRadialZ = 7;
	
	int type = 1;
	
	EditMode emode;
	
	ScaleGroupList groups;
	
	this( int _type )
	{
		type = _type;
	}
	
	bool prepare( Selection sel )
	{
		if ( !Operation.prepare( sel ) )
			return false;
		
		VertexList verts = new VertexList;
		groups = new ScaleGroupList;
		
		emode = sel.mode;
		
		if ( emode == EditMode.Vertex ) {
			verts = sel.sel_verts.l;
			
			while ( verts.length > 0 )
			{
				Vertex v = verts[0];
				verts.remove( v );

				ScaleGroup sg = new ScaleGroup;
				groups.append( sg );
				sg.verts.append( v );

				sg.type = type;

				void addSelectedAdjacents( Vertex sv )
				{
					foreach ( e; sv.edges )
					{
						if ( e.va in verts )
						{
							sg.verts.append( e.va );
							verts.remove( e.va );
							addSelectedAdjacents( e.va );
						}

						if ( e.vb in verts )
						{
							sg.verts.append( e.vb );
							verts.remove( e.vb );
							addSelectedAdjacents( e.vb );
						}
					}
				}

				addSelectedAdjacents( v );

				sg.generateCenterAndBackup( );
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

			ScaleGroup sg = new ScaleGroup;
			groups.append( sg );
			sg.verts.append( e.va );
			sg.verts.append( e.vb );

			sg.type = type;

			void addSelectedAdjacentsE( Vertex sv )
			{
				foreach ( e; sv.edges )
				{
					if ( e in edges )
					{
						// if this edge is in the selection list,
						// add it's verts to the group and remove
						// the edge from the selection list
						
						sg.verts.append( e.va );
						sg.verts.append( e.vb );
						edges.remove( e );
						addSelectedAdjacentsE( e.va );
						addSelectedAdjacentsE( e.vb );
					}
				}
			}

			addSelectedAdjacentsE( e.va );
			addSelectedAdjacentsE( e.vb );

			sg.generateCenterAndBackup( );
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
