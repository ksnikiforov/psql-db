--
-- PostgreSQL database dump
--

-- Dumped from database version 12.3
-- Dumped by pg_dump version 12.3

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- Name: change_stock(); Type: FUNCTION; Schema: public; Owner: kirill
--

CREATE FUNCTION public.change_stock() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
DECLARE
		st integer;
BEGIN
    SELECT stock from comic_book where NEW.book_id=comic_id
    INTO st;

		IF st <= 0 THEN
    		RAISE EXCEPTION 'Item selected is not available';
    ELSIF st < NEW.quanity THEN
    		RAISE EXCEPTION 'Selected quanity is more than available';
    ELSE
    		UPDATE comic_book SET stock = stock-NEW.quanity WHERE comic_id=NEW.book_id;
        RETURN NEW;
    END IF;
END;
$$;


ALTER FUNCTION public.change_stock() OWNER TO kirill;

--
-- Name: check_purchase(); Type: FUNCTION; Schema: public; Owner: kirill
--

CREATE FUNCTION public.check_purchase() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
DECLARE
		cond bool;
BEGIN
    SELECT NEW.comic_id IN (SELECT pb.book_id from customers as c, purchase as p, purchased_book as pb
                            WHERE c.customer_id=NEW.customer_id
                            AND c.customer_id=p.customer_id
                            AND p.purchase_id=pb.purchase_id
                           	AND p.status='delivered')
    INTO cond;
    
		IF NOT cond THEN
    		RAISE EXCEPTION 'Users can not leave reviews without confirmed purchase';
    ELSE
    		RETURN NEW;
    END IF;
END;
$$;


ALTER FUNCTION public.check_purchase() OWNER TO kirill;

--
-- Name: rating_recalculation(); Type: FUNCTION; Schema: public; Owner: kirill
--

CREATE FUNCTION public.rating_recalculation() RETURNS void
    LANGUAGE plpgsql
    AS $$
begin
update comic_book
set rating = stars from(
select comic_id, avg(rating) as stars
from reviews
group by comic_id
) as foo
where comic_book.comic_id = foo.comic_id;
end;
$$;


ALTER FUNCTION public.rating_recalculation() OWNER TO kirill;

--
-- Name: status_update(); Type: FUNCTION; Schema: public; Owner: kirill
--

CREATE FUNCTION public.status_update() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    IF NEW.status != OLD.status OR (TG_OP = 'INSERT') THEN
        INSERT INTO log (time, description, purchase_id) VALUES (CURRENT_TIMESTAMP, NEW.status, NEW.purchase_id);
        IF NEW.status = 'canceled' THEN
            CREATE TEMP TABLE tabletemp (id integer, quanity integer);
            INSERT INTO tabletemp
            SELECT pb.book_id, quanity FROM purchase as p, purchased_book as pb
            WHERE p.purchase_id = pb.purchase_id
            AND customer_id = NEW.customer_id;
            
            UPDATE comic_book as cb
            SET stock = (stock+quanity)
            FROM tabletemp
            WHERE cb.comic_id = tabletemp.id;
            DROP TABLE tabletemp;
        END IF;
    END IF;
RETURN NULL;
END;
$$;


ALTER FUNCTION public.status_update() OWNER TO kirill;

--
-- Name: top_authors(integer, integer, text); Type: FUNCTION; Schema: public; Owner: kirill
--

CREATE FUNCTION public.top_authors(book_num integer, lim integer, genre text DEFAULT ''::text) RETURNS TABLE(author_id integer, author_name text, author_surname text, average_rating numeric)
    LANGUAGE plpgsql
    AS $_$
BEGIN
    RETURN QUERY
    select foo.author_id, name, surname, avg_rating from (    
        select author_book.author_id, ceil(avg(rating)) as avg_rating 
        from comic_book, author_book
        where comic_book.comic_id=author_book.comic_id
      	and ($3 = ''
        or comic_book.comic_id in (select comic_book.comic_id from comic_book, genre
                                    where $3=genre.genre
                                    and comic_book.comic_id=genre.comic_id))
        group by author_book.author_id
        having count(comic_book.comic_id) >= $1
        order by author_book.author_id asc
    ) as foo, authors
    where foo.author_id = authors.author_id
    order by avg_rating desc 
    limit $2;
end;
$_$;


ALTER FUNCTION public.top_authors(book_num integer, lim integer, genre text) OWNER TO kirill;

--
-- Name: top_by_genre(text); Type: FUNCTION; Schema: public; Owner: kirill
--

CREATE FUNCTION public.top_by_genre(text) RETURNS TABLE(comic text, stars integer)
    LANGUAGE plpgsql
    AS $_$
begin
    return query
    select comic_book.title, comic_book.rating
    from comic_book
    inner join (select comic_id from genre where genre = $1) as foo
    on comic_book.comic_id = foo.comic_id
    order by comic_book.rating desc;
end;
$_$;


ALTER FUNCTION public.top_by_genre(text) OWNER TO kirill;

SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: author_book; Type: TABLE; Schema: public; Owner: kirill
--

CREATE TABLE public.author_book (
    author_id integer NOT NULL,
    comic_id integer NOT NULL
);


ALTER TABLE public.author_book OWNER TO kirill;

--
-- Name: authors; Type: TABLE; Schema: public; Owner: kirill
--

CREATE TABLE public.authors (
    author_id integer NOT NULL,
    name text NOT NULL,
    surname text
);


ALTER TABLE public.authors OWNER TO kirill;

--
-- Name: authors_id_seq; Type: SEQUENCE; Schema: public; Owner: kirill
--

CREATE SEQUENCE public.authors_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.authors_id_seq OWNER TO kirill;

--
-- Name: authors_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: kirill
--

ALTER SEQUENCE public.authors_id_seq OWNED BY public.authors.author_id;


--
-- Name: comic_book; Type: TABLE; Schema: public; Owner: kirill
--

CREATE TABLE public.comic_book (
    comic_id integer NOT NULL,
    rating integer,
    stock integer NOT NULL,
    description text NOT NULL,
    price money NOT NULL,
    release_date date NOT NULL,
    series_id integer,
    publisher_id integer,
    title text,
    CONSTRAINT comic_book_price_check CHECK (((price)::numeric >= (0)::numeric)),
    CONSTRAINT comic_book_rating_check CHECK (((0 <= rating) AND (rating <= 10)))
);


ALTER TABLE public.comic_book OWNER TO kirill;

--
-- Name: comic_book_id_seq; Type: SEQUENCE; Schema: public; Owner: kirill
--

CREATE SEQUENCE public.comic_book_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.comic_book_id_seq OWNER TO kirill;

--
-- Name: comic_book_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: kirill
--

ALTER SEQUENCE public.comic_book_id_seq OWNED BY public.comic_book.comic_id;


--
-- Name: customers; Type: TABLE; Schema: public; Owner: kirill
--

CREATE TABLE public.customers (
    customer_id integer NOT NULL,
    name text NOT NULL,
    email text,
    phone text NOT NULL
);


ALTER TABLE public.customers OWNER TO kirill;

--
-- Name: customer_id_seq; Type: SEQUENCE; Schema: public; Owner: kirill
--

CREATE SEQUENCE public.customer_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.customer_id_seq OWNER TO kirill;

--
-- Name: customer_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: kirill
--

ALTER SEQUENCE public.customer_id_seq OWNED BY public.customers.customer_id;


--
-- Name: employee; Type: TABLE; Schema: public; Owner: kirill
--

CREATE TABLE public.employee (
    emp_id integer NOT NULL,
    name text NOT NULL,
    surname text,
    phone text
);


ALTER TABLE public.employee OWNER TO kirill;

--
-- Name: employee_id_seq; Type: SEQUENCE; Schema: public; Owner: kirill
--

CREATE SEQUENCE public.employee_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.employee_id_seq OWNER TO kirill;

--
-- Name: employee_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: kirill
--

ALTER SEQUENCE public.employee_id_seq OWNED BY public.employee.emp_id;


--
-- Name: genre; Type: TABLE; Schema: public; Owner: kirill
--

CREATE TABLE public.genre (
    genre text NOT NULL,
    comic_id integer NOT NULL
);


ALTER TABLE public.genre OWNER TO kirill;

--
-- Name: images; Type: TABLE; Schema: public; Owner: kirill
--

CREATE TABLE public.images (
    id integer NOT NULL,
    comic_id integer NOT NULL,
    img_path text,
    img_name text NOT NULL
);


ALTER TABLE public.images OWNER TO kirill;

--
-- Name: images_id_seq; Type: SEQUENCE; Schema: public; Owner: kirill
--

CREATE SEQUENCE public.images_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.images_id_seq OWNER TO kirill;

--
-- Name: images_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: kirill
--

ALTER SEQUENCE public.images_id_seq OWNED BY public.images.id;


--
-- Name: log; Type: TABLE; Schema: public; Owner: kirill
--

CREATE TABLE public.log (
    "time" timestamp without time zone NOT NULL,
    description text,
    purchase_id integer
);


ALTER TABLE public.log OWNER TO kirill;

--
-- Name: publishers; Type: TABLE; Schema: public; Owner: kirill
--

CREATE TABLE public.publishers (
    publisher_id integer NOT NULL,
    name text NOT NULL
);


ALTER TABLE public.publishers OWNER TO kirill;

--
-- Name: publishers_id_seq; Type: SEQUENCE; Schema: public; Owner: kirill
--

CREATE SEQUENCE public.publishers_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.publishers_id_seq OWNER TO kirill;

--
-- Name: publishers_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: kirill
--

ALTER SEQUENCE public.publishers_id_seq OWNED BY public.publishers.publisher_id;


--
-- Name: purchase; Type: TABLE; Schema: public; Owner: kirill
--

CREATE TABLE public.purchase (
    purchase_id integer NOT NULL,
    date timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    price money NOT NULL,
    customer_id integer NOT NULL,
    employee_id integer,
    status text NOT NULL,
    CONSTRAINT purchase_price_check CHECK (((price)::numeric >= (0)::numeric)),
    CONSTRAINT purchase_status_check CHECK (((status = 'paid'::text) OR (status = 'in progress'::text) OR (status = 'delivered'::text) OR (status = 'canceled'::text)))
);


ALTER TABLE public.purchase OWNER TO kirill;

--
-- Name: purchase_id_seq; Type: SEQUENCE; Schema: public; Owner: kirill
--

CREATE SEQUENCE public.purchase_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.purchase_id_seq OWNER TO kirill;

--
-- Name: purchase_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: kirill
--

ALTER SEQUENCE public.purchase_id_seq OWNED BY public.purchase.purchase_id;


--
-- Name: purchased_book; Type: TABLE; Schema: public; Owner: kirill
--

CREATE TABLE public.purchased_book (
    book_id integer NOT NULL,
    purchase_id integer NOT NULL,
    quanity integer NOT NULL
);


ALTER TABLE public.purchased_book OWNER TO kirill;

--
-- Name: reviews; Type: TABLE; Schema: public; Owner: kirill
--

CREATE TABLE public.reviews (
    review_id integer NOT NULL,
    comic_id integer NOT NULL,
    customer_id integer NOT NULL,
    rating integer NOT NULL,
    overall text,
    pros text,
    cons text,
    date timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    CONSTRAINT reviews_check CHECK ((((overall IS NOT NULL) AND (pros IS NOT NULL) AND (cons IS NOT NULL)) OR ((overall IS NULL) AND (pros IS NULL) AND (cons IS NULL)))),
    CONSTRAINT reviews_rating_check CHECK (((0 <= rating) AND (rating <= 10)))
);


ALTER TABLE public.reviews OWNER TO kirill;

--
-- Name: reviews_id_seq; Type: SEQUENCE; Schema: public; Owner: kirill
--

CREATE SEQUENCE public.reviews_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.reviews_id_seq OWNER TO kirill;

--
-- Name: reviews_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: kirill
--

ALTER SEQUENCE public.reviews_id_seq OWNED BY public.reviews.review_id;


--
-- Name: series; Type: TABLE; Schema: public; Owner: kirill
--

CREATE TABLE public.series (
    series_id integer NOT NULL,
    name text NOT NULL,
    release_date date NOT NULL,
    is_finished boolean NOT NULL
);


ALTER TABLE public.series OWNER TO kirill;

--
-- Name: series_id_seq; Type: SEQUENCE; Schema: public; Owner: kirill
--

CREATE SEQUENCE public.series_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.series_id_seq OWNER TO kirill;

--
-- Name: series_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: kirill
--

ALTER SEQUENCE public.series_id_seq OWNED BY public.series.series_id;


--
-- Name: authors author_id; Type: DEFAULT; Schema: public; Owner: kirill
--

ALTER TABLE ONLY public.authors ALTER COLUMN author_id SET DEFAULT nextval('public.authors_id_seq'::regclass);


--
-- Name: comic_book comic_id; Type: DEFAULT; Schema: public; Owner: kirill
--

ALTER TABLE ONLY public.comic_book ALTER COLUMN comic_id SET DEFAULT nextval('public.comic_book_id_seq'::regclass);


--
-- Name: customers customer_id; Type: DEFAULT; Schema: public; Owner: kirill
--

ALTER TABLE ONLY public.customers ALTER COLUMN customer_id SET DEFAULT nextval('public.customer_id_seq'::regclass);


--
-- Name: employee emp_id; Type: DEFAULT; Schema: public; Owner: kirill
--

ALTER TABLE ONLY public.employee ALTER COLUMN emp_id SET DEFAULT nextval('public.employee_id_seq'::regclass);


--
-- Name: images id; Type: DEFAULT; Schema: public; Owner: kirill
--

ALTER TABLE ONLY public.images ALTER COLUMN id SET DEFAULT nextval('public.images_id_seq'::regclass);


--
-- Name: publishers publisher_id; Type: DEFAULT; Schema: public; Owner: kirill
--

ALTER TABLE ONLY public.publishers ALTER COLUMN publisher_id SET DEFAULT nextval('public.publishers_id_seq'::regclass);


--
-- Name: purchase purchase_id; Type: DEFAULT; Schema: public; Owner: kirill
--

ALTER TABLE ONLY public.purchase ALTER COLUMN purchase_id SET DEFAULT nextval('public.purchase_id_seq'::regclass);


--
-- Name: reviews review_id; Type: DEFAULT; Schema: public; Owner: kirill
--

ALTER TABLE ONLY public.reviews ALTER COLUMN review_id SET DEFAULT nextval('public.reviews_id_seq'::regclass);


--
-- Name: series series_id; Type: DEFAULT; Schema: public; Owner: kirill
--

ALTER TABLE ONLY public.series ALTER COLUMN series_id SET DEFAULT nextval('public.series_id_seq'::regclass);


--
-- Data for Name: author_book; Type: TABLE DATA; Schema: public; Owner: kirill
--

COPY public.author_book (author_id, comic_id) FROM stdin;
56	361
37	119
70	14
76	368
38	12
5	99
52	380
65	207
44	263
46	358
98	6
60	46
59	397
79	114
22	320
4	96
50	105
10	388
10	220
90	12
70	237
35	104
23	317
96	156
64	34
90	105
21	266
12	274
38	2
59	179
1	15
34	331
24	290
79	72
21	37
50	36
41	241
85	3
81	350
100	134
1	252
87	179
11	288
91	194
19	256
82	282
71	390
67	41
10	272
12	16
18	47
12	75
72	143
62	328
100	324
49	335
43	182
68	262
18	326
62	295
37	261
94	295
20	26
16	388
96	33
53	31
69	145
74	16
12	349
4	242
68	237
27	270
40	120
99	186
49	349
51	276
38	306
19	168
90	335
1	50
89	89
69	20
80	295
96	87
32	117
57	146
19	8
63	10
81	154
41	170
24	316
90	345
11	189
51	17
59	111
39	231
67	8
50	222
63	50
27	188
77	67
65	373
53	63
16	14
6	266
23	9
57	398
82	223
18	374
18	384
93	360
74	44
96	292
27	177
19	257
90	116
39	142
12	27
14	165
19	170
35	123
13	330
27	395
63	79
25	118
94	109
89	298
25	157
32	280
24	118
17	291
12	115
90	337
77	123
43	40
81	103
24	248
93	381
2	332
34	215
42	28
53	202
84	86
59	358
88	393
18	15
37	114
16	130
50	193
53	341
74	310
22	201
71	38
79	270
98	119
92	353
8	218
90	83
77	282
21	379
47	156
32	3
48	47
64	265
21	374
57	61
1	113
67	20
27	162
89	291
96	254
73	79
79	267
97	389
88	304
92	187
47	120
41	101
34	17
30	18
52	117
41	157
52	254
24	87
16	378
95	302
26	374
16	58
16	156
29	55
35	126
48	152
1	282
31	387
11	333
49	238
65	178
80	195
9	347
30	299
41	172
94	365
4	289
21	193
77	36
70	201
20	134
32	334
70	395
44	208
63	27
72	266
31	232
62	396
84	350
55	78
50	244
64	317
69	213
75	392
91	311
40	380
11	261
66	87
13	265
16	212
42	116
97	331
18	77
64	360
37	159
11	398
63	51
31	365
69	293
93	198
26	400
45	97
41	284
88	229
32	286
82	309
50	302
51	299
54	355
100	379
80	121
86	257
76	342
60	142
9	95
95	254
51	150
88	117
73	204
92	236
86	378
80	220
11	346
41	282
10	90
75	274
34	332
16	7
14	244
35	87
73	276
65	81
94	159
55	127
97	285
82	370
7	142
69	65
43	390
7	284
5	291
87	241
60	253
65	73
62	64
60	88
77	112
58	282
94	249
74	339
79	237
21	30
40	50
98	46
5	394
81	388
25	251
73	64
83	393
98	47
16	229
100	39
10	278
96	346
44	222
27	192
89	149
15	320
22	386
20	355
76	280
23	101
53	172
85	111
12	226
46	326
90	362
55	338
22	283
88	191
3	157
64	3
80	327
86	367
48	129
76	362
5	20
61	210
71	18
89	334
3	59
100	181
36	16
82	286
76	288
33	112
7	62
38	83
36	13
33	392
33	398
48	156
23	311
50	216
73	10
13	108
9	43
54	148
18	394
96	53
23	186
48	72
32	283
29	290
23	203
19	213
83	152
15	83
34	185
14	93
61	211
92	356
98	278
92	41
50	171
33	217
76	45
90	159
12	188
79	396
9	77
100	318
36	323
23	194
40	224
20	180
57	111
44	11
96	99
62	275
96	392
3	41
87	70
63	198
36	345
56	209
90	309
31	95
80	202
32	363
29	250
82	303
86	361
15	280
16	396
90	342
46	213
11	58
3	242
70	311
100	377
96	317
88	174
51	120
49	122
43	312
29	323
74	381
32	210
4	133
8	369
39	278
27	299
41	129
94	123
81	229
38	232
39	299
5	33
72	160
66	82
90	194
93	295
63	370
30	362
41	287
86	304
83	202
77	37
24	167
40	308
70	296
62	233
14	393
80	161
96	128
74	127
55	250
79	311
16	363
36	291
100	120
45	54
68	294
86	164
10	37
52	238
7	353
29	13
39	69
61	342
94	308
57	388
61	372
70	140
44	161
78	106
99	348
49	312
70	240
90	296
27	76
87	376
80	318
89	177
53	400
86	60
27	234
18	272
58	346
68	223
22	302
71	344
59	106
63	354
26	337
45	334
27	71
51	142
31	58
9	336
12	197
41	131
3	107
16	102
57	155
75	113
45	358
67	107
2	384
12	241
19	49
46	291
17	157
96	328
45	18
58	350
55	371
81	86
56	247
35	35
23	284
77	373
11	81
93	373
70	305
56	351
65	21
82	78
24	293
25	185
65	24
75	116
69	15
11	254
89	33
54	298
31	376
39	7
22	336
33	324
100	32
48	218
65	28
77	394
62	251
88	373
80	44
56	16
69	266
74	22
41	260
52	216
73	162
34	317
7	327
35	336
78	39
64	203
7	158
49	51
8	69
56	218
80	166
\.


--
-- Data for Name: authors; Type: TABLE DATA; Schema: public; Owner: kirill
--

COPY public.authors (author_id, name, surname) FROM stdin;
1	Morgan	Ayers
2	Lyle	Mccullough
3	Nerea	Fernandez
4	Hadley	Ware
5	Cade	Pittman
6	Guy	Solis
7	Dean	Eaton
8	Tatyana	Pennington
9	Blaze	David
10	Dorian	Solomon
11	Jorden	Larson
12	Lucas	Nichols
13	Felix	Pittman
14	Connor	Oneil
15	Baker	Collier
16	Yen	Bullock
17	Len	Salinas
18	Megan	Rush
19	Nigel	Donovan
20	Jared	Austin
21	Alma	Dejesus
22	Malachi	Andrews
23	Katell	Delacruz
24	Reece	Blevins
25	Ulysses	Valencia
26	Lester	Holman
27	Roth	Snyder
28	Amelia	Barlow
29	Reece	Oneal
30	Sydney	Oneal
31	Malik	Thomas
32	Merrill	Ballard
33	Paki	Stout
34	Plato	Peters
35	Ursa	Barber
36	Noel	Savage
37	Odette	Sweet
38	Dalton	Holloway
39	Yolanda	Sharpe
40	Abra	Clay
41	Edan	Bullock
42	Olivia	Harding
43	Lana	Gomez
44	Rudyard	Wyatt
45	Courtney	Richardson
46	Doris	Guy
47	Germane	Shaffer
48	Griffith	Rowe
49	Hillary	Newton
50	Martha	Stone
51	Bradley	Allen
52	Yvonne	Bailey
53	Hu	Weaver
54	Yoshio	Becker
55	Frances	Paul
56	Garrison	Freeman
57	Dominic	Ballard
58	Damon	Gross
59	Ayanna	Bowen
60	Wynter	Houston
61	Armand	Cox
62	Paloma	Gross
63	Josiah	Roth
64	September	Nelson
65	Sopoline	Keller
66	Brian	Rasmussen
67	Warren	Nicholson
68	Yoshio	Buckley
69	Chaney	Mclean
70	Keith	Rollins
71	Justin	Haley
72	Portia	Bell
73	Kendall	Combs
74	Kennan	Randolph
75	Valentine	Douglas
76	Chaney	Valdez
77	Randall	Long
78	Madison	Stephens
79	Demetrius	Williamson
80	Marny	Richardson
81	Marny	Ford
82	Larissa	Wong
83	Myles	Bullock
84	Gray	Chen
85	Ishmael	Guzman
86	Angelica	Ball
87	Madeson	Mooney
88	Veronica	Fischer
89	Kirk	Mcleod
90	Emerson	Bradford
91	Hermione	Cardenas
92	Aspen	Norris
93	Heidi	Oneal
94	Amena	Salazar
95	Priscilla	Crosby
96	Chastity	Carroll
97	Dante	French
98	Mira	Castro
99	Kathleen	Burnett
100	August	Hansen
\.


--
-- Data for Name: comic_book; Type: TABLE DATA; Schema: public; Owner: kirill
--

