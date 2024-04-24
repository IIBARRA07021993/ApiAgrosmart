/*|AGS|*/
IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id = OBJECT_ID(N'[dbo].[fn_GetCodigoMaxPallet]') AND type IN ( N'FN', N'IF', N'TF', N'FS', N'FT' ))
DROP FUNCTION dbo.fn_GetCodigoMaxPallet

/*|AGS|*/
CREATE FUNCTION fn_GetCodigoMaxPallet
(	
	@idTemporada		CHAR(2),
	@idEmpaque			CHAR(2),
	@idUsuario			VARCHAR(20),
	@id_producto  		CHAR(4)
)
RETURNS VARCHAR(10)
AS
	BEGIN
	/*Generar nuevo codigo de pallet con los los campos del punto de empaque*/
		DECLARE @ls_folini VARCHAR(10) = '',
				@ls_folfin VARCHAR(10) = '',
				@ls_folinime VARCHAR(10) = '',
				@ls_folfinme VARCHAR(10) = '',
				@ll_LongPal NUMERIC = 0,
				@ll_longpalme NUMERIC = 0 ,
				@ls_folxmer VARCHAR(50) = '',
				@ls_par194 VARCHAR(50) = '',
				@ls_pal VARCHAR(10) = '',  
				@ls_palsc VARCHAR(10) = '',
				@ls_new VARCHAR(10) = '',
				@ls_mer	CHAR(1) = '',
				@ls_prefpal VARCHAR(50) = ''

		/*valores de los parametros*/
		SELECT  @ls_folxmer = RTRIM(LTRIM(ISNULL(par085.v_valor_par,'')))FROM t_parametro par085 (NOLOCK)
		WHERE par085.c_codigo_par = '085'

		SELECT @ls_par194 = RTRIM(LTRIM(ISNULL(par194.v_valor_par,'')))FROM t_parametro par194 (NOLOCK)
		WHERE par194.c_codigo_par = '194'

		/*sacar mercado del producto */
		SELECT @ls_mer = RTRIM(LTRIM(ISNULL(c_merdes_pro,''))) FROM dbo.t_producto (NOLOCK) WHERE c_codigo_pro = @id_producto

		SELECT @ls_folini = ISNULL(c_codigoini_pem,''), 
				@ls_folfin = ISNULL(c_codigofin_pem,'') , 
				@ls_folinime = ISNULL(c_codigoinime_pem,''), 
				@ls_folfinme = ISNULL(c_codigofinme_pem,''), 
				@ll_LongPal = CONVERT(NUMERIC,c_cerosp_pem), 
				@ll_longpalme = CONVERT(NUMERIC,c_cerospme_pem) 
		FROM t_puntoempaque (NOLOCK) 
		WHERE c_codigo_pem = @idEmpaque
		
		IF (@ll_LongPal <= 0) BEGIN	SET @ll_LongPal = LEN(@ls_folini) END 	 
		IF (@ll_longpalme <= 0) BEGIN	SET @ll_longpalme = LEN(@ls_folinime) END 
		
		/*Regeneracion de folios con longitud correcta*/
		SET @ls_folini = RIGHT( '0000000000' + @ls_folini , @ll_LongPal )
		SET @ls_folfin = RIGHT( '0000000000' + @ls_folfin , @ll_LongPal )
		SET @ls_folinime = RIGHT( '0000000000' + @ls_folinime, @ll_longpalme)
		SET @ls_folfinme = RIGHT( '0000000000' + @ls_folfinme, @ll_longpalme) 
		
		/*Prefijo por usuario-punto de empaque*/
		SELECT @ls_prefpal = ISNULL(v_prefijopal_upe,'')
		FROM   t_usuarioptoempaque
		WHERE  c_usupe_upe = @idUsuario	
		And    c_codigo_pem = @idEmpaque
		And    c_activo_upe = '1'
		IF (@ls_prefpal = '') BEGIN	SET @ls_prefpal = '%' END

		IF(@ls_folxmer<>'S') BEGIN SET @ls_folxmer = 'N' END	

		IF(@ls_folxmer='S' AND @ls_mer='E') 
			BEGIN	
				SELECT 	@ls_pal = MAX(c_codigo_pal) 
				FROM 	t_palet p
				WHERE 	c_codigo_emp = @idEmpaque
				And    c_codigo_pal Between @ls_folinime And @ls_folfinme
				And    c_codigo_tem = @idTemporada
				And    c_codigo_pal Like @ls_prefpal	
				
				select 	@ls_palsc = MAX(c_codigo_pal) 
				from 	t_paletsinconfirmar p
				where 	c_codigo_emp = @idEmpaque
				and c_codigo_pal between @ls_folinime and @ls_folfinme
				and c_codigo_tem = @idTemporada
				And c_codigo_pal Like @ls_prefpal	
				
				IF( @ls_pal = '' and @ls_palsc = '') BEGIN SET @ls_pal = @ls_folinime END	

				IF(@ls_pal <> '' and @ls_palsc <> '')
					BEGIN
						IF(@ls_pal <> '' and @ls_palsc <> '')
							BEGIN
								SET @ls_pal = CONVERT(VARCHAR,CONVERT(NUMERIC,@ls_pal)+1)
								SET @ls_new = RIGHT('0000000000'+@ls_pal,@ll_longpalme)
							END 
						ELSE	
							BEGIN	
								SET @ls_pal = CONVERT(VARCHAR,CONVERT(NUMERIC,@ls_palsc)+1)
								SET @ls_new = RIGHT('0000000000'+@ls_pal,@ll_longpalme)
							END
					END 
				ELSE IF(@ls_pal <> '' and @ls_palsc = '')
					BEGIN
						SET @ls_pal = CONVERT(VARCHAR,CONVERT(NUMERIC,@ls_pal)+1)
						SET @ls_new = RIGHT('0000000000'+@ls_pal,@ll_longpalme)

						IF(@ls_prefpal <> '' And @ls_prefpal <> '%')
							BEGIN	
								SET @ls_new = SUBSTRING( @ls_prefpal , 1, Len( @ls_prefpal ) - 1 ) + SUBSTRING( @ls_new, Len( @ls_prefpal ) , Len( @ls_new ) )	
							END
					END
				ELSE IF(@ls_pal = '' and @ls_palsc <> '')
					BEGIN
						SET @ls_pal = CONVERT(VARCHAR,CONVERT(NUMERIC,@ls_palsc)+1)
						SET @ls_new = RIGHT('0000000000'+@ls_pal,@ll_longpalme)
					END
			END		
		ELSE
			BEGIN	
				Select top 1 @ls_new = ISNULL(x.c_codigo_pal,'')
				From (
							Select 	c_codigo_pal = RTRIM(LTRIM(RIGHT('0000000000' + LTRIM(RTRIM(IsNull(c_codigo_pal,''))),10)))
							From 		t_palet p
							Where 	c_codigo_emp = @idEmpaque
										And c_codigo_pal between @ls_folini and @ls_folfin
										And c_codigo_tem = @idTemporada
										And c_codigo_pal Like @ls_prefpal	
			
							UNION ALL
				
							Select 	c_codigo_pal = RIGHT('0000000000' + LTRIM(RTRIM(IsNull(c_codigo_pal,''))),10)
							From 		t_paletsinconfirmar p
							Where 	c_codigo_emp = @idEmpaque
										And c_codigo_pal between @ls_folini and @ls_folfin
										And c_codigo_tem = @idTemporada
										And c_codigo_pal Like @ls_prefpal	
							
							UNION ALL
				
							Select 	 c_codigo_pal = RIGHT('0000000000' + LTRIM(RTRIM(IsNull(c_codigo_pal,''))),10)
							From 		t_paleteliminado p
							Where 	c_codigo_emp = @idEmpaque
										And c_codigo_pal between @ls_folini and @ls_folfin
										And c_codigo_tem = @idTemporada
										And c_codigo_pal Like @ls_prefpal	
						)x
				ORDER BY x.c_codigo_pal DESC

				IF(@ls_new = '0000000000' OR @ls_new = '' )
					BEGIN	
						SET @ls_new = @ls_folini
						SET @ls_new = CONVERT(VARCHAR,CONVERT(NUMERIC,@ls_new)+1)
						SET @ls_new = RIGHT('0000000000'+@ls_new,@ll_LongPal)

						IF(@ls_prefpal <> '' And @ls_prefpal <> '%')
							BEGIN	
								SET @ls_new = SUBSTRING( @ls_prefpal , 1, Len( @ls_prefpal ) - 1 ) + SUBSTRING( @ls_new, Len( @ls_prefpal ) , Len( @ls_new ) )	
							END 
					END
				ELSE	
					BEGIN	
						SET @ls_new = CONVERT(VARCHAR,CONVERT(NUMERIC,@ls_new)+1)
						SET @ls_new = RIGHT('0000000000'+@ls_new,@ll_LongPal)
					END;

				IF (@ls_par194 = 'PAFSA')
				BEGIN	
					SELECT 	@ls_new = RTRIM(LTRIM(MAX(c_codigo_pal))) 
					FROM 	t_palet p
					WHERE 	c_codigo_emp = @idEmpaque
					And    c_codigo_tem = @idTemporada
					And    c_codigo_pal Like @ls_prefpal
					IF( @ls_new = '') BEGIN SET @ls_new = '0' END	 
					SET @ls_new = CONVERT(VARCHAR,CONVERT(NUMERIC,@ls_new)+1) 
					SET @ls_new = RIGHT('0000000000'+@ls_new,@ll_LongPal)
				END
			END
		RETURN	@ls_new
	END



