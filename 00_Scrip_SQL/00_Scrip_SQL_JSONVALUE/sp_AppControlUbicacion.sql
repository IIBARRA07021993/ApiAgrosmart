/*|AGS|*/
IF EXISTS
(
    SELECT *
    FROM dbo.sysobjects
    WHERE id = OBJECT_ID(N'dbo.sp_AppControlUbicacion')
)
    DROP PROCEDURE sp_AppControlUbicacion;
GO


/*|AGS|*/
CREATE PROCEDURE dbo.sp_AppControlUbicacion
(
    @as_operation INT,
    @as_json VARCHAR(MAX),
    @as_success INT OUTPUT,
    @as_message VARCHAR(1024) OUTPUT
)
AS
SET NOCOUNT ON;

DECLARE @ls_tem VARCHAR(2),
        @ls_emp VARCHAR(2),
        @ls_pallet VARCHAR(10),
        @ls_nivel VARCHAR(4),
        @ls_nomnivel VARCHAR(100),
        @ls_columna VARCHAR(4),
        @ls_nomcolumna VARCHAR(100),
        @ls_posicion VARCHAR(4),
        @ls_nomposicion VARCHAR(100),
        @ls_usuario VARCHAR(20),
        @ls_espaciofisico VARCHAR(10),
        @ls_presentacionpal VARCHAR(50),
        @ls_pedido VARCHAR(16);

SET @as_message = '';
SET @as_success = 0;



