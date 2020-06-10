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
-- Name: status_update(); Type: FUNCTION; Schema: public; Owner: kirill
--

CREATE FUNCTION public.status_update() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    IF NEW.status != OLD.status OR (TG_OP = 'INSERT') THEN
        INSERT INTO log (time, description, purchase_id) VALUES (CURRENT_TIMESTAMP, NEW.status, NEW.purchase_id);
    END IF;
RETURN NULL;
END;
$$;


ALTER FUNCTION public.status_update() OWNER TO kirill;

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
    CONSTRAINT purchase_status_check CHECK (((status = 'paid'::text) OR (status = 'in progress'::text) OR (status = 'delivered'::text)))
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
    purchaise_id integer NOT NULL,
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

COPY public.comic_book (comic_id, rating, stock, description, price, release_date, series_id, publisher_id) FROM stdin;
1	9	843	Nullam ut nisi a odio semper cursus. Integer mollis. Integer tincidunt	$21.69	1954-03-02	8	19
2	3	410	Mauris vel turpis. Aliquam adipiscing lobortis risus. In mi pede, nonummy ut,	$43.80	2018-05-02	10	18
3	3	515	mauris a nunc. In at	$10.52	1938-11-14	2	65
4	5	756	massa. Suspendisse eleifend. Cras sed leo. Cras vehicula aliquet libero.	$76.48	2012-12-04	7	86
5	4	294	ligula. Aenean gravida nunc sed pede. Cum sociis natoque penatibus	$81.36	1958-01-01	4	100
6	9	330	tristique ac, eleifend vitae, erat. Vivamus nisi. Mauris	$88.67	1985-06-06	1	25
7	7	804	quam quis diam. Pellentesque habitant morbi tristique senectus et netus	$9.82	1967-01-17	7	85
8	8	910	consequat, lectus sit amet luctus vulputate, nisi sem semper	$32.26	2003-09-13	5	14
9	10	530	justo. Proin non massa non ante bibendum ullamcorper. Duis cursus, diam at pretium	$51.09	1977-11-06	9	88
10	2	467	euismod et, commodo at, libero.	$3.49	1963-09-04	10	16
11	2	670	fringilla ornare placerat, orci lacus vestibulum lorem, sit amet ultricies sem	$7.80	2016-05-01	10	20
12	10	257	luctus aliquet odio. Etiam ligula tortor, dictum	$10.40	1999-10-22	5	47
13	3	39	scelerisque, lorem ipsum sodales purus, in molestie tortor nibh sit amet orci. Ut	$50.87	1965-03-28	8	37
14	5	858	magna et ipsum cursus vestibulum. Mauris magna. Duis dignissim	$82.50	1973-05-01	9	70
15	5	89	ac tellus. Suspendisse sed dolor. Fusce mi lorem,	$66.56	1960-04-02	2	51
16	5	904	ultrices. Duis volutpat nunc sit amet metus. Aliquam erat volutpat. Nulla facilisis. Suspendisse	$44.04	1979-06-18	3	89
17	6	384	sociis natoque penatibus et magnis dis parturient montes, nascetur ridiculus mus. Donec dignissim magna	$71.44	1964-11-05	6	6
18	2	181	ligula. Aenean gravida nunc sed pede. Cum sociis natoque penatibus et magnis	$54.79	1972-11-06	5	18
19	5	430	orci luctus et ultrices posuere cubilia Curae; Donec tincidunt. Donec vitae erat vel pede	$75.98	1973-02-21	4	12
20	3	145	Phasellus at augue id ante dictum cursus.	$43.99	2001-01-24	3	65
21	5	620	Mauris blandit enim consequat purus. Maecenas libero est, congue a, aliquet vel, vulputate	$24.26	2009-05-24	6	99
22	6	766	et arcu imperdiet ullamcorper. Duis at lacus. Quisque purus sapien, gravida non, sollicitudin a,	$7.27	1983-10-14	2	36
23	6	263	a sollicitudin orci sem eget massa. Suspendisse eleifend. Cras sed leo. Cras vehicula	$33.67	1990-02-01	2	40
24	1	563	dis parturient montes, nascetur ridiculus mus. Proin vel arcu eu odio tristique pharetra.	$88.18	1976-03-14	9	81
25	3	973	lacus. Mauris non dui nec urna suscipit nonummy. Fusce fermentum fermentum arcu. Vestibulum	$30.79	2004-05-16	5	82
26	1	749	lorem, auctor quis, tristique ac, eleifend vitae, erat. Vivamus nisi. Mauris	$80.37	1960-02-22	1	21
27	5	160	a, malesuada id, erat. Etiam vestibulum massa rutrum magna. Cras convallis convallis	$27.14	2007-09-27	10	32
28	7	753	magnis dis parturient montes, nascetur ridiculus mus. Proin vel arcu eu	$64.59	2010-05-08	6	18
29	2	144	non, egestas a, dui. Cras pellentesque. Sed dictum.	$24.01	1963-02-25	10	68
30	5	292	mattis. Integer eu lacus. Quisque imperdiet, erat	$7.89	2018-03-19	6	79
31	1	666	vitae risus. Duis a mi fringilla mi lacinia mattis. Integer eu lacus.	$70.89	1965-05-09	4	72
32	6	204	elit, a feugiat tellus lorem eu metus. In lorem. Donec	$40.10	1971-01-07	10	39
33	2	583	pellentesque eget, dictum placerat, augue. Sed molestie. Sed id risus quis diam luctus	$96.50	1933-04-07	8	82
34	7	843	Pellentesque ultricies dignissim lacus. Aliquam	$1.15	1994-03-13	7	67
35	1	19	ut odio vel est tempor bibendum. Donec felis orci, adipiscing non, luctus	$21.41	1994-08-03	5	73
36	10	904	lacus. Cras interdum. Nunc sollicitudin commodo ipsum. Suspendisse non leo.	$79.03	1955-12-22	5	80
37	5	140	elementum purus, accumsan interdum libero dui	$80.31	1978-07-30	10	6
38	2	762	Aenean sed pede nec ante blandit viverra. Donec tempus, lorem fringilla ornare placerat, orci lacus	$60.97	1973-10-28	5	77
39	6	631	Integer sem elit, pharetra ut, pharetra sed, hendrerit a,	$82.51	1978-07-15	3	13
40	1	73	dolor. Fusce feugiat. Lorem ipsum dolor sit amet, consectetuer adipiscing elit. Aliquam auctor, velit	$46.09	1972-12-12	1	69
41	5	114	erat neque non quam. Pellentesque habitant morbi tristique senectus et netus et malesuada fames	$25.70	1981-06-12	6	57
42	9	767	a, aliquet vel, vulputate eu, odio.	$59.32	1976-02-25	2	8
43	10	912	malesuada id, erat. Etiam vestibulum massa	$78.20	2019-08-10	2	71
44	9	94	Vivamus nibh dolor, nonummy ac,	$26.92	1936-11-06	7	54
45	6	600	Etiam laoreet, libero et tristique pellentesque, tellus sem mollis dui, in sodales	$44.28	1943-06-21	3	40
46	5	973	Nunc mauris sapien, cursus in, hendrerit consectetuer, cursus et, magna. Praesent interdum	$4.17	1956-09-22	7	98
47	2	647	nulla. Integer vulputate, risus a ultricies adipiscing, enim mi tempor lorem,	$50.36	2001-02-07	1	52
48	6	798	vitae velit egestas lacinia. Sed congue, elit sed consequat auctor, nunc nulla vulputate	$98.98	1958-09-06	10	56
49	10	262	Proin dolor. Nulla semper tellus id nunc interdum feugiat. Sed nec metus	$15.86	1943-06-06	10	80
50	1	221	Fusce aliquet magna a neque. Nullam ut nisi	$87.70	1984-11-27	6	66
51	4	251	cursus. Nunc mauris elit, dictum eu, eleifend nec, malesuada ut, sem.	$94.75	1972-08-18	3	92
52	2	776	risus varius orci, in consequat enim diam vel arcu. Curabitur ut odio vel est	$90.99	1987-06-13	6	64
53	3	91	libero. Donec consectetuer mauris id sapien. Cras dolor dolor, tempus	$87.25	1933-07-18	4	24
54	8	963	iaculis quis, pede. Praesent eu dui. Cum sociis natoque penatibus et magnis dis	$7.31	1976-06-30	1	5
55	1	822	amet nulla. Donec non justo. Proin	$54.91	1947-02-24	8	23
56	1	684	dictum. Proin eget odio. Aliquam vulputate ullamcorper magna. Sed eu eros.	$51.07	1973-01-15	6	72
57	7	406	accumsan convallis, ante lectus convallis est, vitae sodales	$77.13	1986-08-22	8	50
58	10	280	et, commodo at, libero. Morbi accumsan laoreet ipsum. Curabitur consequat, lectus sit amet luctus vulputate,	$18.39	1963-11-17	9	44
59	9	132	arcu. Curabitur ut odio vel est tempor bibendum. Donec	$5.59	2019-08-07	6	34
60	3	525	quam vel sapien imperdiet ornare. In faucibus. Morbi vehicula. Pellentesque tincidunt tempus risus.	$65.64	1945-10-09	6	21
61	9	71	amet ultricies sem magna nec	$47.90	2013-03-20	8	91
62	3	15	in magna. Phasellus dolor elit, pellentesque a, facilisis non, bibendum	$9.33	1940-08-12	9	75
63	2	230	Morbi metus. Vivamus euismod urna.	$25.24	1996-08-19	4	70
64	6	200	pede. Cras vulputate velit eu sem. Pellentesque ut	$0.64	1950-04-28	10	77
65	4	546	sed dolor. Fusce mi lorem, vehicula et, rutrum eu, ultrices sit amet,	$69.17	1964-08-06	6	48
66	2	216	at risus. Nunc ac sem ut dolor dapibus gravida. Aliquam tincidunt, nunc ac	$93.56	1989-02-19	5	13
67	9	691	eget, ipsum. Donec sollicitudin adipiscing ligula. Aenean gravida nunc sed pede. Cum	$11.20	1936-10-21	7	54
68	7	445	risus odio, auctor vitae, aliquet nec, imperdiet nec, leo. Morbi neque tellus, imperdiet non,	$58.27	1968-08-16	1	75
69	9	689	velit. Cras lorem lorem, luctus ut,	$17.91	1948-07-18	6	3
70	7	342	Nunc commodo auctor velit. Aliquam nisl. Nulla eu neque	$65.14	1937-02-07	1	77
71	9	786	Nulla dignissim. Maecenas ornare egestas ligula. Nullam feugiat placerat velit. Quisque varius. Nam	$52.02	1952-03-03	10	27
72	8	655	dolor sit amet, consectetuer adipiscing elit. Aliquam	$8.03	1993-04-04	1	80
73	1	563	Praesent luctus. Curabitur egestas nunc sed libero. Proin sed turpis nec mauris blandit mattis.	$0.78	1952-04-19	9	94
74	3	528	Duis gravida. Praesent eu nulla at sem molestie sodales. Mauris blandit enim consequat purus.	$7.31	1936-06-27	9	15
75	5	898	dictum magna. Ut tincidunt orci quis lectus. Nullam suscipit, est ac	$68.43	2001-12-04	9	15
76	9	604	quam quis diam. Pellentesque habitant morbi tristique senectus et netus et malesuada	$71.75	1973-02-28	2	49
77	7	694	ridiculus mus. Proin vel nisl. Quisque fringilla euismod enim. Etiam gravida molestie arcu. Sed eu	$64.49	1977-10-11	10	6
78	9	174	in, tempus eu, ligula. Aenean euismod mauris eu elit. Nulla facilisi. Sed neque. Sed eget	$33.80	1995-01-07	4	72
79	2	918	ante lectus convallis est, vitae sodales nisi magna sed dui. Fusce aliquam, enim nec tempus	$77.75	1936-07-31	6	63
80	9	286	dictum ultricies ligula. Nullam enim. Sed nulla ante, iaculis nec, eleifend non, dapibus rutrum,	$86.10	2006-08-07	4	73
81	8	90	In tincidunt congue turpis. In condimentum. Donec at	$41.01	1963-05-07	9	10
82	1	951	sed libero. Proin sed turpis nec mauris blandit	$91.56	1957-06-01	2	23
83	6	905	erat vel pede blandit congue. In scelerisque scelerisque dui. Suspendisse ac metus vitae	$85.22	1999-05-14	7	63
84	8	289	neque. Morbi quis urna. Nunc quis arcu vel quam dignissim pharetra. Nam ac nulla.	$84.64	1993-04-27	5	7
85	5	787	pellentesque massa lobortis ultrices. Vivamus rhoncus. Donec est. Nunc ullamcorper,	$90.19	1947-11-16	1	24
86	7	470	Nam ligula elit, pretium et, rutrum non, hendrerit id, ante. Nunc	$85.19	2004-10-10	3	11
87	1	45	diam dictum sapien. Aenean massa. Integer vitae nibh. Donec est	$6.03	1938-11-19	7	23
88	9	954	placerat, orci lacus vestibulum lorem, sit amet ultricies	$57.70	1932-07-15	10	65
89	8	962	quam quis diam. Pellentesque habitant morbi tristique senectus	$27.07	2008-03-21	7	19
90	8	163	malesuada fames ac turpis egestas. Fusce aliquet magna a neque. Nullam ut nisi a odio	$69.69	1936-02-25	7	15
91	7	525	arcu. Vestibulum ante ipsum primis in faucibus orci luctus	$20.31	1947-09-07	9	77
92	7	88	magna. Nam ligula elit, pretium et, rutrum non, hendrerit id, ante.	$94.88	1993-05-18	3	68
93	2	450	sem ut dolor dapibus gravida.	$86.53	1966-08-30	3	78
94	8	576	leo, in lobortis tellus justo sit amet nulla. Donec	$84.89	1934-03-28	9	2
95	6	769	non ante bibendum ullamcorper. Duis cursus, diam at pretium aliquet,	$21.18	1936-10-15	7	58
96	4	417	Nullam vitae diam. Proin dolor. Nulla semper tellus id nunc	$65.53	2010-06-24	10	41
97	4	993	quam a felis ullamcorper viverra. Maecenas iaculis aliquet diam. Sed diam lorem,	$85.84	1963-05-29	5	69
98	3	196	purus. Duis elementum, dui quis accumsan convallis,	$32.34	1933-06-10	9	99
99	3	408	venenatis vel, faucibus id, libero.	$34.94	1959-09-29	4	61
100	3	232	massa. Suspendisse eleifend. Cras sed leo. Cras vehicula aliquet libero.	$95.44	1955-04-01	1	60
101	2	82	erat, in consectetuer ipsum nunc	$94.57	1955-08-20	10	14
102	5	724	magna. Suspendisse tristique neque venenatis lacus. Etiam bibendum fermentum metus.	$26.77	1957-05-19	5	95
103	3	951	mi. Aliquam gravida mauris ut mi. Duis risus odio, auctor vitae, aliquet nec,	$87.01	1944-11-07	5	71
104	7	184	mattis velit justo nec ante. Maecenas mi felis, adipiscing fringilla,	$32.08	2019-07-30	8	8
105	4	260	adipiscing elit. Etiam laoreet, libero et tristique pellentesque, tellus sem mollis	$55.58	1989-08-04	3	57
106	4	468	Nullam scelerisque neque sed sem egestas blandit. Nam nulla magna, malesuada vel,	$32.15	1970-03-03	6	48
107	1	250	mauris sit amet lorem semper auctor. Mauris vel turpis. Aliquam adipiscing	$16.26	2006-11-03	3	47
108	1	777	Sed pharetra, felis eget varius ultrices, mauris ipsum porta elit, a feugiat	$80.82	1968-03-05	3	46
109	2	498	tellus, imperdiet non, vestibulum nec, euismod in, dolor. Fusce feugiat. Lorem ipsum dolor	$16.04	1983-01-13	5	6
110	10	672	Curae; Phasellus ornare. Fusce mollis. Duis sit amet diam eu dolor egestas rhoncus. Proin nisl	$55.33	1988-11-28	7	91
111	8	632	Duis at lacus. Quisque purus sapien, gravida non, sollicitudin a, malesuada id,	$92.93	1982-04-13	9	86
112	4	271	eget metus eu erat semper rutrum. Fusce dolor quam, elementum at, egestas a,	$19.66	1949-05-10	3	17
113	6	755	Duis risus odio, auctor vitae, aliquet nec, imperdiet nec, leo. Morbi neque	$12.46	1948-08-03	9	2
114	2	854	Cum sociis natoque penatibus et magnis dis parturient montes, nascetur ridiculus mus.	$82.78	2002-08-03	7	73
115	3	536	Donec feugiat metus sit amet ante. Vivamus non lorem vitae odio sagittis semper.	$36.28	1973-03-22	10	25
116	7	491	sagittis. Duis gravida. Praesent eu nulla at sem molestie sodales. Mauris	$36.42	1989-06-22	7	41
117	9	676	faucibus. Morbi vehicula. Pellentesque tincidunt tempus risus. Donec egestas.	$62.68	1993-02-19	8	32
118	2	876	metus. Aenean sed pede nec ante blandit viverra. Donec	$50.85	2001-05-04	9	63
119	8	560	amet ornare lectus justo eu arcu. Morbi sit amet	$52.05	1946-01-18	3	2
120	7	51	adipiscing ligula. Aenean gravida nunc sed pede. Cum sociis natoque	$41.49	2013-04-06	1	97
121	9	332	cursus non, egestas a, dui. Cras	$25.42	2007-05-24	7	83
122	8	830	ut, pellentesque eget, dictum placerat, augue. Sed molestie. Sed id risus quis	$47.88	1943-07-21	8	98
123	7	597	eget lacus. Mauris non dui nec urna suscipit nonummy. Fusce	$91.94	1999-11-13	3	61
124	5	923	imperdiet non, vestibulum nec, euismod in, dolor. Fusce feugiat. Lorem ipsum dolor sit amet,	$98.93	1958-11-09	7	79
125	10	101	Ut semper pretium neque. Morbi quis	$57.26	1977-02-05	6	87
126	9	994	Nullam velit dui, semper et, lacinia vitae, sodales at, velit.	$27.12	1943-01-04	2	38
127	3	82	vitae risus. Duis a mi fringilla mi	$92.29	1933-12-25	1	18
128	8	521	egestas, urna justo faucibus lectus, a sollicitudin orci sem eget massa. Suspendisse eleifend. Cras	$29.32	1986-01-21	10	27
129	6	65	Quisque varius. Nam porttitor scelerisque neque. Nullam nisl. Maecenas malesuada fringilla est. Mauris	$92.71	2010-04-19	10	100
130	2	281	adipiscing elit. Etiam laoreet, libero et tristique	$82.33	2005-06-04	10	8
131	1	628	diam. Sed diam lorem, auctor quis, tristique	$28.47	1957-02-28	9	58
132	4	153	dictum ultricies ligula. Nullam enim. Sed nulla ante, iaculis nec, eleifend	$56.64	1972-05-20	5	1
133	4	829	nec, diam. Duis mi enim, condimentum eget, volutpat ornare, facilisis eget, ipsum. Donec	$87.84	1996-04-29	4	3
134	7	625	pede. Suspendisse dui. Fusce diam nunc, ullamcorper eu, euismod ac, fermentum vel, mauris. Integer	$64.53	1952-07-16	7	14
135	2	127	arcu. Nunc mauris. Morbi non sapien molestie orci tincidunt adipiscing.	$86.54	2004-05-24	2	67
136	6	631	mi fringilla mi lacinia mattis. Integer eu lacus. Quisque imperdiet, erat	$46.67	1960-10-11	4	4
137	5	333	amet massa. Quisque porttitor eros nec	$40.51	1961-05-18	5	62
138	6	318	ipsum. Suspendisse non leo. Vivamus nibh dolor,	$17.91	1961-02-22	3	32
139	7	725	molestie in, tempus eu, ligula. Aenean euismod mauris eu elit. Nulla facilisi. Sed neque. Sed	$35.29	2007-07-17	9	67
140	9	378	ultrices posuere cubilia Curae; Phasellus ornare. Fusce mollis. Duis sit amet	$26.49	2001-08-12	5	60
141	1	349	sagittis felis. Donec tempor, est ac mattis semper, dui lectus rutrum urna, nec luctus felis	$44.77	1959-05-24	5	62
142	9	279	Sed pharetra, felis eget varius ultrices, mauris ipsum porta elit, a feugiat tellus lorem	$65.49	1938-08-31	5	98
143	10	815	Vivamus euismod urna. Nullam lobortis quam a felis ullamcorper viverra. Maecenas iaculis aliquet diam.	$29.80	1990-07-06	8	65
144	5	500	molestie in, tempus eu, ligula.	$80.22	1951-12-19	8	68
145	4	513	Duis gravida. Praesent eu nulla at sem molestie sodales. Mauris blandit	$5.60	1940-01-20	9	7
146	7	41	Sed congue, elit sed consequat auctor, nunc nulla vulputate dui, nec	$6.19	1992-06-26	9	13
147	3	917	risus. Nulla eget metus eu erat semper rutrum. Fusce dolor quam, elementum at,	$32.50	1978-08-27	6	31
148	4	563	Quisque purus sapien, gravida non, sollicitudin	$56.83	2012-04-23	2	90
149	4	582	semper erat, in consectetuer ipsum nunc id enim. Curabitur massa. Vestibulum accumsan neque et	$3.24	1972-12-08	6	22
150	7	434	magnis dis parturient montes, nascetur ridiculus mus. Proin	$51.18	1982-07-11	10	34
151	2	937	feugiat. Lorem ipsum dolor sit amet,	$30.34	1956-03-10	4	10
152	6	697	quam quis diam. Pellentesque habitant morbi tristique senectus et	$32.56	1985-07-18	10	57
153	1	34	egestas ligula. Nullam feugiat placerat velit. Quisque	$82.06	2011-02-14	7	9
154	6	579	Proin velit. Sed malesuada augue ut lacus. Nulla	$50.14	1979-09-22	3	90
155	7	749	tempus mauris erat eget ipsum. Suspendisse sagittis. Nullam vitae diam. Proin dolor. Nulla	$16.72	1954-10-06	1	34
156	4	426	id ante dictum cursus. Nunc mauris elit, dictum eu, eleifend nec,	$10.92	1943-03-10	4	31
157	9	250	nascetur ridiculus mus. Aenean eget magna. Suspendisse tristique neque	$99.80	1956-10-28	9	78
158	8	913	odio, auctor vitae, aliquet nec, imperdiet nec, leo. Morbi neque tellus, imperdiet non,	$94.47	1948-05-20	1	64
159	9	550	justo sit amet nulla. Donec non justo. Proin non massa non ante bibendum ullamcorper.	$72.39	2006-07-10	9	28
160	9	710	ornare egestas ligula. Nullam feugiat placerat velit. Quisque varius. Nam porttitor	$43.16	1974-07-04	4	14
161	2	545	odio a purus. Duis elementum, dui quis accumsan convallis,	$34.53	1966-08-16	5	7
162	1	698	dui. Fusce diam nunc, ullamcorper eu, euismod ac, fermentum vel, mauris. Integer sem elit,	$24.78	1980-09-08	10	84
163	5	70	ipsum nunc id enim. Curabitur	$19.21	1940-12-13	2	71
164	9	541	enim. Etiam gravida molestie arcu. Sed eu nibh vulputate mauris sagittis placerat. Cras	$94.44	1931-08-17	5	43
165	10	516	pede blandit congue. In scelerisque scelerisque dui. Suspendisse ac metus vitae	$9.93	1981-05-24	3	32
166	5	186	bibendum fermentum metus. Aenean sed pede nec ante blandit viverra.	$51.41	1960-12-21	2	44
167	4	607	tellus sem mollis dui, in sodales elit	$18.73	1981-09-05	3	10
168	1	383	ut, nulla. Cras eu tellus eu augue porttitor interdum.	$25.01	1980-07-10	3	92
169	10	348	libero mauris, aliquam eu, accumsan sed,	$25.22	2015-12-19	7	3
170	8	488	Nullam nisl. Maecenas malesuada fringilla est. Mauris eu turpis. Nulla aliquet. Proin velit. Sed	$99.49	1954-04-06	3	47
171	2	887	dapibus gravida. Aliquam tincidunt, nunc ac mattis ornare, lectus ante	$86.24	1938-01-13	8	31
172	2	752	molestie in, tempus eu, ligula. Aenean euismod mauris eu elit. Nulla facilisi. Sed	$49.53	2010-11-01	3	7
173	7	619	mauris sagittis placerat. Cras dictum ultricies ligula. Nullam enim. Sed nulla ante, iaculis	$15.17	1931-10-09	8	44
174	8	488	Integer vitae nibh. Donec est mauris, rhoncus id,	$89.97	1965-01-15	5	69
175	3	929	eleifend. Cras sed leo. Cras	$69.77	1962-03-13	4	11
176	2	378	quis urna. Nunc quis arcu vel quam dignissim pharetra. Nam ac nulla. In tincidunt congue	$17.15	1983-01-04	8	44
238	9	340	non leo. Vivamus nibh dolor, nonummy ac, feugiat	$8.65	2003-03-23	5	66
177	6	129	sapien molestie orci tincidunt adipiscing. Mauris molestie pharetra nibh. Aliquam ornare, libero at	$40.86	2013-08-13	5	24
178	6	503	et nunc. Quisque ornare tortor at	$34.55	1948-02-19	4	44
179	3	287	sit amet, consectetuer adipiscing elit. Curabitur sed tortor. Integer	$92.38	1973-01-19	10	13
180	1	153	Phasellus vitae mauris sit amet lorem semper auctor. Mauris vel turpis. Aliquam	$61.28	1983-10-02	7	96
181	7	447	lorem lorem, luctus ut, pellentesque eget,	$85.19	2008-09-14	4	7
182	2	935	libero. Proin sed turpis nec	$58.61	1960-05-07	7	84
183	2	872	adipiscing fringilla, porttitor vulputate, posuere	$90.93	2018-07-20	5	20
184	7	545	enim diam vel arcu. Curabitur ut odio vel est tempor	$2.82	1942-10-14	1	82
185	9	261	dapibus id, blandit at, nisi. Cum sociis natoque	$31.62	1939-07-16	5	76
186	3	599	dignissim. Maecenas ornare egestas ligula. Nullam feugiat placerat velit.	$96.29	1997-03-27	6	48
187	1	225	pharetra. Nam ac nulla. In tincidunt congue turpis. In condimentum. Donec	$58.77	1948-01-21	9	8
188	10	965	Nunc mauris sapien, cursus in, hendrerit consectetuer, cursus et,	$9.63	1953-02-18	3	2
189	10	469	a mi fringilla mi lacinia mattis. Integer eu lacus. Quisque imperdiet, erat	$39.94	1943-07-22	10	93
190	10	445	Cras sed leo. Cras vehicula aliquet libero. Integer	$71.56	1959-11-14	1	85
191	2	855	malesuada augue ut lacus. Nulla tincidunt,	$34.71	1941-06-12	10	19
192	5	784	dignissim lacus. Aliquam rutrum lorem ac risus. Morbi metus. Vivamus euismod urna. Nullam	$11.94	1949-12-20	2	57
193	9	962	urna. Nunc quis arcu vel quam dignissim	$60.45	1970-01-05	10	20
194	4	528	ut ipsum ac mi eleifend egestas. Sed pharetra, felis eget varius ultrices, mauris	$54.20	1977-08-08	2	13
195	3	758	dui quis accumsan convallis, ante lectus	$80.99	1949-01-08	4	53
196	3	233	molestie orci tincidunt adipiscing. Mauris molestie pharetra	$2.51	1976-09-02	6	87
197	2	550	enim. Curabitur massa. Vestibulum accumsan neque	$45.08	1961-06-06	4	100
198	1	292	purus mauris a nunc. In at pede. Cras vulputate velit eu sem. Pellentesque	$88.23	1934-01-29	3	48
199	10	1	eleifend nec, malesuada ut, sem. Nulla interdum. Curabitur	$54.18	1931-04-10	7	64
200	8	558	dui augue eu tellus. Phasellus elit	$8.74	1982-02-01	5	6
201	5	730	mauris. Morbi non sapien molestie orci tincidunt	$72.06	1982-02-22	1	47
202	4	321	penatibus et magnis dis parturient montes, nascetur ridiculus mus. Donec dignissim magna	$83.45	1987-08-30	8	86
203	6	40	adipiscing elit. Curabitur sed tortor. Integer aliquam adipiscing lacus.	$22.40	1960-07-11	9	49
204	5	731	neque. In ornare sagittis felis. Donec tempor, est ac	$78.33	2012-10-29	5	81
205	7	775	ac libero nec ligula consectetuer rhoncus. Nullam velit dui, semper et, lacinia vitae,	$38.36	2016-09-17	8	12
206	5	623	leo. Morbi neque tellus, imperdiet non, vestibulum nec, euismod in,	$95.62	1940-10-02	7	6
207	10	761	Aliquam tincidunt, nunc ac mattis ornare, lectus ante	$37.65	1953-03-27	2	72
208	1	906	imperdiet ornare. In faucibus. Morbi vehicula. Pellentesque tincidunt tempus risus. Donec egestas. Duis	$30.08	1979-03-23	5	79
209	5	189	porttitor tellus non magna. Nam ligula elit, pretium et, rutrum non, hendrerit id, ante.	$1.54	1953-01-23	10	36
210	9	550	sit amet ultricies sem magna nec quam. Curabitur vel lectus. Cum sociis natoque penatibus	$49.24	1943-12-07	7	9
211	6	516	tempor lorem, eget mollis lectus pede	$71.45	1986-06-28	6	20
212	6	286	Nullam lobortis quam a felis ullamcorper viverra. Maecenas iaculis	$71.44	1985-05-22	6	37
213	8	53	urna. Nunc quis arcu vel quam dignissim pharetra.	$41.57	2018-06-09	1	69
214	4	429	sapien. Nunc pulvinar arcu et pede. Nunc sed orci	$48.61	1931-04-19	1	43
215	7	141	Aliquam nisl. Nulla eu neque pellentesque massa lobortis ultrices. Vivamus rhoncus. Donec	$16.58	1980-04-06	3	67
216	5	263	magna. Cras convallis convallis dolor. Quisque tincidunt pede	$84.40	2008-07-04	3	46
217	3	753	sit amet, consectetuer adipiscing elit. Curabitur sed tortor. Integer aliquam	$23.30	1942-06-27	4	90
218	7	968	sed orci lobortis augue scelerisque mollis.	$93.78	1987-03-01	3	81
219	4	669	Nullam feugiat placerat velit. Quisque varius. Nam	$38.26	1956-11-01	7	28
220	3	997	dui quis accumsan convallis, ante lectus convallis	$3.14	1996-11-11	6	100
221	10	187	eu enim. Etiam imperdiet dictum magna.	$66.80	1989-12-17	2	70
222	8	684	non nisi. Aenean eget metus. In nec orci. Donec nibh. Quisque nonummy ipsum non	$75.11	1952-12-10	5	87
223	3	683	dictum cursus. Nunc mauris elit, dictum eu, eleifend nec, malesuada ut,	$44.49	1967-10-26	2	89
224	10	544	eu, eleifend nec, malesuada ut, sem. Nulla interdum. Curabitur dictum. Phasellus in felis. Nulla	$79.97	1976-05-31	6	16
225	7	46	viverra. Maecenas iaculis aliquet diam. Sed diam lorem,	$78.85	1952-03-19	6	48
226	6	781	vulputate, posuere vulputate, lacus. Cras interdum. Nunc	$42.81	1983-01-23	6	7
227	1	196	malesuada malesuada. Integer id magna et ipsum cursus	$44.01	1947-02-17	5	28
228	10	567	Proin velit. Sed malesuada augue ut lacus. Nulla	$37.77	1942-11-04	6	57
229	7	818	Aliquam tincidunt, nunc ac mattis ornare, lectus ante dictum	$39.00	1992-02-12	2	68
230	6	353	Donec luctus aliquet odio. Etiam ligula tortor, dictum eu, placerat eget, venenatis a, magna. Lorem	$2.27	1968-11-22	2	48
231	8	412	Sed malesuada augue ut lacus. Nulla tincidunt, neque vitae semper egestas, urna	$85.53	1931-07-21	4	55
232	7	995	malesuada vel, convallis in, cursus et, eros. Proin ultrices.	$51.14	2009-11-17	3	15
233	2	82	egestas a, dui. Cras pellentesque. Sed dictum. Proin eget odio. Aliquam vulputate ullamcorper magna. Sed	$38.09	1941-11-07	6	64
234	6	459	Lorem ipsum dolor sit amet, consectetuer adipiscing elit. Aliquam	$21.88	1974-02-13	3	78
235	9	585	accumsan neque et nunc. Quisque ornare tortor at	$9.13	1956-05-23	3	10
236	7	616	sed tortor. Integer aliquam adipiscing lacus. Ut nec urna et arcu imperdiet ullamcorper.	$83.86	2000-03-03	4	24
237	1	135	elementum sem, vitae aliquam eros turpis non enim. Mauris quis turpis vitae purus gravida	$32.37	1992-08-09	9	44
239	10	176	ante lectus convallis est, vitae sodales nisi magna sed	$11.53	1988-04-05	8	44
240	8	160	nonummy ultricies ornare, elit elit fermentum	$81.18	2012-07-12	9	51
241	6	788	sapien, cursus in, hendrerit consectetuer, cursus et, magna. Praesent	$24.11	2003-06-27	6	14
242	5	221	ornare, elit elit fermentum risus,	$23.37	1985-06-23	8	49
243	9	380	lorem lorem, luctus ut, pellentesque	$68.85	1980-05-04	4	28
244	10	488	Nulla dignissim. Maecenas ornare egestas ligula. Nullam	$50.35	1990-11-30	10	14
245	5	714	sed pede nec ante blandit viverra. Donec tempus, lorem	$76.80	1996-07-27	6	31
246	8	393	dui quis accumsan convallis, ante	$19.31	1936-12-22	8	60
247	4	15	Mauris molestie pharetra nibh. Aliquam ornare, libero	$15.13	1967-10-20	7	17
248	1	80	nulla. Integer vulputate, risus a ultricies adipiscing, enim mi tempor lorem, eget mollis	$20.02	1963-02-27	7	57
249	6	216	dui. Cum sociis natoque penatibus et magnis dis parturient montes, nascetur ridiculus mus. Aenean eget	$37.15	1990-10-03	5	62
250	3	272	urna, nec luctus felis purus ac tellus. Suspendisse sed dolor.	$15.38	1993-03-22	5	89
251	9	432	id, mollis nec, cursus a, enim. Suspendisse aliquet, sem ut cursus luctus,	$67.50	1983-03-10	2	51
252	9	910	ligula. Aenean euismod mauris eu elit. Nulla facilisi.	$9.76	1962-11-30	8	84
253	7	230	erat vel pede blandit congue. In scelerisque scelerisque dui. Suspendisse ac	$5.24	2008-12-05	7	81
254	6	321	Quisque ornare tortor at risus.	$55.69	1971-01-11	9	23
255	8	285	fermentum metus. Aenean sed pede nec ante blandit viverra.	$41.88	2013-08-19	7	31
256	4	555	placerat, orci lacus vestibulum lorem, sit amet ultricies sem magna nec quam. Curabitur	$91.54	1949-09-27	2	92
257	8	987	massa. Integer vitae nibh. Donec est	$91.15	1968-09-04	8	3
258	1	365	consectetuer adipiscing elit. Etiam laoreet, libero	$2.19	1980-02-12	5	74
259	3	978	velit. Pellentesque ultricies dignissim lacus. Aliquam rutrum lorem ac risus. Morbi metus.	$45.66	1943-07-31	2	87
260	3	659	augue id ante dictum cursus. Nunc mauris elit, dictum eu, eleifend nec, malesuada ut,	$26.19	2006-12-25	9	15
261	9	955	torquent per conubia nostra, per inceptos hymenaeos. Mauris ut quam vel sapien imperdiet ornare.	$99.09	1984-11-21	8	78
262	5	315	ligula elit, pretium et, rutrum non, hendrerit id, ante. Nunc mauris sapien, cursus	$72.29	1989-07-09	9	82
263	3	672	fermentum vel, mauris. Integer sem elit, pharetra ut, pharetra	$85.61	1989-01-26	3	6
264	5	526	Quisque libero lacus, varius et, euismod et, commodo at, libero. Morbi accumsan laoreet ipsum.	$68.11	1930-06-25	3	95
265	4	960	vel sapien imperdiet ornare. In faucibus. Morbi vehicula.	$7.93	1943-03-12	5	27
266	9	279	Etiam laoreet, libero et tristique pellentesque, tellus	$37.51	1966-02-08	2	4
267	7	307	Curabitur consequat, lectus sit amet luctus vulputate, nisi sem semper	$74.32	1965-01-01	4	84
268	9	93	mauris elit, dictum eu, eleifend nec,	$74.74	1970-05-22	10	30
269	4	874	posuere cubilia Curae; Phasellus ornare. Fusce mollis. Duis sit amet diam eu dolor egestas rhoncus.	$15.93	1941-08-17	2	72
270	3	486	est mauris, rhoncus id, mollis nec, cursus	$51.06	1944-06-12	10	63
271	1	108	convallis, ante lectus convallis est, vitae sodales nisi magna sed dui.	$62.84	2000-05-07	2	18
272	5	322	sed leo. Cras vehicula aliquet libero. Integer in magna. Phasellus	$28.31	1979-09-15	8	68
273	9	623	amet, risus. Donec nibh enim, gravida	$12.84	1958-06-28	1	49
274	9	76	vitae, posuere at, velit. Cras lorem lorem, luctus ut,	$70.48	1936-04-05	5	78
275	1	601	semper et, lacinia vitae, sodales at, velit. Pellentesque ultricies dignissim lacus. Aliquam rutrum lorem	$26.41	1982-05-13	8	80
276	6	510	pede. Nunc sed orci lobortis augue scelerisque mollis. Phasellus libero mauris, aliquam	$5.06	1964-02-24	1	54
277	5	63	facilisis, magna tellus faucibus leo, in lobortis tellus justo sit amet nulla.	$63.82	2016-03-22	8	75
278	6	85	amet nulla. Donec non justo. Proin non massa non ante bibendum ullamcorper. Duis cursus, diam	$18.54	1985-05-28	5	35
279	5	111	quis arcu vel quam dignissim	$10.89	1973-04-21	5	72
280	3	106	quis accumsan convallis, ante lectus convallis est, vitae sodales nisi magna sed dui. Fusce	$7.97	2007-04-01	8	73
281	2	857	lacinia. Sed congue, elit sed consequat auctor, nunc nulla vulputate dui, nec	$33.96	1959-10-08	1	78
282	10	152	rhoncus. Nullam velit dui, semper	$13.28	1946-12-09	10	1
283	4	786	elementum sem, vitae aliquam eros	$2.42	1943-12-18	1	6
284	6	170	amet risus. Donec egestas. Aliquam nec enim. Nunc ut erat.	$36.76	1966-01-12	3	88
285	5	0	vitae aliquam eros turpis non enim. Mauris quis turpis vitae purus gravida sagittis. Duis	$98.47	2010-05-31	10	45
286	7	385	arcu iaculis enim, sit amet ornare	$73.09	2005-09-13	10	20
287	3	60	dignissim pharetra. Nam ac nulla.	$28.47	1959-05-31	7	30
288	10	229	et malesuada fames ac turpis	$31.58	1983-09-29	5	16
289	10	937	turpis egestas. Fusce aliquet magna a neque. Nullam ut nisi a odio semper cursus.	$43.20	1956-02-12	3	10
290	7	246	vitae purus gravida sagittis. Duis gravida. Praesent eu nulla	$10.08	1981-07-26	2	53
291	2	664	lobortis quam a felis ullamcorper viverra. Maecenas iaculis aliquet diam. Sed diam lorem, auctor quis,	$7.51	1982-05-11	3	25
292	10	523	ipsum sodales purus, in molestie tortor nibh sit amet orci. Ut sagittis lobortis	$28.27	1987-02-21	6	78
293	4	109	euismod est arcu ac orci. Ut semper	$27.96	2008-02-21	10	79
294	3	555	mollis. Duis sit amet diam eu dolor	$71.42	1955-11-08	8	37
295	10	992	pharetra. Nam ac nulla. In tincidunt	$89.51	1967-06-20	7	29
296	10	897	vitae odio sagittis semper. Nam tempor diam dictum sapien.	$97.01	2007-03-04	8	25
297	9	876	dictum. Phasellus in felis. Nulla tempor	$94.42	2017-11-22	8	3
298	7	336	vel est tempor bibendum. Donec	$73.68	1948-07-19	10	1
299	2	328	augue ut lacus. Nulla tincidunt, neque vitae semper egestas,	$87.32	2008-04-18	8	47
300	5	162	Duis mi enim, condimentum eget, volutpat	$98.56	1975-09-20	4	39
301	4	749	mauris elit, dictum eu, eleifend	$93.82	2006-08-15	3	100
302	1	374	ut mi. Duis risus odio, auctor vitae, aliquet	$88.77	1979-07-28	6	72
303	3	172	nibh lacinia orci, consectetuer euismod est arcu ac orci. Ut semper pretium neque. Morbi quis	$67.26	1994-06-22	3	28
304	5	563	est, mollis non, cursus non, egestas a,	$14.29	2013-02-02	1	75
305	1	272	id, erat. Etiam vestibulum massa rutrum magna. Cras convallis convallis dolor. Quisque tincidunt	$51.48	2010-10-19	9	24
306	5	98	nisi. Mauris nulla. Integer urna. Vivamus molestie dapibus ligula. Aliquam erat volutpat. Nulla dignissim. Maecenas	$20.43	1959-06-04	7	4
307	9	21	Aliquam erat volutpat. Nulla dignissim. Maecenas ornare egestas ligula. Nullam feugiat placerat velit. Quisque	$36.00	1972-08-29	2	33
308	6	761	vestibulum nec, euismod in, dolor. Fusce feugiat. Lorem ipsum dolor sit amet,	$84.51	1997-12-29	8	62
309	5	828	posuere cubilia Curae; Phasellus ornare. Fusce mollis. Duis sit amet diam	$71.23	1981-12-26	1	78
310	3	653	Mauris eu turpis. Nulla aliquet. Proin velit. Sed malesuada augue	$8.54	1980-08-08	7	12
311	3	304	augue malesuada malesuada. Integer id	$73.57	1968-01-25	6	44
312	3	432	imperdiet dictum magna. Ut tincidunt orci quis lectus. Nullam suscipit,	$36.57	1991-11-30	6	86
313	3	592	Proin vel nisl. Quisque fringilla euismod enim. Etiam gravida molestie arcu. Sed eu	$70.59	1954-12-14	9	34
314	7	289	imperdiet dictum magna. Ut tincidunt orci quis lectus. Nullam suscipit, est ac facilisis facilisis, magna	$60.35	1978-11-28	9	18
315	3	783	Sed neque. Sed eget lacus. Mauris non dui nec urna suscipit nonummy. Fusce	$30.63	1979-01-25	2	64
316	3	969	mollis nec, cursus a, enim. Suspendisse aliquet,	$19.29	1966-03-13	3	82
317	5	36	vestibulum lorem, sit amet ultricies sem magna nec quam. Curabitur	$70.86	1961-03-20	1	97
318	8	58	elementum sem, vitae aliquam eros turpis non enim. Mauris quis turpis vitae	$22.73	2014-03-22	3	17
319	8	726	egestas. Aliquam nec enim. Nunc ut erat. Sed nunc est, mollis non, cursus non, egestas	$92.61	2010-08-08	2	72
320	7	309	diam. Pellentesque habitant morbi tristique senectus et netus	$54.42	1986-02-01	10	48
321	1	717	semper et, lacinia vitae, sodales at, velit. Pellentesque ultricies dignissim lacus. Aliquam	$52.97	2007-12-26	6	31
322	10	765	tellus eu augue porttitor interdum. Sed auctor odio a purus. Duis elementum, dui quis	$94.37	1992-06-16	10	2
323	2	801	Nunc ac sem ut dolor	$30.81	1930-05-10	2	5
324	3	773	Donec vitae erat vel pede blandit congue. In scelerisque scelerisque dui. Suspendisse	$85.73	1933-02-28	4	39
325	5	393	tellus. Phasellus elit pede, malesuada vel, venenatis vel, faucibus id, libero. Donec consectetuer	$66.35	1932-09-04	7	71
326	10	478	justo faucibus lectus, a sollicitudin orci	$51.06	1931-06-24	4	95
327	4	542	sem ut dolor dapibus gravida.	$82.02	1974-03-19	1	64
328	6	785	at, iaculis quis, pede. Praesent eu dui. Cum sociis natoque penatibus et magnis dis	$56.57	2005-10-19	6	42
329	5	572	montes, nascetur ridiculus mus. Proin vel nisl. Quisque fringilla euismod enim. Etiam gravida molestie arcu.	$78.61	1930-07-18	10	35
330	6	742	ipsum non arcu. Vivamus sit amet risus. Donec egestas. Aliquam nec	$88.30	1988-09-20	5	19
331	2	524	lorem, vehicula et, rutrum eu, ultrices sit amet, risus. Donec nibh enim, gravida sit	$39.60	1986-03-07	1	96
332	1	772	Cras vehicula aliquet libero. Integer in magna. Phasellus dolor elit,	$2.06	2020-04-22	10	76
333	4	638	pede ac urna. Ut tincidunt vehicula risus. Nulla eget metus eu	$13.25	1995-09-08	9	50
334	4	106	velit. Aliquam nisl. Nulla eu neque pellentesque massa lobortis ultrices.	$85.18	1962-12-20	1	82
335	4	196	enim. Suspendisse aliquet, sem ut cursus	$70.66	1943-12-10	9	4
336	5	152	amet ornare lectus justo eu arcu. Morbi	$53.61	2018-10-18	6	38
337	8	317	eu, odio. Phasellus at augue id ante	$56.46	1994-02-05	3	71
338	7	416	amet, consectetuer adipiscing elit. Curabitur sed tortor. Integer aliquam adipiscing lacus. Ut nec urna	$98.12	1955-09-24	3	37
339	1	844	egestas. Duis ac arcu. Nunc mauris. Morbi non sapien molestie	$37.60	1947-10-11	6	70
340	8	581	aliquet, sem ut cursus luctus,	$52.47	1952-01-17	4	22
341	3	171	at, nisi. Cum sociis natoque penatibus et magnis dis parturient	$76.66	2002-11-11	8	30
342	9	26	Lorem ipsum dolor sit amet, consectetuer adipiscing elit.	$14.90	1941-06-09	3	39
343	2	332	ligula. Aliquam erat volutpat. Nulla dignissim. Maecenas ornare egestas ligula. Nullam	$59.85	1951-08-24	3	77
344	7	253	pellentesque, tellus sem mollis dui, in	$26.03	2014-08-12	7	40
345	9	402	natoque penatibus et magnis dis	$57.18	1999-07-16	8	82
346	10	342	pede et risus. Quisque libero lacus, varius et, euismod et, commodo at, libero. Morbi accumsan	$47.88	2003-10-28	7	87
347	10	856	Suspendisse eleifend. Cras sed leo. Cras vehicula aliquet	$75.31	1983-09-02	9	14
348	2	803	vulputate, lacus. Cras interdum. Nunc sollicitudin commodo ipsum. Suspendisse non leo.	$11.30	1962-06-04	6	75
349	1	847	non, bibendum sed, est. Nunc laoreet lectus quis massa. Mauris vestibulum, neque sed dictum	$4.23	1988-06-29	3	28
350	10	745	nisl arcu iaculis enim, sit amet ornare lectus justo eu arcu. Morbi sit amet massa.	$98.45	1997-03-24	5	34
351	8	857	adipiscing lobortis risus. In mi pede, nonummy ut,	$35.10	1990-10-10	2	31
352	2	658	est, mollis non, cursus non, egestas a, dui. Cras pellentesque. Sed	$5.34	1961-02-06	3	40
353	8	227	ut quam vel sapien imperdiet ornare. In faucibus. Morbi vehicula. Pellentesque	$18.43	1974-03-09	6	34
354	7	576	ipsum primis in faucibus orci luctus et ultrices posuere cubilia Curae;	$95.56	2016-09-10	8	78
355	8	9	vel arcu. Curabitur ut odio vel est	$36.50	1998-09-04	7	28
356	6	657	tellus justo sit amet nulla. Donec non justo. Proin	$46.71	2016-12-16	3	59
357	4	700	a, enim. Suspendisse aliquet, sem ut cursus luctus, ipsum leo elementum	$88.44	1980-02-20	1	37
358	4	196	sem. Nulla interdum. Curabitur dictum. Phasellus in felis. Nulla	$20.67	2012-09-27	9	37
359	1	491	erat. Etiam vestibulum massa rutrum magna. Cras convallis convallis dolor. Quisque tincidunt pede ac urna.	$39.79	1940-10-18	6	89
360	1	951	nec metus facilisis lorem tristique aliquet. Phasellus fermentum convallis ligula. Donec luctus aliquet	$40.53	1978-05-25	1	46
361	5	662	consequat auctor, nunc nulla vulputate	$48.28	1933-02-01	7	83
362	5	549	Nam ligula elit, pretium et, rutrum non, hendrerit id, ante. Nunc mauris	$13.11	1949-11-09	3	66
363	9	443	egestas ligula. Nullam feugiat placerat velit. Quisque varius. Nam porttitor scelerisque	$29.75	1965-02-15	10	40
364	6	919	mi eleifend egestas. Sed pharetra, felis eget varius ultrices, mauris ipsum porta elit, a	$45.73	1940-02-28	9	80
365	10	193	tortor. Integer aliquam adipiscing lacus. Ut nec urna et arcu imperdiet	$11.99	1986-11-30	2	71
366	2	124	dis parturient montes, nascetur ridiculus	$90.22	2012-08-22	7	70
367	4	966	id sapien. Cras dolor dolor, tempus non, lacinia at, iaculis quis,	$76.41	2019-05-27	7	28
368	2	20	Nunc mauris. Morbi non sapien molestie orci tincidunt adipiscing. Mauris	$19.13	1945-06-19	9	17
369	10	707	Integer id magna et ipsum cursus vestibulum. Mauris magna. Duis dignissim tempor arcu.	$78.40	1963-07-14	7	25
370	9	273	luctus vulputate, nisi sem semper erat, in consectetuer ipsum nunc id enim. Curabitur	$38.99	1952-09-19	5	8
371	1	296	dictum placerat, augue. Sed molestie. Sed id risus quis	$30.10	1995-01-12	7	78
372	1	141	vitae diam. Proin dolor. Nulla semper tellus id nunc interdum feugiat.	$50.97	1993-04-11	7	56
373	5	628	Sed eget lacus. Mauris non dui nec urna suscipit nonummy. Fusce fermentum	$62.18	2016-02-24	7	41
374	3	481	aliquam, enim nec tempus scelerisque, lorem	$4.36	1966-12-18	5	21
375	9	925	sed, est. Nunc laoreet lectus quis massa. Mauris vestibulum, neque sed	$50.47	1958-11-22	3	6
376	3	389	Proin mi. Aliquam gravida mauris ut mi. Duis risus odio, auctor vitae, aliquet nec,	$81.60	2008-04-26	6	71
377	7	309	amet orci. Ut sagittis lobortis mauris. Suspendisse aliquet molestie tellus. Aenean egestas	$93.49	1987-10-19	4	39
378	6	286	porttitor tellus non magna. Nam	$31.05	1952-08-14	9	79
379	5	766	Phasellus ornare. Fusce mollis. Duis sit	$12.19	1932-05-23	9	69
380	5	113	augue ac ipsum. Phasellus vitae mauris sit amet lorem semper auctor. Mauris vel turpis. Aliquam	$63.02	2000-06-12	2	47
381	8	344	scelerisque scelerisque dui. Suspendisse ac metus vitae velit egestas lacinia. Sed	$30.54	2000-05-25	10	91
382	9	405	metus. Aenean sed pede nec ante blandit viverra.	$21.22	1952-01-10	8	98
383	2	66	est. Mauris eu turpis. Nulla aliquet. Proin velit. Sed malesuada augue ut lacus. Nulla	$20.12	1974-03-08	1	72
384	6	124	magna. Duis dignissim tempor arcu. Vestibulum ut eros non enim commodo hendrerit. Donec porttitor tellus	$79.53	1956-07-26	3	48
385	4	158	magna. Sed eu eros. Nam consequat dolor	$17.28	1985-06-27	4	25
386	10	409	sagittis. Duis gravida. Praesent eu nulla at sem molestie	$39.79	1966-10-24	10	45
387	5	359	elit. Aliquam auctor, velit eget laoreet posuere, enim nisl elementum	$48.17	2009-11-01	9	57
388	4	651	Aliquam vulputate ullamcorper magna. Sed eu eros. Nam consequat dolor vitae dolor.	$50.42	1958-07-04	4	5
389	3	354	mauris elit, dictum eu, eleifend nec, malesuada ut, sem. Nulla	$96.58	1943-08-11	10	34
390	7	988	Pellentesque tincidunt tempus risus. Donec egestas.	$92.30	1958-12-14	2	80
391	7	337	dictum. Proin eget odio. Aliquam	$99.20	1942-05-07	10	36
392	8	684	dignissim tempor arcu. Vestibulum ut	$38.70	1985-04-14	9	51
393	2	38	mus. Proin vel arcu eu odio tristique pharetra. Quisque ac libero	$24.89	1967-09-20	8	54
394	2	681	ac mattis velit justo nec ante. Maecenas mi felis, adipiscing fringilla,	$42.39	1949-08-18	1	92
395	7	189	natoque penatibus et magnis dis	$1.40	2004-12-30	1	41
396	10	895	risus. Donec nibh enim, gravida sit amet, dapibus id, blandit at,	$98.98	2011-06-05	7	18
397	3	204	tellus non magna. Nam ligula elit, pretium et, rutrum	$3.38	1983-03-04	4	36
398	3	269	eget magna. Suspendisse tristique neque venenatis lacus. Etiam bibendum fermentum metus. Aenean sed pede nec	$34.73	1960-04-14	6	51
399	3	337	dis parturient montes, nascetur ridiculus mus. Donec dignissim magna	$17.70	1935-06-29	4	9
400	5	300	commodo ipsum. Suspendisse non leo. Vivamus nibh dolor, nonummy ac,	$59.62	1934-04-05	6	43
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
euismod	2
ante	115
magnis	184
nec	68
Donec	72
tellus	86
sit	397
amet	324
orci	363
sit	228
libero.	282
imperdiet	290
congue	322
Aliquam	291
ligula.	27
adipiscing	231
Morbi	132
cursus	183
cursus.	377
ante,	78
a	153
Aenean	131
et	384
nibh	390
ornare,	390
posuere,	204
et	348
Proin	4
egestas.	198
nulla	356
ipsum	100
Curabitur	193
eget	298
Proin	318
dis	247
eget	131
non	118
Curabitur	46
Aliquam	168
laoreet	212
mi	3
Donec	351
sapien,	169
sagittis	72
a	364
a	369
velit	156
dapibus	314
amet	192
pharetra.	303
Donec	290
sem.	274
tempor	244
auctor	174
hendrerit	81
augue	347
vitae,	310
sit	273
diam	209
vitae	16
est,	35
montes,	193
Donec	157
at,	48
Nam	176
nibh	318
Nunc	251
commodo	268
odio.	325
Cras	171
nulla	36
tristique	328
congue	384
rutrum	117
ligula	33
libero.	45
consectetuer	154
molestie	381
viverra.	347
magna.	28
luctus	37
dolor	160
a,	46
Donec	350
dapibus	190
Aliquam	254
euismod	101
nulla	190
ante	120
Nam	328
diam	99
enim.	396
augue	10
est	130
a,	62
aliquet	95
augue	32
vel,	165
at,	197
sem	113
Nunc	87
Proin	105
ultrices.	385
sapien.	290
Nulla	89
per	182
molestie	241
tellus	60
sed	73
velit.	167
ac	378
mi	399
arcu.	168
amet	131
Sed	137
fermentum	103
lorem,	392
bibendum	356
Duis	70
Donec	260
eu	280
lorem	207
Curabitur	370
elementum	234
magnis	51
magna	19
lacus.	96
dolor.	259
pede	285
Quisque	281
scelerisque	240
a	129
non,	34
sed	120
ullamcorper,	303
Donec	119
mauris,	38
sagittis.	182
viverra.	277
nec	123
dui.	90
et	254
dolor,	91
aliquam	136
tellus.	133
orci	334
ridiculus	11
varius	211
diam.	33
orci,	262
eget	238
tristique	69
vehicula	211
sem,	158
nec	224
malesuada	60
vulputate	31
ultricies	208
euismod	341
convallis,	227
molestie	227
nunc	255
aliquet	82
mi	211
augue	58
montes,	291
dolor	326
odio	386
non	136
auctor,	277
ligula	32
sollicitudin	71
malesuada	20
et	161
nec	351
Nunc	337
iaculis	151
a	179
nonummy	287
accumsan	6
accumsan	226
id	271
magna	386
et	250
Nunc	25
iaculis	168
tempor	109
odio	144
diam.	123
lorem	336
aliquam,	18
magnis	160
Aliquam	147
eget	279
magna.	157
a,	372
dui.	177
quis	334
fringilla	148
non,	72
leo.	267
et,	46
dui	306
ornare	181
commodo	164
laoreet	390
molestie	291
iaculis	387
rhoncus.	63
Duis	127
Donec	74
ipsum	240
tempor	293
arcu	135
amet	12
vel	173
sodales	318
purus,	366
nec	256
pede	252
ultricies	293
fringilla,	4
adipiscing,	23
amet	112
dui.	219
vel,	99
egestas	327
purus,	233
sagittis	399
euismod	73
purus.	89
sociis	8
congue	189
et	297
egestas.	196
aliquet	267
in	28
Quisque	179
pede	10
convallis	57
metus	302
pretium	299
Nam	226
ac	163
Aliquam	309
ac	320
nisi	379
non,	151
ornare	322
tristique	6
luctus	81
ut	287
dictum	118
non,	199
tristique	297
sed	217
at	348
luctus	150
mauris	390
pede.	48
egestas.	265
vel	251
tellus	252
diam	172
Ut	36
sit	32
vestibulum	128
sem	88
sapien.	136
Donec	265
dui,	353
vulputate	320
Duis	34
dui.	332
Maecenas	54
eu	147
aliquet,	187
sapien	9
elit,	83
malesuada	196
Proin	393
magna	240
orci	218
Aenean	314
Praesent	223
Nulla	277
amet	210
sit	202
sagittis	73
Nunc	214
in,	204
libero.	21
mi	152
vehicula	301
nisi.	52
ligula.	93
diam	309
at,	100
turpis	276
mi	238
odio.	400
Praesent	122
Nunc	322
aliquam	365
consectetuer	103
scelerisque	127
magna.	152
Duis	13
porttitor	316
Duis	387
lacus,	324
sit	359
metus	219
id	387
sagittis	397
Cum	170
posuere,	390
leo	194
eget	129
neque	318
ipsum.	143
fringilla.	284
nunc.	315
non	4
nunc	345
dui.	56
molestie	316
ridiculus	274
Sed	313
euismod	268
feugiat	294
Quisque	342
Curabitur	305
hendrerit	254
mi,	182
consequat	263
iaculis	57
id,	268
feugiat	174
sed,	385
sem.	391
dolor.	276
tempor	391
dolor	106
accumsan	73
montes,	103
eu,	22
fringilla	110
tristique	255
erat	215
Fusce	230
Nam	153
ridiculus	230
eget	250
viverra.	349
urna.	372
tortor,	281
felis	280
viverra.	384
mauris	320
consequat	215
bibendum	154
erat	136
eu	307
morbi	64
a	78
Donec	314
In	257
Donec	173
molestie	116
hendrerit	82
accumsan	231
Cras	138
aliquet,	190
vulputate,	176
cursus,	274
augue.	283
porta	336
sed	226
amet,	172
vel	115
aliquet	225
lorem	316
Duis	97
tincidunt	243
In	295
scelerisque	320
Quisque	86
luctus	354
Curabitur	4
non	292
odio	168
purus,	57
Etiam	217
Nam	204
gravida	58
Aliquam	50
risus	129
amet,	343
vitae,	95
imperdiet	216
Lorem	238
velit	260
tortor.	253
vestibulum,	25
tincidunt	249
sed	288
elit	59
Donec	368
est,	16
lacinia	254
nibh.	1
convallis	174
Aliquam	181
sit	143
lectus	312
convallis	286
non	20
tincidunt	74
ut	343
vehicula.	387
tempor	5
sodales	256
Vivamus	168
pellentesque,	364
volutpat	245
in	329
adipiscing	110
nunc.	220
egestas	352
vel	357
cubilia	361
mi.	294
vel,	260
diam.	268
Phasellus	353
Quisque	302
enim.	213
et	271
blandit	186
sit	352
adipiscing	383
tortor.	31
eget	350
consequat	35
nibh	93
dignissim	157
Duis	303
ipsum	282
sem	87
erat	361
eu	389
Nullam	379
venenatis	205
laoreet	265
ornare.	230
Aenean	94
arcu.	329
vulputate	58
euismod	358
metus	133
Mauris	211
ante.	219
egestas.	159
pretium	248
lorem	294
fermentum	108
placerat.	122
magna.	143
scelerisque	121
fringilla	306
risus.	252
luctus	90
Cras	350
mollis	379
aliquet	379
tellus.	141
Nunc	365
accumsan	151
est	20
in	5
Donec	320
Sed	141
mi.	160
nibh	243
eu	30
dui.	102
In	11
tellus	371
lorem	42
arcu.	132
Cras	290
nonummy	340
a,	23
mauris.	384
a	357
dolor.	212
Mauris	210
Nunc	57
ultrices	115
\.


