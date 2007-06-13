module aura.operations.scale;

import std.stdio;

import aura.model.all;
import aura.operation;
import aura.editing;

import aura.list;

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
	
	VertexList verts;
	VertexList orig_verts;
	
	EditMode emode;
	
	this( int _type )
	{
		type = _type;
	}
	
	bool prepare( Selection sel )
	{
		if ( !Operation.prepare( sel ) )
			return false;
		
		verts = new VertexList;
		
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
		
		orig_verts = new VertexList;
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
			
			
			if ( type == scaleX )
			{
				v.x *= value;
			}
			else
			if ( type == scaleY )
			{
				v.y *= value;
			}
			else
			if ( type == scaleZ )
			{
				v.z *= value;
			}
			else
			if ( type == scaleUniform )
			{
				v.x *= value;
				v.y *= value;
				v.z *= value;
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
