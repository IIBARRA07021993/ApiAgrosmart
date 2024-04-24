
/*|AGS|*/
IF EXISTS
(
    SELECT *
    FROM sys.objects
    WHERE object_id = OBJECT_ID(N't_controltirajecontecajas')
          AND type IN ( N'U' )
)
    DROP TABLE dbo.t_controltirajecontecajas;
GO
/*|AGS|*/
IF NOT EXISTS
(
    SELECT *
    FROM sys.objects
    WHERE object_id = OBJECT_ID(N't_controltirajecontecajas')
          AND type IN ( N'U' )
)
BEGIN



    CREATE TABLE t_controltirajecontecajas
    (
        c_codigo_tem CHAR(2) NOT NULL,
        c_codigo_emp CHAR(2) NOT NULL,
        c_ultimofolio_cte VARCHAR(10) NOT NULL,
        c_folioinicial_cte VARCHAR(10) NOT NULL,
        c_foliofinal_cte VARCHAR(10) NOT NULL,
        c_cantidad_cte NUMERIC(18, 0) NOT NULL,
        c_empleado_cte VARCHAR(6) NULL,
        d_fecha_cte DATETIME NULL,
        c_codigo_usu CHAR(20) NULL,
        d_creacion_cte DATETIME NULL,
        c_usumod_cte CHAR(20) NULL,
        d_modifi_cte DATETIME NULL,
        c_activo_cte CHAR(1) NULL
            PRIMARY KEY (
                            c_codigo_tem,
                            c_codigo_emp,
                            c_ultimofolio_cte
                        )
    );
END;

GO
/*|AGS|*/
IF EXISTS
(
    SELECT *
    FROM sys.objects
    WHERE object_id = OBJECT_ID(N't_empleado_controltirajefolios')
          AND type IN ( N'U' )
)
    DROP TABLE dbo.t_empleado_controltirajefolios;

GO

/*|AGS|*/
IF NOT EXISTS
(
    SELECT *
    FROM sys.objects
    WHERE object_id = OBJECT_ID(N't_empleado_controltirajefolios')
          AND type IN ( N'U' )
)
BEGIN


    CREATE TABLE t_empleado_controltirajefolios
    (
        c_codigo_tem CHAR(2) NOT NULL,
        c_codigo_emp CHAR(2) NOT NULL,
        c_folioinicial_emt VARCHAR(10) NOT NULL,
        c_foliofinal_emt VARCHAR(10) NOT NULL,
        c_empleado_emt VARCHAR(6) NOT NULL,
        d_fecha_emt DATETIME NULL,
        c_codigo_usu CHAR(20) NULL,
        d_creacion_emt DATETIME NULL,
        c_usumod_emt CHAR(20) NULL,
        d_modifi_emt DATETIME NULL,
        c_activo_emt CHAR(1) NULL
            PRIMARY KEY (
                            c_codigo_tem,
                            c_codigo_emp,
                            c_empleado_emt
                        )
    );
END;
GO
