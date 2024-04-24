/*|AGS|*/
IF EXISTS
(
    SELECT *
    FROM dbo.sysobjects
    WHERE id = OBJECT_ID(N'[dbo].[sp_AppControlEstiba]')
)
    DROP PROCEDURE sp_AppControlEstiba;
GO


/*|AGS|*/
CREATE PROCEDURE [dbo].[sp_AppControlEstiba]
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
        @ls_banda VARCHAR(2),
        @ls_equipo VARCHAR(100),
        @ls_equipo_corriendo VARCHAR(100),
        @ls_parm375 VARCHAR(50),
        @ls_estiba VARCHAR(10),
        @ls_programaemp VARCHAR(6),
        @ls_usuario VARCHAR(20),
        @ls_codigo VARCHAR(10),
        @lb_nuevo BIT,
        @ls_codPalFinal VARCHAR(10),
        @ls_aux VARCHAR(10),
        @ls_codSec VARCHAR(10),
        @ls_codigo_pro VARCHAR(4),
        @ls_codigo_eti VARCHAR(2),
        @ls_codigo_col VARCHAR(2),
        @ls_lote VARCHAR(4),
        @ls_envase VARCHAR(2),
        @ls_tam VARCHAR(4),
        @ldc_peso NUMERIC(18, 4),
        @ldc_KilosRec NUMERIC(18, 4),
        @ldc_KilosEmp NUMERIC(18, 4),
        @ldc_bultos NUMERIC(18, 4),
        @ls_terminal VARCHAR(100),
        @ls_empleado VARCHAR(6),
        @ld_fecha DATETIME,
        @ls_hora CHAR(8),
        @ls_cajaescaneada VARCHAR(10),
        @ls_usuarioescaneo VARCHAR(20),
        @ls_folio_caja_conteo VARCHAR(14),
        @ls_anio VARCHAR(2),
        @ls_id VARCHAR(10),
        @ls_new VARCHAR(10),
        @ls_folioini VARCHAR(10),
        @ls_foliofin VARCHAR(10);


SET @as_message = '';
SET @as_success = 0;


IF @as_operation = 1 /*validacion para parar la banda*/
BEGIN
    BEGIN TRY
        /*SACAMOS LOS DATOS DEL JSON*/
        SELECT @ls_tem = RTRIM(LTRIM(ISNULL(JSON_VALUE(@as_json, '$.c_codigo_tem'), ''))),
               @ls_emp = RTRIM(LTRIM(ISNULL(JSON_VALUE(@as_json, '$.c_codigo_emp'), ''))),
               @ls_banda = RTRIM(LTRIM(ISNULL(JSON_VALUE(@as_json, '$.c_codigo_bnd'), ''))),
               @ls_equipo = RTRIM(LTRIM(ISNULL(JSON_VALUE(@as_json, '$.v_pc_bnd'), '')));


        /*Sacamos Manejo de parar banda por equipo*/
        IF EXISTS
        (
            SELECT *
            FROM t_parametro parm375 (NOLOCK)
            WHERE parm375.c_codigo_par = '375'
                  AND RTRIM(LTRIM(ISNULL(parm375.v_valor_par, ''))) = 'S'
        )
        BEGIN
            IF NOT EXISTS /*validamos si esta banda esta corriendo con este quipo*/
            (
                SELECT *
                FROM t_banda (NOLOCK)
                WHERE RTRIM(LTRIM(ISNULL(v_pc_bnd, ''))) = @ls_equipo
                      AND RTRIM(LTRIM(ISNULL(c_codigo_bnd, ''))) = @ls_banda
            )
            BEGIN

                /*Sacamos en donde esta corriendo*/
                SELECT @ls_equipo_corriendo = RTRIM(LTRIM(ISNULL(v_pc_bnd, '')))
                FROM t_banda (NOLOCK)
                WHERE c_codigo_bnd = @ls_banda;

                SET @as_success = 0;
                SET @as_message
                    = 'No puede detener esta banda [' + @ls_banda + ']. Esta banda esta asignada al equipo ['
                      + @ls_equipo_corriendo + ']';
            END;
            ELSE
            BEGIN
                SET @as_success = 1;
                SET @as_message = 'Si existe banda con esa pc';
            END;

        END;
        ELSE
        BEGIN
            SET @as_success = 1;
            SET @as_message = 'OK';
        END;

    END TRY
    BEGIN CATCH
        SET @as_success = 0;
        SET @as_message = ERROR_MESSAGE();

    END CATCH;
END;

