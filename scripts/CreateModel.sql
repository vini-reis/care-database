-- Creating schema:
CREATE SCHEMA CARE
    AUTHORIZATION postgres;

COMMENT ON SCHEMA CARE
    IS 'CARE Health System Database';

GRANT ALL ON SCHEMA CARE TO postgres;

-- Creating tables:
CREATE TABLE CARE.Hospital (
    CodHospital         SMALLSERIAL
        CONSTRAINT PkProd PRIMARY KEY,
    NomeHospital        VARCHAR (100) NOT NULL
);

CREATE TABLE CARE.Ala (
    CodAla              SMALLSERIAL
        CONSTRAINT PkAlas PRIMARY KEY,
    CodHospital         SMALLINT NOT NULL,
    NomeAla             VARCHAR (50) NOT NULL,
    Tipo                VARCHAR (30) NOT NULL
);

CREATE TABLE CARE.Sala (
    CodSala             SMALLSERIAL
        CONSTRAINT PkSalas PRIMARY KEY,
    CodAla              SMALLINT NOT NULL,
    Especialidade       VARCHAR (30),
    NumSala             NUMERIC (2),
    NumAndar            NUMERIC (2) NOT NULL
        CONSTRAINT ValidFloor CHECK (NumAndar >= 0 AND NumAndar != 13)
);

CREATE TABLE CARE.Funcionario (
    CodFunc             SMALLSERIAL
        CONSTRAINT PkFunc PRIMARY KEY,
    Nome                VARCHAR (75) NOT NULL,
    Endereco            VARCHAR (200) NOT NULL,
    Telefone            VARCHAR (15) NOT NULL,
    DataContatacao      DATE NOT NULL
);

CREATE TABLE CARE.Medico (
    CodFunc             SMALLINT NOT NULL,
    CRM                 VARCHAR (13) NOT NULL,
    Especialidade       VARCHAR (50) NOT NULL
);

CREATE TABLE CARE.Ponto (
    CodPonto            SERIAL,
    CodFunc             SMALLINT,
    DataHoraEntrada     TIMESTAMP NOT NULL,
    DataHoraSaida       TIMESTAMP NOT NULL,
    CodHospital         SMALLINT NOT NULL,
    CodAla              SMALLINT NOT NULL,
    BoolCoberto         BOOLEAN DEFAULT FALSE,
    CodFuncSubstituto   SMALLINT
        CONSTRAINT isCover CHECK (NOT BoolCoberto AND CodFuncSubstituto IS NULL OR BoolCoberto AND CodFuncSubstituto IS NOT NULL)
);

CREATE TABLE CARE.Paciente (
    CodPac              SERIAL
        CONSTRAINT PkPac PRIMARY KEY,
    Nome                VARCHAR (75) NOT NULL,
    Endereco            VARCHAR (200) NOT NULL,
    DataNascimento      DATE NOT NULL,
    CodGenero           VARCHAR (1) NOT NULL
        CONSTRAINT ValidGender CHECK (CodGenero = ANY(ARRAY['M', 'F', 'O'])),
    CodConvenio         NUMERIC (3),
    CodSUS              VARCHAR (15)
);

CREATE TABLE CARE.Atendimento (
    CodAtendimento      SERIAL
        CONSTRAINT PkAtend PRIMARY KEY,
    CRM                 VARCHAR(13) NOT NULL, -- Editar no conceitual
    DataHora            TIMESTAMP NOT NULL,
    CodPac              INT NOT NULL,
    BoolRetorno         BOOLEAN NOT NULL
);

CREATE TABLE CARE.Diagnostico (
    CodDiag             SERIAL
        CONSTRAINT PkDiag PRIMARY KEY,
    CRM                 VARCHAR (13) NOT NULL, 
    DataHoraDiag        TIMESTAMP NOT NULL,
    CodPac              INT NOT NULL,
    Tipo                VARCHAR (50) NOT NULL,
    Complicacoes        VARCHAR (50),
    Precaucoes          VARCHAR (50)
);

