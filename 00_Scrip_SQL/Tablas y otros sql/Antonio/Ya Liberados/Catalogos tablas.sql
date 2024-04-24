/*|AGS|*/
IF NOT EXISTS
(
    SELECT *
    FROM sys.objects
    WHERE object_id = OBJECT_ID(N't_gradomaduracion')
          AND type IN ( N'U' )
)
BEGIN

    CREATE TABLE t_gradomaduracion
    (
        c_codigo_gdm CHAR(4) NOT NULL PRIMARY KEY,
        v_nombre_gdm VARCHAR(250) NOT NULL,
        v_descripcion_gdm VARCHAR(250) NULL,
        v_foto_gdm VARCHAR(MAX) NULL,
        c_codigoalt_gmd VARCHAR(50) NULL,
        c_codigo_usu CHAR(20) NULL,
        d_creacion_gmd DATETIME NULL,
        c_usumod_gmd CHAR(20) NULL,
        d_modifi_gmd DATETIME NULL,
        c_activo_gmd CHAR(1) NOT NULL
    );
END;


/*|AGS|*/
IF NOT EXISTS
(
    SELECT *
    FROM sys.objects
    WHERE object_id = OBJECT_ID(N't_costospreproceso')
          AND type IN ( N'U' )
)
BEGIN
    CREATE TABLE t_costospreproceso
    (
        c_codigo_cst CHAR(4) NOT NULL PRIMARY KEY,
        v_nombre_cst VARCHAR(250) NOT NULL,
        c_tipo_cst CHAR(2) NOT NULL,
        c_codigoalt_cst VARCHAR(50) NULL,
        c_codigo_usu CHAR(20) NULL,
        d_creacion_cst DATETIME NULL,
        c_usumod_cst CHAR(20) NULL,
        d_modifi_cst DATETIME NULL,
        c_activo_cst CHAR(1) NOT NULL
    );
END;



/*|AGS|*/
IF NOT EXISTS
(
    SELECT *
    FROM sys.objects
    WHERE object_id = OBJECT_ID(N't_calibre')
          AND type IN ( N'U' )
)
BEGIN

    CREATE TABLE t_calibre
    (
        c_codigo_cal CHAR(4) NOT NULL PRIMARY KEY,
        v_nombre_cal VARCHAR(250) NOT NULL,
        v_descripcion_cal VARCHAR(250) NULL,
        v_foto_cal VARCHAR(MAX) NULL,
        c_codigoalt_cal VARCHAR(50) NULL,
        c_codigo_tam CHAR(4) NULL,
        c_codigo_usu CHAR(20) NULL,
        d_creacion_cal DATETIME NULL,
        c_usumod_cal CHAR(20) NULL,
        d_modifi_cal DATETIME NULL,
        c_activo_cal CHAR(1) NOT NULL
    );
END;


/*|AGS|*/
IF NOT EXISTS
(
    SELECT *
    FROM sys.objects
    WHERE object_id = OBJECT_ID(N't_areafisica')
          AND type IN ( N'U' )
)
BEGIN

    CREATE TABLE t_areafisica
    (
        c_codigo_are CHAR(4) NOT NULL PRIMARY KEY,
        v_nombre_are VARCHAR(250) NOT NULL,
        v_descripcion_are VARCHAR(250) NULL,
        v_foto_are VARCHAR(MAX) NULL,
        c_tipo_are CHAR(2) NOT NULL,
        c_codigo_cst CHAR(4) NULL,
        c_codigoalt_are VARCHAR(50) NULL,
        c_codigo_usu CHAR(20) NULL,
        d_creacion_are DATETIME NULL,
        c_usumod_are CHAR(20) NULL,
        d_modifi_are DATETIME NULL,
        c_activo_are CHAR(1) NOT NULL
    );
END;
/*|AGS|*/
IF NOT EXISTS
(
    SELECT *
    FROM sys.objects
    WHERE object_id = OBJECT_ID(N't_relacionareamaduracion')
          AND type IN ( N'U' )
)
BEGIN
    CREATE TABLE t_relacionareamaduracion
    (
        c_codigo_ram CHAR(4) NOT NULL PRIMARY KEY,
        c_codigo_are CHAR(4) NOT NULL,
        c_codigo_gdm CHAR(4) NOT NULL,
        c_minutos_ram INTEGER NULL,
        c_codigoalt_ram VARCHAR(50) NULL,
        c_codigo_usu CHAR(20) NULL,
        d_creacion_ram DATETIME NULL,
        c_usumod_ram CHAR(20) NULL,
        d_modifi_ram DATETIME NULL,
        c_activo_ram CHAR(1) NOT NULL
    );
END;


/*|AGS|*/
IF NOT EXISTS
(
    SELECT *
    FROM sys.objects
    WHERE object_id = OBJECT_ID(N't_relacioncalibremaduracion')
          AND type IN ( N'U' )
)
BEGIN
    CREATE TABLE t_relacioncalibremaduracion
    (
        c_codigo_rcm CHAR(4) NOT NULL PRIMARY KEY,
        c_codigo_are CHAR(4) NOT NULL,
        c_codigo_cal CHAR(4) NOT NULL,
        n_minutos_rcm INTEGER NULL,
        c_codigoalt_rcm VARCHAR(50) NULL,
        c_codigo_usu CHAR(20) NULL,
        d_creacion_rcm DATETIME NULL,
        c_usumod_rcm CHAR(20) NULL,
        d_modifi_rcm DATETIME NULL,
        c_activo_rcm CHAR(1) NOT NULL
    );
END;


