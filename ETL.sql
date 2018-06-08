IF DB_ID('DWTrabalho') IS NULL
	CREATE DATABASE DWTrabalho;
GO

USE DWTrabalho;
GO

IF OBJECT_ID('FK_FatoAr_DimTempo') IS NOT NULL
	ALTER TABLE FatoAr DROP CONSTRAINT FK_FatoAr_DimTempo;
GO

IF OBJECT_ID('FK_FatoAr_DimLocal') IS NOT NULL
	ALTER TABLE FatoAr DROP CONSTRAINT FK_FatoAr_DimLocal;
GO

IF OBJECT_ID('FK_FatoAr_DimPM') IS NOT NULL
	ALTER TABLE FatoAr DROP CONSTRAINT FK_FatoAr_DimPM;
GO

IF OBJECT_ID('FK_FatoCancer_DimTempo') IS NOT NULL
	ALTER TABLE FatoCancer DROP CONSTRAINT FK_FatoCancer_DimTempo;
GO

IF OBJECT_ID('FK_FatoCancer_DimLocal') IS NOT NULL
	ALTER TABLE FatoCancer DROP CONSTRAINT FK_FatoCancer_DimLocal;
GO

IF OBJECT_ID('FK_FatoCancer_DimPessoa') IS NOT NULL
	ALTER TABLE FatoCancer DROP CONSTRAINT FK_FatoCancer_DimPessoa;
GO

IF OBJECT_ID('FK_FatoCancer_DimCancer') IS NOT NULL
	ALTER TABLE FatoCancer DROP CONSTRAINT FK_FatoCancer_DimCancer;
GO

IF OBJECT_ID('FK_FatoPopulacao_DimTempo') IS NOT NULL
	ALTER TABLE FatoPopulacao DROP CONSTRAINT FK_FatoPopulacao_DimTempo;
GO

IF OBJECT_ID('FK_FatoPopulacao_DimLocal') IS NOT NULL
	ALTER TABLE FatoPopulacao DROP CONSTRAINT FK_FatoPopulacao_DimLocal;
GO

IF OBJECT_ID('FK_FatoPopulacao_DimPessoa') IS NOT NULL
	ALTER TABLE FatoPopulacao DROP CONSTRAINT FK_FatoPopulacao_DimPessoa;
GO

IF OBJECT_ID('DimTempo') IS NOT NULL
	DROP TABLE DimTempo;
GO

CREATE TABLE DimTempo (
	idTempo INT IDENTITY,
	Ano INT,
	CONSTRAINT PK_DimTempo PRIMARY KEY (idTempo)
);
GO

IF OBJECT_ID('DimLocal') IS NOT NULL
	DROP TABLE DimLocal;
GO

CREATE TABLE DimLocal (
	idLocal INT IDENTITY,
	Estado VARCHAR(100),
	CONSTRAINT PK_DimLocal PRIMARY KEY (idLocal)
);
GO

IF OBJECT_ID('DimPessoa') IS NOT NULL
	DROP TABLE DimPessoa;
GO

CREATE TABLE DimPessoa (
	idPessoa INT IDENTITY,
	Raca VARCHAR(100),
	Sexo VARCHAR(6),
	CONSTRAINT PK_DimPessoa PRIMARY KEY (idPessoa)
);
GO

IF OBJECT_ID('DimCancer') IS NOT NULL
	DROP TABLE DimCancer;
GO

CREATE TABLE DimCancer (
	idCancer INT IDENTITY,
	Tipo VARCHAR(100),
	CONSTRAINT PK_DimCancer PRIMARY KEY (idCancer)
);
GO

IF OBJECT_ID('DimPM') IS NOT NULL
	DROP TABLE DimPM;
GO

CREATE TABLE DimPM (
	idPM INT IDENTITY,
	Nome VARCHAR(100),
	CONSTRAINT PK_DimPM PRIMARY KEY (idPM)
);
GO

IF OBJECT_ID('FatoAr') IS NOT NULL
	DROP TABLE FatoAr;
GO

CREATE TABLE FatoAr (
	idTempo INT,
	idLocal INT,
	idPM INT,
	Media FLOAT,
	CONSTRAINT FK_FatoAr_DimTempo FOREIGN KEY (idTempo)
		REFERENCES DimTempo(idTempo),
	CONSTRAINT FK_FatoAr_DimLocal FOREIGN KEY (idLocal)
		REFERENCES DimLocal(idLocal),
	CONSTRAINT FK_FatoAr_DimPM FOREIGN KEY (idPM)
		REFERENCES DimPM(idPM),
	CONSTRAINT PK_FatoAr PRIMARY KEY (idTempo, idLocal, idPM)
);
GO

