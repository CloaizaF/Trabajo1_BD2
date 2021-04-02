DROP TABLE individuo;
CREATE TABLE individuo(
    codigo NUMBER(8) PRIMARY KEY,
    nombre VARCHAR2(20) NOT NULL,
    valor NUMBER(8) NOT NULL CHECK (valor > 0),
    padre NUMBER(8), --código del padre del inviduo
    nro_hijos NUMBER(8) NOT NULL CHECK (nro_hijos >=0),
    CHECK(padre <> codigo)
);



-- https://oracle-base.com/articles/11g/trigger-enhancements-11gr1 <-- FOLLOWS esto es para el orden de los trigger
--- Triger a) nr0_hijos debe ser igual a 0
CREATE OR REPLACE TRIGGER trigr1
BEFORE INSERT ON individuo
FOR EACH ROW
DECLARE

BEGIN
    IF :NEW.nro_hijos <> 0 THEN --- en estas lineas se verifica que nro_hijos sea distinto de cero

        RAISE_APPLICATION_ERROR(-20505,'numero de hijos no es igual a 0');  

    END IF;
END;
/

---- triger b) no estoy seguro si puede haber un insert con padre pero que no este en la tabla
CREATE OR REPLACE TRIGGER trigr2
BEFORE INSERT ON individuo
FOR EACH ROW
DECLARE

BEGIN
    --- for que suma los hijos
    FOR mi_i IN (SELECT * FROM individuo) LOOP
        
        IF :NEW.padre = mi_i.codigo THEN
            UPDATE individuo SET nro_hijos = nro_hijos + 1 WHERE codigo = mi_i.codigo;
        END IF;
    
    
    END LOOP;

END;
/




-- c) tecer trigger si se borra un indiviuo con padre no nulo, entonces restarle al padre el hijo



/*   ESTE TRIGGER GENERA EL ERROR DE TABLAS MUTANTES

CREATE OR REPLACE TRIGGER trigr3
BEFORE DELETE ON individuo
FOR EACH ROW

DECLARE
  contador number(4) := :OLD.padre;
BEGIN
  IF contador IS NOT NULL THEN
    UPDATE individuo SET nro_hijos = nro_hijos - 1 WHERE codigo = contador; 
  END IF;
  
END;
/
*/

/
CREATE OR REPLACE TRIGGER trigr3
  FOR DELETE ON individuo COMPOUND TRIGGER
-- Sección declaratica (optional)
-- Variables se declaran durante el Trigger

  

  
 numero_filas number(8) := 0;

  
--Ejecución antes de una consulta DML
  BEFORE STATEMENT IS
  BEGIN
  NULL;
  END BEFORE STATEMENT;

-- Ejecución antes de cada fila, variables :NEW, :OLD son permitidas
  BEFORE EACH ROW IS
  BEGIN
  NULL;
  END BEFORE EACH ROW;

-- Ejecución despues de cada fila, variables :NEW, :OLD son permitidas
  AFTER EACH ROW IS
  
  
  BEGIN
  numero_filas :=  numero_filas +1;
  DBMS_OUTPUT.PUT_LINE(numero_filas);
  END AFTER EACH ROW;

--Ejecución despues de una consulta DML
  AFTER STATEMENT IS
  contador number(4) := :OLD.padre;
  
  BEGIN
  
  IF contador IS NOT NULL THEN
    UPDATE individuo SET nro_hijos = nro_hijos - numero_filas WHERE codigo = contador;
  END IF;
  
  
   
  END AFTER STATEMENT;
  


 
END trigr3;
/

-- d) cuando un individuo se borra y tiene hijos entonces a sus hijos se les pone el atributo padre = null
CREATE OR REPLACE TRIGGER trigr4
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
END trigr4;
/

-- f) cuando se actualice un código, se debe actualizar ese código también en sus hijos
CREATE OR REPLACE TRIGGER trigr6
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
END trigr6;



DELETE individuo;
--INSERT INTO individuo VALUES(1,'juan peña',1000,NULL,1);
---select * from user_errors where type = 'TRIGGER' and name = 'trigger1'
--- así se elimina un trigger DROP trigr1 JASON.NRO_HIJOS_0; 
INSERT INTO individuo VALUES(19,'Hope Sandoval',10,NULL,0);
INSERT INTO individuo VALUES(32,'Kirsty Hawkshaw',8,NULL,0);
INSERT INTO individuo VALUES(64,'Annabella Lwin',10	,19,0);
INSERT INTO individuo VALUES(123,'Amanda Marshall',20,19,0);
INSERT INTO individuo VALUES(122,'Amanda Marshall',20,19,0);
INSERT INTO individuo VALUES(124,'Amanda Marshall',31,19,0);
INSERT INTO individuo VALUES(125,'Amanda Marshall',32,19,0);


INSERT INTO individuo VALUES(123,'Amanda Marshall',32,19,23);

DELETE FROM individuo WHERE codigo = 19; -- Para probar el d
UPDATE individuo SET codigo = 20 WHERE codigo = 19; -- Para probar el f


DROP TRIGGER JASON.trigr3;

