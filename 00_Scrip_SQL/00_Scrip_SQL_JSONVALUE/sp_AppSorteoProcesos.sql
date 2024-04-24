
/*|AGS|*/
IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id = OBJECT_ID(N'[dbo].[sp_AppSorteoProcesos]'))
	DROP PROCEDURE sp_AppSorteoProcesos
	GO
/*|AGS|*/
CREATE PROCEDURE [dbo].[sp_AppSorteoProcesos]
(
    @as_operation INT,
    @as_json VARCHAR(MAX),
    @as_success INT OUTPUT,
    @as_message VARCHAR(1024) OUTPUT
)
AS
SET NOCOUNT ON;

DECLARE @ls_folio VARCHAR(10)
DECLARE @ls_area VARCHAR(4);
DECLARE @ls_codigo VARCHAR(10);
DECLARE @ls_recepcion VARCHAR(10);
DECLARE @ls_conse VARCHAR(3);
DECLARE @ls_lote VARCHAR(4);
DECLARE @ld_kilos DECIMAL(9,3);
DECLARE @ln_cajas NUMERIC;
DECLARE @ls_codcaja VARCHAR(4);
DECLARE @ls_codtari VARCHAR(4);
DECLARE @ls_usu VARCHAR(20);
DECLARE	@ls_tem VARCHAR(2);
DECLARE	@ls_tiposorteo VARCHAR(1)


SET @as_message = '';
SET @as_success = 0;