IF @as_operation = 2 /*Proceso de Parar la banda*/
BEGIN
    BEGIN TRY
        BEGIN TRAN;
        /*SACAMOS LOS DATOS DEL JSON*/
        SELECT @ls_tem = RTRIM(LTRIM(ISNULL(JSON_VALUE(@as_json, '$.c_codigo_tem'), ''))),
               @ls_emp = RTRIM(LTRIM(ISNULL(JSON_VALUE(@as_json, '$.c_codigo_emp'), ''))),
               @ls_banda = RTRIM(LTRIM(ISNULL(JSON_VALUE(@as_json, '$.c_codigo_bnd'), ''))),
               @ls_estiba = RTRIM(LTRIM(ISNULL(JSON_VALUE(@as_json, '$.c_codigo_sel'), ''))),
               @ls_programaemp = RTRIM(LTRIM(ISNULL(JSON_VALUE(@as_json, '$.c_codigo_prq'), ''))),
               @ls_usuario = RTRIM(LTRIM(ISNULL(JSON_VALUE(@as_json, '$.c_codigo_usu'), '')));


        IF EXISTS
        (
            SELECT *
            FROM dbo.t_programa_empaque prq (NOLOCK)
                INNER JOIN dbo.t_programa_empaquedet prd (NOLOCK)
                    ON prd.c_codigo_prq = prq.c_codigo_prq
                       AND prd.c_codigo_tem = prq.c_codigo_tem
                       AND prd.c_codigo_emp = prq.c_codigo_emp
            WHERE prq.c_corriendo_prq = 'S'
                  AND prd.c_codigo_bnd = @ls_banda
                  AND prq.c_codigo_sel = @ls_estiba
                  AND prd.c_codigo_tem = @ls_tem
                  AND prd.c_codigo_emp = @ls_emp
        )
        BEGIN
            /*Actualizamos las cajas Restantes */
            UPDATE t_seleccion
            SET n_cajasrestantes_sel = 1 /* Se dejan 1 Cajas para poder recibir de esa estiba*/
            WHERE c_codigo_sel = @ls_estiba
                  AND c_codigo_tem = @ls_tem;


            /*Actualizamos las programa de empaque */
            UPDATE t_programa_empaque
            SET c_corriendo_prq = 'N',
                d_fechaFin_prq = GETDATE(),
                c_horaFin_prq = LEFT(CONVERT(VARCHAR, GETDATE(), 14), 8),
                c_usumod_prq = @ls_usuario,
                d_modifi_prq = GETDATE()
            WHERE c_codigo_tem = @ls_tem
                  AND c_codigo_emp = @ls_emp
                  AND c_codigo_prq = @ls_programaemp;



            /* Revisa que la estiba no este corriendo en otra banda.
	      Esto es para poder detenerla completamente. el estado a [D] */
            IF NOT EXISTS
            (
                SELECT *
                FROM dbo.t_programa_empaque prq (NOLOCK)
                    INNER JOIN dbo.t_programa_empaquedet prd (NOLOCK)
                        ON prd.c_codigo_prq = prq.c_codigo_prq
                           AND prd.c_codigo_tem = prq.c_codigo_tem
                           AND prd.c_codigo_emp = prq.c_codigo_emp
                WHERE prq.c_corriendo_prq = 'S'
                      AND prd.c_codigo_bnd <> @ls_banda
                      AND prq.c_codigo_sel = @ls_estiba
                      AND prd.c_codigo_tem = @ls_tem
                      AND prd.c_codigo_emp = @ls_emp
            )
            BEGIN

                UPDATE t_seleccion
                SET c_estado_sel = 'D'
                WHERE c_codigo_tem = @ls_tem
                      AND c_codigo_sel = @ls_estiba;
            END;



            /*SE BORRARAN LOS LOTES,CULTIVO, EL CODIGO PROCESO, EL PROGRAMA DE EMPAQUE  Y EMPLEADO ACTIVO */
            /*LIGADOS ALA TABLA DE LA IMPRESION DE LA ETIQUETA DE ARMADO DE CAJAS*/
            IF EXISTS
            (
                SELECT *
                FROM dbo.t_parametro par332 (NOLOCK)
                WHERE par332.c_codigo_par = '332'
                      AND RTRIM(LTRIM(ISNULL(par332.v_valor_par, ''))) = 'S'
            )
            BEGIN
                UPDATE t_programa_armadocaja
                SET c_codigo_lot = '',
                    c_codigo_cul = '',
                    c_activo_tpa = '0',
                    c_codigo_pdo = '',
                    c_codigo_sel = '',
                    c_codigo_prq = ''
                WHERE c_codigo_tem = @ls_tem
                      AND c_codigo_emp = @ls_emp
                      AND c_codigo_bnd = @ls_banda;


            END;



            SET @as_success = 1;
            SET @as_message
                = 'El Folio de Empaque [' + @ls_programaemp + '] asignado a la banda [' + @ls_banda
                  + '] se ha liberado con exito. Ya se puede asignar otro folio de estiba a esta banda.';
        END;
        ELSE
        BEGIN

            SET @as_success = 0;
            SET @as_message
                = 'El Folio de Empaque [' + @ls_programaemp + '] asignado a la banda [' + @ls_banda
                  + '] No esta Corriendo.';

        END;
        COMMIT TRAN;
    END TRY
    BEGIN CATCH
        SET @as_success = 0;
        SET @as_message = ERROR_MESSAGE();
        ROLLBACK TRAN;
    END CATCH;
END;

