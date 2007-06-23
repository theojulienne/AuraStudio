module aura.operations.subdivide;

import std.stdio;

import aura.model.all;
import aura.operation;
import aura.editing;
import aura.list;

class SubdivideOperation : Operation
{
	this( )
	{
		
	}
	
	bool prepare( Selection sel )
	{
		if ( !Operation.prepare( sel ) )
			return false;
		
		// convert selection to edges
		sel.mode = EditMode.Edge;
		
		auto edges = sel.getEdges( );
		EdgeList edgesl = new EdgeList;
		edgesl = edges;
		
		sel.resetSelection( );
		
		FaceList fl = new FaceList;
		
		Vertex[Edge] divided_points;
		
		foreach ( e; edges )
		{
			foreach ( f; e.faces )
				fl.appendUnique( f );
			
			Vertex v = new Vertex( e.faces[0].f_body, 0, 0, 0 );
			v.vector = Vector.getAverage( e.va, e.vb );
			divided_points[e] = v;
		}
		
		foreach ( f; fl )
		{
			if ( f.verts.length == 3 )
			{
				throw new Exception( "Theo was lazy here." );
			}
			else if ( f.verts.length == 4 )
			{
				EdgeList selected = new EdgeList;
				VertexList v_selected = new VertexList;
				VertexList unselected = new VertexList;
				
				foreach ( e; f.edges )
				{
					if ( !( e in edgesl ) )
						continue;
					
					v_selected.append( e.va );
					v_selected.append( e.vb );
					
					selected.append( e );
				}
				
				foreach ( v; f.verts )
				{
					if ( v in v_selected )
						continue;
					
					unselected.append( v );
				}
				
				if ( selected.length == 1 )
				{
					Edge e = selected[0];
					
					Vertex va = unselected[0];
					Vertex vb = unselected[1];
					
					Edge ea = Edge.getEdge( null, va, e.va );
					if ( ea is null )
					{
						Vertex vtmp = va;
						va = vb;
						vb = vtmp;
					}
					
					Face nf;
					nf = f.f_body.addFace( 3, divided_points[e], va, e.va );
					nf = f.f_body.addFace( 3, divided_points[e], e.vb, vb );
					nf = f.f_body.addFace( 3, divided_points[e], vb, va );
				}
				else if ( selected.length == 2 )
				{
					Edge ea = selected[0];
					Edge eb = selected[1];
					
					if ( ea.adjacentTo( eb ) )
					{
						// corner
						Vertex corner = ea.getCommonVertex( eb );
						
						Vertex vmid = new Vertex( f.f_body, 0, 0, 0 );
						vmid.vector = Vector.getAverage( divided_points[ea], divided_points[eb] );
						
						Face nf;
						nf = f.f_body.addFace( 3, divided_points[ea], corner, divided_points[eb] );
						nf = f.f_body.addFace( 3, divided_points[ea], vmid, unselected[0], ea.getOther(corner) );
						nf = f.f_body.addFace( 3, divided_points[eb], eb.getOther(corner), unselected[0], vmid );
					}
					else
					{
						// split
						bool flipped = false;
						
						Edge chk = Edge.getEdge( null, ea.va, eb.va );
						flipped = (chk is null);
						
						Face nf;
						
						if ( flipped )
						{
							nf = f.f_body.addFace( 4, ea.va, eb.vb, divided_points[eb], divided_points[ea] );
							nf = f.f_body.addFace( 4, divided_points[ea], divided_points[eb], eb.va, ea.vb );
						}
						else
						{
							nf = f.f_body.addFace( 4, ea.va, eb.va, divided_points[eb], divided_points[ea] );
							nf = f.f_body.addFace( 4, divided_points[ea], divided_points[eb], eb.vb, ea.vb );
						}
					}
				}
				else if ( selected.length == 3 )
				{
					Edge eunsel = null;
					
					foreach ( e; f.edges )
					{
						if ( e in selected )
							continue;
						
						eunsel = e;
					}
					
					// find the middle of the edges
				}
				else if ( selected.length == 4 )
				{
					Vertex v = new Vertex( f.f_body, 0, 0, 0 );
					v.vector = Vector.getAverage( f.verts.get );
					
					Face nf;
					for ( int a = 0; a < f.edges.length; a++ )
					{
						int b = a - 1;
						if ( b < 0 ) b = f.edges.length-1;
						
						Vertex comm = f.edges[a].getCommonVertex( f.edges[b] );
						
						nf = f.f_body.addFace( 4, v, divided_points[f.edges[b]], comm, divided_points[f.edges[a]] );
					}
				}
			}
			else
			{
				throw new Exception( "Can't subdivide smartly on (N>4)gons, implement this!" );
			}
			
			f.f_body.removeFace( f );
		}
		
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