--
-- Data for Name: log; Type: TABLE DATA; Schema: public; Owner: kirill
--

COPY public.log ("time", description, purchase_id) FROM stdin;
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
\.


--
-- Data for Name: purchased_book; Type: TABLE DATA; Schema: public; Owner: kirill
--

COPY public.purchased_book (book_id, purchaise_id, quanity) FROM stdin;
\.


--
-- Data for Name: reviews; Type: TABLE DATA; Schema: public; Owner: kirill
--

COPY public.reviews (review_id, comic_id, customer_id, rating, overall, pros, cons, date) FROM stdin;
5	1	1	5	\N	\N	\N	2020-06-10 17:54:57.513562
9	1	11	10	nice	nice	not nice	2020-06-10 17:55:56.785995
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
-- Name: publishers_id_seq; Type: SEQUENCE SET; Schema: public; Owner: kirill
--

SELECT pg_catalog.setval('public.publishers_id_seq', 1, false);


--
-- Name: purchase_id_seq; Type: SEQUENCE SET; Schema: public; Owner: kirill
--

SELECT pg_catalog.setval('public.purchase_id_seq', 7, true);


--
-- Name: reviews_id_seq; Type: SEQUENCE SET; Schema: public; Owner: kirill
--

SELECT pg_catalog.setval('public.reviews_id_seq', 9, true);


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
    ADD CONSTRAINT purchased_book_pkey PRIMARY KEY (book_id, purchaise_id);


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

