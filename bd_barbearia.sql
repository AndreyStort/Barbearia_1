-- ATENÇÃO: este script apaga e recria o banco barbearia_ferrari.
-- Execute somente em ambiente de testes ou após fazer backup.
-- Compatibilidade recomendada: MySQL 8.0.16 ou superior.
DROP DATABASE IF EXISTS barbearia_ferrari;
CREATE DATABASE barbearia_ferrari
  CHARACTER SET utf8mb4
  COLLATE utf8mb4_0900_ai_ci;
USE barbearia_ferrari;

CREATE TABLE barbearia (
  id_barbearia BIGINT PRIMARY KEY AUTO_INCREMENT,
  nome VARCHAR(120) NOT NULL,
  endereco VARCHAR(200) NOT NULL,
  telefone VARCHAR(20) NOT NULL,
  CONSTRAINT uq_barbearia_nome_endereco UNIQUE (nome, endereco)
) ENGINE=InnoDB;

CREATE TABLE cliente (
  id_cliente BIGINT PRIMARY KEY AUTO_INCREMENT,
  nome VARCHAR(120) NOT NULL,
  telefone VARCHAR(20) NULL,
  data_cadastro DATE NOT NULL,
  ativo BOOLEAN NOT NULL DEFAULT TRUE,
  INDEX ix_cliente_nome (nome),
  INDEX ix_cliente_telefone (telefone)
) ENGINE=InnoDB;

CREATE TABLE funcionario (
  id_funcionario BIGINT PRIMARY KEY AUTO_INCREMENT,
  id_barbearia BIGINT NOT NULL,
  nome VARCHAR(120) NOT NULL,
  tipo_vinculo ENUM('PROPRIETARIO','EMPREGADO') NOT NULL,
  percentual_comissao DECIMAL(5,2) NOT NULL DEFAULT 0.00,
  status ENUM('ATIVO','INATIVO') NOT NULL DEFAULT 'ATIVO',
  CONSTRAINT fk_funcionario_barbearia FOREIGN KEY (id_barbearia)
    REFERENCES barbearia(id_barbearia),
  CONSTRAINT ck_funcionario_comissao CHECK (percentual_comissao BETWEEN 0 AND 100),
  INDEX ix_funcionario_barbearia (id_barbearia)
) ENGINE=InnoDB;

CREATE TABLE servico (
  id_servico BIGINT PRIMARY KEY AUTO_INCREMENT,
  id_barbearia BIGINT NOT NULL,
  nome VARCHAR(120) NOT NULL,
  descricao VARCHAR(255) NULL,
  categoria ENUM('TRADICIONAL','QUIMICO','COMBO','OUTRO') NOT NULL DEFAULT 'TRADICIONAL',
  preco_atual DECIMAL(10,2) NOT NULL,
  ativo BOOLEAN NOT NULL DEFAULT TRUE,
  CONSTRAINT fk_servico_barbearia FOREIGN KEY (id_barbearia)
    REFERENCES barbearia(id_barbearia),
  CONSTRAINT ck_servico_preco CHECK (preco_atual > 0),
  CONSTRAINT uq_servico_barbearia_nome UNIQUE (id_barbearia, nome)
) ENGINE=InnoDB;

CREATE TABLE atendimento (
  id_atendimento BIGINT PRIMARY KEY AUTO_INCREMENT,
  id_cliente BIGINT NOT NULL,
  id_funcionario BIGINT NOT NULL,
  data_hora_inicio DATETIME NOT NULL,
  data_hora_fim DATETIME NULL,
  status ENUM('ABERTO','CONCLUIDO','CANCELADO') NOT NULL DEFAULT 'ABERTO',
  observacao VARCHAR(500) NULL,
  CONSTRAINT fk_atendimento_cliente FOREIGN KEY (id_cliente)
    REFERENCES cliente(id_cliente),
  CONSTRAINT fk_atendimento_funcionario FOREIGN KEY (id_funcionario)
    REFERENCES funcionario(id_funcionario),
  CONSTRAINT ck_atendimento_datas CHECK (
    data_hora_fim IS NULL OR data_hora_fim >= data_hora_inicio
  ),
  CONSTRAINT ck_atendimento_concluido CHECK (
    status <> 'CONCLUIDO' OR data_hora_fim IS NOT NULL
  ),
  INDEX ix_atendimento_data_status (data_hora_inicio, status),
  INDEX ix_atendimento_cliente (id_cliente),
  INDEX ix_atendimento_funcionario (id_funcionario)
) ENGINE=InnoDB;

CREATE TABLE item_atendimento (
  id_item_atendimento BIGINT PRIMARY KEY AUTO_INCREMENT,
  id_atendimento BIGINT NOT NULL,
  id_servico BIGINT NOT NULL,
  quantidade DECIMAL(8,2) NOT NULL DEFAULT 1.00,
  valor_unitario_praticado DECIMAL(10,2) NOT NULL,
  desconto DECIMAL(10,2) NOT NULL DEFAULT 0.00,
  percentual_comissao_aplicado DECIMAL(5,2) NOT NULL DEFAULT 0.00,
  CONSTRAINT fk_item_atendimento_atendimento FOREIGN KEY (id_atendimento)
    REFERENCES atendimento(id_atendimento),
  CONSTRAINT fk_item_atendimento_servico FOREIGN KEY (id_servico)
    REFERENCES servico(id_servico),
  CONSTRAINT ck_item_quantidade CHECK (quantidade > 0),
  CONSTRAINT ck_item_valor CHECK (valor_unitario_praticado > 0),
  CONSTRAINT ck_item_desconto CHECK (
    desconto >= 0 AND desconto <= quantidade * valor_unitario_praticado
  ),
  CONSTRAINT ck_item_comissao CHECK (percentual_comissao_aplicado BETWEEN 0 AND 100),
  INDEX ix_item_atendimento (id_atendimento),
  INDEX ix_item_servico (id_servico)
) ENGINE=InnoDB;

CREATE TABLE pagamento (
  id_pagamento BIGINT PRIMARY KEY AUTO_INCREMENT,
  id_atendimento BIGINT NOT NULL,
  forma_pagamento ENUM('PIX','DINHEIRO','DEBITO','CREDITO') NOT NULL,
  valor DECIMAL(10,2) NOT NULL,
  data_hora DATETIME NOT NULL,
  status ENUM('CONFIRMADO','PENDENTE','ESTORNADO') NOT NULL DEFAULT 'CONFIRMADO',
  CONSTRAINT fk_pagamento_atendimento FOREIGN KEY (id_atendimento)
    REFERENCES atendimento(id_atendimento),
  CONSTRAINT ck_pagamento_valor CHECK (valor > 0),
  INDEX ix_pagamento_data_status (data_hora, status),
  INDEX ix_pagamento_atendimento (id_atendimento)
) ENGINE=InnoDB;

