module aura.model.mbody;

import aura.list;
import aura.selection;
import aura.editing;
import aura.model.vertex;
import aura.model.face;

import opengl.gl;
import std.stdio;

class BodyList
{
	mixin MixList!(Body);
}

class Body
{
	VertexList verts;
	FaceList faces;
	
	bool selected = false;
	bool hot = false;
	
	this()
	{
		verts = new VertexList;
		faces = new FaceList;
		
		Vertex a, b, c, d, e, f, g, h, i;
		
		a = addVertex(-1.0f,  1.0f,  1.0f ); // front top left
		b = addVertex(-1.0f, -1.0f,  1.0f ); // front bottom left
		c = addVertex( 1.0f,  1.0f,  1.0f ); // front top right
		d = addVertex( 1.0f, -1.0f,  1.0f ); // front bottom right
		
		e = addVertex(-1.0f,  1.0f, -1.0f ); // rear top left
		f = addVertex(-1.0f, -1.0f, -1.0f ); // rear bottom left
		g = addVertex( 1.0f,  1.0f, -1.0f ); // rear top right
		h = addVertex( 1.0f, -1.0f, -1.0f ); // rear bottom right
		
		i = addVertex( 0.0f,  2.0f,  0.0f ); // rear bottom right
		
		Face fa;
		fa = addFace( 4, a, b, d, c );
		fa = addFace( 4, f, b, a, e );
		fa = addFace( 4, c, d, h, g );
		fa = addFace( 4, e, g, h, f );
		//fa = addFace( 4, a, e, g, c );
		fa = addFace( 4, b, f, h, d );
		
		fa = addFace( 3, c, i, a );
		fa = addFace( 3, e, i, g );
		fa = addFace( 3, a, i, e );
		fa = addFace( 3, g, i, c );
		
		/*
		foreach ( f; faces )
		{
			writefln( "%s", f );
			foreach ( t; f.tris )
			{
				writefln( "\t%s", t );
				foreach ( v; t.verts )
				{
					writefln( "\t\t%s (%s edges, %s faces)", v, v.edges.length, v.faces.length );
					foreach ( e; v.edges )
					{
						writefln( "\t\t\t%s (%s faces)", e, e.faces.length );
					}
				}
			}
		}
		
		throw new Exception( "breakpoint" );
		*/
		
		/*
		a = addVertex( 0.0f,  1.0f,  0.0f ); // top
		b = addVertex(-1.0f, -1.0f,  1.0f ); // front left
		c = addVertex( 1.0f, -1.0f,  1.0f ); // front right
		d = addVertex( 1.0f, -1.0f, -1.0f ); // rear right
		e = addVertex(-1.0f, -1.0f, -1.0f ); // rear left
		
		Face f;
		f = addFace( 3, a, b, c );
		f.colour.set( 0.0f, 1.0f, 0.0f, 1.0f );
		f = addFace( 3, a, c, d );
		f.colour.set( 0.0f, 1.0f, 0.0f, 1.0f );
		f = addFace( 3, a, d, e );
		f.colour.set( 0.0f, 1.0f, 0.0f, 1.0f );
		f = addFace( 3, a, e, b );
		f.colour.set( 0.0f, 1.0f, 0.0f, 1.0f );
		*/
	}
	
	Vertex addVertex( float x, float y, float z )
	{
		Vertex v = new Vertex( this, x, y, z );
		
		verts.append( v );
		
		return v;
		/*int v = verts.length;
		
		verts.length = v+1;
		verts[v] = new Vertex( this, x, y, z );*/
		/*verts[v].x = x;
		verts[v].y = y;
		verts[v].z = z;*/
		
		//return verts[v];
	}
	
	Face addFace( int num_verts, Vertex[] fverts ... )
	{
		Face f = new Face;
		f.f_body = this;
		
		faces.append( f );
		
		foreach ( v; fverts )
			f.addVertex( v );
		
		f.computeEdges( );
		
		return f;
		
		/*int f = faces.length;
		
		faces.length = f+1;
		faces[f] = new Face;
		faces[f].f_body = this;
		
		foreach ( v; fverts )
			faces[f].addVertex( v );
		
		faces[f].computeEdges( );*/
		/*
		faces[f].verts.length = fverts.length;
		faces[f].verts[0..length] = fverts[0..length];
		*/
		
		//return faces[f];
	}
	
