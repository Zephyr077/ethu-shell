unit pash;
interface
uses BaseUnix,Unix,crt,SysUtils,DateUtils,strutils,utilidades,comandos;
var tVectorProgramas:tVectorPID;
ultimoEjecutadoPID:string;

procedure ejecutarShell;

implementation



procedure ejecutarShell;
var

 pausar:cint;
 cadena,arg1,arg2,arg3,arg4,arg5,rutaAcumulada,rutaAEjecutar:string;
 esExe,existe:integer;
begin
crearVectorProgramas(tVectorProgramas);
 write(prompt(''));
 rutaAcumulada:='/home';   {Inicia con esta ruta} 
 cadena:='';
 while cadena <> 'exit' do
 begin
  cadena:='';	
	
  readln(cadena);
  if verificarRedireccion(cadena)='' then {si dentro de la cadena no existe un simbolo de redireccion sigue el camino siguiente}
  begin
   analizarCadena(cadena,arg1,arg2,arg3,arg4,arg5);{analiza la cadena y devuelve los distintos argumentos, cada argumento esta separado por un espacio}
		begin
		if (arg1 = 'p') then
			begin
				if (arg2 = '') then
				 begin
						pause(ultimoEjecutadoPID);
				 end
				 else
				 begin
					pause(arg2);
				end;
			end
		else
		begin
		 if (arg1 = 'fg') then
			begin
						if (arg2 = '') then
							begin
								fg(ultimoEjecutadoPID);
							end
							else
							begin
								fg(arg2);
							end;
			end

		else
		 if (arg1 = 'bg') then
			begin
					if (arg2 = '') then
						begin
							bg(ultimoEjecutadoPID);
						end
						else
						begin
							bg(arg2);
						end;
		end
		else
		if (arg1 = 'jobs') then
			begin
				mostrarVectorProgramas(tVectorProgramas);
			end
else

begin

    if arg1='cd' then
     begin
       if (length(arg2)=2) and (arg2[1]='.') and (arg2[2]='.') then {para ver si ingreso 'cd ..'}
         cd(acortarRuta(rutaAcumulada),rutaAcumulada)   
       else
         cd(arg2,rutaAcumulada);
     end
    else
     begin
      if arg1= 'ls-' then
       begin
        if arg2='' then
         ls(rutaAcumulada)
        else
         begin
          if fpChDir(arg2) = 0 then
           ls(arg2)
          else
           writeln('ls: no se puede acceder a ese directorio');
         end;
       end
      else
       begin 
        if arg1= 'ls-l' then 
         begin
          if arg2='' then
           lsl(rutaAcumulada)
          else
           begin
            if fpChDir(arg2) = 0 then
             lsl(arg2)
            else
             writeln('ls: no se puede acceder a ese directorio');
           end;
         end
        else
         begin
          if arg1='ls-a' then
           begin
            if arg2='' then
             lsa(rutaAcumulada)
             else
              begin
               if fpChDir(arg2) = 0 then
               lsa(arg2)
               else
                writeln('ls: no se puede acceder a ese directorio');
              end;
           end
          else
           begin
            if arg1='ls-f' then
             begin
              if arg2='' then
               lsf(rutaAcumulada)
              else
               begin
                if fpChDir(arg2) = 0 then
                 lsf(arg2)
                else
                 writeln('ls: no se puede acceder a ese directorio');
               end;
             end
            else
             begin
              if arg1='pwd' then
               writeln(rutaAcumulada)
              else
               begin
                if arg1='cat' then
                 concatenar(arg2,arg3)
                else
                 begin
                  if arg1='kill' then
                    kill(arg2,arg3)
                  else
                   begin
                    if arg1='exit' then
                     cadena:='exit'
                    else 
                     begin
                      if arg1 <>'' then {pongo esto para que si doy ENTER sin escribir nada no me salte que "no existe el archivo"}
                       if arg1[1]='/' then  
                        begin            
                         verificarSiEsExe(arg1,existe,esExe);
                          if (existe=1) and (esExe=1) then 
                            ejecutar(arg1,arg2)
                          else
                           begin
                            if existe=1 then
                             writeln('Permiso denegado')
                            else
                             writeln('No existe el archivo');
                           end;
                        end                    
                       else 
                        begin
                         verificarSiEsExe(rutaAcumulada+'/'+arg1,existe,esExe);
                          if (existe=1) and (esExe=1) then  
                          ejecutar(rutaAcumulada+'/'+arg1,arg2)
                          else
                           begin
                            buscarEnPath(arg1,rutaAEjecutar);
                            if rutaAEjecutar <>'' then
                           	 externo(rutaAEjecutar,arg2)
                            else
                             writeln('No se encontro la orden');
                           end;
                        end;
                     end;
                   end;
                 end;
               end;
             end; 
           end; 
         end;
       end;
	end;
  end;
end;
end;
end
  else
   begin
    analizarCadena(cadena,arg1,arg2,arg3,arg4,arg5);
     if (arg2='<') and (arg1='cat') then
       redireccionarIN(arg1,arg3)
     else
      begin
       if (arg3='|') then
          pipe(arg1,arg2,arg4,arg5)
       else
        begin
         if (arg2='|') then
          pipe(arg1,'',arg3,arg4)
         else
          begin
           if (arg2='>') and ((arg1='ls-') or (arg1='ls-a') or (arg1='ls-l') or (arg1='ls-f')) then
            redireccionarOUT(arg1,rutaAcumulada,'',arg3)
           else
            begin
             if (arg3='>') and ((arg1='ls-') or (arg1='ls-a') or (arg1='ls-l') or (arg1='ls-f')) then
              redireccionarOUT(arg1,arg2,'',arg4)
             else
              begin
               if (arg3='>') and (arg1='cat') then
                redireccionarOUT(arg1,arg2,'',arg4)
               else
                begin
                 if (arg4='>') and (arg1='cat') then
                  redireccionarOUT(arg1,arg2,arg3,arg5)
                 else
                  begin
                   if (arg2[1]='-') then
                    redireccionarOUT(arg1,arg2,'',arg4)
                   else
                    redireccionarOUT(arg1,'','',arg3);
                  end;
                end;             
              end;
            end;
          end;
        end;
      end;
   end; 
 if cadena <>'exit' then
   write(prompt(rutaAcumulada));
   arg1:='';
   arg2:='';
   arg3:='';
   arg4:='';
   arg5:='';



end;

end;
end.