IF OBJECT_ID('FatoCancer') IS NOT NULL
	DROP TABLE FatoCancer;
GO

CREATE TABLE FatoCancer (
	idTempo INT,
	idLocal INT,
	idPessoa INT,
	idCancer INT,
	NumIncidencias INT,
	NumMortes INT,
	CONSTRAINT FK_FatoCancer_DimTempo FOREIGN KEY (idTempo)
		REFERENCES DimTempo(idTempo),
	CONSTRAINT FK_FatoCancer_DimLocal FOREIGN KEY (idLocal)
		REFERENCES DimLocal(idLocal),
	CONSTRAINT FK_FatoCancer_DimPessoa FOREIGN KEY (idPessoa)
		REFERENCES DimPessoa(idPessoa),
	CONSTRAINT FK_FatoCancer_DimCancer FOREIGN KEY (idCancer)
		REFERENCES DimCancer(idCancer),
	CONSTRAINT PK_FatoCancer PRIMARY KEY (idTempo, idLocal, idPessoa, idCancer)
);
GO

IF OBJECT_ID('FatoPopulacao') IS NOT NULL
	DROP TABLE FatoPopulacao;
GO

CREATE TABLE FatoPopulacao (
	idTempo INT,
	idLocal INT,
	idPessoa INT,
	Populacao INT,
	CONSTRAINT FK_FatoPopulacao_DimTempo FOREIGN KEY (idTempo)
		REFERENCES DimTempo(idTempo),
	CONSTRAINT FK_FatoPopulacao_DimLocal FOREIGN KEY (idLocal)
		REFERENCES DimLocal(idLocal),
	CONSTRAINT FK_FatoPopulacao_DimPessoa FOREIGN KEY (idPessoa)
		REFERENCES DimPessoa(idPessoa),
	CONSTRAINT PK_FatoPopulacao PRIMARY KEY (idTempo, idLocal, idPessoa)
);
GO

-- ETL
INSERT INTO DimTempo(Ano)
SELECT DISTINCT TRIM(YEAR) AS Ano
FROM dbo.BYAREA
WHERE LEN(TRIM(YEAR)) = 4
INTERSECT
SELECT DISTINCT TRIM(year)
FROM dbo.epa_air_quality_annual_summary
ORDER BY Ano;
GO

INSERT INTO DimLocal(Estado)
SELECT DISTINCT TRIM(AREA) AS Estado
FROM dbo.BYAREA
INTERSECT
SELECT DISTINCT TRIM(state_name)
FROM dbo.epa_air_quality_annual_summary
ORDER BY Estado;
GO

INSERT INTO DimPessoa(Raca, Sexo)
SELECT DISTINCT TRIM(RACE) AS Raca, TRIM(SEX) AS Sexo
FROM dbo.BYAREA
WHERE TRIM(RACE) <> 'All Races' AND TRIM(SEX) <> 'Male and Female'
ORDER BY Raca, Sexo;
GO

INSERT INTO DimCancer(Tipo)
SELECT DISTINCT REPLACE(REPLACE(SITE, '<i>', ''), '</i>', '') AS Tipo
FROM dbo.BYAREA
WHERE SITE <> 'All Cancer Sites Combined'
ORDER BY Tipo;
GO

INSERT INTO DimPM(Nome)
SELECT DISTINCT TRIM(SUBSTRING(parameter_name, 1, CHARINDEX(' PM', parameter_name))) AS Nome
FROM dbo.epa_air_quality_annual_summary
WHERE parameter_name LIKE '%PM%' AND units_of_measure <> 'Inverse Megameters'
	AND LEN(TRIM(SUBSTRING(parameter_name, 1, CHARINDEX(' PM', parameter_name)))) > 0
	AND parameter_name NOT LIKE '%rev%'AND parameter_name NOT LIKE '%Unadjusted%'
	AND TRIM(SUBSTRING(parameter_name, 1, CHARINDEX(' PM', parameter_name))) <> 'Acceptable'
	AND sample_duration LIKE '%24%'
ORDER BY Nome;
GO

