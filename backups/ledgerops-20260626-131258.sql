--
-- PostgreSQL database dump
--

\restrict 7BLFx7iwC4w9Ni2Tg8aKJGkFbKYxh8bUOubt3z7k7g7D8nVc6JKtbN3EcZTEqHe

-- Dumped from database version 16.14
-- Dumped by pg_dump version 16.14

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
-- Name: role; Type: TYPE; Schema: public; Owner: postgres
--

CREATE TYPE public.role AS ENUM (
    'admin',
    'finance_manager',
    'viewer'
);


ALTER TYPE public.role OWNER TO postgres;

SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: account_preferences; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.account_preferences (
    id integer NOT NULL,
    user_id integer NOT NULL,
    payment_alerts boolean NOT NULL,
    risk_alerts boolean NOT NULL,
    weekly_digest boolean NOT NULL,
    currency character varying(8) NOT NULL,
    timezone character varying(80) NOT NULL
);


ALTER TABLE public.account_preferences OWNER TO postgres;

--
-- Name: account_preferences_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.account_preferences_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.account_preferences_id_seq OWNER TO postgres;

--
-- Name: account_preferences_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.account_preferences_id_seq OWNED BY public.account_preferences.id;


--
-- Name: alembic_version; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.alembic_version (
    version_num character varying(32) NOT NULL
);


ALTER TABLE public.alembic_version OWNER TO postgres;

--
-- Name: alerts; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.alerts (
    id integer NOT NULL,
    user_id integer,
    severity character varying(20) NOT NULL,
    category character varying(60) NOT NULL,
    message text NOT NULL,
    entity_type character varying(40) NOT NULL,
    entity_id integer,
    is_resolved boolean NOT NULL,
    created_at timestamp without time zone NOT NULL
);


ALTER TABLE public.alerts OWNER TO postgres;

--
-- Name: alerts_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.alerts_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.alerts_id_seq OWNER TO postgres;

--
-- Name: alerts_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.alerts_id_seq OWNED BY public.alerts.id;


--
-- Name: audit_logs; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.audit_logs (
    id integer NOT NULL,
    user_id integer,
    workspace_name character varying(160),
    action character varying(100) NOT NULL,
    entity_type character varying(60) NOT NULL,
    entity_id character varying(80),
    outcome character varying(30) NOT NULL,
    details json NOT NULL,
    request_id character varying(80),
    created_at timestamp without time zone NOT NULL
);


ALTER TABLE public.audit_logs OWNER TO postgres;

--
-- Name: audit_logs_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.audit_logs_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.audit_logs_id_seq OWNER TO postgres;

--
-- Name: audit_logs_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.audit_logs_id_seq OWNED BY public.audit_logs.id;


--
-- Name: auth_sessions; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.auth_sessions (
    id integer NOT NULL,
    user_id integer NOT NULL,
    session_id character varying(64) NOT NULL,
    refresh_token_hash character varying(64) NOT NULL,
    expires_at timestamp without time zone NOT NULL,
    revoked_at timestamp without time zone,
    created_at timestamp without time zone NOT NULL
);


ALTER TABLE public.auth_sessions OWNER TO postgres;

--
-- Name: auth_sessions_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.auth_sessions_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.auth_sessions_id_seq OWNER TO postgres;

--
-- Name: auth_sessions_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.auth_sessions_id_seq OWNED BY public.auth_sessions.id;


--
-- Name: compliance_checks; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.compliance_checks (
    id integer NOT NULL,
    user_id integer,
    entity_type character varying(40) NOT NULL,
    entity_id integer,
    score double precision NOT NULL,
    status character varying(30) NOT NULL,
    recommendations json NOT NULL,
    created_at timestamp without time zone NOT NULL
);


ALTER TABLE public.compliance_checks OWNER TO postgres;

--
-- Name: compliance_checks_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.compliance_checks_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.compliance_checks_id_seq OWNER TO postgres;

--
-- Name: compliance_checks_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.compliance_checks_id_seq OWNED BY public.compliance_checks.id;


--
-- Name: customers; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.customers (
    id integer NOT NULL,
    user_id integer,
    name character varying(160) NOT NULL,
    country character varying(80) NOT NULL,
    currency character varying(8) NOT NULL,
    risk_rating character varying(20) NOT NULL,
    avg_delay_days double precision NOT NULL,
    delayed_invoice_count integer NOT NULL,
    kyc_status character varying(40) NOT NULL
);


ALTER TABLE public.customers OWNER TO postgres;

--
-- Name: customers_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.customers_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.customers_id_seq OWNER TO postgres;

--
-- Name: customers_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.customers_id_seq OWNED BY public.customers.id;


--
-- Name: demo_messages; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.demo_messages (
    id integer NOT NULL,
    sender_id integer NOT NULL,
    recipient_id integer NOT NULL,
    kind character varying(24) NOT NULL,
    text text NOT NULL,
    note character varying(240),
    amount_minor integer,
    currency character varying(8),
    status character varying(24) NOT NULL,
    read_at timestamp without time zone,
    created_at timestamp without time zone NOT NULL
);


ALTER TABLE public.demo_messages OWNER TO postgres;

--
-- Name: demo_messages_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.demo_messages_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.demo_messages_id_seq OWNER TO postgres;

--
-- Name: demo_messages_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.demo_messages_id_seq OWNED BY public.demo_messages.id;


