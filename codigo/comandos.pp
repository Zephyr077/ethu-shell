unit comandos;
interface
uses BaseUnix,Unix,crt,dos,SysUtils,DateUtils,utilidades,strUtils,strings, users;
procedure lsl(ruta:string);
procedure lsa(ruta:string);
procedure ls(ruta:string);
procedure lsf(ruta:string);
procedure ejecutar(ruta:string;opciones:string);
procedure cd(ruta:string;var rutaAcumulada:string);
procedure concatenar(a,b:string);
procedure kill(parametro1:string;parametro2:string);
procedure redireccionarOUT(comando:string;ruta1:string;ruta2:string;rutaArchivo:string);
procedure redireccionarIN(comando:string;rutaArchivo:string);
procedure pipe(comando1:string;opcion1:string;comando2:string;opcion2:string);
procedure pause(P_id: string);
procedure fg(P_id: string);
procedure bg(P_id:string);
procedure standby(pid:string;ruta:string;vezEjecutado:integer);
procedure externo(ruta:string; opciones:string);
procedure matar(P_id: string); //Recibe el PID del proceso, y lo mata



implementation
uses pash;



procedure standby(pid:string;ruta:string;vezEjecutado:integer);
var
i:integer;
op,op2:string;
begin
i:=1;
op:='';
op2:='';
repeat
    repeat
      inc(i);
    until keypressed;
    op:=readkey;
    if op=#26 then
       op2:='Z';
	if op=#25 then
		op2:='C';

until (op2='Z') or (op2='C');
if (op2='Z') then //si fue CTRL+Z
	   begin
				pause(pid);
				
				if vezEjecutado=1 then //si es la primera vez que se ejecuta
					begin
						agregarPrograma(tVectorProgramas,ruta,pid,'Detenido');					
					end
					else
					begin
						modificarPrograma(tVectorProgramas,pid,'Detenido');	
					end;
	   end
	  else
	     begin			
	        	if (op2='C') then //si fue CTRL+C
					begin
						matar(pid);
						  
							if vezEjecutado=1 then //si es la primera vez que se ejecuta
								begin
									agregarPrograma(tVectorProgramas,ruta,pid,'MATADO');
								end
								else
								begin
									modificarPrograma(tVectorProgramas,pid,'MATADO');
								end;
					end;
		end;

op:='';
op2:='';
end;


procedure fg(P_id:string);	// Recibe el codigo de un PID conocido, evalua si el mismo es correcto, si es asi, manda la señal de resumen, caso contrario tira error.
	 var 
		pid:string;				
		cod_error: word;
	    	senialAMandar: cint;
		 R: longint;
		caracter:char;
	 begin
		caracter := 'a';
		pid:=P_id;
	   val(P_id,R,cod_error);
           senialAMandar:=SIGCONT; //Enviamos la señal para traer el proceso a primer plano
   	   if (cod_error = 0) then 
          begin
           fpkill(R,senialAMandar);
           writeln('El proceso se ha vuelto a primero plano, con el PID: ', R);			
			standby(pid,'',2);
			ultimoEjecutadoPID:=pid;

      end
	   else
	   		writeln('No pudo enviarse la señal fg, error nº: ', cod_error);
	 end;

procedure bg(P_id:string);	// Recibe el codigo de un PID conocido, evalua si el mismo es correcto, si es asi, manda la señal de resumen, caso contrario tira error.
	 var 				
		cod_error: word;
	    senialAMandar: cint;
	    R: longint;
		pid:string;
	 begin
		pid:=P_id;
	   val(P_id,R,cod_error);
        senialAMandar:=SIGCONT; //Enviamos la señal para traer el proceso a primer plano


   	   if (cod_error = 0) then 
          begin
		   modificarPrograma(tVectorProgramas,pid,'En Ejecucion');
			ultimoEjecutadoPID:=pid;
           fpkill(R,senialAMandar);
           writeln('El proceso se ha vuelto a segundo plano, con el PID: ', R);
			
      end
	   else
	   		writeln('No pudo enviarse la señal fg, error nº: ', cod_error);
	 end;


