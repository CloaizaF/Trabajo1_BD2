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

/*DROP TABLE CERDOESCOGIDOS;
CREATE TABLE cerdoEscogidos(
cod NUMBER(8) PRIMARY KEY,
pesokilos NUMBER(8) NOT NULL CHECK (pesokilos > 0)
);*/

/* Caso de prueba estandar
DELETE CERDO;
INSERT INTO CERDO VALUES(2, 'Ana Criado', 3);
INSERT INTO CERDO VALUES(4, 'Dua Lipa', 3);
INSERT INTO CERDO VALUES(8, 'Saffron', 3);
INSERT INTO CERDO VALUES(11, 'Ava Max', 3);
INSERT INTO CERDO VALUES(15, 'Esthero', 8);
EXECUTE EscogerCerdos(10);
*/

/* Caso de prueba 1
DELETE CERDO;
INSERT INTO CERDO VALUES(1, 'Saffron', 1);
INSERT INTO CERDO VALUES(2, 'Ava Max', 3);
INSERT INTO CERDO VALUES(3, 'Esthero', 3);
INSERT INTO CERDO VALUES(4, 'Saffron', 4);
INSERT INTO CERDO VALUES(5, 'Ava Max', 4);
INSERT INTO CERDO VALUES(6, 'Esthero', 4);
INSERT INTO CERDO VALUES(7, 'Saffron', 5);
INSERT INTO CERDO VALUES(8, 'Ava Max', 6);
INSERT INTO CERDO VALUES(9, 'Esthero', 7);
INSERT INTO CERDO VALUES(10, 'Saffron', 8);
INSERT INTO CERDO VALUES(11, 'Ava Max', 9);
EXECUTE EscogerCerdos(29);
*/

/* Caso de prueba 2
DELETE CERDO;
INSERT INTO CERDO VALUES(1, 'Saffron', 13);
INSERT INTO CERDO VALUES(2, 'Ava Max', 20);
INSERT INTO CERDO VALUES(3, 'Esthero', 27);
INSERT INTO CERDO VALUES(4, 'Saffron', 29);
INSERT INTO CERDO VALUES(5, 'Ava Max', 30);
INSERT INTO CERDO VALUES(6, 'Esthero', 33);
INSERT INTO CERDO VALUES(7, 'Saffron', 49);
INSERT INTO CERDO VALUES(8, 'Ava Max', 50);
INSERT INTO CERDO VALUES(9, 'Esthero', 53);
INSERT INTO CERDO VALUES(10, 'Saffron', 65);
INSERT INTO CERDO VALUES(11, 'Ava Max', 78);
INSERT INTO CERDO VALUES(12, 'Ava Max', 81);
EXECUTE EscogerCerdos(119);
*/

/* Caso de prueba tipo Pacho 
BEGIN
 DELETE CERDO;
 FOR i IN 1..100000 LOOP
  INSERT INTO CERDO
  VALUES (i, 'Mariah'||i,  
          CEIL(DBMS_RANDOM.VALUE(1,10000)));
 END LOOP;
END;
/ 
EXECUTE EscogerCerdos(200000000);
*/

DELETE CERDO;
INSERT INTO CERDO VALUES(1, 'Saffron', 3);
INSERT INTO CERDO VALUES(2, 'Ava Max', 8);
INSERT INTO CERDO VALUES(3, 'Esthero', 11);
INSERT INTO CERDO VALUES(4, 'Saffron', 13);
INSERT INTO CERDO VALUES(5, 'Ava Max', 19);
INSERT INTO CERDO VALUES(6, 'Esthero', 25);
INSERT INTO CERDO VALUES(7, 'Saffron', 27);
INSERT INTO CERDO VALUES(8, 'Ava Max', 35);
INSERT INTO CERDO VALUES(9, 'Esthero', 36);
INSERT INTO CERDO VALUES(10, 'Saffron', 38);
INSERT INTO CERDO VALUES(11, 'Ava Max', 49);
INSERT INTO CERDO VALUES(12, 'Ava Max', 53);
EXECUTE EscogerCerdos(10);


INSERT INTO CAMION VALUES(13, 10);
INSERT INTO CAMION VALUES(38, 7);
INSERT INTO CAMION VALUES(22, 8);

set SERVEROUTPUT on;

