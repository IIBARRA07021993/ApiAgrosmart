/*|AGS|*/
IF EXISTS
(
    SELECT *
    FROM dbo.sysobjects
    WHERE id = OBJECT_ID(N'[dbo].[sp_AppControlEstibaLavado]')
)
    DROP PROCEDURE sp_AppControlEstibaLavado;
GO


/*|AGS|*/
CREATE PROCEDURE [dbo].[sp_AppControlEstibaLavado]
(
    @as_operation INT,
    @as_json VARCHAR(MAX),
    @as_success INT OUTPUT,
    @as_message VARCHAR(1024) OUTPUT
)
AS
SET NOCOUNT ON;

DECLARE @xml XML,
        @ls_temporada			VARCHAR(2),
        @ls_empaque				VARCHAR(2),
        @ls_terminal			VARCHAR(100),
        @ls_lote				VARCHAR(4),
        @ls_usuario				VARCHAR(20),
        @ls_banda				VARCHAR(2),
        @ldc_bultos				NUMERIC,
        @ldc_peso				NUMERIC,
        @ls_folionew_Sel		VARCHAR(10),
        @ls_folio_new_programa	VARCHAR(6),
        @ll_tolvas				INT,
        @ll_lot_existe			INT,
		@ls_idCorrida			VarChar(15);
SET @as_message = '';
SET @as_success = 0;
SELECT @xml = dbo.fn_parse_json2xml(@as_json);


