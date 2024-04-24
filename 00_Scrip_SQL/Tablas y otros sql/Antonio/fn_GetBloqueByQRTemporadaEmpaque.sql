/*|AGS|*/
IF EXISTS
(
    SELECT *
    FROM dbo.sysobjects
    WHERE id = OBJECT_ID(N'[dbo].[fn_GetBloqueByQRTemporadaEmpaque]')
)
    DROP PROCEDURE fn_GetBloqueByQRTemporadaEmpaque;

GO
/*|AGS|*/
CREATE FUNCTION [dbo].[fn_GetBloqueByQRTemporadaEmpaque]
(	
	@idQR				VARCHAR(22),
	@idTemporada		CHAR(2),
	@idEmpaque			CHAR(2)
)
RETURNS VARCHAR(10)
AS
BEGIN

	Declare	@idPalletTemporal	CHAR(10) = '',
			@idCorrida			CHAR(15) = '',
			@cRecepcionOPallet	Char(01) = ''

	SELECT	@idPalletTemporal = Pal.c_codigo_pte, @idCorrida = Pal.c_codigo_sma, @cRecepcionOPallet = Corrida.c_tipo_sma
	  FROM	t_paletemporal Pal (NoLock)
	 INNER	JOIN t_sortingmaduracion Corrida (NoLock) ON Corrida.c_folio_sma = Pal.c_codigo_sma
													AND Corrida.c_codigo_tem = Pal.c_codigo_tem
													AND Corrida.c_codigo_emp = Pal.c_codigo_emp
	 WHERE	((Pal.c_codqrtemp_pte = @idQR OR pal.c_codigo_pte = @idQR)
	   AND	Pal.c_codigo_tem = @idTemporada
	   AND	Pal.c_codigo_emp = @idEmpaque)
	   OR(LEN(@idQR) = 6 AND Pal.c_codqrtemp_pte = @idQR  )

	WHILE @cRecepcionOPallet <> 'R' AND @cRecepcionOPallet <> 'E'
	BEGIN

		SELECT	TOP 1 @idPalletTemporal = c_codigo_pal 
		  FROM	dbo.t_sortingmaduraciondet (NoLock) 
		 WHERE	c_folio_sma = @idCorrida

		SELECT	@idPalletTemporal = Pal.c_codigo_pte, @idCorrida = Pal.c_codigo_sma, @cRecepcionOPallet = Corrida.c_tipo_sma
		  FROM	t_paletemporal Pal (NoLock)
		 INNER	JOIN t_sortingmaduracion Corrida (NoLock) ON Corrida.c_folio_sma = Pal.c_codigo_sma
														AND Corrida.c_codigo_tem = Pal.c_codigo_tem
														AND Corrida.c_codigo_emp = Pal.c_codigo_emp
		 WHERE	Pal.c_codigo_pte = @idPalletTemporal
		   AND	Pal.c_codigo_tem = @idTemporada
		   AND	Pal.c_codigo_emp = @idEmpaque

	END
RETURN 
(
	SELECT	TOP 1 c_codigo_lot 
	  FROM	dbo.t_sortingmaduraciondet (NoLock) 
	 WHERE	c_folio_sma = @idCorrida
)
End
GO