--
-- Name: demo_wallets; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.demo_wallets (
    id integer NOT NULL,
    user_id integer NOT NULL,
    balance_minor integer NOT NULL,
    currency character varying(8) NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


ALTER TABLE public.demo_wallets OWNER TO postgres;

--
-- Name: demo_wallets_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.demo_wallets_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.demo_wallets_id_seq OWNER TO postgres;

--
-- Name: demo_wallets_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.demo_wallets_id_seq OWNED BY public.demo_wallets.id;


--
-- Name: email_verification_tokens; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.email_verification_tokens (
    id integer NOT NULL,
    user_id integer NOT NULL,
    token_hash character varying(64) NOT NULL,
    expires_at timestamp without time zone NOT NULL,
    used_at timestamp without time zone,
    created_at timestamp without time zone NOT NULL
);


ALTER TABLE public.email_verification_tokens OWNER TO postgres;

--
-- Name: email_verification_tokens_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.email_verification_tokens_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.email_verification_tokens_id_seq OWNER TO postgres;

--
-- Name: email_verification_tokens_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.email_verification_tokens_id_seq OWNED BY public.email_verification_tokens.id;


--
-- Name: event_logs; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.event_logs (
    id integer NOT NULL,
    user_id integer,
    event_type character varying(80) NOT NULL,
    payload json NOT NULL,
    status character varying(30) NOT NULL,
    attempts integer NOT NULL,
    last_error text,
    created_at timestamp without time zone NOT NULL,
    processed_at timestamp without time zone
);


ALTER TABLE public.event_logs OWNER TO postgres;

--
-- Name: event_logs_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.event_logs_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.event_logs_id_seq OWNER TO postgres;

--
-- Name: event_logs_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.event_logs_id_seq OWNED BY public.event_logs.id;


--
-- Name: fx_rates; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.fx_rates (
    id integer NOT NULL,
    base_currency character varying(8) NOT NULL,
    quote_currency character varying(8) NOT NULL,
    rate double precision NOT NULL,
    volatility_score double precision NOT NULL,
    as_of date NOT NULL
);


ALTER TABLE public.fx_rates OWNER TO postgres;

--
-- Name: fx_rates_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.fx_rates_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.fx_rates_id_seq OWNER TO postgres;

--
-- Name: fx_rates_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.fx_rates_id_seq OWNED BY public.fx_rates.id;


--
-- Name: invoices; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.invoices (
    id integer NOT NULL,
    user_id integer,
    invoice_number character varying(40) NOT NULL,
    customer_id integer NOT NULL,
    amount double precision NOT NULL,
    currency character varying(8) NOT NULL,
    country character varying(80) NOT NULL,
    status character varying(30) NOT NULL,
    issued_at date NOT NULL,
    due_date date NOT NULL,
    paid_at date,
    metadata_json json NOT NULL,
    workspace_key character varying(64) NOT NULL
);


ALTER TABLE public.invoices OWNER TO postgres;

--
-- Name: invoices_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.invoices_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.invoices_id_seq OWNER TO postgres;

--
-- Name: invoices_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.invoices_id_seq OWNED BY public.invoices.id;


--
-- Name: password_reset_tokens; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.password_reset_tokens (
    id integer NOT NULL,
    user_id integer NOT NULL,
    token_hash character varying(64) NOT NULL,
    expires_at timestamp without time zone NOT NULL,
    used_at timestamp without time zone,
    created_at timestamp without time zone NOT NULL
);


ALTER TABLE public.password_reset_tokens OWNER TO postgres;

--
-- Name: password_reset_tokens_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.password_reset_tokens_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.password_reset_tokens_id_seq OWNER TO postgres;

--
-- Name: password_reset_tokens_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.password_reset_tokens_id_seq OWNED BY public.password_reset_tokens.id;


--
-- Name: payment_methods; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.payment_methods (
    id integer NOT NULL,
    user_id integer NOT NULL,
    label character varying(80) NOT NULL,
    cardholder_name character varying(120) NOT NULL,
    brand character varying(30) NOT NULL,
    last_four character varying(4) NOT NULL,
    expiry_month integer NOT NULL,
    expiry_year integer NOT NULL,
    is_default boolean NOT NULL,
    provider_token character varying(160),
    created_at timestamp without time zone NOT NULL
);


ALTER TABLE public.payment_methods OWNER TO postgres;

--
-- Name: payment_methods_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.payment_methods_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.payment_methods_id_seq OWNER TO postgres;

--
-- Name: payment_methods_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.payment_methods_id_seq OWNED BY public.payment_methods.id;


--
-- Name: payments; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.payments (
    id integer NOT NULL,
    user_id integer,
    invoice_id integer,
    customer_id integer NOT NULL,
    amount double precision NOT NULL,
    currency character varying(8) NOT NULL,
    country character varying(80) NOT NULL,
    status character varying(30) NOT NULL,
    rail character varying(40) NOT NULL,
    received_at timestamp without time zone NOT NULL,
    external_ref character varying(80) NOT NULL
);


ALTER TABLE public.payments OWNER TO postgres;

--
-- Name: payments_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.payments_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.payments_id_seq OWNER TO postgres;

--
-- Name: payments_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.payments_id_seq OWNED BY public.payments.id;


--
-- Name: predictions; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.predictions (
    id integer NOT NULL,
    user_id integer,
    prediction_type character varying(40) NOT NULL,
    entity_type character varying(40) NOT NULL,
    entity_id integer,
    score double precision NOT NULL,
    output json NOT NULL,
    created_at timestamp without time zone NOT NULL
);


ALTER TABLE public.predictions OWNER TO postgres;

--
-- Name: predictions_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.predictions_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.predictions_id_seq OWNER TO postgres;

--
-- Name: predictions_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.predictions_id_seq OWNED BY public.predictions.id;


--
-- Name: quick_links; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.quick_links (
    id integer NOT NULL,
    user_id integer NOT NULL,
    public_id character varying(48) NOT NULL,
    title character varying(160) NOT NULL,
    payer_name character varying(160),
    payer_email character varying(255),
    payer_country character varying(2),
    amount double precision NOT NULL,
    currency character varying(8) NOT NULL,
    purpose_code character varying(40) NOT NULL,
    status character varying(24) NOT NULL,
    provider character varying(40) NOT NULL,
    provider_mode character varying(24) NOT NULL,
    checkout_id character varying(160),
    checkout_url text,
    invoice_id integer,
    payment_id integer,
    expires_at timestamp without time zone,
    paid_at timestamp without time zone,
    created_at timestamp without time zone NOT NULL
);


ALTER TABLE public.quick_links OWNER TO postgres;

--
-- Name: quick_links_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.quick_links_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.quick_links_id_seq OWNER TO postgres;

--
-- Name: quick_links_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.quick_links_id_seq OWNED BY public.quick_links.id;


--
-- Name: reconciliation_runs; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.reconciliation_runs (
    id integer NOT NULL,
    user_id integer NOT NULL,
    status character varying(30) NOT NULL,
    checked_count integer NOT NULL,
    matched_count integer NOT NULL,
    exception_count integer NOT NULL,
    exceptions json NOT NULL,
    started_at timestamp without time zone NOT NULL,
    completed_at timestamp without time zone
);


ALTER TABLE public.reconciliation_runs OWNER TO postgres;

--
-- Name: reconciliation_runs_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.reconciliation_runs_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.reconciliation_runs_id_seq OWNER TO postgres;

--
-- Name: reconciliation_runs_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.reconciliation_runs_id_seq OWNED BY public.reconciliation_runs.id;


--
-- Name: refunds; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.refunds (
    id integer NOT NULL,
    user_id integer NOT NULL,
    payment_id integer NOT NULL,
    amount double precision NOT NULL,
    currency character varying(8) NOT NULL,
    reason character varying(80) NOT NULL,
    status character varying(30) NOT NULL,
    provider_ref character varying(160),
    idempotency_key character varying(120) NOT NULL,
    created_at timestamp without time zone NOT NULL,
    completed_at timestamp without time zone
);


ALTER TABLE public.refunds OWNER TO postgres;

--
-- Name: refunds_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.refunds_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.refunds_id_seq OWNER TO postgres;

--
-- Name: refunds_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.refunds_id_seq OWNED BY public.refunds.id;


--
-- Name: transactions; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.transactions (
    id integer NOT NULL,
    user_id integer,
    payment_id integer,
    type character varying(30) NOT NULL,
    amount double precision NOT NULL,
    currency character varying(8) NOT NULL,
    country character varying(80) NOT NULL,
    counterparty character varying(160) NOT NULL,
    risk_score double precision NOT NULL,
    created_at timestamp without time zone NOT NULL
);


ALTER TABLE public.transactions OWNER TO postgres;

--
-- Name: transactions_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.transactions_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.transactions_id_seq OWNER TO postgres;

--
-- Name: transactions_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.transactions_id_seq OWNED BY public.transactions.id;


--
-- Name: users; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.users (
    id integer NOT NULL,
    email character varying(255) NOT NULL,
    name character varying(120) NOT NULL,
    account_type character varying(30) NOT NULL,
    workspace_name character varying(160),
    hashed_password character varying(255) NOT NULL,
    role public.role NOT NULL,
    is_active boolean NOT NULL,
    created_at timestamp without time zone NOT NULL,
    email_verified boolean DEFAULT false NOT NULL,
    mfa_enabled boolean DEFAULT false NOT NULL,
    mfa_secret character varying(64),
    workspace_key character varying(64) NOT NULL
);


ALTER TABLE public.users OWNER TO postgres;

--
-- Name: users_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.users_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.users_id_seq OWNER TO postgres;

--
-- Name: users_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.users_id_seq OWNED BY public.users.id;


--
-- Name: account_preferences id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.account_preferences ALTER COLUMN id SET DEFAULT nextval('public.account_preferences_id_seq'::regclass);


--
-- Name: alerts id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.alerts ALTER COLUMN id SET DEFAULT nextval('public.alerts_id_seq'::regclass);


--
-- Name: audit_logs id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.audit_logs ALTER COLUMN id SET DEFAULT nextval('public.audit_logs_id_seq'::regclass);


--
-- Name: auth_sessions id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.auth_sessions ALTER COLUMN id SET DEFAULT nextval('public.auth_sessions_id_seq'::regclass);


--
-- Name: compliance_checks id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.compliance_checks ALTER COLUMN id SET DEFAULT nextval('public.compliance_checks_id_seq'::regclass);


--
-- Name: customers id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.customers ALTER COLUMN id SET DEFAULT nextval('public.customers_id_seq'::regclass);


--
-- Name: demo_messages id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.demo_messages ALTER COLUMN id SET DEFAULT nextval('public.demo_messages_id_seq'::regclass);


--
-- Name: demo_wallets id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.demo_wallets ALTER COLUMN id SET DEFAULT nextval('public.demo_wallets_id_seq'::regclass);


--
-- Name: email_verification_tokens id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.email_verification_tokens ALTER COLUMN id SET DEFAULT nextval('public.email_verification_tokens_id_seq'::regclass);


--
-- Name: event_logs id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.event_logs ALTER COLUMN id SET DEFAULT nextval('public.event_logs_id_seq'::regclass);


--
-- Name: fx_rates id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.fx_rates ALTER COLUMN id SET DEFAULT nextval('public.fx_rates_id_seq'::regclass);


--
-- Name: invoices id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.invoices ALTER COLUMN id SET DEFAULT nextval('public.invoices_id_seq'::regclass);


--
-- Name: password_reset_tokens id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.password_reset_tokens ALTER COLUMN id SET DEFAULT nextval('public.password_reset_tokens_id_seq'::regclass);


--
-- Name: payment_methods id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.payment_methods ALTER COLUMN id SET DEFAULT nextval('public.payment_methods_id_seq'::regclass);


--
-- Name: payments id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.payments ALTER COLUMN id SET DEFAULT nextval('public.payments_id_seq'::regclass);


--
-- Name: predictions id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.predictions ALTER COLUMN id SET DEFAULT nextval('public.predictions_id_seq'::regclass);


--
-- Name: quick_links id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.quick_links ALTER COLUMN id SET DEFAULT nextval('public.quick_links_id_seq'::regclass);


--
-- Name: reconciliation_runs id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.reconciliation_runs ALTER COLUMN id SET DEFAULT nextval('public.reconciliation_runs_id_seq'::regclass);


--
-- Name: refunds id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.refunds ALTER COLUMN id SET DEFAULT nextval('public.refunds_id_seq'::regclass);


--
-- Name: transactions id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.transactions ALTER COLUMN id SET DEFAULT nextval('public.transactions_id_seq'::regclass);


--
-- Name: users id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.users ALTER COLUMN id SET DEFAULT nextval('public.users_id_seq'::regclass);


--
-- Data for Name: account_preferences; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.account_preferences (id, user_id, payment_alerts, risk_alerts, weekly_digest, currency, timezone) FROM stdin;
2	4	t	t	f	USD	Asia/Kolkata
3	5	t	t	f	USD	Asia/Kolkata
1	1	t	t	f	USD	Asia/Kolkata
\.


--
-- Data for Name: alembic_version; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.alembic_version (version_num) FROM stdin;
20260625_0005
\.


--
-- Data for Name: alerts; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.alerts (id, user_id, severity, category, message, entity_type, entity_id, is_resolved, created_at) FROM stdin;
1	1	high	fraud	JPY payment pattern changed outside normal settlement window.	transaction	8	f	2026-06-17 17:13:15.177351
2	1	medium	fx	EUR exposure rose 18% while volatility is trending upward.	fx	\N	f	2026-06-17 17:13:15.177354
3	1	medium	cash	Delayed invoices could reduce runway below 60 days.	forecast	\N	f	2026-06-17 17:13:15.177355
\.


--
-- Data for Name: audit_logs; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.audit_logs (id, user_id, workspace_name, action, entity_type, entity_id, outcome, details, request_id, created_at) FROM stdin;
4	4	Asha Mehta's demo wallet	quicklink.compliance_preflight	quicklink	4	success	{"status": "simulated_clear", "provider": "demo", "purpose_code": "services"}	\N	2026-06-25 12:27:03.378968
\.


--
-- Data for Name: auth_sessions; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.auth_sessions (id, user_id, session_id, refresh_token_hash, expires_at, revoked_at, created_at) FROM stdin;
1	4	KIjoa50G6xGbMTDKQ5JwKRGS0jaNTuIT	bd0c1537b442c49c84d33423abb1ff8020f3932ea6a7563518239d659d4f1c37	2026-07-02 11:20:46.189915	2026-06-25 11:21:07.621947	2026-06-25 11:20:46.195301
2	4	Yqyr8J-fxPTrKy591OtIdIIVQumSrNGS	61fe472d68bf38f299bce1837112d1c9511bdd2082c0928d5e20c30e8c5f84ce	2026-07-02 11:21:10.45809	\N	2026-06-25 11:21:10.458651
3	4	caKke-rvMwJiQFirPSIhN8Z_Mm7ES-hR	f237320a7a6daca081229fec829659472946aa431a61fd96e67f53011c318347	2026-07-02 12:23:33.057904	\N	2026-06-25 12:23:33.0648
4	4	B_7GWpgpQfwXwUkKK07lO9d5Spcz7JbX	3cf1a0608cdbe2c01d1ffad22d26a1fe754a5bc52ea486d2b13dc0cfa4bac30a	2026-07-02 12:27:03.235226	\N	2026-06-25 12:27:03.239448
5	4	98_JnlTLJcdxJ7URTt1s4vCY7qpK2qlo	0f24d5551b8cd75229feafac446c2c05ce8e0b2987a3fe08c8db2f7a5a00c57f	2026-07-02 17:40:01.096603	\N	2026-06-25 17:40:01.110674
6	4	o9Sjl3cT0E_7AzE_zH4tb8aN9pYliNS8	471fa2125800eb569cafae3b94d8dc6c13678dc239c195c54050366ad99ab3db	2026-07-02 17:44:00.230026	\N	2026-06-25 17:44:00.230974
7	4	O42sl6964yxuy5PEdJtInIBZ9r0b5uBr	26ecc7b6dfcd4abe261411dfeb430ae571a593b35f8f8d8ce8caab6dc9efa79d	2026-07-02 17:46:53.509088	\N	2026-06-25 17:46:53.512908
8	4	3_LJIzPCAnpspeNb4u6BKsRhTZkGjzjo	6567f00707b0a4f4fdc2a200a4bbc6a10c80d3187855d2f8a588e7980d5e7431	2026-07-02 18:02:08.573125	2026-06-26 05:36:10.520672	2026-06-25 18:02:08.57411
41	5	F4tufX_3OXTh7GQ6jPlcNS47e8_2x5Ae	88a51f1fee5fbea73d699e47adf858c85a46117fdeb1bdc216c863f381fec436	2026-07-03 05:36:12.371965	2026-06-26 05:47:32.078971	2026-06-26 05:36:12.373618
42	4	7gidrDdgHKorMuE-mDd2m9rD7wdGijUK	ad84ce81dfcde69b2de1b5712ad2e893f2e8bb6935475f9f21ceeadda01718d2	2026-07-03 05:47:37.162914	2026-06-26 05:55:22.515652	2026-06-26 05:47:37.16353
43	5	VybznNZ5JIvMZQB53xqk7AqlwXR6UVen	f5e1ac4e949018bc7015bb1f0f2e548c20b67f968a51fa2112406183bd268a59	2026-07-03 06:01:19.981624	2026-06-26 06:06:11.793023	2026-06-26 06:01:19.98469
44	5	qVUCluW9xJfCeed8EV7XNDeE8mAM8E3n	592c94d3edc24086bdd057608d98243625bd05739189fd9fb1351c5301581ceb	2026-07-03 06:06:13.734421	2026-06-26 06:19:56.621998	2026-06-26 06:06:13.735074
\.


--
-- Data for Name: compliance_checks; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.compliance_checks (id, user_id, entity_type, entity_id, score, status, recommendations, created_at) FROM stdin;
1	1	payment	\N	67	review	["Collect enhanced due diligence for large transaction.", "Attach current KYC document package."]	2026-06-17 17:20:47.039553
2	1	payment	\N	67	review	["Collect enhanced due diligence for large transaction.", "Attach current KYC document package."]	2026-06-17 17:20:47.044068
3	1	payment	\N	67	review	["Collect enhanced due diligence for large transaction.", "Attach current KYC document package."]	2026-06-17 17:22:06.884033
4	1	payment	\N	67	review	["Collect enhanced due diligence for large transaction.", "Attach current KYC document package."]	2026-06-17 17:22:06.886053
5	1	payment	\N	67	review	["Collect enhanced due diligence for large transaction.", "Attach current KYC document package."]	2026-06-17 18:31:50.830963
6	1	payment	\N	67	review	["Collect enhanced due diligence for large transaction.", "Attach current KYC document package."]	2026-06-17 18:31:50.838722
8	1	payment	\N	67	review	["Collect enhanced due diligence for large transaction.", "Attach current KYC document package."]	2026-06-18 07:31:01.074999
7	1	payment	\N	67	review	["Collect enhanced due diligence for large transaction.", "Attach current KYC document package."]	2026-06-18 07:31:01.073916
9	1	payment	\N	67	review	["Collect enhanced due diligence for large transaction.", "Attach current KYC document package."]	2026-06-18 07:39:50.703676
10	1	payment	\N	67	review	["Collect enhanced due diligence for large transaction.", "Attach current KYC document package."]	2026-06-18 07:39:50.705439
12	4	payment	\N	67	review	["Collect enhanced due diligence for large transaction.", "Attach current KYC document package."]	2026-06-23 06:50:22.729582
11	4	payment	\N	67	review	["Collect enhanced due diligence for large transaction.", "Attach current KYC document package."]	2026-06-23 06:50:22.721795
13	4	payment	\N	67	review	["Collect enhanced due diligence for large transaction.", "Attach current KYC document package."]	2026-06-23 08:32:20.024297
14	4	payment	\N	67	review	["Collect enhanced due diligence for large transaction.", "Attach current KYC document package."]	2026-06-23 08:32:20.0215
15	4	payment	\N	67	review	["Collect enhanced due diligence for large transaction.", "Attach current KYC document package."]	2026-06-23 08:38:47.484031
16	4	payment	\N	67	review	["Collect enhanced due diligence for large transaction.", "Attach current KYC document package."]	2026-06-23 08:38:47.485777
17	4	payment	\N	67	review	["Collect enhanced due diligence for large transaction.", "Attach current KYC document package."]	2026-06-23 08:46:25.008917
18	4	payment	\N	67	review	["Collect enhanced due diligence for large transaction.", "Attach current KYC document package."]	2026-06-23 08:46:25.010116
19	4	payment	\N	67	review	["Collect enhanced due diligence for large transaction.", "Attach current KYC document package."]	2026-06-23 08:46:26.483616
20	4	payment	\N	67	review	["Collect enhanced due diligence for large transaction.", "Attach current KYC document package."]	2026-06-23 08:46:26.48756
22	4	payment	\N	67	review	["Collect enhanced due diligence for large transaction.", "Attach current KYC document package."]	2026-06-23 10:30:16.798633
21	4	payment	\N	67	review	["Collect enhanced due diligence for large transaction.", "Attach current KYC document package."]	2026-06-23 10:30:16.797516
23	1	transaction	17	67	review	["Collect enhanced due diligence for large transaction.", "Attach current KYC document package."]	2026-06-24 07:16:31.01014
24	4	transaction	48	85	pass	["Attach current KYC document package."]	2026-06-24 07:33:16.800864
25	4	transaction	48	85	pass	["Attach current KYC document package."]	2026-06-24 07:33:16.80193
26	4	transaction	48	85	pass	["Attach current KYC document package."]	2026-06-24 07:33:21.842763
27	4	transaction	48	85	pass	["Attach current KYC document package."]	2026-06-24 07:33:21.84367
28	5	transaction	50	85	pass	["Attach current KYC document package."]	2026-06-24 07:56:49.19083
29	5	transaction	50	85	pass	["Attach current KYC document package."]	2026-06-24 07:56:49.195759
30	5	transaction	50	85	pass	["Attach current KYC document package."]	2026-06-24 07:56:57.789702
31	5	transaction	50	85	pass	["Attach current KYC document package."]	2026-06-24 07:56:57.79723
32	5	transaction	50	85	pass	["Attach current KYC document package."]	2026-06-24 09:42:41.488869
33	5	transaction	50	85	pass	["Attach current KYC document package."]	2026-06-24 09:42:41.49006
34	5	transaction	50	85	pass	["Attach current KYC document package."]	2026-06-24 09:57:43.09591
35	5	transaction	50	85	pass	["Attach current KYC document package."]	2026-06-24 09:57:43.097296
36	5	transaction	50	85	pass	["Attach current KYC document package."]	2026-06-24 09:58:05.568993
37	5	transaction	50	85	pass	["Attach current KYC document package."]	2026-06-24 09:58:05.572141
38	5	transaction	50	85	pass	["Attach current KYC document package."]	2026-06-24 09:59:37.025104
39	5	transaction	50	85	pass	["Attach current KYC document package."]	2026-06-24 09:59:37.02747
40	5	transaction	52	85	pass	["Attach current KYC document package."]	2026-06-24 10:09:45.608056
41	5	transaction	52	85	pass	["Attach current KYC document package."]	2026-06-24 10:09:45.609625
42	5	transaction	52	85	pass	["Attach current KYC document package."]	2026-06-24 10:18:51.276522
43	5	transaction	52	85	pass	["Attach current KYC document package."]	2026-06-24 10:18:51.278903
44	5	transaction	52	85	pass	["Attach current KYC document package."]	2026-06-24 10:18:58.750579
45	5	transaction	52	85	pass	["Attach current KYC document package."]	2026-06-24 10:18:58.753588
46	5	transaction	52	85	pass	["Attach current KYC document package."]	2026-06-24 10:19:04.107707
47	5	transaction	52	85	pass	["Attach current KYC document package."]	2026-06-24 10:19:04.109985
48	5	transaction	52	85	pass	["Attach current KYC document package."]	2026-06-24 10:20:13.963037
49	5	transaction	52	85	pass	["Attach current KYC document package."]	2026-06-24 10:20:14.003126
50	5	transaction	52	85	pass	["Attach current KYC document package."]	2026-06-24 10:20:20.042006
51	5	transaction	52	85	pass	["Attach current KYC document package."]	2026-06-24 10:20:20.046792
52	5	transaction	52	85	pass	["Attach current KYC document package."]	2026-06-24 10:28:19.788841
53	5	transaction	52	85	pass	["Attach current KYC document package."]	2026-06-24 10:28:19.791416
54	1	transaction	17	67	review	["Collect enhanced due diligence for large transaction.", "Attach current KYC document package."]	2026-06-24 17:51:52.450856
56	4	transaction	53	85	pass	["Attach current KYC document package."]	2026-06-25 11:23:11.367823
55	4	transaction	53	85	pass	["Attach current KYC document package."]	2026-06-25 11:23:11.367191
57	5	transaction	52	85	pass	["Attach current KYC document package."]	2026-06-26 05:37:05.648633
58	5	transaction	52	85	pass	["Attach current KYC document package."]	2026-06-26 05:37:05.655655
59	5	transaction	52	85	pass	["Attach current KYC document package."]	2026-06-26 05:37:05.659828
60	5	transaction	52	85	pass	["Attach current KYC document package."]	2026-06-26 05:37:05.660864
61	5	transaction	52	85	pass	["Attach current KYC document package."]	2026-06-26 05:37:05.663278
62	5	transaction	52	85	pass	["Attach current KYC document package."]	2026-06-26 05:37:05.680206
64	5	transaction	52	85	pass	["Attach current KYC document package."]	2026-06-26 05:37:05.713797
65	5	transaction	52	85	pass	["Attach current KYC document package."]	2026-06-26 05:37:05.715142
66	5	transaction	52	85	pass	["Attach current KYC document package."]	2026-06-26 05:37:05.716871
63	5	transaction	52	85	pass	["Attach current KYC document package."]	2026-06-26 05:37:05.708202
67	4	transaction	53	85	pass	["Attach current KYC document package."]	2026-06-26 05:47:59.462502
68	4	transaction	53	85	pass	["Attach current KYC document package."]	2026-06-26 05:47:59.46646
69	5	transaction	52	85	pass	["Attach current KYC document package."]	2026-06-26 06:02:20.663528
70	5	transaction	52	85	pass	["Attach current KYC document package."]	2026-06-26 06:02:20.666672
71	5	transaction	52	85	pass	["Attach current KYC document package."]	2026-06-26 06:02:20.667961
72	5	transaction	52	85	pass	["Attach current KYC document package."]	2026-06-26 06:02:20.66882
73	5	transaction	52	85	pass	["Attach current KYC document package."]	2026-06-26 06:02:20.669826
74	5	transaction	52	85	pass	["Attach current KYC document package."]	2026-06-26 06:02:20.696074
75	5	transaction	52	85	pass	["Attach current KYC document package."]	2026-06-26 06:02:20.746075
76	5	transaction	52	85	pass	["Attach current KYC document package."]	2026-06-26 06:02:20.747035
77	5	transaction	52	85	pass	["Attach current KYC document package."]	2026-06-26 06:02:20.754422
78	5	transaction	52	85	pass	["Attach current KYC document package."]	2026-06-26 06:02:24.628005
79	5	transaction	52	85	pass	["Attach current KYC document package."]	2026-06-26 06:02:24.629217
80	5	transaction	52	85	pass	["Attach current KYC document package."]	2026-06-26 06:02:24.630821
81	5	transaction	52	85	pass	["Attach current KYC document package."]	2026-06-26 06:02:24.631738
82	5	transaction	52	85	pass	["Attach current KYC document package."]	2026-06-26 06:02:24.632628
83	5	transaction	52	85	pass	["Attach current KYC document package."]	2026-06-26 06:02:24.662389
84	5	transaction	52	85	pass	["Attach current KYC document package."]	2026-06-26 06:02:24.695363
85	5	transaction	52	85	pass	["Attach current KYC document package."]	2026-06-26 06:02:24.696722
86	5	transaction	52	85	pass	["Attach current KYC document package."]	2026-06-26 06:02:24.705547
87	5	transaction	52	85	pass	["Attach current KYC document package."]	2026-06-26 06:02:24.711834
88	5	transaction	52	85	pass	["Attach current KYC document package."]	2026-06-26 06:19:39.178446
89	5	transaction	52	85	pass	["Attach current KYC document package."]	2026-06-26 06:19:39.179695
\.


--
-- Data for Name: customers; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.customers (id, user_id, name, country, currency, risk_rating, avg_delay_days, delayed_invoice_count, kyc_status) FROM stdin;
1	1	Northstar Robotics	US	USD	Low	2	1	Verified
2	1	Kairo Retail Group	AE	AED	Medium	7	3	Verified
3	1	Blue Harbor GmbH	DE	EUR	Low	1	0	Verified
4	1	Sakura Supply KK	JP	JPY	Medium	9	4	Review
5	1	Atlas Minerals	ZA	ZAR	High	13	5	Review
6	1	Maple Cloud Ltd	CA	CAD	Low	3	1	Verified
15	4	Rohan Kapoor	IN	INR	Low	0	0	Demo verified
16	5	Asha Mehta	IN	INR	Low	0	0	Demo verified
\.


--
-- Data for Name: demo_messages; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.demo_messages (id, sender_id, recipient_id, kind, text, note, amount_minor, currency, status, read_at, created_at) FROM stdin;
11	4	5	text	Hi	\N	\N	\N	sent	2026-06-24 07:55:47.542479	2026-06-23 08:39:32.749994
12	4	5	payment	Paid INR 50.00	Invoice settlement	5000	INR	completed	2026-06-24 07:55:47.542517	2026-06-23 08:39:40.338904
13	5	4	text	Money Back	\N	\N	\N	sent	2026-06-25 11:21:04.677363	2026-06-24 07:56:10.15343
14	5	4	payment	Paid INR 50.00	Invoice settlement	5000	INR	completed	2026-06-25 11:21:04.67738	2026-06-24 07:56:15.17763
15	5	4	request	Requested INR 500.00	Invoice settlement	50000	INR	pending	2026-06-25 11:21:04.677383	2026-06-24 09:42:15.396664
16	5	4	payment	Paid INR 10,000.00	Invoice settlement	1000000	INR	completed	2026-06-25 11:21:04.677385	2026-06-24 09:59:46.998596
\.


--
-- Data for Name: demo_wallets; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.demo_wallets (id, user_id, balance_minor, currency, updated_at) FROM stdin;
1	4	3500000	INR	2026-06-24 09:59:46.98788
2	5	800000	INR	2026-06-24 09:59:46.987885
\.


--
-- Data for Name: email_verification_tokens; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.email_verification_tokens (id, user_id, token_hash, expires_at, used_at, created_at) FROM stdin;
\.


--
-- Data for Name: event_logs; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.event_logs (id, user_id, event_type, payload, status, attempts, last_error, created_at, processed_at) FROM stdin;
1	1	payment_link.created	{"invoice_id": 41, "provider": "Demo wallet provider", "checkout_id": "ig_chk_41_1781767895"}	queued	0	\N	2026-06-18 07:31:35.909121	\N
10	4	wallet.payment.sent	{"recipient_name": "Rohan Kapoor", "recipient_handle": "rohan.demo@pay", "amount": 50.0, "currency": "INR", "note": "Invoice settlement", "rail": "LedgerOps Demo", "payment_method_id": null, "idempotency_key": "513f2502-00c8-45b4-8700-43cb77d60c18", "payment_id": 48, "external_ref": "demo_20260623083940316329_out", "funding_source": "Demo balance"}	queued	0	\N	2026-06-23 08:39:40.341942	\N
11	5	wallet.payment.sent	{"recipient_name": "Asha Mehta", "recipient_handle": "asha.demo@pay", "amount": 50.0, "currency": "INR", "note": "Invoice settlement", "rail": "LedgerOps Demo", "payment_method_id": 2, "idempotency_key": "8373bd27-f79a-42d1-8010-1412a9b2f458", "payment_id": 50, "external_ref": "demo_20260624075615156088_out", "funding_source": "Demo balance"}	queued	0	\N	2026-06-24 07:56:15.180554	\N
12	5	wallet.payment.sent	{"recipient_name": "Asha Mehta", "recipient_handle": "asha.demo@pay", "amount": 10000.0, "currency": "INR", "note": "Invoice settlement", "rail": "LedgerOps Demo", "payment_method_id": 2, "idempotency_key": "67af22ed-c979-467a-aa75-82fd1058b466", "payment_id": 52, "external_ref": "demo_20260624095946981214_out", "funding_source": "Demo balance"}	queued	0	\N	2026-06-24 09:59:47.000374	\N
13	4	quicklink.created	{"quicklink_id": 4, "public_id": "N44urpwJJFJYo6CQ", "checkout_id": "ql_demo_N44urpwJJFJYo6CQ", "amount": 125.0, "currency": "INR"}	queued	0	\N	2026-06-25 12:27:03.383593	\N
14	4	quicklink.paid	{"quicklink_id": 4, "payment_id": 54, "external_ref": "demo_card_N44urpwJJFJYo6CQ"}	queued	0	\N	2026-06-25 12:27:03.472266	\N
\.


--
-- Data for Name: fx_rates; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.fx_rates (id, base_currency, quote_currency, rate, volatility_score, as_of) FROM stdin;
1	EUR	USD	1.0945	34.45	2026-06-17
2	EUR	USD	1.06885	22.44	2026-06-16
3	EUR	USD	1.05318	59.66	2026-06-15
4	EUR	USD	1.09186	76.14	2026-06-14
5	EUR	USD	1.09415	45.51	2026-06-13
6	EUR	USD	1.05875	53.27	2026-06-12
7	EUR	USD	1.09845	45.51	2026-06-11
8	EUR	USD	1.06374	36.68	2026-06-10
9	EUR	USD	1.06172	74.93	2026-06-09
10	EUR	USD	1.10281	72.62	2026-06-08
11	EUR	USD	1.08534	44.25	2026-06-07
12	EUR	USD	1.05904	35.96	2026-06-06
13	EUR	USD	1.10621	65.25	2026-06-05
14	EUR	USD	1.06593	27.9	2026-06-04
15	EUR	USD	1.08364	17.2	2026-06-03
16	EUR	USD	1.09252	65.86	2026-06-02
17	EUR	USD	1.10581	47.16	2026-06-01
18	EUR	USD	1.05979	55.54	2026-05-31
19	EUR	USD	1.10413	22.9	2026-05-30
20	EUR	USD	1.08149	52.04	2026-05-29
21	EUR	USD	1.10508	73.31	2026-05-28
22	EUR	USD	1.09378	57.53	2026-05-27
23	EUR	USD	1.0915	38.33	2026-05-26
24	EUR	USD	1.08927	36.65	2026-05-25
25	EUR	USD	1.10158	41.8	2026-05-24
26	EUR	USD	1.06639	16.23	2026-05-23
27	EUR	USD	1.05414	48.56	2026-05-22
28	EUR	USD	1.08478	12.47	2026-05-21
29	EUR	USD	1.09122	15.89	2026-05-20
30	EUR	USD	1.05664	14.07	2026-05-19
31	GBP	USD	1.24932	45.93	2026-06-17
32	GBP	USD	1.24604	44.04	2026-06-16
33	GBP	USD	1.26247	59.74	2026-06-15
34	GBP	USD	1.28409	50.03	2026-06-14
35	GBP	USD	1.24381	43.22	2026-06-13
36	GBP	USD	1.25414	18.23	2026-06-12
37	GBP	USD	1.27002	35.38	2026-06-11
38	GBP	USD	1.2544	69.01	2026-06-10
39	GBP	USD	1.23191	55.13	2026-06-09
40	GBP	USD	1.26921	16	2026-06-08
41	GBP	USD	1.27438	64.84	2026-06-07
42	GBP	USD	1.23538	24.64	2026-06-06
43	GBP	USD	1.26229	21.25	2026-06-05
44	GBP	USD	1.24006	42.53	2026-06-04
45	GBP	USD	1.28359	16.98	2026-06-03
46	GBP	USD	1.27941	68.49	2026-06-02
47	GBP	USD	1.23467	55.04	2026-06-01
48	GBP	USD	1.26256	12.97	2026-05-31
49	GBP	USD	1.23438	61.74	2026-05-30
50	GBP	USD	1.24339	38.82	2026-05-29
51	GBP	USD	1.25883	69.07	2026-05-28
52	GBP	USD	1.28535	22.87	2026-05-27
53	GBP	USD	1.22864	37.77	2026-05-26
54	GBP	USD	1.28687	63.82	2026-05-25
55	GBP	USD	1.24647	57.98	2026-05-24
56	GBP	USD	1.27452	63.7	2026-05-23
57	GBP	USD	1.2702	44.12	2026-05-22
58	GBP	USD	1.24046	26.37	2026-05-21
59	GBP	USD	1.23218	60.56	2026-05-20
60	GBP	USD	1.23234	32.7	2026-05-19
61	JPY	USD	0.00655	43.47	2026-06-17
62	JPY	USD	0.00684	47.05	2026-06-16
63	JPY	USD	0.00655	45.52	2026-06-15
64	JPY	USD	0.00682	16.52	2026-06-14
65	JPY	USD	0.00656	68.88	2026-06-13
66	JPY	USD	0.00667	74.15	2026-06-12
67	JPY	USD	0.00672	50.21	2026-06-11
68	JPY	USD	0.00655	17.41	2026-06-10
69	JPY	USD	0.00675	49.3	2026-06-09
70	JPY	USD	0.00664	29.21	2026-06-08
71	JPY	USD	0.00676	32.74	2026-06-07
72	JPY	USD	0.00662	20.64	2026-06-06
73	JPY	USD	0.00675	42.18	2026-06-05
74	JPY	USD	0.00684	73.76	2026-06-04
75	JPY	USD	0.00654	53	2026-06-03
76	JPY	USD	0.00672	18.6	2026-06-02
77	JPY	USD	0.00671	45.39	2026-06-01
78	JPY	USD	0.00658	35.03	2026-05-31
79	JPY	USD	0.00656	28.12	2026-05-30
80	JPY	USD	0.00663	40.92	2026-05-29
81	JPY	USD	0.00671	31.97	2026-05-28
82	JPY	USD	0.00686	65.27	2026-05-27
83	JPY	USD	0.00671	56.08	2026-05-26
84	JPY	USD	0.00672	73.5	2026-05-25
85	JPY	USD	0.00657	69.96	2026-05-24
86	JPY	USD	0.00662	70.72	2026-05-23
87	JPY	USD	0.00678	22.26	2026-05-22
88	JPY	USD	0.00663	25.9	2026-05-21
89	JPY	USD	0.00665	57.37	2026-05-20
90	JPY	USD	0.00682	45.36	2026-05-19
91	AED	USD	0.26862	71.94	2026-06-17
92	AED	USD	0.26589	53.86	2026-06-16
93	AED	USD	0.27648	14.91	2026-06-15
94	AED	USD	0.26974	20.63	2026-06-14
95	AED	USD	0.27853	22.66	2026-06-13
96	AED	USD	0.27121	58.57	2026-06-12
97	AED	USD	0.27283	19.38	2026-06-11
98	AED	USD	0.27805	57.61	2026-06-10
99	AED	USD	0.26723	14.38	2026-06-09
100	AED	USD	0.27022	48.47	2026-06-08
101	AED	USD	0.27105	14.76	2026-06-07
102	AED	USD	0.27016	73.58	2026-06-06
103	AED	USD	0.27842	14.63	2026-06-05
104	AED	USD	0.27007	57.02	2026-06-04
105	AED	USD	0.27427	35.34	2026-06-03
106	AED	USD	0.27281	69.73	2026-06-02
107	AED	USD	0.27844	61.47	2026-06-01
108	AED	USD	0.27779	27.62	2026-05-31
109	AED	USD	0.26741	64.79	2026-05-30
110	AED	USD	0.26761	39.21	2026-05-29
111	AED	USD	0.26764	73.02	2026-05-28
112	AED	USD	0.27584	39.17	2026-05-27
113	AED	USD	0.27431	60.51	2026-05-26
114	AED	USD	0.26858	22.51	2026-05-25
115	AED	USD	0.27474	37.25	2026-05-24
116	AED	USD	0.26573	43.07	2026-05-23
117	AED	USD	0.26791	72.62	2026-05-22
118	AED	USD	0.26996	66.16	2026-05-21
119	AED	USD	0.27705	26.71	2026-05-20
120	AED	USD	0.27418	38.3	2026-05-19
121	CAD	USD	0.72192	16.58	2026-06-17
122	CAD	USD	0.73998	35.18	2026-06-16
123	CAD	USD	0.73034	56.85	2026-06-15
124	CAD	USD	0.74254	33.86	2026-06-14
125	CAD	USD	0.71276	69.88	2026-06-13
126	CAD	USD	0.72128	50.32	2026-06-12
127	CAD	USD	0.74765	14.52	2026-06-11
128	CAD	USD	0.73352	34.82	2026-06-10
129	CAD	USD	0.74045	40.8	2026-06-09
130	CAD	USD	0.74767	19.63	2026-06-08
131	CAD	USD	0.74458	24.55	2026-06-07
132	CAD	USD	0.71337	40.78	2026-06-06
133	CAD	USD	0.73073	65.23	2026-06-05
134	CAD	USD	0.73682	74.06	2026-06-04
135	CAD	USD	0.73865	25	2026-06-03
136	CAD	USD	0.72749	74.63	2026-06-02
137	CAD	USD	0.74536	53.13	2026-06-01
138	CAD	USD	0.73596	20.23	2026-05-31
139	CAD	USD	0.7446	45.47	2026-05-30
140	CAD	USD	0.73609	33.53	2026-05-29
141	CAD	USD	0.7372	48.59	2026-05-28
142	CAD	USD	0.71875	55.89	2026-05-27
143	CAD	USD	0.72559	61.38	2026-05-26
144	CAD	USD	0.7181	49.56	2026-05-25
145	CAD	USD	0.72657	67.03	2026-05-24
146	CAD	USD	0.72284	25.87	2026-05-23
147	CAD	USD	0.74043	52.04	2026-05-22
148	CAD	USD	0.72351	41.16	2026-05-21
149	CAD	USD	0.73641	45.74	2026-05-20
150	CAD	USD	0.74072	75.35	2026-05-19
151	ZAR	USD	0.05464	55.48	2026-06-17
152	ZAR	USD	0.05342	55.81	2026-06-16
153	ZAR	USD	0.05432	18.16	2026-06-15
154	ZAR	USD	0.05522	27.5	2026-06-14
155	ZAR	USD	0.05349	65.23	2026-06-13
156	ZAR	USD	0.05305	15.05	2026-06-12
157	ZAR	USD	0.05531	52.34	2026-06-11
158	ZAR	USD	0.05472	42.06	2026-06-10
159	ZAR	USD	0.05504	49.99	2026-06-09
160	ZAR	USD	0.05459	37.34	2026-06-08
161	ZAR	USD	0.05373	21.74	2026-06-07
162	ZAR	USD	0.05451	70.92	2026-06-06
163	ZAR	USD	0.05497	70.44	2026-06-05
164	ZAR	USD	0.05475	26.44	2026-06-04
165	ZAR	USD	0.05482	57.93	2026-06-03
166	ZAR	USD	0.0539	48.79	2026-06-02
167	ZAR	USD	0.05513	20.01	2026-06-01
168	ZAR	USD	0.05301	42.67	2026-05-31
169	ZAR	USD	0.05408	48.89	2026-05-30
170	ZAR	USD	0.05351	61.85	2026-05-29
171	ZAR	USD	0.05384	65.79	2026-05-28
172	ZAR	USD	0.05506	40.16	2026-05-27
173	ZAR	USD	0.0551	41.43	2026-05-26
174	ZAR	USD	0.05308	68.86	2026-05-25
175	ZAR	USD	0.05387	61.62	2026-05-24
176	ZAR	USD	0.05492	30.3	2026-05-23
177	ZAR	USD	0.05475	43.98	2026-05-22
178	ZAR	USD	0.0533	41.03	2026-05-21
179	ZAR	USD	0.05458	27.48	2026-05-20
180	ZAR	USD	0.05356	70.94	2026-05-19
181	USD	USD	0.97903	21.95	2026-06-17
182	USD	USD	0.99415	22.09	2026-06-16
183	USD	USD	0.9857	39.38	2026-06-15
184	USD	USD	0.99154	42.75	2026-06-14
185	USD	USD	0.97811	66.97	2026-06-13
186	USD	USD	0.99447	62.81	2026-06-12
187	USD	USD	1.0223	13.29	2026-06-11
188	USD	USD	1.01903	50	2026-06-10
189	USD	USD	0.99885	74.22	2026-06-09
190	USD	USD	0.98993	37.74	2026-06-08
191	USD	USD	1.01958	67.16	2026-06-07
192	USD	USD	1.00191	60.49	2026-06-06
193	USD	USD	1.01499	71.26	2026-06-05
194	USD	USD	0.99941	30.01	2026-06-04
195	USD	USD	0.99928	37.66	2026-06-03
196	USD	USD	1.00844	64.68	2026-06-02
197	USD	USD	1.01121	67.47	2026-06-01
198	USD	USD	1.02098	76.73	2026-05-31
199	USD	USD	1.00171	71.86	2026-05-30
200	USD	USD	1.00459	55.76	2026-05-29
201	USD	USD	0.9792	40.29	2026-05-28
202	USD	USD	1.01834	23.99	2026-05-27
203	USD	USD	0.98801	33.61	2026-05-26
204	USD	USD	0.99773	34.28	2026-05-25
205	USD	USD	1.01898	30.36	2026-05-24
206	USD	USD	1.02256	39.82	2026-05-23
207	USD	USD	1.01675	43.04	2026-05-22
208	USD	USD	1.01245	15.44	2026-05-21
209	USD	USD	1.0226	26.8	2026-05-20
210	USD	USD	0.97843	75.18	2026-05-19
\.


--
-- Data for Name: invoices; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.invoices (id, user_id, invoice_number, customer_id, amount, currency, country, status, issued_at, due_date, paid_at, metadata_json, workspace_key) FROM stdin;
1	1	INV-2026-1000	1	55613.28	USD	US	pending	2026-06-09	2026-07-09	\N	{"contract": "cross-border services", "payment_terms": "net30"}	683357e85e637ff083537c2c6c763612b41f73124d38ceba
2	1	INV-2026-1001	2	5538.38	AED	AE	paid	2026-06-03	2026-07-03	2026-07-08	{"contract": "cross-border services", "payment_terms": "net30"}	683357e85e637ff083537c2c6c763612b41f73124d38ceba
3	1	INV-2026-1002	3	14872.34	EUR	DE	paid	2026-05-28	2026-06-27	2026-06-27	{"contract": "cross-border services", "payment_terms": "net30"}	683357e85e637ff083537c2c6c763612b41f73124d38ceba
4	1	INV-2026-1003	4	10585.51	JPY	JP	paid	2026-05-22	2026-06-21	2026-07-01	{"contract": "cross-border services", "payment_terms": "net30"}	683357e85e637ff083537c2c6c763612b41f73124d38ceba
5	1	INV-2026-1004	5	11136.16	ZAR	ZA	pending	2026-05-16	2026-06-15	\N	{"contract": "cross-border services", "payment_terms": "net30"}	683357e85e637ff083537c2c6c763612b41f73124d38ceba
6	1	INV-2026-1005	6	22461.86	CAD	CA	paid	2026-05-10	2026-06-09	2026-06-25	{"contract": "cross-border services", "payment_terms": "net30"}	683357e85e637ff083537c2c6c763612b41f73124d38ceba
7	1	INV-2026-1006	1	19705.27	USD	US	paid	2026-05-04	2026-06-03	2026-06-17	{"contract": "cross-border services", "payment_terms": "net30"}	683357e85e637ff083537c2c6c763612b41f73124d38ceba
8	1	INV-2026-1007	2	40110.54	AED	AE	paid	2026-04-28	2026-05-28	2026-06-02	{"contract": "cross-border services", "payment_terms": "net30"}	683357e85e637ff083537c2c6c763612b41f73124d38ceba
9	1	INV-2026-1008	3	65342.8	EUR	DE	pending	2026-04-22	2026-05-22	\N	{"contract": "cross-border services", "payment_terms": "net30"}	683357e85e637ff083537c2c6c763612b41f73124d38ceba
10	1	INV-2026-1009	4	16512.23	JPY	JP	paid	2026-04-16	2026-05-16	2026-05-26	{"contract": "cross-border services", "payment_terms": "net30"}	683357e85e637ff083537c2c6c763612b41f73124d38ceba
11	1	INV-2026-1010	5	16171.58	ZAR	ZA	paid	2026-04-10	2026-05-10	2026-05-17	{"contract": "cross-border services", "payment_terms": "net30"}	683357e85e637ff083537c2c6c763612b41f73124d38ceba
12	1	INV-2026-1011	6	34464.08	CAD	CA	paid	2026-04-04	2026-05-04	2026-05-12	{"contract": "cross-border services", "payment_terms": "net30"}	683357e85e637ff083537c2c6c763612b41f73124d38ceba
13	1	INV-2026-1012	1	52703.67	USD	US	pending	2026-03-29	2026-04-28	\N	{"contract": "cross-border services", "payment_terms": "net30"}	683357e85e637ff083537c2c6c763612b41f73124d38ceba
14	1	INV-2026-1013	2	69280.95	AED	AE	paid	2026-03-23	2026-04-22	2026-05-03	{"contract": "cross-border services", "payment_terms": "net30"}	683357e85e637ff083537c2c6c763612b41f73124d38ceba
15	1	INV-2026-1014	3	82808.93	EUR	DE	paid	2026-03-17	2026-04-16	2026-04-25	{"contract": "cross-border services", "payment_terms": "net30"}	683357e85e637ff083537c2c6c763612b41f73124d38ceba
16	1	INV-2026-1015	4	27394.03	JPY	JP	paid	2026-03-11	2026-04-10	2026-04-26	{"contract": "cross-border services", "payment_terms": "net30"}	683357e85e637ff083537c2c6c763612b41f73124d38ceba
17	1	INV-2026-1016	5	50554.2	ZAR	ZA	pending	2026-03-05	2026-04-04	\N	{"contract": "cross-border services", "payment_terms": "net30"}	683357e85e637ff083537c2c6c763612b41f73124d38ceba
18	1	INV-2026-1017	6	60922.6	CAD	CA	paid	2026-02-27	2026-03-29	2026-03-27	{"contract": "cross-border services", "payment_terms": "net30"}	683357e85e637ff083537c2c6c763612b41f73124d38ceba
19	1	INV-2026-1018	1	66505.07	USD	US	paid	2026-02-21	2026-03-23	2026-03-22	{"contract": "cross-border services", "payment_terms": "net30"}	683357e85e637ff083537c2c6c763612b41f73124d38ceba
20	1	INV-2026-1019	2	74118.42	AED	AE	paid	2026-02-15	2026-03-17	2026-03-26	{"contract": "cross-border services", "payment_terms": "net30"}	683357e85e637ff083537c2c6c763612b41f73124d38ceba
21	1	INV-2026-1020	3	55308.28	EUR	DE	pending	2026-02-09	2026-03-11	\N	{"contract": "cross-border services", "payment_terms": "net30"}	683357e85e637ff083537c2c6c763612b41f73124d38ceba
22	1	INV-2026-1021	4	33233.82	JPY	JP	paid	2026-02-03	2026-03-05	2026-03-13	{"contract": "cross-border services", "payment_terms": "net30"}	683357e85e637ff083537c2c6c763612b41f73124d38ceba
23	1	INV-2026-1022	5	58119.28	ZAR	ZA	paid	2026-01-28	2026-02-27	2026-02-26	{"contract": "cross-border services", "payment_terms": "net30"}	683357e85e637ff083537c2c6c763612b41f73124d38ceba
24	1	INV-2026-1023	6	17447.8	CAD	CA	paid	2026-01-22	2026-02-21	2026-02-25	{"contract": "cross-border services", "payment_terms": "net30"}	683357e85e637ff083537c2c6c763612b41f73124d38ceba
25	1	INV-2026-1024	1	34425.62	USD	US	pending	2026-01-16	2026-02-15	\N	{"contract": "cross-border services", "payment_terms": "net30"}	683357e85e637ff083537c2c6c763612b41f73124d38ceba
26	1	INV-2026-1025	2	84146.15	AED	AE	paid	2026-01-10	2026-02-09	2026-02-23	{"contract": "cross-border services", "payment_terms": "net30"}	683357e85e637ff083537c2c6c763612b41f73124d38ceba
27	1	INV-2026-1026	3	29929.04	EUR	DE	paid	2026-01-04	2026-02-03	2026-02-01	{"contract": "cross-border services", "payment_terms": "net30"}	683357e85e637ff083537c2c6c763612b41f73124d38ceba
28	1	INV-2026-1027	4	69111.23	JPY	JP	paid	2025-12-29	2026-01-28	2026-02-06	{"contract": "cross-border services", "payment_terms": "net30"}	683357e85e637ff083537c2c6c763612b41f73124d38ceba
29	1	INV-2026-1028	5	20695.1	ZAR	ZA	pending	2025-12-23	2026-01-22	\N	{"contract": "cross-border services", "payment_terms": "net30"}	683357e85e637ff083537c2c6c763612b41f73124d38ceba
30	1	INV-2026-1029	6	80347.14	CAD	CA	paid	2025-12-17	2026-01-16	2026-01-23	{"contract": "cross-border services", "payment_terms": "net30"}	683357e85e637ff083537c2c6c763612b41f73124d38ceba
31	1	INV-2026-1030	1	44187.35	USD	US	paid	2025-12-11	2026-01-10	2026-01-21	{"contract": "cross-border services", "payment_terms": "net30"}	683357e85e637ff083537c2c6c763612b41f73124d38ceba
32	1	INV-2026-1031	2	14879.87	AED	AE	paid	2025-12-05	2026-01-04	2026-01-18	{"contract": "cross-border services", "payment_terms": "net30"}	683357e85e637ff083537c2c6c763612b41f73124d38ceba
33	1	INV-2026-1032	3	64381.63	EUR	DE	pending	2025-11-29	2025-12-29	\N	{"contract": "cross-border services", "payment_terms": "net30"}	683357e85e637ff083537c2c6c763612b41f73124d38ceba
34	1	INV-2026-1033	4	38417.36	JPY	JP	paid	2025-11-23	2025-12-23	2026-01-07	{"contract": "cross-border services", "payment_terms": "net30"}	683357e85e637ff083537c2c6c763612b41f73124d38ceba
35	1	INV-2026-1034	5	21374.64	ZAR	ZA	paid	2025-11-17	2025-12-17	2025-12-18	{"contract": "cross-border services", "payment_terms": "net30"}	683357e85e637ff083537c2c6c763612b41f73124d38ceba
36	1	INV-2026-1035	6	10909.12	CAD	CA	paid	2025-11-11	2025-12-11	2025-12-09	{"contract": "cross-border services", "payment_terms": "net30"}	683357e85e637ff083537c2c6c763612b41f73124d38ceba
37	1	INV-2026-1036	1	15956.57	USD	US	pending	2025-11-05	2025-12-05	\N	{"contract": "cross-border services", "payment_terms": "net30"}	683357e85e637ff083537c2c6c763612b41f73124d38ceba
38	1	INV-2026-1037	2	16538.53	AED	AE	paid	2025-10-30	2025-11-29	2025-12-09	{"contract": "cross-border services", "payment_terms": "net30"}	683357e85e637ff083537c2c6c763612b41f73124d38ceba
39	1	INV-2026-1038	3	34858.54	EUR	DE	paid	2025-10-24	2025-11-23	2025-12-09	{"contract": "cross-border services", "payment_terms": "net30"}	683357e85e637ff083537c2c6c763612b41f73124d38ceba
40	1	INV-2026-1039	4	23990.25	JPY	JP	paid	2025-10-18	2025-11-17	2025-12-01	{"contract": "cross-border services", "payment_terms": "net30"}	683357e85e637ff083537c2c6c763612b41f73124d38ceba
41	1	INV-2026-1040	5	58943.1	ZAR	ZA	pending	2025-10-12	2025-11-11	\N	{"contract": "cross-border services", "payment_terms": "net30"}	683357e85e637ff083537c2c6c763612b41f73124d38ceba
42	1	INV-2026-1041	6	12835.97	CAD	CA	paid	2025-10-06	2025-11-05	2025-11-19	{"contract": "cross-border services", "payment_terms": "net30"}	683357e85e637ff083537c2c6c763612b41f73124d38ceba
\.


--
-- Data for Name: password_reset_tokens; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.password_reset_tokens (id, user_id, token_hash, expires_at, used_at, created_at) FROM stdin;
\.


--
-- Data for Name: payment_methods; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.payment_methods (id, user_id, label, cardholder_name, brand, last_four, expiry_month, expiry_year, is_default, provider_token, created_at) FROM stdin;
2	5	Demo card	Rohan Kapoor	Visa	1881	12	2029	t	\N	2026-06-23 06:44:41.317507
3	4	Corporate Travel	Avery Shah	Visa	4242	12	2029	t	\N	2026-06-23 08:04:40.430466
\.


--
-- Data for Name: payments; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.payments (id, user_id, invoice_id, customer_id, amount, currency, country, status, rail, received_at, external_ref) FROM stdin;
1	1	2	2	5538.38	AED	AE	settled	SWIFT	2026-07-08 11:00:00	pay_00001
2	1	3	3	14872.34	EUR	DE	settled	SWIFT	2026-06-27 18:00:00	pay_00002
3	1	4	4	10585.51	JPY	JP	settled	SWIFT	2026-07-01 08:00:00	pay_00003
4	1	6	6	22461.86	CAD	CA	settled	ACH	2026-06-25 08:00:00	pay_00005
5	1	7	1	19705.27	USD	US	settled	ACH	2026-06-17 14:00:00	pay_00006
6	1	8	2	40110.54	AED	AE	settled	SWIFT	2026-06-02 20:00:00	pay_00007
7	1	10	4	16512.23	JPY	JP	settled	SWIFT	2026-05-26 13:00:00	pay_00009
8	1	11	5	16171.58	ZAR	ZA	settled	SWIFT	2026-05-17 09:00:00	pay_00010
9	1	12	6	34464.08	CAD	CA	settled	ACH	2026-05-12 21:00:00	pay_00011
10	1	14	2	69280.95	AED	AE	settled	SWIFT	2026-05-03 16:00:00	pay_00013
11	1	15	3	82808.93	EUR	DE	settled	SWIFT	2026-04-25 09:00:00	pay_00014
12	1	16	4	27394.03	JPY	JP	settled	SWIFT	2026-04-26 22:00:00	pay_00015
13	1	18	6	60922.6	CAD	CA	settled	ACH	2026-03-27 18:00:00	pay_00017
14	1	19	1	66505.07	USD	US	settled	ACH	2026-03-22 21:00:00	pay_00018
15	1	20	2	74118.42	AED	AE	settled	SWIFT	2026-03-26 12:00:00	pay_00019
16	1	22	4	33233.82	JPY	JP	settled	SWIFT	2026-03-13 13:00:00	pay_00021
17	1	23	5	58119.28	ZAR	ZA	settled	SWIFT	2026-02-26 17:00:00	pay_00022
18	1	24	6	17447.8	CAD	CA	settled	ACH	2026-02-25 10:00:00	pay_00023
19	1	26	2	84146.15	AED	AE	settled	SWIFT	2026-02-23 11:00:00	pay_00025
20	1	27	3	29929.04	EUR	DE	settled	SWIFT	2026-02-01 11:00:00	pay_00026
21	1	28	4	69111.23	JPY	JP	settled	SWIFT	2026-02-06 12:00:00	pay_00027
22	1	30	6	80347.14	CAD	CA	settled	ACH	2026-01-23 11:00:00	pay_00029
23	1	31	1	44187.35	USD	US	settled	ACH	2026-01-21 10:00:00	pay_00030
24	1	32	2	14879.87	AED	AE	settled	SWIFT	2026-01-18 16:00:00	pay_00031
25	1	34	4	38417.36	JPY	JP	settled	SWIFT	2026-01-07 14:00:00	pay_00033
26	1	35	5	21374.64	ZAR	ZA	settled	SWIFT	2025-12-18 16:00:00	pay_00034
27	1	36	6	10909.12	CAD	CA	settled	ACH	2025-12-09 21:00:00	pay_00035
28	1	38	2	16538.53	AED	AE	settled	SWIFT	2025-12-09 17:00:00	pay_00037
29	1	39	3	34858.54	EUR	DE	settled	SWIFT	2025-12-09 15:00:00	pay_00038
30	1	40	4	23990.25	JPY	JP	settled	SWIFT	2025-12-01 21:00:00	pay_00039
31	1	42	6	12835.97	CAD	CA	settled	ACH	2025-11-19 20:00:00	pay_00041
48	4	\N	15	50	INR	IN	settled	LedgerOps Demo	2026-06-23 08:39:40.333976	demo_20260623083940316329_out
49	5	\N	16	50	INR	IN	settled	LedgerOps Demo	2026-06-23 08:39:40.33398	demo_20260623083940316329_in
50	5	\N	16	50	INR	IN	settled	LedgerOps Demo	2026-06-24 07:56:15.167478	demo_20260624075615156088_out
51	4	\N	15	50	INR	IN	settled	LedgerOps Demo	2026-06-24 07:56:15.167484	demo_20260624075615156088_in
52	5	\N	16	10000	INR	IN	settled	LedgerOps Demo	2026-06-24 09:59:46.992029	demo_20260624095946981214_out
53	4	\N	15	10000	INR	IN	settled	LedgerOps Demo	2026-06-24 09:59:46.992034	demo_20260624095946981214_in
\.


--
-- Data for Name: predictions; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.predictions (id, user_id, prediction_type, entity_type, entity_id, score, output, created_at) FROM stdin;
1	1	fx	currency	\N	100	{"recommendation": "Convert 75% now and hold 25%", "risk": "High", "volatility_score": 100, "trend": "strengthening", "note": "Recommendation engine only; not a guarantee of market direction."}	2026-06-17 17:20:39.42009
2	1	fx	currency	\N	100	{"recommendation": "Convert 75% now and hold 25%", "risk": "High", "volatility_score": 100, "trend": "strengthening", "note": "Recommendation engine only; not a guarantee of market direction."}	2026-06-17 17:20:39.433979
3	1	anomaly	transaction	\N	100	{"anomaly_score": 100, "reasons": ["Amount is abnormal versus trained SMB payment range", "New or elevated-risk country pattern", "Unusual transaction timing", "First-time payer requires manual verification"], "models": {"isolation_forest": -0.039, "one_class_svm": -4.483}}	2026-06-17 17:20:40.826043
4	1	anomaly	transaction	\N	100	{"anomaly_score": 100, "reasons": ["Amount is abnormal versus trained SMB payment range", "New or elevated-risk country pattern", "Unusual transaction timing", "First-time payer requires manual verification"], "models": {"isolation_forest": -0.039, "one_class_svm": -4.483}}	2026-06-17 17:20:40.838136
5	1	fx	currency	\N	100	{"recommendation": "Convert 75% now and hold 25%", "risk": "High", "volatility_score": 100, "trend": "strengthening", "note": "Recommendation engine only; not a guarantee of market direction."}	2026-06-17 17:20:44.271116
6	1	fx	currency	\N	100	{"recommendation": "Convert 75% now and hold 25%", "risk": "High", "volatility_score": 100, "trend": "strengthening", "note": "Recommendation engine only; not a guarantee of market direction."}	2026-06-17 17:20:44.281785
7	1	anomaly	transaction	\N	100	{"anomaly_score": 100, "reasons": ["Amount is abnormal versus trained SMB payment range", "New or elevated-risk country pattern", "Unusual transaction timing", "First-time payer requires manual verification"], "models": {"isolation_forest": -0.039, "one_class_svm": -4.483}}	2026-06-17 17:20:44.807096
8	1	anomaly	transaction	\N	100	{"anomaly_score": 100, "reasons": ["Amount is abnormal versus trained SMB payment range", "New or elevated-risk country pattern", "Unusual transaction timing", "First-time payer requires manual verification"], "models": {"isolation_forest": -0.039, "one_class_svm": -4.483}}	2026-06-17 17:20:44.817915
9	1	runway	company	\N	132	{"projected_days": 132, "risk": "Low", "forecast": [{"week": 1, "cash": 426193.39}, {"week": 2, "cash": 402472.12}, {"week": 3, "cash": 378750.85}, {"week": 4, "cash": 355029.58}, {"week": 5, "cash": 331308.31}, {"week": 6, "cash": 307587.04}, {"week": 7, "cash": 283865.77}, {"week": 8, "cash": 260144.5}, {"week": 9, "cash": 236423.23}, {"week": 10, "cash": 212701.96}, {"week": 11, "cash": 188980.69}, {"week": 12, "cash": 165259.42}], "method": "ARIMA/Prophet-style synthetic ensemble for operational planning"}	2026-06-17 17:20:45.636543
10	1	runway	company	\N	132	{"projected_days": 132, "risk": "Low", "forecast": [{"week": 1, "cash": 426193.39}, {"week": 2, "cash": 402472.12}, {"week": 3, "cash": 378750.85}, {"week": 4, "cash": 355029.58}, {"week": 5, "cash": 331308.31}, {"week": 6, "cash": 307587.04}, {"week": 7, "cash": 283865.77}, {"week": 8, "cash": 260144.5}, {"week": 9, "cash": 236423.23}, {"week": 10, "cash": 212701.96}, {"week": 11, "cash": 188980.69}, {"week": 12, "cash": 165259.42}], "method": "ARIMA/Prophet-style synthetic ensemble for operational planning"}	2026-06-17 17:20:45.651412
11	1	fx	currency	\N	100	{"recommendation": "Convert 75% now and hold 25%", "risk": "High", "volatility_score": 100, "trend": "strengthening", "note": "Recommendation engine only; not a guarantee of market direction."}	2026-06-17 17:22:04.430762
12	1	fx	currency	\N	100	{"recommendation": "Convert 75% now and hold 25%", "risk": "High", "volatility_score": 100, "trend": "strengthening", "note": "Recommendation engine only; not a guarantee of market direction."}	2026-06-17 17:22:04.442118
13	1	fx	currency	\N	100	{"recommendation": "Convert 75% now and hold 25%", "risk": "High", "volatility_score": 100, "trend": "strengthening", "note": "Recommendation engine only; not a guarantee of market direction."}	2026-06-17 17:22:05.442516
14	1	fx	currency	\N	100	{"recommendation": "Convert 75% now and hold 25%", "risk": "High", "volatility_score": 100, "trend": "strengthening", "note": "Recommendation engine only; not a guarantee of market direction."}	2026-06-17 17:22:05.45547
15	1	anomaly	transaction	\N	100	{"anomaly_score": 100, "reasons": ["Amount is abnormal versus trained SMB payment range", "New or elevated-risk country pattern", "Unusual transaction timing", "First-time payer requires manual verification"], "models": {"isolation_forest": -0.039, "one_class_svm": -4.483}}	2026-06-17 17:22:05.830552
16	1	anomaly	transaction	\N	100	{"anomaly_score": 100, "reasons": ["Amount is abnormal versus trained SMB payment range", "New or elevated-risk country pattern", "Unusual transaction timing", "First-time payer requires manual verification"], "models": {"isolation_forest": -0.039, "one_class_svm": -4.483}}	2026-06-17 17:22:05.842669
17	1	runway	company	\N	132	{"projected_days": 132, "risk": "Low", "forecast": [{"week": 1, "cash": 426193.39}, {"week": 2, "cash": 402472.12}, {"week": 3, "cash": 378750.85}, {"week": 4, "cash": 355029.58}, {"week": 5, "cash": 331308.31}, {"week": 6, "cash": 307587.04}, {"week": 7, "cash": 283865.77}, {"week": 8, "cash": 260144.5}, {"week": 9, "cash": 236423.23}, {"week": 10, "cash": 212701.96}, {"week": 11, "cash": 188980.69}, {"week": 12, "cash": 165259.42}], "method": "ARIMA/Prophet-style synthetic ensemble for operational planning"}	2026-06-17 17:22:06.389875
18	1	runway	company	\N	132	{"projected_days": 132, "risk": "Low", "forecast": [{"week": 1, "cash": 426193.39}, {"week": 2, "cash": 402472.12}, {"week": 3, "cash": 378750.85}, {"week": 4, "cash": 355029.58}, {"week": 5, "cash": 331308.31}, {"week": 6, "cash": 307587.04}, {"week": 7, "cash": 283865.77}, {"week": 8, "cash": 260144.5}, {"week": 9, "cash": 236423.23}, {"week": 10, "cash": 212701.96}, {"week": 11, "cash": 188980.69}, {"week": 12, "cash": 165259.42}], "method": "ARIMA/Prophet-style synthetic ensemble for operational planning"}	2026-06-17 17:22:06.400536
19	1	fx	currency	\N	100	{"recommendation": "Convert 75% now and hold 25%", "risk": "High", "volatility_score": 100, "trend": "strengthening", "note": "Recommendation engine only; not a guarantee of market direction."}	2026-06-17 18:31:48.10041
20	1	fx	currency	\N	100	{"recommendation": "Convert 75% now and hold 25%", "risk": "High", "volatility_score": 100, "trend": "strengthening", "note": "Recommendation engine only; not a guarantee of market direction."}	2026-06-17 18:31:48.115367
21	1	anomaly	transaction	\N	100	{"anomaly_score": 100, "reasons": ["Amount is abnormal versus trained SMB payment range", "New or elevated-risk country pattern", "Unusual transaction timing", "First-time payer requires manual verification"], "models": {"isolation_forest": -0.039, "one_class_svm": -4.483}}	2026-06-17 18:31:49.126897
22	1	anomaly	transaction	\N	100	{"anomaly_score": 100, "reasons": ["Amount is abnormal versus trained SMB payment range", "New or elevated-risk country pattern", "Unusual transaction timing", "First-time payer requires manual verification"], "models": {"isolation_forest": -0.039, "one_class_svm": -4.483}}	2026-06-17 18:31:49.138188
23	1	runway	company	\N	132	{"projected_days": 132, "risk": "Low", "forecast": [{"week": 1, "cash": 426193.39}, {"week": 2, "cash": 402472.12}, {"week": 3, "cash": 378750.85}, {"week": 4, "cash": 355029.58}, {"week": 5, "cash": 331308.31}, {"week": 6, "cash": 307587.04}, {"week": 7, "cash": 283865.77}, {"week": 8, "cash": 260144.5}, {"week": 9, "cash": 236423.23}, {"week": 10, "cash": 212701.96}, {"week": 11, "cash": 188980.69}, {"week": 12, "cash": 165259.42}], "method": "ARIMA/Prophet-style synthetic ensemble for operational planning"}	2026-06-17 18:31:50.251258
24	1	runway	company	\N	132	{"projected_days": 132, "risk": "Low", "forecast": [{"week": 1, "cash": 426193.39}, {"week": 2, "cash": 402472.12}, {"week": 3, "cash": 378750.85}, {"week": 4, "cash": 355029.58}, {"week": 5, "cash": 331308.31}, {"week": 6, "cash": 307587.04}, {"week": 7, "cash": 283865.77}, {"week": 8, "cash": 260144.5}, {"week": 9, "cash": 236423.23}, {"week": 10, "cash": 212701.96}, {"week": 11, "cash": 188980.69}, {"week": 12, "cash": 165259.42}], "method": "ARIMA/Prophet-style synthetic ensemble for operational planning"}	2026-06-17 18:31:50.259454
25	1	fx	currency	\N	100	{"recommendation": "Convert 75% now and hold 25%", "risk": "High", "volatility_score": 100, "trend": "strengthening", "note": "Recommendation engine only; not a guarantee of market direction."}	2026-06-18 07:39:47.30785
26	1	fx	currency	\N	100	{"recommendation": "Convert 75% now and hold 25%", "risk": "High", "volatility_score": 100, "trend": "strengthening", "note": "Recommendation engine only; not a guarantee of market direction."}	2026-06-18 07:39:47.320841
27	1	anomaly	transaction	\N	100	{"anomaly_score": 100, "reasons": ["Amount is abnormal versus trained SMB payment range", "New or elevated-risk country pattern", "Unusual transaction timing", "First-time payer requires manual verification"], "models": {"isolation_forest": -0.039, "one_class_svm": -4.483}}	2026-06-18 07:39:47.828779
28	1	anomaly	transaction	\N	100	{"anomaly_score": 100, "reasons": ["Amount is abnormal versus trained SMB payment range", "New or elevated-risk country pattern", "Unusual transaction timing", "First-time payer requires manual verification"], "models": {"isolation_forest": -0.039, "one_class_svm": -4.483}}	2026-06-18 07:39:47.842844
29	1	runway	company	\N	132	{"projected_days": 132, "risk": "Low", "forecast": [{"week": 1, "cash": 426193.39}, {"week": 2, "cash": 402472.12}, {"week": 3, "cash": 378750.85}, {"week": 4, "cash": 355029.58}, {"week": 5, "cash": 331308.31}, {"week": 6, "cash": 307587.04}, {"week": 7, "cash": 283865.77}, {"week": 8, "cash": 260144.5}, {"week": 9, "cash": 236423.23}, {"week": 10, "cash": 212701.96}, {"week": 11, "cash": 188980.69}, {"week": 12, "cash": 165259.42}], "method": "ARIMA/Prophet-style synthetic ensemble for operational planning"}	2026-06-18 07:39:50.022379
30	1	runway	company	\N	132	{"projected_days": 132, "risk": "Low", "forecast": [{"week": 1, "cash": 426193.39}, {"week": 2, "cash": 402472.12}, {"week": 3, "cash": 378750.85}, {"week": 4, "cash": 355029.58}, {"week": 5, "cash": 331308.31}, {"week": 6, "cash": 307587.04}, {"week": 7, "cash": 283865.77}, {"week": 8, "cash": 260144.5}, {"week": 9, "cash": 236423.23}, {"week": 10, "cash": 212701.96}, {"week": 11, "cash": 188980.69}, {"week": 12, "cash": 165259.42}], "method": "ARIMA/Prophet-style synthetic ensemble for operational planning"}	2026-06-18 07:39:50.053536
31	4	runway	company	\N	12	{"projected_days": 12, "risk": "High", "forecast": [{"week": 1, "cash": 50000.0}, {"week": 2, "cash": 18000.0}, {"week": 3, "cash": -14000.0}, {"week": 4, "cash": -46000.0}, {"week": 5, "cash": -78000.0}, {"week": 6, "cash": -110000.0}, {"week": 7, "cash": -142000.0}, {"week": 8, "cash": -174000.0}, {"week": 9, "cash": -206000.0}, {"week": 10, "cash": -238000.0}, {"week": 11, "cash": -270000.0}, {"week": 12, "cash": -302000.0}], "method": "ARIMA/Prophet-style synthetic ensemble for operational planning"}	2026-06-23 06:50:26.140182
32	4	runway	company	\N	12	{"projected_days": 12, "risk": "High", "forecast": [{"week": 1, "cash": 50000.0}, {"week": 2, "cash": 18000.0}, {"week": 3, "cash": -14000.0}, {"week": 4, "cash": -46000.0}, {"week": 5, "cash": -78000.0}, {"week": 6, "cash": -110000.0}, {"week": 7, "cash": -142000.0}, {"week": 8, "cash": -174000.0}, {"week": 9, "cash": -206000.0}, {"week": 10, "cash": -238000.0}, {"week": 11, "cash": -270000.0}, {"week": 12, "cash": -302000.0}], "method": "ARIMA/Prophet-style synthetic ensemble for operational planning"}	2026-06-23 06:50:26.148925
33	4	anomaly	transaction	\N	100	{"anomaly_score": 100, "reasons": ["Amount is abnormal versus trained SMB payment range", "New or elevated-risk country pattern", "Unusual transaction timing", "First-time payer requires manual verification"], "models": {"isolation_forest": -0.039, "one_class_svm": -4.483}}	2026-06-23 06:50:26.681346
34	4	anomaly	transaction	\N	100	{"anomaly_score": 100, "reasons": ["Amount is abnormal versus trained SMB payment range", "New or elevated-risk country pattern", "Unusual transaction timing", "First-time payer requires manual verification"], "models": {"isolation_forest": -0.039, "one_class_svm": -4.483}}	2026-06-23 06:50:26.691566
35	4	fx	currency	\N	100	{"recommendation": "Convert 75% now and hold 25%", "risk": "High", "volatility_score": 100, "trend": "strengthening", "note": "Recommendation engine only; not a guarantee of market direction."}	2026-06-23 06:50:26.358674
36	4	fx	currency	\N	100	{"recommendation": "Convert 75% now and hold 25%", "risk": "High", "volatility_score": 100, "trend": "strengthening", "note": "Recommendation engine only; not a guarantee of market direction."}	2026-06-23 06:50:26.373382
37	4	fx	currency	\N	100	{"recommendation": "Convert 75% now and hold 25%", "risk": "High", "volatility_score": 100, "trend": "strengthening", "note": "Recommendation engine only; not a guarantee of market direction."}	2026-06-23 08:32:10.799756
38	4	fx	currency	\N	100	{"recommendation": "Convert 75% now and hold 25%", "risk": "High", "volatility_score": 100, "trend": "strengthening", "note": "Recommendation engine only; not a guarantee of market direction."}	2026-06-23 08:32:10.809595
39	4	anomaly	transaction	\N	100	{"anomaly_score": 100, "reasons": ["Amount is abnormal versus trained SMB payment range", "New or elevated-risk country pattern", "Unusual transaction timing", "First-time payer requires manual verification"], "models": {"isolation_forest": -0.039, "one_class_svm": -4.483}}	2026-06-23 08:32:11.985292
40	4	anomaly	transaction	\N	100	{"anomaly_score": 100, "reasons": ["Amount is abnormal versus trained SMB payment range", "New or elevated-risk country pattern", "Unusual transaction timing", "First-time payer requires manual verification"], "models": {"isolation_forest": -0.039, "one_class_svm": -4.483}}	2026-06-23 08:32:11.990891
41	4	fx	currency	\N	100	{"recommendation": "Convert 75% now and hold 25%", "risk": "High", "volatility_score": 100, "trend": "strengthening", "note": "Recommendation engine only; not a guarantee of market direction."}	2026-06-23 08:32:15.99362
42	4	fx	currency	\N	100	{"recommendation": "Convert 75% now and hold 25%", "risk": "High", "volatility_score": 100, "trend": "strengthening", "note": "Recommendation engine only; not a guarantee of market direction."}	2026-06-23 08:32:16.003326
43	4	anomaly	transaction	\N	100	{"anomaly_score": 100, "reasons": ["Amount is abnormal versus trained SMB payment range", "New or elevated-risk country pattern", "Unusual transaction timing", "First-time payer requires manual verification"], "models": {"isolation_forest": -0.039, "one_class_svm": -4.483}}	2026-06-23 08:32:17.385763
44	4	anomaly	transaction	\N	100	{"anomaly_score": 100, "reasons": ["Amount is abnormal versus trained SMB payment range", "New or elevated-risk country pattern", "Unusual transaction timing", "First-time payer requires manual verification"], "models": {"isolation_forest": -0.039, "one_class_svm": -4.483}}	2026-06-23 08:32:17.390462
45	4	runway	company	\N	12	{"projected_days": 12, "risk": "High", "forecast": [{"week": 1, "cash": 50000.0}, {"week": 2, "cash": 18000.0}, {"week": 3, "cash": -14000.0}, {"week": 4, "cash": -46000.0}, {"week": 5, "cash": -78000.0}, {"week": 6, "cash": -110000.0}, {"week": 7, "cash": -142000.0}, {"week": 8, "cash": -174000.0}, {"week": 9, "cash": -206000.0}, {"week": 10, "cash": -238000.0}, {"week": 11, "cash": -270000.0}, {"week": 12, "cash": -302000.0}], "method": "ARIMA/Prophet-style synthetic ensemble for operational planning"}	2026-06-23 08:32:18.008393
46	4	runway	company	\N	12	{"projected_days": 12, "risk": "High", "forecast": [{"week": 1, "cash": 50000.0}, {"week": 2, "cash": 18000.0}, {"week": 3, "cash": -14000.0}, {"week": 4, "cash": -46000.0}, {"week": 5, "cash": -78000.0}, {"week": 6, "cash": -110000.0}, {"week": 7, "cash": -142000.0}, {"week": 8, "cash": -174000.0}, {"week": 9, "cash": -206000.0}, {"week": 10, "cash": -238000.0}, {"week": 11, "cash": -270000.0}, {"week": 12, "cash": -302000.0}], "method": "ARIMA/Prophet-style synthetic ensemble for operational planning"}	2026-06-23 08:32:18.018434
47	1	anomaly	transaction	\N	100	{"anomaly_score": 100, "reasons": ["Amount is abnormal versus trained SMB payment range", "New or elevated-risk country pattern", "Unusual transaction timing", "First-time payer requires manual verification"], "models": {"isolation_forest": -0.039, "one_class_svm": -4.483}}	2026-06-23 08:38:18.334137
48	1	anomaly	transaction	\N	100	{"anomaly_score": 100, "reasons": ["Amount is abnormal versus trained SMB payment range", "New or elevated-risk country pattern", "Unusual transaction timing", "First-time payer requires manual verification"], "models": {"isolation_forest": -0.039, "one_class_svm": -4.483}}	2026-06-23 08:38:18.349773
49	1	runway	company	\N	132	{"projected_days": 132, "risk": "Low", "forecast": [{"week": 1, "cash": 426193.39}, {"week": 2, "cash": 402472.12}, {"week": 3, "cash": 378750.85}, {"week": 4, "cash": 355029.58}, {"week": 5, "cash": 331308.31}, {"week": 6, "cash": 307587.04}, {"week": 7, "cash": 283865.77}, {"week": 8, "cash": 260144.5}, {"week": 9, "cash": 236423.23}, {"week": 10, "cash": 212701.96}, {"week": 11, "cash": 188980.69}, {"week": 12, "cash": 165259.42}], "method": "ARIMA/Prophet-style synthetic ensemble for operational planning"}	2026-06-23 08:38:19.177495
50	1	runway	company	\N	132	{"projected_days": 132, "risk": "Low", "forecast": [{"week": 1, "cash": 426193.39}, {"week": 2, "cash": 402472.12}, {"week": 3, "cash": 378750.85}, {"week": 4, "cash": 355029.58}, {"week": 5, "cash": 331308.31}, {"week": 6, "cash": 307587.04}, {"week": 7, "cash": 283865.77}, {"week": 8, "cash": 260144.5}, {"week": 9, "cash": 236423.23}, {"week": 10, "cash": 212701.96}, {"week": 11, "cash": 188980.69}, {"week": 12, "cash": 165259.42}], "method": "ARIMA/Prophet-style synthetic ensemble for operational planning"}	2026-06-23 08:38:19.191121
51	1	anomaly	transaction	\N	100	{"anomaly_score": 100, "reasons": ["Amount is abnormal versus trained SMB payment range", "New or elevated-risk country pattern", "Unusual transaction timing", "First-time payer requires manual verification"], "models": {"isolation_forest": -0.039, "one_class_svm": -4.483}}	2026-06-23 08:38:20.815775
52	1	anomaly	transaction	\N	100	{"anomaly_score": 100, "reasons": ["Amount is abnormal versus trained SMB payment range", "New or elevated-risk country pattern", "Unusual transaction timing", "First-time payer requires manual verification"], "models": {"isolation_forest": -0.039, "one_class_svm": -4.483}}	2026-06-23 08:38:20.82614
53	4	fx	currency	\N	100	{"recommendation": "Convert 75% now and hold 25%", "risk": "High", "volatility_score": 100, "trend": "strengthening", "note": "Recommendation engine only; not a guarantee of market direction."}	2026-06-23 08:38:44.750962
54	4	fx	currency	\N	100	{"recommendation": "Convert 75% now and hold 25%", "risk": "High", "volatility_score": 100, "trend": "strengthening", "note": "Recommendation engine only; not a guarantee of market direction."}	2026-06-23 08:38:44.761465
55	4	anomaly	transaction	\N	100	{"anomaly_score": 100, "reasons": ["Amount is abnormal versus trained SMB payment range", "New or elevated-risk country pattern", "Unusual transaction timing", "First-time payer requires manual verification"], "models": {"isolation_forest": -0.039, "one_class_svm": -4.483}}	2026-06-23 08:38:45.789669
56	4	anomaly	transaction	\N	100	{"anomaly_score": 100, "reasons": ["Amount is abnormal versus trained SMB payment range", "New or elevated-risk country pattern", "Unusual transaction timing", "First-time payer requires manual verification"], "models": {"isolation_forest": -0.039, "one_class_svm": -4.483}}	2026-06-23 08:38:45.799887
57	4	runway	company	\N	12	{"projected_days": 12, "risk": "High", "forecast": [{"week": 1, "cash": 50000.0}, {"week": 2, "cash": 18000.0}, {"week": 3, "cash": -14000.0}, {"week": 4, "cash": -46000.0}, {"week": 5, "cash": -78000.0}, {"week": 6, "cash": -110000.0}, {"week": 7, "cash": -142000.0}, {"week": 8, "cash": -174000.0}, {"week": 9, "cash": -206000.0}, {"week": 10, "cash": -238000.0}, {"week": 11, "cash": -270000.0}, {"week": 12, "cash": -302000.0}], "method": "ARIMA/Prophet-style synthetic ensemble for operational planning"}	2026-06-23 08:38:45.001094
58	4	runway	company	\N	12	{"projected_days": 12, "risk": "High", "forecast": [{"week": 1, "cash": 50000.0}, {"week": 2, "cash": 18000.0}, {"week": 3, "cash": -14000.0}, {"week": 4, "cash": -46000.0}, {"week": 5, "cash": -78000.0}, {"week": 6, "cash": -110000.0}, {"week": 7, "cash": -142000.0}, {"week": 8, "cash": -174000.0}, {"week": 9, "cash": -206000.0}, {"week": 10, "cash": -238000.0}, {"week": 11, "cash": -270000.0}, {"week": 12, "cash": -302000.0}], "method": "ARIMA/Prophet-style synthetic ensemble for operational planning"}	2026-06-23 08:38:45.009246
59	4	fx	currency	\N	100	{"recommendation": "Convert 75% now and hold 25%", "risk": "High", "volatility_score": 100, "trend": "strengthening", "note": "Recommendation engine only; not a guarantee of market direction."}	2026-06-23 08:46:23.162986
60	4	fx	currency	\N	100	{"recommendation": "Convert 75% now and hold 25%", "risk": "High", "volatility_score": 100, "trend": "strengthening", "note": "Recommendation engine only; not a guarantee of market direction."}	2026-06-23 08:46:23.17846
61	4	anomaly	transaction	\N	100	{"anomaly_score": 100, "reasons": ["Amount is abnormal versus trained SMB payment range", "New or elevated-risk country pattern", "Unusual transaction timing", "First-time payer requires manual verification"], "models": {"isolation_forest": -0.039, "one_class_svm": -4.483}}	2026-06-23 08:46:23.722584
62	4	anomaly	transaction	\N	100	{"anomaly_score": 100, "reasons": ["Amount is abnormal versus trained SMB payment range", "New or elevated-risk country pattern", "Unusual transaction timing", "First-time payer requires manual verification"], "models": {"isolation_forest": -0.039, "one_class_svm": -4.483}}	2026-06-23 08:46:23.73198
63	4	runway	company	\N	12	{"projected_days": 12, "risk": "High", "forecast": [{"week": 1, "cash": 50010.0}, {"week": 2, "cash": 18022.5}, {"week": 3, "cash": -13965.0}, {"week": 4, "cash": -45952.5}, {"week": 5, "cash": -77940.0}, {"week": 6, "cash": -109927.5}, {"week": 7, "cash": -141915.0}, {"week": 8, "cash": -173902.5}, {"week": 9, "cash": -205890.0}, {"week": 10, "cash": -237877.5}, {"week": 11, "cash": -269865.0}, {"week": 12, "cash": -301852.5}], "method": "ARIMA/Prophet-style synthetic ensemble for operational planning"}	2026-06-23 08:46:24.488615
64	4	runway	company	\N	12	{"projected_days": 12, "risk": "High", "forecast": [{"week": 1, "cash": 50010.0}, {"week": 2, "cash": 18022.5}, {"week": 3, "cash": -13965.0}, {"week": 4, "cash": -45952.5}, {"week": 5, "cash": -77940.0}, {"week": 6, "cash": -109927.5}, {"week": 7, "cash": -141915.0}, {"week": 8, "cash": -173902.5}, {"week": 9, "cash": -205890.0}, {"week": 10, "cash": -237877.5}, {"week": 11, "cash": -269865.0}, {"week": 12, "cash": -301852.5}], "method": "ARIMA/Prophet-style synthetic ensemble for operational planning"}	2026-06-23 08:46:24.493486
65	4	runway	company	\N	12	{"projected_days": 12, "risk": "High", "forecast": [{"week": 1, "cash": 50010.0}, {"week": 2, "cash": 18022.5}, {"week": 3, "cash": -13965.0}, {"week": 4, "cash": -45952.5}, {"week": 5, "cash": -77940.0}, {"week": 6, "cash": -109927.5}, {"week": 7, "cash": -141915.0}, {"week": 8, "cash": -173902.5}, {"week": 9, "cash": -205890.0}, {"week": 10, "cash": -237877.5}, {"week": 11, "cash": -269865.0}, {"week": 12, "cash": -301852.5}], "method": "ARIMA/Prophet-style synthetic ensemble for operational planning"}	2026-06-23 08:46:28.389828
69	4	anomaly	transaction	\N	100	{"anomaly_score": 100, "reasons": ["Amount is abnormal versus trained SMB payment range", "New or elevated-risk country pattern", "Unusual transaction timing", "First-time payer requires manual verification"], "models": {"isolation_forest": -0.039, "one_class_svm": -4.483}}	2026-06-23 08:46:29.53004
66	4	runway	company	\N	12	{"projected_days": 12, "risk": "High", "forecast": [{"week": 1, "cash": 50010.0}, {"week": 2, "cash": 18022.5}, {"week": 3, "cash": -13965.0}, {"week": 4, "cash": -45952.5}, {"week": 5, "cash": -77940.0}, {"week": 6, "cash": -109927.5}, {"week": 7, "cash": -141915.0}, {"week": 8, "cash": -173902.5}, {"week": 9, "cash": -205890.0}, {"week": 10, "cash": -237877.5}, {"week": 11, "cash": -269865.0}, {"week": 12, "cash": -301852.5}], "method": "ARIMA/Prophet-style synthetic ensemble for operational planning"}	2026-06-23 08:46:28.405982
67	4	fx	currency	\N	100	{"recommendation": "Convert 75% now and hold 25%", "risk": "High", "volatility_score": 100, "trend": "strengthening", "note": "Recommendation engine only; not a guarantee of market direction."}	2026-06-23 08:46:29.016206
68	4	fx	currency	\N	100	{"recommendation": "Convert 75% now and hold 25%", "risk": "High", "volatility_score": 100, "trend": "strengthening", "note": "Recommendation engine only; not a guarantee of market direction."}	2026-06-23 08:46:29.025613
70	4	anomaly	transaction	\N	100	{"anomaly_score": 100, "reasons": ["Amount is abnormal versus trained SMB payment range", "New or elevated-risk country pattern", "Unusual transaction timing", "First-time payer requires manual verification"], "models": {"isolation_forest": -0.039, "one_class_svm": -4.483}}	2026-06-23 08:46:29.539934
71	4	fx	currency	\N	100	{"recommendation": "Convert 75% now and hold 25%", "risk": "High", "volatility_score": 100, "trend": "strengthening", "note": "Recommendation engine only; not a guarantee of market direction."}	2026-06-23 10:29:22.085539
72	4	fx	currency	\N	100	{"recommendation": "Convert 75% now and hold 25%", "risk": "High", "volatility_score": 100, "trend": "strengthening", "note": "Recommendation engine only; not a guarantee of market direction."}	2026-06-23 10:29:22.094376
73	4	anomaly	transaction	\N	100	{"anomaly_score": 100, "reasons": ["Amount is abnormal versus trained SMB payment range", "New or elevated-risk country pattern", "Unusual transaction timing", "First-time payer requires manual verification"], "models": {"isolation_forest": -0.039, "one_class_svm": -4.483}}	2026-06-23 10:29:35.144146
74	4	anomaly	transaction	\N	100	{"anomaly_score": 100, "reasons": ["Amount is abnormal versus trained SMB payment range", "New or elevated-risk country pattern", "Unusual transaction timing", "First-time payer requires manual verification"], "models": {"isolation_forest": -0.039, "one_class_svm": -4.483}}	2026-06-23 10:29:35.16364
75	4	runway	company	\N	12	{"projected_days": 12, "risk": "High", "forecast": [{"week": 1, "cash": 50010.0}, {"week": 2, "cash": 18022.5}, {"week": 3, "cash": -13965.0}, {"week": 4, "cash": -45952.5}, {"week": 5, "cash": -77940.0}, {"week": 6, "cash": -109927.5}, {"week": 7, "cash": -141915.0}, {"week": 8, "cash": -173902.5}, {"week": 9, "cash": -205890.0}, {"week": 10, "cash": -237877.5}, {"week": 11, "cash": -269865.0}, {"week": 12, "cash": -301852.5}], "method": "ARIMA/Prophet-style synthetic ensemble for operational planning"}	2026-06-23 10:29:47.905828
76	4	runway	company	\N	12	{"projected_days": 12, "risk": "High", "forecast": [{"week": 1, "cash": 50010.0}, {"week": 2, "cash": 18022.5}, {"week": 3, "cash": -13965.0}, {"week": 4, "cash": -45952.5}, {"week": 5, "cash": -77940.0}, {"week": 6, "cash": -109927.5}, {"week": 7, "cash": -141915.0}, {"week": 8, "cash": -173902.5}, {"week": 9, "cash": -205890.0}, {"week": 10, "cash": -237877.5}, {"week": 11, "cash": -269865.0}, {"week": 12, "cash": -301852.5}], "method": "ARIMA/Prophet-style synthetic ensemble for operational planning"}	2026-06-23 10:29:47.924662
77	4	anomaly	transaction	\N	100	{"anomaly_score": 100, "reasons": ["Amount is abnormal versus trained SMB payment range", "New or elevated-risk country pattern", "Unusual transaction timing", "First-time payer requires manual verification"], "models": {"isolation_forest": -0.039, "one_class_svm": -4.483}}	2026-06-23 10:29:50.214913
78	4	anomaly	transaction	\N	100	{"anomaly_score": 100, "reasons": ["Amount is abnormal versus trained SMB payment range", "New or elevated-risk country pattern", "Unusual transaction timing", "First-time payer requires manual verification"], "models": {"isolation_forest": -0.039, "one_class_svm": -4.483}}	2026-06-23 10:29:50.223684
79	4	fx	currency	\N	100	{"recommendation": "Convert 75% now and hold 25%", "risk": "High", "volatility_score": 100, "trend": "strengthening", "note": "Recommendation engine only; not a guarantee of market direction."}	2026-06-23 10:29:50.954775
80	4	fx	currency	\N	100	{"recommendation": "Convert 75% now and hold 25%", "risk": "High", "volatility_score": 100, "trend": "strengthening", "note": "Recommendation engine only; not a guarantee of market direction."}	2026-06-23 10:29:50.964754
81	4	runway	company	\N	12	{"projected_days": 12, "risk": "High", "forecast": [{"week": 1, "cash": 50010.0}, {"week": 2, "cash": 18022.5}, {"week": 3, "cash": -13965.0}, {"week": 4, "cash": -45952.5}, {"week": 5, "cash": -77940.0}, {"week": 6, "cash": -109927.5}, {"week": 7, "cash": -141915.0}, {"week": 8, "cash": -173902.5}, {"week": 9, "cash": -205890.0}, {"week": 10, "cash": -237877.5}, {"week": 11, "cash": -269865.0}, {"week": 12, "cash": -301852.5}], "method": "ARIMA/Prophet-style synthetic ensemble for operational planning"}	2026-06-23 10:30:04.961193
82	4	runway	company	\N	12	{"projected_days": 12, "risk": "High", "forecast": [{"week": 1, "cash": 50010.0}, {"week": 2, "cash": 18022.5}, {"week": 3, "cash": -13965.0}, {"week": 4, "cash": -45952.5}, {"week": 5, "cash": -77940.0}, {"week": 6, "cash": -109927.5}, {"week": 7, "cash": -141915.0}, {"week": 8, "cash": -173902.5}, {"week": 9, "cash": -205890.0}, {"week": 10, "cash": -237877.5}, {"week": 11, "cash": -269865.0}, {"week": 12, "cash": -301852.5}], "method": "ARIMA/Prophet-style synthetic ensemble for operational planning"}	2026-06-23 10:30:04.971124
83	1	fx	currency	\N	100	{"recommendation": "Convert 75% now and hold 25%", "risk": "High", "volatility_score": 100, "trend": "weakening", "note": "Recommendation engine only; not a guarantee of market direction."}	2026-06-24 07:16:30.890175
84	1	anomaly	transaction	1	62	{"anomaly_score": 62, "reasons": ["No single rule fired; score is driven by model distance"], "models": {"isolation_forest": 0.031, "one_class_svm": 0.391}}	2026-06-24 07:16:30.960101
85	1	anomaly	transaction	8	100	{"anomaly_score": 100, "reasons": ["New or elevated-risk country pattern"], "models": {"isolation_forest": -0.033, "one_class_svm": -3.081}, "average_score": 73.3, "flagged_count": 16}	2026-06-24 07:30:17.454344
86	1	anomaly	transaction	8	100	{"anomaly_score": 100, "reasons": ["New or elevated-risk country pattern"], "models": {"isolation_forest": -0.033, "one_class_svm": -3.081}, "average_score": 73.3, "flagged_count": 16}	2026-06-24 07:32:27.251601
87	4	anomaly	transaction	48	88	{"anomaly_score": 88, "reasons": ["First-time payer requires manual verification"], "models": {"isolation_forest": -0.052, "one_class_svm": -1.155}, "average_score": 88.0, "flagged_count": 1}	2026-06-24 07:33:14.405023
88	4	anomaly	transaction	48	88	{"anomaly_score": 88, "reasons": ["First-time payer requires manual verification"], "models": {"isolation_forest": -0.052, "one_class_svm": -1.155}, "average_score": 88.0, "flagged_count": 1}	2026-06-24 07:33:14.416316
89	4	anomaly	transaction	48	88	{"anomaly_score": 88, "reasons": ["First-time payer requires manual verification"], "models": {"isolation_forest": -0.052, "one_class_svm": -1.155}, "average_score": 88.0, "flagged_count": 1}	2026-06-24 07:33:24.156488
90	4	anomaly	transaction	48	88	{"anomaly_score": 88, "reasons": ["First-time payer requires manual verification"], "models": {"isolation_forest": -0.052, "one_class_svm": -1.155}, "average_score": 88.0, "flagged_count": 1}	2026-06-24 07:33:24.172016
91	5	runway	company	\N	365	{"projected_days": 365, "risk": "Low", "forecast": [{"week": 1, "cash": 18010.0}, {"week": 2, "cash": 18010.0}, {"week": 3, "cash": 18010.0}, {"week": 4, "cash": 18010.0}, {"week": 5, "cash": 18010.0}, {"week": 6, "cash": 18010.0}, {"week": 7, "cash": 18010.0}, {"week": 8, "cash": 18010.0}, {"week": 9, "cash": 18010.0}, {"week": 10, "cash": 18010.0}, {"week": 11, "cash": 18010.0}, {"week": 12, "cash": 18010.0}], "method": "Observed cash inflow and outflow projection"}	2026-06-24 07:56:32.320727
92	5	runway	company	\N	365	{"projected_days": 365, "risk": "Low", "forecast": [{"week": 1, "cash": 18010.0}, {"week": 2, "cash": 18010.0}, {"week": 3, "cash": 18010.0}, {"week": 4, "cash": 18010.0}, {"week": 5, "cash": 18010.0}, {"week": 6, "cash": 18010.0}, {"week": 7, "cash": 18010.0}, {"week": 8, "cash": 18010.0}, {"week": 9, "cash": 18010.0}, {"week": 10, "cash": 18010.0}, {"week": 11, "cash": 18010.0}, {"week": 12, "cash": 18010.0}], "method": "Observed cash inflow and outflow projection"}	2026-06-24 07:56:32.340327
93	5	anomaly	transaction	50	91	{"anomaly_score": 91, "reasons": ["No single rule fired; score is driven by model distance"], "models": {"isolation_forest": -0.052, "one_class_svm": -1.415}, "average_score": 89.5, "flagged_count": 2}	2026-06-24 07:56:39.351521
94	5	anomaly	transaction	50	91	{"anomaly_score": 91, "reasons": ["No single rule fired; score is driven by model distance"], "models": {"isolation_forest": -0.052, "one_class_svm": -1.415}, "average_score": 89.5, "flagged_count": 2}	2026-06-24 07:56:39.383182
95	5	anomaly	transaction	50	91	{"anomaly_score": 91, "reasons": ["No single rule fired; score is driven by model distance"], "models": {"isolation_forest": -0.052, "one_class_svm": -1.415}, "average_score": 89.5, "flagged_count": 2}	2026-06-24 07:56:50.65108
96	5	anomaly	transaction	50	91	{"anomaly_score": 91, "reasons": ["No single rule fired; score is driven by model distance"], "models": {"isolation_forest": -0.052, "one_class_svm": -1.415}, "average_score": 89.5, "flagged_count": 2}	2026-06-24 07:56:50.660047
99	5	anomaly	transaction	50	91	{"anomaly_score": 91, "reasons": ["No single rule fired; score is driven by model distance"], "models": {"isolation_forest": -0.052, "one_class_svm": -1.415}, "average_score": 89.5, "flagged_count": 2}	2026-06-24 09:42:41.081886
101	5	runway	company	\N	365	{"projected_days": 365, "risk": "Low", "forecast": [{"week": 1, "cash": 18010.0}, {"week": 2, "cash": 18010.0}, {"week": 3, "cash": 18010.0}, {"week": 4, "cash": 18010.0}, {"week": 5, "cash": 18010.0}, {"week": 6, "cash": 18010.0}, {"week": 7, "cash": 18010.0}, {"week": 8, "cash": 18010.0}, {"week": 9, "cash": 18010.0}, {"week": 10, "cash": 18010.0}, {"week": 11, "cash": 18010.0}, {"week": 12, "cash": 18010.0}], "method": "Observed cash inflow and outflow projection"}	2026-06-24 09:42:42.260851
103	5	anomaly	transaction	50	91	{"anomaly_score": 91, "reasons": ["No single rule fired; score is driven by model distance"], "models": {"isolation_forest": -0.052, "one_class_svm": -1.415}, "average_score": 89.5, "flagged_count": 2}	2026-06-24 09:48:24.783046
106	5	runway	company	\N	365	{"projected_days": 365, "risk": "Low", "forecast": [{"week": 1, "cash": 18010.0}, {"week": 2, "cash": 18010.0}, {"week": 3, "cash": 18010.0}, {"week": 4, "cash": 18010.0}, {"week": 5, "cash": 18010.0}, {"week": 6, "cash": 18010.0}, {"week": 7, "cash": 18010.0}, {"week": 8, "cash": 18010.0}, {"week": 9, "cash": 18010.0}, {"week": 10, "cash": 18010.0}, {"week": 11, "cash": 18010.0}, {"week": 12, "cash": 18010.0}], "method": "Observed cash inflow and outflow projection"}	2026-06-24 09:48:25.950633
110	5	anomaly	transaction	50	91	{"anomaly_score": 91, "reasons": ["No single rule fired; score is driven by model distance"], "models": {"isolation_forest": -0.052, "one_class_svm": -1.415}, "average_score": 89.5, "flagged_count": 2}	2026-06-24 09:48:33.744412
114	5	anomaly	transaction	50	91	{"anomaly_score": 91, "reasons": ["No single rule fired; score is driven by model distance"], "models": {"isolation_forest": -0.052, "one_class_svm": -1.415}, "average_score": 89.5, "flagged_count": 2}	2026-06-24 09:56:30.715872
117	5	anomaly	transaction	50	91	{"anomaly_score": 91, "reasons": ["No single rule fired; score is driven by model distance"], "models": {"isolation_forest": -0.052, "one_class_svm": -1.415}, "average_score": 89.5, "flagged_count": 2}	2026-06-24 09:56:58.876761
132	5	anomaly	transaction	50	91	{"anomaly_score": 91, "reasons": ["No single rule fired; score is driven by model distance"], "models": {"isolation_forest": -0.052, "one_class_svm": -1.415}, "average_score": 89.5, "flagged_count": 2}	2026-06-24 09:59:37.752866
97	5	runway	company	\N	365	{"projected_days": 365, "risk": "Low", "forecast": [{"week": 1, "cash": 18010.0}, {"week": 2, "cash": 18010.0}, {"week": 3, "cash": 18010.0}, {"week": 4, "cash": 18010.0}, {"week": 5, "cash": 18010.0}, {"week": 6, "cash": 18010.0}, {"week": 7, "cash": 18010.0}, {"week": 8, "cash": 18010.0}, {"week": 9, "cash": 18010.0}, {"week": 10, "cash": 18010.0}, {"week": 11, "cash": 18010.0}, {"week": 12, "cash": 18010.0}], "method": "Observed cash inflow and outflow projection"}	2026-06-24 09:41:37.457746
98	5	runway	company	\N	365	{"projected_days": 365, "risk": "Low", "forecast": [{"week": 1, "cash": 18010.0}, {"week": 2, "cash": 18010.0}, {"week": 3, "cash": 18010.0}, {"week": 4, "cash": 18010.0}, {"week": 5, "cash": 18010.0}, {"week": 6, "cash": 18010.0}, {"week": 7, "cash": 18010.0}, {"week": 8, "cash": 18010.0}, {"week": 9, "cash": 18010.0}, {"week": 10, "cash": 18010.0}, {"week": 11, "cash": 18010.0}, {"week": 12, "cash": 18010.0}], "method": "Observed cash inflow and outflow projection"}	2026-06-24 09:41:37.487229
100	5	anomaly	transaction	50	91	{"anomaly_score": 91, "reasons": ["No single rule fired; score is driven by model distance"], "models": {"isolation_forest": -0.052, "one_class_svm": -1.415}, "average_score": 89.5, "flagged_count": 2}	2026-06-24 09:42:41.104003
102	5	runway	company	\N	365	{"projected_days": 365, "risk": "Low", "forecast": [{"week": 1, "cash": 18010.0}, {"week": 2, "cash": 18010.0}, {"week": 3, "cash": 18010.0}, {"week": 4, "cash": 18010.0}, {"week": 5, "cash": 18010.0}, {"week": 6, "cash": 18010.0}, {"week": 7, "cash": 18010.0}, {"week": 8, "cash": 18010.0}, {"week": 9, "cash": 18010.0}, {"week": 10, "cash": 18010.0}, {"week": 11, "cash": 18010.0}, {"week": 12, "cash": 18010.0}], "method": "Observed cash inflow and outflow projection"}	2026-06-24 09:42:42.266776
104	5	anomaly	transaction	50	91	{"anomaly_score": 91, "reasons": ["No single rule fired; score is driven by model distance"], "models": {"isolation_forest": -0.052, "one_class_svm": -1.415}, "average_score": 89.5, "flagged_count": 2}	2026-06-24 09:48:24.796507
105	5	runway	company	\N	365	{"projected_days": 365, "risk": "Low", "forecast": [{"week": 1, "cash": 18010.0}, {"week": 2, "cash": 18010.0}, {"week": 3, "cash": 18010.0}, {"week": 4, "cash": 18010.0}, {"week": 5, "cash": 18010.0}, {"week": 6, "cash": 18010.0}, {"week": 7, "cash": 18010.0}, {"week": 8, "cash": 18010.0}, {"week": 9, "cash": 18010.0}, {"week": 10, "cash": 18010.0}, {"week": 11, "cash": 18010.0}, {"week": 12, "cash": 18010.0}], "method": "Observed cash inflow and outflow projection"}	2026-06-24 09:48:25.9421
107	5	anomaly	transaction	50	91	{"anomaly_score": 91, "reasons": ["No single rule fired; score is driven by model distance"], "models": {"isolation_forest": -0.052, "one_class_svm": -1.415}, "average_score": 89.5, "flagged_count": 2}	2026-06-24 09:48:27.161182
108	5	anomaly	transaction	50	91	{"anomaly_score": 91, "reasons": ["No single rule fired; score is driven by model distance"], "models": {"isolation_forest": -0.052, "one_class_svm": -1.415}, "average_score": 89.5, "flagged_count": 2}	2026-06-24 09:48:27.177426
109	5	anomaly	transaction	50	91	{"anomaly_score": 91, "reasons": ["No single rule fired; score is driven by model distance"], "models": {"isolation_forest": -0.052, "one_class_svm": -1.415}, "average_score": 89.5, "flagged_count": 2}	2026-06-24 09:48:33.737556
111	5	runway	company	\N	365	{"projected_days": 365, "risk": "Low", "forecast": [{"week": 1, "cash": 18010.0}, {"week": 2, "cash": 18010.0}, {"week": 3, "cash": 18010.0}, {"week": 4, "cash": 18010.0}, {"week": 5, "cash": 18010.0}, {"week": 6, "cash": 18010.0}, {"week": 7, "cash": 18010.0}, {"week": 8, "cash": 18010.0}, {"week": 9, "cash": 18010.0}, {"week": 10, "cash": 18010.0}, {"week": 11, "cash": 18010.0}, {"week": 12, "cash": 18010.0}], "method": "Observed cash inflow and outflow projection"}	2026-06-24 09:56:29.226478
112	5	runway	company	\N	365	{"projected_days": 365, "risk": "Low", "forecast": [{"week": 1, "cash": 18010.0}, {"week": 2, "cash": 18010.0}, {"week": 3, "cash": 18010.0}, {"week": 4, "cash": 18010.0}, {"week": 5, "cash": 18010.0}, {"week": 6, "cash": 18010.0}, {"week": 7, "cash": 18010.0}, {"week": 8, "cash": 18010.0}, {"week": 9, "cash": 18010.0}, {"week": 10, "cash": 18010.0}, {"week": 11, "cash": 18010.0}, {"week": 12, "cash": 18010.0}], "method": "Observed cash inflow and outflow projection"}	2026-06-24 09:56:29.236374
113	5	anomaly	transaction	50	91	{"anomaly_score": 91, "reasons": ["No single rule fired; score is driven by model distance"], "models": {"isolation_forest": -0.052, "one_class_svm": -1.415}, "average_score": 89.5, "flagged_count": 2}	2026-06-24 09:56:30.702181
115	5	runway	company	\N	365	{"projected_days": 365, "risk": "Low", "forecast": [{"week": 1, "cash": 18010.0}, {"week": 2, "cash": 18010.0}, {"week": 3, "cash": 18010.0}, {"week": 4, "cash": 18010.0}, {"week": 5, "cash": 18010.0}, {"week": 6, "cash": 18010.0}, {"week": 7, "cash": 18010.0}, {"week": 8, "cash": 18010.0}, {"week": 9, "cash": 18010.0}, {"week": 10, "cash": 18010.0}, {"week": 11, "cash": 18010.0}, {"week": 12, "cash": 18010.0}], "method": "Observed cash inflow and outflow projection"}	2026-06-24 09:56:31.336257
116	5	runway	company	\N	365	{"projected_days": 365, "risk": "Low", "forecast": [{"week": 1, "cash": 18010.0}, {"week": 2, "cash": 18010.0}, {"week": 3, "cash": 18010.0}, {"week": 4, "cash": 18010.0}, {"week": 5, "cash": 18010.0}, {"week": 6, "cash": 18010.0}, {"week": 7, "cash": 18010.0}, {"week": 8, "cash": 18010.0}, {"week": 9, "cash": 18010.0}, {"week": 10, "cash": 18010.0}, {"week": 11, "cash": 18010.0}, {"week": 12, "cash": 18010.0}], "method": "Observed cash inflow and outflow projection"}	2026-06-24 09:56:31.345408
118	5	anomaly	transaction	50	91	{"anomaly_score": 91, "reasons": ["No single rule fired; score is driven by model distance"], "models": {"isolation_forest": -0.052, "one_class_svm": -1.415}, "average_score": 89.5, "flagged_count": 2}	2026-06-24 09:56:58.890233
119	5	runway	company	\N	365	{"projected_days": 365, "risk": "Low", "forecast": [{"week": 1, "cash": 18010.0}, {"week": 2, "cash": 18010.0}, {"week": 3, "cash": 18010.0}, {"week": 4, "cash": 18010.0}, {"week": 5, "cash": 18010.0}, {"week": 6, "cash": 18010.0}, {"week": 7, "cash": 18010.0}, {"week": 8, "cash": 18010.0}, {"week": 9, "cash": 18010.0}, {"week": 10, "cash": 18010.0}, {"week": 11, "cash": 18010.0}, {"week": 12, "cash": 18010.0}], "method": "Observed cash inflow and outflow projection"}	2026-06-24 09:57:42.43668
120	5	runway	company	\N	365	{"projected_days": 365, "risk": "Low", "forecast": [{"week": 1, "cash": 18010.0}, {"week": 2, "cash": 18010.0}, {"week": 3, "cash": 18010.0}, {"week": 4, "cash": 18010.0}, {"week": 5, "cash": 18010.0}, {"week": 6, "cash": 18010.0}, {"week": 7, "cash": 18010.0}, {"week": 8, "cash": 18010.0}, {"week": 9, "cash": 18010.0}, {"week": 10, "cash": 18010.0}, {"week": 11, "cash": 18010.0}, {"week": 12, "cash": 18010.0}], "method": "Observed cash inflow and outflow projection"}	2026-06-24 09:57:42.450815
121	5	anomaly	transaction	50	91	{"anomaly_score": 91, "reasons": ["No single rule fired; score is driven by model distance"], "models": {"isolation_forest": -0.052, "one_class_svm": -1.415}, "average_score": 89.5, "flagged_count": 2}	2026-06-24 09:58:03.910746
122	5	anomaly	transaction	50	91	{"anomaly_score": 91, "reasons": ["No single rule fired; score is driven by model distance"], "models": {"isolation_forest": -0.052, "one_class_svm": -1.415}, "average_score": 89.5, "flagged_count": 2}	2026-06-24 09:58:03.923682
123	5	runway	company	\N	365	{"projected_days": 365, "risk": "Low", "forecast": [{"week": 1, "cash": 18010.0}, {"week": 2, "cash": 18010.0}, {"week": 3, "cash": 18010.0}, {"week": 4, "cash": 18010.0}, {"week": 5, "cash": 18010.0}, {"week": 6, "cash": 18010.0}, {"week": 7, "cash": 18010.0}, {"week": 8, "cash": 18010.0}, {"week": 9, "cash": 18010.0}, {"week": 10, "cash": 18010.0}, {"week": 11, "cash": 18010.0}, {"week": 12, "cash": 18010.0}], "method": "Observed cash inflow and outflow projection"}	2026-06-24 09:58:04.378654
127	5	anomaly	transaction	50	91	{"anomaly_score": 91, "reasons": ["No single rule fired; score is driven by model distance"], "models": {"isolation_forest": -0.052, "one_class_svm": -1.415}, "average_score": 89.5, "flagged_count": 2}	2026-06-24 09:59:35.876179
130	5	runway	company	\N	365	{"projected_days": 365, "risk": "Low", "forecast": [{"week": 1, "cash": 18010.0}, {"week": 2, "cash": 18010.0}, {"week": 3, "cash": 18010.0}, {"week": 4, "cash": 18010.0}, {"week": 5, "cash": 18010.0}, {"week": 6, "cash": 18010.0}, {"week": 7, "cash": 18010.0}, {"week": 8, "cash": 18010.0}, {"week": 9, "cash": 18010.0}, {"week": 10, "cash": 18010.0}, {"week": 11, "cash": 18010.0}, {"week": 12, "cash": 18010.0}], "method": "Observed cash inflow and outflow projection"}	2026-06-24 09:59:36.663463
131	5	anomaly	transaction	50	91	{"anomaly_score": 91, "reasons": ["No single rule fired; score is driven by model distance"], "models": {"isolation_forest": -0.052, "one_class_svm": -1.415}, "average_score": 89.5, "flagged_count": 2}	2026-06-24 09:59:37.739995
124	5	runway	company	\N	365	{"projected_days": 365, "risk": "Low", "forecast": [{"week": 1, "cash": 18010.0}, {"week": 2, "cash": 18010.0}, {"week": 3, "cash": 18010.0}, {"week": 4, "cash": 18010.0}, {"week": 5, "cash": 18010.0}, {"week": 6, "cash": 18010.0}, {"week": 7, "cash": 18010.0}, {"week": 8, "cash": 18010.0}, {"week": 9, "cash": 18010.0}, {"week": 10, "cash": 18010.0}, {"week": 11, "cash": 18010.0}, {"week": 12, "cash": 18010.0}], "method": "Observed cash inflow and outflow projection"}	2026-06-24 09:58:04.390325
128	5	anomaly	transaction	50	91	{"anomaly_score": 91, "reasons": ["No single rule fired; score is driven by model distance"], "models": {"isolation_forest": -0.052, "one_class_svm": -1.415}, "average_score": 89.5, "flagged_count": 2}	2026-06-24 09:59:35.888736
125	5	runway	company	\N	365	{"projected_days": 365, "risk": "Low", "forecast": [{"week": 1, "cash": 18010.0}, {"week": 2, "cash": 18010.0}, {"week": 3, "cash": 18010.0}, {"week": 4, "cash": 18010.0}, {"week": 5, "cash": 18010.0}, {"week": 6, "cash": 18010.0}, {"week": 7, "cash": 18010.0}, {"week": 8, "cash": 18010.0}, {"week": 9, "cash": 18010.0}, {"week": 10, "cash": 18010.0}, {"week": 11, "cash": 18010.0}, {"week": 12, "cash": 18010.0}], "method": "Observed cash inflow and outflow projection"}	2026-06-24 09:59:35.179643
133	5	anomaly	transaction	50	91	{"anomaly_score": 91, "reasons": ["No single rule fired; score is driven by model distance"], "models": {"isolation_forest": -0.052, "one_class_svm": -1.415}, "average_score": 84.0, "flagged_count": 3}	2026-06-24 10:10:05.898596
126	5	runway	company	\N	365	{"projected_days": 365, "risk": "Low", "forecast": [{"week": 1, "cash": 18010.0}, {"week": 2, "cash": 18010.0}, {"week": 3, "cash": 18010.0}, {"week": 4, "cash": 18010.0}, {"week": 5, "cash": 18010.0}, {"week": 6, "cash": 18010.0}, {"week": 7, "cash": 18010.0}, {"week": 8, "cash": 18010.0}, {"week": 9, "cash": 18010.0}, {"week": 10, "cash": 18010.0}, {"week": 11, "cash": 18010.0}, {"week": 12, "cash": 18010.0}], "method": "Observed cash inflow and outflow projection"}	2026-06-24 09:59:35.213023
129	5	runway	company	\N	365	{"projected_days": 365, "risk": "Low", "forecast": [{"week": 1, "cash": 18010.0}, {"week": 2, "cash": 18010.0}, {"week": 3, "cash": 18010.0}, {"week": 4, "cash": 18010.0}, {"week": 5, "cash": 18010.0}, {"week": 6, "cash": 18010.0}, {"week": 7, "cash": 18010.0}, {"week": 8, "cash": 18010.0}, {"week": 9, "cash": 18010.0}, {"week": 10, "cash": 18010.0}, {"week": 11, "cash": 18010.0}, {"week": 12, "cash": 18010.0}], "method": "Observed cash inflow and outflow projection"}	2026-06-24 09:59:36.655155
134	5	anomaly	transaction	50	91	{"anomaly_score": 91, "reasons": ["No single rule fired; score is driven by model distance"], "models": {"isolation_forest": -0.052, "one_class_svm": -1.415}, "average_score": 84.0, "flagged_count": 3}	2026-06-24 10:10:05.914484
135	5	runway	company	\N	24	{"projected_days": 24, "risk": "High", "forecast": [{"week": 1, "cash": 8010.0}, {"week": 2, "cash": 5510.0}, {"week": 3, "cash": 3010.0}, {"week": 4, "cash": 510.0}, {"week": 5, "cash": -1990.0}, {"week": 6, "cash": -4490.0}, {"week": 7, "cash": -6990.0}, {"week": 8, "cash": -9490.0}, {"week": 9, "cash": -11990.0}, {"week": 10, "cash": -14490.0}, {"week": 11, "cash": -16990.0}, {"week": 12, "cash": -19490.0}], "method": "Observed cash inflow and outflow projection"}	2026-06-24 10:18:50.663006
136	5	runway	company	\N	24	{"projected_days": 24, "risk": "High", "forecast": [{"week": 1, "cash": 8010.0}, {"week": 2, "cash": 5510.0}, {"week": 3, "cash": 3010.0}, {"week": 4, "cash": 510.0}, {"week": 5, "cash": -1990.0}, {"week": 6, "cash": -4490.0}, {"week": 7, "cash": -6990.0}, {"week": 8, "cash": -9490.0}, {"week": 9, "cash": -11990.0}, {"week": 10, "cash": -14490.0}, {"week": 11, "cash": -16990.0}, {"week": 12, "cash": -19490.0}], "method": "Observed cash inflow and outflow projection"}	2026-06-24 10:18:50.671381
137	5	runway	company	\N	24	{"projected_days": 24, "risk": "High", "forecast": [{"week": 1, "cash": 8010.0}, {"week": 2, "cash": 5510.0}, {"week": 3, "cash": 3010.0}, {"week": 4, "cash": 510.0}, {"week": 5, "cash": -1990.0}, {"week": 6, "cash": -4490.0}, {"week": 7, "cash": -6990.0}, {"week": 8, "cash": -9490.0}, {"week": 9, "cash": -11990.0}, {"week": 10, "cash": -14490.0}, {"week": 11, "cash": -16990.0}, {"week": 12, "cash": -19490.0}], "method": "Observed cash inflow and outflow projection"}	2026-06-24 10:18:55.685672
138	5	runway	company	\N	24	{"projected_days": 24, "risk": "High", "forecast": [{"week": 1, "cash": 8010.0}, {"week": 2, "cash": 5510.0}, {"week": 3, "cash": 3010.0}, {"week": 4, "cash": 510.0}, {"week": 5, "cash": -1990.0}, {"week": 6, "cash": -4490.0}, {"week": 7, "cash": -6990.0}, {"week": 8, "cash": -9490.0}, {"week": 9, "cash": -11990.0}, {"week": 10, "cash": -14490.0}, {"week": 11, "cash": -16990.0}, {"week": 12, "cash": -19490.0}], "method": "Observed cash inflow and outflow projection"}	2026-06-24 10:18:55.70018
139	5	runway	company	\N	24	{"projected_days": 24, "risk": "High", "forecast": [{"week": 1, "cash": 8010.0}, {"week": 2, "cash": 5510.0}, {"week": 3, "cash": 3010.0}, {"week": 4, "cash": 510.0}, {"week": 5, "cash": -1990.0}, {"week": 6, "cash": -4490.0}, {"week": 7, "cash": -6990.0}, {"week": 8, "cash": -9490.0}, {"week": 9, "cash": -11990.0}, {"week": 10, "cash": -14490.0}, {"week": 11, "cash": -16990.0}, {"week": 12, "cash": -19490.0}], "method": "Observed cash inflow and outflow projection"}	2026-06-24 10:19:00.2651
140	5	runway	company	\N	24	{"projected_days": 24, "risk": "High", "forecast": [{"week": 1, "cash": 8010.0}, {"week": 2, "cash": 5510.0}, {"week": 3, "cash": 3010.0}, {"week": 4, "cash": 510.0}, {"week": 5, "cash": -1990.0}, {"week": 6, "cash": -4490.0}, {"week": 7, "cash": -6990.0}, {"week": 8, "cash": -9490.0}, {"week": 9, "cash": -11990.0}, {"week": 10, "cash": -14490.0}, {"week": 11, "cash": -16990.0}, {"week": 12, "cash": -19490.0}], "method": "Observed cash inflow and outflow projection"}	2026-06-24 10:19:00.271131
141	5	anomaly	transaction	50	91	{"anomaly_score": 91, "reasons": ["No single rule fired; score is driven by model distance"], "models": {"isolation_forest": -0.052, "one_class_svm": -1.415}, "average_score": 84.0, "flagged_count": 3}	2026-06-24 10:19:00.805151
142	5	anomaly	transaction	50	91	{"anomaly_score": 91, "reasons": ["No single rule fired; score is driven by model distance"], "models": {"isolation_forest": -0.052, "one_class_svm": -1.415}, "average_score": 84.0, "flagged_count": 3}	2026-06-24 10:19:00.817508
143	5	anomaly	transaction	50	91	{"anomaly_score": 91, "reasons": ["No single rule fired; score is driven by model distance"], "models": {"isolation_forest": -0.052, "one_class_svm": -1.415}, "average_score": 84.0, "flagged_count": 3}	2026-06-24 10:19:03.59113
144	5	anomaly	transaction	50	91	{"anomaly_score": 91, "reasons": ["No single rule fired; score is driven by model distance"], "models": {"isolation_forest": -0.052, "one_class_svm": -1.415}, "average_score": 84.0, "flagged_count": 3}	2026-06-24 10:19:03.603255
145	5	runway	company	\N	24	{"projected_days": 24, "risk": "High", "forecast": [{"week": 1, "cash": 8010.0}, {"week": 2, "cash": 5510.0}, {"week": 3, "cash": 3010.0}, {"week": 4, "cash": 510.0}, {"week": 5, "cash": -1990.0}, {"week": 6, "cash": -4490.0}, {"week": 7, "cash": -6990.0}, {"week": 8, "cash": -9490.0}, {"week": 9, "cash": -11990.0}, {"week": 10, "cash": -14490.0}, {"week": 11, "cash": -16990.0}, {"week": 12, "cash": -19490.0}], "method": "Observed cash inflow and outflow projection"}	2026-06-24 10:19:08.749025
146	5	runway	company	\N	24	{"projected_days": 24, "risk": "High", "forecast": [{"week": 1, "cash": 8010.0}, {"week": 2, "cash": 5510.0}, {"week": 3, "cash": 3010.0}, {"week": 4, "cash": 510.0}, {"week": 5, "cash": -1990.0}, {"week": 6, "cash": -4490.0}, {"week": 7, "cash": -6990.0}, {"week": 8, "cash": -9490.0}, {"week": 9, "cash": -11990.0}, {"week": 10, "cash": -14490.0}, {"week": 11, "cash": -16990.0}, {"week": 12, "cash": -19490.0}], "method": "Observed cash inflow and outflow projection"}	2026-06-24 10:19:08.757876
147	5	anomaly	transaction	50	91	{"anomaly_score": 91, "reasons": ["No single rule fired; score is driven by model distance"], "models": {"isolation_forest": -0.052, "one_class_svm": -1.415}, "average_score": 84.0, "flagged_count": 3}	2026-06-24 10:20:15.259831
148	5	anomaly	transaction	50	91	{"anomaly_score": 91, "reasons": ["No single rule fired; score is driven by model distance"], "models": {"isolation_forest": -0.052, "one_class_svm": -1.415}, "average_score": 84.0, "flagged_count": 3}	2026-06-24 10:20:15.271138
149	5	runway	company	\N	24	{"projected_days": 24, "risk": "High", "forecast": [{"week": 1, "cash": 8010.0}, {"week": 2, "cash": 5510.0}, {"week": 3, "cash": 3010.0}, {"week": 4, "cash": 510.0}, {"week": 5, "cash": -1990.0}, {"week": 6, "cash": -4490.0}, {"week": 7, "cash": -6990.0}, {"week": 8, "cash": -9490.0}, {"week": 9, "cash": -11990.0}, {"week": 10, "cash": -14490.0}, {"week": 11, "cash": -16990.0}, {"week": 12, "cash": -19490.0}], "method": "Observed cash inflow and outflow projection"}	2026-06-24 10:20:15.808255
150	5	runway	company	\N	24	{"projected_days": 24, "risk": "High", "forecast": [{"week": 1, "cash": 8010.0}, {"week": 2, "cash": 5510.0}, {"week": 3, "cash": 3010.0}, {"week": 4, "cash": 510.0}, {"week": 5, "cash": -1990.0}, {"week": 6, "cash": -4490.0}, {"week": 7, "cash": -6990.0}, {"week": 8, "cash": -9490.0}, {"week": 9, "cash": -11990.0}, {"week": 10, "cash": -14490.0}, {"week": 11, "cash": -16990.0}, {"week": 12, "cash": -19490.0}], "method": "Observed cash inflow and outflow projection"}	2026-06-24 10:20:15.822426
157	5	anomaly	transaction	50	91	{"anomaly_score": 91, "reasons": ["No single rule fired; score is driven by model distance"], "models": {"isolation_forest": -0.052, "one_class_svm": -1.415}, "average_score": 84.0, "flagged_count": 3}	2026-06-24 10:28:16.718152
159	5	anomaly	transaction	50	91	{"anomaly_score": 91, "reasons": ["No single rule fired; score is driven by model distance"], "models": {"isolation_forest": -0.052, "one_class_svm": -1.415}, "average_score": 84.0, "flagged_count": 3}	2026-06-24 10:28:18.905602
162	5	runway	company	\N	24	{"projected_days": 24, "risk": "High", "forecast": [{"week": 1, "cash": 8010.0}, {"week": 2, "cash": 5510.0}, {"week": 3, "cash": 3010.0}, {"week": 4, "cash": 510.0}, {"week": 5, "cash": -1990.0}, {"week": 6, "cash": -4490.0}, {"week": 7, "cash": -6990.0}, {"week": 8, "cash": -9490.0}, {"week": 9, "cash": -11990.0}, {"week": 10, "cash": -14490.0}, {"week": 11, "cash": -16990.0}, {"week": 12, "cash": -19490.0}], "method": "Observed cash inflow and outflow projection"}	2026-06-24 10:28:19.414953
163	5	runway	company	\N	24	{"projected_days": 24, "risk": "High", "forecast": [{"week": 1, "cash": 8010.0}, {"week": 2, "cash": 5510.0}, {"week": 3, "cash": 3010.0}, {"week": 4, "cash": 510.0}, {"week": 5, "cash": -1990.0}, {"week": 6, "cash": -4490.0}, {"week": 7, "cash": -6990.0}, {"week": 8, "cash": -9490.0}, {"week": 9, "cash": -11990.0}, {"week": 10, "cash": -14490.0}, {"week": 11, "cash": -16990.0}, {"week": 12, "cash": -19490.0}], "method": "Observed cash inflow and outflow projection"}	2026-06-24 10:28:24.098862
151	5	anomaly	transaction	50	91	{"anomaly_score": 91, "reasons": ["No single rule fired; score is driven by model distance"], "models": {"isolation_forest": -0.052, "one_class_svm": -1.415}, "average_score": 84.0, "flagged_count": 3}	2026-06-24 10:20:18.576732
154	5	runway	company	\N	24	{"projected_days": 24, "risk": "High", "forecast": [{"week": 1, "cash": 8010.0}, {"week": 2, "cash": 5510.0}, {"week": 3, "cash": 3010.0}, {"week": 4, "cash": 510.0}, {"week": 5, "cash": -1990.0}, {"week": 6, "cash": -4490.0}, {"week": 7, "cash": -6990.0}, {"week": 8, "cash": -9490.0}, {"week": 9, "cash": -11990.0}, {"week": 10, "cash": -14490.0}, {"week": 11, "cash": -16990.0}, {"week": 12, "cash": -19490.0}], "method": "Observed cash inflow and outflow projection"}	2026-06-24 10:20:19.132207
155	5	runway	company	\N	24	{"projected_days": 24, "risk": "High", "forecast": [{"week": 1, "cash": 8010.0}, {"week": 2, "cash": 5510.0}, {"week": 3, "cash": 3010.0}, {"week": 4, "cash": 510.0}, {"week": 5, "cash": -1990.0}, {"week": 6, "cash": -4490.0}, {"week": 7, "cash": -6990.0}, {"week": 8, "cash": -9490.0}, {"week": 9, "cash": -11990.0}, {"week": 10, "cash": -14490.0}, {"week": 11, "cash": -16990.0}, {"week": 12, "cash": -19490.0}], "method": "Observed cash inflow and outflow projection"}	2026-06-24 10:20:21.964826
160	5	anomaly	transaction	50	91	{"anomaly_score": 91, "reasons": ["No single rule fired; score is driven by model distance"], "models": {"isolation_forest": -0.052, "one_class_svm": -1.415}, "average_score": 84.0, "flagged_count": 3}	2026-06-24 10:28:18.917971
152	5	anomaly	transaction	50	91	{"anomaly_score": 91, "reasons": ["No single rule fired; score is driven by model distance"], "models": {"isolation_forest": -0.052, "one_class_svm": -1.415}, "average_score": 84.0, "flagged_count": 3}	2026-06-24 10:20:18.584392
156	5	runway	company	\N	24	{"projected_days": 24, "risk": "High", "forecast": [{"week": 1, "cash": 8010.0}, {"week": 2, "cash": 5510.0}, {"week": 3, "cash": 3010.0}, {"week": 4, "cash": 510.0}, {"week": 5, "cash": -1990.0}, {"week": 6, "cash": -4490.0}, {"week": 7, "cash": -6990.0}, {"week": 8, "cash": -9490.0}, {"week": 9, "cash": -11990.0}, {"week": 10, "cash": -14490.0}, {"week": 11, "cash": -16990.0}, {"week": 12, "cash": -19490.0}], "method": "Observed cash inflow and outflow projection"}	2026-06-24 10:20:21.975548
164	5	runway	company	\N	24	{"projected_days": 24, "risk": "High", "forecast": [{"week": 1, "cash": 8010.0}, {"week": 2, "cash": 5510.0}, {"week": 3, "cash": 3010.0}, {"week": 4, "cash": 510.0}, {"week": 5, "cash": -1990.0}, {"week": 6, "cash": -4490.0}, {"week": 7, "cash": -6990.0}, {"week": 8, "cash": -9490.0}, {"week": 9, "cash": -11990.0}, {"week": 10, "cash": -14490.0}, {"week": 11, "cash": -16990.0}, {"week": 12, "cash": -19490.0}], "method": "Observed cash inflow and outflow projection"}	2026-06-24 10:28:24.111621
153	5	runway	company	\N	24	{"projected_days": 24, "risk": "High", "forecast": [{"week": 1, "cash": 8010.0}, {"week": 2, "cash": 5510.0}, {"week": 3, "cash": 3010.0}, {"week": 4, "cash": 510.0}, {"week": 5, "cash": -1990.0}, {"week": 6, "cash": -4490.0}, {"week": 7, "cash": -6990.0}, {"week": 8, "cash": -9490.0}, {"week": 9, "cash": -11990.0}, {"week": 10, "cash": -14490.0}, {"week": 11, "cash": -16990.0}, {"week": 12, "cash": -19490.0}], "method": "Observed cash inflow and outflow projection"}	2026-06-24 10:20:19.118125
158	5	anomaly	transaction	50	91	{"anomaly_score": 91, "reasons": ["No single rule fired; score is driven by model distance"], "models": {"isolation_forest": -0.052, "one_class_svm": -1.415}, "average_score": 84.0, "flagged_count": 3}	2026-06-24 10:28:16.734686
161	5	runway	company	\N	24	{"projected_days": 24, "risk": "High", "forecast": [{"week": 1, "cash": 8010.0}, {"week": 2, "cash": 5510.0}, {"week": 3, "cash": 3010.0}, {"week": 4, "cash": 510.0}, {"week": 5, "cash": -1990.0}, {"week": 6, "cash": -4490.0}, {"week": 7, "cash": -6990.0}, {"week": 8, "cash": -9490.0}, {"week": 9, "cash": -11990.0}, {"week": 10, "cash": -14490.0}, {"week": 11, "cash": -16990.0}, {"week": 12, "cash": -19490.0}], "method": "Observed cash inflow and outflow projection"}	2026-06-24 10:28:19.40811
165	1	fx	currency	\N	100	{"recommendation": "Convert 75% now and hold 25%", "risk": "High", "volatility_score": 100, "trend": "weakening", "note": "Recommendation engine only; not a guarantee of market direction.", "confidence": "High"}	2026-06-24 17:51:52.068076
166	1	anomaly	transaction	8	100	{"anomaly_score": 100, "reasons": ["New or elevated-risk country pattern"], "models": {"isolation_forest": -0.033, "one_class_svm": -3.081}, "average_score": 73.3, "flagged_count": 16, "confidence": "High"}	2026-06-24 17:51:52.282341
167	4	anomaly	transaction	51	91	{"anomaly_score": 91, "reasons": ["No single rule fired; score is driven by model distance"], "models": {"isolation_forest": -0.052, "one_class_svm": -1.415}, "average_score": 84.0, "flagged_count": 3, "confidence": "Low"}	2026-06-25 11:23:04.387454
168	4	anomaly	transaction	51	91	{"anomaly_score": 91, "reasons": ["No single rule fired; score is driven by model distance"], "models": {"isolation_forest": -0.052, "one_class_svm": -1.415}, "average_score": 84.0, "flagged_count": 3, "confidence": "Low"}	2026-06-25 11:23:04.401954
169	4	runway	company	\N	365	{"projected_days": 365, "risk": "Low", "forecast": [{"week": 1, "cash": 36005.0}, {"week": 2, "cash": 37248.75}, {"week": 3, "cash": 38492.5}, {"week": 4, "cash": 39736.25}, {"week": 5, "cash": 40980.0}, {"week": 6, "cash": 42223.75}, {"week": 7, "cash": 43467.5}, {"week": 8, "cash": 44711.25}, {"week": 9, "cash": 45955.0}, {"week": 10, "cash": 47198.75}, {"week": 11, "cash": 48442.5}, {"week": 12, "cash": 49686.25}], "method": "Observed cash inflow and outflow projection", "confidence": "Low"}	2026-06-25 11:23:08.803561
170	4	runway	company	\N	365	{"projected_days": 365, "risk": "Low", "forecast": [{"week": 1, "cash": 36005.0}, {"week": 2, "cash": 37248.75}, {"week": 3, "cash": 38492.5}, {"week": 4, "cash": 39736.25}, {"week": 5, "cash": 40980.0}, {"week": 6, "cash": 42223.75}, {"week": 7, "cash": 43467.5}, {"week": 8, "cash": 44711.25}, {"week": 9, "cash": 45955.0}, {"week": 10, "cash": 47198.75}, {"week": 11, "cash": 48442.5}, {"week": 12, "cash": 49686.25}], "method": "Observed cash inflow and outflow projection", "confidence": "Low"}	2026-06-25 11:23:08.811544
171	4	anomaly	transaction	51	91	{"anomaly_score": 91, "reasons": ["No single rule fired; score is driven by model distance"], "models": {"isolation_forest": -0.052, "one_class_svm": -1.415}, "average_score": 84.0, "flagged_count": 3, "confidence": "Low"}	2026-06-25 11:34:56.724223
172	4	anomaly	transaction	51	91	{"anomaly_score": 91, "reasons": ["No single rule fired; score is driven by model distance"], "models": {"isolation_forest": -0.052, "one_class_svm": -1.415}, "average_score": 84.0, "flagged_count": 3, "confidence": "Low"}	2026-06-25 11:34:56.731573
173	5	anomaly	transaction	50	91	{"anomaly_score": 91, "reasons": ["No single rule fired; score is driven by model distance"], "models": {"isolation_forest": -0.052, "one_class_svm": -1.415}, "average_score": 84.0, "flagged_count": 3, "confidence": "Low"}	2026-06-26 05:37:02.194628
174	5	anomaly	transaction	50	91	{"anomaly_score": 91, "reasons": ["No single rule fired; score is driven by model distance"], "models": {"isolation_forest": -0.052, "one_class_svm": -1.415}, "average_score": 84.0, "flagged_count": 3, "confidence": "Low"}	2026-06-26 05:37:02.204899
175	5	anomaly	transaction	50	91	{"anomaly_score": 91, "reasons": ["No single rule fired; score is driven by model distance"], "models": {"isolation_forest": -0.052, "one_class_svm": -1.415}, "average_score": 84.0, "flagged_count": 3, "confidence": "Low"}	2026-06-26 05:37:02.213105
176	5	anomaly	transaction	50	91	{"anomaly_score": 91, "reasons": ["No single rule fired; score is driven by model distance"], "models": {"isolation_forest": -0.052, "one_class_svm": -1.415}, "average_score": 84.0, "flagged_count": 3, "confidence": "Low"}	2026-06-26 05:37:02.217684
177	5	anomaly	transaction	50	91	{"anomaly_score": 91, "reasons": ["No single rule fired; score is driven by model distance"], "models": {"isolation_forest": -0.052, "one_class_svm": -1.415}, "average_score": 84.0, "flagged_count": 3, "confidence": "Low"}	2026-06-26 05:37:02.225614
178	5	anomaly	transaction	50	91	{"anomaly_score": 91, "reasons": ["No single rule fired; score is driven by model distance"], "models": {"isolation_forest": -0.052, "one_class_svm": -1.415}, "average_score": 84.0, "flagged_count": 3, "confidence": "Low"}	2026-06-26 05:37:02.230928
179	5	anomaly	transaction	50	91	{"anomaly_score": 91, "reasons": ["No single rule fired; score is driven by model distance"], "models": {"isolation_forest": -0.052, "one_class_svm": -1.415}, "average_score": 84.0, "flagged_count": 3, "confidence": "Low"}	2026-06-26 05:37:02.262502
180	5	anomaly	transaction	50	91	{"anomaly_score": 91, "reasons": ["No single rule fired; score is driven by model distance"], "models": {"isolation_forest": -0.052, "one_class_svm": -1.415}, "average_score": 84.0, "flagged_count": 3, "confidence": "Low"}	2026-06-26 05:37:03.948459
181	5	anomaly	transaction	50	91	{"anomaly_score": 91, "reasons": ["No single rule fired; score is driven by model distance"], "models": {"isolation_forest": -0.052, "one_class_svm": -1.415}, "average_score": 84.0, "flagged_count": 3, "confidence": "Low"}	2026-06-26 05:37:03.982125
182	5	anomaly	transaction	50	91	{"anomaly_score": 91, "reasons": ["No single rule fired; score is driven by model distance"], "models": {"isolation_forest": -0.052, "one_class_svm": -1.415}, "average_score": 84.0, "flagged_count": 3, "confidence": "Low"}	2026-06-26 05:37:03.988475
183	5	anomaly	transaction	50	91	{"anomaly_score": 91, "reasons": ["No single rule fired; score is driven by model distance"], "models": {"isolation_forest": -0.052, "one_class_svm": -1.415}, "average_score": 84.0, "flagged_count": 3, "confidence": "Low"}	2026-06-26 05:37:04.012892
184	5	anomaly	transaction	50	91	{"anomaly_score": 91, "reasons": ["No single rule fired; score is driven by model distance"], "models": {"isolation_forest": -0.052, "one_class_svm": -1.415}, "average_score": 84.0, "flagged_count": 3, "confidence": "Low"}	2026-06-26 05:37:04.019524
185	5	anomaly	transaction	50	91	{"anomaly_score": 91, "reasons": ["No single rule fired; score is driven by model distance"], "models": {"isolation_forest": -0.052, "one_class_svm": -1.415}, "average_score": 84.0, "flagged_count": 3, "confidence": "Low"}	2026-06-26 05:37:04.024892
186	5	anomaly	transaction	50	91	{"anomaly_score": 91, "reasons": ["No single rule fired; score is driven by model distance"], "models": {"isolation_forest": -0.052, "one_class_svm": -1.415}, "average_score": 84.0, "flagged_count": 3, "confidence": "Low"}	2026-06-26 05:37:04.029078
187	5	anomaly	transaction	50	91	{"anomaly_score": 91, "reasons": ["No single rule fired; score is driven by model distance"], "models": {"isolation_forest": -0.052, "one_class_svm": -1.415}, "average_score": 84.0, "flagged_count": 3, "confidence": "Low"}	2026-06-26 05:37:04.042441
188	5	runway	company	\N	24	{"projected_days": 24, "risk": "High", "forecast": [{"week": 1, "cash": 8010.0}, {"week": 2, "cash": 5510.0}, {"week": 3, "cash": 3010.0}, {"week": 4, "cash": 510.0}, {"week": 5, "cash": -1990.0}, {"week": 6, "cash": -4490.0}, {"week": 7, "cash": -6990.0}, {"week": 8, "cash": -9490.0}, {"week": 9, "cash": -11990.0}, {"week": 10, "cash": -14490.0}, {"week": 11, "cash": -16990.0}, {"week": 12, "cash": -19490.0}], "method": "Observed cash inflow and outflow projection", "confidence": "Low"}	2026-06-26 05:37:04.557328
196	5	runway	company	\N	24	{"projected_days": 24, "risk": "High", "forecast": [{"week": 1, "cash": 8010.0}, {"week": 2, "cash": 5510.0}, {"week": 3, "cash": 3010.0}, {"week": 4, "cash": 510.0}, {"week": 5, "cash": -1990.0}, {"week": 6, "cash": -4490.0}, {"week": 7, "cash": -6990.0}, {"week": 8, "cash": -9490.0}, {"week": 9, "cash": -11990.0}, {"week": 10, "cash": -14490.0}, {"week": 11, "cash": -16990.0}, {"week": 12, "cash": -19490.0}], "method": "Observed cash inflow and outflow projection", "confidence": "Low"}	2026-06-26 05:37:04.660716
189	5	runway	company	\N	24	{"projected_days": 24, "risk": "High", "forecast": [{"week": 1, "cash": 8010.0}, {"week": 2, "cash": 5510.0}, {"week": 3, "cash": 3010.0}, {"week": 4, "cash": 510.0}, {"week": 5, "cash": -1990.0}, {"week": 6, "cash": -4490.0}, {"week": 7, "cash": -6990.0}, {"week": 8, "cash": -9490.0}, {"week": 9, "cash": -11990.0}, {"week": 10, "cash": -14490.0}, {"week": 11, "cash": -16990.0}, {"week": 12, "cash": -19490.0}], "method": "Observed cash inflow and outflow projection", "confidence": "Low"}	2026-06-26 05:37:04.565192
195	5	runway	company	\N	24	{"projected_days": 24, "risk": "High", "forecast": [{"week": 1, "cash": 8010.0}, {"week": 2, "cash": 5510.0}, {"week": 3, "cash": 3010.0}, {"week": 4, "cash": 510.0}, {"week": 5, "cash": -1990.0}, {"week": 6, "cash": -4490.0}, {"week": 7, "cash": -6990.0}, {"week": 8, "cash": -9490.0}, {"week": 9, "cash": -11990.0}, {"week": 10, "cash": -14490.0}, {"week": 11, "cash": -16990.0}, {"week": 12, "cash": -19490.0}], "method": "Observed cash inflow and outflow projection", "confidence": "Low"}	2026-06-26 05:37:04.656984
190	5	runway	company	\N	24	{"projected_days": 24, "risk": "High", "forecast": [{"week": 1, "cash": 8010.0}, {"week": 2, "cash": 5510.0}, {"week": 3, "cash": 3010.0}, {"week": 4, "cash": 510.0}, {"week": 5, "cash": -1990.0}, {"week": 6, "cash": -4490.0}, {"week": 7, "cash": -6990.0}, {"week": 8, "cash": -9490.0}, {"week": 9, "cash": -11990.0}, {"week": 10, "cash": -14490.0}, {"week": 11, "cash": -16990.0}, {"week": 12, "cash": -19490.0}], "method": "Observed cash inflow and outflow projection", "confidence": "Low"}	2026-06-26 05:37:04.569171
194	5	runway	company	\N	24	{"projected_days": 24, "risk": "High", "forecast": [{"week": 1, "cash": 8010.0}, {"week": 2, "cash": 5510.0}, {"week": 3, "cash": 3010.0}, {"week": 4, "cash": 510.0}, {"week": 5, "cash": -1990.0}, {"week": 6, "cash": -4490.0}, {"week": 7, "cash": -6990.0}, {"week": 8, "cash": -9490.0}, {"week": 9, "cash": -11990.0}, {"week": 10, "cash": -14490.0}, {"week": 11, "cash": -16990.0}, {"week": 12, "cash": -19490.0}], "method": "Observed cash inflow and outflow projection", "confidence": "Low"}	2026-06-26 05:37:04.651587
191	5	runway	company	\N	24	{"projected_days": 24, "risk": "High", "forecast": [{"week": 1, "cash": 8010.0}, {"week": 2, "cash": 5510.0}, {"week": 3, "cash": 3010.0}, {"week": 4, "cash": 510.0}, {"week": 5, "cash": -1990.0}, {"week": 6, "cash": -4490.0}, {"week": 7, "cash": -6990.0}, {"week": 8, "cash": -9490.0}, {"week": 9, "cash": -11990.0}, {"week": 10, "cash": -14490.0}, {"week": 11, "cash": -16990.0}, {"week": 12, "cash": -19490.0}], "method": "Observed cash inflow and outflow projection", "confidence": "Low"}	2026-06-26 05:37:04.572545
192	5	runway	company	\N	24	{"projected_days": 24, "risk": "High", "forecast": [{"week": 1, "cash": 8010.0}, {"week": 2, "cash": 5510.0}, {"week": 3, "cash": 3010.0}, {"week": 4, "cash": 510.0}, {"week": 5, "cash": -1990.0}, {"week": 6, "cash": -4490.0}, {"week": 7, "cash": -6990.0}, {"week": 8, "cash": -9490.0}, {"week": 9, "cash": -11990.0}, {"week": 10, "cash": -14490.0}, {"week": 11, "cash": -16990.0}, {"week": 12, "cash": -19490.0}], "method": "Observed cash inflow and outflow projection", "confidence": "Low"}	2026-06-26 05:37:04.576079
197	4	anomaly	transaction	51	91	{"anomaly_score": 91, "reasons": ["No single rule fired; score is driven by model distance"], "models": {"isolation_forest": -0.052, "one_class_svm": -1.415}, "average_score": 84.0, "flagged_count": 3, "confidence": "Low"}	2026-06-26 05:47:58.229141
200	4	runway	company	\N	365	{"projected_days": 365, "risk": "Low", "forecast": [{"week": 1, "cash": 36005.0}, {"week": 2, "cash": 37248.75}, {"week": 3, "cash": 38492.5}, {"week": 4, "cash": 39736.25}, {"week": 5, "cash": 40980.0}, {"week": 6, "cash": 42223.75}, {"week": 7, "cash": 43467.5}, {"week": 8, "cash": 44711.25}, {"week": 9, "cash": 45955.0}, {"week": 10, "cash": 47198.75}, {"week": 11, "cash": 48442.5}, {"week": 12, "cash": 49686.25}], "method": "Observed cash inflow and outflow projection", "confidence": "Low"}	2026-06-26 05:47:58.642017
193	5	runway	company	\N	24	{"projected_days": 24, "risk": "High", "forecast": [{"week": 1, "cash": 8010.0}, {"week": 2, "cash": 5510.0}, {"week": 3, "cash": 3010.0}, {"week": 4, "cash": 510.0}, {"week": 5, "cash": -1990.0}, {"week": 6, "cash": -4490.0}, {"week": 7, "cash": -6990.0}, {"week": 8, "cash": -9490.0}, {"week": 9, "cash": -11990.0}, {"week": 10, "cash": -14490.0}, {"week": 11, "cash": -16990.0}, {"week": 12, "cash": -19490.0}], "method": "Observed cash inflow and outflow projection", "confidence": "Low"}	2026-06-26 05:37:04.582297
198	4	anomaly	transaction	51	91	{"anomaly_score": 91, "reasons": ["No single rule fired; score is driven by model distance"], "models": {"isolation_forest": -0.052, "one_class_svm": -1.415}, "average_score": 84.0, "flagged_count": 3, "confidence": "Low"}	2026-06-26 05:47:58.241421
199	4	runway	company	\N	365	{"projected_days": 365, "risk": "Low", "forecast": [{"week": 1, "cash": 36005.0}, {"week": 2, "cash": 37248.75}, {"week": 3, "cash": 38492.5}, {"week": 4, "cash": 39736.25}, {"week": 5, "cash": 40980.0}, {"week": 6, "cash": 42223.75}, {"week": 7, "cash": 43467.5}, {"week": 8, "cash": 44711.25}, {"week": 9, "cash": 45955.0}, {"week": 10, "cash": 47198.75}, {"week": 11, "cash": 48442.5}, {"week": 12, "cash": 49686.25}], "method": "Observed cash inflow and outflow projection", "confidence": "Low"}	2026-06-26 05:47:58.636829
201	4	anomaly	transaction	51	91	{"anomaly_score": 91, "reasons": ["No single rule fired; score is driven by model distance"], "models": {"isolation_forest": -0.052, "one_class_svm": -1.415}, "average_score": 84.0, "flagged_count": 3, "confidence": "Low"}	2026-06-26 05:49:58.34623
202	4	anomaly	transaction	51	91	{"anomaly_score": 91, "reasons": ["No single rule fired; score is driven by model distance"], "models": {"isolation_forest": -0.052, "one_class_svm": -1.415}, "average_score": 84.0, "flagged_count": 3, "confidence": "Low"}	2026-06-26 05:49:58.356268
203	5	anomaly	transaction	50	91	{"anomaly_score": 91, "reasons": ["No single rule fired; score is driven by model distance"], "models": {"isolation_forest": -0.052, "one_class_svm": -1.415}, "average_score": 84.0, "flagged_count": 3, "confidence": "Low"}	2026-06-26 06:02:13.532503
204	5	anomaly	transaction	50	91	{"anomaly_score": 91, "reasons": ["No single rule fired; score is driven by model distance"], "models": {"isolation_forest": -0.052, "one_class_svm": -1.415}, "average_score": 84.0, "flagged_count": 3, "confidence": "Low"}	2026-06-26 06:02:13.551189
205	5	anomaly	transaction	50	91	{"anomaly_score": 91, "reasons": ["No single rule fired; score is driven by model distance"], "models": {"isolation_forest": -0.052, "one_class_svm": -1.415}, "average_score": 84.0, "flagged_count": 3, "confidence": "Low"}	2026-06-26 06:02:13.559365
206	5	anomaly	transaction	50	91	{"anomaly_score": 91, "reasons": ["No single rule fired; score is driven by model distance"], "models": {"isolation_forest": -0.052, "one_class_svm": -1.415}, "average_score": 84.0, "flagged_count": 3, "confidence": "Low"}	2026-06-26 06:02:13.569583
207	5	anomaly	transaction	50	91	{"anomaly_score": 91, "reasons": ["No single rule fired; score is driven by model distance"], "models": {"isolation_forest": -0.052, "one_class_svm": -1.415}, "average_score": 84.0, "flagged_count": 3, "confidence": "Low"}	2026-06-26 06:02:13.578608
208	5	anomaly	transaction	50	91	{"anomaly_score": 91, "reasons": ["No single rule fired; score is driven by model distance"], "models": {"isolation_forest": -0.052, "one_class_svm": -1.415}, "average_score": 84.0, "flagged_count": 3, "confidence": "Low"}	2026-06-26 06:02:13.588346
209	5	anomaly	transaction	50	91	{"anomaly_score": 91, "reasons": ["No single rule fired; score is driven by model distance"], "models": {"isolation_forest": -0.052, "one_class_svm": -1.415}, "average_score": 84.0, "flagged_count": 3, "confidence": "Low"}	2026-06-26 06:02:13.672732
210	5	anomaly	transaction	50	91	{"anomaly_score": 91, "reasons": ["No single rule fired; score is driven by model distance"], "models": {"isolation_forest": -0.052, "one_class_svm": -1.415}, "average_score": 84.0, "flagged_count": 3, "confidence": "Low"}	2026-06-26 06:02:13.685244
211	5	runway	company	\N	24	{"projected_days": 24, "risk": "High", "forecast": [{"week": 1, "cash": 8010.0}, {"week": 2, "cash": 5510.0}, {"week": 3, "cash": 3010.0}, {"week": 4, "cash": 510.0}, {"week": 5, "cash": -1990.0}, {"week": 6, "cash": -4490.0}, {"week": 7, "cash": -6990.0}, {"week": 8, "cash": -9490.0}, {"week": 9, "cash": -11990.0}, {"week": 10, "cash": -14490.0}, {"week": 11, "cash": -16990.0}, {"week": 12, "cash": -19490.0}], "method": "Observed cash inflow and outflow projection", "confidence": "Low"}	2026-06-26 06:02:21.197189
212	5	runway	company	\N	24	{"projected_days": 24, "risk": "High", "forecast": [{"week": 1, "cash": 8010.0}, {"week": 2, "cash": 5510.0}, {"week": 3, "cash": 3010.0}, {"week": 4, "cash": 510.0}, {"week": 5, "cash": -1990.0}, {"week": 6, "cash": -4490.0}, {"week": 7, "cash": -6990.0}, {"week": 8, "cash": -9490.0}, {"week": 9, "cash": -11990.0}, {"week": 10, "cash": -14490.0}, {"week": 11, "cash": -16990.0}, {"week": 12, "cash": -19490.0}], "method": "Observed cash inflow and outflow projection", "confidence": "Low"}	2026-06-26 06:02:21.207325
213	5	runway	company	\N	24	{"projected_days": 24, "risk": "High", "forecast": [{"week": 1, "cash": 8010.0}, {"week": 2, "cash": 5510.0}, {"week": 3, "cash": 3010.0}, {"week": 4, "cash": 510.0}, {"week": 5, "cash": -1990.0}, {"week": 6, "cash": -4490.0}, {"week": 7, "cash": -6990.0}, {"week": 8, "cash": -9490.0}, {"week": 9, "cash": -11990.0}, {"week": 10, "cash": -14490.0}, {"week": 11, "cash": -16990.0}, {"week": 12, "cash": -19490.0}], "method": "Observed cash inflow and outflow projection", "confidence": "Low"}	2026-06-26 06:02:21.212359
214	5	runway	company	\N	24	{"projected_days": 24, "risk": "High", "forecast": [{"week": 1, "cash": 8010.0}, {"week": 2, "cash": 5510.0}, {"week": 3, "cash": 3010.0}, {"week": 4, "cash": 510.0}, {"week": 5, "cash": -1990.0}, {"week": 6, "cash": -4490.0}, {"week": 7, "cash": -6990.0}, {"week": 8, "cash": -9490.0}, {"week": 9, "cash": -11990.0}, {"week": 10, "cash": -14490.0}, {"week": 11, "cash": -16990.0}, {"week": 12, "cash": -19490.0}], "method": "Observed cash inflow and outflow projection", "confidence": "Low"}	2026-06-26 06:02:21.217094
215	5	runway	company	\N	24	{"projected_days": 24, "risk": "High", "forecast": [{"week": 1, "cash": 8010.0}, {"week": 2, "cash": 5510.0}, {"week": 3, "cash": 3010.0}, {"week": 4, "cash": 510.0}, {"week": 5, "cash": -1990.0}, {"week": 6, "cash": -4490.0}, {"week": 7, "cash": -6990.0}, {"week": 8, "cash": -9490.0}, {"week": 9, "cash": -11990.0}, {"week": 10, "cash": -14490.0}, {"week": 11, "cash": -16990.0}, {"week": 12, "cash": -19490.0}], "method": "Observed cash inflow and outflow projection", "confidence": "Low"}	2026-06-26 06:02:21.221785
216	5	runway	company	\N	24	{"projected_days": 24, "risk": "High", "forecast": [{"week": 1, "cash": 8010.0}, {"week": 2, "cash": 5510.0}, {"week": 3, "cash": 3010.0}, {"week": 4, "cash": 510.0}, {"week": 5, "cash": -1990.0}, {"week": 6, "cash": -4490.0}, {"week": 7, "cash": -6990.0}, {"week": 8, "cash": -9490.0}, {"week": 9, "cash": -11990.0}, {"week": 10, "cash": -14490.0}, {"week": 11, "cash": -16990.0}, {"week": 12, "cash": -19490.0}], "method": "Observed cash inflow and outflow projection", "confidence": "Low"}	2026-06-26 06:02:21.227559
217	5	runway	company	\N	24	{"projected_days": 24, "risk": "High", "forecast": [{"week": 1, "cash": 8010.0}, {"week": 2, "cash": 5510.0}, {"week": 3, "cash": 3010.0}, {"week": 4, "cash": 510.0}, {"week": 5, "cash": -1990.0}, {"week": 6, "cash": -4490.0}, {"week": 7, "cash": -6990.0}, {"week": 8, "cash": -9490.0}, {"week": 9, "cash": -11990.0}, {"week": 10, "cash": -14490.0}, {"week": 11, "cash": -16990.0}, {"week": 12, "cash": -19490.0}], "method": "Observed cash inflow and outflow projection", "confidence": "Low"}	2026-06-26 06:02:21.338838
218	5	runway	company	\N	24	{"projected_days": 24, "risk": "High", "forecast": [{"week": 1, "cash": 8010.0}, {"week": 2, "cash": 5510.0}, {"week": 3, "cash": 3010.0}, {"week": 4, "cash": 510.0}, {"week": 5, "cash": -1990.0}, {"week": 6, "cash": -4490.0}, {"week": 7, "cash": -6990.0}, {"week": 8, "cash": -9490.0}, {"week": 9, "cash": -11990.0}, {"week": 10, "cash": -14490.0}, {"week": 11, "cash": -16990.0}, {"week": 12, "cash": -19490.0}], "method": "Observed cash inflow and outflow projection", "confidence": "Low"}	2026-06-26 06:02:21.351551
219	5	runway	company	\N	24	{"projected_days": 24, "risk": "High", "forecast": [{"week": 1, "cash": 8010.0}, {"week": 2, "cash": 5510.0}, {"week": 3, "cash": 3010.0}, {"week": 4, "cash": 510.0}, {"week": 5, "cash": -1990.0}, {"week": 6, "cash": -4490.0}, {"week": 7, "cash": -6990.0}, {"week": 8, "cash": -9490.0}, {"week": 9, "cash": -11990.0}, {"week": 10, "cash": -14490.0}, {"week": 11, "cash": -16990.0}, {"week": 12, "cash": -19490.0}], "method": "Observed cash inflow and outflow projection", "confidence": "Low"}	2026-06-26 06:02:21.358105
223	5	runway	company	\N	24	{"projected_days": 24, "risk": "High", "forecast": [{"week": 1, "cash": 8010.0}, {"week": 2, "cash": 5510.0}, {"week": 3, "cash": 3010.0}, {"week": 4, "cash": 510.0}, {"week": 5, "cash": -1990.0}, {"week": 6, "cash": -4490.0}, {"week": 7, "cash": -6990.0}, {"week": 8, "cash": -9490.0}, {"week": 9, "cash": -11990.0}, {"week": 10, "cash": -14490.0}, {"week": 11, "cash": -16990.0}, {"week": 12, "cash": -19490.0}], "method": "Observed cash inflow and outflow projection", "confidence": "Low"}	2026-06-26 06:19:38.298596
220	5	runway	company	\N	24	{"projected_days": 24, "risk": "High", "forecast": [{"week": 1, "cash": 8010.0}, {"week": 2, "cash": 5510.0}, {"week": 3, "cash": 3010.0}, {"week": 4, "cash": 510.0}, {"week": 5, "cash": -1990.0}, {"week": 6, "cash": -4490.0}, {"week": 7, "cash": -6990.0}, {"week": 8, "cash": -9490.0}, {"week": 9, "cash": -11990.0}, {"week": 10, "cash": -14490.0}, {"week": 11, "cash": -16990.0}, {"week": 12, "cash": -19490.0}], "method": "Observed cash inflow and outflow projection", "confidence": "Low"}	2026-06-26 06:02:21.363788
221	5	anomaly	transaction	50	91	{"anomaly_score": 91, "reasons": ["No single rule fired; score is driven by model distance"], "models": {"isolation_forest": -0.052, "one_class_svm": -1.415}, "average_score": 84.0, "flagged_count": 3, "confidence": "Low"}	2026-06-26 06:19:36.985358
222	5	anomaly	transaction	50	91	{"anomaly_score": 91, "reasons": ["No single rule fired; score is driven by model distance"], "models": {"isolation_forest": -0.052, "one_class_svm": -1.415}, "average_score": 84.0, "flagged_count": 3, "confidence": "Low"}	2026-06-26 06:19:36.999317
224	5	runway	company	\N	24	{"projected_days": 24, "risk": "High", "forecast": [{"week": 1, "cash": 8010.0}, {"week": 2, "cash": 5510.0}, {"week": 3, "cash": 3010.0}, {"week": 4, "cash": 510.0}, {"week": 5, "cash": -1990.0}, {"week": 6, "cash": -4490.0}, {"week": 7, "cash": -6990.0}, {"week": 8, "cash": -9490.0}, {"week": 9, "cash": -11990.0}, {"week": 10, "cash": -14490.0}, {"week": 11, "cash": -16990.0}, {"week": 12, "cash": -19490.0}], "method": "Observed cash inflow and outflow projection", "confidence": "Low"}	2026-06-26 06:19:38.310527
\.


--
-- Data for Name: quick_links; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.quick_links (id, user_id, public_id, title, payer_name, payer_email, payer_country, amount, currency, purpose_code, status, provider, provider_mode, checkout_id, checkout_url, invoice_id, payment_id, expires_at, paid_at, created_at) FROM stdin;
\.


--
-- Data for Name: reconciliation_runs; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.reconciliation_runs (id, user_id, status, checked_count, matched_count, exception_count, exceptions, started_at, completed_at) FROM stdin;
\.


--
-- Data for Name: refunds; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.refunds (id, user_id, payment_id, amount, currency, reason, status, provider_ref, idempotency_key, created_at, completed_at) FROM stdin;
\.


--
-- Data for Name: transactions; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.transactions (id, user_id, payment_id, type, amount, currency, country, counterparty, risk_score, created_at) FROM stdin;
1	1	1	inbound	5538.38	AED	AE	Kairo Retail Group	43	2026-07-08 11:00:00
2	1	2	inbound	14872.34	EUR	DE	Blue Harbor GmbH	29	2026-06-27 18:00:00
3	1	3	inbound	10585.51	JPY	JP	Sakura Supply KK	44	2026-07-01 08:00:00
4	1	4	inbound	22461.86	CAD	CA	Maple Cloud Ltd	37	2026-06-25 08:00:00
5	1	5	inbound	19705.27	USD	US	Northstar Robotics	23	2026-06-17 14:00:00
6	1	6	inbound	40110.54	AED	AE	Kairo Retail Group	36	2026-06-02 20:00:00
7	1	7	inbound	16512.23	JPY	JP	Sakura Supply KK	52	2026-05-26 13:00:00
8	1	8	inbound	16171.58	ZAR	ZA	Atlas Minerals	62	2026-05-17 09:00:00
9	1	9	inbound	34464.08	CAD	CA	Maple Cloud Ltd	31	2026-05-12 21:00:00
10	1	10	inbound	69280.95	AED	AE	Kairo Retail Group	39	2026-05-03 16:00:00
11	1	11	inbound	82808.93	EUR	DE	Blue Harbor GmbH	29	2026-04-25 09:00:00
12	1	12	inbound	27394.03	JPY	JP	Sakura Supply KK	55	2026-04-26 22:00:00
13	1	13	inbound	60922.6	CAD	CA	Maple Cloud Ltd	27	2026-03-27 18:00:00
14	1	14	inbound	66505.07	USD	US	Northstar Robotics	23	2026-03-22 21:00:00
15	1	15	inbound	74118.42	AED	AE	Kairo Retail Group	50	2026-03-26 12:00:00
16	1	16	inbound	33233.82	JPY	JP	Sakura Supply KK	50	2026-03-13 13:00:00
17	1	17	inbound	58119.28	ZAR	ZA	Atlas Minerals	80	2026-02-26 17:00:00
18	1	18	inbound	17447.8	CAD	CA	Maple Cloud Ltd	34	2026-02-25 10:00:00
19	1	19	inbound	84146.15	AED	AE	Kairo Retail Group	57	2026-02-23 11:00:00
20	1	20	inbound	29929.04	EUR	DE	Blue Harbor GmbH	13	2026-02-01 11:00:00
21	1	21	inbound	69111.23	JPY	JP	Sakura Supply KK	46	2026-02-06 12:00:00
22	1	22	inbound	80347.14	CAD	CA	Maple Cloud Ltd	40	2026-01-23 11:00:00
23	1	23	inbound	44187.35	USD	US	Northstar Robotics	24	2026-01-21 10:00:00
24	1	24	inbound	14879.87	AED	AE	Kairo Retail Group	44	2026-01-18 16:00:00
25	1	25	inbound	38417.36	JPY	JP	Sakura Supply KK	55	2026-01-07 14:00:00
26	1	26	inbound	21374.64	ZAR	ZA	Atlas Minerals	75	2025-12-18 16:00:00
27	1	27	inbound	10909.12	CAD	CA	Maple Cloud Ltd	23	2025-12-09 21:00:00
28	1	28	inbound	16538.53	AED	AE	Kairo Retail Group	38	2025-12-09 17:00:00
29	1	29	inbound	34858.54	EUR	DE	Blue Harbor GmbH	28	2025-12-09 15:00:00
30	1	30	inbound	23990.25	JPY	JP	Sakura Supply KK	44	2025-12-01 21:00:00
31	1	31	inbound	12835.97	CAD	CA	Maple Cloud Ltd	28	2025-11-19 20:00:00
48	4	48	outbound	50	INR	IN	Rohan Kapoor	5	2026-06-23 08:39:40.345117
49	5	49	inbound	50	INR	IN	Asha Mehta	5	2026-06-23 08:39:40.34512
50	5	50	outbound	50	INR	IN	Asha Mehta	5	2026-06-24 07:56:15.185544
51	4	51	inbound	50	INR	IN	Rohan Kapoor	5	2026-06-24 07:56:15.185548
52	5	52	outbound	10000	INR	IN	Asha Mehta	5	2026-06-24 09:59:47.001996
53	4	53	inbound	10000	INR	IN	Rohan Kapoor	5	2026-06-24 09:59:47.001998
\.


--
-- Data for Name: users; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.users (id, email, name, account_type, workspace_name, hashed_password, role, is_active, created_at, email_verified, mfa_enabled, mfa_secret, workspace_key) FROM stdin;
1	admin@ledgerops.ai	Avery Shah	company	LedgerOps workspace	$2b$12$BKUM8rN8ilWXYamBdd5.CeWyvIohgx7qvzYXYnbk8IlgL2/UlBGNO	admin	t	2026-06-17 17:13:15.097828	f	f	\N	683357e85e637ff083537c2c6c763612b41f73124d38ceba
2	finance@ledgerops.ai	Mira Chen	company	LedgerOps workspace	$2b$12$KRdcZeXbLY5kh4gkL34yierS/MEt.HI2YWxAKfhs8z8.EkhH/Dy76	finance_manager	t	2026-06-17 17:13:15.097833	f	f	\N	683357e85e637ff083537c2c6c763612b41f73124d38ceba
3	viewer@ledgerops.ai	Leo Grant	company	LedgerOps workspace	$2b$12$SM3EcDIl.U0aHZ7sN0FhVe46KDhRQ8thipP76GmHoYiLw8clh984G	viewer	t	2026-06-17 17:13:15.097837	f	f	\N	683357e85e637ff083537c2c6c763612b41f73124d38ceba
4	asha.demo@ledgerops.ai	Asha Mehta	individual	Asha Mehta's demo wallet	$2b$12$rKMfipk2P./fyClrmI0uJOE2PwWgxQvEMI5LlBTu8PXw42W7WkL/6	admin	t	2026-06-23 06:44:39.903621	f	f	\N	96f0bff74a5165fe124a7fd40bd96af0d8ebf26e34c6aa77
5	rohan.demo@ledgerops.ai	Rohan Kapoor	individual	Rohan Kapoor's demo wallet	$2b$12$vqtrnkD22FpCk4d3QGdV9ORnyDN7q52R4fmoORI6Hw6Yy6rHW6SKu	admin	t	2026-06-23 06:44:41.312974	f	f	\N	856c500310e0b91cb001245c65a8fb4b5042076128fa6a01
\.


--
-- Name: account_preferences_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.account_preferences_id_seq', 3, true);


--
-- Name: alerts_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.alerts_id_seq', 3, true);


--
-- Name: audit_logs_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.audit_logs_id_seq', 5, true);


--
-- Name: auth_sessions_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.auth_sessions_id_seq', 44, true);


--
-- Name: compliance_checks_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.compliance_checks_id_seq', 89, true);


--
-- Name: customers_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.customers_id_seq', 16, true);


--
-- Name: demo_messages_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.demo_messages_id_seq', 16, true);


--
-- Name: demo_wallets_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.demo_wallets_id_seq', 2, true);


--
-- Name: email_verification_tokens_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.email_verification_tokens_id_seq', 1, false);


--
-- Name: event_logs_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.event_logs_id_seq', 14, true);


--
-- Name: fx_rates_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.fx_rates_id_seq', 210, true);


--
-- Name: invoices_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.invoices_id_seq', 42, true);


--
-- Name: password_reset_tokens_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.password_reset_tokens_id_seq', 1, false);


--
-- Name: payment_methods_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.payment_methods_id_seq', 3, true);


--
-- Name: payments_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.payments_id_seq', 54, true);


--
-- Name: predictions_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.predictions_id_seq', 224, true);


--
-- Name: quick_links_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.quick_links_id_seq', 5, true);


--
-- Name: reconciliation_runs_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.reconciliation_runs_id_seq', 1, false);


--
-- Name: refunds_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.refunds_id_seq', 1, false);


--
-- Name: transactions_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.transactions_id_seq', 54, true);


--
-- Name: users_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.users_id_seq', 5, true);


--
-- Name: account_preferences account_preferences_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.account_preferences
    ADD CONSTRAINT account_preferences_pkey PRIMARY KEY (id);


--
-- Name: alembic_version alembic_version_pkc; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.alembic_version
    ADD CONSTRAINT alembic_version_pkc PRIMARY KEY (version_num);


--
-- Name: alerts alerts_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.alerts
    ADD CONSTRAINT alerts_pkey PRIMARY KEY (id);


--
-- Name: audit_logs audit_logs_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.audit_logs
    ADD CONSTRAINT audit_logs_pkey PRIMARY KEY (id);


--
-- Name: auth_sessions auth_sessions_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.auth_sessions
    ADD CONSTRAINT auth_sessions_pkey PRIMARY KEY (id);


--
-- Name: compliance_checks compliance_checks_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.compliance_checks
    ADD CONSTRAINT compliance_checks_pkey PRIMARY KEY (id);


--
-- Name: customers customers_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.customers
    ADD CONSTRAINT customers_pkey PRIMARY KEY (id);


--
-- Name: demo_messages demo_messages_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.demo_messages
    ADD CONSTRAINT demo_messages_pkey PRIMARY KEY (id);


--
-- Name: demo_wallets demo_wallets_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.demo_wallets
    ADD CONSTRAINT demo_wallets_pkey PRIMARY KEY (id);


--
-- Name: email_verification_tokens email_verification_tokens_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.email_verification_tokens
    ADD CONSTRAINT email_verification_tokens_pkey PRIMARY KEY (id);


--
-- Name: event_logs event_logs_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.event_logs
    ADD CONSTRAINT event_logs_pkey PRIMARY KEY (id);


--
-- Name: fx_rates fx_rates_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.fx_rates
    ADD CONSTRAINT fx_rates_pkey PRIMARY KEY (id);


--
-- Name: invoices invoices_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.invoices
    ADD CONSTRAINT invoices_pkey PRIMARY KEY (id);


--
-- Name: password_reset_tokens password_reset_tokens_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.password_reset_tokens
    ADD CONSTRAINT password_reset_tokens_pkey PRIMARY KEY (id);


--
-- Name: payment_methods payment_methods_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.payment_methods
    ADD CONSTRAINT payment_methods_pkey PRIMARY KEY (id);


--
-- Name: payments payments_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.payments
    ADD CONSTRAINT payments_pkey PRIMARY KEY (id);


--
-- Name: predictions predictions_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.predictions
    ADD CONSTRAINT predictions_pkey PRIMARY KEY (id);


--
-- Name: quick_links quick_links_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.quick_links
    ADD CONSTRAINT quick_links_pkey PRIMARY KEY (id);


--
-- Name: reconciliation_runs reconciliation_runs_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.reconciliation_runs
    ADD CONSTRAINT reconciliation_runs_pkey PRIMARY KEY (id);


--
-- Name: refunds refunds_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.refunds
    ADD CONSTRAINT refunds_pkey PRIMARY KEY (id);


--
-- Name: refunds refunds_provider_ref_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.refunds
    ADD CONSTRAINT refunds_provider_ref_key UNIQUE (provider_ref);


--
-- Name: transactions transactions_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.transactions
    ADD CONSTRAINT transactions_pkey PRIMARY KEY (id);


--
-- Name: invoices uq_invoices_workspace_number; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.invoices
    ADD CONSTRAINT uq_invoices_workspace_number UNIQUE (workspace_key, invoice_number);


--
-- Name: users users_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_pkey PRIMARY KEY (id);


--
-- Name: ix_account_preferences_user_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE UNIQUE INDEX ix_account_preferences_user_id ON public.account_preferences USING btree (user_id);


--
-- Name: ix_alerts_user_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX ix_alerts_user_id ON public.alerts USING btree (user_id);


--
-- Name: ix_audit_logs_action; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX ix_audit_logs_action ON public.audit_logs USING btree (action);


--
-- Name: ix_audit_logs_created_at; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX ix_audit_logs_created_at ON public.audit_logs USING btree (created_at);


--
-- Name: ix_audit_logs_user_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX ix_audit_logs_user_id ON public.audit_logs USING btree (user_id);


--
-- Name: ix_audit_logs_workspace_name; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX ix_audit_logs_workspace_name ON public.audit_logs USING btree (workspace_name);


--
-- Name: ix_auth_sessions_expires_at; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX ix_auth_sessions_expires_at ON public.auth_sessions USING btree (expires_at);


--
-- Name: ix_auth_sessions_refresh_token_hash; Type: INDEX; Schema: public; Owner: postgres
--

CREATE UNIQUE INDEX ix_auth_sessions_refresh_token_hash ON public.auth_sessions USING btree (refresh_token_hash);


--
-- Name: ix_auth_sessions_session_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE UNIQUE INDEX ix_auth_sessions_session_id ON public.auth_sessions USING btree (session_id);


--
-- Name: ix_auth_sessions_user_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX ix_auth_sessions_user_id ON public.auth_sessions USING btree (user_id);


--
-- Name: ix_compliance_checks_user_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX ix_compliance_checks_user_id ON public.compliance_checks USING btree (user_id);


--
-- Name: ix_customers_name; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX ix_customers_name ON public.customers USING btree (name);


--
-- Name: ix_customers_user_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX ix_customers_user_id ON public.customers USING btree (user_id);


--
-- Name: ix_demo_messages_created_at; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX ix_demo_messages_created_at ON public.demo_messages USING btree (created_at);


--
-- Name: ix_demo_messages_recipient_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX ix_demo_messages_recipient_id ON public.demo_messages USING btree (recipient_id);


--
-- Name: ix_demo_messages_sender_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX ix_demo_messages_sender_id ON public.demo_messages USING btree (sender_id);


--
-- Name: ix_demo_wallets_user_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE UNIQUE INDEX ix_demo_wallets_user_id ON public.demo_wallets USING btree (user_id);


--
-- Name: ix_email_verification_tokens_token_hash; Type: INDEX; Schema: public; Owner: postgres
--

CREATE UNIQUE INDEX ix_email_verification_tokens_token_hash ON public.email_verification_tokens USING btree (token_hash);


--
-- Name: ix_email_verification_tokens_user_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX ix_email_verification_tokens_user_id ON public.email_verification_tokens USING btree (user_id);


--
-- Name: ix_event_logs_event_type; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX ix_event_logs_event_type ON public.event_logs USING btree (event_type);


--
-- Name: ix_event_logs_user_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX ix_event_logs_user_id ON public.event_logs USING btree (user_id);


--
-- Name: ix_invoices_invoice_number; Type: INDEX; Schema: public; Owner: postgres
--

CREATE UNIQUE INDEX ix_invoices_invoice_number ON public.invoices USING btree (invoice_number);


--
-- Name: ix_invoices_user_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX ix_invoices_user_id ON public.invoices USING btree (user_id);


--
-- Name: ix_invoices_workspace_key; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX ix_invoices_workspace_key ON public.invoices USING btree (workspace_key);


--
-- Name: ix_password_reset_tokens_token_hash; Type: INDEX; Schema: public; Owner: postgres
--

CREATE UNIQUE INDEX ix_password_reset_tokens_token_hash ON public.password_reset_tokens USING btree (token_hash);


--
-- Name: ix_password_reset_tokens_user_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX ix_password_reset_tokens_user_id ON public.password_reset_tokens USING btree (user_id);


--
-- Name: ix_payment_methods_user_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX ix_payment_methods_user_id ON public.payment_methods USING btree (user_id);


--
-- Name: ix_payments_external_ref; Type: INDEX; Schema: public; Owner: postgres
--

CREATE UNIQUE INDEX ix_payments_external_ref ON public.payments USING btree (external_ref);


--
-- Name: ix_payments_user_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX ix_payments_user_id ON public.payments USING btree (user_id);


--
-- Name: ix_predictions_prediction_type; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX ix_predictions_prediction_type ON public.predictions USING btree (prediction_type);


--
-- Name: ix_predictions_user_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX ix_predictions_user_id ON public.predictions USING btree (user_id);


--
-- Name: ix_quick_links_checkout_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX ix_quick_links_checkout_id ON public.quick_links USING btree (checkout_id);


--
-- Name: ix_quick_links_created_at; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX ix_quick_links_created_at ON public.quick_links USING btree (created_at);


--
-- Name: ix_quick_links_public_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE UNIQUE INDEX ix_quick_links_public_id ON public.quick_links USING btree (public_id);


--
-- Name: ix_quick_links_status; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX ix_quick_links_status ON public.quick_links USING btree (status);


--
-- Name: ix_quick_links_user_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX ix_quick_links_user_id ON public.quick_links USING btree (user_id);


--
-- Name: ix_reconciliation_runs_status; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX ix_reconciliation_runs_status ON public.reconciliation_runs USING btree (status);


--
-- Name: ix_reconciliation_runs_user_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX ix_reconciliation_runs_user_id ON public.reconciliation_runs USING btree (user_id);


--
-- Name: ix_refunds_idempotency_key; Type: INDEX; Schema: public; Owner: postgres
--

CREATE UNIQUE INDEX ix_refunds_idempotency_key ON public.refunds USING btree (idempotency_key);


--
-- Name: ix_refunds_payment_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX ix_refunds_payment_id ON public.refunds USING btree (payment_id);


--
-- Name: ix_refunds_status; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX ix_refunds_status ON public.refunds USING btree (status);


--
-- Name: ix_refunds_user_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX ix_refunds_user_id ON public.refunds USING btree (user_id);


--
-- Name: ix_transactions_user_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX ix_transactions_user_id ON public.transactions USING btree (user_id);


--
-- Name: ix_users_email; Type: INDEX; Schema: public; Owner: postgres
--

CREATE UNIQUE INDEX ix_users_email ON public.users USING btree (email);


--
-- Name: ix_users_workspace_key; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX ix_users_workspace_key ON public.users USING btree (workspace_key);


--
-- Name: account_preferences account_preferences_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.account_preferences
    ADD CONSTRAINT account_preferences_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id);


