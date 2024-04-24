/*|AGS|*/
IF NOT EXISTS
( SELECT *
  FROM sys.objects
  WHERE object_id = OBJECT_ID(N'CajasYPesoPorDefault')
        AND type IN ( N'U' ))
BEGIN
	CREATE	TABLE CajasYPesoPorDefault(
		idPuntoDeEmpaque CHAR(2) NOT NULL,
		idTipoSorteo CHAR(1) NOT NULL,
		iLibras NUMERIC,
		iCajas NUMERIC
	)
END		