--DELETE dbo.assusuariosistemamenu
--WHERE c_codigo_sis ='70'

DELETE dbo.asssistemamenu
WHERE c_codigo_sis = '70';
GO
/*|AGS|*/
IF NOT EXISTS (SELECT * FROM asssistema WHERE c_codigo_sis = '70')
BEGIN
    INSERT INTO asssistema
    (
        c_codigo_sis,
        v_nombre_sis,
        c_codigo_usu,
        d_creacion_sis,
        c_usumod_sis,
        d_modifi_sis,
        c_activo_sis,
        v_descripcion_sis,
        v_imagetile_sis,
        v_urlwiki_sis,
        vb_activo_sis,
        v_version_sis,
        d_fechaversion_sis
    )
    VALUES
    ('70', 'AgroSmart Empaque App', 'ADMIN', GETDATE(), NULL, NULL, '1', 'AgroSmart Empaque App', '',
     'http://wiki.inventum.com.mx/index.php?title=P%C3%A1gina_principal', NULL, NULL, NULL);
END;
/*|AGS|*/
IF NOT EXISTS
(
    SELECT *
    FROM asssistemamenu
    WHERE c_codigo_sis = '70'
          AND c_codigo_sme = '0100'
)
BEGIN
    INSERT INTO asssistemamenu
    (
        c_codigo_sis,
        c_codigo_sme,
        c_codigo_pad,
        v_nombre_sme,
        v_descripcion_sme,
        v_nombretab_sme,
        c_opcion_sme,
        n_orden_sme,
        c_escarpeta_sme,
        v_nombreclase_sme,
        v_imagetile,
        v_imagenameselected,
        v_imagename,
        v_urlwiki_sme,
        c_codigo_usu,
        d_creacion_sme,
        c_usumod_sme,
        d_modifi_sme,
        c_activo_sme
    )
    VALUES
    ('70', '0100', '', 'Surtir Pedidos', 'Surtir Pedidos', 'Surtir Pedidos', '', 1, '0', '/pedidos/1',
     'push-outline', '', 'assets\icon\orden.png', 'http://wiki.inventum.com.mx/index.php?title=P%C3%A1gina_principal', 'ADMIN', GETDATE(),
     NULL, NULL, '1');
END;

/*|AGS|*/
IF NOT EXISTS
(
    SELECT *
    FROM asssistemamenu
    WHERE c_codigo_sis = '70'
          AND c_codigo_sme = '0101'
)
BEGIN
    INSERT INTO asssistemamenu
    (
        c_codigo_sis,
        c_codigo_sme,
        c_codigo_pad,
        v_nombre_sme,
        v_descripcion_sme,
        v_nombretab_sme,
        c_opcion_sme,
        n_orden_sme,
        c_escarpeta_sme,
        v_nombreclase_sme,
        v_imagetile,
        v_imagenameselected,
        v_imagename,
        v_urlwiki_sme,
        c_codigo_usu,
        d_creacion_sme,
        c_usumod_sme,
        d_modifi_sme,
        c_activo_sme
    )
    VALUES
    ('70', '0101', '', 'Control de Ubicación', 'Control de Ubicación', 'Control de Ubicación', '', 2, '0',
     '/palet-ubi', 'location-outline', '', 'assets\icon\mapas.png', 'http://wiki.inventum.com.mx/index.php?title=P%C3%A1gina_principal',
     'ADMIN', GETDATE(), NULL, NULL, '1');
END;

UPDATE dbo.asssistemamenu
SET v_nombre_sme ='Control de Ubicación',
v_descripcion_sme ='Control de Ubicación',v_nombretab_sme ='Control de Ubicación',v_nombreclase_sme = '/palet-ubi'
 WHERE c_codigo_sis = '70'
          AND c_codigo_sme = '0101'
