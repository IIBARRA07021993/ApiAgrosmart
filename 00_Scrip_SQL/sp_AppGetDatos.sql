
/*|AGS|*/
IF EXISTS
(
    SELECT *
    FROM dbo.sysobjects
    WHERE id = OBJECT_ID(N'[dbo].[sp_AppGetDatos]')
)
    DROP PROCEDURE sp_AppGetDatos;
GO


/*|AGS|*/
CREATE	 PROCEDURE [dbo].[sp_AppGetDatos]
(
    @as_operation INT,
    @as_json VARCHAR(MAX),
    @as_success INT OUTPUT,
    @as_message VARCHAR(1024) OUTPUT
)
AS
SET NOCOUNT ON;

DECLARE @xml XML,
        @ls_tipo VARCHAR(2),
        @ls_pedido VARCHAR(16),
        @ls_temporada VARCHAR(2),
        @ls_puntoemp VARCHAR(2),
        @ls_presentacion VARCHAR(8),
        @ls_conse VARCHAR(3),
        @ls_rec VARCHAR(10),
        @ls_are VARCHAR(4),
        @ls_parm VARCHAR(3),
        @ls_sis VARCHAR(2),
        @ls_pallet VARCHAR(10),
        @ls_codigo VARCHAR(10),
        @codsec VARCHAR(2),
        @ls_terminal VARCHAR(100),
        @ls_codsel VARCHAR(10),
        @ls_banda VARCHAR(2),
        @ls_maduracion VARCHAR(4),
        @ls_man VARCHAR(10),
        @ls_temp VARCHAR(1),
        @ls_mercado VARCHAR(1),
        @ls_vaciado VARCHAR(15),
        @ls_activos VARCHAR(1),
        @ls_tarima VARCHAR(6),
        @tipo CHAR(1),
        @ls_codqr VARCHAR(22),
		@ls_empaque2 VARCHAR(2),
		@ls_usuario VARCHAR(20);

SET @as_message = '';
SET @as_success = 0;


SELECT @xml = dbo.fn_parse_json2xml(@as_json);

IF @as_operation = 1 /*consultar áreas fisicas para cargar en Dropdown*/
BEGIN
    BEGIN TRY
        /*SACAMOS LOS DATOS DEL AREA DEL JSON*/
        SELECT @ls_tipo = RTRIM(LTRIM(ISNULL(n.el.value('c_tipo_are[1]', 'varchar(2)'), '')))
        FROM @xml.nodes('/') n(el);




        SELECT c_codigo_are = RTRIM(LTRIM(ISNULL(c_codigo_are, ''))),
               v_nombre_are = RTRIM(LTRIM(ISNULL(v_nombre_are, '')))
        FROM t_areafisica (NOLOCK)
        WHERE c_activo_are = '1'
              AND c_tipo_are LIKE @ls_tipo;

        SET @as_success = 1;
        SET @as_message = 'OK';
    END TRY
    BEGIN CATCH
        SET @as_success = 0;
        SET @as_message = ERROR_MESSAGE();
    END CATCH;
END;

IF @as_operation = 2 /*consultar tipo de caja o tarima para cargar en Dropdown*/
BEGIN
    BEGIN TRY
        /*SACAMOS LOS DATOS DEl tipo de caja DEL JSON*/
        SELECT @ls_tipo = RTRIM(LTRIM(ISNULL(n.el.value('c_tipo_tcj[1]', 'varchar(2)'), '')))
        FROM @xml.nodes('/') n(el);

        SELECT c_codigo_tcj = RTRIM(LTRIM(ISNULL(c_codigo_tcj, ''))),
               v_nombre_tcj = RTRIM(LTRIM(ISNULL(v_nombre_tcj, '')))
        FROM t_tipocaja (NOLOCK)
        WHERE c_activo_tcj = '1'
              AND c_tipo_tcj LIKE @ls_tipo
              AND c_defaulcajpro_tcj = 'S';

        SET @as_success = 1;
        SET @as_message = 'OK';
    END TRY
    BEGIN CATCH
        SET @as_success = 0;
        SET @as_message = ERROR_MESSAGE();
    END CATCH;
END;

IF @as_operation = 3 /*Consulta de pedidos general*/
BEGIN
    BEGIN TRY
        /*SACAMOS LOS DATOS DEL JSON*/
        SELECT @ls_temporada = RTRIM(LTRIM(ISNULL(n.el.value('c_codigo_tem[1]', 'varchar(2)'), ''))),
               @ls_puntoemp = RTRIM(LTRIM(ISNULL(n.el.value('c_codigo_emp[1]', 'varchar(2)'), '')))
        FROM @xml.nodes('/') n(el);


        SELECT c_codigo_pdo = ped.c_codigo_pdo,
               c_codigo_tem = det.c_codigo_tem,
               v_nombre_tem = tem.v_nombre_tem,
               c_codigo_emp = det.c_codigo_emp,
               v_nombre_pem = emp.v_nombre_pem,
               c_codigo_dis = dis.c_codigo_dis,
               v_nombre_dis = dis.v_nombre_dis,
               d_fecha_pdo = ped.d_fechaSalida_pdo,
               c_estatus_pdo = ped.c_estatus_pdo,
               d_fechaSalida_pdo = ped.d_fechaSalida_pdo,
               v_observaciones_pdo = ped.v_observaciones_pdo,
               n_cajaspedidas_pdd = SUM(det.n_cajaspedidas_pdd),
               n_cajasempacadas_pdd = SUM(det.n_cajasempacadas_pdd),
               n_palets_pdd = SUM(tb_pallets_emp.n_pallets_emp)
        FROM dbo.t_pedido ped (NOLOCK)
            INNER JOIN dbo.t_pedidodet det (NOLOCK)
                ON det.c_codigo_tem = ped.c_codigo_tem
                   AND det.c_codigo_emp = ped.c_codigo_emp
                   AND det.c_codigo_pdo = ped.c_codigo_pdo
            INNER JOIN dbo.t_temporada tem (NOLOCK)
                ON tem.c_codigo_tem = det.c_codigo_tem
            INNER JOIN dbo.t_puntoempaque emp (NOLOCK)
                ON emp.c_codigo_pem = ped.c_codigo_emp
            LEFT JOIN dbo.t_distribuidor dis (NOLOCK)
                ON dis.c_codigo_dis = ped.c_codigo_dis
            LEFT JOIN
            (
                SELECT pal.c_codigo_tem,
                       pal.c_codigo_emp,
                       pal.c_codigo_pdo,
                       n_pallets_emp = COUNT(DISTINCT CASE
                                                          WHEN ISNULL(pal.c_codigo_est, '') = '' THEN
                                                              pal.c_codigo_pal
                                                          ELSE
                                                              pal.c_codigo_est
                                                      END
                                            )
                FROM dbo.t_palet pal (NOLOCK)
                WHERE ISNULL(pal.c_codigo_pdo, '') <> ''
                GROUP BY pal.c_codigo_tem,
                         pal.c_codigo_emp,
                         pal.c_codigo_pdo
            ) tb_pallets_emp
                ON tb_pallets_emp.c_codigo_tem = ped.c_codigo_tem
                   AND tb_pallets_emp.c_codigo_emp = ped.c_codigo_emp
                   AND tb_pallets_emp.c_codigo_pdo = ped.c_codigo_pdo
        WHERE ped.c_codigo_tem = @ls_temporada
              AND ped.c_codigo_emp = @ls_puntoemp
        GROUP BY ped.c_codigo_pdo,
                 det.c_codigo_tem,
                 det.c_codigo_emp,
                 emp.v_nombre_pem,
                 dis.c_codigo_dis,
                 dis.v_nombre_dis,
                 tem.v_nombre_tem,
                 ped.d_fechaSalida_pdo,
                 ped.c_estatus_pdo,
                 ped.d_fechaSalida_pdo,
                 ped.v_observaciones_pdo;

        SET @as_success = 1;
        SET @as_message = 'OK';
    END TRY
    BEGIN CATCH
        SET @as_success = 0;
        SET @as_message = ERROR_MESSAGE();
    END CATCH;
END;

IF @as_operation = 4 /*Consulta de detalles de un pedido */
BEGIN
    BEGIN TRY
        /*SACAMOS LOS DATOS DEL JSON*/
        SELECT @ls_pedido = RTRIM(LTRIM(ISNULL(n.el.value('c_codigo_pdo[1]', 'varchar(16)'), ''))),
               @ls_temporada = RTRIM(LTRIM(ISNULL(n.el.value('c_codigo_tem[1]', 'varchar(2)'), ''))),
               @ls_puntoemp = RTRIM(LTRIM(ISNULL(n.el.value('c_codigo_emp[1]', 'varchar(2)'), '')))
        FROM @xml.nodes('/') n(el);

        SELECT c_codigo_pdo = ped.c_codigo_pdo,
               c_codigo_tem = ped.c_codigo_tem,
               v_nombre_tem = tem.v_nombre_tem,
               c_codigo_emp = ped.c_codigo_emp,
               v_nombre_pem = emp.v_nombre_pem,
               c_codigo_dis = dis.c_codigo_dis,
               v_nombre_dis = dis.v_nombre_dis,
               d_fecha_pdo = ped.d_fecha_pdo,
               c_estatus_pdo = ped.c_estatus_pdo,
               d_fechaSalida_pdo = ped.d_fechaSalida_pdo,
               v_observaciones_pdo = ped.v_observaciones_pdo,
               c_codigo_pro = det.c_codigo_pro,
               v_nombre_pro = pro.v_nombre_pro,
               c_codigo_eti = det.c_codigo_eti,
               v_nombre_eti = eti.v_nombre_eti,
               c_codigo_col = det.c_codigo_col,
               v_nombre_col = col.v_nombre_col,
               n_cajaspedidas_pdd = SUM(ISNULL(det.n_cajaspedidas_pdd, 0)),
               n_cajasempacadas_pdd = SUM(ISNULL(det.n_cajasempacadas_pdd, 0)),
               n_palets_pdd = SUM(ISNULL(det.n_palets_pdd, 0)),
               n_pallets_emp = SUM(ISNULL(tb_pallets_emp.n_pallets_emp, 0))
        FROM dbo.t_pedido ped (NOLOCK)
            INNER JOIN dbo.t_pedidodet det (NOLOCK)
                ON det.c_codigo_tem = ped.c_codigo_tem
                   AND det.c_codigo_emp = ped.c_codigo_emp
                   AND det.c_codigo_pdo = ped.c_codigo_pdo
            INNER JOIN dbo.t_temporada tem (NOLOCK)
                ON tem.c_codigo_tem = det.c_codigo_tem
            INNER JOIN dbo.t_puntoempaque emp (NOLOCK)
                ON emp.c_codigo_pem = ped.c_codigo_emp
            LEFT JOIN dbo.t_distribuidor dis (NOLOCK)
                ON dis.c_codigo_dis = ped.c_codigo_dis
            LEFT JOIN dbo.t_producto pro (NOLOCK)
                ON pro.c_codigo_pro = det.c_codigo_pro
            LEFT JOIN dbo.t_etiqueta eti (NOLOCK)
                ON eti.c_codigo_eti = det.c_codigo_eti
            LEFT JOIN dbo.t_color col (NOLOCK)
                ON col.c_codigo_col = det.c_codigo_col
            LEFT JOIN
            (
                SELECT pal.c_codigo_tem,
                       pal.c_codigo_emp,
                       pal.c_codigo_pdo,
                       pal.c_codigo_pro,
                       pal.c_codigo_eti,
                       pal.c_codigo_col,
                       n_pallets_emp = COUNT(DISTINCT CASE
                                                          WHEN ISNULL(pal.c_codigo_est, '') = '' THEN
                                                              pal.c_codigo_pal
                                                          ELSE
                                                              pal.c_codigo_est
                                                      END
                                            )
                FROM dbo.t_palet pal (NOLOCK)
                WHERE ISNULL(pal.c_codigo_pdo, '') <> ''
                GROUP BY pal.c_codigo_tem,
                         pal.c_codigo_emp,
                         pal.c_codigo_pdo,
                         pal.c_codigo_pro,
                         pal.c_codigo_eti,
                         pal.c_codigo_col
            ) tb_pallets_emp
                ON tb_pallets_emp.c_codigo_tem = ped.c_codigo_tem
                   AND tb_pallets_emp.c_codigo_emp = ped.c_codigo_emp
                   AND tb_pallets_emp.c_codigo_pdo = ped.c_codigo_pdo
                   AND tb_pallets_emp.c_codigo_pro = pro.c_codigo_pro
                   AND tb_pallets_emp.c_codigo_eti = eti.c_codigo_eti
                   AND tb_pallets_emp.c_codigo_col = col.c_codigo_col
        WHERE ped.c_codigo_pdo = @ls_pedido
              AND ped.c_codigo_emp = @ls_puntoemp
              AND tem.c_codigo_tem = @ls_temporada
			  AND ISNULL(det.n_cajaspedidas_pdd,0) > 0
        GROUP BY ped.c_codigo_pdo,
                 ped.c_codigo_tem,
                 ped.c_codigo_emp,
                 emp.v_nombre_pem,
                 dis.c_codigo_dis,
                 dis.v_nombre_dis,
                 tem.v_nombre_tem,
                 ped.d_fecha_pdo,
                 ped.c_estatus_pdo,
                 ped.d_fechaSalida_pdo,
                 ped.v_observaciones_pdo,
                 det.c_codigo_pro,
                 det.c_codigo_eti,
                 det.c_codigo_col,
                 col.v_nombre_col,
                 eti.v_nombre_eti,
                 pro.v_nombre_pro;

        SET @as_success = 1;
        SET @as_message = 'OK';
    END TRY
    BEGIN CATCH
        SET @as_success = 0;
        SET @as_message = ERROR_MESSAGE();
    END CATCH;
END;

IF @as_operation = 5 /*Consulta de pallet ligado a un detalle del pedido */
BEGIN
    BEGIN TRY
        /*SACAMOS LOS DATOS DEL JSON*/
        SELECT @ls_pedido = RTRIM(LTRIM(ISNULL(n.el.value('c_codigo_pdo[1]', 'varchar(16)'), ''))),
               @ls_temporada = RTRIM(LTRIM(ISNULL(n.el.value('c_codigo_tem[1]', 'varchar(2)'), ''))),
               @ls_puntoemp = RTRIM(LTRIM(ISNULL(n.el.value('c_codigo_emp[1]', 'varchar(2)'), ''))),
               @ls_presentacion = RTRIM(LTRIM(ISNULL(n.el.value('c_codigo_pre[1]', 'varchar(8)'), '')))
        FROM @xml.nodes('/') n(el);

        SELECT c_codigo_tem = pal.c_codigo_tem,
               c_codigo_emp = pal.c_codigo_emp,
               c_codigo_pdo = pal.c_codigo_pdo,
               c_codigo_pal = CASE
                                  WHEN ISNULL(pal.c_codigo_est, '') = '' THEN
                                      pal.c_codigo_pal
                                  ELSE
                                      pal.c_codigo_est
                              END,
               c_codigo_pro = pal.c_codigo_pro,
               v_nombre_pro = pro.v_nombre_pro,
               c_codigo_eti = pal.c_codigo_eti,
               v_nombre_eti = eti.v_nombre_eti,
               c_codigo_col = pal.c_codigo_col,
               v_nombre_col = col.v_nombre_col,
               n_bulxpa_pal = SUM(pal.n_bulxpa_pal),
               n_peso_pal = SUM(   CASE
                                       WHEN ISNULL(pal.n_peso_pal, 0) = 0 THEN
                                           pal.n_bulxpa_pal * pro.n_pesbul_pro
                                       ELSE
                                           pal.n_peso_pal
                                   END
                               ),
               c_codigo_pos = LTRIM(RTRIM(ISNULL(pal.c_codigo_pos, '')))
        FROM t_palet pal (NOLOCK)
            INNER JOIN dbo.t_producto pro (NOLOCK)
                ON pro.c_codigo_pro = pal.c_codigo_pro
            INNER JOIN dbo.t_etiqueta eti (NOLOCK)
                ON eti.c_codigo_eti = pal.c_codigo_eti
            INNER JOIN dbo.t_color col (NOLOCK)
                ON col.c_codigo_col = pal.c_codigo_col
        WHERE pal.c_codigo_tem = @ls_temporada
              AND pal.c_codigo_emp = @ls_puntoemp
              AND ISNULL(pal.c_codigo_pdo, '') = @ls_pedido
              AND RTRIM(LTRIM(ISNULL(pal.c_codigo_pro, ''))) + RTRIM(LTRIM(ISNULL(pal.c_codigo_eti, '')))
                  + RTRIM(LTRIM(ISNULL(pal.c_codigo_col, ''))) = @ls_presentacion
        GROUP BY pal.c_codigo_tem,
                 pal.c_codigo_emp,
                 pal.c_codigo_pdo,
                 pal.c_codigo_pro,
                 pro.v_nombre_pro,
                 pal.c_codigo_eti,
                 eti.v_nombre_eti,
                 pal.c_codigo_col,
                 col.v_nombre_col,
                 CASE
                     WHEN ISNULL(pal.c_codigo_est, '') = '' THEN
                         pal.c_codigo_pal
                     ELSE
                         pal.c_codigo_est
                 END,
                 LTRIM(RTRIM(ISNULL(pal.c_codigo_pos, '')));


        SET @as_success = 1;
        SET @as_message = 'OK';
    END TRY
    BEGIN CATCH
        SET @as_success = 0;
        SET @as_message = ERROR_MESSAGE();
    END CATCH;
END;

IF @as_operation = 6 /*OBTENER LISTADO DE PALLETS*/
BEGIN
    BEGIN TRY
        /*SACAMOS LOS DATOS del sorteo DEL JSON*/
        SELECT @ls_are = RTRIM(LTRIM(ISNULL(n.el.value('c_codigo_are[1]', 'varchar(4)'), ''))),
               @ls_puntoemp = RTRIM(LTRIM(ISNULL(n.el.value('c_codigo_emp[1]', 'varchar(2)'), ''))),
               @ls_temporada = RTRIM(LTRIM(ISNULL(n.el.value('c_codigo_tem[1]', 'varchar(2)'), ''))),
               @tipo = RTRIM(LTRIM(ISNULL(n.el.value('c_tipo[1]', 'varchar(1)'), '')))
        FROM @xml.nodes('/') n(el);

        SELECT DISTINCT
               c_codigo_rec = CASE
                                  WHEN ISNULL(det.c_codigo_pal, '') <> '' THEN
                                      ''
                                  ELSE
                                      det.c_codigo_rec
                              END,
               c_concecutivo_dso = CASE
                                       WHEN ISNULL(det.c_codigo_pal, '') <> '' THEN
                                           ''
                                       ELSE
                                           det.c_concecutivo_smd
                                   END,
               c_codigo_lot = det.c_codigo_lot,
               n_kilos_dso = det.n_kilos_smd,
               n_cajas_dso = det.n_cajas_smd,
               c_codigo_pal = ISNULL(det.c_codigo_pal, ''),
               c_folio_sma = det.c_folio_sma,
               v_dueno = rec.c_codigo_dno + ' - ' + due.v_nombre_dno,
               bloque = lot.v_nombre_lot + ' / ' + lot.c_codigo_lot + '-' + det.c_codigo_tem,
               c_lote = lot.c_codigo_lot,
               idrazon = sma.idrazon
        FROM t_sortingmaduraciondet det (NOLOCK)
            LEFT JOIN dbo.t_sortingmaduracion sma
                ON sma.c_folio_sma = det.c_folio_sma
                   AND sma.c_codigo_tem = det.c_codigo_tem
                   AND det.c_codigo_emp = sma.c_codigo_emp
            LEFT JOIN dbo.t_recepciondet rec (NOLOCK)
                ON rec.c_codigo_rec = det.c_codigo_rec
                   AND rec.c_secuencia_red = det.c_concecutivo_smd
                   AND rec.c_codigo_tem = det.c_codigo_tem
            LEFT JOIN dbo.t_duenio due (NOLOCK)
                ON due.c_codigo_dno = rec.c_codigo_dno
            LEFT JOIN dbo.t_lote lot (NOLOCK)
                ON lot.c_codigo_lot = rec.c_codigo_lot
                   AND lot.c_codigo_tem = rec.c_codigo_tem
        WHERE c_codigo_are = @ls_are
              AND c_finvaciado_smd = 'N'
              AND c_activo_smd = '1'
              AND det.c_codigo_emp = @ls_puntoemp
              AND det.c_codigo_tem = @ls_temporada
              AND
              (
                  'P' <> @tipo
                  AND 'T' <> @tipo
              )
        UNION ALL
        SELECT DISTINCT
               c_codigo_rec = CASE
                                  WHEN ISNULL(det.c_codigo_pal, '') <> '' THEN
                                      ''
                                  ELSE
                                      det.c_codigo_rec
                              END,
               c_concecutivo_dso = CASE
                                       WHEN ISNULL(det.c_codigo_pal, '') <> '' THEN
                                           ''
                                       ELSE
                                           det.c_concecutivo_smd
                                   END,
               c_codigo_lot = det.c_codigo_lot,
               n_kilos_dso = det.n_kilos_smd,
               n_cajas_dso = det.n_cajas_smd,
               c_codigo_pal = ISNULL(det.c_codigo_pal, ''),
               c_folio_sma = det.c_folio_sma,
               v_dueno = hue.c_codigo_dno + ' - ' + due.v_nombre_dno,
               bloque = lot.v_nombre_lot + ' / ' + lot.c_codigo_lot + '-' + det.c_codigo_tem,
               c_lote = lot.c_codigo_lot,
               idrazon = sma.idrazon
        FROM t_sortingmaduraciondet det (NOLOCK)
            LEFT JOIN dbo.t_sortingmaduracion sma
                ON sma.c_folio_sma = det.c_folio_sma
                   AND sma.c_codigo_tem = det.c_codigo_tem
                   AND det.c_codigo_emp = sma.c_codigo_emp
            LEFT JOIN dbo.t_paletemporal pte (NOLOCK)
                ON det.c_codigo_pal = pte.c_codigo_pte
                   AND pte.c_codigo_tem = det.c_codigo_tem
                   AND pte.c_codigo_emp = det.c_codigo_emp
            LEFT JOIN dbo.t_lote lot (NOLOCK)
                ON lot.c_codigo_lot = det.c_codigo_lot
                   AND lot.c_codigo_tem = pte.c_codigo_tem
            LEFT JOIN dbo.t_huerto hue (NOLOCK)
                ON hue.c_codigo_hue = lot.c_codigo_hue
            LEFT JOIN dbo.t_duenio due (NOLOCK)
                ON due.c_codigo_dno = hue.c_codigo_dno
        WHERE det.c_codigo_are = @ls_are
              AND c_finvaciado_smd = 'N'
              AND c_activo_smd = '1'
              AND det.c_codigo_emp = @ls_puntoemp
              AND det.c_codigo_tem = @ls_temporada
              AND 'P' = @tipo
        UNION ALL
        SELECT DISTINCT
               c_codigo_rec = CASE
                                  WHEN ISNULL(det.c_codigo_pal, '') <> '' THEN
                                      ''
                                  ELSE
                                      det.c_codigo_rec
                              END,
               c_concecutivo_dso = CASE
                                       WHEN ISNULL(det.c_codigo_pal, '') <> '' THEN
                                           ''
                                       ELSE
                                           det.c_concecutivo_smd
                                   END,
               c_codigo_lot = det.c_codigo_lot,
               n_kilos_dso = det.n_kilos_smd,
               n_cajas_dso = det.n_cajas_smd,
               c_codigo_pal = ISNULL(det.c_codigo_pal, ''),
               c_folio_sma = det.c_folio_sma,
               v_dueno = hue.c_codigo_dno + ' - ' + due.v_nombre_dno,
               bloque = lot.v_nombre_lot + ' / ' + lot.c_codigo_lot + '-' + det.c_codigo_tem,
               c_lote = lot.c_codigo_lot,
               idrazon = sma.idrazon
        FROM dbo.t_palet pal (NOLOCK)
            LEFT JOIN dbo.t_sortingmaduraciondet det (NOLOCK)
                ON pal.c_codigo_pal = det.c_codigo_pal
                   AND det.c_codigo_tem = pal.c_codigo_tem
            LEFT JOIN dbo.t_sortingmaduracion sma (NOLOCK)
                ON sma.c_folio_sma = det.c_folio_sma
                   AND sma.c_codigo_tem = det.c_codigo_tem
                   AND det.c_codigo_emp = sma.c_codigo_emp
            LEFT JOIN dbo.t_paletemporal pte (NOLOCK)
                ON det.c_codigo_pal = pte.c_codigo_pte
                   AND pte.c_codigo_tem = det.c_codigo_tem
                   AND pte.c_codigo_emp = det.c_codigo_emp
            LEFT JOIN dbo.t_lote lot (NOLOCK)
                ON lot.c_codigo_lot = pal.c_codigo_lot
                   AND lot.c_codigo_tem = pal.c_codigo_tem
            LEFT JOIN dbo.t_huerto hue (NOLOCK)
                ON hue.c_codigo_hue = lot.c_codigo_hue
            LEFT JOIN dbo.t_duenio due (NOLOCK)
                ON due.c_codigo_dno = hue.c_codigo_dno
        WHERE det.c_codigo_are = @ls_are
              AND c_finvaciado_smd = 'N'
              AND c_activo_smd = '1'
              AND det.c_codigo_emp = @ls_puntoemp
              AND det.c_codigo_tem = @ls_temporada
              AND 'T' = @tipo;

        SET @as_success = 1;
        SET @as_message = 'OK';
    END TRY
    BEGIN CATCH
        SET @as_success = 0;
        SET @as_message = ERROR_MESSAGE();
    END CATCH;
