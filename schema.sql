-- Plataforma de Prácticas por Facultad – Universidad EAN (prototipo)
-- Pegar completo en Supabase > SQL Editor > Run

create table faculties(id serial primary key, name text unique not null);
create table programs(id serial primary key, faculty_id int not null references faculties on delete cascade, name text unique not null);
create table profiles(id uuid primary key references auth.users on delete cascade, full_name text,
  role text not null default 'student' check(role in('student','company','admin')), consent_at timestamptz);
create table companies(id serial primary key, owner_id uuid references auth.users, name text not null, nit text,
  status text not null default 'pending' check(status in('pending','approved','rejected')));
create table vacancies(id serial primary key, company_id int not null references companies on delete cascade,
  program_id int not null references programs, title text not null,
  modality text not null check(modality in('Presencial','Híbrido','Remoto')), city text not null default 'Bogotá',
  active boolean default true, created_at timestamptz default now());
create table applications(id serial primary key, vacancy_id int not null references vacancies on delete cascade,
  student_id uuid not null references profiles on delete cascade,
  status text not null default 'En revisión' check(status in('En revisión','Preseleccionado','Rechazado','Contratado')),
  created_at timestamptz default now(), unique(vacancy_id, student_id));
create table saved_filters(student_id uuid primary key references profiles on delete cascade, filter jsonb);
create table audit_log(id serial primary key, actor uuid, action text, detail text, at timestamptz default now());

create function is_admin() returns boolean language sql security definer stable set search_path=public
as $$ select exists(select 1 from profiles where id=auth.uid() and role='admin') $$;

-- Al registrarse: crea perfil (con fecha de consentimiento Habeas Data) y, si es empresa, su registro pendiente de aprobación
create function on_signup() returns trigger language plpgsql security definer set search_path=public as $$
declare r text := case when new.raw_user_meta_data->>'role'='company' then 'company' else 'student' end;
begin
  insert into profiles(id,full_name,role,consent_at) values(new.id,new.raw_user_meta_data->>'full_name',r,
    case when new.raw_user_meta_data->>'consent'='true' then now() end);
  if r='company' then insert into companies(owner_id,name) values(new.id,coalesce(new.raw_user_meta_data->>'full_name','Empresa')); end if;
  return new;
end $$;
create trigger t_signup after insert on auth.users for each row execute function on_signup();

-- Auditoría de postulaciones y aprobaciones
create function audit() returns trigger language plpgsql security definer set search_path=public as $$
begin insert into audit_log(actor,action,detail) values(auth.uid(),tg_table_name||' '||tg_op,coalesce(to_jsonb(new)->>'status',''));
return new; end $$;
create trigger a1 after insert or update on applications for each row execute function audit();
create trigger a2 after update on companies for each row execute function audit();

-- Seguridad por filas (RLS): cada rol solo ve y modifica lo que le corresponde
alter table faculties enable row level security; alter table programs enable row level security;
alter table profiles enable row level security; alter table companies enable row level security;
alter table vacancies enable row level security; alter table applications enable row level security;
alter table saved_filters enable row level security; alter table audit_log enable row level security;

create policy f_r on faculties for select to authenticated using(true);
create policy f_w on faculties for all to authenticated using(is_admin()) with check(is_admin());
create policy p_r on programs for select to authenticated using(true);
create policy p_w on programs for all to authenticated using(is_admin()) with check(is_admin());

create policy pr_r on profiles for select to authenticated using(id=auth.uid() or is_admin() or exists(
  select 1 from applications a join vacancies v on v.id=a.vacancy_id join companies c on c.id=v.company_id
  where a.student_id=profiles.id and c.owner_id=auth.uid()));

create policy c_r on companies for select to authenticated using(owner_id=auth.uid() or is_admin() or status='approved');
create policy c_u on companies for update to authenticated using(is_admin()) with check(is_admin());

create policy v_r on vacancies for select to authenticated using(is_admin() or exists(
  select 1 from companies c where c.id=company_id and (c.owner_id=auth.uid() or c.status='approved')));
create policy v_i on vacancies for insert to authenticated with check(exists(
  select 1 from companies c where c.id=company_id and c.owner_id=auth.uid() and c.status='approved'));
create policy v_u on vacancies for update to authenticated using(exists(
  select 1 from companies c where c.id=company_id and c.owner_id=auth.uid()));

create policy a_r on applications for select to authenticated using(student_id=auth.uid() or is_admin() or exists(
  select 1 from vacancies v join companies c on c.id=v.company_id where v.id=vacancy_id and c.owner_id=auth.uid()));
create policy a_i on applications for insert to authenticated with check(student_id=auth.uid());
create policy a_u on applications for update to authenticated using(exists(
  select 1 from vacancies v join companies c on c.id=v.company_id where v.id=vacancy_id and c.owner_id=auth.uid()));

create policy s_all on saved_filters for all to authenticated using(student_id=auth.uid()) with check(student_id=auth.uid());
create policy l_r on audit_log for select to authenticated using(is_admin());

-- Datos semilla (sintéticos)
insert into faculties(name) values('Facultad de Ingeniería'),('Facultad de Administración, Finanzas y Ciencias Económicas'),
  ('Facultad de Ciencias Sociales y Educación'),('Facultad de Estudios en Ambientes Virtuales');
insert into programs(faculty_id,name) values(1,'Ingeniería de Sistemas'),(1,'Ingeniería Industrial'),(1,'Ingeniería Ambiental'),
  (2,'Administración de Empresas'),(2,'Finanzas y Comercio Exterior'),(2,'Mercadeo'),
  (3,'Psicología'),(3,'Comunicación Social'),(3,'Educación Infantil'),(4,'Negocios Digitales'),(4,'Ingeniería de Software virtual');
insert into companies(name,nit,status) values('Datos & Co','900.111.111-1','approved'),('Soft Andina','900.222.222-2','approved'),
  ('Banco Capital','900.333.333-3','approved'),('Marca Viva','900.444.444-4','approved'),('Talento Plus','900.555.555-5','approved'),
  ('Tienda Online','900.666.666-6','approved'),('Nuevo Horizonte SAS','900.123.456-1','pending'),('Consultores del Norte','901.555.222-7','pending');
insert into vacancies(company_id,program_id,title,modality,city) values
  (1,1,'Analista de datos junior','Remoto','Bogotá'),(2,1,'Desarrollador backend','Híbrido','Bogotá'),
  (1,2,'Auxiliar de producción','Presencial','Bogotá'),(2,11,'QA tester','Remoto','Cali'),
  (3,4,'Asistente administrativo','Presencial','Bogotá'),(3,5,'Analista financiero','Híbrido','Bogotá'),
  (4,6,'Asistente de mercadeo digital','Remoto','Bogotá'),(5,7,'Apoyo en bienestar laboral','Presencial','Bogotá'),
  (6,10,'Analista de e-commerce','Remoto','Bogotá');

-- Para crear un administrador: registrarse en la app y luego ejecutar (con su correo):
-- update profiles set role='admin' where id=(select id from auth.users where email='SU_CORREO');