/*|AGS|*/
IF NOT EXISTS
(
    SELECT *
    FROM asssistemamenu
    WHERE c_codigo_sis = '70'
          AND c_codigo_sme = '0102'
)
BEGIN
    INSERT INTO asssistemamenu
    (
        c_codigo_sis,
        c_codigo_sme,
        c_codigo_pad,
        v_nombre_sme,
        v_descripcion_sme,
        v_nombretab_sme,
        c_opcion_sme,
        n_orden_sme,
        c_escarpeta_sme,
        v_nombreclase_sme,
        v_imagetile,
        v_imagenameselected,
        v_imagename,
        v_urlwiki_sme,
        c_codigo_usu,
        d_creacion_sme,
        c_usumod_sme,
        d_modifi_sme,
        c_activo_sme
    )
    VALUES
    ('70', '0102', '', 'Manifiesto Virtual', 'Manifiesto Virtual', 'Manifiesto Virtual', '', 3, '0', '/man-virtual',
     'reader-outline', '',  'assets\icon\cargaman.png', 'http://wiki.inventum.com.mx/index.php?title=P%C3%A1gina_principal', 'ADMIN', GETDATE(),
     NULL, NULL, '1');
END;


/*|AGS|*/
IF NOT EXISTS
(
    SELECT *
    FROM asssistemamenu
    WHERE c_codigo_sis = '70'
          AND c_codigo_sme = '0103'
)
BEGIN
    INSERT INTO asssistemamenu
    (
        c_codigo_sis,
        c_codigo_sme,
        c_codigo_pad,
        v_nombre_sme,
        v_descripcion_sme,
        v_nombretab_sme,
        c_opcion_sme,
        n_orden_sme,
        c_escarpeta_sme,
        v_nombreclase_sme,
        v_imagetile,
        v_imagenameselected,
        v_imagename,
        v_urlwiki_sme,
        c_codigo_usu,
        d_creacion_sme,
        c_usumod_sme,
        d_modifi_sme,
        c_activo_sme
    )
    VALUES
    ('70', '0103', '', 'Crear Corrida', 'Crear Corrida',
     'Crear Corrida', '', 1, '0', '/sorting-est', 'download-outline', '', 'assets\icon\surtido.png',
     'http://wiki.inventum.com.mx/index.php?title=P%C3%A1gina_principal', 'ADMIN', GETDATE(), NULL, NULL, '1');
END;

/*|AGS|*/
IF NOT EXISTS
(
    SELECT *
    FROM asssistemamenu
    WHERE c_codigo_sis = '70'
          AND c_codigo_sme = '0104'
)
BEGIN
    INSERT INTO asssistemamenu
    (
        c_codigo_sis,
        c_codigo_sme,
        c_codigo_pad,
        v_nombre_sme,
        v_descripcion_sme,
        v_nombretab_sme,
        c_opcion_sme,
        n_orden_sme,
        c_escarpeta_sme,
        v_nombreclase_sme,
        v_imagetile,
        v_imagenameselected,
        v_imagename,
        v_urlwiki_sme,
        c_codigo_usu,
        d_creacion_sme,
        c_usumod_sme,
        d_modifi_sme,
        c_activo_sme
    )
    VALUES
    ('70', '0104', '', 'Control de Ubicaciones', 'Control de Ubicaciones',
     'Control de Ubicaciones', '', 5, '0', '/cambio-ubi', 'push-outline', '', 'assets\icon\mapas.png',
     'http://wiki.inventum.com.mx/index.php?title=P%C3%A1gina_principal', 'ADMIN', GETDATE(), NULL, NULL, '1');
END;