COPY public.comic_book (comic_id, rating, stock, description, price, release_date, series_id, publisher_id, title) FROM stdin;
55	1	822	amet nulla. Donec non justo. Proin	$54.91	1947-02-24	8	23	100 Bullets #21 cover
58	3	280	et, commodo at, libero. Morbi accumsan laoreet ipsum. Curabitur consequat, lectus sit amet luctus vulputate,	$18.39	1963-11-17	9	44	In Stinked Part Two
68	2	445	risus odio, auctor vitae, aliquet nec, imperdiet nec, leo. Morbi neque tellus, imperdiet non,	$58.27	1968-08-16	1	75	La Cinta 1 de 2
78	3	174	in, tempus eu, ligula. Aenean euismod mauris eu elit. Nulla facilisi. Sed neque. Sed eget	$33.80	1995-01-07	4	72	The Menace of Aqualad!
90	5	163	malesuada fames ac turpis egestas. Fusce aliquet magna a neque. Nullam ut nisi a odio	$69.69	1936-02-25	7	15	Epic Moments In International Relations
100	4	232	massa. Suspendisse eleifend. Cras sed leo. Cras vehicula aliquet libero.	$95.44	1955-04-01	1	60	Go Vest, Young Man
113	2	755	Duis risus odio, auctor vitae, aliquet nec, imperdiet nec, leo. Morbi neque	$12.46	1948-08-03	9	2	Revenge (a.k.a. Four Dark Judges)
118	5	876	metus. Aenean sed pede nec ante blandit viverra. Donec	$50.85	2001-05-04	9	63	1981 Is the Year of the Alien!
124	8	923	imperdiet non, vestibulum nec, euismod in, dolor. Fusce feugiat. Lorem ipsum dolor sit amet,	$98.93	1958-11-09	7	79	Zombie Beat!
165	10	516	pede blandit congue. In scelerisque scelerisque dui. Suspendisse ac metus vitae	$9.93	1981-05-24	3	32	Book 10 The Märze Murderer Part 6
173	7	619	mauris sagittis placerat. Cras dictum ultricies ligula. Nullam enim. Sed nulla ante, iaculis	$15.17	1931-10-09	8	44	Part Eight
285	3	0	vitae aliquam eros turpis non enim. Mauris quis turpis vitae purus gravida sagittis. Duis	$98.47	2010-05-31	10	45	In the Realm of Pyrrhus Part Five
384	1	124	magna. Duis dignissim tempor arcu. Vestibulum ut eros non enim commodo hendrerit. Donec porttitor tellus	$79.53	1956-07-26	3	48	The Kryptonite Man!
396	5	895	risus. Donec nibh enim, gravida sit amet, dapibus id, blandit at,	$98.98	2011-06-05	7	18	A Tale of Two Brothers
35	8	19	ut odio vel est tempor bibendum. Donec felis orci, adipiscing non, luctus	$21.41	1994-08-03	5	73	Parlez Kung Vous Conclusion
36	10	904	lacus. Cras interdum. Nunc sollicitudin commodo ipsum. Suspendisse non leo.	$79.03	1955-12-22	5	80	Hang Up on the Hang Low Part One
39	6	631	Integer sem elit, pharetra ut, pharetra sed, hendrerit a,	$82.51	1978-07-15	3	13	Hang Up on the Hang Low, Conclusion
40	1	73	dolor. Fusce feugiat. Lorem ipsum dolor sit amet, consectetuer adipiscing elit. Aliquam auctor, velit	$46.09	1972-12-12	1	69	The Mimic
41	5	114	erat neque non quam. Pellentesque habitant morbi tristique senectus et netus et malesuada fames	$25.70	1981-06-12	6	57	Loser
45	6	600	Etiam laoreet, libero et tristique pellentesque, tellus sem mollis dui, in sodales	$44.28	1943-06-21	3	40	In Stinked Part One
46	7	973	Nunc mauris sapien, cursus in, hendrerit consectetuer, cursus et, magna. Praesent interdum	$4.17	1956-09-22	7	98	In Stinked Part Two
49	10	262	Proin dolor. Nulla semper tellus id nunc interdum feugiat. Sed nec metus	$15.86	1943-06-06	10	80	Punch Line Part Two
50	1	221	Fusce aliquet magna a neque. Nullam ut nisi	$87.70	1984-11-27	6	66	Hang Up on the Hang Low Conclusion
52	2	776	risus varius orci, in consequat enim diam vel arcu. Curabitur ut odio vel est	$90.99	1987-06-13	6	64	Hang Up on the Hang Low Part Two
54	8	963	iaculis quis, pede. Praesent eu dui. Cum sociis natoque penatibus et magnis dis	$7.31	1976-06-30	1	5	Idol Chatter
128	6	521	egestas, urna justo faucibus lectus, a sollicitudin orci sem eget massa. Suspendisse eleifend. Cras	$29.32	1986-01-21	10	27	Account Yorga-Vampire Part 2
155	9	749	tempus mauris erat eget ipsum. Suspendisse sagittis. Nullam vitae diam. Proin dolor. Nulla	$16.72	1954-10-06	1	34	Hunted Part Three
8	8	910	consequat, lectus sit amet luctus vulputate, nisi sem semper	$32.26	2003-09-13	5	14	Caricature Sculpture
10	2	467	euismod et, commodo at, libero.	$3.49	1963-09-04	10	16	International
11	2	670	fringilla ornare placerat, orci lacus vestibulum lorem, sit amet ultricies sem	$7.80	2016-05-01	10	20	Energy
21	5	620	Mauris blandit enim consequat purus. Maecenas libero est, congue a, aliquet vel, vulputate	$24.26	2009-05-24	6	99	Notes from the World
24	1	563	dis parturient montes, nascetur ridiculus mus. Proin vel arcu eu odio tristique pharetra.	$88.18	1976-03-14	9	81	Operación Riesgo
25	3	973	lacus. Mauris non dui nec urna suscipit nonummy. Fusce fermentum fermentum arcu. Vestibulum	$30.79	2004-05-16	5	82	Parlez kung vous [parte 1]
26	1	749	lorem, auctor quis, tristique ac, eleifend vitae, erat. Vivamus nisi. Mauris	$80.37	1960-02-22	1	21	Parlez kung vous, Conclusion
27	5	160	a, malesuada id, erat. Etiam vestibulum massa rutrum magna. Cras convallis convallis	$27.14	2007-09-27	10	32	O ídolo tagarela!
29	5	144	non, egestas a, dui. Cras pellentesque. Sed dictum.	$24.01	1963-02-25	10	68	Graves
30	6	292	mattis. Integer eu lacus. Quisque imperdiet, erat	$7.89	2018-03-19	6	79	Jaula fedida: Parte três
32	6	204	elit, a feugiat tellus lorem eu metus. In lorem. Donec	$40.10	1971-01-07	10	39	100 Bullets #83
249	6	216	dui. Cum sociis natoque penatibus et magnis dis parturient montes, nascetur ridiculus mus. Aenean eget	$37.15	1990-10-03	5	62	Engine Summer Part 9
262	1	315	ligula elit, pretium et, rutrum non, hendrerit id, ante. Nunc mauris sapien, cursus	$72.29	1989-07-09	9	82	Memories Are Made of This
274	6	76	vitae, posuere at, velit. Cras lorem lorem, luctus ut,	$70.48	1936-04-05	5	78	The Son Part Three
289	7	937	turpis egestas. Fusce aliquet magna a neque. Nullam ut nisi a odio semper cursus.	$43.20	1956-02-12	3	10	The Son Part Six
296	5	897	vitae odio sagittis semper. Nam tempor diam dictum sapien.	$97.01	2007-03-04	8	25	The Gangbusters Chapter Two: Death From Above!
92	7	88	magna. Nam ligula elit, pretium et, rutrum non, hendrerit id, ante.	$94.88	1993-05-18	3	68	Come On In, the Waters Cold
94	8	576	leo, in lobortis tellus justo sit amet nulla. Donec	$84.89	1934-03-28	9	2	And Away We Go! Jackie Gleason
97	4	993	quam a felis ullamcorper viverra. Maecenas iaculis aliquet diam. Sed diam lorem,	$85.84	1963-05-29	5	69	The Morris Theory of Musical Shapes
101	2	82	erat, in consectetuer ipsum nunc	$94.57	1955-08-20	10	14	Sinbad and the City of the Dead Part Two
102	5	724	magna. Suspendisse tristique neque venenatis lacus. Etiam bibendum fermentum metus.	$26.77	1957-05-19	5	95	An Exciting War Story
117	9	676	faucibus. Morbi vehicula. Pellentesque tincidunt tempus risus. Donec egestas.	$62.68	1993-02-19	8	32	Everest [Part 2]
129	6	65	Quisque varius. Nam porttitor scelerisque neque. Nullam nisl. Maecenas malesuada fringilla est. Mauris	$92.71	2010-04-19	10	100	Case Eight: Worlds at War
187	3	225	pharetra. Nam ac nulla. In tincidunt congue turpis. In condimentum. Donec	$58.77	1948-01-21	9	8	Life on Earth
198	8	292	purus mauris a nunc. In at pede. Cras vulputate velit eu sem. Pellentesque	$88.23	1934-01-29	3	48	Last Breath
209	6	189	porttitor tellus non magna. Nam ligula elit, pretium et, rutrum non, hendrerit id, ante.	$1.54	1953-01-23	10	36	War Buds Part One
218	4	968	sed orci lobortis augue scelerisque mollis.	$93.78	1987-03-01	3	81	War Buds Part Three
307	7	21	Aliquam erat volutpat. Nulla dignissim. Maecenas ornare egestas ligula. Nullam feugiat placerat velit. Quisque	$36.00	1972-08-29	2	33	The Big Empty
324	1	773	Donec vitae erat vel pede blandit congue. In scelerisque scelerisque dui. Suspendisse	$85.73	1933-02-28	4	39	Beowulf Storms The Gates In October
63	2	230	Morbi metus. Vivamus euismod urna.	$25.24	1996-08-19	4	70	100 Bullets #27
65	4	546	sed dolor. Fusce mi lorem, vehicula et, rutrum eu, ultrices sit amet,	$69.17	1964-08-06	6	48	100 Degrees in the Shade Part IV
69	9	689	velit. Cras lorem lorem, luctus ut,	$17.91	1948-07-18	6	3	Desde el Infierno
73	1	563	Praesent luctus. Curabitur egestas nunc sed libero. Proin sed turpis nec mauris blandit mattis.	$0.78	1952-04-19	9	94	Summons to Paradise
74	3	528	Duis gravida. Praesent eu nulla at sem molestie sodales. Mauris blandit enim consequat purus.	$7.31	1936-06-27	9	15	Introducing Stretch Skinner
77	3	694	ridiculus mus. Proin vel nisl. Quisque fringilla euismod enim. Etiam gravida molestie arcu. Sed eu	$64.49	1977-10-11	10	6	Nostradamus Predicts
81	8	90	In tincidunt congue turpis. In condimentum. Donec at	$41.01	1963-05-07	9	10	The Trial of Superboy
82	1	951	sed libero. Proin sed turpis nec mauris blandit	$91.56	1957-06-01	2	23	The Boy of the Year Contest
83	6	905	erat vel pede blandit congue. In scelerisque scelerisque dui. Suspendisse ac metus vitae	$85.22	1999-05-14	7	63	Battle Doll!
86	7	470	Nam ligula elit, pretium et, rutrum non, hendrerit id, ante. Nunc	$85.19	2004-10-10	3	11	[The Injustice Society of the World!] Chapter 2
107	1	250	mauris sit amet lorem semper auctor. Mauris vel turpis. Aliquam adipiscing	$16.26	2006-11-03	3	47	Chapter One: Tyranny in Timely
108	1	777	Sed pharetra, felis eget varius ultrices, mauris ipsum porta elit, a feugiat	$80.82	1968-03-05	3	46	Resan till månen
110	10	672	Curae; Phasellus ornare. Fusce mollis. Duis sit amet diam eu dolor egestas rhoncus. Proin nisl	$55.33	1988-11-28	7	91	Code Name: Assassin
114	2	854	Cum sociis natoque penatibus et magnis dis parturient montes, nascetur ridiculus mus.	$82.78	2002-08-03	7	73	The Black Plague! (part 1)
223	7	683	dictum cursus. Nunc mauris elit, dictum eu, eleifend nec, malesuada ut,	$44.49	1967-10-26	2	89	Book 11 The Thousand Year Stare Part 3
224	5	544	eu, eleifend nec, malesuada ut, sem. Nulla interdum. Curabitur dictum. Phasellus in felis. Nulla	$79.97	1976-05-31	6	16	Fallout Part Three
232	7	995	malesuada vel, convallis in, cursus et, eros. Proin ultrices.	$51.14	2009-11-17	3	15	Book 11 The Thousand Year Stare Part 5
137	5	333	amet massa. Quisque porttitor eros nec	$40.51	1961-05-18	5	62	The Last Thing I Do (Part 6)
138	6	318	ipsum. Suspendisse non leo. Vivamus nibh dolor,	$17.91	1961-02-22	3	32	Fire and Ice
143	10	815	Vivamus euismod urna. Nullam lobortis quam a felis ullamcorper viverra. Maecenas iaculis aliquet diam.	$29.80	1990-07-06	8	65	And the Beast Shall Feast
144	5	500	molestie in, tempus eu, ligula.	$80.22	1951-12-19	8	68	A Wolfs Age
148	4	563	Quisque purus sapien, gravida non, sollicitudin	$56.83	2012-04-23	2	90	Book 10 The Märze Murderer Part 2
150	7	434	magnis dis parturient montes, nascetur ridiculus mus. Proin	$51.18	1982-07-11	10	34	Hunted Part Two
152	6	697	quam quis diam. Pellentesque habitant morbi tristique senectus et	$32.56	1985-07-18	10	57	Get Sin Part Two
154	6	579	Proin velit. Sed malesuada augue ut lacus. Nulla	$50.14	1979-09-22	3	90	Book 10 The Märze Murderer Part 3
156	4	426	id ante dictum cursus. Nunc mauris elit, dictum eu, eleifend nec,	$10.92	1943-03-10	4	31	Get Sin Part Three
158	8	913	odio, auctor vitae, aliquet nec, imperdiet nec, leo. Morbi neque tellus, imperdiet non,	$94.47	1948-05-20	1	64	Book 10 The Märze Murderer Part 4
161	2	545	odio a purus. Duis elementum, dui quis accumsan convallis,	$34.53	1966-08-16	5	7	Book 10 The Märze Murderer Part 5
162	1	698	dui. Fusce diam nunc, ullamcorper eu, euismod ac, fermentum vel, mauris. Integer sem elit,	$24.78	1980-09-08	10	84	Gorehead Part Four
172	2	752	molestie in, tempus eu, ligula. Aenean euismod mauris eu elit. Nulla facilisi. Sed	$49.53	2010-11-01	3	7	Gorehead Part Six
176	2	378	quis urna. Nunc quis arcu vel quam dignissim pharetra. Nam ac nulla. In tincidunt congue	$17.15	1983-01-04	8	44	Book 10 The Märze Murderer Part 8
238	9	340	non leo. Vivamus nibh dolor, nonummy ac, feugiat	$8.65	2003-03-23	5	66	The Shroud Part 2
122	8	830	ut, pellentesque eget, dictum placerat, augue. Sed molestie. Sed id risus quis	$47.88	1943-07-21	8	98	The Statutes of Liberty
123	7	597	eget lacus. Mauris non dui nec urna suscipit nonummy. Fusce	$91.94	1999-11-13	3	61	The Hateful Dead!
127	3	82	vitae risus. Duis a mi fringilla mi	$92.29	1933-12-25	1	18	Curse of the Spider Man
130	2	281	adipiscing elit. Etiam laoreet, libero et tristique	$82.33	2005-06-04	10	8	Scene Of The Crime
132	4	153	dictum ultricies ligula. Nullam enim. Sed nulla ante, iaculis nec, eleifend	$56.64	1972-05-20	5	1	Bison Part One
133	4	829	nec, diam. Duis mi enim, condimentum eget, volutpat ornare, facilisis eget, ipsum. Donec	$87.84	1996-04-29	4	3	Along Came a Spider! Arach Attack in Strontium Dog!
134	7	625	pede. Suspendisse dui. Fusce diam nunc, ullamcorper eu, euismod ac, fermentum vel, mauris. Integer	$64.53	1952-07-16	7	14	Road House Part two
135	2	127	arcu. Nunc mauris. Morbi non sapien molestie orci tincidunt adipiscing.	$86.54	2004-05-24	2	67	Vaped! Part two
136	6	631	mi fringilla mi lacinia mattis. Integer eu lacus. Quisque imperdiet, erat	$46.67	1960-10-11	4	4	What Lies Beneath Part One
178	9	503	et nunc. Quisque ornare tortor at	$34.55	1948-02-19	4	44	Hunted Part Eight
179	3	287	sit amet, consectetuer adipiscing elit. Curabitur sed tortor. Integer	$92.38	1973-01-19	10	13	Part Nine
182	2	935	libero. Proin sed turpis nec	$58.61	1960-05-07	7	84	Gorehead Part Eight
183	2	872	adipiscing fringilla, porttitor vulputate, posuere	$90.93	2018-07-20	5	20	Hunted Part Nine
185	9	261	dapibus id, blandit at, nisi. Cum sociis natoque	$31.62	1939-07-16	5	76	Diehards Part Fourteen
186	3	599	dignissim. Maecenas ornare egestas ligula. Nullam feugiat placerat velit.	$96.29	1997-03-27	6	48	Box-Office Bomb
188	10	965	Nunc mauris sapien, cursus in, hendrerit consectetuer, cursus et,	$9.63	1953-02-18	3	2	Skeleton Life Part 17
193	9	962	urna. Nunc quis arcu vel quam dignissim	$60.45	1970-01-05	10	20	Furies Part Seven
201	5	730	mauris. Morbi non sapien molestie orci tincidunt	$72.06	1982-02-22	1	47	Furies Part Ten
202	4	321	penatibus et magnis dis parturient montes, nascetur ridiculus mus. Donec dignissim magna	$83.45	1987-08-30	8	86	Ouroboros Part Three
204	5	731	neque. In ornare sagittis felis. Donec tempor, est ac	$78.33	2012-10-29	5	81	Inhuman Natures Part 2
205	7	775	ac libero nec ligula consectetuer rhoncus. Nullam velit dui, semper et, lacinia vitae,	$38.36	2016-09-17	8	12	Hope For the Future Part 7
206	5	623	leo. Morbi neque tellus, imperdiet non, vestibulum nec, euismod in,	$95.62	1940-10-02	7	6	Inhuman Natures Part 3
207	10	761	Aliquam tincidunt, nunc ac mattis ornare, lectus ante	$37.65	1953-03-27	2	72	Signal Six Twenty-Four Part Two
210	9	550	sit amet ultricies sem magna nec quam. Curabitur vel lectus. Cum sociis natoque penatibus	$49.24	1943-12-07	7	9	Hope For the Future Part 8
211	6	516	tempor lorem, eget mollis lectus pede	$71.45	1986-06-28	6	20	Inhuman Natures Part 4
217	3	753	sit amet, consectetuer adipiscing elit. Curabitur sed tortor. Integer aliquam	$23.30	1942-06-27	4	90	Foul Play Part Seven
219	4	669	Nullam feugiat placerat velit. Quisque varius. Nam	$38.26	1956-11-01	7	28	Foul Play Part Eight
220	3	997	dui quis accumsan convallis, ante lectus convallis	$3.14	1996-11-11	6	100	Hope For the Future Part 10
222	8	684	non nisi. Aenean eget metus. In nec orci. Donec nibh. Quisque nonummy ipsum non	$75.11	1952-12-10	5	87	Inhuman Natures Part 6
229	7	818	Aliquam tincidunt, nunc ac mattis ornare, lectus ante dictum	$39.00	1992-02-12	2	68	Book 11 The Thousand Year Stare Part 4
233	2	82	egestas a, dui. Cras pellentesque. Sed dictum. Proin eget odio. Aliquam vulputate ullamcorper magna. Sed	$38.09	1941-11-07	6	64	Fallout Part Five
235	9	585	accumsan neque et nunc. Quisque ornare tortor at	$9.13	1956-05-23	3	10	Terrorists Part 5
236	7	616	sed tortor. Integer aliquam adipiscing lacus. Ut nec urna et arcu imperdiet ullamcorper.	$83.86	2000-03-03	4	24	Engine Summer Part 5
237	1	135	elementum sem, vitae aliquam eros turpis non enim. Mauris quis turpis vitae purus gravida	$32.37	1992-08-09	9	44	Book 11 The Thousand Year Stare Part 6
244	10	488	Nulla dignissim. Maecenas ornare egestas ligula. Nullam	$50.35	1990-11-30	10	14	Engine Summer Part 7
245	5	714	sed pede nec ante blandit viverra. Donec tempus, lorem	$76.80	1996-07-27	6	31	Fallout Part Seven
246	8	393	dui quis accumsan convallis, ante	$19.31	1936-12-22	8	60	Live Evil Part 1
248	1	80	nulla. Integer vulputate, risus a ultricies adipiscing, enim mi tempor lorem, eget mollis	$20.02	1963-02-27	7	57	Terrorists Part Nine: The Third Law of Bad Company
252	9	910	ligula. Aenean euismod mauris eu elit. Nulla facilisi.	$9.76	1962-11-30	8	84	Fallout Part Eleven
255	8	285	fermentum metus. Aenean sed pede nec ante blandit viverra.	$41.88	2013-08-19	7	31	Live Evil Part 4
256	4	555	placerat, orci lacus vestibulum lorem, sit amet ultricies sem magna nec quam. Curabitur	$91.54	1949-09-27	2	92	Sunday Scientist
257	8	987	massa. Integer vitae nibh. Donec est	$91.15	1968-09-04	8	3	Terrorists Part 12
259	3	978	velit. Pellentesque ultricies dignissim lacus. Aliquam rutrum lorem ac risus. Morbi metus.	$45.66	1943-07-31	2	87	Undertow Part One
260	3	659	augue id ante dictum cursus. Nunc mauris elit, dictum eu, eleifend nec, malesuada ut,	$26.19	2006-12-25	9	15	In the Realm of Pyrrhus Part One
261	9	955	torquent per conubia nostra, per inceptos hymenaeos. Mauris ut quam vel sapien imperdiet ornare.	$99.09	1984-11-21	8	78	Fit for Purpose Part 1
264	5	526	Quisque libero lacus, varius et, euismod et, commodo at, libero. Morbi accumsan laoreet ipsum.	$68.11	1930-06-25	3	95	Freedom Wears Two Faces
266	9	279	Etiam laoreet, libero et tristique pellentesque, tellus	$37.51	1966-02-08	2	4	Undertow Part Two
271	1	108	convallis, ante lectus convallis est, vitae sodales nisi magna sed dui.	$62.84	2000-05-07	2	18	The Death Watch
272	5	322	sed leo. Cras vehicula aliquet libero. Integer in magna. Phasellus	$28.31	1979-09-15	8	68	In the Field of Battle
275	1	601	semper et, lacinia vitae, sodales at, velit. Pellentesque ultricies dignissim lacus. Aliquam rutrum lorem	$26.41	1982-05-13	8	80	The Devil Dont Care Part One
276	6	510	pede. Nunc sed orci lobortis augue scelerisque mollis. Phasellus libero mauris, aliquam	$5.06	1964-02-24	1	54	Undertow Part Four
277	5	63	facilisis, magna tellus faucibus leo, in lobortis tellus justo sit amet nulla.	$63.82	2016-03-22	8	75	Divide + Conquer!
279	5	111	quis arcu vel quam dignissim	$10.89	1973-04-21	5	72	The Devil Dont Care Part Two
281	2	857	lacinia. Sed congue, elit sed consequat auctor, nunc nulla vulputate dui, nec	$33.96	1959-10-08	1	78	The Son Part Five
282	10	152	rhoncus. Nullam velit dui, semper	$13.28	1946-12-09	10	1	Undertow Part Five
294	3	555	mollis. Duis sit amet diam eu dolor	$71.42	1955-11-08	8	37	Undertow Part Eight
298	7	336	vel est tempor bibendum. Donec	$73.68	1948-07-19	10	1	The Trouble With Gronkses
239	10	176	ante lectus convallis est, vitae sodales nisi magna sed	$11.53	1988-04-05	8	44	Terrorists Part 6
241	6	788	sapien, cursus in, hendrerit consectetuer, cursus et, magna. Praesent	$24.11	2003-06-27	6	14	Book 11 The Thousand Year Stare Part 7
303	3	172	nibh lacinia orci, consectetuer euismod est arcu ac orci. Ut semper pretium neque. Morbi quis	$67.26	1994-06-22	3	28	The Black Plague! (part 1)
304	5	563	est, mollis non, cursus non, egestas a,	$14.29	2013-02-02	1	75	Everest [Part 2]
305	1	272	id, erat. Etiam vestibulum massa rutrum magna. Cras convallis convallis dolor. Quisque tincidunt	$51.48	2010-10-19	9	24	Everest [Part 1]
306	5	98	nisi. Mauris nulla. Integer urna. Vivamus molestie dapibus ligula. Aliquam erat volutpat. Nulla dignissim. Maecenas	$20.43	1959-06-04	7	4	Fodder
242	10	221	ornare, elit elit fermentum risus,	$23.37	1985-06-23	8	49	The Shroud Part 3
308	6	761	vestibulum nec, euismod in, dolor. Fusce feugiat. Lorem ipsum dolor sit amet,	$84.51	1997-12-29	8	62	Juicemobiles
310	3	653	Mauris eu turpis. Nulla aliquet. Proin velit. Sed malesuada augue	$8.54	1980-08-08	7	12	Samenwerking op Links
318	8	58	elementum sem, vitae aliquam eros turpis non enim. Mauris quis turpis vitae	$22.73	2014-03-22	3	17	The Book Club
320	7	309	diam. Pellentesque habitant morbi tristique senectus et netus	$54.42	1986-02-01	10	48	Beowulf Storms The Gates In October
325	5	393	tellus. Phasellus elit pede, malesuada vel, venenatis vel, faucibus id, libero. Donec consectetuer	$66.35	1932-09-04	7	71	The Angel Saga Continues
328	6	785	at, iaculis quis, pede. Praesent eu dui. Cum sociis natoque penatibus et magnis dis	$56.57	2005-10-19	6	42	Goedheiligvrouw
329	5	572	montes, nascetur ridiculus mus. Proin vel nisl. Quisque fringilla euismod enim. Etiam gravida molestie arcu.	$78.61	1930-07-18	10	35	Lootjes trekken
332	1	772	Cras vehicula aliquet libero. Integer in magna. Phasellus dolor elit,	$2.06	2020-04-22	10	76	The Eyes Have It!
333	4	638	pede ac urna. Ut tincidunt vehicula risus. Nulla eget metus eu	$13.25	1995-09-08	9	50	Chapter Two: Sanjiyan
335	4	196	enim. Suspendisse aliquet, sem ut cursus	$70.66	1943-12-10	9	4	Rebirth: Chapter Three
336	5	152	amet ornare lectus justo eu arcu. Morbi	$53.61	2018-10-18	6	38	When Our Ships Come In...
338	7	416	amet, consectetuer adipiscing elit. Curabitur sed tortor. Integer aliquam adipiscing lacus. Ut nec urna	$98.12	1955-09-24	3	37	Were Standing VIGIL With "Fall From Grace"!
342	9	26	Lorem ipsum dolor sit amet, consectetuer adipiscing elit.	$14.90	1941-06-09	3	39	Part 2: Resistance!
344	7	253	pellentesque, tellus sem mollis dui, in	$26.03	2014-08-12	7	40	Inca Insurgency from 1500s to Túpac Amaru, 1780s
345	9	402	natoque penatibus et magnis dis	$57.18	1999-07-16	8	82	Apache Guerrillas of the Southwest!
346	10	342	pede et risus. Quisque libero lacus, varius et, euismod et, commodo at, libero. Morbi accumsan	$47.88	2003-10-28	7	87	Aazhoodena Ipperwash / Stoney Point 1995
352	2	658	est, mollis non, cursus non, egestas a, dui. Cras pellentesque. Sed	$5.34	1961-02-06	3	40	War on the Plains
353	8	227	ut quam vel sapien imperdiet ornare. In faucibus. Morbi vehicula. Pellentesque	$18.43	1974-03-09	6	34	Pontiac 1763 Rebellion and the Royal Proclamation
355	8	9	vel arcu. Curabitur ut odio vel est	$36.50	1998-09-04	7	28	The Unconquered Mapuche
356	6	657	tellus justo sit amet nulla. Donec non justo. Proin	$46.71	2016-12-16	3	59	Dismantled
360	1	951	nec metus facilisis lorem tristique aliquet. Phasellus fermentum convallis ligula. Donec luctus aliquet	$40.53	1978-05-25	1	46	Son of Heaven, Son of Hell
395	7	189	natoque penatibus et magnis dis	$1.40	2004-12-30	1	41	The Shower
5	2	294	ligula. Aenean gravida nunc sed pede. Cum sociis natoque penatibus	$81.36	1958-01-01	4	100	Iran -- Shah -- Khomeini -- Hostages
6	8	330	tristique ac, eleifend vitae, erat. Vivamus nisi. Mauris	$88.67	1985-06-06	1	25	Watergate
7	6	804	quam quis diam. Pellentesque habitant morbi tristique senectus et netus	$9.82	1967-01-17	7	85	Freedom of the Press
12	5	257	luctus aliquet odio. Etiam ligula tortor, dictum	$10.40	1999-10-22	5	47	Deaths
13	9	39	scelerisque, lorem ipsum sodales purus, in molestie tortor nibh sit amet orci. Ut	$50.87	1965-03-28	8	37	The Rodeo Robbers!
15	7	89	ac tellus. Suspendisse sed dolor. Fusce mi lorem,	$66.56	1960-04-02	2	51	The Robber of Rainbow Buttes!
16	9	904	ultrices. Duis volutpat nunc sit amet metus. Aliquam erat volutpat. Nulla facilisis. Suspendisse	$44.04	1979-06-18	3	89	The Case of the Curious Cards
17	4	384	sociis natoque penatibus et magnis dis parturient montes, nascetur ridiculus mus. Donec dignissim magna	$71.44	1964-11-05	6	6	The Tombstone Curse!
18	9	181	ligula. Aenean gravida nunc sed pede. Cum sociis natoque penatibus et magnis	$54.79	1972-11-06	5	18	The Book of Revelations
19	10	430	orci luctus et ultrices posuere cubilia Curae; Donec tincidunt. Donec vitae erat vel pede	$75.98	1973-02-21	4	12	Notes from the World
20	8	145	Phasellus at augue id ante dictum cursus.	$43.99	2001-01-24	3	65	Fire and Ice
22	8	766	et arcu imperdiet ullamcorper. Duis at lacus. Quisque purus sapien, gravida non, sollicitudin a,	$7.27	1983-10-14	2	36	Notes from the World
14	6	858	magna et ipsum cursus vestibulum. Mauris magna. Duis dignissim	$82.50	1973-05-01	9	70	The Desert Devil
23	3	263	a sollicitudin orci sem eget massa. Suspendisse eleifend. Cras sed leo. Cras vehicula	$33.67	1990-02-01	2	40	My German Buddy
28	8	753	magnis dis parturient montes, nascetur ridiculus mus. Proin vel arcu eu	$64.59	2010-05-08	6	18	Anteriormente em 100 Balas
367	4	966	id sapien. Cras dolor dolor, tempus non, lacinia at, iaculis quis,	$76.41	2019-05-27	7	28	The Blood That Runs
371	1	296	dictum placerat, augue. Sed molestie. Sed id risus quis	$30.10	1995-01-12	7	78	The Blood That Runs
372	1	141	vitae diam. Proin dolor. Nulla semper tellus id nunc interdum feugiat.	$50.97	1993-04-11	7	56	Donald na Matemagicalândia
377	7	309	amet orci. Ut sagittis lobortis mauris. Suspendisse aliquet molestie tellus. Aenean egestas	$93.49	1987-10-19	4	39	The Origin of the Justice League!
383	2	66	est. Mauris eu turpis. Nulla aliquet. Proin velit. Sed malesuada augue ut lacus. Nulla	$20.12	1974-03-08	1	72	The Curse of Lena Thorul!
385	4	158	magna. Sed eu eros. Nam consequat dolor	$17.28	1985-06-27	4	25	The Army of Living Kryptonite Men!
386	10	409	sagittis. Duis gravida. Praesent eu nulla at sem molestie	$39.79	1966-10-24	10	45	The Conquest of Superman!
388	4	651	Aliquam vulputate ullamcorper magna. Sed eu eros. Nam consequat dolor vitae dolor.	$50.42	1958-07-04	4	5	Superman in Superman Land
33	3	583	pellentesque eget, dictum placerat, augue. Sed molestie. Sed id risus quis diam luctus	$96.50	1933-04-07	8	82	Parlez Kung Vous [Part One]
34	8	843	Pellentesque ultricies dignissim lacus. Aliquam	$1.15	1994-03-13	7	67	Parlez Kung Vous Part Deux
3	5	15	mauris a nunc. In at	$10.52	1938-11-14	2	65	Gov. Carey
37	5	140	elementum purus, accumsan interdum libero dui	$80.31	1978-07-30	10	6	Hang Up on the Hang Low, Part Two
38	1	762	Aenean sed pede nec ante blandit viverra. Donec tempus, lorem fringilla ornare placerat, orci lacus	$60.97	1973-10-28	5	77	Hang Up on the Hang Low, Part Three
42	6	767	a, aliquet vel, vulputate eu, odio.	$59.32	1976-02-25	2	8	Idol Chatter
43	6	912	malesuada id, erat. Etiam vestibulum massa	$78.20	2019-08-10	2	71	Graves
44	6	94	Vivamus nibh dolor, nonummy ac,	$26.92	1936-11-06	7	54	In Stinked Part One
47	3	647	nulla. Integer vulputate, risus a ultricies adipiscing, enim mi tempor lorem,	$50.36	2001-02-07	1	52	In Stinked Conclusion
48	1	798	vitae velit egestas lacinia. Sed congue, elit sed consequat auctor, nunc nulla vulputate	$98.98	1958-09-06	10	56	Prey for Reign
51	7	251	cursus. Nunc mauris elit, dictum eu, eleifend nec, malesuada ut, sem.	$94.75	1972-08-18	3	92	Hang Up on the Hang Low Part Three
53	2	91	libero. Donec consectetuer mauris id sapien. Cras dolor dolor, tempus	$87.25	1933-07-18	4	24	The Mimic
56	6	684	dictum. Proin eget odio. Aliquam vulputate ullamcorper magna. Sed eu eros.	$51.07	1973-01-15	6	72	In Stinked Conclusion
57	3	406	accumsan convallis, ante lectus convallis est, vitae sodales	$77.13	1986-08-22	8	50	100 Bullets #49 Cover
59	8	132	arcu. Curabitur ut odio vel est tempor bibendum. Donec	$5.59	2019-08-07	6	34	In Stinked [Part One]
60	4	525	quam vel sapien imperdiet ornare. In faucibus. Morbi vehicula. Pellentesque tincidunt tempus risus.	$65.64	1945-10-09	6	21	100 Bullets #47 Cover
61	2	71	amet ultricies sem magna nec	$47.90	2013-03-20	8	91	Prey for Reign
62	1	15	in magna. Phasellus dolor elit, pellentesque a, facilisis non, bibendum	$9.33	1940-08-12	9	75	Der erste Schuss, Teil 1
64	1	200	pede. Cras vulputate velit eu sem. Pellentesque ut	$0.64	1950-04-28	10	77	100 kuler, del 1
66	9	216	at risus. Nunc ac sem ut dolor dapibus gravida. Aliquam tincidunt, nunc ac	$93.56	1989-02-19	5	13	Gewähr mir Zuflucht
67	2	691	eget, ipsum. Donec sollicitudin adipiscing ligula. Aenean gravida nunc sed pede. Cum	$11.20	1936-10-21	7	54	Skalpelle und Kettensägen
70	9	342	Nunc commodo auctor velit. Aliquam nisl. Nulla eu neque	$65.14	1937-02-07	1	77	The Batmobile of 1950!
71	10	786	Nulla dignissim. Maecenas ornare egestas ligula. Nullam feugiat placerat velit. Quisque varius. Nam	$52.02	1952-03-03	10	27	Showdown with the Monk
72	4	655	dolor sit amet, consectetuer adipiscing elit. Aliquam	$8.03	1993-04-04	1	80	Menace of the Monk
75	5	898	dictum magna. Ut tincidunt orci quis lectus. Nullam suscipit, est ac	$68.43	2001-12-04	9	15	Guardians Against Crime!
76	10	604	quam quis diam. Pellentesque habitant morbi tristique senectus et netus et malesuada	$71.75	1973-02-28	2	49	Battle of the Tiny Titans!
79	5	918	ante lectus convallis est, vitae sodales nisi magna sed dui. Fusce aliquam, enim nec tempus	$77.75	1936-07-31	6	63	Dr. Cyclops -- The Villain with the Doomsday Stare
80	4	286	dictum ultricies ligula. Nullam enim. Sed nulla ante, iaculis nec, eleifend non, dapibus rutrum,	$86.10	2006-08-07	4	73	Superbabys Search for a Pet!
89	6	962	quam quis diam. Pellentesque habitant morbi tristique senectus	$27.07	2008-03-21	7	19	This Is My Life by Bob Hope
91	7	525	arcu. Vestibulum ante ipsum primis in faucibus orci luctus	$20.31	1947-09-07	9	77	20,000 Legs Under the Sea
93	10	450	sem ut dolor dapibus gravida.	$86.53	1966-08-30	3	78	Travel Agency
103	6	951	mi. Aliquam gravida mauris ut mi. Duis risus odio, auctor vitae, aliquet nec,	$87.01	1944-11-07	5	71	One of Our Planes is MIssing!
104	7	184	mattis velit justo nec ante. Maecenas mi felis, adipiscing fringilla,	$32.08	2019-07-30	8	8	Next Issue
105	5	260	adipiscing elit. Etiam laoreet, libero et tristique pellentesque, tellus sem mollis	$55.58	1989-08-04	3	57	15 Love Book 1
106	8	468	Nullam scelerisque neque sed sem egestas blandit. Nam nulla magna, malesuada vel,	$32.15	1970-03-03	6	48	Next Issue
109	6	498	tellus, imperdiet non, vestibulum nec, euismod in, dolor. Fusce feugiat. Lorem ipsum dolor	$16.04	1983-01-13	5	6	Vem där?
111	2	632	Duis at lacus. Quisque purus sapien, gravida non, sollicitudin a, malesuada id,	$92.93	1982-04-13	9	86	Insect Paranoia
112	9	271	eget metus eu erat semper rutrum. Fusce dolor quam, elementum at, egestas a,	$19.66	1949-05-10	3	17	Project Black Sky
115	7	536	Donec feugiat metus sit amet ante. Vivamus non lorem vitae odio sagittis semper.	$36.28	1973-03-22	10	25	The Return of Rico
116	6	491	sagittis. Duis gravida. Praesent eu nulla at sem molestie sodales. Mauris	$36.42	1989-06-22	7	41	Everest [Part 1]
31	5	666	vitae risus. Duis a mi fringilla mi lacinia mattis. Integer eu lacus.	$70.89	1965-05-09	4	72	Rinhas, Parte dois
84	6	289	neque. Morbi quis urna. Nunc quis arcu vel quam dignissim pharetra. Nam ac nulla.	$84.64	1993-04-27	5	7	The Flying Chief!
85	10	787	pellentesque massa lobortis ultrices. Vivamus rhoncus. Donec est. Nunc ullamcorper,	$90.19	1947-11-16	1	24	The Card Crimes of the Royal Flush Gang!
87	4	45	diam dictum sapien. Aenean massa. Integer vitae nibh. Donec est	$6.03	1938-11-19	7	23	[The Amazing Story of Superman-Red and Superman-Blue! Part III] The End of Supermans Career!
88	2	954	placerat, orci lacus vestibulum lorem, sit amet ultricies	$57.70	1932-07-15	10	65	Part I: The Super-Moby Dick of Space!
95	4	769	non ante bibendum ullamcorper. Duis cursus, diam at pretium aliquet,	$21.18	1936-10-15	7	58	Phoney Business
96	10	417	Nullam vitae diam. Proin dolor. Nulla semper tellus id nunc	$65.53	2010-06-24	10	41	Go On; Take Two or Three
98	8	196	purus. Duis elementum, dui quis accumsan convallis,	$32.34	1933-06-10	9	99	Suggestion Box
99	8	408	venenatis vel, faucibus id, libero.	$34.94	1959-09-29	4	61	Were Sticklers for Stickers
120	4	51	adipiscing ligula. Aenean gravida nunc sed pede. Cum sociis natoque	$41.49	2013-04-06	1	97	The Perfect Crime
121	5	332	cursus non, egestas a, dui. Cras	$25.42	2007-05-24	7	83	Let the Galaxy Celebrate!
125	9	101	Ut semper pretium neque. Morbi quis	$57.26	1977-02-05	6	87	Criminal Genius: Dredd Breaks the Spell
126	7	994	Nullam velit dui, semper et, lacinia vitae, sodales at, velit.	$27.12	1943-01-04	2	38	Like a Rat Out of Hell!
131	5	628	diam. Sed diam lorem, auctor quis, tristique	$28.47	1957-02-28	9	58	Sector House Part 8
243	4	380	lorem lorem, luctus ut, pellentesque	$68.85	1980-05-04	4	28	Terrorists Part 7
139	4	725	molestie in, tempus eu, ligula. Aenean euismod mauris eu elit. Nulla facilisi. Sed neque. Sed	$35.29	2007-07-17	9	67	A Murder of Angels, Part 6
140	7	378	ultrices posuere cubilia Curae; Phasellus ornare. Fusce mollis. Duis sit amet	$26.49	2001-08-12	5	60	Wyrd Science
141	5	349	sagittis felis. Donec tempor, est ac mattis semper, dui lectus rutrum urna, nec luctus felis	$44.77	1959-05-24	5	62	A Murder of Angels, Part 7
142	2	279	Sed pharetra, felis eget varius ultrices, mauris ipsum porta elit, a feugiat tellus lorem	$65.49	1938-08-31	5	98	A Murder of Angels, Part 8
145	6	513	Duis gravida. Praesent eu nulla at sem molestie sodales. Mauris blandit	$5.60	1940-01-20	9	7	A Murder of Angels, Part 9
166	6	186	bibendum fermentum metus. Aenean sed pede nec ante blandit viverra.	$51.41	1960-12-21	2	44	Gorehead Part Five
167	2	607	tellus sem mollis dui, in sodales elit	$18.73	1981-09-05	3	10	Act of Grud Part Three
168	6	383	ut, nulla. Cras eu tellus eu augue porttitor interdum.	$25.01	1980-07-10	3	92	Hunted Part Six
169	5	348	libero mauris, aliquam eu, accumsan sed,	$25.22	2015-12-19	7	3	Part Seven
170	5	488	Nullam nisl. Maecenas malesuada fringilla est. Mauris eu turpis. Nulla aliquet. Proin velit. Sed	$99.49	1954-04-06	3	47	The Cube Root of Evil Part 1
171	10	887	dapibus gravida. Aliquam tincidunt, nunc ac mattis ornare, lectus ante	$86.24	1938-01-13	8	31	Book 10 The Märze Murderer Part 7
174	9	488	Integer vitae nibh. Donec est mauris, rhoncus id,	$89.97	1965-01-15	5	69	Hunted Part Seven
175	8	929	eleifend. Cras sed leo. Cras	$69.77	1962-03-13	4	11	The Cube Root of Evil Part 2
177	7	129	sapien molestie orci tincidunt adipiscing. Mauris molestie pharetra nibh. Aliquam ornare, libero at	$40.86	2013-08-13	5	24	Gorehead Part Seven
180	7	153	Phasellus vitae mauris sit amet lorem semper auctor. Mauris vel turpis. Aliquam	$61.28	1983-10-02	7	96	Return of the Revolutionaries
181	4	447	lorem lorem, luctus ut, pellentesque eget,	$85.19	2008-09-14	4	7	Book 10 The Märze Murderer Part 9
184	1	545	enim diam vel arcu. Curabitur ut odio vel est tempor	$2.82	1942-10-14	1	82	The Cube Root of Evil Part 3
189	8	469	a mi fringilla mi lacinia mattis. Integer eu lacus. Quisque imperdiet, erat	$39.94	1943-07-22	10	93	Furies Part Six
190	9	445	Cras sed leo. Cras vehicula aliquet libero. Integer	$71.56	1959-11-14	1	85	Foul Play Part One
191	7	855	malesuada augue ut lacus. Nulla tincidunt,	$34.71	1941-06-12	10	19	Border Ops Part One
192	6	784	dignissim lacus. Aliquam rutrum lorem ac risus. Morbi metus. Vivamus euismod urna. Nullam	$11.94	1949-12-20	2	57	Skeleton Life Part 18
194	4	528	ut ipsum ac mi eleifend egestas. Sed pharetra, felis eget varius ultrices, mauris	$54.20	1977-08-08	2	13	Last Breath
195	7	758	dui quis accumsan convallis, ante lectus	$80.99	1949-01-08	4	53	The Wrap-Up
196	3	233	molestie orci tincidunt adipiscing. Mauris molestie pharetra	$2.51	1976-09-02	6	87	Furies Part Eight
197	8	550	enim. Curabitur massa. Vestibulum accumsan neque	$45.08	1961-06-06	4	100	Border Ops Part Two
199	7	1	eleifend nec, malesuada ut, sem. Nulla interdum. Curabitur	$54.18	1931-04-10	7	64	Ouroboros Part One
200	2	558	dui augue eu tellus. Phasellus elit	$8.74	1982-02-01	5	6	The Body Politic
203	1	40	adipiscing elit. Curabitur sed tortor. Integer aliquam adipiscing lacus.	$22.40	1960-07-11	9	49	Signal Six Twenty-Four Part One
208	6	906	imperdiet ornare. In faucibus. Morbi vehicula. Pellentesque tincidunt tempus risus. Donec egestas. Duis	$30.08	1979-03-23	5	79	Foul Play Part Five
212	2	286	Nullam lobortis quam a felis ullamcorper viverra. Maecenas iaculis	$71.44	1985-05-22	6	37	Mechastopheles Part One
213	7	53	urna. Nunc quis arcu vel quam dignissim pharetra.	$41.57	2018-06-09	1	69	Demonslayer!
214	4	429	sapien. Nunc pulvinar arcu et pede. Nunc sed orci	$48.61	1931-04-19	1	43	Hope For the Future Part 9
215	8	141	Aliquam nisl. Nulla eu neque pellentesque massa lobortis ultrices. Vivamus rhoncus. Donec	$16.58	1980-04-06	3	67	Mechastopheles Part Two
216	8	263	magna. Cras convallis convallis dolor. Quisque tincidunt pede	$84.40	2008-07-04	3	46	Inhuman Natures Part 5
119	8	560	amet ornare lectus justo eu arcu. Morbi sit amet	$52.05	1946-01-18	3	2	Dredd Dead?
146	4	41	Sed congue, elit sed consequat auctor, nunc nulla vulputate dui, nec	$6.19	1992-06-26	9	13	A Murder of Angels, Part 10
147	6	917	risus. Nulla eget metus eu erat semper rutrum. Fusce dolor quam, elementum at,	$32.50	1978-08-27	6	31	The Butcher of Rome!
149	8	582	semper erat, in consectetuer ipsum nunc id enim. Curabitur massa. Vestibulum accumsan neque et	$3.24	1972-12-08	6	22	Gorehead Part One
151	4	937	feugiat. Lorem ipsum dolor sit amet,	$30.34	1956-03-10	4	10	Part Three
153	4	34	egestas ligula. Nullam feugiat placerat velit. Quisque	$82.06	2011-02-14	7	9	Gorehead Part Two
157	10	250	nascetur ridiculus mus. Aenean eget magna. Suspendisse tristique neque	$99.80	1956-10-28	9	78	Gorehead Part Three
159	8	550	justo sit amet nulla. Donec non justo. Proin non massa non ante bibendum ullamcorper.	$72.39	2006-07-10	9	28	Hunted Part Four
160	4	710	ornare egestas ligula. Nullam feugiat placerat velit. Quisque varius. Nam porttitor	$43.16	1974-07-04	4	14	Act of Grud Part One
163	3	70	ipsum nunc id enim. Curabitur	$19.21	1940-12-13	2	71	Didnt Manage to Pick Up the Sold-Out Cursed Earth Uncensored?
164	6	541	enim. Etiam gravida molestie arcu. Sed eu nibh vulputate mauris sagittis placerat. Cras	$94.44	1931-08-17	5	43	Hunted Part Five
225	1	46	viverra. Maecenas iaculis aliquet diam. Sed diam lorem,	$78.85	1952-03-19	6	48	Echoes Part 3
226	4	781	vulputate, posuere vulputate, lacus. Cras interdum. Nunc	$42.81	1983-01-23	6	7	Terrorists
227	4	196	malesuada malesuada. Integer id magna et ipsum cursus	$44.01	1947-02-17	5	28	Engine Summer Part 3
228	6	567	Proin velit. Sed malesuada augue ut lacus. Nulla	$37.77	1942-11-04	6	57	Echoes Part 4
230	2	353	Donec luctus aliquet odio. Etiam ligula tortor, dictum eu, placerat eget, venenatis a, magna. Lorem	$2.27	1968-11-22	2	48	Terrorists Part 4
231	5	412	Sed malesuada augue ut lacus. Nulla tincidunt, neque vitae semper egestas, urna	$85.53	1931-07-21	4	55	Engine Summer Part 4
234	6	459	Lorem ipsum dolor sit amet, consectetuer adipiscing elit. Aliquam	$21.88	1974-02-13	3	78	The Shroud Part 1
240	4	160	nonummy ultricies ornare, elit elit fermentum	$81.18	2012-07-12	9	51	Engine Summer Part 6
247	9	15	Mauris molestie pharetra nibh. Aliquam ornare, libero	$15.13	1967-10-20	7	17	Book 11 The Thousand Year Stare Part 9
250	2	272	urna, nec luctus felis purus ac tellus. Suspendisse sed dolor.	$15.38	1993-03-22	5	89	Live Evil Part 3
251	7	432	id, mollis nec, cursus a, enim. Suspendisse aliquet, sem ut cursus luctus,	$67.50	1983-03-10	2	51	Book 11 The Thousand Year Stare Part 11
253	10	230	erat vel pede blandit congue. In scelerisque scelerisque dui. Suspendisse ac	$5.24	2008-12-05	7	81	Terrorists Part Eleven
254	6	321	Quisque ornare tortor at risus.	$55.69	1971-01-11	9	23	Engine Summer Part 11
258	2	365	consectetuer adipiscing elit. Etiam laoreet, libero	$2.19	1980-02-12	5	74	Engine Summer Part 12
263	3	672	fermentum vel, mauris. Integer sem elit, pharetra ut, pharetra	$85.61	1989-01-26	3	6	The Salad of Bad Cafe
265	9	960	vel sapien imperdiet ornare. In faucibus. Morbi vehicula.	$7.93	1943-03-12	5	27	The Son Part One
267	5	307	Curabitur consequat, lectus sit amet luctus vulputate, nisi sem semper	$74.32	1965-01-01	4	84	Fit For Purpose Part 2
268	3	93	mauris elit, dictum eu, eleifend nec,	$74.74	1970-05-22	10	30	In the Realm of Pyrrhus Part Two
269	6	874	posuere cubilia Curae; Phasellus ornare. Fusce mollis. Duis sit amet diam eu dolor egestas rhoncus.	$15.93	1941-08-17	2	72	The Son Part Two
270	2	486	est mauris, rhoncus id, mollis nec, cursus	$51.06	1944-06-12	10	63	Undertow Part Three
273	4	623	amet, risus. Donec nibh enim, gravida	$12.84	1958-06-28	1	49	In the Realm of Pyrrhus Part Three
278	10	85	amet nulla. Donec non justo. Proin non massa non ante bibendum ullamcorper. Duis cursus, diam	$18.54	1985-05-28	5	35	In the Realm of Pyrrhus Part Four
283	7	786	elementum sem, vitae aliquam eros	$2.42	1943-12-18	1	6	New York State of Mind
284	6	170	amet risus. Donec egestas. Aliquam nec enim. Nunc ut erat.	$36.76	1966-01-12	3	88	The Devil Dont Care Part Three
290	2	246	vitae purus gravida sagittis. Duis gravida. Praesent eu nulla	$10.08	1981-07-26	2	53	Undertow Part Seven
291	3	664	lobortis quam a felis ullamcorper viverra. Maecenas iaculis aliquet diam. Sed diam lorem, auctor quis,	$7.51	1982-05-11	3	25	The Son Part Seven
292	10	523	ipsum sodales purus, in molestie tortor nibh sit amet orci. Ut sagittis lobortis	$28.27	1987-02-21	6	78	The Gangbusters Chapter One: Air Superiority!
293	6	109	euismod est arcu ac orci. Ut semper	$27.96	2008-02-21	10	79	An Inconvenient Tooth
295	4	992	pharetra. Nam ac nulla. In tincidunt	$89.51	1967-06-20	7	29	The Son Part Eight
297	5	876	dictum. Phasellus in felis. Nulla tempor	$94.42	2017-11-22	8	3	The Puppet
299	5	328	augue ut lacus. Nulla tincidunt, neque vitae semper egestas,	$87.32	2008-04-18	8	47	Dead Signal
300	6	162	Duis mi enim, condimentum eget, volutpat	$98.56	1975-09-20	4	39	Savage Swamp
301	4	749	mauris elit, dictum eu, eleifend	$93.82	2006-08-15	3	100	Living Your best Life
302	10	374	ut mi. Duis risus odio, auctor vitae, aliquet	$88.77	1979-07-28	6	72	All-Ages Takeover Issue!
309	5	828	posuere cubilia Curae; Phasellus ornare. Fusce mollis. Duis sit amet diam	$71.23	1981-12-26	1	78	The Blood Beast
311	7	304	augue malesuada malesuada. Integer id	$73.57	1968-01-25	6	44	Computer Love
312	10	432	imperdiet dictum magna. Ut tincidunt orci quis lectus. Nullam suscipit,	$36.57	1991-11-30	6	86	Underground
313	5	592	Proin vel nisl. Quisque fringilla euismod enim. Etiam gravida molestie arcu. Sed eu	$70.59	1954-12-14	9	34	Underground
314	8	289	imperdiet dictum magna. Ut tincidunt orci quis lectus. Nullam suscipit, est ac facilisis facilisis, magna	$60.35	1978-11-28	9	18	Underground
315	2	783	Sed neque. Sed eget lacus. Mauris non dui nec urna suscipit nonummy. Fusce	$30.63	1979-01-25	2	64	Underground
316	10	969	mollis nec, cursus a, enim. Suspendisse aliquet,	$19.29	1966-03-13	3	82	Underground
317	7	36	vestibulum lorem, sit amet ultricies sem magna nec quam. Curabitur	$70.86	1961-03-20	1	97	The Hand That Feeds
319	2	726	egestas. Aliquam nec enim. Nunc ut erat. Sed nunc est, mollis non, cursus non, egestas	$92.61	2010-08-08	2	72	Welcome to 30 Days of Night
321	2	717	semper et, lacinia vitae, sodales at, velit. Pellentesque ultricies dignissim lacus. Aliquam	$52.97	2007-12-26	6	31	From the Browser to the Bookshelf
221	8	187	eu enim. Etiam imperdiet dictum magna.	$66.80	1989-12-17	2	70	Mechastopheles Part Three
280	3	106	quis accumsan convallis, ante lectus convallis est, vitae sodales nisi magna sed dui. Fusce	$7.97	2007-04-01	8	73	The Son Part Four
286	10	385	arcu iaculis enim, sit amet ornare	$73.09	2005-09-13	10	20	Undertow Part Six
287	1	60	dignissim pharetra. Nam ac nulla.	$28.47	1959-05-31	7	30	The Devil Dont Care Part Four
288	4	229	et malesuada fames ac turpis	$31.58	1983-09-29	5	16	In the Realm of Pyrrhus Part Six
326	6	478	justo faucibus lectus, a sollicitudin orci	$51.06	1931-06-24	4	95	Easy Come Easy Go
327	7	542	sem ut dolor dapibus gravida.	$82.02	1974-03-19	1	64	Chapter One: Honor
330	8	742	ipsum non arcu. Vivamus sit amet risus. Donec egestas. Aliquam nec	$88.30	1988-09-20	5	19	Collectie
331	10	524	lorem, vehicula et, rutrum eu, ultrices sit amet, risus. Donec nibh enim, gravida sit	$39.60	1986-03-07	1	96	House of Demons Part 1
334	3	106	velit. Aliquam nisl. Nulla eu neque pellentesque massa lobortis ultrices.	$85.18	1962-12-20	1	82	So Where Are The Innovations, Anyway?
337	4	317	eu, odio. Phasellus at augue id ante	$56.46	1994-02-05	3	71	House of Demons, Part Two
340	6	581	aliquet, sem ut cursus luctus,	$52.47	1952-01-17	4	22	Parte 2. Vuelta al pasado
341	9	171	at, nisi. Cum sociis natoque penatibus et magnis dis parturient	$76.66	2002-11-11	8	30	400 BC: The Story of the Ten Thousand
343	4	332	ligula. Aliquam erat volutpat. Nulla dignissim. Maecenas ornare egestas ligula. Nullam	$59.85	1951-08-24	3	77	Seminole Wars
347	6	856	Suspendisse eleifend. Cras sed leo. Cras vehicula aliquet	$75.31	1983-09-02	9	14	1995 Standoff at TsPeten
351	8	857	adipiscing lobortis risus. In mi pede, nonummy ut,	$35.10	1990-10-10	2	31	War on the Coast
354	2	576	ipsum primis in faucibus orci luctus et ultrices posuere cubilia Curae;	$95.56	2016-09-10	8	78	1680 Pueblo Revolt
357	4	700	a, enim. Suspendisse aliquet, sem ut cursus luctus, ipsum leo elementum	$88.44	1980-02-20	1	37	Desmantelado
358	5	196	sem. Nulla interdum. Curabitur dictum. Phasellus in felis. Nulla	$20.67	2012-09-27	9	37	Solveig Muren Sanden 1918-2013
359	2	491	erat. Etiam vestibulum massa rutrum magna. Cras convallis convallis dolor. Quisque tincidunt pede ac urna.	$39.79	1940-10-18	6	89	Solveig Muren Sanden 1918-2013
361	3	662	consequat auctor, nunc nulla vulputate	$48.28	1933-02-01	7	83	Dinner with the Assassin
362	8	549	Nam ligula elit, pretium et, rutrum non, hendrerit id, ante. Nunc mauris	$13.11	1949-11-09	3	66	Seven Funerals
363	8	443	egestas ligula. Nullam feugiat placerat velit. Quisque varius. Nam porttitor scelerisque	$29.75	1965-02-15	10	40	Interview with Dave Stewart
364	7	919	mi eleifend egestas. Sed pharetra, felis eget varius ultrices, mauris ipsum porta elit, a	$45.73	1940-02-28	9	80	The Long Road Home
365	5	193	tortor. Integer aliquam adipiscing lacus. Ut nec urna et arcu imperdiet	$11.99	1986-11-30	2	71	Recap
366	1	124	dis parturient montes, nascetur ridiculus	$90.22	2012-08-22	7	70	5: Dragonfire
368	2	20	Nunc mauris. Morbi non sapien molestie orci tincidunt adipiscing. Mauris	$19.13	1945-06-19	9	17	Previously:
369	8	707	Integer id magna et ipsum cursus vestibulum. Mauris magna. Duis dignissim tempor arcu.	$78.40	1963-07-14	7	25	The Blood That Runs
370	7	273	luctus vulputate, nisi sem semper erat, in consectetuer ipsum nunc id enim. Curabitur	$38.99	1952-09-19	5	8	Previously:
373	3	628	Sed eget lacus. Mauris non dui nec urna suscipit nonummy. Fusce fermentum	$62.18	2016-02-24	7	41	The Old Man of Metropolis!
374	5	481	aliquam, enim nec tempus scelerisque, lorem	$4.36	1966-12-18	5	21	The Revenge of Luthor!
375	7	925	sed, est. Nunc laoreet lectus quis massa. Mauris vestibulum, neque sed	$50.47	1958-11-22	3	6	The E-L-A-S-T-I-C Lad
376	2	389	Proin mi. Aliquam gravida mauris ut mi. Duis risus odio, auctor vitae, aliquet nec,	$81.60	2008-04-26	6	71	The War Between Superman and Jimmy Olsen!
378	6	286	porttitor tellus non magna. Nam	$31.05	1952-08-14	9	79	The Story of Supermans Life!
322	8	765	tellus eu augue porttitor interdum. Sed auctor odio a purus. Duis elementum, dui quis	$94.37	1992-06-16	10	2	The Doctor Is In
323	7	801	Nunc ac sem ut dolor	$30.81	1930-05-10	2	5	Niles and Sienkiewicz Plan a Trip to Barrow
339	9	844	egestas. Duis ac arcu. Nunc mauris. Morbi non sapien molestie	$37.60	1947-10-11	6	70	House of Demons Part Three
348	3	803	vulputate, lacus. Cras interdum. Nunc sollicitudin commodo ipsum. Suspendisse non leo.	$11.30	1962-06-04	6	75	The Oka Crisis
349	10	847	non, bibendum sed, est. Nunc laoreet lectus quis massa. Mauris vestibulum, neque sed dictum	$4.23	1988-06-29	3	28	Wounded Knee 73
350	2	745	nisl arcu iaculis enim, sit amet ornare lectus justo eu arcu. Morbi sit amet massa.	$98.45	1997-03-24	5	34	No Justice on Stolen Land
379	8	766	Phasellus ornare. Fusce mollis. Duis sit	$12.19	1932-05-23	9	69	The Origin of Flashs Masked Identity!
380	6	113	augue ac ipsum. Phasellus vitae mauris sit amet lorem semper auctor. Mauris vel turpis. Aliquam	$63.02	2000-06-12	2	47	The Man from Robins Past
381	9	344	scelerisque scelerisque dui. Suspendisse ac metus vitae velit egestas lacinia. Sed	$30.54	2000-05-25	10	91	Birth of the Atom!
382	7	405	metus. Aenean sed pede nec ante blandit viverra.	$21.22	1952-01-10	8	98	The Impossible Mission!
387	4	359	elit. Aliquam auctor, velit eget laoreet posuere, enim nisl elementum	$48.17	2009-11-01	9	57	The Terrible Trio!
389	7	354	mauris elit, dictum eu, eleifend nec, malesuada ut, sem. Nulla	$96.58	1943-08-11	10	34	Jimmy the Genie!
390	5	988	Pellentesque tincidunt tempus risus. Donec egestas.	$92.30	1958-12-14	2	80	Mrs. Superman
391	4	337	dictum. Proin eget odio. Aliquam	$99.20	1942-05-07	10	36	The Day When Superman Proposed!
392	6	684	dignissim tempor arcu. Vestibulum ut	$38.70	1985-04-14	9	51	Branie!
393	8	38	mus. Proin vel arcu eu odio tristique pharetra. Quisque ac libero	$24.89	1967-09-20	8	54	The Carrier Pigeon
394	5	681	ac mattis velit justo nec ante. Maecenas mi felis, adipiscing fringilla,	$42.39	1949-08-18	1	92	"H" Stands for Heroin
397	4	204	tellus non magna. Nam ligula elit, pretium et, rutrum	$3.38	1983-03-04	4	36	Under the Peace Arch
398	10	269	eget magna. Suspendisse tristique neque venenatis lacus. Etiam bibendum fermentum metus. Aenean sed pede nec	$34.73	1960-04-14	6	51	Treasure
399	5	337	dis parturient montes, nascetur ridiculus mus. Donec dignissim magna	$17.70	1935-06-29	4	9	Clear Skies
400	8	300	commodo ipsum. Suspendisse non leo. Vivamus nibh dolor, nonummy ac,	$59.62	1934-04-05	6	43	Indomitable Human Spirit
1	6	100	Nullam ut nisi a odio semper cursus. Integer mollis. Integer tincidunt	$21.69	1954-03-02	8	19	title
2	4	20	Mauris vel turpis. Aliquam adipiscing lobortis risus. In mi pede, nonummy ut,	$43.80	2018-05-02	10	18	State-Legislature
9	10	530	justo. Proin non massa non ante bibendum ullamcorper. Duis cursus, diam at pretium	$51.09	1977-11-06	9	88	General
4	6	756	massa. Suspendisse eleifend. Cras sed leo. Cras vehicula aliquet libero.	$76.48	2012-12-04	7	86	Jimmy Carter & Friends
\.


