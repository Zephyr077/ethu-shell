program prueba2;
uses crt,BaseUnix,Unix;
var
j:integer;
begin
for j:= 1 to 10000 do
begin
Delay(500);
writeln(j);
writeln('Soy el proceso PRUEBA2 y Te digo mi PIDpor las dudas: ', fpgetpid);
end;
end.