/*|AGS|*/
IF NOT EXISTS
(
    SELECT *
    FROM asssistemamenu
    WHERE c_codigo_sis = '70'
          AND c_codigo_sme = '0105'
)
BEGIN
    INSERT INTO asssistemamenu
    (
        c_codigo_sis,
        c_codigo_sme,
        c_codigo_pad,
        v_nombre_sme,
        v_descripcion_sme,
        v_nombretab_sme,
        c_opcion_sme,
        n_orden_sme,
        c_escarpeta_sme,
        v_nombreclase_sme,
        v_imagetile,
        v_imagenameselected,
        v_imagename,
        v_urlwiki_sme,
        c_codigo_usu,
        d_creacion_sme,
        c_usumod_sme,
        d_modifi_sme,
        c_activo_sme
    )
    VALUES
    ('70', '0105', '', 'Creacíon de palet temporal', 'Registro De Pallets', 'Registro De Pallets', '',
     3  , '0', '/palet-temp', 'add-circle-outline', '', 'assets\icon\pallet.png',
     'http://wiki.inventum.com.mx/index.php?title=P%C3%A1gina_principal', 'ADMIN', GETDATE(), NULL, NULL, '1');
END;

/*|AGS|*/
IF NOT EXISTS
(
    SELECT *
    FROM asssistemamenu
    WHERE c_codigo_sis = '70'
          AND c_codigo_sme = '0106'
)
BEGIN
    INSERT INTO asssistemamenu
    (
        c_codigo_sis,
        c_codigo_sme,
        c_codigo_pad,
        v_nombre_sme,
        v_descripcion_sme,
        v_nombretab_sme,
        c_opcion_sme,
        n_orden_sme,
        c_escarpeta_sme,
        v_nombreclase_sme,
        v_imagetile,
        v_imagenameselected,
        v_imagename,
        v_urlwiki_sme,
        c_codigo_usu,
        d_creacion_sme,
        c_usumod_sme,
        d_modifi_sme,
        c_activo_sme
    )
    VALUES
    ('70', '0106', '', 'Armado de Pallet (Control Estibe)', 'Armado de Pallet (Control Estibe)',
     'Armado de Pallet (Control Estibe)', '', 7, '0', '/armado-pal', 'layers-outline', '', 'assets\icon\pallet.png',
     'http://wiki.inventum.com.mx/index.php?title=P%C3%A1gina_principal', 'ADMIN', GETDATE(), NULL, NULL, '1');
END;

/*|AGS|*/
IF NOT EXISTS
(
    SELECT *
    FROM asssistemamenu
    WHERE c_codigo_sis = '70'
          AND c_codigo_sme = '0107'
)
BEGIN
    INSERT INTO asssistemamenu
    (
        c_codigo_sis,
        c_codigo_sme,
        c_codigo_pad,
        v_nombre_sme,
        v_descripcion_sme,
        v_nombretab_sme,
        c_opcion_sme,
        n_orden_sme,
        c_escarpeta_sme,
        v_nombreclase_sme,
        v_imagetile,
        v_imagenameselected,
        v_imagename,
        v_urlwiki_sme,
        c_codigo_usu,
        d_creacion_sme,
        c_usumod_sme,    
        d_modifi_sme,
        c_activo_sme
    )
    VALUES
    ('70', '0107', '', 'Control Tiraje(Asignación a Empleado).', 'Control Tiraje(Asignación a Empleado).',
     'Control Tiraje(Asignación a Empleado).', '', 8, '0', '/tiraje-empleado', 'repeat-outline', '', 'assets\icon\recurso.png',
     'http://wiki.inventum.com.mx/index.php?title=P%C3%A1gina_principal', 'ADMIN', GETDATE(), NULL, NULL, '1');
END;