IF @as_operation = 3 /*Validacion  folio*/
BEGIN
    BEGIN TRY

        SELECT @ls_tem = RTRIM(LTRIM(ISNULL(JSON_VALUE(@as_json, '$.c_codigo_tem'), ''))),
               @ls_emp = RTRIM(LTRIM(ISNULL(JSON_VALUE(@as_json, '$.c_codigo_emp'), ''))),
               @ls_codigo = RTRIM(LTRIM(ISNULL(JSON_VALUE(@as_json, '$.c_codigo_pme'), ''))),
               @lb_nuevo = RTRIM(LTRIM(ISNULL(JSON_VALUE(@as_json, '$.b_nuevo_pal'), '')));



        /*si no es nuevo*/
        IF @lb_nuevo = 0
        BEGIN
            IF NOT EXISTS
            (
                SELECT *
                FROM t_palet_multiestiba pme (NOLOCK)
                WHERE 1 = 1
                      AND ISNULL(pme.c_codigo_tem, '') LIKE @ls_tem
                      AND ISNULL(pme.c_codigo_emp, '') LIKE @ls_emp
                      AND ISNULL(pme.c_codigo_pme, '') LIKE @ls_codigo
            )
            BEGIN
                SET @as_success = 0;
                SET @as_message
                    = 'El Código de Pallet Ingresado[' + @ls_codigo + '] NO existe como Pallet de Estiba Multiple.';
            END;
            ELSE
            BEGIN
                IF LEFT(@ls_codigo, 3) <> 'VIR'
                BEGIN
                    SET @as_success = 0;
                    SET @as_message
                        = 'El Código de Pallet Ingresado[' + @ls_codigo
                          + '] NO es un Pallet de Estiba Multiple correcto.';
                END;
                ELSE
                BEGIN
                    IF LEN(@ls_codigo) < 10
                    BEGIN
                        SET @ls_codigo = 'VIR' + RIGHT('0000000' + RIGHT(@ls_codigo, (LEN(@ls_codigo) - 3)), 7);
                    END;



                    IF EXISTS
                    (
                        SELECT TOP 1
                               *
                        FROM t_palet_multiestiba pme (NOLOCK)
                        WHERE 1 = 1
                              AND ISNULL(pme.c_codigo_tem, '') LIKE @ls_tem
                              AND ISNULL(pme.c_codigo_emp, '') LIKE @ls_emp
                              AND ISNULL(pme.c_codigo_pme, '') LIKE @ls_codigo
                              AND ISNULL(pme.c_codigo_pal, '') <> ''
                        ORDER BY CAST(ISNULL(pme.c_codsec_pme, '') AS INT) DESC
                    )
                    BEGIN

                        SET @as_success = 0;
                        SET @as_message
                            = 'El Código de Pallet [' + @ls_codigo + '] ya fue confirmado como Pallet final.';
                    END;
                    ELSE
                    BEGIN
                        SET @as_success = 1;
                        SET @as_message = @ls_codigo;

                    END;
                END;
            END;
        END;
        ELSE
        BEGIN

            SELECT @ls_codigo
                = 'VIR'
                  + RIGHT('0000000'
                          + CONVERT(VARCHAR(7), CONVERT(NUMERIC, ISNULL(MAX(SUBSTRING(pme.c_codigo_pme, 4, 7)), 0)) + 1), 7)
            FROM t_palet_multiestiba pme
            WHERE 1 = 1
                  AND ISNULL(pme.c_codigo_tem, '') LIKE @ls_tem
                  AND ISNULL(pme.c_codigo_emp, '') LIKE @ls_emp;
            SET @as_success = 1;
            SET @as_message = @ls_codigo;

        END;


    END TRY
    BEGIN CATCH
        SET @as_success = 0;
        SET @as_message = ERROR_MESSAGE();
    END CATCH;
END;

IF @as_operation = 4 /*Validacion  Precentacion*/
BEGIN
    BEGIN TRY

        SELECT @ls_codigo_pro = RIGHT('0000' + RTRIM(LTRIM(ISNULL(JSON_VALUE(@as_json, '$.c_codigo_pro'), ''))), 4);
        SELECT @ls_codigo_eti = RIGHT('00' + RTRIM(LTRIM(ISNULL(JSON_VALUE(@as_json, '$.c_codigo_eti'), ''))), 2);
        SELECT @ls_codigo_col = RIGHT('00' + RTRIM(LTRIM(ISNULL(JSON_VALUE(@as_json, '$.c_codigo_col'), ''))), 2);

        IF NOT EXISTS
        (
            SELECT *
            FROM dbo.t_producto (NOLOCK)
            WHERE c_codigo_pro = @ls_codigo_pro
                  AND c_activo_pro = '1'
        )
        BEGIN
            SET @as_success = 0;
            SET @as_message
                = 'El código para el producto [' + @ls_codigo_pro + '] NO existe o esta Inactivo en el catálogo.';

        END;
        ELSE
        BEGIN
            IF NOT EXISTS
            (
                SELECT *
                FROM dbo.t_etiqueta (NOLOCK)
                WHERE c_codigo_eti = @ls_codigo_eti
                      AND c_activo_eti = '1'
            )
            BEGIN
                SET @as_success = 0;
                SET @as_message
                    = 'El código para la etiqueta [' + @ls_codigo_eti + '] NO existe o esta Inactivo en el catálogo.';

            END;
            ELSE
            BEGIN
                IF NOT EXISTS
                (
                    SELECT *
                    FROM dbo.t_color (NOLOCK)
                    WHERE c_codigo_col = @ls_codigo_col
                          AND c_activo_col = '1'
                )
                BEGIN
                    SET @as_success = 0;
                    SET @as_message
                        = 'El código para el color [' + @ls_codigo_col + '] NO existe o esta Inactivo en el catálogo.';

                END;
                ELSE
                BEGIN
                    IF EXISTS
                    (
                        SELECT *
                        FROM dbo.t_parametro (NOLOCK)
                        WHERE c_codigo_par = '583'
                              AND RTRIM(LTRIM(ISNULL(v_valor_par, ''))) = 'S'
                    )
                    BEGIN
                        IF NOT EXISTS
                        (
                            SELECT *
                            FROM t_producto_gtin gtin (NOLOCK)
                            WHERE 1 = 1
                                  AND gtin.c_codigo_pro = @ls_codigo_pro
                                  AND gtin.c_codigo_eti = @ls_codigo_eti
                                  AND gtin.c_activo_pgt = '1'
                        )
                        BEGIN
                            SET @as_success = 0;
                            SET @as_message
                                = 'El Código GTIN de la combinación Producto [' + @ls_codigo_pro + '] Etiqueta ['
                                  + @ls_codigo_eti + '] no se encontro registrado en el catálogo de códigos GTIN';

                        END;
                        ELSE
                        BEGIN
                            SET @as_success = 1;
                            SET @as_message = 'ok';
                        END;
                    END;
                    ELSE
                    BEGIN
                        SET @as_success = 1;
                        SET @as_message = 'ok';

                    END;









                END;
            END;
        END;


    END TRY
    BEGIN CATCH
        SET @as_success = 0;
        SET @as_message = ERROR_MESSAGE();
    END CATCH;
