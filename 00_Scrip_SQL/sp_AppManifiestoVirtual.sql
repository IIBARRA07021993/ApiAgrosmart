/*|AGS|*/
IF EXISTS
(
    SELECT *
    FROM dbo.sysobjects
    WHERE id = OBJECT_ID(N'[dbo].[sp_AppManifiestoVirtual]')
)
    DROP PROCEDURE sp_AppManifiestoVirtual;
GO


/*|AGS|*/
CREATE PROCEDURE [dbo].[sp_AppManifiestoVirtual]
(
    @as_operation INT,
    @as_json VARCHAR(MAX),
    @as_success INT OUTPUT,
    @as_message VARCHAR(1024) OUTPUT
)
AS
SET NOCOUNT ON;

DECLARE @xml XML,
        @ls_tem VARCHAR(2),
        @ls_emp VARCHAR(2),
        @ls_pallet VARCHAR(10),
        @ls_man VARCHAR(10),
        @ls_terminal VARCHAR(100),
        @ls_usuario VARCHAR(20),
        @lb_nuevo BIT,
        @ls_mercado VARCHAR(1),
        @ls_sec_max NUMERIC;

SET @as_message = '';
SET @as_success = 0;
SELECT @xml = dbo.fn_parse_json2xml(@as_json);

IF @as_operation = 1 /*Marcar Pallet para manifiesto virtual*/
BEGIN
    BEGIN TRY
        BEGIN TRAN;
        /*SACAMOS LOS DATOS DEL JSON*/
        SELECT @ls_tem = RTRIM(LTRIM(ISNULL(n.el.value('c_codigo_tem[1]', 'varchar(2)'), ''))),
               @ls_emp = RTRIM(LTRIM(ISNULL(n.el.value('c_codigo_emp[1]', 'varchar(2)'), ''))),
               @ls_pallet = RTRIM(LTRIM(ISNULL(n.el.value('c_codigo_pal[1]', 'varchar(10)'), ''))),
               @ls_terminal = RTRIM(LTRIM(ISNULL(n.el.value('c_terminal_pal[1]', 'varchar(100)'), ''))),
               @ls_usuario = RTRIM(LTRIM(ISNULL(n.el.value('c_codigo_usu[1]', 'varchar(20)'), '')))
        FROM @xml.nodes('/') n(el);


        IF NOT EXISTS
        (
            SELECT *
            FROM dbo.t_palet pal
            WHERE pal.c_codigo_tem = @ls_tem
                  AND pal.c_codigo_emp = @ls_emp
                  AND
                  (
                      RTRIM(LTRIM(ISNULL(pal.c_codigo_pal, ''))) = @ls_pallet
                      OR RTRIM(LTRIM(ISNULL(pal.c_codigo_est, ''))) = @ls_pallet
                  )
                  AND ISNULL(pal.c_codigo_man, '') = ''
        )
        BEGIN
            SET @as_success = 0;
            SET @as_message
                = 'El pallet o Estiba <strong>' + @ls_pallet
                  + '</strong> No Existe , Ya fue Manifestado o no es del punto de empaque y temporada.';


        END;
        ELSE
        BEGIN
            IF EXISTS
            (
                SELECT *
                FROM dbo.t_palet pal
                WHERE pal.c_codigo_tem = @ls_tem
                      AND pal.c_codigo_emp = @ls_emp
                      AND
                      (
                          RTRIM(LTRIM(ISNULL(pal.c_codigo_pal, ''))) = @ls_pallet
                          OR RTRIM(LTRIM(ISNULL(pal.c_codigo_est, ''))) = @ls_pallet
                      )
                      AND ISNULL(pal.c_codigo_man, '') = ''
                      AND RTRIM(LTRIM(ISNULL(pal.c_marcado_pal, ''))) = '1'
            )
            BEGIN
                SET @as_success = 0;
                SET @as_message = 'El pallet <strong>' + @ls_pallet + '</strong> ya esta Marcado.';


            END;
            ELSE
            BEGIN

                UPDATE dbo.t_palet
                SET c_marcado_pal = '1',
                    c_terminal_pal = @ls_terminal,
                    c_codigo_usu = @ls_usuario,
                    d_modifi_pal = GETDATE()
                WHERE c_codigo_tem = @ls_tem
                      AND c_codigo_emp = @ls_emp
                      AND
                      (
                          RTRIM(LTRIM(ISNULL(c_codigo_pal, ''))) = @ls_pallet
                          OR RTRIM(LTRIM(ISNULL(c_codigo_est, ''))) = @ls_pallet
                      )
                      AND ISNULL(c_codigo_man, '') = ''
                      AND RTRIM(LTRIM(ISNULL(c_marcado_pal, ''))) <> '1';

                SET @as_success = 1;
                SET @as_message = 'El pallet o Estiba <strong>' + @ls_pallet + '</strong> Marcado Correctamente.';


            END;


        END;

        COMMIT TRAN;
    END TRY
    BEGIN CATCH
        SET @as_success = 0;
        SET @as_message = ERROR_MESSAGE();
        ROLLBACK TRAN;
    END CATCH;