END;

IF @as_operation = 7 /*CONSULTA DE PARAMETROS*/
BEGIN
    BEGIN TRY
        /*SACAMOS LOS DATOS  DEL JSON*/
        SELECT @ls_parm = RTRIM(LTRIM(ISNULL(n.el.value('c_codigo_par[1]', 'varchar(3)'), ''))),
               @ls_sis = RTRIM(LTRIM(ISNULL(n.el.value('c_codigo_sis[1]', 'varchar(2)'), '')))
        FROM @xml.nodes('/') n(el);


        IF @ls_sis = '02' /*eyeplus*/
        BEGIN
            SELECT c_codigo_par,
                   v_nombre_par,
                   v_valor_par
            FROM dbo.t_parametro (NOLOCK)
            WHERE c_codigo_par LIKE @ls_parm;
        END;


        SET @as_success = 1;
        SET @as_message = 'OK';
    END TRY
    BEGIN CATCH
        SET @as_success = 0;
        SET @as_message = ERROR_MESSAGE();
    END CATCH;
END;

IF @as_operation = 8 /*CONSULTA DE temporada*/
BEGIN
    BEGIN TRY
        /*SACAMOS LOS DATOS  DEL JSON*/
        SELECT @ls_temporada = RTRIM(LTRIM(ISNULL(n.el.value('c_codigo_tem[1]', 'varchar(2)'), ''))),
               @ls_tipo = RTRIM(LTRIM(ISNULL(n.el.value('c_activo_tem[1]', 'varchar(2)'), '')))
        FROM @xml.nodes('/') n(el);

        SELECT c_codigo_tem,
               v_nombre_tem,
               d_inicio_tem,
               d_fin_tem
        FROM dbo.t_temporada (NOLOCK)
        WHERE c_codigo_tem LIKE @ls_temporada
              AND c_activo_tem LIKE @ls_tipo;


        SET @as_success = 1;
        SET @as_message = 'OK';
    END TRY
    BEGIN CATCH
        SET @as_success = 0;
        SET @as_message = ERROR_MESSAGE();
    END CATCH;
END;

IF @as_operation = 9 /*CONSULTA DE punto de empaque*/
BEGIN
    BEGIN TRY
        /*SACAMOS LOS DATOS  DEL JSON*/
        SELECT @ls_puntoemp = RTRIM(LTRIM(ISNULL(n.el.value('c_codigo_pem[1]', 'varchar(2)'), '')))
        FROM @xml.nodes('/') n(el);


        SELECT c_codigo_pem,
               v_nombre_pem,
               v_codigoaux_pem
        FROM dbo.t_puntoempaque (NOLOCK)
        WHERE c_codigo_pem LIKE @ls_puntoemp;
        SET @as_success = 1;
        SET @as_message = 'OK';
    END TRY
    BEGIN CATCH
        SET @as_success = 0;
        SET @as_message = ERROR_MESSAGE();
    END CATCH;
END;

IF @as_operation = 10 /*Consulta de Programa de Empaque*/
BEGIN
    BEGIN TRY
        /*SACAMOS LOS DATOS  DEL JSON*/
        SELECT @ls_temporada = RTRIM(LTRIM(ISNULL(n.el.value('c_codigo_tem[1]', 'varchar(2)'), ''))),
               @ls_puntoemp = RTRIM(LTRIM(ISNULL(n.el.value('c_codigo_emp[1]', 'varchar(2)'), '')))
        FROM @xml.nodes('/') n(el);


        SELECT c_codigo_bnd = ISNULL(bnd.c_codigo_bnd, ''),
               v_nombre_bnd = ISNULL(bnd.v_nombre_bnd, ''),
               c_codigo_cul = ISNULL(prog.c_codigo_cul, ''),
               v_nombre_cul = ISNULL(prog.v_nombre_cul, ''),
               c_codigo_lot = ISNULL(prog.c_codigo_lot, ''),
               v_nombre_lot = ISNULL(prog.v_nombre_lot, ''),
               n_superf_lot = ISNULL(prog.n_superf_lot, 0.0000),
               c_codigo_sel = ISNULL(prog.c_codigo_sel, ''),
               c_codigo_prq = ISNULL(prog.c_codigo_prq, ''),
               c_horaFin_prq = REPLACE(prog.c_horaFin_prq, ':', ''),
               c_horaIni_prq = REPLACE(prog.c_horaIni_prq, ':', ''),
               d_fechaIni_prq = ISNULL(prog.d_fechaIni_prq, GETDATE()),
               d_fechaFin_prq = prog.d_fechaFin_prq,
               c_corriendo_prq = ISNULL(prog.c_corriendo_prq, 'N'),
               KilosRec = ISNULL(tRec.KilosRec, 0),
               KilosEmp = ISNULL(tEmp.KilosEmp_Real, 0),
               d_fecha_sel = prog.d_fecha_sel
        FROM
        (
            SELECT bnd.c_codigo_bnd,
                   prq.c_codigo_emp,
                   lot.c_codigo_lot,
                   prq.c_codigo_prq,
                   sel.c_codigo_sel,
                   prq.c_codigo_tem,
                   c_corriendo_prq,
                   c_horaFin_prq,
                   c_horaIni_prq,
                   d_fechaFin_prq,
                   d_fechaIni_prq,
                   v_nombre_lot,
                   n_superf_lot = ISNULL(lot.n_superf_lot, 0.0000),
                   v_nombre_bnd,
                   cul.c_codigo_cul,
                   v_nombre_cul,
                   sel.d_fecha_sel
            FROM t_programa_empaquedet prqd (NOLOCK)
                INNER JOIN t_tolva tlv (NOLOCK)
                    ON prqd.c_codigo_tlv = tlv.c_codigo_tlv
                       AND prqd.c_codigo_bnd = tlv.c_codigo_bnd
                       AND tlv.c_activo_tlv = '1'
                INNER JOIN t_banda bnd (NOLOCK)
                    ON tlv.c_codigo_bnd = bnd.c_codigo_bnd
                INNER JOIN t_programa_empaque prq (NOLOCK)
                    ON prqd.c_codigo_emp = prq.c_codigo_emp
                       AND prqd.c_codigo_tem = prq.c_codigo_tem
                       AND prq.c_codigo_prq = prqd.c_codigo_prq
                INNER JOIN t_seleccion sel (NOLOCK)
                    ON prq.c_codigo_tem = sel.c_codigo_tem
                       AND sel.c_codigo_sel = prq.c_codigo_sel
                INNER JOIN t_lote lot (NOLOCK)
                    ON sel.c_codigo_tem = lot.c_codigo_tem
                       AND sel.c_codigo_lot = lot.c_codigo_lot
                INNER JOIN t_cultivo cul (NOLOCK)
                    ON lot.c_codigo_cul = cul.c_codigo_cul
            WHERE 1 = 1
                  AND prq.c_corriendo_prq = 'S'
                  AND prq.c_codigo_tem = @ls_temporada
                  AND prq.c_codigo_emp = @ls_puntoemp
            GROUP BY bnd.c_codigo_bnd,
                     prq.c_codigo_emp,
                     lot.c_codigo_lot,
                     prq.c_codigo_prq,
                     sel.c_codigo_sel,
                     prq.c_codigo_tem,
                     c_corriendo_prq,
                     c_horaFin_prq,
                     c_horaIni_prq,
                     d_fechaFin_prq,
                     d_fechaIni_prq,
                     v_nombre_lot,
                     lot.n_superf_lot,
                     v_nombre_bnd,
                     cul.c_codigo_cul,
                     cul.v_nombre_cul,
                     sel.d_fecha_sel
        ) prog
            INNER JOIN t_banda bnd (NOLOCK)
                ON prog.c_codigo_bnd = bnd.c_codigo_bnd
            LEFT JOIN
            (
                SELECT c_codigo_sel = prq.c_codigo_sel,
                       c_codigo_lot = sel.c_codigo_lot,
                       KilosRec = SUM(red.n_kilos_red)
                FROM t_programa_empaque prq (NOLOCK)
                    INNER JOIN t_seleccion sel (NOLOCK)
                        ON prq.c_codigo_tem = sel.c_codigo_tem
                           AND sel.c_codigo_sel = prq.c_codigo_sel
                    INNER JOIN t_recepciondet red (NOLOCK)
                        ON red.c_codigo_tem = sel.c_codigo_tem
                           AND red.c_codigo_sel = sel.c_codigo_sel
                           AND red.c_codigo_lot = sel.c_codigo_lot
                WHERE 1 = 1
                      AND prq.c_corriendo_prq = 'S'
                      AND prq.c_codigo_tem = @ls_temporada
                      AND prq.c_codigo_emp = @ls_puntoemp
                GROUP BY prq.c_codigo_sel,
                         sel.c_codigo_lot
            ) tRec
                ON tRec.c_codigo_sel = prog.c_codigo_sel
                   AND tRec.c_codigo_lot = prog.c_codigo_lot
            LEFT JOIN
            (
                SELECT c_codigo_sel = tEmp0.c_codigo_sel,
                       c_codigo_lot = tEmp0.c_codigo_lot,
                       KilosEmp_STD = SUM(ISNULL(tEmp0.KilosEmp_STD, 0.00)),
                       KilosEmp_Real = SUM(ISNULL(tEmp0.KilosEmp_Real, 0.00))
                FROM
                (
                    SELECT c_codigo_sel = prq.c_codigo_sel,
                           c_codigo_lot = sel.c_codigo_lot,
                           KilosEmp_STD = SUM(ISNULL(pal.n_bulxpa_pal, 0) * ISNULL(pro.n_pesbul_pro, 0)),
                           KilosEmp_Real = CASE
                                               WHEN ISNULL(cul.c_pesoreal_cul, 'N') = 'S' THEN
                                                   SUM(ISNULL(pal.n_peso_pal, 0))
                                               ELSE
                                                   SUM(ISNULL(pal.n_bulxpa_pal, 0) * ISNULL(pro.n_pesbul_pro, 0))
                                           END
                    FROM t_programa_empaque prq (NOLOCK)
                        INNER JOIN t_seleccion sel (NOLOCK)
                            ON prq.c_codigo_tem = sel.c_codigo_tem
                               AND sel.c_codigo_sel = prq.c_codigo_sel
                        LEFT JOIN t_palet pal (NOLOCK)
                            ON pal.c_codigo_emp = prq.c_codigo_emp
                               AND pal.c_codigo_sel = prq.c_codigo_sel
                               AND pal.c_codigo_lot = sel.c_codigo_lot
                        LEFT JOIN t_producto pro (NOLOCK)
                            ON pro.c_codigo_pro = pal.c_codigo_pro
                        LEFT JOIN t_cultivo cul (NOLOCK)
                            ON cul.c_codigo_cul = pro.c_codigo_cul
                    WHERE 1 = 1
                          AND prq.c_corriendo_prq = 'S'
                          AND prq.c_codigo_tem = @ls_temporada
                          AND prq.c_codigo_emp = @ls_puntoemp
                    GROUP BY cul.c_pesoreal_cul,
                             prq.c_codigo_sel,
                             sel.c_codigo_lot
                    UNION ALL
                    SELECT c_codigo_sel = prq.c_codigo_sel,
                           c_codigo_lot = sel.c_codigo_lot,
                           KilosEmp_STD = SUM(ISNULL(pal.n_bulxpa_pme, 0) * ISNULL(pro.n_pesbul_pro, 0)),
                           KilosEmp_Real = SUM(ISNULL(pal.n_bulxpa_pme, 0) * ISNULL(pro.n_pesbul_pro, 0))
                    FROM t_programa_empaque prq (NOLOCK)
                        INNER JOIN t_seleccion sel (NOLOCK)
                            ON prq.c_codigo_tem = sel.c_codigo_tem
                               AND sel.c_codigo_sel = prq.c_codigo_sel
                        LEFT JOIN t_palet_multiestiba pal (NOLOCK)
                            ON pal.c_codigo_emp = prq.c_codigo_emp
                               AND pal.c_codigo_sel = prq.c_codigo_sel
                               AND pal.c_codigo_lot = sel.c_codigo_lot
                               AND ISNULL(pal.c_codigo_pal, '') = ''
                        LEFT JOIN t_producto pro (NOLOCK)
                            ON pro.c_codigo_pro = pal.c_codigo_pro
                        LEFT JOIN t_cultivo cul (NOLOCK)
                            ON cul.c_codigo_cul = pro.c_codigo_cul
                    WHERE 1 = 1
                          AND prq.c_corriendo_prq = 'S'
                          AND prq.c_codigo_tem = @ls_temporada
                          AND prq.c_codigo_emp = @ls_puntoemp
                    GROUP BY cul.c_pesoreal_cul,
                             prq.c_codigo_sel,
                             sel.c_codigo_lot
                ) tEmp0
                GROUP BY tEmp0.c_codigo_sel,
                         tEmp0.c_codigo_lot
            ) tEmp
                ON tEmp.c_codigo_sel = prog.c_codigo_sel
                   AND tEmp.c_codigo_lot = prog.c_codigo_lot
        WHERE 1 = 1
              AND bnd.c_activo_bnd = '1'
        ORDER BY prog.d_fecha_sel DESC;



        SET @as_success = 1;
        SET @as_message = 'OK';
    END TRY
    BEGIN CATCH
        SET @as_success = 0;
        SET @as_message = ERROR_MESSAGE();
    END CATCH;
END;

IF @as_operation = 11 /*consultar grado de maduracion para cargar en Dropdown*/
BEGIN
    BEGIN TRY
        SELECT c_codigo_gdm = RTRIM(LTRIM(ISNULL(c_codigo_gdm, ''))),
               v_nombre_gdm = RTRIM(LTRIM(ISNULL(v_nombre_gdm, '')))
        FROM t_gradomaduracion (NOLOCK)
        WHERE c_activo_gmd = '1';

        SET @as_success = 1;
        SET @as_message = 'OK';
    END TRY
    BEGIN CATCH
        SET @as_success = 0;
        SET @as_message = ERROR_MESSAGE();
    END CATCH;
END;

IF @as_operation = 12 /*Maximo de palets temporales*/
BEGIN
    BEGIN TRY
        SELECT c_codigo_pal = RIGHT('0000000000'
                                    + CONVERT(VARCHAR(10), CONVERT(NUMERIC, ISNULL(MAX(c_codigo_pte), '')) + 1), 10)
        FROM t_paletemporal;
        SET @as_success = 1;
        SET @as_message = 'OK';
    END TRY
    BEGIN CATCH
        SET @as_success = 0;
        SET @as_message = ERROR_MESSAGE();
    END CATCH;
END;

IF @as_operation = 13 /*tipo sorteo*/
BEGIN
    BEGIN TRY

        SELECT @ls_codqr = RTRIM(LTRIM(ISNULL(n.el.value('c_codigo[1]', 'varchar(22)'), ''))),
               @ls_temporada = RTRIM(LTRIM(ISNULL(n.el.value('c_codigo_tem[1]', 'varchar(2)'), '')))
        FROM @xml.nodes('/') n(el);

        IF EXISTS /*tipo recepcion secuencia */
        (
            SELECT 1
            FROM t_recepciondet (NOLOCK)
            WHERE c_codigo_rec + c_secuencia_red = @ls_codqr
                  AND c_codigo_tem = @ls_temporada
        )
        BEGIN
            SELECT c_tipo = 'R';
            SET @as_success = 1;
            SET @as_message = 'El codigo ingresado es de tipo R:(Recepcion).';
            RETURN;
        END;
        IF EXISTS /*tipo palet temporal*/
        (
            SELECT 1
            FROM dbo.t_paletemporal (NOLOCK)
            WHERE (
                      c_codqrtemp_pte = @ls_codqr
                      OR c_codigo_pte = @ls_codqr
                  )
                  AND c_codigo_tem = @ls_temporada
        )
        BEGIN
            SELECT c_tipo = 'P';
            SET @as_success = 1;
            SET @as_message = 'El codigo ingresado es de tipo P:(pallet temporal).';
            RETURN;
        END;
        IF EXISTS /*tipo palet externo*/
        (
            SELECT 1
            FROM t_recepciondet (NOLOCK)
            WHERE c_codexterno_rec = @ls_codqr
                  AND c_codigo_tem = @ls_temporada
        )
        BEGIN
            SELECT c_tipo = 'E';
            SET @as_success = 1;
            SET @as_message = 'La recepcion ingresada es de tipo E.';
            RETURN;
        END;
        IF EXISTS /*tipo palet externo*/
        (
            SELECT 1
            FROM dbo.t_palet (NOLOCK)
            WHERE c_codigo_pal = @ls_codqr
                  AND c_codigo_tem = @ls_temporada
        )
        BEGIN
            SELECT c_tipo = 'T';
            SET @as_success = 1;
            SET @as_message = 'La recepcion ingresada es de tipo T.';
            RETURN;
        END;
        /*no existe */
        SELECT c_tipo = 'X';
        SET @as_success = 0;
        SET @as_message = 'La recepcion ingresada no existe .';
        RETURN;
    END TRY
    BEGIN CATCH
        SET @as_success = 0;
        SET @as_message = ERROR_MESSAGE();
    END CATCH;
END;


IF @as_operation = 14 /*Consulta de catalogo de Productos*/
BEGIN
    BEGIN TRY

        SELECT @ls_codigo = RTRIM(LTRIM(ISNULL(n.el.value('c_codigo_pro[1]', 'varchar(10)'), '')))
        FROM @xml.nodes('/') n(el);

        SELECT c_codigo_pro,
               v_nombre_pro,
               v_nomext_pro,
               c_merdes_pro,
               c_codigo_cul,
               c_codigo_env = pro.c_codigo_env,
               c_codigo_tam = pro.c_codigo_tam,
               n_pesuni_pro,
               n_pesbul_pro,
               n_bulxpa_pro,
               id_commodity,
               id_style,
               id_size,
               id_product,
               c_porkilo_pro,
               c_codigo_prc,
               v_codext_pro,
               id_variety,
               id_pack,
               v_nombre_env = RTRIM(LTRIM(ISNULL(enva.v_nombre_env, ''))),
               v_nombre_tam = RTRIM(LTRIM(ISNULL(tam.v_nombre_tam, '')))
        FROM dbo.t_producto pro (NOLOCK)
            INNER JOIN dbo.t_tamanio tam (NOLOCK)
                ON tam.c_codigo_tam = pro.c_codigo_tam
            INNER JOIN dbo.t_envase enva (NOLOCK)
                ON enva.c_codigo_env = pro.c_codigo_env
        WHERE c_activo_pro = '1'
              AND c_codigo_pro LIKE @ls_codigo;

        SET @as_success = 1;
        SET @as_message = 'OK';
    END TRY
    BEGIN CATCH
        SET @as_success = 0;
        SET @as_message = ERROR_MESSAGE();
    END CATCH;
END;


IF @as_operation = 15 /*Consulta de catalogo de etiquetas*/
BEGIN
    BEGIN TRY
        SELECT @ls_codigo = RTRIM(LTRIM(ISNULL(n.el.value('c_codigo_eti[1]', 'varchar(10)'), '')))
        FROM @xml.nodes('/') n(el);

        SELECT c_codigo_eti,
               v_nombre_eti,
               v_imagen_eti,
               c_codigoalt_eti,
               v_nombreingles_eti,
               c_clave_eti,
               v_abreviatura_eti,
               c_texper_eti,
               v_marca_eti
        FROM dbo.t_etiqueta (NOLOCK)
        WHERE c_activo_eti = '1'
              AND c_codigo_eti LIKE @ls_codigo;

        SET @as_success = 1;
        SET @as_message = 'OK';
    END TRY
    BEGIN CATCH
        SET @as_success = 0;
        SET @as_message = ERROR_MESSAGE();
    END CATCH;
END;


IF @as_operation = 16 /*Consulta de catalogo de color*/
BEGIN
    BEGIN TRY

        SELECT @ls_codigo = RTRIM(LTRIM(ISNULL(n.el.value('c_codigo_col[1]', 'varchar(10)'), '')))
        FROM @xml.nodes('/') n(el);

        SELECT c_codigo_col,
               v_nombre_col,
               c_codigoalt_col,
               c_colorcomer_col
        FROM dbo.t_color (NOLOCK)
        WHERE c_activo_col = '1'
              AND c_codigo_col LIKE @ls_codigo;

        SET @as_success = 1;
        SET @as_message = 'OK';
    END TRY
    BEGIN CATCH
        SET @as_success = 0;
        SET @as_message = ERROR_MESSAGE();
    END CATCH;
END;