CREATE TABLE CARE.Agendamento (
    CodAgendamento      SERIAL
        CONSTRAINT PkAgend PRIMARY KEY,
    CodPac              INT NOT NULL,
    DataHora            TIMESTAMP NOT NULL
        CONSTRAINT ValidTmp CHECK (DataHora >= CURRENT_TIMESTAMP),
    CodExame            NUMERIC (4) NOT NULL,
    CodLab              SMALLINT NOT NULL
);

CREATE TABLE CARE.Convenio (
    CodConvenio SMALLSERIAL
        CONSTRAINT PkConv PRIMARY KEY,
    CodExamesCobertos NUMERIC (4) [] NOT NULL
);

CREATE TABLE CARE.Laboratorio (
    CodLab              SMALLSERIAL
        CONSTRAINT PkLab PRIMARY KEY,
    NomeLab              VARCHAR (50) NOT NULL,
    Endereco             VARCHAR (200) NOT NULL,
    Telefone             VARCHAR (15) NOT NULL,
    CodConveniosCobertos NUMERIC (3) [] NOT NULL, -- TODO: Alterar no ModeloConceitual
    DataContrato         DATE NOT NULL,
    CodExamesCobertos    NUMERIC (4) [] NOT NULL
);

CREATE TABLE CARE.Solicitacao (
    CodSolicitacao      SERIAL
        CONSTRAINT PkSolic PRIMARY KEY,
    DataHoraEmissao     TIMESTAMP NOT NULL,
        CONSTRAINT ValidDate CHECK (DataHoraEmissao >= CURRENT_TIMESTAMP),
    CRM                 VARCHAR (13) NOT NULL,
    CodSala             SMALLINT NOT NULL,
    CodPac              INT NOT NULL
);

CREATE TABLE CARE.Internacao (
    CodInternacao      SERIAL
        CONSTRAINT PkInter PRIMARY KEY,
    CodSolicitacao     INT NOT NULL,
    DataHoraEntrada    TIMESTAMP NOT NULL,
    CodSala            SMALLINT NOT NULL
);

CREATE TABLE CARE.Exame (
    CodExame            NUMERIC (4) NOT NULL,
    NomeExame           VARCHAR (50) NOT NULL,
    CodLab              SMALLINT NOT NULL,
    ValorPreco          MONEY NOT NULL
);

CREATE TABLE CARE.Resultado (
    CodAgendamento      INT NOT NULL,
    CodResultado        SERIAL
        CONSTRAINT PkRes PRIMARY KEY,
    Tipo                VARCHAR (50) NOT NULL,
    Resumo              VARCHAR(100) NOT NULL,
    Descricao           VARCHAR (2000)
);

-- Functions:
-- Funções criadas depois para não correr o risco de serem afetadas pela falta
-- do modelo, já que algumas o consultam.
CREATE FUNCTION isCRMValid (CRM text) RETURNS BOOLEAN AS $$
    SELECT UPPER(substring(CRM from position('/' in CRM)+1 for 13)) = ANY(ARRAY['AC','AL','AP','AM','BA','CE','DF','ES','GO','MA','MT','MS','MG','PA','PB','PR','PE','PI','RJ','RN','RS','RO','RR','SC','SP','SE','TO'])
$$ LANGUAGE SQL;

CREATE FUNCTION isUTI (cod integer) RETURNS BOOLEAN AS $$
SELECT 
    cod IN (
        SELECT CodSala FROM CARE.Sala JOIN (
            SELECT * From care.ala where tipo = 'Internação'
        ) AS Alas 
        ON CARE.Sala.CodAla = Alas.CodAla
    )
$$ LANGUAGE SQL;

CREATE FUNCTION examIsCovered (exam numeric, lab integer) RETURNS BOOLEAN AS $$
SELECT
    exam = ANY(ARRAY(
        SELECT CodExamesCobertos FROM CARE.Laboratorio WHERE CodLab = lab
    ))
$$ LANGUAGE SQL;

CREATE FUNCTION examsExists (exams numeric[]) RETURNS BOOLEAN AS $$
SELECT
    exams <@ ARRAY(SELECT CodExame FROM CARE.Exame)
$$ LANGUAGE SQL;

-- Criando as restrições
-- A criação das restrições foi feita depois por dependerem de algumas funções definidas depois do modelo.
ALTER TABLE CARE.Ala ADD CONSTRAINT FkHosp FOREIGN KEY (CodHospital) REFERENCES CARE.Hospital (CodHospital);