END;

IF @as_operation = 5 /*Guardar Pallet Temporal*/
BEGIN
    BEGIN TRY
        BEGIN TRAN;

        /*SACAMOS LOS DATOS DEL JSON*/
        SELECT @ls_tem = RTRIM(LTRIM(ISNULL(JSON_VALUE(@as_json, '$.c_codigo_tem'), ''))),
               @ls_emp = RTRIM(LTRIM(ISNULL(JSON_VALUE(@as_json, '$.c_codigo_emp'), ''))),
               @ls_banda = RTRIM(LTRIM(ISNULL(JSON_VALUE(@as_json, '$.c_codigo_bnd'), ''))),
               @ls_estiba = RTRIM(LTRIM(ISNULL(JSON_VALUE(@as_json, '$.c_codigo_sel'), ''))),
               @ls_lote = RTRIM(LTRIM(ISNULL(JSON_VALUE(@as_json, '$.c_codigo_lot'), ''))),
               @ls_codigo_pro = RTRIM(LTRIM(ISNULL(JSON_VALUE(@as_json, '$.c_codigo_pro'), ''))),
               @ls_codigo_eti = RTRIM(LTRIM(ISNULL(JSON_VALUE(@as_json, '$.c_codigo_eti'), ''))),
               @ls_codigo_col = RTRIM(LTRIM(ISNULL(JSON_VALUE(@as_json, '$.c_codigo_col'), ''))),
               @ldc_bultos = RTRIM(LTRIM(ISNULL(JSON_VALUE(@as_json, '$.n_bulxpa_pal'), ''))),
               @ls_usuario = RTRIM(LTRIM(ISNULL(JSON_VALUE(@as_json, '$.c_codigo_usu'), ''))),
               @ls_codigo = RTRIM(LTRIM(ISNULL(JSON_VALUE(@as_json, '$.c_codigo_pal'), ''))),
               @ls_terminal = RTRIM(LTRIM(ISNULL(JSON_VALUE(@as_json, '$.c_terminal_ccp'), ''))),
               @ldc_KilosRec = RTRIM(LTRIM(ISNULL(JSON_VALUE(@as_json, '$.KilosRec'), ''))),
               @ldc_KilosEmp = RTRIM(LTRIM(ISNULL(JSON_VALUE(@as_json, '$.KilosEmp'), '')));



        IF EXISTS
        (
            SELECT TOP 1
                   *
            FROM t_palet_multiestiba pme (NOLOCK)
            WHERE 1 = 1
                  AND ISNULL(pme.c_codigo_tem, '') LIKE @ls_tem
                  AND ISNULL(pme.c_codigo_emp, '') LIKE @ls_emp
                  AND ISNULL(pme.c_codigo_pme, '') LIKE @ls_codigo
                  AND ISNULL(pme.c_codigo_pal, '') <> ''
            ORDER BY CAST(ISNULL(pme.c_codsec_pme, '') AS INT) DESC
        )
        BEGIN

            SET @as_success = 0;
            SET @as_message = 'El Código de Pallet [' + @ls_codigo + '] ya fue confirmado como Pallet final.';
        END;
        ELSE
        BEGIN


            SELECT @ldc_peso = ISNULL(n_pesbul_pro, 0),
                   @ls_envase = ISNULL(c_codigo_env, ''),
                   @ls_tam = ISNULL(c_codigo_tam, '')
            FROM dbo.t_producto (NOLOCK)
            WHERE c_codigo_pro = @ls_codigo_pro;

            SET @ldc_peso = @ldc_peso * @ldc_bultos;

            /*Sacamos el folio de secuencia siguiente*/
            SELECT TOP 1
                   @ls_codSec
                       = RIGHT('00'
                               + CONVERT(VARCHAR(2), CONVERT(NUMERIC, RTRIM(LTRIM(ISNULL(pme.c_codsec_pme, '')))) + 1), 2)
            FROM t_palet_multiestiba pme (NOLOCK)
            WHERE 1 = 1
                  AND ISNULL(pme.c_codigo_tem, '') LIKE @ls_tem
                  AND ISNULL(pme.c_codigo_emp, '') LIKE @ls_emp
                  AND ISNULL(pme.c_codigo_pme, '') LIKE @ls_codigo
            ORDER BY CAST(ISNULL(pme.c_codsec_pme, '') AS INT) DESC;


            IF RTRIM(LTRIM(ISNULL(@ls_codSec, ''))) = ''
            BEGIN
                SET @ls_codSec = '01';
            END;

            SET @ldc_KilosEmp = +ISNULL(@ldc_KilosEmp, 0) + ISNULL(@ldc_peso, 0);

            IF ISNULL(@ldc_KilosRec, 0) < ISNULL(@ldc_KilosEmp, 0)
            BEGIN

                SET @as_success = 0;
                SET @as_message = 'Los kilos empacados ['+ISNULL(@ldc_KilosEmp, 0)+'] sobrepasan los kilos recibos ['++ISNULL(@ldc_KilosRec, 0)+'] de la estiba al generar el pallet virtual.';
            END;
            ELSE
            BEGIN



                INSERT INTO t_palet_multiestiba
                (
                    c_codigo_tem,
                    c_codigo_emp,
                    c_codigo_pme,
                    c_codigo_pal,
                    c_codsec_pme,
                    d_empaque_pme,
                    c_hora_pme,
                    c_tipo_pme,
                    c_codigo_sel,
                    c_codigo_bnd,
                    c_codigo_lot,
                    c_codigo_pro,
                    c_codigo_eti,
                    c_codigo_col,
                    c_codigo_env,
                    c_codigo_tam,
                    n_peso_pme,
                    n_bulxpa_pme,
                    c_codigo_usu,
                    d_creacion_pme,
                    c_usumod_pme,
                    d_modifi_pme,
                    c_activo_pme,
                    c_terminal_pme
                )
                VALUES
                (@ls_tem, @ls_emp, @ls_codigo, '', @ls_codSec, GETDATE(), LEFT(CONVERT(VARCHAR, GETDATE(), 14), 8),
                 'M', @ls_estiba, @ls_banda, @ls_lote, @ls_codigo_pro, @ls_codigo_eti, @ls_codigo_col, @ls_envase,
                 @ls_tam, @ldc_peso, @ldc_bultos, @ls_usuario, GETDATE(), NULL, NULL, '0', @ls_terminal);


                /*cargar datos del  conteo de cajas de esa terminal  en caso de que exista*/
                SET @ls_anio = RIGHT(DATEPART(YEAR, GETDATE()), 2);
                SET @ls_id =
                (
                    SELECT ISNULL(MAX(RIGHT(c_idcaja_cnt, 10)), '')
                    FROM t_palet_multiestiba_conteo
                    WHERE c_codigo_tem = @ls_tem
                          AND LEFT(LTRIM(RTRIM(ISNULL(c_idcaja_cnt, ''))), 2) = @ls_anio
                );

                IF LTRIM(RTRIM(ISNULL(@ls_id, ''))) = ''
                    SET @ls_folio_caja_conteo
                        = LTRIM(RTRIM(ISNULL(@ls_anio, ''))) + LTRIM(RTRIM(ISNULL(@ls_emp, ''))) + '0000000001';
                ELSE
                BEGIN
                    SET @ls_new = CONVERT(CHAR(10), (CONVERT(INT, ISNULL(@ls_id, '')) + 1));
                    SET @ls_new = RIGHT('0000000000' + LTRIM(RTRIM(ISNULL(@ls_new, ''))), 10);
                    SET @ls_folio_caja_conteo
                        = LTRIM(RTRIM(ISNULL(@ls_anio, '') + ISNULL(@ls_emp, '') + ISNULL(@ls_new, '')));
                END;




                IF CURSOR_STATUS('global', 'CURSOR_CAJAS') >= -1
                BEGIN
                    DEALLOCATE CURSOR_CAJAS;
                END;

                DECLARE CURSOR_CAJAS CURSOR GLOBAL FOR
                SELECT c_empleado_ccp,
                       d_fecha_ccp,
                       c_hrconteo_ccp,
                       c_idcaja_ccp,
                       c_codigo_usu
                FROM t_conteocajas_app_temp (NOLOCK)
                WHERE RTRIM(LTRIM(ISNULL(c_codigo_emp, ''))) = @ls_emp
                      AND RTRIM(LTRIM(ISNULL(c_terminal_ccp, ''))) = @ls_terminal
                      AND RTRIM(LTRIM(ISNULL(c_idcaja_cnt, ''))) = '';


                OPEN CURSOR_CAJAS;
                FETCH NEXT FROM CURSOR_CAJAS
                INTO @ls_empleado,
                     @ld_fecha,
                     @ls_hora,
                     @ls_cajaescaneada,
                     @ls_usuarioescaneo;
                WHILE (@@fetch_status = 0)
                BEGIN

                    INSERT INTO dbo.t_palet_multiestiba_conteo
                    (
                        c_codigo_tem,
                        c_codigo_emp,
                        c_codigo_pme,
                        c_codsec_pme,
                        c_empleado_cnt,
                        c_idcaja_cnt,
                        d_conteo_cnt,
                        c_hrconteo_cnt,
                        n_bulxpa_cnt,
                        c_idcajascaneo_cnt,
                        c_terminal_cnt,
                        c_codigo_usu,
                        d_creacion_cnt,
                        c_usumod_cnt,
                        d_modifi_cnt,
                        c_activo_cnt
                    )
                    VALUES
                    (@ls_tem, @ls_emp, @ls_codigo, @ls_codSec, @ls_empleado, @ls_folio_caja_conteo, @ld_fecha,
                     @ls_hora, 1, @ls_cajaescaneada, @ls_terminal, @ls_usuarioescaneo, GETDATE(), NULL, NULL, '1');

                    /*Actualizamos la caja como  uasada*/
                    UPDATE t_conteocajas_app_temp
                    SET c_idcaja_cnt = @ls_folio_caja_conteo
                    WHERE RTRIM(LTRIM(ISNULL(c_codigo_emp, ''))) = @ls_emp
                          AND RTRIM(LTRIM(ISNULL(c_terminal_ccp, ''))) = @ls_terminal
                          AND RTRIM(LTRIM(ISNULL(c_idcaja_ccp, ''))) = @ls_cajaescaneada;

                    SET @ls_id = RIGHT('0000000000' + LTRIM(RTRIM(ISNULL(@ls_folio_caja_conteo, ''))), 10);
                    SET @ls_new = CONVERT(CHAR(10), (CONVERT(INT, ISNULL(@ls_id, '')) + 1));
                    SET @ls_new = RIGHT('0000000000' + LTRIM(RTRIM(ISNULL(@ls_new, ''))), 10);
                    SET @ls_folio_caja_conteo
                        = LTRIM(RTRIM(ISNULL(@ls_anio, '') + ISNULL(@ls_emp, '') + ISNULL(@ls_new, '')));

                    FETCH NEXT FROM CURSOR_CAJAS
                    INTO @ls_empleado,
                         @ld_fecha,
                         @ls_hora,
                         @ls_cajaescaneada,
                         @ls_usuarioescaneo;

                END;
                CLOSE CURSOR_CAJAS;
                DEALLOCATE CURSOR_CAJAS;


                SET @as_success = 1;
                SET @as_message
                    = 'Se genero el Pallet virtual correctamente.<br/><br/>Folio : <strong> ' + @ls_codigo
                      + ' </strong><br/><br/>Secuencia : <strong> ' + @ls_codSec + ' </strong>';

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

