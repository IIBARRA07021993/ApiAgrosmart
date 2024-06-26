/*|AGS|*/
IF EXISTS
(
    SELECT *
    FROM dbo.sysobjects
    WHERE id = OBJECT_ID(N'[dbo].[sp_Appcontrolpedido]')
)
    DROP PROCEDURE sp_Appcontrolpedido;
GO
/*|AGS|*/

CREATE PROCEDURE [dbo].[sp_Appcontrolpedido]
(
    @as_operation INT,
    @as_json VARCHAR(MAX),
    @as_success INT OUTPUT,
    @as_message VARCHAR(1024) OUTPUT
)
AS
SET NOCOUNT ON;

DECLARE @xml XML,
        @tem CHAR(2),
        @emp CHAR(2),
        @pal VARCHAR(10),
        @pedido VARCHAR(16),
        @presentacion VARCHAR(8),
        @status VARCHAR(1);

SET @as_message = '';
SET @as_success = 0;
SELECT @xml = dbo.fn_parse_json2xml(@as_json);

IF @as_operation = 1 /*AGREGAR EL PALLET AL PEDIDO INICIAl SI CUMPLE CON TODAS LAS VALIDACIONES*/
BEGIN
    BEGIN TRY
        BEGIN TRAN;
        /*SACAMOS LOS DATOS DEL PALLET DEL JSON*/
        SELECT @tem = RTRIM(LTRIM(ISNULL(n.el.value('c_codigo_tem[1]', 'varchar(2)'), ''))),
               @emp = RTRIM(LTRIM(ISNULL(n.el.value('c_codigo_emp[1]', 'varchar(2)'), ''))),
               @pal = RTRIM(LTRIM(ISNULL(n.el.value('c_codigo_pal[1]', 'varchar(10)'), ''))),
               @pedido = RTRIM(LTRIM(ISNULL(n.el.value('c_codigo_pdo[1]', 'varchar(16)'), '')))
        FROM @xml.nodes('/') n(el);



        /*VALIDAMOS SI	PALLET EXISTE*/
        IF NOT EXISTS
        (
            SELECT *
            FROM t_palet pal (NOLOCK)
            WHERE pal.c_codigo_tem = @tem
                  AND pal.c_codigo_emp = @emp
                  AND
                  (
                      RTRIM(LTRIM(ISNULL(pal.c_codigo_pal, ''))) = @pal
                      OR RTRIM(LTRIM(ISNULL(pal.c_codigo_est, ''))) = @pal
                  )
        )
        BEGIN
            SET @as_success = 2;
            SET @as_message = 'El pallet [' + @pal + '] no existe en  la temporada  o punto de empaque del pedido.';
        END;
        ELSE /*ELSE VALIDAMOS SI	PALLET EXISTE*/


        /*VALIDAMOS SI NO TIENE PEDIDO*/
        IF EXISTS
        (
            SELECT *
            FROM t_palet pal (NOLOCK)
            WHERE pal.c_codigo_tem = @tem
                  AND pal.c_codigo_emp = @emp
                  AND
                  (
                      RTRIM(LTRIM(ISNULL(pal.c_codigo_pal, ''))) = @pal
                      OR RTRIM(LTRIM(ISNULL(pal.c_codigo_est, ''))) = @pal
                  )
                  AND ISNULL(pal.c_codigo_pdo, '') <> ''
        )
        BEGIN

            SET @as_success = 3;
            SET @as_message = 'El pallet [' + @pal + '] tiene un número de pedido ligado.';
        END;
        ELSE /* ELSE VALIDAMOS SI NO TIENE PEDIDO*/
        /*VALIDAMOS SI HAY PRESENTACIONES QUE EXEDEN LAS CAJAS PEDIDIDAS*/
        IF EXISTS
        (
            SELECT DET.c_codigo_pro,
                   DET.c_codigo_eti,
                   DET.c_codigo_col,
                   n_cajaspedidas_pdd = SUM(DET.n_cajaspedidas_pdd),
                   n_cajasempacadas_pdd = SUM(DET.n_cajasempacadas_pdd),
                   n_bulxpa_pal = SUM(pal.n_bulxpa_pal)
            FROM t_pedidodet DET (NOLOCK)
                INNER JOIN dbo.t_palet pal
                    ON pal.c_codigo_tem = DET.c_codigo_tem
                       AND pal.c_codigo_emp = DET.c_codigo_emp
                       AND pal.c_codigo_pro = DET.c_codigo_pro
                       AND pal.c_codigo_eti = DET.c_codigo_eti
                       AND pal.c_codigo_col = DET.c_codigo_col
            WHERE DET.c_codigo_tem = @tem
                  AND DET.c_codigo_emp = @emp
                  AND DET.c_codigo_pdo = @pedido
                  AND
                  (
                      RTRIM(LTRIM(ISNULL(pal.c_codigo_pal, ''))) = @pal
                      OR RTRIM(LTRIM(ISNULL(pal.c_codigo_est, ''))) = @pal
                  )
            GROUP BY DET.c_codigo_pro,
                     DET.c_codigo_eti,
                     DET.c_codigo_col
            HAVING SUM(DET.n_cajaspedidas_pdd) < SUM(DET.n_cajasempacadas_pdd) + SUM(pal.n_bulxpa_pal)
        )
        BEGIN
            SET @as_success = 4;
            SET @as_message = 'El pallet [' + @pal + '] tiene presentación/s  que exeden las cajas pedidas.';
        END;

        ELSE /*VALIDAMOS SI HAY PRESENTACIONES QUE ESTAN EL PALLET Y NO ESTAN EN EL PEDIDO*/

        /*VALIDAMOS SI HAY PRESENTACIONES QUE ESTAN EL PALLET Y NO ESTAN EN EL PEDIDO*/
        IF EXISTS
        (
            SELECT *
            FROM dbo.t_palet pal (NOLOCK)
                LEFT JOIN dbo.t_pedidodet det (NOLOCK)
                    ON pal.c_codigo_tem = det.c_codigo_tem
                       AND pal.c_codigo_emp = det.c_codigo_emp
                       AND pal.c_codigo_pro = det.c_codigo_pro
                       AND pal.c_codigo_eti = det.c_codigo_eti
                       AND pal.c_codigo_col = det.c_codigo_col
                       AND det.c_codigo_pdo = @pedido
            WHERE pal.c_codigo_tem = @tem
                  AND pal.c_codigo_emp = @emp
                  AND
                  (
                      RTRIM(LTRIM(ISNULL(pal.c_codigo_pal, ''))) = @pal
                      OR RTRIM(LTRIM(ISNULL(pal.c_codigo_est, ''))) = @pal
                  )
                  AND ISNULL(det.c_codigo_pro, '') = ''
        )
        BEGIN

            SET @as_success = 5;
            SET @as_message
                = 'El pallet [' + @pal + '] tiene presentación/s  que no están en el pedido .[' + @pedido + ']';
        END;

        ELSE /*  ELSE VALIDAMOS SI HAY PRESENTACIONES QUE EXEDEN LAS CAJAS PEDIDIDAS*/
        BEGIN

            /*Actulizamos el pallet con el numero del pedido*/
            UPDATE dbo.t_palet
            SET c_codigo_pdo = @pedido
            WHERE (
                      RTRIM(LTRIM(ISNULL(c_codigo_pal, ''))) = @pal
                      OR RTRIM(LTRIM(ISNULL(c_codigo_est, ''))) = @pal
                  )
                  AND ISNULL(c_codigo_pdo, '') = '';


            /*Actulizamos el pedido con los datos nuevos */
            UPDATE dbo.t_pedidodet
            SET n_cajasempacadas_pdd = tb_pal.n_bulxpa_pal
            FROM
            (
                SELECT pal.c_codigo_tem,
                       pal.c_codigo_emp,
                       pal.c_codigo_pdo,
                       pal.c_codigo_pro,
                       pal.c_codigo_eti,
                       pal.c_codigo_col,
                       n_bulxpa_pal = SUM(pal.n_bulxpa_pal)
                FROM t_palet pal (NOLOCK)
                WHERE pal.c_codigo_tem = @tem
                      AND pal.c_codigo_emp = @emp
                      AND ISNULL(pal.c_codigo_pdo, '') = @pedido
                GROUP BY pal.c_codigo_tem,
                         pal.c_codigo_emp,
                         pal.c_codigo_pdo,
                         pal.c_codigo_pro,
                         pal.c_codigo_eti,
                         pal.c_codigo_col
            ) tb_pal
            WHERE t_pedidodet.c_codigo_tem = tb_pal.c_codigo_tem
                  AND t_pedidodet.c_codigo_emp = tb_pal.c_codigo_emp
                  AND t_pedidodet.c_codigo_pdo = tb_pal.c_codigo_pdo
                  AND t_pedidodet.c_codigo_pro = tb_pal.c_codigo_pro
                  AND t_pedidodet.c_codigo_eti = tb_pal.c_codigo_eti
                  AND t_pedidodet.c_codigo_col = tb_pal.c_codigo_col;


            /*ACTULIZAMOS EL ESTATUS DEL PEDIDO A EN PROCESO*/
            UPDATE dbo.t_pedido
            SET c_estatus_pdo = '2'
            WHERE c_codigo_tem = @tem
                  AND c_codigo_emp = @emp
                  AND ISNULL(c_codigo_pdo, '') = @pedido;

            SET @as_success = 1;
            SET @as_message = 'Pallet Agregado .[' + @pal + ']';

        END;
        COMMIT TRAN;
    END TRY
    BEGIN CATCH
        SET @as_success = 0;
        SET @as_message = ERROR_MESSAGE();
        ROLLBACK TRAN;
    END CATCH;
