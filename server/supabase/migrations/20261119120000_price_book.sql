-- The price book: what the weekly price checker reported, after the server checked it.
--
-- The tables live in their own schema, not public, so Supabase's Data API (which serves
-- public to the app's anon key) cannot reach them; only the server, connecting as the
-- owner, reads and writes them. Row level security is on as well, with no policies.

create schema if not exists pricebook;

-- One weekly run of the price checker: the Managed Agents session that wrote the report.
create table pricebook.runs (
  id bigint generated always as identity primary key,
  session_id text not null unique,
  run_on date not null,
  received_at timestamptz not null default now()
);

-- One line of a run's report. Accepted lines price meals; held lines wait for a person
-- (a big swing from the last price); rejected lines say why they could not be used.
-- raw is the line exactly as the agent wrote it.
create table pricebook.observations (
  id bigint generated always as identity primary key,
  run_id bigint not null references pricebook.runs (id) on delete cascade,
  ingredient_id text,
  store_id text,
  price_php numeric check (price_php > 0),
  per_qty numeric check (per_qty > 0),
  per_unit text check (per_unit in ('kg', 'g', 'l', 'ml', 'pc')),
  -- The price of one of the meal bank's units (a g, a ml or a pc).
  unit_price_php numeric(14, 6) check (unit_price_php > 0),
  source text,
  source_url text,
  observed_on date,
  status text not null check (status in ('accepted', 'held', 'rejected')),
  reason text,
  raw jsonb not null,
  -- Only rejected lines lack a unit price, and a usable line names what it prices.
  check ((status = 'rejected') = (unit_price_php is null)),
  check (status = 'rejected' or (ingredient_id is not null and store_id is not null
                                 and observed_on is not null)),
  -- Held and rejected lines say why.
  check (status = 'accepted' or reason is not null)
);

create index observations_current
  on pricebook.observations (ingredient_id, store_id, observed_on desc, id desc)
  where status = 'accepted';

-- The price each ingredient has at each store now: its latest accepted line.
create view pricebook.current_prices with (security_invoker = true) as
select distinct on (ingredient_id, store_id)
  ingredient_id, store_id, unit_price_php, observed_on, source, source_url, run_id
from pricebook.observations
where status = 'accepted'
order by ingredient_id, store_id, observed_on desc, id desc;

alter table pricebook.runs enable row level security;
alter table pricebook.observations enable row level security;
