-- Ejecutar DESPUÉS de schema.sql (Supabase > SQL Editor > Run)
-- Agrega: registro de empresas con razón social y NIT, y auditoría de cada acción con nombre y rol de quien la hizo.

alter table audit_log add column if not exists actor_name text, add column if not exists actor_role text;

create or replace function on_signup() returns trigger language plpgsql security definer set search_path=public as $$
declare r text := case when new.raw_user_meta_data->>'role'='company' then 'company' else 'student' end;
begin
  insert into profiles(id,full_name,role,consent_at) values(new.id,new.raw_user_meta_data->>'full_name',r,
    case when new.raw_user_meta_data->>'consent'='true' then now() end);
  if r='company' then
    insert into companies(owner_id,name,nit) values(new.id,coalesce(new.raw_user_meta_data->>'company','Empresa'),new.raw_user_meta_data->>'nit');
  end if;
  return new;
end $$;

create or replace function audit() returns trigger language plpgsql security definer set search_path=public as $$
declare n text; r text;
begin
  select full_name, role into n, r from profiles where id=auth.uid();
  insert into audit_log(actor,actor_name,actor_role,action,detail)
  values(auth.uid(),n,r,tg_table_name||' '||tg_op,coalesce(to_jsonb(new)->>'status',to_jsonb(new)->>'title',to_jsonb(new)->>'name',''));
  return new;
end $$;

drop trigger if exists a3 on vacancies;  create trigger a3 after insert on vacancies  for each row execute function audit();
drop trigger if exists a4 on faculties;  create trigger a4 after insert on faculties  for each row execute function audit();
drop trigger if exists a5 on programs;   create trigger a5 after insert on programs   for each row execute function audit();
