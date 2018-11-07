--BOQUILLAS
CREATE OR REPLACE TYPE arrayBoquillas IS VARRAY(4) OF integer;
--


--OBJETO TIPO GPS
CREATE OR REPLACE TYPE GPS AS OBJECT(
	latitud float,
	longitud float,
	calle varchar2(100),
	avenida varchar2(100)
);
--

--OBJETO TIPO HIDRANTE
CREATE OR REPLACE TYPE Hidrante AS OBJECT(
	ubicacion GPS,
	caudal float,
	boquillas arrayBoquillas,
	estado integer
);
--

--ARRAY HIDRANTES
CREATE OR REPLACE TYPE arrayHidrantes is TABLE OF Hidrante;

--TABLA DE HIDRANTES
CREATE TABLE Hidrantes(
	numHidrante integer, 
	hidrante Hidrante,
	CONSTRAINT pkHidrante PRIMARY KEY (numHidrante)
);

CREATE SEQUENCE secNumHidrante 
START WITH 1
INCREMENT BY   1
NOCACHE 
NOCYCLE;


CREATE OR REPLACE TRIGGER triggerAutoINumHidrante
BEFORE INSERT ON Hidrantes
FOR EACH ROW
BEGIN
	SELECT secNumHidrante.NEXTVAL
	INTO :new.numHidrante
	FROM DUAL;
END;




--TABLA DE SOLICITUDES DE TRABAJO
CREATE TABLE SolicitudTrabajo(
	numSolicitud integer,
	tipoSolicitud integer,
	CONSTRAINT pkSolicitudT PRIMARY KEY (numSolicitud)
);
--

--TABLA DE REGISTROS DE TRABAJO
CREATE TABLE RegistroTrabajo(
	numRegistro integer,
	numSolicitud integer,
	numHidrante integer,
	CONSTRAINT pkRegistroT PRIMARY KEY (numRegistro),
	CONSTRAINT fkRegistroT FOREIGN KEY (numSolicitud) REFERENCES SolicitudTrabajo
);

CREATE SEQUENCE secSolicitudTrabajo
START WITH 1
INCREMENT BY   1
NOCACHE 
NOCYCLE;

CREATE SEQUENCE secRegistroTrabajo
START WITH 1
INCREMENT BY   1
NOCACHE 
NOCYCLE;

CREATE OR REPLACE TRIGGER triggerAutoINumSolicitud
BEFORE INSERT ON SolicitudTrabajo
FOR EACH ROW
BEGIN
	SELECT secSolicitudTrabajo.NEXTVAL
	INTO :new.numSolicitud
	FROM DUAL;
END;


CREATE OR REPLACE TRIGGER triggerAutoINumRegistro
BEFORE INSERT ON RegistroTrabajo
FOR EACH ROW
BEGIN
	SELECT secRegistroTrabajo.NEXTVAL
	INTO :new.numRegistro
	FROM DUAL;
END;


--CREACION DEL PAQUETE
CREATE OR REPLACE PACKAGE Bomberos AS
	hidranteAInsertar Hidrante;
	hidranteAModificar Hidrante;
	FUNCTION toRadian(valor float) RETURN float; 
	FUNCTION DistanciaPunto (P1 GPS, P2 GPS) RETURN float;
	FUNCTION insertaHidrante RETURN integer; 
	FUNCTION modificaHidrante(numHidrante integer) RETURN integer; 
	FUNCTION cercanos(punto GPS, arreglo arrayHidrantes, rango float) RETURN arrayHidrantes;
	PROCEDURE SolicitudTrabajoInstalacion;
	PROCEDURE SolicitudTrabajoMantenimiento;
	PROCEDURE registroTrabajoInstalacion(numSolicitud integer, latitud float,longitud float,calle varchar2, avenida varchar2,caudal float,boquilla1 float,boquilla2 float,boquilla3 float,boquilla4 float ,estado integer);
	PROCEDURE registroTrabajoMantenimiento(numSolicitud integer,numHidrante integer,caudal float,boquilla1 float,boquilla2 float,boquilla3 float,boquilla4 float,estado integer );
	PROCEDURE RPH(punto GPS, radioMax float);
END Bomberos;

--CUERPO DEL PAQUETE
CREATE OR REPLACE PACKAGE BODY Bomberos AS

--CONVIERTE FLOAT A RADIANES
FUNCTION toRadian(valor float) RETURN float IS
	PI float := 3.14159;
	resultado float;
BEGIN
	resultado := valor * PI /180;
	RETURN resultado;	
END toRadian;

--CALCULA LA DISTANCIA EN METROS ENTRE DOS PUNTOS
FUNCTION DistanciaPunto (P1 GPS, P2 GPS) RETURN float IS
	R float := 6371000;  					--Radio aproximado de la tierra
	lat1 float := toRadian(P1.latitud); 	--Latitud 1
	lat2 float := toRadian(P2.latitud); 	--Latitud 2
	lon1 float := toRadian(P1.longitud); 	--Latitud 1
	lon2 float := toRadian(P2.longitud); 	--Longitud 2
	pasoA float;
	pasoB float;
	pasoC float;
	distancia float;
