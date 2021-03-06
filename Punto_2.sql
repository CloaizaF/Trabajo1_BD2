DROP TABLE individuo;
CREATE TABLE individuo(
    codigo NUMBER(8) PRIMARY KEY,
    nombre VARCHAR2(20) NOT NULL,
    valor NUMBER(8) NOT NULL CHECK (valor > 0),
    padre NUMBER(8),
    nro_hijos NUMBER(8) NOT NULL CHECK (nro_hijos >=0),
    CHECK(padre <> codigo)
);

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
/

-- c) si se borra un indiviuo con padre no nulo, entonces restarle al padre el hijo
CREATE OR REPLACE TRIGGER decremento_nro_hijos
FOR DELETE ON individuo COMPOUND TRIGGER
  contador number(4) := :OLD.padre;
  numero_filas number(8) := 0;

  AFTER EACH ROW IS
  BEGIN
    numero_filas :=  numero_filas +1;
  END AFTER EACH ROW;

  AFTER STATEMENT IS
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
  
  cod_ind individuo.codigo%TYPE := 0;

  BEFORE EACH ROW IS
  BEGIN
    cod_ind := :OLD.codigo;
  END BEFORE EACH ROW;

  AFTER STATEMENT IS
  BEGIN
    FOR ind IN (SELECT * FROM INDIVIDUO WHERE padre = cod_ind) LOOP
      UPDATE individuo SET padre = Null WHERE codigo = ind.codigo;
    END LOOP;
  END AFTER STATEMENT;

END nullificacion_padre;
/

-- e) incremento del campo valor de la tabla individuo
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
/

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
/

-- f) cuando se actualice un c??digo, se debe actualizar ese c??digo tambi??n en sus hijos
CREATE OR REPLACE TRIGGER actualizacion_codigo
FOR UPDATE OF codigo ON individuo COMPOUND TRIGGER
  old_cod individuo.codigo%TYPE;
  new_cod individuo.codigo%TYPE;

  BEFORE EACH ROW IS
  BEGIN
    old_cod := :OLD.codigo;
    new_cod := :NEW.codigo;
  END BEFORE EACH ROW;

  AFTER STATEMENT IS
  BEGIN
    FOR ind IN (SELECT * FROM INDIVIDUO WHERE padre = old_cod) LOOP
      UPDATE individuo SET padre = new_cod WHERE codigo = ind.codigo;
    END LOOP;
  END AFTER STATEMENT;
END actualizacion_codigo;
/