--
-- Data for Name: customers; Type: TABLE DATA; Schema: public; Owner: kirill
--

COPY public.customers (customer_id, name, email, phone) FROM stdin;
1	Jack	jack@jack	12345
11	Shana	ipsum.sodales@velquam.net	1-700-454-9807
12	Risa	dapibus.gravida.Aliquam@uteros.edu	1-337-430-0958
13	Anjolie	augue.eu@Duisat.co.uk	1-593-278-0675
14	Quamar	eget.metus@ametconsectetuer.net	1-209-711-4956
15	Harrison	tempor.est@nonummy.org	1-886-913-6972
16	Trevor	bibendum@vitae.ca	1-890-449-8278
17	Elmo	Lorem.ipsum.dolor@nonleoVivamus.com	1-743-999-7183
18	Ashton	quis@lorem.edu	1-900-821-4224
19	Branden	ipsum.dolor.sit@Phasellusvitaemauris.net	1-296-110-8944
20	Kermit	quam.Pellentesque.habitant@loremvehicula.edu	1-415-691-8742
21	Dominique	faucibus@ipsumprimis.org	1-515-539-4544
22	Martena	non.magna@liberoatauctor.co.uk	1-564-789-5417
23	Dora	eu.eros.Nam@sagittissemper.com	1-386-707-9837
24	Zorita	Mauris.nulla@lacusQuisquepurus.ca	1-208-657-2090
25	Kyle	netus.et@adipiscingnonluctus.org	1-198-653-3000
26	Luke	rutrum.urna@vel.org	1-130-361-8204
27	Hiroko	scelerisque@iaculisenimsit.com	1-800-966-5521
28	Joshua	erat@accumsan.co.uk	1-765-110-3424
29	Gary	Praesent.eu.dui@feliseget.co.uk	1-197-427-0261
30	Alana	dignissim@ut.edu	1-871-189-7857
31	Laura	quam@in.edu	1-214-815-9747
32	Ginger	nulla.In.tincidunt@Duis.co.uk	1-157-354-9215
33	Cecilia	feugiat@vulputate.co.uk	1-932-448-4206
34	Brett	ullamcorper@Namacnulla.org	1-956-975-8317
35	Jennifer	nec.leo.Morbi@sitamet.co.uk	1-272-884-5120
36	Cullen	eu.sem.Pellentesque@Cras.co.uk	1-111-490-7029
37	Naida	fermentum.vel.mauris@arcuCurabiturut.ca	1-353-775-6147
38	Garrison	Cras@semmagnanec.com	1-526-110-9085
39	Beatrice	Integer@anteMaecenasmi.co.uk	1-395-778-4086
40	Baxter	eget@tellus.edu	1-379-760-5658
41	Forrest	massa.Quisque.porttitor@orcilobortisaugue.net	1-691-659-5133
42	Meredith	in.cursus.et@Donec.org	1-272-847-6009
43	Melissa	eget.tincidunt.dui@Nullamfeugiatplacerat.org	1-862-149-3569
44	Ocean	nibh.sit@faucibusMorbi.net	1-347-734-1655
45	Chantale	dolor.quam@egetlaoreetposuere.edu	1-868-273-5435
46	Fatima	orci.Ut.sagittis@Fuscemi.net	1-370-206-3090
47	Martha	Duis.dignissim.tempor@egetlaoreetposuere.co.uk	1-528-274-2612
48	Samuel	velit@accumsan.com	1-918-635-7902
49	Carly	lorem.vehicula@consectetuer.ca	1-355-253-4828
50	Heather	Phasellus@augue.co.uk	1-784-443-9802
51	Chanda	Ut@Curabitur.com	1-108-711-5811
52	Malik	Curabitur.vel@felis.ca	1-791-686-4662
53	Illana	eget.metus.In@ultrices.co.uk	1-847-576-1560
54	Katell	eu.accumsan@iaculisodio.net	1-212-189-5103
55	Juliet	mus.Proin.vel@ante.com	1-718-813-3831
56	Morgan	Vestibulum.ante@Suspendissesed.net	1-379-416-9840
57	Eugenia	Donec@fringillamilacinia.org	1-212-996-8397
58	Harper	blandit.mattis.Cras@Donecnonjusto.com	1-781-240-2191
59	Simone	felis.Nulla@Duisgravida.net	1-556-370-0666
60	Tobias	lacinia.mattis.Integer@atsem.com	1-517-852-4633
61	Hasad	enim@sit.ca	1-526-332-8243
62	Price	tincidunt.tempus.risus@consectetuereuismod.edu	1-479-529-6469
63	Frances	dictum@euodio.com	1-660-570-3098
64	Rashad	ultrices@scelerisquelorem.net	1-557-636-3129
65	Ulysses	convallis.convallis.dolor@penatibuset.ca	1-813-356-7634
66	Catherine	id.sapien@dis.net	1-205-711-7675
67	Myles	vel.arcu@pedeSuspendissedui.org	1-785-925-9691
68	Freya	risus.Morbi@euneque.net	1-615-680-8118
69	Troy	non.luctus@mauris.ca	1-265-972-9148
70	Hanae	Donec@sedpedeCum.edu	1-987-923-2506
71	Linda	Duis.sit@tinciduntnibhPhasellus.ca	1-964-344-4196
72	Julie	risus.at@Donec.com	1-978-582-0537
73	Dale	urna.nec.luctus@Aliquamrutrum.co.uk	1-382-907-6951
74	Kim	et@ametanteVivamus.ca	1-341-514-0571
75	Cassandra	diam@auctornuncnulla.net	1-798-167-3821
76	Deanna	lacus.Quisque@et.com	1-605-546-9225
77	Cassidy	Pellentesque@euismodestarcu.edu	1-860-848-3769
78	Hamilton	risus@lectusCumsociis.co.uk	1-566-154-2342
79	Kyra	pellentesque.a.facilisis@mollisneccursus.co.uk	1-630-672-8961
80	Tatiana	imperdiet@tinciduntpede.org	1-731-403-0342
81	Doris	amet@ligulaNullam.co.uk	1-171-498-3654
82	Edward	et@cursusnon.ca	1-532-869-4013
83	Darius	nec.tempus@sedconsequat.edu	1-108-681-5089
84	Bo	amet@ultricesDuisvolutpat.net	1-245-614-6421
85	Hall	amet.risus.Donec@seddolorFusce.net	1-271-864-4777
86	Olga	euismod.mauris.eu@dictum.co.uk	1-506-564-3016
87	Mikayla	Suspendisse@Nunc.ca	1-531-160-3282
88	Blythe	natoque.penatibus.et@semperrutrum.com	1-849-925-4646
89	Delilah	Sed@lectuspede.com	1-284-426-7052
90	Madaline	natoque.penatibus.et@urna.com	1-857-516-8599
91	Hilda	ornare.In@mollis.edu	1-961-229-0984
92	Preston	erat@ipsum.edu	1-351-195-0245
93	Hoyt	erat@ligulaAenean.ca	1-887-801-9297
94	Regan	libero.mauris.aliquam@necmetus.com	1-886-613-4200
95	Aladdin	Nunc.ac@ornaretortorat.edu	1-381-483-3386
96	Britanni	risus@InloremDonec.net	1-295-293-3797
97	Carl	orci.Phasellus@quam.net	1-522-816-9307
98	Anika	Pellentesque.ut@nascetur.org	1-709-423-4017
99	Kaye	nulla.ante@euismodin.net	1-762-750-9802
100	Kelsey	orci.sem.eget@urnaetarcu.org	1-574-179-5024
\.


