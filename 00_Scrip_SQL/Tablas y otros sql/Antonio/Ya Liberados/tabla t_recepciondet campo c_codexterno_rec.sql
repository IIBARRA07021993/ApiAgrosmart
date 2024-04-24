
/*|AGS|*/
IF NOT EXISTS (SELECT * FROM sys.columns WHERE name='c_codexterno_rec' AND object_id=OBJECT_ID('t_recepciondet'))
ALTER Table dbo.t_recepciondet Add c_codexterno_rec VarChar(15) Not Null Default ''