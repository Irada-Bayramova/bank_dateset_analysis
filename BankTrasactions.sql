--dataset overview
select * from bankTransactions
where fraud_flag = 1;

select count(*) as total_rows from bankTransactions;

desc bankTransactions;

-- basic transaction statistics
select sum(transaction_amount) from bankTransactions;

select avg(transaction_amount) from bankTransactions;

--checking data for missing and duplicate values
select count(*) as null_amount_count
from bankTransactions
where transaction_amount is null;

select transaction_id, count(*)
from bankTransactions
group by transaction_id
having count(*) > 1;

-- Transaction_type analysis
select transaction_type, count(*)
from bankTransactions
group by transaction_type;

select transaction_type, trunc(avg(transaction_amount))
from bankTransactions
group by transaction_type;

-- outlier transaction analysis
select *
from bankTransactions
order by transaction_amount desc
fetch first 10 rows only;

-- monthly transaction trend
select 
  trunc(transaction_date, 'MM') as month,
  count(*) as transaction_count,
  sum(transaction_amount) as total_amount
from bankTransactions
group by trunc(transaction_date, 'MM')
order by month;

--
select count(transaction_id)as transaction_count,
sum(transaction_amount)as total_amount,
extract ( month from transaction_date) as monthh
from bankTransactions
group by  extract ( month from transaction_date)
order by extract ( month from transaction_date) ;


--geographic analysis
select source_city, count(*)as transaction_count
from bankTransactions
group by source_city
order by count(*);

select source_country, trunc(avg(transaction_amount))
from bankTransactions
group by source_country
order by trunc(avg(transaction_amount));

select destination_country, trunc(avg(transaction_amount))
from bankTransactions
group by destination_country
order by trunc(avg(transaction_amount));


select * from (select source_country,customer_id,transaction_count,
row_number() over(order by transaction_count desc) as rn
from (
select source_country,customer_id,count(transaction_id)as transaction_count
from bankTransactions group by source_country, customer_id
))
where rn <= 10;


--currency analysis
select source_currency, count(*)
from bankTransactions
group by source_currency
order by count(*);

select exchange_rate from bankTransactions;

select exchange_rate, avg(converted_amount) as avg_converted_amount
from bankTransactions
group by exchange_rate;

select round(avg(converted_amount),2) as avg_converted,
case 
    when exchange_rate < 100 then 'low'
    when exchange_rate between 100 and 500 then 'medium'
    else 'high'
end as rate_level
  
from banktransactions
group by 
case 
    when exchange_rate < 100 then 'low'
    when exchange_rate between 100 and 500 then 'medium'
    else 'high'
end;

select avg(exchange_rate) from bankTransactions;

select max(exchange_rate),min(exchange_rate) from bankTransactions;

--customer behaviour analysis
select customer_id , count(*)as transaction_count
from bankTransactions
group by customer_id
order by count(*) desc
fetch first 10 rows only;

-- channel and device analysis
select channel,count(transaction_id),
trunc(avg(processing_time_seconds)) as average_processing_time
from bankTransactions
group by channel;

select device_type, count(transaction_id) as transaction_cout,
trunc(avg(processing_time_seconds)) as average_processing_time
from bankTransactions
group by device_type 
order by  count(transaction_id) desc;

--transaction amount groupping
select transaction_amount from bankTransactions;
select 
case 
    when transaction_amount < 1000 then 'Low'
    when transaction_amount between 1000 and 5000 then 'Medium'
    else 'High'
end as categoried_amout,
    
count(*)
    
from bankTransactions

group by case 
    when transaction_amount < 1000 then 'Low'
    when transaction_amount between 1000 and 5000 then 'Medium'
    else 'High'
end;

--fees and tax analysis
select source_country, sum(fee_charged),sum(tax_applied), 
round(sum(total_deduction),2)
from bankTransactions
group by source_country;

select total_deduction from bankTransactions;

--customer ranking
select customer_id,sum(transaction_amount)as total_amount,
rank() over(order by sum(transaction_amount) desc) as rk
from bankTransactions
group by customer_id
order by sum(transaction_amount) desc;

-- window functions
select *
from( select transaction_amount,
    row_number()over(order by transaction_amount desc)as rn
     from  bankTransactions)
where rn <=10;

--
select customer_id,transaction_date,transaction_amount,
sum(transaction_amount) over(partition by customer_id order by transaction_date)as cumilative_amount
from bankTransactions;

--
select customer_id,transaction_amount,transaction_date,
lag(transaction_amount, 1, 0)over(partition by customer_id order by transaction_date) as previous_amount
from bankTransactions;

--subquery based 
select transaction_amount
from bankTransactions
where transaction_amount >any 
(select avg(transaction_amount) from bankTransactions);

--
select destination_country,transaction_amount
from bankTransactions bt
where transaction_amount > (select avg(transaction_amount) 
                            from bankTransactions
                            where destination_country = bt.destination_country);

--customer groupping
select customer_id,total_amount,
ntile(4) over(order by total_amount desc) as quartile
from(
select customer_id, sum(transaction_amount) as total_amount from bankTransactions
group by customer_id);


--contact type analysis
select contract_type, round(avg(transaction_amount),2) as average_amount
from bankTransactions
group by contract_type;


--fraud and risk analysis
--fraud transactions
select fraud_flag, count(*) as fraud_count
from bankTransactions
group by fraud_flag;

--the average of fraud transactions
select  fraud_flag, round(avg(transaction_amount),2) as average_amount_for_fraud
from bankTransactions
group by fraud_flag;

--risk score analysis
select risk_score from bankTransactions;

select count(*) as count_of_risk_transactions,
case 
    when risk_score < 30 then 'Low'
    when risk_score between 30 and 70 then 'Medium'
    else 'High'
end as risk_level

from bankTransactions
group by 
case 
    when risk_score < 30 then 'Low'
    when risk_score between 30 and 70 then 'Medium'
    else 'High'
end;


-- aml flag
select aml_flag, count(*)
from bankTransactions
group by aml_flag;

--time analysis
select transaction_date, count(*)
from banktransactions
group by transaction_date
order by 1;

--Top 3 transactions with the highest value within each channel
select * from (
select channel, transaction_id, customer_id, transaction_amount,
rank() over( partition by channel order by transaction_amount desc) as rank_in_channel
from bankTransactions)
where rank_in_channel <= 3;

-- difference between customer's previous transactions
select customer_id, transaction_date, transaction_amount,
lag(transaction_amount, 1 , 0) over(partition by customer_id order by transaction_date)as previous_amount,
transaction_amount - lag(transaction_amount, 1, 0) 
over(partition by customer_id order by transaction_date) as differnce
from bankTransactions;


/* what percentage of a customer's total transaction 
amount is made up of their largest single transaction.*/
select customer_id, total_amount, max_tr_amount,
round((max_tr_amount /total_amount)*100, 2) as max_tr_percentage
from(
select customer_id, sum(transaction_amount) as total_amount,
max(transaction_amount) as max_tr_amount
from bankTransactions
group by customer_id)
order by max_tr_percentage desc;