--
-- Data for Name: employee; Type: TABLE DATA; Schema: public; Owner: kirill
--

COPY public.employee (emp_id, name, surname, phone) FROM stdin;
1	John	Krasinsky	12345
11	Lester	Porter	1-306-568-5420
12	Hillary	Reyes	1-934-569-6873
13	Kay	Hatfield	1-259-400-4851
14	Donovan	Bass	1-761-186-1328
15	Rinah	Sargent	1-905-602-7677
16	Mason	Church	1-966-744-7539
17	Christian	Mueller	1-705-787-0429
18	Giselle	Fry	1-306-428-2959
19	Zahir	Bray	1-139-546-8166
20	Isadora	Crosby	1-360-811-2659
21	Lane	Jarvis	1-242-314-7723
22	Nola	Whitley	1-235-928-0462
23	Colton	Gonzales	1-812-454-2335
24	Wendy	Johnston	1-881-132-3714
25	Juliet	Barber	1-596-267-6553
26	Rebecca	Hoover	1-409-839-7607
27	Thomas	Bean	1-787-123-8381
28	Winter	Pierce	1-869-259-2108
29	Zahir	Estrada	1-481-363-9271
30	Shelly	Snider	1-561-554-2409
31	Abraham	Floyd	1-612-679-8613
32	Evangeline	Nolan	1-972-759-3028
33	Lynn	Mclean	1-386-199-6629
34	Regan	Garrett	1-329-671-3475
35	Charde	Guy	1-152-387-5469
36	Kamal	Alston	1-991-144-0596
37	Ann	Herman	1-976-594-7496
38	Jared	Hunter	1-439-874-1258
39	Germaine	England	1-866-411-6031
40	Marsden	Torres	1-788-574-1979
41	Emmanuel	Cleveland	1-932-288-0978
42	Gay	Clements	1-717-820-9685
43	Candice	Underwood	1-418-474-6754
44	Hillary	Wynn	1-186-340-2655
45	Jamalia	Stephens	1-386-381-2175
46	Amy	Pearson	1-322-221-5250
47	Edan	Peterson	1-716-814-2238
48	Merritt	Webb	1-243-538-0330
49	Naida	Carter	1-341-388-4260
50	Lucas	Hunter	1-129-148-1204
51	Colleen	Hogan	1-568-520-5397
52	Aiko	Arnold	1-822-870-0028
53	Guy	Cook	1-877-949-5637
54	Ima	Mcfarland	1-607-270-0911
55	Michael	Mccarthy	1-941-357-5311
56	Sarah	Juarez	1-960-315-2060
57	Oprah	Holden	1-181-749-2219
58	Cooper	Lloyd	1-346-159-2134
59	Chloe	Pickett	1-719-507-9816
60	Selma	Hardin	1-945-952-3988
61	Xerxes	Hamilton	1-188-815-5314
62	Kendall	Landry	1-881-467-0186
63	Gwendolyn	Knight	1-217-828-8690
64	Malcolm	Bailey	1-657-106-4722
65	Ray	Pacheco	1-914-136-8207
66	Alfonso	Mayo	1-680-221-8075
67	Cyrus	Velez	1-336-279-0551
68	Jana	Page	1-443-652-6790
69	Hedwig	Bruce	1-101-322-3885
70	Marsden	Houston	1-956-886-4218
71	Elaine	Brooks	1-967-847-1647
72	Bethany	Miranda	1-252-143-0686
73	Timon	Williams	1-821-426-2225
74	Dale	Santiago	1-651-606-1700
75	Tyrone	Strong	1-668-296-1800
76	Bert	Fields	1-530-700-9738
77	Jackson	Fuentes	1-314-830-4226
78	Jolie	Garner	1-834-971-1659
79	Brenden	Tate	1-229-447-0093
80	Brenda	Stokes	1-292-647-4909
81	Dominique	Fox	1-306-430-7814
82	Gretchen	Gallagher	1-177-756-5199
83	Melyssa	York	1-215-812-2858
84	Brenna	Emerson	1-844-377-0366
85	Jack	Sutton	1-152-678-3712
86	Harrison	Coleman	1-596-710-4174
87	Caleb	Cote	1-137-487-3377
88	Yardley	Camacho	1-151-116-4644
89	Casey	Pollard	1-513-498-2215
90	Rhona	Haley	1-731-115-6350
91	Thane	Mercado	1-229-329-3238
92	Catherine	Byers	1-397-582-0862
93	Scarlet	Oliver	1-980-830-3299
94	Kylynn	Perry	1-509-788-2234
95	Lev	Sweeney	1-818-837-1115
96	Giacomo	Key	1-155-660-9015
97	Sierra	Byrd	1-115-241-3563
98	Hamish	Kirby	1-112-158-3984
99	Gabriel	Valdez	1-185-634-4070
100	Plato	Hoover	1-923-710-2863
\.