END;

IF @as_operation = 2 /*AGREGAR EL PALLET AL PEDIDO  AUNQUE SE EXEDA DE CAJAS PEDIDAS*/
BEGIN
    BEGIN TRY
        BEGIN TRAN;
        /*SACAMOS LOS DATOS DEL PALLET DEL JSON*/
        SELECT @tem = RTRIM(LTRIM(ISNULL(n.el.value('c_codigo_tem[1]', 'varchar(2)'), ''))),
               @emp = RTRIM(LTRIM(ISNULL(n.el.value('c_codigo_emp[1]', 'varchar(2)'), ''))),
               @pal = RTRIM(LTRIM(ISNULL(n.el.value('c_codigo_pal[1]', 'varchar(10)'), ''))),
               @pedido = RTRIM(LTRIM(ISNULL(n.el.value('c_codigo_pdo[1]', 'varchar(16)'), '')))
        FROM @xml.nodes('/') n(el);



        /*VALIDAMOS SI	PALLET EXISTE*/
        IF NOT EXISTS
        (
            SELECT *
            FROM t_palet pal (NOLOCK)
            WHERE pal.c_codigo_tem = @tem
                  AND pal.c_codigo_emp = @emp
                  AND
                  (
                      RTRIM(LTRIM(ISNULL(pal.c_codigo_pal, ''))) = @pal
                      OR RTRIM(LTRIM(ISNULL(pal.c_codigo_est, ''))) = @pal
                  )
        )
        BEGIN
            SET @as_success = 2;
            SET @as_message = 'El pallet [' + @pal + '] no existe en  la temporada  o punto de empaque del pedido.';
        END;
        ELSE /*ELSE VALIDAMOS SI	PALLET EXISTE*/


        /*VALIDAMOS SI NO TIENE PEDIDO*/
        IF EXISTS
        (
            SELECT *
            FROM t_palet pal (NOLOCK)
            WHERE pal.c_codigo_tem = @tem
                  AND pal.c_codigo_emp = @emp
                  AND
                  (
                      RTRIM(LTRIM(ISNULL(pal.c_codigo_pal, ''))) = @pal
                      OR RTRIM(LTRIM(ISNULL(pal.c_codigo_est, ''))) = @pal
                  )
                  AND ISNULL(pal.c_codigo_pdo, '') <> ''
        )
        BEGIN

            SET @as_success = 3;
            SET @as_message = 'El pallet [' + @pal + '] tiene un número de pedido ligado.';
        END;
        ELSE /* ELSE VALIDAMOS SI NO TIENE PEDIDO*/

        /*VALIDAMOS SI HAY PRESENTACIONES QUE ESTAN EL PALLET Y NO ESTAN EN EL PEDIDO*/
        IF EXISTS
        (
            SELECT *
            FROM dbo.t_palet pal (NOLOCK)
                LEFT JOIN dbo.t_pedidodet det (NOLOCK)
                    ON pal.c_codigo_tem = det.c_codigo_tem
                       AND pal.c_codigo_emp = det.c_codigo_emp
                       AND pal.c_codigo_pro = det.c_codigo_pro
                       AND pal.c_codigo_eti = det.c_codigo_eti
                       AND pal.c_codigo_col = det.c_codigo_col
                       AND det.c_codigo_pdo = @pedido
            WHERE pal.c_codigo_tem = @tem
                  AND pal.c_codigo_emp = @emp
                  AND
                  (
                      RTRIM(LTRIM(ISNULL(pal.c_codigo_pal, ''))) = @pal
                      OR RTRIM(LTRIM(ISNULL(pal.c_codigo_est, ''))) = @pal
                  )
                  AND ISNULL(det.c_codigo_pro, '') = ''
        )
        BEGIN

            SET @as_success = 5;
            SET @as_message
                = 'El pallet [' + @pal + '] tiene presentación/s  que no están en el pedido .[' + @pedido + ']';
        END;

        ELSE /*  ELSE VALIDAMOS SI HAY PRESENTACIONES QUE EXEDEN LAS CAJAS PEDIDIDAS*/
        BEGIN

            /*Actulizamos el pallet con el numero del pedido*/
            UPDATE dbo.t_palet
            SET c_codigo_pdo = @pedido
            WHERE (
                      RTRIM(LTRIM(ISNULL(c_codigo_pal, ''))) = @pal
                      OR RTRIM(LTRIM(ISNULL(c_codigo_est, ''))) = @pal
                  )
                  AND ISNULL(c_codigo_pdo, '') = '';


            /*Actulizamos el pedido con los datos nuevos */
            UPDATE dbo.t_pedidodet
            SET n_cajasempacadas_pdd = tb_pal.n_bulxpa_pal
            FROM
            (
                SELECT pal.c_codigo_tem,
                       pal.c_codigo_emp,
                       pal.c_codigo_pdo,
                       pal.c_codigo_pro,
                       pal.c_codigo_eti,
                       pal.c_codigo_col,
                       n_bulxpa_pal = SUM(pal.n_bulxpa_pal)
                FROM t_palet pal (NOLOCK)
                WHERE pal.c_codigo_tem = @tem
                      AND pal.c_codigo_emp = @emp
                      AND ISNULL(pal.c_codigo_pdo, '') = @pedido
                GROUP BY pal.c_codigo_tem,
                         pal.c_codigo_emp,
                         pal.c_codigo_pdo,
                         pal.c_codigo_pro,
                         pal.c_codigo_eti,
                         pal.c_codigo_col
            ) tb_pal
            WHERE t_pedidodet.c_codigo_tem = tb_pal.c_codigo_tem
                  AND t_pedidodet.c_codigo_emp = tb_pal.c_codigo_emp
                  AND t_pedidodet.c_codigo_pdo = tb_pal.c_codigo_pdo
                  AND t_pedidodet.c_codigo_pro = tb_pal.c_codigo_pro
                  AND t_pedidodet.c_codigo_eti = tb_pal.c_codigo_eti
                  AND t_pedidodet.c_codigo_col = tb_pal.c_codigo_col;


            /*ACTULIZAMOS EL ESTATUS DEL PEDIDO A EN PROCESO*/
            UPDATE dbo.t_pedido
            SET c_estatus_pdo = '2'
            WHERE c_codigo_tem = @tem
                  AND c_codigo_emp = @emp
                  AND ISNULL(c_codigo_pdo, '') = @pedido;

            SET @as_success = 1;
            SET @as_message = 'Pallet Agregado .[' + @pal + ']';

        END;
        COMMIT TRAN;
    END TRY
    BEGIN CATCH
        SET @as_success = 0;
        SET @as_message = ERROR_MESSAGE();
        ROLLBACK TRAN;
    END CATCH;