ALTER TABLE CARE.Sala ADD CONSTRAINT FkAla FOREIGN KEY (CodAla) REFERENCES CARE.Ala (CodAla);

ALTER TABLE CARE.Medico ADD CONSTRAINT ValidUF CHECK (isCRMValid(CRM));
ALTER TABLE CARE.Medico ADD CONSTRAINT FkFunc FOREIGN KEY (CodFunc) REFERENCES CARE.Funcionario (CodFunc);
ALTER TABLE CARE.Medico ADD CONSTRAINT CRMUnique UNIQUE (CRM);

ALTER TABLE CARE.Ponto ADD CONSTRAINT FkFunc FOREIGN KEY (CodFunc) REFERENCES CARE.Funcionario (CodFunc);
ALTER TABLE CARE.Ponto ADD CONSTRAINT FkHosp FOREIGN KEY (CodHospital) REFERENCES CARE.Hospital (CodHospital);
ALTER TABLE CARE.Ponto ADD CONSTRAINT FkAla FOREIGN KEY (CodAla) REFERENCES CARE.Ala (CodAla);
ALTER TABLE CARE.Ponto ADD CONSTRAINT FkFuncSubs FOREIGN KEY (CodFuncSubstituto) REFERENCES CARE.Funcionario (CodFunc);

ALTER TABLE CARE.Atendimento ADD CONSTRAINT FkPac FOREIGN KEY (CodPac) REFERENCES CARE.Paciente (CodPac);
ALTER TABLE CARE.Atendimento ADD CONSTRAINT FkCRM FOREIGN KEY (CRM) REFERENCES CARE.Medico (CRM);

ALTER TABLE CARE.Diagnostico ADD CONSTRAINT FkPac FOREIGN KEY (CodPac) REFERENCES CARE.Paciente (CodPac);
ALTER TABLE CARE.Diagnostico ADD CONSTRAINT FkCRM FOREIGN KEY (CRM) REFERENCES CARE.Medico (CRM);

ALTER TABLE CARE.Exame ADD CONSTRAINT FkLab FOREIGN KEY (CodLab) REFERENCES CARE.Laboratorio (CodLab);

ALTER TABLE CARE.Agendamento ADD CONSTRAINT FkPac FOREIGN KEY (CodPac) REFERENCES CARE.Paciente (CodPac);
ALTER TABLE CARE.Agendamento ADD CONSTRAINT FkLab FOREIGN KEY (CodLab) REFERENCES CARE.Laboratorio (CodLab);
ALTER TABLE CARE.Agendamento ADD CONSTRAINT ValidExam CHECK (examIsCovered(CodExame, CodLab));

ALTER TABLE CARE.Convenio ADD CONSTRAINT ExamsExists CHECK (examsExists(CodExamesCobertos));

ALTER TABLE CARE.Solicitacao ADD CONSTRAINT FkPac FOREIGN KEY (CodPac) REFERENCES CARE.Paciente (CodPac);
ALTER TABLE CARE.Solicitacao ADD CONSTRAINT FkCRM FOREIGN KEY (CRM) REFERENCES CARE.Medico (CRM);
ALTER TABLE CARE.Solicitacao ADD CONSTRAINT FkSala FOREIGN KEY (CodSala) REFERENCES CARE.Sala (CodSala);
ALTER TABLE CARE.Solicitacao ADD CONSTRAINT ValidUTI CHECK (isUTI(CodSala));

ALTER TABLE CARE.Internacao ADD CONSTRAINT FkSolic FOREIGN KEY (CodSolicitacao) REFERENCES CARE.Solicitacao (CodSolicitacao);
ALTER TABLE CARE.Internacao ADD CONSTRAINT FkSala FOREIGN KEY (CodSala) REFERENCES CARE.Sala (CodSala);
ALTER TABLE CARE.Internacao ADD CONSTRAINT ValidUTI CHECK (isUTI(CodSala));

ALTER TABLE CARE.Resultado ADD CONSTRAINT ValidAppoint FOREIGN KEY (CodAgendamento) REFERENCES CARE.Agendamento (CodAgendamento);

