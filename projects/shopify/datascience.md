---
layout: default
title: Shopify Fall 2022 Data Science Intern Challenge
nav_exclude: true
search_exclude: true
---
# Shopify Fall 2022 Data Science Intern Challenge

[Download Notebook](../datascience.ipynb){: .btn }

**Note:** All graphs and plots are interactive. Feel free to zoom, pan, and edit the graphs for more granular details.

## Question 1

### Part A

A quick view (first 5 rows) of the data




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
<table border="1" class="dataframe">
  <thead>
    <tr style="text-align: right;">
      <th></th>
      <th>order_id</th>
      <th>shop_id</th>
      <th>user_id</th>
      <th>order_amount</th>
      <th>total_items</th>
      <th>payment_method</th>
      <th>created_at</th>
    </tr>
  </thead>
  <tbody>
    <tr>
      <th>0</th>
      <td>1</td>
      <td>53</td>
      <td>746</td>
      <td>224</td>
      <td>2</td>
      <td>cash</td>
      <td>2017-03-13 12:36:56</td>
    </tr>
    <tr>
      <th>1</th>
      <td>2</td>
      <td>92</td>
      <td>925</td>
      <td>90</td>
      <td>1</td>
      <td>cash</td>
      <td>2017-03-03 17:38:52</td>
    </tr>
    <tr>
      <th>2</th>
      <td>3</td>
      <td>44</td>
      <td>861</td>
      <td>144</td>
      <td>1</td>
      <td>cash</td>
      <td>2017-03-14 4:23:56</td>
    </tr>
    <tr>
      <th>3</th>
      <td>4</td>
      <td>18</td>
      <td>935</td>
      <td>156</td>
      <td>1</td>
      <td>credit_card</td>
      <td>2017-03-26 12:43:37</td>
    </tr>
    <tr>
      <th>4</th>
      <td>5</td>
      <td>18</td>
      <td>883</td>
      <td>156</td>
      <td>1</td>
      <td>credit_card</td>
      <td>2017-03-01 4:35:11</td>
    </tr>
  </tbody>
</table>
</div>



#### Analysis 1: Order Amount Distribution Analysis

Assuming zero-knowledge of the data view, let's graph the `order_amount` distribution.


<iframe
    scrolling="no"
    width="620px"
    height="420"
    src="iframe_figures/figure_65.html"
    frameborder="0"
    allowfullscreen
></iframe>



We can see that the almost all order value is less than or equal $5000, let's graph the data with this bound.


<iframe
    scrolling="no"
    width="620px"
    height="420"
    src="iframe_figures/figure_66.html"
    frameborder="0"
    allowfullscreen
></iframe>



We see that the distribution are left skewed and also bimodal: [0,220) represents first model and (220,5000+) represents the second model
(From the shape of distribution we can assume the first one is normal distribution, the second model is Weibull/Gamma distribution. However, this assumption won't play any role in the solutions).

**The bimodal and skewed distribution, along with outlier points tell us that arithmetic mean of order amount is not a good indicator of the average order amount (AOV). As such, other metrics should be used to analyze the order amount average.**

Also, we can see that the distribution is mostly concentrated in the range [0,1100], which we'll use later to analyze AOV.

#### Analysis 2: Time Series of Order Amount Analysis

From a quick scroll of the original data, we can see that `shop_id` 42 and 78 are outliers that have large order values that **potentially skew the AOV** (cause the AOV to be much larger than it supposed to be). This behavior can also be observed from the graph of Daily Order Amount by Shop.


<iframe
    scrolling="no"
    width="620px"
    height="420"
    src="iframe_figures/figure_67.html"
    frameborder="0"
    allowfullscreen
></iframe>



Graphing the data without outlier shops, we have a more concentrated view of the data.


<iframe
    scrolling="no"
    width="620px"
    height="420"
    src="iframe_figures/figure_68.html"
    frameborder="0"
    allowfullscreen
></iframe>



In fact, we can see that other 98 shops don't have any order that exceed $1100, which agrees with previous analysis on `order_amount` empirical distribution.

### Part B

With previous analyses, I propose 3 solutions to analyze AOV:
- **Median** of order amount as AOV
  - As the first analysis show that the order amount is left skewed and the count of large `order_amount` is small, we can use the median as the AOV.
  - This requires minimum change in code base and is the simplest solution.
  - However, to implement this we need to communicate with stakeholders to brief the reason of using median.
  - This metric doesn't consider temporary spikes (example: shops suddenly got an influx of orders for Christmas, etc.)
- AOV using **arithmetic mean** with `order_amount` capped at $1100.
  - Depends on the business needs (i.e. AOV per product category for small businesses), we can remove large outlier shops.
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

    Median as AOV: $284.0


**Arithmetic mean** of order amount with outliers removed

    Arithmetic mean as AOV on capped order amount of $1100: $301.83704904742604
    Arithmetic mean as AOV with outlier shops removed: $300.1558229655313


**Note:** For median, even with outliers removed, we still get the same result as above

    Median as AOV on capped order amount of $1100: $284.0
    Median as AOV with outlier shops removed: $284.0


**Conclusion:** Depends on business need, either "Median as AOV" or "Arithmetic mean as AOV with outlier shops" can be used to analyze AOV.

## Question 2
Queries for this question are fully compatible with the [website providing the dataset](https://www.w3schools.com/SQL/TRYSQL.ASP?FILENAME=TRYSQL_SELECT_ALL) (w3schools.com).
- a. How many orders were shipped by Speedy Express in total?
  - Result: 54 orders were shipped by Speedy Express in total 
```sql
SELECT count(*)
FROM Orders
    LEFT JOIN Shippers ON Orders.ShipperID = Shippers.ShipperID
WHERE Shippers.ShipperName="Speedy Express";
```
- b. What is the last name of the employee with the most orders?
  - Result: Last name of the employee with the most orders (40) is Peacock
```sql
SELECT TOP 1
    count(*) as OrderCount, Employees.LastName
FROM Orders
    LEFT JOIN Employees ON Orders.EmployeeID=Employees.EmployeeID
GROUP BY Employees.EmployeeID,Employees.LastName
ORDER BY count(*) DESC;
```
- c. What product was ordered the most by customers in Germany?
  - Result: Product was order the most (5 times) by customers in Germany is Gorgonzola Telino
```sql
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