--
-- Name: alerts alerts_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.alerts
    ADD CONSTRAINT alerts_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id);


--
-- Name: audit_logs audit_logs_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.audit_logs
    ADD CONSTRAINT audit_logs_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id);


--
-- Name: auth_sessions auth_sessions_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.auth_sessions
    ADD CONSTRAINT auth_sessions_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id);


--
-- Name: compliance_checks compliance_checks_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.compliance_checks
    ADD CONSTRAINT compliance_checks_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id);


--
-- Name: customers customers_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.customers
    ADD CONSTRAINT customers_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id);


--
-- Name: demo_messages demo_messages_recipient_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.demo_messages
    ADD CONSTRAINT demo_messages_recipient_id_fkey FOREIGN KEY (recipient_id) REFERENCES public.users(id);


--
-- Name: demo_messages demo_messages_sender_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.demo_messages
    ADD CONSTRAINT demo_messages_sender_id_fkey FOREIGN KEY (sender_id) REFERENCES public.users(id);


--
-- Name: demo_wallets demo_wallets_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.demo_wallets
    ADD CONSTRAINT demo_wallets_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id);


--
-- Name: email_verification_tokens email_verification_tokens_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.email_verification_tokens
    ADD CONSTRAINT email_verification_tokens_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id);


--
-- Name: event_logs event_logs_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.event_logs
    ADD CONSTRAINT event_logs_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id);


