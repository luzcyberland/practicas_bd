--ciclo con loop simple

DECLARE
	V_ID NUMBER;
	V_NOMBRE VARCHAR2(50);	
	CURSOR CUR_LOCALIDAD IS
		SELECT ID, NOMBRE FROM B_LOCALIDAD
		ORDER BY NOMBRE;	
BEGIN	
	OPEN CUR_LOCALIDAD;
	LOOP
		FETCH CUR_LOCALIDAD INTO V_ID, V_NOMBRE;
		EXIT WHEN CUR_LOCALIDAD%NOTFOUND;
		DBMS_OUTPUT.PUT_LINE('LOCALIDAD: '|| V_NOMBRE);
	END LOOP;
	CLOSE CUR_LOCALIDAD;
END;

--CICLO CON WHILE LOOP

DECLARE
	V_ID NUMBER;
	V_NOMBRE VARCHAR2(50);	
	CURSOR CUR_LOCALIDAD IS
		SELECT ID, NOMBRE FROM B_LOCALIDAD
		ORDER BY NOMBRE;	
BEGIN	
	OPEN CUR_LOCALIDAD;
	FETCH CUR_LOCALIDAD INTO V_ID, V_NOMBRE;
	WHILE CUR_LOCALIDAD%FOUND
	LOOP
		DBMS_OUTPUT.PUT_LINE('LOCALIDAD: '|| V_NOMBRE);
		FETCH CUR_LOCALIDAD INTO V_ID, V_NOMBRE;
	END LOOP;
	CLOSE CUR_LOCALIDAD;
END;

-- CICLO FOR LOOP

DECLARE

	CURSOR CUR_LOCALIDAD IS
		SELECT ID, NOMBRE FROM B_LOCALIDAD
		ORDER BY NOMBRE;	
BEGIN	
	FOR R_LOCALIDAD IN CUR_LOCALIDAD
	LOOP
		DBMS_OUTPUT.PUT_LINE('LOCALIDAD: '|| R_LOCALIDAD.NOMBRE);
	END LOOP;
END;

/* 			ejecitario
1- Desarrolle un PL/SQL anónimo que calcule la liquidación de salarios del mes de Agosto del 2018. El
PL/SQL deberá realizar lo siguiente:
- Insertar un registro de cabecera de LIQUIDACIÓN correspondiente a agosto del 2018.
- Recorrer secuencialmente el archivo de empleados y calcular la liquidación de cada empleado de
la siguiente manera:
	- salario básico = asignación correspondiente a la categoría de la posición vigente
	- descuento por IPS = 9,5% del salario
	- bonificaciónxventas= a la suma de la bonificación obtenida a partir de las ventas realizadas por ese empleado
	 en el mes de agosto del 2011 (la bonificación es calculada de acuerdo a los artículos vendidos).
-liquido = salario básico – descuento x IPS + bonificación (si corresponde).
Insertar la liquidación calculada en la PLANILLA con el ID de la cabecera de liquidación creada
 */

DECLARE
NEXT_ID B_LIQUIDACION.ID%TYPE;

CURSOR CUR_EMP IS
	SELECT E.CEDULA, CAT.ASIGNACION, CAT.ASIGNACION * 0.095 DESC_IPS, sum(DET.CANTIDAD*DET.PRECIO*A.PORC_COMISION) BONIF
	FROM B_EMPLEADOS E JOIN
	B_POSICION_ACTUAL  P ON 
	P.CEDULA = E.CEDULA JOIN
	B_CATEGORIAS_SALARIALES CAT ON 
	cat.COD_CATEGORIA =p.COD_CATEGORIA 
	RIGHT OUTER JOIN B_VENTAS V
	ON V.CEDULA_VENDEDOR  = E.CEDULA 
		JOIN B_DETALLE_VENTAS DET ON V.ID = DET.ID_VENTA 
		JOIN B_ARTICULOS A 
		ON A.ID = DET.ID_ARTICULO
	 	WHERE TRUNC(V.FECHA) BETWEEN TO_DATE('01/08/2018', 'DD/MM/YYYY') AND TO_DATE('31/08/2018', 'DD/MM/YYYY') 
		AND  P.FECHA_FIN IS NULL
		AND CAT.FECHA_FIN IS NULL
		GROUP BY E.CEDULA, CAT.ASIGNACION;
