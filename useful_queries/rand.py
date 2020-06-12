import random
genre = ['Drama', 'Comedy', 'Adventure', 'Horror', 'School', 
         'University', 'Fantasy', 'Sci-Fi', 'Science', 
         'Fighting', 'Romance', 'Animals']

def gen():
    for i in range(200):
        print("insert into genre(genre, comic_id) values ('{0}', {1}) on conflict "
              "(genre, comic_id) DO NOTHING;".format(random.choice(genre), random.randint(1, 400)))

            
gen()