procedure pause(P_id: string); //Recibe el PID del proceso, y lo pausa
	 var
	 R: longint;
	 senialAMandar: cint;
	 cod_error: word;
	 pid: string;
	 begin 
			pid:=P_id;
			senialAMandar:=SIGSTOP;
			val(P_id,R,cod_error);   	   
     		if (cod_error = 0) then
					begin	
						  modificarPrograma(tVectorProgramas,pid,'Detenido');
     	     			  Fpkill(R,senialAMandar);
     	     			  writeln('El ha sido PAUSADO con exito, el mismo es el:',P_id);
					end
					else
						writeln('Ha habido un error, codigo: ', cod_error);

	end;			

procedure matar(P_id: string); //Recibe el PID del proceso, y lo mata
	 var
	 R: longint;
	 senialAMandar: cint;
	 cod_error: word;
	 pid: string;
	 begin 
			pid:=P_id;
			senialAMandar:=SIGTERM;
			val(P_id,R,cod_error);   	   
     		if (cod_error = 0) then
					begin	
						  modificarPrograma(tVectorProgramas,pid,'MATADO');
     	     			  Fpkill(R,senialAMandar);
     	     			  writeln('El ha sido MATADO con exito, el mismo es el:',pid);
					end
					else
						writeln('Ha habido un error, codigo: ', cod_error);

	end;			

procedure pipe(comando1:string;opcion1:string;comando2:string;opcion2:string);
type
 TFildes =Array[0..1] of cint;
var 
 pid:Tpid;
 options,status: longint;
 fd:TFildes;

begin
 FpPipe(fd);
 pid:=fpFork;
 options:=0;
 status:=0;
 case pid of
  -1:Writeln('Error');
   0: begin
       if fpFork > 0 then
        begin
         fpclose(1); {cierra la salida estandar}
         fpdup(fd[1]);{hace una copia identica del descriptor y lo guardara en la posicion 1 del vector}
         fpexeclp(comando1,[opcion1]);  
        end
       else
        begin
         fpClose(0); {cierra la entrada estandar}
         fpdup(fd[0]);
         fpexeclp(comando2,[opcion2]);   
        end;
      end
   else
    fpWaitpid(pid,status,options);{espera que el proceso hijo de su salida}  
  end;
end;


procedure redireccionarIN(comando:string;rutaArchivo:string);
var 
 pid:Tpid;
 options,status: longint;

begin
 pid:=fpFork;
 options:=0;
 status:=0;
 case pid of
  -1:Writeln('Error');
   0: begin
       Fpclose(0); {cierra el descriptor de archivo 0 que es la entrada estandar}
       fpOpen(rutaArchivo,O_RdOnly);{el fpOpen le va a asignar el descriptor 0 ya que esta desocupado}
        if comando='cat' then
         concatenar(rutaArchivo,'');
       fpExit(1);
      end
   else
    fpWaitpid(pid,status,options);{espera que el proceso hijo de su salida}
 end;
end;

procedure redireccionarOUT(comando:string;ruta1:string;ruta2:string;rutaArchivo:string);
var 
 pid:Tpid;
 options,status: longint;
 rutaAEjecutar:string;

begin
 pid:=fpFork;
 options:=0;
 status:=0;
 case pid of
  -1:Writeln('Error');
   0: begin       
        if comando='ls-l' then
         begin
          Fpclose(1); {cierra el descriptor de archivo 1 que es la salida estandar}
          fpOpen(rutaArchivo,O_WrOnly or O_Creat);{el fpOpen le va a asignar el descriptor 1 ya que esta desocupado}
          lsl(ruta1);
         end;
        if comando='ls-' then
         begin
          Fpclose(1); 
          fpOpen(rutaArchivo,O_WrOnly or O_Creat);
          ls(ruta1);
         end;
        if comando='ls-a' then
         begin
          Fpclose(1); 
          fpOpen(rutaArchivo,O_WrOnly or O_Creat);
          lsa(ruta1);
         end;
        if comando='ls-f' then
         begin
          Fpclose(1); 
          fpOpen(rutaArchivo,O_WrOnly or O_Creat);
          lsf(ruta1);
         end;
        if comando='cat' then
         begin
          Fpclose(1); 
          fpOpen(rutaArchivo,O_WrOnly or O_Creat);
          concatenar(ruta1,ruta2)
         end     
        else 
         begin
          buscarEnPath(comando,rutaAEjecutar);
          if rutaAEjecutar <>'' then
            begin
             Fpclose(1); 
             fpOpen(rutaArchivo,O_WrOnly or O_Creat);
             ejecutar(rutaAEjecutar,ruta1);
            end
          else
            writeln(comando,':  no se encontro la orden');
         end;
       fpExit(1);
      end
   else
    fpWaitpid(pid,status,options);{espera que el proceso hijo de su salida}
 end;
