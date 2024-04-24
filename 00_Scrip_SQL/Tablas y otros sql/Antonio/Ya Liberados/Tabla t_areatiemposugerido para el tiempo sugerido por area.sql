/*|AGS|*/
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N't_areatiemposugerido') AND type in (N'U'))
CREATE TABLE dbo.t_areatiemposugerido
(
c_codigo_ats char (4) NOT NULL PRIMARY KEY,
c_codigo_are char (4) NOT NULL,
c_codigo_gdm char (4) NOT NULL,
c_codigo_pem CHAR(2) NOT NULL,
n_tiemposugerido_ats numeric (18, 0) NOT NULL,
c_codigo_usu char (20)  NOT NULL,
d_creacion_ats datetime NULL,
c_usumod_ats char (20)  NULL,
d_modifi_ats datetime NULL,
c_activo_ats char (1) 
) 