module aura.model.vector;

import aura.model.vertex;

import std.math;

struct Vector
{
	float x, y, z;
	
	void normalize( )
	{
		float len;
		
		len = cast(float)sqrt((x*x) + (y*y) + (z*z));

		if(len == 0.0f)						// Prevents Divide By 0 Error By Providing
			len = 1.0f;						// An Acceptable Value For Vectors To Close To 0.

		x /= len;						// Dividing Each Element By
		y /= len;						// The Length Results In A
		z /= len;						// Unit Normal Vector.
	}
	
	int opAssign( Vertex v )
	{
		
		return 0;
	}
	
	void zero( )
	{
		x = y = z = 0;
	}
	
	int opSubAssign( Vertex v )
	{
		x -= v.x;
		y -= v.y;
		z -= v.z;
		
		return 0;
	}
	
	int opAddAssign( Vector n )
	{
		x += n.x;
		y += n.y;
		z += n.z;
		
		return 0;
	}
	
	int opDivAssign( float n )
	{
		x /= n;
		y /= n;
		z /= n;
		
		return 0;
	}
	
	int opMulAssign( float n )
	{
		x *= n;
		y *= n;
		z *= n;
		
		return 0;
	}
	
	Vector cross( Vector on )
	{
		Vector n;
		
		n.x = y*on.z - z*on.y;				// Cross Product For Y - Z
		n.y = z*on.x - x*on.z;				// Cross Product For X - Z
		n.z = x*on.y - y*on.x;				// Cross Product For X - Y
		
		return n;
	}
	
	void setToVertex( Vertex v )
	{
		x = v.x;
		y = v.y;
		z = v.z;
	}
}
