# erp_mobile

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.

## Database

The project uses [Supabase](https://supabase.com/) as its backend. The SQL file
at `sql/create_estq_produto_foto.sql` contains the statement used to create the
`ESTQ_PRODUTO_FOTO` table which stores product photo URLs. This table
references the existing `ESTQ_PRODUTO` table and generates `EPRO_FOTO_PK`
automatically.

The script `sql/alter_estq_produto_add_cemp_pk.sql` adds the `CEMP_PK`
foreign key to `ESTQ_PRODUTO`, linking each product to a company in
`CADE_EMPRESA`.

A separate SQL script at `sql/create_cade_empresa.sql` defines the
`CADE_EMPRESA` table used for storing company information.

The file `sql/create_cade_usuario.sql` creates the `CADE_USUARIO` table
which stores application users. Each user belongs to a company via the
`CEMP_PK` foreign key. Login credentials will be downloaded from Supabase
after the company is set up and validated against this table. When the
configuration screen loads a company by CNPJ it now also retrieves all
records from this table filtered by the company's `CEMP_PK` and stores
them locally.

Products now include a `CEMP_PK` foreign key referencing `CADE_EMPRESA`.
When synchronizing with Supabase the app filters products by the
company saved locally so that only records for the active company are
fetched.

Product photos are captured directly from the product list. When you tap the
camera icon for a product, the app uses the device camera to take a picture,
uploads the file to the Supabase Storage bucket `fotos-produtos` and saves the
public URL in the `EPRO_FOTO_URL` column of `ESTQ_PRODUTO_FOTO` along with the
corresponding `EPRO_PK` key.

When a product is deleted, the application also removes any associated files
from the `fotos-produtos` bucket to avoid leaving orphan images in storage.

Client information is stored in the `CADE_CONTATO` table. Each record also
includes a `CEMP_PK` foreign key so that contacts belong to a specific
company. The synchronization routine now uploads these client records to
Supabase together with products and photos.

Each client record also stores latitude and longitude coordinates using the
`CCOT_END_LAT` and `CCOT_END_LON` columns in the `CADE_CONTATO` table.

Orders are stored in `PEDI_DOCUMENTOS` and each order can now contain
multiple products through the `PEDI_ITENS` table. The SQL statement used to
create this table is available at `sql/create_pedi_itens.sql`. When editing an
order the application calculates `PDOC_VLR_TOTAL` automatically from the sum
of its items. These order records and their items are also synchronized with
Supabase when using the sync screen.