/*|AGS|*/
IF NOT EXISTS
(
    SELECT *
    FROM asssistemamenu
    WHERE c_codigo_sis = '70'
          AND c_codigo_sme = '0108'
)
BEGIN
    INSERT INTO asssistemamenu
    (
        c_codigo_sis,
        c_codigo_sme,
        c_codigo_pad,
        v_nombre_sme,
        v_descripcion_sme,
        v_nombretab_sme,
        c_opcion_sme,
        n_orden_sme,
        c_escarpeta_sme,
        v_nombreclase_sme,
        v_imagetile,
        v_imagenameselected,
        v_imagename,
        v_urlwiki_sme,
        c_codigo_usu,
        d_creacion_sme,
        c_usumod_sme,    
        d_modifi_sme,
        c_activo_sme
    )
    VALUES
    ('70', '0108', '', 'Control de Pallets Virtuales', 'Control de Pallets Virtuales',
     'Control de Pallets Virtuales', '', 9, '0', '/controlpallet', 'repeat-outline', '', 'assets\icon\lista-de-verificacion.png',
     'http://wiki.inventum.com.mx/index.php?title=P%C3%A1gina_principal', 'ADMIN', GETDATE(), NULL, NULL, '1');
END;




/*|AGS|*/
IF NOT EXISTS
(
    SELECT *
    FROM asssistemamenu
    WHERE c_codigo_sis = '70'
          AND c_codigo_sme = '0109'
)
BEGIN
    INSERT INTO asssistemamenu
    (
        c_codigo_sis,
        c_codigo_sme,
        c_codigo_pad,
        v_nombre_sme,
        v_descripcion_sme,
        v_nombretab_sme,
        c_opcion_sme,
        n_orden_sme,
        c_escarpeta_sme,
        v_nombreclase_sme,
        v_imagetile,
        v_imagenameselected,
        v_imagename,
        v_urlwiki_sme,
        c_codigo_usu,
        d_creacion_sme,
        c_usumod_sme,    
        d_modifi_sme,
        c_activo_sme
    )
    VALUES
    ('70', '0109', '', 'Tarima Virtual (Conteo)', 'Tarima Virtual (Conteo)',
     'Tarima Virtual (Conteo)', '', 10, '0', '/tarima-conteo', 'repeat-outline', '', 'assets\icon\paleta.png',
     'http://wiki.inventum.com.mx/index.php?title=P%C3%A1gina_principal', 'ADMIN', GETDATE(), NULL, NULL, '1');
END;

/*|AGS|*/
IF NOT EXISTS
(
    SELECT *
    FROM asssistemamenu
    WHERE c_codigo_sis = '70'
          AND c_codigo_sme = '0110'
)
BEGIN
    INSERT INTO asssistemamenu
    (
        c_codigo_sis,
        c_codigo_sme,
        c_codigo_pad,
        v_nombre_sme,
        v_descripcion_sme,
        v_nombretab_sme,
        c_opcion_sme,
        n_orden_sme,
        c_escarpeta_sme,
        v_nombreclase_sme,
        v_imagetile,
        v_imagenameselected,
        v_imagename,
        v_urlwiki_sme,
        c_codigo_usu,
        d_creacion_sme,
        c_usumod_sme,    
        d_modifi_sme,
        c_activo_sme
    )
    VALUES
    ('70', '0110', '', 'Cambio de ubicación', 'Cambio de ubicación',
     'Cambio de ubicación', '', 10, '0', '/posicion-ubi', 'push-outline', '', 'assets\icon\mapas.png',
     'http://wiki.inventum.com.mx/index.php?title=P%C3%A1gina_principal', 'ADMIN', GETDATE(), NULL, NULL, '1');
END;

/*|AGS|*/
IF NOT EXISTS
(
    SELECT *
    FROM asssistemamenu
    WHERE c_codigo_sis = '70'
          AND c_codigo_sme = '0111'
)
BEGIN
    INSERT INTO asssistemamenu
    (
        c_codigo_sis,
        c_codigo_sme,
        c_codigo_pad,
        v_nombre_sme,
        v_descripcion_sme,
        v_nombretab_sme,
        c_opcion_sme,
        n_orden_sme,
        c_escarpeta_sme,
        v_nombreclase_sme,
        v_imagetile,
        v_imagenameselected,
        v_imagename,
        v_urlwiki_sme,
        c_codigo_usu,
        d_creacion_sme,
        c_usumod_sme,    
        d_modifi_sme,
        c_activo_sme
    )
    VALUES
    ('70', '0111', '', 'Crea Corrida P/Calibre', 'Crea Corrida P/Calibre',
     'Crea Corrida P/Calibre', '', 2, '0', '/sorting-pal', 'download-outline', '', 'assets\icon\surtido.png',
     'http://wiki.inventum.com.mx/index.php?title=P%C3%A1gina_principal', 'ADMIN', GETDATE(), NULL, NULL, '1');
