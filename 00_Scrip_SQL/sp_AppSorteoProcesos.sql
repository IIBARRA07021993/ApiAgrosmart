
/*|AGS|*/
IF EXISTS
(
    SELECT *
    FROM dbo.sysobjects
    WHERE id = OBJECT_ID(N'[dbo].[sp_AppSorteoProcesos]')
)
    DROP PROCEDURE sp_AppSorteoProcesos;
GO


/*|AGS|*/
CREATE PROCEDURE [dbo].[sp_AppSorteoProcesos]
(
	@as_operation	INT,
    @as_json		VARCHAR(MAX),
    @as_success		INT				OUTPUT,
    @as_message		VARCHAR(1024)	OUTPUT
)
AS
SET NOCOUNT ON;

DECLARE @xml XML,
		@ls_folio				VARCHAR(15),
		@ls_area				VARCHAR(4),
		@ls_codigo				VARCHAR(22),
		@ls_recepcion			VARCHAR(10),
		@ls_conse				VARCHAR(3),
		@ls_lote				VARCHAR(4),
		@ls_lote2				VARCHAR(4),
		@ld_kilos				DECIMAL(9,3),
		@ln_cajas				NUMERIC,
		@ls_codcaja				VARCHAR(4),
		@ls_codtari				VARCHAR(4),
		@ls_tem					VARCHAR(2),
		@ls_tiposorteo			VARCHAR(2),
		@ls_secuencia			VARCHAR(3),
		@ls_gradomaduracion		VARCHAR(4),
		@ls_vaciado				VARCHAR(15),
		@ls_usuario				VARCHAR(20),
		@newcod					VARCHAR(10),
		@ls_qr					VARCHAR(22),
		@ln_totalcajas			NUMERIC,
		@ld_totalkilos			DECIMAL(18,3),
		@ls_empaque				VARCHAR(2),
		@ls_nivel				VARCHAR(4),
        @ls_nomnivel			VARCHAR(100),
        @ls_columna				VARCHAR(4),
        @ls_nomcolumna			VARCHAR(100),
        @ls_posicion			VARCHAR(4),
        @ls_nomposicion			VARCHAR(100),
        @ls_espaciofisico		VARCHAR(10),
        @ls_presentacionpal		VARCHAR(50),
		@ld_fecha				DATETIME,
		@ls_codpte				VARCHAR(20),
		@ls_calibre				VARCHAR(4),
		@ls_codigo_pro			VARCHAR(4),
		@ls_codigo_eti			VARCHAR(2),
		@ls_codigo_col			VARCHAR(2),
		@ls_terminal			VARCHAR(100),
		@ls_palreal				VARCHAR(10),
		@razon					INT,
		@sKilos					VARCHAR(5),
		@sCajas					VARCHAR(4),
		@ls_empaque2			VARCHAR(2),
		@idtraspaso				INT	,
		@ll_totalpalets			NUMERIC = 0 ,
		@ls_nomarea				VARCHAR(200)

SET @as_message = '';
SET @as_success = 0;
SELECT @xml = dbo.fn_parse_json2xml(@as_json);

IF @as_operation = 1 /*Guardado de proceso de sorteo tabla t_sortingmaduraciondet()*/
BEGIN
    BEGIN TRY
		--BEGIN TRAN;
			/*SACAMOS LOS DATOS del sorteo DEL JSON*/ 
			SELECT  @ls_folio		= RTRIM(LTRIM(ISNULL(n.el.value('c_folio[1]',				'varchar( 15)'),''))),
					 @ls_area		= RTRIM(LTRIM(ISNULL(n.el.value('c_codigo_are[1]',			'varchar( 4)'),''))),
					 @ls_codigo		= RTRIM(LTRIM(ISNULL(n.el.value('c_codigo[1]',				'varchar(22)'),''))),
					 @sKilos		= RTRIM(LTRIM(ISNULL(n.el.value('n_kilos_dso[1]',			'VarChar( 5)'),''))),
					 @scajas		= RTRIM(LTRIM(ISNULL(n.el.value('n_cajas_dso[1]',			'varchar( 4)'),''))),
					 @ls_codcaja	= RTRIM(LTRIM(ISNULL(n.el.value('c_codigocaja_tcj[1]',		'varchar( 4)'),''))),
					 @ls_codtari	= RTRIM(LTRIM(ISNULL(n.el.value('c_codigotarima_tcj[1]',	'varchar( 4)'),''))),
					 @ls_usuario	= RTRIM(LTRIM(ISNULL(n.el.value('c_codigo_usu[1]',			'varchar(20)'),''))),
					 @ls_tiposorteo = RTRIM(LTRIM(ISNULL(n.el.value('c_tipo[1]',				'varchar( 1)'),''))),
				     @ls_tem		= RTRIM(LTRIM(ISNULL(n.el.value('c_codigo_tem[1]',			'varchar( 2)'),''))),
					 @ls_empaque	= RTRIM(LTRIM(ISNULL(n.el.value('c_codigo_emp[1]',			'varchar( 2)'),''))),
					 @ls_lote		= RTRIM(LTRIM(ISNULL(n.el.value('c_codigo_lot[1]',			'varchar( 4)'),''))),
					 @razon			= RTRIM(LTRIM(ISNULL(n.el.value('idrazon[1]',				'tinyint'),'')))
			FROM @xml.nodes('/') n(el);

			SET @ls_recepcion = LEFT(@ls_codigo,6)
			SET @ls_conse = RIGHT(@ls_codigo,3)

			IF ISNUMERIC(@sKilos) = 1
				SET @ld_Kilos = CONVERT(NUMERIC, @sKilos)
			ELSE
				SET @ld_Kilos = 0
				
			IF ISNUMERIC(@sCajas) = 1
				SET @ln_cajas = CONVERT(NUMERIC, @sCajas)
			ELSE
				SET @ln_cajas = 0

			IF (SELECT COUNT(1) FROM dbo.t_areafisica (NOLOCK) WHERE c_codigo_are = @ls_area AND c_tipo_are = '05' ) <= 0 
				begin
					SET @as_success = 0;
					SET @as_message = 'El Área ingresada[' + @ls_area + '] no existe o no es valida.[Tipo 05]';
					RETURN 
				END

			IF (@ls_folio = '' )
				SET @ls_folio =  CONVERT(VARCHAR,RIGHT(DATEPART(YEAR,GETDATE()),2))+ RIGHT('000'+ CONVERT(VARCHAR,DATEPART(DAYOFYEAR,GETDATE())),3)+ @ls_area +@ls_lote+ @ls_tem
			ELSE
			BEGIN	
				IF NOT EXISTS(SELECT c_folio_sma FROM dbo.t_sortingmaduraciondet WHERE c_folio_sma = @ls_folio AND c_finvaciado_smd = 'N' ) 
				SET @ls_folio =  CONVERT(VARCHAR,RIGHT(DATEPART(YEAR,GETDATE()),2))+ RIGHT('000'+ CONVERT(VARCHAR,DATEPART(DAYOFYEAR,GETDATE())),3)+ @ls_area +@ls_lote+ @ls_tem
			END 

			IF (@razon = '')
			BEGIN 
				SET @as_success = 0;
				SET @as_message = 'La razon de la corrida no puede quedar vacio, favor de revisar.';
				RETURN 
			END 

			IF (@ls_lote = '')
			BEGIN 
				SET @as_success = 0;
				SET @as_message = 'El lote de la corrida no puede quedar vacio, favor de revisar.';
				RETURN 
			END 

			/*Guardar cabecero */
			BEGIN TRAN
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
					d_creacion_sma ,  c_usumod_sma ,	d_modifi_sma ,  c_activo_sma,	c_tipocorrida_sma, c_codigo_emp, idrazon
				)
				VALUES
				(	@ls_folio ,			@ls_tem ,   @ld_kilos ,   @ln_cajas , 
					@ll_totalpalets ,   'S' ,   @ls_tiposorteo ,   @ls_usuario , 
					GETDATE(),	NULL,	NULL ,   '1' , 'M',		@ls_empaque , @razon
				)
			END
			/*Guardar detalle */
			IF (@ls_tiposorteo = 'R' )
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
							SELECT @ls_lote = RTRIM(LTRIM(ISNULL(c_codigo_lot,''))) 
							FROM t_recepciondet (NOLOCK) 
							WHERE c_codigo_rec = @ls_recepcion
								  AND c_codigo_tem = @ls_tem
								  AND c_secuencia_red = @ls_conse

							SELECT TOP 1 @ls_lote2 =  LTRIM(RTRIM(ISNULL(c_codigo_lot,'')))  
							FROM dbo.t_sortingmaduraciondet (NOLOCK)
							WHERE c_codigo_are = @ls_area
								  AND c_codigo_tem = @ls_tem
								  and c_activo_smd = '1'
								  AND c_finvaciado_smd = 'N'

							IF (@ls_lote <> @ls_lote2 )
							BEGIN	
								SET @as_success = 0;
								SET @as_message = 'El pallet ingresado [' + @ls_codigo + '] no pertenece al bloque: ['+@ls_lote2+'] Favor de revisar.';
								RETURN 
							END;
							
							/*BEGIN TRAN*/
							INSERT INTO t_sortingmaduraciondet
							 (
							   c_folio_sma ,			c_codigo_are ,		   c_codigo_rec ,		   c_concecutivo_smd,      
							   c_codigo_pal,			c_codigo_tem ,		   c_codigo_lot ,		   n_kilos_smd ,		   n_cajas_smd ,		   
							   c_codigocaja_tcj ,	   c_codigotarima_tcj ,	   c_codigo_usu ,		   d_creacion_smd ,		   
							   c_usumod_smd ,		   d_modifi_smd ,		   c_activo_smd,			c_finvaciado_smd, c_codigo_emp
							 )
							VALUES
							 ( @ls_folio ,			@ls_area ,		   @ls_recepcion , 		   @ls_conse ,		    
							   '',					@ls_tem ,		   @ls_lote,		   @ld_kilos , 		   @ln_cajas , 		   
							   @ls_codcaja , 	   @ls_codtari , 	   @ls_usuario , 		   GETDATE() ,
							   NULL ,				NULL , 				'1' ,			   'N', @ls_empaque
							 )

							SET @as_success = 1;
							SET @as_message = 'Recepción [' + @ls_recepcion + '] Guardada correctamente.';
							/*COMMIT TRAN*/
						END;
				END;
			END;
			ELSE IF (@ls_tiposorteo = 'P')
			BEGIN
				IF NOT EXISTS /*Valida que no este guardada*/
					(
					SELECT 1
					FROM dbo.t_paletemporal (NOLOCK) 
					WHERE (c_codqrtemp_pte = @ls_codigo
					AND c_codigo_tem = @ls_tem
					AND c_codigo_emp = @ls_empaque
					AND c_finalizado_pte = 'N')
					OR (c_codigo_pte = @ls_codigo AND c_activo_dso = '1' AND c_codigo_tem = @ls_tem AND c_codigo_emp = @ls_empaque)
					)
					BEGIN
						SET @as_success = 0;
						SET @as_message = 'El QR ingresado [' + @ls_codigo + '] no existe o no esta asignado a un pallet.';
						ROLLBACK TRAN
						RETURN 
					END;
				ELSE
					BEGIN
						IF EXISTS /*Valida que no este guardada*/
							(
								SELECT 1  FROM dbo.t_paletemporal pal
								INNER JOIN  dbo.t_sortingmaduraciondet det 
									ON pal.c_codigo_pte = det.c_codigo_pal
										AND pal.c_codigo_emp = det.c_codigo_emp
										AND pal.c_codigo_tem = det.c_codigo_tem
									WHERE pal.c_codqrtemp_pte = @ls_codigo
										AND det.c_codigo_tem = @ls_tem
										AND det.c_codigo_emp = @ls_empaque
										AND det.c_finvaciado_smd = 'N'
							)
							BEGIN
								SET @as_success = 0;
								SET @as_message = 'El pallet ingresado [' + @ls_codigo + '] esta en proceso de vaciado o ya fue vaciado.';
								ROLLBACK TRAN
								RETURN 
							END;
						ELSE/*si existe el palet*/
							BEGIN			
								DECLARE @ls_folio2 VARCHAR(22)
								SELECT DISTINCT TOP 1 
										@ls_lote = ISNULL(SUBSTRING(Pal.c_codigo_sma,10,4) ,''),--ISNULL(smd.c_codigo_lot ,''),
										@ls_codpte =pal.c_codigo_pte ,
										@ls_folio2 = pal.c_codigo_sma 
								  FROM	t_paletemporal pal (NOLOCK)
								 --INNER JOIN t_sortingmaduraciondet smd (NOLOCK) ON pal.c_codigo_sma = smd.c_folio_sma
								 WHERE ((pal.c_codqrtemp_pte = @ls_codigo 
								   AND Pal.c_finalizado_pte = 'N') OR (pal.c_codigo_pte = @ls_codigo))
								   AND Pal.c_activo_dso = '1'
								ORDER BY pal.c_codigo_sma DESC

								IF (ISNULL(@ls_codpte,'') = '') SET @ls_codpte = @ls_codigo

								SELECT TOP 1 @ls_lote2 =  ISNULL(c_codigo_lot,'')  
								FROM dbo.t_sortingmaduraciondet (NOLOCK)
								WHERE c_codigo_are = @ls_area
									  AND c_codigo_tem = @ls_tem
									  and c_activo_smd = '1'
									  AND c_finvaciado_smd = 'N'

								IF (@ls_lote <> @ls_lote2 ) AND 
								NOT EXISTS(SELECT * FROM dbo.t_paletemporal_consolidado WHERE c_codigo_ptc = @ls_codigo AND c_codigo_tem = @ls_tem AND c_codigo_emp = @ls_empaque AND bloqueid = @ls_lote2 )
								BEGIN	
									SET @as_success = 0;
									SET @as_message = 'El pallet ingresado [' + @ls_codigo + '] no pertenece al bloque: ['+@ls_lote2+'] Favor de revisar.';
									ROLLBACK TRAN
									RETURN 
								END;

								IF LEN(@ls_codpte) > 10 -- Es un QR y se busca el pallet
								BEGIN
									SELECT	@ls_codpte = c_codigo_pte
									  FROM	dbo.t_paletemporal (NoLock)
									 WHERE	c_codqrtemp_pte = @ls_codpte
									   AND	c_finalizado_pte = 'N'
									   AND	c_activo_dso = '1'
								END

								/*BEGIN TRAN*/
								INSERT INTO t_sortingmaduraciondet
								 (
								   c_folio_sma ,			c_codigo_are ,		   c_codigo_rec ,		   c_concecutivo_smd,      
								   c_codigo_pal,			c_codigo_tem ,		   c_codigo_lot ,		   n_kilos_smd ,		   n_cajas_smd ,		   
								   c_codigocaja_tcj ,	   c_codigotarima_tcj ,	   c_codigo_usu ,		   d_creacion_smd ,		   
								   c_usumod_smd ,		   d_modifi_smd ,		   c_activo_smd,			c_finvaciado_smd, c_codigo_emp
								 )
								VALUES
								 ( @ls_folio ,			@ls_area ,		   '' , 		   '',  
								   @ls_codpte,			@ls_tem ,		   @ls_lote,		   @ld_kilos , 		   @ln_cajas , 		   
								   @ls_codcaja , 	   @ls_codtari , 	   @ls_usuario , 		   GETDATE() ,
								   NULL ,				NULL , 				'1' ,			   'N' ,	@ls_empaque
								 )

								 /*liberar QR */
								UPDATE dbo.t_paletemporal SET  c_finalizado_pte = 'S', c_activo_dso = '0' WHERE c_codigo_pte = @ls_codpte AND c_codigo_tem = @ls_tem AND c_codigo_emp = @ls_empaque 

								SET @as_success = 1;
								SET @as_message = 'Corrida guardada correctamente';
								/*COMMIT TRAN*/
							END;
					END ;
            END;
			ELSE IF @ls_tiposorteo = 'E' 
			BEGIN
				/*VALIDAMOS QUE EXISTA */
				IF NOT EXISTS
					(	
						SELECT *
						FROM t_recepciondet (NOLOCK) 
						WHERE c_codexterno_rec = @ls_codigo
						  AND c_codigo_tem = @ls_tem
					)
					BEGIN
						SET @as_success = 0;
						SET @as_message = 'La recepción ingresada [' + @ls_recepcion + '] no existe.';
						ROLLBACK TRAN
						RETURN 
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
							SET @as_message = 'La recepción ingresada [' + @ls_recepcion + '] esta en proceso de vaciado o ya fue vaciada.';
							ROLLBACK TRAN
							RETURN 
						END;
					ELSE/*si existe la recepcion*/
						BEGIN
							SELECT @ls_lote = ISNULL(c_codigo_lot,'') , @ls_recepcion = ISNULL(c_codigo_rec,''), @ls_conse = ISNULL(c_secuencia_red,'')
							FROM t_recepciondet (NOLOCK) 
							WHERE c_codexterno_rec = @ls_codigo
								  AND c_codigo_tem = @ls_tem

								SELECT TOP 1 @ls_lote2 =  ISNULL(c_codigo_lot,'')  
								FROM dbo.t_sortingmaduraciondet (NOLOCK)
								WHERE c_codigo_are = @ls_area
									  AND c_codigo_tem = @ls_tem
									  and c_activo_smd = '1'
									  AND c_finvaciado_smd = 'N'

								IF (@ls_lote <> @ls_lote2 )
								BEGIN	
									SET @as_success = 0;
									SET @as_message = 'El pallet ingresado [' + @ls_codigo + '] no pertenece al bloque: ['+@ls_lote2+'] Favor de revisar.';
									ROLLBACK TRAN
									RETURN 
								END;
							
							/*BEGIN TRAN*/
							INSERT INTO t_sortingmaduraciondet
							 (
							   c_folio_sma ,			c_codigo_are ,		   c_codigo_rec ,		   c_concecutivo_smd,      
							   c_codigo_pal,			c_codigo_tem ,		   c_codigo_lot ,		   n_kilos_smd ,		   n_cajas_smd ,		   
							   c_codigocaja_tcj ,	   c_codigotarima_tcj ,	   c_codigo_usu ,		   d_creacion_smd ,		   
							   c_usumod_smd ,		   d_modifi_smd ,		   c_activo_smd,			c_finvaciado_smd, c_codigo_emp
							 )
							VALUES
							 ( @ls_folio ,			@ls_area ,		   @ls_recepcion , 		   @ls_conse ,		    
							   @ls_codigo,					@ls_tem ,		   @ls_lote,		   @ld_kilos , 		   @ln_cajas , 		   
							   @ls_codcaja , 	   @ls_codtari , 	   @ls_usuario , 		   GETDATE() ,
							   NULL ,				NULL , 				'1' ,			   'N', @ls_empaque
							 )

							SET @as_success = 1;
							SET @as_message = 'palet externo [' + @ls_codigo + '] Guardado correctamente.';
							/*COMMIT TRAN*/
						END;
				END;
			END;
			ELSE IF @ls_tiposorteo = 'T' 
			BEGIN
				/*VALIDAMOS QUE EXISTA */
				IF NOT EXISTS
					(	
						SELECT *
						FROM t_palet (NOLOCK) 
						WHERE c_codigo_pal = @ls_codigo
						  AND c_codigo_tem = @ls_tem
						  AND c_codigo_emp = @ls_empaque
					)
					BEGIN
						SET @as_success = 0;
						SET @as_message = 'El pallet ingresado [' + @ls_codigo + '] no existe.';
						ROLLBACK TRAN
						RETURN 
					END;
				ELSE
				BEGIN	
					IF EXISTS /*Valida que no este guardada*/
						(
							SELECT *
							FROM t_sortingmaduraciondet (NOLOCK) 
							WHERE c_codigo_pal = @ls_codigo
							AND c_codigo_tem = @ls_tem
							AND c_codigo_emp = @ls_empaque
						)
						BEGIN
							SET @as_success = 0;
							SET @as_message = 'El pallet ingresado [' + @ls_codigo + '] esta en proceso de vaciado o ya fue vaciado.';
							ROLLBACK TRAN
							RETURN 
						END;
					ELSE/*si existe la recepcion*/
						BEGIN
							SELECT @ls_lote = ISNULL(c_codigo_lot,'') 
							FROM dbo.t_palet (NOLOCK) 
							WHERE c_codigo_pal = @ls_codigo
								  AND c_codigo_tem = @ls_tem

							SELECT TOP 1 @ls_lote2 =  ISNULL(c_codigo_lot,'')  
							FROM dbo.t_sortingmaduraciondet (NOLOCK)
							WHERE c_codigo_are = @ls_area
									AND c_codigo_tem = @ls_tem
									and c_activo_smd = '1'
									AND c_finvaciado_smd = 'N'

							IF (@ls_lote <> @ls_lote2 )
							BEGIN	
								SET @as_success = 0;
								SET @as_message = 'El pallet ingresado [' + @ls_codigo + '] no pertenece al bloque: ['+@ls_lote2+'] Favor de revisar.';
								ROLLBACK TRAN
								RETURN 
							END;
							
							/*BEGIN TRAN*/
							INSERT INTO t_sortingmaduraciondet
							 (
							   c_folio_sma ,			c_codigo_are ,		   c_codigo_rec ,		   c_concecutivo_smd,      
							   c_codigo_pal,			c_codigo_tem ,		   c_codigo_lot ,		   n_kilos_smd ,		   n_cajas_smd ,		   
							   c_codigocaja_tcj ,	   c_codigotarima_tcj ,	   c_codigo_usu ,		   d_creacion_smd ,		   
							   c_usumod_smd ,		   d_modifi_smd ,		   c_activo_smd,			c_finvaciado_smd, c_codigo_emp
							 )
							VALUES
							 ( @ls_folio ,			@ls_area ,		   @ls_recepcion , 		   @ls_conse ,		    
							   @ls_codigo,					@ls_tem ,		   @ls_lote,		   @ld_kilos , 		   @ln_cajas , 		   
							   @ls_codcaja , 	   @ls_codtari , 	   @ls_usuario , 		   GETDATE() ,
							   NULL ,				NULL , 				'1' ,			   'N', @ls_empaque
							 )

							SET @as_success = 1;
							SET @as_message = 'palet externo [' + @ls_codigo + '] Guardado correctamente.';
							/*COMMIT TRAN*/
						END;
				END;
			END;
			/*actualizar cabecero con nuevo detalle */
			UPDATE t_sortingmaduraciondet 
			SET c_folio_sma = @ls_folio
			WHERE c_codigo_are = @ls_area 
				AND c_finvaciado_smd = 'N'
				AND ISNULL(c_folio_sma,'') = ''
						
			UPDATE t_sortingmaduracion
			SET	n_totalkilos_sma = (SELECT SUM(n_kilos_smd) FROM dbo.t_sortingmaduraciondet (NOLOCK) WHERE c_folio_sma = @ls_folio),
				n_totalcajas_sma = (SELECT SUM(n_cajas_smd) FROM dbo.t_sortingmaduraciondet (NOLOCK) WHERE c_folio_sma = @ls_folio),
				n_totalpalets_sma = (SELECT COUNT(*) FROM dbo.t_sortingmaduraciondet (NOLOCK) WHERE c_folio_sma = @ls_folio)
			WHERE ISNULL(c_folio_sma,'') = @ls_folio
			COMMIT TRAN
    END TRY
    BEGIN CATCH
        SET @as_success = 0;
        SET @as_message = ERROR_MESSAGE();
		IF @@TRANCOUNT > 0
			ROLLBACK TRAN;
    END CATCH;
