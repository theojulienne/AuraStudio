module aura.camera;

import opengl.gl;

import std.stdio;

struct Vector3
{
	float x, y, z;
}

class Camera
{
	Vector3 pos, rot;
	
	float dist;
	
	Vector3 spin_origin;
	float spin_horiz;
	float spin_vert;
	
	this()
	{
		pos.x = 0.0f;
		pos.y = 0.0f;
		pos.z = 0.0f;

		rot.x = 0.0f;
		rot.y = 0.0f;
		rot.z = 0.0f;

		dist = 15.0f;
		spin_vert = -20.0f;
		spin_horiz = 45.0f;
		
		spin_origin.x = 0.0f;
		spin_origin.y = 0.0f;
		spin_origin.z = 0.0f;
	}
	
	void updateCamera( )
	{
		GLfloat matrix[16];

		glPushMatrix( );

		glLoadIdentity( );

		glRotatef( 0.0f, 0.0f, 0.0f, 1.0f );
		glRotatef( spin_horiz, 0.0f, 1.0f, 0.0f );
		glRotatef( spin_vert, 1.0f, 0.0f, 0.0f );

		glTranslatef( 0.0f, 0.0f, -dist );

		glGetFloatv( GL_MODELVIEW_MATRIX, matrix.ptr );

		glPopMatrix( );

		pos.x = spin_origin.x - matrix[12];
		pos.y = spin_origin.y - matrix[13];
		pos.z = spin_origin.z - matrix[14];

		rot.y = spin_horiz;
		rot.x = spin_vert;
	}
	
	void setupPosition( )
	{
		glLoadIdentity( );
		
		updateCamera( );
		
		glRotatef( -rot.x, 1.0f, 0.0f, 0.0f );
		glRotatef( -rot.y, 0.0f, 1.0f, 0.0f );
		glRotatef( -rot.z, 0.0f, 0.0f, 1.0f );
		glTranslatef( -pos.x, -pos.y, -pos.z );
	}
}
