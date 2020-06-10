select * 
from (
    select comic_id, rating, stock, extract(decade from release_date) as decade 
    from comic_book 
    order by decade desc, rating desc) as foo 
where rating > 7;
