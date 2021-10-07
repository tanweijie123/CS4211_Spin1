chan ch12 = [0] of {byte};
chan ch12e = [0] of {byte};
chan ch23 = [0] of {byte};
chan ch23e = [0] of {byte};
chan ch34 = [0] of {byte};
chan ch34e = [0] of {byte};
chan ch41 = [0] of {byte};
chan ch41e = [0] of {byte};
chan ch14 = [0] of {byte};
chan ch14e = [0] of {byte};
chan ch43 = [0] of {byte};
chan ch43e = [0] of {byte};
chan ch32 = [0] of {byte};
chan ch32e = [0] of {byte};
chan ch21 = [0] of {byte};
chan ch21e = [0] of {byte};

active proctype Track12() 
{
	byte shuttle; 
	do 
	:: ch12?shuttle-> ch12e!shuttle;
	od;
}

active proctype Track23() 
{
	byte shuttle; 
	do 
	:: ch23?shuttle -> ch23e!shuttle;
	od;
}

active proctype Track34() 
{
	byte shuttle; 
	do 
	:: ch34?shuttle -> ch34e!shuttle;
	od;
}

active proctype Track41() 
{
	byte shuttle; 
	do 
	:: ch41?shuttle -> ch41e!shuttle;
	od;
}

active proctype Track14() 
{
	byte shuttle; 
	do 
	:: ch14?shuttle -> ch14e!shuttle;
	od;
}

active proctype Track43() 
{
	byte shuttle; 
	do 
	:: ch43?shuttle -> ch43e!shuttle;
	od;
}

active proctype Track32() 
{
	byte shuttle; 
	do 
	:: ch32?shuttle -> ch32e!shuttle;
	od;
}

active proctype Track21() 
{
	byte shuttle; 
	do 
	:: ch21?shuttle -> ch21e!shuttle;
	od;
}


init {
	bool running = true; 
}