END;

IF @as_operation = 2 /*finalizar vaciado de proceso de sorteo tabla t_sortingmaduraciondet*/
BEGIN
    BEGIN TRY
		/*	DECLARE @ls_nomarea VARCHAR(200)
			--DECLARE	@ll_totalpalets NUMERIC
			/*SACAMOS LOS DATOS del sorteo DEL JSON*/
			SELECT @ls_area = RTRIM(LTRIM(ISNULL(n.el.value('c_codigo_are[1]', 'varchar(4)'),''))),
					@ls_usuario = RTRIM(LTRIM(ISNULL(n.el.value('c_codigo_usu[1]', 'varchar(20)'),''))),
					@ls_tiposorteo = RTRIM(LTRIM(ISNULL(n.el.value('c_tipo[1]', 'varchar(1)'),''))),
				   @ls_tem = RTRIM(LTRIM(ISNULL(n.el.value('c_codigo_tem[1]', 'varchar(2)'),''))),
				   @ls_empaque = RTRIM(LTRIM(ISNULL(n.el.value('c_codigo_emp[1]', 'varchar(2)'),''))),
				   @razon = RTRIM(LTRIM(ISNULL(n.el.value('idrazon[1]', 'tinyint'),'')))
			FROM @xml.nodes('/') n(el);

			 /*VALIDAMOS QUE EXISTA los registros */
			IF EXISTS
				(
					SELECT *
					FROM t_sortingmaduraciondet (NOLOCK) 
					WHERE c_codigo_are = @ls_area
					AND c_codigo_tem = @ls_tem
					AND c_finvaciado_smd = 'N'
					AND c_activo_smd = '1'
				)
				BEGIN
					--SELECT TOP 1 @ls_folio = ISNULL(MAX(c_folio_sma),'') FROM dbo.t_sortingmaduraciondet
					--WHERE c_codigo_are = @ls_area AND c_codigo_tem = @ls_tem AND c_finvaciado_smd = 'N' AND c_activo_smd = '1'
					--IF (@ls_folio = '' )
					--	BEGIN
					--		SET @ls_folio = '0000000001'
					--	END
					--ELSE	
					--	BEGIN
					--		SET @ls_folio = RIGHT('0000000000'+convert(varchar(10), CONVERT(numeric,@ls_folio)),10)
					--	END;

					/*Sacamos los totales del detalle */	
					SELECT @ld_kilos = SUM(n_kilos_smd), @ln_cajas = SUM(n_cajas_smd), @ll_totalpalets = COUNT(*),@ls_lote = c_codigo_lot
					FROM t_sortingmaduraciondet (NOLOCK) 
					WHERE c_codigo_are = @ls_area
						AND c_finvaciado_smd = 'N'
					GROUP BY c_codigo_lot

					SET @ls_folio =  CONVERT(VARCHAR,RIGHT(DATEPART(YEAR,GETDATE()),2))+ RIGHT('000'+ CONVERT(VARCHAR,DATEPART(DAYOFYEAR,GETDATE())),3)+ @ls_area +@ls_lote+ @ls_tem

					BEGIN TRAN;
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
								d_creacion_sma ,  c_usumod_sma ,	d_modifi_sma ,  c_activo_sma,	c_tipocorrida_sma, c_codigo_emp, idrazon
							)
							VALUES
							(	@ls_folio ,			@ls_tem ,   @ld_kilos ,   @ln_cajas , 
								@ll_totalpalets ,   'S' ,   @ls_tiposorteo ,   @ls_usuario , 
								 GETDATE(),	NULL,	NULL ,   '1' , 'M',		@ls_empaque , @razon
							)
						END

						UPDATE t_sortingmaduraciondet 
						SET /*c_finvaciado_smd = 'S',*/
							c_folio_sma = @ls_folio
						WHERE c_codigo_are = @ls_area 
							AND c_finvaciado_smd = 'N'
							AND ISNULL(c_folio_sma,'') = ''
						
						UPDATE t_sortingmaduracion
						SET	n_totalkilos_sma = (SELECT SUM(n_kilos_smd) FROM dbo.t_sortingmaduraciondet (NOLOCK) WHERE c_folio_sma = @ls_folio),
							n_totalcajas_sma = (SELECT SUM(n_cajas_smd) FROM dbo.t_sortingmaduraciondet (NOLOCK) WHERE c_folio_sma = @ls_folio),
							n_totalpalets_sma = (SELECT COUNT(*) FROM dbo.t_sortingmaduraciondet (NOLOCK) WHERE c_folio_sma = @ls_folio)
						WHERE ISNULL(c_folio_sma,'') = @ls_folio
					COMMIT TRAN;

					SET @as_success = 2;
					SET @as_message = 'La corrida ya esta generada, favor de revisar.';
				END;
			ELSE
				BEGIN
					--SELECT @ls_folio = ISNULL(MAX(c_folio_sma),'') FROM t_sortingmaduracion /*sacar folio */
					--IF (@ls_folio = '' )
					--	BEGIN
					--		SET @ls_folio = '0000000001'
					--	END
					--ELSE	
					--	BEGIN
					--		SET @ls_folio = RIGHT('0000000000'+convert(varchar(10), CONVERT(numeric,@ls_folio)+1),10)
					--	END;
					/*Sacamos los totales del detalle */	
					SELECT @ld_kilos = SUM(n_kilos_smd), @ln_cajas = SUM(n_cajas_smd), @ll_totalpalets = COUNT(*)
					FROM t_sortingmaduraciondet (NOLOCK) 
					WHERE c_codigo_are = @ls_area
						AND c_finvaciado_smd = 'N'
					GROUP BY c_codigo_lot

					SET @ls_folio =  CONVERT(VARCHAR,RIGHT(DATEPART(YEAR,GETDATE()),2))+ RIGHT('000'+ CONVERT(VARCHAR,DATEPART(DAYOFYEAR,GETDATE())),3)+ @ls_area +@ls_lote+ @ls_tem

					BEGIN TRAN;
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
								d_creacion_sma ,  c_usumod_sma ,	d_modifi_sma ,  c_activo_sma,	c_tipocorrida_sma, c_codigo_emp
							)
							VALUES
							(	@ls_folio ,			@ls_tem ,   @ld_kilos ,   @ln_cajas , 
								@ll_totalpalets ,   'S' ,   @ls_tiposorteo ,   @ls_usuario , 
								 GETDATE(),	NULL,	NULL ,   '1' , 'M',		@ls_empaque 
							)
						END
						/*actualizamos el detalle con el folio*/
						SET @ls_nomarea = (SELECT TOP 1 v_nombre_are FROM dbo.t_areafisica (nolock) WHERE c_codigo_are = @ls_area)
						UPDATE t_sortingmaduraciondet 
						SET /*c_finvaciado_smd = 'S',*/
							c_folio_sma = @ls_folio
						WHERE c_codigo_are = @ls_area 
							AND c_finvaciado_smd = 'N'
							AND ISNULL(c_folio_sma,'') = ''
					COMMIT TRAN;

					SET @as_success = 1;
					SET @as_message = 'El vaciado del área: ['+@ls_nomarea+'] se realizó correctamente. Folio['+@ls_folio+']';
				END;*/
		SET @as_success = 1;
        SET @as_message = 'Disponible';
    END TRY
    BEGIN CATCH
        SET @as_success = 0;
        SET @as_message = ERROR_MESSAGE();
		IF @@TRANCOUNT > 0
			ROLLBACK TRAN;
    END CATCH;
END;

IF @as_operation = 3 /*Eliminar registro individual del vaciado*/
BEGIN
    BEGIN TRY
			/*SACAMOS LOS DATOS del sorteo DEL JSON*/
			SELECT @ls_codigo = RTRIM(LTRIM(ISNULL(n.el.value('c_codigo[1]', 'varchar(10)'),''))),
				   @ls_area = RTRIM(LTRIM(ISNULL(n.el.value('c_codigo_are[1]', 'varchar(4)'),''))),
				   @ls_tem = RTRIM(LTRIM(ISNULL(n.el.value('c_codigo_tem[1]', 'varchar(2)'),''))),
				   @ls_empaque = RTRIM(LTRIM(ISNULL(n.el.value('c_codigo_emp[1]', 'varchar(2)'),''))),
				   @ls_tiposorteo = RTRIM(LTRIM(ISNULL(n.el.value('c_tipo[1]', 'varchar(2)'),'')))
			FROM @xml.nodes('/') n(el);

			IF (@ls_codigo = '' OR LEN(@ls_codigo)<=0)
			BEGIN	
				SET @as_success = 0;
				SET @as_message = 'El código seleccionado no puede estar vacio, favor de revisar.';
				RETURN;
			END		

			 /*VALIDAMOS QUE EXISTA los registros */
			IF NOT EXISTS
				(
					SELECT *
					FROM t_sortingmaduraciondet det (NOLOCK) 
					WHERE (c_codigo_pal = @ls_codigo OR c_codigo_rec+c_concecutivo_smd = @ls_codigo)
					AND det.c_codigo_tem = @ls_tem
					AND det.c_codigo_emp = @ls_empaque
					AND c_finvaciado_smd = 'N'
				)
				BEGIN
					SET @as_success = 0;
					SET @as_message = 'El registro no existe o ya fue eliminado.';
					RETURN;
				END;
			ELSE
				BEGIN
					SELECT @ls_folio = (SELECT TOP 1 det.c_folio_sma FROM t_sortingmaduraciondet det(NOLOCK)
										INNER JOIN dbo.t_sortingmaduracion sma (NOLOCK) ON sma.c_folio_sma = det.c_folio_sma
										WHERE (c_codigo_pal = @ls_codigo OR c_codigo_rec+c_concecutivo_smd = @ls_codigo)
										AND det.c_codigo_tem = @ls_tem
										AND sma.c_codigo_emp = @ls_empaque
										AND c_finvaciado_smd = 'N')
	
					SELECT @ld_kilos = n_kilos_smd ,@ln_cajas = n_cajas_smd FROM t_sortingmaduraciondet
						WHERE (c_codigo_pal = @ls_codigo OR c_codigo_rec+c_concecutivo_smd = @ls_codigo)
						AND c_codigo_tem = @ls_tem
						AND c_finvaciado_smd = 'N'

					BEGIN TRAN;
						DELETE t_sortingmaduraciondet
						WHERE (c_codigo_pal = @ls_codigo OR c_codigo_rec+c_concecutivo_smd = @ls_codigo)
						AND c_codigo_tem = @ls_tem
						AND c_codigo_are = @ls_area
						AND c_codigo_emp = @ls_empaque
						AND c_finvaciado_smd = 'N'

						IF (SELECT  ISNULL(COUNT(1),0)  FROM t_sortingmaduraciondet (NOLOCK) WHERE c_codigo_are = @ls_area AND c_finvaciado_smd = 'N' AND c_activo_smd = '1') = 0
							BEGIN 
								/*eliminamos primero la corrida donde se genero la etiqueta pti */
								DELETE EYE_SortingCPParaPTI WHERE cIdSortingCP = @ls_folio 
								/*eliminamos la corrida completa*/
								DELETE t_sortingmaduracion WHERE c_folio_sma = @ls_folio
								SET @as_message = 'El registro '+@ls_codigo+' fue eliminado exitosamente.(cab/det) '
							END 
						ELSE
							BEGIN
								UPDATE t_sortingmaduracion                                                                   
								SET	n_totalkilos_sma = (SELECT ISNULL(SUM(n_kilos_smd),0) FROM t_sortingmaduraciondet (NOLOCK) WHERE c_folio_sma = @ls_folio),
									n_totalcajas_sma = (SELECT ISNULL(SUM(n_cajas_smd),0) FROM t_sortingmaduraciondet (NOLOCK) WHERE c_folio_sma = @ls_folio),
									n_totalpalets_sma = (SELECT ISNULL(COUNT(*),0) FROM t_sortingmaduraciondet (NOLOCK) WHERE c_folio_sma = @ls_folio)
								WHERE ISNULL(c_folio_sma,'') = @ls_folio
								SET @as_message = 'El registro '+@ls_codigo+' fue eliminado exitosamente.(det) actualizado (cab)';
							END

						/*reasignar QR */
						IF (@ls_tiposorteo = 'CP')
							BEGIN	
								
								IF ((SELECT n_totalkilos_sma FROM dbo.t_sortingmaduracion WHERE c_folio_sma = @ls_folio) <
									(SELECT SUM(n_peso_pal) FROM dbo.t_palet pal (NOLOCK)
									INNER JOIN dbo.t_seleccion sel (NOLOCK) ON sel.c_codigo_sel = pal.c_codigo_sel
									WHERE sel.c_folio_sma = @ls_folio ) )
									BEGIN	
										SET @as_success = 0;
										SET @as_message = 'No se puede eliminar el registro porque el total de libras de los pallets superaria el total de la corrida.';
										ROLLBACK TRAN
										RETURN;
									END 
								
								UPDATE dbo.t_paletemporal SET c_activo_dso = '1' WHERE c_codigo_pte = @ls_codigo AND c_codigo_tem = @ls_tem AND c_codigo_emp = @ls_empaque
								
								/*Si ya existe una banda corriendo con esta corrida sumarle los importes del nuevo tag ingresado*/
								UPDATE dbo.t_seleccion 
								SET	 n_pesohoscorojo_sel = n_pesohoscorojo_sel - @ld_kilos , 
								n_cajas_sel = n_cajas_sel - @ln_cajas ,
								n_cajasrestantes_sel = n_cajasrestantes_sel - @ln_cajas
								WHERE c_folio_sma = @ls_folio
							END		
						ELSE
							IF(SELECT SUBSTRING(ISNULL(c_codqrtemp_pte,''),5,4) FROM dbo.t_paletemporal WHERE c_codigo_pte = @ls_codigo AND c_codigo_tem = @ls_tem AND c_codigo_emp = @ls_empaque )= '0001'
								UPDATE dbo.t_paletemporal SET c_activo_dso = '1' WHERE c_codigo_pte = @ls_codigo AND c_codigo_tem = @ls_tem AND c_codigo_emp = @ls_empaque
							ELSE	
								UPDATE dbo.t_paletemporal SET c_finalizado_pte = 'N',c_activo_dso = '1' WHERE c_codigo_pte = @ls_codigo AND c_codigo_tem = @ls_tem AND c_codigo_emp = @ls_empaque
					COMMIT TRAN
					SET @as_success = 1;
				END;
    END TRY
    BEGIN CATCH
        SET @as_success = 0;
        SET @as_message = ERROR_MESSAGE();
		IF @@TRANCOUNT > 0
			ROLLBACK TRAN;
    END CATCH;
END;

IF @as_operation = 4 /*disponible*/
BEGIN
    BEGIN TRY
		SET @as_success = 1;
        SET @as_message = 'Disponible';
    END TRY
    BEGIN CATCH
        SET @as_success = 0;
        SET @as_message = ERROR_MESSAGE();
		IF @@TRANCOUNT > 0
			ROLLBACK TRAN;
    END CATCH;
END;

IF @as_operation = 5 /*Eliminar registro individual del t_paletemporal */
BEGIN
    BEGIN TRY
			/*SACAMOS LOS DATOS del sorteo DEL JSON*/
			SELECT @ls_qr = RTRIM(LTRIM(ISNULL(n.el.value('c_codigo[1]', 'varchar(22)'),''))),
					 @ls_vaciado = RTRIM(LTRIM(ISNULL(n.el.value('c_codigo_sma[1]', 'varchar(15)'),''))),
					 @ln_cajas = RTRIM(LTRIM(ISNULL(n.el.value('n_cajas_sma[1]', 'numeric'),''))),
					 @ld_kilos = RTRIM(LTRIM(ISNULL(n.el.value('n_kilos_sma[1]', 'decimal(9,3)'),''))),
					 @ls_empaque = RTRIM(LTRIM(ISNULL(n.el.value('c_codigo_emp[1]', 'varchar(2)'),''))),
					 @ls_tem = RTRIM(LTRIM(ISNULL(n.el.value('c_codigo_tem[1]', 'varchar(2)'),'')))
			FROM @xml.nodes('/') n(el);

			SELECT @ls_codpte = c_codigo_pte, @ls_palreal = ISNULL(c_codigofinal_pal,'') 
			FROM t_paletemporal (NOLOCK)
			WHERE c_codqrtemp_pte = @ls_qr 
				AND c_codigo_tem = @ls_tem 
				AND c_codigo_emp = @ls_empaque

			IF ( @ls_palreal <> '')  
				BEGIN	
					SET @as_success = 0;
					SET @as_message =  'El pallet <strong>' + @ls_codpte + '</strong> ya fue generado para un palet real <strong>' + @ls_palreal + '</strong> no se puede eliminar.'
					RETURN
				END;

			SELECT @ls_nomposicion = LTRIM(RTRIM(ISNULL(are.v_nombre_are ,''))) 
			FROM t_palletsubicaciones pte (NOLOCK)
				LEFT JOIN t_areafisica are (NOLOCK) 
					ON are.c_codigo_are = pte.c_codigo_are
			WHERE pte.c_codigo_pte = @ls_codpte 
				AND pte.c_codigo_tem = @ls_tem 
				AND pte.c_codigo_emp = @ls_empaque

			IF NOT EXISTS(SELECT LTRIM(RTRIM(ISNULL(are.v_nombre_are ,''))) 
							FROM t_palletsubicaciones pte (NOLOCK)
								LEFT JOIN t_areafisica are (NOLOCK) 
									ON are.c_codigo_are = pte.c_codigo_are
							WHERE pte.c_codigo_pte = @ls_codpte 
								AND pte.c_codigo_tem = @ls_tem 
								AND pte.c_codigo_emp = @ls_empaque )
				BEGIN	
					BEGIN TRAN;
						DELETE t_paletemporaldet
						WHERE c_codigo_pte = @ls_codpte 
							AND c_codigo_sma = @ls_vaciado
							AND c_codigo_tem = @ls_tem

						DELETE t_paletemporal
						WHERE c_codigo_sma = @ls_vaciado 
							AND c_codigo_tem = @ls_tem
							AND c_codqrtemp_pte = @ls_qr
							AND c_codigo_emp = @ls_empaque
					COMMIT TRAN;
					SET @as_success = 1;
					SET @as_message = 'El registro fue retirado exitosamente del listado.'+ @ls_palreal;
				END 
			ELSE
				BEGIN	
					SET @as_success = 0;
					SET @as_message =  'El pallet <strong>' + @ls_codpte + '</strong> fue movido al area <strong>' + @ls_nomposicion + '</strong> no se puede eliminar.'
				END		
    END TRY
    BEGIN CATCH
        SET @as_success = 0;
        SET @as_message = ERROR_MESSAGE();
		IF @@TRANCOUNT > 0
			ROLLBACK TRAN;
    END CATCH;
END;

IF @as_operation = 6 /*Finalizar palet temporal*/
	BEGIN	
		BEGIN TRY
			BEGIN TRAN
				SELECT @ls_codigo = RTRIM(LTRIM(ISNULL(n.el.value('c_codigo[1]', 'varchar(10)'),''))),
					@ls_empaque = RTRIM(LTRIM(ISNULL(n.el.value('c_codigo_emp[1]', 'varchar(2)'),''))),
					@ls_tem = RTRIM(LTRIM(ISNULL(n.el.value('c_codigo_tem[1]', 'varchar(2)'),'')))
				FROM @xml.nodes('/') n(el);	
			
				UPDATE dbo.t_paletemporal SET c_finalizado_pte = 'S', c_activo_dso = '0' WHERE c_codigo_sma = @ls_codigo AND c_codigo_tem= @ls_tem AND c_codigo_emp = @ls_empaque

				IF EXISTS(SELECT * FROM dbo.t_sortingmaduracion(NOLOCK) WHERE c_folio_sma= @ls_codigo AND c_codigo_tem= @ls_tem AND c_codigo_emp = @ls_empaque AND c_tipocorrida_sma = 'C')
				BEGIN	
					UPDATE dbo.t_paletemporal SET c_activo_dso = '0' WHERE c_codigo_sma = @ls_codigo AND c_codigo_tem= @ls_tem AND c_codigo_emp = @ls_empaque
				END

				DECLARE @diferencia NUMERIC;

				SELECT TOP 1
				   @diferencia = ROUND(ISNULL(sma.n_totalkilos_sma, 0), 0, 1) - ROUND(SUM(ISNULL(pal.d_totkilos_pte, 0)), 0, 1)
				FROM t_sortingmaduracion sma (NOLOCK)
					INNER JOIN t_paletemporal pal (NOLOCK)
						ON sma.c_folio_sma = pal.c_codigo_sma
							AND pal.c_codigo_emp = sma.c_codigo_emp
							AND pal.c_codigo_tem = sma.c_codigo_tem
				WHERE pal.c_codigo_sma = @ls_codigo
						AND pal.c_codigo_tem= @ls_tem 
						AND pal.c_codigo_emp = @ls_empaque
				GROUP BY sma.n_totalkilos_sma;
			
				UPDATE dbo.t_sortingmaduracion
				SET n_diferenciapalet_sma = @diferencia, 
					c_activo_sma = 0
				WHERE c_folio_sma = @ls_codigo
					AND c_codigo_tem= @ls_tem 
					AND c_codigo_emp = @ls_empaque

				UPDATE dbo.t_sortingmaduraciondet
				SET	c_activo_smd = 0,
					c_finvaciado_smd = 'S'
				WHERE c_folio_sma = @ls_codigo
					AND c_codigo_tem= @ls_tem 

			COMMIT TRAN;
			SET @as_success = 1;
			SET @as_message = 'Pallets Finalizados y corrida cerrada correctamente.'
		END TRY	
	    BEGIN CATCH
			SET @as_success = 0;
			SET @as_message = ERROR_MESSAGE();
			IF @@TRANCOUNT > 0
				ROLLBACK TRAN;
		END CATCH;
	END;

