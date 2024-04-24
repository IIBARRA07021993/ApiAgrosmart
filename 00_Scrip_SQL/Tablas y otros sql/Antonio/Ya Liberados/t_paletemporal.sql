
/*|AGS|*/
IF  EXISTS
( SELECT *
  FROM sys.objects
  WHERE object_id = OBJECT_ID(N't_paletemporal')
        AND type IN ( N'U' ))
DROP TABLE t_paletemporal
GO
/*|AGS|*/
  CREATE TABLE t_paletemporal
  ( 
	c_codigo_pte CHAR(10) NOT NULL, /*codigo palet*/
	--c_concecutivo_pte VARCHAR(3) NOT NULL, /*Consecutivo*/
	c_codigo_sma CHAR(15) NOT NULL	, /*corrida*/
    c_codqrtemp_pte VARCHAR(22) NOT NULL ,/*Codigo QR temporal*/
	c_codigo_tem VARCHAR(2) NOT NULL, /*Temporada*/
	d_totcaja_pte NUMERIC NOT NULL,/*total caja */
	d_totkilos_pte DECIMAL(18,3) NOT NULL,/*total kilos */
	d_asignacionqr_pte DATETIME NULL,/*fecha asignacion QR*/
	d_liberacionqr_pte DATETIME NULL,/*fecha liberacion QR*/
	c_codigo_are CHAR(4)  NULL	,/*area*/
	c_ubicacion_pte VARCHAR(10)  NULL,/*ubicacion*/
	c_codigo_cal CHAR(4) NULL, /*calibre*/
    c_codigo_gma CHAR(4) NOT NULL , /*grado maduracion*/
	c_finalizado_pte CHAR(1) NOT NULL,/*ya fue finalizado S/N*/
    c_codigo_usu CHAR(20) NULL ,
    d_creacion_dso DATETIME NULL ,
    c_usumod_dso CHAR(20) NULL ,
    d_modifi_dso DATETIME NULL ,
    c_activo_dso CHAR(1) NOT NULL
	);


/*|AGS|*/
IF EXISTS
( SELECT *
  FROM sys.objects
  WHERE object_id = OBJECT_ID(N't_paletemporaldet')
        AND type IN ( N'U' ))
DROP TABLE	t_paletemporaldet
GO 

/*|AGS|*/
  CREATE TABLE t_paletemporaldet
  ( 
	c_codigo_pte CHAR(10) NOT NULL, /*codigo palet*/
	c_concecutivo_pte VARCHAR(3) NOT NULL, /*Consecutivo*/
	c_codigo_sma CHAR(10) NOT NULL	, /*corrida*/
	c_codigo_tem VARCHAR(2) NOT NULL, /*Temporada*/
	n_cajas_pte NUMERIC NOT NULL,/* caja */
	n_kilos_pte DECIMAL(18,3) NOT NULL,/* kilos */
    c_codigo_usu CHAR(20) NULL ,
    d_creacion_dso DATETIME NULL ,
    c_usumod_dso CHAR(20) NULL ,
    d_modifi_dso DATETIME NULL ,
    c_activo_dso CHAR(1) NOT NULL
	);

	/*Palet temporal*/
