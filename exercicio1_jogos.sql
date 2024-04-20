USE master
CREATE DATABASE exercicio1TriggerVolei
GO
USE exercicio1TriggerVolei
GO
CREATE TABLE Times (
    CodTime INT NOT NULL,
    NomeTime VARCHAR(50) NOT NULL
	PRIMARY KEY (CodTime)
)
GO
CREATE TABLE Jogos (
    CodTimeA INT,
    CodTimeB INT,
    SetTimeA INT,
    SetTimeB INT,
    FOREIGN KEY (CodTimeA) REFERENCES Times(CodTime),
    FOREIGN KEY (CodTimeB) REFERENCES Times(CodTime)
)
GO
INSERT INTO Times (CodTime, NomeTime) VALUES 
(1, 'Time 1'),
(2, 'Time 2'),
(3, 'Time 3'),
(4, 'Time 4');
GO
INSERT INTO Jogos (CodTimeA, CodTimeB, SetTimeA, SetTimeB) VALUES 
(1, 2, 3, 1),
(1, 3, 2, 3),
(1, 4, 3, 2),
(2, 3, 2, 3),
(2, 4, 0, 3),
(3, 4, 3, 1);
GO

CREATE FUNCTION udf_calcularEstatisticas (@CodTime INT)
RETURNS TABLE
AS
RETURN (
    SELECT 
        t.NomeTime AS 'Nome do Time',
        SUM(CASE WHEN j.CodTimeA = @CodTime THEN 
                CASE WHEN j.SetTimeA > j.SetTimeB THEN 2
                     WHEN j.SetTimeA = j.SetTimeB THEN 1
                     ELSE 0
                END
             ELSE
                CASE WHEN j.SetTimeB > j.SetTimeA THEN 2
                     WHEN j.SetTimeB = j.SetTimeA THEN 1
                     ELSE 0
                END
             END) AS 'Total de Pontos',
        SUM(CASE WHEN j.CodTimeA = @CodTime THEN j.SetTimeA
                 ELSE j.SetTimeB
             END) AS 'Total de Sets Ganhos',
        SUM(CASE WHEN j.CodTimeA = @CodTime THEN j.SetTimeB
                 ELSE j.SetTimeA
             END) AS 'Total de Sets Perdidos',
        CAST(SUM(CASE WHEN j.CodTimeA = @CodTime THEN j.SetTimeA
                      ELSE j.SetTimeB
                 END) AS DECIMAL(5,2)) -
        CAST(SUM(CASE WHEN j.CodTimeA = @CodTime THEN j.SetTimeB
                      ELSE j.SetTimeA
                 END) AS DECIMAL(5,2)) AS 'Set Average'
    FROM 
        Jogos j
    INNER JOIN 
        Times t ON j.CodTimeA = t.CodTime OR j.CodTimeB = t.CodTime
    WHERE 
        j.CodTimeA = @CodTime OR j.CodTimeB = @CodTime
    GROUP BY 
        t.NomeTime
);
GO

CREATE TRIGGER t_verificajogos ON jogos
AFTER INSERT
AS
BEGIN
    DECLARE @NumSets INT;
    DECLARE @Vencedor INT;
    DECLARE @Perdedor INT;

    SELECT @NumSets = SUM(SetTimeA + SetTimeB) FROM inserted;

    IF @NumSets > 5
    BEGIN
        RAISERROR('Número máximo de sets excedido. Máximo permitido: 5.', 16, 1);
        ROLLBACK TRANSACTION;
        RETURN;
    END;

    SELECT @Vencedor = CASE WHEN i.SetTimeA > i.SetTimeB THEN i.CodTimeA
                             ELSE i.CodTimeB
                        END,
           @Perdedor = CASE WHEN i.SetTimeA < i.SetTimeB THEN i.CodTimeA
                             ELSE i.CodTimeB
                        END
    FROM INSERTED i;

    IF (SELECT CASE WHEN @Vencedor = i.CodTimeA THEN i.SetTimeA
                    ELSE i.SetTimeB
               END FROM inserted i) > 3
    BEGIN
        RAISERROR('Número máximo de sets para o vencedor excedido. Máximo permitido: 3.', 16, 1);
        ROLLBACK TRANSACTION;
        RETURN;
    END;
END;

-- Teste de Inserção Valido
INSERT INTO jogos VALUES 
(1, 2, 3, 1);

-- Teste de Inserção Invalido
INSERT INTO jogos VALUES 
(1, 2, 3, 1),
(1, 2, 2, 3),
(1, 2, 3, 2),
(1, 2, 1, 3),
(1, 2, 0, 3),
(1, 2, 3, 0);

-- teste de número maximo de 3 sets 
INSERT INTO jogos VALUES 
(1, 2, 4, 1);
