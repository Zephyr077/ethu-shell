unit utilidades;
interface
uses BaseUnix,Unix,strUtils,crt;
const
 n=10000;
type
reg = record
         info:string;
         nombre:string;
         color:byte;
         nombreMay:string;
         end;

Registro=Record
    senial:string;
    id:longint;
    end;  
registroPID = Record
	nombre:string;
	pid: string;	
	estado:string;
	end;	
	
 tvector2=Array[1..36]of Registro;

 tVector=array[1..n]of reg;

 vectorPath=array[1..500] of string;

 tVectorPID=Array[1..10] of registroPID;



function mes(unNumero:word):string;

procedure burbuja(var a:tVector);
function calcularPermisos(numero:string):string;
function cortar(cadena:string):string;{devuelve la cadena que se encuentra al final despues de '/'}
function acortarRuta(cadena:string):string;{corta la cadena empezando del final hasta encontrar un '/'}
procedure verificarSiEsExe(ruta:string;var existe:integer;var resultado:integer);
procedure analizarCadena(cadena:string;var arg1:string;var arg2:string;var arg3:string;var arg4:string;var arg5:string);
function buscarsenial(a:tvector2; senial:string):longint;
procedure crearvector(var a:tvector2);
procedure rutasPath(var vector:vectorPath;var numeroDeRutas:integer);
procedure buscarEnPath (archivo:string;var ruta:string);
function prompt(dir:string):string;
function verificarRedireccion(cadena:string):string;
procedure agregarPrograma(var tVectorProgramas:tVectorPID; programa:string; pid:string; estado: string);
function proximaPosicionLibre(vector: tVectorPID):byte;
procedure mostrarVectorProgramas(tVectorProgramas:tVectorPID);
procedure crearVectorProgramas(var tVectorProgramas:tVectorPID);
procedure modificarPrograma(var tVectorProgramas:tVectorPID;pid:string;estado:string);


implementation
uses pash;

procedure modificarPrograma(var tVectorProgramas:tVectorPID;pid:string;estado:string); //modifica a un estado nuevo
var i:byte;
begin

	i:=1;
		while (i<>11) do
			begin
				if ((tVectorProgramas[i].pid) = pid) then
					begin
							tVectorProgramas[1].estado:='';
							tVectorProgramas[1].estado:=estado;
					end;
				i:=i+1;
			end;
end;

procedure mostrarVectorProgramas(tVectorProgramas:tVectorPID); //el jobs del programa
var i:byte;

begin
	i:=0;
			for i:=1 to 10 do
				begin
					Writeln ('Proceso Numero ', i);
					Writeln ('Nombre: ', tVectorProgramas[i].nombre);
					Writeln ('PID: ', tVectorProgramas[i].pid);
					Writeln ('Estado: ', tVectorProgramas[i].estado);
				end;
end;

function proximaPosicionLibre(vector: tVectorPID):byte; //tira la proxima posicion libre
var i:byte;
begin
	i:=0;
	repeat
	i:=i+1;
	until ((vector[i].pid='') or (i=11));
proximaPosicionLibre:=i;
end;

procedure crearVectorProgramas(var tVectorProgramas:tVectorPID); //Inicialza vector de programas
var i:byte;

begin
i:=0;
	for i:=1 to 10 do
	 begin
		tVectorProgramas[i].nombre:= '';
		tVectorProgramas[i].pid:= '';
		tVectorProgramas[i].estado:= '';
	 end;
Writeln('Vector de programas inicializado.');
end;

procedure agregarPrograma(var tVectorProgramas:tVectorPID; programa: string;pid: string;estado: string);
var i:byte;  //Agrega un programa al vector de programas
begin
i:=0;

i:=proximaPosicionLibre(tVectorProgramas);
		if (i = 11) then
			writeln('Vector lleno')
		else
		begin
			tVectorProgramas[i].nombre:= programa;
			tVectorProgramas[i].pid:=pid;
			tVectorProgramas[i].estado:='Detenido';
		end;
end;



function verificarRedireccion(cadena:string):string;{verifica si en la cadena hay un simbolo de redireccion o pipe}
var 
 i:integer;

