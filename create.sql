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
    name nvarchar (50),
    city nvarchar (50),
    location nvarchar (50),
    rowBatchId int not null,
    rowCreated datetime not null default  getutcdate(),
    CONSTRAINT  [pk_dimStores_stg] PRIMARY KEY CLUSTERED ([id])
);
create unique index UIX_dimStores_stg_rowBatchId on [h5].[dimStores_stg] ([rowBatchId], [rowKey]);

DROP TABLE IF EXISTS [h5].[factInventory_stg];
CREATE TABLE [h5].[factInventory_stg] (
    id int identity (1, 1),
    rowKey nvarchar (200),
    idStore int,
    idProduct int,
    inStock int,
    rowBatchId int not null,
    rowCreated datetime not null default  getutcdate(),
    CONSTRAINT  [pk_factInventory_stg] PRIMARY KEY CLUSTERED ([id])
);
create unique index UIX_factInventory_stg_rowBatchId on [h5].[factInventory_stg] ([rowBatchId], [rowKey]);

DROP TABLE IF EXISTS [h5].[factSales_stg];
CREATE TABLE [h5].[factSales_stg] (
    id int identity (1, 1),
    rowKey nvarchar (200),
    idCalender int,
    receipt nvarchar (20),
    idStore int,
    idProduct int,
    unitsSold smallint,
    rowBatchId int not null,
    rowCreated datetime not null default  getutcdate(),
    CONSTRAINT  [pk_factSales_stg] PRIMARY KEY CLUSTERED ([id])
);
create unique index UIX_factSales_stg_rowBatchId on [h5].[factSales_stg] ([rowBatchId], [rowKey]);

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
    datekey INT,
    -- TODO rowkey nvarchar (200),
    date DATE,
    year INT,
    monthNo INT,
    monthName varchar(20),
    YYYY_MM varchar(7),
    week INT,
    yearWeek varchar(7),
    --OLD id int identity (1, 1),
    --OLD date date not null,
    -- TODO rowBatchId int not null,
    -- TODO rowCreated datetime not null default  getutcdate(),
    -- TODO rowModified datetime not null default getutcdate(),
    CONSTRAINT  [pk_dimCalender] PRIMARY KEY CLUSTERED ([datekey]) -- ??
);
create unique index UIX_dimCalendar_rowBatchId on [h5].[dimCalender] ([datekey]); -- ??

DROP TABLE IF EXISTS [h5].[factInventory];
CREATE TABLE [h5].[factInventory] (
    id int identity (1, 1),
    rowKey nvarchar (200),
    idStore int not null,
    idProduct int not null,
    inStock int not null,
    rowBatchId int not null,
    rowCreated datetime not null default  getutcdate(),
    CONSTRAINT  [pk_factInventory] PRIMARY KEY CLUSTERED ([id])
);
create unique index UIX_factInventory_rowBatchId on [h5].[factInventory] ([rowKey]);

DROP TABLE IF EXISTS [h5].[factSales];
CREATE TABLE [h5].[factSales] (
    id int identity (1, 1),
    rowKey nvarchar (200),
    idCalender int not null,
    receipt nvarchar (20) not null,
    idStore int not null,
    idProduct int not null,
    unitsSold smallint not null,
    rowBatchId int not null,
    rowCreated datetime not null default  getutcdate(),
    CONSTRAINT  [pk_factSales] PRIMARY KEY CLUSTERED ([id])
);
create unique index UIX_factSales_rowBatchId on [h5].[factSales] ([rowKey]);

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
                    OR [name] IS NULL
                    OR [category] IS NULL
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

        UPDATE [h5].[dimProduct_stg]
        SET [name] = 'n/a'
        WHERE [rowBatchId] = @batchId AND [name] IS NULL;

        UPDATE [h5].[dimProduct_stg]
        SET [category] = 'n/a'
        WHERE [rowBatchId] = @batchId AND [category] IS NULL;

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

        INSERT INTO [h5].[errors] (
            [refTable],
            [refColumn],
            [refId],
            [refRowBatchId],
            [error]
        )
        SELECT
            'dimProduct_stg' AS [refTable],
            'name' AS [refColumn],
            [id] AS [refId],
            @batchId AS [refRowBatchId],
            'Invalid data: name is NULL' AS [error]
        FROM [h5].[dimProduct_stg]
        WHERE [rowBatchId] = @batchId AND [name] IS NULL;

        INSERT INTO [h5].[errors] (
            [refTable],
            [refColumn],
            [refId],
            [refRowBatchId],
            [error]
        )
        SELECT
            'dimProduct_stg' AS [refTable],
            'category' AS [refColumn],
            [id] AS [refId],
            @batchId AS [refRowBatchId],
            'Invalid data: category is NULL' AS [error]
        FROM [h5].[dimProduct_stg]
        WHERE [rowBatchId] = @batchId AND [category] IS NULL;
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
    IF EXISTS (
        SELECT 1
        FROM [h5].[dimStores_stg]
        WHERE [rowBatchId] = @batchId
              AND (
                    [name] IS NULL
                    OR [city] IS NULL
                    OR [location] IS NULL
                  )
    )
    BEGIN
        UPDATE [h5].[dimStores_stg]
        SET [name] = 'n/a'
        WHERE [rowBatchId] = @batchId AND [name] IS NULL;

        UPDATE [h5].[dimStores_stg]
        SET [city] = 'n/a'
        WHERE [rowBatchId] = @batchId AND [city] IS NULL;

        UPDATE [h5].[dimStores_stg]
        SET [location] = 'n/a'
        WHERE [rowBatchId] = @batchId AND [location] IS NULL;

        INSERT INTO [h5].[errors] (
            [refTable],
            [refColumn],
            [refId],
            [refRowBatchId],
            [error]
        )
        SELECT
            'dimStores_stg' AS [refTable],
            'name' AS [refColumn],
            [id] AS [refId],
            @batchId AS [refRowBatchId],
            'Invalid data: name is NULL' AS [error]
        FROM [h5].[dimStores_stg]
        WHERE [rowBatchId] = @batchId AND [name] IS NULL;

        INSERT INTO [h5].[errors] (
            [refTable],
            [refColumn],
            [refId],
            [refRowBatchId],
            [error]
        )
        SELECT
            'dimStores_stg' AS [refTable],
            'city' AS [refColumn],
            [id] AS [refId],
            @batchId AS [refRowBatchId],
            'Invalid data: city is NULL' AS [error]
        FROM [h5].[dimStores_stg]
        WHERE [rowBatchId] = @batchId AND [city] IS NULL;

        INSERT INTO [h5].[errors] (
            [refTable],
            [refColumn],
            [refId],
            [refRowBatchId],
            [error]
        )
        SELECT
            'dimStores_stg' AS [refTable],
            'location' AS [refColumn],
            [id] AS [refId],
            @batchId AS [refRowBatchId],
            'Invalid data: location is NULL' AS [error]
        FROM [h5].[dimStores_stg]
        WHERE [rowBatchId] = @batchId AND [location] IS NULL;

    end
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
                   [city]        = SRC.[city],
                   [location]    = SRC.[location],
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

