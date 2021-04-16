-- Teste 01
-- Exames cobertos
-- DROP FUNCTION teste1;
CREATE OR REPLACE FUNCTION Teste1 (conv int, lab int)
RETURNS TABLE (CodExames text) AS $$
SELECT UNNEST(CodExamesCobertos) FROM CARE.laboratorio WHERE CodLab = lab
INTERSECT
SELECT UNNEST(CodExamesCobertos) FROM CARE.Convenio WHERE CodConvenio = conv;
$$ LANGUAGE SQL;

-- Teste 02-1

-- Consultas normais
-- DROP FUNCTION Teste21;
CREATE OR REPLACE FUNCTION Teste21 (pac int) 
RETURNS TABLE (
    CodAtendimento text,
    crm text,
    datahora timestamp,
    codpac int,
    boolretorno boolean
) AS $$ SELECT * FROM CARE.Atendimento WHERE CodPac = pac AND NOT BoolRetorno; $$
LANGUAGE SQL;

-- Retornos
-- DROP FUNCTION Teste22;
CREATE OR REPLACE FUNCTION Teste22 (pac int) 
RETURNS TABLE (
    CodAtendimento int,
    crm text,
    datahora timestamp,
    codpac int,
    boolretorno boolean
) AS $$ SELECT * FROM CARE.Atendimento WHERE CodPac = pac AND BoolRetorno; $$
LANGUAGE SQL;

-- Teste 3
-- DROP FUNCTION Teste3;
CREATE OR REPLACE FUNCTION Teste3 (pac int)
RETURNS TABLE (
    CodSolicitacao int,
    DataHoraEmissao timestamp,
    CRM text,
    CodSala int,
    CodPac int
) AS $$
SELECT * FROM CARE.Solicitacao WHERE CodPac = pac;
$$ LANGUAGE SQL;

-- Teste 4
-- Dias de trabalho em certa ala
-- DROP FUNCTION Teste41;
CREATE OR REPLACE FUNCTION Teste41 (func int, ala int)
RETURNS TABLE (
    CodPonto int,
    CodFunc int,
    DataHoraEntrada timestamp,
    DataHoraSaida timestamp,
    CodHospital int,
    CodAla int,
    BoolCoberto boolean,
    CodFuncSubstituto int
) AS $$
SELECT * FROM CARE.Ponto WHERE CodAla = ala AND CodFunc = func
$$ LANGUAGE SQL;

-- Dias de trabalho em certa ala em que foi substituído, e por quem
-- DROP FUNCTION Teste42;
CREATE OR REPLACE FUNCTION Teste42 (func int, ala int)
RETURNS TABLE (
    DataSubstituido date,
    CodFuncSubstituto int
) AS $$
SELECT 
    DataHoraEntrada::DATE,
    CodFuncSubstituto
FROM Teste41(func, ala)
WHERE BoolCoberto
$$ LANGUAGE SQL;

-- Teste 5
-- Existem salas em determinado andar
-- DROP FUNCTION Teste5;
CREATE OR REPLACE FUNCTION Teste5(andar int)
RETURNS TABLE (
    CodSala int,
    CodAla int,
    Especialidade text,
    NumSala int,
    NumAndar int
) AS $$
SELECT
    *
FROM CARE.Sala
WHERE NumAndar = andar
$$ LANGUAGE SQL;

-- Execução dos testes
-- SELECT * FROM Teste1(1,1);
-- SELECT * FROM Teste22(3);
-- SELECT * FROM Teste3(3);
-- SELECT * FROM Teste41(1,1);
-- SELECT * FROM Teste42(1,1);
SELECT * FROM Teste5(3);