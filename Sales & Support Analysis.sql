use interview;

##Segment 1 ##
-- Question 1: Identify the tables and their respective columns in the database nad their datatypes to ensure they are appropriate for the stored data
Show Tables from interview;
desc agents;
desc customer;
desc orders;

-- Question 2 : Determine the number of records in each table
Select count(*) as number_of_records from agents;
Select count(*) as number_of_records from customer;
Select count(*) as number_of_records from orders;

-- Question 3 Identify and handle any missing or inconsistent values in the dataset.

SET SQL_SAFE_UPDATES = 0;
update agents
Set Agent_name = Trim(agent_name),
Working_Area = Trim(Working_area),
Phone_No = Trim(Phone_no),
Agent_code = Trim(Agent_Code)
;

Update customer
set cust_city = Trim(cust_city),
Agent_code = Trim(Agent_Code),
Phone_No = case when Phone_No REGEXP '[0-9]' then Phone_No else '' end ;

Update orders
Set Agent_code = Trim(Agent_Code),
ORD_DESCRIPTION = REPLACE(REPLACE(ORD_DESCRIPTION, '\r', ''), '\n', '');

-- Question 4 Analyse the data types of the columns in each table to ensure they are appropriate for the stored data.
Describe Agents;
Describe customer;
Describe orders;

/* We can see that In agents Agent code is marked as primary key but in other table like orders table ord_num should be the 
primary key and same like in customer table cust_code should be marked as primary key to ensure that there must not be duplicates 
each value should be unique so we can do that
*/

-- Question 5 Identify any duplicate records within the tables and develop a strategy for handling them.

Select 
	Agent_Code, count(*) from Agents 
group by 
	Agent_Code
having 
	count(*)>1;

Select 
	cust_Code, count(*) from customer
group by 
	Cust_Code
having 
	count(*)>1;

Select 
	Ord_Num , count(*) from orders
group by 
	Ord_Num
having 	
	count(*)>1;

/* We have not found any duplicates but we can add a unique contraint on cust_code in customer table and on ord_num in
   orders table to avoid duplicate records in future.*/

#### Segment 2 ####   Basic Sales Analysis

-- Question 1 :-   Retrieve the total number of orders, total revenue, and average order value.
SELECT 
	COUNT(DISTINCT ORD_NUM) as total_orders, 
    SUM(ORD_AMOUNT) as total_revenue, 
    ROUND(AVG(ORD_AMOUNT),2) as average_order_value
FROM orders;

/* Question 2:-    The operations team needs to track the agent who has handled the maximum number of high-grade customers. 
   Write a SQL query to find the agent_name who has the highest count of customers with a grade of 5. Display the agent_name
   and the count of high-grade customers */
   
Select agent_name , count(Cust_Code) as high_grade_customers
from agents
join customer using(Agent_code)
where Grade = 5
group by Agent_name;
   
### there were no customers with grade 5 we can debug using this query (select distinct Grade from customer) hence we are not getting any result

/*Question 3:-  The company wants to identify the most active customer cities in terms of the total order amount. Write a SQL query to find the top 3 
   customer cities with the highest total order amount. Include cust_city and total_order_amount in the output. */
   
Select Cust_city , sum(Ord_Amount) as total_order_amount
from customer
join orders using(Cust_code)
Group by Cust_City
order by total_order_amount desc
limit 3;
   
### Chennai with 17000, Mumbai with 12700 and London with 12500 total_order amount. These are top 3 cities
   
### Segment 3####   Customer Analysis:
   
-- Question 1:-   Calculate the total number of customers.
Select distinct count(cust_code) as total_customers
from customer;

## There are 25 customers in total##

-- Question 2:-  Identify the top-spending customers based on their total order value.

Select Cust_Name , sum(Ord_Amount) as total_order_value
from customer
join orders using(Cust_code)
Group by Cust_Name
order by total_order_value desc
limit 3;

-- Question 3 :-  Analyse customer retention by calculating the percentage of repeat customers.

With repeat_customers as (
   select count(*) as repeat_cust from (Select distinct cust_code 
   from customer
   join orders using(Cust_code)
   group by cust_code
   having count(ord_Num)>1) as a),
total_customers as (
   Select count(distinct cust_code) as total_cust 
   from customer)
Select round(repeat_cust*100/total_cust,2) as percent_of_repeat_customer
from repeat_customers r,
total_customers t;

-- Question 4:-  Find the name of the customer who has the maximum outstanding amount from every country. 

Select cust_country, Cust_Name, Outstanding_Amt 
from ( 
	Select *, rank() over(partition by cust_country order by Outstanding_Amt desc) as rnk 
    from customer) as a
