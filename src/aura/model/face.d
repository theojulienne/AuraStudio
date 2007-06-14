module aura.model.face;

import aura.list;
import aura.selection;
import aura.model.mbody;
import aura.model.vertex;
import aura.model.edge;
import aura.model.subtri;
import aura.model.normal;

import opengl.gl;
import std.stdio;

class FaceList
{
	mixin MixList!(Face);
}

class Face
{
	VertexList verts;
	EdgeList edges;
	
	SubTriList tris;
	
	Body f_body;
	
	Colour colour;
	
	bool selected = false;
	bool hot = false;
	
	Normal normal;
	
	this( )
	{
		verts = new VertexList;
		edges = new EdgeList;
		tris = new SubTriList;
	}
	
	Normal calculateNormal( )
	{
		normal.zero( );
		
		foreach ( t; tris )
		{
			normal += t.calculateNormal( );
		}
		
		// this is unnecessary
		normal /= tris.length;
		
		normal.normalize();
		
		return normal;
	}
	
	void cleanReferences( )
	{
		foreach ( v; verts )
			v.cleanReferencesToFace( this );
		
		foreach ( e; edges )
			e.cleanReferencesToFace( this );
	}
	
	void rebuildTris( )
	{
		/*foreach ( t; tris )
		{
			delete t;
		}
		
		tris.length = 0;*/
		tris = [];
		
		// now let's make our subtris
		
		//tris.length = verts.length - 2;
		
		//writefln( "Tris calculated: %s", verts.length );
		
		if ( verts.length < 3 )
		{
			return;
		} else if ( verts.length == 3 )
		{
			// tri already
			tris.append( new SubTri( verts[0], verts[1], verts[2] ) );
		}
		else if ( verts.length == 4 )
		{
			// quad
			tris.append( new SubTri( verts[0], verts[1], verts[2] ) );
			tris.append( new SubTri( verts[2], verts[3], verts[0] ) );
		}
		else
		{
			throw new Exception( "Ear clipping not yet implemented, yet a face with more than 4 verts encountered!");
		}
	}
	
	void addVertex( Vertex v )
	{
		verts.append( v );
		
		v.faces.append( this );
		
		if ( v == null )
		{
			throw new Exception( "Attempt to append a null vertex to face with length " ~ std.string.toString(verts.length) );
		}
	}
	
	void computeEdges( )
	{
		int a;
		
		for ( a = 1; a < verts.length; a++ )
			edges.append( Edge.getEdge( this, verts[a-1], verts[a] ) );
		
		edges.append( Edge.getEdge( this, verts[verts.length-1], verts[0] ) );
		
		if ( edges.length != verts.length )
			throw new Exception( "computeEdges made incorrect number of edges" );
		
		rebuildTris( );
	}
	
	void renderSelect( int selectMode )
	{
		glDisable(GL_CULL_FACE);
		
		if ( selectMode == aSelectFace )
		{
			glPushName( cast(int)this );
		
			glBegin( GL_TRIANGLES );
			glColor4f( colour.r, colour.g, colour.b, colour.a );
			
			foreach ( t; tris )
			{
				t.verts[0].glv;
				t.verts[1].glv;
				t.verts[2].glv;
			}
			
			glEnd( );
			
			glPopName( );
		}
	}
	