IF @as_operation = 7 /*Guardado de pallet temporal detalle*/
BEGIN
    BEGIN TRY
			DECLARE @ln_cajasdet NUMERIC;
			DECLARE @ld_kilosdet DECIMAL(18,3);

			/*SACAMOS LOS DATOS del sorteo DEL JSON*/
			SELECT @ls_vaciado = RTRIM(LTRIM(ISNULL(n.el.value('c_codigo_sma[1]', 'varchar(15)'),''))),
			 @ls_qr = RTRIM(LTRIM(ISNULL(n.el.value('c_qr[1]', 'varchar(22)'),''))),
			 @ls_gradomaduracion = RTRIM(LTRIM(ISNULL(n.el.value('c_codigo_gdm[1]', 'varchar(4)'),''))),
			 @ln_totalcajas = RTRIM(LTRIM(ISNULL(n.el.value('n_cajas_dso[1]', 'numeric'),''))),
			 @ld_totalkilos = CONVERT(DECIMAL(18,3),RTRIM(LTRIM(ISNULL(n.el.value('n_kilos_dso[1]', 'DECIMAL(18,3)'),'')))),
			 @ls_usuario = RTRIM(LTRIM(ISNULL(n.el.value('c_codigo_usu[1]', 'varchar(20)'),''))),
			 @ln_cajasdet = RTRIM(LTRIM(ISNULL(n.el.value('n_cajas[1]', 'NUMERIC'),''))),
			 @ld_kilosdet = CONVERT(DECIMAL(18,3),RTRIM(LTRIM(ISNULL(n.el.value('n_kilos[1]', 'DECIMAL(18,3)'),'')))),
			 @ls_empaque = RTRIM(LTRIM(ISNULL(n.el.value('c_codigo_emp[1]', 'varchar(2)'),''))),
			 @ls_tem = RTRIM(LTRIM(ISNULL(n.el.value('c_codigo_tem[1]', 'varchar(2)'),''))), 
			 @ls_calibre = RTRIM(LTRIM(ISNULL(n.el.value('c_codigo_cal[1]', 'varchar(4)'),'')))
			FROM @xml.nodes('/') n(el);

			SELECT @newcod = ISNULL(MAX(c_codigo_pte),'0') FROM t_paletemporal
			SET @newcod = RIGHT( DATEPART(YEAR,GETDATE()) ,2) + RIGHT('00000000'+CONVERT(VARCHAR(10),CONVERT(NUMERIC,@newcod)+1),8)
			SET @ls_secuencia = '001'


				/*VALIDAMOS QUE EXISTA el vaciado */
			IF NOT EXISTS
				(
					SELECT *
					FROM t_sortingmaduracion (NOLOCK) 
					WHERE c_folio_sma = @ls_vaciado
						AND c_codigo_tem = @ls_tem
						AND c_codigo_emp = @ls_empaque
				)
				BEGIN
					SET @as_success = 0;
					SET @as_message = 'El vaciado [' + @ls_vaciado + '] no existe.';
					RETURN;
				END;
			ELSE
				BEGIN
					IF NOT EXISTS (SELECT * FROM dbo.t_paletemporal WHERE c_codigo_pte = @newcod AND c_codigo_sma = @ls_vaciado AND c_codigo_tem = @ls_tem AND c_codigo_emp = @ls_empaque)
						BEGIN
							BEGIN TRAN;
								INSERT INTO dbo.t_paletemporal
								(
									c_codigo_pte,	c_codqrtemp_pte,	c_codigo_tem,
									d_totcaja_pte ,		d_totkilos_pte,		d_asignacionqr_pte,	
									d_liberacionqr_pte,	c_codigo_are,	c_ubicacion_pte,  c_codigo_cal,    
									c_finalizado_pte,    c_codigo_usu,    d_creacion_dso,    c_usumod_dso,
									d_modifi_dso,    c_activo_dso, c_codigo_sma,c_codigo_gma, c_codigo_emp,
									d_fecha_pte
								)
								VALUES
								(   
									@newcod,    @ls_qr,    @ls_tem,       
									 @ln_cajasdet, @ld_kilosdet, GETDATE(), 
									NULL, '0001', NULL,  @ls_calibre,   
									'N',   @ls_usuario,    GETDATE(),  NULL,      
									NULL,   '1'     ,@ls_vaciado   ,@ls_gradomaduracion ,@ls_empaque,
									GETDATE()
								)

								INSERT INTO dbo.t_paletemporaldet
								(
									c_codigo_pte,    c_concecutivo_pte,    c_codigo_sma,    c_codigo_tem,
									c_codigo_usu,    d_creacion_dso,    c_usumod_dso,    d_modifi_dso,
									c_activo_dso,	 n_cajas_pte,		n_kilos_pte, c_codigo_emp
								)
								VALUES
								(   @newcod,       @ls_secuencia,       @ls_vaciado,       @ls_tem,   
									@ls_usuario,     GETDATE(),     NULL,     NULL, 
									'1'    ,@ln_cajasdet		,@ld_kilosdet, @ls_empaque
								)
							COMMIT TRAN
						END;
					ELSE	
						BEGIN
							BEGIN TRAN
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
									c_activo_dso,	 n_cajas_pte,		n_kilos_pte, c_codigo_emp
								)
								VALUES
								(   @newcod,       @ls_secuencia,       @ls_vaciado,       @ls_tem,   
									@ls_usuario,     GETDATE(),     NULL,     NULL, 
									'1'    ,@ln_cajasdet		,@ld_kilosdet, @ls_empaque
								)
							COMMIT TRAN
						END;
				SET @as_success = 1;
				SET @as_message = 'Pallet temporal [' + @newcod +  '] Guardada correctamente.';
			END;	
    END TRY
    BEGIN CATCH
        SET @as_success = 0;
		SET @as_message = ERROR_MESSAGE();
		IF @@TRANCOUNT > 0
			ROLLBACK TRAN;
    END CATCH;
END;

IF @as_operation = 8 /*validar que exista la recepcion, el palet temporal o el real */
BEGIN
    BEGIN TRY
		SELECT @ls_codigo = RTRIM(LTRIM(ISNULL(n.el.value('c_codigo[1]', 'varchar(22)'),''))),
			 @ls_empaque = RTRIM(LTRIM(ISNULL(n.el.value('c_codigo_emp[1]', 'varchar(2)'),''))),
			 @ls_tem = RTRIM(LTRIM(ISNULL(n.el.value('c_codigo_tem[1]', 'varchar(2)'),'')))
		FROM @xml.nodes('/') n(el);	

        IF EXISTS /*Recepcion*/
			(
            SELECT * FROM t_recepciondet (NOLOCK)
            WHERE c_codigo_rec + c_secuencia_red = @ls_codigo
                  AND c_codigo_tem = @ls_tem
			)
			BEGIN	
				SET @as_success = 1;
				SET @as_message = 'Si existe y es una recepción';
			END 
		ELSE IF EXISTS /*palet temporal */
			(
            SELECT * FROM t_recepciondet (NOLOCK)
            WHERE c_codexterno_rec = @ls_codigo
                  AND c_codigo_tem = @ls_tem
			)
			BEGIN	
				SET @as_success = 1;
				SET @as_message = 'Si existe y es un Palet externo';
			END
		ELSE IF EXISTS /*palet temporal */
			(
            SELECT * FROM dbo.t_paletemporal (NOLOCK)
            WHERE (c_codqrtemp_pte = @ls_codigo OR c_codigo_pte = @ls_codigo)
                  AND c_codigo_tem = @ls_tem
				  AND c_codigo_emp = @ls_empaque
			)
			BEGIN	
				SET @as_success = 1;
				SET @as_message = 'Si existe y es un Palet Temporal';
			END
		ELSE IF EXISTS /*palet Final */
			(
            SELECT * FROM dbo.t_palet (NOLOCK)
            WHERE c_codigo_pal = @ls_codigo
                  AND c_codigo_tem = @ls_tem
				  AND c_codigo_emp = @ls_empaque
			)
			BEGIN	
				SET @as_success = 1;
				SET @as_message = 'Si existe y es un Palet final';
			END
		ELSE
			BEGIN
				SET @as_success = 0;
				SET @as_message = 'El registro escaneado no existe';
			END 
    END TRY
    BEGIN CATCH
        SET @as_success = 0;
		SET @as_message = ERROR_MESSAGE();
		IF @@TRANCOUNT > 0
			ROLLBACK TRAN
    END CATCH;
END;

IF @as_operation = 9 /*Asignar Ubicacion al pallet*/
BEGIN
    BEGIN TRY
        BEGIN TRAN;
        /*SACAMOS LOS DATOS DEL JSON*/
        SELECT @ls_tem = RTRIM(LTRIM(ISNULL(n.el.value('c_codigo_tem[1]', 'varchar(2)'), ''))),
               @ls_empaque = RTRIM(LTRIM(ISNULL(n.el.value('c_codigo_emp[1]', 'varchar(2)'), ''))),
               @ls_codigo = RTRIM(LTRIM(ISNULL(n.el.value('c_codigo_pal[1]', 'varchar(10)'), ''))),
               @ls_nivel = RTRIM(LTRIM(ISNULL(n.el.value('c_codigo_niv[1]', 'varchar(4)'), ''))),
               @ls_columna = RTRIM(LTRIM(ISNULL(n.el.value('c_codigo_col[1]', 'varchar(4)'), ''))),
               @ls_posicion = RTRIM(LTRIM(ISNULL(n.el.value('c_codigo_pos[1]', 'varchar(4)'), ''))),
               @ls_espaciofisico = '',
               @ls_usuario = RTRIM(LTRIM(ISNULL(n.el.value('c_codigo_usu[1]', 'varchar(20)'), ''))),
               @ls_area = RTRIM(LTRIM(ISNULL(n.el.value('c_codigo_are[1]', 'varchar(4)'), '')))
        FROM @xml.nodes('/') n(el);

        IF EXISTS /*validar que exista el palet temporal*/
        (
            SELECT *
            FROM dbo.t_paletemporal pal
            WHERE pal.c_codigo_tem = @ls_tem
                  AND pal.c_codigo_emp = @ls_empaque
                  AND RTRIM(LTRIM(ISNULL(pal.c_codigo_pte, ''))) = @ls_codigo
        )
        BEGIN
    --        IF EXISTS/*validar si ya tiene asignada una ubicacion*/
    --        (
    --            SELECT *
    --            FROM dbo.t_paletemporal pal
    --            WHERE pal.c_codigo_tem = @ls_tem
    --                  AND pal.c_codigo_emp = @ls_empaque
    --                  AND RTRIM(LTRIM(ISNULL(pal.c_codigo_pte, ''))) = @ls_codigo
    --                  AND ISNULL(pal.c_codigo_niv, '') <> ''
    --        )
				--BEGIN
				--	SELECT @ls_nivel = pal.c_codigo_niv,
				--		   @ls_columna = pal.c_columna_col,
				--		   @ls_posicion = pal.c_codigo_pos
				--	FROM dbo.t_paletemporal pal
				--	WHERE pal.c_codigo_tem = @ls_tem
				--		  AND pal.c_codigo_emp = @ls_empaque
				--		  AND RTRIM(LTRIM(ISNULL(pal.c_codigo_pte, ''))) = @ls_codigo;

				--	SELECT TOP 1
				--		   @ls_nomnivel = v_descripcion_niv
				--	FROM dbo.t_ubicacionnivel (NOLOCK)
				--	WHERE c_codigo_niv = @ls_nivel;
				--	SELECT TOP 1
				--		   @ls_nomcolumna = c_nomenclatura_col
				--	FROM dbo.t_ubicacioncolumna (NOLOCK)
				--	WHERE c_codigo_col = @ls_columna;
				--	SELECT TOP 1
				--		   @ls_nomposicion = c_posicion_pos
				--	FROM dbo.t_ubicacionposicion (NOLOCK)
				--	WHERE c_codigo_pos = @ls_posicion;

				--	SET @as_success = 0;
				--	SET @as_message
				--		= 'El pallet  <strong> ' + @ls_codigo
				--		  + '</strong> ya tiene asignada la ubicación :<br><br> <strong>Rack: ' + @ls_nomcolumna
				--		  + '<br><br>Nivel: ' + @ls_nomnivel + +'<br><br>Posición: ' + @ls_nomposicion + '</strong> ';
				--END;
    --        ELSE
				--BEGIN
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

					UPDATE dbo.t_paletemporal
					SET c_codigo_niv = @ls_nivel,
						c_columna_col = @ls_columna,
						c_codigo_pos = @ls_posicion,
						c_codigo_def = @ls_espaciofisico,
						c_usumod_dso = @ls_usuario,
						d_modifi_dso = GETDATE()
					WHERE c_codigo_tem = @ls_tem
						  AND c_codigo_emp = @ls_empaque
						  AND RTRIM(LTRIM(ISNULL(c_codigo_pte, ''))) = @ls_codigo;

					SET @as_success = 1;
					SET @as_message
						= 'La ubicación:  <br><br><strong>Rack: ' + @ls_nomcolumna + '<br><br>Nivel: ' + @ls_nomnivel
						  + +'<br><br>Posición: ' + @ls_nomposicion
						  + '</strong> <br><br>fue asignada con éxito al pallet:  <strong> ' + @ls_codigo + '</strong>';
			--	END;
        END;
        ELSE
        BEGIN
            SET @as_success = 0;
            SET @as_message
                = 'El pallet <strong>' + @ls_codigo
                  + '</strong> no existe en la temporada activa o el punto de empaque.';
        END;
        COMMIT TRAN;
    END TRY
    BEGIN CATCH
        SET @as_success = 0;
		SET @as_message = ERROR_MESSAGE();
		IF @@TRANCOUNT > 0
			ROLLBACK TRAN;
    END CATCH;
END;

IF @as_operation = 10 /*Quitar Ubicacion al pallet*/
BEGIN
    BEGIN TRY
        BEGIN TRAN;

        /*SACAMOS LOS DATOS DEL JSON*/
        SELECT @ls_tem = RTRIM(LTRIM(ISNULL(n.el.value('c_codigo_tem[1]', 'varchar(2)'), ''))),
               @ls_empaque = RTRIM(LTRIM(ISNULL(n.el.value('c_codigo_emp[1]', 'varchar(2)'), ''))),
               @ls_codigo = RTRIM(LTRIM(ISNULL(n.el.value('c_codigo_pal[1]', 'varchar(10)'), ''))),
               @ls_usuario = RTRIM(LTRIM(ISNULL(n.el.value('c_codigo_usu[1]', 'varchar(20)'), '')))
        FROM @xml.nodes('/') n(el);

        IF EXISTS
        (
            SELECT *  FROM dbo.t_paletemporal pal (NOLOCK)
            WHERE pal.c_codigo_tem = @ls_tem
                  AND pal.c_codigo_emp = @ls_empaque
                  AND RTRIM(LTRIM(ISNULL(c_codigo_pte, ''))) = @ls_codigo
        )
        BEGIN
            UPDATE dbo.t_paletemporal
            SET c_codigo_niv = '',
                c_columna_col = '',
                c_codigo_pos = '',
                c_codigo_def = '',
                c_usumod_dso = @ls_usuario,
                d_modifi_dso = GETDATE()
            WHERE c_codigo_tem = @ls_tem
                  AND c_codigo_emp = @ls_empaque
                  AND RTRIM(LTRIM(ISNULL(c_codigo_pte, ''))) = @ls_codigo
                  AND ISNULL(c_codigo_pte, '') <> '';

            SET @as_success = 1;
            SET @as_message = 'Pallet: <strong> ' + @ls_codigo + '</strong> Liberado de la ubicación con éxito';
        END;
        ELSE
        BEGIN
            SET @as_success = 0;
            SET @as_message = 'El pallet <strong>' + @ls_codigo + '</strong> no existe en el punto de empaque.';
        END;
        COMMIT TRAN;
    END TRY
    BEGIN CATCH
        SET @as_success = 0;
		SET @as_message = ERROR_MESSAGE();
		IF @@TRANCOUNT > 0
			ROLLBACK TRAN;
    END CATCH;
END;

IF @as_operation = 11 /*guardar cambio de ubicacion*/
BEGIN
    BEGIN TRY
		DECLARE	@ln_hora NUMERIC	
		DECLARE @ln_minutos NUMERIC
			/*SACAMOS LOS DATOS DEL JSON*/
			SELECT @ls_tem = RTRIM(LTRIM(ISNULL(n.el.value('c_codigo_tem[1]', 'varchar(2)'), ''))),
				   @ls_empaque = RTRIM(LTRIM(ISNULL(n.el.value('c_codigo_emp[1]', 'varchar(2)'), ''))),
				   @ls_codpte = RTRIM(LTRIM(ISNULL(n.el.value('c_codigo_pal[1]', 'varchar(10)'), ''))),
				   @ls_usuario = RTRIM(LTRIM(ISNULL(n.el.value('c_codigo_usu[1]', 'varchar(20)'), ''))),
				   @ln_totalcajas = RTRIM(LTRIM(ISNULL(n.el.value('n_cajas[1]', 'NUMERIC'),0))),
				   @ld_totalkilos = CONVERT(DECIMAL(18,3),RTRIM(LTRIM(ISNULL(n.el.value('n_kilos[1]', 'DECIMAL(18,3)'),0)))),
				   @ls_area = RTRIM(LTRIM(ISNULL(n.el.value('c_codigo_are[1]','varchar(4)'),''))),
				   @ls_qr = RTRIM(LTRIM(ISNULL(n.el.value('c_qr[1]', 'varchar(22)'),''))),
				   @ls_nomposicion = RTRIM(LTRIM(ISNULL(n.el.value('v_nombre_are[1]', 'varchar(100)'),''))),
				   @ld_fecha = GETDATE(),
				   @ln_hora = RTRIM(LTRIM(ISNULL(n.el.value('n_horas[1]', 'NUMERIC'),0))),
				   @ln_minutos = RTRIM(LTRIM(ISNULL(n.el.value('n_minutos[1]', 'NUMERIC'),0)))
			FROM @xml.nodes('/') n(el)

			IF(@ln_hora>0)
			BEGIN	
				SET @ln_minutos = (60*@ln_hora) + @ln_minutos
			END

			SELECT @newcod = CONVERT(NUMERIC,ISNULL(MAX(c_codigo_pub),'0'))  FROM t_palletsubicaciones WHERE LEFT(c_codigo_pub,2) = RIGHT(DATEPART(YEAR,GETDATE()),2)
			SET @newcod = RIGHT( DATEPART(YEAR,GETDATE()) ,2) + RIGHT('00000000'+CONVERT(VARCHAR(10),CONVERT(NUMERIC,@newcod)+1),8)
			
			SELECT @ls_codigo = ISNULL(c_codigo_sma,'') 
			FROM t_paletemporal (nolock) 
			WHERE c_codigo_pte = @ls_codpte AND c_codigo_tem = @ls_tem AND c_codigo_emp = @ls_empaque

			IF NOT EXISTS
			(
				SELECT *
				FROM t_palletsubicaciones (NOLOCK)
				WHERE c_ubiactual_pub = '1'
						AND (c_codigo_pte = @ls_codpte OR c_codigo_pte = @ls_qr)
						AND c_codigo_tem = @ls_tem
						AND c_codigo_emp = @ls_empaque
			)
			BEGIN
			SELECT TOP 1 @ld_kilos=t_aux.kilos , 
						@ls_tiposorteo = t_aux.tipo
						FROM	(
						SELECT kilos= ISNULL(d_totkilos_pte, 0),tipo ='P'
						FROM t_paletemporal (NOLOCK)
						WHERE c_codigo_pte = @ls_codpte
								AND c_codigo_tem = @ls_tem
								AND c_codigo_emp = @ls_empaque
						UNION  ALL 
						SELECT  kilos = ISNULL(pal.n_bulxpa_pal, 0) * ISNULL(pro.n_pesbul_pro,0),tipo = 'T'
						FROM dbo.t_palet pal(NOLOCK)
							INNER JOIN dbo.t_producto pro (NOLOCK)
								ON pro.c_codigo_pro = pal.c_codigo_pro
						WHERE pal.c_codigo_pal = @ls_qr
								AND pal.c_codigo_tem = @ls_tem
								AND pal.c_codigo_emp = @ls_empaque
						)t_aux
				SET @ld_kilosdet = @ld_totalkilos - @ld_kilos
			END;
			ELSE
			BEGIN
				SELECT @ld_kilos = ISNULL(n_pesoxpal_pub, 0)
				FROM t_palletsubicaciones (NOLOCK)
				WHERE c_ubiactual_pub = '1'
						AND c_codigo_pte = @ls_codpte
						AND c_codigo_tem = @ls_tem
						AND c_codigo_emp = @ls_empaque;

				SELECT TOP 1 @ls_tiposorteo = t_aux.tipo
							FROM	(
								SELECT tipo ='P'
								FROM t_paletemporal (NOLOCK)
								WHERE c_codigo_pte = @ls_codpte
										AND c_codigo_tem = @ls_tem
										AND c_codigo_emp = @ls_empaque
								UNION  ALL 
								SELECT tipo = 'T'
								FROM dbo.t_palet pal(NOLOCK)
									INNER JOIN dbo.t_producto pro (NOLOCK)
										ON pro.c_codigo_pro = pal.c_codigo_pro
								WHERE pal.c_codigo_pal = @ls_qr
										AND pal.c_codigo_tem = @ls_tem
										AND pal.c_codigo_emp = @ls_empaque
							)t_aux

				SET @ld_kilosdet = @ld_totalkilos - @ld_kilos ;
			END;

			BEGIN TRAN
			IF NOT EXISTS (SELECT * FROM t_palletsubicaciones (NOLOCK)
						WHERE c_ubiactual_pub = '1'
								AND c_codigo_pte = @ls_codpte
								AND c_codigo_tem = @ls_tem
								AND c_codigo_emp = @ls_empaque  
								AND c_codigo_are = @ls_area
								)
			BEGIN		
					UPDATE t_palletsubicaciones SET c_ubiactual_pub = '0', d_salida_pub = @ld_fecha  
					WHERE c_ubiactual_pub = '1' AND c_codigo_pte = @ls_codpte AND c_codigo_tem = @ls_tem AND c_codigo_emp = @ls_empaque 

					INSERT INTO t_palletsubicaciones
					(
						c_codigo_pub,    c_codigo_are,    c_codigo_pte,    c_codqrtemp_pub,
						d_entrada_pub,    d_salida_pub,    c_codigo_sma,    n_pesoxpal_pub,
						n_difpeso_pub,    c_ubiactual_pub,    c_codigo_tem,	  c_codigo_emp,
						c_codigo_usu,    d_creacion_pub,		c_usumod_pub,    d_modifi_pub,    
						c_activo_pub,	n_tiemposugerido_pub
					)
					VALUES
					(	@newcod, @ls_area, @ls_codpte, @ls_qr,
						@ld_fecha, NULL, @ls_codigo, @ld_totalkilos,
						@ld_kilosdet, '1', @ls_tem, @ls_empaque,
						@ls_usuario, @ld_fecha, NULL, NULL,
						'1', @ln_minutos);
			END; 

			IF (@ls_tiposorteo = 'P')
				IF EXISTS(SELECT * FROM dbo.t_areafisica(NOLOCK) WHERE c_codigo_are = @ls_area AND c_ubicacion_are= '1')
					BEGIN	
						IF(SELECT TOP 1 ISNULL(c_codigo_are,'') FROM dbo.t_paletemporal (NOLOCK) 
							WHERE c_codigo_pte = @ls_codpte AND c_codigo_tem = @ls_tem AND c_codigo_emp = @ls_empaque)= @ls_area
							BEGIN	
								UPDATE t_paletemporal SET c_codigo_are = @ls_area WHERE c_codigo_pte = @ls_codpte AND c_codigo_tem = @ls_tem AND c_codigo_emp = @ls_empaque
							END
						ELSE	
							BEGIN		
								UPDATE t_paletemporal SET c_codigo_are = @ls_area, c_codigo_niv = '' ,c_columna_col='',c_codigo_pos =''
								WHERE c_codigo_pte = @ls_codpte AND c_codigo_tem = @ls_tem AND c_codigo_emp = @ls_empaque 
							END 
					END 
				ELSE
					BEGIN	
						UPDATE t_paletemporal SET c_codigo_are = @ls_area, c_codigo_niv = '' ,c_columna_col='',c_codigo_pos =''
						WHERE c_codigo_pte = @ls_codpte AND c_codigo_tem = @ls_tem AND c_codigo_emp = @ls_empaque 
					END 
			ELSE
				IF EXISTS(SELECT * FROM dbo.t_areafisica(NOLOCK) WHERE c_codigo_are = @ls_area AND c_ubicacion_are= '1')
					BEGIN	
						IF(SELECT TOP 1 ISNULL(c_codigo_are,'') FROM dbo.t_palet (NOLOCK) 
							WHERE c_codigo_pal = @ls_codpte AND c_codigo_tem = @ls_tem AND c_codigo_emp = @ls_empaque)= @ls_area
							BEGIN	
								UPDATE t_palet SET c_codigo_are = @ls_area WHERE c_codigo_pal = @ls_codpte AND c_codigo_tem = @ls_tem AND c_codigo_emp = @ls_empaque
							END
						ELSE	
							BEGIN		
								UPDATE t_palet SET c_codigo_are = @ls_area, c_codigo_niv = '' ,c_columna_col='',c_codigo_pos =''
								WHERE c_codigo_pal = @ls_codpte AND c_codigo_tem = @ls_tem AND c_codigo_emp = @ls_empaque 
							END 
					END 
				ELSE
					BEGIN	
						UPDATE t_palet SET c_codigo_are = @ls_area, c_codigo_niv = '' ,c_columna_col='',c_codigo_pos =''
						WHERE c_codigo_pal = @ls_codpte AND c_codigo_tem = @ls_tem AND c_codigo_emp = @ls_empaque 
					END 
			COMMIT TRAN
			SET @as_success = 1;
			SET @as_message = 'Pallet <strong>' + @ls_codpte + '</strong> guardo correctamente en la ubicación <strong>' + @ls_nomposicion + '</strong>.';
    END TRY
    BEGIN CATCH
        SET @as_success = 0;
		SET @as_message = ERROR_MESSAGE();
		IF @@TRANCOUNT > 0
			ROLLBACK TRAN;
    END CATCH;