END;

/*|AGS|*/
IF NOT EXISTS
(
    SELECT *
    FROM asssistemamenu
    WHERE c_codigo_sis = '70'
          AND c_codigo_sme = '0112'
)
BEGIN
    INSERT INTO asssistemamenu
    (
        c_codigo_sis,
        c_codigo_sme,
        c_codigo_pad,
        v_nombre_sme,
        v_descripcion_sme,
        v_nombretab_sme,
        c_opcion_sme,
        n_orden_sme,
        c_escarpeta_sme,
        v_nombreclase_sme,
        v_imagetile,
        v_imagenameselected,
        v_imagename,
        v_urlwiki_sme,
        c_codigo_usu,
        d_creacion_sme,
        c_usumod_sme,    
        d_modifi_sme,
        c_activo_sme
    )
    VALUES
    ('70', '0112', '', 'Tiempo en Zonas de Monitoreo', 'Tiempo en Zonas de Monitoreo',
     'Tiempo en Zonas de Monitoreo', '', 6, '0', '/palet-tiempo', 'download-outline', '', 'assets\icon\temporizador.png',
     'http://wiki.inventum.com.mx/index.php?title=P%C3%A1gina_principal', 'ADMIN', GETDATE(), NULL, NULL, '1');
END;

/*|AGS|*/
IF NOT EXISTS
(
    SELECT *
    FROM asssistemamenu
    WHERE c_codigo_sis = '70'
          AND c_codigo_sme = '0113'
)
BEGIN
    INSERT INTO asssistemamenu
    (
        c_codigo_sis,
        c_codigo_sme,
        c_codigo_pad,
        v_nombre_sme,
        v_descripcion_sme,
        v_nombretab_sme,
        c_opcion_sme,
        n_orden_sme,
        c_escarpeta_sme,
        v_nombreclase_sme,
        v_imagetile,
        v_imagenameselected,
        v_imagename,
        v_urlwiki_sme,
        c_codigo_usu,
        d_creacion_sme,
        c_usumod_sme,    
        d_modifi_sme,
        c_activo_sme
    )
    VALUES
    ('70', '0113', '', 'Entregar Pallet a Eye Plus', 'Entregar Pallet a Eye Plus',
     'Entregar Pallet a Eye Plus', '', 7, '0', '/palet-final', 'download-outline', '', 'assets\icon\pallet.png',
     'http://wiki.inventum.com.mx/index.php?title=P%C3%A1gina_principal', 'ADMIN', GETDATE(), NULL, NULL, '1');
END;

/*|AGS|*/
IF NOT EXISTS
(
    SELECT *
    FROM asssistemamenu
    WHERE c_codigo_sis = '70'
          AND c_codigo_sme = '0114'
)
BEGIN
    INSERT INTO asssistemamenu
    (
        c_codigo_sis,
        c_codigo_sme,
        c_codigo_pad,
        v_nombre_sme,
        v_descripcion_sme,
        v_nombretab_sme,
        c_opcion_sme,
        n_orden_sme,
        c_escarpeta_sme,
        v_nombreclase_sme,
        v_imagetile,
        v_imagenameselected,
        v_imagename,
        v_urlwiki_sme,
        c_codigo_usu,
        d_creacion_sme,
        c_usumod_sme,    
        d_modifi_sme,
        c_activo_sme
    )
    VALUES
    ('70', '0114', '', 'Consultar pallet', 'Consultar pallet',
     'Consultar pallet', '', 4, '0', '/consulta-pal', 'download-outline', '', 'assets\icon\informe.png',
     'http://wiki.inventum.com.mx/index.php?title=P%C3%A1gina_principal', 'ADMIN', GETDATE(), NULL, NULL, '1');
