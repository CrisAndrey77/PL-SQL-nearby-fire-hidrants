PROMPT BIENVENIDO AL REGISTRO DE INSTALACION DE UN HIDRANTE
PROMPT POR FAVOR INGRESE EL NUMERO DE LA SOLICITUD
ACCEPT xSol PROMPT      "NUMERO DE SOLICITUD: "

PROMPT POR FAVOR INGRESE LA UBICACION DEL HIDRANTE
ACCEPT xLat NUMBER PROMPT "LATITUD: "
ACCEPT xLon NUMBER PROMPT "LONGITUD: "
ACCEPT xCalle NUMBER PROMPT "CALLE: "
ACCEPT xAvenida NUMBER PROMPT	"AVENIDA: "

PROMPT POR FAVOR INGRESE LOS DIAMETROS DE CADA BOQUILLA (0 SI NO APLICA)
ACCEPT xBoq1 NUMBER PROMPT		"BOQUILLA NUMERO 1: " DEFAULT 0
ACCEPT xBoq2 NUMBER PROMPT		"BOQUILLA NUMERO 2: " DEFAULT 0
ACCEPT xBoq3 NUMBER PROMPT		"BOQUILLA NUMERO 3: " DEFAULT 0
ACCEPT xBoq4 NUMBER PROMPT		"BOQUILLA NUMERO 4: " DEFAULT 0

PROMPT POR FAVOR INGRESE EL CAUDAL DEL HIDRANTE
ACCEPT xCaud NUMBER PROMPT		"CAUDAL  : " DEFAULT 100


EXECUTE Bomberos.registroTrabajoInstalacion(&xSol, &xLat, &xLon, &xCalle, &xAvenida, &xCaud, &xBoq1, &xBoq2, &xBoq3, &xBoq4,0);

@D:\P1\MENU_PRINCIPAL

