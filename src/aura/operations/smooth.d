module aura.operations.smooth;

import std.stdio;

import aura.model.all;
import aura.operation;
import aura.list;

struct edge_points
{
	Edge e;
	Vertex v;
}

struct VFMap
{
	Face f;
	Vertex v;
}

class ABMap(A,B)
{
	A[] as;
	B[] bs;
	
	void opIndexAssign( B b, A a )
	{
		int an, bn;
		
		an = as.length;
		bn = bs.length;
		
		as.length = an+1;
		bs.length = bn+1;
		
		as[an] = a;
		bs[bn] = b;
	}
	
	B opIndex( A a )
	{
		return opIn_r( a );
	}
	
	B opIn_r( A a )
	{
		foreach ( n, ta; as )
		{
			if ( ta == a )
				return bs[n];
		}
		
		return null;
	}
	
	int length( )
	{
		return as.length;
	}
}

class SmoothOperation : Operation
{
	Body b;
	
	Vertex[Edge] edge_points;
	Vertex[Face] face_points;
	VertexList edge_points_l;
	/*ABMap!(Edge,Vertex) edge_points;
	ABMap!(Face,Vertex) vfmap;*/
	
	this( )
	{
		edge_points_l = new VertexList;
	}
	
	Vertex addFacePoint( Face f )
	{
		Vertex v = new Vertex( b, 0, 0, 0 );
		
		v.vector = Vector.getAverage( f.verts.get );
		
		return v;
	}
	
	// Set each edge point to be the average of all neighbouring face points and original points.
	Vertex addEdgePoint( Edge e )
	{
		int n = 2;
		
		Vertex vb = new Vertex( b, 0, 0, 0 );
		
		//  and original points
		/*vb += e.va;
		vb += e.vb;*/
		
		Vector vs[];
		int vn = 0;
		
		vs.length = 2 + e.faces.length;
		
		// original points
		vs[0] = e.va.vector;
		vs[1] = e.vb.vector;
		vn = 2;
		
		//  of all neighbouring face points
		foreach ( f; e.faces )
		{
			if ( !( f in face_points ) )
				continue;
			
			vs[vn] = face_points[f].vector;
			vn++;
		}
		
		// if this edge has only 1 selected face (as opposed to 2),
		// we don't need to translate the edge point closer to the
		// face point.
		if ( vn == 3 )
			vn = 2;
		
		vs.length = vn;
		
		vb.vector = Vector.getAverage( vs );
		
		edge_points[e] = vb;
		edge_points_l.append( vb );
		
		return vb;
	}
	
	Vertex getEdgePoint( Edge e )
	{
		if ( !( e in edge_points ) )
			return addEdgePoint( e );
		
		return edge_points[e];
	}
	
	bool prepare( Selection sel )
	{
		if ( !Operation.prepare( sel ) )
			return false;
		
		//edge_points = new ABMap!( Edge, Vertex );
		//vfmap = new ABMap!( Face, Vertex );
		
		auto faces = sel.getFaces( );
		sel.resetSelection( );
		
		if ( faces.length == 0 )
			return false;
		
		VertexList original_points = new VertexList;
		
		b = faces[0].f_body;
		
		//ABMap!( Edge, Vertex ) midpoints = new ABMap!( Edge, Vertex );
		Vector[Edge] midpoints;
		
		// The face points are positioned as the average of the positions of the face's original vertices;
		foreach ( n, f; faces )
		{
			Vertex vc = addFacePoint( f );
			face_points[f] = vc;
			
			// collect midpoints for all edges that may be used
			foreach ( v; f.verts )
			{
				foreach ( e; v.edges )
				{
					if ( e in midpoints )
						continue;

					midpoints[e] = Vector.getAverage( e.va, e.vb );
				}
			}
		}
		
		// The edge point locations are calculated as the average of the center point of the original edge 
		// and the average of the locations of the two new adjacent face points;
		foreach ( n, f; faces )
		{
			Vertex vc = face_points[f];
			VertexList vl = new VertexList;
			
			for ( int en = 0; en < f.edges.length; en++ )
			{
				int et = en-1;
				
				if ( et < 0 )
					et = f.edges.length-1;
				
				Vertex vt = getEdgePoint( f.edges[en] );
				Vertex vp = getEdgePoint( f.edges[et] );
				
				Vertex vo = f.edges[en].getCommonVertex( f.edges[et] );
				
				Face nf = b.addFace( 4, vc, vp, vo, vt );
				sel.select( nf );
				
				original_points.appendUnique( vo );
			}
		}
		
		foreach ( P; original_points )
		{
			Vector F;
			
			int a = 0;
			
			foreach ( vf; P.faces )
			{
				if ( !( vf in face_points ) )
				{
					continue;
				}
				
				F += face_points[vf];
				
				a++;
			}
			
			F /= a;

			Vector R;
			int b = 0;
			writefln( "%s edges for P", P.edges.length );
			foreach ( ve; P.edges )
			{
				Vertex other = ve.getOther( P );
				
				// if it's an edge to an edge point, add the midpoint
				if ( other in edge_points_l )
				{
					R += Vector.getAverage( ve.va, ve.vb );
					b++;
					continue;
				}
				
				// if it's an edge to an unselected original point,
				// add our position so we don't move towards it
				if ( !( other in original_points ) )
				{
					R += P.vector;
					b++;
					continue;
				}
				
				// otherwise, it's an edge to an original point that
				// is also selected, so add the precalculated midpoint
				R += midpoints[ve];
				b++;
			}
			writefln( "%s real edges for P", b );
			R /= b;
			
			float n = b;
			
			Vector PC = (F + (R*2) + ((n-3) * P.vector)) / n;
			
			//writefln( "XYZ: %f %f %f", PC.x, PC.y, PC.z );
			P.vector = PC;
		}
		
		foreach ( n, f; faces )
		{
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
