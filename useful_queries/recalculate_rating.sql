begin;
create or replace function rating_recalculation()
returns void
as $$
begin
update comic_book
set rating = stars from(
select comic_id, avg(rating) as stars
from reviews
group by comic_id
) as foo
where comic_book.comic_id = foo.comic_id;
end;
$$
language plpgsql;
commit;
