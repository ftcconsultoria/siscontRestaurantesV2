ALTER TABLE public."CADE_CONTATO" DROP CONSTRAINT IF EXISTS CADE_CONTATO_pkey;
ALTER TABLE public."CADE_CONTATO" DROP COLUMN IF EXISTS "CCOT_PK";
ALTER TABLE public."CADE_CONTATO" ALTER COLUMN "CCOT_CNPJ" SET NOT NULL;
ALTER TABLE public."CADE_CONTATO" ADD PRIMARY KEY ("CCOT_CNPJ");
