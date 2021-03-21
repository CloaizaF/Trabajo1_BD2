DROP TABLE CERDO;
CREATE TABLE cerdo(
cod NUMBER(8) PRIMARY KEY,
nombre VARCHAR(20) NOT NULL,
pesokilos NUMBER(8) NOT NULL CHECK (pesokilos > 0)
);

DROP TABLE CAMION;
CREATE TABLE camion(
idcamion NUMBER(8) PRIMARY KEY,
maximacapacidadkilos NUMBER(8) NOT NULL CHECK (maximacapacidadkilos > 0)
);

set SERVEROUTPUT on;

DECLARE
  v_valor number(4) := &valor; -- Forma de pedir valores de entrada
BEGIN
  DBMS_OUTPUT.PUT_LINE('El valor introducido es ' || v_valor);
END;
/


INSERT INTO CAMION VALUES(13, 10);
INSERT INTO CAMION VALUES(38, 7);
INSERT INTO CAMION VALUES(22, 8);


INSERT INTO CERDO VALUES(2, 'Ana Criado', 3);
INSERT INTO CERDO VALUES(4, 'Dua Lipa', 3);
INSERT INTO CERDO VALUES(8, 'Saffron', 3);
INSERT INTO CERDO VALUES(11, 'Ava Max', 3);
INSERT INTO CERDO VALUES(15, 'Esthero', 8);

DROP TABLE ASIGNACION;
CREATE TABLE ASIGNACION(
cod NUMBER(8) PRIMARY KEY,
idcamion NUMBER(8) NOT NULL
);


-- SELECT * FROM Camion ORDER BY maximacapacidadkilos;