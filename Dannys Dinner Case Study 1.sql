//Challenge from https://8weeksqlchallenge.com/


// Q1.What is the total amount each customer spent at the restaurant?

SELECT S.CUSTOMER_ID as Customer, SUM(M.PRICE) as Total_Spent
FROM SALES as S
INNER JOIN MENU as M
ON S.PRODUCT_ID= M.PRODUCT_ID
GROUP BY CUSTOMER_ID;

//Q2. How many days has each customer visited the restaurant?

SELECT S.CUSTOMER_ID as Customer, COUNT(DISTINCT S.ORDER_DATE) as Days_Visited
FROM SALES as S
GROUP BY S.CUSTOMER_ID;

//Q3. What was the first item from the menu purchased by each customer? RANK Function

WITH EARLIEST_ORDER as (
SELECT S.CUSTOMER_ID as Customer,
       S.ORDER_DATE,
       M.PRODUCT_NAME as Product,
       RANK() OVER (PARTITION BY S.CUSTOMER_ID ORDER BY S.ORDER_DATE ASC ) as RNK
FROM SALES as S
INNER JOIN MENU as M
ON S.PRODUCT_ID= M.PRODUCT_ID)

SELECT *
FROM EARLIEST_ORDER
WHERE RNK=1;

//3. What was the first item from the menu purchased by each customer? Row NUmber Function

WITH EARLIEST_ORDER as (
SELECT S.CUSTOMER_ID as Customer,
       S.ORDER_DATE,
       M.PRODUCT_NAME as Product,
       ROW_NUMBER() OVER (PARTITION BY S.CUSTOMER_ID ORDER BY S.ORDER_DATE ASC ) as RN
FROM SALES as S
INNER JOIN MENU as M
ON S.PRODUCT_ID= M.PRODUCT_ID)

SELECT *
FROM EARLIEST_ORDER
WHERE RN=1;
   


// Q4. What is the most purchased item on the menu and how many times was it purchased by all customers?


SELECT  M. PRODUCT_NAME, 
        COUNT(M.PRODUCT_NAME) as Times_Ordered
FROM SALES as S
INNER JOIN MENU as M
ON S.PRODUCT_ID= M.PRODUCT_ID
GROUP BY M.PRODUCT_NAME,S.PRODUCT_ID
ORDER BY Times_Ordered DESC 
LIMIT 1;

// 5. Which item was the most popular for each customer?

WITH Customer_Orders as (
SELECT  S.CUSTOMER_ID as Customer,
        M. PRODUCT_NAME as Product,
        COUNT(M.PRODUCT_NAME) as Times_Ordered,
        RANK() OVER(PARTITION BY Customer ORDER BY Times_Ordered DESC) as RNK
FROM SALES as S
INNER JOIN MENU as M
ON S.PRODUCT_ID= M.PRODUCT_ID
GROUP BY Product,Customer)

SELECT CUSTOMER,PRODUCT,TIMES_ORDERED
FROM Customer_Orders
WHERE RNK=1;

// 6. Which item was purchased first by the customer after they became a member?

WITH First_Order_After_Membership as (

SELECT MB.CUSTOMER_ID,
       MB.JOIN_DATE,
       S.ORDER_DATE, 
       M.PRODUCT_NAME,
       RANK () OVER (PARTITION BY MB.CUSTOMER_ID ORDER BY ORDER_DATE ASC) as RNK
FROM MEMBERS as MB
INNER JOIN SALES as S
ON MB.CUSTOMER_ID=S.CUSTOMER_ID
INNER JOIN MENU as M
ON S.PRODUCT_ID=M.PRODUCT_ID
WHERE S.ORDER_DATE >= MB.JOIN_DATE)

SELECT *
FROM First_Order_After_Membership
WHERE RNK=1;


// 7. Which item was purchased just before the customer became a member?

