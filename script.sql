-- 1.1 Adicione uma tabela de log ao sistema do restaurante. Ajuste cada procedimento para que ele registre
-- - a data em que a operação aconteceu
-- - o nome do procedimento executado

-- Criação da tabela de log
CREATE TABLE tb_log (
  cod_log SERIAL PRIMARY KEY,
  data_hora TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  procedimento VARCHAR(200) NOT NULL
);

-- Ajustando os procedimentos para gerar log
    -- sp_adicionar_item_a_pedido
CREATE OR REPLACE PROCEDURE sp_adicionar_item_a_pedido(
  IN p_cod_item INT, 
  IN p_cod_pedido INT
)
LANGUAGE plpgsql
AS $$
BEGIN
  INSERT INTO tb_item_pedido (cod_item, cod_pedido)
  VALUES(p_cod_item, p_cod_pedido);
  
  UPDATE tb_pedido 
  SET data_modificacao = CURRENT_TIMESTAMP
  WHERE cod_pedido = p_cod_pedido;

  -- Registro no log
  INSERT INTO tb_log (procedimento)
  VALUES ('sp_adicionar_item_a_pedido');
END;
$$;

    --sp_calcular_valor_de_um_pedido
CREATE OR REPLACE PROCEDURE sp_calcular_valor_de_um_pedido(
  IN p_cod_pedido INT, OUT p_valor_total INT
)
LANGUAGE plpgsql
AS $$
BEGIN
  SELECT SUM(i.valor) 
  FROM tb_pedido p
  INNER JOIN tb_item_pedido ip ON p.cod_pedido = ip.cod_pedido
  INNER JOIN tb_item i ON ip.cod_item = i.cod_item
  WHERE p.cod_pedido = p_cod_pedido
  INTO p_valor_total;
  
  -- Registro no log
  INSERT INTO tb_log (procedimento)
  VALUES ('sp_calcular_valor_de_um_pedido');
END;
$$;

    -- sp_fechar_pedido
CREATE OR REPLACE PROCEDURE sp_fechar_pedido(
  IN p_valor_a_pagar INT,
  IN p_cod_pedido INT
)
LANGUAGE plpgsql 
AS $$
DECLARE
  v_valor_total INT;
BEGIN
  CALL sp_calcular_valor_de_um_pedido(p_cod_pedido, v_valor_total);
  
  IF p_valor_a_pagar < v_valor_total THEN
    RAISE NOTICE 'R$% insuficiente para pagar a conta de R$%', p_valor_a_pagar, v_valor_total;
  ELSE
    UPDATE tb_pedido 
    SET data_modificacao = CURRENT_TIMESTAMP,
        status = 'fechado'
    WHERE cod_pedido = p_cod_pedido;
  END IF;
  
  -- Registro no log
  INSERT INTO tb_log (procedimento)
  VALUES ('sp_fechar_pedido');
END;
$$;

    -- sp_criar_pedido
CREATE OR REPLACE PROCEDURE sp_criar_pedido(
  OUT p_cod_pedido INT, 
  IN p_cod_cliente INT
)
LANGUAGE plpgsql
AS $$
BEGIN
  INSERT INTO tb_pedido(cod_cliente) 
  VALUES (p_cod_cliente);
  
  SELECT LASTVAL() INTO p_cod_pedido;
  
  -- Registro no log
  INSERT INTO tb_log (procedimento)
  VALUES ('sp_criar_pedido');
END;
$$;

    -- sp_cadastrar_cliente
CREATE OR REPLACE PROCEDURE sp_cadastrar_cliente(
  IN p_nome VARCHAR(200), 
  IN p_cod_cliente INT DEFAULT NULL
)
LANGUAGE plpgsql
AS $$
BEGIN
  IF p_cod_cliente IS NULL THEN
    INSERT INTO tb_cliente (nome) VALUES (p_nome);
  ELSE
    INSERT INTO tb_cliente (cod_cliente, nome) VALUES (p_cod_cliente, p_nome);
  END IF;
  
  -- Registro no log
  INSERT INTO tb_log (procedimento)
  VALUES ('sp_cadastrar_cliente');
END;
$$;

-- INSERT INTO tb_log (procedimento)
-- VALUES ('teste_log_manual');

-- Testando o Log
SELECT * FROM tb_log;