CREATE TABLE agendamento (
  id_agendamento BIGINT PRIMARY KEY AUTO_INCREMENT,
  id_cliente BIGINT NOT NULL,
  id_funcionario BIGINT NULL,
  data_hora_inicio DATETIME NOT NULL,
  data_hora_fim DATETIME NULL,
  status ENUM('SOLICITADO','CONFIRMADO','CANCELADO','REALIZADO','NAO_COMPARECEU') NOT NULL DEFAULT 'SOLICITADO',
  observacao VARCHAR(500) NULL,
  CONSTRAINT fk_agendamento_cliente FOREIGN KEY (id_cliente)
    REFERENCES cliente(id_cliente),
  CONSTRAINT fk_agendamento_funcionario FOREIGN KEY (id_funcionario)
    REFERENCES funcionario(id_funcionario),
  CONSTRAINT ck_agendamento_datas CHECK (
    data_hora_fim IS NULL OR data_hora_fim >= data_hora_inicio
  ),
  INDEX ix_agendamento_data_status (data_hora_inicio, status),
  INDEX ix_agendamento_funcionario_horario
    (id_funcionario, data_hora_inicio, data_hora_fim, status)
) ENGINE=InnoDB;

CREATE TABLE despesa (
  id_despesa BIGINT PRIMARY KEY AUTO_INCREMENT,
  id_barbearia BIGINT NOT NULL,
  descricao VARCHAR(180) NOT NULL,
  categoria ENUM('ALUGUEL','AGUA','ENERGIA','INTERNET','MATERIAL','MANUTENCAO','OUTRA') NOT NULL,
  classificacao ENUM('FIXA','VARIAVEL') NOT NULL,
  valor DECIMAL(10,2) NOT NULL,
  data_competencia DATE NOT NULL,
  data_pagamento DATE NULL,
  status ENUM('PENDENTE','PAGA','CANCELADA') NOT NULL DEFAULT 'PENDENTE',
  CONSTRAINT fk_despesa_barbearia FOREIGN KEY (id_barbearia)
    REFERENCES barbearia(id_barbearia),
  CONSTRAINT ck_despesa_valor CHECK (valor > 0),
  CONSTRAINT ck_despesa_pagamento CHECK (
    status <> 'PAGA' OR data_pagamento IS NOT NULL
  ),
  INDEX ix_despesa_data_status (data_competencia, status),
  INDEX ix_despesa_categoria (categoria)
) ENGINE=InnoDB;

CREATE TABLE fornecedor (
  id_fornecedor BIGINT PRIMARY KEY AUTO_INCREMENT,
  nome VARCHAR(120) NOT NULL,
  telefone VARCHAR(20) NULL,
  contato VARCHAR(120) NULL,
  ativo BOOLEAN NOT NULL DEFAULT TRUE
) ENGINE=InnoDB;

CREATE TABLE material (
  id_material BIGINT PRIMARY KEY AUTO_INCREMENT,
  id_barbearia BIGINT NOT NULL,
  nome VARCHAR(120) NOT NULL,
  unidade_medida VARCHAR(20) NOT NULL,
  estoque_minimo DECIMAL(10,2) NOT NULL DEFAULT 0.00,
  ativo BOOLEAN NOT NULL DEFAULT TRUE,
  CONSTRAINT fk_material_barbearia FOREIGN KEY (id_barbearia)
    REFERENCES barbearia(id_barbearia),
  CONSTRAINT ck_material_minimo CHECK (estoque_minimo >= 0),
  CONSTRAINT uq_material_barbearia_nome UNIQUE (id_barbearia, nome)
) ENGINE=InnoDB;

CREATE TABLE compra (
  id_compra BIGINT PRIMARY KEY AUTO_INCREMENT,
  id_fornecedor BIGINT NULL,
  data_compra DATE NOT NULL,
  status ENUM('RASCUNHO','RECEBIDA','CANCELADA') NOT NULL DEFAULT 'RASCUNHO',
  observacao VARCHAR(500) NULL,
  CONSTRAINT fk_compra_fornecedor FOREIGN KEY (id_fornecedor)
    REFERENCES fornecedor(id_fornecedor),
  INDEX ix_compra_data_status (data_compra, status)
) ENGINE=InnoDB;

CREATE TABLE item_compra (
  id_item_compra BIGINT PRIMARY KEY AUTO_INCREMENT,
  id_compra BIGINT NOT NULL,
  id_material BIGINT NOT NULL,
  quantidade DECIMAL(10,2) NOT NULL,
  custo_unitario DECIMAL(10,2) NOT NULL,
  CONSTRAINT fk_item_compra_compra FOREIGN KEY (id_compra)
    REFERENCES compra(id_compra),
  CONSTRAINT fk_item_compra_material FOREIGN KEY (id_material)
    REFERENCES material(id_material),
  CONSTRAINT ck_item_compra_quantidade CHECK (quantidade > 0),
  CONSTRAINT ck_item_compra_custo CHECK (custo_unitario >= 0),
  INDEX ix_item_compra_compra (id_compra)
) ENGINE=InnoDB;

CREATE TABLE movimentacao_estoque (
  id_movimentacao BIGINT PRIMARY KEY AUTO_INCREMENT,
  id_material BIGINT NOT NULL,
  id_compra BIGINT NULL,
  tipo ENUM('ENTRADA','SAIDA','AJUSTE_ENTRADA','AJUSTE_SAIDA') NOT NULL,
  quantidade DECIMAL(10,2) NOT NULL,
  data_hora DATETIME NOT NULL,
  motivo VARCHAR(200) NOT NULL,
  CONSTRAINT fk_movimentacao_material FOREIGN KEY (id_material)
    REFERENCES material(id_material),
  CONSTRAINT fk_movimentacao_compra FOREIGN KEY (id_compra)
    REFERENCES compra(id_compra),
  CONSTRAINT ck_movimentacao_quantidade CHECK (quantidade > 0),
  INDEX ix_movimentacao_material_data (id_material, data_hora)
) ENGINE=InnoDB;

