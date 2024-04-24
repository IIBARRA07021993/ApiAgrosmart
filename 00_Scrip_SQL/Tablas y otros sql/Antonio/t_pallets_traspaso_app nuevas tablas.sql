/*|AGS|*/
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N't_pallet_traspaso_app') AND type in (N'U'))
	CREATE TABLE t_pallet_traspaso_app(
		n_idfolio_pta INT IDENTITY NOT NULL,							
		d_fecha_pta DATE NOT NULL,	
		c_AlmacenQueEnvia_pta CHAR(2) NOT NULL,
		c_AlmacenQueRecibe_pta CHAR(2) NOT NULL,
		n_PalletsEnviados_pta TINYINT NOT NULL,
		n_CajasEnviadas_pta SMALLINT NOT NULL,
		n_PesoPallets_pta INT NOT NULL,
		c_Estatus_pta CHAR(1) NOT NULL,
		c_codigo_tem CHAR(2) NOT NULL,
		c_codigo_usu CHAR(20) NOT NULL,
		d_creacion_pta  DATETIME NOT NULL,
		c_usumod_pta  CHAR(20) NULL,
		d_modifi_pta  DATETIME NULL,
		c_activo_pta  CHAR(1) NOT NULL,
		c_candado_pta CHAR(20) NULL,
		CONSTRAINT PK_t_pallet_traspasos_app PRIMARY KEY NONCLUSTERED (n_idfolio_pta )
		) ON [PRIMARY]


/*|AGS|*/
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N't_pallet_traspaso_app_det') AND type in (N'U'))
	CREATE TABLE t_pallet_traspaso_app_det(
		n_idfolio_pta  INT NOT NULL FOREIGN KEY  REFERENCES t_pallet_traspaso_app(n_idfolio_pta),							
		n_Consecutivo_ptad   VARCHAR(200) NOT NULL ,	
		c_IdPallet_ptad VARCHAR(10) NOT NULL ,
		c_codqrtemp_pte VARCHAR(22) NULL ,
		n_cajas_ptad TINYINT NOT NULL ,
		n_peso_ptad SMALLINT NOT NULL ,
		c_codigo_gma CHAR(4) NULL FOREIGN KEY  REFERENCES dbo.t_gradomaduracion(c_codigo_gdm),
		c_codigo_cal CHAR(4) NULL FOREIGN KEY  REFERENCES dbo.t_calibre(c_codigo_cal),
		c_codigo_usu CHAR(20) NOT NULL,
		d_creacion_ptad  DATETIME NOT NULL,
		c_usumod_ptad CHAR(20) NULL,
		d_modifi_ptad  DATETIME NULL,
		c_activo_ptad  CHAR(1) NOT NULL,
		c_codigo_tem CHAR(2) NOT NULL,
		CONSTRAINT PK_t_pallet_traspasos_app_det PRIMARY KEY NONCLUSTERED (n_idfolio_pta,n_Consecutivo_ptad )	
		) ON [PRIMARY]