IF @as_operation = 17 /*Consulta de palet virtuales*/
BEGIN
    BEGIN TRY

        SELECT @ls_temporada = RTRIM(LTRIM(ISNULL(n.el.value('c_codigo_tem[1]', 'varchar(2)'), ''))),
               @ls_puntoemp = RTRIM(LTRIM(ISNULL(n.el.value('c_codigo_emp[1]', 'varchar(2)'), ''))),
               @ls_codigo = RTRIM(LTRIM(ISNULL(n.el.value('c_codigo_pal[1]', 'varchar(10)'), ''))),
               @codsec = RTRIM(LTRIM(ISNULL(n.el.value('c_codsec_pal[1]', 'varchar(2)'), ''))),
               @ls_tipo = RTRIM(LTRIM(ISNULL(n.el.value('c_tipo[1]', 'varchar(2)'), '')))
        FROM @xml.nodes('/') n(el);

        SELECT c_codigo_tem = RTRIM(LTRIM(ISNULL(pal.c_codigo_tem, ''))),
               c_codigo_emp = RTRIM(LTRIM(ISNULL(pal.c_codigo_emp, ''))),
               c_codigo = RTRIM(LTRIM(ISNULL(pal.c_codigo_pme, ''))),
               c_codigo_pal = RTRIM(LTRIM(ISNULL(pal.c_codigo_pal, ''))),
               c_codsec_pal = RTRIM(LTRIM(ISNULL(pal.c_codsec_pme, ''))),
               c_tipo_pal = RTRIM(LTRIM(ISNULL(pal.c_tipo_pme, ''))),
               d_empaque_pal = pal.d_empaque_pme,
               c_hora_pal = pal.c_hora_pme,
               c_codigo_sel = RTRIM(LTRIM(ISNULL(pal.c_codigo_sel, ''))),
               c_codigo_bnd = RTRIM(LTRIM(ISNULL(pal.c_codigo_bnd, ''))),
               c_codigo_lot = RTRIM(LTRIM(ISNULL(pal.c_codigo_lot, ''))),
               v_nombre_lot = RTRIM(LTRIM(ISNULL(lot.v_nombre_lot, ''))),
               c_codigo_cul = RTRIM(LTRIM(ISNULL(pro.c_codigo_cul, ''))),
               v_nombre_cul = RTRIM(LTRIM(ISNULL(cul.v_nombre_cul, ''))),
               c_codigo_pro = RTRIM(LTRIM(ISNULL(pal.c_codigo_pro, ''))),
               v_nombre_pro = RTRIM(LTRIM(ISNULL(pro.v_nombre_pro, ''))),
               c_codigo_eti = RTRIM(LTRIM(ISNULL(pal.c_codigo_eti, ''))),
               v_nombre_eti = RTRIM(LTRIM(ISNULL(eti.v_nombre_eti, ''))),
               c_codigo_col = RTRIM(LTRIM(ISNULL(pal.c_codigo_col, ''))),
               v_nombre_col = RTRIM(LTRIM(ISNULL(col.v_nombre_col, ''))),
               c_codigo_env = RTRIM(LTRIM(ISNULL(pal.c_codigo_env, ''))),
               v_nombre_env = RTRIM(LTRIM(ISNULL(env.v_nombre_env, ''))),
               v_nombre_tam = RTRIM(LTRIM(ISNULL(tam.v_nombre_tam, ''))),
               n_bulxpa_pal = ISNULL(pal.n_bulxpa_pme, 0.00),
               n_peso_pme = ISNULL(pal.n_peso_pme, 0.00),
               c_codigo_usu = RTRIM(LTRIM(ISNULL(pal.c_codigo_usu, ''))),
               d_creacion = pal.d_creacion_pme,
               c_usumod = RTRIM(LTRIM(ISNULL(pal.c_usumod_pme, ''))),
               d_modifi = pal.d_modifi_pme,
               c_activo = RTRIM(LTRIM(ISNULL(pal.c_activo_pme, ''))),
               n_totalbulxpa_pme = tot.n_totalbulxpa_pme,
               n_totalpeso_pme = tot.n_totalpeso_pme,
               c_terminal_pme = pal.c_terminal_pme
        FROM t_palet_multiestiba pal (NOLOCK)
            LEFT JOIN t_lote lot (NOLOCK)
                ON lot.c_codigo_tem = pal.c_codigo_tem
                   AND lot.c_codigo_lot = pal.c_codigo_lot
            LEFT JOIN t_producto pro (NOLOCK)
                ON pal.c_codigo_pro = pro.c_codigo_pro
            LEFT JOIN t_cultivo cul (NOLOCK)
                ON cul.c_codigo_cul = pro.c_codigo_cul
            LEFT JOIN t_etiqueta eti (NOLOCK)
                ON eti.c_codigo_eti = pal.c_codigo_eti
            LEFT JOIN t_color col (NOLOCK)
                ON col.c_codigo_col = pal.c_codigo_col
            LEFT JOIN t_envase env (NOLOCK)
                ON env.c_codigo_env = pal.c_codigo_env
            LEFT JOIN t_tamanio tam (NOLOCK)
                ON tam.c_codigo_tam = pal.c_codigo_tam
            LEFT JOIN
            (
                SELECT c_codigo_tem = palvir.c_codigo_tem,
                       c_codigo_emp = palvir.c_codigo_emp,
                       c_codigo_pme = palvir.c_codigo_pme,
                       n_totalbulxpa_pme = SUM(palvir.n_bulxpa_pme),
                       n_totalpeso_pme = SUM(palvir.n_peso_pme)
                FROM dbo.t_palet_multiestiba palvir (NOLOCK)
                GROUP BY palvir.c_codigo_tem,
                         palvir.c_codigo_emp,
                         palvir.c_codigo_pme
            ) tot
                ON tot.c_codigo_tem = pal.c_codigo_tem
                   AND tot.c_codigo_emp = pal.c_codigo_emp
                   AND tot.c_codigo_pme = pal.c_codigo_pme
        WHERE 1 = 1
              AND ISNULL(pal.c_codigo_tem, '') LIKE @ls_temporada
              AND ISNULL(pal.c_codigo_emp, '') LIKE @ls_puntoemp
              /* AND ISNULL(pal.c_activo_pme, '1') = '1'*/
              AND pal.c_codigo_pme LIKE @ls_codigo
              AND RTRIM(LTRIM(ISNULL(pal.c_codsec_pme, ''))) LIKE @codsec
              AND
              (
                  (
                      'N' = @ls_tipo
                      AND RTRIM(LTRIM(ISNULL(pal.c_codigo_pal, ''))) = ''
                  )
                  OR
                  (
                      'S' = @ls_tipo
                      AND RTRIM(LTRIM(ISNULL(pal.c_codigo_pal, ''))) <> ''
                  )
                  OR
                  (
                      'A' = @ls_tipo
                      AND RTRIM(LTRIM(ISNULL(pal.c_activo_pme, '0'))) = '0'
                      AND RTRIM(LTRIM(ISNULL(pal.c_codigo_pal, ''))) = ''
                  )
                  OR ('T' = @ls_tipo)
              )
        ORDER BY c_codigo DESC,
                 c_codsec_pal;
        SET @as_success = 1;
        SET @as_message = 'OK';
    END TRY
    BEGIN CATCH
        SET @as_success = 0;
        SET @as_message = ERROR_MESSAGE();
    END CATCH;
END;


IF @as_operation = 18 /*Consulta  conteo de cajas temp*/
BEGIN
    BEGIN TRY

        SELECT @ls_terminal = RTRIM(LTRIM(ISNULL(n.el.value('c_terminal_ccp[1]', 'varchar(100)'), ''))),
               @ls_puntoemp = RTRIM(LTRIM(ISNULL(n.el.value('c_codigo_emp[1]', 'varchar(2)'), '')))
        FROM @xml.nodes('/') n(el);


        SELECT c_terminal_ccp,
               c_codigo_emp,
               c_idcaja_ccp,
               c_empleado_ccp,
               d_fecha_ccp,
               c_hrconteo_ccp,
               n_bulxpa_ccp,
               c_codigo_usu
        FROM t_conteocajas_app_temp (NOLOCK)
        WHERE RTRIM(LTRIM(ISNULL(c_terminal_ccp, ''))) = @ls_terminal
              AND ISNULL(c_codigo_emp, '') = @ls_puntoemp
              AND RTRIM(LTRIM(ISNULL(c_idcaja_cnt, ''))) = '';

        SET @as_success = 1;
        SET @as_message = 'OK';
    END TRY
    BEGIN CATCH
        SET @as_success = 0;
        SET @as_message = ERROR_MESSAGE();
    END CATCH;
END;

IF @as_operation = 19 /*ultimas precentacion empacadas*/
BEGIN
    BEGIN TRY

        SELECT @ls_temporada = RTRIM(LTRIM(ISNULL(n.el.value('c_codigo_tem[1]', 'varchar(2)'), ''))),
               @ls_puntoemp = RTRIM(LTRIM(ISNULL(n.el.value('c_codigo_emp[1]', 'varchar(2)'), ''))),
               @ls_codsel = RTRIM(LTRIM(ISNULL(n.el.value('c_codigo_sel[1]', 'varchar(10)'), ''))),
               @ls_banda = RTRIM(LTRIM(ISNULL(n.el.value('c_codigo_bnd[1]', 'varchar(2)'), '')))
        FROM @xml.nodes('/') n(el);

        SELECT DISTINCT
               c_codigo_pro = tDat.c_codigo_pro,
               v_nombre_pro = tDat.v_nombre_pro,
               c_codigo_eti = tDat.c_codigo_eti,
               v_nombre_eti = tDat.v_nombre_eti,
               c_codigo_col = tDat.c_codigo_col,
               v_nombre_col = tDat.v_nombre_col
        FROM
        (
            SELECT DISTINCT
                   c_codigo_sel = pal.c_codigo_sel,
                   c_codigo_bnd = pal.c_codigo_bnd,
                   c_codigo_pro = pal.c_codigo_pro,
                   c_codigo_eti = pal.c_codigo_eti,
                   c_codigo_col = pal.c_codigo_col,
                   v_nombre_pro = pro.v_nombre_pro,
                   v_nombre_eti = eti.v_nombre_eti,
                   v_nombre_col = col.v_nombre_col
            FROM t_palet pal (NOLOCK)
                INNER JOIN dbo.t_producto pro
                    ON pro.c_codigo_pro = pal.c_codigo_pro
                INNER JOIN dbo.t_etiqueta eti
                    ON eti.c_codigo_eti = pal.c_codigo_eti
                INNER JOIN dbo.t_color col
                    ON col.c_codigo_col = pal.c_codigo_col
            WHERE 1 = 1
                  AND pal.c_codigo_tem = @ls_temporada
                  AND pal.c_codigo_emp = @ls_puntoemp
                  AND ISNULL(pal.c_codigo_sel, '') = @ls_codsel
                  AND ISNULL(pal.c_codigo_bnd, '') LIKE @ls_banda
            /*AND pal.d_empaque_pal = :ad_fechaOpe*/
            UNION ALL
            SELECT DISTINCT
                   c_codigo_sel = pme.c_codigo_sel,
                   c_codigo_bnd = pme.c_codigo_bnd,
                   c_codigo_pro = pme.c_codigo_pro,
                   c_codigo_eti = pme.c_codigo_eti,
                   c_codigo_col = pme.c_codigo_col,
                   v_nombre_pro = pro.v_nombre_pro,
                   v_nombre_eti = eti.v_nombre_eti,
                   v_nombre_col = col.v_nombre_col
            FROM t_palet_multiestiba pme (NOLOCK)
                INNER JOIN dbo.t_producto pro
                    ON pro.c_codigo_pro = pme.c_codigo_pro
                INNER JOIN dbo.t_etiqueta eti
                    ON eti.c_codigo_eti = pme.c_codigo_eti
                INNER JOIN dbo.t_color col
                    ON col.c_codigo_col = pme.c_codigo_col
            WHERE 1 = 1
                  AND pme.c_codigo_tem = @ls_temporada
                  AND pme.c_codigo_emp = @ls_puntoemp
                  AND ISNULL(pme.c_codigo_sel, '') = @ls_codsel
                  AND ISNULL(pme.c_codigo_bnd, '') LIKE @ls_banda
            UNION ALL /*de los pallets temporales*/
            SELECT DISTINCT
                   c_codigo_sel = pal.c_codigo_sel,
                   c_codigo_bnd = pal.c_codigo_bnd,
                   c_codigo_pro = pal.c_codigo_pro,
                   c_codigo_eti = pal.c_codigo_eti,
                   c_codigo_col = pal.c_codigo_col,
                   v_nombre_pro = pro.v_nombre_pro,
                   v_nombre_eti = eti.v_nombre_eti,
                   v_nombre_col = col.v_nombre_col
            FROM t_palet pal (NOLOCK)
                INNER JOIN dbo.t_producto pro
                    ON pro.c_codigo_pro = pal.c_codigo_pro
                INNER JOIN dbo.t_etiqueta eti
                    ON eti.c_codigo_eti = pal.c_codigo_eti
                INNER JOIN dbo.t_color col
                    ON col.c_codigo_col = pal.c_codigo_col
                INNER JOIN dbo.t_paletemporal pte (NOLOCK)
                    ON pal.c_codigo_pal = pte.c_codigofinal_pal
                       AND pte.c_codigo_emp = pal.c_codigo_emp
                       AND pte.c_codigo_tem = pal.c_codigo_tem
            WHERE 1 = 1
                  AND pal.c_codigo_tem = @ls_temporada
                  AND pal.c_codigo_emp = @ls_puntoemp
                  AND @ls_codsel = 'S'
        /*AND pme.d_empaque_pme = :ad_fechaOpe*/
        ) tDat;

        SET @as_success = 1;
        SET @as_message = 'OK';
    END TRY
    BEGIN CATCH
        SET @as_success = 0;
        SET @as_message = ERROR_MESSAGE();
    END CATCH;
END;


IF @as_operation = 20 /*Catalogo de Empleados*/
BEGIN
    BEGIN TRY

        SELECT @ls_codigo = RTRIM(LTRIM(ISNULL(n.el.value('c_codigo_emp[1]', 'varchar(10)'), '')))
        FROM @xml.nodes('/') n(el);

        SELECT c_codigo_emp = emp.c_codigo_emp,
               v_nombre_emp = RTRIM(LTRIM(ISNULL(emp.v_nombre_emp, '')))
                              + RTRIM(LTRIM(ISNULL(emp.v_apellidopat_emp, '')))
                              + RTRIM(LTRIM(ISNULL(emp.v_apellidomat_emp, ''))),
               c_sexo_emp = RTRIM(LTRIM(ISNULL(emp.c_sexo_emp, ''))),
               v_rfc_emp = RTRIM(LTRIM(ISNULL(emp.v_rfc_emp, ''))),
               v_curp_emp = RTRIM(LTRIM(ISNULL(emp.v_curp_emp, ''))),
               n_sueldo_emp = ISNULL(emp.n_sueldo_emp, 0),
               n_sdoimss_emp = ISNULL(emp.n_sdoimss_emp, 0),
               n_sueldofiscal_emp = ISNULL(emp.n_sueldofiscal_emp, 0),
               c_numimss_emp = RTRIM(LTRIM(ISNULL(emp.c_numimss_emp, ''))),
               v_telefono_emp = RTRIM(LTRIM(ISNULL(emp.v_telefono_emp, ''))),
               v_telefono_accidente = RTRIM(LTRIM(ISNULL(emp.v_telefono_accidente, '')))
        FROM nomempleados emp (NOLOCK)
        WHERE c_activo_emp = '1'
              AND emp.c_codigo_emp LIKE @ls_codigo;

        SET @as_success = 1;
        SET @as_message = 'OK';
    END TRY
    BEGIN CATCH
        SET @as_success = 0;
        SET @as_message = ERROR_MESSAGE();
    END CATCH;
END;


IF @as_operation = 21 /*consulta folios de tiraje*/
BEGIN
    BEGIN TRY

        SELECT @ls_temporada = RTRIM(LTRIM(ISNULL(n.el.value('c_codigo_tem[1]', 'varchar(2)'), ''))),
               @ls_puntoemp = RTRIM(LTRIM(ISNULL(n.el.value('c_codigo_emp[1]', 'varchar(2)'), ''))),
               @ls_codigo = RTRIM(LTRIM(ISNULL(n.el.value('c_codigo[1]', 'varchar(10)'), '')))
        FROM @xml.nodes('/') n(el);



        IF EXISTS
        (
            SELECT *
            FROM t_empleado_controltirajefolios (NOLOCK)
            WHERE c_codigo_tem = @ls_temporada
                  AND c_codigo_emp = @ls_puntoemp
                  AND @ls_codigo
                  BETWEEN c_folioinicial_emt AND c_foliofinal_emt
        )
        BEGIN
            SELECT TOP 1
                   c_empleado_emt = c_empleado_emt,
                   c_folioinicial_emt = c_folioinicial_emt,
                   c_foliofinal_emt = c_foliofinal_emt
            FROM t_empleado_controltirajefolios (NOLOCK)
            WHERE c_codigo_tem = @ls_temporada
                  AND c_codigo_emp = @ls_puntoemp
                  AND @ls_codigo
                  BETWEEN c_folioinicial_emt AND c_foliofinal_emt
            ORDER BY c_folioinicial_emt DESC;



        END;
        ELSE
        BEGIN
            SELECT TOP 1
                   c_empleado_emt = c_empleado_cte,
                   c_folioinicial_emt = c_folioinicial_cte,
                   c_foliofinal_emt = c_foliofinal_cte
            FROM t_controltirajecontecajas (NOLOCK)
            WHERE c_codigo_tem = @ls_temporada
                  AND c_codigo_emp = @ls_puntoemp
                  AND @ls_codigo
                  BETWEEN c_folioinicial_cte AND c_foliofinal_cte
            ORDER BY c_folioinicial_emt DESC;
        END;

        SET @as_success = 1;
        SET @as_message = 'OK';
    END TRY
    BEGIN CATCH
        SET @as_success = 0;
        SET @as_message = ERROR_MESSAGE();
    END CATCH;
END;


IF @as_operation = 22 /*consulta vaciados para listado de palet temporal*/
BEGIN
    BEGIN TRY
        SELECT @ls_codigo = RTRIM(LTRIM(ISNULL(n.el.value('c_codigo[1]', 'varchar(10)'), ''))),
               @ls_maduracion = RTRIM(LTRIM(ISNULL(n.el.value('c_codigo_mad[1]', 'varchar(4)'), '')))
        FROM @xml.nodes('/') n(el);

        SELECT TOP 1
               @ls_temporada = ISNULL(c_codigo_tem, '')
        FROM t_temporada (NOLOCK)
        WHERE c_activo_tem = '1';

        IF EXISTS
        (
            SELECT *
            FROM t_sortingmaduraciondet (NOLOCK)
            WHERE c_codigo_tem = @ls_temporada
                  AND c_folio_sma = @ls_codigo
                  AND c_finvaciado_smd = 'S'
        )
        BEGIN
            SELECT c_codigo = c_codigo_rec + c_concecutivo_smd + c_codigo_pal,
                   c_codigo_mad = @ls_maduracion,
                   n_kilos_smd,
                   n_cajas_smd
            FROM dbo.t_sortingmaduraciondet (NOLOCK)
            WHERE c_codigo_tem = @ls_temporada
                  AND c_folio_sma = @ls_codigo
                  AND c_finvaciado_smd = 'S'
                  AND ISNULL(c_codigo_pte, '') = '';
        END;
        ELSE
        BEGIN
            SET @as_success = 1;
            SET @as_message = 'No existe el vaciado indicado. Favor de revisar';
        END;

        SET @as_success = 1;
        SET @as_message = 'OK';
    END TRY
    BEGIN CATCH
        SET @as_success = 0;
        SET @as_message = ERROR_MESSAGE();
    END CATCH;
END;


IF @as_operation = 23 /*Validar si existe el vaciado ingresado*/
BEGIN
    BEGIN TRY
        DECLARE @n_totkilos NUMERIC;
        DECLARE @n_kilospal NUMERIC;

        SELECT @ls_vaciado = RTRIM(LTRIM(ISNULL(n.el.value('c_codigo[1]', 'varchar(15)'), ''))),
               @n_kilospal = RTRIM(LTRIM(ISNULL(n.el.value('n_kilos[1]', 'NUMERIC'), 0)))
        FROM @xml.nodes('/') n(el);

        SELECT TOP 1
               @ls_temporada = ISNULL(c_codigo_tem, '')
        FROM t_temporada (NOLOCK)
        WHERE c_activo_tem = '1';

        IF EXISTS /*que exista el vaciado y este activo*/
        (
            SELECT *
            FROM t_sortingmaduracion (NOLOCK)
            WHERE c_codigo_tem = @ls_temporada
                  AND c_folio_sma = @ls_vaciado
                  AND c_finvaciado_sma = 'S'
                  AND c_activo_sma = '1'
        )
        BEGIN
            SELECT n_kilos = ISNULL(SUM(n_kilos_smd) - @n_kilospal, 0)
            FROM dbo.t_sortingmaduraciondet (NOLOCK)
            WHERE c_folio_sma = @ls_vaciado;

        END;
        ELSE
        BEGIN
            SELECT n_kilos = 0;
            SET @as_success = 1;
            SET @as_message = 'No existe el vaciado indicado. Favor de revisar';
        END;
    END TRY
    BEGIN CATCH
        SET @as_success = 0;
        SET @as_message = ERROR_MESSAGE();
    END CATCH;
END;

IF @as_operation = 24 /*Validar QUE EL QR NO ESTE RELACIONADO A UN PALET	*/
BEGIN
    BEGIN TRY

        SELECT @ls_codqr = RTRIM(LTRIM(ISNULL(n.el.value('c_codigo[1]', 'varchar(22)'), ''))),
               @ls_temporada = RTRIM(LTRIM(ISNULL(n.el.value('c_codigo_tem[1]', 'varchar(2)'), ''))),
               @ls_puntoemp = RTRIM(LTRIM(ISNULL(n.el.value('c_codigo_emp[1]', 'varchar(2)'), '')))
        FROM @xml.nodes('/') n(el);

        IF EXISTS /*que exista el vaciado*/
        (
            SELECT *
            FROM dbo.t_paletemporal (NOLOCK)
            WHERE c_codqrtemp_pte = @ls_codqr
                  AND c_codigo_tem = @ls_temporada
                  AND c_codigo_emp = @ls_puntoemp
                  AND c_activo_dso = '1'
        )
        BEGIN
            SELECT TOP 1
                   c_codqrtemp_pte
            FROM dbo.t_paletemporal (NOLOCK)
            WHERE c_codqrtemp_pte = @ls_codqr
                  AND c_codigo_tem = @ls_temporada
                  AND c_codigo_emp = @ls_puntoemp
                  AND c_activo_dso = '1';

            SET @as_success = 1;
            SET @as_message = 'El QR ya esta relacionado a un palet.';
        END;
        ELSE
        BEGIN
            SET @as_success = 0;
            SET @as_message = 'Qr libre';
        END;
    END TRY
    BEGIN CATCH
        SET @as_success = 0;
        SET @as_message = ERROR_MESSAGE();
    END CATCH;
END;

IF @as_operation = 25 /*Listado de palets temporales segun la corrida*/
BEGIN
    BEGIN TRY

        SELECT @ls_vaciado = RTRIM(LTRIM(ISNULL(n.el.value('c_codigo_sma[1]', 'varchar(15)'), ''))),
               @ls_temporada = RTRIM(LTRIM(ISNULL(n.el.value('c_codigo_tem[1]', 'varchar(2)'), ''))),
               @ls_puntoemp = RTRIM(LTRIM(ISNULL(n.el.value('c_codigo_emp[1]', 'varchar(2)'), '')))
        FROM @xml.nodes('/') n(el);

        IF EXISTS
        (
            SELECT *
            FROM dbo.t_paletemporal (NOLOCK)
            WHERE c_codigo_tem = @ls_temporada
                  AND c_codigo_emp = @ls_puntoemp
                  AND c_codigo_sma = @ls_vaciado
                  AND c_finalizado_pte = 'N'
                  AND c_activo_dso = '1'
        )
        BEGIN
            SELECT DISTINCT
                   c_codigo = pal.c_codqrtemp_pte,
                   c_codigo_mad = gdm.v_nombre_gdm,
                   n_cajas_smd = pal.d_totcaja_pte,
                   n_kilos_smd = pal.d_totkilos_pte,
                   c_codigo_cal = cal.v_nombre_cal
            FROM dbo.t_paletemporal pal (NOLOCK)
                LEFT JOIN t_gradomaduracion gdm (NOLOCK)
                    ON gdm.c_codigo_gdm = pal.c_codigo_gma
                LEFT JOIN dbo.t_calibre cal (NOLOCK)
                    ON cal.c_codigo_cal = pal.c_codigo_cal
            WHERE pal.c_codigo_tem = @ls_temporada
                  AND pal.c_codigo_sma = @ls_vaciado
                  AND pal.c_codigo_emp = @ls_puntoemp;
        END;
        ELSE
        BEGIN
            SET @as_success = 1;
            SET @as_message = 'No existe el vaciado indicado. Favor de revisar';
        END;

        SET @as_success = 1;
        SET @as_message = 'OK';
    END TRY
    BEGIN CATCH
        SET @as_success = 0;
        SET @as_message = ERROR_MESSAGE();
    END CATCH;
END;

IF @as_operation = 26 /*Codigo de palet temporal*/
BEGIN
    BEGIN TRY

        SELECT @ls_vaciado = RTRIM(LTRIM(ISNULL(n.el.value('c_codigo_sma[1]', 'varchar(15)'), '')))
        FROM @xml.nodes('/') n(el);

        SELECT TOP 1
               @ls_temporada = ISNULL(c_codigo_tem, '')
        FROM t_temporada (NOLOCK)
        WHERE c_activo_tem = '1';

        SELECT DISTINCT
               c_codigo_pte
        FROM dbo.t_paletemporal (NOLOCK)
        WHERE c_codigo_tem = @ls_temporada
              AND c_codigo_sma = @ls_vaciado
              AND c_finalizado_pte = 'N';

        SET @as_success = 1;
        SET @as_message = 'OK';
    END TRY
    BEGIN CATCH
        SET @as_success = 0;
        SET @as_message = ERROR_MESSAGE();
    END CATCH;
END;


