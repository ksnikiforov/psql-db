create or replace function top_by_genre(text) 
returns table(comic int, stars int)
as $$
begin
    return query
    select comic_book.comic_id, comic_book.rating
    from comic_book
    inner join (select comic_id from genre where genre = $1) as foo
    on comic_book.comic_id = foo.comic_id
    order by comic_book.rating desc;
end;
$$
language plpgsql;