SELECT * FROM individuo;

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
DROP TRIGGER CAMILO.incrementar_el_campo_valor;
-- e) Incrementar o Decrementar el atributo valor de la tabla individuo
CREATE OR REPLACE TRIGGER trigr7
FOR UPDATE OF valor ON individuo COMPOUND TRIGGER
valor_restante individuo.valor%TYPE;‬
BEFORE EACH ROW IS
BEGIN
IF :NEW.valor - :OLD.valor >= 5 THEN 
    valor_restante := :NEW.valor - :OLD.valor - 2;
    :NEW.valor := :OLD.valor + 2;
    DBMS_OUTPUT.PUT_LINE(valor_restante);
END IF;
END BEFORE EACH ROW;
END trigr7;

/*
CREATE OR REPLACE TRIGGER trigr7
FOR UPDATE OF valor ON individuo COMPOUND TRIGGER
  TYPE ind_tipo IS TABLE OF individuo%ROWTYPE;
  arr_individuo ind_tipo;
  codigo_individuo individuo.codigo%TYPE;
  codigo_padre individuo.codigo%TYPE;
  valor_restante individuo.valor%TYPE;‬

  BEFORE EACH ROW IS
  BEGIN
    IF :NEW.valor - :OLD.valor >= 5
      THEN 
        valor_restante := :NEW.valor - :OLD.valor - 2;
        :NEW.valor := :OLD.valor + 2;
    END IF;
    codigo_padre := :OLD.codigo;
  END BEFORE EACH ROW;

  AFTER STATEMENT IS
  BEGIN
    SELECT * BULK COLLECT INTO arr_individuo FROM individuo WHERE padre = codigo_padre;
    IF arr_individuo.FIRST IS NOT NULL 
      THEN 
        UPDATE individuo SET valor = valor + valor_restante WHERE codigo = arr_individuo(arr_individuo.FIRST).codigo;
    END IF;
  END AFTER STATEMENT;
END trigr7;

CREATE OR REPLACE TRIGGER incrementar_el_campo_valor 
FOR UPDATE OF valor ON individuo COMPOUND TRIGGER
  valor_restante individuo.valor%TYPE;‬

  BEFORE EACH ROW IS
  BEGIN
    IF :NEW.valor - :OLD.valor >= 5
      THEN 
        valor_restante := :NEW.valor - :OLD.valor - 2;
        :NEW.valor := :OLD.valor + 2;
        DBMS_OUTPUT.PUT_LINE(valor_restante);
    END IF;
  END BEFORE EACH ROW;

  AFTER EACH ROW IS
  BEGIN
  codigo_padre := :OLD.codigo;
  SELECT * BULK COLLECT INTO arr_individuo FROM individuo WHERE padre = codigo_padre;
  IF arr_individuo.FIRST IS NOT NULL 
    THEN 
      codigo_individuo := arr_individuo(arr_individuo.FIRST).codigo;
      UPDATE individuo SET valor = valor + valor_restante WHERE codigo = codigo_individuo;
      DBMS_OUTPUT.PUT_LINE(codigo_individuo);
  END IF;
  END AFTER EACH ROW;
END incrementar_el_campo_valor;
*/

UPDATE INDIVIDUO SET valor = 30 WHERE codigo = 19;

set SERVEROUTPUT on;

/*
TYPE ind_tipo IS TABLE OF individuo%ROWTYPE;
  arr_individuo ind_tipo;
  codigo_individuo individuo.codigo%TYPE;
SELECT * BULK COLLECT INTO arr_individuo FROM individuo;
      IF arr_individuo.FIRST IS NOT NULL 
      THEN 
        codigo_individuo := arr_individuo(arr_individuo.FIRST).codigo;
        UPDATE individuo SET valor = valor + valor_restante WHERE codigo = codigo_individuo;
        DBMS_OUTPUT.PUT_LINE(codigo_individuo);
      END IF;
*/

/*
CREATE OR REPLACE TRIGGER incrementar_el_campo_valor
BEFORE UPDATE OF valor ON individuo
FOR EACH ROW
WHEN (NEW.valor > OLD.valor)
DECLARE
  TYPE ind_tipo IS TABLE OF individuo%ROWTYPE;
  arr_individuo ind_tipo;
  codigo_individuo individuo.codigo%TYPE;
  valor_restante individuo.valor%TYPE;
BEGIN 
  IF :NEW.valor - :OLD.valor >= 5
    THEN 
      valor_restante := :NEW.valor - :OLD.valor - 2;
      :NEW.valor := :OLD.valor + 2;
      DBMS_OUTPUT.PUT_LINE(valor_restante);
      SELECT * BULK COLLECT INTO arr_individuo FROM individuo;
      IF arr_individuo.FIRST IS NOT NULL 
      THEN 
        codigo_individuo := arr_individuo(arr_individuo.FIRST).codigo;
        UPDATE individuo SET valor = valor + valor_restante WHERE codigo = codigo_individuo;
        DBMS_OUTPUT.PUT_LINE(codigo_individuo);
      END IF;
  END IF;
END;
*/