CREATE TABLE repasse_comissao (
  id_repasse BIGINT PRIMARY KEY AUTO_INCREMENT,
  id_funcionario BIGINT NOT NULL,
  data_inicio DATE NOT NULL,
  data_fim DATE NOT NULL,
  data_pagamento DATE NULL,
  status ENUM('ABERTO','PAGO','CANCELADO') NOT NULL DEFAULT 'ABERTO',
  observacao VARCHAR(300) NULL,
  CONSTRAINT fk_repasse_funcionario FOREIGN KEY (id_funcionario)
    REFERENCES funcionario(id_funcionario),
  CONSTRAINT ck_repasse_periodo CHECK (data_fim >= data_inicio),
  INDEX ix_repasse_funcionario_periodo (id_funcionario, data_inicio, data_fim)
) ENGINE=InnoDB;

CREATE TABLE item_repasse_comissao (
  id_repasse BIGINT NOT NULL,
  id_item_atendimento BIGINT NOT NULL,
  valor_comissao_pago DECIMAL(10,2) NOT NULL,
  PRIMARY KEY (id_repasse, id_item_atendimento),
  CONSTRAINT uq_item_comissao_repassado UNIQUE (id_item_atendimento),
  CONSTRAINT fk_item_repasse_repasse FOREIGN KEY (id_repasse)
    REFERENCES repasse_comissao(id_repasse),
  CONSTRAINT fk_item_repasse_item FOREIGN KEY (id_item_atendimento)
    REFERENCES item_atendimento(id_item_atendimento),
  CONSTRAINT ck_item_repasse_valor CHECK (valor_comissao_pago >= 0)
) ENGINE=InnoDB;


-- =========================================================
-- REGRAS DE INTEGRIDADE IMPLEMENTADAS COM TRIGGERS
-- Requer MySQL 8.0.16+ para aplicação efetiva dos CHECKs.
-- =========================================================

DELIMITER $$

-- Não permite concluir atendimento sem informar o horário de término
-- e impede atendimento com funcionário inativo.
CREATE TRIGGER trg_atendimento_bi
BEFORE INSERT ON atendimento
FOR EACH ROW
BEGIN
  DECLARE v_status_funcionario VARCHAR(10);

  SELECT status INTO v_status_funcionario
  FROM funcionario
  WHERE id_funcionario = NEW.id_funcionario;

  IF v_status_funcionario IS NULL OR v_status_funcionario <> 'ATIVO' THEN
    SIGNAL SQLSTATE '45000'
      SET MESSAGE_TEXT = 'O atendimento exige um funcionário ativo.';
  END IF;

  IF NEW.status = 'CONCLUIDO' AND NEW.data_hora_fim IS NULL THEN
    SIGNAL SQLSTATE '45000'
      SET MESSAGE_TEXT = 'Atendimento concluído precisa de data_hora_fim.';
  END IF;
END$$

CREATE TRIGGER trg_atendimento_bu
BEFORE UPDATE ON atendimento
FOR EACH ROW
BEGIN
  DECLARE v_status_funcionario VARCHAR(10);

  SELECT status INTO v_status_funcionario
  FROM funcionario
  WHERE id_funcionario = NEW.id_funcionario;

  IF v_status_funcionario IS NULL OR v_status_funcionario <> 'ATIVO' THEN
    SIGNAL SQLSTATE '45000'
      SET MESSAGE_TEXT = 'O atendimento exige um funcionário ativo.';
  END IF;

  IF NEW.status = 'CONCLUIDO' AND NEW.data_hora_fim IS NULL THEN
    SIGNAL SQLSTATE '45000'
      SET MESSAGE_TEXT = 'Atendimento concluído precisa de data_hora_fim.';
  END IF;
END$$

-- Impede que um serviço de outra unidade seja lançado no atendimento.
CREATE TRIGGER trg_item_atendimento_bi
BEFORE INSERT ON item_atendimento
FOR EACH ROW
BEGIN
  DECLARE v_barbearia_funcionario BIGINT;
  DECLARE v_barbearia_servico BIGINT;

  SELECT f.id_barbearia INTO v_barbearia_funcionario
  FROM atendimento a
  JOIN funcionario f ON f.id_funcionario = a.id_funcionario
  WHERE a.id_atendimento = NEW.id_atendimento;

  SELECT id_barbearia INTO v_barbearia_servico
  FROM servico
  WHERE id_servico = NEW.id_servico;

  IF v_barbearia_funcionario IS NULL
     OR v_barbearia_servico IS NULL
     OR v_barbearia_funcionario <> v_barbearia_servico THEN
    SIGNAL SQLSTATE '45000'
      SET MESSAGE_TEXT = 'Funcionário e serviço devem pertencer à mesma barbearia.';
  END IF;
END$$

CREATE TRIGGER trg_item_atendimento_bu
BEFORE UPDATE ON item_atendimento
FOR EACH ROW
BEGIN
  DECLARE v_barbearia_funcionario BIGINT;
  DECLARE v_barbearia_servico BIGINT;

  SELECT f.id_barbearia INTO v_barbearia_funcionario
  FROM atendimento a
  JOIN funcionario f ON f.id_funcionario = a.id_funcionario
  WHERE a.id_atendimento = NEW.id_atendimento;

  SELECT id_barbearia INTO v_barbearia_servico
  FROM servico
  WHERE id_servico = NEW.id_servico;

  IF v_barbearia_funcionario IS NULL
     OR v_barbearia_servico IS NULL
     OR v_barbearia_funcionario <> v_barbearia_servico THEN
    SIGNAL SQLSTATE '45000'
      SET MESSAGE_TEXT = 'Funcionário e serviço devem pertencer à mesma barbearia.';
  END IF;
END$$