BEGIN

	INSERT INTO B_LIQUIDACION (ID, FECHA_LIQUIDACION, ANIO, MES)
	VALUES ((SELECT MAX(ID) +1 FROM B_LIQUIDACION), SYSDATE, EXTRACT (YEAR FROM SYSDATE),EXTRACT (MONTH FROM SYSDATE));
	COMMIT;
	FOR EMP IN CUR_EMP LOOP
		INSERT INTO B_PLANILLA (ID_LIQUIDACION , CEDULA, SALARIO_BASICO, DESCUENTO_IPS, BONIFICACION_X_VENTAS, LIQUIDO_COBRADO)
		VALUES((SELECT MAX(ID) FROM B_LIQUIDACION), EMP.CEDULA, EMP.ASIGNACION, EMP.DESC_IPS, EMP.BONIF,
		EMP.ASIGNACION -EMP.DESC_IPS+EMP.BONIF);
	COMMIT;
	END LOOP;
EXCEPTION 
	WHEN OTHERS THEN
		DBMS_OUTPUT.PUT_LINE('OCURRIO UN ERROR');
	END;

/* 2. Cree un bloque PL/SQL que mayorice los movimientos contables de febrero del 2012. Ud deberá
	o Recorrer las cuentas imputables del Plan de cuentas
	o Por cada cuenta, calcular el acumulado de débitos y créditos del periodo indicado
	o Insertar en el mayor calculando el id = id + el último id */
--SELECT * FROM B_DIARIO_DETALLE;
DECLARE
	CURSOR CUR_MOV IS
		SELECT C.CODIGO_CTA, SUM(DECODE(DD.DEBE_HABER , 'D', IMPORTE,0)) ACUM_DEBE,
		SUM(DECODE(DD.DEBE_HABER , 'C', IMPORTE,0)) ACUM_CREDI
		FROM B_DIARIO_CABECERA CAB
		JOIN B_DIARIO_DETALLE DD 
		ON CAB.ID = DD.ID 
		JOIN B_CUENTAS C ON 
		DD.CODIGO_CTA  = C.CODIGO_CTA 
		WHERE TRUNC(CAB.FECHA) BETWEEN TO_DATE('01/02/2019', 'DD/MM/YYYY') AND TO_DATE('28/02/2019')
		AND C.IMPUTABLE = 'S'
		GROUP BY C.CODIGO_CTA ;
BEGIN 
	FOR MOV IN CUR_MOV LOOP
	INSERT INTO B_MAYOR (ID_MAYOR, CODIGO_CTA, ANIO, MES, ACUM_CREDITO, ACUM_DEBITO)
	VALUES((SELECT MAX(ID_MAYOR) +1 FROM B_MAYOR), MOV.CODIGO_CTA, 2019, 02, MOV.ACUM_CREDI, MOV.ACUM_DEBE);
	COMMIT;
	END LOOP;
END;

/*3. Cree un bloque PL/SQL que haga lo siguiente:
o Declare un cursor que lea todas las localidades (B_LOCALIDAD)
o Declare el cursor C_CLIENTES que reciba como parámetro el id de la localidad, y que deberá
obtener el monto de ventas de cada cliente de dicha localidad (PERSONAS que son clientes).
La idea es procesar el cursor sobre la localidad e imprimir el nombre de la localidad, y por cada
iteración, abrir el cursor c_clientes e imprimir por cada cliente su Nombre y Apellido, y el monto
total de ventas:*/

DECLARE 
	CURSOR CUR_LOCALIDAD IS
		SELECT * FROM B_LOCALIDAD;
	CURSOR C_CLIENTES (LOC NUMBER) IS
		SELECT P.NOMBRE, P.APELLIDO , SUM(V.MONTO_TOTAL) TOTAL
		FROM B_PERSONAS P 
		JOIN B_VENTAS V 
		ON P.ID = V.ID_CLIENTE
		WHERE P.ID_LOCALIDAD = LOC 
		AND P.ES_CLIENTE = 'S'
		GROUP BY P.NOMBRE, P.APELLIDO;
BEGIN
	FOR LOC IN CUR_LOCALIDAD LOOP
		DBMS_OUTPUT.PUT_LINE('LOCALIDAD: ' || LOC.NOMBRE);
		FOR CLIENTE IN C_CLIENTES(LOC.ID) LOOP
			DBMS_OUTPUT.PUT_LINE('	CLIENTE: ' || CLIENTE.NOMBRE ||' '||CLIENTE.APELLIDO || ' MONTO_TOTAL: ' || CLIENTE.TOTAL);
		END LOOP;
	END LOOP;
END;

/* 4. Cree un bloque PL/SQL realice lo siguiente:
o Lectura de todas las tablas de su esquema. Por cada tabla leída, imprima el nombre de la tabla
o Además, por cada tabla, lea con el segundo cursor, todos los campos de dicha tabla (enviada por
parámetro desde el cursor principal). Imprima nombre de la columna, tipo de dato, longitud y si es
o no nulable.*/

DECLARE 
	CURSOR cur_tablas IS
	SELECT DISTINCT TABLE_NAME FROM 
	sys.all_tab_columns WHERE OWNER = 'BASEDATOSP';
	
	CURSOR cur_campos(NOMBRE_TABLA VARCHAR2) IS
	SELECT COLUMN_NAME, DATA_TYPE, NULLABLE
		FROM sys.all_tab_columns
		WHERE TABLE_NAME  = NOMBRE_TABLA;