END;

IF @as_operation = 12 /*Guardado de proceso de sorteo calibre */
BEGIN
    BEGIN TRY
			/*SACAMOS LOS DATOS del sorteo DEL JSON*/ 
			SELECT @ls_folio = '',
					 @ls_area = RTRIM(LTRIM(ISNULL(n.el.value('c_codigo_are[1]','varchar(4)'),''))),
					 @ls_codigo = RTRIM(LTRIM(ISNULL(n.el.value( 'c_codigo[1]','varchar(10)'),''))),
					 @ld_kilos = RTRIM(LTRIM(ISNULL(n.el.value( 'n_kilos_dso[1]','decimal(9,3)'),''))),
					 @ln_cajas = RTRIM(LTRIM(ISNULL(n.el.value( 'n_cajas_dso[1]','numeric'),''))),
					 @ls_codcaja = RTRIM(LTRIM(ISNULL(n.el.value( 'c_codigocaja_tcj[1]','varchar(4)'),''))),
					 @ls_codtari = RTRIM(LTRIM(ISNULL(n.el.value( 'c_codigotarima_tcj[1]','varchar(4)'),''))),
					 @ls_usuario = RTRIM(LTRIM(ISNULL(n.el.value( 'c_codigo_usu[1]','varchar(20)'),''))),
					 @ls_tiposorteo = RTRIM(LTRIM(ISNULL(n.el.value( 'c_tipo[1]','varchar(1)'),''))),
				     @ls_tem = RTRIM(LTRIM(ISNULL(n.el.value('c_codigo_tem[1]', 'varchar(2)'),''))),
				     @ls_empaque = RTRIM(LTRIM(ISNULL(n.el.value('c_codigo_emp[1]', 'varchar(2)'),'')))
			FROM @xml.nodes('/') n(el);

			--IF (@ls_tiposorteo = 'P')
			--BEGIN
				IF NOT EXISTS /*Valida que no este guardada*/
					(
					SELECT *
					FROM dbo.t_paletemporal (NOLOCK) 
					WHERE c_codqrtemp_pte = @ls_codigo
					AND c_codigo_tem = @ls_tem
					AND c_codigo_emp = @ls_empaque
					AND c_activo_dso = '1'
					)
					BEGIN
						SET @as_success = 0;
						SET @as_message = 'El QR ingresado [' + @ls_codigo + '] no existe o no esta asignado a un pallet.';
						RETURN
					END;

				IF EXISTS /*Valida que no este guardada*/
					(
						SELECT *
						FROM t_sortingmaduraciondet det (NOLOCK) 
						INNER JOIN t_paletemporal pal (NOLOCK) ON pal.c_codigo_sma = det.c_folio_sma
						INNER JOIN t_sortingmaduracion sma (NOLOCK) ON sma.c_folio_sma = det.c_folio_sma
						WHERE pal.c_codqrtemp_pte = @ls_codigo
						AND det.c_codigo_tem = @ls_tem
						AND pal.c_codigo_emp = @ls_empaque
						AND sma.c_tipocorrida_sma = 'C'
						AND pal.c_activo_dso= '1'
					)
					BEGIN
						SET @as_success = 0;
						SET @as_message = 'El pallet ingresado [' + @ls_codigo + '] esta en proceso de vaciado o ya fue vaciado.';
						RETURN	
					END;

					SELECT DISTINCT TOP 1 @ls_lote = LTRIM(RTRIM(ISNULL(smd.c_codigo_lot ,''))),@ls_codpte =pal.c_codigo_pte FROM t_paletemporal pal (NOLOCK)
					INNER JOIN t_sortingmaduraciondet smd (NOLOCK) ON pal.c_codigo_sma = smd.c_folio_sma
					WHERE pal.c_codqrtemp_pte = @ls_codigo

					SELECT TOP 1 @ls_lote2 =  LTRIM(RTRIM(ISNULL(c_codigo_lot,'')))  
					FROM dbo.t_sortingmaduraciondet (NOLOCK)
					WHERE c_codigo_are = @ls_area
							AND c_codigo_tem = @ls_tem
							and c_activo_smd = '1'
							AND c_finvaciado_smd = 'N'

					IF (@ls_lote <> @ls_lote2 )
					BEGIN	
						SET @as_success = 0;
						SET @as_message = 'El pallet ingresado [' + @ls_codigo + '] no pertenece al bloque: ['+@ls_lote+'] Favor de revisar.';
						RETURN 
					END;

					BEGIN TRAN;
						INSERT INTO t_sortingmaduraciondet
							(
							c_folio_sma ,			c_codigo_are ,		   c_codigo_rec ,		   c_concecutivo_smd,      
							c_codigo_pal,			c_codigo_tem ,		   c_codigo_lot ,		   n_kilos_smd ,		   n_cajas_smd ,		   
							c_codigocaja_tcj ,	   c_codigotarima_tcj ,	   c_codigo_usu ,		   d_creacion_smd ,		   
							c_usumod_smd ,		   d_modifi_smd ,		   c_activo_smd,			c_finvaciado_smd, c_codigo_emp
							)
						VALUES
							( @ls_folio ,			@ls_area ,		   '' , 		   '',  
							@ls_codpte,			@ls_tem ,		   @ls_lote,		   @ld_kilos , 		   @ln_cajas , 		   
							@ls_codcaja , 	   @ls_codtari , 	   @ls_usuario , 		   GETDATE() ,
							NULL ,				NULL , 				'1' ,			   'N',		@ls_empaque
							)
						/*liberar QR */
						UPDATE dbo.t_paletemporal SET c_finalizado_pte = 'S', c_activo_dso = '0' WHERE c_codigo_pte = @ls_codpte AND c_codigo_tem = @ls_tem AND c_codigo_emp = @ls_empaque 
					COMMIT TRAN;
					SET @as_success = 1;
					SET @as_message = 'Corrida guardada correctamente';
   --         END;
			--ELSE IF @ls_tiposorteo = 'E' 
			--BEGIN
			--	SET @as_success = 1;
			--	SET @as_message = 'Pallet temporal [' + @ls_codigo + '] Guardado correctamente.';
			--END;
    END TRY
    BEGIN CATCH
		BEGIN TRAN
			SET @as_success = 0;
			SET @as_message = ERROR_MESSAGE();
			IF @@TRANCOUNT > 0
				ROLLBACK TRAN;
    END CATCH;
END;

IF @as_operation = 13 /*finalizar vaciado de proceso de sorteo de calibre*/
BEGIN
    BEGIN TRY
			/*SACAMOS LOS DATOS del sorteo DEL JSON*/
			SELECT @ls_area = RTRIM(LTRIM(ISNULL(n.el.value('c_codigo_are[1]', 'varchar(4)'),''))),
					@ls_usuario = RTRIM(LTRIM(ISNULL(n.el.value('c_codigo_usu[1]', 'varchar(20)'),''))),
					@ls_tiposorteo = RTRIM(LTRIM(ISNULL(n.el.value('c_tipo[1]', 'varchar(1)'),''))),
				   @ls_tem = RTRIM(LTRIM(ISNULL(n.el.value('c_codigo_tem[1]', 'varchar(2)'),''))),
				   @ls_empaque = RTRIM(LTRIM(ISNULL(n.el.value('c_codigo_emp[1]', 'varchar(2)'),''))),
				   @razon = RTRIM(LTRIM(ISNULL(n.el.value('idrazon[1]', 'tinyint'),'')))
			FROM @xml.nodes('/') n(el);

			 /*VALIDAMOS QUE EXISTA los registros */
			IF EXISTS
				(
					SELECT *
					FROM t_sortingmaduraciondet (NOLOCK) 
					WHERE c_codigo_are = @ls_area
					AND c_codigo_tem = @ls_tem
					AND c_codigo_emp = @ls_empaque
					AND c_finvaciado_smd = 'N'
					AND c_activo_smd = '1'
					AND ISNULL(c_folio_sma,'') <> '' 
				)
				BEGIN
					--SELECT TOP 1 @ls_folio = ISNULL(MAX(c_folio_sma),'') FROM dbo.t_sortingmaduraciondet
					--WHERE c_codigo_are = @ls_area AND c_finvaciado_smd = 'N' AND c_activo_smd = '1'
					--IF (@ls_folio = '' )
					--	BEGIN
					--		SET @ls_folio = '0000000001'
					--	END
					--ELSE	
					--	BEGIN
					--		SET @ls_folio = RIGHT('0000000000'+convert(varchar(10), CONVERT(numeric,@ls_folio)),10)
					--	END;
										/*Sacamos los totales del detalle */	
					SELECT TOP 1 @ls_lote = c_codigo_lot
					FROM t_sortingmaduraciondet (NOLOCK) 
					WHERE c_codigo_are = @ls_area
						AND c_finvaciado_smd = 'N'

					SET @ls_folio =  CONVERT(VARCHAR,RIGHT(DATEPART(YEAR,GETDATE()),2))+ RIGHT('000'+ CONVERT(VARCHAR,DATEPART(DAYOFYEAR,GETDATE())),3)+ @ls_area +@ls_lote+ @ls_tem

					BEGIN TRAN;
						UPDATE t_sortingmaduraciondet 
						SET /*c_finvaciado_smd = 'S',*/
							c_folio_sma = @ls_folio
						WHERE c_codigo_are = @ls_area 
							AND c_finvaciado_smd = 'N'
							AND ISNULL(c_folio_sma,'') = ''
						
						UPDATE t_sortingmaduracion
						SET	n_totalkilos_sma = (SELECT SUM(n_kilos_smd) FROM dbo.t_sortingmaduraciondet (NOLOCK) WHERE c_folio_sma = @ls_folio),
							n_totalcajas_sma = (SELECT SUM(n_cajas_smd) FROM dbo.t_sortingmaduraciondet (NOLOCK) WHERE c_folio_sma = @ls_folio),
							n_totalpalets_sma = (SELECT COUNT(*) FROM dbo.t_sortingmaduraciondet (NOLOCK) WHERE c_folio_sma = @ls_folio)
						WHERE ISNULL(c_folio_sma,'') = @ls_folio
					COMMIT TRAN
					SET @as_success = 2;
					SET @as_message = 'La corrida ya esta generada, favor de revisar.';
				END;
			ELSE
				BEGIN
					--SELECT @ls_folio = ISNULL(MAX(c_folio_sma),'') FROM dbo.t_sortingmaduraciondet  /*sacar folio */
					--IF (@ls_folio = '' )
					--	BEGIN
					--		SET @ls_folio = '0000000001'
					--	END
					--ELSE	
					--	BEGIN
					--		SET @ls_folio = RIGHT('0000000000'+convert(varchar(10), CONVERT(numeric,@ls_folio)+1),10)
					--	END;
					/*Sacamos los totales del detalle */	
					SELECT @ld_kilos = SUM(n_kilos_smd), @ln_cajas = SUM(n_cajas_smd), @ll_totalpalets = COUNT(*), @ls_lote = c_codigo_lot
					FROM t_sortingmaduraciondet (NOLOCK) 
					WHERE c_codigo_are = @ls_area
						AND c_finvaciado_smd = 'N'
						GROUP BY c_codigo_lot

					SET @ls_folio =  CONVERT(VARCHAR,RIGHT(DATEPART(YEAR,GETDATE()),2))+ RIGHT('000'+ CONVERT(VARCHAR,DATEPART(DAYOFYEAR,GETDATE())),3)+ @ls_area +@ls_lote+ @ls_tem
					/*insertamos el cabecero si no existe*/
					BEGIN TRAN
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
								d_creacion_sma ,  c_usumod_sma ,	d_modifi_sma ,  c_activo_sma,	c_tipocorrida_sma, c_codigo_emp,
								idrazon
							)
							VALUES
							(	@ls_folio ,			@ls_tem ,   @ld_kilos ,   @ln_cajas , 
								@ll_totalpalets ,   'S' ,   @ls_tiposorteo ,   @ls_usuario , 
								 GETDATE(),	NULL,	NULL ,   '1' , 'C',@ls_empaque ,
								@razon
							)
						END
						/*actualizamos el detalle con el folio*/
						SET @ls_nomarea = (SELECT TOP 1 v_nombre_are FROM dbo.t_areafisica (nolock) WHERE c_codigo_are = @ls_area)
						UPDATE t_sortingmaduraciondet 
						SET /*c_finvaciado_smd = 'S',*/
							c_folio_sma = @ls_folio
						WHERE c_codigo_are = @ls_area 
							AND c_finvaciado_smd = 'N'
						AND ISNULL(c_folio_sma,'') = ''
					COMMIT TRAN;
					SET @as_success = 1;
					SET @as_message = 'El vaciado del área: ['+@ls_nomarea+'] se realizó correctamente. Folio['+@ls_folio+']';
				END;
    END TRY
    BEGIN CATCH
		BEGIN TRAN
        SET @as_success = 0;
		SET @as_message = ERROR_MESSAGE();
		IF @@TRANCOUNT > 0
			ROLLBACK TRAN;
    END CATCH;
END; 

IF @as_operation = 14 /*Guardar Pallet final*/
BEGIN
    BEGIN TRY
        BEGIN TRAN;
		DECLARE @ld_hoy DATETIME = CONVERT(DATETIME,CONVERT(DATE,GETDATE())),
				@ls_hora CHAR(8) = LEFT(CONVERT(VARCHAR,CONVERT(TIME,GETDATE())),8)
        /*SACAMOS LOS DATOS DEL JSON*/
        SELECT @ls_tem = RTRIM(LTRIM(ISNULL(n.el.value('c_codigo_tem[1]', 'varchar(2)'), ''))),
               @ls_empaque = RTRIM(LTRIM(ISNULL(n.el.value('c_codigo_emp[1]', 'varchar(2)'), ''))),
               @ls_lote = RTRIM(LTRIM(ISNULL(n.el.value('c_codigo_lot[1]', 'varchar(4)'), ''))),
               @ls_codigo_pro = RTRIM(LTRIM(ISNULL(n.el.value('c_codigo_pro[1]', 'varchar(4)'), ''))),
               @ls_codigo_eti = RTRIM(LTRIM(ISNULL(n.el.value('c_codigo_eti[1]', 'varchar(2)'), ''))),
               @ls_codigo_col = RTRIM(LTRIM(ISNULL(n.el.value('c_codigo_col[1]', 'varchar(2)'), ''))),
               @ln_cajas = RTRIM(LTRIM(ISNULL(n.el.value('n_bulxpa_pal[1]', 'NUMERIC'), '0'))),
			   @ld_kilos = RTRIM(LTRIM(ISNULL(n.el.value( 'n_peso_pal[1]','decimal(9,3)'),''))),
               @ls_usuario = RTRIM(LTRIM(ISNULL(n.el.value('c_codigo_usu[1]', 'varchar(20)'), ''))),
               @ls_codigo = RTRIM(LTRIM(ISNULL(n.el.value('c_codigo_pal[1]', 'varchar(10)'), ''))),
               @ls_terminal = RTRIM(LTRIM(ISNULL(n.el.value('c_terminal_ccp[1]', 'varchar(100)'), '')))
        FROM @xml.nodes('/') n(el);

		/*Rellenamos Folios con ceros*/
        IF @ls_codigo_pro <> ''
        BEGIN
            SET @ls_codigo_pro = RIGHT('0000' + @ls_codigo_pro, 4);
        END;

        IF @ls_codigo_eti <> ''
        BEGIN
            SET @ls_codigo_eti = RIGHT('00' + @ls_codigo_eti, 2);
        END;

        IF @ls_codigo_col <> ''
        BEGIN
            SET @ls_codigo_col = RIGHT('00' + @ls_codigo_col, 2);
        END;

		/*Validamos los bultos*/
        IF ISNULL(@ln_cajas, 0) <= 0
        BEGIN
            SET @as_success = 0;
            SET @as_message = 'Debe especificar el número de Cajas/Bultos a empacar.';
            RETURN;
        END;

		/*Validamos el peso del pallet */
        IF ISNULL(@ld_kilos, 0) <= 0
        BEGIN
            SET @as_success = 0;
            SET @as_message = 'Debe especificar el paso del pallet.';
            RETURN;
        END;

		/*VALIDAMOS PRESENTACION*/
		/*producto*/
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
            RETURN;
        END;


		/*Etiqueta*/
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
            RETURN;
        END;


		/*Color*/
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
            RETURN;
        END;

        IF EXISTS
        (
            SELECT TOP 1
                   *
            FROM dbo.t_paletemporal pte (NOLOCK)
            WHERE 1 = 1
                  AND ISNULL(pte.c_codigo_tem, '') LIKE @ls_tem
                  AND ISNULL(pte.c_codigo_emp, '') LIKE @ls_empaque
                  AND ISNULL(pte.c_codigo_pte, '') LIKE @ls_codigo
                  AND ISNULL(pte.c_codigofinal_pal, '') <> ''
				  AND ISNULL(pte.c_finalizado_pte,'') = 'N'
        )
        BEGIN
            SET @as_success = 0;
            SET @as_message = 'El Código de Pallet [' + @ls_codigo + '] ya fue confirmado como Pallet final.';
			RETURN	
        END;

		/*folio maximo pallet */
		SELECT @ls_codpte = (dbo.fn_GetCodigoMaxPallet(@ls_tem,@ls_empaque,@ls_usuario,@ls_codigo_pro))

		INSERT INTO t_palet (
			c_codigo_tem, c_codigo_pal, c_codsec_pal, c_codigo_pro, c_codigo_eti,
			c_codigo_col, c_codigo_lot, d_empaque_pal, c_staemp_pal, 
			c_staemb_pal, c_codigo_man, c_codigo_env, n_bulxpa_pal, 
			n_precmn_pal, n_precme_pal, c_contab_pal,  
			c_codigo_usu, d_creacion_pal, c_usumod_pal, d_modifi_pal, c_activo_pal, 
			n_peso_pal, n_precioliq_pal, n_kilosliq_pal, c_hora_pal,
			c_codigo_cot, c_excedente_pal, c_tipo_pal, c_codigo_emp, 
			c_mercado_pal, n_costops_pal, n_costodll_pal,
			c_codigo_sel, n_pesoinicial_pal, n_pesotara_pal, c_codigo_pdo, n_temperatura_pal, c_codigo_emb,
			c_temmed_pal, c_sobrante_pal, n_bulxpainicial_pal, c_codigo_bnd, c_paletreemp_pal,n_ctoadicional_pal,
			b_enviado_FTP
			)
		SELECT 
			pte.c_codigo_tem, @ls_codpte, '01', pro.c_codigo_pro, @ls_codigo_eti,
			@ls_codigo_col, @ls_lote, @ld_hoy, '1', 
			'0', '', pro.c_codigo_env, @ln_cajas,  0, 0, '0', 
			@ls_usuario, @ld_hoy, NULL, NULL, '1', 
			@ld_kilos, 0, 0, @ls_hora, '', '0', 'M', 
			pte.c_codigo_emp, pro.c_merdes_pro, 0, 0,
			null, 0, 0, '', 0, '00', 'C', 'N', 0, null, '', 0,
			0
		FROM dbo.t_paletemporal pte (NOLOCK)
		INNER JOIN dbo.t_paletemporaldet det (NOLOCK) ON det.c_codigo_pte = pte.c_codigo_pte
		INNER JOIN t_producto pro (NOLOCK) ON pro.c_codigo_pro = @ls_codigo_pro
		WHERE 1=1
			AND (pte.c_codigo_tem = @ls_tem
			AND pte.c_codigo_emp = @ls_empaque
			AND pte.c_codigo_pte = @ls_codigo)
			OR (LEN(@ls_codigo) = 6 AND pte.c_codqrtemp_pte = @ls_codigo)

		/*agregamos el codigo del palet al palet temporal y lo inactivamos*/
		UPDATE dbo.t_paletemporal SET c_codigofinal_pal = @ls_codpte , c_activo_dso = '0' WHERE c_codigo_pte = @ls_codigo
			

		SET @as_success = 1;
        SET @as_message = 'El Pallet final [' + @ls_codpte + '] fue guardado con exito.';
        COMMIT TRAN;
    END TRY
    BEGIN CATCH
        SET @as_success = 0;
		SET @as_message = ERROR_MESSAGE();
		IF @@TRANCOUNT > 0
			ROLLBACK TRAN;
    END CATCH;
END;

