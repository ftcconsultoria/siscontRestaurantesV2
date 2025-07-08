create table public.dispositivos_autorizados (
  id serial not null,
  uuid text not null,
  usuario text null,
  aparelho text null,
  sistema text null,
  autorizado boolean null default false,
  data_solicitacao timestamp without time zone null default CURRENT_TIMESTAMP,
  "CEMP_PK" bigint null,
  constraint dispositivos_autorizados_pkey primary key (id),
  constraint dispositivos_autorizados_CEMP_PK_fkey foreign KEY ("CEMP_PK") references "CADE_EMPRESA" ("CEMP_PK")
) TABLESPACE pg_default;
