/*|AGS|*/
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N't_paletemporal_consolidado') AND type in (N'U'))
CREATE TABLE dbo.t_paletemporal_consolidado
(
    c_codigo_ptc CHAR(10) COLLATE Modern_Spanish_CI_AS NOT NULL, /*codigo del pallet temporal nuevo */
    c_codigo_pte CHAR(10) COLLATE Modern_Spanish_CI_AS NOT NULL, /*pallets consolidados */
    c_codigo_tem VARCHAR(2) COLLATE Modern_Spanish_CI_AS NOT NULL,
	c_codigo_emp VARCHAR(2) COLLATE Modern_Spanish_CI_AS NOT NULL,
    d_totcaja_ptc NUMERIC(18, 0) NOT NULL,
    d_totkilos_ptc DECIMAL(18, 3) NOT NULL,
    c_codigo_usu CHAR(20) COLLATE Modern_Spanish_CI_AS NULL,
    d_creacion_ptc DATETIME NULL,
    c_usumod_ptc CHAR(20) COLLATE Modern_Spanish_CI_AS NULL,
    d_modifi_ptc DATETIME NULL,
    c_activo_ptc CHAR(1) COLLATE Modern_Spanish_CI_AS NOT NULL,
    bloqueid VARCHAR(10) COLLATE Modern_Spanish_CI_AS NOT NULL,
	c_codigo_cal varchar(4)  COLLATE Modern_Spanish_CI_AS NOT NULL,
	c_codigo_gma varchar(4)  COLLATE Modern_Spanish_CI_AS NOT NULL
);


