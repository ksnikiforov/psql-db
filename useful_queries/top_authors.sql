select author_id, ceil(avg(rating)) as avg_rating from(    
    select author_book.author_id, comic_book.comic_id, comic_book.rating 
    from 
    comic_book inner join author_book on comic_book.comic_id=author_book.comic_id 
    group by author_book.author_id, comic_book.comic_id 
    order by author_book.author_id asc
) as foo
group by author_id
order by avg_rating desc 
limit 10;