CREATE OR REPLACE PACKAGE MI_CERDITO_FELIZ IS
  TYPE t_arreglo2 IS TABLE OF cerdo%ROWTYPE INDEX BY BINARY_INTEGER;
  PROCEDURE EscogerCerdos(maximo_camion IN camion.maximacapacidadkilos%TYPE, arreglo OUT t_arreglo2, ans_out OUT number, index_c OUT number, index_d OUT number);
  PROCEDURE LlenarCamiones();
  FUNCTION main(a in number) RETURN number;
END;
/

CREATE OR REPLACE PACKAGE BODY MI_CERDITO_FELIZ IS
  PROCEDURE EscogerCerdos(maximo_camion IN camion.maximacapacidadkilos%TYPE, arreglo OUT t_arreglo2, ans_out OUT number, index_c OUT number, index_d OUT number)
  IS 
    TYPE t_arreglo IS TABLE OF cerdo.PESOKILOS%TYPE INDEX BY BINARY_INTEGER;
    peso_cerdos t_arreglo;
    cerdos t_arreglo2;
  
    indice_i number(8) := 1;
    indice_j number(8) := 0;
    suma number(16);
    ans number(16) := -1;
    a number(8) := 1;
    b number(8);
    c number(8);
    d number(8);
  BEGIN

    FOR i IN (SELECT * FROM cerdo ORDER BY pesokilos ASC) LOOP
      peso_cerdos(indice_i) :=  i.pesokilos;
      cerdos(indice_i) := i;
      indice_i := indice_i + 1;
    END LOOP;
    
    b  := peso_cerdos.COUNT;
    suma := peso_cerdos(a) + peso_cerdos(b);

    WHILE a <> b LOOP
      IF suma = maximo_camion THEN
        ans := suma;
        c := a;
        d := b;
        EXIT;
      
      ELSIF suma > maximo_camion THEN
        b := b-1;
        suma := suma + peso_cerdos(b) - peso_cerdos(b+1);
      
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
          c := i;
          d := i;
        ELSE
          EXIT;
        END IF;  
      END LOOP;

    END IF;
  
    arreglo := cerdos;
    ans_out := ans;
    index_c := c;
    index_d := d;
  END;

  PROCEDURE LlenarCamiones()
  IS
    salida VARCHAR2(1000000) := 'Informe para Mi Cerdito.' || CHAR(13) || '-----' || CHAR(13);
    pesoSolicitado number(16);    
    pesoEnviado number(16) := 0;
    pesoNoSatisfecho number(16);
    capacidadCamion number(8);
    cerdos t_arreglo2;
    pesoAlcanzado number(8);
    index_c number(8);
    index_d number(8);
  BEGIN
    FOR camion IN (SELECT * FROM CAMION ORDER BY MAXIMACAPACIDADKILOS DESC) LOOP
      salida := salida || 'Camión: ' || camion.IDCAMION || CHAR(13);
      capacidadCamion := camion.MAXIMACAPACIDADKILOS;
      EscogerCerdos(capacidadCamion, cerdos, pesoAlcanzado, index_c, index_d);
      salida := salida || 'Lista cerdos: ';

      FOR i IN 0..index_c LOOP
        salida := salida || cerdos(i).cod || ' (' || cerdos(i).nombre || ') ' || cerdos(i).PESOKILOS || ', ';
        DELETE FROM CERDO WHERE COD = cerdos(i).cod;
      END LOOP;

      salida := salida || CHAR(13) || 'Total peso cerdos: ' || pesoAlcanzado || '.' ||
                'Capacidad no usada del camión: ' || (capacidadCamion - pesoAlcanzado);

      pesoEnviado := pesoEnviado + pesoAlcanzado;
    END LOOP;
  END;

  FUNCTION main(a in number) return number IS
      arreglo t_arreglo2;
      ans NUMBER(16);
      c NUMBER(8);
      d NUMBER(8);
      maximo CAMION.MAXIMACAPACIDADKILOS%TYPE := a;
    BEGIN
      MI_CERDITO_FELIZ.EscogerCerdos(maximo, arreglo, ans, c, d);
      /*
      DBMS_OUTPUT.PUT_LINE('c: ' || c);
      DBMS_OUTPUT.PUT_LINE('d: ' || d);
      FOR i in 1..arreglo.COUNT LOOP
        DBMS_OUTPUT.PUT_LINE(arreglo(i).COD);
      END LOOP;
      */
      RETURN ans;
  END;

END; 
/

BEGIN
  DBMS_OUTPUT.PUT_LINE(MI_CERDITO_FELIZ.main(10));
END;
/