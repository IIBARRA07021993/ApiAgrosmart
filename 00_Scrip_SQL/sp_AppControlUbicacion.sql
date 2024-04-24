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

DECLARE @xml XML,
        @ls_tem VARCHAR(2),
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

SELECT @xml = dbo.fn_parse_json2xml(@as_json);

IF @as_operation = 1
   OR @as_operation = 2 /*Asignar Ubicacion al pallet*/
BEGIN
    BEGIN TRY


        /*SACAMOS LOS DATOS DEL JSON*/
        SELECT @ls_tem = RTRIM(LTRIM(ISNULL(n.el.value('c_codigo_tem[1]', 'varchar(2)'), ''))),
               @ls_emp = RTRIM(LTRIM(ISNULL(n.el.value('c_codigo_emp[1]', 'varchar(2)'), ''))),
               @ls_pallet = RTRIM(LTRIM(ISNULL(n.el.value('c_codigo_pal[1]', 'varchar(10)'), ''))),
               @ls_nivel = RTRIM(LTRIM(ISNULL(n.el.value('c_codigo_niv[1]', 'varchar(4)'), ''))),
               @ls_columna = RTRIM(LTRIM(ISNULL(n.el.value('c_codigo_col[1]', 'varchar(4)'), ''))),
               @ls_posicion = RTRIM(LTRIM(ISNULL(n.el.value('c_codigo_pos[1]', 'varchar(4)'), ''))),
               @ls_espaciofisico = RTRIM(LTRIM(ISNULL(n.el.value('c_codigo_def[1]', 'varchar(10)'), ''))),
               @ls_usuario = RTRIM(LTRIM(ISNULL(n.el.value('c_codigo_usu[1]', 'varchar(20)'), ''))),
               @ls_pedido = RTRIM(LTRIM(ISNULL(n.el.value('c_codigo_pdo[1]', 'varchar(16)'), '')))
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
        )
        BEGIN
            SET @as_success = 0;
            SET @as_message
                = 'El pallet <strong>' + @ls_pallet
                  + '</strong> no existe en la temporada activa o el punto de empaque.';
            RETURN;

        END;



        IF @as_operation = 1
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


                SET @as_success = 2;
                SET @as_message
                    = 'El pallet ' + @ls_pallet + ' ya tiene asignada la ubicación Rack: ' + @ls_nomcolumna
                      + ' Nivel: ' + @ls_nomnivel + +' Posición: ' + @ls_nomposicion
                      + ' ¿Desea reasignar el pallet  ala ubicación seleccionada?';
                /*SET @as_message
                    = 'El pallet  <strong> ' + @ls_pallet
                      + '</strong> ya tiene asignada la ubicación :<br><br> <strong>Rack: ' + @ls_nomcolumna
                      + '<br><br>Nivel: ' + @ls_nomnivel + +'<br><br>Posición: ' + @ls_nomposicion
                      + '</strong>  <br><br> ¿Desea reasignar el pallet  ala ubicación seleccionada?';*/


                RETURN;
            END;
        END;


        SELECT @ls_presentacionpal = STUFF(
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
        )
                                         FOR XML PATH('')
                                     ),
                                     1,
                                     2,
                                     ''
                                          );


        IF @ls_presentacionpal <> ''
           AND @ls_pedido <> ''
        BEGIN
            SET @as_success = 0;
            SET @as_message
                = 'La presentación  <strong>' + @ls_presentacionpal + '</strong> del pallet <strong> ' + @ls_pallet
                  + '</strong> es diferente a la de la ubicación donde se quiere posicionar.';

            RETURN;
        END;



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

        BEGIN TRAN;

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
            = 'La ubicación Rack: ' + @ls_nomcolumna + ' Nivel: ' + @ls_nomnivel + ' Posición: ' + @ls_nomposicion
              + ' fue asignada con éxito al pallet: ' + @ls_pallet;

        /*
   SET @as_message
            = 'La ubicación:  <br><br><strong>Rack: ' + @ls_nomcolumna + '<br><br>Nivel: ' + @ls_nomnivel
              + +'<br><br>Posición: ' + @ls_nomposicion
              + '</strong> <br><br>fue asignada con éxito al pallet:  <strong> ' + @ls_pallet + '</strong>';

			  */

        COMMIT TRAN;
    END TRY
    BEGIN CATCH
        SET @as_success = 0;
        SET @as_message = ERROR_MESSAGE();
        ROLLBACK TRAN;
    END CATCH;
END;


IF @as_operation = 3 /*Quitar Ubicacion al pallet*/
BEGIN
    BEGIN TRY
        BEGIN TRAN;

        /*SACAMOS LOS DATOS DEL JSON*/
        SELECT @ls_tem = RTRIM(LTRIM(ISNULL(n.el.value('c_codigo_tem[1]', 'varchar(2)'), ''))),
               @ls_emp = RTRIM(LTRIM(ISNULL(n.el.value('c_codigo_emp[1]', 'varchar(2)'), ''))),
               @ls_pallet = RTRIM(LTRIM(ISNULL(n.el.value('c_codigo_pal[1]', 'varchar(10)'), ''))),
               @ls_usuario = RTRIM(LTRIM(ISNULL(n.el.value('c_codigo_usu[1]', 'varchar(20)'), '')))
        FROM @xml.nodes('/') n(el);


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