--
-- Name: invoices invoices_customer_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.invoices
    ADD CONSTRAINT invoices_customer_id_fkey FOREIGN KEY (customer_id) REFERENCES public.customers(id);


--
-- Name: invoices invoices_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.invoices
    ADD CONSTRAINT invoices_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id);


--
-- Name: password_reset_tokens password_reset_tokens_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.password_reset_tokens
    ADD CONSTRAINT password_reset_tokens_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id);


--
-- Name: payment_methods payment_methods_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.payment_methods
    ADD CONSTRAINT payment_methods_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id);


--
-- Name: payments payments_customer_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.payments
    ADD CONSTRAINT payments_customer_id_fkey FOREIGN KEY (customer_id) REFERENCES public.customers(id);


--
-- Name: payments payments_invoice_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.payments
    ADD CONSTRAINT payments_invoice_id_fkey FOREIGN KEY (invoice_id) REFERENCES public.invoices(id);


--
-- Name: payments payments_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.payments
    ADD CONSTRAINT payments_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id);


--
-- Name: predictions predictions_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.predictions
    ADD CONSTRAINT predictions_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id);


--
-- Name: quick_links quick_links_invoice_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.quick_links
    ADD CONSTRAINT quick_links_invoice_id_fkey FOREIGN KEY (invoice_id) REFERENCES public.invoices(id);


--
-- Name: quick_links quick_links_payment_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.quick_links
    ADD CONSTRAINT quick_links_payment_id_fkey FOREIGN KEY (payment_id) REFERENCES public.payments(id);


--
-- Name: quick_links quick_links_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.quick_links
    ADD CONSTRAINT quick_links_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id);


--
-- Name: reconciliation_runs reconciliation_runs_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.reconciliation_runs
    ADD CONSTRAINT reconciliation_runs_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id);


--
-- Name: refunds refunds_payment_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.refunds
    ADD CONSTRAINT refunds_payment_id_fkey FOREIGN KEY (payment_id) REFERENCES public.payments(id);


--
-- Name: refunds refunds_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.refunds
    ADD CONSTRAINT refunds_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id);


--
-- Name: transactions transactions_payment_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.transactions
    ADD CONSTRAINT transactions_payment_id_fkey FOREIGN KEY (payment_id) REFERENCES public.payments(id);


--
-- Name: transactions transactions_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.transactions
    ADD CONSTRAINT transactions_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id);


--
-- PostgreSQL database dump complete
--

\unrestrict 7BLFx7iwC4w9Ni2Tg8aKJGkFbKYxh8bUOubt3z7k7g7D8nVc6JKtbN3EcZTEqHe