-- Sales

DROP PROCEDURE IF EXISTS [h5].[factSales_publish];
go

CREATE PROCEDURE [h5].[factSales_publish]
    @batchId int
AS
BEGIN
    -- Quality check
    IF EXISTS (
        SELECT 1
        FROM [h5].[factSales_stg] fs
        LEFT JOIN [h5].[dimProduct] dp ON fs.idProduct = dp.id
        LEFT JOIN [h5].[dimStores] ds ON fs.idStore = ds.id
        WHERE fs.[rowBatchId] = @batchId
              AND (
                    dp.id IS NULL
                    OR ds.id IS NULL
                    OR fs.[unitsSold] IS NULL
                  )
    )
    BEGIN
        -- Log errors to the error table (optional)
        INSERT INTO [h5].[errors] (
            [refTable],
            [refColumn],
            [refId],
            [refRowBatchId],
            [error]
        )
        SELECT
            'factSales_stg' AS [refTable],
            'idProduct' AS [refColumn],
            fs.[id] AS [refId],
            @batchId AS [refRowBatchId],
            'Invalid data: idProduct does not exist in dimProduct' AS [error]
        FROM [h5].[factSales_stg] fs
        LEFT JOIN [h5].[dimProduct] dp ON fs.idProduct = dp.id
        WHERE fs.[rowBatchId] = @batchId AND dp.id IS NULL;

        INSERT INTO [h5].[errors] (
            [refTable],
            [refColumn],
            [refId],
            [refRowBatchId],
            [error]
        )
        SELECT
            'factSales_stg' AS [refTable],
            'idStore' AS [refColumn],
            fs.[id] AS [refId],
            @batchId AS [refRowBatchId],
            'Invalid data: idStore does not exist in dimStores' AS [error]
        FROM [h5].[factSales_stg] fs
        LEFT JOIN [h5].[dimStores] ds ON fs.idStore = ds.id
        WHERE fs.[rowBatchId] = @batchId AND ds.id IS NULL;

        INSERT INTO [h5].[errors] (
            [refTable],
            [refColumn],
            [refId],
            [refRowBatchId],
            [error]
        )
        SELECT
            'factSales_stg' AS [refTable],
            'unitsSold' AS [refColumn],
            fs.[id] AS [refId],
            @batchId AS [refRowBatchId],
            'Invalid data: unitsSold is NULL' AS [error]
        FROM [h5].[factSales_stg] fs
        WHERE fs.[rowBatchId] = @batchId AND fs.[unitsSold] IS NULL;

    END;

    MERGE INTO [h5].[factSales] TRG
    USING
    (
        SELECT
            fs.[idCalender],
            fs.[receipt],
            fs.[unitsSold],
            ds.id AS [idStore],  -- This is the new ID from dimStores
            dp.id AS [idProduct],  -- This is the new ID from dimProduct
            fs.[rowBatchId]
        FROM [h5].[factSales_stg] fs
        LEFT JOIN [h5].[dimStores] ds ON fs.idStore = ds.id
        LEFT JOIN [h5].[dimProduct] dp ON fs.idProduct = dp.id
        WHERE fs.[rowBatchId] = @batchId
    ) SRC
    ON SRC.idCalender = TRG.idCalender
    AND SRC.receipt = TRG.receipt
    AND SRC.idStore = TRG.idStore
    AND SRC.idProduct = TRG.idProduct
    WHEN MATCHED THEN
        UPDATE SET [idCalender] = SRC.[idCalender],
                   [unitsSold] = SRC.[unitsSold],
                   [rowBatchId] = SRC.[rowBatchId]
    WHEN NOT MATCHED THEN
        INSERT
        (
            [idCalender],
            [receipt],
            [unitsSold],
            [idStore],
            [idProduct],
            [rowBatchId]
        )
        VALUES
        (
            SRC.[idCalender],
            SRC.[receipt],
            SRC.[unitsSold],
            SRC.[idStore],  -- Inserting the new ID from dimStores
            SRC.[idProduct],  -- Inserting the new ID from dimProduct
            SRC.[rowBatchId]
        );

    SELECT dummyval = 2;
    RETURN 1;
END;

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