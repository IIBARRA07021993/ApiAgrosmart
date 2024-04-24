/*|AGS|*/
IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id = OBJECT_ID(N'[dbo].[sp_AppAreasFisicas]'))
	DROP PROCEDURE sp_AppAreasFisicas 

/*|AGS|*/
CREATE PROCEDURE [dbo].[sp_AppAreasFisicas]
(
    @as_operation INT,
    @as_json VARCHAR(MAX),
    @as_success INT OUTPUT,
    @as_message VARCHAR(1024) OUTPUT
)
AS
SET NOCOUNT ON;

SET @as_message = '';
SET @as_success = 0;

IF @as_operation = 1 /*consultar áreas fisicas para cargar en Dropdown*/
BEGIN
    BEGIN TRY

        SELECT c_codigo_are = c_codigo_are ,
               v_nombre_are = v_nombre_are 
		FROM t_areafisica (NOLOCK)
		WHERE c_activo_are = '1';

        SET @as_success = 1;
        SET @as_message = 'OK';
    END TRY
    BEGIN CATCH
        SET @as_success = 0;
        SET @as_message = ERROR_MESSAGE();
    END CATCH;
END;