CREATE INDEX fki_purchase ON public.purchased_book USING btree (purchaise_id);


--
-- Name: fki_series_id; Type: INDEX; Schema: public; Owner: kirill
--

CREATE INDEX fki_series_id ON public.comic_book USING btree (series_id);


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
-- Name: genre comic; Type: FK CONSTRAINT; Schema: public; Owner: kirill
--

ALTER TABLE ONLY public.genre
    ADD CONSTRAINT comic FOREIGN KEY (comic_id) REFERENCES public.comic_book(comic_id) NOT VALID;


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
-- Name: comic_book publishers; Type: FK CONSTRAINT; Schema: public; Owner: kirill
--

ALTER TABLE ONLY public.comic_book
    ADD CONSTRAINT publishers FOREIGN KEY (publisher_id) REFERENCES public.publishers(publisher_id) ON UPDATE CASCADE NOT VALID;


--
-- Name: purchased_book purchase; Type: FK CONSTRAINT; Schema: public; Owner: kirill
--

ALTER TABLE ONLY public.purchased_book
    ADD CONSTRAINT purchase FOREIGN KEY (purchaise_id) REFERENCES public.purchase(purchase_id) NOT VALID;


--
-- Name: comic_book series_id; Type: FK CONSTRAINT; Schema: public; Owner: kirill
--

ALTER TABLE ONLY public.comic_book
    ADD CONSTRAINT series_id FOREIGN KEY (series_id) REFERENCES public.series(series_id) ON UPDATE CASCADE ON DELETE CASCADE NOT VALID;


--
-- PostgreSQL database dump complete
--

