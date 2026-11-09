-- Sky Archer run analytics: Supabase schema.
-- Paste the whole file into Supabase > SQL Editor > New query, then Run.
-- Always safe to run again: it creates what's missing, applies column changes,
-- replaces the functions and backfills older rows from their saved JSON.
--
-- How it's locked down:
--   * RLS is on for every table with no policies, so the game's publishable key can't
--     read, change or delete any row.
--   * The game's only door is the submit_run() function. It validates the payload and
--     writes the run and its detail rows in one transaction.
--   * Re-sending the same run (offline retry) is ignored, not duplicated.

-- --- Tables -------------------------------------------------------------------------

create table if not exists public.runs (
	id                uuid primary key,
	received_at       timestamptz not null default now(),
	player_id         text,
	game_version      text,
	build_type        text,
	platform          text,
	summary_version   int,
	started_at        timestamptz,
	ended_at          timestamptz,
	duration_sec      int,
	active_sec        int,
	result            text,
	death_cause       text,
	rift_reached      int,
	biome_reached     text,
	bosses_killed     int,
	elites_killed     int,
	enemies_killed    int,
	events_completed  int,
	events_failed     int,
	objects_destroyed int,
	chests_opened     int,
	islands_visited   int,
	gold              int,
	max_hp_start      int,
	lowest_hp         int,
	shots             int,
	perfect_shots     int,
	arrow_hits        int,
	arrow_misses      int,
	damage_dealt      int,
	damage_taken      int,
	hits_taken        int,
	falls             int,
	final_bow         text,
	final_quiver      text,
	final_ring        text,
	crafted_item      text,
	-- The full summary as sent by the game. Anything not in a column lives here.
	data              jsonb not null
);

-- Column changes for databases created from an older version of this file.
alter table public.runs drop column if exists potions_used;
alter table public.runs drop column if exists active_ability;
alter table public.runs add column if not exists elites_killed     int;
alter table public.runs add column if not exists enemies_killed    int;
alter table public.runs add column if not exists events_completed  int;
alter table public.runs add column if not exists events_failed     int;
alter table public.runs add column if not exists objects_destroyed int;
alter table public.runs add column if not exists chests_opened     int;
alter table public.runs add column if not exists islands_visited   int;
alter table public.runs add column if not exists gold              int;

create index if not exists runs_version_idx on public.runs (game_version, build_type);
create index if not exists runs_player_idx on public.runs (player_id);
create index if not exists runs_ended_idx on public.runs (ended_at);

create table if not exists public.run_rifts (
	run_id            uuid not null references public.runs (id) on delete cascade,
	seq               int not null,   -- order within the run, from 0
	rift_index        int,            -- the game's rift level
	biome             text,
	started_sec       int,
	duration_sec      int,
	kills             int,
	hits_taken        int,
	damage_taken      int,
	damage_dealt      int,
	falls             int,
	chests            int,
	events_completed  int,
	events_failed     int,
	primary key (run_id, seq)
);

-- Biome bosses and elites (apple boss, bird boss...).
create table if not exists public.run_bosses (
	run_id        uuid not null references public.runs (id) on delete cascade,
	seq           int not null,
	name          text,
	after_rift    int,
	started_sec   int,
	duration_sec  int,
	hits_taken    int,
	damage_taken  int,
	damage_dealt  int,
	falls         int,
	won           boolean,
	primary key (run_id, seq)
);

-- One row per thing counted in a run, by name. Categories:
--   enemy, elite, boss          kills per enemy type
--   event_completed, event_failed
--   object                      destroyed objects (barrel, crate...)
--   resource                    collected (coin, wood...)
--   damage_source               damage the player took, per enemy or "Fall"/"Effect"
create table if not exists public.run_counts (
	run_id    uuid not null references public.runs (id) on delete cascade,
	category  text not null,
	name      text not null,
	count     int not null,
	primary key (run_id, category, name)
);

create index if not exists run_counts_lookup_idx on public.run_counts (category, name);

alter table public.runs       enable row level security;
alter table public.run_rifts  enable row level security;
alter table public.run_bosses enable row level security;
alter table public.run_counts enable row level security;

revoke all on public.runs, public.run_rifts, public.run_bosses, public.run_counts from anon, authenticated;

-- --- Helpers ------------------------------------------------------------------------

-- Sum of the values of a {"name": count} JSON object.
create or replace function public.json_count_total(obj jsonb)
returns int
language sql
immutable
as $$
	select coalesce(sum((e.value)::numeric)::int, 0)
	from jsonb_each_text(case when jsonb_typeof(obj) = 'object' then obj else '{}'::jsonb end) as e;
$$;