IF @as_operation = 6 /*Guardar conteo de cajas temporales*/
BEGIN
    BEGIN TRY
        BEGIN TRAN;

        /*SACAMOS LOS DATOS DEL JSON*/
        SELECT @ls_tem = RTRIM(LTRIM(ISNULL(JSON_VALUE(@as_json, '$.c_codigo_tem'), ''))),
               @ls_emp = RTRIM(LTRIM(ISNULL(JSON_VALUE(@as_json, '$.c_codigo_emp'), ''))),
               @ls_terminal = RTRIM(LTRIM(ISNULL(JSON_VALUE(@as_json, '$.c_terminal_ccp'), ''))),
               @ls_codigo = RIGHT('0000000000' + RTRIM(LTRIM(ISNULL(JSON_VALUE(@as_json, '$.c_idcaja_ccp'), ''))), 10),
               @ldc_bultos = RTRIM(LTRIM(ISNULL(JSON_VALUE(@as_json, '$.n_bulxpa_ccp'), ''))),
               @ls_usuario = RTRIM(LTRIM(ISNULL(JSON_VALUE(@as_json, '$.c_codigo_usu'), '')));



        SELECT TOP 1
               @ls_empleado = c_empleado_emt
        FROM t_empleado_controltirajefolios (NOLOCK)
        WHERE c_codigo_tem = @ls_tem
              AND RTRIM(LTRIM(ISNULL(c_codigo_emp, ''))) = @ls_emp
              AND @ls_codigo
              BETWEEN RTRIM(LTRIM(ISNULL(c_folioinicial_emt, ''))) AND RTRIM(LTRIM(ISNULL(c_foliofinal_emt, '')))
              AND c_activo_emt = '1';


        IF RTRIM(LTRIM(ISNULL(@ls_empleado, ''))) = ''
        BEGIN

            SET @as_success = 0;
            SET @as_message
                = 'El ID <strong> ' + @ls_codigo
                  + ' </strong> de caja escaneado NO esta ligado con un numero de empleado para su conteo.';

        END;
        ELSE
        BEGIN

            SELECT @ls_equipo = RTRIM(LTRIM(ISNULL(c_terminal_ccp, '')))
            FROM t_conteocajas_app_temp (NOLOCK)
            WHERE RTRIM(LTRIM(ISNULL(c_codigo_emp, ''))) = @ls_emp
                  AND RTRIM(LTRIM(ISNULL(c_idcaja_ccp, ''))) LIKE @ls_codigo;


            IF RTRIM(LTRIM(ISNULL(@ls_equipo, ''))) <> ''
            BEGIN

                SET @as_success = 0;
                IF RTRIM(LTRIM(ISNULL(@ls_equipo, ''))) = RTRIM(LTRIM(ISNULL(@ls_terminal, '')))
                BEGIN
                    SET @as_message = 'El ID  <strong> ' + @ls_codigo + ' </strong> de caja ya fue escaneado.';
                END;
                ELSE
                BEGIN

                    SET @as_message
                        = 'El ID  <strong> ' + @ls_codigo
                          + ' </strong> de caja ya fue escaneado por la Terminar : <strong> ' + @ls_equipo
                          + ' </strong>';
                END;


            END;
            ELSE
            BEGIN


                INSERT INTO dbo.t_conteocajas_app_temp
                (
                    c_terminal_ccp,
                    c_codigo_emp,
                    c_idcaja_ccp,
                    c_empleado_ccp,
                    d_fecha_ccp,
                    c_hrconteo_ccp,
                    n_bulxpa_ccp,
                    c_idcaja_cnt,
                    c_codigo_usu
                )
                VALUES
                (@ls_terminal, @ls_emp, @ls_codigo, @ls_empleado, GETDATE(), LEFT(CONVERT(VARCHAR, GETDATE(), 14), 8),
                 @ldc_bultos, '', @ls_usuario);

                SET @as_success = 1;
                SET @as_message = 'El ID de caja escaneado :<strong> ' + @ls_codigo + '</strong>  Correctamente';

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

