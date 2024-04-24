/*|AGS|*/
IF NOT EXISTS (SELECT * FROM sys.columns WHERE name='c_areadefault_pem' AND object_id=OBJECT_ID('t_puntoempaque'))
ALTER TABLE t_puntoempaque ADD c_areadefault_pem CHAR(04) NULL
