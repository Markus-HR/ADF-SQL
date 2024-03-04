DROP TABLE IF EXISTS [h5].[dimProduct_stg];
CREATE TABLE [h5].[dimProduct_stg] (
    id int identity (1, 1),
    rowKey nvarchar (200),
    name nvarchar (200),
    category nvarchar (50),
    cost decimal(18,2),
    price decimal(18,2),
    rowBatchId int not null,
    rowCreated datetime not null default  getutcdate(),
    CONSTRAINT  [pk_dimProduct_stg] PRIMARY KEY CLUSTERED ([id])
);
create unique index UIX_dimProduct_stg_rowBatchId on [h5].[dimProduct_stg] ([rowBatchId], [rowKey]);

DROP TABLE IF EXISTS [h5].[dimStores_stg];
CREATE TABLE [h5].[dimStores_stg] (
    id int identity (1, 1),
    rowKey nvarchar (200),
    name nvarchar (50) not null,
    city nvarchar (50) not null,
    location nvarchar (50) not null,
    rowBatchId int not null,
    rowCreated datetime not null default  getutcdate(),
    CONSTRAINT  [pk_dimStores_stg] PRIMARY KEY CLUSTERED ([id])
);
create unique index UIX_dimStores_stg_rowBatchId on [h5].[dimStores_stg] ([rowBatchId], [rowKey]);

DROP TABLE IF EXISTS [h5].[factInventory_stg];
CREATE TABLE [h5].[factInventory_stg] (
    id int identity (1, 1),
    idStore int not null,
    idProduct int not null,
    inStock int not null,
    rowBatchId int not null,
    rowCreated datetime not null default  getutcdate(),
    CONSTRAINT  [pk_factInventory_stg] PRIMARY KEY CLUSTERED ([id])
);
create unique index UIX_factInventory_stg_rowBatchId on [h5].[factInventory_stg] ([rowBatchId]);

DROP TABLE IF EXISTS [h5].[factSales_stg];
CREATE TABLE [h5].[factSales_stg] (
    id int identity (1, 1),
    idCalender int not null,
    receipt nvarchar (20) not null,
    idStore int not null,
    idProduct int not null,
    unitsSold smallint not null,
    rowBatchId int not null,
    rowCreated datetime not null default  getutcdate(),
    CONSTRAINT  [pk_factSales_stg] PRIMARY KEY CLUSTERED ([id])
);
create unique index UIX_factSales_stg_rowBatchId on [h5].[factSales_stg] ([rowBatchId]);

-- Tables

DROP TABLE IF EXISTS [h5].[dimProduct];
CREATE TABLE [h5].[dimProduct] (
    id int identity (1, 1),
    rowKey nvarchar (200),
    name nvarchar (200),
    category nvarchar (50),
    cost decimal not null,
    price decimal not null,
    rowBatchId int not null,
    rowCreated datetime not null default  getutcdate(),
    rowModified datetime not null default getutcdate(),
    CONSTRAINT  [pk_dimProduct] PRIMARY KEY CLUSTERED ([id])
);
create unique index UIX_dimProduct_rowBatchId on [h5].[dimProduct] ([rowKey]);

DROP TABLE IF EXISTS [h5].[dimStores];
CREATE TABLE [h5].[dimStores] (
    id int identity (1, 1),
    rowKey nvarchar (200),
    name nvarchar (50) not null,
    city nvarchar (50) not null,
    location nvarchar (50) not null,
    rowBatchId int not null,
    rowCreated datetime not null default  getutcdate(),
    rowModified datetime not null default getutcdate(),
    CONSTRAINT  [pk_dimStores] PRIMARY KEY CLUSTERED ([id])
);
create unique index UIX_dimStores_rowBatchId on [h5].[dimStores] ([rowKey]);

DROP TABLE IF EXISTS [h5].[dimCalender];
CREATE TABLE [h5].[dimCalender] (
    id int identity (1, 1),
    rowKey nvarchar (200),
    date date not null,
    rowBatchId int not null,
    rowCreated datetime not null default  getutcdate(),
    rowModified datetime not null default getutcdate(),
    CONSTRAINT  [pk_dimCalender] PRIMARY KEY CLUSTERED ([id])
);
create unique index UIX_dimCalendar_rowBatchId on [h5].[dimCalender] ([rowKey]);

DROP TABLE IF EXISTS [h5].[factInventory];
CREATE TABLE [h5].[factInventory] (
    id int identity (1, 1),
    idStore int not null,
    idProduct int not null,
    inStock int not null,
    rowBatchId int not null,
    rowCreated datetime not null default  getutcdate(),
    CONSTRAINT  [pk_factInventory] PRIMARY KEY CLUSTERED ([id])
);
create unique index UIX_factInventory_rowBatchId on [h5].[factInventory] ([rowBatchId]);

DROP TABLE IF EXISTS [h5].[factSales];
CREATE TABLE [h5].[factSales] (
    id int identity (1, 1),
    idCalender int not null,
    receipt nvarchar (20) not null,
    idStore int not null,
    idProduct int not null,
    unitsSold smallint not null,
    rowBatchId int not null,
    rowCreated datetime not null default  getutcdate(),
    CONSTRAINT  [pk_factSales] PRIMARY KEY CLUSTERED ([id])
);
create unique index UIX_factSales_rowBatchId on [h5].[factSales] ([rowBatchId]);