-- Evita conflito de horários para o mesmo profissional.
-- Quando o horário final não for informado, considera duração provisória de 1 hora.
CREATE TRIGGER trg_agendamento_bi
BEFORE INSERT ON agendamento
FOR EACH ROW
BEGIN
  DECLARE v_conflitos INT DEFAULT 0;
  DECLARE v_status_funcionario VARCHAR(10);

  IF NEW.id_funcionario IS NOT NULL
     AND NEW.status NOT IN ('CANCELADO') THEN

    SELECT status INTO v_status_funcionario
    FROM funcionario
    WHERE id_funcionario = NEW.id_funcionario;

    IF v_status_funcionario IS NULL OR v_status_funcionario <> 'ATIVO' THEN
      SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Agendamento exige funcionário ativo.';
    END IF;

    SELECT COUNT(*) INTO v_conflitos
    FROM agendamento a
    WHERE a.id_funcionario = NEW.id_funcionario
      AND a.status <> 'CANCELADO'
      AND NEW.data_hora_inicio <
          COALESCE(a.data_hora_fim, DATE_ADD(a.data_hora_inicio, INTERVAL 1 HOUR))
      AND COALESCE(NEW.data_hora_fim, DATE_ADD(NEW.data_hora_inicio, INTERVAL 1 HOUR))
          > a.data_hora_inicio;

    IF v_conflitos > 0 THEN
      SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Já existe agendamento sobreposto para este funcionário.';
    END IF;
  END IF;
END$$

CREATE TRIGGER trg_agendamento_bu
BEFORE UPDATE ON agendamento
FOR EACH ROW
BEGIN
  DECLARE v_conflitos INT DEFAULT 0;
  DECLARE v_status_funcionario VARCHAR(10);

  IF NEW.id_funcionario IS NOT NULL
     AND NEW.status NOT IN ('CANCELADO') THEN

    SELECT status INTO v_status_funcionario
    FROM funcionario
    WHERE id_funcionario = NEW.id_funcionario;

    IF v_status_funcionario IS NULL OR v_status_funcionario <> 'ATIVO' THEN
      SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Agendamento exige funcionário ativo.';
    END IF;

    SELECT COUNT(*) INTO v_conflitos
    FROM agendamento a
    WHERE a.id_funcionario = NEW.id_funcionario
      AND a.id_agendamento <> OLD.id_agendamento
      AND a.status <> 'CANCELADO'
      AND NEW.data_hora_inicio <
          COALESCE(a.data_hora_fim, DATE_ADD(a.data_hora_inicio, INTERVAL 1 HOUR))
      AND COALESCE(NEW.data_hora_fim, DATE_ADD(NEW.data_hora_inicio, INTERVAL 1 HOUR))
          > a.data_hora_inicio;

    IF v_conflitos > 0 THEN
      SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Já existe agendamento sobreposto para este funcionário.';
    END IF;
  END IF;
END$$

-- Ao mudar uma compra para RECEBIDA, gera suas entradas de estoque automaticamente.
CREATE TRIGGER trg_compra_au
AFTER UPDATE ON compra
FOR EACH ROW
BEGIN
  DECLARE v_itens INT DEFAULT 0;

  IF OLD.status <> 'RECEBIDA' AND NEW.status = 'RECEBIDA' THEN
    SELECT COUNT(*) INTO v_itens
    FROM item_compra
    WHERE id_compra = NEW.id_compra;

    IF v_itens = 0 THEN
      SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Não é possível receber compra sem itens.';
    END IF;

    INSERT INTO movimentacao_estoque
      (id_material, id_compra, tipo, quantidade, data_hora, motivo)
    SELECT
      ic.id_material,
      NEW.id_compra,
      'ENTRADA',
      ic.quantidade,
      CAST(CONCAT(NEW.data_compra, ' 09:00:00') AS DATETIME),
      'Entrada automática pela confirmação da compra'
    FROM item_compra ic
    WHERE ic.id_compra = NEW.id_compra;
  END IF;
END$$

-- Impede alteração de itens depois que a compra foi recebida,
-- evitando divergência entre itens da compra e movimentações já geradas.
CREATE TRIGGER trg_item_compra_bi
BEFORE INSERT ON item_compra
FOR EACH ROW
BEGIN
  DECLARE v_status_compra VARCHAR(12);

  SELECT status INTO v_status_compra
  FROM compra
  WHERE id_compra = NEW.id_compra;

  IF v_status_compra = 'RECEBIDA' THEN
    SIGNAL SQLSTATE '45000'
      SET MESSAGE_TEXT = 'Não é permitido adicionar itens a uma compra recebida.';
  END IF;
END$$

CREATE TRIGGER trg_item_compra_bu
BEFORE UPDATE ON item_compra
FOR EACH ROW
BEGIN
  DECLARE v_status_compra VARCHAR(12);

  SELECT status INTO v_status_compra
  FROM compra
  WHERE id_compra = OLD.id_compra;

  IF v_status_compra = 'RECEBIDA' THEN
    SIGNAL SQLSTATE '45000'
      SET MESSAGE_TEXT = 'Não é permitido alterar itens de uma compra recebida.';
  END IF;
END$$

CREATE TRIGGER trg_item_compra_bd
BEFORE DELETE ON item_compra
FOR EACH ROW
BEGIN
  DECLARE v_status_compra VARCHAR(12);

  SELECT status INTO v_status_compra
  FROM compra
  WHERE id_compra = OLD.id_compra;

  IF v_status_compra = 'RECEBIDA' THEN
    SIGNAL SQLSTATE '45000'
      SET MESSAGE_TEXT = 'Não é permitido excluir itens de uma compra recebida.';
  END IF;
END$$

-- Valida funcionário, período e valor da comissão no repasse.
CREATE TRIGGER trg_item_repasse_bi
BEFORE INSERT ON item_repasse_comissao
FOR EACH ROW
BEGIN
  DECLARE v_funcionario_repasse BIGINT;
  DECLARE v_funcionario_atendimento BIGINT;
  DECLARE v_data_atendimento DATE;
  DECLARE v_data_inicio DATE;
  DECLARE v_data_fim DATE;
  DECLARE v_valor_calculado DECIMAL(10,2);
  DECLARE v_status_repasse VARCHAR(12);

  SELECT id_funcionario, data_inicio, data_fim, status
    INTO v_funcionario_repasse, v_data_inicio, v_data_fim, v_status_repasse
  FROM repasse_comissao
  WHERE id_repasse = NEW.id_repasse;

  SELECT a.id_funcionario, DATE(a.data_hora_inicio),
         ROUND((ia.quantidade * ia.valor_unitario_praticado - ia.desconto)
               * ia.percentual_comissao_aplicado / 100, 2)
    INTO v_funcionario_atendimento, v_data_atendimento, v_valor_calculado
  FROM item_atendimento ia
  JOIN atendimento a ON a.id_atendimento = ia.id_atendimento
  WHERE ia.id_item_atendimento = NEW.id_item_atendimento;

  IF v_status_repasse <> 'ABERTO' THEN
    SIGNAL SQLSTATE '45000'
      SET MESSAGE_TEXT = 'Só é permitido incluir comissões em repasses abertos.';
  END IF;

  IF v_funcionario_repasse IS NULL
     OR v_funcionario_atendimento IS NULL
     OR v_funcionario_repasse <> v_funcionario_atendimento THEN
    SIGNAL SQLSTATE '45000'
      SET MESSAGE_TEXT = 'O item de comissão não pertence ao funcionário deste repasse.';
  END IF;

  IF v_data_atendimento < v_data_inicio
     OR v_data_atendimento > v_data_fim THEN
    SIGNAL SQLSTATE '45000'
      SET MESSAGE_TEXT = 'O atendimento está fora do período do repasse.';
  END IF;

  IF ABS(NEW.valor_comissao_pago - v_valor_calculado) > 0.01 THEN
    SIGNAL SQLSTATE '45000'
      SET MESSAGE_TEXT = 'Valor do repasse diferente da comissão calculada.';
  END IF;