END;

IF @as_operation = 2 /*Guardar Manifiesto Virtual*/
BEGIN
    BEGIN TRY
        BEGIN TRAN;

        /*SACAMOS LOS DATOS DEL JSON*/
        SELECT @ls_tem = RTRIM(LTRIM(ISNULL(n.el.value('c_codigo_tem[1]', 'varchar(2)'), ''))),
               @ls_emp = RTRIM(LTRIM(ISNULL(n.el.value('c_codigo_emp[1]', 'varchar(2)'), ''))),
               @lb_nuevo = n.el.value('b_nuevo[1]', 'BIT'),
               @ls_man = RTRIM(LTRIM(ISNULL(n.el.value('c_codigo_man[1]', 'varchar(10)'), ''))),
               @ls_terminal = RTRIM(LTRIM(ISNULL(n.el.value('c_terminal_pal[1]', 'varchar(100)'), ''))),
               @ls_usuario = RTRIM(LTRIM(ISNULL(n.el.value('c_codigo_usu[1]', 'varchar(20)'), '')))
        FROM @xml.nodes('/') n(el);

        /*Manifiesto ya guardado solo actulizar lo nuevo*/
        IF @lb_nuevo = 0
        BEGIN

            /*Actualizamos la cabecera*/
            UPDATE dbo.t_manifiestovirtual
            SET d_modifi_mv = GETDATE(),
                c_usumod_mv = @ls_usuario
            WHERE RTRIM(LTRIM(ISNULL(c_codigo_tem, ''))) = @ls_tem
                  AND RTRIM(LTRIM(ISNULL(c_codigo_emp, ''))) = @ls_emp
                  AND RTRIM(LTRIM(ISNULL(c_codigo_man, ''))) = @ls_man;



            /*Actulizamos las secuencia por si un pallet fue borrado*/
            UPDATE dbo.t_manifiestovirtualdet
            SET c_secuencia_mv = tb.c_secuencia_new
            FROM
            (
                SELECT det.c_codigo_tem,
                       det.c_codigo_emp,
                       det.c_codigo_man,
                       det.c_secuencia_mv,
                       c_secuencia_new = RIGHT('00'
                                               + CONVERT(   VARCHAR(2),
                                                            ROW_NUMBER() OVER (ORDER BY det.c_codigo_man,
                                                                                        det.c_codigo_tem,
                                                                                        det.c_codigo_emp,
                                                                                        det.c_codigo_pal,
                                                                                        det.c_secuencia_mv
                                                                              )
                                                        ), 2)
                FROM t_manifiestovirtualdet det
                WHERE RTRIM(LTRIM(ISNULL(det.c_codigo_tem, ''))) = @ls_tem
                      AND RTRIM(LTRIM(ISNULL(det.c_codigo_emp, ''))) = @ls_emp
                      AND RTRIM(LTRIM(ISNULL(det.c_codigo_man, ''))) = @ls_man
            ) tb
            WHERE t_manifiestovirtualdet.c_codigo_tem = tb.c_codigo_tem
                  AND t_manifiestovirtualdet.c_codigo_emp = tb.c_codigo_emp
                  AND t_manifiestovirtualdet.c_codigo_man = tb.c_codigo_man
                  AND t_manifiestovirtualdet.c_secuencia_mv = tb.c_secuencia_mv;



            /*	Sacamaos el maximo que quedo para aumentar la secuencia del que sigue para insertar marcado*/
            SELECT @ls_sec_max = CONVERT(NUMERIC, det.c_secuencia_mv)
            FROM t_manifiestovirtualdet det
            WHERE RTRIM(LTRIM(ISNULL(det.c_codigo_tem, ''))) = @ls_tem
                  AND RTRIM(LTRIM(ISNULL(det.c_codigo_emp, ''))) = @ls_emp
                  AND RTRIM(LTRIM(ISNULL(det.c_codigo_man, ''))) = @ls_man;


            INSERT INTO dbo.t_manifiestovirtualdet
            (
                c_codigo_man,
                c_codigo_tem,
                c_codigo_emp,
                c_secuencia_mv,
                c_codigo_pal,
                n_bulxpa_pal,
                c_tipo_pal,
                c_codigo_usu,
                d_creacion_mv,
                c_terminado_mv
            )
            SELECT c_codigo_man = @ls_man,
                   c_codigo_tem = pal.c_codigo_tem,
                   c_codigo_emp = pal.c_codigo_emp,
                   c_secuencia_mv = RIGHT('00'
                                          + CONVERT(
                                                       VARCHAR(2),
                                                       ROW_NUMBER() OVER (ORDER BY pal.c_codigo_emp,
                                                                                   pal.c_codigo_tem,
                                                                                   CASE
                                                                                       WHEN RTRIM(LTRIM(ISNULL(
                                                                                                                  pal.c_codigo_est,
                                                                                                                  ''
                                                                                                              )
                                                                                                       )
                                                                                                 ) = '' THEN
                                                                                           RTRIM(LTRIM(ISNULL(
                                                                                                                 pal.c_codigo_pal,
                                                                                                                 ''
                                                                                                             )
                                                                                                      )
                                                                                                )
                                                                                       ELSE
                                                                                           RTRIM(LTRIM(ISNULL(
                                                                                                                 pal.c_codigo_est,
                                                                                                                 ''
                                                                                                             )
                                                                                                      )
                                                                                                )
                                                                                   END,
                                                                                   RTRIM(LTRIM(ISNULL(
                                                                                                         pal.c_tipo_pal,
                                                                                                         ''
                                                                                                     )
                                                                                              )
                                                                                        )
                                                                         ) + @ls_sec_max
                                                   ), 2),
                   c_codigo_pal = CASE
                                      WHEN RTRIM(LTRIM(ISNULL(pal.c_codigo_est, ''))) = '' THEN
                                          RTRIM(LTRIM(ISNULL(pal.c_codigo_pal, '')))
                                      ELSE
                                          RTRIM(LTRIM(ISNULL(pal.c_codigo_est, '')))
                                  END,
                   n_bulxpa_pal = SUM(pal.n_bulxpa_pal),
                   c_tipo_pal = RTRIM(LTRIM(ISNULL(pal.c_tipo_pal, ''))),
                   c_codigo_usu = @ls_usuario,
                   d_creacion_mv = GETDATE(),
                   c_terminado_mv = '0'
            FROM dbo.t_palet pal (NOLOCK)
                LEFT JOIN dbo.t_manifiestovirtualdet det (NOLOCK)
                    ON det.c_codigo_pal = pal.c_codigo_pal
                       AND det.c_codigo_tem = pal.c_codigo_tem
                       AND det.c_codigo_emp = pal.c_codigo_emp
            WHERE pal.c_codigo_tem = @ls_tem
                  AND pal.c_codigo_emp = @ls_emp
                  AND RTRIM(LTRIM(ISNULL(pal.c_marcado_pal, ''))) = '1'
                  AND RTRIM(LTRIM(ISNULL(c_terminal_pal, ''))) = RTRIM(LTRIM(ISNULL(@ls_terminal, '')))
                  AND RTRIM(LTRIM(ISNULL(det.c_codigo_pal, ''))) = ''
            GROUP BY pal.c_codigo_emp,
                     pal.c_codigo_tem,
                     CASE
                         WHEN RTRIM(LTRIM(ISNULL(pal.c_codigo_est, ''))) = '' THEN
                             RTRIM(LTRIM(ISNULL(pal.c_codigo_pal, '')))
                         ELSE
                             RTRIM(LTRIM(ISNULL(pal.c_codigo_est, '')))
                     END,
                     RTRIM(LTRIM(ISNULL(pal.c_tipo_pal, '')));


            SET @as_success = 1;
            SET @as_message = 'El Manifiesto Virtual <strong>' + @ls_man + '</strong> Se Actualizo Correctamente.';
        END;
        ELSE
        BEGIN
            IF EXISTS
            (
                SELECT *
                FROM dbo.t_manifiestovirtual (NOLOCK)
                WHERE RTRIM(LTRIM(ISNULL(c_codigo_tem, ''))) = @ls_tem
                      AND RTRIM(LTRIM(ISNULL(c_codigo_emp, ''))) = @ls_emp
                      AND RTRIM(LTRIM(ISNULL(c_codigo_man, ''))) = @ls_man
            )
            BEGIN
                SET @as_success = 0;
                SET @as_message = 'El folio del Manifiesto Virtual <strong>' + @ls_man + '</strong> Ya fue utilizado.';
            END;
            ELSE
            BEGIN


                SET @ls_mercado = LEFT(@ls_man, 1);
                INSERT INTO dbo.t_manifiestovirtual
                (
                    c_codigo_man,
                    c_codigo_tem,
                    c_codigo_emp,
                    c_merdes_mv,
                    c_activo_mv,
                    d_fecha_mv,
                    c_codigo_usu,
                    d_creacion_mv,
                    c_usumod_mv,
                    d_modifi_mv
                )
                VALUES
                (@ls_man, @ls_tem, @ls_emp, @ls_mercado, '1', CONVERT(DATE, GETDATE()), @ls_usuario, GETDATE(), NULL,
                 NULL);


                INSERT INTO dbo.t_manifiestovirtualdet
                (
                    c_codigo_man,
                    c_codigo_tem,
                    c_codigo_emp,
                    c_secuencia_mv,
                    c_codigo_pal,
                    n_bulxpa_pal,
                    c_tipo_pal,
                    c_codigo_usu,
                    d_creacion_mv,
                    c_terminado_mv
                )
                SELECT c_codigo_man = @ls_man,
                       c_codigo_tem = pal.c_codigo_tem,
                       c_codigo_emp = pal.c_codigo_emp,
                       c_secuencia_mv = RIGHT('00'
                                              + CONVERT(
                                                           VARCHAR(2),
                                                           ROW_NUMBER() OVER (ORDER BY pal.c_codigo_emp,
                                                                                       pal.c_codigo_tem,
                                                                                       CASE
                                                                                           WHEN RTRIM(LTRIM(ISNULL(
                                                                                                                      pal.c_codigo_est,
                                                                                                                      ''
                                                                                                                  )
                                                                                                           )
                                                                                                     ) = '' THEN
                                                                                               RTRIM(LTRIM(ISNULL(
                                                                                                                     pal.c_codigo_pal,
                                                                                                                     ''
                                                                                                                 )
                                                                                                          )
                                                                                                    )
                                                                                           ELSE
                                                                                               RTRIM(LTRIM(ISNULL(
                                                                                                                     pal.c_codigo_est,
                                                                                                                     ''
                                                                                                                 )
                                                                                                          )
                                                                                                    )
                                                                                       END,
                                                                                       RTRIM(LTRIM(ISNULL(
                                                                                                             pal.c_tipo_pal,
                                                                                                             ''
                                                                                                         )
                                                                                                  )
                                                                                            )
                                                                             )
                                                       ), 2),
                       c_codigo_pal = CASE
                                          WHEN RTRIM(LTRIM(ISNULL(pal.c_codigo_est, ''))) = '' THEN
                                              RTRIM(LTRIM(ISNULL(pal.c_codigo_pal, '')))
                                          ELSE
                                              RTRIM(LTRIM(ISNULL(pal.c_codigo_est, '')))
                                      END,
                       n_bulxpa_pal = SUM(pal.n_bulxpa_pal),
                       c_tipo_pal = RTRIM(LTRIM(ISNULL(pal.c_tipo_pal, ''))),
                       c_codigo_usu = @ls_usuario,
                       d_creacion_mv = GETDATE(),
                       c_terminado_mv = '0'
                FROM dbo.t_palet pal (NOLOCK)
                    LEFT JOIN dbo.t_manifiestovirtualdet det (NOLOCK)
                        ON det.c_codigo_pal = pal.c_codigo_pal
                           AND det.c_codigo_tem = pal.c_codigo_tem
                           AND det.c_codigo_emp = pal.c_codigo_emp
                WHERE pal.c_codigo_tem = @ls_tem
                      AND pal.c_codigo_emp = @ls_emp
                      AND RTRIM(LTRIM(ISNULL(pal.c_marcado_pal, ''))) = '1'
                      AND RTRIM(LTRIM(ISNULL(c_terminal_pal, ''))) = RTRIM(LTRIM(ISNULL(@ls_terminal, '')))
                      AND RTRIM(LTRIM(ISNULL(det.c_codigo_pal, ''))) = ''
                GROUP BY pal.c_codigo_emp,
                         pal.c_codigo_tem,
                         CASE
                             WHEN RTRIM(LTRIM(ISNULL(pal.c_codigo_est, ''))) = '' THEN
                                 RTRIM(LTRIM(ISNULL(pal.c_codigo_pal, '')))
                             ELSE
                                 RTRIM(LTRIM(ISNULL(pal.c_codigo_est, '')))
                         END,
                         RTRIM(LTRIM(ISNULL(pal.c_tipo_pal, '')));

                SET @as_success = 1;
                SET @as_message = 'El Manifiesto Virtual <strong>' + @ls_man + '</strong> Se Guardo Correctamente.';

            END;
        END;
        COMMIT TRAN;
    END TRY
    BEGIN CATCH
        SET @as_success = 0;
        SET @as_message = ERROR_MESSAGE();
        ROLLBACK TRAN;
    END CATCH;