WITH First_Order_Before_Membership as (

SELECT MB.CUSTOMER_ID,
       MB.JOIN_DATE,
       S.ORDER_DATE, 
       M.PRODUCT_NAME,
       RANK () OVER (PARTITION BY MB.CUSTOMER_ID ORDER BY ORDER_DATE DESC) as RNK
FROM MEMBERS as MB
INNER JOIN SALES as S
ON MB.CUSTOMER_ID=S.CUSTOMER_ID
INNER JOIN MENU as M
ON S.PRODUCT_ID=M.PRODUCT_ID
WHERE S.ORDER_DATE < MB.JOIN_DATE)

SELECT *
FROM First_Order_Before_Membership
WHERE RNK=1;


// 8. What is the total items and amount spent for each member before they became a member?///

SELECT MB.CUSTOMER_ID,
       COUNT(M.PRODUCT_NAME) as Number_of_Orders,
       SUM(M.PRICE) AS Total_Spent
FROM MEMBERS as MB
INNER JOIN SALES as S
ON MB.CUSTOMER_ID=S.CUSTOMER_ID
INNER JOIN MENU as M
ON S.PRODUCT_ID=M.PRODUCT_ID
WHERE S.ORDER_DATE < MB.JOIN_DATE
GROUP BY MB.CUSTOMER_ID;

// 9. If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many points would each customer have?

SELECT S.CUSTOMER_ID,
       SUM(CASE WHEN M.PRODUCT_NAME= 'sushi' THEN M.PRICE * 10 * 2
                    ELSE M.PRICE * 10
             END) as Points
FROM SALES as S
INNER JOIN MENU as M 
ON S.PRODUCT_ID=M.PRODUCT_ID
GROUP BY S.CUSTOMER_ID;

// 10. In the first week after a customer joins the program (including their join date) they earn 2x points on all items, not just sushi - how many points do customers A and B have at the end of January?//

SELECT S.CUSTOMER_ID,
       SUM(CASE WHEN S.ORDER_DATE >= MB.JOIN_DATE AND S.ORDER_DATE <= DATEADD('day',6,MB.JOIN_DATE)
                                     THEN M.PRICE * 10 * 2
                                    WHEN M.PRODUCT_NAME= 'sushi' THEN M.PRICE * 10 * 2
                    ELSE M.PRICE * 10
             END) as Points
FROM SALES as S
INNER JOIN MENU as M 
ON S.PRODUCT_ID=M.PRODUCT_ID
INNER JOIN MEMBERS AS MB
ON S.CUSTOMER_ID=MB.CUSTOMER_ID
WHERE ORDER_DATE < (TO_DATE('2021/02/01', 'YYYY/MM/DD'))
GROUP BY S.CUSTOMER_ID;


-- Join All The Things
SELECT 
  S.customer_id, 
  order_date, 
  product_name, 
  price, 
  CASE 
    WHEN join_date IS NULL THEN 'N'
    WHEN order_date < join_date THEN 'N' 
    ELSE 'Y' 
  END as member 
FROM 
  SALES as S
  INNER JOIN MENU AS M ON S.product_id = M.product_id 
  LEFT JOIN MEMBERS AS MEM ON MEM.customer_id = S.customer_id 
ORDER BY 
  S.customer_id, 
  order_date, 
  price DESC;
  
-- Rank All The Things
WITH CTE AS (
  SELECT 
    S.customer_id, 
    S.order_date, 
    product_name, 
    price, 
    CASE 
      WHEN join_date IS NULL THEN 'N'
      WHEN order_date < join_date THEN 'N'
      ELSE 'Y' 
    END as member 
  FROM 
    SALES as S 
    INNER JOIN MENU AS M ON S.product_id = M.product_id
    LEFT JOIN MEMBERS AS MEM ON MEM.customer_id = S.customer_id
  ORDER BY 
    customer_id, 
    order_date, 
    price DESC
)
SELECT 
  *
  ,CASE 
    WHEN member = 'N'  THEN NULL
    ELSE RANK() OVER(PARTITION BY customer_id, member ORDER BY order_date)  
  END as rnk
FROM CTE;

