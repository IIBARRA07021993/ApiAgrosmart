/*|AGS|*/
IF EXISTS
(
    SELECT *
    FROM dbo.sysobjects
    WHERE id = OBJECT_ID(N'[dbo].[sp_AppControlConteoCaja]')
)
    DROP PROCEDURE sp_AppControlConteoCaja;
GO


/*|AGS|*/
CREATE PROCEDURE [dbo].[sp_AppControlConteoCaja]
(
    @as_operation INT,
    @as_json VARCHAR(MAX),
    @as_success INT OUTPUT,
    @as_message VARCHAR(1024) OUTPUT
)
AS
SET NOCOUNT ON;

DECLARE @xml XML,
        @ls_temporada VARCHAR(2),
        @ls_empaque VARCHAR(2),
        @ls_terminal VARCHAR(100),
        @ls_empleado VARCHAR(6),
        @ls_tarima VARCHAR(6),
        @ls_tarima_EXT VARCHAR(6),
        @idcaja VARCHAR(14),
        @idcaja_ext VARCHAR(14),
        @b_embarcado BIT,
        @ls_tarimacerrada VARCHAR(1),
        @ls_productotarima VARCHAR(8),
        @ls_prodcutocaja VARCHAR(8),
        @ll_count_protarima INT,
        @ll_palmixto INT,
        @ls_usuario VARCHAR(20),
        @ldc_bultosxpal NUMERIC,
        @ldc_bultos NUMERIC,
        @ls_codigo_pal VARCHAR(10);

SET @as_message = '';
SET @as_success = 0;
SET @ll_palmixto = 0;
SELECT @xml = dbo.fn_parse_json2xml(@as_json);


IF @as_operation >= 1
   AND @as_operation <= 4