end;

procedure kill(parametro1:string;parametro2:string);
var
 ctrl,i,int, proceso,senial,aux,aux1,c: longint;
 a:tvector2;
 aux2,aux3:string;

begin
val (parametro2,aux,c); {hacemos 2 val para transformar los parametros de string a entero}
val (parametro1,aux1,c);
aux2:=parametro1;
if (aux1=0) or (aux2[1]='-') then  {Si es 0, puede suceder que al val se le paso una cadena que no estaba compuesta de numeros (ej: 'hola').}
 begin                            {Con lo mencionado anteriormente se contempla si se pasa el nombre de una señal, ya sea por ej -SIGUSR1}    
  aux3:='';                        {usamos un aux3 para recortar el '-' y obtener el valor numerico que si existe sera usado mas adelante}
  ctrl:=length(aux2);
  for i:=2 to ctrl do
   aux3:=aux3+aux2[i];   
  if not ((aux3>'1') and (aux3<'30')) then    {si el aux3 no esta entre '1' y '30' debe buscar el nombre de la señal en el vector de señales}
   begin
    crearvector(a);                    {antes que todo hay que crear el vector de señales}
    aux1:=buscarsenial(a,parametro1);  {el buscar señal busca si el nombre de la señal es valido y si lo es nos devuelve el valor numerico de la señal. En caso de no existir se devuelve valor numerico 0, cosa de que el fpkill nos diga que la señal no es valida}
   end
  else 
   begin
    val (aux3,int,c);  {se hace la transformacion a entero en caso de que el aux3 tenga un string que este entre '1' o '30'}
    aux1:=int;
   end;		      
  proceso:=aux;   
  senial:=aux1;
  fpkill(proceso, senial);	 {se envia la señal}
  if fpGetErrno=1 then       {con fpgeterrno obtenemos un entero, que dependiendo de este si es 0 funciono correctamente, en caso contrario devuelve uno de los siguientes errores}
   writeln('The effective userid of the current process doesn’t math the one of process Pid');
  if fpGetErrno=22 then
   writeln('Señal invalida');
  if fpGetErrno=3 then
   writeln('El pid o grupo de procesos no existe');	  	 
 end
else
 begin
  if aux=0 then   {si el segundo parametro es vacio, se envia la señal estandar al proceso especificado}
   begin
    proceso:=aux1;  
    senial:=13;   {se asigna el valor de la señal estandar}
    fpkill(proceso, senial);
    if fpGetErrno=1 then
     writeln('The effective userid of the current process doesn’t math the one of process Pid');
    if fpGetErrno=22 then
     writeln('Señal invalida');
    if fpGetErrno=3 then
     writeln('El pid o grupo de procesos no existe');
   end
  else      {si ambos parametros son numeros, es decir el val del comienzo pudo transformarlos correctamente, se envia la señal estandar a ambas PID.}
   begin
    proceso:=aux;
    senial:=aux1; 
    fpkill(proceso, 13);
    if fpGetErrno=1 then
     writeln('El pid o grupo de procesos no existe');
    if fpGetErrno=22 then
     writeln('Señal invalida');
    if fpGetErrno=3 then
     writeln('The effective userid of the current process doesn’t math the one of process Pid');
    fpkill(senial, 13);
    if fpGetErrno=1 then
     writeln('The effective userid of the current process doesn’t math the one of process Pid');
    if fpGetErrno=22 then
     writeln('Señal invalida');
    if fpGetErrno=3 then
     writeln('El pid o grupo de procesos no existe');
   end;
 end;
end;


procedure cd(ruta:string;var rutaAcumulada:string);

begin
 if ruta[1]='/' then {si comienza con '/' es porque es una ruta absoluta}
  begin
   if fpChdir(ruta)=0 then 
    begin  
     rutaAcumulada:='';       
     rutaAcumulada:=ruta;
    end
   else
    writeln('cd: ',ruta,': No existe el archivo o el directorio');
  end
 else
  begin
   if rutaAcumulada='/' then
    rutaAcumulada:='';
   ruta:='/'+ruta;
   if fpChdir(rutaAcumulada+ruta)=0 then {al no ser una ruta absoluta concatena la rutaAcumulada con el nombre del directorio}
    rutaAcumulada:=rutaAcumulada+ruta
   else
    writeln('cd: ',ruta,': No existe el archivo o el directorio');
  end;      