-- Writes the rift, boss and count rows for one run. Used by submit_run and the backfill.
create or replace function public.store_run_details(v_id uuid, payload jsonb)
returns void
language plpgsql
set search_path = public
as $$
begin
	delete from public.run_rifts  where run_id = v_id;
	delete from public.run_bosses where run_id = v_id;
	delete from public.run_counts where run_id = v_id;

	insert into public.run_rifts (
		run_id, seq, rift_index, biome, started_sec, duration_sec, kills, hits_taken,
		damage_taken, damage_dealt, falls, chests, events_completed, events_failed
	)
	select
		v_id,
		(r.ord - 1)::int,
		(r.value->>'index')::numeric::int,
		nullif(r.value->>'biome', ''),
		(r.value->>'started_sec')::numeric::int,
		(r.value->>'duration_sec')::numeric::int,
		(r.value->>'kills')::numeric::int,
		(r.value->>'hits_taken')::numeric::int,
		(r.value->>'damage_taken')::numeric::int,
		(r.value->>'damage_dealt')::numeric::int,
		(r.value->>'falls')::numeric::int,
		(r.value->>'chests')::numeric::int,
		(r.value->>'events_completed')::numeric::int,
		(r.value->>'events_failed')::numeric::int
	from jsonb_array_elements(coalesce(payload->'rifts', '[]'::jsonb)) with ordinality as r(value, ord);

	insert into public.run_bosses (
		run_id, seq, name, after_rift, started_sec, duration_sec, hits_taken,
		damage_taken, damage_dealt, falls, won
	)
	select
		v_id,
		(b.ord - 1)::int,
		left(b.value->>'name', 64),
		(b.value->>'after_rift')::numeric::int,
		(b.value->>'started_sec')::numeric::int,
		(b.value->>'duration_sec')::numeric::int,
		(b.value->>'hits_taken')::numeric::int,
		(b.value->>'damage_taken')::numeric::int,
		(b.value->>'damage_dealt')::numeric::int,
		(b.value->>'falls')::numeric::int,
		(b.value->>'won')::boolean
	from jsonb_array_elements(coalesce(payload->'bosses', '[]'::jsonb)) with ordinality as b(value, ord);

	insert into public.run_counts (run_id, category, name, count)
	select v_id, src.category, left(e.key, 64), (e.value)::numeric::int
	from (values
		('enemy',           payload#>'{kills,enemies}'),
		('elite',           payload#>'{kills,elites}'),
		('boss',            payload#>'{kills,bosses}'),
		('event_completed', payload->'events_completed'),
		('event_failed',    payload->'events_failed'),
		('object',          payload#>'{economy,objects_destroyed}'),
		('resource',        payload#>'{economy,resources}'),
		('damage_source',   payload->'damage_taken_by_source')
	) as src(category, obj)
	cross join lateral jsonb_each_text(
		case when jsonb_typeof(src.obj) = 'object' then src.obj else '{}'::jsonb end
	) as e
	on conflict do nothing;
end;
$$;

revoke all on function public.store_run_details(uuid, jsonb) from public, anon, authenticated;

-- --- Submit function (the game's only way in) ---------------------------------------

create or replace function public.submit_run(payload jsonb)
returns text
language plpgsql
security definer
set search_path = public
as $$
declare
	v_id uuid;
	v_inserted int;
begin
	if payload is null or jsonb_typeof(payload) <> 'object' then
		raise exception 'payload must be a json object';
	end if;
	if pg_column_size(payload) > 65536 then
		raise exception 'payload too large';
	end if;

	v_id := (payload->>'run_id')::uuid;

	insert into public.runs (id, data) values (v_id, payload)
	on conflict (id) do nothing;

	get diagnostics v_inserted = row_count;
	if v_inserted = 0 then
		return 'duplicate';
	end if;

	perform public.refresh_run_columns(v_id);
	perform public.store_run_details(v_id, payload);
	return 'ok';
end;
$$;

-- Fills a run's columns from its saved JSON.
create or replace function public.refresh_run_columns(v_id uuid)
returns void
language sql
set search_path = public
as $$
	update public.runs r set
		player_id         = left(d->>'player_id', 64),
		game_version      = left(d->>'game_version', 32),
		build_type        = left(d->>'build_type', 16),
		platform          = left(d->>'platform', 32),
		summary_version   = (d->>'summary_version')::numeric::int,
		started_at        = (d->>'started_at')::timestamptz,
		ended_at          = (d->>'ended_at')::timestamptz,
		duration_sec      = (d->>'duration_sec')::numeric::int,
		active_sec        = (d->>'active_sec')::numeric::int,
		result            = left(d->>'result', 32),
		death_cause       = left(nullif(d->>'death_cause', ''), 64),
		rift_reached      = (d->>'rift_reached')::numeric::int,
		biome_reached     = nullif(d->>'biome_reached', ''),
		bosses_killed     = public.json_count_total(d#>'{kills,bosses}'),
		elites_killed     = public.json_count_total(d#>'{kills,elites}'),
		enemies_killed    = public.json_count_total(d#>'{kills,enemies}'),
		events_completed  = public.json_count_total(d->'events_completed'),
		events_failed     = public.json_count_total(d->'events_failed'),
		objects_destroyed = public.json_count_total(d#>'{economy,objects_destroyed}'),
		chests_opened     = coalesce((d#>>'{economy,chests}')::numeric::int, 0),
		islands_visited   = coalesce((d->>'islands_visited')::numeric::int, 0),
		gold              = coalesce((d#>>'{economy,resources,coin}')::numeric::int, 0),
		max_hp_start      = (d->>'max_hp_start')::numeric::int,
		lowest_hp         = (d->>'lowest_hp')::numeric::int,
		shots             = coalesce((d#>>'{combat,shots}')::numeric::int, 0),
		perfect_shots     = coalesce((d#>>'{combat,perfect_shots}')::numeric::int, 0),
		arrow_hits        = coalesce((d#>>'{combat,arrow_hits}')::numeric::int, 0),
		arrow_misses      = coalesce((d#>>'{combat,arrow_misses}')::numeric::int, 0),
		damage_dealt      = coalesce((d#>>'{combat,damage_dealt}')::numeric::int, 0),
		damage_taken      = coalesce((d#>>'{combat,damage_taken}')::numeric::int, 0),
		hits_taken        = coalesce((d#>>'{combat,hits_taken}')::numeric::int, 0),
		falls             = coalesce((d#>>'{movement,falls}')::numeric::int, 0),
		final_bow         = left(d#>>'{build,final_gear,bow,name}', 64),
		final_quiver      = left(d#>>'{build,final_gear,arrow,name}', 64),
		final_ring        = left(d#>>'{build,final_gear,ring,name}', 64),
		crafted_item      = left(nullif(d#>>'{build,crafted_item}', ''), 64)
	from (select data as d from public.runs where id = v_id) as src
	where r.id = v_id;
$$;

revoke all on function public.refresh_run_columns(uuid) from public, anon, authenticated;
revoke all on function public.json_count_total(jsonb) from anon, authenticated;
revoke all on function public.submit_run(jsonb) from public;
grant execute on function public.submit_run(jsonb) to anon;

-- --- Dashboard access ---------------------------------------------------------------
-- The dashboard (docs/analytics/dashboard.html) reads through these two functions with the
-- same publishable key as the game, plus a dashboard password only you know.
-- Set or change the password by running this line on its own in the SQL Editor:
--     select public.set_dashboard_password('your-long-password-here');

create table if not exists public.analytics_access (
	id             int primary key default 1 check (id = 1),
	password_hash  text not null
);
alter table public.analytics_access enable row level security;
revoke all on public.analytics_access from anon, authenticated;

create or replace function public.set_dashboard_password(p_password text)
returns text
language plpgsql
set search_path = public
as $$
begin
	if length(coalesce(p_password, '')) < 12 then
		raise exception 'use at least 12 characters';
	end if;
	insert into public.analytics_access (id, password_hash)
	values (1, encode(sha256(convert_to(p_password, 'UTF8')), 'hex'))
	on conflict (id) do update set password_hash = excluded.password_hash;
	return 'dashboard password set';
end;
$$;
revoke all on function public.set_dashboard_password(text) from public, anon, authenticated;

create or replace function public.check_dashboard_password(p_password text)
returns void
language plpgsql
set search_path = public
as $$
begin
	if not exists (
		select 1 from public.analytics_access
		where password_hash = encode(sha256(convert_to(coalesce(p_password, ''), 'UTF8')), 'hex')
	) then
		perform pg_sleep(1);  -- slows down guessing
		raise exception 'wrong dashboard password' using errcode = '28P01';
	end if;
end;
$$;
revoke all on function public.check_dashboard_password(text) from public, anon, authenticated;

-- Everything the dashboard needs except the raw JSON, in one call.
create or replace function public.analytics_export(p_password text)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
begin
	perform public.check_dashboard_password(p_password);
	return jsonb_build_object(
		'runs',   (select coalesce(jsonb_agg(to_jsonb(r) - 'data' order by r.ended_at desc), '[]'::jsonb) from public.runs r),
		'rifts',  (select coalesce(jsonb_agg(to_jsonb(x)), '[]'::jsonb) from public.run_rifts x),
		'bosses', (select coalesce(jsonb_agg(to_jsonb(x)), '[]'::jsonb) from public.run_bosses x),
		'counts', (select coalesce(jsonb_agg(to_jsonb(x)), '[]'::jsonb) from public.run_counts x)
	);
end;
$$;

-- The full summary of one run, for the dashboard's run detail view.
create or replace function public.analytics_run(p_password text, p_run_id uuid)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
begin
	perform public.check_dashboard_password(p_password);
	return (select data from public.runs where id = p_run_id);
end;
$$;

revoke all on function public.analytics_export(text) from public;
revoke all on function public.analytics_run(text, uuid) from public;
grant execute on function public.analytics_export(text) to anon;
grant execute on function public.analytics_run(text, uuid) to anon;

-- --- Backfill -----------------------------------------------------------------------
-- Rebuilds columns and detail rows of every stored run from its JSON. Cheap at this scale.

do $$
declare
	r record;
begin
	for r in select id, data from public.runs loop
		perform public.refresh_run_columns(r.id);
		perform public.store_run_details(r.id, r.data);
	end loop;
end;
$$;
