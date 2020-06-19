CREATE OR REPLACE FUNCTION public.top_by_genre(VARIADIC arr text[])
 RETURNS TABLE(id integer, comic text, stars integer)
 LANGUAGE plpgsql
AS $function$
begin
    return query
    select comic_book.comic_id, comic_book.title, comic_book.rating
    from comic_book
    inner join (select comic_id from genre where genre = ANY($1)
                GROUP BY comic_id
                HAVING count(*) = cardinality($1)) as foo
    on comic_book.comic_id = foo.comic_id
    order by comic_book.rating desc;
end;
$function$