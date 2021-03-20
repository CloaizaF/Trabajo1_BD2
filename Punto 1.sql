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