-- Inserting values:
INSERT INTO CARE.Hospital (NomeHospital) 
VALUES
    ('Hospital Bartira'),
    ('Hospital Brasil'),
    ('Hospital da Mulher');

INSERT INTO CARE.Ala (CodHospital, NomeAla, Tipo)
VALUES
    (1, 'UTI Nivel 1', 'Internação'),
    (1, 'UTI Nivel 2', 'Internação'),
    (1, 'Cirurgia 1', 'Cirurgia'),
    (1, 'Cirurgia 2', 'Cirurgia'),
    (1, 'Cardiologia', 'Atendimento'),
    (1, 'Ortopedia', 'Atendimento'),
    (1, 'Quartos', 'Internação'),
    (1, 'Pediatria', 'Atendimento'),
    (2, 'UTI Nivel 1', 'Internação'),
    (2, 'UTI Nivel 2', 'Internação'),
    (2, 'Cirurgia 1', 'Cirurgia'),
    (2, 'Cirurgia 2', 'Cirurgia'),
    (2, 'Cardiologia', 'Atendimento'),
    (2, 'Ortopedia', 'Atendimento'),
    (2, 'Quartos', 'Internação'),
    (2, 'Pediatria', 'Atendimento'),
    (3, 'UTI Nivel 1', 'Internação'),
    (3, 'UTI Nivel 2', 'Internação'),
    (3, 'Cirurgia 1', 'Cirurgia'),
    (3, 'Cirurgia 2', 'Cirurgia'),
    (3, 'Cardiologia', 'Atendimento'),
    (3, 'Ortopedia', 'Atendimento'),
    (3, 'Quartos', 'Internação'),
    (3, 'Pediatria', 'Atendimento');

INSERT INTO CARE.Sala (Especialidade, CodAla, NumSala, NumAndar)
VALUES
    ('Ortopedia', 3, 1, 3),
    ('Cardiologia', 3, 1, 3),
    ('Ortopedia', 4, 2, 6),
    ('Atendimento', 5, 1, 5),
    ('Atendimento', 5, 2, 5),
    ('Atendimento', 5, 3, 5),
    ('Atendimento', 6, 1, 8),
    ('Atendimento', 6, 2, 8),
    ('Atendimento', 6, 3, 8),
    ('Atendimento', 8, 1, 2),
    ('Atendimento', 8, 2, 2),
    ('Atendimento', 8, 3, 2),
    ('Quarto', 7, 1, 5);

INSERT INTO CARE.Funcionario (Nome, Endereco, Telefone, DataContatacao)
VALUES
    ('João da Silva', 'Rua das Praças, 123 - Vila Rica, SP', '(11) 91234-6579', '1990-01-31'),
    ('Maria das Graças', 'Rua da Alegia, 1230 - São Caetano do Sul, SP', '(11) 93544-6554', '2020-01-31'),
    ('Rodrigo Batisa', 'Av Rebouças, 12 - São Paulo, SP', '(11) 95498-4135', '2010-04-16'),
    ('Renata Rodrigues', 'Av Paes de Barros, 123 - Vila Industrial, SP', '(11) 96484-2649', '2016-08-23'),
    ('Arnaldo Paes', 'Rua Londres, 9123 - Santo André, SP', '(11) 96497-0354', '2008-05-06'),
    ('Arlindo Jesus', 'Rua Paris, 1235 - Vila Joice, SP', '(11) 96497-0354', '2012-09-16'),
    ('Justino Rua', 'Rua Brasil, 265 - Reino de Jah, SP', '(11) 96497-0354', '2001-11-19'),
    ('Carlos Rosti', 'Rua Curitiba, 3654 - Campinas, SP', '(11) 96497-0354', '2000-12-21'),
    ('Arnaldo Paes', 'Rua Rito, 78 - Carijos, SP', '(11) 96497-0354', '2004-05-06'),
    ('John Doe', 'Rua Riacho, 96 - São Paulo, SP', '(11) 96594-1354', '2012-10-12');

-- Insert de médicos pressupõe que o registro de médico estará amarrado com 
-- o de funcionario na aplicação