/*|AGS|*/
IF NOT EXISTS (SELECT * FROM sys.columns WHERE name='c_codigo_emp' AND object_id=OBJECT_ID('t_paletemporal'))
ALTER TABLE dbo.t_paletemporal ADD c_codigo_emp CHAR(2) NULL
/*|AGS|*/
IF NOT EXISTS (SELECT * FROM sys.columns WHERE name='c_codigo_niv' AND object_id=OBJECT_ID('t_paletemporal'))
ALTER TABLE dbo.t_paletemporal ADD c_codigo_niv CHAR(4) NULL
/*|AGS|*/
IF NOT EXISTS (SELECT * FROM sys.columns WHERE name='c_columna_col' AND object_id=OBJECT_ID('t_paletemporal'))
ALTER TABLE dbo.t_paletemporal ADD c_columna_col CHAR(4) NULL
/*|AGS|*/
IF NOT EXISTS (SELECT * FROM sys.columns WHERE name='c_codigo_pos' AND object_id=OBJECT_ID('t_paletemporal'))
ALTER TABLE dbo.t_paletemporal ADD c_codigo_pos CHAR(4) NULL
/*|AGS|*/
IF NOT EXISTS (SELECT * FROM sys.columns WHERE name='c_codigo_def' AND object_id=OBJECT_ID('t_paletemporal'))
ALTER TABLE dbo.t_paletemporal ADD c_codigo_def CHAR(10) NULL
/*|AGS|*/
IF NOT EXISTS (SELECT * FROM sys.columns WHERE name='d_fecha_pte' AND object_id=OBJECT_ID('t_paletemporal'))
ALTER TABLE dbo.t_paletemporal ADD d_fecha_pte DATETIME
/*|AGS|*/
IF NOT EXISTS (SELECT * FROM sys.columns WHERE name='c_codigofinal_pal' AND object_id=OBJECT_ID('t_paletemporal'))
ALTER TABLE dbo.t_paletemporal ADD c_codigofinal_pal CHAR(10) NULL
/*|AGS|*/
IF NOT EXISTS (SELECT * FROM sys.columns WHERE name='c_pitted_pte' AND object_id=OBJECT_ID('t_paletemporal'))
ALTER TABLE dbo.t_paletemporal ADD c_pitted_pte CHAR(1) NULL
/*|AGS|*/
IF NOT EXISTS (SELECT * FROM sys.columns WHERE name='c_codigocaja_tcj' AND object_id=OBJECT_ID('t_paletemporal'))
ALTER TABLE dbo.t_paletemporal ADD c_codigocaja_tcj CHAR(4) NULL
/*|AGS|*/
IF NOT EXISTS (SELECT * FROM sys.columns WHERE name='c_codigotarima_tcj' AND object_id=OBJECT_ID('t_paletemporal'))
ALTER TABLE dbo.t_paletemporal ADD c_codigotarima_tcj CHAR(4) NULL



/*Detalle del pallet*/
/*|AGS|*/
IF NOT EXISTS (SELECT * FROM sys.columns WHERE name='c_codigo_emp' AND object_id=OBJECT_ID('t_paletemporaldet'))
ALTER TABLE dbo.t_paletemporaldet ADD c_codigo_emp CHAR(2) NULL

/*recepcion generada*/
/*|AGS|*/
IF NOT EXISTS (SELECT * FROM sys.columns WHERE name='c_codigo_niv' AND object_id=OBJECT_ID('t_recepciondet'))
ALTER TABLE dbo.t_recepciondet ADD c_codigo_niv CHAR(4) NULL
/*|AGS|*/
IF NOT EXISTS (SELECT * FROM sys.columns WHERE name='c_columna_col' AND object_id=OBJECT_ID('t_recepciondet'))
ALTER TABLE dbo.t_recepciondet ADD c_columna_col CHAR(4) NULL
/*|AGS|*/
IF NOT EXISTS (SELECT * FROM sys.columns WHERE name='c_codigo_pos' AND object_id=OBJECT_ID('t_recepciondet'))
ALTER TABLE dbo.t_recepciondet ADD c_codigo_pos CHAR(4) NULL
/*|AGS|*/
IF NOT EXISTS (SELECT * FROM sys.columns WHERE name='c_codigo_def' AND object_id=OBJECT_ID('t_recepciondet'))
ALTER TABLE dbo.t_recepciondet ADD c_codigo_def CHAR(10) NULL




/*|AGS|*/
IF  EXISTS
( SELECT *
  FROM sys.objects
  WHERE object_id = OBJECT_ID(N't_cambioubicacion')
        AND type IN ( N'U' ))
DROP TABLE t_cambioubicacion
GO
/*|AGS|*/
  CREATE TABLE t_cambioubicacion
  ( 
	c_codigo_cub CHAR(10) NOT NULL, /*codigo */
	c_codigo_pte VARCHAR(10) NOT NULL,	/*codigo de pallet */
    c_codqrtemp_pte VARCHAR(10) NOT NULL ,/*Codigo QR temporal*/
	c_codigo_tem VARCHAR(2) NOT NULL, /*Temporada*/
	c_codigo_are CHAR(4)  NOT NULL	,/*area*/
	c_codigo_niv CHAR(4) NULL,/*nivel*/
	c_columna_col CHAR(4) NULL,/*rack*/
	c_codigo_pos CHAR(4) NULL,/*posicion*/
	c_codigo_def CHAR(10) NULL,/*ubicacion*/
	d_entreda_cub DATETIME NOT NULL, /*fecha/hora de ingreso al area*/
    c_codigo_usu CHAR(20) NOT NULL ,
    d_creacion_cub DATETIME NOT NULL ,
    c_usumod_cub CHAR(20) NULL ,
    d_modifi_cub DATETIME NULL ,
    c_activo_cub CHAR(1) NOT NULL
	);