--
-- Data for Name: genre; Type: TABLE DATA; Schema: public; Owner: kirill
--

COPY public.genre (genre, comic_id) FROM stdin;
Science	1
University	2
Horror	3
Adventure	4
Science	5
Drama	6
Comedy	7
Sci-Fi	8
Drama	9
University	10
Fighting	11
University	12
Romance	13
Adventure	14
School	15
Drama	16
Adventure	17
Science	18
Science	19
Fighting	20
Sci-Fi	21
Fantasy	22
Fighting	23
Adventure	24
Comedy	25
Adventure	26
Fantasy	27
School	28
Horror	29
School	30
Drama	31
Fighting	32
Comedy	33
Drama	34
School	35
Fighting	36
Drama	37
Fighting	38
Comedy	39
Science	40
University	41
School	42
Sci-Fi	43
Science	44
School	45
Science	46
Romance	47
Sci-Fi	48
Comedy	49
Fighting	50
Romance	51
School	52
Fighting	53
Sci-Fi	54
Drama	55
Drama	56
Comedy	57
Adventure	58
University	59
Sci-Fi	60
Science	61
Drama	62
Fighting	63
University	64
University	65
Science	66
Romance	67
University	68
Horror	69
Sci-Fi	70
Horror	71
Adventure	72
Romance	73
Science	74
School	75
Adventure	76
Adventure	77
Horror	78
Adventure	79
School	80
School	81
University	82
Fantasy	83
Sci-Fi	84
Science	85
Fighting	86
Romance	87
University	88
University	89
Drama	90
Science	91
Drama	92
Horror	93
Adventure	94
School	95
Comedy	96
Comedy	97
Fighting	98
Comedy	99
Sci-Fi	100
Fighting	101
Fighting	102
Fighting	103
Fantasy	104
Fantasy	105
Sci-Fi	106
Drama	107
Adventure	108
University	109
Sci-Fi	110
Romance	111
School	112
Drama	113
Drama	114
Horror	115
Drama	116
Fighting	117
Adventure	118
School	119
Romance	120
Drama	121
Fantasy	122
Sci-Fi	123
Sci-Fi	124
Fighting	125
Sci-Fi	126
Drama	127
Fantasy	128
Romance	129
School	130
School	131
Fighting	132
School	133
School	134
Adventure	135
Romance	136
Science	137
Horror	138
Fighting	139
Romance	140
Fantasy	141
Comedy	142
Fantasy	143
Sci-Fi	144
School	145
Fantasy	146
Fantasy	147
Comedy	148
Fighting	149
Adventure	150
School	151
Romance	152
Horror	153
School	154
Science	155
Sci-Fi	156
Comedy	157
Fantasy	158
Comedy	159
Fighting	160
Drama	161
School	162
Romance	163
Fantasy	164
School	165
University	166
Horror	167
Fantasy	168
Adventure	169
Fighting	170
Adventure	171
School	172
Science	173
Adventure	174
School	175
Adventure	176
Comedy	177
Drama	178
Drama	179
Sci-Fi	180
University	181
Drama	182
Fighting	183
Science	184
School	185
Fantasy	186
Fantasy	187
Science	188
Romance	189
Sci-Fi	190
Fighting	191
Horror	192
Science	193
University	194
Fighting	195
Horror	196
Comedy	197
Romance	198
Romance	199
Sci-Fi	200
University	201
Fighting	202
Fantasy	203
Drama	204
Horror	205
Comedy	206
Adventure	207
University	208
Horror	209
Comedy	210
Adventure	211
Comedy	212
Comedy	213
Science	214
Drama	215
Science	216
School	217
Fantasy	218
Comedy	219
Fighting	220
Fighting	221
Fantasy	222
Fighting	223
Drama	224
Romance	225
Science	226
Comedy	227
Sci-Fi	228
Science	229
Fantasy	230
Horror	231
Adventure	232
School	233
Comedy	234
Science	235
Adventure	236
Fantasy	237
Sci-Fi	238
Fighting	239
Science	240
School	241
Horror	242
Adventure	243
Science	244
Comedy	245
Adventure	246
Science	247
Drama	248
Science	249
Adventure	250
Comedy	251
Drama	252
Fantasy	253
Comedy	254
Fighting	255
Comedy	256
Fantasy	257
Science	258
School	259
Fantasy	260
Sci-Fi	261
Romance	262
University	263
Science	264
Sci-Fi	265
Science	266
University	267
Science	268
School	269
Sci-Fi	270
Drama	271
Romance	272
Drama	273
Adventure	274
Sci-Fi	275
Romance	276
Comedy	277
Adventure	278
Fantasy	279
Horror	280
Fantasy	281
Science	282
Science	283
University	284
Fantasy	285
Sci-Fi	286
Science	287
University	288
Fantasy	289
School	290
Sci-Fi	291
Adventure	292
School	293
School	294
Fighting	295
Science	296
Sci-Fi	297
Adventure	298
Comedy	299
University	300
Drama	301
Fantasy	302
University	303
Fighting	304
University	305
Adventure	306
Romance	307
Fighting	308
Sci-Fi	309
University	310
Comedy	311
Science	312
Comedy	313
Science	314
Science	315
Drama	316
Fantasy	317
Adventure	318
Adventure	319
Fantasy	320
Adventure	321
Comedy	322
University	323
Adventure	324
Sci-Fi	325
Drama	326
Science	327
Romance	328
Sci-Fi	329
University	330
Fantasy	331
Fantasy	332
Fantasy	333
Fantasy	334
Fighting	335
Horror	336
Sci-Fi	337
Sci-Fi	338
Science	339
School	340
Comedy	341
Drama	342
University	343
Sci-Fi	344
Science	345
Sci-Fi	346
School	347
Sci-Fi	348
Fantasy	349
School	350
School	351
Fantasy	352
School	353
Drama	354
University	355
University	356
Science	357
Fighting	358
Sci-Fi	359
Drama	360
Comedy	361
University	362
Adventure	363
Adventure	364
Drama	365
Sci-Fi	366
Horror	367
Romance	368
School	369
Sci-Fi	370
Science	371
Comedy	372
Science	373
School	374
Comedy	375
Drama	376
University	377
University	378
Sci-Fi	379
Science	380
Sci-Fi	381
Fantasy	382
University	383
Drama	384
School	385
Drama	386
School	387
Science	388
Adventure	389
School	390
Fighting	391
Fantasy	392
Comedy	393
Science	394
Fantasy	395
Adventure	396
Comedy	397
Sci-Fi	398
Drama	399
Adventure	400
Romance	1
Comedy	2
Adventure	3
Drama	4
Fantasy	5
Fantasy	6
Fantasy	7
Romance	8
Science	10
Drama	12
Adventure	13
School	14
Sci-Fi	15
School	16
Fantasy	17
Adventure	18
Horror	19
Adventure	21
Drama	22
Science	25
Comedy	26
University	27
University	28
Comedy	29
Romance	30
Romance	31
Sci-Fi	32
Science	33
Comedy	34
Science	35
Adventure	36
Adventure	37
University	38
Romance	39
Horror	40
Adventure	41
Science	42
Romance	43
Adventure	44
Sci-Fi	45
Drama	46
Science	47
Romance	48
Sci-Fi	49
Sci-Fi	51
Adventure	52
School	53
University	54
Horror	55
Sci-Fi	56
Fantasy	57
Science	58
Comedy	59
Horror	60
University	61
School	62
Romance	63
Romance	64
Adventure	66
Fighting	67
Drama	68
Sci-Fi	69
Romance	70
University	71
Romance	72
School	73
University	74
Fighting	75
School	76
School	77
Romance	78
Romance	79
University	80
Science	81
Drama	82
University	83
Romance	84
Romance	85
School	86
Comedy	87
School	88
University	91
Science	92
School	93
Fantasy	94
Drama	95
Fantasy	96
University	97
Romance	98
Science	99
Fantasy	100
Fantasy	102
Horror	103
University	104
Romance	105
Romance	106
Comedy	107
Fantasy	108
School	110
Drama	111
University	112
Fighting	113
School	114
Adventure	115
Romance	116
University	117
Comedy	118
School	120
University	121
Science	122
University	123
Drama	124
Comedy	125
Science	126
Horror	127
Science	128
School	129
Romance	130
University	131
Science	132
University	134
Romance	135
Adventure	136
University	138
Romance	139
Horror	141
Science	143
Science	144
Science	145
School	146
Fighting	147
Romance	148
Horror	150
Fantasy	151
Comedy	152
Romance	153
Adventure	154
Drama	156
Romance	157
Drama	158
Drama	159
Science	161
University	162
School	163
University	164
School	167
School	168
University	169
School	170
Fighting	172
Horror	173
Romance	174
Science	175
Fighting	176
Horror	177
University	178
Science	179
Comedy	180
Horror	181
University	182
Sci-Fi	183
Fantasy	184
Fighting	185
Romance	186
Adventure	187
Fighting	188
Fighting	189
Fighting	190
Sci-Fi	192
Sci-Fi	193
Romance	194
Romance	195
School	196
School	197
School	198
Adventure	199
Fantasy	200
Sci-Fi	201
Science	202
University	203
School	204
Fighting	205
Fighting	206
Science	207
Sci-Fi	208
Romance	210
Fighting	212
Science	213
Horror	214
University	215
School	216
Romance	217
Sci-Fi	218
Drama	219
Adventure	220
Comedy	222
Horror	223
Adventure	224
School	225
Fantasy	226
Fantasy	227
University	228
Fantasy	229
School	230
University	231
School	232
Science	233
Science	234
School	235
Comedy	236
Horror	237
Comedy	238
Adventure	239
Sci-Fi	240
Horror	241
Adventure	242
Comedy	243
Horror	244
Romance	245
School	246
Comedy	247
Sci-Fi	248
School	249
Drama	250
Fantasy	251
Fantasy	252
Sci-Fi	253
Romance	254
Romance	255
Adventure	257
Comedy	259
University	260
Adventure	261
Adventure	262
Sci-Fi	263
Sci-Fi	264
Romance	265
Comedy	266
Romance	267
Fantasy	268
Fighting	269
Romance	270
Comedy	271
University	272
Sci-Fi	273
Drama	275
Sci-Fi	276
School	277
Fighting	278
University	279
Fighting	280
Sci-Fi	281
Romance	283
Horror	284
Adventure	285
Fighting	286
Fantasy	288
University	289
Drama	290
University	291
Sci-Fi	292
Comedy	293
University	294
Comedy	295
Romance	297
School	298
Adventure	299
Horror	300
School	301
School	302
Drama	303
University	304
Adventure	305
Science	306
Sci-Fi	307
Science	308
School	309
School	310
Romance	311
University	312
Horror	313
Comedy	314
University	315
Fantasy	316
Horror	317
Comedy	318
Sci-Fi	319
Fighting	320
Fantasy	321
Fighting	322
Fantasy	323
Romance	324
Romance	325
Comedy	326
Horror	327
Romance	329
Fighting	330
Comedy	331
Horror	332
Drama	333
Science	334
Comedy	335
University	336
University	337
Adventure	338
Drama	340
University	341
Fantasy	342
Adventure	343
Science	344
Fantasy	345
University	347
Horror	348
Horror	350
Science	351
Horror	352
Fantasy	353
Science	355
School	356
Adventure	357
Drama	359
School	360
Fantasy	361
Fantasy	362
Romance	364
Fighting	365
Horror	366
Adventure	367
Comedy	368
Fantasy	369
Romance	370
Adventure	371
Horror	372
Fantasy	374
Fantasy	375
University	376
Horror	377
Comedy	378
University	379
Romance	380
Romance	381
Drama	383
Comedy	386
Science	387
Sci-Fi	388
Horror	389
University	390
University	391
Adventure	392
Sci-Fi	393
School	394
Science	395
School	396
Horror	398
Fighting	399
Comedy	400
\.


--
-- Data for Name: images; Type: TABLE DATA; Schema: public; Owner: kirill
--

