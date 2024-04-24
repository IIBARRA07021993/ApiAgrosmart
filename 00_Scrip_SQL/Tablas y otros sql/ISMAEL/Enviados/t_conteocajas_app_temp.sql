/*|AGS|*/
IF EXISTS (  SELECT *  FROM sys.objects  WHERE object_id = OBJECT_ID(N't_conteocajas_app_temp')  AND type IN ( N'U' ))
DROP TABLE dbo.t_conteocajas_app_temp
/*|AGS|*/
IF NOT  EXISTS
(
    SELECT *
    FROM sys.objects
    WHERE object_id = OBJECT_ID(N't_conteocajas_app_temp')
          AND type IN ( N'U' )
)
BEGIN
CREATE TABLE dbo.t_conteocajas_app_temp
(
c_terminal_ccp varchar (100)  NOT NULL,
c_codigo_emp char (2)  NOT NULL,
c_idcaja_ccp varchar (10)  NOT NULL,
c_empleado_ccp char (6)  NOT NULL,
d_fecha_ccp datetime NOT NULL,
c_hrconteo_ccp char (8)  NOT NULL,
n_bulxpa_ccp numeric (18, 0) NOT NULL,
c_idcaja_cnt VARCHAR(14) NULL ,
c_codigo_usu char (20)  NOT NULL
PRIMARY KEY(c_terminal_ccp, c_codigo_emp, c_idcaja_ccp)
) END