BEGIN
    BEGIN TRY


        /*SACAMOS LOS DATOS DEL JSON*/
        SELECT @ls_temporada = RTRIM(LTRIM(ISNULL(n.el.value('c_codigo_tem[1]', 'varchar(2)'), ''))),
               @ls_empaque = RTRIM(LTRIM(ISNULL(n.el.value('c_codigo_emp[1]', 'varchar(2)'), ''))),
               @ls_tarima = RTRIM(LTRIM(ISNULL(n.el.value('c_idtarima_ccp[1]', 'varchar(6)'), ''))),
               @idcaja = RTRIM(LTRIM(ISNULL(n.el.value('c_idcaja_cpp[1]', 'varchar(14)'), ''))),
               @ls_empleado = RTRIM(LTRIM(ISNULL(n.el.value('c_empleado_emp[1]', 'varchar(6)'), ''))),
               @ls_usuario = RTRIM(LTRIM(ISNULL(n.el.value('c_codigo_usu[1]', 'varchar(20)'), ''))),
               @b_embarcado = RTRIM(LTRIM(ISNULL(n.el.value('b_empacador[1]', 'BIT'), '')))
        FROM @xml.nodes('/') n(el);

        --SET @idcaja ='11002300000008'



        IF RTRIM(LTRIM(ISNULL(@ls_empleado, ''))) = ''
        BEGIN
            SELECT TOP 1
                   @ls_empleado = c_codigo_emp
            FROM dbo.t_controlcaja_pallet (NOLOCK)
            WHERE RTRIM(LTRIM(ISNULL(c_codigo_tem, ''))) = @ls_temporada
                  AND RTRIM(LTRIM(ISNULL(c_codigo_pem, ''))) = @ls_empaque
                  AND RTRIM(LTRIM(ISNULL(c_idcaja_ccp, ''))) = @idcaja;
        END;

        SELECT TOP 1
               @ls_tarimacerrada = RTRIM(LTRIM(ISNULL(c_cerrado_cch, 'N')))
        FROM t_control_conteo_hh hh (NOLOCK)
        WHERE hh.c_idtarima_ccp = @ls_tarima;

        IF RTRIM(LTRIM(ISNULL(@ls_tarimacerrada, ''))) = 'S'
        BEGIN
            SET @as_success = 0;
            SET @as_message = 'La tarima ya ha sido cerrada, no puede ingresarse de nuevo';
            RETURN;
        END;


        /*VALIDACION DEL ID DE CAJA*/
        IF RTRIM(LTRIM(ISNULL(@idcaja, ''))) = ''
        BEGIN
            SET @as_success = 0;
            SET @as_message = 'Código de Caja No puede estar Vacío ';
            RETURN;
        END;
        IF ISNUMERIC(RTRIM(LTRIM(ISNULL(@idcaja, '')))) = ''
        BEGIN
            SET @as_success = 0;
            SET @as_message = 'Código de caja solo puede contener Números';
            RETURN;
        END;
        IF LEN(RTRIM(LTRIM(ISNULL(@idcaja, '')))) < 14
        BEGIN
            SET @as_success = 0;
            SET @as_message = 'Código de caja debe ser de 14 dígitos';
            RETURN;
        END;

        /*VALIDACION DEL ID DE CAJA*/
        IF RTRIM(LTRIM(ISNULL(@ls_tarima, ''))) = ''
        BEGIN
            SET @as_success = 0;
            SET @as_message = 'Código de Tarima No puede estar Vacío ';
            RETURN;
        END;
        IF LEN(RTRIM(LTRIM(ISNULL(@ls_tarima, '')))) < 6
        BEGIN
            SET @as_success = 0;
            SET @as_message = 'Código de Tarima debe ser de 6 caracteres';
            RETURN;
        END;

        /*VALIDACION CODIGO DE EMPLEADO*/
        IF @b_embarcado = 1
        BEGIN

            IF RTRIM(LTRIM(ISNULL(@ls_empleado, ''))) = ''
            BEGIN
                SET @as_success = 0;
                SET @as_message = 'Código de Empleado No puede estar Vacío ';
                RETURN;
            END;

            IF LEN(RTRIM(LTRIM(ISNULL(@ls_empleado, '')))) < 6
            BEGIN
                SET @as_success = 0;
                SET @as_message = 'Código de Empleado debe ser de 6 caracteres';
                RETURN;
            END;
        END;

        SELECT TOP 1
               @idcaja_ext = RTRIM(LTRIM(ISNULL(CCJ.c_idcaja_ccp, ''))),
               @ls_tarima_EXT = RTRIM(LTRIM(ISNULL(CCJ.c_idtarima_ccp, ''))),
               @ls_codigo_pal = RTRIM(LTRIM(ISNULL(CCJ.c_codigo_pal, '')))
        FROM t_controlcaja_pallet CCJ (NOLOCK)
        WHERE RTRIM(LTRIM(ISNULL(CCJ.c_idcaja_ccp, ''))) = @idcaja
              AND RTRIM(LTRIM(ISNULL(CCJ.c_codigo_tem, ''))) = @ls_temporada
              AND RTRIM(LTRIM(ISNULL(CCJ.c_codigo_pem, ''))) = @ls_empaque;

        IF RTRIM(LTRIM(ISNULL(@idcaja_ext, ''))) = ''
        BEGIN
            SET @as_success = 0;
            SET @as_message = 'El código de caja  [' + @idcaja + '] Invalido No Existe';
            RETURN;
        END;

        IF RTRIM(LTRIM(ISNULL(@ls_tarima_EXT, ''))) <> ''
        BEGIN
            SET @as_success = 0;
            SET @as_message
                = 'El código de caja  [' + @idcaja + '] ya fue escaneado en otra tarima  y confirmado como pallet['
                  + @ls_codigo_pal + '].';
            RETURN;
        END;


        SELECT @ll_count_protarima = COUNT(DISTINCT c_codigo_pro)
        FROM t_controlcaja_pallet a (NOLOCK)
            INNER JOIN t_control_conteo_hh b (NOLOCK)
                ON a.c_idcaja_ccp = b.c_idcaja_cpp
                   AND b.c_idtarima_ccp = @ls_tarima;



        IF ISNULL(@ll_count_protarima, 0) = 1 /*SI ES NOMAL se revisa que con el que se vaya meter no se haga mixto*/
        BEGIN

            SELECT TOP 1
                   @ls_productotarima = RTRIM(LTRIM(ISNULL(c_codigo_pro, '')))
            FROM t_controlcaja_pallet a (NOLOCK)
                INNER JOIN t_control_conteo_hh b (NOLOCK)
                    ON a.c_idcaja_ccp = b.c_idcaja_cpp
                       AND RTRIM(LTRIM(ISNULL(b.c_idtarima_ccp, ''))) = @ls_tarima;

            SELECT TOP 1
                   @ls_prodcutocaja = RTRIM(LTRIM(ISNULL(c_codigo_pro, '')))
            FROM t_controlcaja_pallet a (NOLOCK)
            WHERE RTRIM(LTRIM(ISNULL(a.c_idcaja_ccp, ''))) = @idcaja;



            IF RTRIM(LTRIM(ISNULL(@ls_productotarima, ''))) <> RTRIM(LTRIM(ISNULL(@ls_prodcutocaja, '')))
            BEGIN
                SET @ll_palmixto = 1;
            END;


        END;

        IF ISNULL(@ll_count_protarima, 0) > 1 /*Es mixto ya*/
        BEGIN
            SET @ll_palmixto = 2;
        END;


        IF @ll_palmixto = 0 /*SI ES NORMAL VALIDAMOS SI YA TIENE LAS CAJAS COMPLETAS*/
        BEGIN
            SELECT @ldc_bultos = COUNT(a.c_idcaja_ccp)
            FROM t_controlcaja_pallet a (NOLOCK)
                INNER JOIN t_control_conteo_hh b (NOLOCK)
                    ON a.c_idcaja_ccp = b.c_idcaja_cpp
                       AND b.c_idtarima_ccp = @ls_tarima;

            SELECT @ldc_bultosxpal = ISNULL(n_bulxpa_pro, 0)
            FROM dbo.t_producto (NOLOCK)
            WHERE ISNULL(c_codigo_pro, '') = LEFT(ISNULL(@ls_prodcutocaja, ''), 4);

            IF ISNULL(@ldc_bultos, 0) = ISNULL(@ldc_bultosxpal, 0)
               AND ISNULL(@ldc_bultos, 0) > 0
            BEGIN
                SET @as_success = 0;
                SET @as_message
                    = 'La tarima [' + @ls_tarima
                      + '] ha llegado a los bultos asignados por producto para pallet Nomal.';
                RETURN;
            END;
        END;



        SET @idcaja_ext = '';
        SET @ls_tarima_EXT = '';
        SET @ls_tarimacerrada = '';

        SELECT @idcaja_ext = RTRIM(LTRIM(ISNULL(hh.c_idcaja_cpp, ''))),
               @ls_tarima_EXT = RTRIM(LTRIM(ISNULL(hh.c_idtarima_ccp, ''))),
               @ls_tarimacerrada = RTRIM(LTRIM(ISNULL(c_cerrado_cch, 'N')))
        FROM t_control_conteo_hh hh (NOLOCK)
        WHERE RTRIM(LTRIM(ISNULL(hh.c_idcaja_cpp, ''))) = @idcaja;

        IF @as_operation = 1
        BEGIN
            IF RTRIM(LTRIM(ISNULL(@idcaja_ext, ''))) <> ''
               AND RTRIM(LTRIM(ISNULL(@ls_tarima_EXT, ''))) <> RTRIM(LTRIM(ISNULL(@ls_tarima, '')))
            BEGIN

                IF RTRIM(LTRIM(ISNULL(@ls_tarimacerrada, ''))) = 'S'
                   AND @ll_palmixto = 1
                BEGIN


                    SET @as_success = 3;
                    SET @as_message
                        = 'El código de caja  [' + @idcaja + '] ya fue escaneado en otra tarima cerrada ['
                          + @ls_tarima_EXT + '], ¿ Deseas cambiar la caja de tarima?';
                    RETURN;

                END;



                IF RTRIM(LTRIM(ISNULL(@ls_tarimacerrada, ''))) = 'S'
                   AND @ll_palmixto <> 1
                BEGIN
                    SET @as_success = 4;
                    SET @as_message
                        = 'El código de caja  [' + @idcaja + '] ya fue escaneado en otra tarima cerrada ['
                          + @ls_tarima_EXT + '], ¿ Deseas cambiar la caja de tarima?';
                    RETURN;

                END;

                IF @ll_palmixto = 1
                BEGIN
                    SET @as_success = 5;
                END;
                ELSE
                BEGIN
                    SET @as_success = 6;
                END;

                SET @as_message
                    = 'El código de caja  [' + @idcaja + '] ya fue escaneado en otra tarima [' + @ls_tarima_EXT
                      + '] , ¿ Deseas cambiar la caja de tarima?';
                RETURN;
            END;


            IF RTRIM(LTRIM(ISNULL(@idcaja_ext, ''))) <> ''
            BEGIN
                SET @as_success = 0;
                SET @as_message = 'El código de caja  [' + @idcaja + '] ya fue escaneado.';
                RETURN;
            END;

            /*si pasa tosas las validaciones pero es mixto*/
            IF ISNULL(@ll_palmixto, 0) = 1
            BEGIN
                SET @as_success = 2;
                SET @as_message
                    = 'El pallet sera convertido a mixto ya que el producto ingresado no es del mismo tipo, ¿Desea continuar? ';
                RETURN;
            END;
        END;





        BEGIN TRAN;
        IF @as_operation = 2
        BEGIN

            UPDATE dbo.t_control_conteo_hh
            SET c_idtarima_ccp = @ls_tarima,
                c_estibador_cch = @ls_usuario,
                c_hrtarima_cch = LEFT(CONVERT(VARCHAR, GETDATE(), 14), 8),
                c_cerrado_cch = 'N'
            WHERE c_idcaja_cpp = @idcaja;

            SET @as_success = 1;
            SET @as_message = 'Se actualizaron los datos de tarima a la caja [' + @idcaja + '] de manera exitosa.';
            COMMIT TRAN;
            RETURN;
        END;

        IF @as_operation = 3
        BEGIN

            SET @idcaja_ext = '';
            SET @ls_tarima_EXT = '';
            SET @ls_tarimacerrada = '';

            SELECT @idcaja_ext = RTRIM(LTRIM(ISNULL(hh.c_idcaja_cpp, ''))),
                   @ls_tarima_EXT = RTRIM(LTRIM(ISNULL(hh.c_idtarima_ccp, ''))),
                   @ls_tarimacerrada = RTRIM(LTRIM(ISNULL(c_cerrado_cch, 'N')))
            FROM t_control_conteo_hh hh (NOLOCK)
            WHERE RTRIM(LTRIM(ISNULL(hh.c_idcaja_cpp, ''))) = @idcaja;



            /*Actulizamos caja con nueva tarima*/
            UPDATE dbo.t_control_conteo_hh
            SET c_idtarima_ccp = @ls_tarima,
                c_estibador_cch = @ls_usuario,
                c_hrtarima_cch = LEFT(CONVERT(VARCHAR, GETDATE(), 14), 8),
                c_cerrado_cch = 'N'
            WHERE c_idcaja_cpp = @idcaja;

            /*actulizamos tarima que tenia lacaja como cerrada que tenia la caja como abierta*/
            UPDATE dbo.t_control_conteo_hh
            SET c_cerrado_cch = 'N'
            WHERE c_idtarima_ccp = @ls_tarima_EXT;



            SET @as_success = 1;
            SET @as_message
                = 'Se actualizaron los datos de tarima a la caja [' + @idcaja
                  + '] de manera exitosa y se marcó como abierta la tarima [' + @ls_tarima_EXT
                  + '] que tenía anteriormente.';
            COMMIT TRAN;
            RETURN;

        END;


        INSERT INTO t_control_conteo_hh
        (
            c_idtarima_ccp,
            c_idcaja_cpp,
            d_tarima_cch,
            c_hrtarima_cch,
            c_cerrado_cch,
            c_estibador_cch,
            b_enviado_FTP,
            c_codigo_emp
        )
        VALUES
        (@ls_tarima, @idcaja, GETDATE(), LEFT(CONVERT(VARCHAR, GETDATE(), 14), 8), 'N', @ls_usuario, DEFAULT,
         @ls_empleado);


        SET @as_success = 1;
        SET @as_message = 'Caja [' + @idcaja + '] Agregada Con Exito';



        COMMIT TRAN;
    END TRY
    BEGIN CATCH
        SET @as_success = 0;
        SET @as_message = ERROR_MESSAGE();
        ROLLBACK TRAN;
    END CATCH;