IF @as_operation = 15 /*Actualizar peso y cajas del palet*/
BEGIN
    BEGIN TRY
		DECLARE @totalcorrida NUMERIC = 0
		DECLARE @totalpallets NUMERIC = 0	
        /*SACAMOS LOS DATOS DEL JSON*/
		SELECT  @ls_qr = RTRIM(LTRIM(ISNULL(n.el.value('c_qr[1]', 'varchar(22)'), ''))),
               @ln_cajas = RTRIM(LTRIM(ISNULL(n.el.value('n_cajas[1]', 'numeric'), '0'))),
			   @ld_kilos = RTRIM(LTRIM(ISNULL(n.el.value( 'n_kilos[1]','decimal(9,3)'),'0'))),
               @ls_empaque = RTRIM(LTRIM(ISNULL(n.el.value('c_codigo_emp[1]', 'varchar(2)'), ''))),
			   @ls_tem = RTRIM(LTRIM(ISNULL(n.el.value('c_codigo_tem[1]', 'varchar(2)'), '')))
        FROM @xml.nodes('/') n(el)

        IF NOT EXISTS (SELECT * FROM dbo.t_paletemporal (NOLOCK) WHERE c_codigo_tem = @ls_tem AND c_codigo_emp = @ls_empaque AND c_codqrtemp_pte = @ls_qr AND c_activo_dso = '1')
		BEGIN	
			SET @as_success = 0;
			SET @as_message = 'El QR [' + @ls_qr + '] no existe o no esta asignado a ningun pallet';
			RETURN	
		END 
		
		/*validar que no sobre pase el peso de la corrida*/
		SELECT @totalcorrida = sma.n_totalkilos_sma,
				@ls_folio = sma.c_folio_sma
		FROM dbo.t_sortingmaduracion sma (NOLOCK)
			INNER JOIN dbo.t_paletemporal pal (NOLOCK)
				ON pal.c_codigo_tem = sma.c_codigo_tem
				   AND pal.c_codigo_emp = sma.c_codigo_emp
				   AND sma.c_folio_sma = pal.c_codigo_sma
		WHERE pal.c_codqrtemp_pte = @ls_qr;
		
		SELECT @totalpallets = SUM(n_kilos_pte) 
		FROM dbo.t_paletemporaldet ( NOLOCK) 
		WHERE c_codigo_sma = @ls_folio
			AND c_codigo_tem = @ls_tem
			AND c_codigo_emp = @ls_empaque;

		set	@totalpallets = @totalpallets + @ld_kilos
		
		IF(@totalpallets > @totalcorrida)
		BEGIN	
			SET @as_success = 0;
			SET @as_message = 'La suma de las libras capturadas sobrepasa el peso total de la corrida. <br>Libras en corrida: ' + CONVERT(VARCHAR(10),@totalcorrida)+' <br>Libras en pallets: '+ CONVERT(VARCHAR(10),@totalpallets)  ;
			RETURN	
		END 

		SELECT @ls_codpte = c_codigo_pte 
		FROM t_paletemporal (NOLOCK)
		WHERE c_codigo_tem = @ls_tem AND c_codigo_emp = @ls_empaque AND c_codqrtemp_pte = @ls_qr AND c_activo_dso = '1' 

		BEGIN TRAN;
		
			UPDATE t_paletemporal SET  d_totkilos_pte = @ld_kilos, d_totcaja_pte = @ln_cajas
			WHERE c_codigo_tem = @ls_tem AND c_codigo_emp = @ls_empaque AND c_codqrtemp_pte = @ls_qr AND c_activo_dso = '1' 

			UPDATE t_paletemporaldet SET n_kilos_pte = @ld_kilos, n_cajas_pte = @ln_cajas 
			WHERE c_codigo_tem = @ls_tem AND c_activo_dso = '1' AND	c_codigo_pte = @ls_codpte

			SET @as_success = 1;
			SET @as_message = 'El Pallet [' + @ls_codpte + '] fue actualizado con exito.';
        COMMIT TRAN;
		
    END TRY
    BEGIN CATCH
        SET @as_success = 0;
        SET @as_message = ERROR_MESSAGE() + ' Linea : '+ERROR_LINE();
		IF @@TRANCOUNT > 0
			ROLLBACK TRAN;
    END CATCH;
END;

IF @as_operation = 16 /*Asignar ubicacion*/
BEGIN
    BEGIN TRY
		 SELECT 
			@ls_codpte = RTRIM(LTRIM(ISNULL(n.el.value('c_codigo_pal[1]', 'varchar(10)'), ''))), 
			@ls_tem = RTRIM(LTRIM(ISNULL(n.el.value('c_codigo_tem[1]', 'varchar(2)'),''))),
			@ls_empaque = RTRIM(LTRIM(ISNULL(n.el.value('c_codigo_emp[1]', 'varchar(2)'),''))),
			@ls_nivel = RTRIM(LTRIM(ISNULL(n.el.value('c_codigo_niv[1]', 'varchar(4)'), ''))),
			@ls_columna = RTRIM(LTRIM(ISNULL(n.el.value('c_codigo_col[1]', 'varchar(4)'), ''))),
			@ls_posicion = RTRIM(LTRIM(ISNULL(n.el.value('c_codigo_pos[1]', 'varchar(4)'), '')))
        FROM @xml.nodes('/') n(el);

		IF NOT EXISTS (SELECT * FROM dbo.t_ubicacionposicion WHERE c_codigo_pos = @ls_posicion AND c_activo_pos = '1')
			BEGIN	
				SET @as_success = 0;
				SET @as_message ='El código de posición ingresado no existe o se encuentra eliminado. Favor de revisar'
				RETURN 
			END

		IF NOT EXISTS (SELECT * FROM dbo.t_ubicacioncolumna WHERE c_codigo_col = @ls_columna AND c_activo_col = '1')
			BEGIN	
				SET @as_success = 0;
				SET @as_message ='El código de columna ingresado no existe o se encuentra eliminado. Favor de revisar'
				RETURN 
			END

		IF NOT EXISTS (SELECT * FROM dbo.t_ubicacionnivel WHERE c_codigo_niv = @ls_nivel AND c_activo_niv = '1')
			BEGIN	
				SET @as_success = 0;
				SET @as_message ='El código de nivel ingresado no existe o se encuentra eliminado. Favor de revisar'
				RETURN 
			END

		SELECT @ls_area = c_codigo_are 
		FROM dbo.t_paletemporal (NOLOCK)
		WHERE c_codigo_pte = @ls_codpte

		IF EXISTS (	SELECT	1 
					  FROM	dbo.t_paletemporal pte (NOLOCK)
					  LEFT	JOIN dbo.t_palletsubicaciones pub (NOLOCK) ON pub.c_codigo_pte = pte.c_codigo_pte
					 WHERE	pte.c_codigo_emp	= @ls_empaque
					   AND	pte.c_codigo_are	= @ls_area
					   AND	pte.c_codigo_niv	= @ls_nivel
					   AND	pte.c_codigo_pos	= @ls_posicion
					   AND	pte.c_columna_col	= @ls_columna
					   AND	pte.c_activo_dso	= '1'
					   AND	pub.c_ubiactual_pub = '1') 
		BEGIN 
			SET @as_success = 0;
			SET @as_message ='La ubicacion seleccionada ya esta ocupada por otro pallet. Favor de revisar'
			RETURN 
		END 

		BEGIN TRAN
			UPDATE dbo.t_paletemporal 
			SET	c_codigo_niv = @ls_nivel , c_codigo_pos = @ls_posicion, c_columna_col = @ls_columna 
			WHERE c_codigo_pte = @ls_codpte AND c_codigo_emp = @ls_empaque AND c_codigo_tem = @ls_tem

			UPDATE dbo.t_palet 
			SET	c_codigo_niv = @ls_nivel , c_codigo_pos = @ls_posicion, c_columna_col = @ls_columna 
			WHERE c_codigo_pal = @ls_codpte AND c_codigo_emp = @ls_empaque AND c_codigo_tem = @ls_tem

			SET @as_success = 1;
			SET @as_message = 'El Pallet [' + @ls_codpte + '] fue actualizado con exito.';
		COMMIT TRAN
    END TRY
    BEGIN CATCH
        SET @as_success = 0;
        SET @as_message = ERROR_MESSAGE() + ' Linea : '+ERROR_LINE();
		IF @@TRANCOUNT > 0
			ROLLBACK TRAN;
    END CATCH;
END;

IF @as_operation = 17 /*Guardado de proceso de sorteo consumer pack */
BEGIN
    BEGIN TRY
		/*SACAMOS LOS DATOS del sorteo DEL JSON*/ 
		SELECT	@ls_folio		= '',
				@ls_area		= RTRIM(LTRIM(ISNULL(n.el.value('c_codigo_are[1]','varchar(4)'),''))),
				@ls_qr			= RTRIM(LTRIM(ISNULL(n.el.value( 'c_codigo[1]','varchar(22)'),''))),
				@ld_kilos		= RTRIM(LTRIM(ISNULL(n.el.value( 'n_kilos_dso[1]','decimal(9,3)'),''))),
				@ln_cajas		= RTRIM(LTRIM(ISNULL(n.el.value( 'n_cajas_dso[1]','numeric'),''))),
				@ls_codcaja		= RTRIM(LTRIM(ISNULL(n.el.value( 'c_codigocaja_tcj[1]','varchar(4)'),''))),
				@ls_codtari		= RTRIM(LTRIM(ISNULL(n.el.value( 'c_codigotarima_tcj[1]','varchar(4)'),''))),
				@ls_usuario		= RTRIM(LTRIM(ISNULL(n.el.value( 'c_codigo_usu[1]','varchar(20)'),''))),
				@ls_tiposorteo	= RTRIM(LTRIM(ISNULL(n.el.value( 'c_tipo[1]','varchar(1)'),''))),
				@ls_tem			= RTRIM(LTRIM(ISNULL(n.el.value('c_codigo_tem[1]', 'varchar(2)'),''))),
				@ls_empaque		= RTRIM(LTRIM(ISNULL(n.el.value('c_codigo_emp[1]', 'varchar(2)'),'')))
		  FROM	@xml.nodes('/') n(el);

		IF NOT EXISTS /*Valida que no este guardada*/
			(	SELECT	1
				  FROM	dbo.t_paletemporal (NOLOCK) 
				 WHERE ((c_codqrtemp_pte	= @ls_qr
						AND	c_codigo_tem	= @ls_tem
						AND c_codigo_emp	= @ls_empaque
						AND c_activo_dso	= '1')
				    OR	(c_codqrtemp_pte = @ls_qr AND LEN(@ls_qr)= 6) AND c_finalizado_pte = 'N')
				    OR	(c_codigo_pte = @ls_qr AND c_activo_dso = '1' AND c_codigo_tem = @ls_tem AND c_codigo_emp = @ls_empaque)
			)
			BEGIN
				SET @as_success = 0;
				SET @as_message = 'El QR ingresado [' + @ls_qr + '] no existe o no esta asignado a un pallet.'; 
				RETURN
			END;

		IF EXISTS /*Valida que no este guardada*/
			(	SELECT	1
				  FROM	t_sortingmaduraciondet det (NOLOCK) 
				 INNER	JOIN t_paletemporal pal (NOLOCK) ON pal.c_codigo_pte = det.c_codigo_pal
				 WHERE	pal.c_codqrtemp_pte = @ls_qr
				   AND	det.c_codigo_tem = @ls_tem
				   AND	pal.c_codigo_emp = @ls_empaque
				   AND	pal.c_activo_dso= '1'
				   AND	det.c_finvaciado_smd='N')
			BEGIN
				SET @as_success = 0;
				SET @as_message = 'El pallet ingresado [' + @ls_qr + '] esta en proceso de vaciado o ya fue vaciado.';
				RETURN	
			END;

		IF (SELECT COUNT(1) FROM dbo.t_areafisica (NOLOCK) WHERE c_codigo_are = @ls_area AND c_tipo_are = '10' ) <= 0 
			begin
				SET @as_success = 0;
				SET @as_message = 'El Área ingresada[' + @ls_area + '] no existe o no es valida.[Tipo 10]';
				RETURN 
			END

		SELECT	DISTINCT TOP 1 @ls_lote = LTRIM(RTRIM(ISNULL(smd.c_codigo_lot ,''))), @ls_codpte =pal.c_codigo_pte 
		  FROM	t_paletemporal pal (NOLOCK)
		 INNER	JOIN t_sortingmaduraciondet smd (NOLOCK) ON pal.c_codigo_sma = smd.c_folio_sma
		 WHERE	(pal.c_codqrtemp_pte = @ls_qr OR pal.c_codigo_pte = @ls_qr
				AND pal.c_codigo_tem = @ls_tem
				AND pal.c_codigo_emp = @ls_empaque)
		   OR	(c_codqrtemp_pte = @ls_qr AND LEN(@ls_qr)= 6)

		--
		--- Pallet Consolidado
		--
		IF @@ROWCOUNT = 0
		BEGIN
			SELECT	TOP 1 @ls_qr = c_codigo_pte 
			  FROM	t_paletemporal_consolidado (NoLock) 
			 WHERE	c_codigo_ptc = @ls_qr 
			 ORDER	BY d_totkilos_ptc DESC
             
			 SELECT	DISTINCT TOP 1 @ls_lote = LTRIM(RTRIM(ISNULL(smd.c_codigo_lot ,''))), @ls_codpte =pal.c_codigo_pte 
			  FROM	t_paletemporal pal (NOLOCK)
			 INNER	JOIN t_sortingmaduraciondet smd (NOLOCK) ON pal.c_codigo_sma = smd.c_folio_sma
			 WHERE	(pal.c_codqrtemp_pte = @ls_qr OR pal.c_codigo_pte = @ls_qr
					AND pal.c_codigo_tem = @ls_tem)
		End

		SELECT	TOP 1 @ls_lote2 =  LTRIM(RTRIM(ISNULL(c_codigo_lot,'')))  
		  FROM	dbo.t_sortingmaduraciondet (NOLOCK)
		 WHERE	c_codigo_are = @ls_area
		   AND	c_codigo_tem = @ls_tem
		   AND	c_codigo_emp = @ls_empaque
		   AND	c_activo_smd = '1'
		   AND	c_finvaciado_smd = 'N'

		IF (@ls_lote <> @ls_lote2 )
			BEGIN	
				SET @as_success = 0;
				SET @as_message = 'El pallet ingresado [' + @ls_qr + '] no pertenece al bloque: ['+@ls_lote2+'] Favor de revisar.';
				RETURN 
			END;

		BEGIN TRAN;
			INSERT INTO t_sortingmaduraciondet (c_folio_sma,		c_codigo_are,		c_codigo_rec,
												c_concecutivo_smd,	c_codigo_pal,		c_codigo_tem,
												c_codigo_lot,		n_kilos_smd,		n_cajas_smd,		   
												c_codigocaja_tcj,	c_codigotarima_tcj,	c_codigo_usu,
												d_creacion_smd,		c_usumod_smd,		d_modifi_smd,
												c_activo_smd,		c_finvaciado_smd,	c_codigo_emp)
			VALUES (	@ls_folio,		@ls_area,		'',
						'',				@ls_codpte,		@ls_tem,
						@ls_lote,		@ld_kilos,		@ln_cajas, 		   
						@ls_codcaja,	@ls_codtari,	@ls_usuario,
						GETDATE(),		NULL,			NULL,
						'1',			'N',			@ls_empaque)
						/*liberar QR */
			IF LEN(@ls_qr) = 6
				UPDATE dbo.t_paletemporal SET  c_finalizado_pte = 'S', c_activo_dso = '0' WHERE c_codigo_pte = @ls_codpte AND c_codigo_emp = @ls_empaque 
			ELSE 
				UPDATE dbo.t_paletemporal SET  c_finalizado_pte = 'S',c_activo_dso = '0' WHERE c_codigo_pte = @ls_codpte AND c_codigo_tem = @ls_tem AND c_codigo_emp = @ls_empaque 
			
		COMMIT TRAN;
		
		SET @as_success = 1;
		SET @as_message = 'Corrida guardada correctamente';

    END TRY

    BEGIN CATCH
		SET @as_success = 0;
		SET @as_message = ERROR_MESSAGE();
		IF @@TRANCOUNT > 0
				ROLLBACK TRAN;
	END CATCH;
END;

IF @as_operation = 18 /*finalizar vaciado de proceso de costumer pack*/
BEGIN
	BEGIN TRY
		/*SACAMOS LOS DATOS del sorteo DEL JSON*/
		SELECT	@ls_area		= RTRIM(LTRIM(ISNULL(n.el.value('c_codigo_are[1]',	'varchar(4)'),''))),
				@ls_usuario		= RTRIM(LTRIM(ISNULL(n.el.value('c_codigo_usu[1]',	'varchar(20)'),''))),
				@ls_tiposorteo	= RTRIM(LTRIM(ISNULL(n.el.value('c_tipo[1]',		'varchar(1)'),''))),
				@ls_tem			= RTRIM(LTRIM(ISNULL(n.el.value('c_codigo_tem[1]',	'varchar(2)'),''))),
				@ls_empaque		= RTRIM(LTRIM(ISNULL(n.el.value('c_codigo_emp[1]',	'varchar(2)'),'')))
		  FROM	@xml.nodes('/') n(el);

		/*VALIDAMOS QUE EXISTA los registros */
		IF EXISTS (	SELECT	1
					  FROM	t_sortingmaduraciondet (NOLOCK) 
					 WHERE	c_codigo_are = @ls_area
					   AND	c_codigo_tem = @ls_tem
					   AND	c_finvaciado_smd = 'N'
					   AND	c_activo_smd = '1'
					  AND	ISNULL(c_folio_sma,'') <> '')
			BEGIN

				/*Sacamos los totales del detalle */	
				SELECT	@ld_kilos = SUM(n_kilos_smd), @ln_cajas = SUM(n_cajas_smd), @ll_totalpalets = COUNT(*),@ls_lote = c_codigo_lot
				  FROM	t_sortingmaduraciondet (NOLOCK) 
				 WHERE	c_codigo_are = @ls_area
				   AND	c_codigo_emp = @ls_empaque
				   AND	c_codigo_tem = @ls_tem
				   AND	c_finvaciado_smd = 'N'
				 GROUP	BY c_codigo_lot

				SET @ls_folio =  CONVERT(VARCHAR,RIGHT(DATEPART(YEAR,GETDATE()),2))+ RIGHT('000'+ CONVERT(VARCHAR,DATEPART(DAYOFYEAR,GETDATE())),3)+ @ls_area +@ls_lote+ @ls_tem

				BEGIN TRAN;
					/*insertamos el cabecero si no existe*/
					IF NOT EXISTS (	SELECT	1
									 FROM	t_sortingmaduracion
									 WHERE	c_folio_sma = @ls_folio)
						BEGIN
							INSERT INTO t_sortingmaduracion (	c_folio_sma,		c_codigo_tem,		n_totalkilos_sma,
																n_totalcajas_sma,	n_totalpalets_sma,	c_finvaciado_sma,  
																c_tipo_sma,			c_codigo_usu,		d_creacion_sma,
																c_usumod_sma,		d_modifi_sma,		c_activo_sma,	
																c_tipocorrida_sma,	c_codigo_emp,		idrazon)
							VALUES (	@ls_folio,		@ls_tem,			@ld_kilos, 
										@ln_cajas,		@ll_totalpalets,	'S',   
										@ls_tiposorteo, @ls_usuario,		GETDATE(),	
										NULL,			NULL ,				'1' , 
										'P',			@ls_empaque,		7)

							/* Se inserta registro en Tabla EYE_SortingCPParaPTI con folio para PTI */
							IF NOT EXISTS( SELECT 1 FROM EYE_SortingCPParaPTI WHERE cIdSortingCP = @ls_folio)
								BEGIN
                            
									SELECT	@razon = IsNull(Max(nIdCorridaParaPTI),0)
									  From	EYE_SortingCPParaPTI 
									 Where	LEFT(cIdSortingCP,5) = LEFT(@ls_folio,5)
									
									IF @razon = 0
										SELECT @razon = CONVERT(INT, LEFT(@ls_folio,5)) * 100 + 1
									ELSE
										SELECT @razon = @razon + 1

									INSERT INTO EYE_SortingCPParaPTI (cIdSortingCP,	nIdCorridaParaPTI, c_codigo_usu)
									SELECT @ls_folio, @razon, @ls_usuario

								END

						END

					UPDATE	t_sortingmaduraciondet SET /*c_finvaciado_smd = 'S',*/
														c_folio_sma = @ls_folio
					 WHERE	c_codigo_are = @ls_area 
					   AND	c_finvaciado_smd = 'N'
					   AND	ISNULL(c_folio_sma,'') = ''
						
					UPDATE t_sortingmaduracion SET	n_totalkilos_sma = (SELECT	SUM(n_kilos_smd) 
																		  FROM	dbo.t_sortingmaduraciondet (NOLOCK) 
																		 WHERE	c_folio_sma = @ls_folio),
													n_totalcajas_sma = (SELECT	SUM(n_cajas_smd) 
																		  FROM	dbo.t_sortingmaduraciondet (NOLOCK) 
																		 WHERE	c_folio_sma = @ls_folio),
													n_totalpalets_sma =(SELECT	COUNT(1) 
																		  FROM	dbo.t_sortingmaduraciondet (NOLOCK) 
																		 WHERE	c_folio_sma = @ls_folio)
					 WHERE	ISNULL(c_folio_sma,'') = @ls_folio

					/*Si ya existe una banda corriendo con esta corrida sumarle los importes del nuevo tag ingresado*/
					UPDATE dbo.t_seleccion SET	n_pesohoscorojo_sel = (	SELECT	SUM(n_kilos_smd) 
																		  FROM	dbo.t_sortingmaduraciondet (NOLOCK) 
																		 WHERE	c_folio_sma = @ls_folio) , 
												n_cajas_sel = (			SELECT	SUM(n_cajas_smd) 
																		  FROM	dbo.t_sortingmaduraciondet (NOLOCK) 
																		 WHERE	c_folio_sma = @ls_folio) ,
												n_cajasrestantes_sel = (SELECT	SUM(n_cajas_smd) 
																		  FROM	dbo.t_sortingmaduraciondet (NOLOCK) 
																		  WHERE	c_folio_sma = @ls_folio)
					 WHERE c_folio_sma = @ls_folio
				COMMIT TRAN;

				SET @as_success = 2;
				SET @as_message = 'La corrida ya esta generada, favor de revisar.';
			END;
		ELSE
			BEGIN
			
				/*Sacamos los totales del detalle */	
				SELECT	@ld_kilos = SUM(n_kilos_smd), @ln_cajas = SUM(n_cajas_smd), @ll_totalpalets = COUNT(*),@ls_lote = c_codigo_lot
				  FROM	t_sortingmaduraciondet (NOLOCK) 
				 WHERE	c_codigo_are = @ls_area
				   AND	c_codigo_emp = @ls_empaque
				   AND	c_codigo_tem = @ls_tem
				   AND	c_finvaciado_smd = 'N'
				 GROUP	BY c_codigo_lot

				SET @ls_folio =  CONVERT(VARCHAR,RIGHT(DATEPART(YEAR,GETDATE()),2))+ RIGHT('000'+ CONVERT(VARCHAR,DATEPART(DAYOFYEAR,GETDATE())),3)+ @ls_area +@ls_lote+ @ls_tem

				BEGIN TRAN;
					/*insertamos el cabecero si no existe*/
					IF NOT EXISTS (	SELECT	1
									  FROM	t_sortingmaduracion
									 WHERE c_folio_sma = @ls_folio)
						BEGIN

							INSERT INTO t_sortingmaduracion (	c_folio_sma,		c_codigo_tem,		n_totalkilos_sma,  
																n_totalcajas_sma,	n_totalpalets_sma,	c_finvaciado_sma,  
																c_tipo_sma,			c_codigo_usu,		d_creacion_sma,  
																c_usumod_sma,		d_modifi_sma,		c_activo_sma,	
																c_tipocorrida_sma,	c_codigo_emp,		idrazon)
							VALUES (@ls_folio,		@ls_tem,			@ld_kilos,   
									@ln_cajas,		@ll_totalpalets,	'S',   
									@ls_tiposorteo,	@ls_usuario,		GETDATE(),	
									NULL,			NULL,				'1', 
									'P',			@ls_empaque,		7 )

								/* Se inserta registro en Tabla EYE_SortingCPParaPTI con folio para PTI */
							IF NOT EXISTS( SELECT 1 FROM EYE_SortingCPParaPTI WHERE cIdSortingCP = @ls_folio)
								BEGIN
                            
									SELECT	@razon = IsNull(Max(nIdCorridaParaPTI),0)
									  From	EYE_SortingCPParaPTI 
									 Where	LEFT(cIdSortingCP,5) = LEFT(@ls_folio,5)
									
									IF @razon = 0
										SELECT @razon = CONVERT(INT, LEFT(@ls_folio,5)) * 100 + 1
									ELSE
										SELECT @razon = @razon + 1

									INSERT INTO EYE_SortingCPParaPTI (cIdSortingCP,	nIdCorridaParaPTI, c_codigo_usu)
									SELECT @ls_folio, @razon, @ls_usuario

								END
						END

					/*actualizamos el detalle con el folio*/
					SET @ls_nomarea = (SELECT TOP 1 v_nombre_are FROM dbo.t_areafisica (nolock) WHERE c_codigo_are = @ls_area)
					
					UPDATE	t_sortingmaduraciondet SET	/*c_finvaciado_smd = 'S',*/
														c_folio_sma = @ls_folio
					 WHERE	c_codigo_are = @ls_area 
					   AND	c_finvaciado_smd = 'N'
					   AND	ISNULL(c_folio_sma,'') = ''

					UPDATE t_sortingmaduracion
						SET	n_totalkilos_sma	= (SELECT SUM(n_kilos_smd)	FROM dbo.t_sortingmaduraciondet (NOLOCK) WHERE c_folio_sma = @ls_folio),
							n_totalcajas_sma	= (SELECT SUM(n_cajas_smd)	FROM dbo.t_sortingmaduraciondet (NOLOCK) WHERE c_folio_sma = @ls_folio),
							n_totalpalets_sma	= (SELECT COUNT(1)			FROM dbo.t_sortingmaduraciondet (NOLOCK) WHERE c_folio_sma = @ls_folio)
					 WHERE ISNULL(c_folio_sma,'') = @ls_folio
						
				COMMIT TRAN;

				SET @as_success = 1;
				SET @as_message = 'El vaciado del área: ['+@ls_nomarea+'] se realizó correctamente. Folio['+@ls_folio+']';
			END;
    END TRY
    
	BEGIN CATCH
	    SET @as_success = 0;
		SET @as_message = ERROR_MESSAGE();
		IF @@TRANCOUNT > 0
			ROLLBACK TRAN;
    END CATCH;
