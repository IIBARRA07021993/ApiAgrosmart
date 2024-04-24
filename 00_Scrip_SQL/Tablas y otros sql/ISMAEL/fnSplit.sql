/*|AGS|*/
IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id = OBJECT_ID(N'[dbo].[fnSplit]') AND type IN ( N'FN', N'IF', N'TF', N'FS', N'FT' ))
DROP FUNCTION fnSplit
GO

/*|AGS|*/
CREATE FUNCTION [dbo].[fnSplit]
    (
      @data VARCHAR(MAX) ,
      @delimiter VARCHAR(12)
    )
RETURNS @tbldata TABLE ( col VARCHAR(15) )
AS 
    BEGIN

        DECLARE @pos INT

        DECLARE @prevpos INT

        SET @pos = 1
        SET @prevpos = 0

        WHILE @pos > 0 
            BEGIN

                SET @pos = CHARINDEX(@delimiter, @data, @prevpos + 1)

                IF @pos > 0 
                    INSERT  INTO @tbldata
                            ( col
                            )
                    VALUES  ( LTRIM(RTRIM(SUBSTRING(@data, @prevpos + 1,
                                                    @pos - @prevpos - 1)))
                            )

                ELSE 
                    INSERT  INTO @tbldata
                            ( col
                            )
                    VALUES  ( LTRIM(RTRIM(SUBSTRING(@data, @prevpos + 1,
                                                    LEN(@data) - @prevpos)))
                            )

                SET @prevpos = @pos
 
            END
        RETURN

    END

GO