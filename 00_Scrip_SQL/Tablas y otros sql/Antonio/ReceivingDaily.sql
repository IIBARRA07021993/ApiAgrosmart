SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- ======================================================
-- Author:		José Francisco Rico Moreno (667) 303-5010
-- Create date: 3 de Agosto de 2023
-- Description:	Extre los datos para Receiving Daily
-- ======================================================
Create Procedure dbo.ReceivingDaily
--Declare
	@dtFechaInicial	DATE,
	@dtFechaFinal	DATE
As
BEGIN
	
	SET NOCOUNT ON;

	--SET @dtFechaInicial = '2023-07-07'
	--SET @dtFechaFinal	= '2024-06-26'
	
	SELECT	Week = Sem.nIdsemana, Month = Sem.iMes, Date = CONVERT(DATE, Rec.d_fecha_rec),
			GrowerName = Hue.v_nombre_hue, Method = Var.v_nombre_var, BlockId = Lot.v_nombre_lot, 
			TagId = Det.c_codexterno_rec, FieldRun = Det.n_kilos_red
	  FROM	dbo.t_recepcion Rec (NoLock)
	 INNER	JOIN dbo.t_Semanas Sem (NOLOCK) ON Rec.d_fecha_rec BETWEEN Sem.dtInicial AND Sem.dtFinal
	 INNER	JOIN dbo.t_lote Lot (NOLOCK) ON Lot.c_codigo_tem = Rec.c_codigo_tem
										AND Lot.c_codigo_lot = Rec.c_codigo_lot
	 INNER	JOIN dbo.t_huerto Hue (NOLOCK) ON Hue.c_codigo_hue = Lot.c_codigo_hue
	 INNER	JOIN dbo.t_variedad Var (NOLOCK) ON Var.c_codigo_var = Lot.c_codigo_var
	 INNER	JOIN dbo.t_recepciondet Det (NOLOCK) ON Det.c_codigo_tem = Rec.c_codigo_tem
												AND Det.c_codigo_rec = Rec.c_codigo_rec
												AND Det.c_codexterno_rec IS NOT NULL
	 WHERE	Rec.d_fecha_rec BETWEEN @dtFechaInicial AND @dtFechaFinal
	 ORDER	BY 3, 6, 7

END
GO
