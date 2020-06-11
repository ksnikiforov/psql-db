import random
genre = ['Drama', 'Comedy', 'Adventure', 'Horror', 'School', 'University', 'Fantasy', 'Sci-Fi',
        'Science', 'Fighting', 'Romance', 'Animals']

def gen():
    for i in range(1, 401):
        print('insert into genre(genre, comic_id) values (\'{0}\', {1});'.format(genre[random.randint(0,10)], i))

            
gen()
