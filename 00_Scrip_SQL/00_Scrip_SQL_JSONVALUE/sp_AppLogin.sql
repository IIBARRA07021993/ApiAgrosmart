/*|AGS|*/
IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id = OBJECT_ID(N'[dbo].[sp_AppLogin]'))
	DROP PROCEDURE sp_AppLogin 
	GO
    
/*|AGS|*/
CREATE PROCEDURE [dbo].[sp_AppLogin]
(
    @as_operation INT,
    @as_json VARCHAR(MAX),
    @as_success INT OUTPUT,
    @as_message VARCHAR(1024) OUTPUT
)
AS
SET NOCOUNT ON;
DECLARE @as_usuario VARCHAR(20),
        @as_paswword VARCHAR(20),
        @ls_nombreusuario VARCHAR(50),
        @ls_paswword VARCHAR(20);
SET @as_message = '';
SET @as_success = 0;

IF @as_operation = 1 /*Login de Aplicacion*/
BEGIN
    BEGIN TRY


        /*SACAMOS LOS DATOS DEL USUARIO DEL JSON*/
        SELECT @as_usuario = JSON_VALUE(@as_json, '$.c_codigo_usu'),
               @as_paswword = JSON_VALUE(@as_json, '$.v_passwo_usu');

        /*CONSULTAMOS DATOS DEL USUARIO*/
        IF EXISTS
        (
            SELECT *
            FROM dbo.assusuario usu (NOLOCK)
            WHERE usu.c_codigo_usu = @as_usuario
        )
        BEGIN
            SELECT TOP 1
                   @ls_paswword = usu.v_passwo_usu,
                   @ls_nombreusuario = usu.v_nombre_usu
            FROM dbo.assusuario usu (NOLOCK)
            WHERE usu.c_codigo_usu = @as_usuario;


            IF ISNULL(@as_paswword, '') = ISNULL(@ls_paswword, '')
            BEGIN
                SET @as_success = 1;
                SET @as_message = 'Bienvenido '  +ISNULL(@ls_nombreusuario, '') + ' a AgroSmart Empaque';
            END;
            ELSE
            BEGIN
                SET @as_success = 0;
                SET @as_message = 'Usuario o Contraseña Incorrecta';
            END;
        END;
        ELSE
        BEGIN
            SET @as_success = 0;
            SET @as_message = 'Usuario o Contraseña Incorrecta';
        END;
    END TRY
    BEGIN CATCH
        SET @as_success = 0;
        SET @as_message = ERROR_MESSAGE();
       
    END CATCH;
END;