IF @as_operation = 1 /*Guardado de proceso de sorteo tabla t_sortingmaduraciondet()*/
BEGIN
    BEGIN TRY
		BEGIN TRAN;
			/*SACAMOS LOS DATOS del sorteo DEL JSON*/ 
			SELECT @ls_folio = ''
			SELECT @ls_area = RTRIM(LTRIM(ISNULL(JSON_VALUE(@as_json, '$.c_codigo_are'),'')));
			SELECT @ls_codigo = RTRIM(LTRIM(ISNULL(JSON_VALUE(@as_json, '$.c_codigo'),'')));
			SELECT @ld_kilos = RTRIM(LTRIM(ISNULL(JSON_VALUE(@as_json, '$.n_kilos_dso'),'')));
			SELECT @ln_cajas = RTRIM(LTRIM(ISNULL(JSON_VALUE(@as_json, '$.n_cajas_dso'),'')));
			SELECT @ls_codcaja = RTRIM(LTRIM(ISNULL(JSON_VALUE(@as_json, '$.c_codigocaja_tcj'),'')));
			SELECT @ls_codtari = RTRIM(LTRIM(ISNULL(JSON_VALUE(@as_json, '$.c_codigotarima_tcj'),'')));
			SELECT @ls_usu = RTRIM(LTRIM(ISNULL(JSON_VALUE(@as_json, '$.c_codigo_usu'),'')));
			SELECT @ls_tiposorteo = RTRIM(LTRIM(ISNULL(JSON_VALUE(@as_json, '$.c_tipo'),'')));

			SET @ls_recepcion = left(@ls_codigo,6)
			SET @ls_conse = RIGHT(@ls_codigo,3)

			SELECT TOP 1 @ls_tem = ISNULL(c_codigo_tem,'') 
			FROM t_temporada (NOLOCK) 
			WHERE c_activo_tem = '1';

			IF @ls_tiposorteo = 'R' 
			BEGIN
			 /*VALIDAMOS QUE EXISTA */
				IF NOT EXISTS
					(	
						SELECT *
						FROM t_recepciondet (NOLOCK) 
						WHERE c_codigo_rec+c_secuencia_red = @ls_codigo
						  AND c_codigo_tem = @ls_tem
					)
					BEGIN
						SET @as_success = 0;
						SET @as_message = 'La recepción ingresada [' + @ls_recepcion + '] no existe.';
					END;
				ELSE
				BEGIN	
					IF EXISTS /*Valida que no este guardada*/
						(
							SELECT *
							FROM t_sortingmaduraciondet (NOLOCK) 
							WHERE c_codigo_rec+c_concecutivo_smd = @ls_codigo
							AND c_codigo_tem = @ls_tem
						)
						BEGIN
							SET @as_success = 0;
							SET @as_message = 'La recepción ingresada [' + @ls_recepcion + '] esta en proceso de vaciado o ya fue vaciada.';
						END;
					ELSE/*si existe la recepcion*/
						BEGIN
							SELECT @ls_lote = ISNULL(c_codigo_lot,'') 
							FROM t_recepciondet (NOLOCK) 
							WHERE c_codigo_rec = @ls_recepcion
								  AND c_codigo_tem = @ls_tem
								  AND c_secuencia_red = @ls_conse

							INSERT INTO t_sortingmaduraciondet
							 (
							   c_folio_sma ,			c_codigo_are ,		   c_codigo_rec ,		   c_concecutivo_smd,      
							   c_codigo_pal,			c_codigo_tem ,		   c_codigo_lot ,		   n_kilos_smd ,		   n_cajas_smd ,		   
							   c_codigocaja_tcj ,	   c_codigotarima_tcj ,	   c_codigo_usu ,		   d_creacion_smd ,		   
							   c_usumod_smd ,		   d_modifi_smd ,		   c_activo_smd,			c_finvaciado_smd
							 )
							VALUES
							 ( @ls_folio ,			@ls_area ,		   @ls_recepcion , 		   @ls_conse ,		    
							   '',					@ls_tem ,		   @ls_lote,		   @ld_kilos , 		   @ln_cajas , 		   
							   @ls_codcaja , 	   @ls_codtari , 	   @ls_usu , 		   GETDATE() ,
							   NULL ,				NULL , 				'1' ,			   'N'
							 )

							SET @as_success = 1;
							SET @as_message = 'Recepción [' + @ls_recepcion + '] Guardada correctamente.';
						END;
				END;
			END;
			ELSE IF (@ls_tiposorteo = 'P')
			BEGIN
				IF NOT EXISTS /*Valida que no este guardada*/
					(
					SELECT *
					FROM t_preprocesodet (NOLOCK) 
					WHERE c_codigo_pal = @ls_codigo
					AND c_codigo_tem = @ls_tem
					)
					BEGIN
						SET @as_success = 0;
						SET @as_message = 'El pallet ingresado [' + @ls_codigo + '] no existe.';
					END;
				ELSE
					BEGIN
						IF EXISTS /*Valida que no este guardada*/
							(
								SELECT *
								FROM t_sortingmaduraciondet (NOLOCK) 
								WHERE c_codigo_pal = @ls_codigo
								AND c_codigo_tem = @ls_tem
							)
							BEGIN
								SET @as_success = 0;
								SET @as_message = 'El pallet ingresado [' + @ls_codigo + '] esta en proceso de vaciado o ya fue vaciado.';
							END;
						ELSE/*si existe la recepcion*/
							BEGIN				
								SELECT @ls_lote = ISNULL(c_codigo_lot,'') 
								FROM t_preprocesodet (NOLOCK) 
								WHERE c_codigo_pal = @ls_codigo

								INSERT INTO t_sortingmaduraciondet
								 (
								   c_folio_sma ,			c_codigo_are ,		   c_codigo_rec ,		   c_concecutivo_smd,      
								   c_codigo_pal,			c_codigo_tem ,		   c_codigo_lot ,		   n_kilos_smd ,		   n_cajas_smd ,		   
								   c_codigocaja_tcj ,	   c_codigotarima_tcj ,	   c_codigo_usu ,		   d_creacion_smd ,		   
								   c_usumod_smd ,		   d_modifi_smd ,		   c_activo_smd,			c_finvaciado_smd
								 )
								VALUES
								 ( @ls_folio ,			@ls_area ,		   '' , 		   '',  
								   @ls_codigo,			@ls_tem ,		   @ls_lote,		   @ld_kilos , 		   @ln_cajas , 		   
								   @ls_codcaja , 	   @ls_codtari , 	   @ls_usu , 		   GETDATE() ,
								   NULL ,				NULL , 				'1' ,			   'N'
								 )

								SET @as_success = 1;
								SET @as_message = 'Pallet temporal [' + @ls_codigo + '] Guardado correctamente.';
							END;
					END ;
            END;
			ELSE IF @ls_tiposorteo = 'E' 
			BEGIN
				SET @as_success = 1;
				SET @as_message = 'Pallet temporal [' + @ls_codigo + '] Guardado correctamente.';
			END;
		COMMIT TRAN;
    END TRY
    BEGIN CATCH
		BEGIN TRAN
        SET @as_success = 0;
        SET @as_message = ERROR_MESSAGE();
		ROLLBACK TRAN;
    END CATCH;
