chan ch12 = [0] of {bit};
chan ch12e = [0] of {bit};
chan ch23 = [0] of {bit};
chan ch23e = [0] of {bit};
chan ch34 = [0] of {bit};
chan ch34e = [0] of {bit};
chan ch41 = [0] of {bit};
chan ch41e = [0] of {bit};
chan ch14 = [0] of {bit};
chan ch14e = [0] of {bit};
chan ch43 = [0] of {bit};
chan ch43e = [0] of {bit};
chan ch32 = [0] of {bit};
chan ch32e = [0] of {bit};
chan ch21 = [0] of {bit};
chan ch21e = [0] of {bit};

proctype Track12() 
{
	bit in = 0; 
	do 
	:: (in == 0) -> ch12?1; in = 1;
	:: (in == 1) -> in = 0; ch12e!in;
	od;
	
}

proctype Track23() 
{
	bit in = 0; 
	do 
	:: (in == 0) -> ch23?1; in = 1;
	:: (in == 1) -> in = 0; ch23e!in;
	od;
	
}
proctype Track34() 
{
	bit in = 0; 
	do 
	:: (in == 0) -> ch34?1; in = 1;
	:: (in == 1) -> in = 0; ch34e!in;
	od;
	
}

proctype Track41() 
{
	bit in = 0; 
	do 
	:: (in == 0) -> ch41?1; in = 1;
	:: (in == 1) -> in = 0; ch41e!in;
	od;
	
}

proctype Track14() 
{
	bit in = 0; 
	do 
	:: (in == 0) -> ch14?1; in = 1;
	:: (in == 1) -> in = 0; ch14e!in;
	od;
	
}

proctype Track43() 
{
	bit in = 0; 
	do 
	:: (in == 0) -> ch43?1; in = 1;
	:: (in == 1) -> in = 0; ch43e!in;
	od;
	
}

proctype Track32() 
{
	bit in = 0; 
	do 
	:: (in == 0) -> ch32?1; in = 1;
	:: (in == 1) -> in = 0; ch32e!in;
	od;
	
}

proctype Track21() 
{
	bit in = 0; 
	do 
	:: (in == 0) -> ch21?1; in = 1;
	:: (in == 1) -> in = 0; ch21e!in;
	od;
	
}


init {
	run Track12(); 
	run Track23();
	run Track34();
	run Track41();
	run Track14();
	run Track43();
	run Track32();
	run Track21(); 
}