BEGIN
	pasoA := SIN(lat1) * SIN(lat2);
	pasoB := COS(lat1) * COS(lat2);
	pasoC := pasoB * COS(lon2-lon1);
	distancia := ACOS(pasoA + pasoC);
	distancia := distancia * R;
	distancia := ROUND(distancia, 3);
	RETURN distancia;
END DistanciaPunto;



--INSERTA HIDRANTE
FUNCTION insertaHidrante RETURN integer IS
TYPE recursor IS REF CURSOR RETURN Hidrantes%ROWTYPE;
cr recursor;
filaTipo Hidrantes%ROWTYPE; 
retornoNumHidrante integer := -1;
BEGIN
	INSERT INTO Hidrantes (hidrante) VALUES (hidranteAInsertar);
	 IF sql%notfound THEN 
      dbms_output.put_line('Error al insertar hidrante');
	 ELSIF sql%found THEN 
	    --select * from ( select a.*, max(numHidrante) over () as max_pk from Hidrantes a) where numHidrante = max_pk;
		OPEN cr FOR SELECT * FROM Hidrantes WHERE numHidrante = ( SELECT MAX(numHidrante) FROM Hidrantes ); 
		LOOP
			FETCH cr INTO filaTipo;
			EXIT WHEN cr%NOTFOUND;
			retornoNumHidrante := filaTipo.numHidrante;
		END LOOP;
		CLOSE cr;		
     END IF; 
	 COMMIT;
     return retornoNumHidrante;
END insertaHidrante;



--MODIFICA EL HIDRANTE
FUNCTION modificaHidrante(numHidrante integer) RETURN integer IS
BEGIN

	dbms_output.put_line('ENTRO');
	UPDATE Hidrantes SET hidrante = hidranteAModificar WHERE Hidrantes.numHidrante = numHidrante;
	IF sql%notfound THEN 
		dbms_output.put_line('Error al modificar hidrante');
		return -1;
	ELSIF sql%found THEN 
	    dbms_output.put_line('Hidrante modificado con exito');
		return 1;
    END IF; 
    return -1;
	COMMIT;
END modificaHidrante;


--SOLICITUD TRABAJO INSTALACION
PROCEDURE SolicitudTrabajoInstalacion IS
BEGIN
   INSERT INTO SolicitudTrabajo (tipoSolicitud) VALUES (1);
   IF sql%notfound THEN 
      dbms_output.put_line('Error!');
   ELSIF sql%found THEN 
      dbms_output.put_line('Solicitud instalacion registrada!');
   END IF; 
   COMMIT;
END SolicitudTrabajoInstalacion;




--SOLICITUD MANTENIMIENTO
PROCEDURE SolicitudTrabajoMantenimiento IS
BEGIN
   INSERT INTO SolicitudTrabajo (tipoSolicitud) VALUES (2);
   IF sql%notfound THEN 
      dbms_output.put_line('Error!');
   ELSIF sql%found THEN 
      dbms_output.put_line('Solicitud mantenimiento registrada!');
   END IF; 
   COMMIT;
END SolicitudTrabajoMantenimiento;

--REGISTRO TRABAJO INST
PROCEDURE registroTrabajoInstalacion(numSolicitud integer, latitud float,longitud float,calle varchar2, avenida varchar2,caudal float,boquilla1 float,boquilla2 float,boquilla3 float,boquilla4 float ,estado integer) AS
ubicacion GPS := GPS(latitud,longitud,calle,avenida);
boquillas arrayBoquillas := arrayBoquillas(boquilla1,boquilla2,boquilla3,boquilla4);
numHidrante integer := -1;
BEGIN
   hidranteAInsertar := Hidrante(ubicacion,caudal,boquillas,estado);
   numHidrante := insertaHidrante;
   IF numHidrante = -1 THEN
		dbms_output.put_line('Error en el registro instalacion! 1');
   ELSE
		INSERT INTO RegistroTrabajo (numSolicitud, numHidrante) VALUES (numSolicitud, numHidrante);
		IF sql%notfound THEN 
			dbms_output.put_line('Error en el registro instalacion! 2');
		ELSIF sql%found THEN 
			dbms_output.put_line('Registro instalacion completo!');			
        END IF; 
   END IF;
   COMMIT;
END registroTrabajoInstalacion; 