END;





IF @as_operation = 5 /*ELIMINAR CAJA O TARIMA COMPLETA*/
BEGIN
    BEGIN TRY
        /*SACAMOS LOS DATOS DEL JSON*/
        SELECT @ls_temporada = RTRIM(LTRIM(ISNULL(n.el.value('c_codigo_tem[1]', 'varchar(2)'), ''))),
               @ls_empaque = RTRIM(LTRIM(ISNULL(n.el.value('c_codigo_emp[1]', 'varchar(2)'), ''))),
               @ls_tarima = RTRIM(LTRIM(ISNULL(n.el.value('c_idtarima_ccp[1]', 'varchar(6)'), ''))),
               @idcaja = RTRIM(LTRIM(ISNULL(n.el.value('c_idcaja_cpp[1]', 'varchar(14)'), '')))
        FROM @xml.nodes('/') n(el);



        IF RTRIM(LTRIM(ISNULL(@ls_tarima, ''))) = ''
        BEGIN
            SET @as_success = 0;
            SET @as_message = 'Falta elegir tarima.';
            RETURN;
        END;


        SELECT TOP 1
               @ls_tarimacerrada = RTRIM(LTRIM(ISNULL(c_cerrado_cch, 'N')))
        FROM t_control_conteo_hh hh (NOLOCK)
        WHERE hh.c_idtarima_ccp = @ls_tarima;

        IF RTRIM(LTRIM(ISNULL(@ls_tarimacerrada, ''))) = 'S'
        BEGIN
            SET @as_success = 0;
            SET @as_message = 'La tarima ya ha sido cerrada, no puede eliminar caja';
            RETURN;
        END;

        BEGIN TRAN;
        /*Eliminamos la caja*/
        DELETE dbo.t_control_conteo_hh
        WHERE RTRIM(LTRIM(ISNULL(c_idcaja_cpp, ''))) LIKE @idcaja
              AND RTRIM(LTRIM(ISNULL(c_idtarima_ccp, ''))) = @ls_tarima;


        SET @as_success = 1;
        IF @idcaja = '%%'
        BEGIN
            SET @as_message = 'Tarima [' + @idcaja + '] Eliminada Con Exito';
        END;
        ELSE
        BEGIN
            SET @as_message = 'Caja [' + @idcaja + '] Eliminada Con Exito';
        END;

        COMMIT TRAN;
    END TRY
    BEGIN CATCH
        SET @as_success = 0;
        SET @as_message = ERROR_MESSAGE();
        ROLLBACK TRAN;
    END CATCH;