END$$

CREATE TRIGGER trg_item_repasse_bu
BEFORE UPDATE ON item_repasse_comissao
FOR EACH ROW
BEGIN
  DECLARE v_funcionario_repasse BIGINT;
  DECLARE v_funcionario_atendimento BIGINT;
  DECLARE v_data_atendimento DATE;
  DECLARE v_data_inicio DATE;
  DECLARE v_data_fim DATE;
  DECLARE v_valor_calculado DECIMAL(10,2);
  DECLARE v_status_repasse VARCHAR(12);

  SELECT id_funcionario, data_inicio, data_fim, status
    INTO v_funcionario_repasse, v_data_inicio, v_data_fim, v_status_repasse
  FROM repasse_comissao
  WHERE id_repasse = NEW.id_repasse;

  SELECT a.id_funcionario, DATE(a.data_hora_inicio),
         ROUND((ia.quantidade * ia.valor_unitario_praticado - ia.desconto)
               * ia.percentual_comissao_aplicado / 100, 2)
    INTO v_funcionario_atendimento, v_data_atendimento, v_valor_calculado
  FROM item_atendimento ia
  JOIN atendimento a ON a.id_atendimento = ia.id_atendimento
  WHERE ia.id_item_atendimento = NEW.id_item_atendimento;

  IF v_status_repasse <> 'ABERTO' THEN
    SIGNAL SQLSTATE '45000'
      SET MESSAGE_TEXT = 'Só é permitido alterar itens de repasses abertos.';
  END IF;

  IF v_funcionario_repasse IS NULL
     OR v_funcionario_atendimento IS NULL
     OR v_funcionario_repasse <> v_funcionario_atendimento THEN
    SIGNAL SQLSTATE '45000'
      SET MESSAGE_TEXT = 'O item de comissão não pertence ao funcionário deste repasse.';
  END IF;

  IF v_data_atendimento < v_data_inicio OR v_data_atendimento > v_data_fim THEN
    SIGNAL SQLSTATE '45000'
      SET MESSAGE_TEXT = 'O atendimento está fora do período do repasse.';
  END IF;

  IF ABS(NEW.valor_comissao_pago - v_valor_calculado) > 0.01 THEN
    SIGNAL SQLSTATE '45000'
      SET MESSAGE_TEXT = 'Valor do repasse diferente da comissão calculada.';
  END IF;
END$$

DELIMITER ;

-- =========================================================
-- MASSA FICTÍCIA PARA TESTES. Não representa clientes reais.
-- Volume provisório: dimensionar após confirmar o movimento real.
-- =========================================================

INSERT INTO barbearia (nome, endereco, telefone)
VALUES ('Barbearia Ferrari - dados demonstrativos',
        'Endereço fictício para massa de teste', '(11) 90000-0000');

INSERT INTO cliente (nome, telefone, data_cadastro) VALUES
('Cliente Fictício 01','(11) 90000-0001','2026-01-05'),
('Cliente Fictício 02','(11) 90000-0002','2026-01-06'),
('Cliente Fictício 03','(11) 90000-0003','2026-01-08'),
('Cliente Fictício 04','(11) 90000-0004','2026-01-10'),
('Cliente Fictício 05','(11) 90000-0005','2026-01-12'),
('Cliente Fictício 06','(11) 90000-0006','2026-01-15'),
('Cliente Fictício 07','(11) 90000-0007','2026-01-18'),
('Cliente Fictício 08','(11) 90000-0008','2026-01-20'),
('Cliente Fictício 09','(11) 90000-0009','2026-01-22'),
('Cliente Fictício 10','(11) 90000-0010','2026-01-25'),
('Cliente Fictício 11','(11) 90000-0011','2026-02-01'),
('Cliente Fictício 12','(11) 90000-0012','2026-02-03');

INSERT INTO funcionario (id_barbearia, nome, tipo_vinculo, percentual_comissao, status) VALUES
(1,'Profissional Proprietário (fictício)','PROPRIETARIO',0.00,'ATIVO'),
(1,'Profissional Empregado (fictício)','EMPREGADO',50.00,'ATIVO');

INSERT INTO servico (id_barbearia, nome, descricao, categoria, preco_atual) VALUES
(1,'Corte','Serviço tradicional','TRADICIONAL',35.00),
(1,'Barba','Serviço tradicional','TRADICIONAL',25.00),
(1,'Cavanhaque','Serviço tradicional','TRADICIONAL',15.00),
(1,'Bigode','Serviço tradicional','TRADICIONAL',10.00),
(1,'Sobrancelha','Serviço tradicional','TRADICIONAL',5.00),
(1,'Luzes + corte','Pacote químico com corte','QUIMICO',100.00),
(1,'Platinado + corte','Pacote químico com corte','QUIMICO',115.00),
(1,'Progressiva + corte','Pacote químico com corte','QUIMICO',90.00),
(1,'Alisamento + corte','Pacote químico com corte','QUIMICO',70.00);

