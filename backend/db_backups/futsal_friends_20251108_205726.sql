--
-- PostgreSQL database dump
--

\restrict 9HeaLtKlxjKsgRQ4h8nfQHl4lp6AeeKqGBZmewTtW8p09PnPpfYTnpTKUWmSLws

-- Dumped from database version 14.19
-- Dumped by pg_dump version 14.19

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

DROP DATABASE IF EXISTS futsal_friends_db;
--
-- Name: futsal_friends_db; Type: DATABASE; Schema: -; Owner: futsal_user
--

CREATE DATABASE futsal_friends_db WITH TEMPLATE = template0 ENCODING = 'UTF8' LOCALE = 'en_US.utf8';


ALTER DATABASE futsal_friends_db OWNER TO futsal_user;

\unrestrict 9HeaLtKlxjKsgRQ4h8nfQHl4lp6AeeKqGBZmewTtW8p09PnPpfYTnpTKUWmSLws
\connect futsal_friends_db
\restrict 9HeaLtKlxjKsgRQ4h8nfQHl4lp6AeeKqGBZmewTtW8p09PnPpfYTnpTKUWmSLws

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
-- Name: match_result_outcome; Type: TYPE; Schema: public; Owner: futsal_user
--

CREATE TYPE public.match_result_outcome AS ENUM (
    'WIN',
    'DRAW',
    'LOSS',
    'DID_NOT_ATTEND'
);


ALTER TYPE public.match_result_outcome OWNER TO futsal_user;

--
-- Name: match_status; Type: TYPE; Schema: public; Owner: futsal_user
--

CREATE TYPE public.match_status AS ENUM (
    'SCHEDULED',
    'CONFIRMED',
    'COMPLETED',
    'CANCELLED'
);


ALTER TYPE public.match_status OWNER TO futsal_user;

--
-- Name: playertype; Type: TYPE; Schema: public; Owner: futsal_user
--

CREATE TYPE public.playertype AS ENUM (
    'regular',
    'invited'
);


ALTER TYPE public.playertype OWNER TO futsal_user;

--
-- Name: result_type; Type: TYPE; Schema: public; Owner: futsal_user
--

CREATE TYPE public.result_type AS ENUM (
    'WIN',
    'DRAW'
);


ALTER TYPE public.result_type OWNER TO futsal_user;

--
-- Name: rsvp_status; Type: TYPE; Schema: public; Owner: futsal_user
--

CREATE TYPE public.rsvp_status AS ENUM (
    'PENDING',
    'CONFIRMED',
    'DECLINED'
);


ALTER TYPE public.rsvp_status OWNER TO futsal_user;

--
-- Name: team_name; Type: TYPE; Schema: public; Owner: futsal_user
--

CREATE TYPE public.team_name AS ENUM (
    'TEAM_A',
    'TEAM_B'
);


ALTER TYPE public.team_name OWNER TO futsal_user;

SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: alembic_version; Type: TABLE; Schema: public; Owner: futsal_user
--

CREATE TABLE public.alembic_version (
    version_num character varying(32) NOT NULL
);


ALTER TABLE public.alembic_version OWNER TO futsal_user;

--
-- Name: match_attendances; Type: TABLE; Schema: public; Owner: futsal_user
--

