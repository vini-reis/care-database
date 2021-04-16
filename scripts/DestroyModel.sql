DROP TABLE IF EXISTS 
    CARE.Agendamento,
    CARE.Ala,
    CARE.Atendimento,
    CARE.Cobertura,
    CARE.Convenio,
    CARE.Diagnostico,
    CARE.Exame,
	CARE.Funcionario,
    CARE.Hospital,
    CARE.Internacao,
    CARE.Laboratorio,
    CARE.Medico,
    CARE.Paciente,
    CARE.Ponto,
    CARE.Resultado,
    CARE.Sala,
    CARE.Solicitacao;

DROP FUNCTION IF EXISTS isCRMValid;
DROP FUNCTION IF EXISTS isUTI;
DROP FUNCTION IF EXISTS examIsCovered;
DROP FUNCTION IF EXISTS examsExists;
DROP FUNCTION IF EXISTS Teste1;
DROP FUNCTION IF EXISTS Teste21;

DROP SCHEMA IF EXISTS CARE;