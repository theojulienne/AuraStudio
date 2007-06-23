module aura.model.vector;

import aura.model.vertex;

import std.math;

struct Vector
{
	float x=0, y=0, z=0;
	
	void set( float _x, float _y, float _z )
	{
		x = _x;
		y = _y;
		z = _z;
	}
	
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
	
	void zero( )
	{
		x = y = z = 0;
	}
	
	int opAddAssign( Vertex v ) { return opAddAssign( v.vector ); }
	int opSubAssign( Vertex v ) { return opSubAssign( v.vector ); }
	
	int opAddAssign( Vector n )
	{
		x += n.x;
		y += n.y;
		z += n.z;
		
		return 0;
	}
	
	int opSubAssign( Vector n )
	{
		x -= n.x;
		y -= n.y;
		z -= n.z;
		
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
	
	Vector dot( Vector v2 )
	{
		return x*v2.x + y*v2.y + z*v2.z;
	}
	
	Vector opAdd( Vector v )
	{
		Vector tv = *this;
		tv += v;
		return tv;
	}
	
	Vector opSub( Vector v )
	{
		Vector tv = *this;
		tv -= v;
		return tv;
	}
	
	Vector opMul( float n )
	{
		Vector tv = *this;
		tv *= n;
		return tv;
	}
	
	Vector opDiv( float n )
	{
		Vector tv = *this;
		tv /= n;
		return tv;
	}
	
	static Vector opCall( Vertex v )
	{
		Vector tv;
		tv.set( v );
		return tv;
	}
	
	void set( Vector v )
	{
		x = v.x;
		y = v.y;
		z = v.z;
	}
	
	void set( Vertex v )
	{
		set( v.vector );
	}
	
	void setToVertex( Vertex v )
	{
		set( v );
	}
}
