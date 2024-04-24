/*|AGS|*/
IF  EXISTS (SELECT * FROM sys.columns WHERE name='c_codigo_tam' AND object_id=OBJECT_ID('t_palet_multiestiba'))
ALTER TABLE  t_palet_multiestiba ALTER COLUMN c_codigo_tam  CHAR(4) NULL
/*|AGS|*/
IF NOT EXISTS (SELECT * FROM sys.columns WHERE name='c_terminal_pme' AND object_id=OBJECT_ID('t_palet_multiestiba'))
ALTER TABLE dbo.t_palet_multiestiba  ADD c_terminal_pme  VARCHAR(100) NULL  