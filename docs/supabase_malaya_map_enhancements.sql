-- Malaya map enhancements: added_spots + captured_moments
-- Run manually in Supabase SQL editor.

create extension if not exists "pgcrypto";

create table if not exists public.added_spots (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  uploader_name text not null default 'Malaya user',
  spot_name text not null,
  category text not null default 'Other',
  description text,
  location text,
  image_url text not null,
  created_at timestamptz not null default now()
);

create index if not exists idx_added_spots_user_id on public.added_spots(user_id);
create index if not exists idx_added_spots_created_at on public.added_spots(created_at desc);

alter table public.added_spots enable row level security;

drop policy if exists "added_spots_select_all" on public.added_spots;
create policy "added_spots_select_all"
on public.added_spots
for select
using (true);

drop policy if exists "added_spots_insert_owner" on public.added_spots;
create policy "added_spots_insert_owner"
on public.added_spots
for insert
with check (auth.uid() = user_id);

drop policy if exists "added_spots_update_owner" on public.added_spots;
create policy "added_spots_update_owner"
on public.added_spots
for update
using (auth.uid() = user_id)
with check (auth.uid() = user_id);

drop policy if exists "added_spots_delete_owner" on public.added_spots;
create policy "added_spots_delete_owner"
on public.added_spots
for delete
using (auth.uid() = user_id);

create table if not exists public.captured_moments (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  uploader_name text not null default 'Malaya user',
  caption text,
  image_url text not null,
  created_at timestamptz not null default now()
);

create index if not exists idx_captured_moments_user_id on public.captured_moments(user_id);
create index if not exists idx_captured_moments_created_at on public.captured_moments(created_at desc);

alter table public.captured_moments enable row level security;

drop policy if exists "captured_moments_select_owner" on public.captured_moments;
create policy "captured_moments_select_owner"
on public.captured_moments
for select
using (auth.uid() = user_id);

drop policy if exists "captured_moments_insert_owner" on public.captured_moments;
create policy "captured_moments_insert_owner"
on public.captured_moments
for insert
with check (auth.uid() = user_id);

drop policy if exists "captured_moments_update_owner" on public.captured_moments;
create policy "captured_moments_update_owner"
on public.captured_moments
for update
using (auth.uid() = user_id)
with check (auth.uid() = user_id);

drop policy if exists "captured_moments_delete_owner" on public.captured_moments;
create policy "captured_moments_delete_owner"
on public.captured_moments
for delete
using (auth.uid() = user_id);
