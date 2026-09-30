# Supabase Storage Setup (Manual)

Create these public buckets in Supabase Storage:

1. `added-spots`
2. `captured-moments`

Recommended SQL for storage policies:

```sql
-- Public read
create policy "Public read added-spots"
on storage.objects
for select
using (bucket_id = 'added-spots');

create policy "Public read captured-moments"
on storage.objects
for select
using (bucket_id = 'captured-moments');

-- Authenticated upload to own folder (folder name = auth user id)
create policy "Upload own added-spots folder"
on storage.objects
for insert
with check (
  bucket_id = 'added-spots'
  and auth.role() = 'authenticated'
  and (storage.foldername(name))[1] = auth.uid()::text
);

create policy "Upload own captured-moments folder"
on storage.objects
for insert
with check (
  bucket_id = 'captured-moments'
  and auth.role() = 'authenticated'
  and (storage.foldername(name))[1] = auth.uid()::text
);

-- Optional owner update/delete
create policy "Update own added-spots files"
on storage.objects
for update
using (
  bucket_id = 'added-spots'
  and auth.role() = 'authenticated'
  and (storage.foldername(name))[1] = auth.uid()::text
);

create policy "Delete own added-spots files"
on storage.objects
for delete
using (
  bucket_id = 'added-spots'
  and auth.role() = 'authenticated'
  and (storage.foldername(name))[1] = auth.uid()::text
);

create policy "Update own captured-moments files"
on storage.objects
for update
using (
  bucket_id = 'captured-moments'
  and auth.role() = 'authenticated'
  and (storage.foldername(name))[1] = auth.uid()::text
);

create policy "Delete own captured-moments files"
on storage.objects
for delete
using (
  bucket_id = 'captured-moments'
  and auth.role() = 'authenticated'
  and (storage.foldername(name))[1] = auth.uid()::text
);
```
