-- Hægt skal vera að skoða fjölda seldra eininga niður á ár, mánuð, viku eða dag eftir búð og vöru
SELECT
    ds.name AS store_name,
    dp.name AS product_name,
    dc.year,
    dc.monthName AS month,
    dc.week,
    dc.date AS day,
    SUM(fs.unitsSold) AS total_units_sold
FROM
    factSales fs
JOIN dimStores ds ON fs.idStore = ds.id
JOIN dimProduct dp ON fs.idProduct = dp.rowkey
JOIN dimCalender dc ON fs.idCalender = dc.datekey
GROUP BY
    ds.name,
    dp.name,
    dc.year,
    dc.monthName,
    dc.week,
    dc.date, dc.week, dc.week
ORDER BY
    ds.name,
    dp.name,
    dc.year,
    dc.monthName,
    dc.week,
    dc.date;


-- Hægt skal vera að skoða veltu og kostnað með sama niðurbroti
SELECT
    ds.name AS store_name,
    dp.name AS product_name,
    dc.year,
    dc.monthNo,
    dc.week,
    dc.date AS day,
    SUM(fs.unitsSold * dp.price) AS turnover,
    SUM(fs.unitsSold * dp.cost) AS costs
FROM
    factSales fs
JOIN dimStores ds ON fs.idStore = ds.id
JOIN dimProduct dp ON fs.idProduct = dp.rowkey
JOIN dimCalender dc ON fs.idCalender = dc.datekey
GROUP BY
    ds.name,
    dp.name,
    dc.year,
    dc.monthNo,
    dc.week,
    dc.date
ORDER BY
    store_name,
    product_name,
    year,
    monthNo,
    week,
    day;


-- Hægt skal vera að reikna meðal veltu, meðal upphæð körfu og meðal fjölda keyptra hluta per körfu.
WITH Basket AS (
    SELECT
        fs.receipt,
        SUM(fs.unitsSold * dp.price) AS basket_turnover,
        SUM(fs.unitsSold) AS total_items,
        COUNT(DISTINCT fs.idProduct) AS unique_products_in_basket
    FROM
        factSales fs
    JOIN dimProduct dp ON fs.idProduct = dp.rowkey
    GROUP BY
        fs.receipt
)
SELECT
    AVG(basket_turnover) AS avg_turnover,
    AVG(basket_turnover / total_items) AS avg_price_per_item,
    AVG(total_items) AS avg_items_per_basket
FROM
    Basket;

-- Það þarf að vera hægt að skoða lager upplýsingar niður á búð og vöru.
SELECT
    ds.name AS store_name,
    dp.name AS product_name,
    SUM(fi.inStock) AS total_stock
FROM
    factInventory fi
JOIN dimStores ds ON fi.idStore = ds.id
JOIN dimProduct dp ON fi.idProduct = dp.rowkey
GROUP BY
    ds.name,
    dp.name
ORDER BY
    store_name,
    product_name;