END;

IF @as_operation = 19 /*liberar mesa para nuevas corridas*/
BEGIN
    BEGIN TRY
			/*SACAMOS LOS DATOS del sorteo DEL JSON*/
			SELECT @ls_tem = RTRIM(LTRIM(ISNULL(n.el.value('c_codigo_tem[1]', 'varchar(2)'),''))),
				   @ls_empaque = RTRIM(LTRIM(ISNULL(n.el.value('c_codigo_emp[1]', 'varchar(2)'),''))),
				   @ls_vaciado = RTRIM(LTRIM(ISNULL(n.el.value('c_folio_sma[1]', 'varchar(15)'),''))),
				   @ls_area = RTRIM(LTRIM(ISNULL(n.el.value('c_codigo_are[1]', 'varchar(4)'),'')))
			FROM @xml.nodes('/') n(el);

			 IF EXISTS(SELECT * FROM dbo.t_sortingmaduraciondet (NOLOCK) WHERE c_folio_sma = @ls_vaciado AND c_codigo_are = @ls_area AND c_codigo_emp =  @ls_empaque AND c_codigo_tem = @ls_tem)
			  BEGIN
				BEGIN TRAN
					UPDATE dbo.t_sortingmaduraciondet
					SET c_activo_smd = '0',
						c_finvaciado_smd = 'S'
					WHERE c_folio_sma = @ls_vaciado
						  AND c_codigo_are = @ls_area
						  AND c_codigo_emp = @ls_empaque
						  AND c_codigo_tem = @ls_tem;
				COMMIT TRAN
			  END;

			SET @as_success = 1;
			SET @as_message = 'Mesa liberada.';
    END TRY
    BEGIN CATCH
		BEGIN TRAN
        SET @as_success = 0;
		SET @as_message = ERROR_MESSAGE();
		IF @@TRANCOUNT > 0
			ROLLBACK TRAN;
    END CATCH;
END;

IF @as_operation = 20 /*Guardar pallet consolidado */
BEGIN
    BEGIN TRY
			/*SACAMOS LOS DATOS del sorteo DEL JSON*/
			SELECT 
				@ls_codigo = RTRIM(LTRIM(ISNULL(n.el.value( 'c_codigo_ptc[1]','varchar(10)'),''))),
				@ls_qr = RTRIM(LTRIM(ISNULL(n.el.value( 'c_qr[1]','varchar(22)'),''))),
				@ls_tem = RTRIM(LTRIM(ISNULL(n.el.value('c_codigo_tem[1]', 'varchar(2)'),''))),
				@ls_empaque = RTRIM(LTRIM(ISNULL(n.el.value('c_codigo_emp[1]', 'varchar(2)'),''))),
				@ls_usuario = RTRIM(LTRIM(ISNULL(n.el.value('c_codigo_usu[1]', 'varchar(20)'),'')))
			FROM @xml.nodes('/') n(el);



			/*validar que exista el pallet ingresado */
			IF NOT EXISTS(
						SELECT * FROM dbo.t_paletemporal 
						WHERE ((c_codigo_pte = @ls_qr OR c_codqrtemp_pte = @ls_qr)
							AND c_codigo_emp =  @ls_empaque 
							AND c_codigo_tem = @ls_tem)
							OR (LEN(c_codqrtemp_pte) = 6 AND c_codqrtemp_pte = @ls_qr)
							AND c_activo_dso = '1'
					)
			BEGIN
				SET @as_success = 0;
				SET @as_message = 'El registro ingresado ['+@ls_qr+'] no existe. Favor de revisar';	
				RETURN
			END;

			SELECT	@ls_codpte			= c_codigo_pte,
					@ld_totalkilos		= d_totkilos_pte,
					@ln_cajas			= d_totcaja_pte,
					@ls_lote			= SUBSTRING(c_codigo_sma, 10,4), --(SELECT dbo.fn_getBloquebyQrTemporadaEmpaque(@ls_qr, @ls_tem, @ls_empaque)),
					@ls_gradomaduracion = c_codigo_gma,
					@ls_calibre			= c_codigo_cal
			FROM dbo.t_paletemporal (NOLOCK)
			WHERE ((c_codigo_pte = @ls_qr OR c_codqrtemp_pte = @ls_qr)
						AND c_codigo_emp =  @ls_empaque 
						AND c_codigo_tem = @ls_tem)
						OR (LEN(c_codqrtemp_pte) = 6 AND c_codqrtemp_pte = @ls_qr)

			/*validar que el pallet no aya sidoconsolidado con anterioridad o que no sea un palet consolidado*/
			IF EXISTS(
						SELECT * 
						FROM dbo.t_paletemporal_consolidado 
						WHERE(c_codigo_pte = @ls_codpte OR c_codigo_ptc = @ls_codpte)
						)
			BEGIN
				SET @as_success = 0;
				SET @as_message = 'El registro ingresado ya fue consolidado o es un palle consolidado. Favor de revisar';	
				RETURN
			END;

			IF (@ls_codigo = '')
				BEGIN	
					SELECT @ls_codigo = ISNULL(MAX(c_codigo_pte),'0') FROM t_paletemporal
					SET @ls_codigo = RIGHT( DATEPART(YEAR,GETDATE()) ,2) + RIGHT('00000000'+CONVERT(VARCHAR(10),CONVERT(NUMERIC,@ls_codigo)+1),8)
				END 

			BEGIN TRAN
				IF NOT EXISTS (SELECT * FROM dbo.t_paletemporal_consolidado WHERE c_codigo_pte = @ls_codpte AND c_codigo_ptc = @ls_codigo)
					BEGIN	
						IF((@ls_gradomaduracion+@ls_calibre <> (SELECT TOP 1 ISNULL(c_codigo_gma,'')+ISNULL(c_codigo_cal,'')  FROM dbo.t_paletemporal_consolidado WHERE c_codigo_ptc = @ls_codigo)) AND 
																(( SELECT COUNT(1)  FROM dbo.t_paletemporal_consolidado WHERE c_codigo_ptc = @ls_codigo)>0))
							BEGIN	
								SET @as_success = 0;
								SET @as_message = 'El grado de maduracion y el calibre pallet no coinciden con los demas registros, favor de revisar.';
								ROLLBACK TRAN
								RETURN
							END 

						INSERT INTO dbo.t_paletemporal_consolidado
						(
							c_codigo_ptc,    c_codigo_pte,    c_codigo_tem,    c_codigo_emp,
							d_totcaja_ptc,    d_totkilos_ptc,    c_codigo_usu,    d_creacion_ptc,
							c_usumod_ptc,    d_modifi_ptc,    c_activo_ptc,    bloqueid
							,c_codigo_cal , c_codigo_gma
						)
						VALUES
						(   @ls_codigo,    @ls_codpte,    @ls_tem,    @ls_empaque,   
							@ln_cajas,    @ld_totalkilos,    @ls_usuario,	GETDATE(), 
							NULL,    NULL,    '1',    @ls_lote,
							@ls_calibre,@ls_gradomaduracion
						)
					end

					IF NOT EXISTS (SELECT * FROM dbo.t_paletemporal WHERE c_codigo_pte = @ls_codigo)
						INSERT INTO dbo.t_paletemporal
						(
							c_codigo_pte,	c_codqrtemp_pte,	c_codigo_tem,
							d_totcaja_pte ,		d_totkilos_pte,		d_asignacionqr_pte,	
							d_liberacionqr_pte,	c_codigo_are,	c_ubicacion_pte,  c_codigo_gma,    
							c_finalizado_pte,    c_codigo_usu,    d_creacion_dso,    c_usumod_dso,
							d_modifi_dso,    c_activo_dso, c_codigo_emp, c_codigo_sma, c_codigo_cal,
							d_fecha_pte
						)
						VALUES
						(   
							@ls_codigo,    '',    @ls_tem,       
							@ln_cajas, @ld_totalkilos, GETDATE(), 
							NULL, '0001', NULL,  @ls_gradomaduracion,   
							'N',   @ls_usuario,    GETDATE(),  NULL,      
							NULL,   '1', @ls_empaque,	'' , @ls_calibre  ,
							GETDATE()
						)
					ELSE
						UPDATE dbo.t_paletemporal SET	d_totcaja_pte = cajas, d_totkilos_pte = kilos FROM(
							SELECT kilos = SUM(con.d_totkilos_ptc), cajas = SUM(con.d_totcaja_ptc) 
							FROM dbo.t_paletemporal_consolidado con(NOLOCK) 
							WHERE c_codigo_ptc = @ls_codigo )t_aux
						WHERE c_codigo_pte = @ls_codigo

					UPDATE dbo.t_paletemporal SET c_finalizado_pte = 'N',c_activo_dso = '0' WHERE c_codigo_pte = @ls_codpte AND c_codigo_tem = @ls_tem AND c_codigo_emp = @ls_empaque
					/*seleccionar la corrida con mayor libras para asignar al consolidado*/
					SELECT TOP 1  @ls_folio2 = pal.c_codigo_sma FROM dbo.t_paletemporal_consolidado con(NOLOCK)
					INNER JOIN dbo.t_paletemporal pal (NOLOCK) ON pal.c_codigo_pte = con.c_codigo_pte
					WHERE c_codigo_ptc = @ls_codigo
					ORDER BY pal.d_totkilos_pte DESC,pal.c_codigo_sma DESC

					UPDATE dbo.t_paletemporal SET c_codigo_sma = @ls_folio2 WHERE c_codigo_pte = @ls_codigo AND c_codigo_emp = @ls_empaque AND c_codigo_tem = @ls_tem

			COMMIT TRAN
			SET @as_success = 1;
			SET @as_message = 'Pallet consolidado correctamente.'+@ls_codigo;
    END TRY
    BEGIN CATCH
		BEGIN TRAN
        SET @as_success = 0;
		SET @as_message = ERROR_MESSAGE();
		IF @@TRANCOUNT > 0
			ROLLBACK TRAN;
    END CATCH;
END;

IF @as_operation = 21 /*Eliminar registro individual del consolidado*/
BEGIN
    BEGIN TRY
			/*SACAMOS LOS DATOS del sorteo DEL JSON*/
			SELECT @ls_codpte = RTRIM(LTRIM(ISNULL(n.el.value('c_codigo[1]', 'varchar(10)'),''))),
				   @ls_tem = RTRIM(LTRIM(ISNULL(n.el.value('c_codigo_tem[1]', 'varchar(2)'),''))),
				   @ls_empaque = RTRIM(LTRIM(ISNULL(n.el.value('c_codigo_emp[1]', 'varchar(2)'),'')))
			FROM @xml.nodes('/') n(el);


			 /*VALIDAMOS QUE EXISTA los registros */
			IF NOT EXISTS
				(
					SELECT *
					FROM dbo.t_paletemporal_consolidado (NOLOCK) 
					WHERE c_codigo_pte = @ls_codpte
					AND c_codigo_tem = @ls_tem
					AND c_codigo_emp = @ls_empaque
				)
				BEGIN
					SET @as_success = 0;
					SET @as_message = 'El registro no existe o ya fue eliminado.';
					RETURN;
				END;

				SELECT @ls_codigo = (SELECT TOP 1 c_codigo_ptc FROM dbo.t_paletemporal_consolidado(NOLOCK)
									WHERE c_codigo_pte = @ls_codpte 
									AND c_codigo_tem = @ls_tem
									AND c_codigo_emp = @ls_empaque)
				IF EXISTS
				(
					SELECT *
					FROM dbo.t_sortingmaduraciondet (NOLOCK) 
					WHERE c_codigo_pal = @ls_codigo
				)
				BEGIN
					SET @as_success = 0;
					SET @as_message = 'El pallet ya fue ingresado a una corrida no se puede eliminar, favor de revisar.';
					RETURN;
				END;

				BEGIN TRAN;
					DELETE t_paletemporal_consolidado
					WHERE c_codigo_pte = @ls_codpte 
					AND c_codigo_tem = @ls_tem
					AND c_codigo_emp = @ls_empaque

					IF (SELECT  ISNULL(COUNT(1),0)  FROM t_paletemporal_consolidado (NOLOCK) WHERE c_codigo_ptc = @ls_codigo AND c_codigo_tem = @ls_tem AND c_codigo_emp = @ls_empaque) = 0
						BEGIN 
							DELETE dbo.t_paletemporal WHERE c_codigo_pte = @ls_codigo
							SET @as_message = 'El registro '+@ls_codigo+' fue eliminado exitosamente.(cab/det) '
						END 
					ELSE
						BEGIN
							UPDATE dbo.t_paletemporal                                                                   
							SET	d_totkilos_pte = (SELECT ISNULL(SUM(d_totkilos_ptc),0) FROM t_paletemporal_consolidado (NOLOCK) WHERE c_codigo_ptc = @ls_codigo),
								d_totcaja_pte = (SELECT ISNULL(SUM(d_totcaja_ptc),0) FROM t_paletemporal_consolidado (NOLOCK) WHERE c_codigo_ptc = @ls_codigo)
							WHERE ISNULL(c_codigo_pte,'') = @ls_codigo
							SET @as_message = 'El registro '+@ls_codpte+' fue eliminado exitosamente.(det) Pallet '+@ls_codigo+' actualizado (cab)';
						END
						
					UPDATE dbo.t_paletemporal SET c_finalizado_pte = 'S',c_activo_dso = '1' WHERE c_codigo_pte = @ls_codpte AND c_codigo_tem = @ls_tem AND c_codigo_emp = @ls_empaque
					/*seleccionar la corrida con mayor libras para asignar al consolidado*/
					SELECT TOP 1  @ls_folio2 = pal.c_codigo_sma FROM dbo.t_paletemporal_consolidado con(NOLOCK)
					INNER JOIN dbo.t_paletemporal pal (NOLOCK) ON pal.c_codigo_pte = con.c_codigo_pte
					WHERE c_codigo_ptc = @ls_codigo
					ORDER BY pal.d_totkilos_pte DESC,pal.c_codigo_sma DESC

					UPDATE dbo.t_paletemporal SET c_codigo_sma = @ls_folio2 WHERE c_codigo_pte = @ls_codigo AND c_codigo_emp = @ls_empaque AND c_codigo_tem = @ls_tem

				COMMIT TRAN
				SET @as_success = 1;
    END TRY
    BEGIN CATCH
        SET @as_success = 0;
        SET @as_message = ERROR_MESSAGE();
		IF @@TRANCOUNT > 0
			ROLLBACK TRAN;
    END CATCH;
END;