/*|AGS|*/
IF  EXISTS
( SELECT *
  FROM sys.objects
  WHERE object_id = OBJECT_ID(N't_espfisicoubicacion')
        AND type IN ( N'U' ))
DROP TABLE t_espfisicoubicacion
GO
/*|AGS|*/
  CREATE TABLE t_espfisicoubicacion
  ( 
	c_codigo_sfu CHAR(10) NOT NULL, /*codigo */
	c_codigo_are VARCHAR(10) NOT NULL,	/*codigo area*/
    c_codigo_def CHAR(10) NOT NULL,/*ubicacion*/
	c_codigoalt_sfu varchar (50) NULL,
    c_codigo_usu CHAR(20) NOT NULL ,
    d_creacion_sfu DATETIME NOT NULL ,
    c_usumod_sfu CHAR(20) NULL ,
    d_modifi_sfu DATETIME NULL ,
    c_activo_sfu CHAR(1) NOT NULL
	);
GO
ALTER TABLE [dbo].[t_distribucionespfisico] ADD CONSTRAINT [pk_t_espfisicoubicacion] PRIMARY KEY CLUSTERED ([c_codigo_sfu]) ON [PRIMARY]

	/*|AGS|*/
IF EXISTS
(
    SELECT *
    FROM sys.objects
    WHERE object_id = OBJECT_ID(N't_palletsubicaciones')
          AND type IN ( N'U' )
)
    DROP TABLE t_palletsubicaciones;
GO
/*|AGS|*/
CREATE TABLE t_palletsubicaciones
(
    c_codigo_pub CHAR(10) NOT NULL,    /*codigo de la tabla */
    c_codigo_are VARCHAR(4) NOT NULL, /*codigo area*/
    c_codigo_pte CHAR(10) NOT NULL,    /*codigo palet*/
	c_codqrtemp_pub VARCHAR(22) NOT NULL,/*codigo Qr palet*/
	d_entrada_pub DATETIME NOT NULL,	/*fecha entrada*/
	d_salida_pub DATETIME NULL,	/*fecha salida*/
	c_codigo_sma VARCHAR(15) NOT NULL, /*corrida */
	n_pesoxpal_pub NUMERIC NOT NULL, /*Peso del palet al ingresar*/
	n_difpeso_pub NUMERIC NOT NULL,/*diferencia de peso entre ubicaciones.*/
	c_ubiactual_pub CHAR(1) NOT NULL,/*si es la ubicacion actual*/
	c_codigo_tem VARCHAR(2) NOT NULL,/*temporada*/
	c_codigo_emp VARCHAR(2) NOT NULL,/*punto de empaque*/
    c_codigo_usu CHAR(20) NOT NULL,
    d_creacion_pub DATETIME NOT NULL,
    c_usumod_pub CHAR(20) NULL,
    d_modifi_pub DATETIME NULL,
    c_activo_pub CHAR(1) NOT NULL
);


/*|AGS|*/
IF NOT EXISTS (SELECT * FROM sys.columns WHERE name='c_ubicacion_are' AND object_id=OBJECT_ID('t_areafisica'))
ALTER TABLE dbo.t_areafisica ADD c_ubicacion_are CHAR(1) NULL

/*|AGS|*/
IF NOT EXISTS (SELECT * FROM sys.columns WHERE name='n_tiemposugerido_pub' AND object_id=OBJECT_ID('t_palletsubicaciones'))
ALTER TABLE dbo.t_palletsubicaciones ADD n_tiemposugerido_pub numeric NULL

/*|AGS|*/
IF NOT EXISTS (SELECT * FROM sys.columns WHERE name='c_codqrtemp_pub' AND object_id=OBJECT_ID('t_palletsubicaciones'))
ALTER TABLE dbo.t_palletsubicaciones ADD c_codqrtemp_pub VARCHAR(22) NULL


/*|AGS|*/
IF NOT EXISTS (SELECT * FROM sys.columns WHERE name='c_codigo_are' AND object_id=OBJECT_ID('t_palet'))
ALTER TABLE dbo.t_palet ADD c_codigo_are CHAR(4) NULL