END;

IF @as_operation = 2 /*finalizar vaciado de proceso de sorteo tabla t_sortingmaduraciondet*/
BEGIN
    BEGIN TRY
		BEGIN TRAN;
			DECLARE @ls_nomarea VARCHAR(200)
			DECLARE	@ll_totalpalets NUMERIC
			/*SACAMOS LOS DATOS del sorteo DEL JSON*/
			SELECT @ls_area = RTRIM(LTRIM(ISNULL(JSON_VALUE(@as_json, '$.c_codigo_are'),'')));
			SELECT @ls_usu = RTRIM(LTRIM(ISNULL(JSON_VALUE(@as_json, '$.c_codigo_usu'),'')));
			SELECT @ls_tiposorteo = RTRIM(LTRIM(ISNULL(JSON_VALUE(@as_json, '$.c_tipo'),'')));

			SELECT TOP 1 @ls_tem = ISNULL(c_codigo_tem,'') 
			FROM t_temporada (NOLOCK) 
			WHERE c_activo_tem = '1';

			 /*VALIDAMOS QUE EXISTA los registros */
			IF NOT EXISTS
				(
					SELECT *
					FROM t_sortingmaduraciondet (NOLOCK) 
					WHERE c_codigo_are = @ls_area
					AND c_codigo_tem = @ls_tem
					AND c_finvaciado_smd = 'N'
				)
				BEGIN
					SET @as_success = 0;
					SET @as_message = 'No hay registros para vaciar, favor de revisar.';
				END;
			ELSE
				BEGIN
					SELECT @ls_folio = ISNULL(MAX(c_folio_sma),'') FROM t_sortingmaduracion /*sacar folio */
					IF (@ls_folio = '' )
						BEGIN
							SET @ls_folio = '0000000001'
						END
					ELSE	
						BEGIN
							SET @ls_folio = RIGHT('0000000000'+convert(varchar(10), CONVERT(numeric,@ls_folio)+1),10)
						END;
					/*Sacamos los totales del detalle */	
					SELECT @ld_kilos = SUM(n_kilos_smd), @ln_cajas = SUM(n_cajas_smd), @ll_totalpalets = COUNT(*)
					FROM t_sortingmaduraciondet (NOLOCK) 
					WHERE c_codigo_are = @ls_area
					/*insertamos el cabecero si no existe*/
					IF NOT EXISTS	(
						SELECT *
						FROM t_sortingmaduracion
						WHERE c_folio_sma = @ls_folio
					)
					BEGIN
						INSERT INTO t_sortingmaduracion
						(
							c_folio_sma ,  c_codigo_tem ,  n_totalkilos_sma ,  n_totalcajas_sma ,
							n_totalpalets_sma ,	c_finvaciado_sma ,  c_tipo_sma,		c_codigo_usu ,  
							d_creacion_sma ,  c_usumod_sma ,	d_modifi_sma ,  c_activo_sma
						)
						VALUES
						(	@ls_folio ,			@ls_tem ,   @ld_kilos ,   @ln_cajas , 
							@ll_totalpalets ,   'S' ,   @ls_tiposorteo ,   @ls_usu , 
							 GETDATE(),	NULL,	NULL ,   '1' 
						)
					END
					/*actualizamos el detalle con el folio*/
					SET @ls_nomarea = (SELECT TOP 1 v_nombre_are FROM dbo.t_areafisica (nolock) WHERE c_codigo_are = @ls_area)
					UPDATE t_sortingmaduraciondet 
					SET /*c_finvaciado_smd = 'S',*/
						c_folio_sma = @ls_folio
					WHERE c_codigo_are = @ls_area AND c_finvaciado_smd = 'N'

					SET @as_success = 1;
					SET @as_message = 'El vaciado del área: ['+@ls_nomarea+'] se realizó correctamente. Folio['+@ls_folio+']';
				END;
			COMMIT TRAN;
    END TRY
    BEGIN CATCH
		BEGIN TRAN
        SET @as_success = 0;
        SET @as_message = ERROR_MESSAGE();
		ROLLBACK TRAN;
    END CATCH;
