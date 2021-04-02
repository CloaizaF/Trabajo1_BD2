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
  TYPE t_arreglo_pesos IS TABLE OF cerdo.PESOKILOS%TYPE INDEX BY BINARY_INTEGER;
  PROCEDURE EscogerCerdos(maximo_camion IN camion.maximacapacidadkilos%TYPE, pesos IN t_arreglo_pesos, 
  pesos_escogidos OUT t_arreglo_pesos, maximo_alcanzado OUT NUMBER);
  FUNCTION Maximo(numero1 IN NUMBER, numero2 IN NUMBER) RETURN NUMBER;
END;
/

CREATE OR REPLACE PACKAGE BODY MI_CERDITO_FELIZ IS
  
  PROCEDURE EscogerCerdos(maximo_camion IN camion.maximacapacidadkilos%TYPE, pesos IN t_arreglo_pesos, 
  pesos_escogidos OUT t_arreglo_pesos, maximo_alcanzado OUT NUMBER)
  IS
    TYPE t_arreglo IS TABLE OF NUMBER(32) INDEX BY BINARY_INTEGER;
    TYPE t_matriz IS TABLE OF t_arreglo INDEX BY BINARY_INTEGER;
    matriz t_matriz;
    numero NUMBER(8) := 0;
  BEGIN
    FOR i IN 0..pesos.LAST LOOP
        FOR j IN 0..maximo_camion LOOP
            matriz(i)(j) := 0;
            numero := numero + 1;
        END LOOP;
    END LOOP;

    FOR i IN 0..pesos.LAST LOOP
        FOR j IN 0..maximo_camion LOOP
            IF i = 0 OR j = 0 THEN
                matriz(i)(j) := 0;
            ELSIF pesos(i - 1) <= j THEN
                matriz(i)(j) := Maximo(pesos(i - 1) + matriz(i - 1)(j - pesos(i-1)), matriz(i - 1)(j));
            ELSE 
                matriz(i)(j) := matriz(i - 1)(j);
            END IF;
        END LOOP;
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
    TYPE t_arreglo_pesos IS TABLE OF cerdo.PESOKILOS%TYPE INDEX BY BINARY_INTEGER;
    pesos MI_CERDITO_FELIZ.t_arreglo_pesos;
    pesos_escogidos MI_CERDITO_FELIZ.t_arreglo_pesos;
    maximo_alcanzado NUMBER(16);
    indice_i NUMBER(8) := 0;
BEGIN
    FOR i IN (SELECT * FROM cerdo ORDER BY pesokilos ASC) LOOP
      pesos(indice_i) :=  i.pesokilos;
      indice_i := indice_i + 1;
    END LOOP;
    MI_CERDITO_FELIZ.ESCOGERCERDOS(10, pesos, pesos_escogidos, maximo_alcanzado); 
END;

-- SELECT pesokilos BULK COLLECT INTO pesos FROM cerdo ORDER BY pesokilos; 