IF @as_operation = 27 /*Ubicaciones */
BEGIN
    BEGIN TRY


        SELECT @ls_temporada = RTRIM(LTRIM(ISNULL(n.el.value('c_codigo_tem[1]', 'varchar(2)'), ''))),
               @ls_puntoemp = RTRIM(LTRIM(ISNULL(n.el.value('c_codigo_emp[1]', 'varchar(2)'), ''))),
               @ls_pedido = RTRIM(LTRIM(ISNULL(n.el.value('c_codigo_pdo[1]', 'varchar(16)'), ''))),
               @ls_codigo = RTRIM(LTRIM(ISNULL(n.el.value('c_codigo_def[1]', 'varchar(10)'), '')))
        FROM @xml.nodes('/') n(el);

        SELECT DISTINCT
               c_codigo_niv = RTRIM(LTRIM(ISNULL(det.c_codigo_niv, ''))),
               v_descripcion_niv = RTRIM(LTRIM(ISNULL(nivel.v_descripcion_niv, ''))),
               c_nomenclatura_niv = RTRIM(LTRIM(ISNULL(nivel.c_nomenclatura_niv, ''))),
               c_codigo_col = RTRIM(LTRIM(ISNULL(det.c_codigo_col, ''))),
               v_descripcion_col = RTRIM(LTRIM(ISNULL(colum.v_descripcion_col, ''))),
               c_nomenclatura_col = RTRIM(LTRIM(ISNULL(colum.c_nomenclatura_col, ''))),
               c_codigo_pos = RTRIM(LTRIM(ISNULL(det.c_codigo_pos, ''))),
               v_descripcion_pos = RTRIM(LTRIM(ISNULL(posi.v_descripcion_pos, ''))),
               c_posicion_pos = RTRIM(LTRIM(ISNULL(posi.c_posicion_pos, ''))),
               c_codigo_pal = ISNULL(
                              (
                                  SELECT STUFF(
                                         (
                                             SELECT DISTINCT
                                                    ', '
                                                    + ISNULL(   CASE
                                                                    WHEN RTRIM(LTRIM(ISNULL(pal.c_codigo_est, ''))) = '' THEN
                                                                        RTRIM(LTRIM(ISNULL(pal.c_codigo_pal, '')))
                                                                    ELSE
                                                                        RTRIM(LTRIM(ISNULL(pal.c_codigo_est, '')))
                                                                END,
                                                                ''
                                                            )
                                             FROM dbo.t_palet pal (NOLOCK)
                                             WHERE ISNULL(pal.c_codigo_niv, '') <> ''
                                                   AND ISNULL(pal.c_codigo_man, '') = ''
                                                   AND pal.c_codigo_def = det.c_codigo_def
                                                   AND pal.c_codigo_niv = det.c_codigo_niv
                                                   AND pal.c_columna_col = det.c_codigo_col
                                                   AND pal.c_codigo_pos = det.c_codigo_pos
                                                   AND pal.c_codigo_tem = @ls_temporada
                                                   AND pal.c_codigo_emp = @ls_puntoemp
                                             FOR XML PATH('')
                                         ),
                                         1,
                                         2,
                                         ''
                                              )
                              ),
                              ''
                                    ),
               id_pack = ISNULL(
                         (
                             SELECT STUFF(
                                    (
                                        SELECT DISTINCT
                                               ', ' + ISNULL(ubi.id_pack, '')
                                        FROM dbo.t_distribucion_pedido ubi (NOLOCK)
                                        WHERE ubi.c_codigo_tem = @ls_temporada
                                              AND ubi.c_codigo_emp = @ls_puntoemp
                                              AND ubi.c_codigo_pdo IN
                                                  (
                                                      SELECT col FROM dbo.fnSplit(@ls_pedido, ',')
                                                  )
                                              AND ubi.c_codigo_def = det.c_codigo_def
                                              AND ubi.c_codigo_niv = det.c_codigo_niv
                                              AND ubi.c_codigo_pos = det.c_codigo_pos
                                              AND ubi.c_columna_col = det.c_codigo_col
                                        FOR XML PATH('')
                                    ),
                                    1,
                                    2,
                                    ''
                                         )
                         ),
                         ''
                               ),
               v_nombre_eti = RTRIM(LTRIM(ISNULL(dis.v_nombre_dis, '')))
        FROM dbo.t_distribucionespfisicodet det (NOLOCK)
            INNER JOIN dbo.t_ubicacionnivel nivel (NOLOCK)
                ON nivel.c_codigo_niv = det.c_codigo_niv
            INNER JOIN dbo.t_ubicacioncolumna colum (NOLOCK)
                ON colum.c_codigo_col = det.c_codigo_col
            INNER JOIN dbo.t_ubicacionposicion posi (NOLOCK)
                ON posi.c_codigo_pos = det.c_codigo_pos
            INNER JOIN dbo.t_pedido pedo (NOLOCK)
                ON pedo.c_codigo_tem = @ls_temporada
                   AND pedo.c_codigo_emp = @ls_puntoemp
                   AND pedo.c_codigo_pdo IN
                       (
                           SELECT col FROM dbo.fnSplit(@ls_pedido, ',')
                       )
            INNER JOIN dbo.t_distribuidor dis (NOLOCK)
                ON dis.c_codigo_dis = pedo.c_codigo_dis
            LEFT JOIN t_distribucion_pedido ubi (NOLOCK)
                ON ubi.c_codigo_def = det.c_codigo_def
                   AND ubi.c_codigo_niv = det.c_codigo_niv
                   AND ubi.c_codigo_pos = det.c_codigo_pos
                   AND ubi.c_columna_col = det.c_codigo_col
                   AND ubi.c_codigo_tem = pedo.c_codigo_tem
                   AND ubi.c_codigo_emp = pedo.c_codigo_emp
                   AND ubi.c_codigo_pdo = pedo.c_codigo_pdo
        WHERE det.c_codigo_def = @ls_codigo
              AND @ls_pedido <> ''
        UNION ALL
        SELECT DISTINCT
               c_codigo_niv = RTRIM(LTRIM(ISNULL(det.c_codigo_niv, ''))),
               v_descripcion_niv = RTRIM(LTRIM(ISNULL(nivel.v_descripcion_niv, ''))),
               c_nomenclatura_niv = RTRIM(LTRIM(ISNULL(nivel.c_nomenclatura_niv, ''))),
               c_codigo_col = RTRIM(LTRIM(ISNULL(det.c_codigo_col, ''))),
               v_descripcion_col = RTRIM(LTRIM(ISNULL(colum.v_descripcion_col, ''))),
               c_nomenclatura_col = RTRIM(LTRIM(ISNULL(colum.c_nomenclatura_col, ''))),
               c_codigo_pos = RTRIM(LTRIM(ISNULL(det.c_codigo_pos, ''))),
               v_descripcion_pos = RTRIM(LTRIM(ISNULL(posi.v_descripcion_pos, ''))),
               c_posicion_pos = RTRIM(LTRIM(ISNULL(posi.c_posicion_pos, ''))),
               c_codigo_pal = ISNULL(
                              (
                                  SELECT STUFF(
                                         (
                                             SELECT DISTINCT
                                                    ', '
                                                    + ISNULL(   CASE
                                                                    WHEN RTRIM(LTRIM(ISNULL(pal.c_codigo_est, ''))) = '' THEN
                                                                        RTRIM(LTRIM(ISNULL(pal.c_codigo_pal, '')))
                                                                    ELSE
                                                                        RTRIM(LTRIM(ISNULL(pal.c_codigo_est, '')))
                                                                END,
                                                                ''
                                                            )
                                             FROM dbo.t_palet pal (NOLOCK)
                                             WHERE ISNULL(pal.c_codigo_niv, '') <> ''
                                                   AND ISNULL(pal.c_codigo_man, '') = ''
                                                   AND pal.c_codigo_def = det.c_codigo_def
                                                   AND pal.c_codigo_niv = det.c_codigo_niv
                                                   AND pal.c_columna_col = det.c_codigo_col
                                                   AND pal.c_codigo_pos = det.c_codigo_pos
                                                   AND pal.c_codigo_tem = @ls_temporada
                                                   AND pal.c_codigo_emp = @ls_puntoemp
                                             FOR XML PATH('')
                                         ),
                                         1,
                                         2,
                                         ''
                                              )
                              ),
                              ''
                                    ),
               id_pack = ISNULL(
                         (
                             SELECT STUFF(
                                    (
                                        SELECT DISTINCT
                                               ', ' + RTRIM(LTRIM(ISNULL(pro.id_pack, '')))
                                        FROM dbo.t_palet pal (NOLOCK)
                                            INNER JOIN dbo.t_producto pro
                                                ON pro.c_codigo_pro = pal.c_codigo_pro
                                        WHERE ISNULL(pal.c_codigo_niv, '') <> ''
                                              AND ISNULL(pal.c_codigo_man, '') = ''
                                              AND pal.c_codigo_def = det.c_codigo_def
                                              AND pal.c_codigo_niv = det.c_codigo_niv
                                              AND pal.c_columna_col = det.c_codigo_col
                                              AND pal.c_codigo_pos = det.c_codigo_pos
                                              AND pal.c_codigo_tem = @ls_temporada
                                              AND pal.c_codigo_emp = @ls_puntoemp
                                        FOR XML PATH('')
                                    ),
                                    1,
                                    2,
                                    ''
                                         )
                         ),
                         ''
                               ),
               v_nombre_eti = RTRIM(LTRIM(ISNULL('', '')))
        FROM dbo.t_distribucionespfisicodet det (NOLOCK)
            INNER JOIN dbo.t_ubicacionnivel nivel (NOLOCK)
                ON nivel.c_codigo_niv = det.c_codigo_niv
            INNER JOIN dbo.t_ubicacioncolumna colum (NOLOCK)
                ON colum.c_codigo_col = det.c_codigo_col
            INNER JOIN dbo.t_ubicacionposicion posi (NOLOCK)
                ON posi.c_codigo_pos = det.c_codigo_pos
        WHERE det.c_codigo_def = @ls_codigo
              AND @ls_pedido = ''
        ORDER BY RTRIM(LTRIM(ISNULL(det.c_codigo_niv, ''))) ASC,
                 RTRIM(LTRIM(ISNULL(det.c_codigo_col, ''))) ASC,
                 RTRIM(LTRIM(ISNULL(det.c_codigo_pos, ''))) ASC;

        SET @as_success = 1;
        SET @as_message = 'OK';
    END TRY
    BEGIN CATCH
        SET @as_success = 0;
        SET @as_message = ERROR_MESSAGE();
    END CATCH;
END;




IF @as_operation = 28 /*Cuartos frios o bodegas o espasio fisico */
BEGIN
    BEGIN TRY
        SELECT @ls_temporada = RTRIM(LTRIM(ISNULL(n.el.value('c_codigo_tem[1]', 'varchar(2)'), ''))),
               @ls_puntoemp = RTRIM(LTRIM(ISNULL(n.el.value('c_codigo_emp[1]', 'varchar(2)'), ''))),
               @ls_pedido = RTRIM(LTRIM(ISNULL(n.el.value('c_codigo_pdo[1]', 'varchar(16)'), '')))
        FROM @xml.nodes('/') n(el);

        SELECT c_codigo_def = RTRIM(LTRIM(ISNULL(esp.c_codigo_def, ''))),
               v_descripcion_def = esp.v_descripcion_def
        FROM dbo.t_distribucionespfisico esp (NOLOCK)
        WHERE RTRIM(LTRIM(ISNULL(esp.c_activo_def, ''))) = '1'
              AND '' = @ls_pedido
        UNION ALL
        SELECT DISTINCT
               c_codigo_def = RTRIM(LTRIM(ISNULL(esp.c_codigo_def, ''))),
               v_descripcion_def = esp.v_descripcion_def
        FROM dbo.t_distribucionespfisico esp (NOLOCK)
            INNER JOIN t_distribucion_pedido dis
                ON dis.c_codigo_def = esp.c_codigo_def
                   AND RTRIM(LTRIM(ISNULL(dis.c_codigo_tem, ''))) = @ls_temporada
                   AND RTRIM(LTRIM(ISNULL(dis.c_codigo_emp, ''))) = @ls_puntoemp
                   AND RTRIM(LTRIM(ISNULL(dis.c_codigo_pdo, ''))) = @ls_pedido
        WHERE RTRIM(LTRIM(ISNULL(esp.c_activo_def, ''))) = '1';



        SET @as_success = 1;
        SET @as_message = 'OK';
    END TRY
    BEGIN CATCH
        SET @as_success = 0;
        SET @as_message = ERROR_MESSAGE();
    END CATCH;
END;




IF @as_operation = 29 /*CONSULTA DE PALLET UBICACION */
BEGIN
    BEGIN TRY

        SELECT @ls_temporada = RTRIM(LTRIM(ISNULL(n.el.value('c_codigo_tem[1]', 'varchar(2)'), ''))),
               @ls_puntoemp = RTRIM(LTRIM(ISNULL(n.el.value('c_codigo_emp[1]', 'varchar(2)'), ''))),
               @ls_pallet = RTRIM(LTRIM(ISNULL(n.el.value('c_codigo_pal[1]', 'varchar(10)'), '')))
        FROM @xml.nodes('/') n(el);

        SELECT TOP 1
               c_codigo_tem = RTRIM(LTRIM(ISNULL(pal.c_codigo_tem, ''))),
               c_codigo_emp = RTRIM(LTRIM(ISNULL(pal.c_codigo_emp, ''))),
               c_codigo_pal = ISNULL(   CASE
                                            WHEN RTRIM(LTRIM(ISNULL(pal.c_codigo_est, ''))) = '' THEN
                                                RTRIM(LTRIM(ISNULL(pal.c_codigo_pal, '')))
                                            ELSE
                                                RTRIM(LTRIM(ISNULL(pal.c_codigo_est, '')))
                                        END,
                                        ''
                                    ),
               c_codigo_pro = RTRIM(LTRIM(ISNULL(pal.c_codigo_pro, ''))),
               v_nombre_pro = RTRIM(LTRIM(ISNULL(PRO.v_nombre_pro, ''))),
               id_pack = RTRIM(LTRIM(ISNULL(PRO.id_pack, ''))),
               c_codigo_eti = RTRIM(LTRIM(ISNULL(pal.c_codigo_eti, ''))),
               v_nombre_eti = RTRIM(LTRIM(ISNULL(ETI.v_nombre_eti, ''))),
               c_codigo_col = RTRIM(LTRIM(ISNULL(pal.c_codigo_col, ''))),
               v_nombre_col = RTRIM(LTRIM(ISNULL(col.v_nombre_col, ''))),
               c_codigo_pdo = RTRIM(LTRIM(ISNULL(pal.c_codigo_pdo, ''))),
               c_codigo_niv = RTRIM(LTRIM(ISNULL(niv.v_descripcion_niv, ''))),
               c_columna_col = RTRIM(LTRIM(ISNULL(colum.c_nomenclatura_col, ''))),
               c_codigo_pos = RTRIM(LTRIM(ISNULL(pos.c_posicion_pos, ''))),
               c_codigo_def = RTRIM(LTRIM(ISNULL(pal.c_codigo_def, ''))),
               c_codigo_def_pdo = RTRIM(LTRIM(ISNULL(tb_def.c_codigo_def, '')))
        FROM dbo.t_palet pal
            INNER JOIN dbo.t_producto PRO (NOLOCK)
                ON PRO.c_codigo_pro = pal.c_codigo_pro
            INNER JOIN dbo.t_etiqueta ETI (NOLOCK)
                ON ETI.c_codigo_eti = pal.c_codigo_eti
            LEFT JOIN dbo.t_color col (NOLOCK)
                ON col.c_codigo_col = pal.c_codigo_col
            LEFT JOIN dbo.t_ubicacionnivel niv (NOLOCK)
                ON niv.c_codigo_niv = pal.c_codigo_niv
            LEFT JOIN dbo.t_ubicacioncolumna colum (NOLOCK)
                ON colum.c_codigo_col = pal.c_columna_col
            LEFT JOIN dbo.t_ubicacionposicion pos (NOLOCK)
                ON pos.c_codigo_pos = pal.c_codigo_pos
            LEFT JOIN
            (
                SELECT c_codigo_tem = def.c_codigo_tem,
                       c_codigo_emp = def.c_codigo_emp,
                       c_codigo_pdo = def.c_codigo_pdo,
                       c_codigo_def = def.c_codigo_def
                FROM dbo.t_distribucion_pedido def (NOLOCK)
            ) tb_def
                ON tb_def.c_codigo_tem = pal.c_codigo_tem
                   AND tb_def.c_codigo_emp = pal.c_codigo_emp
                   AND tb_def.c_codigo_pdo = pal.c_codigo_pdo
        WHERE pal.c_codigo_tem = @ls_temporada
              AND pal.c_codigo_emp = @ls_puntoemp
              AND
              (
                  RTRIM(LTRIM(ISNULL(pal.c_codigo_pal, ''))) = @ls_pallet
                  OR RTRIM(LTRIM(ISNULL(pal.c_codigo_est, ''))) = @ls_pallet
              );


        SET @as_success = 1;
        SET @as_message = 'OK';
    END TRY
    BEGIN CATCH
        SET @as_success = 0;
        SET @as_message = ERROR_MESSAGE();
    END CATCH;
END;


IF @as_operation = 30 /*Pallet del manifiesto virtual*/
BEGIN
    BEGIN TRY

        SELECT @ls_temporada = RTRIM(LTRIM(ISNULL(n.el.value('c_codigo_tem[1]', 'varchar(2)'), ''))),
               @ls_puntoemp = RTRIM(LTRIM(ISNULL(n.el.value('c_codigo_emp[1]', 'varchar(2)'), ''))),
               @ls_man = RTRIM(LTRIM(ISNULL(n.el.value('c_codigo_man[1]', 'varchar(10)'), ''))),
               @ls_terminal = RTRIM(LTRIM(ISNULL(n.el.value('c_terminal_pal[1]', 'varchar(100)'), ''))),
               @ls_temp = RTRIM(LTRIM(ISNULL(n.el.value('c_temporales_pal[1]', 'varchar(1)'), '')))
        FROM @xml.nodes('/') n(el);

        SELECT c_codigo_tem = pal.c_codigo_tem,
               c_codigo_emp = pal.c_codigo_emp,
               c_codigo_pal = CASE
                                  WHEN RTRIM(LTRIM(ISNULL(pal.c_codigo_est, ''))) = '' THEN
                                      RTRIM(LTRIM(ISNULL(pal.c_codigo_pal, '')))
                                  ELSE
                                      RTRIM(LTRIM(ISNULL(pal.c_codigo_est, '')))
                              END,
               n_bulxpa_pal = SUM(pal.n_bulxpa_pal),
               c_tipo_pal = RTRIM(LTRIM(ISNULL(pal.c_tipo_pal, ''))),
               c_codigo_man = ''
        FROM dbo.t_palet pal (NOLOCK)
            LEFT JOIN dbo.t_manifiestovirtualdet det (NOLOCK)
                ON det.c_codigo_pal = pal.c_codigo_pal
                   AND det.c_codigo_tem = pal.c_codigo_tem
                   AND det.c_codigo_emp = pal.c_codigo_emp
        WHERE pal.c_codigo_tem = @ls_temporada
              AND pal.c_codigo_emp = @ls_puntoemp
              AND RTRIM(LTRIM(ISNULL(pal.c_marcado_pal, ''))) = '1'
              AND RTRIM(LTRIM(ISNULL(c_terminal_pal, ''))) = @ls_terminal
              AND RTRIM(LTRIM(ISNULL(det.c_codigo_pal, ''))) = ''
              AND
              (
                  RTRIM(LTRIM(ISNULL(@ls_temp, ''))) = 'S'
                  OR RTRIM(LTRIM(ISNULL(@ls_temp, ''))) = 'A'
              )
        GROUP BY pal.c_codigo_emp,
                 pal.c_codigo_tem,
                 CASE
                     WHEN RTRIM(LTRIM(ISNULL(pal.c_codigo_est, ''))) = '' THEN
                         RTRIM(LTRIM(ISNULL(pal.c_codigo_pal, '')))
                     ELSE
                         RTRIM(LTRIM(ISNULL(pal.c_codigo_est, '')))
                 END,
                 RTRIM(LTRIM(ISNULL(pal.c_tipo_pal, '')))
        UNION ALL
        SELECT c_codigo_tem = RTRIM(LTRIM(ISNULL(det.c_codigo_tem, ''))),
               c_codigo_emp = RTRIM(LTRIM(ISNULL(det.c_codigo_emp, ''))),
               c_codigo_pal = RTRIM(LTRIM(ISNULL(det.c_codigo_pal, ''))),
               n_bulxpa_pal = SUM(det.n_bulxpa_pal),
               c_tipo_pal = RTRIM(LTRIM(ISNULL(det.c_tipo_pal, ''))),
               c_codigo_man = RTRIM(LTRIM(ISNULL(det.c_codigo_man, '')))
        FROM dbo.t_manifiestovirtualdet det (NOLOCK)
        WHERE det.c_codigo_tem = @ls_temporada
              AND det.c_codigo_emp = @ls_puntoemp
              AND RTRIM(LTRIM(ISNULL(det.c_codigo_man, ''))) = @ls_man
              AND
              (
                  RTRIM(LTRIM(ISNULL(@ls_temp, ''))) = 'N'
                  OR RTRIM(LTRIM(ISNULL(@ls_temp, ''))) = 'A'
              )
        GROUP BY RTRIM(LTRIM(ISNULL(det.c_codigo_tem, ''))),
                 RTRIM(LTRIM(ISNULL(det.c_codigo_emp, ''))),
                 RTRIM(LTRIM(ISNULL(det.c_codigo_pal, ''))),
                 RTRIM(LTRIM(ISNULL(det.c_tipo_pal, ''))),
                 RTRIM(LTRIM(ISNULL(det.c_codigo_man, '')));

        SET @as_success = 1;
        SET @as_message = 'OK';
    END TRY
    BEGIN CATCH
        SET @as_success = 0;
        SET @as_message = ERROR_MESSAGE();
    END CATCH;
END;



IF @as_operation = 31 /*manifiesto virtual*/
BEGIN
    BEGIN TRY

        SELECT @ls_temporada = RTRIM(LTRIM(ISNULL(n.el.value('c_codigo_tem[1]', 'varchar(2)'), ''))),
               @ls_puntoemp = RTRIM(LTRIM(ISNULL(n.el.value('c_codigo_emp[1]', 'varchar(2)'), ''))),
               @ls_activos = RTRIM(LTRIM(ISNULL(n.el.value('c_activo_mv[1]', 'varchar(1)'), '')))
        FROM @xml.nodes('/') n(el);


        SELECT c_codigo_tem = RTRIM(LTRIM(ISNULL(det.c_codigo_tem, ''))),
               c_codigo_emp = RTRIM(LTRIM(ISNULL(det.c_codigo_emp, ''))),
               c_codigo_man = RTRIM(LTRIM(ISNULL(det.c_codigo_man, ''))),
               c_pallets = COUNT(DISTINCT det.c_codigo_pal),
               n_bulxpa_pal = SUM(det.n_bulxpa_pal),
               c_activo_mv = RTRIM(LTRIM(ISNULL(vir.c_activo_mv, '')))
        FROM t_manifiestovirtualdet det (NOLOCK)
            INNER JOIN dbo.t_manifiestovirtual vir (NOLOCK)
                ON vir.c_codigo_tem = det.c_codigo_tem
                   AND vir.c_codigo_emp = det.c_codigo_emp
                   AND vir.c_codigo_man = det.c_codigo_man
        WHERE RTRIM(LTRIM(ISNULL(det.c_codigo_man, ''))) <> ''
              AND RTRIM(LTRIM(ISNULL(det.c_codigo_tem, ''))) = @ls_temporada
              AND RTRIM(LTRIM(ISNULL(det.c_codigo_emp, ''))) = @ls_puntoemp
              AND RTRIM(LTRIM(ISNULL(vir.c_activo_mv, ''))) = @ls_activos
        GROUP BY RTRIM(LTRIM(ISNULL(det.c_codigo_tem, ''))),
                 RTRIM(LTRIM(ISNULL(det.c_codigo_emp, ''))),
                 RTRIM(LTRIM(ISNULL(det.c_codigo_man, ''))),
                 RTRIM(LTRIM(ISNULL(vir.c_activo_mv, '')));

        SET @as_success = 1;
        SET @as_message = 'OK';
    END TRY
    BEGIN CATCH
        SET @as_success = 0;
        SET @as_message = ERROR_MESSAGE();
    END CATCH;
END;



IF @as_operation = 32 /*Maximo de manifiesto virtual temporales*/
BEGIN
    BEGIN TRY

        SELECT @ls_temporada = RTRIM(LTRIM(ISNULL(n.el.value('c_codigo_tem[1]', 'varchar(2)'), ''))),
               @ls_puntoemp = RTRIM(LTRIM(ISNULL(n.el.value('c_codigo_emp[1]', 'varchar(2)'), ''))),
               @ls_mercado = RTRIM(LTRIM(ISNULL(n.el.value('c_merdes_mv[1]', 'varchar(1)'), '')))
        FROM @xml.nodes('/') n(el);


        IF NOT EXISTS
        (
            SELECT *
            FROM t_manifiestovirtual (NOLOCK)
            WHERE c_merdes_mv = @ls_mercado
                  AND c_codigo_tem = @ls_temporada
                  AND c_codigo_emp = @ls_puntoemp
        )
        BEGIN

            SELECT c_codigo_tem = @ls_temporada,
                   c_codigo_emp = @ls_puntoemp,
                   c_codigo_man = RTRIM(LTRIM(ISNULL(@ls_mercado, ''))) + '000000001';


        END;
        ELSE
        BEGIN
            SELECT TOP 1
                   c_codigo_tem,
                   c_codigo_emp,
                   c_codigo_man = RTRIM(LTRIM(ISNULL(@ls_mercado, '')))
                                  + RIGHT('000000000'
                                          + CONVERT(
                                                       VARCHAR(9),
                                                       CONVERT(
                                                                  NUMERIC,
                                                                  MAX(RIGHT(RTRIM(LTRIM(ISNULL(c_codigo_man, ''))), 9))
                                                              ) + 1
                                                   ), 9)
            FROM t_manifiestovirtual (NOLOCK)
            WHERE c_merdes_mv = @ls_mercado
                  AND c_codigo_tem = @ls_temporada
                  AND c_codigo_emp = @ls_puntoemp
            GROUP BY c_codigo_tem,
                     c_codigo_emp;

        END;

        SET @as_success = 1;
        SET @as_message = 'OK';
    END TRY
    BEGIN CATCH
        SET @as_success = 0;
        SET @as_message = ERROR_MESSAGE();
    END CATCH;