where rnk= 1;

-- Question 5:-  Write a SQL query to calculate the percentage of customers in each grade category (1 to 5).

Select grade, round(count(cust_code)*100/(Select count(*) from customer),2) as perecentage_of_customers
from customer
group by grade
order by grade;

### Segment 4 ### Agent Performance Analysis  ####

/* Question 1:-  Company wants to provide a performance bonus to their best agents based on the maximum order amount. 
   Find the top 5 agents eligible for it. */
   
Select Agent_Name, Sum(Ord_amount) as total_order_amt
from orders  o join  agents a using(Agent_code)
group by Agent_name
order by total_order_amt desc
Limit 5;

/* Question 2:-  The company wants to analyse the performance of agents based on the number of orders they have handled. 
Write a SQL query to rank agents based on the total number of orders they have processed. 
Display agent_name, total_orders, and their respective ranking  */

Select Agent_Name, Count( distinct Ord_num) as total_order, rank() over(order by count(distinct ord_num) desc) as rnk
from orders  o join  agents a using(Agent_code)
group by Agent_name;

/* Question 3:-  Company wants to change the commission for the agents, basis advance payment they collected. 
Write a sql query which creates a new column updated_commision on the basis below rules.
If the average advance amount collected is less than 750, there is no change in commission.
If the average advance amount collected is between 750 and 1000 (inclusive), the new commission will be 1.5 times the old commission.
If the average advance amount collected is more than 1000, the new commission will be 2 times the old commission.  */

Select agent_code, Agent_name, round(avg(Advance_Amount),2) as avg_advance_amt, Commission,
   case when avg(Advance_Amount) >1000 then Commission*2 
   when avg(Advance_Amount) between 750 and 1000 then Commission*1.5
   when avg(Advance_Amount)<750 then Commission
   end as updated_commission
from Agents 
join orders using(Agent_code)
group by Agent_code,Agent_name;

### Segemnt 5 ####  SQL taks

/*Add a new column named avg_rcv_amt in the table customers which contains the average receive amount for every country. 
  Display all columns from the customer table along with the avg_rcv_amt column in the last.  */

Alter table customer 
Add column avg_rcv_amt decimal (10,2);

SET SQL_SAFE_UPDATES = 0;

Update customer c join (
Select cust_country, avg(Receive_Amt) as avg_rcv_amt 
from customer
group by cust_country) as avg_table on c.cust_country = avg_table.cust_country
Set c.avg_rcv_amt = avg_table.avg_rcv_amt;

SET SQL_SAFE_UPDATES = 1;

select * from customer;

/* Write a sql query to create and call a UDF named avg_amt to return the average outstanding amount of the customers which are 
   managed by a given agent. Also, call the UDF with the agent name ‘Mukesh’.  */

Delimiter //

Create Function avg_amt(agent_name_input Varchar(40))
Returns Decimal(12,2)
Deterministic
Begin
    Declare avg_out_amt Decimal(12,2);

    Select avg(c.OUTSTANDING_AMT)
    into avg_out_amt
    From customer c
    Join agents a on c.agent_code = a.agent_code
    Where a.agent_name = agent_name_input;

    Return avg_out_amt;
End //

Delimiter ;

/* Write a sql query to create and call a subroutine called cust_detail to return all the details of the customer which are having 
   the given grade. Also, call the subroutine with grade 2.  */

Delimiter //
create procedure cust_detail(In  grade_input decimal(10,0))
Begin
	Select *
    from customer
    where Grade = grade_input;
End //
Delimiter ;

call cust_detail(2);
 


/* Write a stored procedure sp_name which will return the concatenated ord_num (comma separated) of the customer with input customer 
   code using cursor. Also, write the procedure call query with cust_code ‘C00015’.  */ 
 
 
 -- Without using cursor comma sepearated ord_num with cust_code at the end
Delimiter //

Create procedure sp_name(in cust_code_input varchar(6))
Begin
	Select concat_WS('/',group_concat(ord_num ORDER BY ord_num SEPARATOR ','),cust_code_input) as comma_sepearted_ord_num
    from orders
    where cust_code = cust_code_input;
end //
Delimiter ;

Call sp_name('C00015') ;

-- Without cursor comma_seperated ord_num

 Delimiter //

Create procedure sp_name_ord_num(in cust_code_input varchar(6))
Begin
	Select group_concat(ord_num ORDER BY ord_num SEPARATOR ',') as comma_sepearted_ord_num
    from orders
    where cust_code = cust_code_input;
end //
Delimiter ;

Call sp_name_ord_num('C00015') ;












   
   
   


 
 








