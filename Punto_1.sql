DROP TABLE CERDO;
CREATE TABLE cerdo(
cod NUMBER(8) PRIMARY KEY,
nombre VARCHAR(20) NOT NULL,
pesokilos NUMBER(8) NOT NULL CHECK (pesokilos > 0)
);

INSERT INTO CERDO VALUES(2, 'Ana Criado', 3);
INSERT INTO CERDO VALUES(4, 'Dua Lipa', 3);
INSERT INTO CERDO VALUES(8, 'Saffron', 3);
INSERT INTO CERDO VALUES(11, 'Ava Max', 3);
INSERT INTO CERDO VALUES(15, 'Esthero', 8);

DROP TABLE CAMION;
CREATE TABLE camion(
idcamion NUMBER(8) PRIMARY KEY,
maximacapacidadkilos NUMBER(8) NOT NULL CHECK (maximacapacidadkilos > 0)
);

INSERT INTO CAMION VALUES(13, 10);
INSERT INTO CAMION VALUES(38, 7);
INSERT INTO CAMION VALUES(22, 8);


set SERVEROUTPUT on;

CREATE OR REPLACE PACKAGE MI_CERDITO_FELIZ IS
  TYPE t_arreglo_cerdos IS TABLE OF CERDO%ROWTYPE INDEX BY BINARY_INTEGER;
  PROCEDURE EscogerCerdos(maximo_camion IN camion.maximacapacidadkilos%TYPE, cerdos IN t_arreglo_cerdos, 
  cerdos_escogidos OUT t_arreglo_cerdos, maximo_alcanzado OUT NUMBER);
  PROCEDURE LlenarCamiones;
  FUNCTION Maximo(numero1 IN NUMBER, numero2 IN NUMBER) RETURN NUMBER;
END;
/

CREATE OR REPLACE PACKAGE BODY MI_CERDITO_FELIZ IS

  PROCEDURE EscogerCerdos(maximo_camion IN camion.maximacapacidadkilos%TYPE, cerdos IN t_arreglo_cerdos, 
  cerdos_escogidos OUT t_arreglo_cerdos, maximo_alcanzado OUT NUMBER)
  IS
    TYPE t_arreglo IS TABLE OF NUMBER(32) INDEX BY BINARY_INTEGER;
    TYPE t_matriz IS TABLE OF t_arreglo INDEX BY BINARY_INTEGER;
    matriz t_matriz;
    maximo_camion_aux camion.maximacapacidadkilos%TYPE;
    maximo_alcanzado_aux NUMBER(16);
    indice NUMBER(8) := 0;
  BEGIN
    maximo_camion_aux := maximo_camion;

    FOR i IN 0..cerdos.LAST LOOP
        FOR j IN 0..maximo_camion LOOP
            matriz(i)(j) := 0;
        END LOOP;
    END LOOP;

    FOR i IN 0..cerdos.LAST LOOP
        FOR j IN 0..maximo_camion LOOP
            IF i = 0 OR j = 0 THEN
                matriz(i)(j) := 0;
            ELSIF cerdos(i - 1).pesokilos <= j THEN
                matriz(i)(j) := Maximo(cerdos(i - 1).pesokilos + matriz(i - 1)(j - cerdos(i - 1).pesokilos), matriz(i - 1)(j));
            ELSE 
                matriz(i)(j) := matriz(i - 1)(j);
            END IF;
        END LOOP;
    END LOOP;

    maximo_alcanzado := matriz(cerdos.LAST)(maximo_camion);
    maximo_alcanzado_aux := matriz(cerdos.LAST)(maximo_camion);
    DBMS_OUTPUT.PUT_LINE(matriz(cerdos.LAST)(maximo_camion));

    FOR i IN REVERSE 0..cerdos.LAST LOOP
        IF maximo_alcanzado_aux <= 0 THEN
            EXIT;
        END IF;

        IF maximo_alcanzado_aux <> matriz(i-1)(maximo_camion) THEN
            cerdos_escogidos(indice) := cerdos(i-1);
            indice := indice + 1;
            maximo_alcanzado_aux := maximo_alcanzado_aux - cerdos(i-1).pesokilos;
            maximo_camion_aux := maximo_camion_aux - cerdos(i-1).pesokilos;
        END IF;
    END LOOP;

  END;

  PROCEDURE LlenarCamiones
  IS
    salida VARCHAR2(32767) := 'Informe para Mi Cerdito.' || '||' || '-----' || '||';
    peso_solicitado NUMBER(8);
    peso_solicitado_aux NUMBER(8);
    peso_enviado NUMBER(8) := 0;
    peso_no_satisfecho NUMBER(8);
    capacidad_camion NUMBER(8);
    cerdos t_arreglo_cerdos;
    cerdos_escogidos t_arreglo_cerdos;
    peso_alcanzado NUMBER(8);
    peso_faltante NUMBER(8);
    indice_i NUMBER(8) ;
  BEGIN
    
    peso_solicitado := 10;
    
 

    
    FOR camion IN (SELECT * FROM CAMION ORDER BY MAXIMACAPACIDADKILOS DESC) LOOP
      salida := salida || 'Camión: ' || camion.IDCAMION || '
    ';
      indice_i := 0;
      FOR cerdoi IN (SELECT * FROM cerdo ORDER BY pesokilos ASC) LOOP
        cerdos(indice_i) :=  cerdoi;
        indice_i := indice_i + 1;
      END LOOP;
    
      capacidad_camion := camion.MAXIMACAPACIDADKILOS;
      
      peso_faltante := peso_solicitado - peso_enviado;
      
      IF capacidad_camion > peso_faltante THEN
        capacidad_camion := peso_solicitado - peso_enviado;
        DBMS_OUTPUT.PUT_LINE('hola');
      END IF;
       
      EscogerCerdos(capacidad_camion, cerdos, cerdos_escogidos, peso_alcanzado);
        
       salida := salida || 'Lista cerdos: ';
        
      FOR i IN 0..cerdos_escogidos.LAST LOOP
        salida := salida || cerdos_escogidos(i).cod || ' (' ||  cerdos_escogidos(i).nombre
         || ') ' ||  cerdos_escogidos(i).PESOKILOS || ', ';
        DELETE FROM CERDO WHERE cod =  cerdos_escogidos(i).cod;
      END LOOP;

      salida := salida || '
      ' || 'Total peso cerdos: ' || peso_alcanzado || '.' ||
                'Capacidad no usada del camión: ' || (capacidad_camion - peso_alcanzado);

      peso_enviado := peso_enviado + peso_alcanzado;
    END LOOP;
    

    DBMS_OUTPUT.PUT_LINE(peso_solicitado);
  
    
  END;

  FUNCTION Maximo(numero1 IN NUMBER, numero2 IN NUMBER) 
  RETURN NUMBER IS
  BEGIN 
    IF numero1 >= numero2 THEN
        RETURN numero1;
    ELSE
        RETURN numero2;
    END IF;
  END;

END;
/



BEGIN
     
    MI_CERDITO_FELIZ.LlenarCamiones; 

    
END;

show errors
-- SELECT pesokilos BULK COLLECT INTO cerdos FROM cerdo ORDER BY pesokilos; 