-- Sky Archer run analytics: Supabase schema.
-- Paste the whole file into Supabase > SQL Editor > New query, then Run.
-- Safe to run again: it only creates what is missing and replaces the submit function.
--
-- How it's locked down:
--   * RLS is on for every table with no policies, so the game's publishable key can't
--     read, change or delete any row.
--   * The game's only door is the submit_run() function. It validates the payload and
--     writes the run, its rifts and its bosses in one transaction.
--   * Re-sending the same run (offline retry) is ignored, not duplicated.

-- --- Tables -------------------------------------------------------------------------

create table if not exists public.runs (
	id               uuid primary key,
	received_at      timestamptz not null default now(),
	player_id        text,
	game_version     text,
	build_type       text,
	platform         text,
	summary_version  int,
	started_at       timestamptz,
	ended_at         timestamptz,
	duration_sec     int,
	active_sec       int,
	result           text,
	death_cause      text,
	rift_reached     int,
	biome_reached    text,
	bosses_killed    int,
	max_hp_start     int,
	lowest_hp        int,
	shots            int,
	perfect_shots    int,
	arrow_hits       int,
	arrow_misses     int,
	damage_dealt     int,
	damage_taken     int,
	hits_taken       int,
	falls            int,
	potions_used     int,
	final_bow        text,
	final_quiver     text,
	final_ring       text,
	active_ability   text,
	crafted_item     text,
	-- The full summary as sent by the game. Anything not in a column lives here.
	data             jsonb not null
);

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

alter table public.runs       enable row level security;
alter table public.run_rifts  enable row level security;
alter table public.run_bosses enable row level security;

revoke all on public.runs, public.run_rifts, public.run_bosses from anon, authenticated;

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

	insert into public.runs (
		id, player_id, game_version, build_type, platform, summary_version,
		started_at, ended_at, duration_sec, active_sec, result, death_cause,
		rift_reached, biome_reached, bosses_killed, max_hp_start, lowest_hp,
		shots, perfect_shots, arrow_hits, arrow_misses, damage_dealt, damage_taken,
		hits_taken, falls, potions_used,
		final_bow, final_quiver, final_ring, active_ability, crafted_item, data
	) values (
		v_id,
		left(payload->>'player_id', 64),
		left(payload->>'game_version', 32),
		left(payload->>'build_type', 16),
		left(payload->>'platform', 32),
		(payload->>'summary_version')::int,
		(payload->>'started_at')::timestamptz,
		(payload->>'ended_at')::timestamptz,
		(payload->>'duration_sec')::int,
		(payload->>'active_sec')::int,
		left(payload->>'result', 32),
		left(nullif(payload->>'death_cause', ''), 64),
		(payload->>'rift_reached')::int,
		nullif(payload->>'biome_reached', ''),
		(payload->>'bosses_killed')::int,
		(payload->>'max_hp_start')::int,
		(payload->>'lowest_hp')::int,
		coalesce((payload#>>'{combat,shots}')::int, 0),
		coalesce((payload#>>'{combat,perfect_shots}')::int, 0),
		coalesce((payload#>>'{combat,arrow_hits}')::int, 0),
		coalesce((payload#>>'{combat,arrow_misses}')::int, 0),
		coalesce((payload#>>'{combat,damage_dealt}')::int, 0),
		coalesce((payload#>>'{combat,damage_taken}')::int, 0),
		coalesce((payload#>>'{combat,hits_taken}')::int, 0),
		coalesce((payload#>>'{movement,falls}')::int, 0),
		coalesce((payload#>>'{combat,potions_used}')::int, 0),
		left(payload#>>'{build,final_gear,bow,name}', 64),
		left(payload#>>'{build,final_gear,arrow,name}', 64),
		left(payload#>>'{build,final_gear,ring,name}', 64),
		left(nullif(payload#>>'{build,active_ability}', ''), 64),
		left(nullif(payload#>>'{build,crafted_item}', ''), 64),
		payload
	)
	on conflict (id) do nothing;

	get diagnostics v_inserted = row_count;
	if v_inserted = 0 then
		return 'duplicate';
	end if;

	insert into public.run_rifts (
		run_id, seq, rift_index, biome, started_sec, duration_sec, kills, hits_taken,
		damage_taken, damage_dealt, falls, chests, events_completed, events_failed
	)
	select
		v_id,
		(r.ord - 1)::int,
		(r.value->>'index')::int,
		nullif(r.value->>'biome', ''),
		(r.value->>'started_sec')::int,
		(r.value->>'duration_sec')::int,
		(r.value->>'kills')::int,
		(r.value->>'hits_taken')::int,
		(r.value->>'damage_taken')::int,
		(r.value->>'damage_dealt')::int,
		(r.value->>'falls')::int,
		(r.value->>'chests')::int,
		(r.value->>'events_completed')::int,
		(r.value->>'events_failed')::int
	from jsonb_array_elements(coalesce(payload->'rifts', '[]'::jsonb)) with ordinality as r(value, ord);

	insert into public.run_bosses (
		run_id, seq, name, after_rift, started_sec, duration_sec, hits_taken,
		damage_taken, damage_dealt, falls, won
	)
	select
		v_id,
		(b.ord - 1)::int,
		left(b.value->>'name', 64),
		(b.value->>'after_rift')::int,
		(b.value->>'started_sec')::int,
		(b.value->>'duration_sec')::int,
		(b.value->>'hits_taken')::int,
		(b.value->>'damage_taken')::int,
		(b.value->>'damage_dealt')::int,
		(b.value->>'falls')::int,
		(b.value->>'won')::boolean
	from jsonb_array_elements(coalesce(payload->'bosses', '[]'::jsonb)) with ordinality as b(value, ord);

	return 'ok';
end;
$$;

revoke all on function public.submit_run(jsonb) from public;
grant execute on function public.submit_run(jsonb) to anon;
