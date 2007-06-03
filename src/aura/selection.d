module aura.selection;

import std.stdio;

import aura.model;

enum
{
	aSelectNone=0,
	aSelectObject,
	aSelectFace,
	aSelectEdge,
	aSelectVertex,
}

class Selection
{
	Vertex v_hot = null;
	Edge e_hot = null;
	Face f_hot = null;
	Body b_hot = null;
	
	Face[] sel_faces;
	Edge[] sel_edges;
	Vertex[] sel_verts;
	Body[] sel_bodies;
	
	void resetSelection( )
	{
		foreach ( f; sel_faces )
			f.selected = false;
		
		foreach ( e; sel_edges )
			e.selected = false;
				
		foreach ( v; sel_verts )
			v.selected = false;
			
		foreach ( b; sel_bodies )
			b.selected = false;
		
		sel_faces = null;
		sel_edges = null;
		sel_verts = null;
		sel_bodies = null;
	}
	
	Face[] getFaces( )
	{
		return sel_faces;
	}
	
	Edge[] getEdges( )
	{
		return sel_edges;
	}
	
	Vertex[] getVerts( )
	{
		return sel_verts;
	}
	
	Body[] getBodies( )
	{
		return sel_bodies;
	}
	
	void clearHot( )
	{
		if ( v_hot )
		{
			v_hot.hot = false;
			v_hot = null;
		}
		
		if ( e_hot )
		{
			e_hot.hot = false;
			e_hot = null;
		}
		
		if ( f_hot )
		{
			f_hot.hot = false;
			f_hot = null;
		}
		
		if ( b_hot )
		{
			b_hot.hot = false;
			b_hot = null;
		}
	}
	
	void makeHot( Face f )
	{
		if ( f_hot !is null )
			f_hot.hot = false;
		
		if ( f is null )
			return;
		
		f_hot = f;
		f_hot.hot = true;
	}
	
	void makeHot( Edge e )
	{
		if ( e_hot !is null )
			e_hot.hot = false;

		if ( e is null )
			return;

		e_hot = e;
		e_hot.hot = true;
	}
	
	void makeHot( Vertex v )
	{
		if ( v_hot !is null )
			v_hot.hot = false;

		if ( v is null )
			return;

		v_hot = v;
		v_hot.hot = true;
	}
	
	void makeHot( Body b )
	{
		if ( b_hot !is null )
			b_hot.hot = false;

		if ( b is null )
			return;

		b_hot = b;
		b_hot.hot = true;
	}
	
	void select( Face f )
	{
		if ( f !is null )
		{
			f.selected = !f.selected;
			
			if ( f.selected )
			{
				int l = sel_faces.length;
				sel_faces.length = l+1;
				sel_faces[l] = f;
			}
			else
			{
				foreach ( a, sf; sel_faces )
				{
					if ( sf == f )
					{
						auto n = sel_faces[0..a];
						auto m = sel_faces[a+1..length];
						sel_faces = n ~ m;
						break;
					}
				}
			}
		}
	}
	
	void select( Edge e )
	{
		if ( e !is null )
		{
			e.selected = !e.selected;
		}
	}
	
	void select( Vertex v )
	{
		if ( v !is null )
		{
			v.selected = !v.selected;
		}
	}
	
	void select( Body b )
	{
		if ( b !is null )
		{
			b.selected = !b.selected;
		}
	}
}