END;


IF @as_operation = 3 /*Liberamos Pallet Marcados que no estan en el manifiesto todabia*/
BEGIN
    BEGIN TRY
        BEGIN TRAN;
        /*SACAMOS LOS DATOS DEL JSON*/
        SELECT @ls_tem = RTRIM(LTRIM(ISNULL(n.el.value('c_codigo_tem[1]', 'varchar(2)'), ''))),
               @ls_emp = RTRIM(LTRIM(ISNULL(n.el.value('c_codigo_emp[1]', 'varchar(2)'), ''))),
               @ls_pallet = RTRIM(LTRIM(ISNULL(n.el.value('c_codigo_pal[1]', 'varchar(10)'), ''))),
               @ls_terminal = RTRIM(LTRIM(ISNULL(n.el.value('c_terminal_pal[1]', 'varchar(100)'), ''))),
               @ls_usuario = RTRIM(LTRIM(ISNULL(n.el.value('c_codigo_usu[1]', 'varchar(20)'), '')))
        FROM @xml.nodes('/') n(el);


        UPDATE dbo.t_palet
        SET c_marcado_pal = '0',
            c_terminal_pal = '',
            c_usumod_pal = @ls_usuario,
            d_modifi_pal = GETDATE()
        FROM dbo.t_palet pal (NOLOCK)
            LEFT JOIN dbo.t_manifiestovirtualdet det (NOLOCK)
                ON det.c_codigo_pal = pal.c_codigo_pal
                   AND det.c_codigo_tem = pal.c_codigo_tem
                   AND det.c_codigo_emp = pal.c_codigo_emp
        WHERE RTRIM(LTRIM(ISNULL(pal.c_codigo_tem, ''))) = @ls_tem
              AND
              (
                  RTRIM(LTRIM(ISNULL(pal.c_codigo_pal, ''))) LIKE @ls_pallet
                  OR RTRIM(LTRIM(ISNULL(pal.c_codigo_est, ''))) LIKE @ls_pallet
              )
              AND RTRIM(LTRIM(ISNULL(pal.c_codigo_emp, ''))) = @ls_emp
              AND RTRIM(LTRIM(ISNULL(pal.c_marcado_pal, ''))) = '1'
              AND RTRIM(LTRIM(ISNULL(c_terminal_pal, ''))) = @ls_terminal
              AND RTRIM(LTRIM(ISNULL(det.c_codigo_pal, ''))) = '';




        SET @as_success = 1;
        IF @ls_pallet = '%%'
        BEGIN
            SET @as_message = 'Los pallets o Estibas Desmarcados Correctamente.';
        END;
        ELSE
        BEGIN
            SET @as_message = 'El pallet o Estiba <strong>' + @ls_pallet + '</strong> Desmarcados Correctamente.';
        END;



        COMMIT TRAN;
    END TRY
    BEGIN CATCH
        SET @as_success = 0;
        SET @as_message = ERROR_MESSAGE();
        ROLLBACK TRAN;
    END CATCH;
