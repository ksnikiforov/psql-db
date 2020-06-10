select name 
from series 
where series_id in (
  select series_id 
  from (
    select series_id, avg(rating) 
    from comic_book 
    group by series_id) as foo);