IF @as_operation = 7 /*ELIMINAR conteo de cajas temporales*/
BEGIN
    BEGIN TRY
        BEGIN TRAN;

        /*SACAMOS LOS DATOS DEL JSON*/
        SELECT @ls_emp = RTRIM(LTRIM(ISNULL(JSON_VALUE(@as_json, '$.c_codigo_emp'), ''))),
               @ls_terminal = RTRIM(LTRIM(ISNULL(JSON_VALUE(@as_json, '$.c_terminal_ccp'), ''))),
               @ls_codigo = RTRIM(LTRIM(ISNULL(JSON_VALUE(@as_json, '$.c_idcaja_ccp'), '')));

        IF @ls_codigo <> '%%'
        BEGIN
            SET @ls_codigo = RIGHT('0000000000' + RTRIM(LTRIM(ISNULL(@ls_codigo, ''))), 10);
        END;


        DELETE FROM t_conteocajas_app_temp
        WHERE RTRIM(LTRIM(ISNULL(c_terminal_ccp, ''))) = @ls_terminal
              AND RTRIM(LTRIM(ISNULL(c_codigo_emp, ''))) = @ls_emp
              AND RTRIM(LTRIM(ISNULL(c_idcaja_ccp, ''))) LIKE @ls_codigo
              AND RTRIM(LTRIM(ISNULL(c_idcaja_cnt, ''))) = '';




        SET @as_success = 1;
        SET @as_message = 'Cajas Eliminadas Correctamente';


        COMMIT TRAN;
    END TRY
    BEGIN CATCH
        SET @as_success = 0;
        SET @as_message = ERROR_MESSAGE();
        ROLLBACK TRAN;
    END CATCH;