END;

IF @as_operation = 33 /*informacion de la recepcion o pallet temporal*/
BEGIN
    BEGIN TRY

        SELECT @ls_codqr = RTRIM(LTRIM(ISNULL(n.el.value('c_codigo[1]', 'varchar(22)'), ''))),
               @ls_temporada = RTRIM(LTRIM(ISNULL(n.el.value('c_codigo_tem[1]', 'varchar(2)'), ''))),
               @ls_puntoemp = RTRIM(LTRIM(ISNULL(n.el.value('c_codigo_emp[1]', 'varchar(2)'), '')))
        FROM @xml.nodes('/') n(el);

        IF EXISTS /*Sacamos las cajas y las libras de la recepcion*/
        (
            SELECT *
            FROM dbo.t_recepciondet
            WHERE (
                      c_codigo_rec + c_secuencia_red = @ls_codqr
                      OR c_codexterno_rec = @ls_codqr
                  )
                  AND c_codigo_tem = @ls_temporada
        )
        BEGIN
            SELECT n_cajas = ISNULL(ROUND(n_cajascorte_red, 0, 1), 0),
                   n_kilos = ISNULL(ROUND(n_kilos_red, 0, 1), 0),
				   c_lote = c_codigo_lot
            FROM t_recepciondet (NOLOCK)
            WHERE (
                      c_codigo_rec + c_secuencia_red = @ls_codqr
                      OR c_codexterno_rec = @ls_codqr
                  )
                  AND c_codigo_tem = @ls_temporada;
        END;
        ELSE IF EXISTS /*Sacamos las cajas y las libras de del pallet temporal con el QR*/
        (
            SELECT *
            FROM t_paletemporal (NOLOCK)
            WHERE (
                      c_codqrtemp_pte = @ls_codqr
                      AND c_codigo_tem = @ls_temporada
                      AND c_codigo_emp = @ls_puntoemp
                  )
                  OR
                  (
                      c_codqrtemp_pte = @ls_codqr
                      AND LEN(@ls_codqr) = 6
                  )
        )
        BEGIN
            SELECT n_cajas = ROUND(d_totcaja_pte, 0, 1),
                   n_kilos = ROUND(d_totkilos_pte, 0, 1),
				   c_lote = SUBSTRING(c_codigo_sma, 10,4) 
            FROM dbo.t_paletemporal (NOLOCK)
            WHERE (
                      c_codqrtemp_pte = @ls_codqr
                      AND c_codigo_tem = @ls_temporada
                      AND c_codigo_emp = @ls_puntoemp
                  )
                  OR
                  (
                      c_codqrtemp_pte = @ls_codqr
                      AND LEN(@ls_codqr) = 6
                  );
        END;
        ELSE IF EXISTS /*Sacamos las cajas y las libras del pallet temporal con el folio del pallet */
        (
            SELECT *
            FROM t_paletemporal (NOLOCK)
            WHERE (
                      c_codigo_pte = @ls_codqr
                      AND c_codigo_tem = @ls_temporada
                      AND c_codigo_emp = @ls_puntoemp
                  )
        )
        BEGIN
            SELECT n_cajas = ROUND(d_totcaja_pte, 0, 1),
                   n_kilos = ROUND(d_totkilos_pte, 0, 1),
				   c_lote = SUBSTRING(c_codigo_sma, 10,4) 
            FROM dbo.t_paletemporal (NOLOCK)
            WHERE (
                      c_codigo_pte = @ls_codqr
                      AND c_codigo_tem = @ls_temporada
                      AND c_codigo_emp = @ls_puntoemp
                  );
        END;
        ELSE IF EXISTS /*Sacamos las cajas y las libras del pallet final de eyeplus con el folio del pallet */
        (
            SELECT *
            FROM t_palet (NOLOCK)
            WHERE c_codigo_pal = @ls_codqr
                  AND c_codigo_tem = @ls_temporada
                  AND c_codigo_emp = @ls_puntoemp
        )
        BEGIN
            SELECT n_cajas = ROUND(n_bulxpa_pal, 0, 1),
                   n_kilos = ROUND(n_bulxpa_pal * pro.n_pesbul_pro, 0, 1),
				   c_lote = c_codigo_lot
            FROM dbo.t_palet pal (NOLOCK)
                INNER JOIN dbo.t_producto pro
                    ON pro.c_codigo_pro = pal.c_codigo_pro
            WHERE pal.c_codigo_pal = @ls_codqr
                  AND pal.c_codigo_tem = @ls_temporada
                  AND pal.c_codigo_emp = @ls_puntoemp;
        END;

        SET @as_success = 1;
        SET @as_message = 'OK';
    END TRY
    BEGIN CATCH
        SET @as_success = 0;
        SET @as_message = ERROR_MESSAGE();
    END CATCH;
END;


IF @as_operation = 34 /*consultar corridas activas para cargar en Dropdown*/
BEGIN
    BEGIN TRY
        SELECT c_folio_sma = c_folio_sma
        FROM t_sortingmaduracion (NOLOCK)
        WHERE c_activo_sma = '1';

        SET @as_success = 1;
        SET @as_message = 'OK';
    END TRY
    BEGIN CATCH
        SET @as_success = 0;
        SET @as_message = ERROR_MESSAGE();
    END CATCH;
END;

IF @as_operation = 35 /*disponible*/
BEGIN
    BEGIN TRY
        SELECT @ls_codigo = RTRIM(LTRIM(ISNULL(n.el.value('c_codigo[1]', 'varchar(15)'), '')))
        FROM @xml.nodes('/') n(el);

        --SELECT TOP 1
        --       @ls_temporada = ISNULL(c_codigo_tem, '')
        --FROM t_temporada (NOLOCK)
        --WHERE c_activo_tem = '1';

        --SELECT c_codigo_pte = RTRIM(LTRIM(ISNULL(c_codigo_pte, ''))),
        --       c_concecutivo_pte = RTRIM(LTRIM(ISNULL(c_concecutivo_pte, ''))),
        --       n_cajas_pte = RTRIM(LTRIM(ISNULL(n_cajas_pte, 0))),
        --       n_kilos_pte = RTRIM(LTRIM(ISNULL(n_kilos_pte, 0)))
        --FROM t_paletemporaldet (NOLOCK)
        --WHERE c_codigo_sma = ''
        --      AND c_codigo_tem = @ls_temporada
        --      AND c_codigo_sma = @ls_codigo;


        SET @as_success = 1;
        SET @as_message = 'OK';
    END TRY
    BEGIN CATCH
        SET @as_success = 0;
        SET @as_message = ERROR_MESSAGE();
    END CATCH;
END;


IF @as_operation = 36 /*Consulta de cajas por tarima conteo HH*/
BEGIN
    BEGIN TRY
        SELECT @ls_tarima = RTRIM(LTRIM(ISNULL(n.el.value('c_idtarima_ccp[1]', 'varchar(6)'), ''))),
               @ls_temporada = RTRIM(LTRIM(ISNULL(n.el.value('c_codigo_tem[1]', 'varchar(2)'), '')))
        FROM @xml.nodes('/') n(el);


        SELECT c_idtarima_ccp = RTRIM(LTRIM(ISNULL(hh.c_idtarima_ccp, ''))),
               c_idcaja_cpp = RTRIM(LTRIM(ISNULL(hh.c_idcaja_cpp, ''))),
               d_tarima_cch = hh.d_tarima_cch,
               c_hrtarima_cch = RTRIM(LTRIM(ISNULL(hh.c_hrtarima_cch, ''))),
               c_cerrado_cch = RTRIM(LTRIM(ISNULL(hh.c_cerrado_cch, 'N'))),
               c_estibador_cch = RTRIM(LTRIM(ISNULL(hh.c_estibador_cch, ''))),
               c_codigo_emp = CASE
                                  WHEN RTRIM(LTRIM(ISNULL(hh.c_codigo_emp, ''))) = '' THEN
                                      RTRIM(LTRIM(ISNULL(pp.c_codigo_emp, '')))
                                  ELSE
                                      RTRIM(LTRIM(ISNULL(hh.c_codigo_emp, '')))
                              END,
               c_codigo_pro = RTRIM(LTRIM(ISNULL(pp.c_codigo_pro, ''))),
               n_bulxpa_ccp = 1
        FROM t_control_conteo_hh hh (NOLOCK)
            INNER JOIN dbo.t_controlcaja_pallet pp (NOLOCK)
                ON pp.c_idcaja_ccp = hh.c_idcaja_cpp
        WHERE RTRIM(LTRIM(ISNULL(hh.c_idtarima_ccp, ''))) = @ls_tarima
              AND pp.c_codigo_tem = @ls_temporada;


        SET @as_success = 1;
        SET @as_message = 'OK';
    END TRY
    BEGIN CATCH
        SET @as_success = 0;
        SET @as_message = ERROR_MESSAGE();
    END CATCH;
END;

IF @as_operation = 37 /*cambio de ubicacion informacion de pallets*/
BEGIN
    BEGIN TRY
        SELECT @ls_codqr = RTRIM(LTRIM(ISNULL(n.el.value('c_codigo_qr[1]', 'varchar(22)'), ''))),
               @ls_temporada = RTRIM(LTRIM(ISNULL(n.el.value('c_codigo_tem[1]', 'varchar(2)'), ''))),
               @ls_puntoemp = RTRIM(LTRIM(ISNULL(n.el.value('c_codigo_emp[1]', 'varchar(2)'), '')))
        FROM @xml.nodes('/') n(el);

        IF NOT EXISTS
        (
            SELECT *
            FROM t_paletemporal pal (NOLOCK)
            WHERE (
                      (
                          pal.c_codqrtemp_pte = @ls_codqr
                          OR pal.c_codigo_pte = @ls_codqr
                      )
                      AND pal.c_codigo_tem = @ls_temporada
                      AND pal.c_codigo_emp = @ls_puntoemp
                      AND pal.c_activo_dso = '1'
                  )
                  OR
                  (
                      pal.c_codqrtemp_pte = @ls_codqr
                      AND LEN(@ls_codqr) = 6
                  )
        )
           And NOT EXISTS
        (
            SELECT *
            FROM dbo.t_palet pal (NOLOCK)
            WHERE pal.c_codigo_pal = @ls_codqr
                  AND pal.c_codigo_tem = @ls_temporada
                  AND pal.c_codigo_emp = @ls_puntoemp
        )
        BEGIN
            SET @as_success = 0;
            SET @as_message = 'no existe el pallet registrado';
            RETURN;
        END;

        SELECT TOP 1
               c_codigo_pte = ISNULL(RTRIM(LTRIM(pal.c_codigo_pte)), ''),
               d_totcaja_pte = ISNULL(RTRIM(LTRIM(pal.d_totcaja_pte)), 0),
               d_totkilos_pte = CASE
                                    WHEN ROUND(ISNULL(pub.n_pesoxpal_pub, 0), 0, 1) = 0 THEN
                                        ROUND(ISNULL(pal.d_totkilos_pte, 0), 0, 1)
                                    ELSE
                                        ROUND(ISNULL(pub.n_pesoxpal_pub, 0), 0, 1)
                                END,
               v_nombre_gdm = ISNULL(RTRIM(LTRIM(gma.v_nombre_gdm)), ''),
               c_codigo_are = '', /*ISNULL(RTRIM(LTRIM(pal.c_codigo_are)),''),*/
               v_nombre_cal = ISNULL(RTRIM(LTRIM(cal.v_nombre_cal)), ''),
               v_ubicacion_pte = ISNULL(are.v_nombre_are, '') + ' - ' + ISNULL(RTRIM(LTRIM(col.c_nomenclatura_col)), '')
                                 + ISNULL(RTRIM(LTRIM(niv.c_nomenclatura_niv)), '')
                                 + ISNULL(RTRIM(LTRIM(pos.c_posicion_pos)), ''),
               c_codigo_lot = SUBSTRING(pal.c_codigo_sma, 10,4) ,
			   c_codigo_lot2 = lot.c_codigoext_lot,
               /*(
                   SELECT dbo.fn_getBloquebyQrTemporadaEmpaque2(@ls_codqr, @ls_temporada, @ls_puntoemp)
               ),*/
               c_codigo_gma = ISNULL(RTRIM(LTRIM(pal.c_codigo_gma)), '')
        FROM t_paletemporal pal (NOLOCK)
            LEFT JOIN t_gradomaduracion (NOLOCK) gma
                ON gma.c_codigo_gdm = pal.c_codigo_gma
            LEFT JOIN t_calibre (NOLOCK) cal
                ON cal.c_codigo_cal = pal.c_codigo_cal
            LEFT JOIN dbo.t_ubicacionnivel niv (NOLOCK)
                ON niv.c_codigo_niv = pal.c_codigo_niv
            LEFT JOIN dbo.t_ubicacioncolumna col (NOLOCK)
                ON col.c_codigo_col = pal.c_columna_col
            LEFT JOIN t_ubicacionposicion pos (NOLOCK)
                ON pos.c_codigo_pos = pal.c_codigo_pos
            LEFT JOIN t_sortingmaduracion sma (NOLOCK)
                ON pal.c_codigo_sma = sma.c_folio_sma
            LEFT JOIN t_sortingmaduraciondet smadet (NOLOCK)
                ON smadet.c_folio_sma = sma.c_folio_sma
            LEFT JOIN dbo.t_recepciondet red (NOLOCK)
                ON red.c_codigo_rec = smadet.c_codigo_rec
                   AND red.c_secuencia_red = smadet.c_concecutivo_smd
            LEFT JOIN t_palletsubicaciones pub (NOLOCK)
                ON pub.c_codigo_pte = pal.c_codigo_pte
                   AND pub.c_ubiactual_pub = '1'
            LEFT JOIN dbo.t_areafisica are (NOLOCK)
                ON are.c_codigo_are = pal.c_codigo_are
			LEFT JOIN dbo.t_lote lot (NOLOCK) 
				ON SUBSTRING(pal.c_codigo_sma, 10,4) = lot.c_codigo_lot
        WHERE (
                  (
                      pal.c_codqrtemp_pte = @ls_codqr
                      OR pal.c_codigo_pte = @ls_codqr
                  )
                  AND pal.c_codigo_tem = @ls_temporada
                  AND pal.c_codigo_emp = @ls_puntoemp
                  AND pal.c_activo_dso = '1'
              )
              OR
              (
                  pal.c_codqrtemp_pte = @ls_codqr
                  AND LEN(@ls_codqr) = 6
              )
        UNION ALL
        SELECT TOP 1
               c_codigo_pte = ISNULL(RTRIM(LTRIM(pal.c_codigo_pal)), ''),
               d_totcaja_pte = ISNULL(RTRIM(LTRIM(pal.n_bulxpa_pal)), 0),
               d_totkilos_pte = CASE
                                    WHEN ROUND(ISNULL(pub.n_pesoxpal_pub, 0), 0, 1) = 0 THEN
                                        ROUND(ISNULL(pal.n_bulxpa_pal, 0), 0, 1)
                                        * ROUND(ISNULL(pro.n_pesbul_pro, 0), 0, 1)
                                    ELSE
                                        ROUND(ISNULL(pub.n_pesoxpal_pub, 0), 0, 1)
                                END,
               v_nombre_gdm = ISNULL(RTRIM(LTRIM(gma.v_nombre_gdm)), ''),
               c_codigo_are = '',               /*ISNULL(RTRIM(LTRIM(pal.c_codigo_are)),''),*/
               v_nombre_cal = cal.v_nombre_cal, /*ISNULL(RTRIM(LTRIM(cal.v_nombre_cal)), ''),*/
               v_ubicacion_pte = ISNULL(are.v_nombre_are, '') + ' - ' + ISNULL(RTRIM(LTRIM(col.c_nomenclatura_col)), '')
                                 + ISNULL(RTRIM(LTRIM(niv.c_nomenclatura_niv)), '')
                                 + ISNULL(RTRIM(LTRIM(pos.c_posicion_pos)), ''),
               c_codigo_lot = ISNULL(pal.c_codigo_lot, '') + ' - ' + ISNULL(lot.v_nombre_lot, ''),
			   c_codigo_lot2 = ISNULL(pal.c_codigo_lot, '') + ' - ' + ISNULL(lot.v_nombre_lot, ''),
               c_codigo_gma = cal.c_codigo_cal
        FROM dbo.t_palet pal (NOLOCK)
            LEFT JOIN t_gradomaduracion (NOLOCK) gma
                ON gma.c_codigo_gdm = '0001'
            LEFT JOIN dbo.t_color color (NOLOCK)
                ON color.c_codigo_col = pal.c_codigo_col
            LEFT JOIN t_calibre (NOLOCK) cal
                ON LTRIM(RTRIM(cal.v_nombre_cal)) = LTRIM(RTRIM(color.v_nombre_col))
            LEFT JOIN dbo.t_ubicacionnivel niv (NOLOCK)
                ON niv.c_codigo_niv = pal.c_codigo_niv
            LEFT JOIN dbo.t_ubicacioncolumna col (NOLOCK)
                ON col.c_codigo_col = pal.c_columna_col
            LEFT JOIN t_ubicacionposicion pos (NOLOCK)
                ON pos.c_codigo_pos = pal.c_codigo_pos
            --LEFT JOIN t_sortingmaduracion sma (NOLOCK)
            --    ON pal.c_codigo_sma = sma.c_folio_sma
            --LEFT JOIN t_sortingmaduraciondet smadet (NOLOCK)
            --    ON smadet.c_folio_sma = sma.c_folio_sma
            --LEFT JOIN dbo.t_recepciondet red (NOLOCK)
            --    ON red.c_codigo_rec = smadet.c_codigo_rec
            --       AND red.c_secuencia_red = smadet.c_concecutivo_smd
            LEFT JOIN t_palletsubicaciones pub (NOLOCK)
                ON pub.c_codigo_pte = pal.c_codigo_pal
                   AND pub.c_ubiactual_pub = '1'
            LEFT JOIN dbo.t_areafisica are (NOLOCK)
                ON are.c_codigo_are = pal.c_codigo_are
            LEFT JOIN dbo.t_producto pro (NOLOCK)
                ON pro.c_codigo_pro = pal.c_codigo_pro
            LEFT JOIN dbo.t_lote lot (NOLOCK)
                ON lot.c_codigo_tem = pal.c_codigo_tem
                   AND lot.c_codigo_lot = pal.c_codigo_lot
        WHERE pal.c_codigo_pal = @ls_codqr
              AND pal.c_codigo_tem = @ls_temporada
              AND pal.c_codigo_emp = @ls_puntoemp;

        SET @as_success = 1;
        SET @as_message = 'OK';
    END TRY
    BEGIN CATCH
        SET @as_success = 0;
        SET @as_message = ERROR_MESSAGE();
    END CATCH;
END;

IF @as_operation = 38 /*perdida o ganancia entre corrida y pellet generados de la corrida*/
BEGIN
    BEGIN TRY
        SELECT @ls_vaciado = RTRIM(LTRIM(ISNULL(n.el.value('c_codigo[1]', 'varchar(15)'), '')))
        FROM @xml.nodes('/') n(el);

        SELECT TOP 1
               diferencia = ROUND(ISNULL(sma.n_totalkilos_sma, 0), 0, 1) - ROUND(SUM(ISNULL(pal.d_totkilos_pte, 0)), 0, 1),
               totalcorrida = ROUND(ISNULL(sma.n_totalkilos_sma, 0), 0, 1)
        FROM t_sortingmaduracion sma (NOLOCK)
            INNER JOIN t_paletemporal pal (NOLOCK)
                ON sma.c_folio_sma = pal.c_codigo_sma
        WHERE pal.c_codigo_sma = @ls_vaciado
        GROUP BY sma.n_totalkilos_sma;

        SET @as_success = 1;
        SET @as_message = 'OK';
    END TRY
    BEGIN CATCH
        SET @as_success = 0;
        SET @as_message = ERROR_MESSAGE();
    END CATCH;
END;

IF @as_operation = 39 /*validar cuando ya existan palets generados en una corrida */
BEGIN
    BEGIN TRY
        SELECT @ls_are = RTRIM(LTRIM(ISNULL(n.el.value('c_codigo[1]', 'varchar(4)'), ''))),
               @ls_temporada = RTRIM(LTRIM(ISNULL(n.el.value('c_codigo_tem[1]', 'varchar(2)'), ''))),
               @ls_puntoemp = RTRIM(LTRIM(ISNULL(n.el.value('c_codigo_emp[1]', 'varchar(2)'), '')))
        FROM @xml.nodes('/') n(el);

        SELECT TOP 1
               @ls_vaciado = c_folio_sma
        FROM dbo.t_sortingmaduraciondet (NOLOCK)
        WHERE c_codigo_are = @ls_are
              AND c_activo_smd = '1'
              AND c_finvaciado_smd = 'N'
              AND c_codigo_tem = @ls_temporada
              AND c_codigo_emp = @ls_puntoemp;

        SELECT n_pallets = COUNT(c_codigo_pte)
        FROM t_paletemporal (NOLOCK)
        WHERE c_codigo_sma = @ls_vaciado
              AND c_codigo_tem = @ls_temporada
              AND c_codigo_emp = @ls_puntoemp;

        SET @as_success = 1;
        SET @as_message = 'OK';
    END TRY
    BEGIN CATCH
        SET @as_success = 0;
        SET @as_message = ERROR_MESSAGE();
    END CATCH;
END;


IF @as_operation = 40 /*Cuartos frios o bodegas o espasio fisico */
BEGIN
    BEGIN TRY
        SELECT @ls_are = RTRIM(LTRIM(ISNULL(n.el.value('c_codigo_are[1]', 'varchar(4)'), '')))
        FROM @xml.nodes('/') n(el);

        SELECT c_codigo_def = RTRIM(LTRIM(ISNULL(esp.c_codigo_def, ''))),
               v_descripcion_def = esp.v_descripcion_def
        FROM dbo.t_distribucionespfisico esp (NOLOCK)
            INNER JOIN t_espfisicoubicacion efu (NOLOCK)
                ON efu.c_codigo_def = esp.c_codigo_def
        WHERE RTRIM(LTRIM(ISNULL(esp.c_activo_def, ''))) = '1'
              AND efu.c_codigo_are = @ls_are;

        SET @as_success = 1;
        SET @as_message = 'OK';
    END TRY
    BEGIN CATCH
        SET @as_success = 0;
        SET @as_message = ERROR_MESSAGE();
    END CATCH;
END;