INSERT INTO atendimento (id_cliente, id_funcionario, data_hora_inicio, data_hora_fim, status, observacao) VALUES
(1,2,'2026-10-01 10:05:00','2026-10-01 10:35:00','CONCLUIDO',NULL),
(2,2,'2026-10-01 11:00:00','2026-10-01 11:45:00','CONCLUIDO',NULL),
(3,1,'2026-10-01 13:10:00','2026-10-01 13:40:00','CONCLUIDO',NULL),
(4,2,'2026-10-02 10:15:00','2026-10-02 10:50:00','CONCLUIDO',NULL),
(5,2,'2026-10-02 12:00:00','2026-10-02 12:50:00','CONCLUIDO',NULL),
(6,1,'2026-10-03 09:20:00','2026-10-03 09:50:00','CONCLUIDO',NULL),
(7,2,'2026-10-03 10:00:00','2026-10-03 10:40:00','CONCLUIDO',NULL),
(8,2,'2026-10-05 14:00:00','2026-10-05 14:30:00','CONCLUIDO',NULL),
(9,1,'2026-10-06 15:00:00','2026-10-06 15:30:00','CONCLUIDO',NULL),
(10,2,'2026-10-07 16:00:00','2026-10-07 16:50:00','CONCLUIDO',NULL),
(11,2,'2026-10-08 10:00:00','2026-10-08 10:30:00','CONCLUIDO',NULL),
(12,1,'2026-10-09 11:00:00','2026-10-09 11:30:00','CONCLUIDO',NULL),
(1,2,'2026-10-10 09:00:00','2026-10-10 09:40:00','CONCLUIDO',NULL),
(2,2,'2026-10-13 10:00:00','2026-10-13 10:30:00','CONCLUIDO',NULL),
(3,1,'2026-10-14 11:00:00','2026-10-14 11:40:00','CONCLUIDO',NULL),
(4,2,'2026-10-15 13:00:00','2026-10-15 13:30:00','CONCLUIDO',NULL),
(5,2,'2026-10-16 14:00:00','2026-10-16 14:45:00','CONCLUIDO',NULL),
(6,1,'2026-10-17 09:30:00','2026-10-17 10:00:00','CONCLUIDO',NULL),
(7,2,'2026-10-20 10:00:00','2026-10-20 10:35:00','CONCLUIDO',NULL),
(8,2,'2026-10-21 11:00:00',NULL,'ABERTO',NULL);

-- Itens por atendimento; valores praticados preservam o histórico.
INSERT INTO item_atendimento
(id_atendimento, id_servico, quantidade, valor_unitario_praticado, desconto, percentual_comissao_aplicado) VALUES
(1,1,1,35.00,0.00,50.00),
(2,1,1,35.00,0.00,50.00),(2,2,1,25.00,0.00,50.00),
(3,1,1,35.00,0.00,0.00),
(4,2,1,25.00,0.00,50.00),
(5,6,1,100.00,5.00,50.00),
(6,1,1,35.00,0.00,0.00),
(7,1,1,35.00,0.00,50.00),(7,5,1,5.00,0.00,50.00),
(8,3,1,15.00,0.00,50.00),
(9,1,1,35.00,0.00,0.00),
(10,7,1,115.00,0.00,50.00),
(11,4,1,10.00,0.00,50.00),
(12,1,1,35.00,0.00,0.00),
(13,1,1,35.00,0.00,50.00),(13,2,1,25.00,0.00,50.00),
(14,2,1,25.00,0.00,50.00),
(15,8,1,90.00,0.00,0.00),
(16,1,1,35.00,0.00,50.00),
(17,9,1,70.00,0.00,50.00),
(18,1,1,35.00,0.00,0.00),
(19,1,1,35.00,0.00,50.00),
(20,1,1,35.00,0.00,50.00);

INSERT INTO pagamento (id_atendimento, forma_pagamento, valor, data_hora, status) VALUES
(1,'PIX',35.00,'2026-10-01 10:35:00','CONFIRMADO'),
(2,'CREDITO',60.00,'2026-10-01 11:45:00','CONFIRMADO'),
(3,'DINHEIRO',35.00,'2026-10-01 13:40:00','CONFIRMADO'),
(4,'DEBITO',25.00,'2026-10-02 10:50:00','CONFIRMADO'),
(5,'PIX',95.00,'2026-10-02 12:50:00','CONFIRMADO'),
(6,'DINHEIRO',35.00,'2026-10-03 09:50:00','CONFIRMADO'),
(7,'PIX',40.00,'2026-10-03 10:40:00','CONFIRMADO'),
(8,'DINHEIRO',15.00,'2026-10-05 14:30:00','CONFIRMADO'),
(9,'PIX',35.00,'2026-10-06 15:30:00','CONFIRMADO'),
(10,'CREDITO',115.00,'2026-10-07 16:50:00','CONFIRMADO'),
(11,'DINHEIRO',10.00,'2026-10-08 10:30:00','CONFIRMADO'),
(12,'PIX',35.00,'2026-10-09 11:30:00','CONFIRMADO'),
(13,'PIX',60.00,'2026-10-10 09:40:00','CONFIRMADO'),
(14,'DEBITO',25.00,'2026-10-13 10:30:00','CONFIRMADO'),
(15,'PIX',90.00,'2026-10-14 11:40:00','CONFIRMADO'),
(16,'DINHEIRO',35.00,'2026-10-15 13:30:00','CONFIRMADO'),
(17,'CREDITO',70.00,'2026-10-16 14:45:00','CONFIRMADO'),
(18,'PIX',35.00,'2026-10-17 10:00:00','CONFIRMADO'),
(19,'PIX',35.00,'2026-10-20 10:35:00','CONFIRMADO');

INSERT INTO agendamento (id_cliente, id_funcionario, data_hora_inicio, data_hora_fim, status, observacao) VALUES
(9,2,'2026-12-24 10:00:00','2026-12-24 10:40:00','CONFIRMADO','Registro fictício para testar agenda sazonal'),
(10,NULL,'2026-12-24 11:00:00','2026-12-24 11:40:00','SOLICITADO','Profissional ainda não definido'),
(11,2,'2026-12-31 09:00:00','2026-12-31 09:40:00','CANCELADO','Registro fictício de cancelamento');

