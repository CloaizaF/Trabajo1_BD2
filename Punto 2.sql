DROP TABLE individuo;
CREATE TABLE individuo(
    codigo NUMBER(8) PRIMARY KEY,
    nombre VARCHAR2(20) NOT NULL,
    valor NUMBER(8) NOT NULL CHECK (valor > 0),
    padre NUMBER(8),
    nro_hijos NUMBER(8) NOT NULL CHECK (nro_hijos >=0),
    CHECK(padre <> codigo)
);

INSERT INTO individuo VALUES(19,'Hope Sandoval',10,NULL,0);
INSERT INTO individuo VALUES(32,'Kirsty Hawkshaw',8,NULL,0);
INSERT INTO individuo VALUES(64,'Annabella Lwin',10	,19,0);
INSERT INTO individuo VALUES(123,'Amanda Marshall',20,19,0);
INSERT INTO individuo VALUES(122,'Amanda Marshall',20,19,0);
INSERT INTO individuo VALUES(124,'Amanda Marshall',31,19,0);
INSERT INTO individuo VALUES(125,'Amanda Marshall',32,19,0);

--- a) nr0_hijos debe ser igual a 0
CREATE OR REPLACE TRIGGER restriccion_nro_hijos
BEFORE INSERT ON individuo
FOR EACH ROW
BEGIN
  IF :NEW.nro_hijos <> 0 THEN
    RAISE_APPLICATION_ERROR(-20505,'numero de hijos no es igual a 0');
  END IF;
END;
/

-- b) insertar individuo con padre no nulo
CREATE OR REPLACE TRIGGER insertar_con_padre_no_nulo
BEFORE INSERT ON individuo
FOR EACH ROW
WHEN (NEW.padre IS NOT NULL)
BEGIN
  UPDATE individuo
  SET nro_hijos = nro_hijos + 1
  WHERE codigo = :NEW.padre;
END;

INSERT INTO individuo VALUES(130,'Amanda Marshall',20,32,0); -- Para probar el b

-- c) tecer trigger si se borra un indiviuo con padre no nulo, entonces restarle al padre el hijo
CREATE OR REPLACE TRIGGER decremento_nro_hijos
FOR DELETE ON individuo COMPOUND TRIGGER

  numero_filas number(8) := 0;

  AFTER EACH ROW IS
  BEGIN
    numero_filas :=  numero_filas +1;
  END AFTER EACH ROW;

  AFTER STATEMENT IS
    contador number(4) := :OLD.padre;
  BEGIN
    IF contador IS NOT NULL THEN
      UPDATE individuo SET nro_hijos = nro_hijos - numero_filas WHERE codigo = contador;
    END IF;   
  END AFTER STATEMENT;

END decremento_nro_hijos;
/

-- d) cuando un individuo se borra y tiene hijos entonces a sus hijos se les pone el atributo padre = null
CREATE OR REPLACE TRIGGER nullificacion_padre
FOR DELETE ON individuo COMPOUND TRIGGER
  
  codInd individuo.codigo%TYPE := 0;

  BEFORE EACH ROW IS
  BEGIN
    codInd := :OLD.codigo;
  END BEFORE EACH ROW;

  AFTER STATEMENT IS
  BEGIN
    FOR ind IN (SELECT * FROM INDIVIDUO WHERE padre = codInd) LOOP
      UPDATE individuo SET padre = Null WHERE codigo = ind.codigo;
    END LOOP;
  END AFTER STATEMENT;

END nullificacion_padre;
/

DELETE FROM individuo WHERE codigo = 19; -- Para probar el d

-- e) el complicado
CREATE OR REPLACE PACKAGE auxiliar_individuo IS
  trigger_activado BOOLEAN := False;
  PROCEDURE cambiar_estado_trigger;
END;
/

CREATE OR REPLACE PACKAGE BODY auxiliar_individuo IS
  PROCEDURE cambiar_estado_trigger IS
  BEGIN
    IF trigger_activado = False THEN
      trigger_activado := True;
    ELSE
      trigger_activado := False;
    END IF;
  END;
END;

CREATE OR REPLACE TRIGGER incrementar_el_campo_valor 
FOR UPDATE OF valor ON individuo COMPOUND TRIGGER
  TYPE ind_tipo IS TABLE OF individuo%ROWTYPE;
  arr_individuo ind_tipo;
  codigo_individuo individuo.codigo%TYPE;
  codigo_padre individuo.codigo%TYPE;
  valor_restante individuo.valor%TYPE;

  BEFORE EACH ROW IS
  BEGIN
    IF auxiliar_individuo.trigger_activado = False THEN
      IF :NEW.valor - :OLD.valor >= 5
        THEN
          valor_restante := :NEW.valor - :OLD.valor - 2;
          :NEW.valor := :OLD.valor + 2;
          codigo_padre := :OLD.codigo;
      ELSIF :NEW.valor - :OLD.valor > 0 
        THEN
          codigo_padre := Null;
          :NEW.valor := :OLD.valor;
      END IF;
    ELSE
      auxiliar_individuo.cambiar_estado_trigger;
    END IF;
  END BEFORE EACH ROW;

  AFTER STATEMENT IS
  BEGIN
    SELECT * BULK COLLECT INTO arr_individuo FROM individuo WHERE padre = codigo_padre;
    IF arr_individuo.FIRST IS NOT NULL AND codigo_padre IS NOT NULL
      THEN
        codigo_individuo := arr_individuo(arr_individuo.FIRST).codigo;
        auxiliar_individuo.cambiar_estado_trigger;
        UPDATE individuo SET valor = valor + valor_restante WHERE codigo = codigo_individuo;
    END IF;
    arr_individuo.DELETE;
  END AFTER STATEMENT;

END incrementar_el_campo_valor;

UPDATE INDIVIDUO SET valor = 18 WHERE codigo = 19; -- Para probar el trigger e

-- f) cuando se actualice un código, se debe actualizar ese código también en sus hijos
CREATE OR REPLACE TRIGGER actualizacion_codigo
FOR UPDATE OF codigo ON individuo COMPOUND TRIGGER
  oldCod individuo.codigo%TYPE;
  newCod individuo.codigo%TYPE;

  BEFORE EACH ROW IS
  BEGIN
    oldCod := :OLD.codigo;
    newCod := :NEW.codigo;
  END BEFORE EACH ROW;

  AFTER STATEMENT IS
  BEGIN
    FOR ind IN (SELECT * FROM INDIVIDUO WHERE padre = oldCod) LOOP
      UPDATE individuo SET padre = newCod WHERE codigo = ind.codigo;
    END LOOP;
  END AFTER STATEMENT;
END actualizacion_codigo;

UPDATE individuo SET codigo = 20 WHERE codigo = 19; -- Para probar el f