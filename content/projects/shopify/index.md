---
categories:
  - Projects
tags:
  - ProtonDB
  - Jupyter
  - Plotly
  - Steam Deck
  - SteamOS
title: Shopify Fall 2022 Data Science Intern Challenge
excerpt: "Data Science Challenge Solution for Shopify Fall 2022 Internship Application" 
plotly: true
---

[Download Notebook](https://github.com/n0k0m3/n0k0m3.github.io/blob/main/_projects/shopify/datascience.ipynb){: .btn .btn--info }

**Note:** All graphs and plots are interactive. Feel free to zoom, pan, and edit the graphs for more granular details.

## Question 1

### Part A

<details>
<summary>Code</summary>

``` python
import pandas as pd
import plotly.express as px

px.defaults.width = 600
px.defaults.height = 400
```

</details>

A quick view (first 5 rows) of the data

<details>
<summary>Code</summary>

``` python
data = pd.read_csv("https://docs.google.com/spreadsheets/d/16i38oonuX1y1g7C_UAmiK9GkY7cS-64DfiDMNiR41LM/edit#gid=0".replace('/edit#gid=', '/export?format=csv&gid='))
data.head()
```

</details>
<div>
<style scoped>
    .dataframe tbody tr th:only-of-type {
        vertical-align: middle;
    }

    .dataframe tbody tr th {
        vertical-align: top;
    }

    .dataframe thead th {
        text-align: right;
    }
</style>

|     | order_id | shop_id | user_id | order_amount | total_items | payment_method | created_at          |
|-----|----------|---------|---------|--------------|-------------|----------------|---------------------|
| 0   | 1        | 53      | 746     | 224          | 2           | cash           | 2017-03-13 12:36:56 |
| 1   | 2        | 92      | 925     | 90           | 1           | cash           | 2017-03-03 17:38:52 |
| 2   | 3        | 44      | 861     | 144          | 1           | cash           | 2017-03-14 4:23:56  |
| 3   | 4        | 18      | 935     | 156          | 1           | credit_card    | 2017-03-26 12:43:37 |
| 4   | 5        | 18      | 883     | 156          | 1           | credit_card    | 2017-03-01 4:35:11  |

</div>
<details>
<summary>Code</summary>

``` python
data.created_at = pd.to_datetime(data.created_at)
data = data.sort_values(["created_at"])
```

</details>

#### Analysis 1: Order Amount Distribution Analysis

Assuming zero-knowledge of the data view, let's graph the `order_amount` distribution.

<details>
<summary>Code</summary>

``` python
fig = px.histogram(data.order_amount,title="Order Amount Histogram")
fig.show()
fig.write_json("plot_data/order_amount_histogram.json")
```

</details>

{{< plotly json="plot_data/order_amount_histogram.json" >}}

We can see that the almost all order value is less than or equal \$5000, let's graph the data with this bound.

<details>
<summary>Code</summary>

``` python
fig = px.histogram(data.order_amount[data.order_amount<=5000],title="Order Amount (with Amount < $5000) Histogram")
fig.show()
fig.write_json("plot_data/order_amount_histogram_5000.json")
```

</details>

{{< plotly json="plot_data/order_amount_histogram_5000.json" >}}

We see that the distribution are left skewed and also bimodal: \[0,220) represents first model and (220,5000+) represents the second model
(From the shape of distribution we can assume the first one is normal distribution, the second model is Weibull/Gamma distribution. However, this assumption won't play any role in the solutions).

**The bimodal and skewed distribution, along with outlier points tell us that arithmetic mean of order amount is not a good indicator of the average order amount (AOV). As such, other metrics should be used to analyze the order amount average.**

Also, we can see that the distribution is mostly concentrated in the range \[0,1100\], which we'll use later to analyze AOV.

#### Analysis 2: Time Series of Order Amount Analysis

From a quick scroll of the original data, we can see that `shop_id` 42 and 78 are outliers that have large order values that **potentially skew the AOV** (cause the AOV to be much larger than it supposed to be). This behavior can also be observed from the graph of Daily Order Amount by Shop.

<details>
<summary>Code</summary>

``` python
fig = px.line(data,y="order_amount",x="created_at",color="shop_id",title="Daily Order Amount by Shop")
fig.show()
fig.write_json("plot_data/daily_order_amount_by_shop.json")
```

</details>

{{< plotly json="plot_data/daily_order_amount_by_shop.json" >}}

Graphing the data without outlier shops, we have a more concentrated view of the data.

<details>
<summary>Code</summary>

``` python
fig = px.line(data[~data.shop_id.isin([42,78])],y="order_amount",x="created_at",color="shop_id",title="Daily Order Amount by non-outlier Shop")
fig.show()
fig.write_json("plot_data/daily_order_amount_by_shop_no_outlier.json")
```

</details>

{{< plotly json="plot_data/daily_order_amount_by_shop_no_outlier.json" >}}

In fact, we can see that other 98 shops don't have any order that exceed \$1100, which agrees with previous analysis on `order_amount` empirical distribution.

### Part B

With previous analyses, I propose 3 solutions to analyze AOV:
- **Median** of order amount as AOV
- As the first analysis show that the order amount is left skewed and the count of large `order_amount` is small, we can use the median as the AOV.
- This requires minimum change in code base and is the simplest solution.
- However, to implement this we need to communicate with stakeholders to brief the reason of using median.
- This metric doesn't consider temporary spikes (example: shops suddenly got an influx of orders for Christmas, etc.)
- AOV using **arithmetic mean** with `order_amount` capped at \$1100.
- Depends on the business needs (i.e. AOV per product category for small businesses), we can remove large outlier shops.
- Doesn't change the metric type
- Alienate large business users, and doesn't consider temporary spikes
- In larger scale, we need to build a robust solution to detect and remove outliers from reported AOV.
- AOV using **arithmetic mean** with `shop_id` 42 and 78 **removed as outliers**.
- Same pros and cons as the 2nd solution, except that we **will able to catch temporary spikes in order amount**.

We can also add other interesting additions to the above solutions (won't be implemented for this challenge):
- Per-shop AOV
- Report to shop owner for their personalized metrics
- Shop performance metrics on platform
- Daily AOV with outliers removed
- Analyzing trends of order amount by day
- Identify peak days and potential bottoms

### Part C

**Median** of order amount as AOV (Note that this median is on the whole dataset with outliers included)

<details>
<summary>Code</summary>

``` python
print("Median as AOV: ${}".format(data.order_amount.median()))
```

</details>

    Median as AOV: $284.0

**Arithmetic mean** of order amount with outliers removed

<details>
<summary>Code</summary>

``` python
print("Arithmetic mean as AOV on capped order amount of $1100: ${}".format(data.order_amount[data.order_amount<=1100].mean()))
print("Arithmetic mean as AOV with outlier shops removed: ${}".format(data[~data.shop_id.isin([42,78])].order_amount.mean()))
```

</details>

    Arithmetic mean as AOV on capped order amount of $1100: $301.83704904742604
    Arithmetic mean as AOV with outlier shops removed: $300.1558229655313

**Note:** For median, even with outliers removed, we still get the same result as above

<details>
<summary>Code</summary>

``` python
print("Median as AOV on capped order amount of $1100: ${}".format(data.order_amount[data.order_amount<=1100].median()))
print("Median as AOV with outlier shops removed: ${}".format(data[~data.shop_id.isin([42,78])].order_amount.median()))
```

</details>

    Median as AOV on capped order amount of $1100: $284.0
    Median as AOV with outlier shops removed: $284.0

**Conclusion:** Depends on business need, either "Median as AOV" or "Arithmetic mean as AOV with outlier shops" can be used to analyze AOV.

## Question 2

Queries for this question are fully compatible with the [website providing the dataset](https://www.w3schools.com/SQL/TRYSQL.ASP?FILENAME=TRYSQL_SELECT_ALL) (w3schools.com).
- 1. How many orders were shipped by Speedy Express in total?
    - Result: 54 orders were shipped by Speedy Express in total

    ``` sql
    SELECT count(*)
    FROM Orders
        LEFT JOIN Shippers ON Orders.ShipperID = Shippers.ShipperID
    WHERE Shippers.ShipperName="Speedy Express";
    ```

-   2.  What is the last name of the employee with the most orders?

    -   Result: Last name of the employee with the most orders (40) is Peacock

    ``` sql
    SELECT TOP 1
      count(*) as OrderCount, Employees.LastName
    FROM Orders
      LEFT JOIN Employees ON Orders.EmployeeID=Employees.EmployeeID
    GROUP BY Employees.EmployeeID,Employees.LastName
    ORDER BY count(*) DESC;
    ```

-   3.  What product was ordered the most by customers in Germany?

    -   Result: Product was order the most (5 times) by customers in Germany is Gorgonzola Telino

    ``` sql
    SELECT TOP 1
      count(*) as OrderCount, Products.ProductName
    FROM (((Orders
      INNER JOIN OrderDetails ON Orders.OrderID=OrderDetails.OrderID)
      INNER JOIN Products ON OrderDetails.ProductID=Products.ProductID)
      INNER JOIN Customers ON Orders.CustomerID=Customers.CustomerID)
    WHERE Country = "Germany"
    GROUP BY Products.ProductID,Products.ProductName
    ORDER BY count(*) DESC;
    ```
