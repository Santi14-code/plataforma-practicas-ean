-- Carreras reales de la Universidad EAN + vacantes coherentes con cada carrera.
-- Ejecutar DESPUÉS de schema.sql y schema_update.sql (Supabase > SQL Editor > Run).
-- Reemplaza el catálogo y las vacantes de ejemplo. Las empresas y las cuentas de usuario se conservan.

truncate faculties, programs, vacancies restart identity cascade;

insert into faculties(name) values
  ('Administración, Economía, Negocios y Finanzas'),
  ('Humanidades y Ciencias Sociales'),
  ('Ingenierías');

insert into programs(faculty_id,name)
select f.id,p.n from (values
  ('Administración, Economía, Negocios y Finanzas','Administración de Empresas'),
  ('Administración, Economía, Negocios y Finanzas','Administración en Salud'),
  ('Administración, Economía, Negocios y Finanzas','Contaduría Pública'),
  ('Administración, Economía, Negocios y Finanzas','Economía'),
  ('Administración, Economía, Negocios y Finanzas','Mercadeo y Estrategia Comercial'),
  ('Administración, Economía, Negocios y Finanzas','Negocios Internacionales'),
  ('Humanidades y Ciencias Sociales','Comunicación'),
  ('Humanidades y Ciencias Sociales','Estudios y Gestión Cultural'),
  ('Humanidades y Ciencias Sociales','Lenguas Modernas'),
  ('Humanidades y Ciencias Sociales','Psicología'),
  ('Humanidades y Ciencias Sociales','Turismo Sostenible'),
  ('Ingenierías','Ingeniería Ambiental'),
  ('Ingenierías','Ingeniería de Producción'),
  ('Ingenierías','Ingeniería de Sistemas'),
  ('Ingenierías','Ingeniería en Ciencia de Datos'),
  ('Ingenierías','Ingeniería en Energías'),
  ('Ingenierías','Ingeniería en Inteligencia Artificial'),
  ('Ingenierías','Ingeniería Industrial'),
  ('Ingenierías','Ingeniería Mecatrónica'),
  ('Ingenierías','Ingeniería Química')
) p(f,n) join faculties f on f.name=p.f;

-- Empresas aliadas adicionales (aprobadas) si aún no existen
insert into companies(name,nit,status)
select v.n,v.nit,'approved' from (values
  ('Logística Total','900.701.001-1'),('Clínica Andina','900.702.002-2'),('Auditores Asociados','900.703.003-3'),
  ('Importex','900.704.004-4'),('Canal Regional','900.705.005-5'),('Centro Cultural Bogotá','900.706.006-6'),
  ('Idiomas Global','900.707.007-7'),('Viajes Verdes','900.708.008-8'),('EcoVerde','900.709.009-9'),
  ('Plásticos SAS','900.710.010-0'),('Telecom Sur','900.711.011-1'),('EcoEnergía SA','900.712.012-2'),
  ('Robótica Industrial','900.713.013-3'),('Química del Sur','900.714.014-4')
) v(n,nit) where not exists (select 1 from companies c where c.name=v.n);

insert into vacancies(company_id,program_id,title,modality,city)
select c.id,p.id,v.t,v.m,v.ci from (values
  ('Banco Capital','Administración de Empresas','Asistente administrativo','Presencial','Bogotá'),
  ('Logística Total','Administración de Empresas','Coordinación de proyectos junior','Híbrido','Medellín'),
  ('Clínica Andina','Administración en Salud','Auxiliar de gestión hospitalaria','Presencial','Bogotá'),
  ('Auditores Asociados','Contaduría Pública','Auxiliar contable','Presencial','Bogotá'),
  ('Auditores Asociados','Contaduría Pública','Auxiliar de auditoría','Híbrido','Cali'),
  ('Banco Capital','Economía','Analista económico junior','Híbrido','Bogotá'),
  ('Marca Viva','Mercadeo y Estrategia Comercial','Asistente de mercadeo digital','Remoto','Bogotá'),
  ('Tienda Online','Mercadeo y Estrategia Comercial','Analista de estrategia comercial','Híbrido','Bogotá'),
  ('Importex','Negocios Internacionales','Practicante de comercio exterior','Presencial','Cartagena'),
  ('Marca Viva','Comunicación','Community manager','Remoto','Medellín'),
  ('Canal Regional','Comunicación','Productor de contenidos','Híbrido','Bogotá'),
  ('Centro Cultural Bogotá','Estudios y Gestión Cultural','Gestor de programación cultural','Presencial','Bogotá'),
  ('Idiomas Global','Lenguas Modernas','Asistente de traducción','Remoto','Bogotá'),
  ('Talento Plus','Psicología','Apoyo en bienestar laboral','Presencial','Bogotá'),
  ('Talento Plus','Psicología','Apoyo en selección de personal','Híbrido','Bogotá'),
  ('Viajes Verdes','Turismo Sostenible','Asistente de turismo sostenible','Presencial','Cartagena'),
  ('EcoVerde','Ingeniería Ambiental','Gestión ambiental','Presencial','Bogotá'),
  ('Plásticos SAS','Ingeniería de Producción','Auxiliar de producción','Presencial','Bogotá'),
  ('Soft Andina','Ingeniería de Sistemas','Desarrollador backend','Híbrido','Bogotá'),
  ('Telecom Sur','Ingeniería de Sistemas','Soporte TI y redes','Presencial','Medellín'),
  ('Datos & Co','Ingeniería en Ciencia de Datos','Analista de datos junior','Remoto','Bogotá'),
  ('EcoEnergía SA','Ingeniería en Energías','Practicante en energías renovables','Presencial','Cali'),
  ('Datos & Co','Ingeniería en Inteligencia Artificial','Asistente de machine learning','Remoto','Bogotá'),
  ('Logística Total','Ingeniería Industrial','Analista de mejora continua','Híbrido','Cali'),
  ('Robótica Industrial','Ingeniería Mecatrónica','Auxiliar de automatización','Presencial','Medellín'),
  ('Química del Sur','Ingeniería Química','Auxiliar de laboratorio de procesos','Presencial','Bogotá')
) v(co,pr,t,m,ci) join companies c on c.name=v.co join programs p on p.name=v.pr;

-- Limpia del registro de actividad los movimientos de esta carga inicial
delete from audit_log where actor is null;
