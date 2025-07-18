CREATE TABLE public."SIS_LOG_EVENTO" (
  "LOG_PK" bigint GENERATED BY DEFAULT AS IDENTITY PRIMARY KEY,
  "CEMP_PK" bigint NOT NULL,
  "CUSU_PK" bigint NULL,
  "LOG_ENTIDADE" text NOT NULL,
  "LOG_CHAVE" bigint NULL,
  "LOG_TIPO" text NOT NULL,
  "LOG_TELA" text NULL,
  "LOG_MENSAGEM" text NULL,
  "LOG_DADOS" jsonb NULL,
  "LOG_DT" timestamp DEFAULT current_timestamp
);
