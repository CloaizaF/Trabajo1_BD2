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

DECLARE 
    TYPE t_arreglo_cerdos IS TABLE OF cerdo.PESOKILOS%TYPE INDEX BY BINARY_INTEGER;
    cerdos MI_CERDITO_FELIZ.t_arreglo_cerdos;
    cerdos_escogidos MI_CERDITO_FELIZ.t_arreglo_cerdos;
    maximo_alcanzado NUMBER(16);
    indice_i NUMBER(8) := 0;
BEGIN
    FOR cerdoi IN (SELECT * FROM cerdo ORDER BY pesokilos ASC) LOOP
      cerdos(indice_i) :=  cerdoi;
      indice_i := indice_i + 1;
    END LOOP;
    MI_CERDITO_FELIZ.ESCOGERCERDOS(10, cerdos, cerdos_escogidos, maximo_alcanzado); 

    FOR i in 0..cerdos_escogidos.LAST LOOP
        DBMS_OUTPUT.PUT_LINE(cerdos_escogidos(i).cod);
    END LOOP;
END;

-- SELECT pesokilos BULK COLLECT INTO cerdos FROM cerdo ORDER BY pesokilos; 