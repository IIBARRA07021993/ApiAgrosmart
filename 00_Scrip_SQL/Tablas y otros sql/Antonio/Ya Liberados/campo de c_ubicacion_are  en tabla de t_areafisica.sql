/*|AGS|*/
IF NOT EXISTS (SELECT * FROM sys.columns WHERE name='c_ubicacion_are' AND object_id=OBJECT_ID('t_areafisica'))
ALTER TABLE dbo.t_areafisica ADD c_ubicacion_are CHAR(1) NULL