END;
/*|AGS|*/
IF NOT EXISTS
(
    SELECT *
    FROM asssistemamenu
    WHERE c_codigo_sis = '70'
          AND c_codigo_sme = '0115'
)
BEGIN
    INSERT INTO asssistemamenu
    (
        c_codigo_sis,
        c_codigo_sme,
        c_codigo_pad,
        v_nombre_sme,
        v_descripcion_sme,
        v_nombretab_sme,
        c_opcion_sme,
        n_orden_sme,
        c_escarpeta_sme,
        v_nombreclase_sme,
        v_imagetile,
        v_imagenameselected,
        v_imagename,
        v_urlwiki_sme,
        c_codigo_usu,
        d_creacion_sme,
        c_usumod_sme,    
        d_modifi_sme,
        c_activo_sme
    )
    VALUES
    ('70', '0115', '', 'Crea Corrida P/Costumer Pack', 'Crea Corrida P/Costumer Pack',
     'Crea Corrida P/Costumer Pack', '', 3, '0', '/sorting-pak', 'download-outline', '', 'assets\icon\surtido.png',
     'http://wiki.inventum.com.mx/index.php?title=P%C3%A1gina_principal', 'ADMIN', GETDATE(), NULL, NULL, '1');
END;

/*|AGS|*/
IF NOT EXISTS
(
    SELECT *
    FROM asssistemamenu
    WHERE c_codigo_sis = '70'
          AND c_codigo_sme = '0116'
)
BEGIN
    INSERT INTO asssistemamenu
    (
        c_codigo_sis,
        c_codigo_sme,
        c_codigo_pad,
        v_nombre_sme,
        v_descripcion_sme,
        v_nombretab_sme,
        c_opcion_sme,
        n_orden_sme,
        c_escarpeta_sme,
        v_nombreclase_sme,
        v_imagetile,
        v_imagenameselected,
        v_imagename,
        v_urlwiki_sme,
        c_codigo_usu,
        d_creacion_sme,
        c_usumod_sme,    
        d_modifi_sme,
        c_activo_sme
    )
    VALUES
    ('70', '0116', '', 'Pallet Consumer Pack', 'Pallet Consumer Pack',
     'Pallet Consumer Pack', '', 4, '0', '/palet-pack', 'download-outline', '', 'assets\icon\pallet.png',
     'http://wiki.inventum.com.mx/index.php?title=P%C3%A1gina_principal', 'ADMIN', GETDATE(), NULL, NULL, '1');
END;

/*|AGS|*/
IF NOT EXISTS
(
    SELECT *
    FROM asssistemamenu
    WHERE c_codigo_sis = '70'
          AND c_codigo_sme = '0117'
)
BEGIN
    INSERT INTO asssistemamenu
    (
        c_codigo_sis,
        c_codigo_sme,
        c_codigo_pad,
        v_nombre_sme,
        v_descripcion_sme,
        v_nombretab_sme,
        c_opcion_sme,
        n_orden_sme,
        c_escarpeta_sme,
        v_nombreclase_sme,
        v_imagetile,
        v_imagenameselected,
        v_imagename,
        v_urlwiki_sme,
        c_codigo_usu,
        d_creacion_sme,
        c_usumod_sme,    
        d_modifi_sme,
        c_activo_sme
    )
    VALUES
    ('70', '0117', '', 'Consolidar Pallet', 'Consolidar Pallet',
     'Consolidar Pallet', '', 16, '0', '/palet-consol', 'download-outline', '', 'assets\icon\pallet.png',
     'http://wiki.inventum.com.mx/index.php?title=P%C3%A1gina_principal', 'ADMIN', GETDATE(), NULL, NULL, '1');