END;




IF @as_operation = 6 /*CERRAR TARIMA*/
BEGIN
    BEGIN TRY
        /*SACAMOS LOS DATOS DEL JSON*/
        SELECT @ls_temporada = RTRIM(LTRIM(ISNULL(n.el.value('c_codigo_tem[1]', 'varchar(2)'), ''))),
               @ls_empaque = RTRIM(LTRIM(ISNULL(n.el.value('c_codigo_emp[1]', 'varchar(2)'), ''))),
               @ls_tarima = RTRIM(LTRIM(ISNULL(n.el.value('c_idtarima_ccp[1]', 'varchar(6)'), ''))),
               @ls_usuario = RTRIM(LTRIM(ISNULL(n.el.value('c_codigo_usu[1]', 'varchar(20)'), '')))
        FROM @xml.nodes('/') n(el);

        SELECT TOP 1
               @ls_tarimacerrada = RTRIM(LTRIM(ISNULL(c_cerrado_cch, 'N')))
        FROM t_control_conteo_hh hh (NOLOCK)
        WHERE hh.c_idtarima_ccp = @ls_tarima;

        IF RTRIM(LTRIM(ISNULL(@ls_tarima, ''))) = ''
        BEGIN
            SET @as_success = 0;
            SET @as_message = 'Falta elegir tarima para cierre.';
            RETURN;
        END;


        IF RTRIM(LTRIM(ISNULL(@ls_tarimacerrada, ''))) = 'S'
        BEGIN
            SET @as_success = 0;
            SET @as_message = 'La tarima ya ha sido cerrada.';
            RETURN;
        END;


        BEGIN TRAN;
        /*Eliminamos la caja*/
        UPDATE t_control_conteo_hh
        SET c_cerrado_cch = 'S',
            c_estibador_cch = @ls_usuario
        WHERE RTRIM(LTRIM(ISNULL(c_idtarima_ccp, ''))) = @ls_tarima;


        SET @as_success = 1;
        SET @as_message = 'Tarima [' + @ls_tarima + '] Cerrada Con Exito';

        COMMIT TRAN;
    END TRY
    BEGIN CATCH
        SET @as_success = 0;
        SET @as_message = ERROR_MESSAGE();
        ROLLBACK TRAN;
    END CATCH;
END;



