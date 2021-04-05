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
  PROCEDURE LlenarCamiones(peso_solicitado IN NUMBER);
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

    FOR i IN 0..cerdos.LAST+1 LOOP
        FOR j IN 0..maximo_camion LOOP
            matriz(i)(j) := 0;
        END LOOP;
    END LOOP;

    FOR i IN 0..cerdos.LAST+1 LOOP
        FOR j IN 0..maximo_camion LOOP
            IF i = 0 OR j = 0 THEN
                matriz(i)(j) := 0;
            ELSIF cerdos(i - 1).pesokilos <= j THEN
                matriz(i)(j) := Maximo(cerdos(i - 1).pesokilos + matriz(i - 1)(j - cerdos(i - 1).pesokilos), 
                                        matriz(i - 1)(j));
            ELSE
                matriz(i)(j) := matriz(i - 1)(j);
            END IF;
        END LOOP;
    END LOOP;

    maximo_alcanzado := matriz(cerdos.LAST+1)(maximo_camion);
    maximo_alcanzado_aux := matriz(cerdos.LAST+1)(maximo_camion);

    FOR i IN REVERSE 0..cerdos.LAST+1 LOOP

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

  PROCEDURE LlenarCamiones(peso_solicitado IN NUMBER)
  IS
    TYPE t_arreglo_salida IS TABLE OF VARCHAR2(32767) INDEX BY BINARY_INTEGER;
    contador BINARY_INTEGER := 0;
    salida t_arreglo_salida;
    peso_enviado NUMBER(8) := 0;
    peso_no_satisfecho NUMBER(8);
    capacidad_camion camion.MAXIMACAPACIDADKILOS%TYPE;
    cerdos t_arreglo_cerdos;
    cerdos_escogidos t_arreglo_cerdos;
    peso_alcanzado NUMBER(8);
    peso_faltante camion.MAXIMACAPACIDADKILOS%TYPE := 0;
    existencia_cerdos BOOLEAN := True;
    existencia_solucion BOOLEAN := True;
    control_capacidad BOOLEAN := False;
    indice_i NUMBER(8);
  BEGIN

    salida(contador) := 'Informe para Mi Cerdito.' || chr(13)||chr(10) || '-----';
    contador := contador + 1;

    FOR camion IN (SELECT * FROM CAMION ORDER BY MAXIMACAPACIDADKILOS DESC) LOOP

      IF control_capacidad = True THEN
        EXIT;
      END IF;

      indice_i := 0;
      cerdos.DELETE;
      FOR cerdoi IN (SELECT * FROM cerdo ORDER BY pesokilos ASC) LOOP
        cerdos(indice_i) :=  cerdoi;
        indice_i := indice_i + 1;
      END LOOP;

      IF cerdos.FIRST IS NULL THEN
        existencia_cerdos := False;
        EXIT;
      END IF;
      
      capacidad_camion := camion.MAXIMACAPACIDADKILOS;
      peso_faltante := peso_solicitado - peso_enviado;
      IF capacidad_camion > peso_faltante THEN
        control_capacidad := True;
        EscogerCerdos(peso_faltante, cerdos, cerdos_escogidos, peso_alcanzado);
      ELSE
        EscogerCerdos(capacidad_camion, cerdos, cerdos_escogidos, peso_alcanzado);
      END IF;

      IF cerdos_escogidos.FIRST IS NULL THEN
        existencia_solucion := False;
        EXIT;
      END IF;

      salida(contador) := 'Camión: ' || camion.IDCAMION;
      contador := contador + 1;
      salida(contador) := 'Lista cerdos: ';
      FOR i IN 0..cerdos_escogidos.LAST LOOP
        salida(contador) := salida(contador) || cerdos_escogidos(i).cod || ' (' ||  cerdos_escogidos(i).nombre
         || ') ' ||  cerdos_escogidos(i).PESOKILOS || 'kg';
        IF i <> cerdos_escogidos.LAST THEN
          salida(contador) := salida(contador) || ', ';
        END IF;
        DELETE FROM CERDO WHERE cod = cerdos_escogidos(i).cod;
      END LOOP;
      contador := contador + 1;
      salida(contador) := 'Total peso cerdos: ' || peso_alcanzado || 'kg. ' || 'Capacidad no usada del camión: ' 
        || (capacidad_camion - peso_alcanzado) || 'kg';
      contador := contador + 1;

      peso_enviado := peso_enviado + peso_alcanzado;

    END LOOP;

    IF (control_capacidad = True AND (existencia_cerdos = True AND existencia_solucion = True)) OR
          (existencia_cerdos = False AND peso_enviado > 0 ) OR
          (existencia_solucion = False AND peso_enviado > 0) THEN
      peso_no_satisfecho := peso_solicitado - peso_enviado;
      salida(contador) := '-----';
      contador := contador + 1;
      salida(contador) := 'Total Peso solicitado: ' || peso_solicitado || 'kg. Peso real enviado: ' 
        || peso_enviado || 'kg. Peso no satisfecho: ' || peso_no_satisfecho || 'kg.';
    ELSE
      salida.DELETE;
      salida(0) := 'El pedido no se puede satisfacer';
    END IF;

    FOR i IN 0..salida.LAST LOOP
      DBMS_OUTPUT.PUT_LINE(salida(i));
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

EXECUTE MI_CERDITO_FELIZ.LlenarCamiones(16);