END;

IF @as_operation = 3 /*Eliminar registro individual del vaciado*/
BEGIN
    BEGIN TRY
		BEGIN TRAN;
			/*SACAMOS LOS DATOS del sorteo DEL JSON*/
			SELECT @ls_codigo = RTRIM(LTRIM(ISNULL(JSON_VALUE(@as_json, '$.c_codigo'),'')));

			SELECT TOP 1 @ls_tem = ISNULL(c_codigo_tem,'') 
			FROM t_temporada (NOLOCK) 
			WHERE c_activo_tem = '1';

			 /*VALIDAMOS QUE EXISTA los registros */
			IF NOT EXISTS
				(
					SELECT *
					FROM t_sortingmaduraciondet (NOLOCK) 
					WHERE c_codigo_pal = @ls_codigo OR c_codigo_rec+c_concecutivo_smd = @ls_codigo
					AND c_codigo_tem = @ls_tem
					AND c_finvaciado_smd = 'N'
				)
				BEGIN
					SET @as_success = 0;
					SET @as_message = 'El registro no existe o ya fue eliminado.';
				END;
			ELSE
				BEGIN
					DELETE t_sortingmaduraciondet
					WHERE c_codigo_pal = @ls_codigo OR c_codigo_rec+c_concecutivo_smd = @ls_codigo
					AND c_codigo_tem = @ls_tem
					AND c_finvaciado_smd = 'N'
					SET @as_success = 1;
					SET @as_message = 'El registro fue eliminado exitosamente.';
				END;
			COMMIT TRAN;
    END TRY
    BEGIN CATCH
		BEGIN TRAN
        SET @as_success = 0;
        SET @as_message = ERROR_MESSAGE();
		ROLLBACK TRAN;
    END CATCH;
END;

