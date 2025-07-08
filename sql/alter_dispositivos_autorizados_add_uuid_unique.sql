ALTER TABLE public.dispositivos_autorizados
  ADD CONSTRAINT dispositivos_autorizados_uuid_key UNIQUE (uuid);
