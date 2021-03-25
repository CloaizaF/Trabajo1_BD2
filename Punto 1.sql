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

DROP TABLE CERDOESCOGIDOS;
CREATE TABLE cerdoEscogidos(
cod NUMBER(8) PRIMARY KEY,
pesokilos NUMBER(8) NOT NULL CHECK (pesokilos > 0)
);

INSERT INTO CERDO VALUES(2, 'Ana Criado', 3);
INSERT INTO CERDO VALUES(4, 'Dua Lipa', 3);
INSERT INTO CERDO VALUES(8, 'Saffron', 3);
INSERT INTO CERDO VALUES(11, 'Ava Max', 3);
INSERT INTO CERDO VALUES(15, 'Esthero', 8);


INSERT INTO CAMION VALUES(13, 10);
INSERT INTO CAMION VALUES(38, 7);
INSERT INTO CAMION VALUES(22, 8);


set SERVEROUTPUT on;

CREATE OR REPLACE PROCEDURE EscogerCerdos(maximo_camion IN camion.maximacapacidadkilos%TYPE)
IS
  TYPE t_arreglo IS TABLE OF cerdo.PESOKILOS%TYPE INDEX BY BINARY_INTEGER;
  peso_cerdos t_arreglo;

  TYPE t_arreglo2 IS TABLE OF cerdo%ROWTYPE INDEX BY BINARY_INTEGER;
  
  cerdos t_arreglo2;
 
  indice_i number(4) := 1;
  indice_j number(4) := 0;
  suma number(4);
  ans number(4) := -1;
  a number(4) := 1;
  b number(4);
  c number(4);
  d number(4);

BEGIN
  
  DELETE CERDOESCOGIDOS;

  FOR i IN (SELECT * FROM cerdo ORDER BY pesokilos ASC) LOOP
    peso_cerdos(indice_i) :=  i.pesokilos;
    cerdos(indice_i) := i;
    indice_i := indice_i + 1;
  END LOOP;
  
  b  := peso_cerdos.COUNT;
  suma := peso_cerdos(a) + peso_cerdos(b);

  DBMS_OUTPUT.PUT_LINE(suma);

  WHILE a <> b LOOP
    IF suma = maximo_camion THEN
      ans := suma;
      EXIT;
    
    ELSIF suma > maximo_camion THEN
      b := b-1;
      suma := suma + peso_cerdos(b)- peso_cerdos(b+1);
    
    ELSIF suma < maximo_camion THEN
      IF ans < suma THEN
        ans := suma;
        c := a;
        d := b;
      END IF;  
      a := a + 1;
      suma := suma + peso_cerdos(a);

    END IF;

  END LOOP;

  IF ans = -1 THEN
    
    FOR i IN 1..peso_cerdos.COUNT  LOOP
      IF peso_cerdos(i) <= maximo_camion THEN
        ans := peso_cerdos(i);
      ELSE
        EXIT;
      END IF;  
    END LOOP;
    
  ELSE
    FOR i IN 1..c LOOP
    INSERT INTO cerdoEscogidos values(cerdos(i).COD,cerdos(i).pesokilos);
    END LOOP;
  
    INSERT INTO cerdoEscogidos values(cerdos(d).COD,cerdos(d).pesokilos);
  


  
  
  END IF;
  
 
  
  DBMS_OUTPUT.PUT_LINE(ans);
  
  
  
  
  



END;
/

EXECUTE EscogerCerdos(10);

-- comentario.