IF @as_operation = 41 /*Ubicaciones */
BEGIN
    BEGIN TRY
        SELECT @ls_temporada = RTRIM(LTRIM(ISNULL(n.el.value('c_codigo_tem[1]', 'varchar(2)'), ''))),
               @ls_puntoemp = RTRIM(LTRIM(ISNULL(n.el.value('c_codigo_emp[1]', 'varchar(2)'), ''))),
               @ls_are = RTRIM(LTRIM(ISNULL(n.el.value('c_codigo_are[1]', 'varchar(16)'), ''))),
               @ls_codigo = RTRIM(LTRIM(ISNULL(n.el.value('c_codigo_def[1]', 'varchar(10)'), '')))
        FROM @xml.nodes('/') n(el);

        SELECT DISTINCT
               c_codigo_niv = RTRIM(LTRIM(ISNULL(det.c_codigo_niv, ''))),
               v_descripcion_niv = RTRIM(LTRIM(ISNULL(nivel.v_descripcion_niv, ''))),
               c_nomenclatura_niv = RTRIM(LTRIM(ISNULL(nivel.c_nomenclatura_niv, ''))),
               c_codigo_col = RTRIM(LTRIM(ISNULL(det.c_codigo_col, ''))),
               v_descripcion_col = RTRIM(LTRIM(ISNULL(colum.v_descripcion_col, ''))),
               c_nomenclatura_col = RTRIM(LTRIM(ISNULL(colum.c_nomenclatura_col, ''))),
               c_codigo_pos = RTRIM(LTRIM(ISNULL(det.c_codigo_pos, ''))),
               v_descripcion_pos = RTRIM(LTRIM(ISNULL(posi.v_descripcion_pos, ''))),
               c_posicion_pos = RTRIM(LTRIM(ISNULL(posi.c_posicion_pos, ''))),
               c_codigo_pal = ISNULL(
                              (
                                  SELECT STUFF(
                                         (
                                             SELECT DISTINCT
                                                    ', ' + ISNULL(pal.c_codigo_pte, '')
                                             FROM t_paletemporal pal (NOLOCK)
                                             WHERE ISNULL(pal.c_codigo_niv, '') <> ''
                                                   AND pal.c_codigo_def = det.c_codigo_def
                                                   AND pal.c_codigo_niv = det.c_codigo_niv
                                                   AND pal.c_columna_col = det.c_codigo_col
                                                   AND pal.c_codigo_pos = det.c_codigo_pos
                                                   AND pal.c_codigo_tem = @ls_temporada
                                                   AND pal.c_codigo_emp = @ls_puntoemp
                                                   AND pal.c_codigo_are = @ls_are
                                             FOR XML PATH('')
                                         ),
                                         1,
                                         2,
                                         ''
                                              )
                              ),
                              ''
                                    ),
               id_pack = '',
               v_nombre_eti = RTRIM(LTRIM(ISNULL('', '')))
        FROM dbo.t_distribucionespfisicodet det (NOLOCK)
            INNER JOIN dbo.t_ubicacionnivel nivel (NOLOCK)
                ON nivel.c_codigo_niv = det.c_codigo_niv
            INNER JOIN dbo.t_ubicacioncolumna colum (NOLOCK)
                ON colum.c_codigo_col = det.c_codigo_col
            INNER JOIN dbo.t_ubicacionposicion posi (NOLOCK)
                ON posi.c_codigo_pos = det.c_codigo_pos
        WHERE det.c_codigo_def = @ls_codigo
              AND @ls_are <> ''
        UNION ALL
        SELECT DISTINCT
               c_codigo_niv = RTRIM(LTRIM(ISNULL(det.c_codigo_niv, ''))),
               v_descripcion_niv = RTRIM(LTRIM(ISNULL(nivel.v_descripcion_niv, ''))),
               c_nomenclatura_niv = RTRIM(LTRIM(ISNULL(nivel.c_nomenclatura_niv, ''))),
               c_codigo_col = RTRIM(LTRIM(ISNULL(det.c_codigo_col, ''))),
               v_descripcion_col = RTRIM(LTRIM(ISNULL(colum.v_descripcion_col, ''))),
               c_nomenclatura_col = RTRIM(LTRIM(ISNULL(colum.c_nomenclatura_col, ''))),
               c_codigo_pos = RTRIM(LTRIM(ISNULL(det.c_codigo_pos, ''))),
               v_descripcion_pos = RTRIM(LTRIM(ISNULL(posi.v_descripcion_pos, ''))),
               c_posicion_pos = RTRIM(LTRIM(ISNULL(posi.c_posicion_pos, ''))),
               c_codigo_pal = ISNULL(
                              (
                                  SELECT STUFF(
                                         (
                                             SELECT DISTINCT
                                                    ', ' + ISNULL(pal.c_codigo_pte, '')
                                             FROM t_paletemporal pal (NOLOCK)
                                             WHERE ISNULL(pal.c_codigo_niv, '') <> ''
                                                   AND pal.c_codigo_def = det.c_codigo_def
                                                   AND pal.c_codigo_niv = det.c_codigo_niv
                                                   AND pal.c_columna_col = det.c_codigo_col
                                                   AND pal.c_codigo_pos = det.c_codigo_pos
                                                   AND pal.c_codigo_tem = @ls_temporada
                                                   AND pal.c_codigo_emp = @ls_puntoemp
                                             FOR XML PATH('')
                                         ),
                                         1,
                                         2,
                                         ''
                                              )
                              ),
                              ''
                                    ),
               id_pack = '',
               v_nombre_eti = RTRIM(LTRIM(ISNULL('', '')))
        FROM dbo.t_distribucionespfisicodet det (NOLOCK)
            INNER JOIN dbo.t_ubicacionnivel nivel (NOLOCK)
                ON nivel.c_codigo_niv = det.c_codigo_niv
            INNER JOIN dbo.t_ubicacioncolumna colum (NOLOCK)
                ON colum.c_codigo_col = det.c_codigo_col
            INNER JOIN dbo.t_ubicacionposicion posi (NOLOCK)
                ON posi.c_codigo_pos = det.c_codigo_pos
        WHERE det.c_codigo_def = @ls_codigo
              AND @ls_are = ''
        ORDER BY RTRIM(LTRIM(ISNULL(det.c_codigo_niv, ''))) ASC,
                 RTRIM(LTRIM(ISNULL(det.c_codigo_col, ''))) ASC,
                 RTRIM(LTRIM(ISNULL(det.c_codigo_pos, ''))) ASC;


        SET @as_success = 1;
        SET @as_message = 'OK';
    END TRY
    BEGIN CATCH
        SET @as_success = 0;
        SET @as_message = ERROR_MESSAGE();
    END CATCH;
END;

IF @as_operation = 42 /*CONSULTA DE PALLET UBICACION temporal */
BEGIN
    BEGIN TRY

        SELECT @ls_temporada = RTRIM(LTRIM(ISNULL(n.el.value('c_codigo_tem[1]', 'varchar(2)'), ''))),
               @ls_puntoemp = RTRIM(LTRIM(ISNULL(n.el.value('c_codigo_emp[1]', 'varchar(2)'), ''))),
               @ls_pallet = RTRIM(LTRIM(ISNULL(n.el.value('c_codigo_pal[1]', 'varchar(10)'), '')))
        FROM @xml.nodes('/') n(el);

        SELECT TOP 1
               c_codigo_tem = RTRIM(LTRIM(ISNULL(pal.c_codigo_tem, ''))),
               c_codigo_emp = RTRIM(LTRIM(ISNULL(pal.c_codigo_emp, ''))),
               c_codigo_pal = RTRIM(LTRIM(ISNULL(pal.c_codigo_pte, ''))),
               c_codigo_pro = '',
               v_nombre_pro = '',
               id_pack = '',
               c_codigo_eti = '',
               v_nombre_eti = '',
               c_codigo_col = '',
               v_nombre_col = '',
               c_codigo_pdo = '',
               c_codigo_niv = RTRIM(LTRIM(ISNULL(pal.c_codigo_niv, ''))),
               c_columna_col = RTRIM(LTRIM(ISNULL(pal.c_columna_col, ''))),
               c_codigo_pos = RTRIM(LTRIM(ISNULL(pal.c_codigo_pos, ''))),
               c_codigo_def = RTRIM(LTRIM(ISNULL(pal.c_codigo_def, ''))),
               c_codigo_def_pdo = RTRIM(LTRIM(ISNULL(pal.c_codigo_def, '')))
        FROM dbo.t_paletemporal pal
        WHERE pal.c_codigo_tem = @ls_temporada
              AND pal.c_codigo_emp = @ls_puntoemp
              AND RTRIM(LTRIM(ISNULL(pal.c_codigo_pte, ''))) = @ls_pallet;

        SET @as_success = 1;
        SET @as_message = 'OK';
    END TRY
    BEGIN CATCH
        SET @as_success = 0;
        SET @as_message = ERROR_MESSAGE();
    END CATCH;
END;


IF @as_operation = 43 /*maneja ubicacion */
BEGIN
    BEGIN TRY
        SELECT @ls_temporada = RTRIM(LTRIM(ISNULL(n.el.value('c_codigo_tem[1]', 'varchar(2)'), ''))),
               @ls_puntoemp = RTRIM(LTRIM(ISNULL(n.el.value('c_codigo_emp[1]', 'varchar(2)'), ''))),
               @ls_pallet = RTRIM(LTRIM(ISNULL(n.el.value('c_codigo_pte[1]', 'varchar(10)'), '')))
        FROM @xml.nodes('/') n(el);

        IF EXISTS
        (
            SELECT *
            FROM t_palletsubicaciones (NOLOCK)
            WHERE c_codigo_pte = @ls_pallet
                  AND c_codigo_tem = @ls_temporada
                  AND c_codigo_emp = @ls_puntoemp
        )
        BEGIN
            SELECT TOP 1
                   c_ubicacion_are = ISNULL(c_ubicacion_are, '0')
            FROM t_areafisica are (NOLOCK)
                INNER JOIN dbo.t_paletemporal pal (NOLOCK)
                    ON pal.c_codigo_are = are.c_codigo_are
            WHERE pal.c_codigo_pte = @ls_pallet
                  AND pal.c_codigo_tem = @ls_temporada
                  AND pal.c_codigo_emp = @ls_puntoemp
            UNION ALL
            SELECT TOP 1
                   c_ubicacion_are = ISNULL(c_ubicacion_are, '0')
            FROM t_areafisica are (NOLOCK)
                INNER JOIN dbo.t_palet pal (NOLOCK)
                    ON pal.c_codigo_are = are.c_codigo_are
            WHERE pal.c_codigo_pal = @ls_pallet
                  AND pal.c_codigo_tem = @ls_temporada
                  AND pal.c_codigo_emp = @ls_puntoemp;


            SET @as_success = 1;
            SET @as_message = 'OK';
        END;

    END TRY
    BEGIN CATCH
        SET @as_success = 0;
        SET @as_message = ERROR_MESSAGE();
    END CATCH;
END;

IF @as_operation = 44 /*traer tipo de corrida */
BEGIN
    BEGIN TRY
        SELECT @ls_temporada = RTRIM(LTRIM(ISNULL(n.el.value('c_codigo_tem[1]', 'varchar(2)'), ''))),
               @ls_puntoemp = RTRIM(LTRIM(ISNULL(n.el.value('c_codigo_emp[1]', 'varchar(2)'), ''))),
               @ls_vaciado = RTRIM(LTRIM(ISNULL(n.el.value('c_codigo_sma[1]', 'varchar(15)'), '')))
        FROM @xml.nodes('/') n(el);

        IF EXISTS
        (
            SELECT *
            FROM dbo.t_sortingmaduracion (NOLOCK)
            WHERE c_folio_sma = @ls_vaciado
                  AND c_codigo_tem = @ls_temporada
                  AND c_codigo_emp = @ls_puntoemp
        )
        BEGIN
            SELECT TOP 1
                   c_tipo_corrida = ISNULL(c_tipocorrida_sma, 'M')
            FROM t_sortingmaduracion (NOLOCK)
            WHERE c_folio_sma = @ls_vaciado
                  AND c_codigo_tem = @ls_temporada
                  AND c_codigo_emp = @ls_puntoemp;

            SET @as_success = 1;
            SET @as_message = 'OK';
            RETURN;
        END;
        SET @as_success = 0;
        SET @as_message = 'OK';
    END TRY
    BEGIN CATCH
        SET @as_success = 0;
        SET @as_message = ERROR_MESSAGE();
    END CATCH;
END;

IF @as_operation = 45 /*consultar calibre para cargar en Dropdown*/
BEGIN
    BEGIN TRY
        SELECT c_codigo_cal = RTRIM(LTRIM(ISNULL(c_codigo_cal, ''))),
               v_nombre_cal = RTRIM(LTRIM(ISNULL(v_nombre_cal, '')))
        FROM dbo.t_calibre (NOLOCK)
        WHERE c_activo_cal = '1';

        SET @as_success = 1;
        SET @as_message = 'OK';
    END TRY
    BEGIN CATCH
        SET @as_success = 0;
        SET @as_message = ERROR_MESSAGE();
    END CATCH;
END;

IF @as_operation = 46 /*consultar tiempo sugerido respecto al area seleccionada*/
BEGIN
    BEGIN TRY
        SELECT @ls_are = RTRIM(LTRIM(ISNULL(n.el.value('c_codigo_are[1]', 'varchar(4)'), ''))),
               @ls_maduracion = RTRIM(LTRIM(ISNULL(n.el.value('c_codigo_gma[1]', 'varchar(4)'), '')))
        FROM @xml.nodes('/') n(el);

        SELECT TOP 1
               n_hora = ISNULL(ROUND(n_tiemposugerido_ats / 60, 0, 1), 0),
               n_minuto = ISNULL(ROUND(n_tiemposugerido_ats % 60, 0, 1), 0)
        FROM t_areatiemposugerido (NOLOCK)
        WHERE c_codigo_are = @ls_are
              AND c_codigo_gdm = @ls_maduracion;

        SET @as_success = 1;
        SET @as_message = 'OK';
    END TRY
    BEGIN CATCH
        SET @as_success = 0;
        SET @as_message = ERROR_MESSAGE();
    END CATCH;
END;


IF @as_operation = 47 /*consultar tiempo sugerido respecto al area seleccionada*/
BEGIN
    BEGIN TRY
        SELECT @ls_temporada = RTRIM(LTRIM(ISNULL(n.el.value('c_codigo_tem[1]', 'varchar(2)'), ''))),
               @ls_puntoemp = RTRIM(LTRIM(ISNULL(n.el.value('c_codigo_emp[1]', 'varchar(2)'), '')))
        FROM @xml.nodes('/') n(el);

        SELECT c_qr = pal.c_codqrtemp_pte,
               c_pallet = pal.c_codigo_pte,
               v_area = are.v_nombre_are,
               d_entrada = CONVERT(VARCHAR, ubi.d_entrada_pub, 20),
               d_salida = CONVERT(VARCHAR, DATEADD(MINUTE, ubi.n_tiemposugerido_pub, ubi.d_entrada_pub), 20),
               d_hoy = CONVERT(VARCHAR, GETDATE(), 20),
               d_duracion = ubi.n_tiemposugerido_pub,
               v_restante = DATEDIFF(
                                        MINUTE,
                                        CONVERT(VARCHAR, GETDATE(), 20),
                                        CONVERT(
                                                   VARCHAR,
                                                   DATEADD(MINUTE, ubi.n_tiemposugerido_pub, ubi.d_entrada_pub),
                                                   20
                                               )
                                    )
        FROM t_paletemporal pal (NOLOCK)
            INNER JOIN t_palletsubicaciones ubi (NOLOCK)
                ON ubi.c_codigo_pte = pal.c_codigo_pte
            INNER JOIN t_areafisica are (NOLOCK)
                ON are.c_codigo_are = pal.c_codigo_are
        WHERE pal.c_codigo_tem = @ls_temporada
              AND pal.c_codigo_emp = @ls_puntoemp
              AND ubi.n_tiemposugerido_pub > 0
              AND pal.c_finalizado_pte = 'N'
              AND ubi.c_ubiactual_pub = '1'
        ORDER BY 8 ASC;

        SET @as_success = 1;
        SET @as_message = 'OK';
    END TRY
    BEGIN CATCH
        SET @as_success = 0;
        SET @as_message = ERROR_MESSAGE();
    END CATCH;
END;

IF @as_operation = 48 /*validar que exista el pallet con el QR*/
BEGIN
    BEGIN TRY
        SELECT @ls_temporada = RTRIM(LTRIM(ISNULL(n.el.value('c_codigo_tem[1]', 'varchar(2)'), ''))),
               @ls_puntoemp = RTRIM(LTRIM(ISNULL(n.el.value('c_codigo_emp[1]', 'varchar(2)'), ''))),
               @ls_codqr = RTRIM(LTRIM(ISNULL(n.el.value('c_codigo_qr[1]', 'varchar(22)'), '')))
        FROM @xml.nodes('/') n(el);

        SELECT TOP 1
               c_codigo_pal = pal.c_codigo_pte
        FROM t_paletemporal pal (NOLOCK)
        WHERE (
                  pal.c_codigo_tem = @ls_temporada
                  AND pal.c_codigo_emp = @ls_puntoemp
                  AND pal.c_codqrtemp_pte = @ls_codqr
              )
              OR
              (
                  pal.c_codqrtemp_pte = @ls_codqr
                  AND LEN(@ls_codqr) = 6
              );

        SET @as_success = 1;
        SET @as_message = 'OK';
    END TRY
    BEGIN CATCH
        SET @as_success = 0;
        SET @as_message = ERROR_MESSAGE();
    END CATCH;
END;

IF @as_operation = 49 /*traer corrida dependiendo la mesa */
BEGIN
    BEGIN TRY
        SELECT @ls_codigo = RTRIM(LTRIM(ISNULL(n.el.value('c_codigo_are[1]', 'varchar(4)'), ''))),
               @ls_temporada = RTRIM(LTRIM(ISNULL(n.el.value('c_codigo_tem[1]', 'varchar(2)'), '')))
        FROM @xml.nodes('/') n(el);

        SELECT TOP 1
               c_folio_sma = c_folio_sma
        FROM t_sortingmaduraciondet (NOLOCK)
        WHERE c_codigo_are = @ls_codigo
              AND c_codigo_tem = @ls_temporada
              AND c_activo_smd = '1'
              AND c_finvaciado_smd = 'N';

        SET @as_success = 1;
        SET @as_message = 'OK';
    END TRY
    BEGIN CATCH
        SET @as_success = 0;
        SET @as_message = ERROR_MESSAGE();
    END CATCH;
END;

IF @as_operation = 50 /*validar datos de catalogos areas,grado maduracion,tipo caja  */
BEGIN
    BEGIN TRY

        SELECT @ls_codigo = RTRIM(LTRIM(ISNULL(n.el.value('c_codigo[1]', 'varchar(4)'), ''))),
               @tipo = RTRIM(LTRIM(ISNULL(n.el.value('c_tipo[1]', 'varchar(1)'), ''))),
			   @ls_puntoemp = RTRIM(LTRIM(ISNULL(n.el.value('c_codigo_emp[1]', 'varchar(2)'), '')))
        FROM @xml.nodes('/') n(el);


        IF (@tipo = 1) /*Catalogo de area mesas*/
        BEGIN
            SELECT c_codigo = c_codigo_are
            FROM dbo.t_areafisica (NOLOCK)
            WHERE c_codigo_are = @ls_codigo
                  AND c_tipo_are = '05'
                  AND c_activo_are = '1'
				  AND c_codigo_emp = @ls_puntoemp;
        END;
        ELSE IF (@tipo = 2) /*Catalogo de grado de maduracion*/
        BEGIN
            SELECT c_codigo = c_codigo_gdm
            FROM dbo.t_gradomaduracion
            WHERE c_codigo_gdm = @ls_codigo
                  AND c_activo_gmd = '1';
        END;
        ELSE IF (@tipo = 3) /*Catalogo de tipo de caja */
        BEGIN
            SELECT c_codigo = c_codigo_tcj
            FROM dbo.t_tipocaja (NOLOCK)
            WHERE c_codigo_tcj = @ls_codigo
                  AND c_tipo_tcj = 'C'
                  AND c_activo_tcj = '1'
                  AND c_defaulcajpro_tcj = 'S';
        END;
        ELSE IF (@tipo = 4) /*Catalogo de tipo tarima*/
        BEGIN
            SELECT c_codigo = c_codigo_tcj
            FROM dbo.t_tipocaja (NOLOCK)
            WHERE c_codigo_tcj = @ls_codigo
                  AND c_tipo_tcj = 'T'
                  AND c_activo_tcj = '1'
                  AND c_defaulcajpro_tcj = 'S';
        END;
        ELSE IF (@tipo = 5) /*Catalogo de calibre*/
        BEGIN
            SELECT c_codigo = c_codigo_cal
            FROM dbo.t_calibre (NOLOCK)
            WHERE c_codigo_cal = @ls_codigo
                  AND c_activo_cal = '1';
        END;
        ELSE IF (@tipo = 6) /*mesa de costumer pack tipo 10*/
        BEGIN
            SELECT c_codigo = c_codigo_are
            FROM dbo.t_areafisica (NOLOCK)
            WHERE c_codigo_are = @ls_codigo
                  AND c_tipo_are = '10'
                  AND c_activo_are = '1';
        END;
        ELSE IF (@tipo = 7) /*mesa de corridas*/
        BEGIN
            SELECT v_nombre_are = v_nombre_are
            FROM dbo.t_areafisica (NOLOCK)
            WHERE c_codigo_are = @ls_codigo
                  AND c_activo_are = '1'
				  --AND c_tipo_are = '05'
				  AND c_codigo_emp = @ls_puntoemp;
        END;
        ELSE
        BEGIN
            SELECT c_codigo = '';
        END;

        SET @as_success = 1;
        SET @as_message = 'OK';
    END TRY
    BEGIN CATCH
        SET @as_success = 0;
        SET @as_message = ERROR_MESSAGE();
    END CATCH;
END;

IF @as_operation = 51 /*validar tipo de corrida calibre o maduracion  */
BEGIN
    BEGIN TRY
        SELECT @ls_codigo = RTRIM(LTRIM(ISNULL(n.el.value('c_codigo[1]', 'varchar(4)'), '')))
        FROM @xml.nodes('/') n(el);

        IF NOT EXISTS
        (
            SELECT *
            FROM dbo.t_areafisica (NOLOCK)
            WHERE c_tipo_are = '05'
                  OR c_tipo_are = '10'
                     AND c_codigo_are = @ls_codigo
        )
        BEGIN
            SELECT c_tipo = 'N';
            RETURN;
        END;

        SELECT TOP 1
               c_tipo = sma.c_tipocorrida_sma
        FROM dbo.t_sortingmaduraciondet det (NOLOCK)
            INNER JOIN dbo.t_sortingmaduracion sma (NOLOCK)
                ON sma.c_folio_sma = det.c_folio_sma
                   AND sma.c_codigo_tem = det.c_codigo_tem
                   AND sma.c_codigo_emp = det.c_codigo_emp
        WHERE c_codigo_are = @ls_codigo
              AND c_finvaciado_smd = 'N'
              AND c_activo_smd = '1';

        SET @as_success = 1;
        SET @as_message = 'OK';
    END TRY
    BEGIN CATCH
        SET @as_success = 0;
        SET @as_message = ERROR_MESSAGE();
    END CATCH;
END;

IF @as_operation = 52 /*traer peso y cajas default */
BEGIN
    BEGIN TRY
        SELECT @ls_puntoemp = RTRIM(LTRIM(ISNULL(n.el.value('c_codigo_emp[1]', 'varchar(2)'), ''))),
               @ls_codqr = RTRIM(LTRIM(ISNULL(n.el.value('c_codigo[1]', 'varchar(22)'), '')))
        FROM @xml.nodes('/') n(el);
        SET @tipo = '';

        SELECT @tipo = sma.c_tipocorrida_sma
        FROM dbo.t_sortingmaduracion sma (NOLOCK)
            INNER JOIN dbo.t_paletemporal pal (NOLOCK)
                ON pal.c_codigo_tem = sma.c_codigo_tem
                   AND pal.c_codigo_emp = sma.c_codigo_emp
                   AND sma.c_folio_sma = pal.c_codigo_sma
        WHERE pal.c_codqrtemp_pte = @ls_codqr;

        IF (LEN(@tipo) > 0)
            SELECT n_libras = iLibras,
                   n_cajas = iCajas
            FROM CajasYPesoPorDefault (NOLOCK)
            WHERE idPuntoDeEmpaque = @ls_puntoemp
                  AND idTipoSorteo = @tipo;
        ELSE
            SELECT n_libras = 0,
                   n_cajas = 0;

        SET @as_success = 1;
        SET @as_message = 'OK';
    END TRY
    BEGIN CATCH
        SET @as_success = 0;
        SET @as_message = ERROR_MESSAGE();
    END CATCH;
END;

IF @as_operation = 53 /*traer peso y cajas del producto */
BEGIN
    BEGIN TRY
        SELECT @ls_codigo = RTRIM(LTRIM(ISNULL(n.el.value('c_codigo_pro[1]', 'varchar(10)'), '')))
        FROM @xml.nodes('/') n(el);

        IF EXISTS
        (
            SELECT *
            FROM dbo.t_producto (NOLOCK)
            WHERE c_codigo_pro = @ls_codigo
        )
            SELECT n_bulxpa_pal = n_bulxpa_pro,
                   n_peso_pal = ROUND(n_pesbul_pro * n_bulxpa_pro, 0, 1)
            FROM dbo.t_producto (NOLOCK)
            WHERE c_codigo_pro = @ls_codigo;
        ELSE
            SELECT n_bulxpa_pal = 0,
                   n_peso_pal = 0;

        SET @as_success = 1;
        SET @as_message = 'OK';
    END TRY
    BEGIN CATCH
        SET @as_success = 0;
        SET @as_message = ERROR_MESSAGE();
    END CATCH;
