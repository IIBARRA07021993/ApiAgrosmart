/*|AGS|*/
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 't_paletemporalEliminado')
BEGIN	 
	CREATE TABLE dbo.t_paletemporalEliminado
	(
		c_codigo_pte char (10)  NOT NULL,
		c_codigo_sma char (15)  NOT NULL,
		c_codqrtemp_pte varchar (22)  NOT NULL,
		c_codigo_tem varchar (2)  NOT NULL,
		d_totcaja_pte numeric (18, 0) NOT NULL,
		d_totkilos_pte decimal (18, 3) NOT NULL,
		d_asignacionqr_pte datetime NULL,
		d_liberacionqr_pte datetime NULL,
		c_codigo_are char (4)  NULL,
		c_ubicacion_pte varchar (10)  NULL,
		c_codigo_cal char (4)  NULL,
		c_codigo_gma char (4)  NOT NULL,
		c_finalizado_pte char (1)  NOT NULL,
		c_codigo_usu char (20)  NULL,
		d_creacion_dso datetime NULL,
		c_usumod_dso char (20)  NULL,
		d_modifi_dso datetime NULL,
		c_activo_dso char (1)  NOT NULL,
		c_codigo_emp char (2)  NULL,
		c_codigo_niv char (4)  NULL,
		c_columna_col char (4)  NULL,
		c_codigo_pos char (4)  NULL,
		c_codigo_def char (10)  NULL,
		d_fecha_pte datetime NULL,
		c_codigofinal_pal char (10)  NULL,
		c_pitted_pte char (1)  NULL,
		c_codigocaja_tcj char (4)  NULL,
		c_codigotarima_tcj char (4)  NULL,
		cUsuarioQueElimina varchar (20)  NOT NULL,
		dFechaEliminacion datetime NOT NULL
	) 
END 
