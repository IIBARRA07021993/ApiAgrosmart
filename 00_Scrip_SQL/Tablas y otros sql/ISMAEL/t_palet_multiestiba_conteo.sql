

/*|AGS|*/
IF EXISTS
(
    SELECT *
    FROM sys.objects
    WHERE object_id = OBJECT_ID(N't_palet_multiestiba_conteo')
          AND type IN ( N'U' )
)
    DROP TABLE t_palet_multiestiba_conteo;
GO
/*|AGS|*/
IF NOT EXISTS
(
    SELECT *
    FROM sys.objects
    WHERE object_id = OBJECT_ID(N't_palet_multiestiba_conteo')
          AND type IN ( N'U' )
)
BEGIN
    CREATE TABLE dbo.t_palet_multiestiba_conteo
    (
        c_codigo_tem CHAR(2) NOT NULL,
        c_codigo_emp CHAR(2) NOT NULL,
        c_codigo_pme CHAR(10) NOT NULL,
        c_codsec_pme CHAR(2) NOT NULL,
        c_empleado_cnt CHAR(6) NOT NULL,
        c_idcaja_cnt CHAR(14) NOT NULL,
        d_conteo_cnt DATETIME NULL,
        c_hrconteo_cnt CHAR(8) NULL,
        n_bulxpa_cnt NUMERIC(10, 2) NULL,
        c_idcajascaneo_cnt VARCHAR(10) NOT NULL,
        c_terminal_cnt VARCHAR(100) NOT NULL,
        c_codigo_usu CHAR(20) NOT NULL,
        d_creacion_cnt DATETIME NOT NULL,
        c_usumod_cnt CHAR(20) NULL,
        d_modifi_cnt DATETIME NULL,
        c_activo_cnt CHAR(1) NOT NULL
            PRIMARY KEY (
                            c_codigo_tem,
                            c_codigo_emp,
                            c_codigo_pme,
                            c_codsec_pme,
                            c_idcaja_cnt
                        )
    );
END;
GO