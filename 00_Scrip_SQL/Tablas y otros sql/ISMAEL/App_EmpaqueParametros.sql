CREATE TABLE dbo.App_EmpaqueParametros
(
    c_codigo_par CHAR(3) NOT NULL,
    v_nombre_par VARCHAR(100) NOT NULL,
    v_valor_par VARCHAR(100) NULL,
    c_codigo_usu CHAR(20) NOT NULL,
    d_creacion_par DATETIME NOT NULL,
    c_usumod_par CHAR(20) NULL,
    d_modifi_par DATETIME NULL,
    c_activo_par CHAR(1) NOT NULL,
    c_codigo_sis CHAR(2) NULL,
    c_tipodato_par CHAR(3) NULL,
    c_tipo_par VARCHAR(25) NULL,
    c_ocultar_par CHAR(1) NULL,
    c_addclient_par CHAR(1) NULL,
    c_edit_par CHAR(1) NULL
);
GO
ALTER TABLE dbo.App_EmpaqueParametros
ADD CONSTRAINT PK_App_EmpaqueParametros
    PRIMARY KEY CLUSTERED (c_codigo_par);
GO



INSERT INTO App_EmpaqueParametros
(
    c_codigo_par,
    v_nombre_par,
    v_valor_par,
    c_codigo_usu,
    d_creacion_par,
    c_usumod_par,
    d_modifi_par,
    c_activo_par,
    c_codigo_sis,
    c_tipodato_par,
    c_tipo_par,
    c_ocultar_par,
    c_addclient_par,
    c_edit_par
)
VALUES
(   '001',                                                                        -- c_codigo_par - char(3)
    'Validacion de Kilos Recibidos VS Empacados en Generacion de Pallet Virtual', -- v_nombre_par - varchar(100)
    'N',                                                                          -- v_valor_par - varchar(100)
    'admin',                                                                      -- c_codigo_usu - char(20)
    GETDATE(),                                                                    -- d_creacion_par - datetime
    NULL,                                                                         -- c_usumod_par - char(20)
    NULL,                                                                         -- d_modifi_par - datetime
    '1',                                                                          -- c_activo_par - char(1)
    '70',                                                                         -- c_codigo_sis - char(2)
    NULL,                                                                         -- c_tipodato_par - char(3)
    NULL,                                                                         -- c_tipo_par - varchar(25)
    NULL,                                                                         -- c_ocultar_par - char(1)
    NULL,                                                                         -- c_addclient_par - char(1)
    NULL                                                                          -- c_edit_par - char(1)
    );