END;



IF @as_operation = 4 /*Eliminamos Manifiesto Vitual*/
BEGIN
    BEGIN TRY
        BEGIN TRAN;
        /*SACAMOS LOS DATOS DEL JSON*/
        SELECT @ls_tem = RTRIM(LTRIM(ISNULL(n.el.value('c_codigo_tem[1]', 'varchar(2)'), ''))),
               @ls_emp = RTRIM(LTRIM(ISNULL(n.el.value('c_codigo_emp[1]', 'varchar(2)'), ''))),
               @ls_man = RTRIM(LTRIM(ISNULL(n.el.value('c_codigo_man[1]', 'varchar(10)'), ''))),
               @ls_terminal = RTRIM(LTRIM(ISNULL(n.el.value('c_terminal_pal[1]', 'varchar(100)'), ''))),
               @ls_usuario = RTRIM(LTRIM(ISNULL(n.el.value('c_codigo_usu[1]', 'varchar(20)'), '')))
        FROM @xml.nodes('/') n(el);

        UPDATE dbo.t_palet
        SET c_marcado_pal = '0',
            c_terminal_pal = '',
            c_usumod_pal = @ls_usuario,
            d_modifi_pal = GETDATE()
        FROM dbo.t_palet pal (NOLOCK)
            INNER JOIN dbo.t_manifiestovirtualdet det (NOLOCK)
                ON det.c_codigo_pal = pal.c_codigo_pal
                   AND det.c_codigo_tem = pal.c_codigo_tem
                   AND det.c_codigo_emp = pal.c_codigo_emp
        WHERE RTRIM(LTRIM(ISNULL(pal.c_codigo_tem, ''))) = @ls_tem
              AND RTRIM(LTRIM(ISNULL(pal.c_codigo_emp, ''))) = @ls_emp
              AND RTRIM(LTRIM(ISNULL(det.c_codigo_man, ''))) = @ls_man
              AND RTRIM(LTRIM(ISNULL(pal.c_marcado_pal, ''))) = '1'
              AND RTRIM(LTRIM(ISNULL(c_terminal_pal, ''))) = @ls_terminal;


        /*Eliminamos Todos los detalles de manifiesto virtual*/
        DELETE dbo.t_manifiestovirtualdet
        WHERE RTRIM(LTRIM(ISNULL(c_codigo_tem, ''))) = @ls_tem
              AND RTRIM(LTRIM(ISNULL(c_codigo_emp, ''))) = @ls_emp
              AND RTRIM(LTRIM(ISNULL(c_codigo_man, ''))) = @ls_man;


        /*Eliminamos Manifiesto virtual*/
        DELETE dbo.t_manifiestovirtual
        WHERE RTRIM(LTRIM(ISNULL(c_codigo_tem, ''))) = @ls_tem
              AND RTRIM(LTRIM(ISNULL(c_codigo_emp, ''))) = @ls_emp
              AND RTRIM(LTRIM(ISNULL(c_codigo_man, ''))) = @ls_man;

        SET @as_success = 1;
        SET @as_message = 'Manifiesto Virtual <strong>' + @ls_man + '</strong> Eliminado Correctamente.';


        COMMIT TRAN;
    END TRY
    BEGIN CATCH
        SET @as_success = 0;
        SET @as_message = ERROR_MESSAGE();
        ROLLBACK TRAN;
    END CATCH;