--REGISTRO MANT
PROCEDURE registroTrabajoMantenimiento(numSolicitud integer,numHidrante integer,caudal float,boquilla1 float,boquilla2 float,boquilla3 float,boquilla4 float,estado integer ) IS
--TYPE recursor IS REF CURSOR RETURN Hidrantes%ROWTYPE;
CURSOR cr IS select * from Hidrantes where Hidrantes.numHidrante = numHidrante;
filaTipo Hidrantes%ROWTYPE; 
exito integer := -1;
boquillasTemp arrayBoquillas := arrayBoquillas(boquilla1,boquilla2,boquilla3,boquilla4);
BEGIN
	OPEN cr;
	FETCH cr INTO filaTipo;
	hidranteAModificar := filaTipo.hidrante;
	CLOSE cr;

	FOR i IN 1..4 LOOP
		IF boquillasTemp(i) <> 0 THEN
			hidranteAModificar.boquillas(i) := boquillasTemp(i);
		END IF;
    END LOOP;

	IF caudal <> 0 THEN
		hidranteAModificar.caudal := caudal;
	END IF;

	IF estado <> hidranteAModificar.estado THEN
		hidranteAModificar.estado := estado;
	END IF;

	exito := modificaHidrante(numHidrante);

	 IF exito = -1 THEN
		dbms_output.put_line('Error en el registro mantenimiento! 1');
     ELSE
		INSERT INTO RegistroTrabajo (numSolicitud, numHidrante) VALUES (numSolicitud, numHidrante);
		IF sql%notfound THEN 
			dbms_output.put_line('Error en el registro mantenimiento! 2');
		ELSIF sql%found THEN 
			dbms_output.put_line('Registro mantenimiento completo!');
        END IF; 
     END IF;
	 COMMIT;
END registroTrabajoMantenimiento;


--AGREGA A UNA LISTA SI ENCUENTRA HIDRANTES EN ESE RANGO
PROCEDURE RPH (punto GPS, radioMax float)
IS
	h Hidrante := Hidrante(GPS(0, 0, '', ''), 0, arrayBoquillas(0,0,0,0), 0);
	arreglo arrayHidrantes := arrayHidrantes();
	i integer;
	CURSOR crsr IS
		SELECT Hidrantes.hidrante into h FROM Hidrantes;
	arregloTemp arrayHidrantes;
BEGIN
	OPEN crsr;
	FETCH crsr INTO h;
	i := 1;
	WHILE crsr%FOUND LOOP
		arreglo.EXTEND;
		arreglo(i) := h;
		FETCH crsr INTO h;
		i := i+1;
	END LOOP;
	CLOSE crsr;	
	arregloTemp := cercanos(punto, arreglo, radioMax);
	--SE PUEDE MANEJAR EL ARREGLO;
END RPH;

--COMPLEMENTA A RPH, ES PARA REDUCIR EL TAMANHO DEL METODO
FUNCTION cercanos(punto GPS, arreglo arrayHidrantes, rango float)
RETURN arrayHidrantes
IS
	resultado arrayHidrantes := arrayHidrantes();
	distancia float;	
	temp GPS;
	contador integer := 1;
	hidranteTemp Hidrante:= Hidrante(GPS(-300, -300, '', ''), 0, arrayBoquillas(0, 0, 0, 0), 1);
	tempRango float := rango + 500;
BEGIN
	resultado.EXTEND;
	resultado(1) := hidranteTemp;

	FOR i IN arreglo.FIRST..arreglo.LAST LOOP
		temp := GPS(arreglo(i).ubicacion.latitud, arreglo(i).ubicacion.longitud, '', '');
		distancia := DistanciaPunto(punto, temp);
		IF (distancia <= rango) AND arreglo(i).estado = 0 THEN
			IF contador != 1 THEN
				resultado.EXTEND;
			END IF;

			resultado(contador) := arreglo(i);		
			dbms_output.put_line('SE ENCUENTRA UN HIDRANTE A ' || distancia || ' MTS, CON CAUDAL DE '|| arreglo(i).caudal || ' GAL/MIN EN LA CALLE ' || arreglo(i).ubicacion.calle || ' Y  AVENIDA ' || arreglo(i).ubicacion.avenida || ' COORDENADAS: ' || arreglo(i).ubicacion.latitud || ', ' || arreglo(i).ubicacion.longitud);
			contador := contador + 1;
		END IF;
	END LOOP;
		IF resultado(1).ubicacion.latitud = -300 THEN
			dbms_output.put_line('NO SE ENCONTRARON HIDRANTES POR FAVOR INTENTE CON UN NUEVO RANGO');
		END IF;
	RETURN resultado;
END cercanos;
END Bomberos; 


--EXECUTE Bomberos.registroTrabajoInstalacion(4,10,11,'maria','av1',1500,1000,2000,0,5000,1);
--EXECUTE Bomberos.registroTrabajoMantenimiento(5,2,0,10,10,10,0,1);


declare
	hidranteA Hidrante := Hidrante(GPS(-1, -1, '', ''), 30, arrayBoquillas(0,0,0,0),1);
BEGIN
	update Hidrantes set Hidrante = hidranteA where Hidrantes.numHidrante = 5;
end;