END;


/*|AGS|*/
IF NOT EXISTS
(
    SELECT *
    FROM asssistemamenu
    WHERE c_codigo_sis = '70'
          AND c_codigo_sme = '0118'
)
BEGIN
    INSERT INTO asssistemamenu
    (
        c_codigo_sis,
        c_codigo_sme,
        c_codigo_pad,
        v_nombre_sme,
        v_descripcion_sme,
        v_nombretab_sme,
        c_opcion_sme,
        n_orden_sme,
        c_escarpeta_sme,
        v_nombreclase_sme,
        v_imagetile,
        v_imagenameselected,
        v_imagename,
        v_urlwiki_sme,
        c_codigo_usu,
        d_creacion_sme,
        c_usumod_sme,    
        d_modifi_sme,
        c_activo_sme
    )
    VALUES
    ('70', '0118', '', 'Conteo Directo', 'Conteo Directo',
     'Conteo Directo', '', 18, '0', '/conteocajaspage', 'download-outline', '', 'assets\icon\codigo-de-barras.gif',
     'http://wiki.inventum.com.mx/index.php?title=P%C3%A1gina_principal', 'ADMIN', GETDATE(), NULL, NULL, '1');
END;

/*|AGS|*/
IF NOT EXISTS
(
    SELECT *
    FROM asssistemamenu
    WHERE c_codigo_sis = '70'
          AND c_codigo_sme = '0119'
)
BEGIN
    INSERT INTO asssistemamenu
    (
        c_codigo_sis,
        c_codigo_sme,
        c_codigo_pad,
        v_nombre_sme,
        v_descripcion_sme,
        v_nombretab_sme,
        c_opcion_sme,
        n_orden_sme,
        c_escarpeta_sme,
        v_nombreclase_sme,
        v_imagetile,
        v_imagenameselected,
        v_imagename,
        v_urlwiki_sme,
        c_codigo_usu,
        d_creacion_sme,
        c_usumod_sme,    
        d_modifi_sme,
        c_activo_sme
    )
    VALUES
    ('70', '0119', '', 'Elaboración de Transferencias', 'Elaboración de Transferencias',
     'Elaboración de Transferencias', '', 19, '0', '/palet-transfe', 'download-outline', '', 'assets\icon\Transferecia.png',
     'http://wiki.inventum.com.mx/index.php?title=P%C3%A1gina_principal', 'ADMIN', GETDATE(), NULL, NULL, '1');
END;

/*|AGS|*/
IF NOT EXISTS
(
    SELECT *
    FROM asssistemamenu
    WHERE c_codigo_sis = '70'
          AND c_codigo_sme = '0120'
)
BEGIN
    INSERT INTO asssistemamenu
    (
        c_codigo_sis,
        c_codigo_sme,
        c_codigo_pad,
        v_nombre_sme,
        v_descripcion_sme,
        v_nombretab_sme,
        c_opcion_sme,
        n_orden_sme,
        c_escarpeta_sme,
        v_nombreclase_sme,
        v_imagetile,
        v_imagenameselected,
        v_imagename,
        v_urlwiki_sme,
        c_codigo_usu,
        d_creacion_sme,
        c_usumod_sme,    
        d_modifi_sme,
        c_activo_sme
    )
    VALUES
    ('70', '0120', '', 'Recepción de Transferencias', 'Recepción de Transferencias',
     'Recepción de Transferencias', '', 20, '0', '/palet-recepcion', 'download-outline', '', 'assets\icon\lista-de-verificacion.png',
     'http://wiki.inventum.com.mx/index.php?title=P%C3%A1gina_principal', 'ADMIN', GETDATE(), NULL, NULL, '1');
