select emp_id, name, surname
from employee
where emp_id in (
    select employee_id
    from (
    select employee_id, sum(purchase_id)
    from purchase
    group by employee_id) as foo);