END;

IF @as_operation = 3 /*AGREGAR EL PALLET AL PEDIDO INICIAl SI Y AGREGAR PRESENTACION QUE NO ESTA EN EL PEDIDO*/
BEGIN
    BEGIN TRY
        BEGIN TRAN;
        /*SACAMOS LOS DATOS DEL PALLET DEL JSON*/
        SELECT @tem = RTRIM(LTRIM(ISNULL(n.el.value('c_codigo_tem[1]', 'varchar(2)'), ''))),
               @emp = RTRIM(LTRIM(ISNULL(n.el.value('c_codigo_emp[1]', 'varchar(2)'), ''))),
               @pal = RTRIM(LTRIM(ISNULL(n.el.value('c_codigo_pal[1]', 'varchar(10)'), ''))),
               @pedido = RTRIM(LTRIM(ISNULL(n.el.value('c_codigo_pdo[1]', 'varchar(16)'), '')))
        FROM @xml.nodes('/') n(el);



        /*VALIDAMOS SI	PALLET EXISTE*/
        IF NOT EXISTS
        (
            SELECT *
            FROM t_palet pal (NOLOCK)
            WHERE pal.c_codigo_tem = @tem
                  AND pal.c_codigo_emp = @emp
                  AND
                  (
                      RTRIM(LTRIM(ISNULL(pal.c_codigo_pal, ''))) = @pal
                      OR RTRIM(LTRIM(ISNULL(pal.c_codigo_est, ''))) = @pal
                  )
        )
        BEGIN
            SET @as_success = 2;
            SET @as_message = 'El pallet [' + @pal + '] no existe en  la temporada  o punto de empaque del pedido.';
        END;
        ELSE /*ELSE VALIDAMOS SI	PALLET EXISTE*/


        /*VALIDAMOS SI NO TIENE PEDIDO*/
        IF EXISTS
        (
            SELECT *
            FROM t_palet pal (NOLOCK)
            WHERE pal.c_codigo_tem = @tem
                  AND pal.c_codigo_emp = @emp
                  AND
                  (
                      RTRIM(LTRIM(ISNULL(pal.c_codigo_pal, ''))) = @pal
                      OR RTRIM(LTRIM(ISNULL(pal.c_codigo_est, ''))) = @pal
                  )
                  AND ISNULL(pal.c_codigo_pdo, '') <> ''
        )
        BEGIN

            SET @as_success = 3;
            SET @as_message = 'El pallet [' + @pal + '] tiene un número de pedido ligado.';
        END;

        ELSE /* ELSE VALIDAMOS SI NO TIENE PEDIDO */
        BEGIN


            /*INSERTAMOS PRESENTACIONES QUE NO ESTEN EN EL PEDIDO*/
            INSERT INTO dbo.t_pedidodet
            SELECT c_codigo_tem = pal.c_codigo_tem,
                   c_codigo_emp = pal.c_codigo_emp,
                   c_codigo_pdo = @pedido,
                   c_codigo_pro = pal.c_codigo_pro,
                   c_codigo_eti = pal.c_codigo_eti,
                   c_codigo_col = pal.c_codigo_col,
                   n_cajasxpal_pdd = SUM(pal.n_bulxpa_pal),
                   n_cajaspedidas_pdd = SUM(pal.n_bulxpa_pal),
                   n_palets_pdd = 1,
                   n_cajasempacadas_pdd = SUM(pal.n_bulxpa_pal),
                   n_precio_pdd = 0,
                   c_precxkg_pdd = 0,
                   n_pesoxcaja_pdd = 0
            FROM dbo.t_palet pal (NOLOCK)
                LEFT JOIN dbo.t_pedidodet det (NOLOCK)
                    ON pal.c_codigo_tem = det.c_codigo_tem
                       AND pal.c_codigo_emp = det.c_codigo_emp
                       AND pal.c_codigo_pro = det.c_codigo_pro
                       AND pal.c_codigo_eti = det.c_codigo_eti
                       AND pal.c_codigo_col = det.c_codigo_col
                       AND det.c_codigo_pdo = @pedido
            WHERE pal.c_codigo_tem = @tem
                  AND pal.c_codigo_emp = @emp
                  AND
                  (
                      RTRIM(LTRIM(ISNULL(pal.c_codigo_pal, ''))) = @pal
                      OR RTRIM(LTRIM(ISNULL(pal.c_codigo_est, ''))) = @pal
                  )
                  AND ISNULL(det.c_codigo_pro, '') = ''
            GROUP BY pal.c_codigo_tem,
                     pal.c_codigo_emp,
                     pal.c_codigo_pro,
                     pal.c_codigo_eti,
                     pal.c_codigo_col;


            /*Actulizamos el pallet con el numero del pedido*/
            UPDATE dbo.t_palet
            SET c_codigo_pdo = @pedido
            WHERE (
                      RTRIM(LTRIM(ISNULL(c_codigo_pal, ''))) = @pal
                      OR RTRIM(LTRIM(ISNULL(c_codigo_est, ''))) = @pal
                  )
                  AND ISNULL(c_codigo_pdo, '') = '';


            /*Actulizamos el pedido con los datos nuevos */
            UPDATE dbo.t_pedidodet
            SET n_cajasempacadas_pdd = tb_pal.n_bulxpa_pal
            FROM
            (
                SELECT pal.c_codigo_tem,
                       pal.c_codigo_emp,
                       pal.c_codigo_pdo,
                       pal.c_codigo_pro,
                       pal.c_codigo_eti,
                       pal.c_codigo_col,
                       n_bulxpa_pal = SUM(pal.n_bulxpa_pal)
                FROM t_palet pal (NOLOCK)
                WHERE pal.c_codigo_tem = @tem
                      AND pal.c_codigo_emp = @emp
                      AND ISNULL(pal.c_codigo_pdo, '') = @pedido
                GROUP BY pal.c_codigo_tem,
                         pal.c_codigo_emp,
                         pal.c_codigo_pdo,
                         pal.c_codigo_pro,
                         pal.c_codigo_eti,
                         pal.c_codigo_col
            ) tb_pal
            WHERE t_pedidodet.c_codigo_tem = tb_pal.c_codigo_tem
                  AND t_pedidodet.c_codigo_emp = tb_pal.c_codigo_emp
                  AND t_pedidodet.c_codigo_pdo = tb_pal.c_codigo_pdo
                  AND t_pedidodet.c_codigo_pro = tb_pal.c_codigo_pro
                  AND t_pedidodet.c_codigo_eti = tb_pal.c_codigo_eti
                  AND t_pedidodet.c_codigo_col = tb_pal.c_codigo_col;


            /*ACTULIZAMOS EL ESTATUS DEL PEDIDO A EN PROCESO*/
            UPDATE dbo.t_pedido
            SET c_estatus_pdo = '2'
            WHERE c_codigo_tem = @tem
                  AND c_codigo_emp = @emp
                  AND ISNULL(c_codigo_pdo, '') = @pedido;

            SET @as_success = 1;
            SET @as_message = 'Pallet Agregado .[' + @pal + ']';

        END;
        COMMIT TRAN;
    END TRY
    BEGIN CATCH
        SET @as_success = 0;
        SET @as_message = ERROR_MESSAGE();
        ROLLBACK TRAN;
    END CATCH;