end;  

procedure concatenar(a,b:string);

const
 n=249;

var
 text1,text2:Longint;
 s1,s2:Stat;
                        
procedure muestra(text:longint;t:cardinal);

var
 j,x,i,pos:cardinal;
 b:char;
 v:array[0..n]of byte;
 ac:string;
 datos:byte;
   
begin 
 ac:='';
 pos:=0;
 j:=0;
 x:=n;
 while pos <= (t-1) do {Hace un ciclo para mostrar todos lo elementos del archivo}
    begin
     while (pos <= (t-1)) and (j <= x) do {Este ciclo es para escribir el vector que funciona como un buffer}
       begin  
        FpLSeek(text,pos,Seek_Set);
        FpRead(text,datos,1);
        v[j]:=datos;
        pos:= pos +1;
        j:= j+1;
       end;     
     if j>x then {En caso que no se halla listado todo el archivo y el buffer este lleno muestra el contenido del buffer y sigue el ciclo}
      begin 
       for i:=0 to x do
        begin
         b:=chr(v[i]);
         ac:= ac + b;            
        end;
       j:=0;
       write(ac);
       ac:='';
      end
     else
      begin
       for i:=0 to j-1 do {En caso que se alcance el tamaño del archivo, estando lleno o no el buffer, muestra su contenido y termina el ciclo}
        begin
         b:=chr(v[i]);
         ac:= ac + b; 
        end;
         write(ac);
         ac:='';  
      end;
    end;
end;

begin
 text1:= fpOpen(a,O_RdOnly);
 text2:= fpOpen(b,O_RdOnly);
 if (text2 > 0) and (text2 > 0) then {Concatena 2 archivos}
  begin
   FpStat(a,s1);
   muestra(text1,s1.st_size);
   fpClose(text1);
   FpStat(b,s2);   
   muestra(text2,s2.st_size);
   fpClose(text2);
  end
 else
  begin
   if (text2 < 0) and (text1 > 0) then {Concatena 1 archivos, el del primer parametro, segun si existe y esta vacio, o no existe el segundo}
    begin
     FpStat(a,s1);
     muestra(text1,s1.st_size);
     fpClose(text1); 
    end
   else
    begin   
     if (text2 > 0) and (text1 < 0) then {Concatena 1 archivos, el del segundo parametro, segun si existe y esta vacio, o no existe el primero}
      begin
       FpStat(b,s2);
       muestra(text2,s2.st_size);
       fpClose(text2);
      end
     else  
      writeln('Cat: Error al ejecutar'); {muestra error si no hay parametros o los dos no son archivos}
    end;
  end; 
end;
procedure ejecutar(ruta:string; opciones:string);

var 
senialAMandar: cint;
	 cod: word;
pid:tpid;
pidHijo:integer;
 options: longint;
 status:longint;
caracter:char;
UEPID:string;
begin

pidHijo:=0;
caracter:='a';
 options:=0;
 status:=0;
clrscr;
 pid:=fpFork;

 case pid of
  -1:Writeln('Error');
   0: 	
		begin			
			fpExecl(ruta,[opciones]);
		end;

   else
	begin
			pidHijo:=pid;
			ultimoEjecutadoPID:=IntToStr(pidHijo);
			UEPID:=IntToStr(pidHijo);
			standby(UEPID,ruta,1);			

	end;
 end;


end;



procedure externo(ruta:string; opciones:string);

var 
senialAMandar: cint;
	 cod: word;
pid:tpid;
 options: longint;
pidHijo:integer;
 status:longint;
caracter:char;
UEPID:string;
aux1:ansiString;

SS: array of ansiString;

begin
aux1:=opciones;
setLength(SS,1);
SS[0]:=aux1;
 options:=0;
 status:=0;
 pid:=fpFork;


 case pid of
  -1:Writeln('Error');
   0: 	
		begin
			if (opciones = '') then			
			FpExecLP(ruta,[])
			else
			FpExecLP(ruta,SS)
		end;

   else
	begin
			fpWaitPid(pid,status,options);	
	end;
 end;