begin
 i:=1;
 while (i <= length(cadena)) and (cadena[i] <> '<') and (cadena[i] <> '>') and (cadena[i] <> '|') do
  i:=i+1;
 if i > length(cadena) then
  verificarRedireccion:=''{si no se encontro algun simbolo de redireccion devuelvo la cadena vacia}
 else
  verificarRedireccion:=cadena[i];{si encontro algun simbolo de redireccion devuelve el simbolo}
end;

function prompt(dir:string):string;
var
hostName,cadena:string;
begin
hostName:=GetHostName;
cadena:=hostname+':-'+dir+'$ ';{concatena el nombre el equipo con el directorio actual de trabajo}
prompt:=cadena;
end;

procedure buscarEnPath (archivo:string;var ruta:string);{busca si el archivo existe en el PATH}
var
 vector:vectorPath;
 num,control,j,existe,resultado:integer;
 rutaAEjecutar:string;

begin
 archivo:='/'+archivo;{agrega '/' delante del nombre del archivo }
 rutasPath(vector,num); {obtiene las rutas del PATH para hacer la busqueda}
 control:=0;
 j:=1;
 rutaAEjecutar:='';
 while (control=0) and (num >= j) do
  begin
   verificarSiEsExe(vector[j]+archivo,existe,resultado);{verifica si el archivo esta dentro del directorio (PATH) y si es ejecutable }
   if (existe=1) and (resultado=1) then {si el archivo existe y es ejecutable entonces a rutaAejecutar se le asigna la ruta completa para poder ejecutarse}
    begin
     control:=1;
     rutaAEjecutar:=vector[j]+archivo;
   end;
  j:=j+1;
 end;
ruta:=rutaAEjecutar {devuelve la ruta, si es vacia no se ejecuta nada porque el nombre del programa es incorrecto o no existe en el PATH,caso contrario ejecutara el programa}
 
end;

procedure rutasPath(var vector:vectorPath;var numeroDeRutas:integer);{Devuelve un array con el nombre de las rutas (directorios) que estan en el PATH}
var 
path,ac:string;
i,j:integer;
vec: vectorPath;

begin
 i:=1;
 j:=1;
 path:=fpGetenv('PATH');
 ac:='';
 while i<=length(path)  do
  begin
   if path[i]=':'then
    begin
     vec[j]:=ac;{inserta en la posicion j del array el acumulador que contiene un directorio}
     ac:='';
     j:=j+1;
    end
   else
    ac:=ac+path[i];{acumula hasta encontrar ':' que es el comienzo de otro directorio}
   i:=i+1;
  end;
 vec[j]:=ac;
 vector:=vec;
 numeroDeRutas:=j; {devuelve la cantidad de directorio que se encontraron en el PATH}
end;

procedure crearvector(var a:tvector2); {Para poder permitir que el usuario envie señales las cuales se identifican a traves de su nombre creamos un vector con las señales y sus valores numericos para poder usarlo en el kill ya que fpkill funciona con enteros}

