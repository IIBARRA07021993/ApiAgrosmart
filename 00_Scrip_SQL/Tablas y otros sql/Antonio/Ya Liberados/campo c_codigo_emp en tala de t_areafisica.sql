/*|AGS|*/
IF NOT  EXISTS (SELECT * FROM sys.columns WHERE name='c_codigo_emp' AND object_id=OBJECT_ID('t_areafisica'))
ALTER TABLE dbo.t_areafisica ADD c_codigo_emp VARCHAR(2) NULL