INSERT INTO despesa (id_barbearia, descricao, categoria, classificacao, valor, data_competencia, data_pagamento, status) VALUES
(1,'Aluguel mensal - teste','ALUGUEL','FIXA',700.00,'2026-10-01','2026-10-05','PAGA'),
(1,'Conta de água - teste','AGUA','FIXA',250.00,'2026-10-01','2026-10-08','PAGA'),
(1,'Energia elétrica - teste','ENERGIA','FIXA',300.00,'2026-10-01','2026-10-09','PAGA'),
(1,'Internet - teste','INTERNET','FIXA',80.00,'2026-10-01','2026-10-03','PAGA'),
(1,'Navalhas - teste','MATERIAL','VARIAVEL',100.00,'2026-10-03','2026-10-03','PAGA'),
(1,'Shampoo - teste','MATERIAL','VARIAVEL',40.00,'2026-10-04','2026-10-04','PAGA'),
(1,'Condicionador - teste','MATERIAL','VARIAVEL',40.00,'2026-10-04','2026-10-04','PAGA'),
(1,'Outros materiais - teste','MATERIAL','VARIAVEL',150.00,'2026-10-05',NULL,'PENDENTE');

INSERT INTO fornecedor (nome, telefone, contato) VALUES
('Fornecedor Fictício de Higiene','(11) 91111-1111','Contato fictício');

INSERT INTO material (id_barbearia, nome, unidade_medida, estoque_minimo) VALUES
(1,'Navalha descartável','UN',20),
(1,'Shampoo','ML',500),
(1,'Condicionador','ML',300),
(1,'Produto químico A','ML',250),
(1,'Luvas descartáveis','UN',30);

INSERT INTO compra (id_fornecedor, data_compra, status, observacao) VALUES
(1,'2026-10-03','RASCUNHO','Compra fictícia para teste de estoque; será recebida após inserir os itens.');

INSERT INTO item_compra (id_compra, id_material, quantidade, custo_unitario) VALUES
(1,1,50,2.00),(1,2,1000,0.04),(1,3,600,0.05),(1,4,500,0.12),(1,5,100,0.30);

-- Ao receber a compra, a trigger gera automaticamente as entradas no estoque.
UPDATE compra SET status = 'RECEBIDA' WHERE id_compra = 1;

INSERT INTO movimentacao_estoque (id_material, id_compra, tipo, quantidade, data_hora, motivo) VALUES
(1,NULL,'SAIDA',35,'2026-10-05 18:00:00','Consumo fictício'),
(1,NULL,'SAIDA',10,'2026-10-06 18:00:00','Consumo fictício'),
(2,NULL,'SAIDA',650,'2026-10-07 18:00:00','Consumo fictício'),
(3,NULL,'SAIDA',350,'2026-10-07 18:00:00','Consumo fictício'),
(4,NULL,'SAIDA',300,'2026-10-08 18:00:00','Consumo fictício'),
(5,NULL,'SAIDA',75,'2026-10-08 18:00:00','Consumo fictício');

-- Repasse fictício de comissão para demonstrar a baixa de itens já pagos.
-- Itens 1 e 2 pertencem ao funcionário empregado e somam R$ 35,00 de comissão.
INSERT INTO repasse_comissao
(id_funcionario, data_inicio, data_fim, data_pagamento, status, observacao)
VALUES
(2,'2026-10-01','2026-10-01','2026-10-05','ABERTO','Repasse demonstrativo fictício');

INSERT INTO item_repasse_comissao
(id_repasse, id_item_atendimento, valor_comissao_pago)
VALUES
(1,1,17.50),
(1,2,17.50);

UPDATE repasse_comissao SET status = 'PAGO' WHERE id_repasse = 1;

-- SELECT com JOIN (consulta operacional)
SELECT a.id_atendimento, a.data_hora_inicio, c.nome AS cliente,
       f.nome AS profissional, s.nome AS servico,
       ia.quantidade, ia.valor_unitario_praticado, ia.desconto
FROM atendimento a
JOIN cliente c ON c.id_cliente = a.id_cliente
JOIN funcionario f ON f.id_funcionario = a.id_funcionario
JOIN item_atendimento ia ON ia.id_atendimento = a.id_atendimento
JOIN servico s ON s.id_servico = ia.id_servico
ORDER BY a.data_hora_inicio, a.id_atendimento;

-- UPDATE demonstrativo: altera preço vigente sem alterar o histórico em ITEM_ATENDIMENTO.
UPDATE servico SET preco_atual = 37.00 WHERE id_servico = 1;

-- DELETE demonstrativo: remove apenas um agendamento fictício cancelado.
DELETE FROM agendamento WHERE id_agendamento = 3 AND status = 'CANCELADO';

-- =========================================================
-- CONSULTAS GERENCIAIS
-- =========================================================

-- G01 — Qual foi o total recebido por forma de pagamento no período?
-- Atende: P3, P5 e KPI Receita recebida.
SELECT forma_pagamento, SUM(valor) AS total_recebido
FROM pagamento
WHERE status = 'CONFIRMADO'
  AND data_hora >= '2026-10-01' AND data_hora < '2026-11-01'
GROUP BY forma_pagamento
ORDER BY total_recebido DESC;

-- G02 — Quantos atendimentos foram concluídos por dia?
-- Atende: P1, P2 e KPI Quantidade de atendimentos.
SELECT DATE(data_hora_inicio) AS dia, COUNT(*) AS atendimentos_concluidos
FROM atendimento
WHERE status = 'CONCLUIDO'
  AND data_hora_inicio >= '2026-10-01' AND data_hora_inicio < '2026-11-01'
GROUP BY DATE(data_hora_inicio)
ORDER BY dia;

-- G03 — Qual é o ticket médio por atendimento concluído no período?
-- Atende: KPI Ticket médio. Considera valor líquido dos itens, não o total de pagamentos.
SELECT AVG(total_atendimento) AS ticket_medio
FROM (
  SELECT a.id_atendimento,
         SUM(ia.quantidade * ia.valor_unitario_praticado - ia.desconto) AS total_atendimento
  FROM atendimento a
  JOIN item_atendimento ia ON ia.id_atendimento = a.id_atendimento
  WHERE a.status = 'CONCLUIDO'
    AND a.data_hora_inicio >= '2026-10-01' AND a.data_hora_inicio < '2026-11-01'
  GROUP BY a.id_atendimento
) t;

-- G04 — Quais serviços foram mais realizados no período?
-- Atende: P2 e KPI Serviços mais realizados.
SELECT s.nome, SUM(ia.quantidade) AS quantidade_realizada,
       SUM(ia.quantidade * ia.valor_unitario_praticado - ia.desconto) AS valor_liquido
FROM item_atendimento ia
JOIN atendimento a ON a.id_atendimento = ia.id_atendimento
JOIN servico s ON s.id_servico = ia.id_servico
WHERE a.status = 'CONCLUIDO'
  AND a.data_hora_inicio >= '2026-10-01' AND a.data_hora_inicio < '2026-11-01'