INSERT INTO FatoAr(idTempo, idLocal, idPM, Media)
SELECT T.idTempo, L.idLocal, P.idPM, AVG(Aux.Media)
FROM (
	SELECT TRIM(year), TRIM(state_name),
		TRIM(SUBSTRING(parameter_name, 1, CHARINDEX(' PM', parameter_name))),
		CASE WHEN units_of_measure LIKE '%Nanograms%' THEN CAST(arithmetic_mean AS FLOAT) / 1000
			 ELSE CAST(arithmetic_mean AS FLOAT)
		END
	FROM dbo.epa_air_quality_annual_summary
	WHERE parameter_name LIKE '%PM%' AND units_of_measure <> 'Inverse Megameters'
		AND LEN(TRIM(SUBSTRING(parameter_name, 1, CHARINDEX(' PM', parameter_name)))) > 0
		AND parameter_name NOT LIKE '%rev%'AND parameter_name NOT LIKE '%Unadjusted%'
		AND TRIM(SUBSTRING(parameter_name, 1, CHARINDEX(' PM', parameter_name))) <> 'Acceptable'
		AND sample_duration LIKE '%24%'
) AS Aux(Ano, Estado, Nome, Media)
JOIN DimTempo T ON T.Ano = Aux.Ano
JOIN DimLocal L	ON L.Estado = Aux.Estado
JOIN DimPM P ON P.Nome = Aux.Nome
GROUP BY T.idTempo, L.idLocal, P.idPM;
GO

INSERT INTO FatoCancer(idTempo, idLocal, idPessoa, idCancer, NumIncidencias, NumMortes)
SELECT T.idTempo, L.idLocal, P.idPessoa, C.idCancer, Aux.NumIncidencias, Aux.NumMortes
FROM (
	SELECT ISNULL(I.Ano, M.Ano), ISNULL(I.Estado, M.Estado), ISNULL(I.Raca, M.Raca), ISNULL(I.Sexo, M.Sexo), 
		ISNULL(I.Tipo, M.Tipo), CASE WHEN I.NumIncidencias IN ('~', '.', '-') THEN NULL ELSE I.NumIncidencias END,
		CASE WHEN M.NumMortes IN ('~', '.', '-') THEN NULL ELSE M.NumMortes END
	FROM (
		SELECT TRIM(YEAR), TRIM(AREA), TRIM(RACE), TRIM(SEX), REPLACE(REPLACE(SITE, '<i>', ''), '</i>', ''), COUNT
		FROM dbo.BYAREA
		WHERE LEN(TRIM(YEAR)) = 4 AND TRIM(RACE) <> 'All Races' AND TRIM(SEX) <> 'Male and Female'
			AND SITE <> 'All Cancer Sites Combined'	AND TRIM(EVENT_TYPE) = 'Incidence'
	) AS I(Ano, Estado, Raca, Sexo, Tipo, NumIncidencias)
	FULL OUTER JOIN (
		SELECT TRIM(YEAR), TRIM(AREA), TRIM(RACE), TRIM(SEX), REPLACE(REPLACE(SITE, '<i>', ''), '</i>', ''), COUNT
		FROM dbo.BYAREA
		WHERE LEN(TRIM(YEAR)) = 4 AND TRIM(RACE) <> 'All Races' AND TRIM(SEX) <> 'Male and Female'
			AND SITE <> 'All Cancer Sites Combined' AND TRIM(EVENT_TYPE) = 'Mortality'
	) AS M(Ano, Estado, Raca, Sexo, Tipo, NumMortes)
		ON I.Ano = M.Ano AND I.Estado = M.Estado AND I.Raca = M.Raca AND I.Sexo = M.Sexo AND I.Tipo = M.Tipo
) AS Aux(Ano, Estado, Raca, Sexo, Tipo, NumIncidencias, NumMortes)
JOIN DimTempo T ON T.Ano = Aux.Ano
JOIN DimLocal L ON L.Estado = Aux.Estado
JOIN DimPessoa P ON P.Raca = Aux.Raca AND P.Sexo = Aux.Sexo
JOIN DimCancer C ON C.Tipo = Aux.Tipo;
GO

INSERT INTO FatoPopulacao(idTempo, idLocal, idPessoa, Populacao)
SELECT T.idTempo, L.idLocal, P.idPessoa, MAX(Populacao)
FROM (
	SELECT TRIM(YEAR), TRIM(AREA), TRIM(RACE), TRIM(SEX), CAST(POPULATION AS INT)
	FROM dbo.BYAREA
	WHERE LEN(TRIM(YEAR)) = 4 AND TRIM(RACE) <> 'All Races' AND TRIM(SEX) <> 'Male and Female'
) AS Aux(Ano, Estado, Raca, Sexo, Populacao)
JOIN DimTempo T ON T.Ano = Aux.Ano
JOIN DimLocal L ON L.Estado = Aux.Estado
JOIN DimPessoa P ON P.Raca = Aux.Raca AND P.Sexo = Aux.Sexo
GROUP BY T.idTempo, L.idLocal, P.idPessoa;
GO