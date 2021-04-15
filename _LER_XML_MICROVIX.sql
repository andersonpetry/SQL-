
/*
Antes de iniciar a leitura do arquivo XML da Microvix 
	- deve-se fazer o tratamento de substituição (DE: <D /> ; POR: <D>null</D>)
*/

/*
CREATE DATABASE OPENXMLTesting
GO

USE OPENXMLTesting
GO
	
						   
CREATE TABLE XMLwithOpenXML
(
Id INT IDENTITY PRIMARY KEY,
XMLData XML,
LoadedDateTime DATETIME
)
		 */


USE OPENXMLTesting
GO

/*																				  
INSERT INTO XMLwithOpenXML(XMLData, LoadedDateTime)
SELECT CONVERT(XML, BulkColumn) AS BulkColumn, GETDATE() 
FROM OPENROWSET(BULK 'C:\_APIs_microvix\xml\LINXMOVIMENTO.XML', SINGLE_BLOB) AS x;

SELECT * FROM XMLwithOpenXML

*/
GO
DROP TABLE #xml_test
GO
DROP TABLE ##test_xml
GO

DECLARE @XML AS XML, @hDoc AS INT, @SQL NVARCHAR (MAX)
SELECT
	@XML = XMLData
FROM XMLwithOpenXML
WHERE id = 1
EXEC sp_xml_preparedocument	@hDoc OUTPUT
							,@XML

SELECT
	PARENTID
	,text
	,id
	,prev
	,localname INTO #xml_test
FROM OPENXML(@hDoc, 'Microvix/ResponseData')
EXEC sp_xml_removedocument @hDoc
GO

SELECT
	ROW_NUMBER() OVER (PARTITION BY (SELECT TOP 1
			T2.PARENTID
		FROM #xml_test T2
		WHERE T2.ID = t.parentid
		AND localname = 'D')
	ORDER BY ID) AS ROW_NUMBER_ordem_parentid

	,(SELECT TOP 1
			T2.PARENTID
		FROM #xml_test T2
		WHERE T2.ID = t.parentid)
	AS ordem_parentid

	,id
	,text
	,prev
	,parentid INTO ##test_xml
FROM #xml_test t

WHERE parentid IN (SELECT DISTINCT
		prev
	FROM #xml_test
	WHERE localname = 'D')

ORDER BY 1 ASC, t.parentid, t.id




 DECLARE @cols AS NVARCHAR(MAX),
    @query  AS NVARCHAR(MAX)

SELECT
	@cols = STUFF((SELECT
			',' + QUOTENAME(text)
		FROM ##test_xml
		WHERE ordem_parentId = 3
		ORDER BY ordem_parentId, ROW_NUMBER_ordem_parentid

		FOR XML PATH (''), TYPE)
	.value('.', 'NVARCHAR(MAX)')
	, 1, 1, '')

SET @query = N'SELECT ' + @cols + N' from 
             (
                select CAST(ISNULL(text,'''') AS NVARCHAR(MAX) )  as value
				, (SELECT top 1 CAST(text AS VARCHAR(100) )   as nome_coluna from ##test_xml t2 where t2.ROW_NUMBER_ordem_parentid = t.ROW_NUMBER_ordem_parentid AND t2.ROW_NUMBER_ordem_parentid = t.ROW_NUMBER_ordem_parentid 		ORDER BY  ordem_parentId , 	ROW_NUMBER_ordem_parentid) as ColumnName
				, ordem_parentId    
                from ##test_xml t
				where t.ordem_parentId<>3   
            ) x
            pivot 
            (
                max(value) 
                for ColumnName in (' + @cols + N')
            ) p  '

EXEC sp_executesql @query;