GROUP BY s.id_servico, s.nome
ORDER BY quantidade_realizada DESC;

-- G05 — Quanto de comissão foi apurado por funcionário no período?
-- Atende: P4 e KPI Comissão apurada.
SELECT f.nome,
       SUM((ia.quantidade * ia.valor_unitario_praticado - ia.desconto)
           * ia.percentual_comissao_aplicado / 100) AS comissao_apurada
FROM item_atendimento ia
JOIN atendimento a ON a.id_atendimento = ia.id_atendimento
JOIN funcionario f ON f.id_funcionario = a.id_funcionario
WHERE a.status = 'CONCLUIDO'
  AND a.data_hora_inicio >= '2026-10-01' AND a.data_hora_inicio < '2026-11-01'
GROUP BY f.id_funcionario, f.nome;

-- G06 — Quanto foi efetivamente pago por categoria no mês?
-- Regime de caixa: considera a data em que o pagamento da despesa ocorreu.
SELECT categoria, SUM(valor) AS total_despesas_pagas
FROM despesa
WHERE status = 'PAGA'
  AND data_pagamento >= '2026-10-01' AND data_pagamento < '2026-11-01'
GROUP BY categoria
ORDER BY total_despesas_pagas DESC;

-- G07 — Qual é o resultado operacional simplificado do período?
-- Regime de caixa: entradas por data do recebimento, despesas por data do pagamento
-- e comissões por data do repasse efetivo.
SELECT
  (SELECT COALESCE(SUM(valor),0) FROM pagamento
   WHERE status='CONFIRMADO' AND data_hora >= '2026-10-01' AND data_hora < '2026-11-01')
  -
  (SELECT COALESCE(SUM(valor),0) FROM despesa
   WHERE status='PAGA' AND data_pagamento >= '2026-10-01' AND data_pagamento < '2026-11-01')
  -
  (SELECT COALESCE(SUM(valor_comissao_pago),0)
   FROM item_repasse_comissao ir
   JOIN repasse_comissao r ON r.id_repasse=ir.id_repasse
   WHERE r.status='PAGO' AND r.data_pagamento >= '2026-10-01' AND r.data_pagamento < '2026-11-01')
  AS resultado_operacional_simplificado;

-- G08 — Quantos agendamentos existem por situação no período?
-- Atende: processo de agendamento e KPI Agendamentos.
SELECT status, COUNT(*) AS quantidade
FROM agendamento
WHERE data_hora_inicio >= '2026-12-01' AND data_hora_inicio < '2027-01-01'
GROUP BY status;

-- G09 — Quais materiais estão abaixo do estoque mínimo?
-- Atende: P6 (após confirmação do processo) e KPI Estoque mínimo.
SELECT m.id_material, m.nome, m.unidade_medida, m.estoque_minimo,
       COALESCE(SUM(
         CASE
           WHEN me.tipo IN ('ENTRADA','AJUSTE_ENTRADA') THEN me.quantidade
           WHEN me.tipo IN ('SAIDA','AJUSTE_SAIDA') THEN -me.quantidade
           ELSE 0
         END
       ),0) AS saldo_atual
FROM material m
LEFT JOIN movimentacao_estoque me ON me.id_material = m.id_material
GROUP BY m.id_material, m.nome, m.unidade_medida, m.estoque_minimo
HAVING saldo_atual < m.estoque_minimo
ORDER BY m.nome;

-- =========================================================
-- CONSULTAS DE AUDITORIA
-- =========================================================

-- A01 — Existem atendimentos concluídos sem item de serviço?
-- Verifica: RN01 e RN10.
SELECT a.id_atendimento, a.data_hora_inicio
FROM atendimento a
LEFT JOIN item_atendimento ia ON ia.id_atendimento = a.id_atendimento
WHERE a.status = 'CONCLUIDO'
GROUP BY a.id_atendimento, a.data_hora_inicio
HAVING COUNT(ia.id_item_atendimento) = 0;

-- A02 — Existem atendimentos concluídos cujo valor dos pagamentos confirmados
-- não corresponde ao total líquido dos itens?
-- Verifica: RN02 e RN09. Ajustar a regra se houver pagamentos parciais/pendentes.
SELECT a.id_atendimento,
       COALESCE(i.total_itens,0) AS total_itens,
       COALESCE(p.total_pago,0) AS total_pago
FROM atendimento a
LEFT JOIN (
  SELECT id_atendimento,
         SUM(quantidade * valor_unitario_praticado - desconto) AS total_itens
  FROM item_atendimento GROUP BY id_atendimento
) i ON i.id_atendimento = a.id_atendimento
LEFT JOIN (
  SELECT id_atendimento, SUM(valor) AS total_pago
  FROM pagamento WHERE status = 'CONFIRMADO' GROUP BY id_atendimento
) p ON p.id_atendimento = a.id_atendimento
WHERE a.status = 'CONCLUIDO'
  AND ABS(COALESCE(i.total_itens,0) - COALESCE(p.total_pago,0)) > 0.01;

-- A03 — Existem itens de atendimento com comissão diferente do percentual cadastrado
-- para o funcionário no cadastro atual?
-- Verifica: RN05. Divergência histórica pode ser legítima se o percentual mudou;
-- conferir manualmente antes de corrigir registros antigos.
SELECT ia.id_item_atendimento, f.nome,
       ia.percentual_comissao_aplicado, f.percentual_comissao
FROM item_atendimento ia
JOIN atendimento a ON a.id_atendimento = ia.id_atendimento
JOIN funcionario f ON f.id_funcionario = a.id_funcionario
WHERE ia.percentual_comissao_aplicado <> f.percentual_comissao;

-- A04 — Existem materiais cujo saldo calculado é negativo?
-- Verifica: regra de integridade do estoque (a validar após confirmação do processo).
SELECT m.id_material, m.nome,
       SUM(CASE
         WHEN me.tipo IN ('ENTRADA','AJUSTE_ENTRADA') THEN me.quantidade
         WHEN me.tipo IN ('SAIDA','AJUSTE_SAIDA') THEN -me.quantidade
         ELSE 0
       END) AS saldo_atual
FROM material m
LEFT JOIN movimentacao_estoque me ON me.id_material = m.id_material
GROUP BY m.id_material, m.nome
HAVING COALESCE(saldo_atual, 0) < 0;