DROP TABLE IF EXISTS [h5].[errors];
CREATE TABLE [h5].[errors] (
    id int identity (1, 1),
    refTable nvarchar (20),
    refColumn nvarchar (20),
    refId int,
    refRowBatchId int,
    error varchar (50)
);

-- PROCEDURES

-- PRODUCT
go
DROP PROCEDURE IF EXISTS [h5].[dimProduct_publish];
go

CREATE PROCEDURE [h5].[dimProduct_publish]
    @batchId int
AS
BEGIN
    -- Quality check
    IF EXISTS (
        SELECT 1
        FROM [h5].[dimProduct_stg]
        WHERE [rowBatchId] = @batchId
              AND (
                    [cost] IS NULL
                    OR [price] IS NULL
                    OR [cost] < 0
                    OR [price] < 0
                  )
    )
    BEGIN
        -- set cost or price to 0
        UPDATE [h5].[dimProduct_stg]
        SET [cost] = 0
        WHERE [rowBatchId] = @batchId AND ([cost] < 0 OR [cost] IS NULL);

        UPDATE [h5].[dimProduct_stg]
        SET [price] = 0
        WHERE [rowBatchId] = @batchId AND ([price] < 0 OR [price] IS NULL);

        -- Log errors to the error table (optional)
        INSERT INTO [h5].[errors] (
            [refTable],
            [refColumn],
            [refId],
            [refRowBatchId],
            [error]
        )
        SELECT
            'dimProduct_stg' AS [refTable],
            'cost' AS [refColumn],
            [id] AS [refId],
            @batchId AS [refRowBatchId],
            'Invalid data: cost is negative or NULL' AS [error]
        FROM [h5].[dimProduct_stg]
        WHERE [rowBatchId] = @batchId AND ([cost] < 0 OR [cost] IS NULL);

        INSERT INTO [h5].[errors] (
            [refTable],
            [refColumn],
            [refId],
            [refRowBatchId],
            [error]
        )
        SELECT
            'dimProduct_stg' AS [refTable],
            'price' AS [refColumn],
            [id] AS [refId],
            @batchId AS [refRowBatchId],
            'Invalid data: price is negative or NULL' AS [error]
        FROM [h5].[dimProduct_stg]
        WHERE [rowBatchId] = @batchId AND ([price] < 0 OR [price] IS NULL);
    END;
    MERGE INTO [h5].[dimProduct] TRG
    USING
    (
        SELECT [rowKey],
               [name] = ISNULL([name], 'n/a'),
               [category] = ISNULL([category], 'n/a'),
               [cost],
               [price],
               [rowBatchId]
        FROM [h5].[dimProduct_stg]
        WHERE [rowBatchId] = @batchId
    ) SRC
    ON SRC.rowKey = TRG.rowKey
    WHEN MATCHED THEN
        UPDATE SET [name]        = SRC.[name],
                   [category]    = SRC.[category],
                   [cost]        = SRC.[cost],
                   [price]       = SRC.[price],
                   [rowBatchId]  = SRC.[rowBatchId],
                   [rowModified] = getutcdate()
    WHEN NOT MATCHED THEN
        INSERT
        (
             [rowKey],
             [name],
             [category],
             [cost],
             [price],
             [rowBatchId]
        )
        VALUES
        (
         SRC.[rowKey],
         SRC.[name],
         SRC.[category],
         SRC.[cost],
         SRC.[price],
         SRC.[rowBatchId]
        );
	select dummyval = 2
    return 1
    END;

go

DROP PROCEDURE IF EXISTS [h5].[dimProduct_postprocess];
go
CREATE PROCEDURE [h5].[dimProduct_postprocess]
    @BatchID int
    AS
    DELETE FROM [h5].[dimProduct_stg] WHERE rowBatchId = @BatchID;
    select dummyval = 2
    return 1
go

-- STORES
go
DROP PROCEDURE IF EXISTS [h5].[dimStores_publish];
go

CREATE PROCEDURE [h5].[dimStores_publish]
    @batchId int
AS
    -- Quality check
    MERGE INTO [h5].[dimStores] TRG
    USING
    (
        SELECT [rowKey],
               [name]= ISNULL([location], 'n/a'),
               [city] = ISNULL([location], 'n/a'),
               [location] = ISNULL([location], 'n/a'),
               [rowBatchId]
        FROM [h5].[dimStores_stg]
        WHERE [rowBatchId] = @batchId
    ) SRC
    ON SRC.rowKey = TRG.rowKey
    WHEN MATCHED THEN
        UPDATE SET [name]        = SRC.[name],
                   [city]    = SRC.[city],
                   [location]        = SRC.[location],
                   [rowBatchId]  = SRC.[rowBatchId],
                   [rowModified] = getutcdate()
    WHEN NOT MATCHED THEN
        INSERT
        (
             [rowKey],
             [name],
             [city],
             [location],
             [rowBatchId]
        )
        VALUES
        (
         SRC.[rowKey],
         SRC.[name],
         SRC.[city],
         SRC.[location],
         SRC.[rowBatchId]
        );
    select dummyval = 2
    return 1
go
DROP PROCEDURE IF EXISTS [h5].[dimStores_postprocess];
go
CREATE PROCEDURE [h5].[dimStores_postprocess]
    @BatchID int
    AS
    DELETE FROM [h5].[dimStores_stg] WHERE rowBatchId = @BatchID;
    select dummyval = 2
    return 1
go