END;

IF @as_operation = 4 /*ACTULIZAR ESTATUS DEL PEDIDO Y LAS CAJAS ESPACADAS SEGUN LOS PALLETES MARCADOS*/
BEGIN
    BEGIN TRY
        BEGIN TRAN;
        /*SACAMOS LOS DATOS DEL PALLET DEL JSON*/
        SELECT @tem = RTRIM(LTRIM(ISNULL(n.el.value('c_codigo_tem[1]', 'varchar(2)'), ''))),
               @emp = RTRIM(LTRIM(ISNULL(n.el.value('c_codigo_emp[1]', 'varchar(2)'), ''))),
               @pedido = RTRIM(LTRIM(ISNULL(n.el.value('c_codigo_pdo[1]', 'varchar(16)'), ''))),
               @status = RTRIM(LTRIM(ISNULL(n.el.value('c_estatus_pdo[1]', 'varchar(1)'), '')))
        FROM @xml.nodes('/') n(el);


        /*ACTULIZAMOS EL ESTATUS DEL PEDIDO */
        UPDATE dbo.t_pedido
        SET c_estatus_pdo = @status
        WHERE c_codigo_tem = @tem
              AND c_codigo_emp = @emp
              AND ISNULL(c_codigo_pdo, '') = @pedido;


        /*Actulizamos el pedido con los datos de los palletes marcados */
        UPDATE dbo.t_pedidodet
        SET n_cajasempacadas_pdd = tb_pal.n_bulxpa_pal
        FROM
        (
            SELECT pal.c_codigo_tem,
                   pal.c_codigo_emp,
                   pal.c_codigo_pdo,
                   pal.c_codigo_pro,
                   pal.c_codigo_eti,
                   pal.c_codigo_col,
                   n_bulxpa_pal = SUM(pal.n_bulxpa_pal)
            FROM t_palet pal (NOLOCK)
            WHERE pal.c_codigo_tem = @tem
                  AND pal.c_codigo_emp = @emp
                  AND ISNULL(pal.c_codigo_pdo, '') = @pedido
            GROUP BY pal.c_codigo_tem,
                     pal.c_codigo_emp,
                     pal.c_codigo_pdo,
                     pal.c_codigo_pro,
                     pal.c_codigo_eti,
                     pal.c_codigo_col
        ) tb_pal
        WHERE t_pedidodet.c_codigo_tem = tb_pal.c_codigo_tem
              AND t_pedidodet.c_codigo_emp = tb_pal.c_codigo_emp
              AND t_pedidodet.c_codigo_pdo = tb_pal.c_codigo_pdo
              AND t_pedidodet.c_codigo_pro = tb_pal.c_codigo_pro
              AND t_pedidodet.c_codigo_eti = tb_pal.c_codigo_eti
              AND t_pedidodet.c_codigo_col = tb_pal.c_codigo_col;

        SET @as_success = 1;
        SET @as_message = 'Pedido Actulizado.[' + @pedido + ']';

        COMMIT TRAN;
    END TRY
    BEGIN CATCH
        SET @as_success = 0;
        SET @as_message = ERROR_MESSAGE();
        ROLLBACK TRAN;
    END CATCH;