END;

IF @as_operation = 54 /*consultar banda para cargar en Dropdown*/
BEGIN
    BEGIN TRY
        SELECT @ls_temporada = RTRIM(LTRIM(ISNULL(n.el.value('c_codigo_tem[1]', 'varchar(2)'), ''))),
               @ls_puntoemp = RTRIM(LTRIM(ISNULL(n.el.value('c_codigo_emp[1]', 'varchar(2)'), '')))
        FROM @xml.nodes('/') n(el);

        SELECT c_codigo_bnd = ISNULL(c_codigo_bnd, ''),
               v_nombre_bnd = ISNULL(v_nombre_bnd, '')
        FROM dbo.t_banda (NOLOCK)
        WHERE c_activo_bnd = '1';
        /* WHERE c_codigo_bnd NOT IN
              (
                  SELECT DISTINCT
                         det.c_codigo_bnd
                  FROM dbo.t_programa_empaquedet det (NOLOCK)
                      INNER JOIN dbo.t_programa_empaque emp (NOLOCK)
                          ON emp.c_codigo_prq = det.c_codigo_prq
                             AND emp.c_codigo_emp = det.c_codigo_emp
                             AND emp.c_codigo_tem = det.c_codigo_tem
                  WHERE emp.c_corriendo_prq = 'S'
                        AND emp.c_codigo_tem = @ls_temporada
                        AND emp.c_codigo_emp = @ls_puntoemp
              );*/

        SET @as_success = 1;
        SET @as_message = 'OK';
    END TRY
    BEGIN CATCH
        SET @as_success = 0;
        SET @as_message = ERROR_MESSAGE();
    END CATCH;
END;

IF @as_operation = 55 /*consultar reazones para cargar en Dropdown*/
BEGIN
    BEGIN TRY
        SELECT @ls_temporada = RTRIM(LTRIM(ISNULL(n.el.value('c_codigo_tem[1]', 'varchar(2)'), ''))),
               @ls_puntoemp = RTRIM(LTRIM(ISNULL(n.el.value('c_codigo_emp[1]', 'varchar(2)'), '')))
        FROM @xml.nodes('/') n(el);

        SELECT idrazon = idrazon,
               cNombre = cNombre
        FROM t_razones (NOLOCK)
        WHERE bEnOperacion = 1
              AND c_activo_raz = '1';

        SET @as_success = 1;
        SET @as_message = 'OK';
    END TRY
    BEGIN CATCH
        SET @as_success = 0;
        SET @as_message = ERROR_MESSAGE();
    END CATCH;
END;

IF @as_operation = 56 /*informacion de pallets solo para revision*/
BEGIN
    BEGIN TRY
        SELECT @ls_codqr = RTRIM(LTRIM(ISNULL(n.el.value('c_codigo_qr[1]', 'varchar(22)'), ''))),
               @ls_temporada = RTRIM(LTRIM(ISNULL(n.el.value('c_codigo_tem[1]', 'varchar(2)'), ''))),
               @ls_puntoemp = RTRIM(LTRIM(ISNULL(n.el.value('c_codigo_emp[1]', 'varchar(2)'), '')))
        FROM @xml.nodes('/') n(el);

        SELECT TOP 1
               c_codigo_pte = ISNULL(RTRIM(LTRIM(pal.c_codigo_pte)), ''),
               d_totcaja_pte = ISNULL(RTRIM(LTRIM(pal.d_totcaja_pte)), 0),
               d_totkilos_pte = CASE
                                    WHEN ROUND(ISNULL(pub.n_pesoxpal_pub, 0), 0, 1) = 0 THEN
                                        ROUND(ISNULL(pal.d_totkilos_pte, 0), 0, 1)
                                    ELSE
                                        ROUND(ISNULL(pub.n_pesoxpal_pub, 0), 0, 1)
                                END,
               v_nombre_gdm = ISNULL(RTRIM(LTRIM(gma.v_nombre_gdm)), ''),
               c_codigo_are = ISNULL(RTRIM(LTRIM(pal.c_codigo_are)), ''),
               v_nombre_cal = ISNULL(RTRIM(LTRIM(cal.v_nombre_cal)), ''),
               v_ubicacion_pte = ISNULL(are.v_nombre_are, '') + ' - ' + ISNULL(RTRIM(LTRIM(col.c_nomenclatura_col)), '')
                                 + ISNULL(RTRIM(LTRIM(niv.c_nomenclatura_niv)), '')
                                 + ISNULL(RTRIM(LTRIM(pos.c_posicion_pos)), ''),    
               c_codigo_lot = SUBSTRING(pal.c_codigo_sma, 10,4) ,
			   c_codigo_lot2 = lot.c_codigoext_lot,
               /*(
                   SELECT dbo.fn_getBloquebyQrTemporadaEmpaque2(@ls_codqr, @ls_temporada, @ls_puntoemp)
               ),*/
               c_codigo_gma = ISNULL(RTRIM(LTRIM(pal.c_codigo_gma)), '')
        FROM t_paletemporal pal (NOLOCK)
            LEFT JOIN t_gradomaduracion (NOLOCK) gma
                ON gma.c_codigo_gdm = pal.c_codigo_gma
            LEFT JOIN t_calibre (NOLOCK) cal
                ON cal.c_codigo_cal = pal.c_codigo_cal
            LEFT JOIN dbo.t_ubicacionnivel niv (NOLOCK)
                ON niv.c_codigo_niv = pal.c_codigo_niv
            LEFT JOIN dbo.t_ubicacioncolumna col (NOLOCK)
                ON col.c_codigo_col = pal.c_columna_col
            LEFT JOIN t_ubicacionposicion pos (NOLOCK)
                ON pos.c_codigo_pos = pal.c_codigo_pos
            LEFT JOIN t_sortingmaduracion sma (NOLOCK)
                ON pal.c_codigo_sma = sma.c_folio_sma
            LEFT JOIN t_sortingmaduraciondet smadet (NOLOCK)
                ON smadet.c_folio_sma = sma.c_folio_sma
            LEFT JOIN dbo.t_recepciondet red (NOLOCK)
                ON red.c_codigo_rec = smadet.c_codigo_rec
                   AND red.c_secuencia_red = smadet.c_concecutivo_smd
            LEFT JOIN t_palletsubicaciones pub (NOLOCK)
                ON pub.c_codigo_pte = pal.c_codigo_pte
                   AND pub.c_ubiactual_pub = '1'
            LEFT JOIN dbo.t_areafisica are (NOLOCK)
                ON are.c_codigo_are = pal.c_codigo_are
			LEFT JOIN dbo.t_lote lot (NOLOCK) 
				ON SUBSTRING(pal.c_codigo_sma, 10,4) = lot.c_codigo_lot
        WHERE (
                  pal.c_codqrtemp_pte = @ls_codqr
                  OR pal.c_codigo_pte = @ls_codqr
              )
              AND pal.c_codigo_tem = @ls_temporada
              AND pal.c_codigo_emp = @ls_puntoemp
              AND pal.c_activo_dso = '1';

        SET @as_success = 1;
        SET @as_message = 'OK';
    END TRY
    BEGIN CATCH
        SET @as_success = 0;
        SET @as_message = ERROR_MESSAGE();
    END CATCH;
END;

IF @as_operation = 57 /*Listado de palets temporales segun la corrida*/
BEGIN
    BEGIN TRY

        SELECT @ls_codigo = RTRIM(LTRIM(ISNULL(n.el.value('c_codigo_ptc[1]', 'varchar(10)'), ''))),
               @ls_temporada = RTRIM(LTRIM(ISNULL(n.el.value('c_codigo_tem[1]', 'varchar(2)'), ''))),
               @ls_puntoemp = RTRIM(LTRIM(ISNULL(n.el.value('c_codigo_emp[1]', 'varchar(2)'), '')))
        FROM @xml.nodes('/') n(el);

        IF EXISTS
        (
            SELECT *
            FROM dbo.t_paletemporal_consolidado (NOLOCK)
            WHERE c_codigo_tem = @ls_temporada
                  AND c_codigo_emp = @ls_puntoemp
                  AND c_codigo_ptc = @ls_codigo
        )
        BEGIN
            SELECT DISTINCT
                   c_codigo = pal.c_codigo_pte,
                   c_codigo_mad = gdm.v_nombre_gdm,
                   n_cajas_smd = pal.d_totcaja_ptc,
                   n_kilos_smd = pal.d_totkilos_ptc,
                   c_codigo_cal = cal.v_nombre_cal,
                   c_codigo_lot = pal.bloqueid,
                   v_nombre_lot = lot.v_nombre_lot
            FROM dbo.t_paletemporal_consolidado pal (NOLOCK)
                INNER JOIN dbo.t_paletemporal pte (NOLOCK)
                    ON pte.c_codigo_pte = pal.c_codigo_pte
                LEFT JOIN dbo.t_gradomaduracion gdm (NOLOCK)
                    ON gdm.c_codigo_gdm = pte.c_codigo_gma
                LEFT JOIN dbo.t_calibre cal (NOLOCK)
                    ON cal.c_codigo_cal = pte.c_codigo_cal
                LEFT JOIN dbo.t_lote lot (NOLOCK)
                    ON lot.c_codigo_lot = pal.bloqueid
            WHERE pal.c_codigo_tem = @ls_temporada
                  AND pal.c_codigo_ptc = @ls_codigo
                  AND pal.c_codigo_emp = @ls_puntoemp;

        END;
        ELSE
        BEGIN
            SET @as_success = 1;
            SET @as_message = 'No existen pallets relacionados. Favor de revisar';
        END;

        SET @as_success = 1;
        SET @as_message = 'OK';
    END TRY
    BEGIN CATCH
        SET @as_success = 0;
        SET @as_message = ERROR_MESSAGE();
    END CATCH;
END;


IF @as_operation = 58 /*Listado de palets temporales segun la corrida*/
BEGIN
    BEGIN TRY

        SELECT @ls_codigo = RTRIM(LTRIM(ISNULL(n.el.value('c_codigo_ptc[1]', 'varchar(10)'), ''))),
               @ls_temporada = RTRIM(LTRIM(ISNULL(n.el.value('c_codigo_tem[1]', 'varchar(2)'), ''))),
               @ls_puntoemp = RTRIM(LTRIM(ISNULL(n.el.value('c_codigo_emp[1]', 'varchar(2)'), '')))
        FROM @xml.nodes('/') n(el);

        IF EXISTS
        (
            SELECT *
            FROM dbo.t_paletemporal_consolidado (NOLOCK)
            WHERE c_codigo_tem = @ls_temporada
                  AND c_codigo_emp = @ls_puntoemp
                  AND c_codigo_ptc = @ls_codigo
        )
        BEGIN
            SELECT DISTINCT
                   c_codigo_lot = pal.bloqueid,
                   v_nombre_lot = lot.v_nombre_lot
            FROM dbo.t_paletemporal_consolidado pal (NOLOCK)
                INNER JOIN dbo.t_paletemporal pte (NOLOCK)
                    ON pte.c_codigo_pte = pal.c_codigo_pte
                LEFT JOIN dbo.t_gradomaduracion gdm (NOLOCK)
                    ON gdm.c_codigo_gdm = pte.c_codigo_gma
                LEFT JOIN dbo.t_calibre cal (NOLOCK)
                    ON cal.c_codigo_cal = pte.c_codigo_cal
                LEFT JOIN dbo.t_lote lot (NOLOCK)
                    ON lot.c_codigo_lot = pal.bloqueid
            WHERE pal.c_codigo_tem = @ls_temporada
                  AND pal.c_codigo_ptc = @ls_codigo
                  AND pal.c_codigo_emp = @ls_puntoemp;
        END;
        ELSE
        BEGIN
            SET @as_success = 1;
            SET @as_message = 'No existen pallets relacionados. Favor de revisar';
        END;

        SET @as_success = 1;
        SET @as_message = 'OK';
    END TRY
    BEGIN CATCH
        SET @as_success = 0;
        SET @as_message = ERROR_MESSAGE();
    END CATCH;
END;



IF @as_operation = 59 /*PARAMETROS DE APP*/
BEGIN
    BEGIN TRY

        SELECT @ls_codigo = RTRIM(LTRIM(ISNULL(n.el.value('c_codigo_par[1]', 'varchar(3)'), '')))
        FROM @xml.nodes('/') n(el);

        SELECT TOP 1
               c_codigo_par,
               v_nombre_par,
               v_valor_par = ISNULL(v_valor_par, '')
        FROM App_EmpaqueParametros (NOLOCK)
        WHERE ISNULL(c_codigo_par, '') LIKE @ls_codigo;


        SET @as_success = 1;
        SET @as_message = 'OK';
    END TRY
    BEGIN CATCH
        SET @as_success = 0;
        SET @as_message = ERROR_MESSAGE();
    END CATCH;
END;

IF @as_operation = 60 /*Consulta de palet virtuales concentrada*/
BEGIN
    BEGIN TRY

        SELECT @ls_temporada = RTRIM(LTRIM(ISNULL(n.el.value('c_codigo_tem[1]', 'varchar(2)'), ''))),
               @ls_puntoemp = RTRIM(LTRIM(ISNULL(n.el.value('c_codigo_emp[1]', 'varchar(2)'), ''))),
               @ls_codigo = RTRIM(LTRIM(ISNULL(n.el.value('c_codigo_pal[1]', 'varchar(10)'), ''))),
               @codsec = RTRIM(LTRIM(ISNULL(n.el.value('c_codsec_pal[1]', 'varchar(2)'), ''))),
               @ls_tipo = RTRIM(LTRIM(ISNULL(n.el.value('c_tipo[1]', 'varchar(2)'), '')))
        FROM @xml.nodes('/') n(el);

        SELECT c_codigo_tem = tb_vir.c_codigo_tem,
               c_codigo_emp = tb_vir.c_codigo_emp,
               c_codigo = tb_vir.c_codigo,
               c_codigo_pal = tb_vir.c_codigo_pal,
               c_codsec_pal = tb_vir.c_codsec_pal,
               c_tipo_pal = tb_vir.c_tipo_pal,
               d_empaque_pal = tb_vir.d_empaque_pal,
               c_hora_pal = tb_vir.c_hora_pal,
               c_codigo_sel = tb_vir.c_codigo_sel,
               c_codigo_bnd = tb_vir.c_codigo_bnd,
               c_codigo_lot = tb_vir.c_codigo_lot,
               v_nombre_lot = tb_vir.v_nombre_lot,
               c_codigo_cul = tb_vir.c_codigo_cul,
               v_nombre_cul = tb_vir.v_nombre_cul,
               c_codigo_pro = tb_vir.c_codigo_pro,
               v_nombre_pro = tb_vir.v_nombre_pro,
               c_codigo_eti = tb_vir.c_codigo_eti,
               v_nombre_eti = tb_vir.v_nombre_eti,
               c_codigo_col = tb_vir.c_codigo_col,
               v_nombre_col = tb_vir.v_nombre_col,
               c_codigo_env = tb_vir.c_codigo_env,
               v_nombre_env = tb_vir.v_nombre_env,
               v_nombre_tam = tb_vir.v_nombre_tam,
               n_bulxpa_pal = tb_vir.n_bulxpa_pal,
               n_peso_pme = tb_vir.n_peso_pme,
               c_codigo_usu = tb_vir.c_codigo_usu,
               d_creacion = tb_vir.d_creacion,
               c_usumod = tb_vir.c_usumod,
               d_modifi = tb_vir.d_modifi,
               c_activo = tb_vir.c_activo,
               n_totalbulxpa_pme = tb_vir.n_totalbulxpa_pme,
               n_totalpeso_pme = tb_vir.n_totalpeso_pme,
               c_terminal_pme = tb_vir.c_terminal_pme
        FROM
        (
            SELECT ROW_NUMBER() OVER (PARTITION BY RTRIM(LTRIM(ISNULL(pal.c_codigo_tem, ''))),
                                                   RTRIM(LTRIM(ISNULL(pal.c_codigo_emp, ''))),
                                                   RTRIM(LTRIM(ISNULL(pal.c_codigo_pme, '')))
                                      ORDER BY RTRIM(LTRIM(ISNULL(pal.c_codigo_tem, ''))) ASC,
                                               RTRIM(LTRIM(ISNULL(pal.c_codigo_emp, ''))) ASC,
                                               RTRIM(LTRIM(ISNULL(pal.c_codigo_pme, ''))) ASC,
                                               RTRIM(LTRIM(ISNULL(pal.c_codsec_pme, ''))) ASC
                                     ) AS Rowpal,
                   c_codigo_tem = RTRIM(LTRIM(ISNULL(pal.c_codigo_tem, ''))),
                   c_codigo_emp = RTRIM(LTRIM(ISNULL(pal.c_codigo_emp, ''))),
                   c_codigo = RTRIM(LTRIM(ISNULL(pal.c_codigo_pme, ''))),
                   c_codigo_pal = RTRIM(LTRIM(ISNULL(pal.c_codigo_pal, ''))),
                   c_codsec_pal = RTRIM(LTRIM(ISNULL(pal.c_codsec_pme, ''))),
                   c_tipo_pal = RTRIM(LTRIM(ISNULL(pal.c_tipo_pme, ''))),
                   d_empaque_pal = pal.d_empaque_pme,
                   c_hora_pal = pal.c_hora_pme,
                   c_codigo_sel = RTRIM(LTRIM(ISNULL(pal.c_codigo_sel, ''))),
                   c_codigo_bnd = RTRIM(LTRIM(ISNULL(pal.c_codigo_bnd, ''))),
                   c_codigo_lot = RTRIM(LTRIM(ISNULL(pal.c_codigo_lot, ''))),
                   v_nombre_lot = RTRIM(LTRIM(ISNULL(lot.v_nombre_lot, ''))),
                   c_codigo_cul = RTRIM(LTRIM(ISNULL(pro.c_codigo_cul, ''))),
                   v_nombre_cul = RTRIM(LTRIM(ISNULL(cul.v_nombre_cul, ''))),
                   c_codigo_pro = RTRIM(LTRIM(ISNULL(pal.c_codigo_pro, ''))),
                   v_nombre_pro = RTRIM(LTRIM(ISNULL(pro.v_nombre_pro, ''))),
                   c_codigo_eti = RTRIM(LTRIM(ISNULL(pal.c_codigo_eti, ''))),
                   v_nombre_eti = RTRIM(LTRIM(ISNULL(eti.v_nombre_eti, ''))),
                   c_codigo_col = RTRIM(LTRIM(ISNULL(pal.c_codigo_col, ''))),
                   v_nombre_col = RTRIM(LTRIM(ISNULL(col.v_nombre_col, ''))),
                   c_codigo_env = RTRIM(LTRIM(ISNULL(pal.c_codigo_env, ''))),
                   v_nombre_env = RTRIM(LTRIM(ISNULL(env.v_nombre_env, ''))),
                   v_nombre_tam = RTRIM(LTRIM(ISNULL(tam.v_nombre_tam, ''))),
                   n_bulxpa_pal = ISNULL(pal.n_bulxpa_pme, 0.00),
                   n_peso_pme = ISNULL(pal.n_peso_pme, 0.00),
                   c_codigo_usu = RTRIM(LTRIM(ISNULL(pal.c_codigo_usu, ''))),
                   d_creacion = pal.d_creacion_pme,
                   c_usumod = RTRIM(LTRIM(ISNULL(pal.c_usumod_pme, ''))),
                   d_modifi = pal.d_modifi_pme,
                   c_activo = RTRIM(LTRIM(ISNULL(pal.c_activo_pme, ''))),
                   n_totalbulxpa_pme = tot.n_totalbulxpa_pme,
                   n_totalpeso_pme = tot.n_totalpeso_pme,
                   c_terminal_pme = pal.c_terminal_pme
            FROM t_palet_multiestiba pal (NOLOCK)
                LEFT JOIN t_lote lot (NOLOCK)
                    ON lot.c_codigo_tem = pal.c_codigo_tem
                       AND lot.c_codigo_lot = pal.c_codigo_lot
                LEFT JOIN t_producto pro (NOLOCK)
                    ON pal.c_codigo_pro = pro.c_codigo_pro
                LEFT JOIN t_cultivo cul (NOLOCK)
                    ON cul.c_codigo_cul = pro.c_codigo_cul
                LEFT JOIN t_etiqueta eti (NOLOCK)
                    ON eti.c_codigo_eti = pal.c_codigo_eti
                LEFT JOIN t_color col (NOLOCK)
                    ON col.c_codigo_col = pal.c_codigo_col
                LEFT JOIN t_envase env (NOLOCK)
                    ON env.c_codigo_env = pal.c_codigo_env
                LEFT JOIN t_tamanio tam (NOLOCK)
                    ON tam.c_codigo_tam = pal.c_codigo_tam
                LEFT JOIN
                (
                    SELECT c_codigo_tem = palvir.c_codigo_tem,
                           c_codigo_emp = palvir.c_codigo_emp,
                           c_codigo_pme = palvir.c_codigo_pme,
                           n_totalbulxpa_pme = SUM(palvir.n_bulxpa_pme),
                           n_totalpeso_pme = SUM(palvir.n_peso_pme)
                    FROM dbo.t_palet_multiestiba palvir (NOLOCK)
                    GROUP BY palvir.c_codigo_tem,
                             palvir.c_codigo_emp,
                             palvir.c_codigo_pme
                ) tot
                    ON tot.c_codigo_tem = pal.c_codigo_tem
                       AND tot.c_codigo_emp = pal.c_codigo_emp
                       AND tot.c_codigo_pme = pal.c_codigo_pme
            WHERE 1 = 1
                  AND ISNULL(pal.c_codigo_tem, '') LIKE @ls_temporada
                  AND ISNULL(pal.c_codigo_emp, '') LIKE @ls_puntoemp
                  /* AND ISNULL(pal.c_activo_pme, '1') = '1'*/
                  AND pal.c_codigo_pme LIKE @ls_codigo
                  AND RTRIM(LTRIM(ISNULL(pal.c_codsec_pme, ''))) LIKE @codsec
                  AND
                  (
                      (
                          'N' = @ls_tipo
                          AND RTRIM(LTRIM(ISNULL(pal.c_codigo_pal, ''))) = ''
                      )
                      OR
                      (
                          'S' = @ls_tipo
                          AND RTRIM(LTRIM(ISNULL(pal.c_codigo_pal, ''))) <> ''
                      )
                      OR
                      (
                          'A' = @ls_tipo
                          AND RTRIM(LTRIM(ISNULL(pal.c_activo_pme, '0'))) = '0'
                          AND RTRIM(LTRIM(ISNULL(pal.c_codigo_pal, ''))) = ''
                      )
                      OR ('T' = @ls_tipo)
                  )
        ) tb_vir
        WHERE tb_vir.Rowpal = 1
        ORDER BY c_codigo DESC,
                 c_codsec_pal;
        SET @as_success = 1;
        SET @as_message = 'OK';
    END TRY
    BEGIN CATCH
        SET @as_success = 0;
        SET @as_message = ERROR_MESSAGE();
    END CATCH;
END;

IF @as_operation = 61 /*CONSULTA DE punto de empaque sin origen*/
BEGIN
    BEGIN TRY
        /*SACAMOS LOS DATOS  DEL JSON*/
        SELECT @ls_puntoemp = RTRIM(LTRIM(ISNULL(n.el.value('c_codigo_pem[1]', 'varchar(2)'), '')))
        FROM @xml.nodes('/') n(el);

        SELECT c_codigo_pem,
               v_nombre_pem,
               v_codigoaux_pem
        FROM dbo.t_puntoempaque (NOLOCK)
        WHERE c_codigo_pem <> @ls_puntoemp;
        SET @as_success = 1;
        SET @as_message = 'OK';
    END TRY
    BEGIN CATCH
        SET @as_success = 0;
        SET @as_message = ERROR_MESSAGE();
    END CATCH;
END;

