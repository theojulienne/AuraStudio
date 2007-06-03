module aura.operations.move;

import std.stdio;

import aura.model;
import aura.operation;
import aura.editing;

import aura.list;

class MoveOperation : Operation
{
	static int DirectionX = 1;
	static int DirectionY = 2;
	static int DirectionZ = 3;
	static int DirectionN = 4;
	
	int dir = 1;
	
	List!(Vertex) verts;
	List!(Vertex) orig_verts;
	
	EditMode emode;
	
	this( int _dir )
	{
		dir = _dir;
	}
	
	bool prepare( Selection sel )
	{
		if ( !Operation.prepare( sel ) )
			return false;
		
		verts = new List!(Vertex);
		
		emode = sel.mode;
		
		if ( emode == EditMode.Vertex )
			verts = sel.sel_verts;
		else if ( emode == EditMode.Edge )
		{
			foreach ( e; sel.sel_edges )
			{
				if ( verts.find( e.va ) == -1 )
					verts.append( e.va );
				if ( verts.find( e.vb ) == -1 )
					verts.append( e.vb );
			}
		}
		else if ( emode == EditMode.Face )
		{
			foreach ( f; sel.sel_faces )
			{
				foreach ( v; f.verts )
				{
					if ( verts.find( v ) == -1 )
						verts.append( v );
				}
			}
		}
		else if ( emode == EditMode.Body )
		{
			foreach ( b; sel.sel_bodies )
			{
				foreach ( f; b.faces )
				{
					foreach ( v; f.verts )
					{
						if ( verts.find( v ) == -1 )
							verts.append( v );
					}
				}
			}
		}
		
		orig_verts = new List!(Vertex);
		foreach ( v; verts )
		{
			orig_verts.append( new Vertex( v ) );
		}
		
		return true;
	}
	
	void update( )
	{
		int a = 0;
		
		foreach ( v; verts )
		{
			Vertex ov = orig_verts[a];
			
			v.setTo( ov );
			
			if ( dir == DirectionX )
			{
				v.x += value;
			}
			else
			if ( dir == DirectionY )
			{
				v.y += value;
			}
			else
			if ( dir == DirectionZ )
			{
				v.z += value;
			}
			else
			if ( dir == DirectionN )
			{
				v.x += 0;//value;
				v.y += 0;//value;
				v.z += 0;//value;
			}
			
			a++;
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