END;

IF @as_operation = 5 /*LIBERAMOS EL PALLET DEL PEDIDOS*/
BEGIN
    BEGIN TRY
        BEGIN TRAN;
        SELECT @tem = RTRIM(LTRIM(ISNULL(n.el.value('c_codigo_tem[1]', 'varchar(2)'), ''))),
               @emp = RTRIM(LTRIM(ISNULL(n.el.value('c_codigo_emp[1]', 'varchar(2)'), ''))),
               @pal = RTRIM(LTRIM(ISNULL(n.el.value('c_codigo_pal[1]', 'varchar(10)'), ''))),
               @pedido = RTRIM(LTRIM(ISNULL(n.el.value('c_codigo_pdo[1]', 'varchar(16)'), '')))
        FROM @xml.nodes('/') n(el);


        /*Actulizamos el pallet con el numero del pedido*/
        UPDATE dbo.t_palet
        SET c_codigo_pdo = NULL
        WHERE (
                  RTRIM(LTRIM(ISNULL(c_codigo_pal, ''))) = @pal
                  OR RTRIM(LTRIM(ISNULL(c_codigo_est, ''))) = @pal
              );

        IF NOT EXISTS
        (
            SELECT *
            FROM t_palet pal (NOLOCK)
            WHERE pal.c_codigo_tem = @tem
                  AND pal.c_codigo_emp = @emp
                  AND ISNULL(pal.c_codigo_pdo, '') = @pedido
        )
        BEGIN
            UPDATE dbo.t_pedidodet
            SET n_cajasempacadas_pdd = 0
            WHERE c_codigo_tem = @tem
                  AND c_codigo_emp = @emp
                  AND c_codigo_pdo = @pedido;

            /*REGRESAMOS A 1 SI YA NO TIENE NINGUN PALLET LIGADO*/
            UPDATE dbo.t_pedido
            SET c_estatus_pdo = '1'
            WHERE c_codigo_tem = @tem
                  AND c_codigo_emp = @emp
                  AND ISNULL(c_codigo_pdo, '') = @pedido;

        END;
        ELSE
        BEGIN
            /*Actulizamos el pedido con los datos nuevos */
            UPDATE dbo.t_pedidodet
            SET n_cajasempacadas_pdd = tb_pal.n_bulxpa_pal
            FROM
            (
                SELECT pal.c_codigo_tem,
                       pal.c_codigo_emp,
                       pal.c_codigo_pdo,
                       pal.c_codigo_pro,
                       pal.c_codigo_eti,
                       pal.c_codigo_col,
                       n_bulxpa_pal = SUM(pal.n_bulxpa_pal)
                FROM t_palet pal (NOLOCK)
                WHERE pal.c_codigo_tem = @tem
                      AND pal.c_codigo_emp = @emp
                      AND ISNULL(pal.c_codigo_pdo, '') = @pedido
                GROUP BY pal.c_codigo_tem,
                         pal.c_codigo_emp,
                         pal.c_codigo_pdo,
                         pal.c_codigo_pro,
                         pal.c_codigo_eti,
                         pal.c_codigo_col
            ) tb_pal
            WHERE t_pedidodet.c_codigo_tem = tb_pal.c_codigo_tem
                  AND t_pedidodet.c_codigo_emp = tb_pal.c_codigo_emp
                  AND t_pedidodet.c_codigo_pdo = tb_pal.c_codigo_pdo
                  AND t_pedidodet.c_codigo_pro = tb_pal.c_codigo_pro
                  AND t_pedidodet.c_codigo_eti = tb_pal.c_codigo_eti
                  AND t_pedidodet.c_codigo_col = tb_pal.c_codigo_col;


            UPDATE dbo.t_pedidodet
            SET n_cajasempacadas_pdd = 0
            FROM dbo.t_pedidodet det
                LEFT JOIN dbo.t_palet pal
                    ON pal.c_codigo_tem = det.c_codigo_tem
                       AND pal.c_codigo_emp = det.c_codigo_emp
                       AND pal.c_codigo_pdo = det.c_codigo_pdo
                       AND pal.c_codigo_pro = det.c_codigo_pro
                       AND pal.c_codigo_eti = det.c_codigo_eti
                       AND pal.c_codigo_col = det.c_codigo_col
            WHERE ISNULL(pal.c_codigo_pdo, '') = '';

            UPDATE dbo.t_pedido
            SET c_estatus_pdo = '2'
            WHERE c_codigo_tem = @tem
                  AND c_codigo_emp = @emp
                  AND ISNULL(c_codigo_pdo, '') = @pedido;
        END;

        SET @as_success = 1;
        SET @as_message = 'Pallet Liberado con Exito .[' + @pal + ']';

        COMMIT TRAN;
    END TRY
    BEGIN CATCH
        SET @as_success = 0;
        SET @as_message = ERROR_MESSAGE();
        ROLLBACK TRAN;
    END CATCH;
END;