CREATE TABLE public.match_attendances (
    id uuid NOT NULL,
    match_id uuid NOT NULL,
    player_id uuid NOT NULL,
    rsvp_status public.rsvp_status NOT NULL,
    rsvp_at timestamp without time zone,
    attended boolean NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


ALTER TABLE public.match_attendances OWNER TO futsal_user;

--
-- Name: match_results; Type: TABLE; Schema: public; Owner: futsal_user
--

CREATE TABLE public.match_results (
    id uuid NOT NULL,
    match_id uuid NOT NULL,
    team_a_id uuid NOT NULL,
    team_b_id uuid NOT NULL,
    team_a_score integer NOT NULL,
    team_b_score integer NOT NULL,
    winning_team_id uuid,
    result_type public.result_type NOT NULL,
    recorded_at timestamp without time zone NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


ALTER TABLE public.match_results OWNER TO futsal_user;

--
-- Name: matches; Type: TABLE; Schema: public; Owner: futsal_user
--

CREATE TABLE public.matches (
    id uuid NOT NULL,
    season_id uuid NOT NULL,
    match_date timestamp without time zone NOT NULL,
    status public.match_status NOT NULL,
    rsvp_deadline timestamp without time zone,
    location character varying(200),
    notes text,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    match_week integer NOT NULL,
    CONSTRAINT ck_match_week_positive CHECK ((match_week > 0))
);


ALTER TABLE public.matches OWNER TO futsal_user;

--
-- Name: player_match_ratings; Type: TABLE; Schema: public; Owner: futsal_user
--

CREATE TABLE public.player_match_ratings (
    id uuid NOT NULL,
    player_id uuid NOT NULL,
    match_id uuid NOT NULL,
    season_id uuid NOT NULL,
    match_number integer NOT NULL,
    match_date timestamp without time zone NOT NULL,
    attended_match boolean NOT NULL,
    attended_third_time boolean NOT NULL,
    match_result public.match_result_outcome NOT NULL,
    team_average_rating double precision,
    opponent_average_rating double precision,
    rating_before double precision NOT NULL,
    rating_after double precision NOT NULL,
    rating_change double precision NOT NULL,
    elo_k_factor double precision NOT NULL,
    attendance_bonus double precision NOT NULL,
    third_time_bonus double precision NOT NULL,
    non_attendance_penalty double precision NOT NULL,
    calculated_at timestamp without time zone NOT NULL,
    created_at timestamp without time zone NOT NULL,
    CONSTRAINT ck_match_number_positive CHECK ((match_number > 0)),
    CONSTRAINT ck_rating_after_range CHECK (((rating_after >= (1.0)::double precision) AND (rating_after <= (5.0)::double precision))),
    CONSTRAINT ck_rating_before_range CHECK (((rating_before >= (1.0)::double precision) AND (rating_before <= (5.0)::double precision)))
);


ALTER TABLE public.player_match_ratings OWNER TO futsal_user;

--
-- Name: player_season_ratings; Type: TABLE; Schema: public; Owner: futsal_user
--

CREATE TABLE public.player_season_ratings (
    id uuid NOT NULL,
    player_id uuid NOT NULL,
    season_id uuid NOT NULL,
    current_rating double precision NOT NULL,
    matches_completed integer NOT NULL,
    matches_attended integer NOT NULL,
    rating_locked boolean NOT NULL,
    last_calculated_at timestamp without time zone,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    CONSTRAINT ck_attendance_count CHECK ((matches_attended <= matches_completed)),
    CONSTRAINT ck_rating_range CHECK (((current_rating >= (1.0)::double precision) AND (current_rating <= (5.0)::double precision)))
);


ALTER TABLE public.player_season_ratings OWNER TO futsal_user;

--
-- Name: players; Type: TABLE; Schema: public; Owner: futsal_user
--

CREATE TABLE public.players (
    id uuid NOT NULL,
    name character varying(100) NOT NULL,
    is_active boolean NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    player_type public.playertype DEFAULT 'regular'::public.playertype NOT NULL
);


ALTER TABLE public.players OWNER TO futsal_user;

--
-- Name: seasons; Type: TABLE; Schema: public; Owner: futsal_user
--

CREATE TABLE public.seasons (
    id uuid NOT NULL,
    name character varying(100) NOT NULL,
    year integer NOT NULL,
    start_date date NOT NULL,
    end_date date,
    is_active boolean NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


ALTER TABLE public.seasons OWNER TO futsal_user;

--
-- Name: team_players; Type: TABLE; Schema: public; Owner: futsal_user
--

CREATE TABLE public.team_players (
    id uuid NOT NULL,
    team_id uuid NOT NULL,
    player_id uuid NOT NULL,
    "position" character varying(50),
    created_at timestamp without time zone NOT NULL
);


ALTER TABLE public.team_players OWNER TO futsal_user;

--
-- Name: teams; Type: TABLE; Schema: public; Owner: futsal_user
--

CREATE TABLE public.teams (
    id uuid NOT NULL,
    match_id uuid NOT NULL,
    name public.team_name NOT NULL,
    average_skill_rating double precision,
    created_at timestamp without time zone NOT NULL
);


ALTER TABLE public.teams OWNER TO futsal_user;

--
-- Name: third_time_attendances; Type: TABLE; Schema: public; Owner: futsal_user
--

CREATE TABLE public.third_time_attendances (
    id uuid NOT NULL,
    match_id uuid NOT NULL,
    player_id uuid NOT NULL,
    attended boolean NOT NULL,
    created_at timestamp without time zone NOT NULL
);


ALTER TABLE public.third_time_attendances OWNER TO futsal_user;

--
-- Data for Name: alembic_version; Type: TABLE DATA; Schema: public; Owner: futsal_user
--

COPY public.alembic_version (version_num) FROM stdin;
2270fe0f8d73
\.


--
-- Data for Name: match_attendances; Type: TABLE DATA; Schema: public; Owner: futsal_user
--

COPY public.match_attendances (id, match_id, player_id, rsvp_status, rsvp_at, attended, created_at, updated_at) FROM stdin;
26cf7178-90ff-4e5d-8c37-ca9c84bf0a98	7712a21a-7fc7-4f07-bfbd-fea814175b7c	839f0f95-bd46-4565-b2bc-9c76f0eec536	CONFIRMED	2025-03-09 00:00:00	t	2025-11-01 21:23:17.959575	2025-11-01 21:23:17.959581
3e5dad3b-ae7a-4c16-a270-07644b1c7d93	7712a21a-7fc7-4f07-bfbd-fea814175b7c	638378af-a3a0-4010-96bd-a4fcdf49e841	CONFIRMED	2025-03-09 00:00:00	t	2025-11-01 21:23:17.969971	2025-11-01 21:23:17.969973
79145cde-fac2-4bd5-bd80-cf222b9ab0b1	7712a21a-7fc7-4f07-bfbd-fea814175b7c	e22adc74-dbad-4a52-8822-d41df3c3a7d0	CONFIRMED	2025-03-09 00:00:00	t	2025-11-01 21:23:17.972068	2025-11-01 21:23:17.972071
07d2ef0c-fda9-4ce7-ac2e-0464ceb25dbd	7712a21a-7fc7-4f07-bfbd-fea814175b7c	c98f7bfd-cbba-443e-941b-962dd6d40fed	DECLINED	\N	f	2025-11-01 21:23:17.974003	2025-11-01 21:23:17.974004
19497156-8f5d-4b04-9fee-fa133991fbc6	7712a21a-7fc7-4f07-bfbd-fea814175b7c	d83f7d2d-2b57-40bd-80ad-23e4eb03b8a9	DECLINED	\N	f	2025-11-01 21:23:17.975895	2025-11-01 21:23:17.975896
9b82556f-55f4-46be-843f-dbf03a99aeec	7712a21a-7fc7-4f07-bfbd-fea814175b7c	2f2fd4c0-7f94-45f7-8b48-0cbecd8e018c	CONFIRMED	2025-03-09 00:00:00	t	2025-11-01 21:23:17.977709	2025-11-01 21:23:17.97771
652d73cc-60b1-44ac-a6a6-5abdc415b84f	7712a21a-7fc7-4f07-bfbd-fea814175b7c	b5b71c9b-a553-4db3-8a95-f0e9fc460a17	DECLINED	\N	f	2025-11-01 21:23:17.979586	2025-11-01 21:23:17.979587
6a826dc6-8eb0-40a4-80e1-782c4756a7b4	7712a21a-7fc7-4f07-bfbd-fea814175b7c	f18488fd-d485-4bcf-8f0f-0c2f3cfdb025	DECLINED	\N	f	2025-11-01 21:23:17.981588	2025-11-01 21:23:17.981589
01c96d46-117d-4e09-8142-807770dd36ca	7712a21a-7fc7-4f07-bfbd-fea814175b7c	0ae22ab5-d3a0-4b3f-9b8d-ece4224f340a	DECLINED	\N	f	2025-11-01 21:23:17.983337	2025-11-01 21:23:17.983338
55c62b97-80c7-46b6-af2e-53ee4feacbe8	7712a21a-7fc7-4f07-bfbd-fea814175b7c	958f1430-f51c-43a0-871d-e10324151dbc	CONFIRMED	2025-03-09 00:00:00	t	2025-11-01 21:23:17.985172	2025-11-01 21:23:17.985173
1172c095-0ee0-41f4-b78b-19cc641ce301	7712a21a-7fc7-4f07-bfbd-fea814175b7c	de7929fd-181e-4cbd-b564-b9fd597779c9	DECLINED	\N	f	2025-11-01 21:23:17.986975	2025-11-01 21:23:17.986976
39ab1ec7-2e3f-4a32-adb3-31d34406b9c5	7712a21a-7fc7-4f07-bfbd-fea814175b7c	b982f348-6db4-438a-b106-c74d69e87e2d	CONFIRMED	2025-03-09 00:00:00	t	2025-11-01 21:23:17.98864	2025-11-01 21:23:17.988641
6ec079fc-4cad-459d-821a-138bba89170d	7712a21a-7fc7-4f07-bfbd-fea814175b7c	c976e410-ded4-4cc0-ab2f-53ee8abe2a4d	CONFIRMED	2025-03-09 00:00:00	t	2025-11-01 21:23:17.990401	2025-11-01 21:23:17.990402
deccefd3-cd1e-48f4-83b9-af99cbf7fa57	7712a21a-7fc7-4f07-bfbd-fea814175b7c	fb1a9540-a35f-4789-a917-888bc71c4e5b	CONFIRMED	2025-03-09 00:00:00	t	2025-11-01 21:23:17.992412	2025-11-01 21:23:17.992415
48ba4377-1beb-4df7-bf19-4d23a202c141	7712a21a-7fc7-4f07-bfbd-fea814175b7c	d3373e62-c862-48ad-9db6-4cf353621f7e	CONFIRMED	2025-03-09 00:00:00	t	2025-11-01 21:23:17.994343	2025-11-01 21:23:17.994345
a04ce271-d55b-4fa0-b176-ea1e977bb3b3	e940f144-fd5a-4cf4-b348-decd293ccd1e	839f0f95-bd46-4565-b2bc-9c76f0eec536	DECLINED	\N	f	2025-11-01 21:27:14.6013	2025-11-01 21:27:14.601302
a2780727-c13d-4d85-a5eb-45da35d262ea	e940f144-fd5a-4cf4-b348-decd293ccd1e	638378af-a3a0-4010-96bd-a4fcdf49e841	CONFIRMED	2025-09-10 00:00:00	t	2025-11-01 21:27:14.608721	2025-11-01 21:27:14.608722
181f5476-600d-4158-8b35-af6b77e200ee	e940f144-fd5a-4cf4-b348-decd293ccd1e	e22adc74-dbad-4a52-8822-d41df3c3a7d0	CONFIRMED	2025-09-10 00:00:00	t	2025-11-01 21:27:14.609861	2025-11-01 21:27:14.609861
abea1d74-c31f-46b8-a1e9-c51a88c86fc2	e940f144-fd5a-4cf4-b348-decd293ccd1e	c98f7bfd-cbba-443e-941b-962dd6d40fed	CONFIRMED	2025-09-10 00:00:00	t	2025-11-01 21:27:14.610746	2025-11-01 21:27:14.610746
1203b3a0-b5d4-4586-ad2a-77bc8f341c13	e940f144-fd5a-4cf4-b348-decd293ccd1e	d83f7d2d-2b57-40bd-80ad-23e4eb03b8a9	DECLINED	\N	f	2025-11-01 21:27:14.611511	2025-11-01 21:27:14.611511
8e986324-db09-4338-b5f3-b71bb758bc8a	e940f144-fd5a-4cf4-b348-decd293ccd1e	2f2fd4c0-7f94-45f7-8b48-0cbecd8e018c	DECLINED	\N	f	2025-11-01 21:27:14.61238	2025-11-01 21:27:14.612381
eaf6b196-8045-4ca8-9a04-833ac195ea30	e940f144-fd5a-4cf4-b348-decd293ccd1e	b5b71c9b-a553-4db3-8a95-f0e9fc460a17	DECLINED	\N	f	2025-11-01 21:27:14.613199	2025-11-01 21:27:14.6132
0c5d64e6-3f9e-4119-b956-08c153dfb1d1	e940f144-fd5a-4cf4-b348-decd293ccd1e	f18488fd-d485-4bcf-8f0f-0c2f3cfdb025	DECLINED	\N	f	2025-11-01 21:27:14.613929	2025-11-01 21:27:14.613929
a6144c72-69bd-4830-b295-8ba658e20976	e940f144-fd5a-4cf4-b348-decd293ccd1e	0ae22ab5-d3a0-4b3f-9b8d-ece4224f340a	DECLINED	\N	f	2025-11-01 21:27:14.614716	2025-11-01 21:27:14.614717
3f1eaf0b-5ff7-46aa-9fbe-96d0f1575869	e940f144-fd5a-4cf4-b348-decd293ccd1e	958f1430-f51c-43a0-871d-e10324151dbc	DECLINED	\N	f	2025-11-01 21:27:14.615537	2025-11-01 21:27:14.615537
c05f23ae-9a8a-4d28-a36a-eb790028befe	e940f144-fd5a-4cf4-b348-decd293ccd1e	de7929fd-181e-4cbd-b564-b9fd597779c9	CONFIRMED	2025-09-10 00:00:00	t	2025-11-01 21:27:14.616697	2025-11-01 21:27:14.616697
5d7b8921-c341-420a-b677-948f7fb260a3	e940f144-fd5a-4cf4-b348-decd293ccd1e	b982f348-6db4-438a-b106-c74d69e87e2d	CONFIRMED	2025-09-10 00:00:00	t	2025-11-01 21:27:14.617801	2025-11-01 21:27:14.617802
7a1e7023-8689-4cd1-bbc7-0673d9a335b9	e940f144-fd5a-4cf4-b348-decd293ccd1e	c976e410-ded4-4cc0-ab2f-53ee8abe2a4d	CONFIRMED	2025-09-10 00:00:00	t	2025-11-01 21:27:14.619605	2025-11-01 21:27:14.619606
b8409234-7c19-4d3f-9e27-c9004723b448	e940f144-fd5a-4cf4-b348-decd293ccd1e	fb1a9540-a35f-4789-a917-888bc71c4e5b	CONFIRMED	2025-09-10 00:00:00	t	2025-11-01 21:27:14.621002	2025-11-01 21:27:14.621002
c7f2b7f7-e5bf-4f83-9994-91a41c036c86	e940f144-fd5a-4cf4-b348-decd293ccd1e	d3373e62-c862-48ad-9db6-4cf353621f7e	CONFIRMED	2025-09-10 00:00:00	t	2025-11-01 21:27:14.622258	2025-11-01 21:27:14.622259
14d40e09-a490-482b-ae2f-33223aa7f480	3b9359ce-9703-40ba-b24c-4890af8e64e7	839f0f95-bd46-4565-b2bc-9c76f0eec536	DECLINED	\N	f	2025-11-01 21:29:44.907723	2025-11-01 21:29:44.907728
c5893b14-9d1d-4947-be73-df9458a54527	3b9359ce-9703-40ba-b24c-4890af8e64e7	638378af-a3a0-4010-96bd-a4fcdf49e841	DECLINED	\N	f	2025-11-01 21:29:44.922793	2025-11-01 21:29:44.922797
fb552312-b04f-4ac4-8b89-42f293bd0712	3b9359ce-9703-40ba-b24c-4890af8e64e7	e22adc74-dbad-4a52-8822-d41df3c3a7d0	CONFIRMED	2025-09-17 00:00:00	t	2025-11-01 21:29:44.925708	2025-11-01 21:29:44.92571
a432d686-fb2c-4166-87aa-befe0de3e461	3b9359ce-9703-40ba-b24c-4890af8e64e7	c98f7bfd-cbba-443e-941b-962dd6d40fed	CONFIRMED	2025-09-17 00:00:00	t	2025-11-01 21:29:44.928214	2025-11-01 21:29:44.928216
62df55fd-9adc-465c-9f85-63d16a22f3fb	3b9359ce-9703-40ba-b24c-4890af8e64e7	d83f7d2d-2b57-40bd-80ad-23e4eb03b8a9	DECLINED	\N	f	2025-11-01 21:29:44.930305	2025-11-01 21:29:44.930305
2eea065b-b0d5-444b-a8b3-140cd9114b39	3b9359ce-9703-40ba-b24c-4890af8e64e7	2f2fd4c0-7f94-45f7-8b48-0cbecd8e018c	CONFIRMED	2025-09-17 00:00:00	t	2025-11-01 21:29:44.932205	2025-11-01 21:29:44.932206
a3629071-d139-4edb-9f9f-99f49b668381	3b9359ce-9703-40ba-b24c-4890af8e64e7	b5b71c9b-a553-4db3-8a95-f0e9fc460a17	DECLINED	\N	f	2025-11-01 21:29:44.934965	2025-11-01 21:29:44.934967
854e6d4e-7546-405b-9323-3e9b4e37e878	3b9359ce-9703-40ba-b24c-4890af8e64e7	f18488fd-d485-4bcf-8f0f-0c2f3cfdb025	DECLINED	\N	f	2025-11-01 21:29:44.937619	2025-11-01 21:29:44.937623
e6651ead-b3cd-48e6-8607-6c78d74f7111	3b9359ce-9703-40ba-b24c-4890af8e64e7	0ae22ab5-d3a0-4b3f-9b8d-ece4224f340a	CONFIRMED	2025-09-17 00:00:00	t	2025-11-01 21:29:44.94102	2025-11-01 21:29:44.941024
528450e7-98b9-43da-acca-f0586fbe853a	3b9359ce-9703-40ba-b24c-4890af8e64e7	958f1430-f51c-43a0-871d-e10324151dbc	CONFIRMED	2025-09-17 00:00:00	t	2025-11-01 21:29:44.943775	2025-11-01 21:29:44.943779
4897afc9-edca-48e7-b0f9-f46870a47d8b	3b9359ce-9703-40ba-b24c-4890af8e64e7	de7929fd-181e-4cbd-b564-b9fd597779c9	CONFIRMED	2025-09-17 00:00:00	t	2025-11-01 21:29:44.94902	2025-11-01 21:29:44.949025
fda7abb0-fe5c-4f64-83f5-71545d7876c7	3b9359ce-9703-40ba-b24c-4890af8e64e7	b982f348-6db4-438a-b106-c74d69e87e2d	DECLINED	\N	f	2025-11-01 21:29:44.953338	2025-11-01 21:29:44.953348
fca8bc00-32e3-474c-834e-c394cd00efbf	3b9359ce-9703-40ba-b24c-4890af8e64e7	c976e410-ded4-4cc0-ab2f-53ee8abe2a4d	CONFIRMED	2025-09-17 00:00:00	t	2025-11-01 21:29:44.958827	2025-11-01 21:29:44.958832
5339911b-bda9-4120-95ca-4fae7bbcb445	3b9359ce-9703-40ba-b24c-4890af8e64e7	fb1a9540-a35f-4789-a917-888bc71c4e5b	CONFIRMED	2025-09-17 00:00:00	t	2025-11-01 21:29:44.962186	2025-11-01 21:29:44.962189
fa465df0-44fb-40a8-aca1-d1d809197ac4	3b9359ce-9703-40ba-b24c-4890af8e64e7	d3373e62-c862-48ad-9db6-4cf353621f7e	CONFIRMED	2025-09-17 00:00:00	t	2025-11-01 21:29:44.965265	2025-11-01 21:29:44.965267
21fbe4c3-2ce5-44ad-9e39-cf928e36c827	8c910fd4-9582-4c74-863e-40f6bc168bc0	839f0f95-bd46-4565-b2bc-9c76f0eec536	DECLINED	\N	f	2025-11-01 21:32:34.927528	2025-11-01 21:32:34.927531
d042aea2-cc54-470f-b4f0-ab67214a4a19	8c910fd4-9582-4c74-863e-40f6bc168bc0	638378af-a3a0-4010-96bd-a4fcdf49e841	DECLINED	\N	f	2025-11-01 21:32:34.94023	2025-11-01 21:32:34.940232
aa984c86-af53-4637-931d-325a5eeba7d7	8c910fd4-9582-4c74-863e-40f6bc168bc0	e22adc74-dbad-4a52-8822-d41df3c3a7d0	CONFIRMED	2025-09-24 00:00:00	t	2025-11-01 21:32:34.9417	2025-11-01 21:32:34.941701
fca2d221-3fa4-4372-926b-21bf443092d8	8c910fd4-9582-4c74-863e-40f6bc168bc0	c98f7bfd-cbba-443e-941b-962dd6d40fed	CONFIRMED	2025-09-24 00:00:00	t	2025-11-01 21:32:34.943221	2025-11-01 21:32:34.943222
af584bc3-229a-4224-8cf6-d3b57007a1ef	8c910fd4-9582-4c74-863e-40f6bc168bc0	d83f7d2d-2b57-40bd-80ad-23e4eb03b8a9	DECLINED	\N	f	2025-11-01 21:32:34.944594	2025-11-01 21:32:34.944595
8e2ec6e3-6fa7-4e63-8481-2bb03363b11a	8c910fd4-9582-4c74-863e-40f6bc168bc0	2f2fd4c0-7f94-45f7-8b48-0cbecd8e018c	CONFIRMED	2025-09-24 00:00:00	t	2025-11-01 21:32:34.946063	2025-11-01 21:32:34.946064
d8159056-5798-45fb-a4b2-92b766b91d46	8c910fd4-9582-4c74-863e-40f6bc168bc0	b5b71c9b-a553-4db3-8a95-f0e9fc460a17	DECLINED	\N	f	2025-11-01 21:32:34.947629	2025-11-01 21:32:34.94763
697b3b21-1b04-4290-a06e-333a84954601	8c910fd4-9582-4c74-863e-40f6bc168bc0	f18488fd-d485-4bcf-8f0f-0c2f3cfdb025	CONFIRMED	2025-09-24 00:00:00	t	2025-11-01 21:32:34.948823	2025-11-01 21:32:34.948824
02dbceb2-e554-4fea-88dc-e36f8baf435b	8c910fd4-9582-4c74-863e-40f6bc168bc0	0ae22ab5-d3a0-4b3f-9b8d-ece4224f340a	CONFIRMED	2025-09-24 00:00:00	t	2025-11-01 21:32:34.950128	2025-11-01 21:32:34.950128
38916614-773f-4947-bda5-b83e5b526eb7	8c910fd4-9582-4c74-863e-40f6bc168bc0	958f1430-f51c-43a0-871d-e10324151dbc	CONFIRMED	2025-09-24 00:00:00	t	2025-11-01 21:32:34.951675	2025-11-01 21:32:34.951676
1bca5795-a4a9-470f-8067-70d63159248d	8c910fd4-9582-4c74-863e-40f6bc168bc0	de7929fd-181e-4cbd-b564-b9fd597779c9	CONFIRMED	2025-09-24 00:00:00	t	2025-11-01 21:32:34.955778	2025-11-01 21:32:34.955779
9a665dab-9fb1-414c-bfc2-57f6aee40630	8c910fd4-9582-4c74-863e-40f6bc168bc0	b982f348-6db4-438a-b106-c74d69e87e2d	DECLINED	\N	f	2025-11-01 21:32:34.957478	2025-11-01 21:32:34.957479
9217eaa6-3411-4efb-ad43-5f3d1434818b	8c910fd4-9582-4c74-863e-40f6bc168bc0	c976e410-ded4-4cc0-ab2f-53ee8abe2a4d	CONFIRMED	2025-09-24 00:00:00	t	2025-11-01 21:32:34.959083	2025-11-01 21:32:34.959084
3eed3049-b89b-4008-8545-54fd61615430	8c910fd4-9582-4c74-863e-40f6bc168bc0	fb1a9540-a35f-4789-a917-888bc71c4e5b	DECLINED	\N	f	2025-11-01 21:32:34.960527	2025-11-01 21:32:34.960528
0c5d2506-2275-46ff-a168-ec98e27b5634	8c910fd4-9582-4c74-863e-40f6bc168bc0	d3373e62-c862-48ad-9db6-4cf353621f7e	CONFIRMED	2025-09-24 00:00:00	t	2025-11-01 21:32:34.962063	2025-11-01 21:32:34.962064
21661f2d-c30d-45ac-ada7-0406ce436f76	2061fd5e-1567-4c8d-87af-a240deb4f826	839f0f95-bd46-4565-b2bc-9c76f0eec536	CONFIRMED	2025-10-01 00:00:00	t	2025-11-01 21:35:09.990707	2025-11-01 21:35:09.990715
c6b30097-c457-4012-9bf5-4cc45ae6fcba	2061fd5e-1567-4c8d-87af-a240deb4f826	638378af-a3a0-4010-96bd-a4fcdf49e841	CONFIRMED	2025-10-01 00:00:00	t	2025-11-01 21:35:10.004963	2025-11-01 21:35:10.004966
676a1d0e-00dd-472b-b6e7-6798b0ab66f9	2061fd5e-1567-4c8d-87af-a240deb4f826	e22adc74-dbad-4a52-8822-d41df3c3a7d0	CONFIRMED	2025-10-01 00:00:00	t	2025-11-01 21:35:10.007397	2025-11-01 21:35:10.007399
8f8f3f9d-6e9a-4676-ae00-6b45b1794da6	2061fd5e-1567-4c8d-87af-a240deb4f826	c98f7bfd-cbba-443e-941b-962dd6d40fed	CONFIRMED	2025-10-01 00:00:00	t	2025-11-01 21:35:10.009458	2025-11-01 21:35:10.009459
e5661435-f6d5-4c03-b1bd-fb6727ac986d	2061fd5e-1567-4c8d-87af-a240deb4f826	d83f7d2d-2b57-40bd-80ad-23e4eb03b8a9	CONFIRMED	2025-10-01 00:00:00	t	2025-11-01 21:35:10.011418	2025-11-01 21:35:10.011418
4de3d768-b666-4d74-befa-a0ca3ff0a61e	2061fd5e-1567-4c8d-87af-a240deb4f826	2f2fd4c0-7f94-45f7-8b48-0cbecd8e018c	CONFIRMED	2025-10-01 00:00:00	t	2025-11-01 21:35:10.013435	2025-11-01 21:35:10.013436
a9557191-796b-4388-bb6f-fa50cfc018fa	2061fd5e-1567-4c8d-87af-a240deb4f826	b5b71c9b-a553-4db3-8a95-f0e9fc460a17	DECLINED	\N	f	2025-11-01 21:35:10.01542	2025-11-01 21:35:10.015421
6c3a1a4b-70fe-458d-83a1-6ea244c6407e	2061fd5e-1567-4c8d-87af-a240deb4f826	f18488fd-d485-4bcf-8f0f-0c2f3cfdb025	DECLINED	\N	f	2025-11-01 21:35:10.017674	2025-11-01 21:35:10.017678
31a46614-618a-43c7-8809-8415d2ac7b26	2061fd5e-1567-4c8d-87af-a240deb4f826	0ae22ab5-d3a0-4b3f-9b8d-ece4224f340a	DECLINED	\N	f	2025-11-01 21:35:10.019932	2025-11-01 21:35:10.019935
387261f1-c4e2-4f94-82b2-1c3831d36288	2061fd5e-1567-4c8d-87af-a240deb4f826	958f1430-f51c-43a0-871d-e10324151dbc	DECLINED	\N	f	2025-11-01 21:35:10.023956	2025-11-01 21:35:10.023961
0b4cc5aa-7601-4f14-94d8-5b96ed96b201	2061fd5e-1567-4c8d-87af-a240deb4f826	de7929fd-181e-4cbd-b564-b9fd597779c9	CONFIRMED	2025-10-01 00:00:00	t	2025-11-01 21:35:10.026688	2025-11-01 21:35:10.02669
d727d165-2970-4599-ab84-cdc719c71381	2061fd5e-1567-4c8d-87af-a240deb4f826	b982f348-6db4-438a-b106-c74d69e87e2d	DECLINED	\N	f	2025-11-01 21:35:10.028728	2025-11-01 21:35:10.02873
93eee515-dcf8-4043-a6f3-6fca211b81d4	2061fd5e-1567-4c8d-87af-a240deb4f826	c976e410-ded4-4cc0-ab2f-53ee8abe2a4d	CONFIRMED	2025-10-01 00:00:00	t	2025-11-01 21:35:10.034098	2025-11-01 21:35:10.034103
f484bceb-5042-4f33-a9d2-67c5dd94daaf	2061fd5e-1567-4c8d-87af-a240deb4f826	fb1a9540-a35f-4789-a917-888bc71c4e5b	CONFIRMED	2025-10-01 00:00:00	t	2025-11-01 21:35:10.0376	2025-11-01 21:35:10.037602
c39dddf7-4c67-4af2-ac11-9aa115f1c39d	2061fd5e-1567-4c8d-87af-a240deb4f826	d3373e62-c862-48ad-9db6-4cf353621f7e	DECLINED	\N	f	2025-11-01 21:35:10.040218	2025-11-01 21:35:10.04022
f008b9d8-3add-482c-9994-973983867a20	6514c434-5c57-4efc-b9f9-710aa9fe061e	839f0f95-bd46-4565-b2bc-9c76f0eec536	CONFIRMED	2025-10-08 00:00:00	t	2025-11-01 21:37:55.902549	2025-11-01 21:37:55.902552
a077cdaf-d0e1-466f-85f1-385cf5a74146	6514c434-5c57-4efc-b9f9-710aa9fe061e	638378af-a3a0-4010-96bd-a4fcdf49e841	CONFIRMED	2025-10-08 00:00:00	t	2025-11-01 21:37:55.91711	2025-11-01 21:37:55.917113
3462a671-9fd8-43df-bc6f-4cca937cafc3	6514c434-5c57-4efc-b9f9-710aa9fe061e	e22adc74-dbad-4a52-8822-d41df3c3a7d0	CONFIRMED	2025-10-08 00:00:00	t	2025-11-01 21:37:55.919317	2025-11-01 21:37:55.919319
21775da6-796a-4d7d-8845-d12f19be7839	6514c434-5c57-4efc-b9f9-710aa9fe061e	c98f7bfd-cbba-443e-941b-962dd6d40fed	CONFIRMED	2025-10-08 00:00:00	t	2025-11-01 21:37:55.921127	2025-11-01 21:37:55.921128
4c145cb9-db51-43f1-9373-a42409748ed5	6514c434-5c57-4efc-b9f9-710aa9fe061e	d83f7d2d-2b57-40bd-80ad-23e4eb03b8a9	CONFIRMED	2025-10-08 00:00:00	t	2025-11-01 21:37:55.922967	2025-11-01 21:37:55.922969
86319fb6-328b-410a-b03a-a1043ce70e35	6514c434-5c57-4efc-b9f9-710aa9fe061e	2f2fd4c0-7f94-45f7-8b48-0cbecd8e018c	CONFIRMED	2025-10-08 00:00:00	t	2025-11-01 21:37:55.924606	2025-11-01 21:37:55.924607
25b182d9-b82c-4dba-bc7a-7beda6b86e98	6514c434-5c57-4efc-b9f9-710aa9fe061e	b5b71c9b-a553-4db3-8a95-f0e9fc460a17	DECLINED	\N	f	2025-11-01 21:37:55.926226	2025-11-01 21:37:55.926227
78a7ff9e-e357-4ec0-a92b-dd727c20402e	6514c434-5c57-4efc-b9f9-710aa9fe061e	f18488fd-d485-4bcf-8f0f-0c2f3cfdb025	CONFIRMED	2025-10-08 00:00:00	t	2025-11-01 21:37:55.927811	2025-11-01 21:37:55.927812
0f9fc9c8-6845-4a40-a1b4-739ec91c2974	6514c434-5c57-4efc-b9f9-710aa9fe061e	0ae22ab5-d3a0-4b3f-9b8d-ece4224f340a	CONFIRMED	2025-10-08 00:00:00	t	2025-11-01 21:37:55.929701	2025-11-01 21:37:55.929702
f98e4ce1-dc3f-4964-acc6-b29950069d9f	6514c434-5c57-4efc-b9f9-710aa9fe061e	958f1430-f51c-43a0-871d-e10324151dbc	CONFIRMED	2025-10-08 00:00:00	t	2025-11-01 21:37:55.931468	2025-11-01 21:37:55.931469
50379587-a148-477f-a9df-a200e2336319	6514c434-5c57-4efc-b9f9-710aa9fe061e	de7929fd-181e-4cbd-b564-b9fd597779c9	CONFIRMED	2025-10-08 00:00:00	t	2025-11-01 21:37:55.933454	2025-11-01 21:37:55.933455
2e966220-914c-4ac5-a8f5-237a343eb950	6514c434-5c57-4efc-b9f9-710aa9fe061e	b982f348-6db4-438a-b106-c74d69e87e2d	CONFIRMED	2025-10-08 00:00:00	t	2025-11-01 21:37:55.93554	2025-11-01 21:37:55.935542
b4aaa73b-648b-49f4-92bf-4f78cbb75769	6514c434-5c57-4efc-b9f9-710aa9fe061e	c976e410-ded4-4cc0-ab2f-53ee8abe2a4d	CONFIRMED	2025-10-08 00:00:00	t	2025-11-01 21:37:55.938357	2025-11-01 21:37:55.93836
a10be853-5e57-4fce-8c47-d8359d16fe5d	6514c434-5c57-4efc-b9f9-710aa9fe061e	fb1a9540-a35f-4789-a917-888bc71c4e5b	CONFIRMED	2025-10-08 00:00:00	t	2025-11-01 21:37:55.940255	2025-11-01 21:37:55.940256
2e9b85a1-f5df-4b37-831c-b9cfd071545f	6514c434-5c57-4efc-b9f9-710aa9fe061e	d3373e62-c862-48ad-9db6-4cf353621f7e	DECLINED	\N	f	2025-11-01 21:37:55.941857	2025-11-01 21:37:55.941858
2eda2e91-3c3f-48bd-9946-80b5ca8a853e	de2e7706-10ec-42a7-b94f-e8ac29f7fbe1	839f0f95-bd46-4565-b2bc-9c76f0eec536	CONFIRMED	2025-10-15 00:00:00	t	2025-11-01 21:39:52.626751	2025-11-01 21:39:52.626755
815f28d4-0b8d-499d-965b-4f88b53f385d	de2e7706-10ec-42a7-b94f-e8ac29f7fbe1	638378af-a3a0-4010-96bd-a4fcdf49e841	CONFIRMED	2025-10-15 00:00:00	t	2025-11-01 21:39:52.63929	2025-11-01 21:39:52.639293
f324000f-5b9a-4537-9a3b-491e04e2fb0b	de2e7706-10ec-42a7-b94f-e8ac29f7fbe1	e22adc74-dbad-4a52-8822-d41df3c3a7d0	CONFIRMED	2025-10-15 00:00:00	t	2025-11-01 21:39:52.641503	2025-11-01 21:39:52.641504
13c483a1-87c9-4f94-b10f-b9681eccad4d	de2e7706-10ec-42a7-b94f-e8ac29f7fbe1	c98f7bfd-cbba-443e-941b-962dd6d40fed	CONFIRMED	2025-10-15 00:00:00	t	2025-11-01 21:39:52.643281	2025-11-01 21:39:52.643282
cf542c35-721b-4230-960b-9f389dfdd185	de2e7706-10ec-42a7-b94f-e8ac29f7fbe1	d83f7d2d-2b57-40bd-80ad-23e4eb03b8a9	CONFIRMED	2025-10-15 00:00:00	t	2025-11-01 21:39:52.645031	2025-11-01 21:39:52.645031
8de49b4a-0512-4d93-9c94-d0642fc3944b	de2e7706-10ec-42a7-b94f-e8ac29f7fbe1	2f2fd4c0-7f94-45f7-8b48-0cbecd8e018c	CONFIRMED	2025-10-15 00:00:00	t	2025-11-01 21:39:52.646827	2025-11-01 21:39:52.646828
eef006a7-58c2-4883-aaec-6f3b1897b6a1	de2e7706-10ec-42a7-b94f-e8ac29f7fbe1	b5b71c9b-a553-4db3-8a95-f0e9fc460a17	DECLINED	\N	f	2025-11-01 21:39:52.648601	2025-11-01 21:39:52.648601
966787ef-0dd3-43ce-810e-460287d6666d	de2e7706-10ec-42a7-b94f-e8ac29f7fbe1	f18488fd-d485-4bcf-8f0f-0c2f3cfdb025	DECLINED	\N	f	2025-11-01 21:39:52.650308	2025-11-01 21:39:52.65031
f74a6e13-5f57-4df5-b0d5-3818420767ab	de2e7706-10ec-42a7-b94f-e8ac29f7fbe1	0ae22ab5-d3a0-4b3f-9b8d-ece4224f340a	DECLINED	\N	f	2025-11-01 21:39:52.652191	2025-11-01 21:39:52.652193
0796cf79-b8e3-41b2-be3a-530d4cfe4d31	de2e7706-10ec-42a7-b94f-e8ac29f7fbe1	958f1430-f51c-43a0-871d-e10324151dbc	CONFIRMED	2025-10-15 00:00:00	t	2025-11-01 21:39:52.655258	2025-11-01 21:39:52.655263
411d545e-4d91-4b1b-bb9f-2b71d15054ce	de2e7706-10ec-42a7-b94f-e8ac29f7fbe1	de7929fd-181e-4cbd-b564-b9fd597779c9	CONFIRMED	2025-10-15 00:00:00	t	2025-11-01 21:39:52.657444	2025-11-01 21:39:52.657446
ff31d005-dbbb-4538-947b-bda06f9c3f16	de2e7706-10ec-42a7-b94f-e8ac29f7fbe1	b982f348-6db4-438a-b106-c74d69e87e2d	CONFIRMED	2025-10-15 00:00:00	t	2025-11-01 21:39:52.660528	2025-11-01 21:39:52.66053
045398e9-052f-44ba-97cf-a6f124fc179e	de2e7706-10ec-42a7-b94f-e8ac29f7fbe1	c976e410-ded4-4cc0-ab2f-53ee8abe2a4d	CONFIRMED	2025-10-15 00:00:00	t	2025-11-01 21:39:52.663016	2025-11-01 21:39:52.663018
58b9278d-8b82-45c1-b654-1a4c33ec2068	de2e7706-10ec-42a7-b94f-e8ac29f7fbe1	fb1a9540-a35f-4789-a917-888bc71c4e5b	CONFIRMED	2025-10-15 00:00:00	t	2025-11-01 21:39:52.665085	2025-11-01 21:39:52.665086
3d93ed5e-9dd1-49f8-ae62-f611c7b7ee64	de2e7706-10ec-42a7-b94f-e8ac29f7fbe1	d3373e62-c862-48ad-9db6-4cf353621f7e	DECLINED	\N	f	2025-11-01 21:39:52.667471	2025-11-01 21:39:52.667473
62cf69e8-c5a6-4afb-bf03-30bc01c92c46	0317af43-f94a-46e8-8f99-4b83d5227da2	839f0f95-bd46-4565-b2bc-9c76f0eec536	CONFIRMED	2025-10-22 00:00:00	t	2025-11-01 21:46:25.317779	2025-11-01 21:46:25.317781
a2637b4e-22f7-468e-bc90-80f302a7b2df	0317af43-f94a-46e8-8f99-4b83d5227da2	638378af-a3a0-4010-96bd-a4fcdf49e841	CONFIRMED	2025-10-22 00:00:00	t	2025-11-01 21:46:25.327646	2025-11-01 21:46:25.327647
57a9aa40-f702-4d89-b31b-dd909b7de8fd	0317af43-f94a-46e8-8f99-4b83d5227da2	e22adc74-dbad-4a52-8822-d41df3c3a7d0	CONFIRMED	2025-10-22 00:00:00	t	2025-11-01 21:46:25.329605	2025-11-01 21:46:25.329606
1fe46893-99d5-4c61-abe5-390078cd7fb2	0317af43-f94a-46e8-8f99-4b83d5227da2	c98f7bfd-cbba-443e-941b-962dd6d40fed	CONFIRMED	2025-10-22 00:00:00	t	2025-11-01 21:46:25.33162	2025-11-01 21:46:25.331621
a2098ac9-fd9c-4446-9085-d06b58279b0e	0317af43-f94a-46e8-8f99-4b83d5227da2	d83f7d2d-2b57-40bd-80ad-23e4eb03b8a9	CONFIRMED	2025-10-22 00:00:00	t	2025-11-01 21:46:25.333077	2025-11-01 21:46:25.333078
a1a89a90-97b0-47bf-9aff-ff4aeb87d992	0317af43-f94a-46e8-8f99-4b83d5227da2	2f2fd4c0-7f94-45f7-8b48-0cbecd8e018c	CONFIRMED	2025-10-22 00:00:00	t	2025-11-01 21:46:25.335193	2025-11-01 21:46:25.335193
a471cb16-683a-4a0b-b1c4-c0842ab28afe	0317af43-f94a-46e8-8f99-4b83d5227da2	b5b71c9b-a553-4db3-8a95-f0e9fc460a17	DECLINED	\N	f	2025-11-01 21:46:25.336519	2025-11-01 21:46:25.336519
5b958855-bac9-4758-9b22-fa60f0bbbcac	0317af43-f94a-46e8-8f99-4b83d5227da2	f18488fd-d485-4bcf-8f0f-0c2f3cfdb025	DECLINED	\N	f	2025-11-01 21:46:25.338295	2025-11-01 21:46:25.338297
fc40f978-a634-4c42-88b7-9b89cb9ffdf7	0317af43-f94a-46e8-8f99-4b83d5227da2	0ae22ab5-d3a0-4b3f-9b8d-ece4224f340a	DECLINED	\N	f	2025-11-01 21:46:25.340087	2025-11-01 21:46:25.340088
60e9df03-50ac-48da-9e7b-6487025e1bb6	0317af43-f94a-46e8-8f99-4b83d5227da2	958f1430-f51c-43a0-871d-e10324151dbc	DECLINED	\N	f	2025-11-01 21:46:25.341316	2025-11-01 21:46:25.341316
7907b751-3c83-4819-85f7-4b0e23d3a1da	0317af43-f94a-46e8-8f99-4b83d5227da2	de7929fd-181e-4cbd-b564-b9fd597779c9	CONFIRMED	2025-10-22 00:00:00	t	2025-11-01 21:46:25.342958	2025-11-01 21:46:25.342958
e06a8e2d-9eb6-4664-9cba-05eee7ed3407	0317af43-f94a-46e8-8f99-4b83d5227da2	b982f348-6db4-438a-b106-c74d69e87e2d	DECLINED	\N	f	2025-11-01 21:46:25.34453	2025-11-01 21:46:25.344531
641b494f-8b95-4ff7-9d28-897245964640	0317af43-f94a-46e8-8f99-4b83d5227da2	c976e410-ded4-4cc0-ab2f-53ee8abe2a4d	CONFIRMED	2025-10-22 00:00:00	t	2025-11-01 21:46:25.346024	2025-11-01 21:46:25.346025
5b0334ee-cfff-435d-bbb4-dcdc1e3e6fd1	0317af43-f94a-46e8-8f99-4b83d5227da2	fb1a9540-a35f-4789-a917-888bc71c4e5b	CONFIRMED	2025-10-22 00:00:00	t	2025-11-01 21:46:25.348242	2025-11-01 21:46:25.348243
1e293d1f-9368-4f3f-b6eb-1d6c190b93f2	0317af43-f94a-46e8-8f99-4b83d5227da2	d3373e62-c862-48ad-9db6-4cf353621f7e	DECLINED	\N	f	2025-11-01 21:46:25.349529	2025-11-01 21:46:25.34953
ebb75806-64ca-4942-abd9-1bc7609b27c9	4a640ed2-2210-4f67-9e30-a4ad2230b334	839f0f95-bd46-4565-b2bc-9c76f0eec536	DECLINED	\N	f	2025-11-01 21:48:31.301126	2025-11-01 21:48:31.30113
96bfaab2-1d50-4dec-8806-f04b0d7b57db	4a640ed2-2210-4f67-9e30-a4ad2230b334	638378af-a3a0-4010-96bd-a4fcdf49e841	CONFIRMED	2025-10-29 00:00:00	t	2025-11-01 21:48:31.315474	2025-11-01 21:48:31.315477
8a18be7d-ca69-4ef4-8ed6-47acb3c7e05e	4a640ed2-2210-4f67-9e30-a4ad2230b334	e22adc74-dbad-4a52-8822-d41df3c3a7d0	CONFIRMED	2025-10-29 00:00:00	t	2025-11-01 21:48:31.317758	2025-11-01 21:48:31.317759
57c48722-9f86-45ae-8d7b-5e7c7bf5513f	4a640ed2-2210-4f67-9e30-a4ad2230b334	c98f7bfd-cbba-443e-941b-962dd6d40fed	CONFIRMED	2025-10-29 00:00:00	t	2025-11-01 21:48:31.319996	2025-11-01 21:48:31.319997
76f8bb91-f3a8-4234-b87b-bd7656f4002c	4a640ed2-2210-4f67-9e30-a4ad2230b334	d83f7d2d-2b57-40bd-80ad-23e4eb03b8a9	CONFIRMED	2025-10-29 00:00:00	t	2025-11-01 21:48:31.322382	2025-11-01 21:48:31.322386
eeb341c5-5c55-43c9-9249-15eff637fd63	4a640ed2-2210-4f67-9e30-a4ad2230b334	2f2fd4c0-7f94-45f7-8b48-0cbecd8e018c	DECLINED	\N	f	2025-11-01 21:48:31.324487	2025-11-01 21:48:31.324488
ff316fef-f673-4286-8089-476b0076e363	4a640ed2-2210-4f67-9e30-a4ad2230b334	b5b71c9b-a553-4db3-8a95-f0e9fc460a17	DECLINED	\N	f	2025-11-01 21:48:31.326454	2025-11-01 21:48:31.326455
5a2e63ca-a55f-4f75-acd7-835a0d519f9e	4a640ed2-2210-4f67-9e30-a4ad2230b334	f18488fd-d485-4bcf-8f0f-0c2f3cfdb025	DECLINED	\N	f	2025-11-01 21:48:31.328459	2025-11-01 21:48:31.32846
3dcd09d5-f98a-45c9-99f0-4a4b84a2360f	4a640ed2-2210-4f67-9e30-a4ad2230b334	0ae22ab5-d3a0-4b3f-9b8d-ece4224f340a	DECLINED	\N	f	2025-11-01 21:48:31.330323	2025-11-01 21:48:31.330324
772fa382-b868-4bdc-a5a2-c90bec7ce50c	4a640ed2-2210-4f67-9e30-a4ad2230b334	958f1430-f51c-43a0-871d-e10324151dbc	DECLINED	\N	f	2025-11-01 21:48:31.332329	2025-11-01 21:48:31.332332
638290e0-375f-4985-9218-9a4ba79ef7ac	4a640ed2-2210-4f67-9e30-a4ad2230b334	de7929fd-181e-4cbd-b564-b9fd597779c9	CONFIRMED	2025-10-29 00:00:00	t	2025-11-01 21:48:31.334149	2025-11-01 21:48:31.33415
e71fb258-fafe-4060-9541-7ba930365f86	4a640ed2-2210-4f67-9e30-a4ad2230b334	b982f348-6db4-438a-b106-c74d69e87e2d	DECLINED	\N	f	2025-11-01 21:48:31.335791	2025-11-01 21:48:31.335793
442d151f-6cb8-44d7-8477-9188bebcdb09	4a640ed2-2210-4f67-9e30-a4ad2230b334	c976e410-ded4-4cc0-ab2f-53ee8abe2a4d	CONFIRMED	2025-10-29 00:00:00	t	2025-11-01 21:48:31.337421	2025-11-01 21:48:31.337423
0494705b-a501-4d50-b685-c6b73a0d1a86	4a640ed2-2210-4f67-9e30-a4ad2230b334	fb1a9540-a35f-4789-a917-888bc71c4e5b	CONFIRMED	2025-10-29 00:00:00	t	2025-11-01 21:48:31.339047	2025-11-01 21:48:31.339048
b830be7f-4eac-44a8-acaf-b43b6fd8fb0c	4a640ed2-2210-4f67-9e30-a4ad2230b334	d3373e62-c862-48ad-9db6-4cf353621f7e	CONFIRMED	2025-10-29 00:00:00	t	2025-11-01 21:48:31.34055	2025-11-01 21:48:31.340551
\.


--
-- Data for Name: match_results; Type: TABLE DATA; Schema: public; Owner: futsal_user
--

COPY public.match_results (id, match_id, team_a_id, team_b_id, team_a_score, team_b_score, winning_team_id, result_type, recorded_at, created_at, updated_at) FROM stdin;
4983a7e9-e82c-4e39-b85d-e07be8dee35d	7712a21a-7fc7-4f07-bfbd-fea814175b7c	eafa770a-8ac9-4025-b579-a0314bbd1a97	1ab3ea1a-c81d-4423-9f04-167981168861	6	6	\N	DRAW	2025-11-01 22:23:42.378374	2025-11-01 21:23:42.381437	2025-11-01 21:23:42.381442
7b93c424-76ac-4dce-89f0-57cf1b459920	e940f144-fd5a-4cf4-b348-decd293ccd1e	fe361d58-3493-4f98-91fa-90b519eb7e58	114221e1-0217-4a2c-8402-0f366919c8fd	5	8	114221e1-0217-4a2c-8402-0f366919c8fd	WIN	2025-11-01 22:27:43.301813	2025-11-01 21:27:43.305214	2025-11-01 21:27:43.305219
075bbb4d-3315-4c86-b9fc-b76edb440afe	3b9359ce-9703-40ba-b24c-4890af8e64e7	f5d89f13-97ba-4fdc-a181-c8a4b6f21e94	7573d1ca-36df-40f9-9261-7713ec286b72	6	7	7573d1ca-36df-40f9-9261-7713ec286b72	WIN	2025-11-01 22:30:00.269314	2025-11-01 21:30:00.272644	2025-11-01 21:30:00.27265
2c9e665b-40d2-4433-be3e-92a9920bc3b8	8c910fd4-9582-4c74-863e-40f6bc168bc0	3e90ffab-57e8-4e72-9a7a-f72cbfc9ba69	53d88b18-430f-4823-8387-7e537b296bde	8	5	3e90ffab-57e8-4e72-9a7a-f72cbfc9ba69	WIN	2025-11-01 22:32:49.321337	2025-11-01 21:32:49.324188	2025-11-01 21:32:49.324193
c4dac2ed-ac69-4be7-a482-4e97a4fea9ba	2061fd5e-1567-4c8d-87af-a240deb4f826	24f236f5-2fc7-48ec-b8c6-73d3cafc9b0d	91e02f49-5329-4554-9393-5c8d30c1640b	9	5	24f236f5-2fc7-48ec-b8c6-73d3cafc9b0d	WIN	2025-11-01 22:35:26.482607	2025-11-01 21:35:26.486276	2025-11-01 21:35:26.486281
08cd9891-5bfc-4d63-8c31-4c688512fdc3	6514c434-5c57-4efc-b9f9-710aa9fe061e	cd847220-bfca-4761-a321-2fbbafa38e06	3e989c42-47d9-4e74-99f2-bd61549619c4	10	7	cd847220-bfca-4761-a321-2fbbafa38e06	WIN	2025-11-01 22:38:08.47193	2025-11-01 21:38:08.475993	2025-11-01 21:38:08.475997
e0190872-0c67-4dc4-9d16-3ef87bca029c	de2e7706-10ec-42a7-b94f-e8ac29f7fbe1	b5321620-7ab9-4b40-a174-e3f3bc5e10e2	9fded2b1-6747-40e5-9ef6-ac9f472277a4	10	10	\N	DRAW	2025-11-01 22:40:07.541335	2025-11-01 21:40:07.545021	2025-11-01 21:40:07.545026
b67f7d9f-dd42-4422-ab8e-ee5c0f35988b	0317af43-f94a-46e8-8f99-4b83d5227da2	a0b35643-7af6-4cc9-a78d-c6d682eefa93	f95a51fa-849a-4f04-a940-908eef1b5b21	9	9	\N	DRAW	2025-11-01 22:46:39.893781	2025-11-01 21:46:39.897291	2025-11-01 21:46:39.897297
cb1b871c-dee4-4ff9-84bd-7d38ae30c1e8	4a640ed2-2210-4f67-9e30-a4ad2230b334	e35eda2e-1dc1-4119-a0a9-9cbba53dfac2	03d8eb93-2b45-4637-8e78-4871e64ea882	8	3	e35eda2e-1dc1-4119-a0a9-9cbba53dfac2	WIN	2025-11-01 22:48:50.034544	2025-11-01 21:48:50.038385	2025-11-01 21:48:50.038389
\.


--
-- Data for Name: matches; Type: TABLE DATA; Schema: public; Owner: futsal_user
--

COPY public.matches (id, season_id, match_date, status, rsvp_deadline, location, notes, created_at, updated_at, match_week) FROM stdin;
7712a21a-7fc7-4f07-bfbd-fea814175b7c	f16413de-819b-4c68-b591-7ed59f852bbe	2025-09-03 00:00:00	COMPLETED	\N	\N	\N	2025-11-01 21:23:17.916785	2025-11-01 21:23:17.916801	1
e940f144-fd5a-4cf4-b348-decd293ccd1e	f16413de-819b-4c68-b591-7ed59f852bbe	2025-09-10 00:00:00	COMPLETED	\N	\N	\N	2025-11-01 21:27:14.554616	2025-11-01 21:27:14.554741	2
3b9359ce-9703-40ba-b24c-4890af8e64e7	f16413de-819b-4c68-b591-7ed59f852bbe	2025-09-17 00:00:00	COMPLETED	\N	\N	\N	2025-11-01 21:29:44.861399	2025-11-01 21:29:44.861412	3
8c910fd4-9582-4c74-863e-40f6bc168bc0	f16413de-819b-4c68-b591-7ed59f852bbe	2025-09-24 00:00:00	COMPLETED	\N	\N	\N	2025-11-01 21:32:34.879065	2025-11-01 21:32:34.879104	4
2061fd5e-1567-4c8d-87af-a240deb4f826	f16413de-819b-4c68-b591-7ed59f852bbe	2025-10-01 00:00:00	COMPLETED	\N	\N	\N	2025-11-01 21:35:09.943831	2025-11-01 21:35:09.943855	5
6514c434-5c57-4efc-b9f9-710aa9fe061e	f16413de-819b-4c68-b591-7ed59f852bbe	2025-10-08 00:00:00	COMPLETED	\N	\N	\N	2025-11-01 21:37:55.851163	2025-11-01 21:37:55.851201	6
de2e7706-10ec-42a7-b94f-e8ac29f7fbe1	f16413de-819b-4c68-b591-7ed59f852bbe	2025-10-15 00:00:00	COMPLETED	\N	\N	\N	2025-11-01 21:39:52.583596	2025-11-01 21:39:52.583613	7
0317af43-f94a-46e8-8f99-4b83d5227da2	f16413de-819b-4c68-b591-7ed59f852bbe	2025-10-22 00:00:00	COMPLETED	\N	\N	\N	2025-11-01 21:46:25.275271	2025-11-01 21:46:25.275345	8
4a640ed2-2210-4f67-9e30-a4ad2230b334	f16413de-819b-4c68-b591-7ed59f852bbe	2025-10-29 00:00:00	COMPLETED	\N	\N	\N	2025-11-01 21:48:31.250348	2025-11-01 21:48:31.250387	9
\.


--
-- Data for Name: player_match_ratings; Type: TABLE DATA; Schema: public; Owner: futsal_user
--

COPY public.player_match_ratings (id, player_id, match_id, season_id, match_number, match_date, attended_match, attended_third_time, match_result, team_average_rating, opponent_average_rating, rating_before, rating_after, rating_change, elo_k_factor, attendance_bonus, third_time_bonus, non_attendance_penalty, calculated_at, created_at) FROM stdin;
d5fcd8c5-1148-4ba8-b1f6-90e440f8af2c	839f0f95-bd46-4565-b2bc-9c76f0eec536	e940f144-fd5a-4cf4-b348-decd293ccd1e	f16413de-819b-4c68-b591-7ed59f852bbe	2	2025-09-10 00:00:00	f	f	DID_NOT_ATTEND	\N	\N	3	3	0	0.5	0	0	0	2025-11-01 21:28:20.107198	2025-11-01 21:28:20.15
62f9f159-fd88-4701-983a-59cd8f24dc9c	638378af-a3a0-4010-96bd-a4fcdf49e841	e940f144-fd5a-4cf4-b348-decd293ccd1e	f16413de-819b-4c68-b591-7ed59f852bbe	2	2025-09-10 00:00:00	t	t	LOSS	3	3	3	3	0	0.5	0	0	0	2025-11-01 21:28:20.112176	2025-11-01 21:28:20.150006
e0ed158a-2730-4009-abd3-249e919fc6d8	e22adc74-dbad-4a52-8822-d41df3c3a7d0	e940f144-fd5a-4cf4-b348-decd293ccd1e	f16413de-819b-4c68-b591-7ed59f852bbe	2	2025-09-10 00:00:00	t	t	WIN	3	3	3	3	0	0.5	0	0	0	2025-11-01 21:28:20.115194	2025-11-01 21:28:20.15001
dbf12302-f6c1-47e2-8a02-530aded3af6b	c98f7bfd-cbba-443e-941b-962dd6d40fed	e940f144-fd5a-4cf4-b348-decd293ccd1e	f16413de-819b-4c68-b591-7ed59f852bbe	2	2025-09-10 00:00:00	t	f	WIN	3	3	3	3	0	0.5	0	0	0	2025-11-01 21:28:20.117588	2025-11-01 21:28:20.150014
0c2118c3-4290-4751-a79e-bad6625d2014	d83f7d2d-2b57-40bd-80ad-23e4eb03b8a9	e940f144-fd5a-4cf4-b348-decd293ccd1e	f16413de-819b-4c68-b591-7ed59f852bbe	2	2025-09-10 00:00:00	f	f	DID_NOT_ATTEND	\N	\N	3	3	0	0.5	0	0	0	2025-11-01 21:28:20.119978	2025-11-01 21:28:20.150018
5988981b-6272-4458-827f-5edb620474ac	2f2fd4c0-7f94-45f7-8b48-0cbecd8e018c	e940f144-fd5a-4cf4-b348-decd293ccd1e	f16413de-819b-4c68-b591-7ed59f852bbe	2	2025-09-10 00:00:00	f	f	DID_NOT_ATTEND	\N	\N	3	3	0	0.5	0	0	0	2025-11-01 21:28:20.122353	2025-11-01 21:28:20.150021
b1c4ba21-bdbe-4a7e-98a3-bb7c032a20b7	b5b71c9b-a553-4db3-8a95-f0e9fc460a17	e940f144-fd5a-4cf4-b348-decd293ccd1e	f16413de-819b-4c68-b591-7ed59f852bbe	2	2025-09-10 00:00:00	f	f	DID_NOT_ATTEND	\N	\N	3	3	0	0.5	0	0	0	2025-11-01 21:28:20.125017	2025-11-01 21:28:20.150025
fd36b5f4-7234-466a-b911-c22601da0886	f18488fd-d485-4bcf-8f0f-0c2f3cfdb025	e940f144-fd5a-4cf4-b348-decd293ccd1e	f16413de-819b-4c68-b591-7ed59f852bbe	2	2025-09-10 00:00:00	f	f	DID_NOT_ATTEND	\N	\N	3	3	0	0.5	0	0	0	2025-11-01 21:28:20.127442	2025-11-01 21:28:20.150028
5531e46d-d846-4275-8957-2a6e865b4073	0ae22ab5-d3a0-4b3f-9b8d-ece4224f340a	e940f144-fd5a-4cf4-b348-decd293ccd1e	f16413de-819b-4c68-b591-7ed59f852bbe	2	2025-09-10 00:00:00	f	f	DID_NOT_ATTEND	\N	\N	3	3	0	0.5	0	0	0	2025-11-01 21:28:20.130024	2025-11-01 21:28:20.150032
3ab6dccb-f516-4159-a202-fdf08896e906	958f1430-f51c-43a0-871d-e10324151dbc	e940f144-fd5a-4cf4-b348-decd293ccd1e	f16413de-819b-4c68-b591-7ed59f852bbe	2	2025-09-10 00:00:00	f	f	DID_NOT_ATTEND	\N	\N	3	3	0	0.5	0	0	0	2025-11-01 21:28:20.132586	2025-11-01 21:28:20.150035
4ca1e0d2-38a9-4dcf-9c8e-1dd7d0a1a3ec	de7929fd-181e-4cbd-b564-b9fd597779c9	e940f144-fd5a-4cf4-b348-decd293ccd1e	f16413de-819b-4c68-b591-7ed59f852bbe	2	2025-09-10 00:00:00	t	f	WIN	3	3	3	3	0	0.5	0	0	0	2025-11-01 21:28:20.135052	2025-11-01 21:28:20.150039
e24b4631-ce02-4020-8db6-bad22a46b2c7	b982f348-6db4-438a-b106-c74d69e87e2d	e940f144-fd5a-4cf4-b348-decd293ccd1e	f16413de-819b-4c68-b591-7ed59f852bbe	2	2025-09-10 00:00:00	t	t	WIN	3	3	3	3	0	0.5	0	0	0	2025-11-01 21:28:20.137978	2025-11-01 21:28:20.150042
55c935b7-5133-4116-8af0-255b24728a3c	c976e410-ded4-4cc0-ab2f-53ee8abe2a4d	e940f144-fd5a-4cf4-b348-decd293ccd1e	f16413de-819b-4c68-b591-7ed59f852bbe	2	2025-09-10 00:00:00	t	f	LOSS	3	3	3	3	0	0.5	0	0	0	2025-11-01 21:28:20.140905	2025-11-01 21:28:20.150046
158c06b1-dfa4-4f70-82d9-203199546b71	fb1a9540-a35f-4789-a917-888bc71c4e5b	e940f144-fd5a-4cf4-b348-decd293ccd1e	f16413de-819b-4c68-b591-7ed59f852bbe	2	2025-09-10 00:00:00	t	t	LOSS	3	3	3	3	0	0.5	0	0	0	2025-11-01 21:28:20.143673	2025-11-01 21:28:20.150049
5afc8d87-ba1f-4935-8286-756a4bfc9ffa	d3373e62-c862-48ad-9db6-4cf353621f7e	e940f144-fd5a-4cf4-b348-decd293ccd1e	f16413de-819b-4c68-b591-7ed59f852bbe	2	2025-09-10 00:00:00	t	t	LOSS	3	3	3	3	0	0.5	0	0	0	2025-11-01 21:28:20.146444	2025-11-01 21:28:20.150053
153a7b6d-96a2-4034-b2e2-b18e302735e2	839f0f95-bd46-4565-b2bc-9c76f0eec536	3b9359ce-9703-40ba-b24c-4890af8e64e7	f16413de-819b-4c68-b591-7ed59f852bbe	3	2025-09-17 00:00:00	f	f	DID_NOT_ATTEND	\N	\N	3	3	0	0.5	0	0	0	2025-11-01 21:30:53.640934	2025-11-01 21:30:53.687404
96becba0-3056-4321-8ff7-1dd66c62cc75	638378af-a3a0-4010-96bd-a4fcdf49e841	3b9359ce-9703-40ba-b24c-4890af8e64e7	f16413de-819b-4c68-b591-7ed59f852bbe	3	2025-09-17 00:00:00	f	f	DID_NOT_ATTEND	\N	\N	3	3	0	0.5	0	0	0	2025-11-01 21:30:53.647009	2025-11-01 21:30:53.687412
09c07989-d6c8-43fc-9873-5868d6d179e8	e22adc74-dbad-4a52-8822-d41df3c3a7d0	3b9359ce-9703-40ba-b24c-4890af8e64e7	f16413de-819b-4c68-b591-7ed59f852bbe	3	2025-09-17 00:00:00	t	t	LOSS	3	3	3	3	0	0.5	0	0	0	2025-11-01 21:30:53.649526	2025-11-01 21:30:53.687417
f180fe63-64a5-4d23-a37c-16c73f572ae9	c98f7bfd-cbba-443e-941b-962dd6d40fed	3b9359ce-9703-40ba-b24c-4890af8e64e7	f16413de-819b-4c68-b591-7ed59f852bbe	3	2025-09-17 00:00:00	t	f	WIN	3	3	3	3	0	0.5	0	0	0	2025-11-01 21:30:53.653432	2025-11-01 21:30:53.687423
eb05fd98-7c63-4800-b022-e26a86b6f241	d83f7d2d-2b57-40bd-80ad-23e4eb03b8a9	3b9359ce-9703-40ba-b24c-4890af8e64e7	f16413de-819b-4c68-b591-7ed59f852bbe	3	2025-09-17 00:00:00	f	f	DID_NOT_ATTEND	\N	\N	3	3	0	0.5	0	0	0	2025-11-01 21:30:53.656881	2025-11-01 21:30:53.687428
9753f2ad-d9cb-4490-9dcc-0e5376b3d0ab	2f2fd4c0-7f94-45f7-8b48-0cbecd8e018c	3b9359ce-9703-40ba-b24c-4890af8e64e7	f16413de-819b-4c68-b591-7ed59f852bbe	3	2025-09-17 00:00:00	t	f	LOSS	3	3	3	3	0	0.5	0	0	0	2025-11-01 21:30:53.659191	2025-11-01 21:30:53.687433
b4ee5f01-9194-4adf-a895-0acb0471b9f8	b5b71c9b-a553-4db3-8a95-f0e9fc460a17	3b9359ce-9703-40ba-b24c-4890af8e64e7	f16413de-819b-4c68-b591-7ed59f852bbe	3	2025-09-17 00:00:00	f	f	DID_NOT_ATTEND	\N	\N	3	3	0	0.5	0	0	0	2025-11-01 21:30:53.661942	2025-11-01 21:30:53.687438
cd101d1e-ba4b-4d78-9f43-c8d3d6b466d7	f18488fd-d485-4bcf-8f0f-0c2f3cfdb025	3b9359ce-9703-40ba-b24c-4890af8e64e7	f16413de-819b-4c68-b591-7ed59f852bbe	3	2025-09-17 00:00:00	f	f	DID_NOT_ATTEND	\N	\N	3	3	0	0.5	0	0	0	2025-11-01 21:30:53.664855	2025-11-01 21:30:53.687443
e4a8224a-c813-41d4-97c7-7ba5e48cdaca	0ae22ab5-d3a0-4b3f-9b8d-ece4224f340a	3b9359ce-9703-40ba-b24c-4890af8e64e7	f16413de-819b-4c68-b591-7ed59f852bbe	3	2025-09-17 00:00:00	t	f	LOSS	3	3	3	3	0	0.5	0	0	0	2025-11-01 21:30:53.667456	2025-11-01 21:30:53.687448
bc738108-f8b5-4c7e-adf9-a3e5136cf2c6	958f1430-f51c-43a0-871d-e10324151dbc	3b9359ce-9703-40ba-b24c-4890af8e64e7	f16413de-819b-4c68-b591-7ed59f852bbe	3	2025-09-17 00:00:00	t	f	WIN	3	3	3	3	0	0.5	0	0	0	2025-11-01 21:30:53.670132	2025-11-01 21:30:53.687453
90dc47ef-f6ee-4908-8b78-6ace6719bb8a	839f0f95-bd46-4565-b2bc-9c76f0eec536	7712a21a-7fc7-4f07-bfbd-fea814175b7c	f16413de-819b-4c68-b591-7ed59f852bbe	1	2025-09-03 00:00:00	t	t	DRAW	3	3	3	3	0	0.5	0	0	0	2025-11-01 21:24:00.370799	2025-11-01 21:24:00.439464
7926e62c-2398-4b92-83c2-af7f13cc46e3	de7929fd-181e-4cbd-b564-b9fd597779c9	3b9359ce-9703-40ba-b24c-4890af8e64e7	f16413de-819b-4c68-b591-7ed59f852bbe	3	2025-09-17 00:00:00	t	t	WIN	3	3	3	3	0	0.5	0	0	0	2025-11-01 21:30:53.672896	2025-11-01 21:30:53.687458
5e5c386e-2875-43b6-b843-b2c543184c2b	b982f348-6db4-438a-b106-c74d69e87e2d	3b9359ce-9703-40ba-b24c-4890af8e64e7	f16413de-819b-4c68-b591-7ed59f852bbe	3	2025-09-17 00:00:00	f	f	DID_NOT_ATTEND	\N	\N	3	3	0	0.5	0	0	0	2025-11-01 21:30:53.675568	2025-11-01 21:30:53.687463
0395a768-2f30-41eb-a739-427d4ea9b676	c976e410-ded4-4cc0-ab2f-53ee8abe2a4d	3b9359ce-9703-40ba-b24c-4890af8e64e7	f16413de-819b-4c68-b591-7ed59f852bbe	3	2025-09-17 00:00:00	t	t	WIN	3	3	3	3	0	0.5	0	0	0	2025-11-01 21:30:53.678333	2025-11-01 21:30:53.687467
2166a926-9931-4d02-89ae-59011539c074	fb1a9540-a35f-4789-a917-888bc71c4e5b	3b9359ce-9703-40ba-b24c-4890af8e64e7	f16413de-819b-4c68-b591-7ed59f852bbe	3	2025-09-17 00:00:00	t	f	LOSS	3	3	3	3	0	0.5	0	0	0	2025-11-01 21:30:53.681013	2025-11-01 21:30:53.687472
fb25d1cc-9dba-4a62-8c4e-187db528af9b	d3373e62-c862-48ad-9db6-4cf353621f7e	3b9359ce-9703-40ba-b24c-4890af8e64e7	f16413de-819b-4c68-b591-7ed59f852bbe	3	2025-09-17 00:00:00	t	t	WIN	3	3	3	3	0	0.5	0	0	0	2025-11-01 21:30:53.683453	2025-11-01 21:30:53.687477
45a502b0-d3f2-42be-84d9-dfc152ebbe59	839f0f95-bd46-4565-b2bc-9c76f0eec536	8c910fd4-9582-4c74-863e-40f6bc168bc0	f16413de-819b-4c68-b591-7ed59f852bbe	4	2025-09-24 00:00:00	f	f	DID_NOT_ATTEND	\N	\N	3	2.8	-0.2	0.5	0	0	-0.2	2025-11-01 21:33:01.818439	2025-11-01 21:33:01.888674
fcd6840d-ef3b-401e-8c55-bcd3ef04b565	638378af-a3a0-4010-96bd-a4fcdf49e841	8c910fd4-9582-4c74-863e-40f6bc168bc0	f16413de-819b-4c68-b591-7ed59f852bbe	4	2025-09-24 00:00:00	f	f	DID_NOT_ATTEND	\N	\N	3	2.8	-0.2	0.5	0	0	-0.2	2025-11-01 21:33:01.827982	2025-11-01 21:33:01.888684
f6ed1484-ef93-40a8-b969-23f838c9de5f	e22adc74-dbad-4a52-8822-d41df3c3a7d0	8c910fd4-9582-4c74-863e-40f6bc168bc0	f16413de-819b-4c68-b591-7ed59f852bbe	4	2025-09-24 00:00:00	t	t	WIN	3	3	3	3.4	0.39999999999999997	0.5	0.1	0.05	0	2025-11-01 21:33:01.833073	2025-11-01 21:33:01.88869
c7d60341-56e7-4c6a-8e48-9da03095b63c	c98f7bfd-cbba-443e-941b-962dd6d40fed	8c910fd4-9582-4c74-863e-40f6bc168bc0	f16413de-819b-4c68-b591-7ed59f852bbe	4	2025-09-24 00:00:00	t	f	WIN	3	3	3	3.35	0.35	0.5	0.1	0	0	2025-11-01 21:33:01.838242	2025-11-01 21:33:01.888697
de607bdc-1dc0-4c3f-a34e-c03164fb350e	d83f7d2d-2b57-40bd-80ad-23e4eb03b8a9	8c910fd4-9582-4c74-863e-40f6bc168bc0	f16413de-819b-4c68-b591-7ed59f852bbe	4	2025-09-24 00:00:00	f	f	DID_NOT_ATTEND	\N	\N	3	2.8	-0.2	0.5	0	0	-0.2	2025-11-01 21:33:01.842036	2025-11-01 21:33:01.888703
eb44b101-1514-4ec3-845d-89641bee19e5	2f2fd4c0-7f94-45f7-8b48-0cbecd8e018c	8c910fd4-9582-4c74-863e-40f6bc168bc0	f16413de-819b-4c68-b591-7ed59f852bbe	4	2025-09-24 00:00:00	t	f	WIN	3	3	3	3.35	0.35	0.5	0.1	0	0	2025-11-01 21:33:01.845784	2025-11-01 21:33:01.888709
3ee7cee6-e3de-498b-a7f0-488bbb55f3b6	b5b71c9b-a553-4db3-8a95-f0e9fc460a17	8c910fd4-9582-4c74-863e-40f6bc168bc0	f16413de-819b-4c68-b591-7ed59f852bbe	4	2025-09-24 00:00:00	f	f	DID_NOT_ATTEND	\N	\N	3	2.8	-0.2	0.5	0	0	-0.2	2025-11-01 21:33:01.849415	2025-11-01 21:33:01.888715
491a1666-a459-4bff-b8f0-a4cd9184754b	f18488fd-d485-4bcf-8f0f-0c2f3cfdb025	8c910fd4-9582-4c74-863e-40f6bc168bc0	f16413de-819b-4c68-b591-7ed59f852bbe	4	2025-09-24 00:00:00	t	f	LOSS	3	3	3	2.85	-0.15	0.5	0.1	0	0	2025-11-01 21:33:01.853007	2025-11-01 21:33:01.88872
241fb021-3e21-487a-9924-b9ecd4119b06	0ae22ab5-d3a0-4b3f-9b8d-ece4224f340a	8c910fd4-9582-4c74-863e-40f6bc168bc0	f16413de-819b-4c68-b591-7ed59f852bbe	4	2025-09-24 00:00:00	t	f	LOSS	3	3	3	2.85	-0.15	0.5	0.1	0	0	2025-11-01 21:33:01.858193	2025-11-01 21:33:01.888726
26cbf041-214e-4130-8637-4c128af42cd3	958f1430-f51c-43a0-871d-e10324151dbc	8c910fd4-9582-4c74-863e-40f6bc168bc0	f16413de-819b-4c68-b591-7ed59f852bbe	4	2025-09-24 00:00:00	t	f	LOSS	3	3	3	2.85	-0.15	0.5	0.1	0	0	2025-11-01 21:33:01.862771	2025-11-01 21:33:01.888732
e4e94650-5218-4a09-97a0-0ce7e56a965c	de7929fd-181e-4cbd-b564-b9fd597779c9	8c910fd4-9582-4c74-863e-40f6bc168bc0	f16413de-819b-4c68-b591-7ed59f852bbe	4	2025-09-24 00:00:00	t	f	WIN	3	3	3	3.35	0.35	0.5	0.1	0	0	2025-11-01 21:33:01.867262	2025-11-01 21:33:01.888738
104ea10e-bb8b-4154-b87f-56f38ac497c8	b982f348-6db4-438a-b106-c74d69e87e2d	8c910fd4-9582-4c74-863e-40f6bc168bc0	f16413de-819b-4c68-b591-7ed59f852bbe	4	2025-09-24 00:00:00	f	f	DID_NOT_ATTEND	\N	\N	3	2.8	-0.2	0.5	0	0	-0.2	2025-11-01 21:33:01.871342	2025-11-01 21:33:01.888744
9af010c0-841c-4655-b126-dcc5dad1e640	c976e410-ded4-4cc0-ab2f-53ee8abe2a4d	8c910fd4-9582-4c74-863e-40f6bc168bc0	f16413de-819b-4c68-b591-7ed59f852bbe	4	2025-09-24 00:00:00	t	f	LOSS	3	3	3	2.85	-0.15	0.5	0.1	0	0	2025-11-01 21:33:01.875385	2025-11-01 21:33:01.888749
281ca2e5-8de9-442e-85f6-8f83c9c7fdb4	fb1a9540-a35f-4789-a917-888bc71c4e5b	8c910fd4-9582-4c74-863e-40f6bc168bc0	f16413de-819b-4c68-b591-7ed59f852bbe	4	2025-09-24 00:00:00	f	f	DID_NOT_ATTEND	\N	\N	3	2.8	-0.2	0.5	0	0	-0.2	2025-11-01 21:33:01.87982	2025-11-01 21:33:01.888755
2399cd60-064f-4471-a5a4-d5ad9915af0e	d3373e62-c862-48ad-9db6-4cf353621f7e	8c910fd4-9582-4c74-863e-40f6bc168bc0	f16413de-819b-4c68-b591-7ed59f852bbe	4	2025-09-24 00:00:00	t	t	LOSS	3	3	3	2.9	-0.09999999999999999	0.5	0.1	0.05	0	2025-11-01 21:33:01.884256	2025-11-01 21:33:01.888761
a6eca5e6-80a2-4f37-aace-93a4580225c8	839f0f95-bd46-4565-b2bc-9c76f0eec536	2061fd5e-1567-4c8d-87af-a240deb4f826	f16413de-819b-4c68-b591-7ed59f852bbe	5	2025-10-01 00:00:00	t	t	LOSS	3.03	3.0874999999999995	2.8	2.7082718945370385	-0.09172810546296133	0.5	0.1	0.05	0	2025-11-01 21:36:28.631935	2025-11-01 21:36:28.679056
7e652e81-e04a-4513-bea6-dd4ab3242350	638378af-a3a0-4010-96bd-a4fcdf49e841	2061fd5e-1567-4c8d-87af-a240deb4f826	f16413de-819b-4c68-b591-7ed59f852bbe	5	2025-10-01 00:00:00	t	t	WIN	3.0874999999999995	3.03	2.8	3.1917281054629614	0.3917281054629614	0.5	0.1	0.05	0	2025-11-01 21:36:28.637822	2025-11-01 21:36:28.679062
c4b1dd8c-04e9-4d44-80da-9a862dace110	e22adc74-dbad-4a52-8822-d41df3c3a7d0	2061fd5e-1567-4c8d-87af-a240deb4f826	f16413de-819b-4c68-b591-7ed59f852bbe	5	2025-10-01 00:00:00	t	f	WIN	3.0874999999999995	3.03	3.4	3.741728105462961	0.3417281054629614	0.5	0.1	0	0	2025-11-01 21:36:28.6408	2025-11-01 21:36:28.679066
52e18093-a5ce-4d7a-9b13-d8fe75cc0669	c98f7bfd-cbba-443e-941b-962dd6d40fed	2061fd5e-1567-4c8d-87af-a240deb4f826	f16413de-819b-4c68-b591-7ed59f852bbe	5	2025-10-01 00:00:00	t	f	WIN	3.0874999999999995	3.03	3.35	3.6917281054629614	0.3417281054629614	0.5	0.1	0	0	2025-11-01 21:36:28.64389	2025-11-01 21:36:28.67907
454efa31-2b82-446e-8aed-82965cfc5402	d83f7d2d-2b57-40bd-80ad-23e4eb03b8a9	2061fd5e-1567-4c8d-87af-a240deb4f826	f16413de-819b-4c68-b591-7ed59f852bbe	5	2025-10-01 00:00:00	t	t	WIN	3.0874999999999995	3.03	2.8	3.1917281054629614	0.3917281054629614	0.5	0.1	0.05	0	2025-11-01 21:36:28.646759	2025-11-01 21:36:28.679074
d1330912-a2e5-46f1-a261-955b9ee98dad	2f2fd4c0-7f94-45f7-8b48-0cbecd8e018c	2061fd5e-1567-4c8d-87af-a240deb4f826	f16413de-819b-4c68-b591-7ed59f852bbe	5	2025-10-01 00:00:00	t	f	LOSS	3.03	3.0874999999999995	3.35	3.208271894537039	-0.14172810546296133	0.5	0.1	0	0	2025-11-01 21:36:28.64962	2025-11-01 21:36:28.679078
d0d96ed5-c693-4edd-839f-9195725d33dc	b5b71c9b-a553-4db3-8a95-f0e9fc460a17	2061fd5e-1567-4c8d-87af-a240deb4f826	f16413de-819b-4c68-b591-7ed59f852bbe	5	2025-10-01 00:00:00	f	f	DID_NOT_ATTEND	\N	\N	2.8	2.5999999999999996	-0.2	0.5	0	0	-0.2	2025-11-01 21:36:28.652538	2025-11-01 21:36:28.679082
3e1258de-6081-4144-b1f8-1641048467ce	f18488fd-d485-4bcf-8f0f-0c2f3cfdb025	2061fd5e-1567-4c8d-87af-a240deb4f826	f16413de-819b-4c68-b591-7ed59f852bbe	5	2025-10-01 00:00:00	f	f	DID_NOT_ATTEND	\N	\N	2.85	2.65	-0.2	0.5	0	0	-0.2	2025-11-01 21:36:28.656055	2025-11-01 21:36:28.679086
e392e274-88e9-48f7-a4a7-45f947772993	0ae22ab5-d3a0-4b3f-9b8d-ece4224f340a	2061fd5e-1567-4c8d-87af-a240deb4f826	f16413de-819b-4c68-b591-7ed59f852bbe	5	2025-10-01 00:00:00	f	f	DID_NOT_ATTEND	\N	\N	2.85	2.65	-0.2	0.5	0	0	-0.2	2025-11-01 21:36:28.658889	2025-11-01 21:36:28.67909
1ff904b4-c7b7-46ec-9390-871f457ee6d9	958f1430-f51c-43a0-871d-e10324151dbc	2061fd5e-1567-4c8d-87af-a240deb4f826	f16413de-819b-4c68-b591-7ed59f852bbe	5	2025-10-01 00:00:00	f	f	DID_NOT_ATTEND	\N	\N	2.85	2.65	-0.2	0.5	0	0	-0.2	2025-11-01 21:36:28.661644	2025-11-01 21:36:28.679094
ed9dd05b-fdc8-4fc6-9d9d-756380096cd0	de7929fd-181e-4cbd-b564-b9fd597779c9	2061fd5e-1567-4c8d-87af-a240deb4f826	f16413de-819b-4c68-b591-7ed59f852bbe	5	2025-10-01 00:00:00	t	f	LOSS	3.03	3.0874999999999995	3.35	3.208271894537039	-0.14172810546296133	0.5	0.1	0	0	2025-11-01 21:36:28.664615	2025-11-01 21:36:28.679098
b463d4a1-f523-4087-bcac-2ed3a29edbe0	b982f348-6db4-438a-b106-c74d69e87e2d	2061fd5e-1567-4c8d-87af-a240deb4f826	f16413de-819b-4c68-b591-7ed59f852bbe	5	2025-10-01 00:00:00	f	f	DID_NOT_ATTEND	\N	\N	2.8	2.5999999999999996	-0.2	0.5	0	0	-0.2	2025-11-01 21:36:28.66749	2025-11-01 21:36:28.679102
4035f4d2-c204-46a9-85fb-dd1bb5c66bf2	c976e410-ded4-4cc0-ab2f-53ee8abe2a4d	2061fd5e-1567-4c8d-87af-a240deb4f826	f16413de-819b-4c68-b591-7ed59f852bbe	5	2025-10-01 00:00:00	t	t	LOSS	3.03	3.0874999999999995	2.85	2.758271894537039	-0.09172810546296133	0.5	0.1	0.05	0	2025-11-01 21:36:28.670311	2025-11-01 21:36:28.679106
c8eb4b30-024d-4dbd-8863-b18138edba60	fb1a9540-a35f-4789-a917-888bc71c4e5b	2061fd5e-1567-4c8d-87af-a240deb4f826	f16413de-819b-4c68-b591-7ed59f852bbe	5	2025-10-01 00:00:00	t	f	LOSS	3.03	3.0874999999999995	2.8	2.6582718945370383	-0.14172810546296133	0.5	0.1	0	0	2025-11-01 21:36:28.672952	2025-11-01 21:36:28.67911
2698a40f-c1d9-4a15-8313-0d8ac69a2de1	d3373e62-c862-48ad-9db6-4cf353621f7e	2061fd5e-1567-4c8d-87af-a240deb4f826	f16413de-819b-4c68-b591-7ed59f852bbe	5	2025-10-01 00:00:00	f	f	DID_NOT_ATTEND	\N	\N	2.9	2.6999999999999997	-0.2	0.5	0	0	-0.2	2025-11-01 21:36:28.675826	2025-11-01 21:36:28.679113
9b54209e-a557-4e8e-a8a9-dab3e8616a14	839f0f95-bd46-4565-b2bc-9c76f0eec536	6514c434-5c57-4efc-b9f9-710aa9fe061e	f16413de-819b-4c68-b591-7ed59f852bbe	6	2025-10-08 00:00:00	t	t	LOSS	2.9118696540211646	3.087530719398147	2.7082718945370385	2.633465743565637	-0.07480615097140193	0.5	0.1	0.05	0	2025-11-01 21:38:31.067423	2025-11-01 21:38:31.119079
42c2c3af-9e2f-4dac-a134-65344c6c027d	638378af-a3a0-4010-96bd-a4fcdf49e841	6514c434-5c57-4efc-b9f9-710aa9fe061e	f16413de-819b-4c68-b591-7ed59f852bbe	6	2025-10-08 00:00:00	t	t	LOSS	2.9118696540211646	3.087530719398147	3.1917281054629614	3.1169219544915596	-0.07480615097140193	0.5	0.1	0.05	0	2025-11-01 21:38:31.073823	2025-11-01 21:38:31.119086
1600f5f5-5142-44c5-9d6e-c423ef59a600	e22adc74-dbad-4a52-8822-d41df3c3a7d0	6514c434-5c57-4efc-b9f9-710aa9fe061e	f16413de-819b-4c68-b591-7ed59f852bbe	6	2025-10-08 00:00:00	t	t	WIN	3.087530719398147	2.9118696540211646	3.741728105462961	4.116534256434363	0.37480615097140196	0.5	0.1	0.05	0	2025-11-01 21:38:31.077124	2025-11-01 21:38:31.119091
c497af99-e9d6-44e4-96d1-d8b7d4c0b2ab	c98f7bfd-cbba-443e-941b-962dd6d40fed	6514c434-5c57-4efc-b9f9-710aa9fe061e	f16413de-819b-4c68-b591-7ed59f852bbe	6	2025-10-08 00:00:00	t	f	WIN	3.087530719398147	2.9118696540211646	3.6917281054629614	4.016534256434364	0.324806150971402	0.5	0.1	0	0	2025-11-01 21:38:31.080512	2025-11-01 21:38:31.119096
891a87cb-6021-407f-a201-563255907ddf	d83f7d2d-2b57-40bd-80ad-23e4eb03b8a9	6514c434-5c57-4efc-b9f9-710aa9fe061e	f16413de-819b-4c68-b591-7ed59f852bbe	6	2025-10-08 00:00:00	t	t	WIN	3.087530719398147	2.9118696540211646	3.1917281054629614	3.5665342564343634	0.37480615097140196	0.5	0.1	0.05	0	2025-11-01 21:38:31.083678	2025-11-01 21:38:31.1191
96d46e9b-bd00-4c89-be2e-123af4f2a8f7	2f2fd4c0-7f94-45f7-8b48-0cbecd8e018c	6514c434-5c57-4efc-b9f9-710aa9fe061e	f16413de-819b-4c68-b591-7ed59f852bbe	6	2025-10-08 00:00:00	t	f	LOSS	2.9118696540211646	3.087530719398147	3.208271894537039	3.083465743565637	-0.12480615097140194	0.5	0.1	0	0	2025-11-01 21:38:31.087109	2025-11-01 21:38:31.119105
b3d316f3-0bb9-4e34-9a60-026e609b4aee	b5b71c9b-a553-4db3-8a95-f0e9fc460a17	6514c434-5c57-4efc-b9f9-710aa9fe061e	f16413de-819b-4c68-b591-7ed59f852bbe	6	2025-10-08 00:00:00	f	f	DID_NOT_ATTEND	\N	\N	2.5999999999999996	2.3999999999999995	-0.2	0.5	0	0	-0.2	2025-11-01 21:38:31.090148	2025-11-01 21:38:31.119109
871879a0-03b0-48a4-92f8-66c6216f506c	f18488fd-d485-4bcf-8f0f-0c2f3cfdb025	6514c434-5c57-4efc-b9f9-710aa9fe061e	f16413de-819b-4c68-b591-7ed59f852bbe	6	2025-10-08 00:00:00	t	f	WIN	3.087530719398147	2.9118696540211646	2.65	2.9748061509714017	0.324806150971402	0.5	0.1	0	0	2025-11-01 21:38:31.093802	2025-11-01 21:38:31.119114
4824c840-f618-427c-8aeb-ce7a7765155e	0ae22ab5-d3a0-4b3f-9b8d-ece4224f340a	6514c434-5c57-4efc-b9f9-710aa9fe061e	f16413de-819b-4c68-b591-7ed59f852bbe	6	2025-10-08 00:00:00	t	f	WIN	3.087530719398147	2.9118696540211646	2.65	2.9748061509714017	0.324806150971402	0.5	0.1	0	0	2025-11-01 21:38:31.096758	2025-11-01 21:38:31.119118
9f98d3a5-7c46-47a4-9563-4967a3e6ce80	958f1430-f51c-43a0-871d-e10324151dbc	6514c434-5c57-4efc-b9f9-710aa9fe061e	f16413de-819b-4c68-b591-7ed59f852bbe	6	2025-10-08 00:00:00	t	f	LOSS	2.9118696540211646	3.087530719398147	2.65	2.525193849028598	-0.12480615097140194	0.5	0.1	0	0	2025-11-01 21:38:31.100036	2025-11-01 21:38:31.119123
f8ee8265-e090-4023-8b60-5093fd76fe61	de7929fd-181e-4cbd-b564-b9fd597779c9	6514c434-5c57-4efc-b9f9-710aa9fe061e	f16413de-819b-4c68-b591-7ed59f852bbe	6	2025-10-08 00:00:00	t	f	LOSS	2.9118696540211646	3.087530719398147	3.208271894537039	3.083465743565637	-0.12480615097140194	0.5	0.1	0	0	2025-11-01 21:38:31.103182	2025-11-01 21:38:31.119127
a00f88ae-312a-41dd-a8ca-84611665f3d9	b982f348-6db4-438a-b106-c74d69e87e2d	6514c434-5c57-4efc-b9f9-710aa9fe061e	f16413de-819b-4c68-b591-7ed59f852bbe	6	2025-10-08 00:00:00	t	t	WIN	3.087530719398147	2.9118696540211646	2.5999999999999996	2.9748061509714017	0.37480615097140196	0.5	0.1	0.05	0	2025-11-01 21:38:31.106238	2025-11-01 21:38:31.119131
1e7ab00a-5a65-4e3e-8c82-2fc968ca1c30	c976e410-ded4-4cc0-ab2f-53ee8abe2a4d	6514c434-5c57-4efc-b9f9-710aa9fe061e	f16413de-819b-4c68-b591-7ed59f852bbe	6	2025-10-08 00:00:00	t	f	LOSS	2.9118696540211646	3.087530719398147	2.758271894537039	2.633465743565637	-0.12480615097140194	0.5	0.1	0	0	2025-11-01 21:38:31.10936	2025-11-01 21:38:31.119136
be7d98f8-ab28-4693-8574-e088be11ae0b	fb1a9540-a35f-4789-a917-888bc71c4e5b	6514c434-5c57-4efc-b9f9-710aa9fe061e	f16413de-819b-4c68-b591-7ed59f852bbe	6	2025-10-08 00:00:00	t	t	LOSS	2.9118696540211646	3.087530719398147	2.6582718945370383	2.5834657435656365	-0.07480615097140193	0.5	0.1	0.05	0	2025-11-01 21:38:31.112812	2025-11-01 21:38:31.11914
3ccadfa0-977f-4268-b2ae-f09fab3c1112	d3373e62-c862-48ad-9db6-4cf353621f7e	6514c434-5c57-4efc-b9f9-710aa9fe061e	f16413de-819b-4c68-b591-7ed59f852bbe	6	2025-10-08 00:00:00	f	f	DID_NOT_ATTEND	\N	\N	2.6999999999999997	2.4999999999999996	-0.2	0.5	0	0	-0.2	2025-11-01 21:38:31.115927	2025-11-01 21:38:31.119145
08449ec0-8283-40d2-af31-9c1389acbd6e	839f0f95-bd46-4565-b2bc-9c76f0eec536	de2e7706-10ec-42a7-b94f-e8ac29f7fbe1	f16413de-819b-4c68-b591-7ed59f852bbe	7	2025-10-15 00:00:00	t	t	DRAW	3.0847765987657056	3.16503876980572	2.633465743565637	2.9950081864961104	0.16154244293047365	0.5	0.1	0.05	0	2025-11-01 21:40:24.230699	2025-11-01 21:40:24.281517
b3ddc140-0d44-400e-9d20-1decb7d8601e	638378af-a3a0-4010-96bd-a4fcdf49e841	de2e7706-10ec-42a7-b94f-e8ac29f7fbe1	f16413de-819b-4c68-b591-7ed59f852bbe	7	2025-10-15 00:00:00	t	t	DRAW	3.0847765987657056	3.16503876980572	3.1169219544915596	3.4784643974220333	0.16154244293047365	0.5	0.1	0.05	0	2025-11-01 21:40:24.237495	2025-11-01 21:40:24.281525
6382902a-f06d-43e3-96f1-f7d788e6b9fc	e22adc74-dbad-4a52-8822-d41df3c3a7d0	de2e7706-10ec-42a7-b94f-e8ac29f7fbe1	f16413de-819b-4c68-b591-7ed59f852bbe	7	2025-10-15 00:00:00	t	t	DRAW	3.0847765987657056	3.16503876980572	4.116534256434363	3.878076699364837	0.16154244293047365	0.5	0.1	0.05	0	2025-11-01 21:40:24.240937	2025-11-01 21:40:24.281529
0f284fd6-248d-4c1c-9085-1f545a84e3e8	c98f7bfd-cbba-443e-941b-962dd6d40fed	de2e7706-10ec-42a7-b94f-e8ac29f7fbe1	f16413de-819b-4c68-b591-7ed59f852bbe	7	2025-10-15 00:00:00	t	f	DRAW	3.16503876980572	3.0847765987657056	4.016534256434364	3.7549918135038896	0.08845755706952643	0.5	0.1	0	0	2025-11-01 21:40:24.244555	2025-11-01 21:40:24.281533
aad583b2-b4b5-4b12-917c-d6fac959fe84	d83f7d2d-2b57-40bd-80ad-23e4eb03b8a9	de2e7706-10ec-42a7-b94f-e8ac29f7fbe1	f16413de-819b-4c68-b591-7ed59f852bbe	7	2025-10-15 00:00:00	t	f	DRAW	3.16503876980572	3.0847765987657056	3.5665342564343634	3.85499181350389	0.08845755706952643	0.5	0.1	0	0	2025-11-01 21:40:24.247582	2025-11-01 21:40:24.281537
39c1a01e-6602-4469-a883-01f1ebd2e06e	2f2fd4c0-7f94-45f7-8b48-0cbecd8e018c	de2e7706-10ec-42a7-b94f-e8ac29f7fbe1	f16413de-819b-4c68-b591-7ed59f852bbe	7	2025-10-15 00:00:00	t	f	DRAW	3.16503876980572	3.0847765987657056	3.083465743565637	2.821923300635163	0.08845755706952643	0.5	0.1	0	0	2025-11-01 21:40:24.250561	2025-11-01 21:40:24.281542
2d661a37-1585-44da-9b0a-9e336a05de78	b5b71c9b-a553-4db3-8a95-f0e9fc460a17	de2e7706-10ec-42a7-b94f-e8ac29f7fbe1	f16413de-819b-4c68-b591-7ed59f852bbe	7	2025-10-15 00:00:00	f	f	DID_NOT_ATTEND	\N	\N	2.3999999999999995	2.3999999999999995	-0.2	0.5	0	0	-0.2	2025-11-01 21:40:24.253661	2025-11-01 21:40:24.281546
14421f51-90af-47a2-90e2-de8401e11491	f18488fd-d485-4bcf-8f0f-0c2f3cfdb025	de2e7706-10ec-42a7-b94f-e8ac29f7fbe1	f16413de-819b-4c68-b591-7ed59f852bbe	7	2025-10-15 00:00:00	f	f	DID_NOT_ATTEND	\N	\N	2.9748061509714017	2.924806150971402	-0.2	0.5	0	0	-0.2	2025-11-01 21:40:24.257408	2025-11-01 21:40:24.28155
f9f55904-898f-4d5e-8f01-f5f190aaa563	0ae22ab5-d3a0-4b3f-9b8d-ece4224f340a	de2e7706-10ec-42a7-b94f-e8ac29f7fbe1	f16413de-819b-4c68-b591-7ed59f852bbe	7	2025-10-15 00:00:00	f	f	DID_NOT_ATTEND	\N	\N	2.9748061509714017	2.924806150971402	-0.2	0.5	0	0	-0.2	2025-11-01 21:40:24.261109	2025-11-01 21:40:24.281553
86b94cec-868c-4e92-a334-92bff3ebc594	958f1430-f51c-43a0-871d-e10324151dbc	de2e7706-10ec-42a7-b94f-e8ac29f7fbe1	f16413de-819b-4c68-b591-7ed59f852bbe	7	2025-10-15 00:00:00	t	f	DRAW	3.16503876980572	3.0847765987657056	2.525193849028598	2.7636514060981243	0.08845755706952643	0.5	0.1	0	0	2025-11-01 21:40:24.263953	2025-11-01 21:40:24.281557
8748cc07-4b5f-43f4-a8ca-c24eed013f86	de7929fd-181e-4cbd-b564-b9fd597779c9	de2e7706-10ec-42a7-b94f-e8ac29f7fbe1	f16413de-819b-4c68-b591-7ed59f852bbe	7	2025-10-15 00:00:00	t	f	DRAW	3.0847765987657056	3.16503876980572	3.083465743565637	2.84500818649611	0.11154244293047363	0.5	0.1	0	0	2025-11-01 21:40:24.267002	2025-11-01 21:40:24.281561
1519a6e8-a810-4f86-8575-d85f9cf786a5	b982f348-6db4-438a-b106-c74d69e87e2d	de2e7706-10ec-42a7-b94f-e8ac29f7fbe1	f16413de-819b-4c68-b591-7ed59f852bbe	7	2025-10-15 00:00:00	t	f	DRAW	3.0847765987657056	3.16503876980572	2.9748061509714017	3.2863485939018755	0.11154244293047363	0.5	0.1	0	0	2025-11-01 21:40:24.26988	2025-11-01 21:40:24.281565
ea0c956e-b7ba-4627-bb0c-03e460d5a422	c976e410-ded4-4cc0-ab2f-53ee8abe2a4d	de2e7706-10ec-42a7-b94f-e8ac29f7fbe1	f16413de-819b-4c68-b591-7ed59f852bbe	7	2025-10-15 00:00:00	t	f	DRAW	3.16503876980572	3.0847765987657056	2.633465743565637	2.871923300635163	0.08845755706952643	0.5	0.1	0	0	2025-11-01 21:40:24.27262	2025-11-01 21:40:24.281569
ee4cf3b7-92a2-4134-8dc9-ad9eef48454a	fb1a9540-a35f-4789-a917-888bc71c4e5b	de2e7706-10ec-42a7-b94f-e8ac29f7fbe1	f16413de-819b-4c68-b591-7ed59f852bbe	7	2025-10-15 00:00:00	t	f	DRAW	3.0847765987657056	3.16503876980572	2.5834657435656365	2.8950081864961104	0.11154244293047363	0.5	0.1	0	0	2025-11-01 21:40:24.275544	2025-11-01 21:40:24.281573
b87a21a2-f142-46d2-8618-f6c6e32be6f7	d3373e62-c862-48ad-9db6-4cf353621f7e	de2e7706-10ec-42a7-b94f-e8ac29f7fbe1	f16413de-819b-4c68-b591-7ed59f852bbe	7	2025-10-15 00:00:00	f	f	DID_NOT_ATTEND	\N	\N	2.4999999999999996	2.3999999999999995	-0.2	0.5	0	0	-0.2	2025-11-01 21:40:24.278524	2025-11-01 21:40:24.281577
d7bda7f8-7d13-4896-8903-d51c5be413ec	839f0f95-bd46-4565-b2bc-9c76f0eec536	0317af43-f94a-46e8-8f99-4b83d5227da2	f16413de-819b-4c68-b591-7ed59f852bbe	8	2025-10-22 00:00:00	t	f	DRAW	3.2936186144714115	3.2318257030490622	2.9950081864961104	3.177847325877686	0.0911110339186145	0.5	0.1	0	0	2025-11-01 21:46:48.328695	2025-11-01 21:46:48.361053
58a16e8e-55b4-48f2-a7b8-05a1e02d36e0	638378af-a3a0-4010-96bd-a4fcdf49e841	0317af43-f94a-46e8-8f99-4b83d5227da2	f16413de-819b-4c68-b591-7ed59f852bbe	8	2025-10-22 00:00:00	t	f	DRAW	3.2318257030490622	3.2936186144714115	3.4784643974220333	3.195625258040457	0.10888896608138551	0.5	0.1	0	0	2025-11-01 21:46:48.332884	2025-11-01 21:46:48.361057
5d0409f4-df7e-42f0-a40a-daa08bd50194	e22adc74-dbad-4a52-8822-d41df3c3a7d0	0317af43-f94a-46e8-8f99-4b83d5227da2	f16413de-819b-4c68-b591-7ed59f852bbe	8	2025-10-22 00:00:00	t	f	DRAW	3.2936186144714115	3.2318257030490622	3.878076699364837	3.62745962782049	0.0911110339186145	0.5	0.1	0	0	2025-11-01 21:46:48.33521	2025-11-01 21:46:48.36106
51fe7299-5a93-4f44-aebd-86fe44251a50	c98f7bfd-cbba-443e-941b-962dd6d40fed	0317af43-f94a-46e8-8f99-4b83d5227da2	f16413de-819b-4c68-b591-7ed59f852bbe	8	2025-10-22 00:00:00	t	f	DRAW	3.2318257030490622	3.2936186144714115	3.7549918135038896	3.522152674122314	0.10888896608138551	0.5	0.1	0	0	2025-11-01 21:46:48.337172	2025-11-01 21:46:48.361062
1fe4e437-d5c9-4299-9082-7318c2c18d73	d83f7d2d-2b57-40bd-80ad-23e4eb03b8a9	0317af43-f94a-46e8-8f99-4b83d5227da2	f16413de-819b-4c68-b591-7ed59f852bbe	8	2025-10-22 00:00:00	t	f	DRAW	3.2936186144714115	3.2318257030490622	3.85499181350389	3.554374741959543	0.0911110339186145	0.5	0.1	0	0	2025-11-01 21:46:48.339253	2025-11-01 21:46:48.361065
33dc2bae-a42d-4cf6-b51d-b8993793ad9e	2f2fd4c0-7f94-45f7-8b48-0cbecd8e018c	0317af43-f94a-46e8-8f99-4b83d5227da2	f16413de-819b-4c68-b591-7ed59f852bbe	8	2025-10-22 00:00:00	t	f	DRAW	3.2318257030490622	3.2936186144714115	2.821923300635163	3.07254037217951	0.10888896608138551	0.5	0.1	0	0	2025-11-01 21:46:48.341399	2025-11-01 21:46:48.361067
ce727854-4e57-4ef8-b210-cea81bb05b59	b5b71c9b-a553-4db3-8a95-f0e9fc460a17	0317af43-f94a-46e8-8f99-4b83d5227da2	f16413de-819b-4c68-b591-7ed59f852bbe	8	2025-10-22 00:00:00	f	f	DID_NOT_ATTEND	\N	\N	2.3999999999999995	2.3999999999999995	-0.2	0.5	0	0	-0.2	2025-11-01 21:46:48.343429	2025-11-01 21:46:48.36107
7aba0783-c8be-4be3-b030-c21d6d4c65dd	f18488fd-d485-4bcf-8f0f-0c2f3cfdb025	0317af43-f94a-46e8-8f99-4b83d5227da2	f16413de-819b-4c68-b591-7ed59f852bbe	8	2025-10-22 00:00:00	f	f	DID_NOT_ATTEND	\N	\N	2.924806150971402	2.924806150971402	-0.2	0.5	0	0	-0.2	2025-11-01 21:46:48.34583	2025-11-01 21:46:48.361072
c290fcbe-cfe4-4561-8a8c-aad413109aa2	0ae22ab5-d3a0-4b3f-9b8d-ece4224f340a	0317af43-f94a-46e8-8f99-4b83d5227da2	f16413de-819b-4c68-b591-7ed59f852bbe	8	2025-10-22 00:00:00	f	f	DID_NOT_ATTEND	\N	\N	2.924806150971402	2.924806150971402	-0.2	0.5	0	0	-0.2	2025-11-01 21:46:48.347768	2025-11-01 21:46:48.361074
c2125608-bacc-415a-a7e4-fe656b675323	958f1430-f51c-43a0-871d-e10324151dbc	0317af43-f94a-46e8-8f99-4b83d5227da2	f16413de-819b-4c68-b591-7ed59f852bbe	8	2025-10-22 00:00:00	f	f	DID_NOT_ATTEND	\N	\N	2.7636514060981243	2.7636514060981243	-0.2	0.5	0	0	-0.2	2025-11-01 21:46:48.349581	2025-11-01 21:46:48.361076
396e13e3-fb0d-45f2-8865-11aafccee3fa	de7929fd-181e-4cbd-b564-b9fd597779c9	0317af43-f94a-46e8-8f99-4b83d5227da2	f16413de-819b-4c68-b591-7ed59f852bbe	8	2025-10-22 00:00:00	t	f	DRAW	3.2936186144714115	3.2318257030490622	2.84500818649611	3.077847325877686	0.0911110339186145	0.5	0.1	0	0	2025-11-01 21:46:48.351546	2025-11-01 21:46:48.361079
88266894-8af3-49be-bb72-1deb8429596a	b982f348-6db4-438a-b106-c74d69e87e2d	0317af43-f94a-46e8-8f99-4b83d5227da2	f16413de-819b-4c68-b591-7ed59f852bbe	8	2025-10-22 00:00:00	f	f	DID_NOT_ATTEND	\N	\N	3.2863485939018755	3.2863485939018755	-0.2	0.5	0	0	-0.2	2025-11-01 21:46:48.353374	2025-11-01 21:46:48.361081
2ea48447-da36-4fca-b4ca-166386b4e4e1	c976e410-ded4-4cc0-ab2f-53ee8abe2a4d	0317af43-f94a-46e8-8f99-4b83d5227da2	f16413de-819b-4c68-b591-7ed59f852bbe	8	2025-10-22 00:00:00	t	f	DRAW	3.2318257030490622	3.2936186144714115	2.871923300635163	3.07254037217951	0.10888896608138551	0.5	0.1	0	0	2025-11-01 21:46:48.355286	2025-11-01 21:46:48.361083
a575a97c-0d07-4738-bed0-cae62725e73c	fb1a9540-a35f-4789-a917-888bc71c4e5b	0317af43-f94a-46e8-8f99-4b83d5227da2	f16413de-819b-4c68-b591-7ed59f852bbe	8	2025-10-22 00:00:00	t	f	DRAW	3.2936186144714115	3.2318257030490622	2.8950081864961104	3.127847325877686	0.0911110339186145	0.5	0.1	0	0	2025-11-01 21:46:48.357113	2025-11-01 21:46:48.361086
3115e5a2-3056-4d25-a3e1-99c471c183f3	d3373e62-c862-48ad-9db6-4cf353621f7e	0317af43-f94a-46e8-8f99-4b83d5227da2	f16413de-819b-4c68-b591-7ed59f852bbe	8	2025-10-22 00:00:00	f	f	DID_NOT_ATTEND	\N	\N	2.3999999999999995	2.3999999999999995	-0.2	0.5	0	0	-0.2	2025-11-01 21:46:48.358987	2025-11-01 21:46:48.361088
947d344d-9e95-4568-8e70-feeb06b25560	839f0f95-bd46-4565-b2bc-9c76f0eec536	4a640ed2-2210-4f67-9e30-a4ad2230b334	f16413de-819b-4c68-b591-7ed59f852bbe	9	2025-10-29 00:00:00	f	f	DID_NOT_ATTEND	\N	\N	3.177847325877686	3.0526534768490876	-0.2	0.5	0	0	-0.2	2025-11-01 21:49:14.970088	2025-11-01 21:49:15.015099
67346eab-99f0-473d-bb31-ec727f48c406	638378af-a3a0-4010-96bd-a4fcdf49e841	4a640ed2-2210-4f67-9e30-a4ad2230b334	f16413de-819b-4c68-b591-7ed59f852bbe	9	2025-10-29 00:00:00	t	t	WIN	3.35	3.0444618314694214	3.195625258040457	3.626908791871957	0.3564773828600983	0.5	0.1	0.05	0	2025-11-01 21:49:14.973975	2025-11-01 21:49:15.015103
58d7900e-9396-4f27-b747-1b4a651c9af7	e22adc74-dbad-4a52-8822-d41df3c3a7d0	4a640ed2-2210-4f67-9e30-a4ad2230b334	f16413de-819b-4c68-b591-7ed59f852bbe	9	2025-10-29 00:00:00	t	t	LOSS	3.0444618314694214	3.35	3.62745962782049	3.1961760939889894	-0.056477382860098305	0.5	0.1	0.05	0	2025-11-01 21:49:14.976597	2025-11-01 21:49:15.015105
c45b8b51-a888-4861-bef9-81a45fa63563	c98f7bfd-cbba-443e-941b-962dd6d40fed	4a640ed2-2210-4f67-9e30-a4ad2230b334	f16413de-819b-4c68-b591-7ed59f852bbe	9	2025-10-29 00:00:00	t	f	WIN	3.35	3.0444618314694214	3.522152674122314	3.5038239060110103	0.3064773828600983	0.5	0.1	0	0	2025-11-01 21:49:14.979991	2025-11-01 21:49:15.015108
aeca5139-6a44-4eef-a36b-e84849ca97a0	d83f7d2d-2b57-40bd-80ad-23e4eb03b8a9	4a640ed2-2210-4f67-9e30-a4ad2230b334	f16413de-819b-4c68-b591-7ed59f852bbe	9	2025-10-29 00:00:00	t	f	WIN	3.35	3.0444618314694214	3.554374741959543	3.486045973848239	0.3064773828600983	0.5	0.1	0	0	2025-11-01 21:49:14.983897	2025-11-01 21:49:15.015111
49be7529-874d-41e9-83e8-0bc434dac6da	2f2fd4c0-7f94-45f7-8b48-0cbecd8e018c	4a640ed2-2210-4f67-9e30-a4ad2230b334	f16413de-819b-4c68-b591-7ed59f852bbe	9	2025-10-29 00:00:00	f	f	DID_NOT_ATTEND	\N	\N	3.07254037217951	2.9973465231509118	-0.2	0.5	0	0	-0.2	2025-11-01 21:49:14.986906	2025-11-01 21:49:15.015113
4a8c376e-4c83-4118-9362-1f1b37da7c50	b5b71c9b-a553-4db3-8a95-f0e9fc460a17	4a640ed2-2210-4f67-9e30-a4ad2230b334	f16413de-819b-4c68-b591-7ed59f852bbe	9	2025-10-29 00:00:00	f	f	DID_NOT_ATTEND	\N	\N	2.3999999999999995	2.3999999999999995	-0.2	0.5	0	0	-0.2	2025-11-01 21:49:14.989803	2025-11-01 21:49:15.015115
9e0e6fa0-a413-47f7-af9a-9a3e206a346a	f18488fd-d485-4bcf-8f0f-0c2f3cfdb025	4a640ed2-2210-4f67-9e30-a4ad2230b334	f16413de-819b-4c68-b591-7ed59f852bbe	9	2025-10-29 00:00:00	f	f	DID_NOT_ATTEND	\N	\N	2.924806150971402	2.3999999999999995	-0.2	0.5	0	0	-0.2	2025-11-01 21:49:14.993498	2025-11-01 21:49:15.015118
9ac80177-37da-4940-848b-866f13e6d8e6	0ae22ab5-d3a0-4b3f-9b8d-ece4224f340a	4a640ed2-2210-4f67-9e30-a4ad2230b334	f16413de-819b-4c68-b591-7ed59f852bbe	9	2025-10-29 00:00:00	f	f	DID_NOT_ATTEND	\N	\N	2.924806150971402	2.3999999999999995	-0.2	0.5	0	0	-0.2	2025-11-01 21:49:14.996139	2025-11-01 21:49:15.01512
8bcef77f-b801-416d-8359-984b547b6e27	958f1430-f51c-43a0-871d-e10324151dbc	4a640ed2-2210-4f67-9e30-a4ad2230b334	f16413de-819b-4c68-b591-7ed59f852bbe	9	2025-10-29 00:00:00	f	f	DID_NOT_ATTEND	\N	\N	2.7636514060981243	2.688457557069526	-0.2	0.5	0	0	-0.2	2025-11-01 21:49:14.998664	2025-11-01 21:49:15.015122
e283d9fb-0290-4fb2-9292-be6d802cbd8e	de7929fd-181e-4cbd-b564-b9fd597779c9	4a640ed2-2210-4f67-9e30-a4ad2230b334	f16413de-819b-4c68-b591-7ed59f852bbe	9	2025-10-29 00:00:00	t	f	LOSS	3.0444618314694214	3.35	3.077847325877686	3.0961760939889897	-0.10647738286009831	0.5	0.1	0	0	2025-11-01 21:49:15.00171	2025-11-01 21:49:15.015124
71b058f6-c03e-44a6-956b-b912411c3bd1	b982f348-6db4-438a-b106-c74d69e87e2d	4a640ed2-2210-4f67-9e30-a4ad2230b334	f16413de-819b-4c68-b591-7ed59f852bbe	9	2025-10-29 00:00:00	f	f	DID_NOT_ATTEND	\N	\N	3.2863485939018755	2.7115424429304733	-0.2	0.5	0	0	-0.2	2025-11-01 21:49:15.004669	2025-11-01 21:49:15.015127
542bd213-66a0-473d-8778-8fc89c22b4fb	c976e410-ded4-4cc0-ab2f-53ee8abe2a4d	4a640ed2-2210-4f67-9e30-a4ad2230b334	f16413de-819b-4c68-b591-7ed59f852bbe	9	2025-10-29 00:00:00	t	f	LOSS	3.0444618314694214	3.35	3.07254037217951	3.0908691402908137	-0.10647738286009831	0.5	0.1	0	0	2025-11-01 21:49:15.007278	2025-11-01 21:49:15.015129
1a457a9e-7d44-43af-8dae-41b2cbb672a9	fb1a9540-a35f-4789-a917-888bc71c4e5b	4a640ed2-2210-4f67-9e30-a4ad2230b334	f16413de-819b-4c68-b591-7ed59f852bbe	9	2025-10-29 00:00:00	t	f	WIN	3.35	3.0444618314694214	3.127847325877686	3.5091308597091864	0.3064773828600983	0.5	0.1	0	0	2025-11-01 21:49:15.010313	2025-11-01 21:49:15.015131
3a3e53d5-8fb5-428a-ada4-ebf813ece649	d3373e62-c862-48ad-9db6-4cf353621f7e	4a640ed2-2210-4f67-9e30-a4ad2230b334	f16413de-819b-4c68-b591-7ed59f852bbe	9	2025-10-29 00:00:00	t	t	LOSS	3.0444618314694214	3.35	2.3999999999999995	2.5435226171399012	-0.056477382860098305	0.5	0.1	0.05	0	2025-11-01 21:49:15.012877	2025-11-01 21:49:15.015134
1b4d2768-ce4a-4447-8bb5-f5f32144dc03	b982f348-6db4-438a-b106-c74d69e87e2d	7712a21a-7fc7-4f07-bfbd-fea814175b7c	f16413de-819b-4c68-b591-7ed59f852bbe	1	2025-09-03 00:00:00	t	t	DRAW	3	3	3	3	0	0.5	0	0	0	2025-11-01 21:24:00.419542	2025-11-01 21:24:00.43953
cac94792-9442-426e-80c1-58d42fe915a7	638378af-a3a0-4010-96bd-a4fcdf49e841	7712a21a-7fc7-4f07-bfbd-fea814175b7c	f16413de-819b-4c68-b591-7ed59f852bbe	1	2025-09-03 00:00:00	t	t	DRAW	3	3	3	3	0	0.5	0	0	0	2025-11-01 21:24:00.375806	2025-11-01 21:24:00.439471
22db724b-ca1f-4093-b6ea-a8c6ddf2e1b8	e22adc74-dbad-4a52-8822-d41df3c3a7d0	7712a21a-7fc7-4f07-bfbd-fea814175b7c	f16413de-819b-4c68-b591-7ed59f852bbe	1	2025-09-03 00:00:00	t	f	DRAW	3	3	3	3	0	0.5	0	0	0	2025-11-01 21:24:00.380259	2025-11-01 21:24:00.439478
3074e902-7d7c-450e-b0f3-faa499d7bd42	c98f7bfd-cbba-443e-941b-962dd6d40fed	7712a21a-7fc7-4f07-bfbd-fea814175b7c	f16413de-819b-4c68-b591-7ed59f852bbe	1	2025-09-03 00:00:00	f	f	DID_NOT_ATTEND	\N	\N	3	3	0	0.5	0	0	0	2025-11-01 21:24:00.385074	2025-11-01 21:24:00.439484
6b004a81-34c0-41f4-9825-3db42948f626	d83f7d2d-2b57-40bd-80ad-23e4eb03b8a9	7712a21a-7fc7-4f07-bfbd-fea814175b7c	f16413de-819b-4c68-b591-7ed59f852bbe	1	2025-09-03 00:00:00	f	f	DID_NOT_ATTEND	\N	\N	3	3	0	0.5	0	0	0	2025-11-01 21:24:00.391768	2025-11-01 21:24:00.43949
751088d8-8970-4eb8-8e5c-d3757a82639d	2f2fd4c0-7f94-45f7-8b48-0cbecd8e018c	7712a21a-7fc7-4f07-bfbd-fea814175b7c	f16413de-819b-4c68-b591-7ed59f852bbe	1	2025-09-03 00:00:00	t	f	DRAW	3	3	3	3	0	0.5	0	0	0	2025-11-01 21:24:00.395639	2025-11-01 21:24:00.439496
ddcedf8e-0a6c-4d11-8911-f781ceefebe2	b5b71c9b-a553-4db3-8a95-f0e9fc460a17	7712a21a-7fc7-4f07-bfbd-fea814175b7c	f16413de-819b-4c68-b591-7ed59f852bbe	1	2025-09-03 00:00:00	f	f	DID_NOT_ATTEND	\N	\N	3	3	0	0.5	0	0	0	2025-11-01 21:24:00.399277	2025-11-01 21:24:00.439501
561b8a36-3f2f-4635-a02a-7265cfa3b3b0	f18488fd-d485-4bcf-8f0f-0c2f3cfdb025	7712a21a-7fc7-4f07-bfbd-fea814175b7c	f16413de-819b-4c68-b591-7ed59f852bbe	1	2025-09-03 00:00:00	f	f	DID_NOT_ATTEND	\N	\N	3	3	0	0.5	0	0	0	2025-11-01 21:24:00.403131	2025-11-01 21:24:00.439507
59bb91c0-8af3-490b-9004-6c2d4ad6e856	0ae22ab5-d3a0-4b3f-9b8d-ece4224f340a	7712a21a-7fc7-4f07-bfbd-fea814175b7c	f16413de-819b-4c68-b591-7ed59f852bbe	1	2025-09-03 00:00:00	f	f	DID_NOT_ATTEND	\N	\N	3	3	0	0.5	0	0	0	2025-11-01 21:24:00.406982	2025-11-01 21:24:00.439513
19f1d98d-f86c-41dd-879c-1d1f8fa7c010	958f1430-f51c-43a0-871d-e10324151dbc	7712a21a-7fc7-4f07-bfbd-fea814175b7c	f16413de-819b-4c68-b591-7ed59f852bbe	1	2025-09-03 00:00:00	t	f	DRAW	3	3	3	3	0	0.5	0	0	0	2025-11-01 21:24:00.410902	2025-11-01 21:24:00.439518
6655957a-3f0d-4721-b30d-168444b1f9c6	de7929fd-181e-4cbd-b564-b9fd597779c9	7712a21a-7fc7-4f07-bfbd-fea814175b7c	f16413de-819b-4c68-b591-7ed59f852bbe	1	2025-09-03 00:00:00	f	f	DID_NOT_ATTEND	\N	\N	3	3	0	0.5	0	0	0	2025-11-01 21:24:00.415242	2025-11-01 21:24:00.439524
75208f12-435a-468f-adfc-0bed1ad7352a	c976e410-ded4-4cc0-ab2f-53ee8abe2a4d	7712a21a-7fc7-4f07-bfbd-fea814175b7c	f16413de-819b-4c68-b591-7ed59f852bbe	1	2025-09-03 00:00:00	t	t	DRAW	3	3	3	3	0	0.5	0	0	0	2025-11-01 21:24:00.42473	2025-11-01 21:24:00.439535
6bcfd2f2-e996-448a-b92e-5a0b725972d6	fb1a9540-a35f-4789-a917-888bc71c4e5b	7712a21a-7fc7-4f07-bfbd-fea814175b7c	f16413de-819b-4c68-b591-7ed59f852bbe	1	2025-09-03 00:00:00	t	t	DRAW	3	3	3	3	0	0.5	0	0	0	2025-11-01 21:24:00.430208	2025-11-01 21:24:00.439541
fde27aaa-5725-4394-b5e5-3d6056ba8804	d3373e62-c862-48ad-9db6-4cf353621f7e	7712a21a-7fc7-4f07-bfbd-fea814175b7c	f16413de-819b-4c68-b591-7ed59f852bbe	1	2025-09-03 00:00:00	t	t	DRAW	3	3	3	3	0	0.5	0	0	0	2025-11-01 21:24:00.4351	2025-11-01 21:24:00.439546
2926eb22-bfce-43bd-a1bd-6283f211c42b	ac73c184-e192-4aef-9960-40e2d6a9fa5e	de2e7706-10ec-42a7-b94f-e8ac29f7fbe1	f16413de-819b-4c68-b591-7ed59f852bbe	1	2025-10-15 00:00:00	t	f	DRAW	3.170369679905526	3.109506157195786	3	3	0	0.5	0	0	0	2025-11-08 19:39:26.626294	2025-11-08 19:39:26.629357
8f810969-d6e5-4a43-9e7d-576d2e515ac1	f35e24e8-b959-4c58-a22d-24dbd8b3f81c	2061fd5e-1567-4c8d-87af-a240deb4f826	f16413de-819b-4c68-b591-7ed59f852bbe	1	2025-10-01 00:00:00	t	f	LOSS	3.1243626823314976	3.302159127620033	3	3	0	0.5	0	0	0	2025-11-08 19:39:26.649762	2025-11-08 19:39:26.651397
68b9e689-97e9-4e02-acfe-61a90fef9df0	71132191-d659-475e-a74e-4a241e1d8146	7712a21a-7fc7-4f07-bfbd-fea814175b7c	f16413de-819b-4c68-b591-7ed59f852bbe	1	2025-09-03 00:00:00	t	f	DRAW	2.971554449560056	3.0978801342734177	3	3	0	0.5	0	0	0	2025-11-08 19:39:26.670634	2025-11-08 19:39:26.672098
f8092dad-0931-4fc4-97bf-5366504edd97	71132191-d659-475e-a74e-4a241e1d8146	3b9359ce-9703-40ba-b24c-4890af8e64e7	f16413de-819b-4c68-b591-7ed59f852bbe	2	2025-09-17 00:00:00	t	f	LOSS	3.0205306953698177	2.9845698629000483	3	3	0	0.5	0	0	0	2025-11-08 19:39:26.684454	2025-11-08 19:39:26.685855
4cb1b9d5-cc5f-483a-8ae6-496d894f67d4	8496795e-a44d-4a5c-8dd1-8404fa4ff555	e940f144-fd5a-4cf4-b348-decd293ccd1e	f16413de-819b-4c68-b591-7ed59f852bbe	1	2025-09-10 00:00:00	t	f	WIN	3.0846197561532436	3.1284052348353093	3	3	0	0.5	0	0	0	2025-11-08 19:39:26.701392	2025-11-08 19:39:26.702701
c28ba487-7691-4095-868b-b5aab19697ba	8496795e-a44d-4a5c-8dd1-8404fa4ff555	8c910fd4-9582-4c74-863e-40f6bc168bc0	f16413de-819b-4c68-b591-7ed59f852bbe	2	2025-09-24 00:00:00	t	f	LOSS	2.687141552416706	3.132253769523317	3	3	0	0.5	0	0	0	2025-11-08 19:39:26.714522	2025-11-08 19:39:26.715711
c3f0cb38-c73e-4142-9923-3ff056de1491	8496795e-a44d-4a5c-8dd1-8404fa4ff555	6514c434-5c57-4efc-b9f9-710aa9fe061e	f16413de-819b-4c68-b591-7ed59f852bbe	3	2025-10-08 00:00:00	t	f	WIN	2.9567983452541013	3.1516489204186393	3	3	0	0.5	0	0	0	2025-11-08 19:39:26.726991	2025-11-08 19:39:26.733361
2810f0fc-628a-4026-92ef-300481a4853b	8496795e-a44d-4a5c-8dd1-8404fa4ff555	4a640ed2-2210-4f67-9e30-a4ad2230b334	f16413de-819b-4c68-b591-7ed59f852bbe	4	2025-10-29 00:00:00	t	f	LOSS	2.987790657568116	3.425181906288079	3	2.91164840988528	-0.08835159011472005	0.5	0.1	0	0	2025-11-08 19:39:26.76398	2025-11-08 19:39:26.765551
c64cb00e-3475-4501-a205-7eac1ccdc811	034c7caa-ad2f-4e20-b53c-dca203245606	7712a21a-7fc7-4f07-bfbd-fea814175b7c	f16413de-819b-4c68-b591-7ed59f852bbe	1	2025-09-03 00:00:00	t	f	DRAW	3.0978801342734177	2.971554449560056	3	3	0	0.5	0	0	0	2025-11-08 19:39:26.777722	2025-11-08 19:39:26.778962
9507513b-2155-4ae4-a59e-296abb366fbf	034c7caa-ad2f-4e20-b53c-dca203245606	de2e7706-10ec-42a7-b94f-e8ac29f7fbe1	f16413de-819b-4c68-b591-7ed59f852bbe	2	2025-10-15 00:00:00	t	f	DRAW	3.109506157195786	3.170369679905526	3	3	0	0.5	0	0	0	2025-11-08 19:39:26.788987	2025-11-08 19:39:26.790032
f4e8b4e8-c9a6-4715-a161-7fd6ce6f2c02	4326b42b-cf7b-4671-bf7a-f4229d7344b3	8c910fd4-9582-4c74-863e-40f6bc168bc0	f16413de-819b-4c68-b591-7ed59f852bbe	1	2025-09-24 00:00:00	t	f	WIN	3.132253769523317	2.6724162873975863	3	3	0	0.5	0	0	0	2025-11-08 19:39:26.804007	2025-11-08 19:39:26.805079
3ac155e2-154b-4c8d-8fc4-c5a4f3f79c0d	4326b42b-cf7b-4671-bf7a-f4229d7344b3	2061fd5e-1567-4c8d-87af-a240deb4f826	f16413de-819b-4c68-b591-7ed59f852bbe	2	2025-10-01 00:00:00	t	f	WIN	3.302159127620033	3.1243626823314976	3	3	0	0.5	0	0	0	2025-11-08 19:39:26.814333	2025-11-08 19:39:26.815378
688a74da-1dab-4e1b-937d-94eee673cb15	719a45cc-f620-46ec-8996-52c08ccb015d	e940f144-fd5a-4cf4-b348-decd293ccd1e	f16413de-819b-4c68-b591-7ed59f852bbe	1	2025-09-10 00:00:00	t	f	WIN	3.0698944911341237	3.1284052348353093	3	3	0	0.5	0	0	0	2025-11-08 19:39:26.829742	2025-11-08 19:39:26.830801
b7b82a32-2cd3-43f2-89d0-10fc4c5e6e1a	9e1eae73-0ce2-48c9-9b24-268ae4645ed5	8c910fd4-9582-4c74-863e-40f6bc168bc0	f16413de-819b-4c68-b591-7ed59f852bbe	1	2025-09-24 00:00:00	t	f	WIN	3.132253769523317	2.6724162873975863	3	3	0	0.5	0	0	0	2025-11-08 19:39:26.842155	2025-11-08 19:39:26.843164
dd097e8c-47b6-4653-9666-6ff5e7933d00	877347bd-6025-4aa6-ae3e-afdf6376b503	7712a21a-7fc7-4f07-bfbd-fea814175b7c	f16413de-819b-4c68-b591-7ed59f852bbe	1	2025-09-03 00:00:00	t	f	DRAW	3.0978801342734177	2.971554449560056	3	3	0	0.5	0	0	0	2025-11-08 19:39:26.855071	2025-11-08 19:39:26.856059
4781dac0-e421-4e2d-88bc-0fb80f892ffd	877347bd-6025-4aa6-ae3e-afdf6376b503	de2e7706-10ec-42a7-b94f-e8ac29f7fbe1	f16413de-819b-4c68-b591-7ed59f852bbe	2	2025-10-15 00:00:00	t	f	DRAW	3.109506157195786	3.170369679905526	3	3	0	0.5	0	0	0	2025-11-08 19:39:26.865834	2025-11-08 19:39:26.866825
864a396e-22cf-47c9-ae1c-ab022fffb21a	877347bd-6025-4aa6-ae3e-afdf6376b503	0317af43-f94a-46e8-8f99-4b83d5227da2	f16413de-819b-4c68-b591-7ed59f852bbe	3	2025-10-22 00:00:00	t	f	DRAW	3.2437896722649384	3.2680364996768985	3	3	0	0.5	0	0	0	2025-11-08 19:39:26.87561	2025-11-08 19:39:26.876658
893aaee0-0c14-4530-83fc-05d8ab5a8f5e	877347bd-6025-4aa6-ae3e-afdf6376b503	4a640ed2-2210-4f67-9e30-a4ad2230b334	f16413de-819b-4c68-b591-7ed59f852bbe	4	2025-10-29 00:00:00	t	f	LOSS	2.973065392548996	3.425181906288079	3	2.9136344855649936	-0.08636551443500637	0.5	0.1	0	0	2025-11-08 19:39:26.886093	2025-11-08 19:39:26.887108
b89b9838-6c87-42a3-b7c4-f6ac4d0073ea	587d93e7-16c3-4021-be70-8b481636dc0f	e940f144-fd5a-4cf4-b348-decd293ccd1e	f16413de-819b-4c68-b591-7ed59f852bbe	1	2025-09-10 00:00:00	t	f	LOSS	3.1284052348353093	3.0698944911341237	3	3	0	0.5	0	0	0	2025-11-08 19:39:26.898168	2025-11-08 19:39:26.899132
18593a0a-8ce2-4e35-a61a-35ef5436fde2	587d93e7-16c3-4021-be70-8b481636dc0f	2061fd5e-1567-4c8d-87af-a240deb4f826	f16413de-819b-4c68-b591-7ed59f852bbe	2	2025-10-01 00:00:00	t	f	WIN	3.302159127620033	3.1243626823314976	3	3	0	0.5	0	0	0	2025-11-08 19:39:26.907891	2025-11-08 19:39:26.908894
6442e23d-1a73-407b-b9e1-f153cf9c28e3	587d93e7-16c3-4021-be70-8b481636dc0f	4a640ed2-2210-4f67-9e30-a4ad2230b334	f16413de-819b-4c68-b591-7ed59f852bbe	3	2025-10-29 00:00:00	t	f	WIN	3.425181906288079	2.9586711401431613	3	3	0	0.5	0	0	0	2025-11-08 19:39:26.917453	2025-11-08 19:39:26.918391
dcf6ded4-62fc-4547-b81d-91e7de26a845	d171c377-4bc6-4d28-973d-68343b373b58	e940f144-fd5a-4cf4-b348-decd293ccd1e	f16413de-819b-4c68-b591-7ed59f852bbe	1	2025-09-10 00:00:00	t	f	LOSS	3.1284052348353093	3.0698944911341237	3	3	0	0.5	0	0	0	2025-11-08 19:39:26.929454	2025-11-08 19:39:26.930418
\.


--
-- Data for Name: player_season_ratings; Type: TABLE DATA; Schema: public; Owner: futsal_user
--

COPY public.player_season_ratings (id, player_id, season_id, current_rating, matches_completed, matches_attended, rating_locked, last_calculated_at, created_at, updated_at) FROM stdin;
ae2467f0-9bbf-4878-92c1-993cc9498e91	d3373e62-c862-48ad-9db6-4cf353621f7e	f16413de-819b-4c68-b591-7ed59f852bbe	2.5435226171399012	9	5	f	2025-11-01 21:49:15.012906	2025-11-01 21:24:00.433339	2025-11-01 21:49:15.012989
945c2895-af5a-4868-a666-a24884fa4724	587d93e7-16c3-4021-be70-8b481636dc0f	f16413de-819b-4c68-b591-7ed59f852bbe	3	3	3	f	2025-11-08 19:39:26.917482	2025-11-08 19:39:26.88944	2025-11-08 19:39:26.917552
b3e14780-0f12-4a13-9c0c-370fcaf5161d	d171c377-4bc6-4d28-973d-68343b373b58	f16413de-819b-4c68-b591-7ed59f852bbe	3	1	1	t	2025-11-08 19:39:26.929482	2025-11-08 19:39:26.920755	2025-11-08 19:39:26.929555
ae94230c-23ad-44f8-9db0-f19e5928f74c	ac73c184-e192-4aef-9960-40e2d6a9fa5e	f16413de-819b-4c68-b591-7ed59f852bbe	3	1	1	t	2025-11-08 19:39:26.626353	2025-11-08 19:39:26.583513	2025-11-08 19:39:26.626835
377f6903-ea89-4aad-9e44-658e0d97e645	f35e24e8-b959-4c58-a22d-24dbd8b3f81c	f16413de-819b-4c68-b591-7ed59f852bbe	3	1	1	t	2025-11-08 19:39:26.649818	2025-11-08 19:39:26.634662	2025-11-08 19:39:26.649969
7df637d5-8215-4dbf-b00c-baa60016eb21	71132191-d659-475e-a74e-4a241e1d8146	f16413de-819b-4c68-b591-7ed59f852bbe	3	2	2	t	2025-11-08 19:39:26.684498	2025-11-08 19:39:26.655507	2025-11-08 19:39:26.68462
92d62873-2977-4e87-b922-adc982fd52e6	8496795e-a44d-4a5c-8dd1-8404fa4ff555	f16413de-819b-4c68-b591-7ed59f852bbe	2.91164840988528	4	4	f	2025-11-08 19:39:26.764018	2025-11-08 19:39:26.689461	2025-11-08 19:39:26.764312
5a41b2f7-e8cb-4277-8562-d66c9882dcbd	034c7caa-ad2f-4e20-b53c-dca203245606	f16413de-819b-4c68-b591-7ed59f852bbe	3	2	2	t	2025-11-08 19:39:26.789018	2025-11-08 19:39:26.768225	2025-11-08 19:39:26.789109
544e5881-ac58-4147-9220-4abfed08282d	4326b42b-cf7b-4671-bf7a-f4229d7344b3	f16413de-819b-4c68-b591-7ed59f852bbe	3	2	2	t	2025-11-08 19:39:26.814367	2025-11-08 19:39:26.792507	2025-11-08 19:39:26.814451
3ed1dc91-5183-4780-8430-09c0b63a7d17	719a45cc-f620-46ec-8996-52c08ccb015d	f16413de-819b-4c68-b591-7ed59f852bbe	3	1	1	t	2025-11-08 19:39:26.829774	2025-11-08 19:39:26.820039	2025-11-08 19:39:26.829866
2fccd3ea-1ee9-4878-950e-c838caa46ee7	9e1eae73-0ce2-48c9-9b24-268ae4645ed5	f16413de-819b-4c68-b591-7ed59f852bbe	3	1	1	t	2025-11-08 19:39:26.842186	2025-11-08 19:39:26.833083	2025-11-08 19:39:26.842266
c9b6009d-c76f-4cd9-9492-e45dd141f20c	877347bd-6025-4aa6-ae3e-afdf6376b503	f16413de-819b-4c68-b591-7ed59f852bbe	2.9136344855649936	4	4	f	2025-11-08 19:39:26.886136	2025-11-08 19:39:26.845608	2025-11-08 19:39:26.886226
61a36511-cf54-48ca-b7e4-fab9bb5db9d8	839f0f95-bd46-4565-b2bc-9c76f0eec536	f16413de-819b-4c68-b591-7ed59f852bbe	3.0526534768490876	9	5	f	2025-11-01 21:49:14.970123	2025-11-01 21:24:00.366036	2025-11-01 21:49:14.970508
18f2c940-b152-4e2a-a2f2-f86dd4c12b84	638378af-a3a0-4010-96bd-a4fcdf49e841	f16413de-819b-4c68-b591-7ed59f852bbe	3.626908791871957	9	7	f	2025-11-01 21:49:14.974005	2025-11-01 21:24:00.374133	2025-11-01 21:49:14.974198
87690487-bea3-4729-b4c8-753e8c1e6ecf	e22adc74-dbad-4a52-8822-d41df3c3a7d0	f16413de-819b-4c68-b591-7ed59f852bbe	3.1961760939889894	9	9	f	2025-11-01 21:49:14.976622	2025-11-01 21:24:00.378847	2025-11-01 21:49:14.976689
b5ae48bb-99da-4741-bd3c-db8101561837	c98f7bfd-cbba-443e-941b-962dd6d40fed	f16413de-819b-4c68-b591-7ed59f852bbe	3.5038239060110103	9	8	f	2025-11-01 21:49:14.980029	2025-11-01 21:24:00.383146	2025-11-01 21:49:14.980122
4b3bb26f-057a-4b22-8361-a914fc24d703	d83f7d2d-2b57-40bd-80ad-23e4eb03b8a9	f16413de-819b-4c68-b591-7ed59f852bbe	3.486045973848239	9	5	f	2025-11-01 21:49:14.983959	2025-11-01 21:24:00.390227	2025-11-01 21:49:14.984128
e135bec2-0c99-4742-8872-389f1d66cd5f	2f2fd4c0-7f94-45f7-8b48-0cbecd8e018c	f16413de-819b-4c68-b591-7ed59f852bbe	2.9973465231509118	9	7	f	2025-11-01 21:49:14.986965	2025-11-01 21:24:00.394354	2025-11-01 21:49:14.987122
d4e9811d-3dba-4863-b1c5-a4c991a3f24b	b5b71c9b-a553-4db3-8a95-f0e9fc460a17	f16413de-819b-4c68-b591-7ed59f852bbe	2.3999999999999995	9	0	f	2025-11-01 21:49:14.989857	2025-11-01 21:24:00.397926	2025-11-01 21:49:14.990267
ec2d9eb1-8620-45c0-af60-e6680413e699	f18488fd-d485-4bcf-8f0f-0c2f3cfdb025	f16413de-819b-4c68-b591-7ed59f852bbe	2.3999999999999995	9	2	f	2025-11-01 21:49:14.993524	2025-11-01 21:24:00.401769	2025-11-01 21:49:14.993608
c9604d68-dddc-4136-8b9a-48dcf6eeacf4	0ae22ab5-d3a0-4b3f-9b8d-ece4224f340a	f16413de-819b-4c68-b591-7ed59f852bbe	2.3999999999999995	9	3	f	2025-11-01 21:49:14.996192	2025-11-01 21:24:00.405609	2025-11-01 21:49:14.996344
e9c4ec9c-998f-482a-b25d-28678ac174a4	958f1430-f51c-43a0-871d-e10324151dbc	f16413de-819b-4c68-b591-7ed59f852bbe	2.688457557069526	9	5	f	2025-11-01 21:49:14.998718	2025-11-01 21:24:00.409443	2025-11-01 21:49:14.998865
52bd8215-d769-4f54-9305-2549ff64aa77	de7929fd-181e-4cbd-b564-b9fd597779c9	f16413de-819b-4c68-b591-7ed59f852bbe	3.0961760939889897	9	8	f	2025-11-01 21:49:15.001764	2025-11-01 21:24:00.413484	2025-11-01 21:49:15.001824
7d888668-ec3c-4600-acf1-64a5fb133e9d	b982f348-6db4-438a-b106-c74d69e87e2d	f16413de-819b-4c68-b591-7ed59f852bbe	2.7115424429304733	9	4	f	2025-11-01 21:49:15.004722	2025-11-01 21:24:00.418108	2025-11-01 21:49:15.00487
f1b67b3d-b64d-487e-bacc-555ab13de62d	c976e410-ded4-4cc0-ab2f-53ee8abe2a4d	f16413de-819b-4c68-b591-7ed59f852bbe	3.0908691402908137	9	9	f	2025-11-01 21:49:15.007308	2025-11-01 21:24:00.422716	2025-11-01 21:49:15.007384
cf5d4625-adc3-4d46-afa0-c9ab9f3ea406	fb1a9540-a35f-4789-a917-888bc71c4e5b	f16413de-819b-4c68-b591-7ed59f852bbe	3.5091308597091864	9	8	f	2025-11-01 21:49:15.010335	2025-11-01 21:24:00.428212	2025-11-01 21:49:15.010394
\.


--
-- Data for Name: players; Type: TABLE DATA; Schema: public; Owner: futsal_user
--

COPY public.players (id, name, is_active, created_at, updated_at, player_type) FROM stdin;
839f0f95-bd46-4565-b2bc-9c76f0eec536	Lupi	t	2025-11-01 20:51:15.124364	2025-11-01 20:51:15.124381	regular
638378af-a3a0-4010-96bd-a4fcdf49e841	Toni	t	2025-11-01 20:51:25.381692	2025-11-01 20:51:25.381699	regular
e22adc74-dbad-4a52-8822-d41df3c3a7d0	Alexander	t	2025-11-01 20:51:36.569216	2025-11-01 20:51:36.569253	regular
c98f7bfd-cbba-443e-941b-962dd6d40fed	Fon	t	2025-11-01 20:51:40.919283	2025-11-01 20:51:40.919291	regular
d83f7d2d-2b57-40bd-80ad-23e4eb03b8a9	Pakillo	t	2025-11-01 20:51:42.917177	2025-11-01 20:51:42.917185	regular
2f2fd4c0-7f94-45f7-8b48-0cbecd8e018c	Villo	t	2025-11-01 20:51:48.879332	2025-11-01 20:51:48.879345	regular
b5b71c9b-a553-4db3-8a95-f0e9fc460a17	Jose	t	2025-11-01 20:51:52.96016	2025-11-01 20:51:52.960168	regular
f18488fd-d485-4bcf-8f0f-0c2f3cfdb025	Sego	t	2025-11-01 20:52:11.340635	2025-11-01 20:52:11.340644	regular
0ae22ab5-d3a0-4b3f-9b8d-ece4224f340a	Agus	t	2025-11-01 20:52:16.042883	2025-11-01 20:52:16.042889	regular
958f1430-f51c-43a0-871d-e10324151dbc	Bryan	t	2025-11-01 20:52:19.647942	2025-11-01 20:52:19.647951	regular
de7929fd-181e-4cbd-b564-b9fd597779c9	Pablo	t	2025-11-01 20:52:26.072356	2025-11-01 20:52:26.072363	regular
b982f348-6db4-438a-b106-c74d69e87e2d	Pesca	t	2025-11-01 20:52:28.214735	2025-11-01 20:52:28.214742	regular
c976e410-ded4-4cc0-ab2f-53ee8abe2a4d	Raúl	t	2025-11-01 20:52:06.607875	2025-11-01 20:52:06.607883	regular
fb1a9540-a35f-4789-a917-888bc71c4e5b	Rubén	t	2025-11-01 20:51:31.434154	2025-11-01 20:51:31.434162	regular
d3373e62-c862-48ad-9db6-4cf353621f7e	Aleh	t	2025-11-01 20:51:21.970441	2025-11-01 20:51:21.970448	regular
587d93e7-16c3-4021-be70-8b481636dc0f	Nico	t	2025-11-08 18:58:49.094726	2025-11-08 18:58:49.094729	invited
8496795e-a44d-4a5c-8dd1-8404fa4ff555	Joaquín	t	2025-11-08 18:58:57.52014	2025-11-08 18:58:57.520143	invited
877347bd-6025-4aa6-ae3e-afdf6376b503	Miguelillo	t	2025-11-08 18:59:00.725568	2025-11-08 18:59:00.725574	invited
034c7caa-ad2f-4e20-b53c-dca203245606	José Carlos	t	2025-11-08 18:59:18.950146	2025-11-08 18:59:18.950153	invited
ac73c184-e192-4aef-9960-40e2d6a9fa5e	Alberto	t	2025-11-08 18:59:20.751279	2025-11-08 18:59:20.751286	invited
4326b42b-cf7b-4671-bf7a-f4229d7344b3	Juan	t	2025-11-08 18:59:36.654281	2025-11-08 18:59:36.654289	invited
f35e24e8-b959-4c58-a22d-24dbd8b3f81c	Amigo de Juan	t	2025-11-08 18:59:40.080104	2025-11-08 18:59:40.080111	invited
9e1eae73-0ce2-48c9-9b24-268ae4645ed5	Migue García	t	2025-11-08 18:59:56.872405	2025-11-08 18:59:56.872408	invited
71132191-d659-475e-a74e-4a241e1d8146	Carayol	t	2025-11-08 19:00:07.857006	2025-11-08 19:00:07.857012	invited
d171c377-4bc6-4d28-973d-68343b373b58	Álvaro	t	2025-11-08 19:00:16.860842	2025-11-08 19:00:16.860846	invited
719a45cc-f620-46ec-8996-52c08ccb015d	León	t	2025-11-08 19:00:24.436502	2025-11-08 19:00:24.436512	invited
\.


--
-- Data for Name: seasons; Type: TABLE DATA; Schema: public; Owner: futsal_user
--

COPY public.seasons (id, name, year, start_date, end_date, is_active, created_at, updated_at) FROM stdin;
f16413de-819b-4c68-b591-7ed59f852bbe	Entrelosdedos Bouquet 2025	2025	2025-09-03	\N	t	2025-11-01 20:50:51.234692	2025-11-01 20:50:51.234694
\.


--
-- Data for Name: team_players; Type: TABLE DATA; Schema: public; Owner: futsal_user
--

COPY public.team_players (id, team_id, player_id, "position", created_at) FROM stdin;
0b6f8572-e3b7-4ec9-944b-9670ba93b52c	eafa770a-8ac9-4025-b579-a0314bbd1a97	fb1a9540-a35f-4789-a917-888bc71c4e5b	\N	2025-11-01 21:23:40.263045
8ef7e2f2-9596-4276-8557-7fbeb16b91d1	eafa770a-8ac9-4025-b579-a0314bbd1a97	958f1430-f51c-43a0-871d-e10324151dbc	\N	2025-11-01 21:23:40.268989
bc796e87-2605-48c9-86fa-c62970a91f5b	eafa770a-8ac9-4025-b579-a0314bbd1a97	c976e410-ded4-4cc0-ab2f-53ee8abe2a4d	\N	2025-11-01 21:23:40.274715
8247708f-e610-489a-be46-5f086e3954f6	eafa770a-8ac9-4025-b579-a0314bbd1a97	2f2fd4c0-7f94-45f7-8b48-0cbecd8e018c	\N	2025-11-01 21:23:40.279679
6144128b-4e07-46d4-9f7f-fde029e9ab3f	1ab3ea1a-c81d-4423-9f04-167981168861	839f0f95-bd46-4565-b2bc-9c76f0eec536	\N	2025-11-01 21:23:40.293613
0dc6d64f-d4f9-4d1d-901b-fca881a7499c	1ab3ea1a-c81d-4423-9f04-167981168861	638378af-a3a0-4010-96bd-a4fcdf49e841	\N	2025-11-01 21:23:40.298267
217d17cd-211b-46c7-a548-fc2d90d3ab1b	1ab3ea1a-c81d-4423-9f04-167981168861	e22adc74-dbad-4a52-8822-d41df3c3a7d0	\N	2025-11-01 21:23:40.303133
93ef5c10-68c7-4a84-b501-9bb06809bedf	1ab3ea1a-c81d-4423-9f04-167981168861	b982f348-6db4-438a-b106-c74d69e87e2d	\N	2025-11-01 21:23:40.308887
367d791d-9c8d-4165-b303-2bac4e001492	fe361d58-3493-4f98-91fa-90b519eb7e58	fb1a9540-a35f-4789-a917-888bc71c4e5b	\N	2025-11-01 21:27:37.900507
4beaa08b-701b-45fb-9092-d07622569146	fe361d58-3493-4f98-91fa-90b519eb7e58	638378af-a3a0-4010-96bd-a4fcdf49e841	\N	2025-11-01 21:27:37.903631
278f63a9-d590-47de-9cb5-b3c82d1a99bf	fe361d58-3493-4f98-91fa-90b519eb7e58	c976e410-ded4-4cc0-ab2f-53ee8abe2a4d	\N	2025-11-01 21:27:37.906942
a6dbe461-8af4-4dae-b412-0724ee5d12d1	114221e1-0217-4a2c-8402-0f366919c8fd	e22adc74-dbad-4a52-8822-d41df3c3a7d0	\N	2025-11-01 21:27:37.919122
cf6733f8-845c-4aec-9595-8203f59ee293	114221e1-0217-4a2c-8402-0f366919c8fd	c98f7bfd-cbba-443e-941b-962dd6d40fed	\N	2025-11-01 21:27:37.921687
8e5dcda8-4422-47bf-9d56-6e15ed3beb93	114221e1-0217-4a2c-8402-0f366919c8fd	b982f348-6db4-438a-b106-c74d69e87e2d	\N	2025-11-01 21:27:37.924049
a2b23ec5-eaf6-4568-88df-c4fe7f1af80b	f5d89f13-97ba-4fdc-a181-c8a4b6f21e94	fb1a9540-a35f-4789-a917-888bc71c4e5b	\N	2025-11-01 21:29:55.474192
cc12b8b7-f6d9-447d-b1c8-5ed61725005e	f5d89f13-97ba-4fdc-a181-c8a4b6f21e94	e22adc74-dbad-4a52-8822-d41df3c3a7d0	\N	2025-11-01 21:29:55.477283
0c9e0cd5-2fa0-4c56-a3e3-441cbae72502	f5d89f13-97ba-4fdc-a181-c8a4b6f21e94	2f2fd4c0-7f94-45f7-8b48-0cbecd8e018c	\N	2025-11-01 21:29:55.480143
e3044bcc-bcba-4a6a-ac40-900c3e61e028	7573d1ca-36df-40f9-9261-7713ec286b72	d3373e62-c862-48ad-9db6-4cf353621f7e	\N	2025-11-01 21:29:55.492534
1b81f5f9-30b9-407c-97a7-8a48b37f2eb8	7573d1ca-36df-40f9-9261-7713ec286b72	c98f7bfd-cbba-443e-941b-962dd6d40fed	\N	2025-11-01 21:29:55.497064
8c3119f5-0caf-4d85-ab20-f4f93d74bd88	7573d1ca-36df-40f9-9261-7713ec286b72	958f1430-f51c-43a0-871d-e10324151dbc	\N	2025-11-01 21:29:55.50026
6379325b-3f21-4c56-94de-c8abae2a4436	7573d1ca-36df-40f9-9261-7713ec286b72	c976e410-ded4-4cc0-ab2f-53ee8abe2a4d	\N	2025-11-01 21:29:55.503071
195c0edf-7a77-4006-882b-5d1fadb4994c	3e90ffab-57e8-4e72-9a7a-f72cbfc9ba69	c98f7bfd-cbba-443e-941b-962dd6d40fed	\N	2025-11-01 21:32:46.74458
710acd4d-eef1-4a7e-923f-bf58d18db746	3e90ffab-57e8-4e72-9a7a-f72cbfc9ba69	e22adc74-dbad-4a52-8822-d41df3c3a7d0	\N	2025-11-01 21:32:46.748781
bb2e5842-c2da-4136-8dfc-dace684ecda9	3e90ffab-57e8-4e72-9a7a-f72cbfc9ba69	2f2fd4c0-7f94-45f7-8b48-0cbecd8e018c	\N	2025-11-01 21:32:46.752431
97b0f441-e2c5-4145-a89b-ce3fd6c081c5	53d88b18-430f-4823-8387-7e537b296bde	d3373e62-c862-48ad-9db6-4cf353621f7e	\N	2025-11-01 21:32:46.763997
2ac85a03-875f-4be8-8c28-c5cde7a29e59	53d88b18-430f-4823-8387-7e537b296bde	f18488fd-d485-4bcf-8f0f-0c2f3cfdb025	\N	2025-11-01 21:32:46.766831
40e5ee52-6aec-4e01-80f1-1408bcf6e0d3	53d88b18-430f-4823-8387-7e537b296bde	958f1430-f51c-43a0-871d-e10324151dbc	\N	2025-11-01 21:32:46.769044
e3805112-e84c-4629-adc9-4ac4d6fd5a6d	53d88b18-430f-4823-8387-7e537b296bde	c976e410-ded4-4cc0-ab2f-53ee8abe2a4d	\N	2025-11-01 21:32:46.771072
fb5a8423-43c7-47f2-b426-d03c6dca23eb	24f236f5-2fc7-48ec-b8c6-73d3cafc9b0d	d83f7d2d-2b57-40bd-80ad-23e4eb03b8a9	\N	2025-11-01 21:35:22.068118
3ac83181-0162-4cd8-8eac-0ec8bfa59997	24f236f5-2fc7-48ec-b8c6-73d3cafc9b0d	c98f7bfd-cbba-443e-941b-962dd6d40fed	\N	2025-11-01 21:35:22.077397
b013f7fe-6c6e-4a59-8db8-01cd20686078	24f236f5-2fc7-48ec-b8c6-73d3cafc9b0d	638378af-a3a0-4010-96bd-a4fcdf49e841	\N	2025-11-01 21:35:22.082644
666e90ef-f51e-487e-9311-5689d8eae5f9	24f236f5-2fc7-48ec-b8c6-73d3cafc9b0d	e22adc74-dbad-4a52-8822-d41df3c3a7d0	\N	2025-11-01 21:35:22.08791
e01ae5ae-d2ae-4ea9-a70c-5708a9ed83df	91e02f49-5329-4554-9393-5c8d30c1640b	839f0f95-bd46-4565-b2bc-9c76f0eec536	\N	2025-11-01 21:35:22.117022
49dbf132-cb57-4f4a-ac2b-e763d3d6a9b1	91e02f49-5329-4554-9393-5c8d30c1640b	fb1a9540-a35f-4789-a917-888bc71c4e5b	\N	2025-11-01 21:35:22.125229
5649ab0a-5235-4185-b64a-4d12641c8988	91e02f49-5329-4554-9393-5c8d30c1640b	2f2fd4c0-7f94-45f7-8b48-0cbecd8e018c	\N	2025-11-01 21:35:22.128743
c62a19d1-d6cf-46b9-87a5-362f72acd2da	91e02f49-5329-4554-9393-5c8d30c1640b	c976e410-ded4-4cc0-ab2f-53ee8abe2a4d	\N	2025-11-01 21:35:22.130999
d1ca4205-9929-47f7-9fcb-baa83d9913ba	cd847220-bfca-4761-a321-2fbbafa38e06	d83f7d2d-2b57-40bd-80ad-23e4eb03b8a9	\N	2025-11-01 21:38:05.327927
47c5a313-f583-43c7-868e-287a8adf7ef8	cd847220-bfca-4761-a321-2fbbafa38e06	f18488fd-d485-4bcf-8f0f-0c2f3cfdb025	\N	2025-11-01 21:38:05.330852
5a9a5adf-5fca-4bbe-9e84-362ea6c1daf3	cd847220-bfca-4761-a321-2fbbafa38e06	c98f7bfd-cbba-443e-941b-962dd6d40fed	\N	2025-11-01 21:38:05.333462
5235fc17-b65b-44e7-b4c4-83b273862226	cd847220-bfca-4761-a321-2fbbafa38e06	e22adc74-dbad-4a52-8822-d41df3c3a7d0	\N	2025-11-01 21:38:05.335954
06fd57cb-53b2-4e28-a7b7-a8e95c972ce2	cd847220-bfca-4761-a321-2fbbafa38e06	b982f348-6db4-438a-b106-c74d69e87e2d	\N	2025-11-01 21:38:05.338476
95a39336-c27a-48e1-89d8-b86d9b5d7187	3e989c42-47d9-4e74-99f2-bd61549619c4	839f0f95-bd46-4565-b2bc-9c76f0eec536	\N	2025-11-01 21:38:05.347872
87dd6110-f4cd-4055-97fb-29f775a8895b	3e989c42-47d9-4e74-99f2-bd61549619c4	fb1a9540-a35f-4789-a917-888bc71c4e5b	\N	2025-11-01 21:38:05.34972
711899bf-37f2-4977-b27e-ae40a7068132	3e989c42-47d9-4e74-99f2-bd61549619c4	958f1430-f51c-43a0-871d-e10324151dbc	\N	2025-11-01 21:38:05.351468
46fc3641-0ca2-41a3-bee1-aa0cfe9fbe80	3e989c42-47d9-4e74-99f2-bd61549619c4	638378af-a3a0-4010-96bd-a4fcdf49e841	\N	2025-11-01 21:38:05.353256
48058353-cd89-4e46-ad1b-d0eb5f7b9451	3e989c42-47d9-4e74-99f2-bd61549619c4	2f2fd4c0-7f94-45f7-8b48-0cbecd8e018c	\N	2025-11-01 21:38:05.355013
2efcd937-0c1e-4429-af0d-2ff474f70c2b	3e989c42-47d9-4e74-99f2-bd61549619c4	c976e410-ded4-4cc0-ab2f-53ee8abe2a4d	\N	2025-11-01 21:38:05.357225
6cc60319-3678-48d4-9357-de36c4dbec51	b5321620-7ab9-4b40-a174-e3f3bc5e10e2	839f0f95-bd46-4565-b2bc-9c76f0eec536	\N	2025-11-01 21:40:04.649512
87bb7de2-60ab-42f5-b432-82f4fe48a623	b5321620-7ab9-4b40-a174-e3f3bc5e10e2	e22adc74-dbad-4a52-8822-d41df3c3a7d0	\N	2025-11-01 21:40:04.654619
8fe8edf7-178e-43f4-b6ef-7087e139e937	b5321620-7ab9-4b40-a174-e3f3bc5e10e2	fb1a9540-a35f-4789-a917-888bc71c4e5b	\N	2025-11-01 21:40:04.657947
daacd744-5805-4c01-90e7-727a5bd4bd3c	b5321620-7ab9-4b40-a174-e3f3bc5e10e2	638378af-a3a0-4010-96bd-a4fcdf49e841	\N	2025-11-01 21:40:04.660971
d3afb8e2-5045-4a6a-8d5c-95a9487fe14f	b5321620-7ab9-4b40-a174-e3f3bc5e10e2	b982f348-6db4-438a-b106-c74d69e87e2d	\N	2025-11-01 21:40:04.664217
017557a2-b69c-4d81-92e7-d1c0824e71e2	9fded2b1-6747-40e5-9ef6-ac9f472277a4	c98f7bfd-cbba-443e-941b-962dd6d40fed	\N	2025-11-01 21:40:04.671667
25303845-e020-441e-9686-1bd180fa0fc9	9fded2b1-6747-40e5-9ef6-ac9f472277a4	2f2fd4c0-7f94-45f7-8b48-0cbecd8e018c	\N	2025-11-01 21:40:04.674477
de2320f3-660b-4d25-96f8-a570104c9a61	9fded2b1-6747-40e5-9ef6-ac9f472277a4	d83f7d2d-2b57-40bd-80ad-23e4eb03b8a9	\N	2025-11-01 21:40:04.677238
013423c4-2e19-4ff2-a61d-7ea414d8d717	9fded2b1-6747-40e5-9ef6-ac9f472277a4	958f1430-f51c-43a0-871d-e10324151dbc	\N	2025-11-01 21:40:04.680059
ed3cdcdb-167e-4656-9b97-c06f8f060314	9fded2b1-6747-40e5-9ef6-ac9f472277a4	c976e410-ded4-4cc0-ab2f-53ee8abe2a4d	\N	2025-11-01 21:40:04.683206
59295271-831a-4388-a9a3-395caca4b51e	a0b35643-7af6-4cc9-a78d-c6d682eefa93	839f0f95-bd46-4565-b2bc-9c76f0eec536	\N	2025-11-01 21:46:34.947957
af37ce6d-c439-4d30-939d-e477607f999d	a0b35643-7af6-4cc9-a78d-c6d682eefa93	d83f7d2d-2b57-40bd-80ad-23e4eb03b8a9	\N	2025-11-01 21:46:34.950838
8c416725-72f4-4123-8672-23fbd5c65591	a0b35643-7af6-4cc9-a78d-c6d682eefa93	fb1a9540-a35f-4789-a917-888bc71c4e5b	\N	2025-11-01 21:46:34.953158
c8abd08d-afba-4a89-9c84-a04804474428	a0b35643-7af6-4cc9-a78d-c6d682eefa93	e22adc74-dbad-4a52-8822-d41df3c3a7d0	\N	2025-11-01 21:46:34.954671
fe0469fd-33cc-459a-864e-d2bd2376c281	f95a51fa-849a-4f04-a940-908eef1b5b21	c98f7bfd-cbba-443e-941b-962dd6d40fed	\N	2025-11-01 21:46:34.961017
0c5ce0c1-496c-4702-bc9f-2525bcd0351a	f95a51fa-849a-4f04-a940-908eef1b5b21	638378af-a3a0-4010-96bd-a4fcdf49e841	\N	2025-11-01 21:46:34.962818
4f9abe93-45e7-40f9-89e1-e64c9d9721c1	f95a51fa-849a-4f04-a940-908eef1b5b21	2f2fd4c0-7f94-45f7-8b48-0cbecd8e018c	\N	2025-11-01 21:46:34.964756
13fda48c-e603-4f7f-a7e0-be4824c4a630	f95a51fa-849a-4f04-a940-908eef1b5b21	c976e410-ded4-4cc0-ab2f-53ee8abe2a4d	\N	2025-11-01 21:46:34.966388
cff3f289-3228-40bc-892e-8409cdce8d86	e35eda2e-1dc1-4119-a0a9-9cbba53dfac2	fb1a9540-a35f-4789-a917-888bc71c4e5b	\N	2025-11-01 21:48:45.411554
87c1a965-2d73-4e06-bb88-2cf759c95a7d	e35eda2e-1dc1-4119-a0a9-9cbba53dfac2	c98f7bfd-cbba-443e-941b-962dd6d40fed	\N	2025-11-01 21:48:45.416681
accc8c7d-8462-4269-9540-ee3229897738	e35eda2e-1dc1-4119-a0a9-9cbba53dfac2	638378af-a3a0-4010-96bd-a4fcdf49e841	\N	2025-11-01 21:48:45.423012
40a8c992-4c48-4d7b-8c98-f9eaf502a4dd	03d8eb93-2b45-4637-8e78-4871e64ea882	d3373e62-c862-48ad-9db6-4cf353621f7e	\N	2025-11-01 21:48:45.440969
f2aa266f-0d9b-4b93-8801-35b33517fecb	03d8eb93-2b45-4637-8e78-4871e64ea882	e22adc74-dbad-4a52-8822-d41df3c3a7d0	\N	2025-11-01 21:48:45.446075
b59feff5-a9f7-4c40-8008-f4750f079878	03d8eb93-2b45-4637-8e78-4871e64ea882	c976e410-ded4-4cc0-ab2f-53ee8abe2a4d	\N	2025-11-01 21:48:45.450695
615c5a5c-bc60-4536-afa5-16dc9bed6044	e35eda2e-1dc1-4119-a0a9-9cbba53dfac2	d83f7d2d-2b57-40bd-80ad-23e4eb03b8a9	goalkeeper	2025-11-01 21:48:45.403004
b4846942-70c3-42d1-8358-6af4bea64f8c	03d8eb93-2b45-4637-8e78-4871e64ea882	de7929fd-181e-4cbd-b564-b9fd597779c9	goalkeeper	2025-11-01 21:48:45.436435
7658e55c-fb2d-45ff-98d6-0f4863e7f6fb	a0b35643-7af6-4cc9-a78d-c6d682eefa93	de7929fd-181e-4cbd-b564-b9fd597779c9	goalkeeper	2025-11-01 21:46:34.939345
4d615389-93b0-4f9d-b7ee-8c1529877254	b5321620-7ab9-4b40-a174-e3f3bc5e10e2	de7929fd-181e-4cbd-b564-b9fd597779c9	goalkeeper	2025-11-01 21:40:04.639545
d2504497-e048-49ff-a664-9ae9ccb31e42	cd847220-bfca-4761-a321-2fbbafa38e06	0ae22ab5-d3a0-4b3f-9b8d-ece4224f340a	goalkeeper	2025-11-01 21:38:05.318652
fdbec3c6-9b69-40f9-bc56-5a5293d23e5b	3e989c42-47d9-4e74-99f2-bd61549619c4	de7929fd-181e-4cbd-b564-b9fd597779c9	goalkeeper	2025-11-01 21:38:05.345806
bc807d5d-cdef-459f-911f-9de43578467f	91e02f49-5329-4554-9393-5c8d30c1640b	de7929fd-181e-4cbd-b564-b9fd597779c9	goalkeeper	2025-11-01 21:35:22.108274
04a7ea4d-a705-4265-bd93-2eaa9dc85e55	53d88b18-430f-4823-8387-7e537b296bde	0ae22ab5-d3a0-4b3f-9b8d-ece4224f340a	goalkeeper	2025-11-01 21:32:46.76072
ca7f3780-6f77-43ef-bae5-4f19d62a54d3	3e90ffab-57e8-4e72-9a7a-f72cbfc9ba69	de7929fd-181e-4cbd-b564-b9fd597779c9	goalkeeper	2025-11-01 21:32:46.732947
53ea41cf-7367-4061-a665-69188980f81f	f5d89f13-97ba-4fdc-a181-c8a4b6f21e94	0ae22ab5-d3a0-4b3f-9b8d-ece4224f340a	goalkeeper	2025-11-01 21:29:55.468036
6459940a-85b2-440e-8664-262c784fc65e	7573d1ca-36df-40f9-9261-7713ec286b72	de7929fd-181e-4cbd-b564-b9fd597779c9	goalkeeper	2025-11-01 21:29:55.489105
47573f8e-7adc-4c57-b2af-f188075646c1	fe361d58-3493-4f98-91fa-90b519eb7e58	d3373e62-c862-48ad-9db6-4cf353621f7e	goalkeeper	2025-11-01 21:27:37.894203
e5f3196e-87dd-4fb5-83a2-1fe0e88143da	114221e1-0217-4a2c-8402-0f366919c8fd	de7929fd-181e-4cbd-b564-b9fd597779c9	goalkeeper	2025-11-01 21:27:37.915984
48bdf537-8b80-4109-ac92-5f6ff0e5d4a3	eafa770a-8ac9-4025-b579-a0314bbd1a97	d3373e62-c862-48ad-9db6-4cf353621f7e	goalkeeper	2025-11-01 21:23:40.251998
fa7910b0-3fa4-47d7-a68b-d8ce2b18858c	e35eda2e-1dc1-4119-a0a9-9cbba53dfac2	587d93e7-16c3-4021-be70-8b481636dc0f	\N	2025-11-08 19:01:38.867366
7cd77dc1-40d0-4f8d-acc0-1a765a2d5646	03d8eb93-2b45-4637-8e78-4871e64ea882	8496795e-a44d-4a5c-8dd1-8404fa4ff555	\N	2025-11-08 19:02:41.134244
eebbf986-3db6-46d9-a652-57c9df9f35a7	03d8eb93-2b45-4637-8e78-4871e64ea882	877347bd-6025-4aa6-ae3e-afdf6376b503	\N	2025-11-08 19:06:04.842956
c160547a-9a79-4474-bbb2-83a1699e0fb0	f95a51fa-849a-4f04-a940-908eef1b5b21	877347bd-6025-4aa6-ae3e-afdf6376b503	\N	2025-11-08 19:07:19.015474
2436377e-950b-4633-a696-879615ed471e	eafa770a-8ac9-4025-b579-a0314bbd1a97	71132191-d659-475e-a74e-4a241e1d8146	\N	2025-11-08 19:15:06.213269
efd28e5e-a303-4eb0-99a3-76b2d882a038	1ab3ea1a-c81d-4423-9f04-167981168861	877347bd-6025-4aa6-ae3e-afdf6376b503	\N	2025-11-08 19:15:27.331173
1e139347-d2b3-4c4e-a313-42604b43182b	1ab3ea1a-c81d-4423-9f04-167981168861	034c7caa-ad2f-4e20-b53c-dca203245606	goalkeeper	2025-11-08 19:15:32.761071
05ee3936-e791-49df-94fa-dffa309f1493	fe361d58-3493-4f98-91fa-90b519eb7e58	587d93e7-16c3-4021-be70-8b481636dc0f	\N	2025-11-08 19:16:24.980442
efaca489-805e-4dc4-9d32-58e0ab939405	fe361d58-3493-4f98-91fa-90b519eb7e58	d171c377-4bc6-4d28-973d-68343b373b58	\N	2025-11-08 19:16:29.045954
6c7d0cb6-c9c2-428c-8241-fb428e35e8af	114221e1-0217-4a2c-8402-0f366919c8fd	719a45cc-f620-46ec-8996-52c08ccb015d	\N	2025-11-08 19:16:38.659811
3cbb0a01-3eff-4243-be33-19e37e4ac44e	114221e1-0217-4a2c-8402-0f366919c8fd	8496795e-a44d-4a5c-8dd1-8404fa4ff555	\N	2025-11-08 19:16:41.747889
09270822-daf7-41d1-aac0-a10048c34188	f5d89f13-97ba-4fdc-a181-c8a4b6f21e94	71132191-d659-475e-a74e-4a241e1d8146	\N	2025-11-08 19:17:32.254501
b66e3928-3005-4eb7-9040-b22bdd458ca3	3e90ffab-57e8-4e72-9a7a-f72cbfc9ba69	4326b42b-cf7b-4671-bf7a-f4229d7344b3	\N	2025-11-08 19:18:14.544837
0d6e7659-9d28-4f8d-a295-8e90b77a54fd	3e90ffab-57e8-4e72-9a7a-f72cbfc9ba69	9e1eae73-0ce2-48c9-9b24-268ae4645ed5	\N	2025-11-08 19:18:19.790663
d40ca5b0-1565-445a-ade1-67c80dd4a366	53d88b18-430f-4823-8387-7e537b296bde	8496795e-a44d-4a5c-8dd1-8404fa4ff555	\N	2025-11-08 19:18:28.140505
a2563794-d385-437a-b146-40dbe7d8112d	24f236f5-2fc7-48ec-b8c6-73d3cafc9b0d	587d93e7-16c3-4021-be70-8b481636dc0f	\N	2025-11-08 19:18:58.195309
c5144e9b-9157-4dfe-a5a6-726872c29c04	24f236f5-2fc7-48ec-b8c6-73d3cafc9b0d	4326b42b-cf7b-4671-bf7a-f4229d7344b3	\N	2025-11-08 19:19:00.644512
a70d25ce-e189-4dfa-ae22-3e649f46ff98	91e02f49-5329-4554-9393-5c8d30c1640b	f35e24e8-b959-4c58-a22d-24dbd8b3f81c	\N	2025-11-08 19:19:10.0196
ee9589f2-7240-419e-b2d7-2cd1009e88b1	cd847220-bfca-4761-a321-2fbbafa38e06	8496795e-a44d-4a5c-8dd1-8404fa4ff555	\N	2025-11-08 19:20:00.894737
971e0c18-db25-4cca-a840-278d9bacd715	b5321620-7ab9-4b40-a174-e3f3bc5e10e2	ac73c184-e192-4aef-9960-40e2d6a9fa5e	\N	2025-11-08 19:20:48.333686
7e8ba9c0-9507-46bd-81ab-cd83d11d9719	9fded2b1-6747-40e5-9ef6-ac9f472277a4	034c7caa-ad2f-4e20-b53c-dca203245606	goalkeeper	2025-11-08 19:20:57.901211
238324bd-ec52-4b2a-bd54-20a44fc6bebf	9fded2b1-6747-40e5-9ef6-ac9f472277a4	877347bd-6025-4aa6-ae3e-afdf6376b503	\N	2025-11-08 19:21:03.422053
\.


--
-- Data for Name: teams; Type: TABLE DATA; Schema: public; Owner: futsal_user
--

COPY public.teams (id, match_id, name, average_skill_rating, created_at) FROM stdin;
9fded2b1-6747-40e5-9ef6-ac9f472277a4	de2e7706-10ec-42a7-b94f-e8ac29f7fbe1	TEAM_B	3.109506157195786	2025-11-01 21:40:04.669345
b5321620-7ab9-4b40-a174-e3f3bc5e10e2	de2e7706-10ec-42a7-b94f-e8ac29f7fbe1	TEAM_A	3.170369679905526	2025-11-01 21:40:04.617783
24f236f5-2fc7-48ec-b8c6-73d3cafc9b0d	2061fd5e-1567-4c8d-87af-a240deb4f826	TEAM_A	3.302159127620033	2025-11-01 21:35:22.046678
91e02f49-5329-4554-9393-5c8d30c1640b	2061fd5e-1567-4c8d-87af-a240deb4f826	TEAM_B	3.1243626823314976	2025-11-01 21:35:22.102411
1ab3ea1a-c81d-4423-9f04-167981168861	7712a21a-7fc7-4f07-bfbd-fea814175b7c	TEAM_B	3.0978801342734177	2025-11-01 21:23:40.290364
eafa770a-8ac9-4025-b579-a0314bbd1a97	7712a21a-7fc7-4f07-bfbd-fea814175b7c	TEAM_A	2.971554449560056	2025-11-01 21:23:40.230087
7573d1ca-36df-40f9-9261-7713ec286b72	3b9359ce-9703-40ba-b24c-4890af8e64e7	TEAM_B	2.9845698629000483	2025-11-01 21:29:55.485737
f5d89f13-97ba-4fdc-a181-c8a4b6f21e94	3b9359ce-9703-40ba-b24c-4890af8e64e7	TEAM_A	3.0205306953698177	2025-11-01 21:29:55.452958
fe361d58-3493-4f98-91fa-90b519eb7e58	e940f144-fd5a-4cf4-b348-decd293ccd1e	TEAM_A	3.1284052348353093	2025-11-01 21:27:37.870412
3e90ffab-57e8-4e72-9a7a-f72cbfc9ba69	8c910fd4-9582-4c74-863e-40f6bc168bc0	TEAM_A	3.132253769523317	2025-11-01 21:32:46.711113
3e989c42-47d9-4e74-99f2-bd61549619c4	6514c434-5c57-4efc-b9f9-710aa9fe061e	TEAM_B	3.1516489204186393	2025-11-01 21:38:05.343803
cd847220-bfca-4761-a321-2fbbafa38e06	6514c434-5c57-4efc-b9f9-710aa9fe061e	TEAM_A	2.9567983452541013	2025-11-01 21:38:05.292704
e35eda2e-1dc1-4119-a0a9-9cbba53dfac2	4a640ed2-2210-4f67-9e30-a4ad2230b334	TEAM_A	3.425181906288079	2025-11-01 21:48:45.381128
53d88b18-430f-4823-8387-7e537b296bde	8c910fd4-9582-4c74-863e-40f6bc168bc0	TEAM_B	2.6724162873975863	2025-11-01 21:32:46.758013
114221e1-0217-4a2c-8402-0f366919c8fd	e940f144-fd5a-4cf4-b348-decd293ccd1e	TEAM_B	3.0698944911341237	2025-11-01 21:27:37.913542
a0b35643-7af6-4cc9-a78d-c6d682eefa93	0317af43-f94a-46e8-8f99-4b83d5227da2	TEAM_A	3.2680364996768985	2025-11-01 21:46:34.907486
f95a51fa-849a-4f04-a940-908eef1b5b21	0317af43-f94a-46e8-8f99-4b83d5227da2	TEAM_B	3.2437896722649384	2025-11-01 21:46:34.959938
03d8eb93-2b45-4637-8e78-4871e64ea882	4a640ed2-2210-4f67-9e30-a4ad2230b334	TEAM_B	2.9586711401431613	2025-11-01 21:48:45.432863
\.


--
-- Data for Name: third_time_attendances; Type: TABLE DATA; Schema: public; Owner: futsal_user
--

COPY public.third_time_attendances (id, match_id, player_id, attended, created_at) FROM stdin;
ca96619e-8c86-4ecd-9333-c4fb2a4f9e34	7712a21a-7fc7-4f07-bfbd-fea814175b7c	839f0f95-bd46-4565-b2bc-9c76f0eec536	t	2025-11-01 21:24:00.302226
8f39bb65-b5d5-40ee-9ec1-c662a181629f	7712a21a-7fc7-4f07-bfbd-fea814175b7c	638378af-a3a0-4010-96bd-a4fcdf49e841	t	2025-11-01 21:24:00.314172
33505ced-97f9-473e-a8ad-4cf0096795ba	7712a21a-7fc7-4f07-bfbd-fea814175b7c	b982f348-6db4-438a-b106-c74d69e87e2d	t	2025-11-01 21:24:00.316831
61f70477-21b9-4d88-a22e-0849dd88f211	7712a21a-7fc7-4f07-bfbd-fea814175b7c	fb1a9540-a35f-4789-a917-888bc71c4e5b	t	2025-11-01 21:24:00.321007
011e7807-549d-4cb0-8ecb-cf22da44fdec	7712a21a-7fc7-4f07-bfbd-fea814175b7c	d3373e62-c862-48ad-9db6-4cf353621f7e	t	2025-11-01 21:24:00.324679
c70d0dfb-2bb0-4931-9467-235abc9779ac	7712a21a-7fc7-4f07-bfbd-fea814175b7c	c976e410-ded4-4cc0-ab2f-53ee8abe2a4d	t	2025-11-01 21:24:00.327163
724793d3-4819-44c8-9f12-d0135b9496bc	e940f144-fd5a-4cf4-b348-decd293ccd1e	d3373e62-c862-48ad-9db6-4cf353621f7e	t	2025-11-01 21:28:20.031481
38ccb972-df9a-43ae-b0fd-2b63eca73349	e940f144-fd5a-4cf4-b348-decd293ccd1e	fb1a9540-a35f-4789-a917-888bc71c4e5b	t	2025-11-01 21:28:20.047425
b73c5cc2-a009-46f2-96ab-fcb30c883f5c	e940f144-fd5a-4cf4-b348-decd293ccd1e	638378af-a3a0-4010-96bd-a4fcdf49e841	t	2025-11-01 21:28:20.051148
5219fdce-0c2d-40b5-aaf2-15d9c59a77b3	e940f144-fd5a-4cf4-b348-decd293ccd1e	e22adc74-dbad-4a52-8822-d41df3c3a7d0	t	2025-11-01 21:28:20.065458
0d913775-ec59-4b85-8955-1ddfe1cbe45b	e940f144-fd5a-4cf4-b348-decd293ccd1e	b982f348-6db4-438a-b106-c74d69e87e2d	t	2025-11-01 21:28:20.070545
7a2a228d-053f-431e-8271-214dff357a7a	3b9359ce-9703-40ba-b24c-4890af8e64e7	e22adc74-dbad-4a52-8822-d41df3c3a7d0	t	2025-11-01 21:30:53.556607
ad157d3b-6e5e-4a12-83cb-f8d08881f628	3b9359ce-9703-40ba-b24c-4890af8e64e7	de7929fd-181e-4cbd-b564-b9fd597779c9	t	2025-11-01 21:30:53.588871
dd70f434-4731-4d16-b1fd-199c00aa7244	3b9359ce-9703-40ba-b24c-4890af8e64e7	d3373e62-c862-48ad-9db6-4cf353621f7e	t	2025-11-01 21:30:53.591511
e7f172b9-4ad6-4bd1-80d9-c88491b98990	3b9359ce-9703-40ba-b24c-4890af8e64e7	c976e410-ded4-4cc0-ab2f-53ee8abe2a4d	t	2025-11-01 21:30:53.596058
b45e43ce-8419-4a27-8aed-c09aa910e2e0	8c910fd4-9582-4c74-863e-40f6bc168bc0	e22adc74-dbad-4a52-8822-d41df3c3a7d0	t	2025-11-01 21:33:01.737815
46132db2-a122-4404-b87d-a6ce87453442	8c910fd4-9582-4c74-863e-40f6bc168bc0	d3373e62-c862-48ad-9db6-4cf353621f7e	t	2025-11-01 21:33:01.750808
dcc34d91-a823-4f98-ae5d-78f7c811fed5	2061fd5e-1567-4c8d-87af-a240deb4f826	d83f7d2d-2b57-40bd-80ad-23e4eb03b8a9	t	2025-11-01 21:36:28.53194
fde98bb0-28cd-4305-9880-628c291924fa	2061fd5e-1567-4c8d-87af-a240deb4f826	638378af-a3a0-4010-96bd-a4fcdf49e841	t	2025-11-01 21:36:28.570424
edeaba43-7680-40ff-be4e-b829b73e2e69	2061fd5e-1567-4c8d-87af-a240deb4f826	839f0f95-bd46-4565-b2bc-9c76f0eec536	t	2025-11-01 21:36:28.573517
087ae518-6273-4a65-96a4-c5302deaacfa	2061fd5e-1567-4c8d-87af-a240deb4f826	c976e410-ded4-4cc0-ab2f-53ee8abe2a4d	t	2025-11-01 21:36:28.576391
00b1f98e-479b-4c55-a6e8-534b0c7399ce	6514c434-5c57-4efc-b9f9-710aa9fe061e	d83f7d2d-2b57-40bd-80ad-23e4eb03b8a9	t	2025-11-01 21:38:30.97062
8e8a049a-f0d7-4afa-85f9-5b14af02feb7	6514c434-5c57-4efc-b9f9-710aa9fe061e	e22adc74-dbad-4a52-8822-d41df3c3a7d0	t	2025-11-01 21:38:30.98707
7a1e5dfa-8544-4a6f-82b6-fe12da7dbf4a	6514c434-5c57-4efc-b9f9-710aa9fe061e	b982f348-6db4-438a-b106-c74d69e87e2d	t	2025-11-01 21:38:30.99082
54385281-7bb8-4e96-af3b-30ee3f176f9d	6514c434-5c57-4efc-b9f9-710aa9fe061e	839f0f95-bd46-4565-b2bc-9c76f0eec536	t	2025-11-01 21:38:30.996422
fa6612e5-0a1a-464e-aee3-1765c35a6b8b	6514c434-5c57-4efc-b9f9-710aa9fe061e	fb1a9540-a35f-4789-a917-888bc71c4e5b	t	2025-11-01 21:38:30.99933
a33cc3a2-28e1-479c-b830-a1b0c5c406aa	6514c434-5c57-4efc-b9f9-710aa9fe061e	638378af-a3a0-4010-96bd-a4fcdf49e841	t	2025-11-01 21:38:31.002364
1a84f9cf-a5d9-44db-bf04-3593f3be071b	de2e7706-10ec-42a7-b94f-e8ac29f7fbe1	839f0f95-bd46-4565-b2bc-9c76f0eec536	t	2025-11-01 21:40:24.126913
ff30f3d4-add2-4cd0-a832-8d12c371dbd0	de2e7706-10ec-42a7-b94f-e8ac29f7fbe1	638378af-a3a0-4010-96bd-a4fcdf49e841	t	2025-11-01 21:40:24.161863
e933b1f2-16bd-4791-8a48-3b53fb184243	de2e7706-10ec-42a7-b94f-e8ac29f7fbe1	e22adc74-dbad-4a52-8822-d41df3c3a7d0	t	2025-11-01 21:40:24.167132
7203de10-89b1-46d6-a00f-7e76a0ac88c6	4a640ed2-2210-4f67-9e30-a4ad2230b334	638378af-a3a0-4010-96bd-a4fcdf49e841	t	2025-11-01 21:49:14.898266
56df9500-a3f5-4303-adba-7b156041f2d3	4a640ed2-2210-4f67-9e30-a4ad2230b334	d3373e62-c862-48ad-9db6-4cf353621f7e	t	2025-11-01 21:49:14.912391
97a06002-2b34-4d28-8471-cc7e231f48ef	4a640ed2-2210-4f67-9e30-a4ad2230b334	e22adc74-dbad-4a52-8822-d41df3c3a7d0	t	2025-11-01 21:49:14.919521
11507e49-e8b5-45c1-a104-03cff5dbd7d0	6514c434-5c57-4efc-b9f9-710aa9fe061e	d3373e62-c862-48ad-9db6-4cf353621f7e	t	2025-11-01 21:51:57.925433
\.


--
-- Name: alembic_version alembic_version_pkc; Type: CONSTRAINT; Schema: public; Owner: futsal_user
--

ALTER TABLE ONLY public.alembic_version
    ADD CONSTRAINT alembic_version_pkc PRIMARY KEY (version_num);


--
-- Name: match_attendances match_attendances_pkey; Type: CONSTRAINT; Schema: public; Owner: futsal_user
--

ALTER TABLE ONLY public.match_attendances
    ADD CONSTRAINT match_attendances_pkey PRIMARY KEY (id);


--
-- Name: match_results match_results_pkey; Type: CONSTRAINT; Schema: public; Owner: futsal_user
--

ALTER TABLE ONLY public.match_results
    ADD CONSTRAINT match_results_pkey PRIMARY KEY (id);


--
-- Name: matches matches_pkey; Type: CONSTRAINT; Schema: public; Owner: futsal_user
--

ALTER TABLE ONLY public.matches
    ADD CONSTRAINT matches_pkey PRIMARY KEY (id);


--
-- Name: player_match_ratings player_match_ratings_pkey; Type: CONSTRAINT; Schema: public; Owner: futsal_user
--

ALTER TABLE ONLY public.player_match_ratings
    ADD CONSTRAINT player_match_ratings_pkey PRIMARY KEY (id);


--
-- Name: player_season_ratings player_season_ratings_pkey; Type: CONSTRAINT; Schema: public; Owner: futsal_user
--

ALTER TABLE ONLY public.player_season_ratings
    ADD CONSTRAINT player_season_ratings_pkey PRIMARY KEY (id);


--
-- Name: players players_pkey; Type: CONSTRAINT; Schema: public; Owner: futsal_user
--

ALTER TABLE ONLY public.players
    ADD CONSTRAINT players_pkey PRIMARY KEY (id);


--
-- Name: seasons seasons_pkey; Type: CONSTRAINT; Schema: public; Owner: futsal_user
--

ALTER TABLE ONLY public.seasons
    ADD CONSTRAINT seasons_pkey PRIMARY KEY (id);


--
-- Name: team_players team_players_pkey; Type: CONSTRAINT; Schema: public; Owner: futsal_user
--

ALTER TABLE ONLY public.team_players
    ADD CONSTRAINT team_players_pkey PRIMARY KEY (id);


--
-- Name: teams teams_pkey; Type: CONSTRAINT; Schema: public; Owner: futsal_user
--

ALTER TABLE ONLY public.teams
    ADD CONSTRAINT teams_pkey PRIMARY KEY (id);


--
-- Name: third_time_attendances third_time_attendances_pkey; Type: CONSTRAINT; Schema: public; Owner: futsal_user
--

ALTER TABLE ONLY public.third_time_attendances
    ADD CONSTRAINT third_time_attendances_pkey PRIMARY KEY (id);


--
-- Name: match_attendances uq_match_player_attendance; Type: CONSTRAINT; Schema: public; Owner: futsal_user
--

ALTER TABLE ONLY public.match_attendances
    ADD CONSTRAINT uq_match_player_attendance UNIQUE (match_id, player_id);


--
-- Name: third_time_attendances uq_match_player_third_time; Type: CONSTRAINT; Schema: public; Owner: futsal_user
--

ALTER TABLE ONLY public.third_time_attendances
    ADD CONSTRAINT uq_match_player_third_time UNIQUE (match_id, player_id);


--
-- Name: teams uq_match_team_name; Type: CONSTRAINT; Schema: public; Owner: futsal_user
--

ALTER TABLE ONLY public.teams
    ADD CONSTRAINT uq_match_team_name UNIQUE (match_id, name);


--
-- Name: player_match_ratings uq_player_match_rating; Type: CONSTRAINT; Schema: public; Owner: futsal_user
--

ALTER TABLE ONLY public.player_match_ratings
    ADD CONSTRAINT uq_player_match_rating UNIQUE (player_id, match_id);


--
-- Name: player_season_ratings uq_player_season; Type: CONSTRAINT; Schema: public; Owner: futsal_user
--

ALTER TABLE ONLY public.player_season_ratings
    ADD CONSTRAINT uq_player_season UNIQUE (player_id, season_id);


--
-- Name: matches uq_season_match_week; Type: CONSTRAINT; Schema: public; Owner: futsal_user
--

ALTER TABLE ONLY public.matches
    ADD CONSTRAINT uq_season_match_week UNIQUE (season_id, match_week);


--
-- Name: team_players uq_team_player; Type: CONSTRAINT; Schema: public; Owner: futsal_user
--

ALTER TABLE ONLY public.team_players
    ADD CONSTRAINT uq_team_player UNIQUE (team_id, player_id);


--
-- Name: ix_match_attendances_match_id; Type: INDEX; Schema: public; Owner: futsal_user
--

CREATE INDEX ix_match_attendances_match_id ON public.match_attendances USING btree (match_id);


--
-- Name: ix_match_attendances_player_id; Type: INDEX; Schema: public; Owner: futsal_user
--

CREATE INDEX ix_match_attendances_player_id ON public.match_attendances USING btree (player_id);


--
-- Name: ix_match_results_match_id; Type: INDEX; Schema: public; Owner: futsal_user
--

CREATE UNIQUE INDEX ix_match_results_match_id ON public.match_results USING btree (match_id);


--
-- Name: ix_matches_match_date; Type: INDEX; Schema: public; Owner: futsal_user
--

CREATE INDEX ix_matches_match_date ON public.matches USING btree (match_date);


--
-- Name: ix_matches_match_week; Type: INDEX; Schema: public; Owner: futsal_user
--

CREATE INDEX ix_matches_match_week ON public.matches USING btree (match_week);


--
-- Name: ix_matches_season_id; Type: INDEX; Schema: public; Owner: futsal_user
--

CREATE INDEX ix_matches_season_id ON public.matches USING btree (season_id);


--
-- Name: ix_matches_status; Type: INDEX; Schema: public; Owner: futsal_user
--

CREATE INDEX ix_matches_status ON public.matches USING btree (status);


--
-- Name: ix_player_match_ratings_match_date; Type: INDEX; Schema: public; Owner: futsal_user
--

CREATE INDEX ix_player_match_ratings_match_date ON public.player_match_ratings USING btree (match_date);


--
-- Name: ix_player_match_ratings_match_id; Type: INDEX; Schema: public; Owner: futsal_user
--

CREATE INDEX ix_player_match_ratings_match_id ON public.player_match_ratings USING btree (match_id);


--
-- Name: ix_player_match_ratings_player_id; Type: INDEX; Schema: public; Owner: futsal_user
--

CREATE INDEX ix_player_match_ratings_player_id ON public.player_match_ratings USING btree (player_id);


--
-- Name: ix_player_match_ratings_season_id; Type: INDEX; Schema: public; Owner: futsal_user
--

CREATE INDEX ix_player_match_ratings_season_id ON public.player_match_ratings USING btree (season_id);


--
-- Name: ix_player_season_match_date_desc; Type: INDEX; Schema: public; Owner: futsal_user
--

CREATE INDEX ix_player_season_match_date_desc ON public.player_match_ratings USING btree (player_id, season_id, match_date DESC);


--
-- Name: ix_player_season_ratings_player_id; Type: INDEX; Schema: public; Owner: futsal_user
--

CREATE INDEX ix_player_season_ratings_player_id ON public.player_season_ratings USING btree (player_id);


--
-- Name: ix_player_season_ratings_season_id; Type: INDEX; Schema: public; Owner: futsal_user
--

CREATE INDEX ix_player_season_ratings_season_id ON public.player_season_ratings USING btree (season_id);


--
-- Name: ix_players_name; Type: INDEX; Schema: public; Owner: futsal_user
--

CREATE INDEX ix_players_name ON public.players USING btree (name);


--
-- Name: ix_seasons_is_active; Type: INDEX; Schema: public; Owner: futsal_user
--

CREATE INDEX ix_seasons_is_active ON public.seasons USING btree (is_active);


--
-- Name: ix_seasons_year; Type: INDEX; Schema: public; Owner: futsal_user
--

CREATE INDEX ix_seasons_year ON public.seasons USING btree (year);


--
-- Name: ix_team_players_player_id; Type: INDEX; Schema: public; Owner: futsal_user
--

CREATE INDEX ix_team_players_player_id ON public.team_players USING btree (player_id);


--
-- Name: ix_team_players_team_id; Type: INDEX; Schema: public; Owner: futsal_user
--

CREATE INDEX ix_team_players_team_id ON public.team_players USING btree (team_id);


--
-- Name: ix_teams_match_id; Type: INDEX; Schema: public; Owner: futsal_user
--

CREATE INDEX ix_teams_match_id ON public.teams USING btree (match_id);


--
-- Name: ix_third_time_attendances_match_id; Type: INDEX; Schema: public; Owner: futsal_user
--

CREATE INDEX ix_third_time_attendances_match_id ON public.third_time_attendances USING btree (match_id);


--
-- Name: ix_third_time_attendances_player_id; Type: INDEX; Schema: public; Owner: futsal_user
--

CREATE INDEX ix_third_time_attendances_player_id ON public.third_time_attendances USING btree (player_id);


--
-- Name: match_attendances match_attendances_match_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: futsal_user
--

ALTER TABLE ONLY public.match_attendances
    ADD CONSTRAINT match_attendances_match_id_fkey FOREIGN KEY (match_id) REFERENCES public.matches(id) ON DELETE CASCADE;


--
-- Name: match_attendances match_attendances_player_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: futsal_user
--

ALTER TABLE ONLY public.match_attendances
    ADD CONSTRAINT match_attendances_player_id_fkey FOREIGN KEY (player_id) REFERENCES public.players(id) ON DELETE CASCADE;


--
-- Name: match_results match_results_match_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: futsal_user
--

ALTER TABLE ONLY public.match_results
    ADD CONSTRAINT match_results_match_id_fkey FOREIGN KEY (match_id) REFERENCES public.matches(id) ON DELETE CASCADE;


--
-- Name: match_results match_results_team_a_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: futsal_user
--

ALTER TABLE ONLY public.match_results
    ADD CONSTRAINT match_results_team_a_id_fkey FOREIGN KEY (team_a_id) REFERENCES public.teams(id) ON DELETE CASCADE;


--
-- Name: match_results match_results_team_b_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: futsal_user
--

ALTER TABLE ONLY public.match_results
    ADD CONSTRAINT match_results_team_b_id_fkey FOREIGN KEY (team_b_id) REFERENCES public.teams(id) ON DELETE CASCADE;


--
-- Name: match_results match_results_winning_team_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: futsal_user
--

ALTER TABLE ONLY public.match_results
    ADD CONSTRAINT match_results_winning_team_id_fkey FOREIGN KEY (winning_team_id) REFERENCES public.teams(id) ON DELETE CASCADE;


--
-- Name: matches matches_season_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: futsal_user
--

ALTER TABLE ONLY public.matches
    ADD CONSTRAINT matches_season_id_fkey FOREIGN KEY (season_id) REFERENCES public.seasons(id) ON DELETE CASCADE;


--
-- Name: player_match_ratings player_match_ratings_match_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: futsal_user
--

ALTER TABLE ONLY public.player_match_ratings
    ADD CONSTRAINT player_match_ratings_match_id_fkey FOREIGN KEY (match_id) REFERENCES public.matches(id) ON DELETE CASCADE;


--
-- Name: player_match_ratings player_match_ratings_player_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: futsal_user
--

ALTER TABLE ONLY public.player_match_ratings
    ADD CONSTRAINT player_match_ratings_player_id_fkey FOREIGN KEY (player_id) REFERENCES public.players(id) ON DELETE CASCADE;


--
-- Name: player_match_ratings player_match_ratings_season_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: futsal_user
--

ALTER TABLE ONLY public.player_match_ratings
    ADD CONSTRAINT player_match_ratings_season_id_fkey FOREIGN KEY (season_id) REFERENCES public.seasons(id) ON DELETE CASCADE;


--
-- Name: player_season_ratings player_season_ratings_player_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: futsal_user
--

ALTER TABLE ONLY public.player_season_ratings
    ADD CONSTRAINT player_season_ratings_player_id_fkey FOREIGN KEY (player_id) REFERENCES public.players(id) ON DELETE CASCADE;


--
-- Name: player_season_ratings player_season_ratings_season_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: futsal_user
--

ALTER TABLE ONLY public.player_season_ratings
    ADD CONSTRAINT player_season_ratings_season_id_fkey FOREIGN KEY (season_id) REFERENCES public.seasons(id) ON DELETE CASCADE;


--
-- Name: team_players team_players_player_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: futsal_user
--

ALTER TABLE ONLY public.team_players
    ADD CONSTRAINT team_players_player_id_fkey FOREIGN KEY (player_id) REFERENCES public.players(id) ON DELETE CASCADE;


--
-- Name: team_players team_players_team_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: futsal_user
--

ALTER TABLE ONLY public.team_players
    ADD CONSTRAINT team_players_team_id_fkey FOREIGN KEY (team_id) REFERENCES public.teams(id) ON DELETE CASCADE;


--
-- Name: teams teams_match_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: futsal_user
--

ALTER TABLE ONLY public.teams
    ADD CONSTRAINT teams_match_id_fkey FOREIGN KEY (match_id) REFERENCES public.matches(id) ON DELETE CASCADE;


--
-- Name: third_time_attendances third_time_attendances_match_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: futsal_user
--

ALTER TABLE ONLY public.third_time_attendances
    ADD CONSTRAINT third_time_attendances_match_id_fkey FOREIGN KEY (match_id) REFERENCES public.matches(id) ON DELETE CASCADE;


--
-- Name: third_time_attendances third_time_attendances_player_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: futsal_user
--

ALTER TABLE ONLY public.third_time_attendances
    ADD CONSTRAINT third_time_attendances_player_id_fkey FOREIGN KEY (player_id) REFERENCES public.players(id) ON DELETE CASCADE;


--
-- PostgreSQL database dump complete
--

\unrestrict 9HeaLtKlxjKsgRQ4h8nfQHl4lp6AeeKqGBZmewTtW8p09PnPpfYTnpTKUWmSLws