begin
 fillchar(a,sizeof(a),#0);
 a[1].senial:='-SIGHUP';
 a[1].id:=1;
 a[2].senial:='-SIGINT';
 a[2].id:=2;
 a[3].senial:='-SIGQUIT';
 a[3].id:=3;
 a[4].senial:='-SIGILL';
 a[4].id:=4;
 a[5].senial:='-SIGABRT';
 a[5].id:=6;         
 a[6].senial:='-SIGFPE';
 a[6].id:=8;         
 a[7].senial:='-SIGKILL';
 a[7].id:=9;         
 a[8].senial:='-SIGSEGV';
 a[8].id:=11;         
 a[9].senial:='-SIGPIPE';
 a[9].id:=13;         
 a[10].senial:='-SIGALRM';
 a[10].id:=14;         
 a[11].senial:='-SIGTERM';
 a[11].id:=15;                 
 a[13].senial:='-SIGUSR1';
 a[13].id:=10;         
 a[14].senial:='-SIGUSR2';
 a[14].id:=12;                 
 a[15].senial:='-SIGCHLD';
 a[15].id:=17;         
 a[16].senial:='-SIGCONT';
 a[16].id:=18;         
 a[17].senial:='-SIGSTOP';
 a[17].id:=19;         
 a[18].senial:='-SIGSTP';
 a[18].id:=20;         
 a[19].senial:='-SIGTTIN';
 a[19].id:=21;         
 a[20].senial:='-SIGTTOU';
 a[20].id:=22;         
 a[21].senial:='-SIGBUS';
 a[21].id:=7;                  
 a[23].senial:='-SIGPROF';
 a[23].id:=27;         
 a[24].senial:='-SIGTRAP';
 a[24].id:=5;   
 a[25].senial:='-SIGURG';
 a[25].id:=23;                 
 a[27].senial:='-SIGVTALRM';
 a[27].id:=26;         
 a[28].senial:='-SIGXCPU';
 a[28].id:=24;         
 a[29].senial:='-SIGXFSZ';
 a[29].id:=25;         
 a[30].senial:='-SIGEMT';
 a[30].id:=6;         
 a[31].senial:='-SIGSTKFLT';
 a[31].id:=16;         
 a[32].senial:='-SIGLIO';
 a[32].id:=29;         
 a[33].senial:='-SIGPWR';
 a[33].id:=30;
 a[34].senial:='-SIGSTKFLT';
 a[34].id:=16;                  
 a[35].senial:='-SIGWINCH';
 a[35].id:=16;                  
 a[36].senial:='-SIGUNUSED';
 a[36].id:=31;   
end;


function buscarsenial(a:tvector2; senial:string):longint;

var resul,i:longint;

begin
 i:=1;
 while (i<=36) and (a[i].senial<> senial) do
  i:=i+1;
  if i>36 then
   resul:=0 {devuelve 0 en caso de que le pasemos el nombre de una señal que no existe}
  else
   resul:=a[i].id;
 buscarsenial:=resul
end;

procedure analizarCadena(cadena:string;var arg1:string;var arg2:string;var arg3:string;var arg4:string;var arg5:string);{analiza la cadena y la separa en argumentos distintos, cada argumento sera una cadena en la que se separa de otro argumento por un espacio (' ')}
var
i,long:integer;
ac1,ac2,ac3,ac4,ac5:string;

begin
 i:=1;
 ac1:='';
 ac2:='';
 ac3:='';
 ac4:='';
 ac5:='';
 long:=length(cadena);
 while (long >=i) and (cadena[i]=' ')do
  i:=i+1;
 while (long >=i) and (cadena[i]<>' ')do
   begin
    ac1:=ac1+cadena[i];
    i:=i+1;
   end;
  arg1:=ac1;
 while (long >=i) and (cadena[i]=' ')do
  i:=i+1;
 while (long >=i) and (cadena[i]<>' ')do
  begin
    ac2:=ac2+cadena[i];
    i:=i+1;
   end;
  arg2:=ac2;
 while (long >=i) and (cadena[i]=' ')do
  i:=i+1;
 while (long >=i) and (cadena[i]<>' ')do
  begin
    ac3:=ac3+cadena[i];
    i:=i+1;
   end;
  arg3:=ac3;
 while (long >=i) and (cadena[i]=' ')do
  i:=i+1;
 while (long >=i) and (cadena[i]<>' ')do
  begin
    ac4:=ac4+cadena[i];
    i:=i+1;
   end;
  arg4:=ac4;
 while (long >=i) and (cadena[i]=' ')do
  i:=i+1;
 while (long >=i) and (cadena[i]<>' ')do
  begin
    ac5:=ac5+cadena[i];
    i:=i+1;
   end;
  arg5:=ac5;
end;


procedure verificarSiEsExe(ruta:string;var existe:integer;var resultado:integer);{verifica si la ruta entrante es un archivo Ejecutable}
var 
 nombre,permisos:string;
 dir: shortString;
 info: Stat; 
 directorio: Pdir;
 entrada: PDirent;
 i:integer;

begin
 resultado:=0;
 existe:=0;
 dir:='';
 nombre:=cortar(ruta);{la funcion cortar devuelve el nombre del archivo}
 for i:=1 to length(ruta)-length(nombre)-1 do {cicla desde 1 hasta la diferencia de la longitud de la ruta y la longitud del nombre del archivo}
  dir:=dir+ruta[i];{obtiene el directorio para ver si existe el archivo}
 directorio:= fpOpenDir(dir);{abre el directorio}
 if (directorio<>nil) then
  begin
   repeat 
    entrada:= fpReadDir(directorio^);
    if entrada <> nil then
      with entrada^ do
        begin
         if fpLStat(ruta,info)=0 then
          begin 
           if nombre=pchar(@d_name[0]) then
            begin
             existe:=1;
             permisos:='';
             permisos:=calcularPermisos(IntToBin(info.st_mode,16,0)); 
             if permisos[10]='x'then {si la cadena de permisos termina con 'x' y comienza con '-' es ejecutable}
              if permisos [1]='-' then
               resultado:=1;
            end;
          end;
        end; 
   until entrada=nil;
  end;
end;

function acortarRuta(cadena:string):string;{recorta la cadena entrante empezando por el final hasta encontrar '/'}
var
i,j:longint;
aux:string;

begin
 aux:='';
 i:=length(cadena);
 if cadena='/'then 
  acortarRuta:='/'
 else
  begin
   while (length(cadena)>1) and (cadena[i]<>'/') do
    begin
     cadena[i]:=' ';{le va asignado espacios vacios para ir borrando la ultima parte de la cadena hasta encontrar '/'}
     i:=i-1;
    end;
   if i=1 then
    acortarRuta:='/'
   else
    begin
     cadena[i]:=' ';
     for j:=1 to i-1 do {se hace este ciclo para que los espacios vacios asignados anteriormente no formen parte de la cadena a devolver por la funcion}
      aux:=aux+cadena[j];
     acortarRuta:=aux;
    end;
  end;
end;

function cortar(cadena:string):string; {recorta el nombre de la cadena que esta al final despues de '/'}
var
 pos,lon,j:longint;
 ac:string;

begin
 if cadena='' then
  cortar:=''
 else
  begin
   ac:='';
   lon:=length(cadena);
   pos:=lon;
   while cadena[lon] <>'/' do
    begin
     pos:=pos-1;
     lon:=lon-1;
    end;
   for j:= pos+1 to length(cadena) do
    ac:=ac+cadena[j];
   cortar:= ac;
  end;
end;


procedure burbuja(var a:tVector);{ordena el vector entrante por el campo nombreMay(nombre en mayuscula)}
var 
 i,j:cardinal;
 aux:reg;

begin
 for i:=1 to n-1 do
  for j:=1 to n-i do
   if (a[j].nombreMay>a[j+1].nombreMay) and (a[j+1].nombreMay<>'')then
    begin
     aux:=a[j];
     a[j]:=a[j+1];
     a[j+1]:=aux;    
    end;
end;

function calcularPermisos(numero:string):string;{el parametro (numero) es un numero en binario}
var i:integer;
    cadena,aux:string;
begin
 cadena:='';
  if numero[1]='1' then
   cadena:='-'
  else
   cadena:='d';
  for i:=1 to 3 do
   begin
    case i of
     1:aux:=numero[8]+numero[9]+numero[10];
     2:aux:=numero[11]+numero[12]+numero[13];
     3:aux:=numero[14]+numero[15]+numero[16];
   end;
    if aux='000' then
     cadena:=cadena+'---'
      else 
        begin 
          if aux='001' then
           cadena:=cadena+'--x'
          else 
            begin 
             if aux='011' then
               cadena:=cadena+'-wx'
             else
              begin  
               if aux='111' then
                cadena:=cadena+'rwx'
               else 
                begin 
                 if aux='100' then
                  cadena:=cadena+'r--'
                 else
                  begin  
                   if aux='101' then
                    cadena:=cadena+'r-x'
                   else
                    begin  
                     if aux='110' then
                      cadena:=cadena+'rw-'
                     else 
                      begin 
                       if aux='010' then
                        cadena:=cadena+'-w-';
                      end;
                    end;
                  end;
                end;
              end;
            end;
        end;
calcularPermisos:=cadena;
end;
end;

function mes(unNumero:word):string;
begin
 case unNumero of
  1: mes:='Ene';
  2: mes:='Feb';
  3: mes:='Mar';
  4: mes:='Abr';
  5: mes:='May';
  6: mes:='Jun';
  7:mes:='Jul';
  8: mes:='Ago';
  9: mes:='Sep';
  10:mes:='Oct';
  11:mes:='Nov';
  12:mes:='Dic';
 end;
end;

end.
