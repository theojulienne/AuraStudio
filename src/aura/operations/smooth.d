module aura.operations.smooth;

import std.stdio;

import aura.model.all;
import aura.operation;
import aura.list;

struct VEMap
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
	
	/*Vertex[Edge] vemap;
	Vertex[Face] vfmap;*/
	ABMap!(Edge,Vertex) vemap;
	ABMap!(Face,Vertex) vfmap;
	
	this( )
	{
	}
	
	Vertex add_face_vert( Face f )
	{
		Vertex v = new Vertex( b, 0, 0, 0 );
		
		foreach ( fv; f.verts )
		{
			v += fv;
		}
		
		v /= f.verts.length;
		
		return v;
	}
	
	// Set each edge point to be the average of all neighbouring face points and original points.
	Vertex add_edge_vert( Edge e )
	{
		int n = 2;
		
		Vertex vb = new Vertex( b, 0, 0, 0 );
		
		//  and original points
		vb += e.va;
		vb += e.vb;
		
		//  of all neighbouring face points
		foreach ( f; e.faces )
		{
			if ( !( f in vfmap ) )
				continue;
			
			vb += vfmap[f];
			n++;
		}
		
		vb /= n;
		
		vemap[e] = vb;
		
		return vb;
	}
	
	Vertex get_vert_for_edge( Edge e )
	{
		if ( !( e in vemap ) )
			return add_edge_vert( e );
		
		return vemap[e];
	}
	
	bool prepare( Selection sel )
	{
		if ( !Operation.prepare( sel ) )
			return false;
		
		vemap = new ABMap!( Edge, Vertex );
		vfmap = new ABMap!( Face, Vertex );
		
		auto faces = sel.getFaces( );
		sel.resetSelection( );
		
		VertexList ops = new VertexList;
		
		b = faces[0].f_body;
		
		ABMap!( Edge, Vertex ) midpoints = new ABMap!( Edge, Vertex );
		
		// The face points are positioned as the average of the positions of the face's original vertices;
		foreach ( n, f; faces )
		{
			Vertex vc = add_face_vert( f );
			vfmap[f] = vc;
			
			foreach ( e; f.edges )
			{
				Vertex vt = new Vertex( null, 0, 0, 0 );
				vt += e.va;
				vt += e.vb;
				vt /= 2;
				midpoints[e] = vt;
			}
		}
		
		// The edge point locations are calculated as the average of the center point of the original edge 
		// and the average of the locations of the two new adjacent face points;
		foreach ( n, f; faces )
		{
			Vertex vc = vfmap[f];
			VertexList vl = new VertexList;
			
			for ( int en = 0; en < f.edges.length; en++ )
			{
				int et = en-1;
				
				if ( et < 0 )
					et = f.edges.length-1;
				
				Vertex vt = get_vert_for_edge( f.edges[en] );
				Vertex vp = get_vert_for_edge( f.edges[et] );
				
				Vertex vo = f.edges[en].getCommonVertex( f.edges[et] );
				
				b.addFace( 4, vc, vp, vo, vt );
				
				ops.appendUnique( vo );
			}
		}
		
		foreach ( P; ops )
		{
			Vertex F = new Vertex( null, 0, 0, 0 );
			
			int a = 0;
			
			writefln( "P.faces.length: %d", P.faces.length);
			writefln( "P.edges.length: %d", P.edges.length);
			writefln( "vfmap.length: %d", vfmap.length);
			writefln( "vemap.length: %d", vemap.length);
			foreach ( vf; P.faces )
			{
	
				if ( !( vf in vfmap ) )
					continue;
				
				F += vfmap[vf];

				writefln( "F-XYZ: %f %f %f", F.x, F.y, F.z );
				
				
				a++;
			}
			
			F /= a;
			

			Vertex R = new Vertex( null, 0, 0, 0 );
			int b = 0;
			
			foreach ( ve; P.edges )
			{
				if ( !( ve in vemap ) )
					continue;
				
				R += midpoints[ve];

				
				writefln( "R-XYZ: %f %f %f", R.x, R.y, R.z );
				
				
				b++;
			}
			
			R /= b;
			
			float n = b;
			
			Vertex PC = (F + (R*2) + ((n-3) * P)) / n;
			
			writefln( "XYZ: %f %f %f", PC.x, PC.y, PC.z );
			P.zero;
			P += PC;
			
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
