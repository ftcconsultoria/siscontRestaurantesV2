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