BEGIN 
	FOR TABLA IN CUR_TABLAS LOOP
		DBMS_OUTPUT.PUT_LINE('TABLA: ' || TABLA.TABLE_NAME);
	DBMS_OUTPUT.PUT_LINE('COLUMNA: 			' || ' TIPO: 			' || 'NULL: 			');
		FOR COLUMNA IN CUR_CAMPOS (TABLA.TABLE_NAME)LOOP
			DBMS_OUTPUT.PUT_LINE(COLUMNA.COLUMN_NAME ||' 			'|| COLUMNA.DATA_TYPE ||' 			' || COLUMNA. NULLABLE);
		END LOOP;
	END LOOP;
END;

/*5.PL/SQL para obtener las tablas de un tablespace:
Cree un PL/SQL anónimo que reciba como parámetro la identificación de un tablespace. El programa
deberá:
o Verificar que el tablespace exista. De no existir imprimirá el mensaje: ‘El tablespace no existe’.
o De existir el tablespace, deberá imprimir todas las tablas que dependen de ella:*/

DECLARE
	NO_TABLESPACE_FOUND EXCEPTION;
	NOMBRE_TABLA VARCHAR2(50) := :P_NOMBRETAB;
 	CURSOR CUR_TABLAS (NOMBRE_TABLESPACE VARCHAR2) IS
 		SELECT DISTINCT TABLE_NAME FROM 
		sys.all_tab_columns WHERE OWNER = NOMBRE_TABLA;
	CUR_LINE CUR_TABLAS%ROWTYPE;
BEGIN
	OPEN CUR_TABLAS(NOMBRE_TABLA);
	FETCH CUR_TABLAS INTO CUR_LINE;
	IF CUR_TABLAS%NOTFOUND THEN
		RAISE NO_TABLESPACE_FOUND;
	END IF;
	CLOSE CUR_TABLAS;
	FOR TABLA IN CUR_TABLAS(NOMBRE_TABLA) LOOP
		DBMS_OUTPUT.PUT_LINE( TABLA.TABLE_NAME);
	END LOOP;	

EXCEPTION
	WHEN NO_TABLESPACE_FOUND THEN
		dbms_output.put_line('El tablespace '||NOMBRE_TABLA || ' no existe');
		IF CUR_TABLAS%ISOPEN THEN
			CLOSE CUR_TABLAS;
		END IF;
	WHEN OTHERS THEN
		dbms_output.put_line('OCURRIO UN ERROR');
		IF CUR_TABLAS%ISOPEN THEN
			CLOSE CUR_TABLAS;
		END IF;		
END;


/*6. Cree una tabla que tenga lo siguiente:
REPOSICIÓN
Código artículo
Nombre artículo
Cantidad a pedir
Id del proveedor.
- Para poblar la tabla creada debe seleccionar en un cursor todas los artículos cuyo STOCK sea
inferior al STOCK MÍNIMO.
	- Cantidad a pedir = stock mínimo más un 35% adicional
	-Id del proveedor: Si existe un registro de compra para dicho artículo, se deberá recuperar
	 el id del proveedor a quien compramos por ultima vez.
- Insertar los datos leídos en la tabla de reposición.*/

CREATE TABLE REPOSICION  (
Codigo_articulo NUMBER(8) NOT NULL,
Nombre_articulo VARCHAR2 (50),
Cantidad NUMBER(8),
Id_proveedor NUMBER(8)
);

DECLARE 
CURSOR cur_articulos IS
	SELECT a.id,a.nombre,a.STOCK_MINIMO , a.STOCK_ACTUAL, max(cc.ID_PROVEEDOR)id_proveedor FROM B_ARTICULOS  a
	JOIN B_DETALLE_COMPRAS c 
	ON c.ID_ARTICULO =a.ID 
	JOIN B_COMPRAS cc 
	ON cc.ID =c.ID_COMPRA 
	WHERE a.STOCK_MINIMO > a.STOCK_ACTUAL
	GROUP BY  a.id,a.nombre, a.STOCK_MINIMO , a.STOCK_ACTUAL;
cur_art_line cur_articulos%rowtype;
BEGIN 
	FOR articulo IN CUR_ARTICULOS  LOOP
		INSERT INTO reposicion (Codigo_articulo,Nombre_articulo,Cantidad,Id_proveedor)
		values(
			articulo.id, articulo.nombre,Round(articulo.stock_minimo + (articulo.stock_minimo*0.35)), articulo.id_proveedor);
		COMMIT;
		END LOOP;
END;

--SELECT * FROM reposicion;