END;



IF @as_operation = 5 /*eliminamos  Pallet de manifiesto virtual y desmarcamos*/
BEGIN
    BEGIN TRY
        BEGIN TRAN;
        /*SACAMOS LOS DATOS DEL JSON*/
        SELECT @ls_tem = RTRIM(LTRIM(ISNULL(n.el.value('c_codigo_tem[1]', 'varchar(2)'), ''))),
               @ls_emp = RTRIM(LTRIM(ISNULL(n.el.value('c_codigo_emp[1]', 'varchar(2)'), ''))),
               @ls_pallet = RTRIM(LTRIM(ISNULL(n.el.value('c_codigo_pal[1]', 'varchar(10)'), ''))),
               @ls_terminal = RTRIM(LTRIM(ISNULL(n.el.value('c_terminal_pal[1]', 'varchar(100)'), ''))),
               @ls_usuario = RTRIM(LTRIM(ISNULL(n.el.value('c_codigo_usu[1]', 'varchar(20)'), '')))
        FROM @xml.nodes('/') n(el);


        IF NOT EXISTS
        (
            SELECT *
            FROM dbo.t_palet pal
            WHERE pal.c_codigo_tem = @ls_tem
                  AND pal.c_codigo_emp = @ls_emp
                  AND
                  (
                      RTRIM(LTRIM(ISNULL(pal.c_codigo_pal, ''))) = @ls_pallet
                      OR RTRIM(LTRIM(ISNULL(pal.c_codigo_est, ''))) = @ls_pallet
                  )
                  AND ISNULL(pal.c_codigo_man, '') = ''
        )
        BEGIN
            SET @as_success = 0;
            SET @as_message
                = 'El pallet o Estiba <strong>' + @ls_pallet
                  + '</strong> No Existe , Ya fue Manifestado o no es del punto de empaque y temporada.';


        END;
        ELSE
        BEGIN

            UPDATE dbo.t_palet
            SET c_marcado_pal = '0',
                c_terminal_pal = '',
                c_codigo_usu = @ls_usuario,
                d_modifi_pal = GETDATE()
            WHERE c_codigo_tem = @ls_tem
                  AND c_codigo_emp = @ls_emp
                  AND
                  (
                      RTRIM(LTRIM(ISNULL(c_codigo_pal, ''))) = @ls_pallet
                      OR RTRIM(LTRIM(ISNULL(c_codigo_est, ''))) = @ls_pallet
                  )
                  AND ISNULL(c_codigo_man, '') = ''
                  AND RTRIM(LTRIM(ISNULL(c_marcado_pal, ''))) = '1';



            DELETE dbo.t_manifiestovirtualdet
            WHERE c_codigo_tem = @ls_tem
                  AND c_codigo_emp = @ls_emp
                  AND RTRIM(LTRIM(ISNULL(c_codigo_pal, ''))) = @ls_pallet;


            SET @as_success = 1;
            SET @as_message = 'El pallet o Estiba <strong>' + @ls_pallet + '</strong> Liberado Correctamente.';


        END;




        COMMIT TRAN;
    END TRY
    BEGIN CATCH
        SET @as_success = 0;
        SET @as_message = ERROR_MESSAGE();
        ROLLBACK TRAN;
    END CATCH;
END;
