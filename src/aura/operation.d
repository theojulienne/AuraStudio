module aura.operation;

import claro.graphics.all;

public import aura.selection;

class Operation
{
	// prepares for a new usage of the operation
	abstract bool prepare( Selection sel )
	{
		_value = 0;
		
		Cursor.capture( );
		Cursor.hide( );
		
		return true;
	}
	
	// 
	void updateFromMouse( int x, int y )
	{
		value = value + (x * 0.01);
	}
	
	float _value;
	void value( float v )
	{
		_value = v;
		update( );
	}
	
	float value() { return _value; }
	
	abstract void complete( )
	{
		
	}
	
	abstract void update( )
	{
		
	}
	
	// cleans up from the operation
	abstract void cleanup( )
	{
		Cursor.show( );
		Cursor.release( );
	}
}
