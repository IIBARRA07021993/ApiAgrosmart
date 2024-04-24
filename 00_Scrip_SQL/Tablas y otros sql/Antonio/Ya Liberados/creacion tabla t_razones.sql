/*|AGS|*/
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N't_razones') AND type in (N'U'))
CREATE TABLE t_razones (
	idRazon TINYINT IDENTITY (1,1)PRIMARY KEY,
	cNombre VARCHAR(50) NOT NULL,
	cDescripcion VARCHAR(100) NOT NULL	DEFAULT '',
	nCostoPorLibra DECIMAL(9,2) NOT NULL DEFAULT 0,
	nCostoPorHoras DECIMAL(9,2) NOT NULL DEFAULT 0,
	bEnOperacion BIT NOT NULL DEFAULT 1 ,
	c_codigo_usu VARCHAR(20) NOT NULL,
	d_creacion_raz DATETIME NOT NULL,
	c_usomod_raz VARCHAR(20)	NULL,
	d_modifi_raz DATETIME NULL,
	c_activo_raz CHAR(1) NOT NULL
 )