IF @as_operation = 1
BEGIN
    BEGIN TRY
        /*SACAMOS LOS DATOS DEL JSON*/
        SELECT @ls_temporada	= RTRIM(LTRIM(ISNULL(n.el.value('c_codigo_tem[1]',	'varchar(2)'),		''))),
               @ls_empaque		= RTRIM(LTRIM(ISNULL(n.el.value('c_codigo_emp[1]',	'varchar(2)'),		''))),
               @ls_banda		= RTRIM(LTRIM(ISNULL(n.el.value('c_codigo_bnd[1]',	'varchar(2)'),		''))),
               @ls_lote			= RTRIM(LTRIM(ISNULL(n.el.value('c_codigo_lot[1]',	'varchar(4)'),		''))),
               @ldc_bultos		= RTRIM(LTRIM(ISNULL(n.el.value('n_cajas_sel[1]',	'NUMERIC'),			''))),
               @ldc_peso		= RTRIM(LTRIM(ISNULL(n.el.value('n_peso_sel[1]',	'NUMERIC'),			''))),
               @ls_usuario		= RTRIM(LTRIM(ISNULL(n.el.value('c_codigo_usu[1]',	'varchar(20)'),		''))),
               @ls_terminal		= RTRIM(LTRIM(ISNULL(n.el.value('c_terminal[1]',	'varchar(100)'),	''))),
			   @ls_idCorrida	= RTRIM(LTRIM(ISNULL(n.el.value('c_folio_sma[1]',	'varchar(15)'),		'')))
        FROM @xml.nodes('/') n(el);

        /*Validamos la temporada */
        IF NOT EXISTS
        (
            SELECT *
            FROM dbo.t_temporada TEM (NOLOCK)
            WHERE TEM.c_codigo_tem = @ls_temporada
        )
        BEGIN
            SET @as_success = 0;
            SET @as_message = 'Temporada [' + @ls_temporada + '] no es válida o no existe ,validar e intentar de nuevo. vale veg ';
            RETURN;
        END;

        /*Validamos el punto de empaque */
        IF NOT EXISTS
        (
            SELECT *
            FROM dbo.t_puntoempaque emp (NOLOCK)
            WHERE emp.c_codigo_pem = @ls_empaque
        )
        BEGIN
            SET @as_success = 0;
            SET @as_message
                = 'Punto de Empaque [' + @ls_empaque + '] no es válido o no existe,validar e intentar de nuevo.';
            RETURN;
        END;

        /*Validamosla banda */
        IF RTRIM(LTRIM(ISNULL(@ls_banda, ''))) = ''
        BEGIN
            SET @as_success = 0;
            SET @as_message = 'La banda  no puede estar vacía , revisar e intentar de nuevo.';
            RETURN;
        END;

        IF NOT EXISTS
        (
            SELECT *
            FROM dbo.t_banda ban (NOLOCK)
            WHERE ban.c_codigo_bnd = @ls_banda
        )
        BEGIN
            SET @as_success = 0;
            SET @as_message = 'La Banda [' + @ls_banda + '] no es válida o no existe ,validar e intentar de nuevo.';
            RETURN;
        END;


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
                  AND prd.c_codigo_tem = @ls_temporada
                  AND prd.c_codigo_emp = @ls_empaque
        )
        BEGIN
            SET @as_success = 0;
            SET @as_message = 'La Banda [' + @ls_banda + ']  ya se Encuentra Corriendo en un Programa de Empaque.';
            RETURN;
        END;



        /*Validamos el lote*/
        IF RTRIM(LTRIM(ISNULL(@ls_lote, ''))) = ''
        BEGIN
            SET @as_success = 0;
            SET @as_message = 'El lote no puede estar vacío , revisar e intentar de nuevo.';
            RETURN;
        END;


        IF NOT EXISTS
        (
            SELECT *
            FROM dbo.t_lote LOT (NOLOCK)
            WHERE LOT.c_codigo_tem = @ls_temporada
                  AND LOT.c_codigo_lot = @ls_lote
        )
        BEGIN
            SET @as_success = 0;
            SET @as_message = 'El lote [' + @ls_lote + '] no es válido o no existe ,validar e intentar de nuevo.';
            RETURN;
        END;


        IF NOT EXISTS
        (
            SELECT *
            FROM
            (
                SELECT tlv.c_codigo_tlv AS c_codigo_tlv,
                       tlv.v_nombre_tlv AS v_nombre_tlv,
                       bnd.c_codigo_bnd AS c_codigo_bnd,
                       bnd.v_nombre_bnd AS v_nombre_bnd,
                       lot.c_codigo_lot AS c_codigo_lot,
                       lot.v_nombre_lot AS v_nombre_lot,
                       cul.c_codigo_cul AS c_codigo_cul,
                       cul.v_nombre_cul AS v_nombre_cul,
                       eti.c_codigo_eti AS c_codigo_eti,
                       eti.v_nombre_eti AS v_nombre_eti,
                       pro.c_codigo_pro AS c_codigo_pro,
                       pro.v_nombre_pro AS v_nombre_pro,
                       col.c_codigo_col AS c_codigo_col,
                       col.v_nombre_col AS v_nombre_col,
                       prqd.c_codigo_pdo AS c_codigo_pdo,
                       prqd.c_codempl_pqd AS c_codempl_pqd
                FROM t_programa_empaquedet AS prqd (NOLOCK)
                    INNER JOIN t_programa_empaque AS prq (NOLOCK)
                        ON prqd.c_codigo_emp = prq.c_codigo_emp
                           AND prqd.c_codigo_prq = prq.c_codigo_prq
                           AND prqd.c_codigo_tem = prq.c_codigo_tem
                    LEFT JOIN t_producto AS pro (NOLOCK)
                        ON pro.c_codigo_pro = prqd.c_codigo_pro
                    INNER JOIN t_tolva AS tlv (NOLOCK)
                        ON prqd.c_codigo_tlv = tlv.c_codigo_tlv
                           AND prqd.c_codigo_bnd = tlv.c_codigo_bnd
                    INNER JOIN t_banda AS bnd (NOLOCK)
                        ON tlv.c_codigo_bnd = bnd.c_codigo_bnd
                    LEFT JOIN t_etiqueta AS eti (NOLOCK)
                        ON eti.c_codigo_eti = prqd.c_codigo_eti
                    INNER JOIN t_seleccion AS sel (NOLOCK)
                        ON sel.c_codigo_tem = prq.c_codigo_tem
                           AND sel.c_codigo_sel = prq.c_codigo_sel
                    INNER JOIN t_lote AS lot (NOLOCK)
                        ON sel.c_codigo_lot = lot.c_codigo_lot
                           AND sel.c_codigo_tem = lot.c_codigo_tem
                    INNER JOIN t_cultivo AS cul (NOLOCK)
                        ON lot.c_codigo_cul = cul.c_codigo_cul
                    LEFT JOIN t_color AS col (NOLOCK)
                        ON prqd.c_codigo_col = col.c_codigo_col
                WHERE prqd.c_codigo_tem = @ls_temporada
                      AND prqd.c_codigo_emp = @ls_empaque
                      AND prq.c_corriendo_prq = 'S'
                      AND CAST(REPLACE(SUBSTRING(CONVERT(VARCHAR, prqd.d_fecha_pqd, 127), 1, 10), '-', '') + ' '
                               + prqd.c_hora_pqd AS DATETIME) =
                      (
                          SELECT MAX(CAST(REPLACE(SUBSTRING(CONVERT(VARCHAR, prqd2.d_fecha_pqd, 127), 1, 10), '-', '')
                                          + ' ' + prqd2.c_hora_pqd AS DATETIME)
                                    )
                          FROM dbo.t_programa_empaquedet AS prqd2 (NOLOCK)
                          WHERE prqd2.c_codigo_emp = prqd.c_codigo_emp
                                AND prqd2.c_codigo_prq = prqd.c_codigo_prq
                                AND prqd2.c_codigo_tem = prqd.c_codigo_tem
                      )
            ) AS prg
                RIGHT JOIN t_tolva AS tlv (NOLOCK)
                    ON prg.c_codigo_tlv = tlv.c_codigo_tlv
                       AND tlv.c_codigo_bnd = prg.c_codigo_bnd
                INNER JOIN t_banda AS bnd (NOLOCK)
                    ON tlv.c_codigo_bnd = bnd.c_codigo_bnd
            WHERE bnd.c_codigo_bnd = @ls_banda
        )
        BEGIN
            SET @as_success = 0;
            SET @as_message = 'No existen tolvas relacionadas a la banda [' + @ls_banda + '].';
            RETURN;
        END;



		/*Generamos el folio de la estiba*/
        SELECT @ls_folionew_Sel
            = RIGHT('0000000000' + CONVERT(VARCHAR(10), CONVERT(NUMERIC, ISNULL(MAX(c_codigo_sel), 0) + 1)), 10)
        FROM
        (
            SELECT MAX(c_codigo_sel) c_codigo_sel
            FROM dbo.t_seleccion (NOLOCK)
            WHERE c_codigo_tem = @ls_temporada
            UNION ALL
            SELECT MAX(c_codigo_sel) AS c_codigo_sel
            FROM dbo.t_seleccion_eliminado (NOLOCK)
            WHERE c_codigo_tem = @ls_temporada
        ) AS sub;

        IF RTRIM(LTRIM(ISNULL(@ls_folionew_Sel, ''))) = ''
        BEGIN
            SET @ls_folionew_Sel = '0000000001';
        END;



        BEGIN TRAN;

        /*Paso 1 - Insertamos la estiba de lavado*/
        INSERT INTO dbo.t_seleccion
        (
            c_codigo_sel,
            c_idestiba_red,
            c_codigo_tem,
            d_fecha_sel,
            c_hora_sel,
            n_pesorez_sel,
            n_porezaga_sel,
            c_codigo_usu,
            d_creacion_sel,
            c_usumod_sel,
            d_modifi_sel,
            c_activo_sel,
            c_codigo_lot,
            n_cajas_sel,
            n_pesobasura_sel,
            n_pesomerma_sel,
            n_pesohoscorojo_sel,
            n_ventadirectacampo_sel,
            n_cajasrestantes_sel,
            c_contrato_sel,
            c_estado_sel,
            c_codsec_sel,
            b_enviado_FTP,
            v_observaciones_sel,
            c_liquidacion_lpr,
            n_factor_sel,
			c_folio_sma
        )
        VALUES
        (   @ls_folionew_Sel,                                                                     /* c_codigo_sel - char(10)*/
            NULL,                                                                                 /* c_idestiba_red - char(9)*/
            @ls_temporada,                                                                        /* c_codigo_tem - char(2)*/
            CONVERT(DATE, GETDATE()),                                                             /* d_fecha_sel - datetime*/
            LEFT(CONVERT(VARCHAR, GETDATE(), 14), 8),                                             /* c_hora_sel - char(8)*/
            DEFAULT,                                                                              /* n_pesorez_sel - numeric(18, 4)*/
            DEFAULT,                                                                              /* n_porezaga_sel - numeric(18, 2)*/
            @ls_usuario,                                                                          /* c_codigo_usu - char(20)*/
            GETDATE(),                                                                            /* d_creacion_sel - datetime*/
            NULL,                                                                                 /* c_usumod_sel - char(20)*/
            NULL,                                                                                 /* d_modifi_sel - datetime*/
            '1',                                                                                  /* c_activo_sel - char(1)*/
            @ls_lote,                                                                                 /* c_codigo_lot - char(4)*/
            @ldc_bultos,                                                                          /* n_cajas_sel - int*/
            DEFAULT,                                                                              /* n_pesobasura_sel - numeric(18, 4)*/
            DEFAULT,                                                                              /* n_pesomerma_sel - numeric(18, 4)*/
            @ldc_peso,                                                                            /* n_pesohoscorojo_sel - numeric(18, 4)*/
            DEFAULT,                                                                              /* n_ventadirectacampo_sel - numeric(18, 4)*/
            @ldc_bultos,                                                                          /* n_cajasrestantes_sel - int*/
            DEFAULT,                                                                              /* c_contrato_sel - char(14)*/
            'C',                                                                                  /* c_estado_sel - char(1)*/
            DEFAULT,                                                                              /* c_codsec_sel - char(10)*/
            DEFAULT,                                                                              /* b_enviado_FTP - bit*/
            'Generación de estiba automática por  App Empaque Terminal : [' + @ls_terminal + ']', /* v_observaciones_sel - varchar(250)*/
            NULL,                                                                                 /* c_liquidacion_lpr - char(10)*/
            NULL,                                                                                  /* n_factor_sel - decimal(18, 10)*/
			@ls_idCorrida																		  /* c_folio_sma - VarChar(15)*/
            );



        /*Paso 2 - Generamos el programa de empaque con la estiba y lo dejamos corriendo*/
		/*Generamos Folio de Programa de empaque*/
        SELECT @ls_folio_new_programa
            = RIGHT('000000' + CONVERT(VARCHAR(6), CONVERT(NUMERIC, ISNULL(MAX(ultimo.c_codigo_prq), 0) + 1)), 6)
        FROM
        (
            SELECT c_codigo_prq = ISNULL(MAX(c_codigo_prq), '0')
            FROM t_programa_empaque (NOLOCK)
            WHERE c_codigo_tem = @ls_temporada
                  AND c_codigo_emp = @ls_empaque
            UNION ALL
            SELECT c_codigo_prq = ISNULL(MAX(c_codigo_prq), '0')
            FROM t_programa_empaque_eliminado (NOLOCK)
            WHERE c_codigo_tem = @ls_temporada
                  AND c_codigo_emp = @ls_empaque
        ) AS ultimo;

        IF RTRIM(LTRIM(ISNULL(@ls_folio_new_programa, ''))) = ''
        BEGIN
            SET @ls_folio_new_programa = '000001';
        END;


		/*Insertamos el programa*/
        INSERT INTO dbo.t_programa_empaque
        (
            c_codigo_tem,
            c_codigo_emp,
            c_codigo_prq,
            d_fechaIni_prq,
            d_fechaFin_prq,
            c_horaIni_prq,
            c_horaFin_prq,
            c_codigo_sel,
            c_corriendo_prq,
            c_codigo_usu,
            d_creacion_prq,
            c_usumod_prq,
            d_modifi_prq
        )
        VALUES
        (   @ls_temporada,                            /*c_codigo_tem - char(2)*/
            @ls_empaque,                              /*c_codigo_emp - char(2)*/
            @ls_folio_new_programa,                   /*c_codigo_prq - char(6)*/
            CONVERT(DATE, GETDATE()),                 /*d_fechaIni_prq - datetime*/
            NULL,                                     /*d_fechaFin_prq - datetime*/
            LEFT(CONVERT(VARCHAR, GETDATE(), 14), 8), /*c_horaIni_prq - char(8)*/
            NULL,                                     /*c_horaFin_prq - char(8)*/
            @ls_folionew_Sel,                         /*c_codigo_sel - char(10)*/
            'S',                                      /*c_corriendo_prq - char(1)*/
            @ls_usuario,                              /*c_codigo_usu - char(20)*/
            GETDATE(),                                /*d_creacion_prq - datetime*/
            NULL,                                     /*c_usumod_prq - char(20)*/
            NULL                                      /*d_modifi_prq - datetime*/
            );



        /*Paso 3 -  Insertamos el detalle del programa*/
        INSERT INTO dbo.t_programa_empaquedet
        (
            c_codigo_tem,
            c_codigo_emp,
            c_codigo_prq,
            c_codigo_tlv,
            c_codigo_pro,
            c_codigo_eti,
            c_codigo_col,
            c_codigo_pdo,
            c_hora_pqd,
            d_fecha_pqd,
            c_codempl_pqd,
            c_codigo_bnd
        )
        SELECT c_codigo_tem = @ls_temporada,
               c_codigo_emp = @ls_empaque,
               c_codigo_prq = @ls_folio_new_programa,
               c_codigo_tlv = tlv.c_codigo_tlv,
               c_codigo_pro = prg.c_codigo_pro,
               c_codigo_eti = prg.c_codigo_eti,
               c_codigo_col = prg.c_codigo_col,
               c_codigo_pdo = prg.c_codigo_pdo,
               c_hora_pqd = LEFT(CONVERT(VARCHAR, GETDATE(), 14), 8),
               d_fecha_pqd = CONVERT(DATE, GETDATE()),
               c_codempl_pqd = prg.c_codempl_pqd,
               c_codigo_bnd = @ls_banda
        FROM
        (
            SELECT tlv.c_codigo_tlv AS c_codigo_tlv,
                   tlv.v_nombre_tlv AS v_nombre_tlv,
                   bnd.c_codigo_bnd AS c_codigo_bnd,
                   bnd.v_nombre_bnd AS v_nombre_bnd,
                   lot.c_codigo_lot AS c_codigo_lot,
                   lot.v_nombre_lot AS v_nombre_lot,
                   cul.c_codigo_cul AS c_codigo_cul,
                   cul.v_nombre_cul AS v_nombre_cul,
                   eti.c_codigo_eti AS c_codigo_eti,
                   eti.v_nombre_eti AS v_nombre_eti,
                   pro.c_codigo_pro AS c_codigo_pro,
                   pro.v_nombre_pro AS v_nombre_pro,
                   col.c_codigo_col AS c_codigo_col,
                   col.v_nombre_col AS v_nombre_col,
                   prqd.c_codigo_pdo AS c_codigo_pdo,
                   prqd.c_codempl_pqd AS c_codempl_pqd
            FROM t_programa_empaquedet AS prqd (NOLOCK)
                INNER JOIN t_programa_empaque AS prq (NOLOCK)
                    ON prqd.c_codigo_emp = prq.c_codigo_emp
                       AND prqd.c_codigo_prq = prq.c_codigo_prq
                       AND prqd.c_codigo_tem = prq.c_codigo_tem
                LEFT JOIN t_producto AS pro (NOLOCK)
                    ON pro.c_codigo_pro = prqd.c_codigo_pro
                INNER JOIN t_tolva AS tlv (NOLOCK)
                    ON prqd.c_codigo_tlv = tlv.c_codigo_tlv
                       AND prqd.c_codigo_bnd = tlv.c_codigo_bnd
                INNER JOIN t_banda AS bnd (NOLOCK)
                    ON tlv.c_codigo_bnd = bnd.c_codigo_bnd
                LEFT JOIN t_etiqueta AS eti (NOLOCK)
                    ON eti.c_codigo_eti = prqd.c_codigo_eti
                INNER JOIN t_seleccion AS sel (NOLOCK)
                    ON sel.c_codigo_tem = prq.c_codigo_tem
                       AND sel.c_codigo_sel = prq.c_codigo_sel
                INNER JOIN t_lote AS lot (NOLOCK)
                    ON sel.c_codigo_lot = lot.c_codigo_lot
                       AND sel.c_codigo_tem = lot.c_codigo_tem
                INNER JOIN t_cultivo AS cul (NOLOCK)
                    ON lot.c_codigo_cul = cul.c_codigo_cul
                LEFT JOIN t_color AS col (NOLOCK)
                    ON prqd.c_codigo_col = col.c_codigo_col
            WHERE prqd.c_codigo_tem = @ls_temporada
                  AND prqd.c_codigo_emp = @ls_empaque
                  AND prq.c_corriendo_prq = 'S'
                  AND CAST(REPLACE(SUBSTRING(CONVERT(VARCHAR, prqd.d_fecha_pqd, 127), 1, 10), '-', '') + ' '
                           + prqd.c_hora_pqd AS DATETIME) =
                  (
                      SELECT MAX(CAST(REPLACE(SUBSTRING(CONVERT(VARCHAR, prqd2.d_fecha_pqd, 127), 1, 10), '-', '')
                                      + ' ' + prqd2.c_hora_pqd AS DATETIME)
                                )
                      FROM dbo.t_programa_empaquedet AS prqd2 (NOLOCK)
                      WHERE prqd2.c_codigo_emp = prqd.c_codigo_emp
                            AND prqd2.c_codigo_prq = prqd.c_codigo_prq
                            AND prqd2.c_codigo_tem = prqd.c_codigo_tem
                  )
        ) AS prg
            RIGHT JOIN t_tolva AS tlv (NOLOCK)
                ON prg.c_codigo_tlv = tlv.c_codigo_tlv
                   AND tlv.c_codigo_bnd = prg.c_codigo_bnd
            INNER JOIN t_banda AS bnd (NOLOCK)
                ON tlv.c_codigo_bnd = bnd.c_codigo_bnd
        WHERE bnd.c_codigo_bnd = @ls_banda;


		/*Final del Proceso*/
        SET @as_success = 1;
        SET @as_message
            = 'La banda empezo a correr Generando la estiba de lavado y selección ['
              + RTRIM(LTRIM(ISNULL(@ls_folionew_Sel, ''))) + '] en el Folio de Empaque ['
              + RTRIM(LTRIM(ISNULL(@ls_folio_new_programa, ''))) + ']';



        COMMIT TRAN;
    END TRY
    BEGIN CATCH
        SET @as_success = 0;
        SET @as_message = ERROR_MESSAGE();
		IF @@TRANCOUNT > 0
			ROLLBACK TRAN;
    END CATCH;
END;


