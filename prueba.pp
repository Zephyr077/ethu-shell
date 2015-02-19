program prueba;
uses crt,BaseUnix;
var j:integer;

begin

for j:= 1 to 10000 do
begin
		Delay(500);
		writeln(j);
		writeln('Soy el proceso PRUEBA y Te digo mi PIDpor las dudas: ', fpgetpid);

end;

end.
