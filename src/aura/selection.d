module aura.selection;

import std.stdio;

import aura.model.edge;
import aura.model.face;
import aura.model.mbody;
import aura.model.vector;
import aura.model.subtri;
import aura.model.vertex;

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
	// defines whether this is the selection for the window.
	// if this is false, it's just a group of whatever's and
	// won't actually change any props of the objects
	// (this means slower lookups because .selected wont work)
	// only 1 Selection instance can have this set true.
	bool window_selection = false;
	
	Vertex v_hot = null;
	Edge e_hot = null;
	Face f_hot = null;
	Body b_hot = null;
	
	EditMode _mode;
	
	FaceList sel_faces;
	EdgeList sel_edges;
	VertexList sel_verts;
	BodyList sel_bodies;
	
	EditMode mode( )
	{
		return _mode;
	}
	
	void mode( EditMode _m )
	{
		changeModes( _mode, _m );
		_mode = _m;
	}
	
	void changeModes( EditMode from, EditMode to )
	{
		if ( from == to )
			return;
		
		if ( to == EditMode.Body )
		{
			// Body
			resetBodySelection( );
			
			if ( from == EditMode.Face )
			{
				foreach ( f; sel_faces )
					select( f.f_body, false, true );
			}
			else if ( from == EditMode.Edge )
			{
				foreach ( e; sel_edges )
					select( e.va.p_body, false, true );
			}
			else if ( from == EditMode.Vertex )
			{
				foreach( v; sel_verts )
					select( v.p_body, false, true );
			}
			
			resetFaceSelection( );
			resetEdgeSelection( );
			resetVertSelection( );
		}
		else if ( to == EditMode.Face )
		{
			// Face
			resetFaceSelection( );
			
			if ( from == EditMode.Body )
			{
				foreach ( b; sel_bodies )
				{
					foreach ( f; b.faces )
						select( f, false, true );
				}
			}
			else if ( from == EditMode.Edge )
			{
				foreach ( e; sel_edges )
				{
					foreach ( f; e.faces )
						select( f, false, true );
				}
			}
			else if ( from == EditMode.Vertex )
			{
				foreach( v; sel_verts )
				{
					foreach ( f; v.faces )
						select( f, false, true );
				}
			}
			
			resetBodySelection( );
			resetEdgeSelection( );
			resetVertSelection( );
		}
		else if ( to == EditMode.Edge )
		{
			// Edge
			resetEdgeSelection( );
			
			if ( from == EditMode.Body )
			{
				foreach ( b; sel_bodies )
				{
					foreach ( f; b.faces )
					{
						foreach ( e; f.edges )
							select( e, false, true );
					}
				}
			}
			else if ( from == EditMode.Face )
			{
				foreach ( f; sel_faces )
				{
					foreach ( e; f.edges )
						select( e, false, true );
				}
			}
			else if ( from == EditMode.Vertex )
			{
				foreach( v; sel_verts )
				{
					foreach ( e; v.edges )
						select( e, false, true );
				}
			}
			
			resetBodySelection( );
			resetFaceSelection( );
			resetVertSelection( );
		}
		else if ( to == EditMode.Vertex )
		{
			// Vertex
			resetVertSelection( );
			
			if ( from == EditMode.Body )
			{
				foreach ( b; sel_bodies )
				{
					foreach ( v; b.verts )
						select( v, false, true );
				}
			}
			else if ( from == EditMode.Face )
			{
				foreach ( f; sel_faces )
				{
					foreach ( v; f.verts )
						select( v, false, true );
				}
			}
			else if ( from == EditMode.Edge )
			{
				foreach( e; sel_edges )
				{
					select( e.va, false, true );
					select( e.vb, false, true );
				}
			}
			
			resetBodySelection( );
			resetFaceSelection( );
			resetEdgeSelection( );
		}
	}
	
	this( )
	{
		sel_faces = new FaceList;
		sel_edges = new EdgeList;
		sel_verts = new VertexList;
		sel_bodies = new BodyList;
	}
	
	void resetFaceSelection( )
	{
		if ( window_selection )
		{
			foreach ( f; sel_faces )
				f.selected = false;
		}
		
		sel_faces = new FaceList;
	}
	
	void resetEdgeSelection( )
	{
		if ( window_selection )
		{
			foreach ( e; sel_edges )
				e.selected = false;
		}
		
		sel_edges = new EdgeList;
	}
	
	void resetVertSelection( )
	{
		if ( window_selection )
		{
			foreach ( v; sel_verts )
				v.selected = false;
		}
		
		sel_verts = new VertexList;
	}
	
	void resetBodySelection( )
	{
		if ( window_selection )
		{
			foreach ( b; sel_bodies )
				b.selected = false;
		}
		
		sel_bodies = new BodyList;
	}
	
	void resetSelection( )
	{
		resetBodySelection( );
		resetFaceSelection( );
		resetEdgeSelection( );
		resetVertSelection( );
	}
	
	void grow( )
	{
		if ( mode == EditMode.Face )
		{
			// Construct a temporary list of faces that are neighbors
			// to currently selected faces (otherwise we may end up
			// selecting every single face)
			
			FaceList fl = new FaceList;
			
			foreach ( f; sel_faces )
			{
				foreach ( e; f.edges )
				{
					foreach ( nf; e.faces )
					{
						fl.appendUnique( nf );
					}
				}
			}
			
			foreach ( f; fl )
			{
				select( f, false, true );
			}
		}
		else if ( mode == EditMode.Edge )
		{
			EdgeList el = new EdgeList;
			
			foreach ( e; sel_edges )
			{
				void appendEdgesOfVert( Vertex v )
				{
					foreach ( ve; v.edges )
					{
						el.append( ve );
					}
				}
				
				appendEdgesOfVert( e.va );
				appendEdgesOfVert( e.vb );
			}
			
			foreach ( e; el )
			{
				if ( !e.isReal )
					continue;
				
				select( e, false, true );
			}
		}
		else if ( mode == EditMode.Vertex )
		{
			VertexList vl = new VertexList;
			
			foreach ( v; sel_verts )
			{
				foreach ( e; v.edges )
				{
					if ( !e.isReal )
						continue;
					
					vl.append( e.va );
					vl.append( e.vb );
				}
			}
			
			foreach ( v; vl )
			{
				select( v, false, true );
			}
		}
	}				
	
	void shrink( )
	{
		if ( mode == EditMode.Face )
		{
			FaceList fl = new FaceList;
			
			foreach ( f; sel_faces )
			{
				bool neighbor_selected = true;
				
				foreach ( e; f.edges )
				{
					foreach ( nf; e.faces )
					{
						if ( !nf.selected )
							neighbor_selected = false;
					}
				}
				
				if ( !neighbor_selected )
					fl.append( f );
			}
			
			foreach ( f; fl )
			{
				select( f, false, false );
			}
		}
		else if ( mode == EditMode.Edge )
		{
			EdgeList el = new EdgeList;
			
			foreach ( e; sel_edges )
			{
				bool neighbor_selected = true;
				
				void appendEdgesOfVert( Vertex v )
				{
					foreach ( ve; v.edges )
					{
						if ( !ve.isReal )
							continue;
						
						if ( !ve.selected )
							neighbor_selected = false;
					}
				}
				
				appendEdgesOfVert( e.va );
				appendEdgesOfVert( e.vb );
				
				if ( !neighbor_selected )
					el.append( e );
			}
			
			foreach ( e; el )
			{
				select( e, false, false );
			}
		}
		else if ( mode == EditMode.Vertex )
		{
			VertexList vl = new VertexList;
			
			foreach ( v; sel_verts )
			{
				foreach ( e; v.edges )
				{
					if ( !e.isReal )
						continue;
					
					if ( !e.va.selected || !e.vb.selected )
						vl.append( v );
				}
			}
			
			foreach ( v; vl )
			{
				select( v, false, false );
			}
		}
	}
	
	void selectSimilar( )
	{
		// implement me		
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
		if ( !window_selection )
			return;
		
		if ( f_hot !is null )
			f_hot.hot = false;
		
		if ( f is null )
			return;
		
		f_hot = f;
		f_hot.hot = true;
	}
	
	void makeHot( Edge e )
	{
		if ( !window_selection )
			return;
		
		if ( e_hot !is null )
			e_hot.hot = false;

		if ( e is null )
			return;

		e_hot = e;
		e_hot.hot = true;
	}
	
	void makeHot( Vertex v )
	{
		if ( !window_selection )
			return;
		
		if ( v_hot !is null )
			v_hot.hot = false;

		if ( v is null )
			return;

		v_hot = v;
		v_hot.hot = true;
	}
	
	void makeHot( Body b )
	{
		if ( !window_selection )
			return;
		
		if ( b_hot !is null )
			b_hot.hot = false;

		if ( b is null )
			return;

		b_hot = b;
		b_hot.hot = true;
	}
	
	void select( Face f, bool toggle=true, bool set=false )
	{
		if ( !window_selection )
		{
			bool sel = toggle ? !(f in sel_faces) : set;
			
			if ( sel )
				sel_faces.appendUnique( f );
			else
				sel_faces.remove( f );
			
			return;
		}
		
		if ( f !is null )
		{
			f.selected = !f.selected;
			
			if ( !toggle ) f.selected = set;
			
			if ( f.selected )
				sel_faces.appendUnique( f );
			else
				sel_faces.remove( f );
		}
	}
	
	void select( Edge e, bool toggle=true, bool set=false )
	{
		if ( !window_selection )
		{
			bool sel = toggle ? !(e in sel_edges) : set;
			
			if ( sel )
				sel_edges.appendUnique( e );
			else
				sel_edges.remove( e );
			
			return;
		}
		
		if ( e !is null )
		{
			e.selected = !e.selected;
			
			if ( !toggle ) e.selected = set;
			
			if ( e.selected )
				sel_edges.appendUnique( e );
			else
				sel_edges.remove( e );
		}
	}
	
	void select( Vertex v, bool toggle=true, bool set=false )
	{
		if ( !window_selection )
		{
			bool sel = toggle ? !(v in sel_verts) : set;
			
			if ( sel )
				sel_verts.appendUnique( v );
			else
				sel_verts.remove( v );
			
			return;
		}
		
		if ( v !is null )
		{
			v.selected = !v.selected;
			
			if ( !toggle ) v.selected = set;
			
			if ( v.selected )
				sel_verts.appendUnique( v );
			else
				sel_verts.remove( v );
		}
	}
	
	void select( Body b, bool toggle=true, bool set=false )
	{
		if ( !window_selection )
		{
			bool sel = toggle ? !(b in sel_bodies) : set;
			
			if ( sel )
				sel_bodies.appendUnique( b );
			else
				sel_bodies.remove( b );
			
			return;
		}
		
		if ( b !is null )
		{
			b.selected = !b.selected;
			
			if ( !toggle ) b.selected = set;
			
			if ( b.selected )
				sel_bodies.appendUnique( b );
			else
				sel_bodies.remove( b );
		}
	}
}
