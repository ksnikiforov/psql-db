import csv 
with open('story_export_20200611.csv') as f:
    stories = csv.reader(f, delimiter=',')
    i = 1
    for row in stories:
        if i <= 400:
            row = row[1]
            row = row.replace('\'','')
            print('update comic_book set title = \'%s\' where comic_id = %s;' % (row,i))
            i += 1
