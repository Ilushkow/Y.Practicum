[!ER-diagram](er-diagram.png)

```

Table "car_shop"."colors" {
  "id" serial4 [not null]
  "name" varchar(10) [not null]
  "created_at" timestamptz [not null, default: `CURRENT_TIMESTAMP`]

  Indexes {
    id [pk, name: "colors_pkey"]
  }
}

Table "car_shop"."countries" {
  "id" serial4 [not null]
  "name" varchar(15) [not null]
  "created_at" timestamptz [not null, default: `CURRENT_TIMESTAMP`]

  Indexes {
    id [pk, name: "countries_pkey"]
  }
}

Table "car_shop"."users" {
  "id" serial4 [not null]
  "name" varchar(30) [not null]
  "phone" varchar(25) [not null]
  "created_at" timestamptz [not null, default: `CURRENT_TIMESTAMP`]

  Indexes {
    id [pk, name: "users_pkey"]
  }
}

Table "car_shop"."brands" {
  "id" serial4 [not null]
  "country_id" int4
  "name" varchar(10) [not null]
  "created_at" timestamptz [not null, default: `CURRENT_TIMESTAMP`]

  Indexes {
    id [pk, name: "brands_pkey"]
  }
}

Table "car_shop"."models" {
  "id" serial4 [not null]
  "brand_id" int4 [not null]
  "name" varchar(20) [not null]
  "gasoline_consumption" float4
  "created_at" timestamptz [not null, default: `CURRENT_TIMESTAMP`]

  Indexes {
    id [pk, name: "models_pkey"]
  }
}

Table "car_shop"."purchases" {
  "id" serial4 [not null]
  "user_id" int4 [not null]
  "model_id" int4 [not null]
  "color_id" int4 [not null]
  "price" numeric(7,2) [not null]
  "discount" int4 [not null]
  "date" date [not null]
  "created_at" timestamptz [not null, default: `CURRENT_TIMESTAMP`]

  Indexes {
    id [pk, name: "purchases_pkey"]
  }
}

Ref "brands_country_id_fkey":"car_shop"."countries"."id" < "car_shop"."brands"."country_id"

Ref "models_brand_id_fkey":"car_shop"."brands"."id" < "car_shop"."models"."brand_id"

Ref "purchases_color_id_fkey":"car_shop"."colors"."id" < "car_shop"."purchases"."color_id"

Ref "purchases_model_id_fkey":"car_shop"."models"."id" < "car_shop"."purchases"."model_id"

Ref "purchases_user_id_fkey":"car_shop"."users"."id" < "car_shop"."purchases"."user_id"
```