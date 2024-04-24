/*
DECLARE @as_success INT,
        @as_message VARCHAR(1024);
EXEC dbo.sp_AppLogin @as_operation = 1,                -- int
                   @as_json = '{"c_codigo_usu":"ADMIN","v_passwo_usu":"ccons"}',                    -- varchar(max)
                   @as_success = @as_success OUTPUT, -- int
                   @as_message = @as_message OUTPUT; -- varchar(1024)

PRINT @as_success;
PRINT @as_message;
*/
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
                SET @as_message = 'Bienvenido ' + +ISNULL(@ls_nombreusuario, '') + ' a AgroSmart Empaque';
            END;
            ELSE
            BEGIN
                SET @as_success = 0;
                SET @as_message = 'La Contraseña es Incorrecta';
            END;
        END;
        ELSE
        BEGIN
            SET @as_success = 0;
            SET @as_message = 'El Usuario ' + @as_usuario + ' No existe';
        END;
    END TRY
    BEGIN CATCH
        SET @as_success = 0;
        SET @as_message = ERROR_MESSAGE();
       
    END CATCH;
END;