IF @as_operation = 22 /*Guardar traspaso de pallets */
BEGIN
    BEGIN TRY
		/*SACAMOS LOS DATOS del sorteo DEL JSON*/
		SELECT @ls_empaque = RTRIM(LTRIM(ISNULL(n.el.value('c_codigo_pem[1]', 'varchar(2)'),''))),
				@ls_empaque2 = RTRIM(LTRIM(ISNULL(n.el.value('c_codigo_pem2[1]', 'varchar(2)'),''))),
				@ls_tem = RTRIM(LTRIM(ISNULL(n.el.value('c_codigo_tem[1]', 'varchar(2)'),''))),
				@ls_qr = RTRIM(LTRIM(ISNULL(n.el.value('c_codigo[1]', 'varchar(22)'),''))),
				@ls_usuario = RTRIM(LTRIM(ISNULL(n.el.value('c_codigo_usu[1]', 'varchar(20)'),''))),
				@idtraspaso = RTRIM(LTRIM(ISNULL(n.el.value('n_idtraspaso[1]', 'int'),0)))
		FROM @xml.nodes('/') n(el);

		IF (@ls_qr = '') 
		BEGIN
			SET @as_success = 0;
			SET @as_message = 'El Campo QR no pueden quedar vacios, favor de revisar';
			RETURN;
		END

		IF (@ls_empaque = '' OR @ls_empaque2 = '') 
		BEGIN
			SET @as_success = 0;
			SET @as_message = 'El punto de empaque de origen o destino no pueden quedar vacios, favor de revisar';
			RETURN;
		END

		IF NOT EXISTS /*validar punto de empaque origen */
		(
			SELECT c_codigo_pem
			FROM dbo.t_puntoempaque (NOLOCK) 
			WHERE c_codigo_pem = @ls_empaque
			AND c_activo_pem = '1'
		)
		BEGIN
			SET @as_success = 0;
			SET @as_message = 'El punto de empaque de origen no es valido o no existe, favor de revisar';
			RETURN;
		END;

		IF NOT EXISTS /*validar punto de empaque destino */
		(
			SELECT c_codigo_pem
			FROM dbo.t_puntoempaque (NOLOCK) 
			WHERE c_codigo_pem = @ls_empaque2
			AND c_activo_pem = '1'
		)
		BEGIN
			SET @as_success = 0;
			SET @as_message = 'El punto de empaque destino no es valido o no existe, favor de revisar';
			RETURN;
		END;

		IF LEN(@ls_qr) = 22 /*Validar QR ***********************************************************************************************************************/
			BEGIN
				IF NOT EXISTS
				(
					SELECT c_codqrtemp_pte
					FROM dbo.t_paletemporal (NOLOCK) 
					WHERE c_codqrtemp_pte = @ls_qr
					AND c_codigo_tem = @ls_tem
					AND c_codigo_emp = @ls_empaque
					AND c_finalizado_pte = 'N'
				)
				BEGIN
					SET @as_success = 0;
					SET @as_message = 'El QR no existe o no esta relacionado a un pallet.';
					RETURN;
				END;

				IF EXISTS
				(
					SELECT c_IdPallet_ptad
					FROM dbo.t_pallet_traspaso_app_det det (NOLOCK) 
					INNER JOIN dbo.t_pallet_traspaso_app tra(NOLOCK) ON tra.n_idfolio_pta = det.n_idfolio_pta
					WHERE det.c_codqrtemp_pte = @ls_qr
					AND tra.c_Estatus_pta = 'C'
				)
				BEGIN
					SET @as_success = 0;
					SET @as_message = 'El registro ingresado ya se encuentra en proceso de traspaso. Favor de revisar.';
					RETURN;
				END;

				BEGIN TRAN
					IF NOT EXISTS (SELECT * FROM dbo.t_pallet_traspaso_app (NOLOCK) WHERE n_idfolio_pta = @idtraspaso)
					BEGIN	
						/*insertar cabecero*/
						INSERT INTO dbo.t_pallet_traspaso_app
						(
							d_fecha_pta,				    c_AlmacenQueEnvia_pta,			c_AlmacenQueRecibe_pta,			n_PalletsEnviados_pta,
							n_CajasEnviadas_pta,			n_PesoPallets_pta,				c_Estatus_pta,				    c_codigo_tem,
							c_codigo_usu,				    d_creacion_pta,				    c_usumod_pta,				    d_modifi_pta,
							c_activo_pta
						)
						VALUES
						(  
							GETDATE(), 				    @ls_empaque,        				    @ls_empaque2,        				    0,      				    
							0,         				    0,         				    'C',       				    @ls_tem,       				    
							@ls_usuario,        		GETDATE(), 				    NULL,      				    NULL,      				    
							'1'         
						)
					END 
				
					/*sacamos consecutivo de traspaso*/
					SELECT @idtraspaso = ISNULL(MAX(n_idfolio_pta),0) FROM dbo.t_pallet_traspaso_app
					IF @idtraspaso = 0 BEGIN SELECT @idtraspaso = ISNULL(MAX(n_idfolio_pta),0)+1 FROM dbo.t_pallet_traspaso_app END 
					
					SELECT @ls_conse = ISNULL(MAX(n_Consecutivo_ptad),0)+1 FROM dbo.t_pallet_traspaso_app_det WHERE n_idfolio_pta = @idtraspaso
					SET @ls_conse = RIGHT('000'+ @ls_conse,3)

					/*insertar detalle*/
					INSERT INTO dbo.t_pallet_traspaso_app_det
					(
						n_idfolio_pta,
						n_Consecutivo_ptad,					c_IdPallet_ptad,				c_codqrtemp_pte,		n_cajas_ptad,				    
						n_peso_ptad,						c_codigo_gma,				    c_codigo_cal,			c_codigo_usu,				    
						d_creacion_ptad,				    c_usumod_ptad,				    d_modifi_ptad,			c_activo_ptad,
						c_codigo_tem
					)
					SELECT
						@idtraspaso,
						@ls_conse,						c_codigo_pte,					@ls_qr,					d_totcaja_pte,				    
						d_totkilos_pte,				    c_codigo_gma,					c_codigo_cal,			@ls_usuario,
						GETDATE(),						NULL,      						NULL,					'1',
						@ls_tem
					FROM dbo.t_paletemporal (NOLOCK)
					WHERE c_codqrtemp_pte = @ls_qr
						AND c_codigo_tem = @ls_tem
						AND c_codigo_emp = @ls_empaque
						AND c_finalizado_pte = 'N'
				
					/*Actualizamos los importes con los registros del detalle */
					UPDATE dbo.t_pallet_traspaso_app 
					SET	n_PalletsEnviados_pta = (SELECT COUNT(n_idfolio_pta) FROM dbo.t_pallet_traspaso_app_det (NOLOCK) WHERE n_idfolio_pta = @idtraspaso ),
						n_CajasEnviadas_pta = (SELECT SUM(n_cajas_ptad) FROM dbo.t_pallet_traspaso_app_det (NOLOCK) WHERE n_idfolio_pta = @idtraspaso ) ,
						n_PesoPallets_pta = (SELECT SUM(n_peso_ptad) FROM dbo.t_pallet_traspaso_app_det (NOLOCK) WHERE n_idfolio_pta = @idtraspaso )
					WHERE n_idfolio_pta = @idtraspaso

					SET @as_success = 1;
					SET @as_message = 'Registro agregado al traspaso ['+CONVERT(VARCHAR(10),@idtraspaso)+'] correctamente.';
				COMMIT TRAN
			END 
		ELSE IF	LEN(@ls_qr) = 10 /*Validar Pallet temporal o final***********************************************************************************************************************/
			BEGIN	
			IF NOT EXISTS
				(
					SELECT c_codigo_pte
					FROM dbo.t_paletemporal (NOLOCK) 
					WHERE c_codigo_pte = @ls_qr
					AND c_codigo_tem = @ls_tem
					AND c_codigo_emp = @ls_empaque
					AND c_activo_dso = '1'
					UNION ALL 
					SELECT c_codigo_pal 
					FROM dbo.t_palet (NOLOCK) 
					WHERE c_codigo_pal = @ls_qr
					AND c_codigo_tem = @ls_tem
					AND c_codigo_emp = @ls_empaque
					AND c_activo_pal = '1'
				)
				BEGIN
					SET @as_success = 0;
					SET @as_message = 'El Pallet no existe o no esta activo.';
					RETURN;
				END;

				IF EXISTS /*Pallets temporales***********************************************************************************************************************/
				(
					SELECT c_codigo_pte
					FROM dbo.t_paletemporal (NOLOCK) 
					WHERE c_codigo_pte = @ls_qr
					AND c_codigo_tem = @ls_tem
					AND c_codigo_emp = @ls_empaque
					AND c_activo_dso = '1'
				)
				BEGIN
					IF EXISTS
					(
						SELECT c_IdPallet_ptad
						FROM dbo.t_pallet_traspaso_app_det det (NOLOCK) 
						INNER JOIN dbo.t_pallet_traspaso_app tra(NOLOCK) ON tra.n_idfolio_pta = det.n_idfolio_pta
						WHERE det.c_IdPallet_ptad = @ls_qr
						AND tra.c_Estatus_pta = 'C'
					)
					BEGIN
						SET @as_success = 0;
						SET @as_message = 'El registro ingresado ['+@ls_qr+'] ya se encuentra en proceso de traspaso. Favor de revisar.';
						RETURN;
					END;
					BEGIN TRAN
						IF NOT EXISTS (SELECT * FROM dbo.t_pallet_traspaso_app (NOLOCK) WHERE n_idfolio_pta = @idtraspaso)
						BEGIN	
							/*insertar cabecero*/
							INSERT INTO dbo.t_pallet_traspaso_app
							(
								d_fecha_pta,				    c_AlmacenQueEnvia_pta,			c_AlmacenQueRecibe_pta,			n_PalletsEnviados_pta,
								n_CajasEnviadas_pta,			n_PesoPallets_pta,				c_Estatus_pta,				    c_codigo_tem,
								c_codigo_usu,				    d_creacion_pta,				    c_usumod_pta,				    d_modifi_pta,
								c_activo_pta
							)
							VALUES
							(  
								GETDATE(), 				    @ls_empaque,        				    @ls_empaque2,        				    0,      				    
								0,         				    0,         				    'C',       				    @ls_tem,       				    
								@ls_usuario,        		GETDATE(), 				    NULL,      				    NULL,      				    
								'1'         
							)
						END 
				
						/*sacamos consecutivo de traspaso*/
						SELECT @idtraspaso = ISNULL(MAX(n_idfolio_pta),0) FROM dbo.t_pallet_traspaso_app
						IF @idtraspaso = 0 BEGIN SELECT @idtraspaso = ISNULL(MAX(n_idfolio_pta),0)+1 FROM dbo.t_pallet_traspaso_app END 
					
						SELECT @ls_conse = ISNULL(MAX(n_Consecutivo_ptad),0)+1 FROM dbo.t_pallet_traspaso_app_det WHERE n_idfolio_pta = @idtraspaso
						SET @ls_conse = RIGHT('000'+ @ls_conse,3)

						/*insertar detalle*/
						INSERT INTO dbo.t_pallet_traspaso_app_det
						(
							n_idfolio_pta,
							n_Consecutivo_ptad,					c_IdPallet_ptad,				c_codqrtemp_pte,		n_cajas_ptad,				    
							n_peso_ptad,						c_codigo_gma,				    c_codigo_cal,			c_codigo_usu,				    
							d_creacion_ptad,				    c_usumod_ptad,				    d_modifi_ptad,			c_activo_ptad,
							c_codigo_tem
						)
						SELECT
							@idtraspaso,
							@ls_conse,						@ls_qr,							c_codqrtemp_pte,		d_totcaja_pte,				    
							d_totkilos_pte,				    c_codigo_gma,					c_codigo_cal,			@ls_usuario,
							GETDATE(),						NULL,      						NULL,					'1',
							@ls_tem
						FROM dbo.t_paletemporal (NOLOCK)
						WHERE c_codigo_pte = @ls_qr
							AND c_codigo_tem = @ls_tem
							AND c_codigo_emp = @ls_empaque
							AND c_activo_dso = '1'
				
						/*Actualizamos los importes con los registros del detalle */
						UPDATE dbo.t_pallet_traspaso_app 
						SET	n_PalletsEnviados_pta = (SELECT COUNT(n_idfolio_pta) FROM dbo.t_pallet_traspaso_app_det (NOLOCK) WHERE n_idfolio_pta = @idtraspaso ),
							n_CajasEnviadas_pta = (SELECT SUM(n_cajas_ptad) FROM dbo.t_pallet_traspaso_app_det (NOLOCK) WHERE n_idfolio_pta = @idtraspaso ) ,
							n_PesoPallets_pta = (SELECT SUM(n_peso_ptad) FROM dbo.t_pallet_traspaso_app_det (NOLOCK) WHERE n_idfolio_pta = @idtraspaso )
						WHERE n_idfolio_pta = @idtraspaso

						SET @as_success = 1;
						SET @as_message = 'Registro agregado al traspaso ['+CONVERT(VARCHAR(10),@idtraspaso)+'] correctamente.';
					COMMIT TRAN
				END;

				IF EXISTS  /*Pallets Finales***********************************************************************************************************************/
				(
					SELECT c_codigo_pal 
					FROM dbo.t_palet (NOLOCK) 
					WHERE c_codigo_pal = @ls_qr
					AND c_codigo_tem = @ls_tem
					AND c_codigo_emp = @ls_empaque
					AND c_activo_pal = '1'
				)
				BEGIN
					IF EXISTS
					(
						SELECT c_IdPallet_ptad
						FROM dbo.t_pallet_traspaso_app_det det (NOLOCK) 
						INNER JOIN dbo.t_pallet_traspaso_app tra(NOLOCK) ON tra.n_idfolio_pta = det.n_idfolio_pta
						WHERE det.c_IdPallet_ptad = @ls_qr
						AND tra.c_Estatus_pta = 'C'
					)
					BEGIN
						SET @as_success = 0;
						SET @as_message = 'El registro ingresado ['+@ls_qr+'] ya se encuentra en proceso de traspaso. Favor de revisar.';
						RETURN;
					END;
						BEGIN TRAN
							IF NOT EXISTS (SELECT * FROM dbo.t_pallet_traspaso_app (NOLOCK) WHERE n_idfolio_pta = @idtraspaso)
							BEGIN	
								/*insertar cabecero*/
								INSERT INTO dbo.t_pallet_traspaso_app
								(
									d_fecha_pta,				    c_AlmacenQueEnvia_pta,			c_AlmacenQueRecibe_pta,			n_PalletsEnviados_pta,
									n_CajasEnviadas_pta,			n_PesoPallets_pta,				c_Estatus_pta,				    c_codigo_tem,
									c_codigo_usu,				    d_creacion_pta,				    c_usumod_pta,				    d_modifi_pta,
									c_activo_pta
								)
								VALUES
								(  
									GETDATE(), 				    @ls_empaque,        				    @ls_empaque2,        				    0,      				    
									0,         				    0,         				    'C',       				    @ls_tem,       				    
									@ls_usuario,        		GETDATE(), 				    NULL,      				    NULL,      				    
									'1'         
								)
							END 
				
							/*sacamos consecutivo de traspaso*/
							SELECT @idtraspaso = ISNULL(MAX(n_idfolio_pta),0) FROM dbo.t_pallet_traspaso_app
							IF @idtraspaso = 0 BEGIN SELECT @idtraspaso = ISNULL(MAX(n_idfolio_pta),0)+1 FROM dbo.t_pallet_traspaso_app END 
					
							SELECT @ls_conse = ISNULL(MAX(n_Consecutivo_ptad),0)+1 FROM dbo.t_pallet_traspaso_app_det  
							SET @ls_conse = RIGHT('000'+ @ls_conse,3)

							/*insertar detalle*/
							INSERT INTO dbo.t_pallet_traspaso_app_det
							(
								n_idfolio_pta,
								n_Consecutivo_ptad,					c_IdPallet_ptad,				c_codqrtemp_pte,		n_cajas_ptad,				    
								n_peso_ptad,						c_codigo_gma,				    c_codigo_cal,			c_codigo_usu,				    
								d_creacion_ptad,				    c_usumod_ptad,				    d_modifi_ptad,			c_activo_ptad,
								c_codigo_tem
							)
							SELECT
								@idtraspaso,
								@ls_conse,						@ls_qr,							@ls_qr,					n_bulxpa_pal,				    
								n_peso_pal,						'0000',							'0000',					@ls_usuario,
								GETDATE(),						NULL,      						NULL,					'1',
								@ls_tem
							FROM dbo.t_palet (NOLOCK)
							WHERE c_codigo_pal = @ls_qr
								AND c_codigo_tem = @ls_tem
								AND c_codigo_emp = @ls_empaque
								AND c_activo_pal = '1'
				
							/*Actualizamos los importes con los registros del detalle */
							UPDATE dbo.t_pallet_traspaso_app 
							SET	n_PalletsEnviados_pta = (SELECT COUNT(n_idfolio_pta) FROM dbo.t_pallet_traspaso_app_det (NOLOCK) WHERE n_idfolio_pta = @idtraspaso ),
								n_CajasEnviadas_pta = (SELECT SUM(n_cajas_ptad) FROM dbo.t_pallet_traspaso_app_det (NOLOCK) WHERE n_idfolio_pta = @idtraspaso ) ,
								n_PesoPallets_pta = (SELECT SUM(n_peso_ptad) FROM dbo.t_pallet_traspaso_app_det (NOLOCK) WHERE n_idfolio_pta = @idtraspaso )
							WHERE n_idfolio_pta = @idtraspaso

							SET @as_success = 1;
							SET @as_message = 'Registro agregado al traspaso ['+CONVERT(VARCHAR(10),@idtraspaso)+'] correctamente.';
						COMMIT TRAN
					END;
			END;
		ELSE IF	LEN(@ls_qr) = 9 /*Validar Recepcion-secuencia ***********************************************************************************************************************/
			BEGIN		
				IF NOT EXISTS
				(
					SELECT c_codigo_rec+c_secuencia_red
					FROM dbo.t_recepciondet (NOLOCK) 
					WHERE c_codigo_rec+c_secuencia_red = @ls_qr
					AND c_codigo_tem = @ls_tem
					AND c_codigo_pem = @ls_empaque
					AND c_activo_red = '1'
				)
				BEGIN
					SET @as_success = 0;
					SET @as_message = 'La Recepción-Secuencia no existe o no esta activo.';
					RETURN;
				END;
				IF EXISTS
				(
					SELECT c_IdPallet_ptad
					FROM dbo.t_pallet_traspaso_app_det det (NOLOCK) 
					INNER JOIN dbo.t_pallet_traspaso_app tra(NOLOCK) ON tra.n_idfolio_pta = det.n_idfolio_pta
					WHERE det.c_IdPallet_ptad = @ls_qr
					AND tra.c_Estatus_pta = 'C'
				)
				BEGIN
					SET @as_success = 0;
					SET @as_message = 'El registro ingresado ['+@ls_qr+'] ya se encuentra en proceso de traspaso. Favor de revisar.';
					RETURN;
				END;
				BEGIN TRAN
					IF NOT EXISTS (SELECT * FROM dbo.t_pallet_traspaso_app (NOLOCK) WHERE n_idfolio_pta = @idtraspaso)
					BEGIN	
						/*insertar cabecero*/
						INSERT INTO dbo.t_pallet_traspaso_app
						(
							d_fecha_pta,				    c_AlmacenQueEnvia_pta,			c_AlmacenQueRecibe_pta,			n_PalletsEnviados_pta,
							n_CajasEnviadas_pta,			n_PesoPallets_pta,				c_Estatus_pta,				    c_codigo_tem,
							c_codigo_usu,				    d_creacion_pta,				    c_usumod_pta,				    d_modifi_pta,
							c_activo_pta
						)
						VALUES
						(  
							GETDATE(), 				    @ls_empaque,        		@ls_empaque2,        		0,      				    
							0,         				    0,         				    'C',       				    @ls_tem,       				    
							@ls_usuario,        		GETDATE(), 				    NULL,      				    NULL,      				    
							'1'         
						)
					END 
				
					/*sacamos consecutivo de traspaso*/
					SELECT @idtraspaso = ISNULL(MAX(n_idfolio_pta),0) FROM dbo.t_pallet_traspaso_app
					IF @idtraspaso = 0 BEGIN SELECT @idtraspaso = ISNULL(MAX(n_idfolio_pta),0)+1 FROM dbo.t_pallet_traspaso_app END 
					
					SELECT @ls_conse = ISNULL(MAX(n_Consecutivo_ptad),0)+1 FROM dbo.t_pallet_traspaso_app_det WHERE n_idfolio_pta = @idtraspaso
					SET @ls_conse = RIGHT('000'+ @ls_conse,3)

					/*insertar detalle*/
					INSERT INTO dbo.t_pallet_traspaso_app_det
					(
						n_idfolio_pta,
						n_Consecutivo_ptad,					c_IdPallet_ptad,				c_codqrtemp_pte,		n_cajas_ptad,				    
						n_peso_ptad,						c_codigo_gma,				    c_codigo_cal,			c_codigo_usu,				    
						d_creacion_ptad,				    c_usumod_ptad,				    d_modifi_ptad,			c_activo_ptad,
						c_codigo_tem
					)
					SELECT
						@idtraspaso,
						@ls_conse,						@ls_qr,								@ls_qr,					n_cajascorte_red,				    
						n_kilos_red,				    '0000',								'0000',					@ls_usuario,
						GETDATE(),						NULL,      							NULL,					'1',
						@ls_tem
					FROM dbo.t_recepciondet (NOLOCK)
					WHERE c_codigo_rec+c_secuencia_red = @ls_qr
						AND c_codigo_tem = @ls_tem
						AND c_codigo_pem = @ls_empaque
						AND c_activo_red = '1'
				
					/*Actualizamos los importes con los registros del detalle */
					UPDATE dbo.t_pallet_traspaso_app 
					SET	n_PalletsEnviados_pta = (SELECT COUNT(n_idfolio_pta) FROM dbo.t_pallet_traspaso_app_det (NOLOCK) WHERE n_idfolio_pta = @idtraspaso ),
						n_CajasEnviadas_pta = (SELECT SUM(n_cajas_ptad) FROM dbo.t_pallet_traspaso_app_det (NOLOCK) WHERE n_idfolio_pta = @idtraspaso ) ,
						n_PesoPallets_pta = (SELECT SUM(n_peso_ptad) FROM dbo.t_pallet_traspaso_app_det (NOLOCK) WHERE n_idfolio_pta = @idtraspaso )
					WHERE n_idfolio_pta = @idtraspaso

					SET @as_success = 1;
					SET @as_message = 'Registro agregado al traspaso ['+CONVERT(VARCHAR(10),@idtraspaso)+'] correctamente.';
				COMMIT TRAN
			END; 
		ELSE IF	LEN(@ls_qr) = 6 /*Validar TagID ***********************************************************************************************************************/
			BEGIN		
				IF NOT EXISTS
				(
					SELECT c_codexterno_rec
					FROM dbo.t_recepciondet (NOLOCK) 
					WHERE c_codexterno_rec = @ls_qr
					AND c_codigo_tem = @ls_tem
					AND c_codigo_pem = @ls_empaque
					AND c_activo_red = '1'
				)
				BEGIN
					SET @as_success = 0;
					SET @as_message = 'El Tag ID no existe o no esta activo.';
					RETURN;
				END;
				IF EXISTS
				(
					SELECT c_IdPallet_ptad
					FROM dbo.t_pallet_traspaso_app_det det (NOLOCK) 
					INNER JOIN dbo.t_pallet_traspaso_app tra(NOLOCK) ON tra.n_idfolio_pta = det.n_idfolio_pta
					WHERE det.c_IdPallet_ptad = @ls_qr
					AND tra.c_Estatus_pta = 'C'
				)
				BEGIN
					SET @as_success = 0;
					SET @as_message = 'El registro ingresado ['+@ls_qr+'] ya se encuentra en proceso de traspaso. Favor de revisar.';
					RETURN;
				END;
				BEGIN TRAN
					IF NOT EXISTS (SELECT * FROM dbo.t_pallet_traspaso_app (NOLOCK) WHERE n_idfolio_pta = @idtraspaso)
					BEGIN	
						/*insertar cabecero*/
						INSERT INTO dbo.t_pallet_traspaso_app
						(
							d_fecha_pta,				    c_AlmacenQueEnvia_pta,			c_AlmacenQueRecibe_pta,			n_PalletsEnviados_pta,
							n_CajasEnviadas_pta,			n_PesoPallets_pta,				c_Estatus_pta,				    c_codigo_tem,
							c_codigo_usu,				    d_creacion_pta,				    c_usumod_pta,				    d_modifi_pta,
							c_activo_pta
						)
						VALUES
						(  
							GETDATE(), 				    @ls_empaque,        		@ls_empaque2,        			0,      				    
							0,         				    0,         				    'C',       				    @ls_tem,       				    
							@ls_usuario,        		GETDATE(), 				    NULL,      				    NULL,      				    
							'1'         
						)
					END 
				
					/*sacamos consecutivo de traspaso*/
					SELECT @idtraspaso = ISNULL(MAX(n_idfolio_pta),0) FROM dbo.t_pallet_traspaso_app
					IF @idtraspaso = 0 BEGIN SELECT @idtraspaso = ISNULL(MAX(n_idfolio_pta),0)+1 FROM dbo.t_pallet_traspaso_app END 
					
					SELECT @ls_conse = ISNULL(MAX(n_Consecutivo_ptad),0)+1 FROM dbo.t_pallet_traspaso_app_det WHERE n_idfolio_pta = @idtraspaso
					SET @ls_conse = RIGHT('000'+ @ls_conse,3)

					/*insertar detalle*/
					INSERT INTO dbo.t_pallet_traspaso_app_det
					(
						n_idfolio_pta,
						n_Consecutivo_ptad,					c_IdPallet_ptad,				c_codqrtemp_pte,		n_cajas_ptad,				    
						n_peso_ptad,						c_codigo_gma,				    c_codigo_cal,			c_codigo_usu,				    
						d_creacion_ptad,				    c_usumod_ptad,				    d_modifi_ptad,			c_activo_ptad,
						c_codigo_tem
					)
					SELECT
						@idtraspaso,
						@ls_conse,						@ls_qr,								@ls_qr,					n_cajascorte_red,				    
						n_kilos_red,				    '0000',								'0000',					@ls_usuario,
						GETDATE(),						NULL,      							NULL,					'1',
						@ls_tem
					FROM dbo.t_recepciondet (NOLOCK)
					WHERE c_codexterno_rec = @ls_qr
						AND c_codigo_tem = @ls_tem
						AND c_codigo_pem = @ls_empaque
						AND c_activo_red = '1'
				
					/*Actualizamos los importes con los registros del detalle */
					UPDATE dbo.t_pallet_traspaso_app 
					SET	n_PalletsEnviados_pta = (SELECT COUNT(n_idfolio_pta) FROM dbo.t_pallet_traspaso_app_det (NOLOCK) WHERE n_idfolio_pta = @idtraspaso ),
						n_CajasEnviadas_pta = (SELECT SUM(n_cajas_ptad) FROM dbo.t_pallet_traspaso_app_det (NOLOCK) WHERE n_idfolio_pta = @idtraspaso ) ,
						n_PesoPallets_pta = (SELECT SUM(n_peso_ptad) FROM dbo.t_pallet_traspaso_app_det (NOLOCK) WHERE n_idfolio_pta = @idtraspaso )
					WHERE n_idfolio_pta = @idtraspaso

					SET @as_success = 1;
					SET @as_message = 'Registro agregado al traspaso ['+CONVERT(VARCHAR(10),@idtraspaso)+'] correctamente.';
				COMMIT TRAN
			END; 
    END TRY
    BEGIN CATCH
        SET @as_success = 0;
        SET @as_message = ERROR_MESSAGE();
		IF @@TRANCOUNT > 0
			ROLLBACK TRAN;
    END CATCH;
END;

