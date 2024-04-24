/*|AGS|*/
IF NOT EXISTS
(
    SELECT *
    FROM sys.objects
    WHERE object_id = OBJECT_ID(N't_areatiemposugerido')
          AND type IN ( N'U' )
)
BEGIN

    CREATE TABLE t_areatiemposugerido
    (
        c_codigo_ats CHAR(4) NOT NULL PRIMARY KEY,
        c_codigo_are CHAR(4) NOT NULL,
        c_codigo_gdm CHAR(4) NOT NULL,
		n_tiemposugerido_ats NUMERIC NOT NULL,
        c_codigo_usu CHAR(20) NULL,
        d_creacion_ats DATETIME NULL,
        c_usumod_ats CHAR(20) NULL,
        d_modifi_ats DATETIME NULL,
        c_activo_ats CHAR(1) NOT NULL
    );
END;