IF @as_operation = 62 /*Listado de pallets en trasperencia estatus "C","P" y "E" */
BEGIN
    BEGIN TRY
	DECLARE	@transferencia INT = 0 , @estatus VARCHAR(1) = ''
        /*SACAMOS LOS DATOS  DEL JSON*/
        SELECT @ls_puntoemp = RTRIM(LTRIM(ISNULL(n.el.value('c_codigo_pem[1]', 'varchar(2)'),''))),
			   @ls_empaque2 = RTRIM(LTRIM(ISNULL(n.el.value('c_codigo_pem2[1]', 'varchar(2)'),''))),
			   @estatus = RTRIM(LTRIM(ISNULL(n.el.value('c_estatus_pta[1]', 'varchar(1)'),''))),
			   @transferencia = RTRIM(LTRIM(ISNULL(n.el.value('n_idfolio_pta[1]', 'varchar(20)'),''))),
			   @tipo = RTRIM(LTRIM(ISNULL(n.el.value('c_tipo[1]', 'varchar(1)'),'')))
        FROM @xml.nodes('/') n(el);

		SELECT c_IdPallet_ptad = det.c_IdPallet_ptad,
				v_nombre_gdm = LTRIM(RTRIM(gma.v_nombre_gdm)),
				v_nombre_cal = LTRIM(RTRIM(cal.v_nombre_cal)),
				n_peso_ptad = det.n_peso_ptad,
				n_idfolio_pta = LTRIM(RTRIM(det.n_idfolio_pta)),
				c_codigo_usu = LTRIM(RTRIM(tra.c_codigo_usu)),
				c_origen = emp.v_nombre_pem,
				c_destino = emp2.v_nombre_pem,
				c_traspasado_ptad = ISNULL(det.c_traspasado_ptad,'0')
		FROM dbo.t_pallet_traspaso_app_det det (NOLOCK) 
		INNER JOIN dbo.t_pallet_traspaso_app tra (NOLOCK) ON tra.n_idfolio_pta = det.n_idfolio_pta
		LEFT JOIN dbo.t_gradomaduracion gma (NOLOCK) ON gma.c_codigo_gdm = det.c_codigo_gma
		LEFT JOIN dbo.t_calibre cal (NOLOCK) ON cal.c_codigo_cal = det.c_codigo_cal
		LEFT JOIN  dbo.t_puntoempaque emp (NOLOCK) ON emp.c_codigo_pem = tra.c_AlmacenQueEnvia_pta 
		LEFT JOIN  dbo.t_puntoempaque emp2 (NOLOCK) ON emp2.c_codigo_pem = tra.c_AlmacenQueRecibe_pta 
		WHERE tra.c_AlmacenQueEnvia_pta = @ls_puntoemp
		AND tra.c_AlmacenQueRecibe_pta = @ls_empaque2
		AND tra.c_Estatus_pta = @estatus
		AND @tipo = 'T'
		And (@transferencia = 0 OR tra.n_idfolio_pta = @transferencia)

		UNION ALL 

		SELECT c_IdPallet_ptad = det.c_IdPallet_ptad,
				v_nombre_gdm = LTRIM(RTRIM(gma.v_nombre_gdm)),
				v_nombre_cal = LTRIM(RTRIM(cal.v_nombre_cal)),
				n_peso_ptad = det.n_peso_ptad,
				n_idfolio_pta = LTRIM(RTRIM(det.n_idfolio_pta)),
				c_codigo_usu = LTRIM(RTRIM(tra.c_codigo_usu)),
				c_origen = emp.v_nombre_pem,
				c_destino = emp2.v_nombre_pem,
				c_traspasado_ptad = ISNULL(det.c_traspasado_ptad,'0')
		FROM dbo.t_pallet_traspaso_app_det det (NOLOCK) 
		INNER JOIN dbo.t_pallet_traspaso_app tra (NOLOCK) ON tra.n_idfolio_pta = det.n_idfolio_pta
		LEFT JOIN dbo.t_gradomaduracion gma (NOLOCK) ON gma.c_codigo_gdm = det.c_codigo_gma
		LEFT JOIN dbo.t_calibre cal (NOLOCK) ON cal.c_codigo_cal = det.c_codigo_cal
		LEFT JOIN  dbo.t_puntoempaque emp (NOLOCK) ON emp.c_codigo_pem = tra.c_AlmacenQueEnvia_pta 
		LEFT JOIN  dbo.t_puntoempaque emp2 (NOLOCK) ON emp2.c_codigo_pem = tra.c_AlmacenQueRecibe_pta 
		WHERE tra.c_AlmacenQueEnvia_pta = @ls_empaque2
		AND tra.c_AlmacenQueRecibe_pta =  @ls_puntoemp
		AND tra.c_Estatus_pta = @estatus
		AND @tipo = 'R'
		And (@transferencia = 0 OR tra.n_idfolio_pta = @transferencia)

        SET @as_success = 1;
        SET @as_message = 'OK';
    END TRY
    BEGIN CATCH
        SET @as_success = 0;
        SET @as_message = ERROR_MESSAGE();
    END CATCH;
END;

IF @as_operation = 63 /*informacion de pallets solo para revision trasferencias y recepciones de tranferencias*/
BEGIN
    BEGIN TRY
        SELECT @ls_codqr = RTRIM(LTRIM(ISNULL(n.el.value('c_codigo_qr[1]', 'varchar(22)'), ''))),
               @ls_temporada = RTRIM(LTRIM(ISNULL(n.el.value('c_codigo_tem[1]', 'varchar(2)'), ''))),
               @ls_puntoemp = RTRIM(LTRIM(ISNULL(n.el.value('c_codigo_emp[1]', 'varchar(2)'), ''))),
			   @tipo = RTRIM(LTRIM(ISNULL(n.el.value('c_tipo[1]', 'varchar(2)'), '')))
        FROM @xml.nodes('/') n(el);

        SELECT DISTINCT TOP 1 /*pallet temporal */
               c_codigo_pte = ISNULL(RTRIM(LTRIM(pal.c_codigo_pte)), ''),
               d_totcaja_pte = ISNULL(RTRIM(LTRIM(pal.d_totcaja_pte)), 0),
               d_totkilos_pte = CASE
                                    WHEN ROUND(ISNULL(pub.n_pesoxpal_pub, 0), 0, 1) = 0 THEN
                                        ROUND(ISNULL(pal.d_totkilos_pte, 0), 0, 1)
                                    ELSE
                                        ROUND(ISNULL(pub.n_pesoxpal_pub, 0), 0, 1)
                                END,
               v_nombre_gdm = ISNULL(RTRIM(LTRIM(gma.v_nombre_gdm)), ''),
               c_codigo_are = ISNULL(RTRIM(LTRIM(pal.c_codigo_are)), ''),
               v_nombre_cal = ISNULL(RTRIM(LTRIM(cal.v_nombre_cal)), ''),
               v_ubicacion_pte = ISNULL(are.v_nombre_are, '') + ' - ' + ISNULL(RTRIM(LTRIM(col.c_nomenclatura_col)), '')
                                 + ISNULL(RTRIM(LTRIM(niv.c_nomenclatura_niv)), '')
                                 + ISNULL(RTRIM(LTRIM(pos.c_posicion_pos)), ''),    
               c_codigo_lot = SUBSTRING(pal.c_codigo_sma, 10,4) ,
			   c_codigo_lot2 = lot.c_codigoext_lot,
               c_codigo_gma = ISNULL(RTRIM(LTRIM(pal.c_codigo_gma)), ''),
			   c_activo = pal.c_activo_dso ,
			   c_corrida = ISNULL((SELECT TOP 1 c_folio_sma FROM dbo.t_sortingmaduraciondet WHERE c_codigo_pal =pal.c_codigo_pte),'') ,
			   c_finalizado = pal.c_finalizado_pte
        FROM t_paletemporal pal (NOLOCK)
            LEFT JOIN t_gradomaduracion (NOLOCK) gma
                ON gma.c_codigo_gdm = pal.c_codigo_gma
            LEFT JOIN t_calibre (NOLOCK) cal
                ON cal.c_codigo_cal = pal.c_codigo_cal
            LEFT JOIN dbo.t_ubicacionnivel niv (NOLOCK)
                ON niv.c_codigo_niv = pal.c_codigo_niv
            LEFT JOIN dbo.t_ubicacioncolumna col (NOLOCK)
                ON col.c_codigo_col = pal.c_columna_col
            LEFT JOIN t_ubicacionposicion pos (NOLOCK)
                ON pos.c_codigo_pos = pal.c_codigo_pos
            LEFT JOIN t_sortingmaduracion sma (NOLOCK)
                ON pal.c_codigo_sma = sma.c_folio_sma
            LEFT JOIN t_sortingmaduraciondet smadet (NOLOCK)
                ON smadet.c_folio_sma = sma.c_folio_sma
            LEFT JOIN dbo.t_recepciondet red (NOLOCK)
                ON red.c_codigo_rec = smadet.c_codigo_rec
                   AND red.c_secuencia_red = smadet.c_concecutivo_smd
            LEFT JOIN t_palletsubicaciones pub (NOLOCK)
                ON pub.c_codigo_pte = pal.c_codigo_pte
                   AND pub.c_ubiactual_pub = '1'
            LEFT JOIN dbo.t_areafisica are (NOLOCK)
                ON are.c_codigo_are = pal.c_codigo_are
			LEFT JOIN dbo.t_lote lot (NOLOCK) 
				ON SUBSTRING(pal.c_codigo_sma, 10,4) = lot.c_codigo_lot
        WHERE (
                  pal.c_codqrtemp_pte = @ls_codqr
                  OR pal.c_codigo_pte = @ls_codqr
              )
              AND pal.c_codigo_tem = @ls_temporada
              AND pal.c_codigo_emp = @ls_puntoemp
			  AND pal.c_activo_dso = '1'
			  AND @tipo = 'T'
		UNION ALL 

		SELECT DISTINCT TOP 1/*Pallet real de eyeplus */
               c_codigo_pte = ISNULL(RTRIM(LTRIM(pal.c_codigo_pal)), ''),
               d_totcaja_pte = ISNULL(RTRIM(LTRIM(pal.n_bulxpa_pal)), 0),
               d_totkilos_pte = pal.n_peso_pal,
               v_nombre_gdm = ISNULL(RTRIM(LTRIM(gma.v_nombre_gdm)), ''),
               c_codigo_are = ISNULL(RTRIM(LTRIM(pal.c_codigo_are)), ''),
               v_nombre_cal = ISNULL(RTRIM(LTRIM(cal.v_nombre_cal)), ''),
               v_ubicacion_pte = ISNULL(are.v_nombre_are, '') + ' - ' + ISNULL(RTRIM(LTRIM(col.c_nomenclatura_col)), '')
                                 + ISNULL(RTRIM(LTRIM(niv.c_nomenclatura_niv)), '')
                                 + ISNULL(RTRIM(LTRIM(pos.c_posicion_pos)), ''),    
               c_codigo_lot = lot.c_codigo_lot ,
			   c_codigo_lot2 = lot.c_codigoext_lot,
               c_codigo_gma = ISNULL(RTRIM(LTRIM(gma.c_codigo_gdm)), ''),
			   c_activo = pal.c_activo_pal ,
			   c_corrida = '' ,
			   c_finalizado = ''
        FROM dbo.t_palet pal (NOLOCK)
            LEFT JOIN t_gradomaduracion (NOLOCK) gma
                ON gma.c_codigo_gdm = '0000'
            LEFT JOIN t_calibre (NOLOCK) cal
                ON cal.c_codigo_cal = '0000'
            LEFT JOIN dbo.t_ubicacionnivel niv (NOLOCK)
                ON niv.c_codigo_niv = pal.c_codigo_niv
            LEFT JOIN dbo.t_ubicacioncolumna col (NOLOCK)
                ON col.c_codigo_col = pal.c_columna_col
            LEFT JOIN t_ubicacionposicion pos (NOLOCK)
                ON pos.c_codigo_pos = pal.c_codigo_pos
            LEFT JOIN dbo.t_areafisica are (NOLOCK)
                ON are.c_codigo_are = pal.c_codigo_are
			LEFT JOIN dbo.t_lote lot (NOLOCK) 
				ON pal.c_codigo_lot= lot.c_codigo_lot
        WHERE pal.c_codigo_pal = @ls_codqr
              AND pal.c_codigo_tem = @ls_temporada
              AND pal.c_codigo_emp = @ls_puntoemp
			  AND pal.c_activo_pal = '1'
			  AND @tipo = 'T'

		UNION ALL	

		SELECT DISTINCT TOP 1/*recepciones y tagsid*/
               c_codigo_pte = ISNULL(RTRIM(LTRIM(pal.c_codigo_rec)), '')+ISNULL(RTRIM(LTRIM(pal.c_secuencia_red)), ''),
               d_totcaja_pte = ISNULL(RTRIM(LTRIM(pal.n_cajas_ocd)), 0),
               d_totkilos_pte = pal.n_kilos_red,
               v_nombre_gdm = ISNULL(RTRIM(LTRIM(gma.v_nombre_gdm)), ''),
               c_codigo_are = '',
               v_nombre_cal = ISNULL(RTRIM(LTRIM(cal.v_nombre_cal)), ''),
               v_ubicacion_pte = '',    
               c_codigo_lot = lot.c_codigo_lot ,
			   c_codigo_lot2 = lot.c_codigoext_lot,
               c_codigo_gma = ISNULL(RTRIM(LTRIM(gma.c_codigo_gdm)), ''),
			   c_activo = pal.c_activo_red ,
			   c_corrida = '' ,
			   c_finalizado = ''
        FROM dbo.t_recepciondet pal (NOLOCK)
            LEFT JOIN t_gradomaduracion (NOLOCK) gma
                ON gma.c_codigo_gdm = '0000'
            LEFT JOIN t_calibre (NOLOCK) cal
                ON cal.c_codigo_cal = '0000'
            LEFT JOIN dbo.t_ubicacionnivel niv (NOLOCK)
                ON niv.c_codigo_niv = pal.c_codigo_niv
            LEFT JOIN dbo.t_ubicacioncolumna col (NOLOCK)
                ON col.c_codigo_col = pal.c_columna_col
            LEFT JOIN t_ubicacionposicion pos (NOLOCK)
                ON pos.c_codigo_pos = pal.c_codigo_pos
			LEFT JOIN dbo.t_lote lot (NOLOCK) 
				ON pal.c_codigo_lot= lot.c_codigo_lot
        WHERE (pal.c_codigo_rec+pal.c_secuencia_red = @ls_codqr OR pal.c_codexterno_rec = @ls_codqr)
              AND pal.c_codigo_tem = @ls_temporada
              AND pal.c_codigo_pem = @ls_puntoemp
			  AND pal.c_activo_red = '1'
			  AND @tipo = 'T'

		UNION ALL /************************************************************************/

		SELECT DISTINCT TOP 1/*recepciones de transferencias de pallet temporales */
               c_codigo_pte = ISNULL(RTRIM(LTRIM(pal.c_codigo_pte)), ''),
               d_totcaja_pte = ISNULL(RTRIM(LTRIM(pal.d_totcaja_pte)), 0),
               d_totkilos_pte = CASE
                                    WHEN ROUND(ISNULL(pub.n_pesoxpal_pub, 0), 0, 1) = 0 THEN
                                        ROUND(ISNULL(pal.d_totkilos_pte, 0), 0, 1)
                                    ELSE
                                        ROUND(ISNULL(pub.n_pesoxpal_pub, 0), 0, 1)
                                END,
               v_nombre_gdm = ISNULL(RTRIM(LTRIM(gma.v_nombre_gdm)), ''),
               c_codigo_are = ISNULL(RTRIM(LTRIM(pal.c_codigo_are)), ''),
               v_nombre_cal = ISNULL(RTRIM(LTRIM(cal.v_nombre_cal)), ''),
               v_ubicacion_pte = ISNULL(are.v_nombre_are, '') + ' - ' + ISNULL(RTRIM(LTRIM(col.c_nomenclatura_col)), '')
                                 + ISNULL(RTRIM(LTRIM(niv.c_nomenclatura_niv)), '')
                                 + ISNULL(RTRIM(LTRIM(pos.c_posicion_pos)), ''),    
               c_codigo_lot = SUBSTRING(pal.c_codigo_sma, 10,4) ,
			   c_codigo_lot2 = lot.c_codigoext_lot,
               c_codigo_gma = ISNULL(RTRIM(LTRIM(pal.c_codigo_gma)), ''),
			   c_activo = pal.c_activo_dso ,
			   c_corrida = ISNULL((SELECT TOP 1 c_folio_sma FROM dbo.t_sortingmaduraciondet WHERE c_codigo_pal =pal.c_codigo_pte),'') ,
			   c_finalizado = pal.c_finalizado_pte
        FROM t_paletemporal pal (NOLOCK)
            LEFT JOIN t_gradomaduracion (NOLOCK) gma
                ON gma.c_codigo_gdm = pal.c_codigo_gma
            LEFT JOIN t_calibre (NOLOCK) cal
                ON cal.c_codigo_cal = pal.c_codigo_cal
            LEFT JOIN dbo.t_ubicacionnivel niv (NOLOCK)
                ON niv.c_codigo_niv = pal.c_codigo_niv
            LEFT JOIN dbo.t_ubicacioncolumna col (NOLOCK)
                ON col.c_codigo_col = pal.c_columna_col
            LEFT JOIN t_ubicacionposicion pos (NOLOCK)
                ON pos.c_codigo_pos = pal.c_codigo_pos
            LEFT JOIN t_sortingmaduracion sma (NOLOCK)
                ON pal.c_codigo_sma = sma.c_folio_sma
            LEFT JOIN t_sortingmaduraciondet smadet (NOLOCK)
                ON smadet.c_folio_sma = sma.c_folio_sma
            LEFT JOIN dbo.t_recepciondet red (NOLOCK)
                ON red.c_codigo_rec = smadet.c_codigo_rec
                   AND red.c_secuencia_red = smadet.c_concecutivo_smd
            LEFT JOIN t_palletsubicaciones pub (NOLOCK)
                ON pub.c_codigo_pte = pal.c_codigo_pte
                   AND pub.c_ubiactual_pub = '1'
            LEFT JOIN dbo.t_areafisica are (NOLOCK)
                ON are.c_codigo_are = pal.c_codigo_are
			LEFT JOIN dbo.t_lote lot (NOLOCK) 
				ON SUBSTRING(pal.c_codigo_sma, 10,4) = lot.c_codigo_lot
        WHERE (
                  pal.c_codqrtemp_pte = @ls_codqr
                  OR pal.c_codigo_pte = @ls_codqr
              )
              AND pal.c_codigo_tem = @ls_temporada
              AND pal.c_codigo_emp = '99'
			  AND @tipo = 'R'

		UNION ALL 

		SELECT DISTINCT TOP 1/*recepciones de transferencias de Pallet real de eyeplus */
               c_codigo_pte = ISNULL(RTRIM(LTRIM(pal.c_codigo_pal)), ''),
               d_totcaja_pte = ISNULL(RTRIM(LTRIM(pal.n_bulxpa_pal)), 0),
               d_totkilos_pte = pal.n_peso_pal,
               v_nombre_gdm = ISNULL(RTRIM(LTRIM(gma.v_nombre_gdm)), ''),
               c_codigo_are = ISNULL(RTRIM(LTRIM(pal.c_codigo_are)), ''),
               v_nombre_cal = ISNULL(RTRIM(LTRIM(cal.v_nombre_cal)), ''),
               v_ubicacion_pte = ISNULL(are.v_nombre_are, '') + ' - ' + ISNULL(RTRIM(LTRIM(col.c_nomenclatura_col)), '')
                                 + ISNULL(RTRIM(LTRIM(niv.c_nomenclatura_niv)), '')
                                 + ISNULL(RTRIM(LTRIM(pos.c_posicion_pos)), ''),    
               c_codigo_lot = lot.c_codigo_lot ,
			   c_codigo_lot2 = lot.c_codigoext_lot,
               c_codigo_gma = ISNULL(RTRIM(LTRIM(gma.c_codigo_gdm)), ''),
			   c_activo = pal.c_activo_pal ,
			   c_corrida = '' ,
			   c_finalizado = ''
        FROM dbo.t_palet pal (NOLOCK)
            LEFT JOIN t_gradomaduracion (NOLOCK) gma
                ON gma.c_codigo_gdm = '0000'
            LEFT JOIN t_calibre (NOLOCK) cal
                ON cal.c_codigo_cal = '0000'
            LEFT JOIN dbo.t_ubicacionnivel niv (NOLOCK)
                ON niv.c_codigo_niv = pal.c_codigo_niv
            LEFT JOIN dbo.t_ubicacioncolumna col (NOLOCK)
                ON col.c_codigo_col = pal.c_columna_col
            LEFT JOIN t_ubicacionposicion pos (NOLOCK)
                ON pos.c_codigo_pos = pal.c_codigo_pos
            LEFT JOIN dbo.t_areafisica are (NOLOCK)
                ON are.c_codigo_are = pal.c_codigo_are
			LEFT JOIN dbo.t_lote lot (NOLOCK) 
				ON pal.c_codigo_lot= lot.c_codigo_lot
        WHERE pal.c_codigo_pal = @ls_codqr
              AND pal.c_codigo_tem = @ls_temporada
              AND pal.c_codigo_emp = '99'
			  AND pal.c_activo_pal = '1'
			  AND @tipo = 'R'

		UNION ALL	

		SELECT DISTINCT TOP 1/*recepciones de transferencias de recepciones y tagsid*/
               c_codigo_pte = ISNULL(RTRIM(LTRIM(pal.c_codigo_rec)), '')+ISNULL(RTRIM(LTRIM(pal.c_secuencia_red)), ''),
               d_totcaja_pte = ISNULL(RTRIM(LTRIM(pal.n_cajas_ocd)), 0),
               d_totkilos_pte = pal.n_kilos_red,
               v_nombre_gdm = ISNULL(RTRIM(LTRIM(gma.v_nombre_gdm)), ''),
               c_codigo_are = '',
               v_nombre_cal = ISNULL(RTRIM(LTRIM(cal.v_nombre_cal)), ''),
               v_ubicacion_pte = '',    
               c_codigo_lot = lot.c_codigo_lot ,
			   c_codigo_lot2 = lot.c_codigoext_lot,
               c_codigo_gma = ISNULL(RTRIM(LTRIM(gma.c_codigo_gdm)), ''),
			   c_activo = pal.c_activo_red ,
			   c_corrida = '' ,
			   c_finalizado = ''
        FROM dbo.t_recepciondet pal (NOLOCK)
            LEFT JOIN t_gradomaduracion (NOLOCK) gma
                ON gma.c_codigo_gdm = '0000'
            LEFT JOIN t_calibre (NOLOCK) cal
                ON cal.c_codigo_cal = '0000'
            LEFT JOIN dbo.t_ubicacionnivel niv (NOLOCK)
                ON niv.c_codigo_niv = pal.c_codigo_niv
            LEFT JOIN dbo.t_ubicacioncolumna col (NOLOCK)
                ON col.c_codigo_col = pal.c_columna_col
            LEFT JOIN t_ubicacionposicion pos (NOLOCK)
                ON pos.c_codigo_pos = pal.c_codigo_pos
			LEFT JOIN dbo.t_lote lot (NOLOCK) 
				ON pal.c_codigo_lot= lot.c_codigo_lot
        WHERE (pal.c_codigo_rec+pal.c_secuencia_red = @ls_codqr OR pal.c_codexterno_rec = @ls_codqr)
              AND pal.c_codigo_tem = @ls_temporada
              AND pal.c_codigo_pem = '99'
			  AND pal.c_activo_red = '1'
			  AND @tipo = 'R'
		ORDER BY c_codigo_pte DESC ;

        SET @as_success = 1;
        SET @as_message = 'OK';
    END TRY
    BEGIN CATCH
        SET @as_success = 0;
        SET @as_message = ERROR_MESSAGE();
    END CATCH;
END;

IF @as_operation = 64 /*Listado de pallets en trasperencia estatus "P" y "E" */
BEGIN
    BEGIN TRY
        /*SACAMOS LOS DATOS  DEL JSON*/
        SELECT @ls_puntoemp = RTRIM(LTRIM(ISNULL(n.el.value('c_codigo_pem[1]', 'varchar(2)'),''))),
			   @tipo = RTRIM(LTRIM(ISNULL(n.el.value('c_estatus_pta[1]', 'varchar(20)'),'')))

        FROM @xml.nodes('/') n(el);

		SELECT n_idfolio_pta = tra.n_idfolio_pta,
			   c_envia = tra.c_AlmacenQueEnvia_pta 
		FROM dbo.t_pallet_traspaso_app tra (NOLOCK)
		WHERE tra.c_AlmacenQueRecibe_pta = @ls_puntoemp
		AND tra.c_Estatus_pta = @tipo

        SET @as_success = 1;
        SET @as_message = 'OK';
    END TRY
    BEGIN CATCH
        SET @as_success = 0;
        SET @as_message = ERROR_MESSAGE();
    END CATCH;
END;