END;
/*==========================Permisos especiales=============================*/
/*|AGS|*/
IF NOT EXISTS
(
    SELECT *
    FROM asssistemamenu
    WHERE c_codigo_sis = '70'
          AND c_codigo_sme = '0197'
)
BEGIN
    INSERT INTO asssistemamenu
    (
        c_codigo_sis,
        c_codigo_sme,
        c_codigo_pad,
        v_nombre_sme,
        v_descripcion_sme,
        v_nombretab_sme,
        c_opcion_sme,
        n_orden_sme,
        c_escarpeta_sme,
        v_nombreclase_sme,
        v_imagetile,
        v_imagenameselected,
        v_imagename,
        v_urlwiki_sme,
        c_codigo_usu,
        d_creacion_sme,
        c_usumod_sme,
        d_modifi_sme,
        c_activo_sme
    )
    VALUES
    ('70', '0197', '', 'Permiso para agregar presentaciones que no están en el pedido al surtir pallet.',
     'Permiso para agregar presentaciones que no están en el pedido al surtir pallet.',
     'Permiso para agregar presentaciones que no están en el pedido al surtir pallet.', '', 0, '0', '', '', '', '',
     'http://wiki.inventum.com.mx/index.php?title=P%C3%A1gina_principal', 'ADMIN', GETDATE(), NULL, NULL, '1');
END;
/*|AGS|*/
IF NOT EXISTS
(
    SELECT *
    FROM asssistemamenu
    WHERE c_codigo_sis = '70'
          AND c_codigo_sme = '0198'
)
BEGIN
    INSERT INTO asssistemamenu
    (
        c_codigo_sis,
        c_codigo_sme,
        c_codigo_pad,
        v_nombre_sme,
        v_descripcion_sme,
        v_nombretab_sme,
        c_opcion_sme,
        n_orden_sme,
        c_escarpeta_sme,
        v_nombreclase_sme,
        v_imagetile,
        v_imagenameselected,
        v_imagename,
        v_urlwiki_sme,
        c_codigo_usu,
        d_creacion_sme,
        c_usumod_sme,
        d_modifi_sme,
        c_activo_sme
    )
    VALUES
    ('70', '0198', '', 'Permiso para exceder las cajas pedidas de una presentación al surtir el pallet.',
     'Permiso para exceder las cajas pedidas de una presentación al surtir el pallet.',
     'Permiso para exceder las cajas pedidas de una presentación al surtir el pallet.', '', 0, '0', '', '', '', '',
     'http://wiki.inventum.com.mx/index.php?title=P%C3%A1gina_principal', 'ADMIN', GETDATE(), NULL, NULL, '1');
END;
/*|AGS|*/
IF NOT EXISTS
(
    SELECT *
    FROM asssistemamenu
    WHERE c_codigo_sis = '70'
          AND c_codigo_sme = '0199'
)
BEGIN
    INSERT INTO asssistemamenu
    (
        c_codigo_sis,
        c_codigo_sme,
        c_codigo_pad,
        v_nombre_sme,
        v_descripcion_sme,
        v_nombretab_sme,
        c_opcion_sme,
        n_orden_sme,
        c_escarpeta_sme,
        v_nombreclase_sme,
        v_imagetile,
        v_imagenameselected,
        v_imagename,
        v_urlwiki_sme,
        c_codigo_usu,
        d_creacion_sme,
        c_usumod_sme,
        d_modifi_sme,
        c_activo_sme
    )
    VALUES
    ('70', '0199', '', 'Permiso para activar manejo de conteo de cajas en generación de pallet virtual.',
     'Permiso para activar manejo de conteo de cajas en generación de pallet virtual.',
     'Permiso para activar manejo de conteo de cajas en generación de pallet virtual.', '', 0, '0', '', '', '', '',
     'http://wiki.inventum.com.mx/index.php?title=P%C3%A1gina_principal', 'ADMIN', GETDATE(), NULL, NULL, '1');
END;