INSERT INTO CARE.Medico (CodFunc, CRM, Especialidade)
VALUES 
    (4, '12356448-9/SP', 'Pediatra'),
    (5, '64897464-6/SP', 'Ortopedista'),
    (6, '13465987-3/SP', 'Cardiologista'),
    (7, '96487413-2/SP', 'Infectologista');

INSERT INTO CARE.Ponto (CodFunc, DataHoraEntrada, DataHoraSaida, CodHospital, CodAla, BoolCoberto, CodFuncSubstituto)
VALUES
    (1, '2021-04-12 09:05:00', '2021-04-12 18:07:00', 1, 1, FALSE, NULL),
    (1, '2021-04-13 09:02:00', '2021-04-13 18:20:00', 1, 1, FALSE, NULL),
    (1, '2021-04-14 09:01:00', '2021-04-14 18:23:00', 1, 1, FALSE, NULL),
    (1, '2021-04-15 09:32:00', '2021-04-15 18:04:00', 1, 1, FALSE, NULL),
    (2, '2021-04-12 09:05:00', '2021-04-12 18:07:00', 1, 2, FALSE, NULL),
    (2, '2021-04-13 09:02:00', '2021-04-13 18:20:00', 1, 2, FALSE, NULL),
    (2, '2021-04-14 09:01:00', '2021-04-14 18:23:00', 1, 2, FALSE, NULL),
    (2, '2021-04-15 09:32:00', '2021-04-15 18:04:00', 1, 2, FALSE, NULL),
    (3, '2021-04-12 09:05:00', '2021-04-12 18:07:00', 1, 3, FALSE, NULL),
    (3, '2021-04-13 09:02:00', '2021-04-13 18:20:00', 1, 3, FALSE, NULL),
    (3, '2021-04-14 09:01:00', '2021-04-14 18:23:00', 1, 3, FALSE, NULL),
    (3, '2021-04-15 09:32:00', '2021-04-15 18:04:00', 1, 3, FALSE, NULL),
    (4, '2021-04-12 09:05:00', '2021-04-12 18:07:00', 1, 5, FALSE, NULL),
    (4, '2021-04-13 09:02:00', '2021-04-13 18:20:00', 1, 5, FALSE, NULL),
    (4, '2021-04-14 09:01:00', '2021-04-14 18:23:00', 1, 5, FALSE, NULL),
    (4, '2021-04-15 09:32:00', '2021-04-15 18:04:00', 1, 5, FALSE, NULL),
    (5, '2021-04-12 09:05:00', '2021-04-12 18:07:00', 1, 3, FALSE, NULL),
    (5, '2021-04-13 09:02:00', '2021-04-13 18:20:00', 1, 3, FALSE, NULL),
    (5, '2021-04-14 09:01:00', '2021-04-14 18:23:00', 1, 3, FALSE, NULL),
    (5, '2021-04-15 09:32:00', '2021-04-15 18:04:00', 1, 3, FALSE, NULL),
    (6, '2021-04-12 09:05:00', '2021-04-12 18:07:00', 1, 2, FALSE, NULL),
    (6, '2021-04-13 09:02:00', '2021-04-13 18:20:00', 1, 2, FALSE, NULL),
    (6, '2021-04-14 09:01:00', '2021-04-14 18:23:00', 1, 2, FALSE, NULL),
    (6, '2021-04-15 09:32:00', '2021-04-15 18:04:00', 1, 2, FALSE, NULL),
    (1, '2021-04-09 08:57:47', '2021-04-09 18:40:32', 1, 1, TRUE, 3),
    (4, '2021-04-09 05:37:40', '2021-04-09 15:59:10', 1, 1, TRUE, 2);

INSERT INTO CARE.Paciente (Nome, Endereco, DataNascimento, CodGenero, CodSUS)
VALUES
    ('Vinícius de Oliveira Campos dos Reis', 'Rua Lima, 123 - Vila IVG, SP', '1997-01-16', 'M', '7984619479'),
    ('Eduardo Prado', 'Rua Luma, 64 - Diadema, SP', '1996-02-22', 'M', '7984619479'),
    ('Rafael Batista', 'Rua Raio de Sol, 51 - Jundiaí, SP', '1987-04-01', 'M', '7984619479'),
    ('Tatiane Lima', 'Rua Rubens, 1346 - Jurerema, SP', '1970-10-28', 'F', '7984619479'),
    ('Leonardo Lins', 'Rua Rudge, 9685 - Praia Grande, SP', '2000-11-10', 'M', '7984619479'),
    ('Fabio Cruz', 'Rua Rota, 64 - Santos, SP', '1990-10-20', 'O', '7984619479'),
    ('Carol Lens', 'Rua Raizes, 11 - Guarujá, SP', '1950-01-03', 'M', '7984619479');

