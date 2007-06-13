module aura.list;

/*class List(T)
{
	T[] l;
	
	void append( T i )
	{
		int n = l.length;
		l.length = n+1;
		l[n] = i;
	}
	
	void appendUnique( T i )
	{
		if ( find( i ) != -1 )
			return;
		
		append( i );
	}
	
	int find( T i )
	{
		foreach ( a, ti; l )
		{
			if ( ti == i )
				return a;
		}
		
		return -1;
	}
	
	void remove( T i )
	{
		foreach ( a, ti; l )
		{
			if ( ti == i )
			{
				auto n = l[0..a];
				auto m = l[a+1..l.length];
				l = n ~ m;
				return;
			}
		}
	}
	
	T opIndex( int a )
	{
		return l[a];
	}
	
	T[] opAssign( T[] il )
	{
		l = il;
		
		return l;
	}
	
	T opIndexAssign( T v, int a )
	{
		l[a] = v;
		
		return l[a];
	}
	
	int opApply( int delegate(inout T) dg )
	{
		foreach ( inout val; l )
		{
			if ( int r = dg( val ) )
				return r;
		}
	}
	
	T[] get( )
	{
		return l;
	}
	
	int length( )
	{
		return l.length;
	}
}*/

template MixList(T)
{
	T[] l;
		
	void append( T i )
	{
		int n = l.length;
		l.length = n+1;
		l[n] = i;
		
	}
	
	void appendUnique( T i )
	{
		if ( find( i ) != -1 )
			return;
		
		append( i );
	}
	
	int find( T i )
	{
		foreach ( a, ti; l )
		{
			if ( ti == i )
				return a;
		}
		
		return -1;
	}
	
	void remove( T i )
	{
		T[] n;
		int el = 0;
		
		n.length = l.length;
		
		foreach ( a, ti; l )
		{
			if ( ti != i )
			{
				n[el] = ti;
				el++;
			}
		}
		
		n.length = el;
		
		delete l;
		l = n;
	}
	
	T opIndex( int a )
	{
		return l[a];
	}
	
	T[] opAssign( T[] il )
	{
		l = il;
		
		return l;
	}
	
	T opIndexAssign( T v, int a )
	{
		l[a] = v;
		
		return l[a];
	}
	
	int opApply( int delegate(inout T) dg )
	{
		foreach ( inout val; l )
		{
			if ( int r = dg( val ) )
				return r;
		}
		return 0;
	}
	
	T[] get( )
	{
		return l;
	}
	
	int length( )
	{
		return l.length;
	}
}