END;

IF @as_operation = 8 /*ELIMINAR PALLET TEMPORA*/
BEGIN
    BEGIN TRY
        BEGIN TRAN;

        /*SACAMOS LOS DATOS DEL JSON*/
        SELECT @ls_tem = RTRIM(LTRIM(ISNULL(JSON_VALUE(@as_json, '$.c_codigo_tem'), ''))),
               @ls_emp = RTRIM(LTRIM(ISNULL(JSON_VALUE(@as_json, '$.c_codigo_emp'), ''))),
               @ls_terminal = RTRIM(LTRIM(ISNULL(JSON_VALUE(@as_json, '$.c_terminal_ccp'), ''))),
               @ls_codigo = RTRIM(LTRIM(ISNULL(JSON_VALUE(@as_json, '$.c_codigo'), ''))),
               @ls_codSec = RTRIM(LTRIM(ISNULL(JSON_VALUE(@as_json, '$.c_codsec_pal'), '')));

        IF EXISTS
        (
            SELECT TOP 1
                   *
            FROM t_palet_multiestiba pme (NOLOCK)
            WHERE 1 = 1
                  AND ISNULL(pme.c_codigo_tem, '') LIKE @ls_tem
                  AND ISNULL(pme.c_codigo_emp, '') LIKE @ls_emp
                  AND ISNULL(pme.c_codigo_pme, '') LIKE @ls_codigo
                  AND ISNULL(pme.c_codigo_pal, '') <> ''
            ORDER BY CAST(ISNULL(pme.c_codsec_pme, '') AS INT) DESC
        )
        BEGIN

            SET @as_success = 0;
            SET @as_message = 'El Código de Pallet [' + @ls_codigo + '] ya fue confirmado como Pallet final.';
        END;
        ELSE
        BEGIN


            DELETE dbo.t_palet_multiestiba
            WHERE c_codigo_tem = @ls_tem
                  AND c_codigo_emp = @ls_emp
                  AND c_codigo_pme = @ls_codigo
                  AND c_codsec_pme = @ls_codSec;

            /*Actulizamos cajas temporales*/
            DELETE dbo.t_conteocajas_app_temp
            WHERE RTRIM(LTRIM(ISNULL(c_terminal_ccp, ''))) + RTRIM(LTRIM(ISNULL(c_codigo_emp, '')))
                  + RTRIM(LTRIM(ISNULL(c_idcaja_ccp, '')))IN
                  (
                      SELECT RTRIM(LTRIM(ISNULL(temp.c_terminal_ccp, '')))
                             + RTRIM(LTRIM(ISNULL(temp.c_codigo_emp, '')))
                             + RTRIM(LTRIM(ISNULL(temp.c_idcaja_ccp, '')))
                      FROM dbo.t_conteocajas_app_temp temp
                          INNER JOIN dbo.t_palet_multiestiba_conteo cj
                              ON cj.c_codigo_emp = temp.c_codigo_emp
                                 AND cj.c_idcaja_cnt = temp.c_idcaja_cnt
                      WHERE cj.c_codigo_tem = @ls_tem
                            AND cj.c_codigo_emp = @ls_emp
                            AND cj.c_codigo_pme = @ls_codigo
                            AND cj.c_codsec_pme = @ls_codSec
                  );


            DELETE dbo.t_palet_multiestiba_conteo
            WHERE c_codigo_tem = @ls_tem
                  AND c_codigo_emp = @ls_emp
                  AND c_codigo_pme = @ls_codigo
                  AND c_codsec_pme = @ls_codSec;


            SET @as_success = 1;
            SET @as_message = 'Pallet Temporal Eliminado Correctamente';

        END;
        COMMIT TRAN;
    END TRY
    BEGIN CATCH
        SET @as_success = 0;
        SET @as_message = ERROR_MESSAGE();
        ROLLBACK TRAN;
    END CATCH;
END;

