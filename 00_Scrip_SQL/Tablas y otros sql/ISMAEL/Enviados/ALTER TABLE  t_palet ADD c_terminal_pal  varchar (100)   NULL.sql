/*|AGS|*/
IF NOT  EXISTS (SELECT * FROM sys.columns WHERE name='c_terminal_pal' AND object_id=OBJECT_ID('t_palet'))
ALTER TABLE  t_palet ADD c_terminal_pal  varchar (100)   NULL