	void renderFaceSelectVertex( )
	{
		/*if ( tris.length > 1 )
			return;*/
		
		foreach ( t; tris )
		{
			Vertex center = new Vertex( null, 0, 0, 0 );
			foreach ( v; t.verts )
				center += v;
			center /= t.verts.length;
			
			Vertex va = t.verts[0];
			Vertex vb = t.verts[1];
			Vertex vc = t.verts[2];
			
			Edge ea = Edge.getEdge( null, va, vb );
			Edge eb = Edge.getEdge( null, vb, vc );
			Edge ec = Edge.getEdge( null, vc, va );
			
			Vertex ca = Vertex.makeCenterOf( va, vb );
			Vertex cb = Vertex.makeCenterOf( vb, vc );
			Vertex cc = Vertex.makeCenterOf( vc, va );
			
			int real_edges = 0;
			
			if ( ea.hasFace(this) )
				real_edges++;
			else
				ea = null;
			
			if ( eb.hasFace(this) )
				real_edges++;
			else
				eb = null;
				
			if ( ec.hasFace(this) )
				real_edges++;
			else
				ec = null;
			
			if ( real_edges == 3 )
			{
				glPushName( cast(int)va );
				glBegin( GL_TRIANGLES );
				glColor3f( 1.0f, 0.0f, 0.0f );
				va.glv; ca.glv; center.glv;
				glColor3f( 1.0f, 0.5f, 0.0f );
				va.glv; cc.glv; center.glv;
				glEnd( );
				glPopName( );

				glPushName( cast(int)vb );
				glBegin( GL_TRIANGLES );
				glColor3f( 0.0f, 1.0f, 0.0f );
				vb.glv; cb.glv; center.glv;
				glColor3f( 0.0f, 1.0f, 0.5f );
				vb.glv; ca.glv; center.glv;
				glEnd( );
				glPopName( );

				glPushName( cast(int)vc );
				glBegin( GL_TRIANGLES );
				glColor3f( 0.0f, 0.0f, 1.0f );
				vc.glv; cc.glv; center.glv;
				glColor3f( 0.0f, 0.5f, 1.0f );
				vc.glv; cb.glv; center.glv;
				glEnd( );
				glPopName( );
			}
			
			else if ( real_edges == 2 )
			{
				// move the edges down the stack so the 2 real edges are "ea" and "eb"
				if ( ea is null )
				{
					ea = eb;
					eb = ec;
				}
				else if ( eb is null )
				{
					eb = ec;
				}
				
				// which vertex is shared?
				Vertex shared = ea.va;
				if ( !eb.hasVertex( shared ) ) shared = ea.vb;
				if ( !eb.hasVertex( shared ) ) throw new Exception( "2 edges of a triangle don't share a common vertex!" );
				
				if ( !ea.hasVertex( shared ) || !eb.hasVertex( shared ) )
					throw new Exception( "Something broke :)" );
				
				// find the 2 verts that are unique (not shared by a real edge)
				Vertex ua = ea.getOther( shared );
				Vertex ub = eb.getOther( shared );
				
				if ( ua == shared || ub == shared )
					throw new Exception( "Unique vertex was same as shared vertex" );
				
				// calculate the center of the edge between ua and ub
				Vertex ecenter = Vertex.makeCenterOf( ua, ub );
				
				// calculate the center of each real edges
				Vertex eac = ea.getCenter( );
				Vertex ebc = eb.getCenter( );
				
				glDisable( GL_CULL_FACE );
				
				glPushName( cast(int)shared );
				glBegin( GL_TRIANGLES );
				glColor3f( 1.0f, 0.0f, 0.0f );
				shared.glv; eac.glv; ecenter.glv;
				shared.glv; ebc.glv; ecenter.glv;
				glEnd( );
				glPopName( );
				
				glPushName( cast(int)ua );
				glBegin( GL_TRIANGLES );
				glColor3f( 1.0f, 0.0f, 0.0f );
				ua.glv; eac.glv; ecenter.glv;
				glEnd( );
				glPopName( );
				
				glPushName( cast(int)ub );
				glBegin( GL_TRIANGLES );
				glColor3f( 1.0f, 0.0f, 0.0f );
				ub.glv; ebc.glv; ecenter.glv;
				glEnd( );
				glPopName( );
			}
			
			else if ( real_edges == 1 )
			{
				throw new Exception( "Encountered a sub-triangle with only 1 real edge. Was triangulation implemented without adding vertex detection code for this case? Oops!" );
			}
		}
		
		/*
		
		Vertex center = new Vertex( null, 0, 0, 0 );
		foreach ( v; verts )
			center += v;
		center /= verts.length;
		
		glDisable(GL_CULL_FACE);
		
		Vertex va = verts[0];
		Vertex vb = verts[1];
		Vertex vc = verts[2];
		
		Vertex ca = Vertex.makeCenterOf( va, vb );
		Vertex cb = Vertex.makeCenterOf( vb, vc );
		Vertex cc = Vertex.makeCenterOf( vc, va );
		
		glPushName( cast(int)va );
		glBegin( GL_TRIANGLES );
		glColor3f( 1.0f, 0.0f, 0.0f );
		va.glv; ca.glv; center.glv;
		glColor3f( 1.0f, 0.5f, 0.0f );
		va.glv; cc.glv; center.glv;
		glEnd( );
		glPopName( );
		
		glPushName( cast(int)vb );
		glBegin( GL_TRIANGLES );
		glColor3f( 0.0f, 1.0f, 0.0f );
		vb.glv; cb.glv; center.glv;
		glColor3f( 0.0f, 1.0f, 0.5f );
		vb.glv; ca.glv; center.glv;
		glEnd( );
		glPopName( );
		
		glPushName( cast(int)vc );
		glBegin( GL_TRIANGLES );
		glColor3f( 0.0f, 0.0f, 1.0f );
		vc.glv; cc.glv; center.glv;
		glColor3f( 0.0f, 0.5f, 1.0f );
		vc.glv; cb.glv; center.glv;
		glEnd( );
		glPopName( );
		*/
	}
	
