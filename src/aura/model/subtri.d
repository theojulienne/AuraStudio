module aura.model.subtri;

import aura.list;
import aura.model.vertex;
import aura.model.vector;

import std.math;

class SubTriList
{
	mixin MixList!(SubTri);
}

class SubTri
{
	Vertex verts[3];
	
	this( Vertex a, Vertex b, Vertex c )
	{
		verts[0] = a;
		verts[1] = b;
		verts[2] = c;
	}
	
	Vector calculateNormal( )
	{
	 	Vector v1, v2;
		v1.setToVertex( verts[1] );
		v1 -= verts[0];
		v2.setToVertex( verts[2] );
		v2 -= verts[0];
		
		return v1.cross( v2 );
	}
	
	



	bool intersects ( SubTri other )
	{
		
		bool coplanar_intersect(Vector n, Vector v0, Vector v1, Vector v2, Vector u0, Vector u1, Vector u2 )
		{
			Vector a;
			int i0, i1;
			a.x = abs( n.x );
			a.y = abs( n.y );
			a.z = abs( n.z );

			if( a.x > a.y )
			{
				if( a.x > a.z )
				{
					i0 = 1;
					i1 = 2;
				} else {
					i0 = 0;
					i1 = 1;
				}
			} else {
				if( a.z > a.y )
				{
					i0 = 0;
					i1 = 1;
				} else {
					i0 = 0;
					i1 = 2;
				}
			}

			
			// ... err
			return false;
		}
		
		
		
		
		Vector v0, v1, v2, u0, u1, u2;
		
		v0.setToVertex( verts[0] );
		v1.setToVertex( verts[1] );
		v2.setToVertex( verts[2] );
		
		u0.setToVertex( other.verts[0] );
		u1.setToVertex( other.verts[1] );
		u2.setToVertex( other.verts[2] );
		
		// the plane of this triangle
		Vector e1 = v1 - v0;
		Vector e2 = v2 - v0;
		Vector n1 = e1.cross( e2 );
		float d1 = -n1.dot( v0 );
		
	  	// signed distances from other triangle to the plane
	  	float du0 = n1.dot( u0 ) + d1;
		float du1 = n1.dot( u1 ) + d1;
		float du2 = n1.dot( u2 ) + d1;
		
		// pre-calculate multiplications
		float du0du1 = du0 * du1;
		float du0du2 = du0 * du2;

		// same sign on all distances, no collision
		if( du0du1 > 0 && du0du2 > 0) return false;
		
		// the plane of the other triangle
		e1 = u1 - u0;
		e2 = u2 - u0;
		Vector n2 = e1.cross( e2 );
		float d2 = -n1.dot( v0 );

	  	// signed distances from this triangle to the other plane
	  	float dv0 = n2.dot( v0 ) + d2;
		float dv1 = n2.dot( v1 ) + d2;
		float dv2 = n2.dot( v2 ) + d2;	
		
		// pre-calculate multiplications
		float dv0dv1 = dv0 * dv1;
		float dv0dv2 = dv0 * dv2;
		
		// same sign on all distances, no collision
		if( dv0dv1 > 0 && dv0dv2 > 0) return false;
		
		// direction of intersection line
		Vector dv = n1.cross( n2 );
		
		// largest component of d
		float max = abs( dv.x );
		float max_y  = abs( dv.y );
		float max_z  = abs( dv.z );
		
		float vp0, vp1, vp2, up0, up1, up2;
		
		vp0 = v0.x;
		vp1 = v1.x;
		vp2 = v2.x;

		up0 = u0.x;
		up1 = u1.x;
		up2 = u2.x;
		
		if( max_y > max ) {
			max = max_y;
			
			vp0 = v0.y;
			vp1 = v1.y;
			vp2 = v2.y;

			up0 = u0.y;
			up1 = u1.y;
			up2 = u2.y;
		}
		
		if( max_z > max ) {
			max = max_z;
			
			vp0 = v0.z;
			vp1 = v1.z;
			vp2 = v2.z;

			up0 = u0.z;
			up1 = u1.z;
			up2 = u2.z;
		}
		
		
		// compute intervals
		// this triangle
		float a, b, c;
		float x0, x1;
		if( dv0dv1 > 0 )
		{
			a = vp0;
			b = (vp0 - vp2) * dv2;
			c = (vp1 - vp2) * dv2;
			x0 = dv2 - dv0;
			x1 = dv2 - dv1;
		} else if( dv0dv2 > 0 ) 
		{
			a = vp1;
			b = (vp0 - vp1) * dv1;
			c = (vp2 - vp1) * dv1;
			x0 = dv1 - dv0;
			x1 = dv1 - dv2;
		} else if( dv1 * dv2 > 0 || dv0 != 0 )
		{
			a = vp0;
			b = (vp1 - vp0) * dv0;
			c = (vp2 - vp0) * dv0;
			x0 = dv0 - dv1;
			x1 = dv0 - dv2;
		} else if( dv1 != 0 ) 
		{
			a = vp1;
			b = (vp0 - vp1) * dv1;
			c = (vp2 - vp1) * dv1;
			x0 = dv1 - dv0;
			x1 = dv1 - dv2;
		} else if( dv2 != 0 )
		{
			a = vp2;
			b = (vp0 - vp2) * dv2;
			c = (vp1 - vp2) * dv2;
			x0 = dv2 - dv0;
			x1 = dv2 - dv1;
		} else {
			return coplanar_intersect( n1, v0, v1, v2, u0, u1, u2 );
		}  

		// other triangle
		float d, e, f;
		float y0, y1;
		if( du0du1 > 0 )
		{
			d = up0;
			e = (up0 - up2) * du2;
			f = (up1 - up2) * du2;
			y0 = du2 - du0;
			y1 = du2 - du1;
		} else if( du0du2 > 0 ) 
		{
			d = up1;
			e = (up0 - up1) * du1;
			f = (up2 - up1) * du1;
			y0 = du1 - du0;
			y1 = du1 - du2;
		} else if( du1 * du2 > 0 || du0 != 0 )
		{
			d = up0;
			e = (up1 - up0) * du0;
			f = (up2 - up0) * du0;
			y0 = du0 - du1;
			y1 = du0 - du2;
		} else if( du1 != 0 ) 
		{
			d = up1;
			e = (up0 - up1) * du1;
			f = (up2 - up1) * du1;
			y0 = du1 - du0;
			y1 = du1 - du2;
		} else if( du2 != 0 )
		{
			d = up2;
			e = (up0 - up2) * du2;
			f = (up1 - up2) * du2;
			y0 = du2 - du0;
			y1 = du2 - du1;
		} else {
			return coplanar_intersect( n1, v0, v1, v2, u0, u1, u2 );
		}	
		
		float xx = x0 * x1;
		float yy = y0 * y1;
		float xxyy = xx * yy;

		float temp;
		
		temp = a * xxyy;
		float isect10 = temp + b * x1 * yy;
		float isect11 = temp + c * x0 * yy;
		
		temp = d * xxyy;
		float isect20 = temp + e * xx * y1;
		float isect21 = temp + f * xx * y0;

		if ( isect10 > isect11 ) {
			temp = isect11;
			isect11 = isect10;
			isect10 = temp;
		}
		
		if ( isect20 > isect21 ) {
			temp = isect21;
			isect21 = isect20;
			isect20 = temp;
		}

		if ( isect11 < isect20 || isect21 < isect10 ) {
			return true;
		} else {
			return false;
		}
	}
}