IF @as_operation = 23 /*Eliminar registro individual del traspaso*/
BEGIN
    BEGIN TRY
			/*SACAMOS LOS DATOS del sorteo DEL JSON*/
			SELECT TOP 1 @ls_codigo = RTRIM(LTRIM(ISNULL(n.el.value('c_codigo[1]', 'varchar(22)'),''))),
				   @idtraspaso = RTRIM(LTRIM(ISNULL(n.el.value('n_idtraspaso[1]', 'INT'),'')))
			FROM @xml.nodes('/') n(el);

			 /*VALIDAMOS QUE EXISTA los registros */
			IF NOT EXISTS
				(
					SELECT *
					FROM dbo.t_pallet_traspaso_app_det det (NOLOCK) 
					INNER JOIN dbo.t_pallet_traspaso_app tra ( NOLOCK) ON tra.n_idfolio_pta = det.n_idfolio_pta 
					WHERE tra.c_Estatus_pta = 'C'
					AND det.c_IdPallet_ptad = @ls_codigo
					AND det.n_idfolio_pta = @idtraspaso
				)
				BEGIN
					SET @as_success = 0;
					SET @as_message = 'El registro['+@ls_codigo+'] no existe o ya fue eliminado.'+CONVERT(varchar(10),@idtraspaso)
					RETURN;
				END;
			ELSE
				BEGIN
					BEGIN TRAN;
						DELETE dbo.t_pallet_traspaso_app_det 
						WHERE c_IdPallet_ptad = @ls_codigo
						AND n_idfolio_pta = @idtraspaso

						IF (SELECT  ISNULL(COUNT(1),0)  FROM t_pallet_traspaso_app_det (NOLOCK) WHERE n_idfolio_pta = @idtraspaso) = 0
							BEGIN 
								/*eliminamos el traspaso por completa*/
								DELETE t_pallet_traspaso_app WHERE n_idfolio_pta = @idtraspaso
								SELECT @idtraspaso = ISNULL(MAX(n_idfolio_pta),0) FROM dbo.t_pallet_traspaso_app 
								DBCC CHECKIDENT(t_pallet_traspaso_app, RESEED , @idtraspaso)
								SET @as_success = 1;
								SET @as_message = 'El registro '+@ls_codigo+' fue eliminado exitosamente.(cab/det) '
							END 
						ELSE
							BEGIN
								/*Actualizamos los importes con los registros del detalle */
								UPDATE dbo.t_pallet_traspaso_app 
								SET	n_PalletsEnviados_pta = (SELECT COUNT(n_idfolio_pta) FROM dbo.t_pallet_traspaso_app_det (NOLOCK) WHERE n_idfolio_pta = @idtraspaso ),
									n_CajasEnviadas_pta = (SELECT SUM(n_cajas_ptad) FROM dbo.t_pallet_traspaso_app_det (NOLOCK) WHERE n_idfolio_pta = @idtraspaso ) ,
									n_PesoPallets_pta = (SELECT SUM(n_peso_ptad) FROM dbo.t_pallet_traspaso_app_det (NOLOCK) WHERE n_idfolio_pta = @idtraspaso )
								WHERE n_idfolio_pta = @idtraspaso
								SET @as_success = 1;
								SET @as_message = 'El registro '+@ls_codigo+' fue eliminado exitosamente.(det) actualizado (cab)';
							END
						COMMIT TRAN
				END;
    END TRY
    BEGIN CATCH
        SET @as_success = 0;
        SET @as_message = ERROR_MESSAGE();
		IF @@TRANCOUNT > 0
			SELECT @idtraspaso = ISNULL(MAX(n_idfolio_pta),0) FROM dbo.t_pallet_traspaso_app 
			DBCC CHECKIDENT(t_pallet_traspaso_app, RESEED , @idtraspaso)
			ROLLBACK TRAN;
    END CATCH;
END;

IF @as_operation = 24 /*terminar transferencia entre puntos de empaque*/
BEGIN
    BEGIN TRY
		/*SACAMOS LOS DATOS del sorteo DEL JSON*/
		SELECT @ls_empaque = RTRIM(LTRIM(ISNULL(n.el.value('c_codigo_pem[1]', 'varchar(2)'),''))),
				@ls_empaque2 = RTRIM(LTRIM(ISNULL(n.el.value('c_codigo_pem2[1]', 'varchar(2)'),''))),
				@ls_tem = RTRIM(LTRIM(ISNULL(n.el.value('c_codigo_tem[1]', 'varchar(2)'),''))),
				@ls_qr = RTRIM(LTRIM(ISNULL(n.el.value('c_codigo[1]', 'varchar(22)'),''))),
				@ls_usuario = RTRIM(LTRIM(ISNULL(n.el.value('c_codigo_usu[1]', 'varchar(20)'),''))),
				@idtraspaso = RTRIM(LTRIM(ISNULL(n.el.value('n_idtraspaso[1]', 'int'),0)))
		FROM @xml.nodes('/') n(el);

			/*VALIDAMOS QUE EXISTA los registros */
		IF NOT EXISTS
		(
			SELECT *
			FROM dbo.t_pallet_traspaso_app_det det (NOLOCK) 
			INNER JOIN dbo.t_pallet_traspaso_app tra ( NOLOCK) ON tra.n_idfolio_pta = det.n_idfolio_pta 
			WHERE tra.c_Estatus_pta = 'C'
			AND det.n_idfolio_pta = @idtraspaso
			AND tra.c_codigo_usu = @ls_usuario
			AND tra.c_AlmacenQueEnvia_pta = @ls_empaque
		)
		BEGIN
			SET @as_success = 0;
			SET @as_message = 'El traspaso ['+CONVERT(varchar(10),@idtraspaso)+'] ya fue confirmado o ya no existe'
			RETURN;
		END;

		BEGIN TRAN
		/*actualizar registros con almacen 99*/
		IF OBJECT_ID('TempDB..#traspasotemp') IS NOT NULL
			DROP TABLE #traspasotemp

		SELECT	bAplicado = 0, * 
		  INTO	#traspasotemp
		  FROM	dbo.t_pallet_traspaso_app_det Det (NoLock)
		 WHERE	n_idfolio_pta = @idtraspaso

		DECLARE	@c_IdPallet_ptad	VARCHAR(100),
				@bEncuentra			BIT = 0

		SELECT TOP 1 @c_IdPallet_ptad = c_IdPallet_ptad
		  FROM #traspasotemp
		 WHERE bAplicado = 0

		WHILE @@ROWCOUNT > 0
		BEGIN
			
			SET @bEncuentra = 0

			IF LEN(@c_IdPallet_ptad) = 10 
			BEGIN
				IF EXISTS (SELECT 1 FROM dbo.t_paletemporal (NoLock) WHERE c_codigo_pte = @c_IdPallet_ptad AND c_codigo_emp = @ls_empaque AND c_codigo_tem = @ls_tem)
					BEGIN
						UPDATE dbo.t_paletemporal SET c_codigo_emp = '99' WHERE c_codigo_pte = @c_IdPallet_ptad AND c_codigo_emp = @ls_empaque AND c_codigo_tem = @ls_tem
						SET @bEncuentra = 1
					END;
				ELSE
					IF EXISTS (SELECT 1 FROM dbo.t_palet (NoLock) WHERE c_codigo_pal = @c_IdPallet_ptad AND c_codigo_emp = @ls_empaque AND c_codigo_tem = @ls_tem)
						BEGIN
							UPDATE dbo.t_palet SET c_codigo_emp = '99' WHERE c_codigo_pal = @c_IdPallet_ptad AND c_codigo_emp = @ls_empaque AND c_codigo_tem = @ls_tem
							SET @bEncuentra = 1
						END;
					ELSE
						BEGIN	
							SET @as_success = 0;
							SET @as_message = 'El pallet ['+@c_IdPallet_ptad+'] no se encontro, favor de revisar.'
							ROLLBACK TRAN
							RETURN
						END; 
			END; 

			IF LEN(@c_IdPallet_ptad) = 9
				BEGIN
					UPDATE dbo.t_recepciondet SET c_codigo_pem  = '99' WHERE c_codigo_rec+c_secuencia_red =  @c_IdPallet_ptad AND c_codigo_pem = @ls_empaque AND c_codigo_tem = @ls_tem
					SET @bEncuentra = 1
				END

			IF LEN(@c_IdPallet_ptad) = 6
				BEGIN
					UPDATE dbo.t_recepciondet SET c_codigo_pem  = '99' WHERE c_codexterno_rec =  @c_IdPallet_ptad AND c_codigo_pem = @ls_empaque AND c_codigo_tem = @ls_tem
					SET @bEncuentra = 1
				END

			IF @bEncuentra = 0
				BEGIN	
					SET @as_success = 0;
					SET @as_message = 'El pallet ['+@c_IdPallet_ptad+'] no se encontro, favor de revisar.'
					ROLLBACK TRAN
					RETURN
				END
			ELSE	
				BEGIN
					UPDATE #traspasotemp SET bAplicado = 1 WHERE c_IdPallet_ptad = @c_IdPallet_ptad
					SELECT TOP 1 @c_IdPallet_ptad = c_IdPallet_ptad
					  FROM #traspasotemp
					 WHERE bAplicado = 0
				END
		END

		UPDATE dbo.t_pallet_traspaso_app SET c_Estatus_pta = 'G', c_usumod_pta = @ls_usuario, d_modifi_pta = GETDATE() where n_idfolio_pta = @idtraspaso
		COMMIT TRAN
		SET @as_success = 1;
		SET @as_message = 'Registros transferidos correctamente.'
		
    END TRY
    BEGIN CATCH
        SET @as_success = 0;
        SET @as_message = ERROR_MESSAGE();
		IF @@TRANCOUNT > 0
			ROLLBACK TRAN;
    END CATCH;
END;

IF @as_operation = 25 /* recepciones de transferencias  */
BEGIN
	BEGIN TRY
		/*SACAMOS LOS DATOS del sorteo DEL JSON*/
		DECLARE @ls_nombre VARCHAR(300) = ''
		SELECT @ls_empaque = RTRIM(LTRIM(ISNULL(n.el.value('c_codigo_pem[1]', 'varchar(2)'),''))),
				@ls_empaque2 = RTRIM(LTRIM(ISNULL(n.el.value('c_codigo_pem2[1]', 'varchar(2)'),''))),
				@ls_tem = RTRIM(LTRIM(ISNULL(n.el.value('c_codigo_tem[1]', 'varchar(2)'),''))),
				@ls_qr = RTRIM(LTRIM(ISNULL(n.el.value('c_codigo[1]', 'varchar(22)'),''))),
				@ls_usuario = RTRIM(LTRIM(ISNULL(n.el.value('c_codigo_usu[1]', 'varchar(20)'),''))),
				@idtraspaso = RTRIM(LTRIM(ISNULL(n.el.value('n_idtraspaso[1]', 'int'),0)))
		FROM @xml.nodes('/') n(el);

		IF (@ls_qr = '' OR LEN(@ls_qr) = 0) 
		BEGIN
			SET @as_success = 0;
			SET @as_message = 'El Campo QR no pueden quedar vacios, favor de revisar';
			RETURN;
		END

		IF (@ls_empaque = '' OR @ls_empaque2 = '') 
		BEGIN
			SET @as_success = 0;
			SET @as_message = 'El punto de empaque de origen o destino no pueden quedar vacios, favor de revisar';
			RETURN;
		END

		IF NOT EXISTS /*validar punto de empaque origen */
		(
			SELECT c_codigo_pem
			FROM dbo.t_puntoempaque (NOLOCK) 
			WHERE c_codigo_pem = @ls_empaque
			AND c_activo_pem = '1'
		)
		BEGIN
			SET @as_success = 0;
			SET @as_message = 'El punto de empaque de origen no es valido o no existe, favor de revisar';
			RETURN;
		END;

		IF NOT EXISTS /*validar punto de empaque destino */
		(
			SELECT c_codigo_pem
			FROM dbo.t_puntoempaque (NOLOCK) 
			WHERE c_codigo_pem = @ls_empaque2
			AND c_activo_pem = '1'
		)
		BEGIN
			SET @as_success = 0;
			SET @as_message = 'El punto de empaque destino no es valido o no existe, favor de revisar';
			RETURN;
		END;
		SELECT @ls_nombre = v_nombre_pem ,@ls_area = c_areadefault_pem FROM dbo.t_puntoempaque (NOLOCK) WHERE c_codigo_pem = @ls_empaque2

		IF LEN(@ls_qr) = 10 /*Validar pallet temporal y real  ***********************************************************************************************************************/
			BEGIN	
				IF NOT EXISTS(SELECT c_codigo_pte FROM dbo.t_paletemporal (NOLOCK) WHERE c_codigo_pte = @ls_qr ) 
						AND NOT EXISTS(SELECT c_codigo_pal FROM dbo.t_palet (NOLOCK) WHERE c_codigo_pal = @ls_qr )
				BEGIN 
					SET @as_success = 0;
					SET @as_message = 'El código de pallet '+@ls_qr +' no existe, Favor de revisar.';
					RETURN;
				END
			
				IF NOT EXISTS(SELECT c_IdPallet_ptad FROM dbo.t_pallet_traspaso_app_det det (NOLOCK) 
								INNER JOIN dbo.t_pallet_traspaso_app tra (NOLOCK) ON tra.n_idfolio_pta = det.n_idfolio_pta
								WHERE c_IdPallet_ptad = @ls_qr
								AND det.n_idfolio_pta = @idtraspaso
								AND ISNULL(det.c_traspasado_ptad,'0') = '0'
								AND (tra.c_Estatus_pta = 'E' OR tra.c_Estatus_pta = 'P'  ))
				BEGIN
					SELECT @ls_nombre =  CONVERT(VARCHAR(10),det.n_idfolio_pta) FROM dbo.t_pallet_traspaso_app_det det (NOLOCK)
					INNER JOIN dbo.t_pallet_traspaso_app tra (NOLOCK) ON tra.n_idfolio_pta = det.n_idfolio_pta
					WHERE c_IdPallet_ptad = @ls_qr AND (tra.c_Estatus_pta = 'E' OR tra.c_Estatus_pta = 'P'  )

					IF (@ls_nombre = '')
						BEGIN	
							SET @as_message = 'El código de pallet '+@ls_qr +' no pertenece a una trasferencias, Favor de revisar.';
						END
					ELSE
						BEGIN 
							SET @as_message = 'El código de pallet '+@ls_qr +' pertenece a la remisión'+@ls_nombre+', se esta resibiendo la '+@idtraspaso+', Favor de revisar.';
						END 
					SET @as_success = 0;
					RETURN;	
				END

				BEGIN TRAN
					UPDATE dbo.t_pallet_traspaso_app_det SET c_traspasado_ptad = '1' WHERE	c_IdPallet_ptad = @ls_qr AND n_idfolio_pta = @idtraspaso

					IF EXISTS(SELECT c_codigo_pte FROM dbo.t_paletemporal (NOLOCK) WHERE c_codigo_pte = @ls_qr ) /*pallet temporal APP*/
						UPDATE dbo.t_paletemporal 
						SET c_codigo_emp = @ls_empaque2 ,
							c_codigo_are = @ls_area, 
							c_codigo_niv='' , 
							c_codigo_pos='' ,
							c_columna_col='' 
						WHERE c_codigo_pte = @ls_qr
						/*validar si es consolidado*/
						IF EXISTS(SELECT c_codigo_ptc FROM dbo.t_paletemporal_consolidado (NOLOCK) WHERE c_codigo_ptc = @ls_qr)
							UPDATE dbo.t_paletemporal 
							SET  c_codigo_emp = @ls_empaque2 ,
							c_codigo_are = @ls_area, 
							c_codigo_niv='' , 
							c_codigo_pos='' ,
							c_columna_col='' 
							WHERE c_codigo_pte IN (SELECT c_codigo_pte FROM dbo.t_paletemporal_consolidado (NOLOCK) WHERE c_codigo_ptc = @ls_qr) OR  t_paletemporal.c_codigo_pte = @ls_qr
					ELSE IF EXISTS(SELECT c_codigo_pal FROM dbo.t_palet (NOLOCK) WHERE c_codigo_pal = @ls_qr )/*Pallet final en eyeplus*/
						UPDATE dbo.t_palet 
						SET c_codigo_emp = @ls_empaque2,
							c_codigo_are = @ls_area, 
							c_codigo_niv='' , 
							c_codigo_pos='' ,
							c_columna_col='' 
						WHERE c_codigo_pal = @ls_qr
					
					UPDATE dbo.t_pallet_traspaso_app SET c_Estatus_pta = 'P' where n_idfolio_pta = @idtraspaso

					SET @as_success = 1;
					SET @as_message = 'El pallet '+@ls_qr +' se traspaso al almacén '+@ls_nombre+' con existo.';
				COMMIT TRAN
			END	
		IF LEN(@ls_qr) = 9 /*Validar Recepcion secuencia ***********************************************************************************************************************/
			BEGIN
				IF NOT EXISTS(SELECT c_codigo_rec+c_secuencia_red FROM dbo.t_recepciondet (NOLOCK) WHERE c_codigo_rec+c_secuencia_red = @ls_qr ) 	
				BEGIN 
					SET @as_success = 0;
					SET @as_message = 'El código de Recepción '+@ls_qr +' no existe, Favor de revisar.';
					RETURN;
				END
				IF NOT EXISTS(SELECT c_IdPallet_ptad FROM dbo.t_pallet_traspaso_app_det det (NOLOCK) 
								INNER JOIN dbo.t_pallet_traspaso_app tra (NOLOCK) ON tra.n_idfolio_pta = det.n_idfolio_pta
								WHERE c_IdPallet_ptad = @ls_qr
								AND det.n_idfolio_pta = @idtraspaso
								AND ISNULL(det.c_traspasado_ptad,'0') = '0'
								AND (tra.c_Estatus_pta = 'E' OR tra.c_Estatus_pta = 'P'  ))
				BEGIN
					SELECT @ls_nombre =  CONVERT(VARCHAR(10),det.n_idfolio_pta) FROM dbo.t_pallet_traspaso_app_det det (NOLOCK)
						INNER JOIN dbo.t_pallet_traspaso_app tra (NOLOCK) ON tra.n_idfolio_pta = det.n_idfolio_pta
						WHERE c_IdPallet_ptad = @ls_qr AND (tra.c_Estatus_pta = 'E' OR tra.c_Estatus_pta = 'P'  )

					IF (@ls_nombre = '')
						BEGIN	
							SET @as_message = 'El código de Recepción '+@ls_qr +' no pertenece a una trasferencias, Favor de revisar.';
						END
					ELSE
						BEGIN 
							SET @as_message = 'El código de Recepción '+@ls_qr +' pertenece a la remisión'+@ls_nombre+', se esta resibiendo la '+@idtraspaso+', Favor de revisar.';
						END 
					SET @as_success = 0;
					RETURN;			   
				END
				BEGIN TRAN
					UPDATE dbo.t_pallet_traspaso_app_det SET c_traspasado_ptad = '1' WHERE	c_IdPallet_ptad = @ls_qr AND n_idfolio_pta = @idtraspaso

					UPDATE dbo.t_recepciondet 
					SET c_codigo_pem = @ls_empaque2
					WHERE c_codigo_rec+c_secuencia_red = @ls_qr

					UPDATE dbo.t_pallet_traspaso_app SET c_Estatus_pta = 'P' where n_idfolio_pta = @idtraspaso

					SET @as_success = 1;
					SET @as_message = 'El pallet '+@ls_qr +' se traspaso al almacén '+@ls_nombre+' con existo.';
				COMMIT TRAN
			END
		IF LEN(@ls_qr) = 6 /*Validar TagID ***********************************************************************************************************************/
		BEGIN 
			IF NOT EXISTS
				(
					SELECT c_codexterno_rec
					FROM dbo.t_recepciondet (NOLOCK) 
					WHERE c_codexterno_rec = @ls_qr
					AND c_codigo_tem = @ls_tem
					AND c_activo_red = '1'
				)
				BEGIN
					SET @as_success = 0;
					SET @as_message = 'El Tag ID no existe o no esta activo, favor de revisar ';
					RETURN;
				END
			IF NOT EXISTS(SELECT c_IdPallet_ptad FROM dbo.t_pallet_traspaso_app_det det (NOLOCK) 
							INNER JOIN dbo.t_pallet_traspaso_app tra (NOLOCK) ON tra.n_idfolio_pta = det.n_idfolio_pta
							WHERE c_IdPallet_ptad = @ls_qr
							AND det.n_idfolio_pta = @idtraspaso
							AND ISNULL(det.c_traspasado_ptad,'0') = '0'
							AND (tra.c_Estatus_pta = 'E' OR tra.c_Estatus_pta = 'P'  ))
			BEGIN
				SELECT @ls_nombre =  CONVERT(VARCHAR(10),det.n_idfolio_pta) FROM dbo.t_pallet_traspaso_app_det det (NOLOCK)
					INNER JOIN dbo.t_pallet_traspaso_app tra (NOLOCK) ON tra.n_idfolio_pta = det.n_idfolio_pta
					WHERE c_IdPallet_ptad = @ls_qr AND (tra.c_Estatus_pta = 'E' OR tra.c_Estatus_pta = 'P'  )

				IF (@ls_nombre = '')
					BEGIN	
						SET @as_message = 'El código de TAGID '+@ls_qr +' no pertenece a una trasferencias, Favor de revisar.';
					END
				ELSE
					BEGIN 
						SET @as_message = 'El código de TAGID '+@ls_qr +' pertenece a la remisión'+@ls_nombre+', se esta resibiendo la '+@idtraspaso+', Favor de revisar.';
					END 
				SET @as_success = 0;
				RETURN;			   
			END
			BEGIN TRAN
				UPDATE dbo.t_pallet_traspaso_app_det SET c_traspasado_ptad = '1' WHERE	c_IdPallet_ptad = @ls_qr AND n_idfolio_pta = @idtraspaso

				UPDATE dbo.t_recepciondet 
				SET c_codigo_pem = @ls_empaque2
				WHERE c_codexterno_rec = @ls_qr

				UPDATE dbo.t_pallet_traspaso_app SET c_Estatus_pta = 'P' where n_idfolio_pta = @idtraspaso

				SET @as_success = 1;
				SET @as_message = 'El TAGID '+@ls_qr +' se traspaso al almacén '+@ls_nombre+' con existo.';
			COMMIT TRAN
		END 
	END TRY	
	
    BEGIN CATCH
        SET @as_success = 0;
        SET @as_message = ERROR_MESSAGE();
		IF @@TRANCOUNT > 0
			ROLLBACK TRAN;
    END CATCH;
END 

IF @as_operation = 26 /*Finalizar recepcion */
BEGIN
    BEGIN TRY
		/*SACAMOS LOS DATOS del sorteo DEL JSON*/

		SELECT TOP 1 @idtraspaso = RTRIM(LTRIM(ISNULL(n.el.value('n_idtraspaso[1]', 'INT'),'')))
		FROM @xml.nodes('/') n(el);

			/*VALIDAMOS QUE EXISTA los registros */
		IF NOT EXISTS
		(
			SELECT n_idfolio_pta FROM dbo.t_pallet_traspaso_app (NOLOCK) WHERE n_idfolio_pta = @idtraspaso
		)
		BEGIN
			SET @as_success = 0;
			SET @as_message = 'La transferencia '+CONVERT(varchar(10),@idtraspaso) + 'No existe, favor de revisar.'
			RETURN;
		END;

		IF EXISTS (SELECT n_idfolio_pta FROM dbo.t_pallet_traspaso_app_det (NOLOCK) WHERE n_idfolio_pta = @idtraspaso AND ISNULL(c_traspasado_ptad,'0') = '0') 
			BEGIN 
				SET @as_success = 1;
				SET @as_message = 'Transferencia ['+CONVERT(varchar(10),@idtraspaso) +'] recibida de manera parcial.'
				RETURN;
			END 
		ELSE
			BEGIN
				BEGIN TRAN
					UPDATE dbo.t_pallet_traspaso_app SET c_Estatus_pta = 'T' WHERE n_idfolio_pta = @idtraspaso
				COMMIT TRAN
				SET @as_success = 1;
				SET @as_message = 'La remisión fue recibida de manera exitosa.'
				RETURN;
			END 
    END TRY
    BEGIN CATCH
        SET @as_success = 0;
        SET @as_message = ERROR_MESSAGE();
		IF @@TRANCOUNT > 0
			SELECT @idtraspaso = ISNULL(MAX(n_idfolio_pta),0) FROM dbo.t_pallet_traspaso_app 
			DBCC CHECKIDENT(t_pallet_traspaso_app, RESEED , @idtraspaso)
			ROLLBACK TRAN;
    END CATCH;
END;