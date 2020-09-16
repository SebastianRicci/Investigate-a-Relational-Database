/* What is the percentage of rentals per family category? */

WITH t1 AS
        (SELECT f.title,c.name
        FROM film f
        JOIN film_category fc
        ON f.film_id=fc.film_id
        JOIN category c
        ON fc.category_id=c.category_id
        JOIN inventory i
        ON i.film_id=f.film_id
        JOIN rental r
        ON r.inventory_id=i.inventory_id
        WHERE c.name IN ('Animation','Children','Classics','Comedy','Family','Music'))

SELECT title,name,COUNT(*)
FROM t1
GROUP BY 1,2
ORDER BY 2,1

/* How does rental duration vary for each film category */

WITH family_friendly AS (SELECT f.title,c.name,f.rental_duration,
                        NTILE(4) OVER (ORDER BY f.rental_duration) AS standard_quartile
                        FROM film f
                        JOIN film_category fc
                        ON f.film_id=fc.film_id
                        JOIN category c
                        ON c.category_id=fc.category_id
                        WHERE c.name IN ('Animation','Children','Classics','Comedy','Family','Music'))
SELECT  name,standard_quartile,
       COUNT(*)
FROM family_friendly
GROUP BY 1,2
ORDER BY 1,2

/* How do the stores compare against each other in the amount of rental orders since their opening? */

SELECT DATE_PART('month',r.rental_date) Rental_month,
       DATE_PART('year',r.rental_date) Rental_year,
       c.store_id,COUNT(c.store_id)

FROM rental r
JOIN customer c
ON r.customer_id=c.customer_id
GROUP BY 1,2,3
ORDER BY 4 DESC

/* Are customer payments increasing? */

WITH Payment_difference AS
        (WITH top_customers AS

            (SELECT c.customer_id AS customer,SUM(p.amount)
            FROM customer c
            JOIN payment p
            ON p.customer_id=c.customer_id
            GROUP BY 1
            ORDER BY 2 DESC
            LIMIT 10)

        SELECT DATE_TRUNC('month',p.payment_date) date,
               CONCAT(c.first_name,' ',c.last_name) full_name,
               COUNT(p.customer_id),SUM(p.amount) payment_amount

        FROM payment p
        JOIN customer c
        on p.customer_id=c.customer_id
        JOIN top_customers
        ON top_customers.customer=p.customer_id
        GROUP BY 1,2
        ORDER BY 2)

SELECT date,full_name,payment_amount,
       LEAD(payment_amount) OVER (ORDER BY full_name) - payment_amount AS month_difference
FROM Payment_difference
