/*|AGS|*/
If OBJECT_ID('EYE_SortingCPParaPTI') Is Null
	CREATE TABLE [dbo].[EYE_SortingCPParaPTI](
		[cIdSortingCP] [varchar](15) NOT NULL,
		[nIdCorridaParaPTI] [int] NOT NULL,
		[c_codigo_usu] [char](20) NOT NULL,
		[d_creacion_scp] [datetime] NOT NULL,
		[c_usumod_scp] [char](20) NULL,
		[d_modifi_scp] [datetime] NULL,
		[c_activo_scp] [char](1) NOT NULL,
	 CONSTRAINT [PK_SortingCPParaPTI] PRIMARY KEY CLUSTERED 
	(
		[cIdSortingCP] ASC
	)WITH (	PAD_INDEX					= OFF, 
			STATISTICS_NORECOMPUTE		= OFF, 
			IGNORE_DUP_KEY				= OFF, 
			ALLOW_ROW_LOCKS				= ON, 
			ALLOW_PAGE_LOCKS			= ON, 
			OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
	) ON [PRIMARY]

/*|AGS|*/
If Not Exists(Select 1 from sys.indexes Where name = 'IX_SortingCPParaPTI')
	CREATE NONCLUSTERED INDEX [IX_SortingCPParaPTI] ON [dbo].[EYE_SortingCPParaPTI]
	(
		[cIdSortingCP] ASC
	)WITH (	PAD_INDEX = OFF, 
			STATISTICS_NORECOMPUTE		= OFF, 
			SORT_IN_TEMPDB				= OFF, 
			DROP_EXISTING				= OFF, 
			ONLINE						= OFF, 
			ALLOW_ROW_LOCKS				= ON, 
			ALLOW_PAGE_LOCKS			= ON, 
			OPTIMIZE_FOR_SEQUENTIAL_KEY	= OFF) ON [PRIMARY]

/*|AGS|*/
If OBJECT_ID('DF_EYE_SortingCPParaPTI_d_creacion_scp') Is Null
	ALTER TABLE [dbo].[EYE_SortingCPParaPTI] ADD  CONSTRAINT [DF_EYE_SortingCPParaPTI_d_creacion_scp]  
											DEFAULT (CONVERT([date],getdate(),(0))) FOR [d_creacion_scp]
/*|AGS|*/
If OBJECT_ID('DF_EYE_SortingCPParaPTI_c_activo_scp') Is Null
	ALTER TABLE [dbo].[EYE_SortingCPParaPTI] ADD  CONSTRAINT [DF_EYE_SortingCPParaPTI_c_activo_scp]  
											DEFAULT ('1') FOR [c_activo_scp]
/*|AGS|*/
If Object_Id('PK_t_sortingmaduracion') Is Null
	ALTER TABLE t_sortingmaduracion ADD CONSTRAINT PK_t_sortingmaduracion PRIMARY KEY (c_folio_sma)

/*|AGS|*/
If Object_Id('FK_EYE_SortingCPParaPTI_t_sortingmaduracion') Is Null
	ALTER TABLE [dbo].[EYE_SortingCPParaPTI]  WITH CHECK ADD  CONSTRAINT [FK_EYE_SortingCPParaPTI_t_sortingmaduracion] 
														FOREIGN KEY([cIdSortingCP])
														REFERENCES [dbo].[t_sortingmaduracion] ([c_folio_sma])

/*|AGS|*/
ALTER TABLE [dbo].[EYE_SortingCPParaPTI] CHECK CONSTRAINT [FK_EYE_SortingCPParaPTI_t_sortingmaduracion]
