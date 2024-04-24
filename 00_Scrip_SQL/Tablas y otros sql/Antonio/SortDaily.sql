SELECT	WarehouseLocation	= Emp.v_nombre_pem,
		Week				= Sem.nIdSemana,
		Month				= Sem.iMes,
		RunDate				= Convert(Date, Sor.d_creacion_sma),
		GrowerName			= Due.v_Nombre_dno,
		BlockId				= Lot.v_nombre_lot,
		Method				= Met.v_nombre_var,
		Libras				= Sor.n_totalkilos_sma,
		Corrida				= Sor.c_folio_sma, 
		Maduracion			= Mad.v_nombre_gdm,
		Grado				= Cal.v_nombre_cal,
		Temporada			= Sor.c_codigo_tem, 
		--NoDePallets			= Sor.n_totalpalets_sma,
		Razon				= ISNULL(Raz.cNombre, 'CONSUMER PACK'),
		--Cajas				= Sor.n_totalcajas_sma, 
		--FinVaciado			= CASE Sor.c_finvaciado_sma WHEN 'S' THEN 'Si' ELSE 'No' END,
		Pallet				= ISNULL(Pal.c_codigo_pte, ''),
		--Area				= ISNULL(Are.v_nombre_are, ''),
		Libras				= ISNULL(Pal.d_totkilos_pte, 0),
		Cajas				= ISNULL(Pal.d_totcaja_pte, 0),
		SUBSTRING(Sor.c_folio_sma, 3,3 )
FROM	dbo.t_sortingmaduracion Sor (NOLOCK)
	LEFT	JOIN dbo.t_razones Raz (NOLOCK) ON Raz.idRazon = Sor.idrazon
	INNER	JOIN dbo.t_puntoempaque Emp (NOLOCK) ON Emp.c_codigo_pem = Sor.c_codigo_emp
	INNER	JOIN dbo.t_lote Lot (NOLOCK) ON Lot.c_codigo_tem = RIGHT(Sor.c_folio_sma,2)
									AND Lot.c_codigo_lot = SUBSTRING(Sor.c_folio_sma, 10,4)
	LEFT	JOIN dbo.t_paletemporal Pal (NOLOCK) ON Pal.c_codigo_sma = Sor.c_folio_sma
	LEFT	JOIN dbo.t_areafisica Are (NOLOCK) ON Are.c_codigo_are = Pal.c_codigo_are
	INNER	JOIN dbo.t_Semanas Sem (NOLOCK) ON Sor.d_creacion_sma BETWEEN Sem.dtInicial AND Sem.dtFinal
	INNER	JOIN dbo.t_huerto Hue (NOLOCK) ON Hue.c_codigo_hue = Lot.c_codigo_hue
	INNER	JOIN dbo.t_Duenio Due (NOLOCK) ON Due.c_codigo_dno = Hue.c_codigo_dno
	INNER	JOIN dbo.t_Variedad Met (NOLOCK) ON Met.c_codigo_var = Lot.c_codigo_var
	LEFT	JOIN dbo.t_gradomaduracion Mad (NOLOCK) ON Mad.c_codigo_gdm = Pal.c_codigo_gma
	LEFT	JOIN dbo.t_Calibre Cal (NOLOCK) ON Cal.c_codigo_cal = Pal.c_codigo_cal
WHERE	SUBSTRING(Sor.c_folio_sma, 2,3 ) BETWEEN CAST(:ad_ini-CAST(CAST(YEAR(:ad_ini)-1 AS VARCHAR(4))+'1231' AS DATETIME) AS INT)
													AND CAST(:ad_fin-CAST(CAST(YEAR(:ad_fin)-1 AS VARCHAR(4))+'1231' AS DATETIME) AS INT)
	AND SUBSTRING(Sor.c_folio_sma, 1,2 ) BETWEEN RIGHT(YEAR(GETDATE()),2) AND RIGHT(YEAR(GETDATE()),2)
	AND ( :as_dueno = '' OR dno.c_codigo_dno IN( :as_duenos) )
	AND ( :as_bloque = '' OR Lot.c_codigoext_lot IN( :as_bloques ) ) 
	AND ISNULL(Vari.c_codigo_var,'') like :as_variedad
	AND ISNULL(Det.c_codigo_tem,'') like :as_temp
	AND ISNULL(Det.c_codigo_pem,'') like :as_emp
	AND SUBSTRING(c_folio_sma,6,4) like :as_are
	AND Pal.c_codigo_cal LIKE :as_cal
	AND pal.c_codigo_gma LIKE :as_grado
	AND Sor.idrazon = :as_razon
ORDER	BY Sor.c_folio_sma, Pal.c_codigo_pte