IF @as_operation = 4 /*Guardado de pallet temporal*/
BEGIN
    BEGIN TRY
		DECLARE @ls_secuencia VARCHAR(3);
		DECLARE @ls_gradomaduracion VARCHAR(10);
		DECLARE @ls_vaciado VARCHAR(10);
		DECLARE @ls_usuario VARCHAR(20);
		DECLARE @newcod VARCHAR(10);
		DECLARE @ls_qr VARCHAR(10);
		DECLARE @ln_totalcajas NUMERIC;
		DECLARE @ld_totalkilos DECIMAL(18,3);

		/*SACAMOS LOS DATOS del sorteo DEL JSON*/
		SELECT @ls_vaciado = RTRIM(LTRIM(ISNULL(JSON_VALUE(@as_json, '$.c_codigo_sma'),'')));
		SELECT @ls_qr = RTRIM(LTRIM(ISNULL(JSON_VALUE(@as_json, '$.c_qr'),'')));
		SELECT @ls_gradomaduracion = RTRIM(LTRIM(ISNULL(JSON_VALUE(@as_json, '$.c_codigo_gdm'),'')));
		SELECT @ln_totalcajas = RTRIM(LTRIM(ISNULL(JSON_VALUE(@as_json, '$.n_cajas_dso'),'')));
		SELECT @ld_totalkilos = CONVERT(DECIMAL(18,3),RTRIM(LTRIM(ISNULL(JSON_VALUE(@as_json, '$.n_kilos_dso'),''))));
		SELECT @ls_usuario = RTRIM(LTRIM(ISNULL(JSON_VALUE(@as_json, '$.c_codigo_usu'),'')));

		SELECT TOP 1 @ls_tem = ISNULL(c_codigo_tem,'') 
		FROM t_temporada (NOLOCK) 
		WHERE c_activo_tem = '1';

		IF  NOT EXISTS(SELECT * FROM t_paletemporal WHERE c_codigo_sma = @ls_vaciado AND c_codigo_tem = @ls_tem AND c_finalizado_pte = 'N' )
			BEGIN
				SELECT @newcod = ISNULL(MAX(c_codigo_pte),'0') FROM t_paletemporal
				SET @newcod = RIGHT('0000000000'+CONVERT(VARCHAR(10),CONVERT(NUMERIC,@newcod)+1),10)
				SET @ls_secuencia = '001'
			END;
		ELSE
			BEGIN
				SELECT @newcod = ISNULL(MAX(pte.c_codigo_pte), '')
				FROM t_paletemporal pte (NOLOCK)
					INNER JOIN dbo.t_paletemporaldet det (NOLOCK)
						ON det.c_codigo_pte = pte.c_codigo_pte
						   AND pte.c_codigo_tem = det.c_codigo_tem
					WHERE pte.c_codigo_sma = @ls_vaciado 
					AND pte.c_codigo_tem = @ls_tem
					AND pte.c_finalizado_pte = 'N';

				SELECT @ls_secuencia = ISNULL(MAX(c_concecutivo_pte),'') 
				FROM t_paletemporaldet (nolock)
				WHERE c_codigo_tem = @ls_tem 
				AND c_codigo_pte = @newcod;

				SET @ls_secuencia = RIGHT('000'+CONVERT(VARCHAR(3),CONVERT(NUMERIC,@ls_secuencia)+1),3)
			END ;

			/*VALIDAMOS QUE EXISTA el vaciado */
		IF NOT EXISTS
			(
				SELECT *
				FROM t_sortingmaduracion (NOLOCK) 
				WHERE c_folio_sma = @ls_vaciado
					AND c_codigo_tem = @ls_tem
			)
			BEGIN
				SET @as_success = 0;
				SET @as_message = 'El vaciado [' + @ls_vaciado + '] no existe.';
			END;
		ELSE
			BEGIN
				IF NOT EXISTS (SELECT * FROM dbo.t_paletemporal (NOLOCK) WHERE c_codigo_pte = @newcod AND c_codigo_sma = @ls_vaciado AND c_codigo_tem = @ls_tem)
					BEGIN	
						INSERT INTO dbo.t_paletemporal
						(
							c_codigo_pte,	c_codqrtemp_pte,	c_codigo_tem,
							d_totcaja_pte ,		d_totkilos_pte,		d_asignacionqr_pte,	
							d_liberacionqr_pte,	c_codigo_are,	c_ubicacion_pte,  c_codigo_cal,    
							c_finalizado_pte,    c_codigo_usu,    d_creacion_dso,    c_usumod_dso,
							d_modifi_dso,    c_activo_dso
						)
						VALUES
						(   
							@newcod,    @ls_qr,    @ls_tem,       
							@ln_totalcajas, @ld_totalkilos, GETDATE(), 
							NULL, NULL, NULL,  NULL,   
							'N',   @ls_usuario,    GETDATE(),  NULL,      
							NULL,   '1'         
							)
					END;
				ELSE	
					BEGIN
							UPDATE t_paletemporal 
							SET d_totcaja_pte =   @ln_totalcajas
							,d_totkilos_pte =  @ld_totalkilos
							WHERE c_codigo_sma = @ls_vaciado
							AND c_codigo_pte = @newcod 
							AND c_codigo_tem = @ls_tem
					END;

				INSERT INTO dbo.t_paletemporaldet
				(
					c_codigo_pte,    c_concecutivo_pte,    c_codigo_sma,    c_codigo_tem,
					c_codigo_usu,    d_creacion_dso,    c_usumod_dso,    d_modifi_dso,
					c_activo_dso
				)
				VALUES
				(   @newcod,       @ls_secuencia,       @ls_vaciado,       @ls_tem,   
					@ls_usuario,     GETDATE(),     NULL,     NULL, 
					'1'    
				)

				UPDATE t_sortingmaduraciondet 
				SET c_codigo_pte = @newcod 
				WHERE c_folio_sma = @ls_vaciado 
					AND c_codigo_tem = @ls_tem
					AND	c_finvaciado_smd = 'S'
						
				SET @as_success = 1;
				SET @as_message = 'Pallet temporal [' + @newcod + @ls_secuencia +  '] Guardada correctamente.';
			END;	
    END TRY
    BEGIN CATCH
		BEGIN TRAN
        SET @as_success = 0;
        SET @as_message = ERROR_MESSAGE();
		ROLLBACK TRAN;
    END CATCH;