IF @as_operation = 1 /*Asignar Ubicacion al pallet*/
BEGIN
    BEGIN TRY
        BEGIN TRAN;

        /*SACAMOS LOS DATOS DEL JSON*/
        SELECT @ls_tem = RTRIM(LTRIM(ISNULL(JSON_VALUE(@as_json, '$.c_codigo_tem'), ''))),
               @ls_emp = RTRIM(LTRIM(ISNULL(JSON_VALUE(@as_json, '$.c_codigo_emp'), ''))),
               @ls_pallet = RTRIM(LTRIM(ISNULL(JSON_VALUE(@as_json, '$.c_codigo_pal'), ''))),
               @ls_nivel = RTRIM(LTRIM(ISNULL(JSON_VALUE(@as_json, '$.c_codigo_niv'), ''))),
               @ls_columna = RTRIM(LTRIM(ISNULL(JSON_VALUE(@as_json, '$.c_codigo_col'), ''))),
               @ls_posicion = RTRIM(LTRIM(ISNULL(JSON_VALUE(@as_json, '$.c_codigo_pos'), ''))),
               @ls_espaciofisico = RTRIM(LTRIM(ISNULL(JSON_VALUE(@as_json, '$.c_codigo_def'), ''))),
               @ls_usuario = RTRIM(LTRIM(ISNULL(JSON_VALUE(@as_json, '$.c_codigo_usu'), ''))),
               @ls_pedido = RTRIM(LTRIM(ISNULL(JSON_VALUE(@as_json, '$.c_codigo_pdo'), '')));

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
        )
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
                      AND ISNULL(pal.c_codigo_niv, '') <> ''
            )
            BEGIN
                SELECT @ls_nivel = pal.c_codigo_niv,
                       @ls_columna = pal.c_columna_col,
                       @ls_posicion = pal.c_codigo_pos
                FROM dbo.t_palet pal
                WHERE pal.c_codigo_tem = @ls_tem
                      AND pal.c_codigo_emp = @ls_emp
                      AND
                      (
                          RTRIM(LTRIM(ISNULL(pal.c_codigo_pal, ''))) = @ls_pallet
                          OR RTRIM(LTRIM(ISNULL(pal.c_codigo_est, ''))) = @ls_pallet
                      );


                SELECT TOP 1
                       @ls_nomnivel = v_descripcion_niv
                FROM dbo.t_ubicacionnivel (NOLOCK)
                WHERE c_codigo_niv = @ls_nivel;
                SELECT TOP 1
                       @ls_nomcolumna = c_nomenclatura_col
                FROM dbo.t_ubicacioncolumna (NOLOCK)
                WHERE c_codigo_col = @ls_columna;
                SELECT TOP 1
                       @ls_nomposicion = c_posicion_pos
                FROM dbo.t_ubicacionposicion (NOLOCK)
                WHERE c_codigo_pos = @ls_posicion;


                SET @as_success = 0;
                SET @as_message
                    = 'El pallet  <strong> ' + @ls_pallet
                      + '</strong> ya tiene asignada la ubicación :<br><br> <strong>Rack: ' + @ls_nomcolumna
                      + '<br><br>Nivel: ' + @ls_nomnivel + +'<br><br>Posición: ' + @ls_nomposicion + '</strong> ';


            END;
            ELSE
            BEGIN



                IF NOT EXISTS
                (
                    SELECT *
                    FROM dbo.t_palet pal (NOLOCK)
                        INNER JOIN dbo.t_producto pro (NOLOCK)
                            ON pro.c_codigo_pro = pal.c_codigo_pro
                    WHERE pal.c_codigo_tem = @ls_tem
                          AND pal.c_codigo_emp = @ls_emp
                          AND
                          (
                              RTRIM(LTRIM(ISNULL(pal.c_codigo_pal, ''))) = @ls_pallet
                              OR RTRIM(LTRIM(ISNULL(pal.c_codigo_est, ''))) = @ls_pallet
                          )
                          AND UPPER(RTRIM(LTRIM(ISNULL(pro.id_pack, '')))) NOT IN
                              (
                                  SELECT UPPER(RTRIM(LTRIM(ISNULL(pre.id_pack, ''))))
                                  FROM dbo.t_distribucion_pedido pre (NOLOCK)
                                  WHERE pre.c_codigo_tem = @ls_tem
                                        AND pre.c_codigo_emp = @ls_emp
                                        AND pre.c_codigo_niv = @ls_nivel
                                        AND pre.c_columna_col = @ls_columna
                                        AND pre.c_codigo_pos = @ls_posicion
                                        AND pre.c_codigo_pdo = @ls_pedido
                              )
							  AND @ls_pedido <> ''
                )
                BEGIN





                    SELECT TOP 1
                           @ls_nomnivel = v_descripcion_niv
                    FROM dbo.t_ubicacionnivel (NOLOCK)
                    WHERE RTRIM(LTRIM(ISNULL(c_codigo_niv, ''))) = @ls_nivel;
                    SELECT TOP 1
                           @ls_nomcolumna = c_nomenclatura_col
                    FROM dbo.t_ubicacioncolumna (NOLOCK)
                    WHERE RTRIM(LTRIM(ISNULL(c_codigo_col, ''))) = @ls_columna;
                    SELECT TOP 1
                           @ls_nomposicion = c_posicion_pos
                    FROM dbo.t_ubicacionposicion (NOLOCK)
                    WHERE RTRIM(LTRIM(ISNULL(c_codigo_pos, ''))) = @ls_posicion;



                    UPDATE dbo.t_palet
                    SET c_codigo_niv = @ls_nivel,
                        c_columna_col = @ls_columna,
                        c_codigo_pos = @ls_posicion,
                        c_codigo_def = @ls_espaciofisico,
                        c_usumod_pal = @ls_usuario,
                        d_modifi_pal = GETDATE()
                    WHERE c_codigo_tem = @ls_tem
                          AND c_codigo_emp = @ls_emp
                          AND
                          (
                              RTRIM(LTRIM(ISNULL(c_codigo_pal, ''))) = @ls_pallet
                              OR RTRIM(LTRIM(ISNULL(c_codigo_est, ''))) = @ls_pallet
                          );



                    SET @as_success = 1;
                    SET @as_message
                        = 'La ubicación:  <br><br><strong>Rack: ' + @ls_nomcolumna + '<br><br>Nivel: ' + @ls_nomnivel
                          + +'<br><br>Posición: ' + @ls_nomposicion
                          + '</strong> <br><br>fue asignada con éxito al pallet:  <strong> ' + @ls_pallet + '</strong>';

                END;
                ELSE
                BEGIN

                    SELECT @ls_presentacionpal
                        = STUFF(
                          (
                              SELECT DISTINCT
                                     ', ' + UPPER(RTRIM(LTRIM(ISNULL(pro.id_pack, ''))))
                              FROM dbo.t_palet pal (NOLOCK)
                                  INNER JOIN dbo.t_producto pro (NOLOCK)
                                      ON pro.c_codigo_pro = pal.c_codigo_pro
                              WHERE pal.c_codigo_tem = @ls_tem
                                    AND pal.c_codigo_emp = @ls_emp
                                    AND
                                    (
                                        RTRIM(LTRIM(ISNULL(pal.c_codigo_pal, ''))) = @ls_pallet
                                        OR RTRIM(LTRIM(ISNULL(pal.c_codigo_est, ''))) = @ls_pallet
                                    )
                                    AND UPPER(RTRIM(LTRIM(ISNULL(pro.id_pack, '')))) NOT IN
                    (
                        SELECT UPPER(RTRIM(LTRIM(ISNULL(pre.id_pack, ''))))
                        FROM dbo.t_distribucion_pedido pre (NOLOCK)
                        WHERE pre.c_codigo_tem = @ls_tem
                              AND pre.c_codigo_emp = @ls_emp
                              AND pre.c_codigo_niv = @ls_nivel
                              AND pre.c_columna_col = @ls_columna
                              AND pre.c_codigo_pos = @ls_posicion
                              AND pre.c_codigo_pdo = @ls_pedido
                    ) FOR XML PATH('')  ), 1,   2,  ''   );


                    SET @as_success = 0;
                    SET @as_message
                        = 'La presentación  <strong>' + @ls_presentacionpal + '</strong> del pallet <strong> '
                          + @ls_pallet + '</strong> es diferente a la de la ubicación donde se quiere posicionar.';


                END;
            END;
        END;
        ELSE
        BEGIN

            SET @as_success = 0;
            SET @as_message
                = 'El pallet <strong>' + @ls_pallet
                  + '</strong> no existe en la temporada activa o el punto de empaque.';


        END;


        COMMIT TRAN;
    END TRY
    BEGIN CATCH
        SET @as_success = 0;
        SET @as_message = ERROR_MESSAGE();
        ROLLBACK TRAN;
    END CATCH;