COPY public.images (id, comic_id, img_path, img_name) FROM stdin;
1	1	comicimages/	buddy-longway_3-1.jpg
2	2	comicimages/	grackle_3-1.jpg
3	3	comicimages/	los-4-fantasticos_98-4.jpg
4	4	comicimages/	weapon-zero_5-1.jpg
5	5	comicimages/	normalman_5-1.jpg
6	6	comicimages/	revere_1-1.jpg
7	7	comicimages/	supergirl_75-1.jpg
8	8	comicimages/	astro-boy_4-1.jpg
9	9	comicimages/	punisher-mini-series_5-5.jpg
10	10	comicimages/	marshal-blueberry_1-3.jpg
11	11	comicimages/	cine-mondial_27-1.jpg
12	12	comicimages/	millie-the-model_99-10.jpg
13	13	comicimages/	escalator_1-1.jpg
14	14	comicimages/	batman-gotham-nights_4-1.jpg
15	15	comicimages/	liberty-meadows_3-1.jpg
16	16	comicimages/	challengers-of-the-fantastic_1-1.jpg
17	17	comicimages/	falling-in-love_49-6.jpg
18	18	comicimages/	thrilling-comics_65-1.jpg
19	19	comicimages/	bat-thing_1-1.jpg
20	20	comicimages/	true-adventures_13-1.jpg
21	21	comicimages/	russian-dvds_95-1.jpg
22	22	comicimages/	strange-sports-stories_2-1.jpg
23	23	comicimages/	3d-batman_1-1.jpg
24	24	comicimages/	rivets_1-1.jpg
25	25	comicimages/	sire_1-1.jpg
26	26	comicimages/	blue-inferior_1-1.jpg
27	27	comicimages/	avon-fantasy-reader_17-1.jpg
28	28	comicimages/	smash_137-1.jpg
29	29	comicimages/	durango_7-9.jpg
30	30	comicimages/	bogie-man_4-1.jpg
31	31	comicimages/	grusel-schocker_42-1.jpg
32	32	comicimages/	arm_1-1.jpg
33	33	comicimages/	avengers-1998_81-1.jpg
34	34	comicimages/	flash-gordon_24-1.jpg
35	35	comicimages/	3-x-3-augen_29-1.jpg
36	36	comicimages/	planet-of-the-apes_3-1.jpg
37	37	comicimages/	rick-master-kult-editionen_40-3.jpg
38	38	comicimages/	icon_3-1.jpg
39	39	comicimages/	brute_2-1.jpg
40	40	comicimages/	new-man_1-1.jpg
41	41	comicimages/	crisis_40-1.jpg
42	42	comicimages/	battle_61-1.jpg
43	43	comicimages/	thorgal_16-4.jpg
44	44	comicimages/	neotopia-3_3-1.jpg
45	45	comicimages/	hoshin-engi_1-1.jpg
46	46	comicimages/	daring-mystery_11-1.jpg
47	47	comicimages/	astounding-stories_729-1.jpg
48	48	comicimages/	ein-fall-fuer-jeff-jordan_1-1.jpg
49	49	comicimages/	force-of-buddhas-palm_51-1.jpg
50	50	comicimages/	electrical-experimenter_50-1.jpg
51	51	comicimages/	science-books_290-3.jpg
52	52	comicimages/	batman-dark-knight-strikes-again_2-1.jpg
53	53	comicimages/	country-gentleman_53-1.jpg
54	54	comicimages/	new-story-magazine_18-1.jpg
55	55	comicimages/	prinz-eisenherz_12-4.jpg
56	56	comicimages/	infinity-gauntlet_4-1.jpg
57	57	comicimages/	doom-2099_5-1.jpg
58	58	comicimages/	black-coat_1-1.jpg
59	59	comicimages/	justice-league-america_79-1.jpg
60	60	comicimages/	new-gods_4-1.jpg
61	61	comicimages/	betty-veronica-summer-fun_1-1.jpg
62	62	comicimages/	digital-graffiti_3-1.jpg
63	63	comicimages/	nam_71-1.jpg
64	64	comicimages/	wizard_55-5.jpg
65	65	comicimages/	daredevil_366-1.jpg
66	66	comicimages/	tozzer-2_3-1.jpg
67	67	comicimages/	lustiges-taschenbuch_235-1.jpg
68	68	comicimages/	.DS_Store
69	69	comicimages/	search-for-love_1-1.jpg
70	70	comicimages/	pluck-and-luck_14-1.jpg
71	71	comicimages/	amazing-man-comics_17-9.jpg
72	72	comicimages/	sky-ape_1-1.jpg
73	73	comicimages/	jughead-with-archie-digest_41-1.jpg
74	74	comicimages/	jughead-friends-digest_7-1.jpg
75	75	comicimages/	backlash_25-1.jpg
76	76	comicimages/	famous-fantastic_31-1.jpg
77	77	comicimages/	wartime-romances_16-8.jpg
78	78	comicimages/	pm-computerheft_23-2.jpg
79	79	comicimages/	baraka-and-black-magic-in-morocco_1-1.jpg
80	80	comicimages/	aquaman_35-1.jpg
81	81	comicimages/	conan-the-king_22-8.jpg
82	82	comicimages/	sandman-mystery-theatre_44-1.jpg
83	83	comicimages/	black-mask_38-1.jpg
84	84	comicimages/	out-of-this-world_8-1.jpg
85	85	comicimages/	saucy-movie_7-1.jpg
86	86	comicimages/	dragonring_4-1.jpg
87	87	comicimages/	canton-kid_3-1.jpg
88	88	comicimages/	monsters-from-outer-space_3-1.jpg
89	89	comicimages/	thunder-agents_17-1.jpg
90	90	comicimages/	police-comics_68-1.jpg
91	91	comicimages/	puma-blues_6-1.jpg
92	92	comicimages/	how-to-draw-transforming-robots_1-1.jpg
93	93	comicimages/	a1_6-1.jpg
94	94	comicimages/	superman-birthright_3-1.jpg
95	95	comicimages/	whats-michael_2-1.jpg
96	96	comicimages/	exciting-sports_19-1.jpg
97	97	comicimages/	simpsons-comics_31-1.jpg
98	98	comicimages/	bloodthirst_2-1.jpg
99	99	comicimages/	arena37c_47-1.jpg
100	100	comicimages/	aquaman-german_9-3.jpg
101	101	comicimages/	astounding-stories_841-1.jpg
102	102	comicimages/	falken-der-meere_2-7.jpg
103	103	comicimages/	archie-at-riverdale-high_2-1.jpg
104	104	comicimages/	dangerous-secrets_1-1.jpg
105	105	comicimages/	netherworlds_1-1.jpg
106	106	comicimages/	sam-and-twitch_26-1.jpg
107	107	comicimages/	adam-and-eve-ad_1-1.jpg
108	108	comicimages/	black-hole_9-12.jpg
109	109	comicimages/	don-winslow-of-the-navy_46-6.jpg
110	110	comicimages/	percy-pickwick_9-1.jpg
111	111	comicimages/	retief-and-the-warlords_2-1.jpg
112	112	comicimages/	thrills-incorporated_8-1.jpg
113	113	comicimages/	c64-games_1910-1.jpg
114	114	comicimages/	new-avengers_1-1.jpg
115	115	comicimages/	devils-keeper_3-1.jpg
116	116	comicimages/	bartman_6-1.jpg
117	117	comicimages/	american-rifleman_100-2.jpg
118	118	comicimages/	anima_5-5.jpg
119	119	comicimages/	tarzan-collection_6-3.jpg
120	120	comicimages/	western-yarns_1-1.jpg
121	121	comicimages/	books-about-movies_22-2.jpg
122	122	comicimages/	madonna_74-1.jpg
123	123	comicimages/	x-patrol_1-1.jpg
124	124	comicimages/	aquaman_29-1.jpg
125	125	comicimages/	yenny_5-1.jpg
126	126	comicimages/	halle-the-hooters-girl_1-1.jpg
127	127	comicimages/	adventures-on-the-planet-of-the-apes_4-9.jpg
128	128	comicimages/	apple-ii-games_36-1.jpg
129	129	comicimages/	superman-presents-tip-top_94-1.jpg
130	130	comicimages/	dune-buggies-and-hot-vws_57-8.jpg
131	131	comicimages/	boneyard_14-1.jpg
132	132	comicimages/	batman-face-the-face_1-1.jpg
133	133	comicimages/	sixgun-samurai_5-1.jpg
134	134	comicimages/	destructor_1-1.jpg
135	135	comicimages/	police-detective-cases_9-1.jpg
136	136	comicimages/	richie-rich-bank-books_20-1.jpg
137	137	comicimages/	all-funny-comics_22-6.jpg
138	138	comicimages/	paper-theater_1-1.jpg
139	139	comicimages/	next_22-3.jpg
140	140	comicimages/	thrilling-western_12-1.jpg
141	141	comicimages/	sega-magazin_57-2.jpg
142	142	comicimages/	kalle-anka-co_28-3.jpg
143	143	comicimages/	amiga-special_50-4.jpg
144	144	comicimages/	buffalo-bill_5-8.jpg
145	145	comicimages/	popeye_61-1.jpg
146	146	comicimages/	crimson_9-1.jpg
147	147	comicimages/	western-yarns_3-1.jpg
148	148	comicimages/	youngblood-strikefile_7-8.jpg
149	149	comicimages/	naru-taru_9-1.jpg
150	150	comicimages/	umpah-pah_5-5.jpg
151	151	comicimages/	skeleton-hand_1-1.jpg
152	152	comicimages/	challengers-of-the-unknown_15-1.jpg
153	153	comicimages/	herbie-1991_1-1.jpg
154	154	comicimages/	those-who-hunt-elves_4-1.jpg
155	155	comicimages/	pc-player_46-3.jpg
156	156	comicimages/	dylan-dog_33-1.jpg
157	157	comicimages/	batman-dark-victory_2-1.jpg
158	158	comicimages/	batman-cult_2-1.jpg
159	159	comicimages/	spirit-of-the-tao_4-16.jpg
160	160	comicimages/	die-gringos_6-4.jpg
161	161	comicimages/	tarzan-collection_4-7.jpg
162	162	comicimages/	robotech-vermilion_4-1.jpg
163	163	comicimages/	tweety-and-sylvester_104-1.jpg
164	164	comicimages/	c64-games_932-1.jpg
165	165	comicimages/	outlaw-nation_17-1.jpg
166	166	comicimages/	armorquest_2-1.jpg
167	167	comicimages/	superman-for-earth_1-1.jpg
168	168	comicimages/	danger-girl_2-1.jpg
169	169	comicimages/	other-worlds-science-stories_1-1.jpg
170	170	comicimages/	commando_2781-1.jpg
171	171	comicimages/	wolverine-2003_19-1.jpg
172	172	comicimages/	rex-morgan-md_3-1.jpg
173	173	comicimages/	x-isle_3-1.jpg
174	174	comicimages/	iron-lantern_1-1.jpg
175	175	comicimages/	dragonring-2_12-1.jpg
176	176	comicimages/	daemonen-land_116-1.jpg
177	177	comicimages/	ghost_35-1.jpg
178	178	comicimages/	wilbur_50-1.jpg
179	179	comicimages/	bumperboy_1-1.jpg
180	180	comicimages/	silver-surfer-2003_9-1.jpg
181	181	comicimages/	spider-man-books_51-4.jpg
182	182	comicimages/	superman-4-movie_1-1.jpg
183	183	comicimages/	union-jacks_1-1.jpg
184	184	comicimages/	greyshirt_3-1.jpg
185	185	comicimages/	dennis-the-menace_127-1.jpg
186	186	comicimages/	world-war-hulk_4-1.jpg
187	187	comicimages/	wampus_3-1.jpg
188	188	comicimages/	wonder-man_3-1.jpg
189	189	comicimages/	powers-that-be_3-1.jpg
190	190	comicimages/	white-princess-of-the-jungle_3-1.jpg
191	191	comicimages/	spy-stories_2-1.jpg
192	192	comicimages/	venus-wars-ii_6-2.jpg
193	193	comicimages/	gentlemen-gmbh_2-2.jpg
194	194	comicimages/	ir_3-6.jpg
195	195	comicimages/	stark-future_10-1.jpg
196	196	comicimages/	shadow-comics_26-1.jpg
197	197	comicimages/	black-fury_57-1.jpg
198	198	comicimages/	assassin-school-2_2-1.jpg
199	199	comicimages/	captain-america-2004_28-1.jpg
200	200	comicimages/	everythings-archie_133-1.jpg
201	201	comicimages/	batman-dark-knight-returns_4-1.jpg
202	202	comicimages/	barbie_52-1.jpg
203	203	comicimages/	winnie-the-pooh_2-4.jpg
204	204	comicimages/	complete-cowboy-magazine_18-1.jpg
205	205	comicimages/	donald-duck-adventures_30-1.jpg
206	206	comicimages/	lassie_42-1.jpg
207	207	comicimages/	house-of-frightenstein_1-1.jpg
208	208	comicimages/	hardware_37-1.jpg
209	209	comicimages/	love-romances_76-1.jpg
210	210	comicimages/	cgc-10-comics_21-1.jpg
211	211	comicimages/	reggie-and-me_66-1.jpg
212	212	comicimages/	sure-fire-comics_4-1.jpg
213	213	comicimages/	gadget_1-1.jpg
214	214	comicimages/	star-trek-the-next-generation_16-3.jpg
215	215	comicimages/	aquaman-german_6-2.jpg
216	216	comicimages/	novel-library_38-1.jpg
217	217	comicimages/	badger_50-1.jpg
218	218	comicimages/	fate_344-1.jpg
219	219	comicimages/	murderous-gangsters_1-1.jpg
220	220	comicimages/	smithsonian_272-6.jpg
221	221	comicimages/	twin-signal_1-1.jpg
222	222	comicimages/	all-romances_4-1.jpg
223	223	comicimages/	rogue_1-1.jpg
224	224	comicimages/	hulk-2008_12-5.jpg
225	225	comicimages/	illustrierte-klassiker_74-7.jpg
226	226	comicimages/	kingdom-come_2-1.jpg
227	227	comicimages/	young-lovers_1-1.jpg
228	228	comicimages/	off-beat-detective-stories_2-1.jpg
229	229	comicimages/	turbo-hi-tech-performance_9-5.jpg
230	230	comicimages/	henry_32-1.jpg
231	231	comicimages/	league-of-extraordinary-gentlemen_3-1.jpg
232	232	comicimages/	ironman_3-7.jpg
233	233	comicimages/	molly-o-day_1-1.jpg
234	234	comicimages/	dragonforce-chronicles_3-1.jpg
235	235	comicimages/	turok-spring-break-in-the-lost-land_1-1.jpg
236	236	comicimages/	boys-and-their-cars_19-1.jpg
237	237	comicimages/	men_1-1.jpg
238	238	comicimages/	pizzeria-kamikaze_1-1.jpg
239	239	comicimages/	mick-tangy_4-2.jpg
240	240	comicimages/	new-gods_9-1.jpg
241	241	comicimages/	fifteen-western-tales_45-1.jpg
242	242	comicimages/	sad-sack_54-1.jpg
243	243	comicimages/	mothers-mouth_1-1.jpg
244	244	comicimages/	hellblazer_188-1.jpg
245	245	comicimages/	hip-hop-books_84-4.jpg
246	246	comicimages/	super-soldier_1-1.jpg
247	247	comicimages/	generations-2_1-1.jpg
248	248	comicimages/	vampire-girls_2-1.jpg
249	249	comicimages/	battle-of-the-planets_4-1.jpg
250	250	comicimages/	science-fiction-monthly_8-1.jpg
251	251	comicimages/	el-gato_2-1.jpg
252	252	comicimages/	gang-world_11-1.jpg
253	253	comicimages/	perma-books_104-1.jpg
254	254	comicimages/	myriad_2-1.jpg
255	255	comicimages/	alpha-shade_1-1.jpg
256	256	comicimages/	war-stories_4-1.jpg
257	257	comicimages/	west-coast-avengers_11-1.jpg
258	258	comicimages/	der-magier_31-1.jpg
259	259	comicimages/	richie-rich-money-world_15-1.jpg
260	260	comicimages/	mans-life_7-1.jpg
261	261	comicimages/	peter-parker-spider-man_37-1.jpg
262	262	comicimages/	jughead-friends-digest_8-1.jpg
263	263	comicimages/	deadfish-bedeviled_1-1.jpg
264	264	comicimages/	brooklyn-dreams_1-1.jpg
265	265	comicimages/	thor-1998_50-1.jpg
266	266	comicimages/	colonial-homes_64-3.jpg
267	267	comicimages/	spanish-dvds_445-1.jpg
268	268	comicimages/	message-in-a-bottle_1-1.jpg
269	269	comicimages/	colby_2-4.jpg
270	270	comicimages/	funny-stuff_9-1.jpg
271	271	comicimages/	etude_23-1.jpg
272	272	comicimages/	white-death_1-1.jpg
273	273	comicimages/	djinn_2-1.jpg
274	274	comicimages/	der-neue-superman-handbuch_1-3.jpg
275	275	comicimages/	buffy-the-vampire-slayer-books_252-9.jpg
276	276	comicimages/	tomb-raider_21-1.jpg
277	277	comicimages/	chaser-platoon_1-1.jpg
278	278	comicimages/	astonishing_38-1.jpg
279	279	comicimages/	south-park-books_35-1.jpg
280	280	comicimages/	all-man_3-1.jpg
281	281	comicimages/	troublemakers_11-1.jpg
282	282	comicimages/	richie-rich-success-stories_55-1.jpg
283	283	comicimages/	mark-hellmann_12-1.jpg
284	284	comicimages/	all-funny-comics_17-2.jpg
285	285	comicimages/	world-war-iii_1-1.jpg
286	286	comicimages/	police_30-1.jpg
287	287	comicimages/	kade_1-1.jpg
288	288	comicimages/	my-greatest-adventure_70-1.jpg
289	289	comicimages/	worst-album-covers_25-1.jpg
290	290	comicimages/	candy-wrappers_1391-4.jpg
291	291	comicimages/	astro-boy_9-1.jpg
292	292	comicimages/	leatherface_1-1.jpg
293	293	comicimages/	famous-monsters-of-filmland_81-4.jpg
294	294	comicimages/	new-worlds_34-1.jpg
295	295	comicimages/	magic-comics_93-1.jpg
296	296	comicimages/	new-worlds-fiction_3-1.jpg
297	297	comicimages/	gokinjo-monogatari_1-1.jpg
298	298	comicimages/	adrenaline_3-1.jpg
299	299	comicimages/	mark-hellmann_6-1.jpg
300	300	comicimages/	ninjak_9-1.jpg
301	301	comicimages/	all-detective-magazine_20-1.jpg
302	302	comicimages/	xenon_3-1.jpg
303	303	comicimages/	bloodshot_21-1.jpg
304	304	comicimages/	lustiges-taschenbuch-neuauflage_13-1.jpg
305	305	comicimages/	jsa_73-1.jpg
306	306	comicimages/	special-detective_7-1.jpg
307	307	comicimages/	design-books_197-5.jpg
308	308	comicimages/	7-days-to-fame_3-1.jpg
309	309	comicimages/	architectural-digest_179-7.jpg
310	310	comicimages/	little-snow-fairy-sugar_2-1.jpg
311	311	comicimages/	secret-origins-1986_39-16.jpg
312	312	comicimages/	mighty-world-of-marvel_23-1.jpg
313	313	comicimages/	profolio_1-1.jpg
314	314	comicimages/	midnight_5-1.jpg
315	315	comicimages/	straw-men_6-1.jpg
316	316	comicimages/	funnies_24-1.jpg
317	317	comicimages/	ironman_29-3.jpg
318	318	comicimages/	buck-duck_1-1.jpg
319	319	comicimages/	spider-man-fairy-tales_1-1.jpg
320	320	comicimages/	archie_249-1.jpg
321	321	comicimages/	sojourn_9-1.jpg
322	322	comicimages/	okko_1-1.jpg
323	323	comicimages/	trollords_2-1.jpg
324	324	comicimages/	naughty-bits_19-1.jpg
325	325	comicimages/	cowboy-stories_33-1.jpg
326	326	comicimages/	hit-comics_38-1.jpg
327	327	comicimages/	archies-madhouse_6-1.jpg
328	328	comicimages/	punisher_93-8.jpg
329	329	comicimages/	jsa_61-12.jpg
330	330	comicimages/	rumblestrips_1-1.jpg
331	331	comicimages/	turok-timewalker_1-1.jpg
332	332	comicimages/	next_6-8.jpg
333	333	comicimages/	rg-veda_1-1.jpg
334	334	comicimages/	mystery-adventures_2-1.jpg
335	335	comicimages/	killer_1-1.jpg
336	336	comicimages/	premier-magazine_5-1.jpg
337	337	comicimages/	love-letters_6-1.jpg
338	338	comicimages/	mega-dragon-tiger_2-2.jpg
339	339	comicimages/	die-gringos_5-9.jpg
340	340	comicimages/	madman_5-1.jpg
341	341	comicimages/	elfenwelt_3-1.jpg
342	342	comicimages/	spectre_3-1.jpg
343	343	comicimages/	dime-mystery_31-1.jpg
344	344	comicimages/	rg-veda_3-1.jpg
345	345	comicimages/	captain-marvel_59-2.jpg
346	346	comicimages/	justice-league-america_91-1.jpg
347	347	comicimages/	economist_1741-6.jpg
348	348	comicimages/	stray-bullets_1-1.jpg
349	349	comicimages/	tv-action-countdown_102-16.jpg
350	350	comicimages/	tales-of-the-unexpected_218-1.jpg
351	351	comicimages/	ari_1-1.jpg
352	352	comicimages/	little-monsters_35-1.jpg
353	353	comicimages/	xiii_1-1.jpg
354	354	comicimages/	baby-huey-and-papa_16-1.jpg
355	355	comicimages/	battle-binder-plus_4-1.jpg
356	356	comicimages/	archies-joke-book_174-1.jpg
357	357	comicimages/	apocalypse_3-1.jpg
358	358	comicimages/	el-gato_1-1.jpg
359	359	comicimages/	dead-heat_1-1.jpg
360	360	comicimages/	diary-loves_14-1.jpg
361	361	comicimages/	worlds-finest-1999_1-1.jpg
362	362	comicimages/	maxx_1-1.jpg
363	363	comicimages/	xenon_2-1.jpg
364	364	comicimages/	how-to-draw-manga-next-generation_9-1.jpg
365	365	comicimages/	warrior-nun-areala-ghosts-of-the-past_4-1.jpg
366	366	comicimages/	anthro_4-1.jpg
367	367	comicimages/	wow_1-1.jpg
368	368	comicimages/	first-love-illustrated_53-5.jpg
369	369	comicimages/	adventure-comics_117-1.jpg
370	370	comicimages/	my-romantic-adventures_117-1.jpg
371	371	comicimages/	pendulum_1-1.jpg
372	372	comicimages/	die-blauen-boys_12-1.jpg
373	373	comicimages/	wretch_5-1.jpg
374	374	comicimages/	marvel-comics_73-1.jpg
375	375	comicimages/	bloodshot_39-1.jpg
376	376	comicimages/	history-books_882-6.jpg
377	377	comicimages/	team-nippon_2-1.jpg
378	378	comicimages/	bluesman_3-1.jpg
379	379	comicimages/	perma-books_493-1.jpg
380	380	comicimages/	junge-giganten_10-9.jpg
381	381	comicimages/	arik-khan_1-1.jpg
382	382	comicimages/	new-mutants_37-1.jpg
383	383	comicimages/	x-men-fairy-tales_1-1.jpg
384	384	comicimages/	goofy-comics_3-1.jpg
385	385	comicimages/	four-color_1255-1.jpg
386	386	comicimages/	toxic_4-1.jpg
387	387	comicimages/	silver-surfer_14-1.jpg
388	388	comicimages/	my-greatest-adventure_10-1.jpg
389	389	comicimages/	fantasy-and-science-fiction_80-1.jpg
390	390	comicimages/	innomables_4-1.jpg
391	391	comicimages/	flex_116-8.jpg
392	392	comicimages/	adventures-of-dean-martin-and-jerry-lewis_26-8.jpg
393	393	comicimages/	gravitation_11-1.jpg
394	394	comicimages/	dragonforce-chronicles_4-1.jpg
395	395	comicimages/	mutant-x_14-1.jpg
396	396	comicimages/	cages_9-1.jpg
\.


--
-- Data for Name: log; Type: TABLE DATA; Schema: public; Owner: kirill
--

COPY public.log ("time", description, purchase_id) FROM stdin;
2020-06-11 02:15:22.693783	paid	8
2020-06-11 02:22:49.195683	delivered	8
2020-06-11 02:26:51.334096	paid	8
2020-06-11 18:07:05.770688	paid	9
2020-06-11 20:25:19.165693	delivered	9
2020-06-11 20:27:56.967153	canceled	9
2020-06-11 20:28:22.853643	paid	10
2020-06-11 20:33:22.729143	canceled	10
2020-06-11 20:36:28.272907	paid	11
2020-06-11 20:41:43.592272	canceled	11
\.


--
-- Data for Name: publishers; Type: TABLE DATA; Schema: public; Owner: kirill
--

COPY public.publishers (publisher_id, name) FROM stdin;
1	Consectetuer Adipiscing Incorporated
2	Magna A Neque Consulting
3	Proin Nisl Foundation
4	Sed Libero PC
5	Sit Amet LLP
6	Bibendum Donec Industries
7	Consectetuer Rhoncus Nullam PC
8	Nec Institute
9	Dui Semper Et Associates
10	Natoque Penatibus Associates
11	Ac Consulting
12	Neque Non Industries
13	Et Commodo Foundation
14	Sapien Cras Institute
15	Dolor Quam Elementum Company
16	Mauris Molestie Pharetra Limited
17	Vel Lectus Cum PC
18	Interdum Libero Associates
19	Lobortis Associates
20	A Company
21	Vitae Risus LLP
22	Ultrices A Auctor Foundation
23	Ultricies Dignissim Incorporated
24	Pharetra Nibh Aliquam LLC
25	Tellus Eu Augue Inc.
26	Egestas Rhoncus Institute
27	Nullam Ut Nisi Ltd
28	Volutpat Nulla Facilisis Institute
29	Neque Ltd
30	Rutrum Fusce Dolor Ltd
31	Tellus Corp.
32	Sit Amet PC
33	Eu Dolor Egestas LLC
34	Est Ac Mattis Incorporated
35	Sed Dolor Inc.
36	Tristique Neque Associates
37	Nunc Nulla Ltd
38	Blandit Institute
39	Vitae Nibh Donec Corp.
40	Semper Corp.
41	Eget Mollis Lectus Foundation
42	A Consulting
43	Diam Lorem Corp.
44	Fringilla Ornare Placerat Associates
45	Augue Id Limited
46	Ut Mi Corporation
47	Varius Et Ltd
48	In Ornare Sagittis Associates
49	Maecenas Malesuada LLC
50	Mauris Molestie Pharetra LLP
51	Rhoncus Corp.
52	Etiam PC
53	Luctus Foundation
54	In Condimentum Donec Foundation
55	Gravida LLC
56	Dolor PC
57	Tristique Consulting
58	Et Magnis Dis Foundation
59	Elit Sed Consulting
60	At Libero Industries
61	Ligula Aliquam Limited
62	Donec Consulting
63	Nunc Laoreet LLC
64	Tempor Diam Dictum LLC
65	Nisl Corp.
66	Ac Mattis Velit Associates
67	Neque Foundation
68	Odio Tristique Industries
69	Eu Euismod Ac LLP
70	Euismod Et Commodo Inc.
71	Ut Company
72	Vel Lectus Cum Consulting
73	Fusce Aliquam Enim Associates
74	Proin Limited
75	Suspendisse Industries
76	Porttitor Tellus Company
77	Pretium Neque Corporation
78	Posuere Ltd
79	Tristique Pellentesque Corporation
80	Molestie Inc.
81	Auctor Nunc Limited
82	Nibh Foundation
83	Turpis Aliquam Inc.
84	Metus Vivamus Euismod LLC
85	Vulputate Dui Nec Company
86	Vestibulum Ut Eros Associates
87	Elit PC
88	Netus Et Malesuada LLC
89	Donec Fringilla Ltd
90	Quisque Associates
91	Adipiscing Elit LLP
92	Purus Gravida Foundation
93	Et Malesuada Foundation
94	Mauris Ut Inc.
95	Semper LLP
96	Neque Non Quam Institute
97	Sodales Elit Erat Associates
98	Dui Inc.
99	Quam Vel LLC
100	Amet Ornare Ltd
\.


--
-- Data for Name: purchase; Type: TABLE DATA; Schema: public; Owner: kirill
--

COPY public.purchase (purchase_id, date, price, customer_id, employee_id, status) FROM stdin;
9	2020-06-11 18:07:05.770688	$10.00	1	1	canceled
10	2020-06-11 20:28:22.853643	$40.00	1	\N	canceled
11	2020-06-11 20:36:28.272907	$50.00	1	\N	canceled
\.


--
-- Data for Name: purchased_book; Type: TABLE DATA; Schema: public; Owner: kirill
--

COPY public.purchased_book (book_id, purchase_id, quanity) FROM stdin;
1	9	100
1	10	10
2	10	10
3	10	10
1	11	10
3	11	5
9	11	10
4	11	10
\.


--
-- Data for Name: reviews; Type: TABLE DATA; Schema: public; Owner: kirill
--