END;

IF @as_operation = 5 /*Eliminar registro individual del t_paletemporal */
BEGIN
    BEGIN TRY
		BEGIN TRAN;
			DECLARE @ls_codpte VARCHAR(20)
			DECLARE @ls_codqr VARCHAR(10)
			/*SACAMOS LOS DATOS del sorteo DEL JSON*/
			SELECT @ls_codqr = RTRIM(LTRIM(ISNULL(JSON_VALUE(@as_json, '$.c_codigo'),'')));
			SELECT @ls_vaciado = RTRIM(LTRIM(ISNULL(JSON_VALUE(@as_json, '$.c_codigo_sma'),'')));
			SELECT @ln_cajas = RTRIM(LTRIM(ISNULL(JSON_VALUE(@as_json, '$.n_cajas_sma'),'')));
			SELECT @ld_kilos = RTRIM(LTRIM(ISNULL(JSON_VALUE(@as_json, '$.n_kilos_sma'),'')));


			SELECT TOP 1 @ls_tem = ISNULL(c_codigo_tem,'') 
			FROM t_temporada (NOLOCK) 
			WHERE c_activo_tem = '1';

			SELECT @ls_codpte = c_codigo_pte FROM t_paletemporal WHERE c_codqrtemp_pte = @ls_codqr

			DELETE dbo.t_paletemporaldet 
			WHERE c_codigo_pte = @ls_codpte 
				AND c_codigo_sma = @ls_vaciado
				AND c_codigo_tem = @ls_tem;

			DELETE t_paletemporal
			WHERE c_codigo_sma = @ls_vaciado 
				AND c_codigo_tem = @ls_tem
				AND c_codqrtemp_pte = @ls_codqr

			SET @as_success = 1;
			SET @as_message = 'El registro fue retirado exitosamente del listado.';
			COMMIT TRAN;
    END TRY
    BEGIN CATCH
		BEGIN TRAN
        SET @as_success = 0;
        SET @as_message = ERROR_MESSAGE();
		ROLLBACK TRAN;
    END CATCH;
END;

IF @as_operation = 6 /*Finalizar palet temporal*/
	BEGIN	
		BEGIN TRY
			SELECT @ls_codigo = RTRIM(LTRIM(ISNULL(JSON_VALUE(@as_json, '$.c_codigo'),'')));
			IF EXISTS (SELECT * FROM dbo.t_paletemporal WHERE c_codigo_pte = @ls_codigo)
				BEGIN	
					UPDATE dbo.t_paletemporal SET c_finalizado_pte = 'S' WHERE c_codigo_pte = @ls_codigo
				END;
			SET @as_success = 1;
			SET @as_message = 'Pallet Temporal Finalizado correctamente.'
		END TRY	
	    BEGIN CATCH
			BEGIN TRAN
			SET @as_success = 0;
			SET @as_message = ERROR_MESSAGE();
			ROLLBACK TRAN;
		END CATCH;
	END;