END;


IF @as_operation = 2 /*Quitar Ubicacion al pallet*/
BEGIN
    BEGIN TRY
        BEGIN TRAN;

        /*SACAMOS LOS DATOS DEL JSON*/
        SELECT @ls_tem = RTRIM(LTRIM(ISNULL(JSON_VALUE(@as_json, '$.c_codigo_tem'), ''))),
               @ls_emp = RTRIM(LTRIM(ISNULL(JSON_VALUE(@as_json, '$.c_codigo_emp'), ''))),
               @ls_pallet = RTRIM(LTRIM(ISNULL(JSON_VALUE(@as_json, '$.c_codigo_pal'), ''))),
               @ls_usuario = RTRIM(LTRIM(ISNULL(JSON_VALUE(@as_json, '$.c_codigo_usu'), '')));


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
        )
        BEGIN


            UPDATE dbo.t_palet
            SET c_codigo_niv = '',
                c_columna_col = '',
                c_codigo_pos = '',
                c_codigo_def = '',
                c_usumod_pal = @ls_usuario,
                d_modifi_pal = GETDATE()
            WHERE c_codigo_tem = @ls_tem
                  AND c_codigo_emp = @ls_emp
                  AND
                  (
                      RTRIM(LTRIM(ISNULL(c_codigo_pal, ''))) = @ls_pallet
                      OR RTRIM(LTRIM(ISNULL(c_codigo_est, ''))) = @ls_pallet
                  )
                  AND ISNULL(c_codigo_pal, '') <> '';



            SET @as_success = 1;
            SET @as_message = 'Pallet: <strong> ' + @ls_pallet + '</strong> Liberado de la ubicación con éxito';


        END;
        ELSE
        BEGIN

            SET @as_success = 0;
            SET @as_message = 'El pallet <strong>' + @ls_pallet + '</strong> no existe en el punto de empaque.';


        END;


        COMMIT TRAN;
    END TRY
    BEGIN CATCH
        SET @as_success = 0;
        SET @as_message = ERROR_MESSAGE();
        ROLLBACK TRAN;
    END CATCH;
END;
