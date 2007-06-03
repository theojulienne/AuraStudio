module aura.operation;

public import aura.selection;

class Operation
{
	bool has_mouse_started = false;
	int mouse_lastx, mouse_lasty;
	float mouse_value;
	
	// prepares for a new usage of the operation
	abstract bool prepare( Selection sel )
	{
		has_mouse_started = false;
		_value = 1;
		
		return true;
	}
	
	// 
	void updateFromMouse( int x, int y )
	{
		if ( has_mouse_started == false )
		{
			mouse_lastx = x;
			mouse_lasty = y;
			has_mouse_started = true;
			return;
		}
		
		int mdx;
		
		mdx = x - mouse_lastx;
		mouse_lastx = x;
		mouse_lasty = y;
		
		value = value + (mdx * 0.01);
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
		
	}
}
