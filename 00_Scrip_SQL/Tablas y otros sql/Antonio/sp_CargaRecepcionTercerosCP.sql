/*|AGS|*/
IF EXISTS
(
    SELECT *
    FROM dbo.sysobjects
    WHERE id = OBJECT_ID(N'[dbo].[sp_CargaRecepcionTercerosCP]')
)
    DROP PROCEDURE sp_CargaRecepcionTercerosCP;
GO

CREATE PROCEDURE dbo.sp_CargaRecepcionTercerosCP
AS
BEGIN
	
	-- 
	--- Antes de correr este SP es necesario que se haya alimentado
	--- la tabla t_recepcion_terceros_cpcon los siguientes campos:
	--- GrowerName
	--- Cosecha, Cliente, InventarioVivo, Metodo, Region,
	--- TagId, Color, BlockId, Grado, Condicion
	--

	SET NOCOUNT ON;

	BEGIN TRY

		BEGIN TRAN

			DECLARE @idDuenio			CHAR(4),
					@sNombre			VARCHAR(50) = '',
					@cRegion			CHAR(3),
					@iContador			SmallInt = 1,
					@iRegistros			SmallInt = 0,
					@idTemporada		VARCHAR(2),
					@idVariedad			VARCHAR(2),
					@cBlockId			VARCHAR(20),
					@cidLote			CHAR(4),
					@idRecepcion		CHAR(6) = '',
					@idSecuencia		Char(3),
					@idJefeCuadrilla	Char(6),
					@cIdMesa			CHAR(4) = '',
					@cAnio				CHAR(2),
					@cIdSortingDetalle	CHAR(10),
					@iContadorPTem		SMALLINT,
					@iJuliana			SMALLINT,
					@dtInicioAnual		DATE,
					@sCorridaInicial	VARCHAR(5)

			--
			--- Dueños
			--
			Begin
				PRINT 'Importando Dueños y Huertos'

				IF OBJECT_ID('TempDB..#Duenios') IS NOT NULL
					DROP TABLE #Duenios

				SELECT	DISTINCT idDuenio = SUBSTRING(BlockId,3,2), Cliente, Region
				  INTO	#Duenios
				  FROM	dbo.t_recepcion_terceros_cp (NoLock)
				 WHERE	bAplicado = 0
				 ORDER	By 1

				SELECT	TOP 1 @idDuenio = '00' + idDuenio, @sNombre = Cliente, @cRegion = Region
				  FROM	#Duenios
				 WHERE	Cliente > @sNombre
				 ORDER	BY Cliente

				 While	@@RowCount > 0
				 BEGIN

					IF NOT EXISTS(SELECT 1 FROM t_Duenio (NoLock) WHERE c_codigo_dno = @idDuenio)
						INSERT INTO dbo.t_duenio (	c_codigo_dno,	v_nombre_dno,		c_codigo_usu,
													d_creacion_dno,	c_activo_dno,		v_pagara_dno,
													n_pormerm_dno,	n_preckgmerm_dno)
						VALUES (	@idDuenio,	UPPER(@sNombre),	'JRICO',
									GETDATE(),	'1',				'MOCTEZUMA',
									0,			0)

					IF NOT EXISTS(SELECT 1 FROM dbo.t_huerto (NoLock) WHERE c_codigo_hue = @idDuenio)
						INSERT INTO dbo.t_huerto (	c_codigo_hue,	v_nombre_hue,	c_codigo_dno,
													v_registro_hue,	c_codigo_est,	v_ciudad_est,
													c_codigo_usu,	d_creacion_hue,	c_activo_hue,
													c_calidad_hue,	c_estatus_hue,	b_enviado_FTP)
						VALUES (	@idDuenio,			UPPER(@sNombre), 	@idDuenio,
									UPPER(@sNombre),	26,					'SAN LUIS RIO COLORADO',
									'JRICO',			GETDATE(),			1,
									@cRegion,			'A',				0)
			    
					SELECT	TOP 1 @idDuenio = '00' + idDuenio, @sNombre = Cliente, @cRegion = Region
					  FROM	#Duenios
					 WHERE	Cliente > @sNombre
					 ORDER	BY Cliente

				 END
	
				DROP TABLE #Duenios

			END

			--
			--- Temporadas
			--
			BEGIN
				Print 'Temporadas'
	
				IF NOT EXISTS(Select 1 FROM dbo.t_temporada (NoLock) WHERE  c_codigo_tem = '00')
					INSERT into t_temporada (c_codigo_tem, v_nombre_tem, c_activo_tem, c_codigo_emp)
					VALUES ('00', '2020', 0, '00')
				ELSE
					UPDATE dbo.t_temporada SET c_codigo_tem = '00', v_nombre_tem = '2020', c_activo_tem = 0 WHERE c_codigo_tem = '00'

				IF NOT EXISTS(Select 1 FROM dbo.t_temporada (NoLock) WHERE  c_codigo_tem = '01')
					INSERT into t_temporada (c_codigo_tem, v_nombre_tem, c_activo_tem, c_codigo_emp)
					VALUES ('01', '2021', 0, '00')

				IF NOT EXISTS(Select 1 FROM dbo.t_temporada (NoLock) WHERE  c_codigo_tem = '02')
					INSERT into t_temporada (c_codigo_tem, v_nombre_tem, c_activo_tem, c_codigo_emp)
					VALUES ('02', '2022', 0, '00')

				IF NOT EXISTS(Select 1 FROM dbo.t_temporada (NoLock) WHERE  c_codigo_tem = '03')
					INSERT into t_temporada (c_codigo_tem, v_nombre_tem, c_activo_tem, c_codigo_emp)
					VALUES ('03', '2023', 1, '00')
				ELSE
					UPDATE dbo.t_temporada SET v_nombre_tem = '2023', c_activo_tem = 1 WHERE c_codigo_tem = '03'
			END
			--
			--- Variedades
			--
			BEGIN	
				IF NOT EXISTS(SELECT 1 FROM dbo.t_variedad (NoLock) WHERE c_codigo_var = '01')
					INSERT INTO t_variedad (c_codigo_var, v_nombre_var, c_codigo_usu, d_creacion_var, c_activo_var)
					SELECT '01', 'CONVENCIONAL', 'jrico', GETDATE(), '1'

				IF NOT EXISTS(SELECT 1 FROM dbo.t_variedad (NoLock) WHERE c_codigo_var = '02')
					INSERT INTO t_variedad (c_codigo_var, v_nombre_var, c_codigo_usu, d_creacion_var, c_activo_var)
					SELECT '02', 'ORGANICO', 'jrico', GETDATE(), '1'

			END

			--
			--- Lotes
			--
			BEGIN
				Print 'Lotes'

				UPDATE	Lot	SET c_codigo_tem = '03' 
				  FROM	t_lote Lot
				 WHERE	Lot.c_codigo_lot <= '0115'
				   AND	NOT EXISTS (SELECT 1 FROM t_lote Lo2 WHERE Lo2.c_codigo_tem = '03' AND Lo2.c_codigo_lot = Lot.c_codigo_lot)

				IF OBJECT_ID('TempDB..#Lotes') IS NOT NULL
					DROP TABLE #Lotes

				CREATE TABLE #Lotes (	Indice		Smallint Identity(1,1),
										idTemporada	Char(2),
										idVariedad	Char(2),
										BlockId		VarChar(20),
										Duenio		VarChar(4))

				INSERT INTO #Lotes (idTemporada, idVariedad, BlockId, Duenio)
				SELECT	DISTINCT 
						idTemporada	= '0' + Substring(BlockId, 2,1), 
						idVariedad	= CASE Metodo WHEN 'Con' THEN '01' ELSE '02' END,
						BlockId, 
						Duenio = '00' + SUBSTRING(BlockId, 3, 2)
				  FROM	dbo.t_recepcion_terceros_cp(NoLock) 
				 WHERE	bAplicado = 0
				   AND	BlockId NOT IN (SELECT ISNULL(c_codigoext_lot,'') FROM dbo.t_lote (NoLock))

				SET @iRegistros = @@ROWCOUNT
				SET @iContador = 1

				SELECT	TOP 1 @idTemporada = idTemporada, @idVariedad = idVariedad, @cBlockId = BlockId, @idDuenio = Duenio
				  FROM	#Lotes
				 ORDER	BY BlockId

				WHILE @@ROWCOUNT > 0
				BEGIN

					IF NOT EXISTS(SELECT 1 FROM dbo.t_lote (NoLock) WHERE v_nombre_lot = @cBlockId)
						BEGIN
            
							SELECT	@cidLote = RIGHT('0000' + CONVERT(VARCHAR(4), CONVERT(SMALLINT, MAX(c_codigo_lot)) + 1),4)
							  FROM	dbo.t_lote

							INSERT INTO dbo.t_lote (c_codigo_tem,	c_codigo_lot,	v_nombre_lot,
													c_tipo_lot,		c_codigo_cul,	c_codigo_eta,
													n_superf_lot,	c_codigo_var,	c_codigo_usu,
													d_creacion_lot,	c_activo_lot,	c_codigoext_lot,
													c_codigo_hue,	b_enviado_FTP)
							VALUES (@idTemporada, @cidLote, @cBlockId,
									'N', '01', '01',
									1, @idVariedad, 'jrico',
									GETDATE(), '1', @cBlockId,
									@idDuenio, 0)
						END

					PRINT 'Lote ' + @cidLote

					SELECT	TOP 1 @idTemporada = idTemporada, @idVariedad = idVariedad, @cBlockId = BlockId, @idDuenio = Duenio
					  FROM	#Lotes
					 WHERE	BlockId > @cBlockId
					 ORDER	BY BlockId

				END

				INSERT INTO dbo.t_lote (c_codigo_tem,	c_codigo_lot,	v_nombre_lot,
										c_tipo_lot,		c_codigo_cul,	c_codigo_eta,
										n_superf_lot,	c_codigo_var,	c_codigo_usu,
										d_creacion_lot,	c_activo_lot,	c_codigoext_lot,
										c_codigo_hue,	b_enviado_FTP)
				SELECT	'03',			c_codigo_lot,	v_nombre_lot,
						c_tipo_lot,		c_codigo_cul,	c_codigo_eta,
						n_superf_lot,	c_codigo_var,	c_codigo_usu,
						d_creacion_lot,	c_activo_lot,	c_codigoext_lot,
						c_codigo_hue,	b_enviado_FTP
				  FROM	dbo.t_lote (NoLock)
				 WHERE	c_codigo_tem < '03'
				   AND	c_codigo_lot NOT IN (SELECT c_codigo_lot FROM t_lote WHERE c_codigo_tem = '03')

				DROP TABLE #Lotes
			END

			--
			--- Recepción
			--
			BEGIN	
				Print 'Recepciones'

				IF OBJECT_ID('TempDB..#Recepciones') IS NOT NULL
					DROP TABLE #Recepciones
	
				SELECT	DISTINCT Temporada = '0' + SUBSTRING(BlockId,2,1), BlockId, bAplicado = 0
				  INTO	#Recepciones
				  FROM	dbo.t_recepcion_terceros_cp
				 WHERE	bAplicado = 0
				   AND	BlockId Not In (Select	Lot.v_nombre_lot 
										  From	t_recepcion Rec (NoLock)
										 Inner	Join t_lote Lot (NoLock) On Lot.c_codigo_Lot = Rec.c_codigo_lot)
				 ORDER	BY 1

				SELECT	TOP (1) @idTemporada = Temporada, @cBlockId = BlockId
				  FROM	#Recepciones
				 ORDER	BY  Temporada, BlockId

				WHILE @@ROWCOUNT > 0
				BEGIN

					If Not Exists ( Select 1 From dbo.t_recepcion (Nolock) WHERE c_codigo_lot = (SELECT Top 1 c_codigo_lot FROM dbo.t_lote (Nolock) WHERE c_codigoext_lot = @cBlockId))
						BEGIN	
							SELECT	@idRecepcion = RIGHT('000000' + CONVERT(VARCHAR(6), CONVERT(INT, MAX(c_codigo_rec)) + 1), 6)
							  FROM	dbo.t_recepcion

							If Len(@idRecepcion) = 0 Or @idRecepcion Is Null
								Set @idRecepcion = '000001'

							INSERT INTO dbo.t_recepcion (	c_codigo_rec,	c_codigo_tem,	d_fecha_rec,
															c_hora_rec,		
															c_ticketbas_rec,	c_codigo_ciu,	c_codigo_ope,	
															c_codigo_can,		v_recibio_rec,	c_codigo_usu,
															d_creacion_rec,		c_activo_rec,	c_codigo_lot)
							VALUES (	@idRecepcion, @idTemporada, GETDATE(),
										(SELECT REPLACE(CONVERT(VARCHAR(8), CONVERT(TIME, GETDATE())), ':', '')), 
										'',		'0001',		'0001',
										'0001',	'jrico',	'jrico',	
										GETDATE(),	'1',	(SELECT TOP 1 c_codigo_lot FROM dbo.t_lote (NOLOCK) WHERE c_codigoext_lot = @cBlockId))
						END
		
					UPDATE TOP (1) #Recepciones SET bAplicado = 1 WHERE Temporada = @idTemporada AND BlockId = @cBlockId

					SELECT	TOP 1 @idTemporada = Temporada, @cBlockId = BlockId
					  FROM	#Recepciones
					 WHERE	bAplicado = 0 
					 ORDER	BY  Temporada, BlockId
				END

				DROP TABLE #Recepciones

			END

			--
			--- Recepciones Detalle
			--
			BEGIN

				Print 'Detalle de Recepciones'

				IF OBJECT_ID('TempDB..#Recepciondetalle') IS NOT NULL
					DROP TABLE #Recepciondetalle

				CREATE TABLE #Recepciondetalle (Indice		Smallint Identity(1,1),
												Temporada	Char(2),
												Lote		Char(4),
												Duenio		Char(4),
												Libras		SmallInt,
												Cajas		TinyInt,
												Recepcion	Char(6),
												BlockId		VarChar(20),
												TagId		VarChar(10),
												Grado		VarChar(20),
												Color		VARCHAR(10),
												bExiste		BIT)

				INSERT INTO #Recepciondetalle (	Temporada,	Lote,	Duenio,
												Libras,		Cajas,	Recepcion,
												BlockId,	TagId,	Grado,
												Color,		bExiste)	
				SELECT	Temporada = '0' + SUBSTRING(BlockId,2,1), Lot.c_codigo_lot, c_codigo_hue = '00' + SUBSTRING(BlockId,3,2),  
						Qty, Cajas = CONVERT(INT, Qty / 22), rec.c_codigo_rec,
						BlockId, TagId, Inv.Grado,
						Inv.Color, bExiste = CASE WHEN Det.c_codexterno_rec = Inv.TagId THEN 1 ELSE 0 End
				  FROM	dbo.t_recepcion_terceros_cp Inv (NOLOCK)
				 INNER	JOIN dbo.t_lote Lot (NOLOCK) ON Lot.c_codigo_tem = '0' + SUBSTRING(BlockId,2,1)
													AND Lot.c_codigoext_lot = Inv.BlockId
				 INNER	JOIN dbo.t_recepcion Rec (NOLOCK) ON Rec.c_codigo_tem = '0' + SUBSTRING(BlockId,2,1)
														AND Rec.c_codigo_lot = Lot.c_codigo_lot
				  LEFT	JOIN dbo.t_recepcionDet Det (NoLock) ON Det.c_codigo_rec = Rec.c_codigo_rec
															AND Det.c_codexterno_rec = Inv.TagId
				 WHERE	bAplicado = 0
				 ORDER	BY 1, 6,7,8

				SET @iRegistros = @@RowCount 

				SELECT	TOP (1) @idJefeCuadrilla = c_codigo_jec
				  FROM	dbo.t_jefeCuadrilla (NOLOCK)
				 ORDER	BY c_codigo_jec
	
				WHILE @iContador <= @iRegistros
				BEGIN
	
					IF (SELECT bExiste FROM	#Recepciondetalle WHERE	Indice = @iContador) = 0
					BEGIN

						SET @idSecuencia = 0

						SELECT	@idSecuencia = RIGHT('000' + CONVERT(VARCHAR(10), CONVERT(SMALLINT, MAX(c_secuencia_red)) + 1), 3)
						  FROM	dbo.t_RecepcionDet Rec (NOLOCK)
						 INNER	JOIN #Recepciondetalle Det (NOLOCK) ON Det.Temporada = Rec.c_codigo_tem COLLATE Modern_Spanish_CI_AS
																	AND Det.Recepcion = Rec.c_codigo_rec COLLATE Modern_Spanish_CI_AS
						 WHERE	Det.Indice = @iContador

						IF @idSecuencia IS NULL OR @idSecuencia = 0
							SET @idSecuencia = '001'

						INSERT	INTO dbo.t_RecepcionDet (	c_codigo_rec,		d_fecha_rec,			c_codigo_tem,
															c_secuencia_red,	c_idestiba_red,			c_codigo_hue,
															c_codigo_dno,		c_codigo_lot,			c_codigo_cul,
															c_codigo_jec,		n_cajascorte_red,		n_kilos_red,
															v_nota_red,			c_codigosec_ocd,		c_codigo_usu,		
															d_creacion_red,		c_activo_red,			c_codexterno_rec)
						SELECT	Recepcion,			GETDATE(),					Temporada,
								@idSecuencia,		Recepcion + @idSecuencia,	Duenio,
								Duenio,				Lote,						'01',
								@idJefeCuadrilla,	Cajas,						Libras,
								'',					'',							'jrico',
								GETDATE(),			'1',						TagId
						  FROM	#Recepciondetalle
						 WHERE	Indice = @iContador
					END 
					
					SET @iContador = @iContador + 1

				END

			END

			--
			--- Corridas
			--
			PRINT 'Corridas'

			IF OBJECT_ID('TempDB..#Corridas') IS NOT NULL
				DROP TABLE #Corridas

			CREATE TABLE #Corridas (Indice		SMALLINT IDENTITY(1,1),
									Temporada	CHAR(2),
									Lote		CHAR(4),
									BlockId		VARCHAR(20),
									Pallets		SMALLINT,
									Cajas		INT,
									Libras		INT)

			INSERT	INTO #Corridas (Temporada,	Lote,	BlockId,
									Pallets,	Cajas,	Libras)
			SELECT	Temporada, Lote, BlockId, Pallets = SUM(1), TotCajas = SUM(Cajas), TotLibras = SUM(Libras)
			  FROM	#Recepciondetalle 
			 GROUP	BY Temporada, Lote, BlockId

			SET @iRegistros = @@RowCount 

			SET @iContador = 1

			SELECT	TOP (1) @cIdMesa = c_codigo_are
			  FROM	dbo.t_areafisica (NOLOCK)
			 WHERE	c_tipo_are = '05'
			 ORDER	BY c_codigo_are

			SET @cAnio = RIGHT(CONVERT(VARCHAR(4), YEAR(GETDATE())), 2)

			IF OBJECT_ID('TempDB..#paletemporal') IS NOT NULL
				DROP TABLE  #paletemporal
	
			CREATE TABLE #paletemporal (Indice				SMALLINT IDENTITY(1,1),
										c_codigo_sma		CHAR(15),
										c_codigo_tem		VARCHAR(2),
										d_totcaja_pte		NUMERIC(18, 0),
										d_totkilos_pte		DECIMAL(18, 3),
										c_codigo_cal		CHAR(10),
										c_codigo_gma		CHAR(4),
										c_pitted_pte		CHAR(1),
										TagId				VARCHAR(10) COLLATE Modern_Spanish_CI_AS);

			If Object_Id('TempDB..#SortingDet') Is Not Null
				Drop Table  #SortingDet
	
			Create Table #SortingDet (	Indice				SMALLINT Identity(1,1),
										c_folio_sma			VARCHAR(15),
										c_codigo_are		CHAR(4),
										c_codigo_rec		VARCHAR(10),
										c_codigo_pal		VARCHAR(10),
										c_concecutivo_smd	VARCHAR(3),	
										c_codigo_tem		VARCHAR(2),		
										c_codigo_lot		VARCHAR(4),		
										n_kilos_smd			DECIMAL(9,3),		
										n_cajas_smd			SMALLINT)		
	
			While @iContador <= @iRegistros
			Begin

				Select	@cBlockId = BlockId
				  From	#Corridas
				 Where	Indice = @iContador

				SET	@dtInicioAnual		= CONVERT(DATE, CONVERT(VARCHAR(4), YEAR(GETDATE())) + '0101')
				SET @iJuliana			= DATEDIFF(dd, @dtInicioAnual, GETDATE()) + 1
				SET @sCorridaInicial	= LEFT(@cBlockId,2) + RIGHT('000' + CONVERT(VARCHAR(3), @iJuliana),3)	

				IF Not Exists (Select 1 From t_sortingmaduracion (NoLock) Where  c_usumod_sma = @cBlockId AND LEFT(c_folio_sma,5) = @sCorridaInicial)
					BEGIN

						INSERT INTO dbo.t_sortingmaduracion(c_folio_sma,			
															c_codigo_tem,		n_totalkilos_sma,	n_totalcajas_sma,		
															n_totalpalets_sma,	c_finvaciado_sma,	c_tipo_sma,				
															c_codigo_usu,		d_creacion_sma,		c_activo_sma,
															c_usumod_sma,		c_tipocorrida_sma,	c_codigo_emp,
															idrazon)
						Select	@sCorridaInicial + @cIdMesa + Lote + Temporada,
								Temporada,	Libras,		Cajas,
								Pallets,	'S',		'E',
								'jrico',	GETDATE(),	'1',
								BlockId,	'C',		'00',
								7
						  From	#Corridas 
						 Where	Indice = @iContador
					END

				IF Not Exists (	Select	1 
								  From	t_sortingmaduracionDet (NoLock) 
								 Where  c_codigo_pal = (SELECT	Det.TagId Collate Modern_Spanish_CI_AS
														  From	#Corridas Cor			
														 INNER	JOIN #RecepcionDetalle Det ON Det.Lote = Cor.Lote
														 Where	Cor.Indice = @iContador))
					BEGIN
						INSERT INTO #SortingDet (	c_folio_sma,		
													c_codigo_are,		c_codigo_rec,		c_codigo_pal,		
													c_concecutivo_smd,	c_codigo_tem,		c_codigo_lot,		
													n_kilos_smd,		n_cajas_smd)
						SELECT	@sCorridaInicial + @cIdMesa + Det.Lote + Det.Temporada,
								@cIdMesa,		Det.Recepcion,	Det.TagId,
								'',				Det.Temporada,	Cor.Lote,
								Det.Libras,		Det.Cajas
						  From	#Corridas Cor
						 INNER	JOIN #RecepcionDetalle Det ON Det.Lote = Cor.Lote
						 Where	Cor.Indice = @iContador

						UPDATE #SortingDet SET c_concecutivo_smd = RIGHT('000' + CONVERT(VARCHAR(3), indice),3)

						Select	Top(1) @iContadorPTem = Indice
						  From	#SortingDet
						 Order	By Indice

						While @@ROWCOUNT > 0
						BEGIN

							SELECT	@cIdSortingDetalle = @cAnio + RIGHT('00000000' + CONVERT(VARCHAR(8), CONVERT(INT, ISNULL(MAX(RIGHT(c_codigo_pal,8)),0)) + 1), 8)
							  FROM	dbo.t_sortingmaduraciondet
							 WHERE	LEFT(c_codigo_pal, 2) = @cAnio

							SELECT	@idSecuencia = RIGHT('000' + CONVERT(VARCHAR(10), CONVERT(SMALLINT, MAX(ISNULL(c_concecutivo_smd,'0'))) + 1),3)
							  FROM	dbo.t_sortingmaduraciondet
							 WHERE	c_folio_sma = (	SELECT	MAX(c_folio_sma) 
													  FROM	dbo.t_sortingmaduracion 
													 Where	c_codigo_tem Collate Modern_Spanish_CI_AS = 
													(SELECT Temporada FROM #Corridas WHERE Indice = @iContador))

							IF @idSecuencia IS NULL
								SET @idSecuencia = '001'

							INSERT INTO dbo.t_sortingmaduraciondet (c_folio_sma,		c_codigo_are,		c_codigo_rec,		
																	c_codigo_pal,		c_concecutivo_smd,	c_codigo_tem,		
																	c_codigo_lot,		n_kilos_smd,		n_cajas_smd,	
																	c_codigocaja_tcj,	c_codigotarima_tcj,	c_finvaciado_smd,	
																	c_codigo_usu,		d_creacion_smd,		c_activo_smd,		
																	c_codigo_emp)
							SELECT	c_folio_sma,		c_codigo_are,	c_codigo_rec,		
									@cIdSortingDetalle,	@idSecuencia,	c_codigo_tem,		
									c_codigo_lot,		n_kilos_smd,	n_cajas_smd,		
									'0001',				'0001',			'S',			
									'jrico',			GETDATE(),		'1',			
									'00'
							  From	#SortingDet
							 WHERE	indice = @iContadorPTem

							Select	TOP(1) @iContadorPTem = Indice
							  From	#SortingDet
							 Where	Indice > @iContadorPTem
							 Order	By Indice

						END

						Delete from #Paletemporal

						INSERT INTO #paletemporal (	c_codigo_sma,	c_codigo_tem,	d_totcaja_pte,
													d_totkilos_pte,	c_codigo_cal,	c_codigo_gma,	
													c_pitted_pte,	TagId)
						SELECT	DISTINCT Sor.c_folio_sma,
								Cor.Temporada,
								IIF(Det.Cajas > 0, Det.Cajas, 1),
								Det.Libras,
								Det.Grado,
								'0001',
								CASE WHEN Det.Color = 'Whole' THEN 'N' ELSE 'S' END,
								Det.TagId
						  From	#Corridas Cor
						 INNER	JOIN #RecepcionDetalle Det ON Det.Lote = Cor.Lote
						 INNER	JOIN #SortingDet Sor ON Sor.c_codigo_lot = Cor.Lote
						 Where	Cor.Indice = @iContador

						TRUNCATE TABLE #SortingDet

						Select	TOP(1) @iContadorPTem = Indice
						  From	#paletemporal
						 Order	By Indice

						While @@ROWCOUNT > 0
						BEGIN
                        
							SELECT	@cAnio = LEFT(c_codigo_sma,2)
                             From	#paletemporal
							 Where	Indice = @iContadorPTem

							SELECT	@cIdSortingDetalle = @cAnio + RIGHT('00000000' + CONVERT(VARCHAR(8), CONVERT(INT, ISNULL(MAX(RIGHT(c_codigo_pte,8)),0)) + 1), 8)
							  FROM	dbo.t_paletemporal
							 WHERE	LEFT(c_codigo_pte, 2) = @cAnio

							INSERT INTO dbo.t_paletemporal (c_codigo_pte,		c_codigo_sma,		c_codqrtemp_pte,
															c_codigo_tem,		d_totcaja_pte,		d_totkilos_pte,
															d_asignacionqr_pte,	c_codigo_are,		c_ubicacion_pte,	
															c_codigo_cal,		c_codigo_gma,		c_finalizado_pte,	
															c_codigo_usu,		d_creacion_dso,		c_activo_dso,
															c_codigo_emp,		d_fecha_pte,		c_codigofinal_pal,
															c_pitted_pte)
							SELECT	@cIdSortingDetalle,
									Tem.c_codigo_sma,
									Tem.TagId,
									Tem.c_codigo_tem,
									Tem.d_totcaja_pte,
									Tem.d_totkilos_pte,
									GETDATE(),		
									@cIdMesa,		
									'',				
									CASE Tem.c_codigo_cal	WHEN 'Premium'	THEN '0001'
															WHEN 'Large'	THEN '0001'
															WHEN 'Jumbo'	THEN '0001'
															WHEN 'SDry'		THEN '0005'
															WHEN 'PDry'		THEN '0005'
															WHEN 'SGrind'	THEN '0006'
															WHEN 'PGrind'	THEN '0006' 
															ELSE '' END,
									Tem.c_codigo_gma,
									'N',			
									'jrico',		
									GETDATE(),		
									'1',			
									'00',			
									GETDATE(),		
									'',				
									Tem.c_pitted_pte
							  From	#paletemporal Tem
							 Where	Indice = @iContadorPTem

							UPDATE dbo.t_recepcion_terceros_cp SET bAplicado = 1 WHERE TagId = (SELECT TagId COLLATE Modern_Spanish_CI_AS FROM #paletemporal Where	Indice = @iContadorPTem)

							Select	Top (1) @iContadorPTem = Indice
							  From	#paletemporal
							 Where	Indice > @iContadorPTem
							 Order	By Indice

						END
 
					END
				
				SET @iContador = @iContador + 1
			END

		COMMIT TRAN

	END TRY

	BEGIN CATCH

		IF @@TRANCOUNT > 0	
			ROLLBACK TRAN

		SELECT Mensaje = ERROR_MESSAGE()
	END CATCH
    
END
GO