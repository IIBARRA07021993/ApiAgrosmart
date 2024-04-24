/*|AGS|*/
IF NOT EXISTS
(
    SELECT *
    FROM asssistemamenu
    WHERE c_codigo_sis = '02'
          AND c_codigo_sme = '9020'
)
BEGIN
    INSERT INTO dbo.asssistemamenu
    (
        c_codigo_sis,
        c_codigo_sme,
        v_nombre_sme,
        c_codigo_usu,
        d_creacion_sme,
        c_usumod_sme,
        d_modifi_sme,
        c_activo_sme,
        c_codigo_pad,
        v_imagename,
        v_imagenameselected,
        v_imagetile,
        v_descripcion_sme,
        c_escarpeta_sme,
        v_nombreclase_sme,
        v_nombretab_sme,
        c_opcion_sme,
        n_orden_sme,
        v_urlwiki_sme
    )
    VALUES
    ('02', '9020', 'Permiso para poder abrir corridas cerradas', 'ADMIN',
     GETDATE(), NULL, NULL, '1', NULL, '', '', '',
     'Permiso para poder abrir corridas cerradas', NULL, NULL,
     'Permiso para poder abrir corridas cerradas', NULL, NULL, NULL);
END;

