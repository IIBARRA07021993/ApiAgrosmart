/*|AGS|*/
IF EXISTS
(
    SELECT *
    FROM dbo.sysobjects
    WHERE id = OBJECT_ID(N'[dbo].[sp_AppOpcionesMenu]')
)
    DROP PROCEDURE sp_AppOpcionesMenu;
GO
/*|AGS|*/
CREATE PROCEDURE [dbo].[sp_AppOpcionesMenu]
(
    @as_operation INT,
    @as_json VARCHAR(MAX),
    @as_success INT OUTPUT,
    @as_message VARCHAR(1024) OUTPUT
)
AS
SET NOCOUNT ON;

DECLARE @xml XML,
        @as_usuario VARCHAR(20),
        @as_sis VARCHAR(2),
        @as_permiso VARCHAR(4),
        @c_tienepermiso BIT;

SET @as_message = '';
SET @as_success = 0;
SELECT @xml = dbo.fn_parse_json2xml(@as_json);

IF @as_operation = 1 /*consultar opciones del menu que tenga el usuario permiso */
BEGIN
    BEGIN TRY



        /*SACAMOS LOS DATOS  DEL JSON*/
        SELECT @as_usuario = RTRIM(LTRIM(ISNULL(n.el.value('c_codigo_usu[1]', 'varchar(20)'), ''))),
               @as_sis = RTRIM(LTRIM(ISNULL(n.el.value('c_codigo_sis[1]', 'varchar(2)'), '')))
        FROM @xml.nodes('/') n(el);


        SELECT c_codigo_sme = sm.c_codigo_sme,
               v_nombre_sme = sm.v_nombre_sme,
               v_imagetile = sm.v_imagetile,
               v_nombreclase_sme = sm.v_nombreclase_sme,
               v_imagename = sm.v_imagename
        FROM dbo.asssistemamenu sm (NOLOCK)
            INNER JOIN dbo.asssistema sis (NOLOCK)
                ON (sis.c_codigo_sis = sm.c_codigo_sis)
            INNER JOIN dbo.assusuariosistemamenu usm (NOLOCK)
                ON (
                       usm.c_codigo_sis = sm.c_codigo_sis
                       AND usm.c_codigo_sme = sm.c_codigo_sme
                   )
        WHERE usm.c_codigo_usu = @as_usuario
              AND sis.c_codigo_sis = @as_sis
              AND sm.c_activo_sme = '1'
              AND sis.c_activo_sis = '1'
              AND RTRIM(LTRIM(ISNULL(sm.v_nombreclase_sme, ''))) <> '' /*si no tiene clase no es menu*/
        ORDER BY SUBSTRING(sm.c_codigo_sis, 1, 2),
                 sm.n_orden_sme,
                 sm.c_codigo_sme;


        SET @as_success = 1;
        SET @as_message = 'OK';
    END TRY
    BEGIN CATCH
        SET @as_success = 0;
        SET @as_message = ERROR_MESSAGE();
    END CATCH;
END;


IF @as_operation = 2 /*consulta de permiso especial configurado en el sistema */
BEGIN
    BEGIN TRY

        /*SACAMOS LOS DATOS  DEL JSON*/
        SELECT @as_usuario = RTRIM(LTRIM(ISNULL(n.el.value('c_codigo_usu[1]', 'varchar(20)'), ''))),
               @as_sis = RTRIM(LTRIM(ISNULL(n.el.value('c_codigo_sis[1]', 'varchar(2)'), ''))),
               @as_permiso = RTRIM(LTRIM(ISNULL(n.el.value('c_codigo_sme[1]', 'varchar(4)'), '')))
        FROM @xml.nodes('/') n(el);


        SELECT TOP 1
               c_codigo_sme = sm.c_codigo_sme
        FROM dbo.asssistemamenu sm (NOLOCK)
            INNER JOIN dbo.asssistema sis (NOLOCK)
                ON (sis.c_codigo_sis = sm.c_codigo_sis)
            INNER JOIN dbo.assusuariosistemamenu usm (NOLOCK)
                ON (
                       usm.c_codigo_sis = sm.c_codigo_sis
                       AND usm.c_codigo_sme = sm.c_codigo_sme
                   )
        WHERE usm.c_codigo_usu = @as_usuario
              AND sis.c_codigo_sis = @as_sis
              AND sm.c_codigo_sme = @as_permiso
              AND sm.c_activo_sme = '1'
              AND sis.c_activo_sis = '1'
              AND usm.c_activo_usm = '1'
              AND RTRIM(LTRIM(ISNULL(sm.v_nombreclase_sme, ''))) = ''; /*si no tiene clase no es menu*/

        SET @as_success = 1;
        SET @as_message = 'OK';
    END TRY
    BEGIN CATCH
        SET @as_success = 0;
        SET @as_message = ERROR_MESSAGE();
    END CATCH;
END;