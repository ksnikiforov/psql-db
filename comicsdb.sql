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
    CONSTRAINT comic_book_rating_check CHECK (((0 <= rating) AND (rating <= 5)))
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
    CONSTRAINT reviews_rating_check CHECK (((0 <= rating) AND (rating <= 5)))
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

SELECT pg_catalog.setval('public.reviews_id_seq', 4, true);


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

