/*|AGS|*/
IF EXISTS
( SELECT *
  FROM sys.objects
  WHERE object_id = OBJECT_ID(N't_sortingmaduracion')
        AND type IN ( N'U' ))
DROP TABLE t_sortingmaduracion
GO 
/*|AGS|*/
  CREATE TABLE t_sortingmaduracion

  ( 
    c_folio_sma VARCHAR(15) NOT NULL ,
    c_codigo_tem VARCHAR(2) NOT NULL ,
    n_totalkilos_sma DECIMAL(9, 3) NOT NULL ,
    n_totalcajas_sma SMALLINT NOT NULL ,
	n_totalpalets_sma SMALLINT NOT NULL,
	c_finvaciado_sma CHAR(1) NOT NULL ,
	c_tipo_sma CHAR(1) NOT NULL,
    c_codigo_usu CHAR(20) NULL ,
    d_creacion_sma DATETIME NULL ,
    c_usumod_sma CHAR(20) NULL ,
    d_modifi_sma DATETIME NULL ,
    c_activo_sma CHAR(1) NOT NULL);


/*|AGS|*/
IF EXISTS
( SELECT *
  FROM sys.objects
  WHERE object_id = OBJECT_ID(N't_sortingmaduraciondet')
        AND type IN ( N'U' ))
DROP TABLE t_sortingmaduraciondet
GO 
/*|AGS|*/
  CREATE TABLE t_sortingmaduraciondet
  ( c_folio_sma VARCHAR(15) NOT NULL ,
    c_codigo_are CHAR(4) NOT NULL ,
    c_codigo_rec VARCHAR(10) NOT NULL ,
	c_codigo_pal VARCHAR(10) NOT NULL,
    c_concecutivo_smd VARCHAR(3) NOT NULL ,
    c_codigo_tem VARCHAR(2) NOT NULL ,
    c_codigo_lot VARCHAR(4) NOT NULL ,
    n_kilos_smd DECIMAL(9, 3) NOT NULL ,
    n_cajas_smd SMALLINT NOT NULL ,
    c_codigocaja_tcj CHAR(4) NOT NULL ,
    c_codigotarima_tcj CHAR(4) NOT NULL ,
    c_finvaciado_smd CHAR(1) NOT NULL ,
	c_codigo_pte VARCHAR(10) NULL,
    c_codigo_usu CHAR(20) NULL ,
    d_creacion_smd DATETIME NULL ,
    c_usumod_smd CHAR(20) NULL ,
    d_modifi_smd DATETIME NULL ,
    c_activo_smd CHAR(1) NOT NULL);



/*|AGS|*/
IF NOT EXISTS (SELECT * FROM sys.columns WHERE name='n_diferenciapalet_sma' AND object_id=OBJECT_ID('t_sortingmaduracion'))
	ALTER TABLE t_sortingmaduracion ADD n_diferenciapalet_sma NUMERIC NULL

	/*|AGS|*/
IF NOT EXISTS (SELECT * FROM sys.columns WHERE name='c_tipocorrida_sma' AND object_id=OBJECT_ID('t_sortingmaduracion'))
	ALTER TABLE t_sortingmaduracion ADD c_tipocorrida_sma VARCHAR(1) NULL

	/*|AGS|*/
IF NOT EXISTS (SELECT * FROM sys.columns WHERE name='c_codigo_emp' AND object_id=OBJECT_ID('t_sortingmaduracion'))
	ALTER TABLE t_sortingmaduracion ADD c_codigo_emp VARCHAR(2) NULL

	/*|AGS|*/
IF NOT EXISTS (SELECT * FROM sys.columns WHERE name='c_codigo_emp' AND object_id=OBJECT_ID('t_sortingmaduraciondet'))
	ALTER TABLE t_sortingmaduraciondet ADD c_codigo_emp VARCHAR(2) NULL

	/*|AGS|*/
IF NOT EXISTS (SELECT * FROM sys.columns WHERE name='idrazon' AND object_id=OBJECT_ID('t_sortingmaduracion'))
	ALTER TABLE t_sortingmaduracion ADD idrazon TINYINT NULL

	