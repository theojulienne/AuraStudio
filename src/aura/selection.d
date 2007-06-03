module aura.selection;

import std.stdio;

import aura.model;
import aura.editing;
import aura.list;

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
	
	EditMode mode;
	
	List!(Face) sel_faces;
	List!(Edge) sel_edges;
	List!(Vertex) sel_verts;
	List!(Body) sel_bodies;
	
	this( )
	{
		sel_faces = new List!(Face);
		sel_edges = new List!(Edge);
		sel_verts = new List!(Vertex);
		sel_bodies = new List!(Body);
	}
	
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
		
		sel_faces = new List!(Face);
		sel_edges = new List!(Edge);
		sel_verts = new List!(Vertex);
		sel_bodies = new List!(Body);
	}
	
	Face[] getFaces( )
	{
		return sel_faces.get;
	}
	
	Edge[] getEdges( )
	{
		return sel_edges.get;
	}
	
	Vertex[] getVerts( )
	{
		return sel_verts.get;
	}
	
	Body[] getBodies( )
	{
		return sel_bodies.get;
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
				sel_faces.append( f );
			else
				sel_faces.remove( f );
		}
	}
	
	void select( Edge e )
	{
		if ( e !is null )
		{
			e.selected = !e.selected;
			
			if ( e.selected )
				sel_edges.append( e );
			else
				sel_edges.remove( e );
		}
	}
	
	void select( Vertex v )
	{
		if ( v !is null )
		{
			v.selected = !v.selected;
			
			if ( v.selected )
				sel_verts.append( v );
			else
				sel_verts.remove( v );
		}
	}
	
	void select( Body b )
	{
		if ( b !is null )
		{
			b.selected = !b.selected;
			
			if ( b.selected )
				sel_bodies.append( b );
			else
				sel_bodies.remove( b );
		}
	}
}
