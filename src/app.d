module app;

import claro.core;
import claro.base.all;
import claro.graphics.all;

import aura.modeller;
import aura.motiontest;

void main( char [][] args ) {
	Claro.init();
	Claro.Graphics.init();
	
	WindowWidget w;
	
	if ( args.length > 1 && args[1] == "-motion" )
		w = new AuraMotionTestWindow( );
	else
		w = new AuraModellerWindow( );
	
	w.show( );
	w.focus( );

	Claro.loop();
}