COPY public.reviews (review_id, comic_id, customer_id, rating, overall, pros, cons, date) FROM stdin;
5	1	1	5	\N	\N	\N	2020-06-10 17:54:57.513562
9	1	11	10	nice	nice	not nice	2020-06-10 17:55:56.785995
11	2	90	7	\N	\N	\N	2020-06-10 18:51:10.442313
12	47	43	2	luctus vulputate,	Curabitur	eu dolor egestas rhoncus. Proin nisl	2020-06-10 18:58:12.939536
13	60	36	2	accumsan convallis, ante lectus convallis est,	a purus.	libero et tristique pellentesque, tellus sem mollis dui, in sodales	2020-06-10 18:58:12.939536
14	215	11	10	velit. Cras lorem lorem, luctus ut, pellentesque eget, dictum placerat,	leo.	Nunc	2020-06-10 18:58:12.939536
15	121	38	1	urna et arcu imperdiet ullamcorper. Duis	libero.	id nunc interdum feugiat. Sed nec	2020-06-10 18:58:12.939536
16	315	11	2	laoreet lectus quis massa. Mauris	lacus	Mauris vestibulum, neque	2020-06-10 18:58:12.939536
17	149	84	8	ut, molestie in, tempus eu, ligula. Aenean euismod	lacinia	rutrum lorem ac risus.	2020-06-10 18:58:12.939536
18	180	96	7	arcu. Vivamus	massa. Suspendisse eleifend. Cras	imperdiet non, vestibulum nec, euismod in, dolor. Fusce feugiat.	2020-06-10 18:58:12.939536
19	203	41	1	ante dictum mi, ac	luctus lobortis. Class aptent taciti sociosqu ad litora torquent per	rhoncus id,	2020-06-10 18:58:12.939536
20	66	28	6	velit. Quisque varius.	sem egestas blandit. Nam nulla	tristique neque venenatis lacus. Etiam bibendum	2020-06-10 18:58:12.939536
21	381	80	9	in faucibus orci luctus et ultrices posuere cubilia Curae; Donec	sit amet,	mi. Aliquam	2020-06-10 18:58:12.939536
22	17	70	4	Phasellus elit pede, malesuada	bibendum sed, est. Nunc laoreet lectus quis massa.	dolor, nonummy ac, feugiat non,	2020-06-10 18:58:12.981668
23	169	58	8	habitant morbi tristique	Donec tempus, lorem fringilla ornare placerat, orci lacus	iaculis aliquet diam. Sed diam lorem, auctor quis, tristique ac,	2020-06-10 18:58:12.981668
24	140	95	7	dolor, nonummy ac, feugiat non, lobortis quis, pede.	In lorem. Donec elementum, lorem ut	Cum sociis natoque	2020-06-10 18:58:12.981668
25	396	75	8	accumsan sed, facilisis	feugiat. Sed nec metus facilisis lorem tristique	nisi nibh lacinia orci, consectetuer euismod est arcu ac	2020-06-10 18:58:12.981668
26	145	46	1	nibh. Donec est mauris, rhoncus id, mollis nec,	congue turpis. In condimentum. Donec at arcu.	orci	2020-06-10 18:58:12.981668
27	317	16	7	Fusce aliquet	nisi magna sed dui. Fusce aliquam, enim nec	convallis in, cursus et,	2020-06-10 18:58:12.981668
28	190	90	9	amet ante. Vivamus non lorem vitae odio sagittis	Cras	egestas nunc sed libero. Proin	2020-06-10 18:58:12.981668
29	197	16	10	non sapien molestie orci tincidunt adipiscing. Mauris molestie pharetra nibh.	dapibus gravida. Aliquam tincidunt, nunc ac mattis	erat volutpat.	2020-06-10 18:58:12.981668
30	141	46	5	Curabitur vel lectus. Cum sociis	velit egestas lacinia. Sed congue, elit sed consequat auctor, nunc	diam. Proin dolor. Nulla semper tellus id nunc	2020-06-10 18:58:12.981668
31	351	59	8	luctus. Curabitur egestas nunc sed libero. Proin	dapibus ligula. Aliquam erat volutpat. Nulla dignissim. Maecenas ornare egestas	ut eros non enim commodo hendrerit. Donec	2020-06-10 18:58:12.981668
32	121	28	6	consequat,	suscipit nonummy. Fusce	mus. Proin	2020-06-10 18:58:13.028585
33	393	75	10	ac turpis egestas.	ligula	Aliquam nec enim. Nunc ut erat. Sed	2020-06-10 18:58:13.028585
34	48	82	1	dictum magna. Ut tincidunt orci quis lectus.	eu nulla at sem molestie sodales. Mauris blandit enim	vehicula risus. Nulla eget metus	2020-06-10 18:58:13.028585
35	33	40	7	faucibus id, libero. Donec consectetuer mauris id sapien.	venenatis a, magna. Lorem ipsum	mi. Duis risus	2020-06-10 18:58:13.028585
36	131	45	5	felis ullamcorper viverra. Maecenas iaculis aliquet diam. Sed diam	ultrices posuere cubilia Curae; Donec tincidunt. Donec vitae	Phasellus ornare. Fusce mollis. Duis sit amet diam eu	2020-06-10 18:58:13.028585
37	42	18	3	sapien, gravida non, sollicitudin a, malesuada id,	massa lobortis ultrices. Vivamus	eu tempor erat	2020-06-10 18:58:13.028585
38	231	28	5	ipsum. Curabitur consequat,	magna nec quam. Curabitur vel lectus.	Morbi metus. Vivamus euismod urna. Nullam	2020-06-10 18:58:13.028585
39	35	94	10	fringilla mi lacinia mattis. Integer	magna. Cras convallis convallis dolor. Quisque tincidunt pede ac	ipsum. Suspendisse sagittis. Nullam vitae diam.	2020-06-10 18:58:13.028585
40	187	38	4	velit. Aliquam nisl.	vitae sodales nisi magna sed dui. Fusce	nec tellus. Nunc	2020-06-10 18:58:13.028585
41	151	38	2	nulla at sem molestie sodales. Mauris blandit enim consequat	habitant morbi tristique senectus et netus et malesuada	Duis elementum, dui quis accumsan convallis, ante lectus convallis	2020-06-10 18:58:13.028585
42	215	52	5	Phasellus	nonummy. Fusce fermentum fermentum arcu. Vestibulum ante ipsum	magna. Ut tincidunt orci quis lectus. Nullam suscipit, est	2020-06-10 18:58:13.050001
43	79	18	5	adipiscing elit. Curabitur sed tortor. Integer aliquam adipiscing	mollis. Duis sit amet diam eu dolor egestas	Fusce	2020-06-10 18:58:13.050001
44	80	52	9	Curabitur egestas nunc	amet diam	vulputate, posuere vulputate, lacus. Cras interdum. Nunc	2020-06-10 18:58:13.050001
45	290	39	2	Suspendisse aliquet, sem ut cursus luctus, ipsum leo elementum	auctor vitae, aliquet nec, imperdiet nec, leo. Morbi neque	quis massa. Mauris vestibulum, neque sed	2020-06-10 18:58:13.050001
46	153	90	2	ullamcorper, velit in aliquet lobortis, nisi nibh lacinia orci, consectetuer	magnis dis parturient montes, nascetur	in, cursus et, eros. Proin ultrices. Duis volutpat nunc	2020-06-10 18:58:13.050001
47	227	99	4	dis parturient	in faucibus orci luctus	feugiat non, lobortis quis, pede. Suspendisse dui. Fusce	2020-06-10 18:58:13.050001
48	104	27	9	ut dolor dapibus	pulvinar arcu et pede. Nunc	sit amet ornare lectus justo eu arcu. Morbi sit amet	2020-06-10 18:58:13.050001
49	98	27	8	Donec egestas.	nunc	aliquet vel, vulputate eu, odio. Phasellus at	2020-06-10 18:58:13.050001
50	330	74	7	aliquam iaculis, lacus pede sagittis augue, eu tempor erat neque	eu neque pellentesque massa	eu erat semper rutrum.	2020-06-10 18:58:13.050001
51	109	72	9	euismod	nunc nulla vulputate dui, nec	magna,	2020-06-10 18:58:13.050001
52	249	62	7	mauris a	adipiscing	mus. Aenean	2020-06-10 18:58:13.068366
53	209	40	10	sodales elit erat vitae	pede,	dolor elit, pellentesque	2020-06-10 18:58:13.068366
54	321	42	2	vestibulum nec, euismod	pharetra nibh. Aliquam ornare, libero	nunc nulla vulputate dui, nec tempus mauris erat	2020-06-10 18:58:13.068366
55	398	18	10	velit. Sed malesuada augue ut lacus. Nulla tincidunt, neque vitae	in	neque vitae semper egestas, urna justo faucibus lectus, a sollicitudin	2020-06-10 18:58:13.068366
56	95	62	2	Nam ligula elit, pretium et, rutrum non, hendrerit id, ante.	et, rutrum non, hendrerit id, ante. Nunc mauris sapien, cursus	quis urna. Nunc quis arcu vel quam dignissim pharetra.	2020-06-10 18:58:13.068366
57	354	31	3	luctus aliquet odio. Etiam ligula tortor, dictum eu,	molestie. Sed id risus quis diam luctus lobortis. Class aptent	ut	2020-06-10 18:58:13.068366
58	104	61	5	magna. Nam	Nam consequat dolor vitae dolor. Donec	Aenean euismod mauris eu elit. Nulla facilisi. Sed neque. Sed	2020-06-10 18:58:13.068366
59	118	95	7	et, eros. Proin ultrices.	risus	tellus.	2020-06-10 18:58:13.068366
60	221	18	8	Aliquam	amet,	vel, mauris. Integer sem	2020-06-10 18:58:13.068366
61	56	79	6	tempus mauris erat eget ipsum. Suspendisse sagittis. Nullam vitae	vel turpis. Aliquam adipiscing lobortis risus. In	ut, pharetra	2020-06-10 18:58:13.068366
62	327	17	8	luctus lobortis. Class aptent taciti sociosqu ad litora torquent	id	nunc est,	2020-06-10 18:58:13.086372
63	159	64	8	eu, odio. Phasellus	fames ac turpis egestas. Fusce aliquet	iaculis nec, eleifend non, dapibus rutrum, justo. Praesent luctus.	2020-06-10 18:58:13.086372
64	14	74	4	per inceptos hymenaeos. Mauris	Cum sociis natoque penatibus et magnis dis	et	2020-06-10 18:58:13.086372
65	365	46	4	sem, consequat nec, mollis vitae, posuere at, velit.	Aliquam fringilla cursus purus. Nullam scelerisque	orci. Ut semper pretium neque. Morbi quis urna.	2020-06-10 18:58:13.086372
66	91	78	9	sollicitudin commodo ipsum. Suspendisse non leo. Vivamus nibh	tincidunt nibh. Phasellus nulla. Integer vulputate, risus a	dolor.	2020-06-10 18:58:13.086372
67	343	52	4	consectetuer ipsum nunc id enim. Curabitur	sagittis felis. Donec tempor, est ac	Nam consequat dolor vitae dolor. Donec fringilla. Donec	2020-06-10 18:58:13.086372
68	231	56	2	Phasellus ornare. Fusce mollis. Duis sit amet diam	Morbi accumsan	metus facilisis	2020-06-10 18:58:13.086372
69	301	41	2	Praesent	malesuada vel,	blandit congue. In scelerisque scelerisque dui. Suspendisse ac	2020-06-10 18:58:13.086372
70	88	47	2	tempus risus. Donec egestas.	amet,	odio a purus.	2020-06-10 18:58:13.086372
71	373	53	3	nec enim. Nunc ut	lorem vitae odio sagittis semper. Nam tempor	dis parturient montes,	2020-06-10 18:58:13.086372
72	191	12	4	tellus,	Donec tempor, est ac mattis semper, dui lectus rutrum urna,	ullamcorper magna. Sed eu eros. Nam consequat	2020-06-10 18:58:13.107184
73	61	79	1	at, velit. Cras lorem lorem, luctus ut,	risus. Donec egestas. Duis ac arcu.	lorem, eget mollis lectus pede et	2020-06-10 18:58:13.107184
74	160	75	5	sodales. Mauris blandit enim consequat purus. Maecenas libero	pede, nonummy ut, molestie in, tempus eu, ligula.	id, ante. Nunc mauris sapien, cursus	2020-06-10 18:58:13.107184
75	13	80	7	molestie pharetra nibh. Aliquam ornare, libero	cursus et, magna. Praesent interdum ligula eu	et, eros. Proin ultrices. Duis volutpat nunc sit	2020-06-10 18:58:13.107184
76	146	26	4	Donec dignissim magna a tortor. Nunc commodo auctor velit.	vel nisl. Quisque fringilla euismod enim.	aliquet lobortis, nisi nibh lacinia orci,	2020-06-10 18:58:13.107184
77	347	96	6	dolor. Fusce feugiat. Lorem ipsum dolor sit amet, consectetuer	nec quam. Curabitur vel lectus. Cum sociis natoque penatibus	scelerisque dui. Suspendisse ac metus vitae velit egestas lacinia.	2020-06-10 18:58:13.107184
78	365	69	2	taciti	Sed eu nibh vulputate mauris sagittis placerat. Cras	semper cursus.	2020-06-10 18:58:13.107184
79	64	12	1	et	mollis non, cursus non, egestas	Morbi sit amet massa. Quisque porttitor	2020-06-10 18:58:13.107184
80	1	16	5	non enim. Mauris quis turpis	lorem	Suspendisse commodo tincidunt nibh. Phasellus nulla. Integer	2020-06-10 18:58:13.107184
81	78	75	4	vel turpis. Aliquam adipiscing lobortis risus. In mi pede,	Suspendisse	cursus et, magna. Praesent interdum ligula eu enim. Etiam	2020-06-10 18:58:13.107184
82	31	57	5	ligula. Donec luctus aliquet	diam lorem, auctor quis, tristique ac, eleifend vitae,	Integer	2020-06-10 18:58:13.126415
83	226	54	4	scelerisque scelerisque dui.	orci lobortis augue scelerisque mollis. Phasellus libero	Pellentesque habitant morbi tristique senectus et netus et	2020-06-10 18:58:13.126415
84	227	55	5	ornare, lectus ante dictum mi, ac mattis velit justo nec	lorem, sit amet ultricies sem magna nec quam. Curabitur	urna. Nullam lobortis quam a felis ullamcorper viverra. Maecenas	2020-06-10 18:58:13.126415
85	87	60	4	feugiat nec, diam. Duis mi enim, condimentum eget, volutpat	Suspendisse ac metus vitae velit egestas	nisl sem, consequat nec, mollis vitae,	2020-06-10 18:58:13.126415
86	151	71	4	Sed auctor odio a purus. Duis elementum,	Fusce fermentum fermentum arcu. Vestibulum	Ut semper pretium neque. Morbi	2020-06-10 18:58:13.126415
87	227	90	3	elit sed consequat auctor, nunc	gravida	Pellentesque habitant morbi tristique senectus et netus et malesuada	2020-06-10 18:58:13.126415
88	171	29	10	magna a neque.	senectus et netus et malesuada fames ac turpis egestas.	consectetuer ipsum nunc id	2020-06-10 18:58:13.126415
89	106	67	7	malesuada. Integer id magna et	rutrum. Fusce dolor	rhoncus. Nullam velit dui, semper	2020-06-10 18:58:13.126415
90	30	69	7	semper, dui lectus	mi lorem, vehicula	quam. Curabitur vel lectus. Cum sociis natoque penatibus et magnis	2020-06-10 18:58:13.126415
91	115	58	10	luctus vulputate, nisi sem semper erat, in consectetuer	mattis.	nec, leo. Morbi neque tellus, imperdiet non,	2020-06-10 18:58:13.126415
92	6	22	8	in molestie	aliquet magna a	risus. Donec egestas. Aliquam nec enim. Nunc ut erat. Sed	2020-06-10 18:58:13.145232
93	59	91	9	in molestie tortor nibh sit amet	orci. Donec nibh. Quisque nonummy	est. Nunc laoreet lectus quis massa. Mauris vestibulum,	2020-06-10 18:58:13.145232
94	75	53	5	nibh sit amet orci. Ut sagittis lobortis mauris. Suspendisse	quis turpis vitae purus gravida sagittis.	tellus id nunc interdum feugiat. Sed	2020-06-10 18:58:13.145232
95	307	79	7	urna justo faucibus lectus, a sollicitudin orci	vulputate	ligula. Nullam feugiat placerat velit. Quisque	2020-06-10 18:58:13.145232
96	44	17	8	tempor arcu. Vestibulum ut eros non enim commodo hendrerit.	congue.	Sed neque. Sed eget lacus.	2020-06-10 18:58:13.145232
97	269	28	6	Donec	justo. Proin non massa non ante bibendum	Aliquam erat volutpat. Nulla facilisis. Suspendisse commodo tincidunt nibh.	2020-06-10 18:58:13.145232
98	84	85	4	tempus mauris erat eget ipsum. Suspendisse sagittis. Nullam vitae diam.	Donec consectetuer mauris id sapien. Cras dolor dolor, tempus non,	felis. Nulla tempor	2020-06-10 18:58:13.145232
99	309	79	5	In tincidunt congue turpis. In	orci lobortis augue scelerisque mollis. Phasellus libero	semper, dui lectus rutrum	2020-06-10 18:58:13.145232
100	312	56	10	Aliquam fringilla cursus purus. Nullam scelerisque neque sed sem egestas	magna, malesuada vel, convallis in, cursus et, eros.	at fringilla purus mauris a nunc. In at pede.	2020-06-10 18:58:13.145232
101	268	30	5	tristique aliquet. Phasellus fermentum convallis ligula. Donec luctus	et tristique pellentesque, tellus sem mollis dui,	neque pellentesque massa lobortis ultrices. Vivamus rhoncus. Donec est.	2020-06-10 18:58:13.145232
102	301	92	5	orci.	Nulla interdum. Curabitur dictum. Phasellus in	pellentesque massa lobortis ultrices. Vivamus rhoncus.	2020-06-10 18:58:15.328531
103	316	100	10	nisi. Aenean eget metus. In nec orci. Donec nibh.	Fusce fermentum fermentum arcu. Vestibulum ante	eros. Proin ultrices. Duis volutpat nunc	2020-06-10 18:58:15.328531
104	223	76	7	ullamcorper	semper	Vestibulum ante ipsum primis	2020-06-10 18:58:15.328531
105	249	51	8	ultrices. Duis volutpat nunc sit amet metus. Aliquam erat	nec, eleifend non, dapibus	pretium et, rutrum non, hendrerit id, ante. Nunc	2020-06-10 18:58:15.328531
106	23	50	3	arcu. Vestibulum ante ipsum	dui augue eu tellus. Phasellus elit pede, malesuada	consectetuer ipsum nunc id enim. Curabitur massa. Vestibulum accumsan	2020-06-10 18:58:15.328531
107	234	22	3	fermentum fermentum	nisi a odio semper cursus. Integer	ornare, lectus ante dictum mi, ac mattis	2020-06-10 18:58:15.328531
108	337	83	4	egestas a, scelerisque sed, sapien. Nunc pulvinar arcu et	Cras	Donec elementum,	2020-06-10 18:58:15.328531
109	380	29	7	odio sagittis	sodales nisi magna sed	quis diam. Pellentesque habitant morbi tristique	2020-06-10 18:58:15.328531
110	251	65	10	augue porttitor interdum.	nisi. Mauris nulla.	In at pede. Cras vulputate velit eu	2020-06-10 18:58:15.328531
111	394	17	8	felis eget varius ultrices, mauris ipsum porta elit,	mi eleifend egestas.	pharetra nibh.	2020-06-10 18:58:15.328531
112	20	63	8	\N	\N	\N	2020-06-10 19:01:28.742142
113	91	76	4	\N	\N	\N	2020-06-10 19:01:28.742142
114	151	38	8	\N	\N	\N	2020-06-10 19:01:28.742142
115	195	92	4	\N	\N	\N	2020-06-10 19:01:28.742142
116	112	22	9	\N	\N	\N	2020-06-10 19:01:28.742142
117	224	65	7	\N	\N	\N	2020-06-10 19:01:28.742142
118	218	66	4	\N	\N	\N	2020-06-10 19:01:28.742142
119	59	14	6	\N	\N	\N	2020-06-10 19:01:28.742142
120	100	46	4	\N	\N	\N	2020-06-10 19:01:28.742142
121	66	73	10	\N	\N	\N	2020-06-10 19:01:28.742142
122	369	12	9	\N	\N	\N	2020-06-10 19:01:28.755084
123	85	56	10	\N	\N	\N	2020-06-10 19:01:28.755084
124	302	23	10	\N	\N	\N	2020-06-10 19:01:28.755084
125	145	54	10	\N	\N	\N	2020-06-10 19:01:28.755084
126	247	27	9	\N	\N	\N	2020-06-10 19:01:28.755084
127	242	72	10	\N	\N	\N	2020-06-10 19:01:28.755084
128	90	85	6	\N	\N	\N	2020-06-10 19:01:28.755084
129	198	48	8	\N	\N	\N	2020-06-10 19:01:28.755084
130	12	18	1	\N	\N	\N	2020-06-10 19:01:28.755084
131	66	96	10	\N	\N	\N	2020-06-10 19:01:28.755084
132	396	88	5	\N	\N	\N	2020-06-10 19:01:28.763838
133	339	42	9	\N	\N	\N	2020-06-10 19:01:28.763838
134	51	28	7	\N	\N	\N	2020-06-10 19:01:28.763838
135	362	22	9	\N	\N	\N	2020-06-10 19:01:28.763838
136	334	25	3	\N	\N	\N	2020-06-10 19:01:28.763838
137	93	29	10	\N	\N	\N	2020-06-10 19:01:28.763838
138	228	98	6	\N	\N	\N	2020-06-10 19:01:28.763838
139	208	40	5	\N	\N	\N	2020-06-10 19:01:28.763838
140	5	52	2	\N	\N	\N	2020-06-10 19:01:28.763838
141	42	34	10	\N	\N	\N	2020-06-10 19:01:28.763838
142	326	33	6	\N	\N	\N	2020-06-10 19:01:28.773325
143	199	87	7	\N	\N	\N	2020-06-10 19:01:28.773325
144	43	35	6	\N	\N	\N	2020-06-10 19:01:28.773325
145	33	85	1	\N	\N	\N	2020-06-10 19:01:28.773325
146	105	47	8	\N	\N	\N	2020-06-10 19:01:28.773325
147	232	33	7	\N	\N	\N	2020-06-10 19:01:28.773325
148	358	72	4	\N	\N	\N	2020-06-10 19:01:28.773325
149	389	33	8	\N	\N	\N	2020-06-10 19:01:28.773325
150	297	49	7	\N	\N	\N	2020-06-10 19:01:28.773325
151	287	89	1	\N	\N	\N	2020-06-10 19:01:28.773325
152	43	71	5	\N	\N	\N	2020-06-10 19:01:28.784185
153	265	24	9	\N	\N	\N	2020-06-10 19:01:28.784185
154	358	61	6	\N	\N	\N	2020-06-10 19:01:28.784185
155	90	24	1	\N	\N	\N	2020-06-10 19:01:28.784185
156	249	17	2	\N	\N	\N	2020-06-10 19:01:28.784185
157	209	39	3	\N	\N	\N	2020-06-10 19:01:28.784185
158	72	77	4	\N	\N	\N	2020-06-10 19:01:28.784185
159	121	30	9	\N	\N	\N	2020-06-10 19:01:28.784185
160	129	74	5	\N	\N	\N	2020-06-10 19:01:28.784185
161	363	93	8	\N	\N	\N	2020-06-10 19:01:28.784185
162	280	49	3	\N	\N	\N	2020-06-10 19:01:28.794285
163	322	17	8	\N	\N	\N	2020-06-10 19:01:28.794285
164	75	62	2	\N	\N	\N	2020-06-10 19:01:28.794285
165	53	87	1	\N	\N	\N	2020-06-10 19:01:28.794285
166	60	54	2	\N	\N	\N	2020-06-10 19:01:28.794285
167	369	95	6	\N	\N	\N	2020-06-10 19:01:28.794285
168	90	16	10	\N	\N	\N	2020-06-10 19:01:28.794285
169	46	38	4	\N	\N	\N	2020-06-10 19:01:28.794285
170	177	75	3	\N	\N	\N	2020-06-10 19:01:28.794285
171	168	59	6	\N	\N	\N	2020-06-10 19:01:28.794285
172	396	38	1	\N	\N	\N	2020-06-10 19:01:28.801969
173	118	17	2	\N	\N	\N	2020-06-10 19:01:28.801969
174	362	11	10	\N	\N	\N	2020-06-10 19:01:28.801969
175	391	45	4	\N	\N	\N	2020-06-10 19:01:28.801969
176	208	82	7	\N	\N	\N	2020-06-10 19:01:28.801969
177	91	16	8	\N	\N	\N	2020-06-10 19:01:28.801969
178	330	46	8	\N	\N	\N	2020-06-10 19:01:28.801969
179	262	74	1	\N	\N	\N	2020-06-10 19:01:28.801969
180	200	91	2	\N	\N	\N	2020-06-10 19:01:28.801969
181	216	40	8	\N	\N	\N	2020-06-10 19:01:28.801969
182	157	42	9	\N	\N	\N	2020-06-10 19:01:28.810044
183	194	67	6	\N	\N	\N	2020-06-10 19:01:28.810044
184	99	73	10	\N	\N	\N	2020-06-10 19:01:28.810044
185	126	79	7	\N	\N	\N	2020-06-10 19:01:28.810044
186	293	79	6	\N	\N	\N	2020-06-10 19:01:28.810044
187	13	13	10	\N	\N	\N	2020-06-10 19:01:28.810044
188	51	16	8	\N	\N	\N	2020-06-10 19:01:28.810044
189	153	65	5	\N	\N	\N	2020-06-10 19:01:28.810044
190	177	29	7	\N	\N	\N	2020-06-10 19:01:28.810044
191	348	72	3	\N	\N	\N	2020-06-10 19:01:28.810044
192	297	96	8	\N	\N	\N	2020-06-10 19:01:28.820359
193	380	57	3	\N	\N	\N	2020-06-10 19:01:28.820359
194	364	29	5	\N	\N	\N	2020-06-10 19:01:28.820359
195	129	45	7	\N	\N	\N	2020-06-10 19:01:28.820359
196	397	84	1	\N	\N	\N	2020-06-10 19:01:28.820359
197	184	67	1	\N	\N	\N	2020-06-10 19:01:28.820359
198	273	100	5	\N	\N	\N	2020-06-10 19:01:28.820359
199	29	52	5	\N	\N	\N	2020-06-10 19:01:28.820359
200	300	53	6	\N	\N	\N	2020-06-10 19:01:28.820359
201	368	48	2	\N	\N	\N	2020-06-10 19:01:28.820359
202	296	11	5	\N	\N	\N	2020-06-10 19:01:29.850087
203	273	82	4	\N	\N	\N	2020-06-10 19:01:29.850087
204	70	48	9	\N	\N	\N	2020-06-10 19:01:29.850087
205	393	43	6	\N	\N	\N	2020-06-10 19:01:29.850087
206	111	41	2	\N	\N	\N	2020-06-10 19:01:29.850087
207	284	32	8	\N	\N	\N	2020-06-10 19:01:29.850087
208	234	87	8	\N	\N	\N	2020-06-10 19:01:29.850087
209	142	21	2	\N	\N	\N	2020-06-10 19:01:29.850087
210	125	36	9	\N	\N	\N	2020-06-10 19:01:29.850087
211	19	34	10	\N	\N	\N	2020-06-10 19:01:29.850087
212	349	70	10	\N	\N	\N	2020-06-10 19:01:48.697325
213	288	55	4	\N	\N	\N	2020-06-10 19:01:48.697325
214	316	75	10	\N	\N	\N	2020-06-10 19:01:48.697325
215	283	89	7	\N	\N	\N	2020-06-10 19:01:48.697325
216	181	24	4	\N	\N	\N	2020-06-10 19:01:48.697325
217	14	47	8	\N	\N	\N	2020-06-10 19:01:48.697325
218	370	100	9	\N	\N	\N	2020-06-10 19:01:48.697325
219	243	69	4	\N	\N	\N	2020-06-10 19:01:48.697325
220	273	96	2	\N	\N	\N	2020-06-10 19:01:48.697325
221	379	24	8	\N	\N	\N	2020-06-10 19:01:48.697325
222	375	22	10	\N	\N	\N	2020-06-10 19:01:48.706719
223	57	44	1	\N	\N	\N	2020-06-10 19:01:48.706719
224	119	85	8	\N	\N	\N	2020-06-10 19:01:48.706719
225	194	17	1	\N	\N	\N	2020-06-10 19:01:48.706719
226	80	58	1	\N	\N	\N	2020-06-10 19:01:48.706719
227	42	14	3	\N	\N	\N	2020-06-10 19:01:48.706719
228	51	88	7	\N	\N	\N	2020-06-10 19:01:48.706719
229	192	51	10	\N	\N	\N	2020-06-10 19:01:48.706719
230	399	22	5	\N	\N	\N	2020-06-10 19:01:48.706719
231	313	90	5	\N	\N	\N	2020-06-10 19:01:48.706719
232	326	37	5	\N	\N	\N	2020-06-10 19:01:48.713983
233	374	91	1	\N	\N	\N	2020-06-10 19:01:48.713983
234	314	90	8	\N	\N	\N	2020-06-10 19:01:48.713983
235	390	34	5	\N	\N	\N	2020-06-10 19:01:48.713983
236	139	59	4	\N	\N	\N	2020-06-10 19:01:48.713983
237	378	30	8	\N	\N	\N	2020-06-10 19:01:48.713983
238	240	41	4	\N	\N	\N	2020-06-10 19:01:48.713983
239	323	96	4	\N	\N	\N	2020-06-10 19:01:48.713983
240	297	72	1	\N	\N	\N	2020-06-10 19:01:48.713983
241	258	51	2	\N	\N	\N	2020-06-10 19:01:48.713983
242	33	20	2	\N	\N	\N	2020-06-10 19:01:48.72183
243	109	57	2	\N	\N	\N	2020-06-10 19:01:48.72183
244	20	40	10	\N	\N	\N	2020-06-10 19:01:48.72183
245	34	68	9	\N	\N	\N	2020-06-10 19:01:48.72183
246	362	75	6	\N	\N	\N	2020-06-10 19:01:48.72183
247	53	43	2	\N	\N	\N	2020-06-10 19:01:48.72183
248	166	85	6	\N	\N	\N	2020-06-10 19:01:48.72183
249	254	74	6	\N	\N	\N	2020-06-10 19:01:48.72183
250	37	80	5	\N	\N	\N	2020-06-10 19:01:48.72183
251	147	52	6	\N	\N	\N	2020-06-10 19:01:48.72183
252	387	86	3	\N	\N	\N	2020-06-10 19:01:48.731451
253	189	14	8	\N	\N	\N	2020-06-10 19:01:48.731451
254	58	88	3	\N	\N	\N	2020-06-10 19:01:48.731451
255	358	78	1	\N	\N	\N	2020-06-10 19:01:48.731451
256	46	51	9	\N	\N	\N	2020-06-10 19:01:48.731451
257	15	16	7	\N	\N	\N	2020-06-10 19:01:48.731451
258	375	48	3	\N	\N	\N	2020-06-10 19:01:48.731451
259	380	41	7	\N	\N	\N	2020-06-10 19:01:48.731451
260	44	94	8	\N	\N	\N	2020-06-10 19:01:48.731451
261	289	25	4	\N	\N	\N	2020-06-10 19:01:48.731451
262	90	80	6	\N	\N	\N	2020-06-10 19:01:48.739191
263	76	24	10	\N	\N	\N	2020-06-10 19:01:48.739191
264	289	49	9	\N	\N	\N	2020-06-10 19:01:48.739191
265	361	17	3	\N	\N	\N	2020-06-10 19:01:48.739191
266	1	77	3	\N	\N	\N	2020-06-10 19:01:48.739191
267	214	68	4	\N	\N	\N	2020-06-10 19:01:48.739191
268	278	79	10	\N	\N	\N	2020-06-10 19:01:48.739191
269	270	76	2	\N	\N	\N	2020-06-10 19:01:48.739191
270	30	13	4	\N	\N	\N	2020-06-10 19:01:48.739191
271	267	97	5	\N	\N	\N	2020-06-10 19:01:48.739191
272	288	85	4	\N	\N	\N	2020-06-10 19:01:48.746824
273	364	36	9	\N	\N	\N	2020-06-10 19:01:48.746824
274	7	23	6	\N	\N	\N	2020-06-10 19:01:48.746824
275	359	16	2	\N	\N	\N	2020-06-10 19:01:48.746824
276	95	39	6	\N	\N	\N	2020-06-10 19:01:48.746824
277	373	55	2	\N	\N	\N	2020-06-10 19:01:48.746824
278	209	56	5	\N	\N	\N	2020-06-10 19:01:48.746824
279	90	61	3	\N	\N	\N	2020-06-10 19:01:48.746824
280	106	99	9	\N	\N	\N	2020-06-10 19:01:48.746824
281	285	13	3	\N	\N	\N	2020-06-10 19:01:48.746824
282	160	41	2	\N	\N	\N	2020-06-10 19:01:48.754376
283	299	55	9	\N	\N	\N	2020-06-10 19:01:48.754376
284	68	26	2	\N	\N	\N	2020-06-10 19:01:48.754376
285	230	29	2	\N	\N	\N	2020-06-10 19:01:48.754376
286	4	53	6	\N	\N	\N	2020-06-10 19:01:48.754376
287	174	33	9	\N	\N	\N	2020-06-10 19:01:48.754376
288	35	47	6	\N	\N	\N	2020-06-10 19:01:48.754376
289	113	32	2	\N	\N	\N	2020-06-10 19:01:48.754376
290	358	26	8	\N	\N	\N	2020-06-10 19:01:48.754376
291	47	91	3	\N	\N	\N	2020-06-10 19:01:48.754376
292	250	58	2	\N	\N	\N	2020-06-10 19:01:48.7604
293	164	82	6	\N	\N	\N	2020-06-10 19:01:48.7604
294	378	24	4	\N	\N	\N	2020-06-10 19:01:48.7604
295	374	86	9	\N	\N	\N	2020-06-10 19:01:48.7604
296	392	39	6	\N	\N	\N	2020-06-10 19:01:48.7604
297	13	34	10	\N	\N	\N	2020-06-10 19:01:48.7604
298	103	18	6	\N	\N	\N	2020-06-10 19:01:48.7604
299	96	47	10	\N	\N	\N	2020-06-10 19:01:48.7604
300	191	77	8	\N	\N	\N	2020-06-10 19:01:48.7604
301	165	25	10	\N	\N	\N	2020-06-10 19:01:48.7604
302	354	57	1	\N	\N	\N	2020-06-10 19:01:49.660829
303	213	81	7	\N	\N	\N	2020-06-10 19:01:49.660829
304	6	55	8	\N	\N	\N	2020-06-10 19:01:49.660829
305	173	55	6	\N	\N	\N	2020-06-10 19:01:49.660829
306	71	69	10	\N	\N	\N	2020-06-10 19:01:49.660829
307	191	45	8	\N	\N	\N	2020-06-10 19:01:49.660829
308	197	99	6	\N	\N	\N	2020-06-10 19:01:49.660829
309	169	48	4	\N	\N	\N	2020-06-10 19:01:49.660829
310	350	36	2	\N	\N	\N	2020-06-10 19:01:49.660829
311	22	28	8	\N	\N	\N	2020-06-10 19:01:49.660829
312	394	76	1	\N	\N	\N	2020-06-10 19:02:03.988976
313	251	82	5	\N	\N	\N	2020-06-10 19:02:03.988976
314	77	43	3	\N	\N	\N	2020-06-10 19:02:03.988976
315	2	35	1	\N	\N	\N	2020-06-10 19:02:03.988976
316	224	97	2	\N	\N	\N	2020-06-10 19:02:03.988976
317	381	58	9	\N	\N	\N	2020-06-10 19:02:03.988976
318	291	81	3	\N	\N	\N	2020-06-10 19:02:03.988976
319	78	46	2	\N	\N	\N	2020-06-10 19:02:03.988976
320	163	72	3	\N	\N	\N	2020-06-10 19:02:03.988976
321	389	76	6	\N	\N	\N	2020-06-10 19:02:03.988976
322	299	37	1	\N	\N	\N	2020-06-10 19:02:04.00168
323	167	35	2	\N	\N	\N	2020-06-10 19:02:04.00168
324	231	53	5	\N	\N	\N	2020-06-10 19:02:04.00168
325	124	29	8	\N	\N	\N	2020-06-10 19:02:04.00168
326	61	27	3	\N	\N	\N	2020-06-10 19:02:04.00168
327	116	80	6	\N	\N	\N	2020-06-10 19:02:04.00168
328	397	59	7	\N	\N	\N	2020-06-10 19:02:04.00168
329	231	30	8	\N	\N	\N	2020-06-10 19:02:04.00168
330	376	78	2	\N	\N	\N	2020-06-10 19:02:04.00168
331	175	97	8	\N	\N	\N	2020-06-10 19:02:04.00168
332	178	78	9	\N	\N	\N	2020-06-10 19:02:04.01343
333	295	68	3	\N	\N	\N	2020-06-10 19:02:04.01343
334	286	39	10	\N	\N	\N	2020-06-10 19:02:04.01343
335	151	11	2	\N	\N	\N	2020-06-10 19:02:04.01343
336	194	93	6	\N	\N	\N	2020-06-10 19:02:04.01343
337	169	20	4	\N	\N	\N	2020-06-10 19:02:04.01343
338	116	21	6	\N	\N	\N	2020-06-10 19:02:04.01343
339	44	29	8	\N	\N	\N	2020-06-10 19:02:04.01343
340	358	75	5	\N	\N	\N	2020-06-10 19:02:04.01343
341	387	61	5	\N	\N	\N	2020-06-10 19:02:04.01343
342	116	42	7	\N	\N	\N	2020-06-10 19:02:04.023195
343	89	60	1	\N	\N	\N	2020-06-10 19:02:04.023195
344	120	77	6	\N	\N	\N	2020-06-10 19:02:04.023195
345	400	26	8	\N	\N	\N	2020-06-10 19:02:04.023195
346	296	80	5	\N	\N	\N	2020-06-10 19:02:04.023195
347	38	99	1	\N	\N	\N	2020-06-10 19:02:04.023195
348	196	54	3	\N	\N	\N	2020-06-10 19:02:04.023195
349	250	43	1	\N	\N	\N	2020-06-10 19:02:04.023195
350	20	16	7	\N	\N	\N	2020-06-10 19:02:04.023195
351	3	46	5	\N	\N	\N	2020-06-10 19:02:04.023195
352	84	86	7	\N	\N	\N	2020-06-10 19:02:04.031117
353	251	26	7	\N	\N	\N	2020-06-10 19:02:04.031117
354	28	88	8	\N	\N	\N	2020-06-10 19:02:04.031117
355	208	21	5	\N	\N	\N	2020-06-10 19:02:04.031117
356	34	100	7	\N	\N	\N	2020-06-10 19:02:04.031117
357	170	72	5	\N	\N	\N	2020-06-10 19:02:04.031117
358	192	61	1	\N	\N	\N	2020-06-10 19:02:04.031117
359	67	29	2	\N	\N	\N	2020-06-10 19:02:04.031117
360	323	78	10	\N	\N	\N	2020-06-10 19:02:04.031117
361	44	81	4	\N	\N	\N	2020-06-10 19:02:04.031117
362	319	95	2	\N	\N	\N	2020-06-10 19:02:04.038881
363	340	61	7	\N	\N	\N	2020-06-10 19:02:04.038881
364	341	18	9	\N	\N	\N	2020-06-10 19:02:04.038881
365	357	85	4	\N	\N	\N	2020-06-10 19:02:04.038881
366	15	65	6	\N	\N	\N	2020-06-10 19:02:04.038881
367	187	35	2	\N	\N	\N	2020-06-10 19:02:04.038881
368	120	41	1	\N	\N	\N	2020-06-10 19:02:04.038881
369	363	27	8	\N	\N	\N	2020-06-10 19:02:04.038881
370	292	38	10	\N	\N	\N	2020-06-10 19:02:04.038881
371	295	94	5	\N	\N	\N	2020-06-10 19:02:04.038881
372	9	15	10	\N	\N	\N	2020-06-10 19:02:04.049146
373	173	87	8	\N	\N	\N	2020-06-10 19:02:04.049146
374	382	36	7	\N	\N	\N	2020-06-10 19:02:04.049146
375	365	46	8	\N	\N	\N	2020-06-10 19:02:04.049146
376	57	78	4	\N	\N	\N	2020-06-10 19:02:04.049146
377	195	62	9	\N	\N	\N	2020-06-10 19:02:04.049146
378	89	16	10	\N	\N	\N	2020-06-10 19:02:04.049146
379	157	14	10	\N	\N	\N	2020-06-10 19:02:04.049146
380	284	67	3	\N	\N	\N	2020-06-10 19:02:04.049146
381	60	43	8	\N	\N	\N	2020-06-10 19:02:04.049146
382	324	96	1	\N	\N	\N	2020-06-10 19:02:04.05912
383	268	16	1	\N	\N	\N	2020-06-10 19:02:04.05912
384	62	76	1	\N	\N	\N	2020-06-10 19:02:04.05912
385	212	82	2	\N	\N	\N	2020-06-10 19:02:04.05912
386	15	19	8	\N	\N	\N	2020-06-10 19:02:04.05912
387	327	32	6	\N	\N	\N	2020-06-10 19:02:04.05912
388	263	16	3	\N	\N	\N	2020-06-10 19:02:04.05912
389	105	94	2	\N	\N	\N	2020-06-10 19:02:04.05912
390	115	81	3	\N	\N	\N	2020-06-10 19:02:04.05912
391	331	85	10	\N	\N	\N	2020-06-10 19:02:04.05912
392	12	49	8	\N	\N	\N	2020-06-10 19:02:04.069359
393	253	27	10	\N	\N	\N	2020-06-10 19:02:04.069359
394	384	96	1	\N	\N	\N	2020-06-10 19:02:04.069359
395	42	74	8	\N	\N	\N	2020-06-10 19:02:04.069359
396	155	18	9	\N	\N	\N	2020-06-10 19:02:04.069359
397	18	33	9	\N	\N	\N	2020-06-10 19:02:04.069359
398	128	44	6	\N	\N	\N	2020-06-10 19:02:04.069359
399	225	81	1	\N	\N	\N	2020-06-10 19:02:04.069359
400	177	95	10	\N	\N	\N	2020-06-10 19:02:04.069359
401	274	77	6	\N	\N	\N	2020-06-10 19:02:04.069359
402	340	95	4	\N	\N	\N	2020-06-10 19:02:04.509975
403	370	76	5	\N	\N	\N	2020-06-10 19:02:04.509975
404	80	57	1	\N	\N	\N	2020-06-10 19:02:04.509975
405	44	20	1	\N	\N	\N	2020-06-10 19:02:04.509975
406	311	32	7	\N	\N	\N	2020-06-10 19:02:04.509975
407	230	61	2	\N	\N	\N	2020-06-10 19:02:04.509975
408	99	11	6	\N	\N	\N	2020-06-10 19:02:04.509975
409	75	26	7	\N	\N	\N	2020-06-10 19:02:04.509975
410	16	26	9	\N	\N	\N	2020-06-10 19:02:04.509975
411	366	18	1	\N	\N	\N	2020-06-10 19:02:04.509975
\.