	void removeFace( Face f )
	{
		// remove the face from the faces list
		faces.remove( f );
		
		/*
		foreach ( a, sf; faces )
		{
			if ( sf is null ) throw new Exception( "While scanning faces, a face was null. Oops!" );
			if ( sf == f )
			{
				auto n = faces[0..a];
				auto m = faces[a+1..length];
				faces = n ~ m;
				break;
			}
		}*/
		
		f.cleanReferences( );
	}
	
	// renders a single face, with all transformations, and
	// passes on the selectMode choice.
	void renderFaceSelect( Face f, int selectMode )
	{
		f.renderFaceSelect( selectMode );
	}
	
	// renders all faces of the object, either with object
	// naming or with face naming.
	void renderSelect( int selectMode )
	{
		if ( selectMode == aSelectObject )
		{
			glPushName( cast(int)this );
			
			render( EditMode.None ); // render as usual
			
			glPopName( );
		}
		else
		{
			foreach ( f; faces )
			{
				// render in face mode, rest done later
				f.renderSelect( aSelectFace );
			}
		}
	}
	
	void render( int editMode )
	{
		glEnable(GL_POLYGON_OFFSET_FILL);
		glPolygonOffset(1.0f, 1.0f);
		
		glBegin( GL_TRIANGLES );
		
		if ( editMode == EditMode.Body )
		{
			float r, g, b;
			
			r = g = b = 0.0f;
			if ( this.hot )
				g = 0.4;
			
			if ( this.selected )
				r = 0.5;
			
			if ( !this.selected && !this.hot )
				r = g = b = 0.5f;
			
			glColor4f( r, g, b, 1.0 );
		}
		
		foreach ( f; faces )
		{
			if ( editMode == EditMode.Face )
			{
				float r, g, b;
				
				r = g = b = 0.0f;
				if ( f.hot )
					g = 0.4;
				
				if ( f.selected )
					r = 0.5;
				
				if ( !f.selected && !f.hot )
					r = g = b = 0.5f;
				
				glColor4f( r, g, b, 1.0 );
			}
			else if ( editMode != EditMode.Body )
				glColor4f( 0.5, 0.5, 0.5, 1 );
			
			foreach ( t; f.tris )
			{
				if ( t.verts[0] is null || t.verts[1] is null || t.verts[2] is null )
					continue; // bandaid to fix strange crashes
				t.verts[0].glv;
				t.verts[1].glv;
				t.verts[2].glv;
			}
		}
		glEnd( );
		
		//glEnable(GL_CULL_FACE);
		glCullFace(GL_BACK);
		glEnable(GL_POLYGON_OFFSET_LINE);
		glPolygonOffset(-1.0f, -1.0f);
		
		glEnable(GL_NORMALIZE);
		foreach ( f; faces )
		{
			foreach ( e; f.edges )
			{
				float r, g, b;
				float w = 1.0f;
				
				r = g = b = 0.0f;
				
				if ( editMode == EditMode.Edge )
				{
					if ( e.hot )
					{
						g = 0.5;
						w = 2.0;
					}
					if ( e.selected )
					{
						r = 0.8;
						w = 2.0;
					}
				}
			
				glColor3f( r, g, b );
				glLineWidth( w );
				
				glBegin( GL_LINES );
				glVertex3f( e.va.x, e.va.y, e.va.z );
				glVertex3f( e.vb.x, e.vb.y, e.vb.z );
				glEnd( );
			}
		}
		
		if ( editMode == EditMode.Vertex )
		{
			glEnable(GL_POLYGON_OFFSET_POINT);
			glPolygonOffset(5.0f, 5.0f);
			
			foreach ( f; faces )
			{
				foreach ( v; f.verts )
				{
					float r, g, b;
					float s = 4.0;
					r = g = b = 0.0f;
					if ( v.hot )
					{
						g = 0.5;
						s = 5;
					}
					if ( v.selected )
					{
						r = 0.8;
						s = 5;
					}
				
					glPointSize( s );

					glBegin( GL_POINTS );
					glColor3f( r, g, b );
					glVertex3f( v.x, v.y, v.z );
					glEnd( );
				}
			}
		}
		
		/*
		foreach ( f; faces )
		{
			// render in face mode, rest done later
			f.renderFaceSelectEdge( );
		}*/
		
		//foreach ( f; faces ) f.renderFaceSelectVertex( );
	}
}