	void renderFaceSelectEdge( )
	{
		foreach ( t; tris )
		{
			Vertex center = new Vertex( null, 0, 0, 0 );
			foreach ( v; t.verts )
				center += v;
			center /= t.verts.length;
			
			Vertex va = t.verts[0];
			Vertex vb = t.verts[1];
			Vertex vc = t.verts[2];
			
			Edge ea = Edge.getEdge( null, va, vb );
			Edge eb = Edge.getEdge( null, vb, vc );
			Edge ec = Edge.getEdge( null, vc, va );
			
			int real_edges = 0;
			
			if ( ea.hasFace(this) )
				real_edges++;
			else
				ea = null;
			
			if ( eb.hasFace(this) )
				real_edges++;
			else
				eb = null;
				
			if ( ec.hasFace(this) )
				real_edges++;
			else
				ec = null;
			
			if ( real_edges == 3 )
			{
				// we have 3 edges that belong to this face.
				// render the tris from the center to the verts
				
				glPushName( cast(int)ea );
				glBegin( GL_TRIANGLES );
				glColor3f( 1.0f, 0.0f, 0.0f );
				va.glv; vb.glv; center.glv;
				glEnd( );
				glPopName( );

				glPushName( cast(int)eb );
				glBegin( GL_TRIANGLES );
				glColor3f( 0.0f, 1.0f, 0.0f );
				vb.glv; vc.glv; center.glv;
				glEnd( );
				glPopName( );

				glPushName( cast(int)ec );
				glBegin( GL_TRIANGLES );
				glColor3f( 0.0f, 0.0f, 1.0f );
				vc.glv; va.glv; center.glv;
				glEnd( );
				glPopName( );
			}
			
			else if ( real_edges == 2 )
			{
				// move the edges down the stack so the 2 real edges are "ea" and "eb"
				if ( ea is null )
				{
					ea = eb;
					eb = ec;
				}
				else if ( eb is null )
				{
					eb = ec;
				}
				
				// which vertex is shared?
				Vertex shared = ea.va;
				if ( !eb.hasVertex( shared ) ) shared = ea.vb;
				if ( !eb.hasVertex( shared ) ) throw new Exception( "2 edges of a triangle don't share a common vertex!" );
				
				if ( !ea.hasVertex( shared ) || !eb.hasVertex( shared ) )
					throw new Exception( "Something broke :)" );
				
				// find the 2 verts that are unique (not shared by a real edge)
				Vertex ua = ea.getOther( shared );
				Vertex ub = eb.getOther( shared );
				
				if ( ua == shared || ub == shared )
					throw new Exception( "Unique vertex was same as shared vertex" );
				
				// calculate the center of the edge between ua and ub
				Vertex ecenter = Vertex.makeCenterOf( ua, ub );
				
				// got all we need!
				
				glDisable( GL_CULL_FACE );
				
				glPushName( cast(int)ea );
				glBegin( GL_TRIANGLES );
				glColor3f( 1.0f, 0.0f, 0.0f );
				shared.glv; ua.glv; ecenter.glv;
				glEnd( );
				glPopName( );

				glPushName( cast(int)eb );
				glBegin( GL_TRIANGLES );
				glColor3f( 0.0f, 1.0f, 0.0f );
				eb.va.glv; eb.vb.glv; ecenter.glv;
				glEnd( );
				glPopName( );
			}
			
			else if ( real_edges == 1 )
			{
				throw new Exception( "Encountered a sub-triangle with only 1 real edge. Was triangulation implemented without adding edge detection code for this case? Oops!" );
			}
		}
		
		/*return;
		
		////// OLD //////
		Vertex center = new Vertex( null, 0, 0, 0 );
		foreach ( v; verts )
			center += v;
		center /= verts.length;
		
		glDisable(GL_CULL_FACE);
		
		Vertex va = verts[0];
		Vertex vb = verts[1];
		Vertex vc = verts[2];
		
		Edge ea = Edge.getEdge( null, va, vb );
		Edge eb = Edge.getEdge( null, vb, vc );
		Edge ec = Edge.getEdge( null, vc, va );
		
		glPushName( cast(int)ea );
		glBegin( GL_TRIANGLES );
		glColor3f( 1.0f, 0.0f, 0.0f );
		va.glv; vb.glv; center.glv;
		glEnd( );
		glPopName( );
		
		glPushName( cast(int)eb );
		glBegin( GL_TRIANGLES );
		glColor3f( 0.0f, 1.0f, 0.0f );
		vb.glv; vc.glv; center.glv;
		glEnd( );
		glPopName( );
		
		glPushName( cast(int)ec );
		glBegin( GL_TRIANGLES );
		glColor3f( 0.0f, 0.0f, 1.0f );
		vc.glv; va.glv; center.glv;
		glEnd( );
		glPopName( );*/
	}
	
	void renderFaceSelect( int selectMode )
	{
		if ( selectMode == aSelectVertex ) renderFaceSelectVertex( );
		else if ( selectMode == aSelectEdge ) renderFaceSelectEdge( );
	}
}