--
-- Data for Name: series; Type: TABLE DATA; Schema: public; Owner: kirill
--

COPY public.series (series_id, name, release_date, is_finished) FROM stdin;
1	malesuada fames ac turpis	1977-02-23	t
2	tincidunt.	1991-11-04	t
3	lorem, eget	2012-05-19	f
4	Mauris	1940-10-30	f
5	per conubia nostra, per inceptos	1959-01-08	t
6	eu, odio.	1946-12-10	t
7	ante ipsum primis	1973-12-07	f
8	est.	1961-09-27	f
9	gravida sit amet, dapibus	1954-11-12	t
10	cubilia Curae;	1931-10-03	f
\.


--
-- Name: authors_id_seq; Type: SEQUENCE SET; Schema: public; Owner: kirill
--

SELECT pg_catalog.setval('public.authors_id_seq', 1, false);


--
-- Name: comic_book_id_seq; Type: SEQUENCE SET; Schema: public; Owner: kirill
--

SELECT pg_catalog.setval('public.comic_book_id_seq', 2, true);


--
-- Name: customer_id_seq; Type: SEQUENCE SET; Schema: public; Owner: kirill
--

SELECT pg_catalog.setval('public.customer_id_seq', 1, false);


--
-- Name: employee_id_seq; Type: SEQUENCE SET; Schema: public; Owner: kirill
--

SELECT pg_catalog.setval('public.employee_id_seq', 1, false);


--
-- Name: images_id_seq; Type: SEQUENCE SET; Schema: public; Owner: kirill
--

SELECT pg_catalog.setval('public.images_id_seq', 396, true);


--
-- Name: publishers_id_seq; Type: SEQUENCE SET; Schema: public; Owner: kirill
--

SELECT pg_catalog.setval('public.publishers_id_seq', 1, false);


--
-- Name: purchase_id_seq; Type: SEQUENCE SET; Schema: public; Owner: kirill
--

SELECT pg_catalog.setval('public.purchase_id_seq', 11, true);


--
-- Name: reviews_id_seq; Type: SEQUENCE SET; Schema: public; Owner: kirill
--

SELECT pg_catalog.setval('public.reviews_id_seq', 427, true);


--
-- Name: series_id_seq; Type: SEQUENCE SET; Schema: public; Owner: kirill
--

SELECT pg_catalog.setval('public.series_id_seq', 1, true);


--
-- Name: author_book author_book_pkey; Type: CONSTRAINT; Schema: public; Owner: kirill
--

ALTER TABLE ONLY public.author_book
    ADD CONSTRAINT author_book_pkey PRIMARY KEY (author_id, comic_id);


--
-- Name: authors authors_pkey; Type: CONSTRAINT; Schema: public; Owner: kirill
--

ALTER TABLE ONLY public.authors
    ADD CONSTRAINT authors_pkey PRIMARY KEY (author_id);


--
-- Name: comic_book comic_book_pkey; Type: CONSTRAINT; Schema: public; Owner: kirill
--

ALTER TABLE ONLY public.comic_book
    ADD CONSTRAINT comic_book_pkey PRIMARY KEY (comic_id);


--
-- Name: customers customers_pkey; Type: CONSTRAINT; Schema: public; Owner: kirill
--

ALTER TABLE ONLY public.customers
    ADD CONSTRAINT customers_pkey PRIMARY KEY (customer_id);


--
-- Name: employee employee_pkey; Type: CONSTRAINT; Schema: public; Owner: kirill
--

ALTER TABLE ONLY public.employee
    ADD CONSTRAINT employee_pkey PRIMARY KEY (emp_id);


--
-- Name: genre genre_pkey; Type: CONSTRAINT; Schema: public; Owner: kirill
--

ALTER TABLE ONLY public.genre
    ADD CONSTRAINT genre_pkey PRIMARY KEY (genre, comic_id);


--
-- Name: images images_pkey; Type: CONSTRAINT; Schema: public; Owner: kirill
--

ALTER TABLE ONLY public.images
    ADD CONSTRAINT images_pkey PRIMARY KEY (id);


--
-- Name: log log_pkey; Type: CONSTRAINT; Schema: public; Owner: kirill
--

ALTER TABLE ONLY public.log
    ADD CONSTRAINT log_pkey PRIMARY KEY ("time");


--
-- Name: publishers publishers_pkey; Type: CONSTRAINT; Schema: public; Owner: kirill
--

ALTER TABLE ONLY public.publishers
    ADD CONSTRAINT publishers_pkey PRIMARY KEY (publisher_id);


--
-- Name: purchase purchase_pkey; Type: CONSTRAINT; Schema: public; Owner: kirill
--

ALTER TABLE ONLY public.purchase
    ADD CONSTRAINT purchase_pkey PRIMARY KEY (purchase_id);


--
-- Name: purchased_book purchased_book_pkey; Type: CONSTRAINT; Schema: public; Owner: kirill
--

ALTER TABLE ONLY public.purchased_book
    ADD CONSTRAINT purchased_book_pkey PRIMARY KEY (book_id, purchase_id);


--
-- Name: series series_pkey; Type: CONSTRAINT; Schema: public; Owner: kirill
--

ALTER TABLE ONLY public.series
    ADD CONSTRAINT series_pkey PRIMARY KEY (series_id);


--
-- Name: fki_author; Type: INDEX; Schema: public; Owner: kirill
--

CREATE INDEX fki_author ON public.author_book USING btree (author_id);


--
-- Name: fki_book; Type: INDEX; Schema: public; Owner: kirill
--

CREATE INDEX fki_book ON public.purchased_book USING btree (book_id);


--
-- Name: fki_comic; Type: INDEX; Schema: public; Owner: kirill
--

CREATE INDEX fki_comic ON public.author_book USING btree (comic_id);


--
-- Name: fki_customer; Type: INDEX; Schema: public; Owner: kirill
--

CREATE INDEX fki_customer ON public.purchase USING btree (customer_id);


--
-- Name: fki_employee; Type: INDEX; Schema: public; Owner: kirill
--

CREATE INDEX fki_employee ON public.purchase USING btree (employee_id);


--
-- Name: fki_publishers; Type: INDEX; Schema: public; Owner: kirill
--

CREATE INDEX fki_publishers ON public.comic_book USING btree (publisher_id);


--
-- Name: fki_purchase; Type: INDEX; Schema: public; Owner: kirill
--

CREATE INDEX fki_purchase ON public.purchased_book USING btree (purchase_id);


--
-- Name: fki_series_id; Type: INDEX; Schema: public; Owner: kirill
--

CREATE INDEX fki_series_id ON public.comic_book USING btree (series_id);


--
-- Name: reviews check_purchase; Type: TRIGGER; Schema: public; Owner: kirill
--

CREATE TRIGGER check_purchase BEFORE INSERT ON public.reviews FOR EACH ROW EXECUTE FUNCTION public.check_purchase();

ALTER TABLE public.reviews DISABLE TRIGGER check_purchase;


--
-- Name: purchased_book check_stock; Type: TRIGGER; Schema: public; Owner: kirill
--

CREATE TRIGGER check_stock BEFORE INSERT ON public.purchased_book FOR EACH ROW EXECUTE FUNCTION public.change_stock();


--
-- Name: purchase status_upgrade; Type: TRIGGER; Schema: public; Owner: kirill
--

CREATE TRIGGER status_upgrade AFTER INSERT OR UPDATE ON public.purchase FOR EACH ROW EXECUTE FUNCTION public.status_update();


--
-- Name: author_book author; Type: FK CONSTRAINT; Schema: public; Owner: kirill
--

ALTER TABLE ONLY public.author_book
    ADD CONSTRAINT author FOREIGN KEY (author_id) REFERENCES public.authors(author_id) ON UPDATE CASCADE ON DELETE CASCADE NOT VALID;


--
-- Name: purchased_book book; Type: FK CONSTRAINT; Schema: public; Owner: kirill
--

ALTER TABLE ONLY public.purchased_book
    ADD CONSTRAINT book FOREIGN KEY (book_id) REFERENCES public.comic_book(comic_id) NOT VALID;


--
-- Name: reviews comic; Type: FK CONSTRAINT; Schema: public; Owner: kirill
--

ALTER TABLE ONLY public.reviews
    ADD CONSTRAINT comic FOREIGN KEY (comic_id) REFERENCES public.comic_book(comic_id) NOT VALID;


--
-- Name: author_book comic; Type: FK CONSTRAINT; Schema: public; Owner: kirill
--

ALTER TABLE ONLY public.author_book
    ADD CONSTRAINT comic FOREIGN KEY (comic_id) REFERENCES public.comic_book(comic_id) ON UPDATE CASCADE ON DELETE CASCADE NOT VALID;


--
-- Name: reviews customer; Type: FK CONSTRAINT; Schema: public; Owner: kirill
--

ALTER TABLE ONLY public.reviews
    ADD CONSTRAINT customer FOREIGN KEY (customer_id) REFERENCES public.customers(customer_id) NOT VALID;


--
-- Name: purchase customer; Type: FK CONSTRAINT; Schema: public; Owner: kirill
--

ALTER TABLE ONLY public.purchase
    ADD CONSTRAINT customer FOREIGN KEY (customer_id) REFERENCES public.customers(customer_id) ON UPDATE CASCADE NOT VALID;


--
-- Name: purchase employee; Type: FK CONSTRAINT; Schema: public; Owner: kirill
--

ALTER TABLE ONLY public.purchase
    ADD CONSTRAINT employee FOREIGN KEY (employee_id) REFERENCES public.employee(emp_id) ON UPDATE CASCADE NOT VALID;


--
-- Name: genre genre_comic_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: kirill
--

ALTER TABLE ONLY public.genre
    ADD CONSTRAINT genre_comic_id_fkey FOREIGN KEY (comic_id) REFERENCES public.comic_book(comic_id);


--
-- Name: images images; Type: FK CONSTRAINT; Schema: public; Owner: kirill
--

ALTER TABLE ONLY public.images
    ADD CONSTRAINT images FOREIGN KEY (comic_id) REFERENCES public.comic_book(comic_id) ON UPDATE CASCADE ON DELETE CASCADE NOT VALID;


--
-- Name: comic_book publishers; Type: FK CONSTRAINT; Schema: public; Owner: kirill
--

ALTER TABLE ONLY public.comic_book
    ADD CONSTRAINT publishers FOREIGN KEY (publisher_id) REFERENCES public.publishers(publisher_id) ON UPDATE CASCADE NOT VALID;


--
-- Name: purchased_book purchase; Type: FK CONSTRAINT; Schema: public; Owner: kirill
--

ALTER TABLE ONLY public.purchased_book
    ADD CONSTRAINT purchase FOREIGN KEY (purchase_id) REFERENCES public.purchase(purchase_id) NOT VALID;


--
-- Name: comic_book series_id; Type: FK CONSTRAINT; Schema: public; Owner: kirill
--

ALTER TABLE ONLY public.comic_book
    ADD CONSTRAINT series_id FOREIGN KEY (series_id) REFERENCES public.series(series_id) ON UPDATE CASCADE ON DELETE CASCADE NOT VALID;


--
-- PostgreSQL database dump complete
--