end;

procedure lsl(ruta:string);
var
 aux,permisos,espacio,puntos,nlink,size,day,hour,minute: string;
 archivo: Stat; 
 directorio: Pdir;
 entrada: PDirent;
 time: TDateTime;
 aYear,aMonth,ADay,Ahour,AMinute,ASecond,AMilliSecond:word;
 registro:reg;
 vector:tVector;
 i,j:Integer;

begin
fillchar(vector,sizeof(vector),#0);{inicializa el vector}
directorio:= fpOpenDir(ruta);{abre el directorio con la funcion fpOpenDir con la ruta pasada como parametro}
if (directorio<>nil) then
 begin
 i:=0;
 repeat  
    entrada:= fpReadDir(directorio^);{devuelve un puntero al directorio tratado}
    if entrada <> nil then
     with entrada^ do
      begin
       aux:=pchar(@d_name[0]);
       if aux[1]<>'.' then {si el nombre del archivo empieza con . es porque esta oculto entonces no se lista}
        begin        
          if fpLStat(aux,archivo)=0 then
           begin
            permisos:='';
            permisos:=calcularPermisos(IntToBin(archivo.st_mode,16,0));{esta funcion devuelve los permisos que tiene el archivo}
            if fpS_ISLNK(archivo.st_mode) then {si es un enlace}
             registro.color:=15; {color blanco}
            if fpS_ISREG(archivo.st_mode) then {si es un archivo normal}
             registro.color:=12;{color rojo}
            if fpS_ISDIR(archivo.st_mode) then {si es directorio}
             registro.color:=10; {color verde}
            if permisos[10]='x'then {si la cadena de permisos termina con 'x' y comienza con '-' es ejecutable}
             if permisos [1]='-' then
              registro.color:=9; {color azul}  
           end;          
            time:=UnixToDateTime(archivo.st_mtime);{transforma la hora en tipo unix a TDateTime}
            DecodeDateTime(time,AYear,AMonth,ADay,AHour,AMinute,ASecond,AMilliSecond);{decodifica el tiempo separando en año,mes,dia,hora,minutos}
            espacio:='  ';
            puntos:=':';
            str(archivo.st_nlink,nlink);
            str(archivo.st_size,size);{transforma a string}
            str(ADay,day);
            str(AHour,hour);
            str(aMinute,minute);
            registro.info:=permisos+espacio+nlink+espacio+getGroupName(archivo.st_gid)+espacio+getUserName(archivo.st_uid)+espacio+size+espacio+mes(aMonth)+espacio+day+espacio+hour+puntos+minute; {guarda en el campo info la cadena que contiene la informacion del archivo}
            registro.nombre:=strpas(pchar(@d_name[0]));{guarda en el campo nombre el nombre del archivo}
            registro.nombreMay:=UpCase(strpas(pchar(@d_name[0])));{guarda en el campo nombreMay el nombre del archivo en mayuscula}
            vector[i]:=registro;{guarda el registro con la informacion del archivo en un vector}
            i:=i+1;      
        end;
      end;  
 until entrada = nil;
burbuja(vector);{ordena el vector por el campo nombreMay}
for j:=1 to i-1 do
 begin
  textcolor(vector[j].color);
  writeln(vector[j].info,' ',vector[j].nombre); {lista por pantalla la informacion alojada en el vector}
 end;
fpCloseDir(directorio^);{cierra el directorio}
textcolor(white);
end;
end;

procedure lsa(ruta:string);
var
 aux,permisos: string;
 archivo: Stat; 
 directorio: Pdir;
 entrada: PDirent;
 i,j: integer;
 registro: reg;
 vector:tVector;
begin
fillchar(vector,sizeof(vector),#0);
directorio:= fpOpenDir(ruta);
 if (directorio<>nil) then
  begin   
   i:=1;
   repeat  
    entrada:= fpReadDir(directorio^);
    if entrada <> nil then
     with entrada^ do
      begin
       aux:=pchar(@d_name[0]);
        if fpLStat(aux,archivo)=0 then
         begin
          permisos:='';
          permisos:=calcularPermisos(IntToBin(archivo.st_mode,16,0));
           if fpS_ISLNK(archivo.st_mode) then 
            registro.color:=15; {color blanco}
           if fpS_ISREG(archivo.st_mode) then
            registro.color:=12; {color rojo}
           if fpS_ISDIR(archivo.st_mode) then
            registro.color:=10; {color verde}
           if permisos[10]='x'then {si la cadena de permisos termina con 'x' y comienza con '-' es ejecutable}
            if permisos [1]='-' then
             registro.color:=9 {color azul}
         end;
       registro.nombre:=strpas(pchar(@d_name[0]));
       registro.nombreMay:=UpCase(strpas(pchar(@d_name[0])));
       vector[i]:=registro;
       i:=i+1;
      end;
   until entrada = nil;
   burbuja(vector);
   for j:=1 to i-1 do
    begin
     textcolor(vector[j].color);
     writeln(vector[j].nombre);
    end;
   fpCloseDir(directorio^);
   textcolor(white);
  end;
end;

procedure ls(ruta:string);

var
 aux,permisos: string;
 archivo: Stat; 
 directorio: Pdir;
 entrada: PDirent;
 i,j: integer;
 registro: reg;
 vector:tVector;


begin
fillchar(vector,sizeof(vector),#0);
directorio:= fpOpenDir(ruta);
 if (directorio<>nil) then
  begin   
   i:=1;
   repeat  
    entrada:= fpReadDir(directorio^);
    if entrada <> nil then
      with entrada^ do
       begin 
        aux:=pchar(@d_name[0]);
        if aux[1]<>'.' then
         begin
           if fpLStat(aux,archivo)=0 then
            begin
             permisos:='';
             permisos:=calcularPermisos(IntToBin(archivo.st_mode,16,0));
             if fpS_ISLNK(archivo.st_mode) then 
              registro.color:=15; {color blanco}
             if fpS_ISREG(archivo.st_mode) then
              registro.color:=12; {color rojo}
             if fpS_ISDIR(archivo.st_mode) then
              registro.color:=10; {color verde}
             if permisos[10]='x'then
              if permisos [1]='-' then
               registro.color:=9 {color azul}
            end;
          registro.nombre:=strpas(pchar(@d_name[0]));
          registro.nombreMay:=UpCase(strpas(pchar(@d_name[0])));
          vector[i]:=registro;
          i:=i+1;
         end;
    end;
   until entrada = nil;
   burbuja(vector);
   for j:=1 to i-1 do
    begin
     textcolor(vector[j].color);
     Writeln(vector[j].nombre);
    end;
   fpCloseDir(directorio^);
   textcolor(white);
  end;
end;

procedure lsf(ruta:string);
var
 aux,permisos,arch: string;
 archivo: Stat; 
 directorio: Pdir;
 entrada: PDirent;
i,j:integer;
registro:reg;
 vector:tVector;

begin
 fillchar(vector,sizeof(vector),#0);
 directorio:= fpOpenDir(ruta);
 if (directorio<>nil) then
 begin
  i:=1;
  repeat  
    entrada:= fpReadDir(directorio^);
    if entrada <> nil then
     with entrada^ do
      begin
       aux:=pchar(@d_name[0]);
       if aux[1]<>'.' then
        begin
          if fpLStat(aux,archivo)=0 then
           begin
            permisos:='';
            permisos:=calcularPermisos(IntToBin(archivo.st_mode,16,0));
            if fpS_ISLNK(archivo.st_mode) then 
              begin
               arch:='@';
               registro.color:=15; {color blanco}
              end;
            if fpS_ISDIR(archivo.st_mode) then
              begin
               arch:='/';
               registro.color:=10; {color verde}
              end;	
            if fpS_ISREG(archivo.st_mode) then
             begin
              arch:='';
              registro.color:=12; {color rojo}
             end;
            if permisos[10]='x'then
             if permisos [1]='-' then
              begin
               arch:='*';
               registro.color:=9; {color azul}
              end;
           end;
         registro.nombre:=strpas(pchar(@d_name[0]))+arch;
         registro.nombreMay:=UpCase(strpas(pchar(@d_name[0]))+arch);
         vector[i]:=registro;
         i:=i+1;
        end;
      end;
  until entrada = nil;
  writeln(i);
   burbuja(vector);
  for j:=1 to i-1 do
  begin
   textcolor(vector[j].color);
   writeln(vector[j].nombre);
  end;
  fpCloseDir(directorio^);
  textcolor(white);
 end;
end;

end.