INSERT INTO CARE.Atendimento (CRM, DataHora, CodPac, BoolRetorno)
VALUES
    ('64897464-6/SP','2021-04-14 13:00:00', 1, FALSE),
    ('96487413-2/SP','2021-04-12 13:00:00', 3, FALSE),
    ('96487413-2/SP','2021-04-20 13:00:00', 3, TRUE);

INSERT INTO CARE.Diagnostico (CRM, CodPac, DataHoraDiag, Tipo, Complicacoes, Precaucoes)
VALUES
    ('12356448-9/SP', 1, CURRENT_TIMESTAMP, 'Primeira consulta', NULL, 'Reduzir ingestão de glútem'),
    ('64897464-6/SP', 2, CURRENT_TIMESTAMP, 'Primeira consulta', 'Lesão no pulso esquerdo', 'Repouso e inclusão de tala'),
    ('13465987-3/SP', 2, CURRENT_TIMESTAMP, 'Retorno pós-exames', NULL, 'Não praticar exercícios pesados'),
    ('13465987-3/SP', 3, CURRENT_TIMESTAMP, 'Primeira consulta', 'Dor no estômago', 'Tomar os remédios indicados'),
    ('12356448-9/SP', 4, CURRENT_TIMESTAMP, 'Primeira consulta', NULL, NULL);

INSERT INTO CARE.Laboratorio (NomeLab, Endereco, Telefone, CodConveniosCobertos, DataContrato, CodExamesCobertos)
VALUES
    ('Lavoisier São Caetano', 'Rua Alegre, 987 - São Caetano, SP', '(11) 4613-4647', '{1,3}', '2018-02-01', '{1,2}'),
    ('Lavoisier Bartira', 'Rua Chile, 987 - Santo André, SP', '(11) 4337-4647', '{2,3}', '2016-02-01', '{1}'),
    ('Delboni Santo André', 'Av Industrial, 1649 - Santo André, SP', '(11) 4264-6597', '{1,2,3}', '2016-02-01', '{1,2,3}');

INSERT INTO CARE.Exame (CodExame, NomeExame, CodLab, ValorPreco)
VALUES
    (1, 'Radiografia', 1, 150.00),
    (1, 'Radiografia', 2, 175.00),
    (1, 'Radiografia', 3, 200.00),
    (2, 'Endoscopia', 1, 300.00),
    (2, 'Endoscopia', 3, 275.00),
    (3, 'Biópsia', 3, 500.00);

INSERT INTO CARE.Agendamento (CodPac, DataHora, CodExame, CodLab)
VALUES
    (2, '2021-04-25 17:00:00', 1, 1),
    (3, '2021-05-01 10:00:00', 2, 3),
    (3, '2021-04-29 11:30:00', 1, 2);

INSERT INTO CARE.Convenio (CodExamesCobertos)
VALUES
    ('{1,2,3}'),
    ('{1,2}'),
    ('{1,3}');

INSERT INTO CARE.Solicitacao (DataHoraEmissao, CRM, CodSala, CodPac)
VALUES
    (CURRENT_TIMESTAMP, '13465987-3/SP', 13, 3);

INSERT INTO CARE.Internacao (CodSolicitacao, DataHoraEntrada, CodSala)
VALUES
    (1, CURRENT_TIMESTAMP, 13);

INSERT INTO CARE.Resultado (CodAgendamento, Tipo, Resumo, Descricao)
VALUES
    (1, 'Radiografia', 'Sem anomalias', NULL),
    (2, 'Endoscopia', 'Alterações encontradas', 'A região lateral esquerda do estômago apresenta lesões de grau II. \n\nO paciente precisa ser internado e tratado imediatamente!');