IF @as_operation = 7 /*Guardado de pallet temporal detalle*/
BEGIN
    BEGIN TRY
		/*DECLARE @ls_secuencia VARCHAR(3);
		DECLARE @ls_gradomaduracion VARCHAR(10);
		DECLARE @ls_vaciado VARCHAR(10);
		DECLARE @ls_usuario VARCHAR(20);
		DECLARE @newcod VARCHAR(10);
		DECLARE @ls_qr VARCHAR(10);
		DECLARE @ln_totalcajas NUMERIC;
		DECLARE @ld_totalkilos DECIMAL(18,3);*/
		DECLARE @ln_cajasdet NUMERIC;
		DECLARE @ld_kilosdet DECIMAL(18,3);

		/*SACAMOS LOS DATOS del sorteo DEL JSON*/
		SELECT @ls_vaciado = RTRIM(LTRIM(ISNULL(JSON_VALUE(@as_json, '$.c_codigo_sma'),'')));
		SELECT @ls_qr = RTRIM(LTRIM(ISNULL(JSON_VALUE(@as_json, '$.c_qr'),'')));
		SELECT @ls_gradomaduracion = RTRIM(LTRIM(ISNULL(JSON_VALUE(@as_json, '$.c_codigo_gdm'),'')));
		SELECT @ln_totalcajas = RTRIM(LTRIM(ISNULL(JSON_VALUE(@as_json, '$.n_cajas_dso'),'')));
		SELECT @ld_totalkilos = CONVERT(DECIMAL(18,3),RTRIM(LTRIM(ISNULL(JSON_VALUE(@as_json, '$.n_kilos_dso'),''))));
		SELECT @ls_usuario = RTRIM(LTRIM(ISNULL(JSON_VALUE(@as_json, '$.c_codigo_usu'),'')));
		SELECT @ln_cajasdet = RTRIM(LTRIM(ISNULL(JSON_VALUE(@as_json, '$.n_cajas'),'')));
		SELECT @ld_kilosdet = CONVERT(DECIMAL(18,3),RTRIM(LTRIM(ISNULL(JSON_VALUE(@as_json, '$.n_kilos'),''))));

		SELECT TOP 1 @ls_tem = ISNULL(c_codigo_tem,'') 
		FROM t_temporada (NOLOCK) 
		WHERE c_activo_tem = '1';

		--IF  NOT EXISTS(SELECT * FROM t_paletemporal WHERE c_codigo_sma = @ls_vaciado AND c_codigo_tem = @ls_tem AND c_finalizado_pte = 'N' )
		--	BEGIN
				SELECT @newcod = ISNULL(MAX(c_codigo_pte),'0') FROM t_paletemporal
				SET @newcod = RIGHT('0000000000'+CONVERT(VARCHAR(10),CONVERT(NUMERIC,@newcod)+1),10)
				SET @ls_secuencia = '001'
		--	END;
		--ELSE
		--	BEGIN
		--		SELECT @newcod = ISNULL(MAX(pte.c_codigo_pte), '')
		--		FROM t_paletemporal pte (NOLOCK)
		--			INNER JOIN dbo.t_paletemporaldet det (NOLOCK)
		--				ON det.c_codigo_pte = pte.c_codigo_pte
		--				   AND pte.c_codigo_tem = det.c_codigo_tem
		--			WHERE pte.c_codigo_sma = @ls_vaciado 
		--			AND pte.c_codigo_tem = @ls_tem
		--			AND pte.c_finalizado_pte = 'N';

		--		SELECT @ls_secuencia = ISNULL(MAX(c_concecutivo_pte),'') 
		--		FROM t_paletemporaldet (nolock)
		--		WHERE c_codigo_tem = @ls_tem 
		--		AND c_codigo_pte = @newcod;

		--		SET @ls_secuencia = RIGHT('000'+CONVERT(VARCHAR(3),CONVERT(NUMERIC,@ls_secuencia)+1),3)
		--	END ;

			/*VALIDAMOS QUE EXISTA el vaciado */
		IF NOT EXISTS
			(
				SELECT *
				FROM t_sortingmaduracion (NOLOCK) 
				WHERE c_folio_sma = @ls_vaciado
					AND c_codigo_tem = @ls_tem
			)
			BEGIN
				SET @as_success = 0;
				SET @as_message = 'El vaciado [' + @ls_vaciado + '] no existe.';
			END;
		ELSE
			BEGIN
				IF NOT EXISTS (SELECT * FROM dbo.t_paletemporal WHERE c_codigo_pte = @newcod AND c_codigo_sma = @ls_vaciado AND c_codigo_tem = @ls_tem)
					BEGIN	
						INSERT INTO dbo.t_paletemporal
						(
							c_codigo_pte,	c_codqrtemp_pte,	c_codigo_tem,
							d_totcaja_pte ,		d_totkilos_pte,		d_asignacionqr_pte,	
							d_liberacionqr_pte,	c_codigo_are,	c_ubicacion_pte,  c_codigo_cal,    
							c_finalizado_pte,    c_codigo_usu,    d_creacion_dso,    c_usumod_dso,
							d_modifi_dso,    c_activo_dso, c_codigo_sma
						)
						VALUES
						(   
							@newcod,    @ls_qr,    @ls_tem,       
							 @ln_totalcajas, @ld_totalkilos, GETDATE(), 
							NULL, NULL, NULL,  NULL,   
							'N',   @ls_usuario,    GETDATE(),  NULL,      
							NULL,   '1'     ,@ls_vaciado    
						)

						INSERT INTO dbo.t_paletemporaldet
						(
							c_codigo_pte,    c_concecutivo_pte,    c_codigo_sma,    c_codigo_tem,
							c_codigo_usu,    d_creacion_dso,    c_usumod_dso,    d_modifi_dso,
							c_activo_dso,	 n_cajas_pte,		n_kilos_pte, c_codigo_gma
						)
						VALUES
						(   @newcod,       @ls_secuencia,       @ls_vaciado,       @ls_tem,   
							@ls_usuario,     GETDATE(),     NULL,     NULL, 
							'1'    ,@ln_cajasdet		,@ld_kilosdet, @ls_gradomaduracion
						)
					END;
				ELSE	
					BEGIN
						UPDATE t_paletemporal 
						SET d_totcaja_pte =   @ln_totalcajas
							,d_totkilos_pte =  @ld_totalkilos
						WHERE c_codigo_sma = @ls_vaciado
						AND c_codigo_pte = @newcod 
						AND c_codigo_tem = @ls_tem

						DELETE t_paletemporaldet 
						WHERE c_codigo_sma = @ls_vaciado
						AND c_codigo_pte = @newcod 
						AND c_codigo_tem = @ls_tem

						INSERT INTO dbo.t_paletemporaldet
						(
							c_codigo_pte,    c_concecutivo_pte,    c_codigo_sma,    c_codigo_tem,
							c_codigo_usu,    d_creacion_dso,    c_usumod_dso,    d_modifi_dso,
							c_activo_dso,	 n_cajas_pte,		n_kilos_pte, c_codigo_gma
						)
						VALUES
						(   @newcod,       @ls_secuencia,       @ls_vaciado,       @ls_tem,   
							@ls_usuario,     GETDATE(),     NULL,     NULL, 
							'1'    ,@ln_cajasdet		,@ld_kilosdet, @ls_gradomaduracion
						)
					END;
						
				SET @as_success = 1;
				SET @as_message = 'Pallet temporal [' + @newcod + @ls_secuencia +  '] Guardada correctamente.';
			END;	
    END TRY
    BEGIN CATCH
		BEGIN TRAN
        SET @as_success = 0;
        SET @as_message = ERROR_MESSAGE();
		ROLLBACK TRAN;
    END CATCH;
END;