IF @as_operation = 9 /*Asignar Tiraje a empleado*/
BEGIN
    BEGIN TRY
        BEGIN TRAN;

        /*SACAMOS LOS DATOS DEL JSON*/
        SELECT @ls_tem = RTRIM(LTRIM(ISNULL(JSON_VALUE(@as_json, '$.c_codigo_tem'), ''))),
               @ls_emp = RTRIM(LTRIM(ISNULL(JSON_VALUE(@as_json, '$.c_codigo_emp'), ''))),
               @ls_empleado = RTRIM(LTRIM(ISNULL(JSON_VALUE(@as_json, '$.c_empleado_cte'), ''))),
               @ls_folioini = RTRIM(LTRIM(ISNULL(JSON_VALUE(@as_json, '$.c_folioinicial_cte'), ''))),
               @ls_foliofin = RTRIM(LTRIM(ISNULL(JSON_VALUE(@as_json, '$.c_foliofinal_cte'), ''))),
               @ls_usuario = RTRIM(LTRIM(ISNULL(JSON_VALUE(@as_json, '$.c_codigo_usu'), '')));


        IF EXISTS
        (
            SELECT *
            FROM t_empleado_controltirajefolios (NOLOCK)
            WHERE RTRIM(LTRIM(ISNULL(c_codigo_tem, ''))) = @ls_tem
                  AND RTRIM(LTRIM(ISNULL(c_codigo_emp, ''))) = @ls_emp
                  AND @ls_folioini
                  BETWEEN c_folioinicial_emt AND c_foliofinal_emt
        )
        BEGIN

            UPDATE t_empleado_controltirajefolios
            SET c_empleado_emt = @ls_empleado,
                d_modifi_emt = GETDATE(),
                c_usumod_emt = @ls_usuario
            WHERE RTRIM(LTRIM(ISNULL(c_codigo_tem, ''))) = @ls_tem
                  AND RTRIM(LTRIM(ISNULL(c_codigo_emp, ''))) = @ls_emp
                  AND @ls_folioini
                  BETWEEN c_folioinicial_emt AND c_foliofinal_emt;

            SET @as_message
                = 'Tiraje de Etiquetas Reasignado al empleado  <strong> ' + @ls_empleado + '</strong>  Correctamente';

        END;
        ELSE
        BEGIN


            INSERT INTO t_empleado_controltirajefolios
            (
                c_codigo_tem,
                c_codigo_emp,
                c_folioinicial_emt,
                c_foliofinal_emt,
                c_empleado_emt,
                d_fecha_emt,
                c_codigo_usu,
                d_creacion_emt,
                c_usumod_emt,
                d_modifi_emt,
                c_activo_emt
            )
            VALUES
            (@ls_tem, @ls_emp, @ls_folioini, @ls_foliofin, @ls_empleado, GETDATE(), @ls_usuario, GETDATE(), NULL, NULL,
             '1');
            SET @as_message
                = 'Tiraje de Etiquetas Asignado al empleado  <strong> ' + @ls_empleado + '</strong>  Correctamente';

        END;


        SET @as_success = 1;



        COMMIT TRAN;
    END TRY
    BEGIN CATCH
        SET @as_success = 0;
        SET @as_message = ERROR_MESSAGE();
        ROLLBACK TRAN;
    END CATCH;
END;


IF @as_operation = 10 /*CONFIRMAMOS PALLET TEMPORA*/
BEGIN
    BEGIN TRY
        BEGIN TRAN;

        /*SACAMOS LOS DATOS DEL JSON*/
        SELECT @ls_tem = RTRIM(LTRIM(ISNULL(JSON_VALUE(@as_json, '$.c_codigo_tem'), ''))),
               @ls_emp = RTRIM(LTRIM(ISNULL(JSON_VALUE(@as_json, '$.c_codigo_emp'), ''))),
               @ls_terminal = RTRIM(LTRIM(ISNULL(JSON_VALUE(@as_json, '$.c_terminal_ccp'), ''))),
               @ls_codigo = RTRIM(LTRIM(ISNULL(JSON_VALUE(@as_json, '$.c_codigo'), ''))),
               @ls_codSec = RTRIM(LTRIM(ISNULL(JSON_VALUE(@as_json, '$.c_codsec_pal'), '')));


        IF EXISTS
        (
            SELECT TOP 1
                   *
            FROM t_palet_multiestiba pme (NOLOCK)
            WHERE 1 = 1
                  AND ISNULL(pme.c_codigo_tem, '') LIKE @ls_tem
                  AND ISNULL(pme.c_codigo_emp, '') LIKE @ls_emp
                  AND ISNULL(pme.c_codigo_pme, '') LIKE @ls_codigo
                  AND ISNULL(pme.c_codigo_pal, '') <> ''
            ORDER BY CAST(ISNULL(pme.c_codsec_pme, '') AS INT) DESC
        )
        BEGIN

            SET @as_success = 0;
            SET @as_message = 'El Código de Pallet [' + @ls_codigo + '] ya fue confirmado como Pallet final.';
        END;
        ELSE
        BEGIN


            UPDATE dbo.t_palet_multiestiba
            SET c_activo_pme = '1'
            WHERE c_codigo_tem = @ls_tem
                  AND c_codigo_emp = @ls_emp
                  AND c_codigo_pme = @ls_codigo;

            SET @as_success = 1;
            SET @as_message = 'Pallet Temporal Confirmado Correctamente';
        END;

        COMMIT TRAN;
    END TRY
    BEGIN CATCH
        SET @as_success = 0;
        SET @as_message = ERROR_MESSAGE();
        ROLLBACK TRAN;
    END CATCH;
END;

